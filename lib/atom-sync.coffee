AtomSyncView = require './atom-sync-view'
{CompositeDisposable} = require 'atom'
path = require 'path'
cson = require 'CSON'
fs = require 'fs-plus'
Rsync = require 'rsync'

module.exports = AtomSync =
    atomSyncView: null
    modalPanel: null
    subscriptions: null
    configFileName: 'sync-config.cson'
    configFile: null
    config: null
    root: null

    activate: (state) ->
        if atom.project.rootDirectories.length < 1
            return

        @root = atom.project.rootDirectories[0].path
        @configFile = path.join @root, @configFileName

        @loadConfig()

        @atomSyncView = new AtomSyncView(state.atomSyncViewState)
        @modalPanel = atom.workspace.addModalPanel(item: @atomSyncView.getElement(), visible: false)

        # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
        @subscriptions = new CompositeDisposable

        # Register command that toggles this view
        @subscriptions.add atom.commands.add '.tree-view.full-menu .header.list-item', 'atom-sync:configure': (e) => @configure(e)
        @subscriptions.add atom.commands.add 'atom-workspace', 'atom-sync:download': (e) => @download(e)
        @subscriptions.add atom.commands.add 'atom-workspace', 'atom-sync:upload': (e) => @upload(e)

        if @config.behaviour.uploadOnSave is true
            @subscriptions.add atom.workspace.observeTextEditors (editor) =>
                onDidSave = editor.onDidSave (e) =>
                    @upload()
        if @config.behaviour.syncDownOnOpen is true
            @subscriptions.add atom.workspace.onDidOpen (e) =>
                @download()
                atom.workspace.reopenItem()

    deactivate: ->
        @modalPanel.destroy()
        @subscriptions.dispose()
        @atomSyncView.destroy()

    serialize: ->
        atomSyncViewState: @atomSyncView.serialize()

    configure: (e) ->
        if not fs.isFileSync @configFile
            sample = cson.createCSONString @sampleConfig
            fs.writeFileSync @configFile, sample

        atom.workspace.open( @configFile)
        # if not @modalPanel.isVisible()
        #     @modalPanel.show()
        #     setTimeout (=> @modalPanel.hide()), 1000

    download: ->
        if not @loadConfig()
            throw new Error "Create config file first"

        remote = "#{@config.remote.user}@#{@config.remote.host}:#{@config.remote.path}"
        @sync(remote, @root, @config.option)

    upload: ->
        if not @loadConfig()
            throw new Error "Create config file first"

        remote = "#{@config.remote.user}@#{@config.remote.host}:#{@config.remote.path}"
        @sync(@root, remote, @config.option)

    sync: (src, dst, opt = {}) ->
        console.log "Syncing from #{src} to #{dst}..."
        flags = opt.flags ? 'avzp'
        rsync = new Rsync()
            .shell 'ssh'
            .flags flags
            .source "#{src}/"
            .destination dst.replace(/\/$/, '')
            .output (data) -> console.log data.toString('utf-8').trim()

        rsync.delete() if opt.deleteFiles?
        rsync.exclude opt.exclude if opt.exclude?
        rsync.execute (err, code, cmd) ->
            console.log err if err?

    loadConfig: ->
        if fs.isFileSync @configFile
            @config = cson.load @configFile
            return true
        return false

    sampleConfig:
        remote:
            host: "HOSTNAME",
            user: "USERNAME",
            path: "REMOTE_DIR"
        behaviour:
            uploadOnSave: true
            syncDownOnOpen: true
        option:
            deleteFiles: true
            exclude: [
                'sync-config.cson'
                '.git'
                'node_modules'
                'tmp'
                'vendor'
            ]
