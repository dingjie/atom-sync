config = require '../helper/config-helper'

module.exports = (opt = {}) ->
    src = opt.src
    dst = opt.dst
    config = opt.config
    success = opt.success
    error = opt.error
    progress = opt.progress

    # progress? JSON.stringify opt, null, 4

    if opt.showError and error
        error "Error!"
    else
        success()
