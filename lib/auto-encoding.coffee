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

  # Get best encoding.
  #
  # @param {Array.<String>} encodings
  # @return {String} encoding
  getBestEncode = (encodings) ->
    encoding = 'utf8'
    encMap = {}
    max = 0

    encodings.forEach (enc) ->
      encMap[enc] = 0 unless encMap[enc]?
      encMap[enc]++
      return

    for k, v of encMap
      if max < v
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

  fire: ->
    # get active text editor
    @editor = atom.workspace.getActiveTextEditor()
    return if not @editor?

    # get file path
    filePath = @editor.getPath()
    return unless fs.existsSync(filePath)

    # show warn message?
    isShowMsgW1252 = atom.config.get 'auto-encoding.warningWindows1252'

    # convert text
    return fs.readFile filePath, (error, buffer) =>
      return if error?

      encoding = getBestEncode(
        divideBuffer(buffer, 3).map (buf) -> detectEncoding(buf)
      )

      return unless iconv.encodingExists(encoding)
      encoding = encoding.toLowerCase().replace(/[^0-9a-z]|:\d{4}$/g, '')
      unless encoding is @editor.getEncoding()

        if isShowMsgW1252 and encoding is 'windows1252'
          atom.notifications?.addWarning 'change encoding to windows1252'

        @editor.setEncoding(encoding)
