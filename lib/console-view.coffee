{$, View} = require 'atom-space-pen-views'

module.exports =
class ConsoleView extends View
    @content: ->
        @div class: 'atom-sync', =>
            @div class: 'header', "Sync Console", =>
                @div class: 'btn_close', 'x'
            @div class: 'console', "Ready"

    close: (cb) ->
        @find 'div.btn_close'
            .click (e) =>
                cb()

    log: (msg) ->
        div = @find 'div.console'
        div.html @find('div.console').html() + "\n" + msg
        if div[0].scrollHeight > div.height()
            div.scrollTop div[0].scrollHeight - div.height()
