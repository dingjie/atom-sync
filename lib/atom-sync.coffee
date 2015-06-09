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
    configFile: null
    config: null
    root: null

    activate: (state) ->
        if atom.project.rootDirectories.length < 1
            return

        @root = atom.project.rootDirectories[0].path
        @configFile = path.join @root, 'sync-config.cson'

        @loadConfig()

        @consoleView = new ConsoleView(state.consoleViewState)
        @bottomPanel = atom.workspace.addBottomPanel(item: @consoleView.element, visible: false)
        @consoleView.close =>
            @bottomPanel.hide()

        @subscriptions = new CompositeDisposable
        @subscriptions.add atom.commands.add '.tree-view.full-menu .header.list-item', 'atom-sync:configure': (e) =>
            @configure()
        @subscriptions.add atom.commands.add 'atom-workspace', 'atom-sync:download': (e) =>
            @downloadDirectory atom.workspace.getLeftPanels()[0].getItem().selectedPaths()[0]
        @subscriptions.add atom.commands.add 'atom-workspace', 'atom-sync:upload': (e) =>
            @uploadDirectory atom.workspace.getLeftPanels()[0].getItem().selectedPaths()[0]
        @subscriptions.add atom.commands.add 'atom-workspace', 'atom-sync:show-panel': (e) =>
            @bottomPanel.show()
        @subscriptions.add atom.commands.add 'atom-workspace', 'atom-sync:close-panel': (e) =>
            @bottomPanel.hide()

        if @config isnt null
            if @config.behaviour.uploadOnSave is true
                @subscriptions.add atom.workspace.observeTextEditors (editor) =>
                    onDidSave = editor.onDidSave (e) =>
                        @uploadFile e.path
            if @config.behaviour.syncDownOnOpen is true
                @subscriptions.add atom.workspace.onDidOpen (e) =>
                        @downloadFile e.uri

    deactivate: ->
        @bottomPanel.destroy()
        @subscriptions.dispose()
        @consoleView.destroy()

    serialize: ->
        consoleView: @consoleView.serialize()

    configure: (e) ->
        if not fs.isFileSync @configFile
            sample = cson.createCSONString @sampleConfig
            fs.writeFileSync @configFile, sample

        atom.workspace.open @configFile

    getRelativePath: (base, fullpath) ->
        fullpath.replace new RegExp('^'+base.replace(/([.?*+^$[\]\\/(){}|-])/g, "\\$1")), ''

    loadConfig: ->
        if fs.isFileSync @configFile
            @config = cson.load @configFile
            return true
        return false

    assertConfig: ->
        if not @loadConfig()
            atom.notifications.addError "You must create remote config first"
            return

    isExcluded: (str) ->
        for pattern in @config.option.exclude
            return true if (str.indexOf pattern) isnt -1
        return false

    downloadFile: (f) ->
        @assertConfig()
        return if @isExcluded (@getRelativePath @root, f)
        src = "#{@config.remote.user}@#{@config.remote.host}:" + path.join @config.remote.path, (@getRelativePath @root, f)
        dst = (path.dirname f) + '/'
        @sync src, dst, @config.option

    uploadFile: (f) ->
        @assertConfig()
        return if @isExcluded (@getRelativePath @root, f)
        src = f
        dst = "#{@config.remote.user}@#{@config.remote.host}:" + path.dirname path.join @config.remote.path, (@getRelativePath @root, f)
        @sync src, dst, @config.option

    downloadDirectory: (d) ->
        @assertConfig()
        return if @isExcluded (@getRelativePath @root, d)
        src = "#{@config.remote.user}@#{@config.remote.host}:" + (path.join @config.remote.path, (@getRelativePath @root, d)) + '/'
        dst = path.normalize d
        @sync src, dst, @config.option

    uploadDirectory: (d) ->
        @assertConfig()
        return if @isExcluded (@getRelativePath @root, d)
        src = "#{d}/"
        dst = "#{@config.remote.user}@#{@config.remote.host}:" + path.join @config.remote.path, (@getRelativePath @root, d)
        @sync src, dst, @config.option

    # @TODO confirm dialogue

    sync: (src, dst, opt = {}, cb = null) ->
        @bottomPanel.show() if not @config.behaviour.forgetConsole
        @consoleView.log "<span class='info'>Syncing from #{src} to #{dst}</span> ..."
        rsync = new Rsync()
            .shell 'ssh'
            .flags 'avzpu'
            .source src
            .destination dst
            .output (data) => @consoleView.log data.toString('utf-8').trim()

        rsync.delete() if opt.deleteFiles?
        rsync.exclude opt.exclude if opt.exclude?
        rsync.execute (err, code, cmd) =>
            if err
                atom.notifications.addError "#{err.message}, please review your config file." if err
                console.error cmd
            else
                @consoleView.log "<span class='success'>Sync completed without error.</spane>\n"
                if not @config.behaviour.autoHideConsole
                    setTimeout (=> @bottomPanel.hide()), 3000


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
                'sync-config.cson'
                '.git'
                'node_modules'
                'tmp'
                'vendor'
            ]
