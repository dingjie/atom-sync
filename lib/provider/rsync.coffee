Rsync = require 'rsync'

module.exports = (opt = {}) ->
    src = opt.src
    dst = opt.dst
    config = opt.config
    flags = config?.flags ? 'avzpu'
    success = opt.success
    error = opt.error
    progress = opt.progress

    rsync = new Rsync()
        .shell 'ssh'
        .flags 'avzpu'
        .source src
        .destination dst
        .output (data) ->
            progress data.toString('utf-8').trim()

    rsync.delete() if config.option?.deleteFiles?
    rsync.exclude config.option.exclude if config?.option?.exclude
    rsync.execute (err, code, cmd) =>
        if err then error?(err.message, cmd) err else success?()
