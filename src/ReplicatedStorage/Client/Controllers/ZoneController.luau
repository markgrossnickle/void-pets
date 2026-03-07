--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local VoidPetsConfig = require(ReplicatedStorage.Shared.VoidPetsConfig)
local LocalPlayer = Players.LocalPlayer

--[=[
	@class ZoneController
	Zone visuals, portal interaction, atmosphere, zone transitions.
]=]
local ZoneController = Knit.CreateController({
	Name = "ZoneController",
})

local ZoneService
local unlockedZones: { [string]: boolean } = {}
local currentZone = 1

-- ============================================================================
-- Atmosphere
-- ============================================================================

local function applyZoneAtmosphere(zoneNumber: number)
	local zoneDef = VoidPetsConfig.Zones[zoneNumber]
	if not zoneDef then
		return
	end

	-- Tween lighting
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Parent = Lighting
	end

	TweenService:Create(Lighting, TweenInfo.new(1), {
		Ambient = zoneDef.AmbientColor,
		OutdoorAmbient = zoneDef.AmbientColor,
		FogColor = zoneDef.AmbientColor,
	}):Play()

	-- Sky color
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if not sky then
		sky = Instance.new("Sky")
		sky.StarCount = 3000
		sky.CelestialBodiesShown = false
		sky.Parent = Lighting
	end

	-- Zone 5 (Cosmic) gets extra stars
	sky.StarCount = if zoneNumber == 5 then 5000 else 3000
end

-- ============================================================================
-- Portal Interaction
-- ============================================================================

local function setupPortalTouchDetection()
	-- Check proximity to portals each frame
	local character = LocalPlayer.Character
	if not character then
		return
	end

	for _, obj in workspace:GetDescendants() do
		if obj:IsA("BasePart") and obj:GetAttribute("PortalZone") then
			local targetZone = obj:GetAttribute("PortalZone")

			-- Create a touch detector
			local touch = Instance.new("ClickDetector")
			touch.MaxActivationDistance = 10
			touch.Parent = obj

			touch.MouseClick:Connect(function(player)
				if player ~= LocalPlayer then
					return
				end

				if unlockedZones[tostring(targetZone)] then
					-- Teleport
					ZoneService:TeleportToZone(targetZone)
				else
					-- Try to unlock
					task.spawn(function()
						local ok, err = ZoneService:UnlockZone(targetZone):await()
						if not ok then
							warn(`Cannot unlock zone: {err}`)
						end
					end)
				end
			end)
		end
	end
end

-- ============================================================================
-- Zone Transition Effect
-- ============================================================================

local function playZoneTransition(callback: () -> ())
	local gui = Instance.new("ScreenGui")
	gui.Name = "ZoneTransition"
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 200
	gui.Parent = LocalPlayer.PlayerGui

	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.Parent = gui

	-- Fade in
	local fadeIn = TweenService:Create(overlay, TweenInfo.new(0.3), { BackgroundTransparency = 0 })
	fadeIn:Play()
	fadeIn.Completed:Once(function()
		callback()
		task.wait(0.2)
		-- Fade out
		local fadeOut = TweenService:Create(overlay, TweenInfo.new(0.4), { BackgroundTransparency = 1 })
		fadeOut:Play()
		fadeOut.Completed:Once(function()
			gui:Destroy()
		end)
	end)
end

-- ============================================================================
-- Portal Visual Updates
-- ============================================================================

local function updatePortalVisuals()
	for _, obj in workspace:GetDescendants() do
		if obj:IsA("BasePart") and obj:GetAttribute("PortalZone") then
			local targetZone = obj:GetAttribute("PortalZone")
			local isUnlocked = unlockedZones[tostring(targetZone)] == true

			local zoneDef = VoidPetsConfig.Zones[targetZone]
			if not zoneDef then
				continue
			end

			obj.Color = if isUnlocked then zoneDef.AccentColor else Color3.fromRGB(200, 50, 50)

			local light = obj:FindFirstChildOfClass("PointLight")
			if light then
				light.Color = obj.Color
			end

			-- Update or hide cost label
			local bbg = obj:FindFirstChildOfClass("BillboardGui")
			if bbg and isUnlocked then
				bbg.Enabled = false
			end
		end
	end
end

-- ============================================================================
-- Public API
-- ============================================================================

function ZoneController:GetCurrentZone(): number
	return currentZone
end

function ZoneController:GetUnlockedZones(): { [string]: boolean }
	return unlockedZones
end

function ZoneController:IsZoneUnlocked(zoneNumber: number): boolean
	return unlockedZones[tostring(zoneNumber)] == true
end

function ZoneController:TeleportToZone(zoneNumber: number)
	playZoneTransition(function()
		task.spawn(function()
			local ok = ZoneService:TeleportToZone(zoneNumber):await()
			if ok then
				currentZone = zoneNumber
				applyZoneAtmosphere(zoneNumber)
			end
		end)
	end)
end

function ZoneController:UnlockZone(zoneNumber: number)
	task.spawn(function()
		local ok, err = ZoneService:UnlockZone(zoneNumber):await()
		if not ok then
			warn(`Failed to unlock zone {zoneNumber}: {err}`)
		end
	end)
end

-- ============================================================================
-- Lifecycle
-- ============================================================================

function ZoneController:KnitInit()
	ZoneService = Knit.GetService("ZoneService")
end

function ZoneController:KnitStart()
	-- Initial sync
	task.spawn(function()
		local ok1, zones = ZoneService:GetUnlockedZones():await()
		local ok2, zone = ZoneService:GetCurrentZone():await()
		if ok1 then
			unlockedZones = zones
		end
		if ok2 then
			currentZone = zone
		end
		applyZoneAtmosphere(currentZone)
		updatePortalVisuals()

		-- Setup portal interactions after zones are built
		task.wait(1)
		setupPortalTouchDetection()
	end)

	-- Listen for zone unlocks
	ZoneService.ZoneUnlocked:Connect(function(zoneNumber)
		unlockedZones[tostring(zoneNumber)] = true
		updatePortalVisuals()
	end)

	-- Listen for zone changes
	ZoneService.ZoneChanged:Connect(function(zoneNumber)
		currentZone = zoneNumber
		applyZoneAtmosphere(zoneNumber)
	end)

	ZoneService.ZonesSync:Connect(function(zones, zone)
		unlockedZones = zones
		currentZone = zone
		applyZoneAtmosphere(zone)
		updatePortalVisuals()
	end)
end

return ZoneController
