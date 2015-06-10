{CompositeDisposable} = require 'atom'

controller = require './controller/service-controller'

module.exports = AtomSync =
    subscriptions: null
    controller: controller;

    activate: (state) ->
        @subscriptions = new CompositeDisposable
        @subscriptions.add atom.commands.add '.tree-view.full-menu .header.list-item', 'atom-sync:configure': (e) =>
            @controller.editConfigFile()

        @subscriptions.add atom.commands.add 'atom-workspace', 'atom-sync:download-directory': (e) =>
            @controller.downloadDirectory atom.workspace.getLeftPanels()[0].getItem().selectedPaths()[0]

        @subscriptions.add atom.commands.add 'atom-workspace', 'atom-sync:upload-directory': (e) =>
            @controller.uploadDirectory atom.workspace.getLeftPanels()[0].getItem().selectedPaths()[0]

        @subscriptions.add atom.commands.add 'atom-workspace', 'atom-sync:download-file': (e) =>
            @controller.downloadFile atom.workspace.getLeftPanels()[0].getItem().selectedPaths()[0]

        @subscriptions.add atom.commands.add 'atom-workspace', 'atom-sync:upload-file': (e) =>
            @controller.uploadFile atom.workspace.getLeftPanels()[0].getItem().selectedPaths()[0]

        @subscriptions.add atom.commands.add 'atom-workspace', 'atom-sync:toggle-log-panel': (e) =>
            if @controller.console.isVisible() then @controller.console.hide() else @controller.console.show()

        @subscriptions.add atom.workspace.observeTextEditors (editor) =>
            editor.onDidSave (e) =>
                @controller.uploadEditingFile e.path

        @subscriptions.add atom.workspace.onDidOpen (e) =>
            @controller.downloadOpeningFile e.uri

    deactivate: ->
        @controller.destory()

    serialize: ->
        consoleView: @controller.serialize()
