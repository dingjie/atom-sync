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
        .output (data) -> console.log data.toString 'utf8'
            , (err)-> console.log err.toString 'utf8'

    rsync.delete() if not opt.sync_skip_deletes
    rsync.exclude opt.exclude if opt.exclude?
    rsync.execute (err, code, cmd) ->
        console.log err if err?

upload = ->
    console.log 'Syncing from local to remote ...'
    sync(local, remote, config.option)

download = ->
    console.log 'Syncing from remote to local ...'
    sync(remote, local, config.option)

download()
