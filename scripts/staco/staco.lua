--------------------------------------------------------------------------------
--- Main stack combinator class
--------------------------------------------------------------------------------

local util = require('util')

---@class StaCo
---@field NAME string
---@field PACKED_NAME string
---@field SEARCH_NAMES string
---@field MATCH_NAMES table<string, boolean>
---@field Output StaCoOutput
---@field Config StaCoConfig
---@field id number?
---@field input LuaEntity?
---@field output LuaEntity?
---@field config StaCoConfig?
local StaCo = {
    --[[ Constants ]]
    NAME = 'stack-combinator',
    PACKED_NAME = 'stack-combinator-packed',
    SEARCH_NAMES = 'stack-combinator',
    MATCH_NAMES = { ['stack-combinator'] = true },

    --[[ Classes ]]
    Output = require('scripts.staco.staco-output'),
    Config = require('scripts.staco.staco-config'),
    --[[ Instance fields ]]
    --- Unique ID for this SC
    id = nil,
    --- The in-game stack-combinator entity
    input = nil,
    --- The in-game stack-combinator-output entity
    output = nil,
    --- SC configuration
    config = nil
}

---@param signal SignalID|SignalFilter
---@return string key
local function create_key(signal)
    local type = signal.type or 'item'
    local quality = signal.quality or 'normal'
    local key = ('%s-%s-%s'):format(type, signal.name, quality)
    return key
end

---@param signal Signal
---@return LogisticFilter
local function signal_to_logistic_filter(signal)
    ---@type LogisticFilter
    local filter = {
        value = {
            type = signal.signal.type or 'item',
            name = signal.signal.name,
            quality = signal.signal.quality or 'normal',
        },
        min = signal.count,
    }

    return filter
end

--- Main combinator logic, process inputs into stackified output
function StaCo:run()
    if not (self.input.valid and self.output.valid) then return end

    local output = self.output.get_control_behavior() --[[@as LuaConstantCombinatorControlBehavior ]]
    assert(output)
    assert(output.sections_count == 1)

    local section = output.sections[1]
    assert(section.type == defines.logistic_section_type.manual)


    if (self.input.status == defines.entity_status.no_power) then
        if (Mod.settings:runtime().empty_unpowered) then
            section.filters = {}
        end
        return
    end

    local red = self.input.get_circuit_network(defines.wire_connector_id.combinator_input_red)
    local green = self.input.get_circuit_network(defines.wire_connector_id.combinator_input_green)

    local op = self.config.operation

    ---@type table<string, LogisticFilter>
    local result = {}

    if (self.config.merge_inputs) then
        ---@type table<string, LogisticFilter>
        local merged = {}
        for _, entry in pairs(red and red.signals or {}) do
            local key = create_key(entry.signal)
            merged[key] = signal_to_logistic_filter(entry)
            merged[key].min = merged[key].min * (self.config.invert_red and -1 or 1)
        end

        for _, entry in pairs(green and green.signals or {}) do
            local key = create_key(entry.signal)
            local value = signal_to_logistic_filter(entry)
            value.min = value.min * (self.config.invert_green and -1 or 1)

            if (merged[key]) then
                merged[key].min = merged[key].min + value.min
            else
                merged[key] = value
            end
        end

        result = self:stackify(merged, false, op, {})
    else
        result = self:stackify(red and red.signals, self.config.invert_red, op, result)
        result = self:stackify(green and green.signals, self.config.invert_green, op, result)
    end

    local total = table_size(result)
    if (This.runtime:signal_overflow(self, total)) then
        --- Not enough signal space
        section.filters = {}
    else
        for _, entry in pairs(result) do
            if (entry.min > (2 ^ 31 - 1)) then
                entry.min = 2 ^ 31 - 1
            elseif (entry.min < -2 ^ 32) then
                entry.min = -2 ^ 32
            end
        end

        local filters = {}

        for _, filter in pairs(result) do
            table.insert(filters, filter)
        end

        section.filters = filters
    end
end

--- Convert circuit network signal values to their stack sizes
---@param input (Signal[])?
---@param invert boolean
---@param operation number
---@param result table<string, LogisticFilter>
---@return  table<string, LogisticFilter>
function StaCo:stackify(input, invert, operation, result)
    if not input then return result or {} end
    local nonItems = Mod.settings:runtime().non_item_signals

    local wagon_stacks = { cargo = nil, fluid = nil }
    if (self.config.wagon_stacks) then
        for _, entry in pairs(input) do
            local entity = prototypes.entity[entry.signal.name]
            if entity and entity.valid then
                local cargo_stacks = entity.type == 'cargo-wagon' and entity.get_inventory_size(defines.inventory.cargo_wagon)
                if (cargo_stacks) then
                    cargo_stacks = cargo_stacks * entry.count
                    wagon_stacks.cargo = cargo_stacks + (wagon_stacks.cargo or 0)
                end

                local fluid_stack = entity.type == 'fluid-wagon' and entity.fluid_capacity
                if (fluid_stack) then
                    fluid_stack = fluid_stack * entry.count
                    wagon_stacks.fluid = fluid_stack + (wagon_stacks.fluid or 0)
                end
            end
        end
    end

    for _, entry in pairs(input) do
        local filter = signal_to_logistic_filter(entry)

        local name = filter.value.name
        assert(name)

        local value = filter.min
        assert(value)
        local type = filter.value.type
        local process = (type == 'item' or nonItems == 'pass' or nonItems == 'invert')
        local entity = prototypes.entity[name]
        if (self.config.wagon_stacks and entity) then
            process = (type == 'fluid' or (entity.type ~= 'cargo-wagon' and entity.type ~= 'fluid-wagon'))
        end
        local multiplier = (invert and (type == 'item' or nonItems == 'invert')) and -1 or 1

        if (process) then
            local stack = (type == 'item' and (prototypes.item[name].stack_size or 1) * (wagon_stacks.cargo or 1)) or 1
            stack = (type == 'fluid' and (wagon_stacks.fluid or 1)) or stack
            local op = operation
            if (op == 1) then
                -- Multiply
                value = value * stack * multiplier
            elseif (op == 2 or op == 3) then
                local func
                if (op == 2 and value >= 0) or (op == 3 and value < 0) then
                    func = math.ceil
                else
                    func = math.floor
                end

                value = func(value / stack) * multiplier
            elseif (op == 4) then
                -- Round
                op = (math.abs(value) % stack > math.ceil(stack / 2)) and 5 or 6
            end

            if (op == 5 or op == 6) then
                local func
                if (op == 5 and value >= 0) or (op == 6 and value < 0) then
                    func = math.ceil
                else
                    func = math.floor
                end

                value = func(value / stack) * stack * multiplier
            end
        end

        local key = create_key(filter.value)

        if (result[key]) then
            result[key].min = result[key].min + value
        else
            if (process) then
                result[key] = filter
                result[key].min = value
            end
        end
    end
    return result
end

--- Create a StackCombinator instance for a placed SC entity
---@param input LuaEntity In-game combinator entity
-- @param output LuaEntity? In-game output combinator entity if one exists
function StaCo.created(input, output)
    if not (input and input.valid and StaCo.MATCH_NAMES[input.name]) then
        error('Tried to configure ' .. input.name .. ' as a stack combinator.')
    end
    if (output and output.valid and not StaCo.Output.MATCH_NAMES[output.name]) then
        error('Tried to configure ' .. output.name .. ' as a stack combinator output.')
    end

    local sc = {}
    setmetatable(sc, { __index = StaCo })
    sc.id = input.unit_number
    sc.input = input

    if (output) then
        sc:debug_log('Output ' .. output.unit_number .. ' already exists, (re)connecting.')
    else
        output = sc.input.surface.find_entity(This.StaCo.Output.determine_name(input), input.position)
        if (output) then
            sc:debug_log('Found existing output (' .. output.unit_number .. '), connecting.')
        else
            output = StaCo.Output.create(sc)
        end
    end

    sc.output = output
    sc:connect()
    sc.config = StaCo.Config.create(sc)
    return sc
end

--- Connect the output combinator to the stack combinator's output
--- so that when player connects to the SC's output (which outputs nothing),
--- the OC's signals are on the same wires.
function StaCo:connect()
    if not (self.input and self.input.valid) then return end
    if not (self.output and self.output.valid) then return end

    local input_connectors = self.input.get_wire_connectors(true)
    local output_connectors = self.output.get_wire_connectors(true)

    input_connectors[defines.wire_connector_id.combinator_output_red].connect_to(output_connectors[defines.wire_connector_id.circuit_red], false)
    input_connectors[defines.wire_connector_id.combinator_output_green].connect_to(output_connectors[defines.wire_connector_id.circuit_green], false)

    self:debug_log('Output connected to input.')
end

function StaCo:moved()
    -- Move output as well
    self:debug_log('Input moved to ' .. serpent.line(self.input.position) .. ', moving output to match.')
    self.output.teleport(self.input.position)
end

--- In-game entity removed
function StaCo:destroyed()
    -- Close GUI for all players
    if (This.gui.staco == self) then
        for _, player in pairs(game.players) do
            This.gui:destroy(player)
        end
    end
    -- Input entity has already been destroyed, we need to remove the output
    self.output.destroy { raise_destroy = false }
    self:debug_log('Output destroyed.')
end

--- Output a combinator-specific debug log message
-- @param message [LocalisedString] Text to output.
function StaCo:debug_log(message)
    Mod.logger:debug('[SC-' .. self.id .. '] ' .. message)
end

--------------------------------------------------------------------------------
return StaCo
