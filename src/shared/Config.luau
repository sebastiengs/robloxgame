-- Placeholder shared module. Safe to delete once your real code is in.
--
-- Files in this folder become ModuleScripts inside ReplicatedStorage,
-- which means BOTH the server and the client can require() them.
-- Good for things like settings, constants, and helper functions.
--
-- Use it from another script like this:
--   local Config = require(game.ReplicatedStorage.Shared.Config)
--   print(Config.GameName)

local Config = {
	GameName = "robloxgame",
	Version = "0.1.0",
}

return Config
