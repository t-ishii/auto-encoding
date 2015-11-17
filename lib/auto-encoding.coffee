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

  fire: ->
    # get active text editor
    @editor = atom.workspace.getActiveTextEditor()
    return if not @editor?

    # get file path
    filePath = @editor.getPath()
    return unless fs.existsSync(filePath)

    # convert text
    return fs.readFile filePath, (error, buffer) =>
      return if error?
      encoding =  detectEncoding(buffer)
      return unless iconv.encodingExists(encoding)
      encoding = encoding.toLowerCase().replace(/[^0-9a-z]|:\d{4}$/g, '')
      @editor.setEncoding(encoding)
