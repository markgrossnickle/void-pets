--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local VoidPetsConfig = require(ReplicatedStorage.Shared.VoidPetsConfig)

local PlayerDataService
local MonetizationService

--[=[
	@class PetService
	Pet inventory, equipping, leveling, and trading.
]=]
local PetService = Knit.CreateService({
	Name = "PetService",
	PetAdded = Signal.new(), -- (player, petIndex, petData)
	PetEquipped = Signal.new(), -- (player, petIndex)
	PetUnequipped = Signal.new(), -- (player, petIndex)
	Client = {
		PetAdded = Knit.CreateSignal(), -- (petIndex, petData)
		PetRemoved = Knit.CreateSignal(), -- (petIndex)
		PetEquipped = Knit.CreateSignal(), -- (equippedSlots)
		PetUnequipped = Knit.CreateSignal(), -- (equippedSlots)
		PetLeveledUp = Knit.CreateSignal(), -- (petIndex, newLevel)
		TradeCompleted = Knit.CreateSignal(), -- (tradeData)
		InventorySync = Knit.CreateSignal(), -- (pets, equippedSlots)
	},
})

-- ============================================================================
-- Helpers
-- ============================================================================

function PetService:_getPlayerData(player: Player)
	return PlayerDataService:WaitForProfile(player):expect()
end

function PetService:_getPets(player: Player): { any }
	local data = PlayerDataService:Read(player, { "Pets" })
	return data or {}
end

function PetService:_getEquippedSlots(player: Player): { number }
	local data = PlayerDataService:Read(player, { "EquippedPetSlots" })
	return data or {}
end

function PetService:_getMaxEquipped(player: Player): number
	if MonetizationService:HasGamePass(player, "ExtraEquip") then
		return VoidPetsConfig.PetConfig.MaxEquippedVIP
	end
	return VoidPetsConfig.PetConfig.MaxEquipped
end

function PetService:_getRaritySortOrder(rarity: string): number
	local info = VoidPetsConfig.Rarities[rarity]
	return if info then info.SortOrder else 0
end

-- ============================================================================
-- Pet Creation
-- ============================================================================

function PetService:AddPet(player: Player, petType: string, rarity: string): number?
	self:_getPlayerData(player)
	local pets = self:_getPets(player)

	local newPet = {
		Type = petType,
		Rarity = rarity,
		Level = 1,
		Locked = false,
		ObtainedAt = os.time(),
		TradeLockUntil = 0,
	}

	table.insert(pets, newPet)
	PlayerDataService:Write(player, { "Pets" }, pets)

	local petIndex = #pets

	-- Update rarest pet stat
	local currentRarest = PlayerDataService:Read(player, { "RarestPetRarity" }) or "Common"
	if self:_getRaritySortOrder(rarity) > self:_getRaritySortOrder(currentRarest) then
		PlayerDataService:Write(player, { "RarestPetRarity" }, rarity)
	end

	self.PetAdded:Fire(player, petIndex, newPet)
	self.Client.PetAdded:Fire(player, petIndex, newPet)

	return petIndex
end

-- ============================================================================
-- Equip / Unequip
-- ============================================================================

function PetService:EquipPet(player: Player, petIndex: number): boolean
	self:_getPlayerData(player)
	local pets = self:_getPets(player)
	local equipped = self:_getEquippedSlots(player)

	if not pets[petIndex] then
		return false
	end

	-- Check if already equipped
	for _, idx in equipped do
		if idx == petIndex then
			return false
		end
	end

	local maxEquipped = self:_getMaxEquipped(player)
	if #equipped >= maxEquipped then
		return false
	end

	table.insert(equipped, petIndex)
	PlayerDataService:Write(player, { "EquippedPetSlots" }, equipped)

	self.PetEquipped:Fire(player, petIndex)
	self.Client.PetEquipped:Fire(player, equipped)
	return true
end

function PetService:UnequipPet(player: Player, petIndex: number): boolean
	self:_getPlayerData(player)
	local equipped = self:_getEquippedSlots(player)

	local found = false
	for i, idx in equipped do
		if idx == petIndex then
			table.remove(equipped, i)
			found = true
			break
		end
	end

	if not found then
		return false
	end

	PlayerDataService:Write(player, { "EquippedPetSlots" }, equipped)
	self.PetUnequipped:Fire(player, petIndex)
	self.Client.PetUnequipped:Fire(player, equipped)
	return true
end

-- ============================================================================
-- Multiplier Calculation
-- ============================================================================

function PetService:GetPetMultiplier(player: Player): number
	self:_getPlayerData(player)
	local pets = self:_getPets(player)
	local equipped = self:_getEquippedSlots(player)

	local total = 0
	for _, petIndex in equipped do
		local pet = pets[petIndex]
		if pet then
			local rarityInfo = VoidPetsConfig.Rarities[pet.Rarity]
			if rarityInfo then
				local baseMultiplier = rarityInfo.Multiplier
				local levelBonus = 1 + (pet.Level - 1) * VoidPetsConfig.PetConfig.LevelUpMultiplierBonus
				total = total + (baseMultiplier * levelBonus)
			end
		end
	end

	return math.max(total, 1)
end

-- ============================================================================
-- Pet Leveling (Feed Duplicates)
-- ============================================================================

function PetService:LevelUpPet(player: Player, petIndex: number): (boolean, string?)
	self:_getPlayerData(player)
	local pets = self:_getPets(player)
	local pet = pets[petIndex]

	if not pet then
		return false, "Pet not found"
	end

	if pet.Level >= VoidPetsConfig.PetConfig.MaxLevel then
		return false, "Pet is already max level"
	end

	-- Count available duplicates (same type, not the target pet, not equipped, not locked)
	local equipped = self:_getEquippedSlots(player)
	local equippedSet: { [number]: boolean } = {}
	for _, idx in equipped do
		equippedSet[idx] = true
	end

	local duplicateIndices: { number } = {}
	for i, otherPet in pets do
		if i ~= petIndex and otherPet.Type == pet.Type and not otherPet.Locked and not equippedSet[i] then
			table.insert(duplicateIndices, i)
			if #duplicateIndices >= VoidPetsConfig.PetConfig.DuplicatesPerLevelUp then
				break
			end
		end
	end

	if #duplicateIndices < VoidPetsConfig.PetConfig.DuplicatesPerLevelUp then
		return false, `Need {VoidPetsConfig.PetConfig.DuplicatesPerLevelUp} duplicate {pet.Type} pets`
	end

	-- Remove duplicates (iterate in reverse to preserve indices)
	table.sort(duplicateIndices, function(a, b)
		return a > b
	end)

	-- Fix equipped slots after removal
	for _, removeIdx in duplicateIndices do
		table.remove(pets, removeIdx)
		-- Adjust equipped indices
		for i, eqIdx in equipped do
			if eqIdx > removeIdx then
				equipped[i] = eqIdx - 1
			end
		end
		-- Adjust target index if needed
		if petIndex > removeIdx then
			petIndex = petIndex - 1
		end
	end

	-- Level up
	pets[petIndex].Level = pets[petIndex].Level + 1

	PlayerDataService:Write(player, { "Pets" }, pets)
	PlayerDataService:Write(player, { "EquippedPetSlots" }, equipped)

	self.Client.PetLeveledUp:Fire(player, petIndex, pets[petIndex].Level)
	return true, nil
end

-- ============================================================================
-- Trading
-- ============================================================================

function PetService:InitiateTrade(
	player1: Player,
	player2: Player,
	offer1: { number },
	offer2: { number }
): (boolean, string?)
	self:_getPlayerData(player1)
	self:_getPlayerData(player2)

	local pets1 = self:_getPets(player1)
	local pets2 = self:_getPets(player2)
	local now = os.time()

	-- Validate player 1's offer
	local equipped1 = self:_getEquippedSlots(player1)
	local equippedSet1: { [number]: boolean } = {}
	for _, idx in equipped1 do
		equippedSet1[idx] = true
	end

	for _, idx in offer1 do
		local pet = pets1[idx]
		if not pet then
			return false, "Invalid pet in your offer"
		end
		if pet.Locked then
			return false, `{pet.Type} is locked`
		end
		if pet.TradeLockUntil > now then
			return false, `{pet.Type} is trade-locked`
		end
		if equippedSet1[idx] then
			return false, `Unequip {pet.Type} before trading`
		end
	end

	-- Validate player 2's offer
	local equipped2 = self:_getEquippedSlots(player2)
	local equippedSet2: { [number]: boolean } = {}
	for _, idx in equipped2 do
		equippedSet2[idx] = true
	end

	for _, idx in offer2 do
		local pet = pets2[idx]
		if not pet then
			return false, "Invalid pet in partner's offer"
		end
		if pet.Locked then
			return false, `Partner's {pet.Type} is locked`
		end
		if pet.TradeLockUntil > now then
			return false, `Partner's {pet.Type} is trade-locked`
		end
		if equippedSet2[idx] then
			return false, `Partner must unequip {pet.Type}`
		end
	end

	-- Collect pets to swap
	local tradeLockUntil = now + VoidPetsConfig.PetConfig.TradeLockDuration
	local petsToPlayer1: { any } = {}
	local petsToPlayer2: { any } = {}
	local givenNames1: { string } = {}
	local givenNames2: { string } = {}

	for _, idx in offer1 do
		local pet = table.clone(pets1[idx])
		pet.TradeLockUntil = tradeLockUntil
		table.insert(petsToPlayer2, pet)
		table.insert(givenNames1, pet.Type)
	end

	for _, idx in offer2 do
		local pet = table.clone(pets2[idx])
		pet.TradeLockUntil = tradeLockUntil
		table.insert(petsToPlayer1, pet)
		table.insert(givenNames2, pet.Type)
	end

	-- Remove traded pets (reverse order)
	local sortedOffer1 = table.clone(offer1)
	table.sort(sortedOffer1, function(a, b)
		return a > b
	end)
	for _, idx in sortedOffer1 do
		table.remove(pets1, idx)
	end

	local sortedOffer2 = table.clone(offer2)
	table.sort(sortedOffer2, function(a, b)
		return a > b
	end)
	for _, idx in sortedOffer2 do
		table.remove(pets2, idx)
	end

	-- Add received pets
	for _, pet in petsToPlayer1 do
		table.insert(pets1, pet)
	end
	for _, pet in petsToPlayer2 do
		table.insert(pets2, pet)
	end

	-- Fix equipped slots
	local newEquipped1 = self:_fixEquippedAfterRemoval(equipped1, sortedOffer1, #pets1 - #petsToPlayer1)
	local newEquipped2 = self:_fixEquippedAfterRemoval(equipped2, sortedOffer2, #pets2 - #petsToPlayer2)

	-- Write all data
	PlayerDataService:Write(player1, { "Pets" }, pets1)
	PlayerDataService:Write(player1, { "EquippedPetSlots" }, newEquipped1)
	PlayerDataService:Write(player2, { "Pets" }, pets2)
	PlayerDataService:Write(player2, { "EquippedPetSlots" }, newEquipped2)

	-- Record trade history
	self:_addTradeRecord(player1, player2, givenNames1, givenNames2, now)
	self:_addTradeRecord(player2, player1, givenNames2, givenNames1, now)

	-- Notify clients
	self.Client.TradeCompleted:Fire(player1, { received = givenNames2, given = givenNames1 })
	self.Client.TradeCompleted:Fire(player2, { received = givenNames1, given = givenNames2 })

	return true, nil
end

function PetService:_fixEquippedAfterRemoval(
	equipped: { number },
	removedIndices: { number },
	_petCountBefore: number
): { number }
	-- removedIndices are sorted descending
	local newEquipped: { number } = {}
	for _, eqIdx in equipped do
		local removed = false
		local offset = 0
		for _, rmIdx in removedIndices do
			if eqIdx == rmIdx then
				removed = true
				break
			end
			if eqIdx > rmIdx then
				offset = offset + 1
			end
		end
		if not removed then
			table.insert(newEquipped, eqIdx - offset)
		end
	end
	return newEquipped
end

function PetService:_addTradeRecord(
	player: Player,
	partner: Player,
	given: { string },
	received: { string },
	timestamp: number
)
	local history = PlayerDataService:Read(player, { "TradeHistory" }) or {}
	table.insert(history, 1, {
		Timestamp = timestamp,
		PartnerId = partner.UserId,
		PartnerName = partner.DisplayName,
		Given = given,
		Received = received,
	})
	-- Keep only last 20
	while #history > 20 do
		table.remove(history)
	end
	PlayerDataService:Write(player, { "TradeHistory" }, history)
end

-- ============================================================================
-- Pet Lock (prevent accidental trade/feed)
-- ============================================================================

function PetService:ToggleLock(player: Player, petIndex: number): boolean
	self:_getPlayerData(player)
	local pets = self:_getPets(player)
	local pet = pets[petIndex]
	if not pet then
		return false
	end
	pet.Locked = not pet.Locked
	PlayerDataService:Write(player, { "Pets" }, pets)
	return true
end

-- ============================================================================
-- Client API
-- ============================================================================

function PetService.Client:GetPets(player: Player)
	return self.Server:_getPets(player)
end

function PetService.Client:GetEquippedSlots(player: Player)
	return self.Server:_getEquippedSlots(player)
end

function PetService.Client:GetPetMultiplier(player: Player)
	return self.Server:GetPetMultiplier(player)
end

function PetService.Client:EquipPet(player: Player, petIndex: number)
	return self.Server:EquipPet(player, petIndex)
end

function PetService.Client:UnequipPet(player: Player, petIndex: number)
	return self.Server:UnequipPet(player, petIndex)
end

function PetService.Client:LevelUpPet(player: Player, petIndex: number)
	return self.Server:LevelUpPet(player, petIndex)
end

function PetService.Client:ToggleLock(player: Player, petIndex: number)
	return self.Server:ToggleLock(player, petIndex)
end

-- ============================================================================
-- Lifecycle
-- ============================================================================

function PetService:KnitInit()
	PlayerDataService = Knit.GetService("PlayerDataService")
	MonetizationService = Knit.GetService("MonetizationService")

	Players.PlayerRemoving:Connect(function(_player: Player)
		-- Cleanup handled by PlayerDataService
	end)
end

function PetService:KnitStart()
	-- Sync inventory to clients that are already connected
	for _, player in Players:GetPlayers() do
		task.spawn(function()
			PlayerDataService:WaitForProfile(player)
				:andThen(function()
					local pets = self:_getPets(player)
					local equipped = self:_getEquippedSlots(player)
					self.Client.InventorySync:Fire(player, pets, equipped)
				end)
				:catch(function(err)
					warn(`PetService: Failed to sync for {player.Name}: {err}`)
				end)
		end)
	end
end

return PetService
