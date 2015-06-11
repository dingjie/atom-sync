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

    # Interfaces
    toggleConsole: ->
        if @console.isVisible() then @console.hide() else @console.show()

    onCreate: ->
        @config.initialise()

    opSave: (f) ->
        config = @config.load(f)
        @doSync(f, 'up') if config?.behaviour.uploadOnSave

    onOpen: (f) ->
        config = @config.load(f)
        @doSync(f, 'down') if config?.behaviour.syncDownOnOpen

    onSync: (obj, direction) ->
        obj = path.normalize obj
        config = @config.assert obj
        relativePath = @config.getRelativePath obj

        if @config.isExcluded relativePath, config.option.exclude
            return

        switch direction
            when 'up'
                src = obj + (if fs.isDirectorySync obj then '/' else '')
                dst = @genRemoteString config.remote.user, config.remote.host,
                    if fs.isDirectorySync obj then path.join config.remote.path, relativePath else path.dirname (path.join config.remote.path, relativePath)
            when 'down'
                src = (@genRemoteString config.remote.user, config.remote.host, (path.join config.remote.path, relativePath)) + (if fs.isDirectorySync obj then '/' else '')
                dst = if fs.isDirectorySync obj then path.normalize obj else (path.dirname obj) + '/'
            else
                return

        @syncAdapter src, dst, config

    # Core
    genRemoteString: (user, remoteAddr, remotePath) ->
        result = "#{remoteAddr}:#{remotePath}"
        result = "#{user}@#{result}" if user

    sync: (src, dst, config = {}, provider = 'rsync-service') ->
        @console.show() if not config.behaviour.forgetConsole
        @console.log "<span class='info'>Syncing from #{src} to #{dst}</span> ..."

        (require '../service/' + provider)
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
                #atom.notifications.addError "#{err}, please review your config file."
                #console.error cmd
                @console.log "<span class='error'>#{err}, plese review your config file.</span>\n"
