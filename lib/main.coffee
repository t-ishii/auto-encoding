{CompositeDisposable} = require 'atom'
AutoEncoding = require './auto-encoding'

module.exports = Main =
  autoEncoding: null

  activate: (state) ->

    @autoEncoding = new AutoEncoding()

    atom.commands.add 'atom-workspace',
      'auto-encoding:toggle': => @autoEncoding.toggle()

  deactivate: ->
    @autoEncoding.erase()

  serialize: ->
