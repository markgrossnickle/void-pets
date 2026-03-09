--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local VoidPetsConfig = require(ReplicatedStorage.Shared.VoidPetsConfig)

local PlayerDataService

--[=[
	@class ZoneService
	Zone unlocking, player zone tracking, zone building.
]=]
local ZoneService = Knit.CreateService({
	Name = "ZoneService",
	ZoneUnlocked = Signal.new(), -- (player, zoneNumber)
	PlayerChangedZone = Signal.new(), -- (player, zoneNumber)
	Client = {
		ZoneUnlocked = Knit.CreateSignal(), -- (zoneNumber)
		ZoneChanged = Knit.CreateSignal(), -- (zoneNumber)
		ZonesSync = Knit.CreateSignal(), -- (unlockedZones, currentZone)
	},
})

-- Zone world models, keyed by zone number
local zoneModels: { [number]: Model } = {}

-- ============================================================================
-- Zone World Building (code-built)
-- ============================================================================

local function createCrystal(position: Vector3, color: Color3, size: Vector3): BasePart
	local crystal = Instance.new("Part")
	crystal.Name = "VoidCrystal"
	crystal.Anchored = true
	crystal.CanCollide = true
	crystal.Size = size
	crystal.Position = position
	crystal.Color = color
	crystal.Material = Enum.Material.Neon
	crystal.Transparency = 0.1
	crystal:SetAttribute("VoidCrystal", true)

	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = 3
	light.Range = 15
	light.Parent = crystal

	local particle = Instance.new("ParticleEmitter")
	particle.Color = ColorSequence.new(color)
	particle.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0) })
	particle.Lifetime = NumberRange.new(0.8, 1.5)
	particle.Rate = 8
	particle.Speed = NumberRange.new(0.5, 1.5)
	particle.SpreadAngle = Vector2.new(180, 180)
	particle.Parent = crystal

	return crystal
end

local function createEggPedestal(position: Vector3, color: Color3, eggId: string): Model
	local model = Instance.new("Model")
	model.Name = `EggPedestal_{eggId}`

	-- Base platform
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Anchored = true
	base.Size = Vector3.new(4, 1, 4)
	base.Position = position
	base.Color = Color3.fromRGB(60, 60, 70)
	base.Material = Enum.Material.Slate
	base.Parent = model

	-- Egg on top
	local egg = Instance.new("Part")
	egg.Name = "Egg"
	egg.Anchored = true
	egg.CanCollide = true
	egg.Shape = Enum.PartType.Ball
	egg.Size = Vector3.new(2, 2.8, 2)
	egg.Position = position + Vector3.new(0, 2, 0)
	egg.Color = color
	egg.Material = Enum.Material.SmoothPlastic
	egg:SetAttribute("EggId", eggId)

	local eggLight = Instance.new("PointLight")
	eggLight.Color = color
	eggLight.Brightness = 1.5
	eggLight.Range = 6
	eggLight.Parent = egg

	egg.Parent = model

	-- Cost label
	local eggDef = VoidPetsConfig.Eggs[eggId]
	if eggDef then
		local bbg = Instance.new("BillboardGui")
		bbg.Size = UDim2.fromOffset(160, 50)
		bbg.StudsOffset = Vector3.new(0, 3, 0)
		bbg.AlwaysOnTop = true
		bbg.Parent = egg

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.fromScale(1, 0.5)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = eggDef.Name
		nameLabel.TextColor3 = color
		nameLabel.TextStrokeTransparency = 0
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextScaled = true
		nameLabel.Parent = bbg

		local costLabel = Instance.new("TextLabel")
		costLabel.Size = UDim2.fromScale(1, 0.5)
		costLabel.Position = UDim2.fromScale(0, 0.5)
		costLabel.BackgroundTransparency = 1

		local PlatformUtil = require(ReplicatedStorage.Shared.PlatformUtil)
		costLabel.Text = `{PlatformUtil.FormatNumber(eggDef.Cost)} VE`
		costLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		costLabel.TextStrokeTransparency = 0.3
		costLabel.Font = Enum.Font.Gotham
		costLabel.TextScaled = true
		costLabel.Parent = bbg
	end

	model.PrimaryPart = base
	return model
end

local function createPortal(position: Vector3, targetZone: number, color: Color3, locked: boolean): Model
	local model = Instance.new("Model")
	model.Name = `Portal_Zone{targetZone}`

	local frame = Instance.new("Part")
	frame.Name = "Frame"
	frame.Anchored = true
	frame.CanCollide = false
	frame.Size = Vector3.new(8, 10, 1)
	frame.Position = position
	frame.Color = Color3.fromRGB(40, 40, 50)
	frame.Material = Enum.Material.Slate
	frame.Transparency = 0.3
	frame.Parent = model

	local glow = Instance.new("Part")
	glow.Name = "Glow"
	glow.Anchored = true
	glow.CanCollide = false
	glow.Size = Vector3.new(6, 8, 0.5)
	glow.Position = position
	glow.Color = if locked then Color3.fromRGB(200, 50, 50) else color
	glow.Material = Enum.Material.Neon
	glow.Transparency = 0.4
	glow:SetAttribute("PortalZone", targetZone)
	glow:SetAttribute("Locked", locked)
	glow.Parent = model

	local light = Instance.new("PointLight")
	light.Color = glow.Color
	light.Brightness = 2
	light.Range = 12
	light.Parent = glow

	-- Cost label for locked portals
	if locked then
		local zoneDef = VoidPetsConfig.Zones[targetZone]
		if zoneDef then
			local bbg = Instance.new("BillboardGui")
			bbg.Size = UDim2.fromOffset(200, 60)
			bbg.StudsOffset = Vector3.new(0, 6, 0)
			bbg.AlwaysOnTop = true
			bbg.Parent = glow

			local label = Instance.new("TextLabel")
			label.Size = UDim2.fromScale(1, 0.5)
			label.BackgroundTransparency = 1
			label.Text = zoneDef.Name
			label.TextColor3 = Color3.fromRGB(255, 200, 200)
			label.TextStrokeTransparency = 0
			label.Font = Enum.Font.GothamBold
			label.TextScaled = true
			label.Parent = bbg

			local PlatformUtil = require(ReplicatedStorage.Shared.PlatformUtil)
			local costLabel = Instance.new("TextLabel")
			costLabel.Size = UDim2.fromScale(1, 0.5)
			costLabel.Position = UDim2.fromScale(0, 0.5)
			costLabel.BackgroundTransparency = 1
			costLabel.Text = `{PlatformUtil.FormatNumber(zoneDef.UnlockCost)} VE`
			costLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
			costLabel.Font = Enum.Font.Gotham
			costLabel.TextScaled = true
			costLabel.Parent = bbg
		end
	end

	model.PrimaryPart = frame
	return model
end

function ZoneService:_buildZone(zoneNumber: number): Model
	local zoneDef = VoidPetsConfig.Zones[zoneNumber]
	if not zoneDef then
		error(`Unknown zone: {zoneNumber}`)
	end

	local model = Instance.new("Model")
	model.Name = `Zone_{zoneNumber}_{zoneDef.Name:gsub(" ", "")}`

	-- Zone offset (each zone is 80 studs apart)
	local zoneOffset = Vector3.new((zoneNumber - 1) * 80, 0, 0)

	-- Ground platform
	local ground = Instance.new("Part")
	ground.Name = "Ground"
	ground.Anchored = true
	ground.Size = Vector3.new(60, 2, 60)
	ground.Position = zoneOffset + Vector3.new(0, -1, 0)
	ground.Color = zoneDef.AmbientColor
	ground.Material = Enum.Material.Slate
	ground.TopSurface = Enum.SurfaceType.Smooth
	ground.Parent = model

	-- Void Crystal (center)
	local crystal = createCrystal(zoneOffset + Vector3.new(0, 4, 0), zoneDef.AccentColor, Vector3.new(4, 6, 4))
	crystal.Parent = model

	-- Zone label
	local zoneLabelPart = Instance.new("Part")
	zoneLabelPart.Anchored = true
	zoneLabelPart.CanCollide = false
	zoneLabelPart.Transparency = 1
	zoneLabelPart.Size = Vector3.new(0.1, 0.1, 0.1)
	zoneLabelPart.Position = zoneOffset + Vector3.new(0, 12, 0)
	zoneLabelPart.Parent = model

	local zoneGui = Instance.new("BillboardGui")
	zoneGui.Size = UDim2.fromOffset(300, 60)
	zoneGui.AlwaysOnTop = true
	zoneGui.Parent = zoneLabelPart

	local zoneName = Instance.new("TextLabel")
	zoneName.Size = UDim2.fromScale(1, 1)
	zoneName.BackgroundTransparency = 1
	zoneName.Text = zoneDef.Name
	zoneName.TextColor3 = zoneDef.AccentColor
	zoneName.TextStrokeTransparency = 0
	zoneName.Font = Enum.Font.GothamBold
	zoneName.TextScaled = true
	zoneName.Parent = zoneGui

	-- Egg pedestals
	local eggPrefix = { "BasicEgg", "PremiumEgg", "GoldenEgg" }
	local eggPositions = {
		zoneOffset + Vector3.new(-12, 0, -15),
		zoneOffset + Vector3.new(0, 0, -15),
		zoneOffset + Vector3.new(12, 0, -15),
	}

	for i, prefix in eggPrefix do
		local eggId = `{prefix}{zoneNumber}`
		if VoidPetsConfig.Eggs[eggId] then
			local pedestal = createEggPedestal(eggPositions[i], zoneDef.AccentColor, eggId)
			pedestal.Parent = model
		end
	end

	-- Decorative accent parts (4 corner pillars)
	for _, corner in
		{
			Vector3.new(-25, 0, -25),
			Vector3.new(25, 0, -25),
			Vector3.new(-25, 0, 25),
			Vector3.new(25, 0, 25),
		}
	do
		local pillar = Instance.new("Part")
		pillar.Anchored = true
		pillar.Size = Vector3.new(2, 8, 2)
		pillar.Position = zoneOffset + corner + Vector3.new(0, 3, 0)
		pillar.Color = zoneDef.AccentColor
		pillar.Material = Enum.Material.Neon
		pillar.Transparency = 0.5
		pillar.Parent = model
	end

	-- Portal to next zone (at far end)
	if zoneNumber < 6 then
		local nextZone = zoneNumber + 1
		local portal = createPortal(
			zoneOffset + Vector3.new(35, 5, 0),
			nextZone,
			VoidPetsConfig.Zones[nextZone].AccentColor,
			true -- starts locked, updated per-player on client
		)
		portal.Parent = model
	end

	-- Spawn point
	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Position = zoneOffset + Vector3.new(0, 0.5, 15)
	spawn.Transparency = 1
	spawn.CanCollide = true
	spawn.Neutral = true
	spawn.Parent = model

	model.Parent = workspace
	return model
end

function ZoneService:_buildAllZones()
	-- Remove default Baseplate and SpawnLocation to prevent Z-fighting
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
	end
	local defaultSpawn = workspace:FindFirstChild("SpawnLocation")
	if defaultSpawn then
		defaultSpawn:Destroy()
	end

	for zoneNumber = 1, 6 do
		zoneModels[zoneNumber] = self:_buildZone(zoneNumber)
	end
end

-- ============================================================================
-- Zone Unlocking
-- ============================================================================

function ZoneService:UnlockZone(player: Player, zoneNumber: number): (boolean, string?)
	PlayerDataService:WaitForProfile(player):expect()

	local zoneDef = VoidPetsConfig.Zones[zoneNumber]
	if not zoneDef then
		return false, "Invalid zone"
	end

	local unlockedZones = PlayerDataService:Read(player, { "UnlockedZones" }) or {}
	if unlockedZones[tostring(zoneNumber)] then
		return false, "Already unlocked"
	end

	-- Check previous zone is unlocked
	if zoneNumber > 1 and not unlockedZones[tostring(zoneNumber - 1)] then
		return false, "Unlock previous zone first"
	end

	local currentVE = PlayerDataService:Read(player, { "VoidEnergy" }) or 0
	if currentVE < zoneDef.UnlockCost then
		return false, "Not enough Void Energy"
	end

	PlayerDataService:Write(player, { "VoidEnergy" }, currentVE - zoneDef.UnlockCost)
	unlockedZones[tostring(zoneNumber)] = true
	PlayerDataService:Write(player, { "UnlockedZones" }, unlockedZones)

	self.ZoneUnlocked:Fire(player, zoneNumber)
	self.Client.ZoneUnlocked:Fire(player, zoneNumber)

	return true, nil
end

function ZoneService:TeleportToZone(player: Player, zoneNumber: number): boolean
	PlayerDataService:WaitForProfile(player):expect()

	local unlockedZones = PlayerDataService:Read(player, { "UnlockedZones" }) or {}
	if not unlockedZones[tostring(zoneNumber)] then
		return false
	end

	local zoneModel = zoneModels[zoneNumber]
	if not zoneModel then
		return false
	end

	local character = player.Character
	if not character then
		return false
	end
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then
		return false
	end

	-- Teleport to zone spawn
	local zoneOffset = Vector3.new((zoneNumber - 1) * 80, 5, 15)
	rootPart.CFrame = CFrame.new(zoneOffset)

	PlayerDataService:Write(player, { "CurrentZone" }, zoneNumber)
	self.PlayerChangedZone:Fire(player, zoneNumber)
	self.Client.ZoneChanged:Fire(player, zoneNumber)

	return true
end

-- ============================================================================
-- Client API
-- ============================================================================

function ZoneService.Client:GetUnlockedZones(player: Player)
	PlayerDataService:WaitForProfile(player):expect()
	return PlayerDataService:Read(player, { "UnlockedZones" }) or {}
end

function ZoneService.Client:GetCurrentZone(player: Player)
	PlayerDataService:WaitForProfile(player):expect()
	return PlayerDataService:Read(player, { "CurrentZone" }) or 1
end

function ZoneService.Client:UnlockZone(player: Player, zoneNumber: number)
	return self.Server:UnlockZone(player, zoneNumber)
end

function ZoneService.Client:TeleportToZone(player: Player, zoneNumber: number)
	return self.Server:TeleportToZone(player, zoneNumber)
end

-- ============================================================================
-- Lifecycle
-- ============================================================================

function ZoneService:KnitInit()
	PlayerDataService = Knit.GetService("PlayerDataService")
end

function ZoneService:KnitStart()
	-- Build all zone geometry
	self:_buildAllZones()

	-- Sync zone data to connected players
	for _, player in Players:GetPlayers() do
		task.spawn(function()
			PlayerDataService:WaitForProfile(player)
				:andThen(function()
					local zones = PlayerDataService:Read(player, { "UnlockedZones" }) or {}
					local current = PlayerDataService:Read(player, { "CurrentZone" }) or 1
					self.Client.ZonesSync:Fire(player, zones, current)
					-- Teleport to their current zone
					self:TeleportToZone(player, current)
				end)
				:catch(function(err)
					warn(`ZoneService: Failed to sync for {player.Name}: {err}`)
				end)
		end)
	end

	-- New player setup
	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			PlayerDataService:WaitForProfile(player)
				:andThen(function()
					local zones = PlayerDataService:Read(player, { "UnlockedZones" }) or {}
					local current = PlayerDataService:Read(player, { "CurrentZone" }) or 1
					self.Client.ZonesSync:Fire(player, zones, current)

					-- Wait for character then teleport
					if not player.Character then
						player.CharacterAdded:Wait()
						task.wait(0.5)
					end
					self:TeleportToZone(player, current)
				end)
				:catch(function(err)
					warn(`ZoneService: Failed to init for {player.Name}: {err}`)
				end)
		end)
	end)
end

return ZoneService
