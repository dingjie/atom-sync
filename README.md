# atom-sync package

atom-sync is an Atom package to sync files between remote host and local over ssh+rsync.

The package is currently in early development and has only been tested on my Mac.

*USE IT AT YOUR OWN RISK.*

![atom-sync](https://cloud.githubusercontent.com/assets/586262/8066587/feedcc68-0f1a-11e5-973e-e6b3668586fb.gif)

### Quick Start ###
* Install atom-sync from where you find it.
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

### Notice ###
* Password based login is not supported, you have to assign your key file and better host name in .ssh/config in advanced. Try [Simplify Your Life With an SSH Config File](http://nerderati.com/2011/03/17/simplify-your-life-with-an-ssh-config-file/).

### Known Problems ###
* You have to `Sync Local -> Remote` manually after renaming and deleteing files.

### Roadmap ###
* Listen to events
  * Create folders
  * Rename files/folders

* SSH parameters in config file e.g. public key assignment, port et al.
