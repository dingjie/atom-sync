path = require 'path'
fs = require 'fs-plus'
log = require '../helper/logger-helper'

consoleHelper = require '../helper/console-helper'
configHelper = require '../helper/config-helper'

module.exports = ServiceController =
    console: consoleHelper
    config: configHelper

    destory: ->
        @console.destory()

    serialize: ->
        @console.serialize()

    editConfigFile: ->
        @config.initialise()

################################################################################

    # TODO Should match exclude pattern in the same way as node-rsync does
    uploadEditingFile: (f) ->
        config = @config.load(f)
        if config and config.behaviour.uploadOnSave
            log f
            @uploadFile(f)
        else
            log 'give up'

    downloadOpeningFile: (f) ->
        config = @config.load(f)
        if config and config.behaviour.syncDownOnOpen
            log f
            @downloadFile(f)
        else
            log 'give up'

    downloadFile: (f) ->
        if not fs.isFileSync f
            log 'not a file'
            return
        config = @config.assert(f)
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
        config = @config.assert(f)
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

        (require '../service/rsync-service')
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
