{$, View} = require 'atom-space-pen-views'

module.exports =
class ConsoleView extends View
    @content: ->
        @div class: 'atom-sync', =>
            @div class: 'header', "Sync Console"
            @div class: 'console', "Ready"

    log: (msg) ->
        div = @find 'div.console'
        div.text @find('div.console').text() + "\n" + msg
        if div[0].scrollHeight > div.height()
            div.scrollTop div[0].scrollHeight - div.height()
