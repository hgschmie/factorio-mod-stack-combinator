----------------------------------------------------------------------------------------------------
--- Output (signals)
----------------------------------------------------------------------------------------------------

---@class staco.GuiOutput
---@field filter_table LuaGuiElement?
local GuiOutput = {
    filter_table = nil
}

---@param filter LogisticFilter
---@return string
local function logistic_filter_to_sprite_name(filter)
    assert(filter)

    local filter_type = filter.value.type or 'item'                                  -- see https://lua-api.factorio.com/latest/concepts/SignalID.html
    local sprite_type = filter_type == 'virtual' and 'virtual-signal' or filter_type -- see https://lua-api.factorio.com/latest/concepts/SpritePath.html

    return ('%s/%s'):format(sprite_type, filter.value.name)
end

---@param filter LogisticFilter
---@return LuaPrototypeBase
local function logistic_filter_to_prototype(filter)
    assert(filter)

    local filter_type = filter.value.type or 'item'                           -- see https://lua-api.factorio.com/latest/concepts/SignalID.html
    local type = filter_type == 'virtual' and 'virtual_signal' or filter_type -- see https://lua-api.factorio.com/latest/classes/LuaPrototypes.html

    assert(prototypes[type], ("prototype [%s] does not exist"):format(type))
    assert(prototypes[type][filter.value.name], ("prototype [%s][%s] does not exist"):format(type, filter.value.name))
    return prototypes[type][filter.value.name]
end

---@param filter LogisticFilter
---@return ElemID
local function logistic_filter_to_elem_id(filter)
    assert(filter)

    local filter_type = filter.value.type or 'item'                          -- see https://lua-api.factorio.com/latest/concepts/SignalID.html

    ---@type ElemID
    local result = {
        type = filter_type,
        name = filter.value.name,
    }

    if filter_type == 'virtual' then
        result.type = 'signal'
        result.signal_type = filter_type
    elseif filter.value.quality then
        result.type = result.type .. '-with-quality'
        result.quality = tostring(filter.value.quality)
    end

    return result
end

function GuiOutput:tick(sc)
    if not (self.filter_table) then return end
    self.filter_table.clear()

    local output = sc.output.get_control_behavior() --[[@as LuaConstantCombinatorControlBehavior ]]
    assert(output)
    assert(output.sections_count == 1)

    local section = output.sections[1]
    assert(section.type == defines.logistic_section_type.manual)

    local filters = section.filters

    if not (filters) then return end

    for _, filter in pairs(filters) do
        if filter.value.name then
            self.filter_table.add {
                type = 'sprite-button',
                style = 'compact_slot',
                number = filter.min,
                sprite = logistic_filter_to_sprite_name(filter),
                tooltip = logistic_filter_to_prototype(filter).localised_name,
                elem_tooltip = logistic_filter_to_elem_id(filter),
                --enabled = false
            }
        end
    end
end

---@param parent LuaGuiElement
function GuiOutput:create(parent)
    parent.add {
        type = 'label',
        -- Built-in localisation
        caption = { '', { 'gui-constant.output-signals' }, ' [img=info]' },
        tooltip = { 'gui.output-signals-description' },
        style = 'heading_2_label'
    }

    local scroll_pane = parent.add {
        type = 'scroll-pane',
        style = 'naked_scroll_pane',
        vertical_scroll_policy = 'never',
        horizontal_scroll_policy = 'auto-and-reserve-space',
    }
    scroll_pane.style.margin = 0
    scroll_pane.style.horizontally_stretchable = true

    local flow = scroll_pane.add {
        type = 'flow',
        direction = 'horizontal'
    }
    flow.style.horizontal_align = 'center'
    flow.style.horizontally_stretchable = true
    flow.style.horizontally_squashable = true

    self.filter_table = flow.add {
        type = 'table',
        style = 'slot_table',
        column_count = Mod.settings:startup().signal_capacity
    }
    flow.style.horizontally_squashable = true
end

return GuiOutput
