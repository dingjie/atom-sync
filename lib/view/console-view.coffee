{$, View} = require 'atom-space-pen-views'

module.exports =
class ConsoleView extends View
    @content: ->
        @div class: 'atom-sync', =>
            @div class: 'header', "Sync Console", =>
                @div class: 'btn_close', title: 'Close', String.fromCharCode(0xf081)
                @div class: 'btn_empty', title: 'Clear sync log', String.fromCharCode(0xf0d0)
            @div class: 'console inset-panel panel-bottom run-command native-key-bindings', tabindex: -1, "Ready"

    initialize: ->
        @find 'div.btn_empty'
            .click (e) =>
                @empty()

    close: (cb) ->
        @find 'div.btn_close'
            .click (e) =>
                cb()

    log: (msg) ->
        div = @find 'div.console'
        div.html @find('div.console').html() + "\n" + msg
        if div[0].scrollHeight > div.height()
            div.scrollTop div[0].scrollHeight - div.height()

    empty: ->
        @find 'div.console'
            .html('')
