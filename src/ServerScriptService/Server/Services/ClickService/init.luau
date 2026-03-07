--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local VoidPetsConfig = require(ReplicatedStorage.Shared.VoidPetsConfig)

local PlayerDataService
local PetService
local MonetizationService

--[=[
	@class ClickService
	Void Crystal clicking, VE earning, anti-autoclicker, auto-click upgrade.
]=]
local ClickService = Knit.CreateService({
	Name = "ClickService",
	VoidEnergyChanged = Signal.new(), -- (player, newAmount, delta)
	Client = {
		VoidEnergyChanged = Knit.CreateSignal(), -- (newAmount, delta, vePerClick)
		ClickRegistered = Knit.CreateSignal(), -- (veEarned)
	},
})

-- Anti-cheat: track click timestamps per player
local clickHistory: { [Player]: { number } } = {}
local autoClickPlayers: { [Player]: boolean } = {}

-- ============================================================================
-- VE Calculation
-- ============================================================================

function ClickService:GetVEPerClick(player: Player): number
	local base = VoidPetsConfig.Click.BaseVEPerClick

	-- Pet multiplier
	local petMultiplier = PetService:GetPetMultiplier(player)

	-- Rebirth multiplier
	local rebirthCount = PlayerDataService:Read(player, { "RebirthCount" }) or 0
	local rebirthMultiplier = (1 + VoidPetsConfig.Rebirth.MultiplierPerRebirth) ^ rebirthCount

	-- Zone multiplier
	local currentZone = PlayerDataService:Read(player, { "CurrentZone" }) or 1
	local zoneDef = VoidPetsConfig.Zones[currentZone]
	local zoneMultiplier = if zoneDef then zoneDef.ZoneMultiplier else 1

	-- VIP multiplier
	local vipMultiplier = if MonetizationService:HasGamePass(player, "VIP") then 2 else 1

	return math.floor(base * petMultiplier * rebirthMultiplier * zoneMultiplier * vipMultiplier)
end

-- ============================================================================
-- Click Handling
-- ============================================================================

function ClickService:ProcessClick(player: Player): (boolean, number?)
	PlayerDataService:WaitForProfile(player):expect()

	-- Anti-autoclicker check
	local now = os.clock()
	local history = clickHistory[player]
	if not history then
		history = {}
		clickHistory[player] = history
	end

	-- Remove clicks older than 1 second
	while #history > 0 and (now - history[1]) > 1 do
		table.remove(history, 1)
	end

	if #history >= VoidPetsConfig.Click.MaxClicksPerSecond then
		return false, nil
	end

	table.insert(history, now)

	-- Calculate and award VE
	local veEarned = self:GetVEPerClick(player)
	local currentVE = PlayerDataService:Read(player, { "VoidEnergy" }) or 0
	local newVE = currentVE + veEarned

	PlayerDataService:Write(player, { "VoidEnergy" }, newVE)

	-- Update total VE earned
	local totalEarned = PlayerDataService:Read(player, { "TotalVoidEnergyEarned" }) or 0
	PlayerDataService:Write(player, { "TotalVoidEnergyEarned" }, totalEarned + veEarned)

	-- Update total clicks
	local totalClicks = PlayerDataService:Read(player, { "TotalClicks" }) or 0
	PlayerDataService:Write(player, { "TotalClicks" }, totalClicks + 1)

	self.VoidEnergyChanged:Fire(player, newVE, veEarned)
	self.Client.ClickRegistered:Fire(player, veEarned)

	return true, veEarned
end

-- ============================================================================
-- Auto-Click
-- ============================================================================

function ClickService:PurchaseAutoClick(player: Player): boolean
	PlayerDataService:WaitForProfile(player):expect()

	local hasAutoClick = PlayerDataService:Read(player, { "HasAutoClick" })
	if hasAutoClick then
		return false -- already purchased
	end

	-- Cost: 10,000 VE
	local cost = 10000
	local currentVE = PlayerDataService:Read(player, { "VoidEnergy" }) or 0
	if currentVE < cost then
		return false
	end

	PlayerDataService:Write(player, { "VoidEnergy" }, currentVE - cost)
	PlayerDataService:Write(player, { "HasAutoClick" }, true)
	return true
end

function ClickService:_startAutoClick(player: Player)
	if autoClickPlayers[player] then
		return
	end
	autoClickPlayers[player] = true
end

function ClickService:_stopAutoClick(player: Player)
	autoClickPlayers[player] = nil
end

function ClickService:_processAutoClicks()
	for player, _ in autoClickPlayers do
		if not player.Parent then
			autoClickPlayers[player] = nil
			continue
		end

		local hasAutoClick = PlayerDataService:Read(player, { "HasAutoClick" })
		if not hasAutoClick then
			autoClickPlayers[player] = nil
			continue
		end

		local vePerClick = self:GetVEPerClick(player)
		local autoVE = math.floor(vePerClick * VoidPetsConfig.Click.AutoClickRate)
		if autoVE < 1 then
			autoVE = 1
		end

		local currentVE = PlayerDataService:Read(player, { "VoidEnergy" }) or 0
		local newVE = currentVE + autoVE

		PlayerDataService:Write(player, { "VoidEnergy" }, newVE)

		local totalEarned = PlayerDataService:Read(player, { "TotalVoidEnergyEarned" }) or 0
		PlayerDataService:Write(player, { "TotalVoidEnergyEarned" }, totalEarned + autoVE)

		self.VoidEnergyChanged:Fire(player, newVE, autoVE)
		self.Client.VoidEnergyChanged:Fire(player, newVE, autoVE, vePerClick)
	end
end

-- ============================================================================
-- Client API
-- ============================================================================

function ClickService.Client:Click(player: Player)
	return self.Server:ProcessClick(player)
end

function ClickService.Client:GetVEPerClick(player: Player)
	return self.Server:GetVEPerClick(player)
end

function ClickService.Client:GetVoidEnergy(player: Player)
	PlayerDataService:WaitForProfile(player):expect()
	return PlayerDataService:Read(player, { "VoidEnergy" }) or 0
end

function ClickService.Client:PurchaseAutoClick(player: Player)
	return self.Server:PurchaseAutoClick(player)
end

function ClickService.Client:HasAutoClick(player: Player)
	PlayerDataService:WaitForProfile(player):expect()
	return PlayerDataService:Read(player, { "HasAutoClick" }) or false
end

function ClickService.Client:EnableAutoClick(player: Player)
	local hasAutoClick = PlayerDataService:Read(player, { "HasAutoClick" })
	if hasAutoClick then
		self.Server:_startAutoClick(player)
		return true
	end
	return false
end

function ClickService.Client:DisableAutoClick(player: Player)
	self.Server:_stopAutoClick(player)
	return true
end

-- ============================================================================
-- Lifecycle
-- ============================================================================

function ClickService:KnitInit()
	PlayerDataService = Knit.GetService("PlayerDataService")
	PetService = Knit.GetService("PetService")
	MonetizationService = Knit.GetService("MonetizationService")

	Players.PlayerRemoving:Connect(function(player)
		clickHistory[player] = nil
		autoClickPlayers[player] = nil
	end)
end

function ClickService:KnitStart()
	-- Auto-click tick every second
	local autoClickAccumulator = 0
	RunService.Heartbeat:Connect(function(dt)
		autoClickAccumulator = autoClickAccumulator + dt
		if autoClickAccumulator >= 1 then
			autoClickAccumulator = autoClickAccumulator - 1
			self:_processAutoClicks()
		end
	end)

	-- Start auto-click for players who already have it
	for _, player in Players:GetPlayers() do
		task.spawn(function()
			PlayerDataService:WaitForProfile(player)
				:andThen(function()
					local hasAutoClick = PlayerDataService:Read(player, { "HasAutoClick" })
					if hasAutoClick then
						self:_startAutoClick(player)
					end
				end)
				:catch(function() end)
		end)
	end
end

return ClickService
