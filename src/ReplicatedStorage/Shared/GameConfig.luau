--!strict
--[=[
	@class GameConfig
	Shared baseline configuration for runtime-tunable values.
	LiveConfigService reads this as the baseline. Use Cmdr to override at runtime.
]=]

local GameConfig = {
	Player = {
		WalkSpeed = 16,
		JumpPower = 50,
	},
	Click = {
		BaseVEPerClick = 1,
		MaxClicksPerSecond = 20,
		AutoClickMultiplier = 0.5,
	},
	Pets = {
		MaxEquipped = 3,
		MaxEquippedVIP = 6,
		MaxLevel = 10,
		DuplicatesPerLevelUp = 3,
	},
	Eggs = {
		HatchDuration = 3,
		AutoHatchDelay = 0.5,
		TripleHatchCostMultiplier = 2.5,
	},
	Rebirth = {
		MultiplierPerRebirth = 0.5,
		MaxRebirths = 20,
	},
}

return GameConfig
