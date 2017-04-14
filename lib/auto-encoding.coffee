# auto-encoding: utf8
fs = require 'fs'
jschardet = require 'jschardet'
iconv = require 'iconv-lite'
_ = require 'lodash'

module.exports =
class AutoEncoding

  # Detect file encoding.
  #
  # @param {Buffer} buffer
  # @return {String} encoding
  detectEncoding = (buffer) ->
    {encoding} =  jschardet.detect(buffer) ? { encoding: null }

    encoding = encoding ? atom.config.get 'core.fileEncoding'
    encoding = stripEncName(encoding)
    encoding = 'utf8' if encoding is 'ascii'

    forceEncMap = getForceEncTypes()
    if forceEncMap?[encoding]
      encoding = forceEncMap[encoding]

    encoding

  # Get disallow encs.
  #
  # @return {Array.<String>} disallowList
  getDisallowEncTypes = ->
    loadSetting = atom.config.get 'auto-encoding.disallowEncTypes'
    disallowList = []

    unless /^(\s+)?$/.test loadSetting
      disallowList = loadSetting.split(/,/).map (enc) ->
        enc.replace(/\s/g, '').toLowerCase()

    disallowList

  # Get forced encoding types
  #
  # @return {Object} encMap
  getForceEncTypes = ->
    loadSetting = atom.config.get 'auto-encoding.forceEncTypes'
    encMap = {}

    if loadSetting.length
      items = loadSetting.replace(/\s/g, '').split(',')
      items.forEach (item) ->
        kv = item.split(':')
        encMap[kv[0]] = kv[1]

    encMap

  # Strip symbols from encoding name
  #
  # @return {String}
  stripEncName = (name) ->
    name.toLowerCase().replace(/[^0-9a-z]|:\d{4}$/g, '')

  # Get best encoding.
  #
  # @param {Array.<String>} encodings
  # @return {String} encoding
  getBestEncode = (encodings) ->

    # reject disallow encs
    disallowEncs = getDisallowEncTypes()
    encodings = encodings.filter (enc) ->
      enc? and disallowEncs.indexOf(
        stripEncName(enc)
      ) is -1

    # get default enc
    encoding = atom.config.get 'core.fileEncoding'
    encMap = {}
    max = 0

    encodings
    .forEach (enc) ->
      encMap[enc] = 0 unless encMap[enc]?
      encMap[enc]++
      return

    for k, v of encMap
      if max < v or (max is v and k isnt encoding)
        max = v
        encoding = k

    encoding

  # divide buffers.
  #
  # @param {Buffer} buffer
  # @param {Number} n
  # @return {Array.<Buffer>} divide buffer.
  divideBuffer = (buffer, n) ->
    step = Math.floor(buffer.length / n)
    [0..n-1].map (idx) ->
      start = if idx is 0 then 0 else idx * step + 1
      end = start + step
      if idx is n-1
        buffer.slice(start)
      else
        buffer.slice(start, end)

  # find encoding definition from comment
  #
  # @param {DomElement} view workspace view.
  # @returns {String} encoding
  getEncodingFromView = (view) ->
    encoding = ''
    pat = /auto-encoding:\s+(\w+)$/
    _.each(view.querySelectorAll('.syntax--comment'), (node) =>
      matcher = pat.exec(node.textContent)
      if matcher
        encoding = matcher[1]
        return false
    )
    encoding

  # is allow file
  #
  # @param {String} filePath
  # @returns {Boolean} is allow file
  isAllowFile = (filePath) ->
    fileName = require('path').basename(filePath)
    filterExt = atom.config.get 'auto-encoding.ignorePattern'
    return filterExt is '' or not new RegExp(filterExt).test fileName

  fire: ->
    # get active text editor
    @editor = atom.workspace.getActiveTextEditor()
    return if not @editor?

    # get file path
    filePath = @editor.getPath()
    return unless fs.existsSync(filePath)

    # divide size
    divideSize = atom.config.get 'auto-encoding.divideSize'

    # convert text
    return fs.readFile filePath, (error, buffer) =>
      return if error? or not @editor?

      encoding = getEncodingFromView(atom.views.getView(@editor))
      unless encoding
        encoding = getBestEncode(
          divideBuffer(buffer, divideSize).map (buf) -> detectEncoding(buf)
        )

      return unless iconv.encodingExists(encoding)
      encoding = stripEncName(encoding)
      editorPath = @editor?.getPath()
      if encoding isnt @editor?.getEncoding() and editorPath?
        @editor?.setEncoding(encoding) if @editor? and isAllowFile(editorPath)
