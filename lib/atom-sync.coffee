ConsoleView = require './console-view'
{CompositeDisposable} = require 'atom'
path = require 'path'
cson = require 'CSON'
fs = require 'fs-plus'
log = require './helper/logger'

# TODO refactor and foolproof

module.exports = AtomSync =
    consoleView: null
    bottomPanel: null
    subscriptions: null

    # TODO To be refactored
    activate: (state) ->
        log()
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

    # TODO To be refactored

    log: (msg) ->
        log msg
        @consoleView.log msg if @consoleView?

    show: ->
        if @bottomPanel is null
            log 'create'
            @consoleView = new ConsoleView()
            @bottomPanel = atom.workspace.addBottomPanel item: @consoleView.element
            @consoleView.close =>
                @hide()
        else
            @bottomPanel.show()
            log()

    hide: ->
        if @bottomPanel isnt null
            log()
            @bottomPanel.hide()
        else
            log 'nothing to hide'

    uploadEditingFile: (f) ->
        config = @loadConfig()
        if config and config.behaviour.uploadOnSave
            log f
            @uploadFile(f)
        else
            log 'give up'

    downloadOpeningFile: (f) ->
        config = @loadConfig()
        if config and config.behaviour.syncDownOnOpen
            log f
            @downloadFile(f)
        else
            log 'give up'


    getCurrentRootDirectory: ->
        if atom.project.rootDirectories.length < 1
            log 'no tree-view, give up'
            return

        roots = atom.project.rootDirectories
        selected = atom.workspace.getLeftPanels()[0].getItem().selectedPaths()[0]

        if not roots or not selected
            log 'something wrong, give up'
            return

        for dir in roots
            if (@getRelativePath dir.path, selected) isnt selected
                log 'matched', dir.path, selected
                return dir.path

    deactivate: ->
        log()
        @bottomPanel.destroy()
        @subscriptions.dispose()
        @consoleView.destroy()

    serialize: ->
        log()
        consoleView: @consoleView.serialize()

    configure: (e) ->
        configFile =  @getConfigFilePath()
        if not fs.isFileSync configFile
            log 'create', configFile
            sample = cson.createCSONString @sampleConfig
            fs.writeFileSync configFile, sample

        log 'open', configFile
        atom.workspace.open configFile

    getRelativePath: (base, fullpath) ->
        if not base or not fullpath
            log 'something wrong, give up'
            return

        relativePath = fullpath.replace new RegExp('^'+base.replace(/([.?*+^$[\]\\/(){}|-])/g, "\\$1")), ''
        if not relativePath
            log 'find nothing'
        else
            log relativePath

        return relativePath

    getConfigFilePath: ->
        root = @getCurrentRootDirectory()
        if not root
            log 'no root, give up'
            return
        configFile = path.join root, '.sync-config.cson'
        log configFile
        return configFile

    loadConfig: ->
        configFile = @getConfigFilePath()
        if not configFile
            log 'something wrong, give up'
            return
        if fs.isFileSync configFile
            log 'configFile loaded'
            return cson.load configFile

        log 'configFile does not exist'
        return

    assertConfig: ->
        config = @loadConfig()
        if not config
            log 'no config'
            throw new Error "You must create remote config first"

        log()
        return config

    # TODO Should match exclude pattern in the same way as node-rsync does

    isExcluded: (str, exclude) ->
        log str
        for pattern in exclude
            if (str.indexOf pattern) isnt -1
                log pattern
                return true
        return false

    # TODO Following 4 funcs should be integrated in some way

    downloadFile: (f) ->
        if not fs.isFileSync f
            log 'not a file'
            return
        config = @assertConfig()
        relativePath = @getRelativePath @getCurrentRootDirectory(), f
        if @isExcluded relativePath, config.option.exclude
            log 'excluded'
            return

        log f

        src = "#{config.remote.user}@#{config.remote.host}:" + path.join config.remote.path, relativePath
        dst = (path.dirname f) + '/'
        @sync src, dst, config

    uploadFile: (f) ->
        if not fs.isFileSync f
            log 'not a file'
            return
        config = @assertConfig()
        relativePath = @getRelativePath @getCurrentRootDirectory(), f
        if @isExcluded relativePath, config.option.exclude
            log 'excluded'
            return

        log f

        src = f
        dst = "#{config.remote.user}@#{config.remote.host}:" + path.dirname path.join config.remote.path, relativePath
        @sync src, dst, config

    downloadDirectory: (d) ->
        if not fs.isDirectorySync d
            log 'not a directory'
            return
        config = @assertConfig()
        relativePath = @getRelativePath @getCurrentRootDirectory(), d
        if @isExcluded relativePath, config.option.exclude
            log 'excluded'
            return

        log d

        src = "#{config.remote.user}@#{config.remote.host}:" + (path.join config.remote.path, relativePath) + '/'
        dst = path.normalize d
        @sync src, dst, config

    uploadDirectory: (d) ->
        if not fs.isDirectorySync d
            log 'not a directory'
            return
        config = @assertConfig()
        relativePath = @getRelativePath @getCurrentRootDirectory(), d
        if @isExcluded relativePath, config.option.exclude
            log 'excluded'
            return

        log d

        src = "#{d}/"
        dst = "#{config.remote.user}@#{config.remote.host}:" + path.join config.remote.path, relativePath
        @sync src, dst, config

    # TODO confirm dialogue

    sync: (src, dst, config = {}) ->
        log src, dst, config
        @show() if not config.behaviour.forgetConsole
        @log "<span class='info'>Syncing from #{src} to #{dst}</span> ..."

        (require './provider/echo')
            src: src,
            dst: dst,
            config: config,
            progress: (msg) =>
                log msg
                @consoleView.log msg
            success: =>
                log 'success'
                @log "<span class='success'>Sync completed without error.</span>\n"
                setTimeout @hide(), 1500 if config.behaviour.autoHideConsole
            error: (err, cmd) =>
                log err
                atom.notifications.addError "#{err}, please review your config file."
                console.error cmd

    # TODO Should be store in a static file for comments

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
