fs = require 'fs'
jschardet = require 'jschardet'
iconv = require 'iconv-lite'

module.exports =
class AutoEncoding

  # Detect file encoding.
  #
  # @param {Buffer} buffer
  # @return {String} encoding
  detectEncoding = (buffer) ->
    {encoding} =  jschardet.detect(buffer) ? {}
    encoding = 'utf8' if encoding is 'ascii'
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

  # Get best encoding.
  #
  # @param {Array.<String>} encodings
  # @return {String} encoding
  getBestEncode = (encodings) ->

    # reject disallow encs
    disallowEncs = getDisallowEncTypes()
    encodings = encodings.filter (enc) ->
      enc? and disallowEncs.indexOf(
        enc.toLowerCase().replace(/[^0-9a-z]|:\d{4}$/g, '')
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
      return if error?

      encoding = getBestEncode(
        divideBuffer(buffer, divideSize).map (buf) -> detectEncoding(buf)
      )

      return unless iconv.encodingExists(encoding)
      encoding = encoding.toLowerCase().replace(/[^0-9a-z]|:\d{4}$/g, '')
      unless encoding is @editor?.getEncoding()
        @editor?.setEncoding(encoding) if isAllowFile(@editor.getPath())
