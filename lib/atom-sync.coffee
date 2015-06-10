{CompositeDisposable} = require 'atom'

path = require 'path'
fs = require 'fs-plus'
log = require './helper/logger-helper'

consoleHelper = require './helper/console-helper'
configHelper = require './helper/config-helper'

# TODO refactor and foolproof

module.exports = AtomSync =
    consoleView: null
    bottomPanel: null
    subscriptions: null


    # TODO To be refactored
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
            if @console.isVisible() then @console.hide() else @console.show()

        @subscriptions.add atom.workspace.observeTextEditors (editor) =>
            editor.onDidSave (e) =>
                @uploadEditingFile e.path

        @subscriptions.add atom.workspace.onDidOpen (e) =>
            @downloadOpeningFile e.uri

    deactivate: ->
        @console.destory()

    serialize: ->
        consoleView: @console.serialize()

    console: consoleHelper
    config: configHelper

    # TODO Should match exclude pattern in the same way as node-rsync does

    uploadEditingFile: (f) ->
        config = @config.load()
        if config and config.behaviour.uploadOnSave
            log f
            @uploadFile(f)
        else
            log 'give up'

    downloadOpeningFile: (f) ->
        config = @config.load()
        if config and config.behaviour.syncDownOnOpen
            log f
            @downloadFile(f)
        else
            log 'give up'

    downloadFile: (f) ->
        if not fs.isFileSync f
            log 'not a file'
            return
        config = @config.assert()
        relativePath = @config.getRelativePath f
        if @config.isExcluded relativePath, config.option.exclude
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
        config = @config.assert()
        relativePath = @config.getRelativePath f
        if @config.isExcluded relativePath, config.option.exclude
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
        config = @config.assert()
        relativePath = @config.getRelativePath d
        if @config.isExcluded relativePath, config.option.exclude
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
        config = @config.assert()
        relativePath = @config.getRelativePath d
        if @config.isExcluded relativePath, config.option.exclude
            log 'excluded'
            return

        log d

        src = "#{d}/"
        dst = "#{config.remote.user}@#{config.remote.host}:" + path.join config.remote.path, relativePath
        @sync src, dst, config

################################################################################

    sync: (src, dst, config = {}) ->
        @console.show() if not config.behaviour.forgetConsole
        @console.log "<span class='info'>Syncing from #{src} to #{dst}</span> ..."

        (require './service/echo-service')
            src: src,
            dst: dst,
            config: config,
            progress: (msg) =>
                @console.log msg
            success: =>
                @console.log "<span class='success'>Sync completed without error.</span>\n"
                if config.behaviour.autoHideConsole
                    setTimeout =>
                        @console.hide()
                    , 1500
            error: (err, cmd) =>
                atom.notifications.addError "#{err}, please review your config file."
                console.error cmd
