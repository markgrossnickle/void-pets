--!strict
--[=[
	@class MonetizationConfig
	Shared configuration for GamePasses, Developer Products, and Daily Login Rewards.
	Update these tables with real IDs when forking the template.
]=]

export type GamePassEntry = {
	Id: number,
	Name: string,
}

export type DevProductEntry = {
	Id: number,
	Name: string,
	Handler: string,
}

export type DailyReward = {
	Type: string,
	Currency: string?,
	Amount: number?,
	ItemId: string?,
	Description: string,
}

-- Map pass names to GamePass IDs. Update IDs for your game.
local GamePasses: { [string]: GamePassEntry } = {
	VIP = { Id = 0, Name = "VIP" },
	ExtraEquip = { Id = 0, Name = "Extra Equip Slots" },
	AutoHatchPlus = { Id = 0, Name = "Auto-Hatch Plus" },
	Lucky = { Id = 0, Name = "Lucky" },
	ExclusiveEgg = { Id = 0, Name = "Exclusive Egg Access" },
}

-- Map product names to Developer Product IDs + handler function names.
local DevProducts: { [string]: DevProductEntry } = {
	["1000VE"] = { Id = 0, Name = "1,000 Void Energy", Handler = "_handleVEProduct" },
	["10000VE"] = { Id = 0, Name = "10,000 Void Energy", Handler = "_handleVEProduct" },
	["100000VE"] = { Id = 0, Name = "100,000 Void Energy", Handler = "_handleVEProduct" },
}

-- VE amounts for dev products
local DevProductVEAmounts: { [string]: number } = {
	["1000VE"] = 1000,
	["10000VE"] = 10000,
	["100000VE"] = 100000,
}

-- Daily login rewards (7-day cycle, repeats)
local DailyRewards: { DailyReward } = {
	{ Type = "Currency", Currency = "VoidEnergy", Amount = 500, Description = "500 Void Energy" },
	{ Type = "Currency", Currency = "VoidEnergy", Amount = 1000, Description = "1,000 Void Energy" },
	{ Type = "Currency", Currency = "VoidEnergy", Amount = 2000, Description = "2,000 Void Energy" },
	{ Type = "Currency", Currency = "VoidEnergy", Amount = 3000, Description = "3,000 Void Energy" },
	{ Type = "Currency", Currency = "VoidEnergy", Amount = 5000, Description = "5,000 Void Energy" },
	{ Type = "Currency", Currency = "VoidEnergy", Amount = 8000, Description = "8,000 Void Energy" },
	{ Type = "Currency", Currency = "VoidEnergy", Amount = 15000, Description = "15,000 Void Energy" },
}

-- Premium membership multiplier for currency earnings
local PremiumMultiplier = 1.5

return {
	GamePasses = GamePasses,
	DevProducts = DevProducts,
	DevProductVEAmounts = DevProductVEAmounts,
	DailyRewards = DailyRewards,
	PremiumMultiplier = PremiumMultiplier,
}
