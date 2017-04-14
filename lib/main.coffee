# auto-encoding: utf8
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
      default: true
    # divide buffer option
    divideSize:
      title: 'The number of the consideration.'
      description: 'divide size of buffer'
      type: 'number'
      default: 1
      minimum: 1
    disallowEncTypes:
      title: 'Disallow some encoding types'
      description: 'example: windows1252, iso88591'
      type: 'string'
      default: ''
    ignorePattern:
      title: 'Ignore Pattern'
      description: 'example: (txt|js)$'
      type: 'string'
      default: ''
    forceEncTypes:
      title: 'Force some encoding types'
      description: 'example: windows1252:windows1251, iso88591:windows1251'
      type: 'string'
      default: ''

  activate: ->

    atom.commands.add 'atom-workspace', 'auto-encoding:toggle': =>
      @toggle()

    # always auto-detect
    if atom.config.get 'auto-encoding.alwaysAutoDetect'
      @enabled()

  enabled: ->
    @subscriptions ?= new CompositeDisposable
    @enc ?= new AutoEncoding()

    # event: open file
    @subscriptions.add atom.workspace.observeTextEditors => @enc.fire()
    # event: changed active pane
    @subscriptions.add atom.workspace.onDidChangeActivePaneItem => @enc.fire()

  disabled: ->
    @subscriptions?.dispose()
    @subscriptions = null
    @enc = null

  toggle: ->
    if not @subscriptions?
      @enabled()
      atom.notifications?.addSuccess 'auto-encoding: on'
    else
      @disabled()
      atom.notifications?.addSuccess 'auto-encoding: off'
