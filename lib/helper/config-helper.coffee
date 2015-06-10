fs = require 'fs-plus'
cson = require 'CSON'

module.exports = ConfigHelper =
    initialise: ->
        file =  @getFullPath()
        if not fs.isFileSync file
            csonSample = cson.createCSONString @sample
            fs.writeFileSync file, csonSample
        atom.workspace.open file

    load: ->
        file = @getFullPath()
        if not file
            return

        if fs.isFileSync file
            return cson.load file

        return

    assert: ->
        config = @load()
        if not config
            throw new Error "You must create remote config first"

        return config

    isExcluded: (str, exclude) ->
        for pattern in exclude
            if (str.indexOf pattern) isnt -1
                return true
        return false

    getRelativePath: (fullpath) ->
        base = @getCurrentProjectDirectory()
        return @getRelativePathByBase base, fullpath

    getRelativePathByBase: (base, fullpath) ->
        if not base or not fullpath
            return

        return fullpath.replace new RegExp('^'+base.replace(/([.?*+^$[\]\\/(){}|-])/g, "\\$1")), ''

    getFullPath: ->
        root = @getCurrentProjectDirectory()
        if not root
            return

        return path.join root, '.sync-config.cson'

    getCurrentProjectDirectory: ->
        if atom.project.rootDirectories.length < 1
            return

        roots = atom.project.rootDirectories
        selected = atom.workspace.getLeftPanels()[0].getItem().selectedPaths()[0]

        if not roots or not selected
            return

        for dir in roots
            if (@getRelativePathByBase dir.path, selected) isnt selected
                return dir.path

    # TODO Should be store in a static file for comments
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
        option:
            deleteFiles: true
            exclude: [
                '.sync-config.cson'
                '.git'
                'node_modules'
                'tmp'
                'vendor'
            ]
