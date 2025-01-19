local runtime = require("framework/runtime")

----------------------------------------------------------------------------------------------------

--- Mod object access point
-- The main global singleton in the mod, defines globally used data and provides access to all
-- other components.
local Mod = {
  --- The non-localised name (textual ID) of this mod, used in filenames, localisation keys etc.
  -- Must be set as the earliest possible time, as virtually all other framework parts use this.
  NAME = nil,

  --- Name of the field in `storage` to store framework persistent runtime data.
  STORAGE = "framework",

  --- @see Settings
  settings = nil,

  --- @see Logger
  logger = nil,

  --- @see Runtime
  runtime = nil,
}

function Mod:init(mod_name)
  if (not mod_name or mod_name == "") then
    error("Can't initialize mod without a name.")
  end
  self.NAME = mod_name
  self.settings = require("framework/settings")
  self.logger = require("framework/logger")
  if (script) then
    self.runtime = runtime
    require("framework/event-setup"):register_all()
  end
end

---------------------------------------------------------------------------------------------------

return Mod
