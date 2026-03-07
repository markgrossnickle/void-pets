--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local VoidPetsConfig = require(ReplicatedStorage.Shared.VoidPetsConfig)

local PlayerDataService
local ZoneService

--[=[
	@class RebirthService
	Rebirth system: reset progress for permanent multiplier. Keeps pets.
]=]
local RebirthService = Knit.CreateService({
	Name = "RebirthService",
	PlayerRebirthed = Signal.new(), -- (player, newRebirthCount)
	Client = {
		PlayerRebirthed = Knit.CreateSignal(), -- (newRebirthCount, newMultiplier)
	},
})

-- ============================================================================
-- Rebirth Logic
-- ============================================================================

function RebirthService:GetRebirthMultiplier(player: Player): number
	PlayerDataService:WaitForProfile(player):expect()
	local rebirthCount = PlayerDataService:Read(player, { "RebirthCount" }) or 0
	return (1 + VoidPetsConfig.Rebirth.MultiplierPerRebirth) ^ rebirthCount
end

function RebirthService:GetRebirthRequirement(player: Player): number?
	PlayerDataService:WaitForProfile(player):expect()
	local rebirthCount = PlayerDataService:Read(player, { "RebirthCount" }) or 0
	local nextRebirth = rebirthCount + 1

	if nextRebirth > VoidPetsConfig.Rebirth.MaxRebirths then
		return nil -- maxed out
	end

	return VoidPetsConfig.Rebirth.Thresholds[nextRebirth]
end

function RebirthService:CanRebirth(player: Player): (boolean, string?)
	PlayerDataService:WaitForProfile(player):expect()
	local rebirthCount = PlayerDataService:Read(player, { "RebirthCount" }) or 0

	if rebirthCount >= VoidPetsConfig.Rebirth.MaxRebirths then
		return false, "Maximum rebirths reached"
	end

	-- Check zone requirement
	local unlockedZones = PlayerDataService:Read(player, { "UnlockedZones" }) or {}
	if not unlockedZones[tostring(VoidPetsConfig.Rebirth.MinZone)] then
		return false, `Must reach Zone {VoidPetsConfig.Rebirth.MinZone} first`
	end

	-- Check VE threshold
	local totalEarned = PlayerDataService:Read(player, { "TotalVoidEnergyEarned" }) or 0
	local nextRebirth = rebirthCount + 1
	local threshold = VoidPetsConfig.Rebirth.Thresholds[nextRebirth]

	if not threshold then
		return false, "No threshold defined"
	end

	if totalEarned < threshold then
		return false, `Need {threshold} total VE earned (have {totalEarned})`
	end

	return true, nil
end

function RebirthService:DoRebirth(player: Player): (boolean, string?)
	local canRebirth, reason = self:CanRebirth(player)
	if not canRebirth then
		return false, reason
	end

	local rebirthCount = PlayerDataService:Read(player, { "RebirthCount" }) or 0
	local newRebirthCount = rebirthCount + 1

	-- Reset: VE balance
	PlayerDataService:Write(player, { "VoidEnergy" }, 0)
	PlayerDataService:Write(player, { "TotalVoidEnergyEarned" }, 0)

	-- Reset: zone progress (back to zone 1 only)
	PlayerDataService:Write(player, { "UnlockedZones" }, { ["1"] = true })
	PlayerDataService:Write(player, { "CurrentZone" }, 1)

	-- Reset: auto-click
	PlayerDataService:Write(player, { "HasAutoClick" }, false)

	-- Keep: pets, pet levels, trade history, gamepasses, stats (clicks, hatches)
	-- Increment rebirth count
	PlayerDataService:Write(player, { "RebirthCount" }, newRebirthCount)

	-- Calculate new multiplier
	local newMultiplier = (1 + VoidPetsConfig.Rebirth.MultiplierPerRebirth) ^ newRebirthCount

	-- Teleport back to zone 1
	ZoneService:TeleportToZone(player, 1)

	-- Notify
	self.PlayerRebirthed:Fire(player, newRebirthCount)
	self.Client.PlayerRebirthed:Fire(player, newRebirthCount, newMultiplier)

	print(`{player.DisplayName} rebirthed! Count: {newRebirthCount}, Multiplier: {string.format("%.1f", newMultiplier)}x`)

	return true, nil
end

-- ============================================================================
-- Client API
-- ============================================================================

function RebirthService.Client:GetRebirthCount(player: Player)
	PlayerDataService:WaitForProfile(player):expect()
	return PlayerDataService:Read(player, { "RebirthCount" }) or 0
end

function RebirthService.Client:GetRebirthMultiplier(player: Player)
	return self.Server:GetRebirthMultiplier(player)
end

function RebirthService.Client:GetRebirthRequirement(player: Player)
	return self.Server:GetRebirthRequirement(player)
end

function RebirthService.Client:CanRebirth(player: Player)
	return self.Server:CanRebirth(player)
end

function RebirthService.Client:DoRebirth(player: Player)
	return self.Server:DoRebirth(player)
end

-- ============================================================================
-- Lifecycle
-- ============================================================================

function RebirthService:KnitInit()
	PlayerDataService = Knit.GetService("PlayerDataService")
	ZoneService = Knit.GetService("ZoneService")
end

function RebirthService:KnitStart() end

return RebirthService
