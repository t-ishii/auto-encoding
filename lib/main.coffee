{CompositeDisposable} = require 'atom'
AutoEncoding = require './auto-encoding'

module.exports = Main =
  subscriptions: null
  enc: null

  activate: ->
    atom.commands.add 'atom-workspace', 'auto-encoding:toggle': => @toggle()

  toggle: ->
    if not @subscriptions?

      atom.notifications?.addSuccess 'auto-encoding: on'

      @subscriptions ?= new CompositeDisposable
      @enc ?= new AutoEncoding()

      # event: open file
      @subscriptions.add atom.workspace.onDidOpen => @enc.fire()
      # event: changed active pane
      @subscriptions.add atom.workspace.onDidChangeActivePaneItem => @enc.fire()

    else

      atom.notifications?.addSuccess 'auto-encoding: off'

      @subscriptions?.dispose()

      @subscriptions = null
      @enc = null
