local util = require('util')

local table = require('stdlib.utils.table')

if (mods['nullius']) then
    log('Nullius mod detected, adjusting tech & recipe accordingly.')

    --- Tech
    local tech = data.raw['technology']['stack-combinator']
    tech.order = 'nullius-' .. (tech.order or 's')
    tech.prerequisites = { 'nullius-computation' }
    tech.unit = util.copy(data.raw['technology']['nullius-computation'].unit)
    -- Use a fraction of the main technology costs to remain balanced
    tech.unit.count = math.ceil(tech.unit.count / 4)
    tech.unit.time = math.ceil(tech.unit.time / 4)

    --- Recipe
    local base = data.raw['recipe']['stack-combinator']
    local recipe = util.copy(data.raw['recipe']['nullius-arithmetic-circuit'])

    recipe.name = base.name
    recipe.results = base.results
    -- Repair pack is too expensive and complicated to manufacture to be considered a
    -- simple tool, so instead we make SC require 4 insulated wires (for wiring up the extra logic).
    recipe.ingredients = {
        { type = 'item', name = 'arithmetic-combinator', amount = 1 },
        { type = 'item', name = 'copper-cable',          amount = 4 }
    }
    -- Basic combinator takes 4 seconds to craft, modifying it should take less time.
    recipe.energy_required = math.ceil(recipe.energy_required / 2)

    --- Item
    local item = data.raw['item']['stack-combinator']
    item.order = 'nullius-f-s'
    -- Remove hidden flag, if set
    item.flags = table.filter(item.flags, function(flag) return not flag == 'hidden' end)

    data:extend { tech, recipe, item }
end
