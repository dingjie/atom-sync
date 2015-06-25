fs = require 'fs-plus'
cson = require 'season'
path = require 'path'

module.exports = ConfigHelper =
    initialise: ->
        file =  @getFullPath()
        if not fs.isFileSync file
            csonSample = cson.stringify @sample
            fs.writeFileSync file, csonSample
        atom.workspace.open file

    load: (anchor = null) ->
        file = @getFullPath(anchor)
        if not file
            return

        if fs.isFileSync file
            return cson.readFileSync file

        return

    assert: (anchor = null) ->
        config = @load(anchor)
        if not config
            throw new Error "You must create remote config first"

        return config

    # TODO Should match exclude pattern in the same way as node-rsync does
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

    getFullPath: (anchor = null) ->
        root = @getCurrentProjectDirectory(anchor)
        if not root
            return

        return path.join root, '.sync-config.cson'

    getCurrentProjectDirectory: (anchor) ->
        if atom.project.rootDirectories.length < 1
            return

        roots = atom.project.rootDirectories
        selected = (->
            if anchor?
                anchor
            else if atom.workspace.getLeftPanels()[0]
                atom.workspace.getLeftPanels()[0].getItem().selectedPaths()[0]
            else
                false
        )()

        if not (roots and selected)
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
