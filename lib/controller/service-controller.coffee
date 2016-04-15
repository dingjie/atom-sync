_ = require 'lodash'
path = require 'path'
fs = require 'fs-plus'
log = require '../helper/logger-helper'

consoleHelper = require '../helper/console-helper'
configHelper = require '../helper/config-helper'

module.exports = ServiceController =
    console: consoleHelper
    config: configHelper

    debug: ->
        log arguments

    destory: ->
        @console.destory()

    serialize: ->
        @console.serialize()

    # Interfaces
    toggleConsole: ->
        if @console.isVisible() then @console.hide() else @console.show()

    onCreate: (obj) ->
        @config.initialise obj

    onSave: (obj) ->
        config = @config.load obj
        @onSync obj, 'up' if config?.behaviour?.uploadOnSave

    onOpen: (obj) ->
        config = @config.load obj
        @onSync obj, 'down' if config?.behaviour?.syncDownOnOpen

    onSync: (obj, direction) ->
        obj = path.normalize obj

        try
            config = @config.assert obj
        catch err
            @console.show()
            @console.log "<span class='error'>#{err}</span>\n"
            return

        relativePath = @config.getRelativePath obj

        return if @config.isExcluded relativePath, config.option?.exclude

        switch direction
            when 'up'
                if config.behaviour?.alwaysSyncAll is true
                    src = (@config.getRootPath obj) + path.sep
                    dst = @genRemoteString config.remote.user, config.remote.host, config.remote.path
                else
                    src = obj + (if fs.isDirectorySync obj then path.sep else '')
                    dst = @genRemoteString config.remote.user, config.remote.host,
                        if fs.isDirectorySync obj then path.join config.remote.path, relativePath else path.dirname (path.join config.remote.path, relativePath)
            when 'down'
                if config.behaviour?.alwaysSyncAll is true
                    # A hack to prevent a newly created file being deleted
                    src = (@genRemoteString config.remote.user, config.remote.host, (path.join config.remote.path, relativePath)) + (if fs.isDirectorySync obj then '/' else '')
                    dst = if fs.isDirectorySync obj then path.normalize obj else (path.dirname obj) + '/'
                    @sync src, dst, config

                    src = (@genRemoteString config.remote.user, config.remote.host, config.remote.path) + path.sep
                    dst = (@config.getRootPath obj) + path.sep
                    config.option.exclude.push relativePath
                else
                    src = (@genRemoteString config.remote.user, config.remote.host, (path.join config.remote.path, relativePath)) + (if fs.isDirectorySync obj then '/' else '')
                    dst = if fs.isDirectorySync obj then path.normalize obj else (path.dirname obj) + '/'
            else
                return

        @sync src, dst, config, 'rsync-service', =>
            if direction is 'up' and config.trigger
                @fireTriggers obj, config


    # Core
    genRemoteString: (user, remoteAddr, remotePath) ->
        result = "#{remoteAddr}:#{remotePath}"
        result = "#{user}@#{result}" if user

    sync: (src, dst, config = {}, provider, complete) ->
        delay = config.option?.autoHideDelay or 1500

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
                complete() if complete
                if config.behaviour?.autoHideConsole
                    clearTimeout @_timer
                    @_timer = setTimeout (=>
                        @console.hide()
                    ), delay
            error: (err, cmd) =>
                @console.log "<span class='error'>#{err}, please review your config file.</span>\n"

    fireTriggers: (path, config) ->
        rpath = @config.getRelativePath path
        tasks = _.flattenDeep _.filter config.trigger, (o, i) => (i is '*') or rpath.startsWith i
        if tasks?.length > 0
            tasks.unshift "cd #{config.remote.path}"
            cmd = (_.map tasks, (x) -> x.replace ';', '\\;').join ';'
            ssh = new (require 'node-sshclient').SSH
                hostname: config.remote.host
                user: config.remote.user
            ssh.command cmd, '', (out) =>
                @console.log "<span class='info'>Triggered</span>\n#{out.stdout}<span class='success'>Done!\n</span>"
