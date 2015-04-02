{CompositeDisposable} = require 'atom'

fs = require 'fs'
jschardet = require 'jschardet'
iconv = require 'iconv-lite'

module.exports =
class AutoEncoding

  subscriptions = null

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
        @editor.setEncoding(enc)
      )

  erase: ->
    @subscriptions?.dispose()
    @subscriptions = null

  toggle: ->
    if not @subscriptions?
      @subscriptions = new CompositeDisposable
      @subscriptions.add atom.workspace.onDidOpen =>
        @fire()
    else
      @erase()
