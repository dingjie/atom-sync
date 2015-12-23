fs = require 'fs-plus'
cson = require 'season'
path = require 'path'
_ = require 'underscore'

module.exports = ConfigHelper =
    configFileName: '.sync-config.cson'

    initialise: (f) ->
        config = @getConfigPath f
        if not fs.isFileSync config
            csonSample = cson.stringify @sample
            fs.writeFileSync config, csonSample
        atom.workspace.open config

    load: (f) ->
        config = @getConfigPath f
        return if not config or not fs.isFileSync config
        cson.readFileSync config

    assert: (f) ->
        config = @load f
        if not config then throw new Error "You must create remote config first"
        config

    isExcluded: (str, exclude) ->
        for pattern in exclude
            return true if (str.indexOf pattern) isnt -1
        return false

    getRelativePath: (f) ->
         path.relative (@getRootPath f), f

    getRootPath: (f) ->
        _.find atom.project.getPaths(), (x) -> (f.indexOf x) isnt -1

    getConfigPath: (f) ->
        base = @getRootPath f
        return if not base
        path.join base, @configFileName

    sample:
        remote:
            host: "HOSTNAME",
            user: "USERNAME",
            path: "REMOTE_DIR"
        behaviour:
            uploadOnSave: true
            syncDownOnOpen: true
            forgetConsole: false
            autoHideConsole: true
            alwaysSyncAll: false
        option:
            deleteFiles: false
            exclude: [
                '.sync-config.cson'
                '.git'
                'node_modules'
                'tmp'
                'vendor'
            ]
