ConsoleView = require './console-view'
{CompositeDisposable} = require 'atom'
path = require 'path'
cson = require 'CSON'
fs = require 'fs-plus'
Rsync = require 'rsync'

# @TODO refactor and foolproof

module.exports = AtomSync =
    consoleView: null
    bottomPanel: null
    subscriptions: null

    activate: (state) ->
        @subscriptions = new CompositeDisposable
        @subscriptions.add atom.commands.add '.tree-view.full-menu .header.list-item', 'atom-sync:configure': (e) =>
            @configure()

        @subscriptions.add atom.commands.add 'atom-workspace', 'atom-sync:download-directory': (e) =>
            @downloadDirectory atom.workspace.getLeftPanels()[0].getItem().selectedPaths()[0]

        @subscriptions.add atom.commands.add 'atom-workspace', 'atom-sync:upload-directory': (e) =>
            @uploadDirectory atom.workspace.getLeftPanels()[0].getItem().selectedPaths()[0]

        @subscriptions.add atom.commands.add 'atom-workspace', 'atom-sync:download-file': (e) =>
            @downloadFile atom.workspace.getLeftPanels()[0].getItem().selectedPaths()[0]

        @subscriptions.add atom.commands.add 'atom-workspace', 'atom-sync:upload-file': (e) =>
            @uploadFile atom.workspace.getLeftPanels()[0].getItem().selectedPaths()[0]

        @subscriptions.add atom.commands.add 'atom-workspace', 'atom-sync:toggle-log-panel': (e) =>
            if @bottomPanel isnt null and @bottomPanel.isVisible() then @hide() else @show()

        @subscriptions.add atom.workspace.observeTextEditors (editor) =>
            editor.onDidSave (e) =>
                @uploadEditingFile e.path

        @subscriptions.add atom.workspace.onDidOpen (e) =>
            @downloadOpeningFile e.uri

    show: ->
        if @bottomPanel is null
            @consoleView = new ConsoleView()
            @bottomPanel = atom.workspace.addBottomPanel item: @consoleView.element
            @consoleView.close =>
                @hide()
        else
            @bottomPanel.show()

    hide: ->
        @bottomPanel.hide() if @bottomPanel isnt null

    uploadEditingFile: (f) ->
        config = @loadConfig()
        if config and config.behaviour.uploadOnSave
            @uploadFile(f)

    downloadOpeningFile: (f) ->
        config = @loadConfig()
        if config and config.behaviour.syncDownOnOpen
            @downloadFile(f)


    getCurrentRootDirectory: ->
        if atom.project.rootDirectories.length < 1
            return

        roots = atom.project.rootDirectories
        selected = atom.workspace.getLeftPanels()[0].getItem().selectedPaths()[0]
        for dir in roots
            if (@getRelativePath dir.path, selected) isnt selected
                return dir.path

    deactivate: ->
        @bottomPanel.destroy()
        @subscriptions.dispose()
        @consoleView.destroy()

    serialize: ->
        consoleView: @consoleView.serialize()

    configure: (e) ->
        configFile =  @getConfigFilePath()
        if not fs.isFileSync configFile
            sample = cson.createCSONString @sampleConfig
            fs.writeFileSync configFile, sample

        atom.workspace.open configFile

    getRelativePath: (base, fullpath) ->
        fullpath.replace new RegExp('^'+base.replace(/([.?*+^$[\]\\/(){}|-])/g, "\\$1")), ''

    getConfigFilePath: ->
        configFile = path.join @getCurrentRootDirectory(), '.sync-config.cson'

    loadConfig: ->
        configFile = @getConfigFilePath()
        if fs.isFileSync configFile
            return cson.load configFile
        return null

    assertConfig: ->
        config = @loadConfig()
        if not config
            throw new Error "You must create remote config first"
        return config

    isExcluded: (str, exclude) ->
        for pattern in exclude
            return true if (str.indexOf pattern) isnt -1
        return false

    downloadFile: (f) ->
        return if not fs.isFileSync f
        config = @assertConfig()
        relativePath = @getRelativePath @getCurrentRootDirectory(), f
        return if @isExcluded relativePath, config.option.exclude

        src = "#{config.remote.user}@#{config.remote.host}:" + path.join config.remote.path, relativePath
        dst = (path.dirname f) + '/'
        @sync src, dst, config

    uploadFile: (f) ->
        return if not fs.isFileSync f
        config = @assertConfig()
        relativePath = @getRelativePath @getCurrentRootDirectory(), f
        return if @isExcluded relativePath, config.option.exclude

        src = f
        dst = "#{config.remote.user}@#{config.remote.host}:" + path.dirname path.join config.remote.path, relativePath
        @sync src, dst, config

    downloadDirectory: (d) ->
        return if not fs.isDirectorySync d
        config = @assertConfig()
        relativePath = @getRelativePath @getCurrentRootDirectory(), d
        return if @isExcluded relativePath, config.option.exclude

        src = "#{config.remote.user}@#{config.remote.host}:" + (path.join config.remote.path, relativePath) + '/'
        dst = path.normalize d
        @sync src, dst, config

    uploadDirectory: (d) ->
        return if not fs.isDirectorySync d
        config = @assertConfig()
        relativePath = @getRelativePath @getCurrentRootDirectory(), d
        return if @isExcluded relativePath, config.option.exclude

        src = "#{d}/"
        dst = "#{config.remote.user}@#{config.remote.host}:" + path.join config.remote.path, relativePath
        @sync src, dst, config

    # @TODO confirm dialogue

    sync: (src, dst, config = {}) ->
        @show() if not config.behaviour.forgetConsole
        @consoleView.log "<span class='info'>Syncing from #{src} to #{dst}</span> ..." if @consoleView isnt null
        rsync = new Rsync()
            .shell 'ssh'
            .flags 'avzpu'
            .source src
            .destination dst
            .output (data) => @consoleView.log data.toString('utf-8').trim()

        rsync.delete() if config.option.deleteFiles?
        rsync.exclude config.option.exclude if config.option.exclude?
        rsync.execute (err, code, cmd) =>
            if err
                atom.notifications.addError "#{err.message}, please review your config file." if err
                console.error cmd
            else
                @consoleView.log "<span class='success'>Sync completed without error.</spane>\n" if @consoleView isnt null
                if config.behaviour.autoHideConsole
                    setTimeout (=> @hide()), 1500


    sampleConfig:
        remote:
            host: "HOSTNAME",
            user: "USERNAME",
            path: "REMOTE_DIR"
        behaviour:
            uploadOnSave: true
            syncDownOnOpen: true
            forgetConsole: false
            autoHideConsole: true
        option:
            deleteFiles: true
            exclude: [
                '.sync-config.cson'
                '.git'
                'node_modules'
                'tmp'
                'vendor'
            ]
