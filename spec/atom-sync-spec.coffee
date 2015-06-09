AtomSync = require '../lib/atom-sync'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "AtomSync", ->
  [workspaceElement, activationPromise] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('atom-sync')

  describe "when the atom-sync:toggle-log-panel event is triggered", ->
    it "hides and shows the log panel", ->
      # Before the activation event the view is not on the DOM, and no panel
      # has been created
      expect(workspaceElement.querySelector('.atom-sync')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.commands.dispatch workspaceElement, 'atom-sync:toggle-log-panel'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(workspaceElement.querySelector('.atom-sync')).toExist()

        atomSyncElement = workspaceElement.querySelector('.atom-sync')
        expect(atomSyncElement).toExist()

        atomSyncPanel = atom.workspace.panelForItem(atomSyncElement)
        expect(atomSyncPanel.isVisible()).toBe true
        atom.commands.dispatch workspaceElement, 'atom-sync:toggle-log-panel'
        expect(atomSyncPanel.isVisible()).toBe false
        
