ConsoleView = require '../view/console-view'

module.exports = ConsoleHelper =
    consoleView: null
    bottomPanel: null

    isVisible: ->
        return @bottomPanel?.isVisible()

    show: ->
        if @bottomPanel is null
            @consoleView = new ConsoleView()
            @bottomPanel = atom.workspace.addBottomPanel item: @consoleView.element
            @consoleView.close => @hide()
        else
            @bottomPanel.show()

    hide: ->
        @bottomPanel?.hide()

    log: (msg) ->
        @consoleView?.log msg

    destory: ->
        @consoleView?.destory()
        @bottomPanel?.destory()

    serialize: ->
        @consoleView?.serialize()

    error: (msg) ->
        @log "<span class='error'>#{msg}</span>"

    info: (msg) ->
        @log "<span class='info'>#{msg}</span>"

    warn: (msg) ->
        @log "<span class='warning'>#{msg}</span>"

    success: (msg) ->
        @log "<span class='success'>#{msg}</span>"
