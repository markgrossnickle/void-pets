--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local VoidPetsConfig = require(ReplicatedStorage.Shared.VoidPetsConfig)
local PlatformUtil = require(ReplicatedStorage.Shared.PlatformUtil)

local LocalPlayer = Players.LocalPlayer

--[=[
	@class ClickController
	Crystal interaction, click effects, VE display, combo counter.
]=]
local ClickController = Knit.CreateController({
	Name = "ClickController",
})

local ClickService
local currentVE = 0
local vePerClick = 1
local comboCount = 0
local lastClickTime = 0

-- ============================================================================
-- Floating Text Effect
-- ============================================================================

local function showFloatingText(amount: number, position: Vector3, isCombo: boolean)
	local bbg = Instance.new("BillboardGui")
	bbg.Size = UDim2.fromOffset(120, 40)
	bbg.StudsOffset = Vector3.new((math.random() - 0.5) * 2, math.random() * 1 + 1, (math.random() - 0.5) * 2)
	bbg.AlwaysOnTop = true
	bbg.MaxDistance = 50

	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Size = Vector3.new(0.1, 0.1, 0.1)
	part.Position = position + Vector3.new(0, 2, 0)
	part.Parent = workspace

	bbg.Adornee = part
	bbg.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = `+{PlatformUtil.FormatNumber(amount)} VE`
	label.TextColor3 = if isCombo then Color3.fromRGB(255, 200, 40) else Color3.fromRGB(180, 100, 255)
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = bbg

	if isCombo and comboCount > 1 then
		label.Text = `+{PlatformUtil.FormatNumber(amount)} VE x{comboCount}`
	end

	-- Float up and fade
	local tween = TweenService:Create(part, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = part.Position + Vector3.new(0, 3, 0),
	})
	tween:Play()

	TweenService:Create(label, TweenInfo.new(1.2), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()

	task.delay(1.3, function()
		part:Destroy()
	end)
end

-- ============================================================================
-- Crystal Pulse Effect
-- ============================================================================

local function pulseCrystal(crystal: BasePart)
	local originalSize = crystal.Size
	local pulseSize = originalSize * 1.08

	local grow = TweenService:Create(crystal, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = pulseSize,
	})
	grow:Play()
	grow.Completed:Once(function()
		TweenService:Create(crystal, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = originalSize,
		}):Play()
	end)

	-- Particle burst
	local emitter = crystal:FindFirstChildOfClass("ParticleEmitter")
	if emitter then
		emitter:Emit(if PlatformUtil.IsMobile() then 3 else 6)
	end
end

-- ============================================================================
-- Click / Tap Handling
-- ============================================================================

local function findCrystalFromTarget(target: Instance?): BasePart?
	if not target then
		return nil
	end
	-- Walk up parents to find a tagged crystal
	local current: Instance? = target
	while current and current ~= workspace do
		if current:IsA("BasePart") and current:GetAttribute("VoidCrystal") then
			return current :: BasePart
		end
		current = current.Parent
	end
	return nil
end

local function onClickInput()
	local now = os.clock()

	-- Combo logic
	if now - lastClickTime < VoidPetsConfig.Click.ComboWindow then
		comboCount = math.min(comboCount + 1, VoidPetsConfig.Click.MaxCombo)
	else
		comboCount = 1
	end
	lastClickTime = now

	-- Send click to server
	task.spawn(function()
		local ok, veEarned = ClickService:Click():await()
		if ok and veEarned then
			currentVE = currentVE + veEarned

			-- Find nearest crystal for effect position
			local character = LocalPlayer.Character
			if character and character:FindFirstChild("HumanoidRootPart") then
				local rootPos = (character.HumanoidRootPart :: BasePart).Position
				showFloatingText(veEarned, rootPos, comboCount > 1)
			end
		end
	end)
end

-- ============================================================================
-- Public API
-- ============================================================================

function ClickController:GetCurrentVE(): number
	return currentVE
end

function ClickController:GetVEPerClick(): number
	return vePerClick
end

function ClickController:GetComboCount(): number
	return comboCount
end

function ClickController:PurchaseAutoClick()
	return ClickService:PurchaseAutoClick()
end

-- ============================================================================
-- Lifecycle
-- ============================================================================

function ClickController:KnitInit()
	ClickService = Knit.GetService("ClickService")
end

function ClickController:KnitStart()
	-- Get initial VE
	task.spawn(function()
		local ok, ve = ClickService:GetVoidEnergy():await()
		if ok then
			currentVE = ve
		end
		local ok2, vpc = ClickService:GetVEPerClick():await()
		if ok2 then
			vePerClick = vpc
		end
	end)

	-- Listen for VE changes from server (auto-click, etc.)
	ClickService.VoidEnergyChanged:Connect(function(newVE, _delta, vpc)
		currentVE = newVE
		if vpc then
			vePerClick = vpc
		end
	end)

	ClickService.ClickRegistered:Connect(function(_veEarned)
		-- Update VE per click periodically
		task.spawn(function()
			local ok, vpc = ClickService:GetVEPerClick():await()
			if ok then
				vePerClick = vpc
			end
		end)
	end)

	-- Mouse click on crystals
	local mouse = LocalPlayer:GetMouse()
	mouse.Button1Down:Connect(function()
		local crystal = findCrystalFromTarget(mouse.Target)
		if crystal then
			pulseCrystal(crystal)
			onClickInput()
		end
	end)

	-- Touch support (tap on crystal)
	UserInputService.TouchTap:Connect(function(touchPositions)
		if #touchPositions == 0 then
			return
		end
		local pos = touchPositions[1]
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end
		local ray = camera:ViewportPointToRay(pos.X, pos.Y)
		local result = workspace:Raycast(ray.Origin, ray.Direction * 100)
		if result then
			local crystal = findCrystalFromTarget(result.Instance)
			if crystal then
				pulseCrystal(crystal)
				onClickInput()
			end
		end
	end)

	-- Gamepad support: A button when near crystal
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.KeyCode == Enum.KeyCode.ButtonA then
			-- Find nearest crystal
			local character = LocalPlayer.Character
			if not character or not character:FindFirstChild("HumanoidRootPart") then
				return
			end
			local rootPos = (character.HumanoidRootPart :: BasePart).Position
			-- Simple proximity check for crystals in workspace
			for _, obj in workspace:GetDescendants() do
				if obj:IsA("BasePart") and obj:GetAttribute("VoidCrystal") then
					if (obj.Position - rootPos).Magnitude < 15 then
						pulseCrystal(obj)
						onClickInput()
						break
					end
				end
			end
		end
	end)
end

return ClickController
