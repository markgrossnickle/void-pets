--!strict
--[=[
	@class PlayerData
	@server
]=]

export type PetData = {
	Type: string,
	Rarity: string,
	Level: number,
	Locked: boolean,
	ObtainedAt: number,
	TradeLockUntil: number,
}

export type TradeRecord = {
	Timestamp: number,
	PartnerId: number,
	PartnerName: string,
	Given: { string },
	Received: { string },
}

export type PlayerData = {
	-- Void Energy
	VoidEnergy: number,
	TotalVoidEnergyEarned: number,

	-- Pets
	Pets: { PetData },
	EquippedPetSlots: { number },

	-- Zones
	UnlockedZones: { [string]: boolean },
	CurrentZone: number,

	-- Rebirth
	RebirthCount: number,

	-- Upgrades
	HasAutoClick: boolean,

	-- Statistics
	TotalClicks: number,
	TotalHatches: number,
	RarestPetRarity: string,

	-- Trading
	TradeHistory: { TradeRecord },

	-- Monetization: processed receipt IDs to prevent double-processing
	ProcessedReceipts: { [string]: boolean },

	-- Daily Login Rewards
	LoginStreak: number,
	LastLoginDate: string,
	LastLoginRewardClaimed: boolean,

	-- Analytics / Session tracking
	FirstJoinDate: string,
	TotalPlayTime: number,
	SessionCount: number,
	LastSessionStart: number,
}

local playerDataTemplate: PlayerData = {
	VoidEnergy = 0,
	TotalVoidEnergyEarned = 0,

	Pets = {},
	EquippedPetSlots = {},

	UnlockedZones = { ["1"] = true },
	CurrentZone = 1,

	RebirthCount = 0,

	HasAutoClick = false,

	TotalClicks = 0,
	TotalHatches = 0,
	RarestPetRarity = "Common",

	TradeHistory = {},

	ProcessedReceipts = {},

	LoginStreak = 0,
	LastLoginDate = "",
	LastLoginRewardClaimed = false,

	FirstJoinDate = "",
	TotalPlayTime = 0,
	SessionCount = 0,
	LastSessionStart = 0,
}

return playerDataTemplate
