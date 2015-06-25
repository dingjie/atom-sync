# atom-sync package

atom-sync is an Atom package to sync files bidirectionally between remote host and local over ssh+rsync. Inspired by [Sublime SFTP](http://wbond.net/sublime_packages/sftp).

[![experimental](http://badges.github.io/stability-badges/dist/experimental.svg)](http://github.com/badges/stability-badges)[![Build Status](https://travis-ci.org/dingjie/atom-sync.svg?branch=master)](https://travis-ci.org/dingjie/atom-sync)

> This package is currently in early development and has only been tested on Mac. Please kindly [try it out](http://atom.io/packages/atom-sync) and [provide feedback](https://github.com/dingjie/atom-sync/issues/new).

![atom-sync](https://cloud.githubusercontent.com/assets/586262/8085519/2b63a7c4-0fc3-11e5-930a-685b09fe7af3.gif)

### Feature ###
* Sync over ssh+rsync — still [secure](http://www.sakana.fr/blog/2008/05/07/securing-automated-rsync-over-ssh/), but much [faster](http://stackoverflow.com/questions/20244585/what-is-the-difference-between-scp-and-rsync).
* [Multi-Folder Projects](http://blog.atom.io/2015/04/15/multi-folder-projects.html) with different sync config files supported

### Prerequisite ###
* Ensure you have `ssh` and `rsync` installed.

### Quick Start ###
* Open a project folder to sync in [Atom](http://atom.io).
* Right click on the project folder and select `Sync` -> `Edit Remote Config`.
* Edit and save the config file.
* Right click on the project folder and select `Sync` -> `Sync Remote -> Local`.
* Watch water flows.

### Notice ###
* Password based login is not supported—at least yet, you have to [assign your key file](https://www.linode.com/docs/security/use-public-key-authentication-with-ssh) and better host name in .ssh/config in advanced. Try to [Simplify Your Life With an SSH Config File](http://nerderati.com/2011/03/17/simplify-your-life-with-an-ssh-config-file/).

### Config File ###
> .sync-config.cson

```
remote:
    host: "HOSTNAME",       # server name or ip or ssh host abbr in .ssh/config
    user: "USERNAME",       # ssh username
    path: "REMOTE_DIR"      # e.g. /home/someone/somewhere

behaviour:
    uploadOnSave: true      # Upload every time you save a file
    syncDownOnOpen: true    # Download every time you open a file
    forgetConsole: false    # Never show console panel even while syncing
    autoHideConsole: true   # Hide console automatically after 1.5s
    alwaysSyncAll: false    # Sync all files and folders under the project \
                            # instead of syncing single file or folder
option:
    deleteFiles: true       # Delete files during syncing
    exclude: [              # Excluding patterns
        '.sync-config.cson'
        '.git'
        'node_modules'
        'tmp'
        'vendor'
    ]
```

### Keybindings ###
* `ctrl`+`alt`+`l` Toggle log window

### Known Problems ###
* You have to `Sync Local -> Remote` manually after renaming and deleteing files.

### Roadmap ###
* Refactoring
* ConsoleView::clean() and btnClean
* --list-only and confirm dialogue
* Listen to events
  * Create folders
  * Rename files/folders
  * What about deleting?
* SSH parameters in config file e.g. public key, port et al.
