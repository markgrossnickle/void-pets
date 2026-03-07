--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local VoidPetsConfig = require(ReplicatedStorage.Shared.VoidPetsConfig)

local PlayerDataService
local PetService
local MonetizationService

--[=[
	@class EggService
	Egg purchasing, hatching, and rarity rolling.
]=]
local EggService = Knit.CreateService({
	Name = "EggService",
	Client = {
		EggHatched = Knit.CreateSignal(), -- (eggId, petData, isNew)
		HatchStarted = Knit.CreateSignal(), -- (eggId)
	},
})

-- Track hatching cooldowns per player
local hatchCooldowns: { [Player]: number } = {}

-- ============================================================================
-- Rarity Rolling
-- ============================================================================

function EggService:_rollRarity(eggDef: VoidPetsConfig.EggDefinition, hasLucky: boolean): string
	local rarityBoost = eggDef.RarityBoost
	local luckMultiplier = if hasLucky then 1.5 else 1

	-- Build weighted table
	local weights: { { rarity: string, weight: number } } = {}
	local totalWeight = 0

	for _, rarity in VoidPetsConfig.RarityOrder do
		local info = VoidPetsConfig.Rarities[rarity]
		local weight = info.Chance

		-- Boost rarer cards for premium/golden eggs
		if rarityBoost > 0 and info.SortOrder >= 3 then -- Rare+
			weight = weight * (1 + rarityBoost)
		end

		-- Lucky gamepass
		if luckMultiplier > 1 and info.SortOrder >= 3 then
			weight = weight * luckMultiplier
		end

		totalWeight = totalWeight + weight
		table.insert(weights, { rarity = rarity, weight = totalWeight })
	end

	local roll = math.random() * totalWeight
	for _, entry in weights do
		if roll <= entry.weight then
			-- Golden eggs guarantee at least Rare
			if eggDef.Tier == "Golden" then
				local minOrder = VoidPetsConfig.Rarities[VoidPetsConfig.Hatch.GoldenMinRarity].SortOrder
				if VoidPetsConfig.Rarities[entry.rarity].SortOrder < minOrder then
					return VoidPetsConfig.Hatch.GoldenMinRarity
				end
			end
			return entry.rarity
		end
	end

	return "Common"
end

function EggService:_rollPetType(eggDef: VoidPetsConfig.EggDefinition): string
	local zonePets = VoidPetsConfig.ZonePets[eggDef.Zone]
	if not zonePets or #zonePets == 0 then
		return "VoidPup" -- fallback
	end

	local chosen = zonePets[math.random(1, #zonePets)]

	-- Golden egg: chance for golden variant
	if eggDef.Tier == "Golden" then
		local goldenType = VoidPetsConfig.GoldenVariants[chosen]
		if goldenType and math.random() < VoidPetsConfig.Hatch.GoldenVariantChance then
			return goldenType
		end
	end

	return chosen
end

-- ============================================================================
-- Egg Purchase + Hatch
-- ============================================================================

function EggService:HatchEgg(player: Player, eggId: string): (boolean, any?)
	PlayerDataService:WaitForProfile(player):expect()

	-- Cooldown check
	local now = os.clock()
	local lastHatch = hatchCooldowns[player] or 0
	if now - lastHatch < 0.3 then
		return false, "Too fast"
	end
	hatchCooldowns[player] = now

	local eggDef = VoidPetsConfig.Eggs[eggId]
	if not eggDef then
		return false, "Unknown egg"
	end

	-- Check zone unlock
	local unlockedZones = PlayerDataService:Read(player, { "UnlockedZones" }) or {}
	if not unlockedZones[tostring(eggDef.Zone)] then
		return false, "Zone not unlocked"
	end

	-- Exclusive egg check
	if eggDef.Tier == "Exclusive" then
		if not MonetizationService:HasGamePass(player, "ExclusiveEgg") then
			return false, "Need Exclusive Egg gamepass"
		end
	end

	-- Check cost
	local currentVE = PlayerDataService:Read(player, { "VoidEnergy" }) or 0
	if currentVE < eggDef.Cost then
		return false, "Not enough Void Energy"
	end

	-- Deduct cost
	PlayerDataService:Write(player, { "VoidEnergy" }, currentVE - eggDef.Cost)

	-- Roll rarity and pet
	local hasLucky = MonetizationService:HasGamePass(player, "Lucky")
	local rarity = self:_rollRarity(eggDef, hasLucky)
	local petType = self:_rollPetType(eggDef)

	-- Add pet to inventory
	local petIndex = PetService:AddPet(player, petType, rarity)

	-- Update stats
	local totalHatches = PlayerDataService:Read(player, { "TotalHatches" }) or 0
	PlayerDataService:Write(player, { "TotalHatches" }, totalHatches + 1)

	-- Check if this is a new pet type for the player
	local pets = PlayerDataService:Read(player, { "Pets" }) or {}
	local isNew = true
	for i, pet in pets do
		if i ~= petIndex and pet.Type == petType then
			isNew = false
			break
		end
	end

	local result = {
		PetIndex = petIndex,
		PetType = petType,
		Rarity = rarity,
		IsNew = isNew,
		EggId = eggId,
	}

	-- Notify client
	self.Client.EggHatched:Fire(player, eggId, result, isNew)

	-- Mythic server announcement
	if rarity == "Mythic" then
		self:_announceRarePet(player, petType, rarity)
	end

	return true, result
end

function EggService:TripleHatch(player: Player, eggId: string): (boolean, { any }?)
	local eggDef = VoidPetsConfig.Eggs[eggId]
	if not eggDef then
		return false, nil
	end

	local tripleCost = math.floor(eggDef.Cost * VoidPetsConfig.Hatch.TripleHatchCostMultiplier)
	local currentVE = PlayerDataService:Read(player, { "VoidEnergy" }) or 0
	if currentVE < tripleCost then
		return false, nil
	end

	-- Deduct triple cost (we handle cost manually since HatchEgg also deducts)
	-- Instead, temporarily set enough VE for 3 hatches at individual cost
	-- Actually, let's deduct the triple cost and then do free hatches
	PlayerDataService:Write(player, { "VoidEnergy" }, currentVE - tripleCost)

	-- Override cost check by temporarily giving VE back per egg
	-- Simpler: just roll 3 pets directly
	local results = {}
	local hasLucky = MonetizationService:HasGamePass(player, "Lucky")

	for _ = 1, 3 do
		local rarity = self:_rollRarity(eggDef, hasLucky)
		local petType = self:_rollPetType(eggDef)
		local petIndex = PetService:AddPet(player, petType, rarity)

		local totalHatches = PlayerDataService:Read(player, { "TotalHatches" }) or 0
		PlayerDataService:Write(player, { "TotalHatches" }, totalHatches + 1)

		local pets = PlayerDataService:Read(player, { "Pets" }) or {}
		local isNew = true
		for i, pet in pets do
			if i ~= petIndex and pet.Type == petType then
				isNew = false
				break
			end
		end

		local result = {
			PetIndex = petIndex,
			PetType = petType,
			Rarity = rarity,
			IsNew = isNew,
			EggId = eggId,
		}
		table.insert(results, result)

		self.Client.EggHatched:Fire(player, eggId, result, isNew)

		if rarity == "Mythic" then
			self:_announceRarePet(player, petType, rarity)
		end
	end

	return true, results
end

function EggService:_announceRarePet(player: Player, petType: string, rarity: string)
	local petDef = VoidPetsConfig.Pets[petType]
	local petName = if petDef then petDef.Name else petType
	local message = `{player.DisplayName} hatched a {rarity} {petName}!`

	-- Use Roblox chat system for server-wide announcement
	-- In a real game you'd use a custom announcement system
	for _, p in game:GetService("Players"):GetPlayers() do
		-- Fire to all clients via a generic signal would be cleaner,
		-- but for now we just print server-side
		_ = p -- suppress unused warning
	end
	print(`[ANNOUNCEMENT] {message}`)
end

-- ============================================================================
-- Client API
-- ============================================================================

function EggService.Client:HatchEgg(player: Player, eggId: string)
	return self.Server:HatchEgg(player, eggId)
end

function EggService.Client:TripleHatch(player: Player, eggId: string)
	return self.Server:TripleHatch(player, eggId)
end

function EggService.Client:GetEggCost(_player: Player, eggId: string): number?
	local eggDef = VoidPetsConfig.Eggs[eggId]
	return if eggDef then eggDef.Cost else nil
end

function EggService.Client:GetTripleHatchCost(_player: Player, eggId: string): number?
	local eggDef = VoidPetsConfig.Eggs[eggId]
	if not eggDef then
		return nil
	end
	return math.floor(eggDef.Cost * VoidPetsConfig.Hatch.TripleHatchCostMultiplier)
end

-- ============================================================================
-- Lifecycle
-- ============================================================================

function EggService:KnitInit()
	PlayerDataService = Knit.GetService("PlayerDataService")
	PetService = Knit.GetService("PetService")
	MonetizationService = Knit.GetService("MonetizationService")

	game:GetService("Players").PlayerRemoving:Connect(function(player)
		hatchCooldowns[player] = nil
	end)
end

function EggService:KnitStart() end

return EggService
