----------------------------------------------------------------------------------------------------
--- Define the main StaCo entity prototypes
----------------------------------------------------------------------------------------------------

local util = require('util')

local collision_mask_util = require('collision-mask-util')

local StaCo = require('scripts.staco.staco')

----------------------------------------------------------------------------------------------------

-- Hidden constant combinator for outputting signals to the network
-- Automatically de/constructed along with the stack combinator
local out = util.copy(data.raw['constant-combinator']['constant-combinator'])
out.name = StaCo.Output.NAME
out.minable = nil
out.collision_mask = collision_mask_util.new_mask()
out.selection_box = nil
out.allow_copy_paste = false
out.item_slot_count = Mod.settings:startup().signal_capacity
table.insert(out.flags, 'placeable-off-grid')
table.insert(out.flags, 'not-selectable-in-game')
table.insert(out.flags, 'not-flammable')
Mod.logger:debug('Entity `' .. out.name .. '` defined, signal capacity: ' .. out.item_slot_count)


-- Main combinator
local sc = util.copy(data.raw['arithmetic-combinator']['arithmetic-combinator'])
sc.name = StaCo.NAME
sc.minable.result = StaCo.NAME
-- Prevent other mods overriding AC's localisation from propagating to StaCo
sc.localised_name = nil
sc.localised_description = nil
sc.energy_source.type = Mod.settings:startup().require_power and 'electric' or 'void'

-- Graphics
local display_base = {
    filename = '__stack-combinator__/graphics/entity/combinator/sc-display.png',
    width = 30,
    height = 21,
}

-- The small display window on top of the combinator
local north = util.copy(display_base)
north.scale = sc.and_symbol_sprites.north.scale
north.shift = sc.and_symbol_sprites.north.shift
local east = util.copy(display_base)
east.scale = sc.and_symbol_sprites.east.scale
east.shift = sc.and_symbol_sprites.east.shift
local south = util.copy(display_base)
south.scale = sc.and_symbol_sprites.south.scale
south.shift = sc.and_symbol_sprites.south.shift
local west = util.copy(display_base)
west.scale = sc.and_symbol_sprites.west.scale
west.shift = sc.and_symbol_sprites.west.shift

local display = {
    north = north,
    east = east,
    south = south,
    west = west
}

sc.and_symbol_sprites = display
sc.divide_symbol_sprites = display
sc.left_shift_symbol_sprites = display
sc.minus_symbol_sprites = display
sc.modulo_symbol_sprites = display
sc.multiply_symbol_sprites = display
sc.or_symbol_sprites = display
sc.plus_symbol_sprites = display
sc.power_symbol_sprites = display
sc.right_shift_symbol_sprites = display
sc.xor_symbol_sprites = display

Mod.logger:debug('Entity `' .. sc.name .. '` defined.')

data:extend { sc, out }
