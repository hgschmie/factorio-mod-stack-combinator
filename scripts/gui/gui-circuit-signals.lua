----------------------------------------------------------------------------------------------------
--- GUI elements showing signals on the circuit networks
----------------------------------------------------------------------------------------------------

---@class staco.GuiCircuitSignals
---@field red LuaGuiElement?
---@field green LuaGuiElement?
---@field input boolean
local GuiCircuitSignals = {
    red = nil,
    green = nil,
    input = false,
}

---@param signal Signal
---@return string
local function signal_to_sprite_name(signal)
    assert(signal)

    local signal_type = signal.signal.type or 'item'                                 -- see https://lua-api.factorio.com/latest/concepts/SignalID.html
    local sprite_type = signal_type == 'virtual' and 'virtual-signal' or signal_type -- see https://lua-api.factorio.com/latest/concepts/SpritePath.html

    return ('%s/%s'):format(sprite_type, signal.signal.name)
end

---@param signal Signal
---@return LuaPrototypeBase
local function signal_to_prototype(signal)
    assert(signal)

    local signal_type = signal.signal.type or 'item'                          -- see https://lua-api.factorio.com/latest/concepts/SignalID.html
    local type = signal_type == 'virtual' and 'virtual_signal' or signal_type -- see https://lua-api.factorio.com/latest/classes/LuaPrototypes.html

    assert(prototypes[type], ('prototype [%s] does not exist'):format(type))
    assert(prototypes[type][signal.signal.name], ('prototype [%s][%s] does not exist'):format(type, signal.signal.name))
    return prototypes[type][signal.signal.name]
end

---@param signal Signal
---@return ElemID
local function signal_to_elem_id(signal)
    assert(signal)
    local signal_type = signal.signal.type or 'item'                          -- see https://lua-api.factorio.com/latest/concepts/SignalID.html

    ---@type ElemID
    local result = {
        type = signal_type,
        name = signal.signal.name,
    }

    if signal_type == 'virtual' then
        result.type = 'signal'
        result.signal_type = signal_type
    elseif signal.signal.quality then
        result.type = result.type .. '-with-quality'
        result.quality = tostring(signal.signal.quality)
    end

    return result
end

function GuiCircuitSignals:tick(sc)
    for _, color in ipairs { 'red', 'green' } do
        local gui_element = self[color] --[[@as LuaGuiElement ]]
        assert(gui_element)
        gui_element.clear()

        local connector_id = self.input
            and defines.wire_connector_id['combinator_input_' .. color]
            or defines.wire_connector_id['circuit_' .. color]

        local control = (self.input and sc.input or sc.output).get_control_behavior() --[[@as LuaControlBehavior]]
        assert(control)
        local network = control.get_circuit_network(connector_id)

        -- If the wires between input & output have been cut, restore them.
        if not self.input and not network then
            sc:connect()
            network = control.get_circuit_network(connector_id)
        end

        if network then
            for _, signal in ipairs(network.signals or {}) do
                gui_element.add {
                    type = 'sprite-button',
                    sprite = signal_to_sprite_name(signal),
                    number = signal.count,
                    style = color .. '_circuit_network_content_slot',
                    tooltip = signal_to_prototype(signal).localised_name,
                    elem_tooltip = signal_to_elem_id(signal),
                }
            end
        end
    end
end

---@param input boolean
---@param parent LuaGuiElement
function GuiCircuitSignals:create(input, parent)
    self.input = input
    local key = input and 'input' or 'output'

    parent.add {
        type = 'label',
        style = 'heading_2_label',
        caption = { '', { 'gui.' .. key .. '-networks' }, ' [img=info]' },
        tooltip = { 'gui.' .. key .. '-networks-description' }
    }

    local table = parent.add {
        type = 'table',
        column_count = 2,
        tooltip = { 'gui.' .. key .. '-networks-description' }
    }

    table.style.column_alignments[1] = 'left'
    table.style.column_alignments[2] = 'right'

    local spacing = 36 / 4
    for _, color in ipairs { 'red', 'green' } do
        local block = table.add {
            type = 'flow',
            direction = 'horizontal',
            maximum_horizontal_squash_size = 0,
        }

        block.style.horizontally_stretchable = true
        block.style.horizontal_align = color == 'red' and 'left' or 'right'
        block.style.margin = { 0, (color == 'red' and spacing or 0), 0, (color == 'green' and spacing or 0) }
        block.style.width = 36 * 7

        local scroll = block.add {
            type = 'scroll-pane',
            style = 'naked_scroll_pane',
            vertical_scroll_policy = 'never',
            horizontal_scroll_policy = 'auto-and-reserve-space',
        }
        scroll.style.margin = 0
        scroll.style.padding = 0

        self[color] = scroll.add {
            type = 'table',
            style = 'slot_table',
            vertical_centering = false,
            column_count = Mod.settings:startup().signal_capacity,
        }
        self[color].style.horizontally_squashable = true
    end
end

----------------------------------------------------------------------------------------------------

return GuiCircuitSignals
