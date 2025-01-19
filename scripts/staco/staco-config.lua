--------------------------------------------------------------------------------
--- # A stack combinators configuration
-- Since Factorio doesn't allow arbitrary data attachment to entities, we use
-- the built-in arithmetic combinator's settings to store what we need in order
-- to ensure compatibility with vanilla functions (such as Blueprints).
-- @type StackCombinatorConfig
--------------------------------------------------------------------------------
-- Global imports
local _serpent = serpent
local _table = require('stdlib.utils.table')

local GuiInputOp = require('scripts.gui.gui-input-op')

--- Boolean settings stored as bits in the combinator's second_constant
local Flags = {
    MERGE_INPUTS = 1,
    WAGON_STACKS = 2,
}

---@class StaCoConfig
local StaCoConfig = {
    --- Static combinator that this configuration is for
    sc = nil,

    --- Invert red inputs?
    invert_red = nil,

    --- Invert green inputs?
    invert_green = nil,

    --- Merge inputs before stacking?
    merge_inputs = nil,

    --- Treat wagon capacity as stack size?
    wagon_stacks = nil,

    --- Input operation
    operation = 1,
}

--- Instantiate a configuration object for a stack combinator
-- @param sc StaCo Stack combinator that this configuration is for
-- @return StaCoConfig Created configuration object
function StaCoConfig.create(sc)
    local config = { sc = sc }
    setmetatable(config, { __index = StaCoConfig })
    config:load_or_default()
    return config
end

local op_map_write = {
    '*', -- 1
    '+', -- 2
    '/', -- 3
    'AND', -- 4
    'OR', -- 5
    'XOR', -- 6
}

--- Write SC's configuration
function StaCoConfig:save()
    local r, g = self.invert_red, self.invert_green
    local name = (r and g and 'yellow') or (r and 'red') or (g and 'green') or ('black')
    local signal = { type = 'virtual', name = 'signal-' .. name }

    local flags = 0
    if (self.merge_inputs) then flags = bit32.bor(flags, Flags.MERGE_INPUTS) end
    if (self.wagon_stacks) then flags = bit32.bor(flags, Flags.WAGON_STACKS) end

    local control = self.sc.input.get_or_create_control_behavior()
    control.parameters = {
        first_signal = signal,
        second_constant = flags,
        operation = op_map_write[self.operation]
    }
    self.sc:debug_log('Config: '
        .. 'Invert red: ' .. tostring(self.invert_red) .. ', '
        .. 'Invert green: ' .. tostring(self.invert_green) .. ', '
        .. 'Merge first: ' .. tostring(self.merge_inputs) .. ', '
        .. 'Op: ' .. GuiInputOp.item_names[self.operation] .. ' (' .. self.operation .. '), '
        .. 'Flags: ' .. (control.parameters.second_constant or 'nil') .. '.'
    )
end

local op_map_read = {
    ['*'] = 1,
    ['+'] = 2, -- divide with ceil
    ['/'] = 3, -- divide with floor
    ['AND'] = 4,
    ['OR'] = 5,
    ['XOR'] = 6,
}

local function hasFlag(value, flag)
    return bit32.band(value or 0, flag) == flag
end

--- Read SC's configuration, or create the default if there isn't one
function StaCoConfig:load_or_default()
    local params = self.sc.input.get_control_behavior().parameters

    function params.hasFlag(flag)
        return bit32.band(params.second_constant or 0, flag) == flag
    end

    -- Merge first
    self.merge_inputs = params.hasFlag(Flags.MERGE_INPUTS)
    -- Wagon wagon_stacks
    self.wagon_stacks = params.hasFlag(Flags.WAGON_STACKS)

    -- Input inversion
    local signal = params.first_signal
    if (signal and signal.type == 'virtual') then
        self.invert_red = signal.name == 'signal-red' or signal.name == 'signal-yellow'
        self.invert_green = signal.name == 'signal-green' or signal.name == 'signal-yellow'
    else
        self.sc:debug_log('No valid configuration (signal is ' .. _serpent.line(signal) .. '), resetting to defaults.')
        _table.merge(self, self.defaults())
    end

    -- Operation
    local op = params.operation
    self.operation = op_map_read[op]

    self:save()
    return self
end

function StaCoConfig.defaults()
    local cfg = Mod.settings:runtime()
    return {
        invert_red = cfg.invert_signals == 'red' or cfg.invert_signals == 'both',
        invert_green = cfg.invert_signals == 'green' or cfg.invert_signals == 'both',
        merge_inputs = false,
        wagon_stacks = false,
    }
end

--------------------------------------------------------------------------------
return StaCoConfig
