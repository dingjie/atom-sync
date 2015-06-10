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
