# atom-sync package

The package is currently in early development and has only been tested in Mac, USE IT AT YOUR OWN RISK.

### Quick Guide ###
* Install Atom-sync from where you found it
* Open a directory you are going to sync in [Atom](http://atom.io)
* Right click on the directory and select "Sync" -> "Edit Remote Config"
* Edit and save the config file
* Right click on the directory and select "Sync" -> "Sync Remote -> Local"
* Watch water flows

### Config File ###
```
remote:
    host: "HOSTNAME",  # server name or ip or ssh host in .ssh/config
    user: "USERNAME",  # ssh username
    path: "REMOTE_DIR" # e.g. /home/someone/somewhere
behaviour:
    uploadOnSave: true      # Upload file on save
    syncDownOnOpen: true    # Download file on open
    forgetConsole: false    # Never show console panel
    autoHideConsole: true   # Hide console after 1.5s
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


### Roadmap ###
* Support renaming files
