{CompositeDisposable} = require 'atom'
AutoEncoding = require './auto-encoding'

module.exports = Main =
  subscriptions: null
  enc: null

  config:
    alwaysAutoDetect:
      title: 'Always auto detect'
      description: 'enabled from startup'
      type: 'boolean'
      default: false

  activate: ->

    @commands = atom.commands.add 'atom-workspace', 'auto-encoding:toggle': =>
      @toggle()

    # always auto-detect
    if atom.config.get 'auto-encoding.alwaysAutoDetect'
      @enabled()

  enabled: ->
    atom.notifications?.addSuccess 'auto-encoding: on'

    @subscriptions ?= new CompositeDisposable
    @enc ?= new AutoEncoding()

    # event: open file
    @subscriptions.add atom.workspace.onDidOpen => @enc.fire()
    # event: changed active pane
    @subscriptions.add atom.workspace.onDidChangeActivePaneItem => @enc.fire()

  disenabled: ->
    atom.notifications?.addSuccess 'auto-encoding: off'
    @subscriptions?.dispose()
    @commands?.dispose()
    @subscriptions = null
    @enc = null

  toggle: ->
    if not @subscriptions?
      @enabled()
    else
      @disenabled()
