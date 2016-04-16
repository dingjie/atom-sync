path = require 'path'
{CompositeDisposable} = require 'atom'
{$} = require 'atom-space-pen-views'

controller = require './controller/service-controller'

module.exports = AtomSync =
    subscriptions: null
    controller: controller

    activate: (state) ->
        @subscriptions = new CompositeDisposable

        # Bind commands

        # @subscriptions.add atom.commands.add 'atom-workspace', 'atom-sync:debug': (e) =>
        #     @controller.debug @getProjectPath atom.workspace.getActivePaneItem().buffer.file.path

        @subscriptions.add atom.commands.add '.tree-view.full-menu .header.list-item', 'atom-sync:configure': (e) =>
            @controller.onCreate @getSelectedPath e.target

        @subscriptions.add atom.commands.add 'atom-workspace', 'atom-sync:upload-project': (e) =>
            projectFolder = @getProjectPath atom.workspace.getActivePaneItem().buffer.file.path
            @controller.onSync projectFolder, 'up' if projectFolder

        @subscriptions.add atom.commands.add 'atom-workspace', 'atom-sync:download-directory': (e) =>
            @controller.onSync (@getSelectedPath e.target, yes), 'down'

        @subscriptions.add atom.commands.add 'atom-workspace', 'atom-sync:upload-directory': (e) =>
            @controller.onSync (@getSelectedPath e.target, yes), 'up'

        @subscriptions.add atom.commands.add 'atom-workspace', 'atom-sync:download-file': (e) =>
            @controller.onSync (@getSelectedPath e.target), 'down'

        @subscriptions.add atom.commands.add 'atom-workspace', 'atom-sync:upload-file': (e) =>
            @controller.onSync (@getSelectedPath e.target), 'up'

        @subscriptions.add atom.commands.add 'atom-workspace', 'atom-sync:toggle-log-panel': (e) =>
            @controller.toggleConsole()

        # Observe events

        @subscriptions.add atom.workspace.observeTextEditors (editor) =>
            editor.onDidSave (e) =>
                @controller.onSave e.path

        @subscriptions.add atom.workspace.onDidOpen (e) =>
            @controller.onOpen e.uri

    getSelectedPath: (target, directory = no) ->
        selection = (if ($ target).is 'span' then $ target else ($ target).find 'span')?.attr 'data-path'
        if selection?
            selection
        else
            if directory
                path.dirname(atom.workspace.getActivePaneItem().buffer.file.path)
            else
                atom.workspace.getActivePaneItem().buffer.file.path

    getProjectPath: (f) ->
        _.find atom.project.getPaths(), (x) -> (f.indexOf x) isnt -1

    deactivate: ->
        @controller.destory()

    serialize: ->
        consoleView: @controller.serialize()
