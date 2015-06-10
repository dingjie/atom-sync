# atom-sync package

atom-sync is an Atom package to sync files bidirectionally between remote host and local over ssh+rsync. Inspired by [Sublime SFTP](http://wbond.net/sublime_packages/sftp).

[![experimental](http://badges.github.io/stability-badges/dist/experimental.svg)](http://github.com/badges/stability-badges)[![Build Status](https://travis-ci.org/dingjie/atom-sync.svg?branch=master)](https://travis-ci.org/dingjie/atom-sync)

The package is currently in early development and has only been tested on my Mac. Please try it out and provide feedback.

Please ensure you have `ssh` and `rsync` installed.

![atom-sync](https://cloud.githubusercontent.com/assets/586262/8066587/feedcc68-0f1a-11e5-973e-e6b3668586fb.gif)

### Quick Start ###
* Open a directory you are going to sync in [Atom](http://atom.io).
* Right click on the directory and select `Sync` -> `Edit Remote Config`.
* Edit and save the config file.
* Right click on the directory and select `Sync` -> `Sync Remote -> Local`.
* Watch water flows.

### Config File ###
.sync-config.cson
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

### Shortcut ###
* `ctrl`+`alt`+`l` Toggle log window

### Notice ###
* Password based login is not supported, you have to assign your key file and better host name in .ssh/config in advanced. Try to [Simplify Your Life With an SSH Config File](http://nerderati.com/2011/03/17/simplify-your-life-with-an-ssh-config-file/).

### Known Problems ###
* You have to `Sync Local -> Remote` manually after renaming and deleteing files.

### Roadmap ###
* ConsoleView::clean() and btnClean
* --list-only and confirm dialogue
* Listen to events
  * Create folders
  * Rename files/folders
* SSH parameters in config file e.g. public key assignment, port et al.
