-- HealthTweaks (Cyber Engine Tweaks mod)
-- Entry point: CET loads this file automatically.

local modName = "HealthTweaks"

-- Basic logger wrapper (CET provides `print`)
local function log(msg)
  print(string.format("[%s] %s", modName, tostring(msg)))
end

log("loaded")

-- Optional: require your modules from ./modules
-- local health = require("modules/health")

-- Register callbacks/events as you build the mod.
-- Example (uncomment if you want a tick handler):
-- registerForEvent("onUpdate", function(deltaTime)
-- end)
