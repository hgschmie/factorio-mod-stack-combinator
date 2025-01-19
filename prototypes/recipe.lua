----------------------------------------------------------------------------------------------------
--- # Recipes for building stack combinators
----------------------------------------------------------------------------------------------------

local util = require('util')

local StaCo = require('scripts.staco.staco')

local recipe = util.copy(data.raw['recipe']['arithmetic-combinator'])

recipe.name = 'stack-combinator'
recipe.enabled = false
recipe.results = { { type = 'item', name = StaCo.NAME, amount = 1, }, }
-- A stack combinator is basically a hacked AC, so the crafting price should reflect that.
recipe.ingredients = {
    { type = 'item', name = 'arithmetic-combinator', amount = 1 },
    { type = 'item', name = 'repair-pack',           amount = 1 }
}
-- Prevent other mods overriding AC's localisation from propagating to StaCo
recipe.localised_name = nil
recipe.localised_description = nil

data:extend { recipe }
