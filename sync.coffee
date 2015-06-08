_ = require 'underscore'
cson = require 'CSON'
Rsync = require 'rsync'

config = cson.load 'sync-config.cson'
local = __dirname
remote = "#{config.remote.user}@#{config.remote.host}:#{config.remote.path}"
local = "/Users/dingjie/tmp/remote"

sync = (src, dst, opt = {}) ->
    flags = opt.flags ? 'avzp'
    rsync = new Rsync()
        .shell 'ssh'
        .flags flags
        .source "#{src}/"
        .destination(dst)
        .output (data) -> console.log data.toString('utf-8').trim()

    rsync.delete() if opt.delete_files?
    rsync.exclude opt.exclude if opt.exclude?
    rsync.execute (err, code, cmd) ->
        console.log err if err?
        console.log cmd

upload = ->
    console.log "Syncing from #{local} to #{config.remote.host} ..."
    sync(local, remote, config.option)

download = ->
    console.log "Syncing from #{config.remote.host} to #{local} ..."
    sync(remote, local, config.option)
