--!strict
--[=[
	@class VoidPetsConfig
	All constants, pet definitions, egg tables, zone costs, and rarity data for Void Pets.
]=]

export type Rarity = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythic"

export type RarityInfo = {
	Color: Color3,
	Chance: number,
	Multiplier: number,
	SortOrder: number,
}

export type PetDefinition = {
	Name: string,
	Type: string,
	Zone: number,
	Shape: string,
	Description: string,
}

export type EggDefinition = {
	Name: string,
	Cost: number,
	Zone: number,
	Tier: string,
	RarityBoost: number,
}

export type ZoneDefinition = {
	Name: string,
	UnlockCost: number,
	Theme: string,
	ZoneMultiplier: number,
	AmbientColor: Color3,
	AccentColor: Color3,
}

-- ============================================================================
-- Rarities
-- ============================================================================

local Rarities: { [Rarity]: RarityInfo } = {
	Common = { Color = Color3.fromRGB(220, 220, 220), Chance = 0.60, Multiplier = 1.5, SortOrder = 1 },
	Uncommon = { Color = Color3.fromRGB(80, 200, 80), Chance = 0.25, Multiplier = 2.5, SortOrder = 2 },
	Rare = { Color = Color3.fromRGB(60, 120, 255), Chance = 0.10, Multiplier = 5, SortOrder = 3 },
	Epic = { Color = Color3.fromRGB(160, 60, 220), Chance = 0.04, Multiplier = 12, SortOrder = 4 },
	Legendary = { Color = Color3.fromRGB(255, 200, 40), Chance = 0.009, Multiplier = 30, SortOrder = 5 },
	Mythic = { Color = Color3.fromRGB(255, 100, 200), Chance = 0.001, Multiplier = 100, SortOrder = 6 },
}

local RarityOrder: { Rarity } = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" }

-- ============================================================================
-- Pet Definitions (45 total)
-- ============================================================================

local Pets: { [string]: PetDefinition } = {
	-- Zone 1: Void Nursery
	VoidPup = {
		Name = "Void Pup",
		Type = "VoidPup",
		Zone = 1,
		Shape = "Sphere",
		Description = "A small blob of void energy",
	},
	ShadowKitten = {
		Name = "Shadow Kitten",
		Type = "ShadowKitten",
		Zone = 1,
		Shape = "Cube",
		Description = "A kitten made of shadows",
	},
	VoidBunny = {
		Name = "Void Bunny",
		Type = "VoidBunny",
		Zone = 1,
		Shape = "Sphere",
		Description = "Hops through the void",
	},
	DarkHatchling = {
		Name = "Dark Hatchling",
		Type = "DarkHatchling",
		Zone = 1,
		Shape = "Sphere",
		Description = "Just hatched from darkness",
	},
	MiniShade = {
		Name = "Mini Shade",
		Type = "MiniShade",
		Zone = 1,
		Shape = "Cube",
		Description = "A tiny shadow creature",
	},
	VoidSlime = { Name = "Void Slime", Type = "VoidSlime", Zone = 1, Shape = "Sphere", Description = "Jiggly void goo" },

	-- Zone 2: Crystal Cavern
	CrystalFox = {
		Name = "Crystal Fox",
		Type = "CrystalFox",
		Zone = 2,
		Shape = "Cube",
		Description = "A fox of living crystal",
	},
	GemBeetle = {
		Name = "Gem Beetle",
		Type = "GemBeetle",
		Zone = 2,
		Shape = "Sphere",
		Description = "Shell glitters with gems",
	},
	PrismBird = {
		Name = "Prism Bird",
		Type = "PrismBird",
		Zone = 2,
		Shape = "Sphere",
		Description = "Refracts light beautifully",
	},
	ShardSerpent = {
		Name = "Shard Serpent",
		Type = "ShardSerpent",
		Zone = 2,
		Shape = "Cube",
		Description = "Scales made of crystal shards",
	},
	CrystalGolem = {
		Name = "Crystal Golem",
		Type = "CrystalGolem",
		Zone = 2,
		Shape = "Cube",
		Description = "A tiny golem of pure crystal",
	},
	DiamondMoth = {
		Name = "Diamond Moth",
		Type = "DiamondMoth",
		Zone = 2,
		Shape = "Sphere",
		Description = "Wings sparkle like diamonds",
	},

	-- Zone 3: Fungal Garden
	SporeSprite = {
		Name = "Spore Sprite",
		Type = "SporeSprite",
		Zone = 3,
		Shape = "Sphere",
		Description = "Releases glowing spores",
	},
	MushroomFrog = {
		Name = "Mushroom Frog",
		Type = "MushroomFrog",
		Zone = 3,
		Shape = "Sphere",
		Description = "Has a mushroom cap hat",
	},
	MyceliumCat = {
		Name = "Mycelium Cat",
		Type = "MyceliumCat",
		Zone = 3,
		Shape = "Cube",
		Description = "Connected to the fungal network",
	},
	BiolumiFish = {
		Name = "Biolumi Fish",
		Type = "BiolumiFish",
		Zone = 3,
		Shape = "Sphere",
		Description = "Glows in the dark",
	},
	FungalOwl = {
		Name = "Fungal Owl",
		Type = "FungalOwl",
		Zone = 3,
		Shape = "Cube",
		Description = "Wise and bioluminescent",
	},
	BloomBear = {
		Name = "Bloom Bear",
		Type = "BloomBear",
		Zone = 3,
		Shape = "Cube",
		Description = "Flowers bloom where it walks",
	},

	-- Zone 4: Abyssal Depths
	DeepAngler = {
		Name = "Deep Angler",
		Type = "DeepAngler",
		Zone = 4,
		Shape = "Sphere",
		Description = "Lures you with its glow",
	},
	VoidJellyfish = {
		Name = "Void Jellyfish",
		Type = "VoidJellyfish",
		Zone = 4,
		Shape = "Sphere",
		Description = "Translucent void creature",
	},
	AbyssCrab = {
		Name = "Abyss Crab",
		Type = "AbyssCrab",
		Zone = 4,
		Shape = "Cube",
		Description = "Armored in dark shell",
	},
	ShadowEel = {
		Name = "Shadow Eel",
		Type = "ShadowEel",
		Zone = 4,
		Shape = "Sphere",
		Description = "Slithers through darkness",
	},
	DarkStarfish = {
		Name = "Dark Starfish",
		Type = "DarkStarfish",
		Zone = 4,
		Shape = "Sphere",
		Description = "Five arms of shadow",
	},
	LeviathanPup = {
		Name = "Leviathan Pup",
		Type = "LeviathanPup",
		Zone = 4,
		Shape = "Cube",
		Description = "Baby sea monster",
	},

	-- Zone 5: Cosmic Realm
	StarKitten = {
		Name = "Star Kitten",
		Type = "StarKitten",
		Zone = 5,
		Shape = "Sphere",
		Description = "Made of starlight",
	},
	NebulaFox = {
		Name = "Nebula Fox",
		Type = "NebulaFox",
		Zone = 5,
		Shape = "Cube",
		Description = "Fur swirls like a nebula",
	},
	CometBunny = {
		Name = "Comet Bunny",
		Type = "CometBunny",
		Zone = 5,
		Shape = "Sphere",
		Description = "Leaves a trail of stardust",
	},
	GalaxySerpent = {
		Name = "Galaxy Serpent",
		Type = "GalaxySerpent",
		Zone = 5,
		Shape = "Cube",
		Description = "Contains galaxies within",
	},
	NovaBird = {
		Name = "Nova Bird",
		Type = "NovaBird",
		Zone = 5,
		Shape = "Sphere",
		Description = "Explodes with stellar light",
	},
	AstralDragon = {
		Name = "Astral Dragon",
		Type = "AstralDragon",
		Zone = 5,
		Shape = "Cube",
		Description = "Breathes cosmic fire",
	},

	-- Zone 6: Chaos Dimension
	GlitchCat = {
		Name = "Glitch Cat",
		Type = "GlitchCat",
		Zone = 6,
		Shape = "Cube",
		Description = "Flickers in and out of reality",
	},
	ParadoxPup = {
		Name = "Paradox Pup",
		Type = "ParadoxPup",
		Zone = 6,
		Shape = "Sphere",
		Description = "Exists in two places at once",
	},
	EntropySlime = {
		Name = "Entropy Slime",
		Type = "EntropySlime",
		Zone = 6,
		Shape = "Sphere",
		Description = "Dissolves order itself",
	},
	ChaosPhoenix = {
		Name = "Chaos Phoenix",
		Type = "ChaosPhoenix",
		Zone = 6,
		Shape = "Sphere",
		Description = "Reborn from chaos",
	},
	RiftBear = {
		Name = "Rift Bear",
		Type = "RiftBear",
		Zone = 6,
		Shape = "Cube",
		Description = "Tears open dimensional rifts",
	},
	VoidTitan = {
		Name = "Void Titan",
		Type = "VoidTitan",
		Zone = 6,
		Shape = "Cube",
		Description = "Ancient void entity",
	},

	-- Special: Golden variants
	GoldenVoidPup = {
		Name = "Golden Void Pup",
		Type = "GoldenVoidPup",
		Zone = 0,
		Shape = "Sphere",
		Description = "A rare golden blob",
	},
	GoldenCrystalFox = {
		Name = "Golden Crystal Fox",
		Type = "GoldenCrystalFox",
		Zone = 0,
		Shape = "Cube",
		Description = "Pure gold crystal fox",
	},
	GoldenAstralDragon = {
		Name = "Golden Astral Dragon",
		Type = "GoldenAstralDragon",
		Zone = 0,
		Shape = "Cube",
		Description = "Legendary golden dragon",
	},

	-- Special: Exclusive
	VoidEmperor = {
		Name = "Void Emperor",
		Type = "VoidEmperor",
		Zone = 0,
		Shape = "Cube",
		Description = "Ruler of the void",
	},
	CosmicOverlord = {
		Name = "Cosmic Overlord",
		Type = "CosmicOverlord",
		Zone = 0,
		Shape = "Cube",
		Description = "Master of the cosmos",
	},
	ChaosArchon = {
		Name = "Chaos Archon",
		Type = "ChaosArchon",
		Zone = 0,
		Shape = "Cube",
		Description = "Supreme chaos entity",
	},
}

-- Pets available per zone (by type key)
local ZonePets: { [number]: { string } } = {
	[1] = { "VoidPup", "ShadowKitten", "VoidBunny", "DarkHatchling", "MiniShade", "VoidSlime" },
	[2] = { "CrystalFox", "GemBeetle", "PrismBird", "ShardSerpent", "CrystalGolem", "DiamondMoth" },
	[3] = { "SporeSprite", "MushroomFrog", "MyceliumCat", "BiolumiFish", "FungalOwl", "BloomBear" },
	[4] = { "DeepAngler", "VoidJellyfish", "AbyssCrab", "ShadowEel", "DarkStarfish", "LeviathanPup" },
	[5] = { "StarKitten", "NebulaFox", "CometBunny", "GalaxySerpent", "NovaBird", "AstralDragon" },
	[6] = { "GlitchCat", "ParadoxPup", "EntropySlime", "ChaosPhoenix", "RiftBear", "VoidTitan" },
}

-- Golden pet mapping: base type -> golden type
local GoldenVariants: { [string]: string } = {
	VoidPup = "GoldenVoidPup",
	CrystalFox = "GoldenCrystalFox",
	AstralDragon = "GoldenAstralDragon",
}

-- Exclusive pets (Robux egg or trading only)
local ExclusivePets: { string } = { "VoidEmperor", "CosmicOverlord", "ChaosArchon" }

-- ============================================================================
-- Zones
-- ============================================================================

local Zones: { [number]: ZoneDefinition } = {
	[1] = {
		Name = "Void Nursery",
		UnlockCost = 0,
		Theme = "Void",
		ZoneMultiplier = 1,
		AmbientColor = Color3.fromRGB(40, 10, 60),
		AccentColor = Color3.fromRGB(160, 60, 220),
	},
	[2] = {
		Name = "Crystal Cavern",
		UnlockCost = 10000,
		Theme = "Crystal",
		ZoneMultiplier = 1.5,
		AmbientColor = Color3.fromRGB(10, 30, 60),
		AccentColor = Color3.fromRGB(60, 200, 255),
	},
	[3] = {
		Name = "Fungal Garden",
		UnlockCost = 500000,
		Theme = "Fungal",
		ZoneMultiplier = 2,
		AmbientColor = Color3.fromRGB(10, 40, 30),
		AccentColor = Color3.fromRGB(60, 255, 180),
	},
	[4] = {
		Name = "Abyssal Depths",
		UnlockCost = 20000000,
		Theme = "Abyss",
		ZoneMultiplier = 3,
		AmbientColor = Color3.fromRGB(5, 10, 40),
		AccentColor = Color3.fromRGB(40, 80, 200),
	},
	[5] = {
		Name = "Cosmic Realm",
		UnlockCost = 1000000000,
		Theme = "Cosmic",
		ZoneMultiplier = 5,
		AmbientColor = Color3.fromRGB(10, 5, 30),
		AccentColor = Color3.fromRGB(200, 150, 255),
	},
	[6] = {
		Name = "Chaos Dimension",
		UnlockCost = 50000000000,
		Theme = "Chaos",
		ZoneMultiplier = 8,
		AmbientColor = Color3.fromRGB(30, 5, 5),
		AccentColor = Color3.fromRGB(255, 50, 80),
	},
}

-- ============================================================================
-- Eggs
-- ============================================================================

local Eggs: { [string]: EggDefinition } = {
	-- Zone 1
	BasicEgg1 = { Name = "Void Egg", Cost = 100, Zone = 1, Tier = "Basic", RarityBoost = 0 },
	PremiumEgg1 = { Name = "Premium Void Egg", Cost = 1000, Zone = 1, Tier = "Premium", RarityBoost = 1 },
	GoldenEgg1 = { Name = "Golden Void Egg", Cost = 10000, Zone = 1, Tier = "Golden", RarityBoost = 2 },
	-- Zone 2
	BasicEgg2 = { Name = "Crystal Egg", Cost = 5000, Zone = 2, Tier = "Basic", RarityBoost = 0 },
	PremiumEgg2 = { Name = "Premium Crystal Egg", Cost = 50000, Zone = 2, Tier = "Premium", RarityBoost = 1 },
	GoldenEgg2 = { Name = "Golden Crystal Egg", Cost = 500000, Zone = 2, Tier = "Golden", RarityBoost = 2 },
	-- Zone 3
	BasicEgg3 = { Name = "Fungal Egg", Cost = 250000, Zone = 3, Tier = "Basic", RarityBoost = 0 },
	PremiumEgg3 = { Name = "Premium Fungal Egg", Cost = 2500000, Zone = 3, Tier = "Premium", RarityBoost = 1 },
	GoldenEgg3 = { Name = "Golden Fungal Egg", Cost = 25000000, Zone = 3, Tier = "Golden", RarityBoost = 2 },
	-- Zone 4
	BasicEgg4 = { Name = "Abyss Egg", Cost = 10000000, Zone = 4, Tier = "Basic", RarityBoost = 0 },
	PremiumEgg4 = { Name = "Premium Abyss Egg", Cost = 100000000, Zone = 4, Tier = "Premium", RarityBoost = 1 },
	GoldenEgg4 = { Name = "Golden Abyss Egg", Cost = 1000000000, Zone = 4, Tier = "Golden", RarityBoost = 2 },
	-- Zone 5
	BasicEgg5 = { Name = "Cosmic Egg", Cost = 500000000, Zone = 5, Tier = "Basic", RarityBoost = 0 },
	PremiumEgg5 = { Name = "Premium Cosmic Egg", Cost = 5000000000, Zone = 5, Tier = "Premium", RarityBoost = 1 },
	GoldenEgg5 = { Name = "Golden Cosmic Egg", Cost = 50000000000, Zone = 5, Tier = "Golden", RarityBoost = 2 },
	-- Zone 6
	BasicEgg6 = { Name = "Chaos Egg", Cost = 25000000000, Zone = 6, Tier = "Basic", RarityBoost = 0 },
	PremiumEgg6 = { Name = "Premium Chaos Egg", Cost = 250000000000, Zone = 6, Tier = "Premium", RarityBoost = 1 },
	GoldenEgg6 = { Name = "Golden Chaos Egg", Cost = 2500000000000, Zone = 6, Tier = "Golden", RarityBoost = 2 },
}

-- ============================================================================
-- Gameplay Constants
-- ============================================================================

local Click = {
	BaseVEPerClick = 1,
	MaxClicksPerSecond = 20,
	AutoClickRate = 0.5, -- 50% of manual rate
	ComboWindow = 0.5, -- seconds between clicks to maintain combo
	MaxCombo = 10,
}

local PetConfig = {
	MaxEquipped = 3,
	MaxEquippedVIP = 6,
	MaxLevel = 10,
	LevelUpMultiplierBonus = 0.10, -- +10% per level
	DuplicatesPerLevelUp = 3,
	OrbitRadius = 3,
	BobSpeed = 2,
	BobHeight = 0.5,
	TradeLockDuration = 86400, -- 24 hours in seconds
}

local Rebirth = {
	MinZone = 4, -- Must reach zone 4 to rebirth
	MultiplierPerRebirth = 0.50, -- +50% per rebirth (multiplicative)
	MaxRebirths = 20,
	-- VE thresholds for each rebirth (total VE earned)
	Thresholds = {
		20000000, -- 20M
		50000000, -- 50M
		200000000, -- 200M
		1000000000, -- 1B
		5000000000, -- 5B
		20000000000, -- 20B
		100000000000, -- 100B
		500000000000, -- 500B
		2000000000000, -- 2T
		10000000000000, -- 10T
		50000000000000, -- 50T
		200000000000000, -- 200T
		1000000000000000, -- 1Qa
		5000000000000000, -- 5Qa
		20000000000000000, -- 20Qa
		100000000000000000, -- 100Qa
		500000000000000000, -- 500Qa
		2000000000000000000, -- 2Qi
		10000000000000000000, -- 10Qi
		50000000000000000000, -- 50Qi
	},
}

local Hatch = {
	HatchDuration = 3, -- seconds
	TripleHatchCostMultiplier = 2.5,
	AutoHatchDelay = 0.5, -- seconds between auto-hatches
	GoldenMinRarity = "Rare", -- Golden eggs guarantee at least Rare
	GoldenVariantChance = 0.10, -- 10% chance of golden variant from golden egg
}

-- ============================================================================
-- Number Formatting Suffixes
-- ============================================================================

local NumberSuffixes = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc" }

-- ============================================================================
-- Module Export
-- ============================================================================

return {
	Rarities = Rarities,
	RarityOrder = RarityOrder,
	Pets = Pets,
	ZonePets = ZonePets,
	GoldenVariants = GoldenVariants,
	ExclusivePets = ExclusivePets,
	Zones = Zones,
	Eggs = Eggs,
	Click = Click,
	PetConfig = PetConfig,
	Rebirth = Rebirth,
	Hatch = Hatch,
	NumberSuffixes = NumberSuffixes,
}
