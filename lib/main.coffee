{CompositeDisposable} = require 'atom'
AutoEncoding = require './auto-encoding'

module.exports = Main =
  subscriptions: null
  enc: null

  activate: ->
    atom.commands.add 'atom-workspace', 'auto-encoding:toggle': => @toggle()

  toggle: ->
    if not @subscriptions?
      @subscriptions ?= new CompositeDisposable
      @enc ?= new AutoEncoding()
      # event: open file
      @subscriptions.add atom.workspace.onDidOpen =>
        @enc.fire()
    else
      @subscriptions?.dispose()
      @subscriptions = null
      @enc = null
