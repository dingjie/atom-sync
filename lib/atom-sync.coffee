AtomSyncView = require './atom-sync-view'
{CompositeDisposable} = require 'atom'

module.exports = AtomSync =
  atomSyncView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @atomSyncView = new AtomSyncView(state.atomSyncViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @atomSyncView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-sync:toggle': => @toggle()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @atomSyncView.destroy()

  serialize: ->
    atomSyncViewState: @atomSyncView.serialize()

  toggle: ->
    console.log 'AtomSync was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()
