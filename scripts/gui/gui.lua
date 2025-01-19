--------------------------------------------------------------------------------
--- # GUI layout: the main StaCo config window and all its contents
--------------------------------------------------------------------------------

local Gui = {
    NAME = This.StaCo.NAME .. '-gui',

    --- Static combinator that this GUI is opened for
    staco = nil,

    elements = {
        window = nil,
        title_bar = require('scripts.gui.gui-title-bar'),
        status = require('scripts.gui.gui-status-label'),
        preview = require('scripts.gui.gui-preview'),
        input = require('scripts.gui.gui-input'),
        input_op = require('scripts.gui.gui-input-op'),
        output = require('scripts.gui.gui-output'),
        input_network = {},
        output_network = {},
    }
}
local GuiSignalDisplay = require('scripts.gui.gui-circuit-signals')
setmetatable(Gui.elements.input_network, { __index = GuiSignalDisplay })
setmetatable(Gui.elements.output_network, { __index = GuiSignalDisplay })

Gui.CLOSE_BUTTON_NAME = Gui.NAME .. '-close'
Gui.INVERT_RED_NAME = Gui.NAME .. '-invert-red'
Gui.INVERT_GREEN_NAME = Gui.NAME .. '-invert-green'
Gui.MERGE_INPUTS = Gui.NAME .. '-merge-first'
Gui.INPUT_WAGON_STACKS_NAME = Gui.NAME .. '-wagon-stacks'
Gui.INPUT_OP_NAME = Gui.NAME .. '-input-op'
Gui.INPUT_OP_DESC = Gui.NAME .. '-input-op-description'

function Gui:tick()
    self.elements.status:tick(self.staco)
    self.elements.output:tick(self.staco)
    self.elements.input_network:tick(self.staco)
    self.elements.output_network:tick(self.staco)
end

--- Create and show the the GUI
---@param sc StaCo
---@param player LuaPlayer
function Gui:create(sc, player)
    -- player.opened = sc.input
    -- if true then return end

    local window = player.gui.screen.add {
        type = 'frame',
        direction = 'vertical',
        name = Gui.NAME,
    }

    -- Title bar
    self.elements.window = window
    self.elements.title_bar:create(sc, window)
    self.elements.title_bar.close_button.name = self.CLOSE_BUTTON_NAME

    -- Main content
    local contents = window.add {
        type = 'frame',
        style = 'entity_frame',
        direction = 'vertical',
    }

    -- Status indicator & entity preview
    self.elements.status:create(sc, contents)
    self.elements.preview:create(sc, contents)

    -- Input signals
    self.elements.input_network:create(true, contents)

    -- Configuration start
    contents.add { type = 'line' }

    contents.add {
        type = 'label',
        style = 'heading_2_label',
        caption = { '', { 'gui.config' } },
    }

    self.elements.input:create(sc, contents)
    self.elements.input.red.name = self.INVERT_RED_NAME
    self.elements.input.green.name = self.INVERT_GREEN_NAME
    self.elements.input.merge_inputs.name = self.MERGE_INPUTS
    self.elements.input.wagon_stacks.name = self.INPUT_WAGON_STACKS_NAME

    -- Operation
    self.elements.input_op:create(sc, contents)
    self.elements.input_op.selector.name = self.INPUT_OP_NAME
    self.elements.input_op.description.name = self.INPUT_OP_DESC

    contents.add { type = 'line' }
    -- Configuration end

    -- Output signals
    self.elements.output:create(contents)
    self.elements.output_network:create(false, contents)

    player.opened = window

    -- Keep for reference
    self.staco = sc
    self:tick()

    -- Data on which players have our GUI open is not saved with the game, so we have to store it manually
    storage.open_sc_ids = storage.open_sc_ids or {}
    storage.open_sc_ids[player.index] = sc.id

    window.force_auto_center()
    return window
end

--- Destroy the GUI
function Gui:destroy(player)
    -- Since only one combinator GUI is supposed to be open at a time, we don't
    -- need to store any specific references; just remove everything that's ours.
    for _, g in ipairs(player.gui.screen.children) do
        if g.name == Gui.NAME then
            player.opened = nil
            storage.open_sc_ids[player.index] = nil
            This.gui.staco = nil
            g.destroy()
        end
    end
end

--------------------------------------------------------------------------------
return Gui
