--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)

local VoidPetsConfig = require(ReplicatedStorage.Shared.VoidPetsConfig)
local PlatformUtil = require(ReplicatedStorage.Shared.PlatformUtil)

--[=[
	@class EggController
	Egg pedestals, hatch animation, pet reveal on the client.
]=]
local EggController = Knit.CreateController({
	Name = "EggController",
})

local EggService
local autoHatchEnabled = false
local autoHatchTrove = Trove.new()

-- ============================================================================
-- Egg Hatch Animation
-- ============================================================================

local function createEggVisual(eggId: string, position: Vector3): Model
	local eggDef = VoidPetsConfig.Eggs[eggId]
	local zone = if eggDef then eggDef.Zone else 1
	local zoneDef = VoidPetsConfig.Zones[zone]
	local accentColor = if zoneDef then zoneDef.AccentColor else Color3.fromRGB(160, 60, 220)

	local model = Instance.new("Model")
	model.Name = "HatchingEgg"

	-- Egg body (ellipsoid via mesh)
	local eggPart = Instance.new("Part")
	eggPart.Name = "EggBody"
	eggPart.Anchored = true
	eggPart.CanCollide = false
	eggPart.Size = Vector3.new(2, 2.8, 2)
	eggPart.Shape = Enum.PartType.Ball
	eggPart.Position = position
	eggPart.Color = accentColor
	eggPart.Material = Enum.Material.SmoothPlastic
	eggPart.Parent = model

	-- Glow
	local light = Instance.new("PointLight")
	light.Color = accentColor
	light.Brightness = 2
	light.Range = 8
	light.Parent = eggPart

	model.PrimaryPart = eggPart
	model.Parent = workspace

	return model
end

local function playHatchAnimation(eggModel: Model, rarity: string, callback: () -> ())
	local eggPart = eggModel.PrimaryPart
	if not eggPart then
		callback()
		return
	end

	local rarityInfo = VoidPetsConfig.Rarities[rarity]
	local duration = VoidPetsConfig.Hatch.HatchDuration

	-- Phase 1: Wobble (0 to duration * 0.6)
	local wobbleTime = duration * 0.6
	local startTime = os.clock()

	local wobbleConn
	wobbleConn = game:GetService("RunService").Heartbeat:Connect(function()
		local elapsed = os.clock() - startTime
		if elapsed > wobbleTime then
			if wobbleConn then
				wobbleConn:Disconnect()
			end
			return
		end
		local intensity = elapsed / wobbleTime * 15
		local wobble = math.sin(elapsed * intensity) * 5
		eggPart.CFrame = CFrame.new(eggPart.Position) * CFrame.Angles(0, 0, math.rad(wobble))
	end)

	-- Phase 2: Crack + burst
	task.delay(wobbleTime, function()
		-- Create crack lines
		for i = 1, 4 do
			local crack = Instance.new("Part")
			crack.Name = "Crack"
			crack.Anchored = true
			crack.CanCollide = false
			crack.Size = Vector3.new(0.1, 0.8, 0.1)
			crack.Color = Color3.new(1, 1, 1)
			crack.Material = Enum.Material.Neon
			crack.CFrame = eggPart.CFrame * CFrame.Angles(0, math.rad(i * 90), math.rad(30))
			crack.Parent = eggModel
		end

		-- Light intensifies
		local light = eggPart:FindFirstChildOfClass("PointLight")
		if light then
			TweenService:Create(light, TweenInfo.new(duration * 0.3), { Brightness = 10, Range = 20 }):Play()
		end
	end)

	-- Phase 3: Burst open
	task.delay(duration * 0.9, function()
		-- Scale down egg parts
		for _, part in eggModel:GetDescendants() do
			if part:IsA("BasePart") then
				TweenService:Create(part, TweenInfo.new(0.15), { Transparency = 1 }):Play()
			end
		end

		-- Light burst
		local burst = Instance.new("Part")
		burst.Name = "Burst"
		burst.Anchored = true
		burst.CanCollide = false
		burst.Shape = Enum.PartType.Ball
		burst.Size = Vector3.new(0.5, 0.5, 0.5)
		burst.Position = eggPart.Position
		burst.Color = if rarityInfo then rarityInfo.Color else Color3.new(1, 1, 1)
		burst.Material = Enum.Material.Neon
		burst.Transparency = 0.3
		burst.Parent = workspace

		TweenService
			:Create(burst, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = Vector3.new(8, 8, 8),
				Transparency = 1,
			})
			:Play()

		task.delay(0.6, function()
			burst:Destroy()
		end)
	end)

	-- Cleanup and callback
	task.delay(duration, function()
		eggModel:Destroy()
		callback()
	end)
end

-- ============================================================================
-- Pet Reveal
-- ============================================================================

local function showPetReveal(result: any)
	local petDef = VoidPetsConfig.Pets[result.PetType]
	local rarityInfo = VoidPetsConfig.Rarities[result.Rarity]
	if not petDef or not rarityInfo then
		return
	end

	-- Create reveal GUI
	local gui = Instance.new("ScreenGui")
	gui.Name = "PetReveal"
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 100
	gui.Parent = game:GetService("Players").LocalPlayer.PlayerGui

	-- Background overlay
	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.Parent = gui

	TweenService:Create(overlay, TweenInfo.new(0.3), { BackgroundTransparency = 0.6 }):Play()

	-- Pet name + rarity banner
	local banner = Instance.new("Frame")
	banner.Size = UDim2.fromScale(0.5, 0.2)
	banner.Position = UDim2.fromScale(0.25, 0.4)
	banner.BackgroundTransparency = 1
	banner.Parent = gui

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.fromScale(1, 0.5)
	nameLabel.Position = UDim2.fromScale(0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = petDef.Name
	nameLabel.TextColor3 = rarityInfo.Color
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.Parent = banner

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.fromScale(1, 0.3)
	rarityLabel.Position = UDim2.fromScale(0, 0.5)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = result.Rarity
	rarityLabel.TextColor3 = rarityInfo.Color
	rarityLabel.TextStrokeTransparency = 0.3
	rarityLabel.Font = Enum.Font.Gotham
	rarityLabel.TextScaled = true
	rarityLabel.Parent = banner

	local multiplierLabel = Instance.new("TextLabel")
	multiplierLabel.Size = UDim2.fromScale(1, 0.2)
	multiplierLabel.Position = UDim2.fromScale(0, 0.8)
	multiplierLabel.BackgroundTransparency = 1
	multiplierLabel.Text = `{rarityInfo.Multiplier}x Multiplier`
	multiplierLabel.TextColor3 = Color3.new(1, 1, 1)
	multiplierLabel.Font = Enum.Font.Gotham
	multiplierLabel.TextScaled = true
	multiplierLabel.Parent = banner

	if result.IsNew then
		local newLabel = Instance.new("TextLabel")
		newLabel.Size = UDim2.fromScale(0.3, 0.08)
		newLabel.Position = UDim2.fromScale(0.35, 0.35)
		newLabel.BackgroundColor3 = Color3.fromRGB(255, 200, 40)
		newLabel.BackgroundTransparency = 0.2
		newLabel.Text = "NEW!"
		newLabel.TextColor3 = Color3.new(0, 0, 0)
		newLabel.Font = Enum.Font.GothamBold
		newLabel.TextScaled = true
		newLabel.Parent = gui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.3, 0)
		corner.Parent = newLabel
	end

	-- Auto dismiss
	task.delay(2, function()
		TweenService:Create(overlay, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
		for _, child in gui:GetChildren() do
			if child:IsA("GuiObject") then
				TweenService:Create(child, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
			end
		end
		task.delay(0.4, function()
			gui:Destroy()
		end)
	end)
end

-- ============================================================================
-- Public API
-- ============================================================================

function EggController:HatchEgg(eggId: string)
	-- Fire to server
	local ok, result = EggService:HatchEgg(eggId):await()
	if not ok or not result then
		return false
	end
	return true
end

function EggController:TripleHatch(eggId: string)
	local ok, results = EggService:TripleHatch(eggId):await()
	if not ok or not results then
		return false
	end
	return true
end

function EggController:SetAutoHatch(enabled: boolean, eggId: string?)
	autoHatchEnabled = enabled
	autoHatchTrove:Clean()

	if enabled and eggId then
		local delay = VoidPetsConfig.Hatch.AutoHatchDelay
		task.spawn(function()
			while autoHatchEnabled do
				local ok = self:HatchEgg(eggId)
				if not ok then
					autoHatchEnabled = false
					break
				end
				task.wait(delay)
			end
		end)
	end
end

function EggController:IsAutoHatching(): boolean
	return autoHatchEnabled
end

function EggController:GetEggCost(eggId: string): number
	local eggDef = VoidPetsConfig.Eggs[eggId]
	return if eggDef then eggDef.Cost else 0
end

-- ============================================================================
-- Lifecycle
-- ============================================================================

function EggController:KnitInit()
	EggService = Knit.GetService("EggService")
end

function EggController:KnitStart()
	-- Listen for hatch results
	EggService.EggHatched:Connect(function(eggId, result, _isNew)
		-- Find egg position (use character position as fallback)
		local character = game:GetService("Players").LocalPlayer.Character
		local pos = if character and character:FindFirstChild("HumanoidRootPart")
			then (character.HumanoidRootPart :: BasePart).Position + Vector3.new(0, 3, -5)
			else Vector3.new(0, 5, 0)

		if not autoHatchEnabled then
			-- Full animation for manual hatches
			local eggModel = createEggVisual(eggId, pos)
			playHatchAnimation(eggModel, result.Rarity, function()
				showPetReveal(result)
			end)
		else
			-- Quick reveal for auto-hatch
			showPetReveal(result)
		end
	end)
end

return EggController
