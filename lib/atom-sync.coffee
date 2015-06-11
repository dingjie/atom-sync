{CompositeDisposable} = require 'atom'

controller = require './controller/service-controller'

module.exports = AtomSync =
    subscriptions: null
    controller: controller;

    activate: (state) ->
        @subscriptions = new CompositeDisposable
        @subscriptions.add atom.commands.add '.tree-view.full-menu .header.list-item', 'atom-sync:configure': (e) =>
            @controller.onCreate()

        @subscriptions.add atom.commands.add 'atom-workspace', 'atom-sync:download-directory': (e) =>
            @controller.onSync atom.workspace.getLeftPanels()[0].getItem().selectedPaths()[0], 'down'

        @subscriptions.add atom.commands.add 'atom-workspace', 'atom-sync:upload-directory': (e) =>
            @controller.onSync atom.workspace.getLeftPanels()[0].getItem().selectedPaths()[0], 'up'

        @subscriptions.add atom.commands.add 'atom-workspace', 'atom-sync:download-file': (e) =>
            @controller.onSync atom.workspace.getLeftPanels()[0].getItem().selectedPaths()[0], 'down'

        @subscriptions.add atom.commands.add 'atom-workspace', 'atom-sync:upload-file': (e) =>
            @controller.onSync atom.workspace.getLeftPanels()[0].getItem().selectedPaths()[0], 'up'

        @subscriptions.add atom.commands.add 'atom-workspace', 'atom-sync:toggle-log-panel': (e) =>
            @controller.toggleConsole()

        @subscriptions.add atom.workspace.observeTextEditors (editor) =>
            editor.onDidSave (e) =>
                @controller.onSave e.path

        @subscriptions.add atom.workspace.onDidOpen (e) =>
            @controller.onOpen e.uri

    deactivate: ->
        @controller.destory()

    serialize: ->
        consoleView: @controller.serialize()
