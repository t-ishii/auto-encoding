fs = require 'fs'
jschardet = require 'jschardet'
iconv = require 'iconv-lite'

module.exports =
class AutoEncoding

  fire: ->
    # get active text editor
    @editor = atom.workspace.getActiveTextEditor()
    return if not @editor?

    # get file path
    filePath = @editor.getPath()

    return if not fs.existsSync filePath

    # convert text
    return fs.readFile(
      filePath,
      (error, buffer) =>
        return if error isnt null
        enc = (if (_ref = jschardet.detect buffer)? then _ref else {}).encoding
        enc = 'utf8' if enc is 'ascii'
        return if not iconv.encodingExists enc
        enc = enc.toLowerCase().replace /[^0-9a-z]|:\d{4}$/g, ''
        if not new RegExp('^'+enc+'$', 'i').test @editor.getEncoding()
          @editor.setEncoding(enc)
      )
