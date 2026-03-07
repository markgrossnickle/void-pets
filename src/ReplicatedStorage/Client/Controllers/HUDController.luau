--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local VoidPetsConfig = require(ReplicatedStorage.Shared.VoidPetsConfig)
local PlatformUtil = require(ReplicatedStorage.Shared.PlatformUtil)

local LocalPlayer = Players.LocalPlayer

--[=[
	@class HUDController
	Main HUD: VE counter, pet slots, zone indicator, inventory button, rebirth button, settings.
]=]
local HUDController = Knit.CreateController({
	Name = "HUDController",
})

local RebirthService
local PetService

local screenGui: ScreenGui
local veLabel: TextLabel
local vePerClickLabel: TextLabel
local zoneLabel: TextLabel
local rebirthButton: TextButton
local inventoryButton: TextButton
local autoHatchToggle: TextButton
local petSlotFrames: { Frame } = {}
local inventoryFrame: Frame?

-- ============================================================================
-- UI Creation Helpers
-- ============================================================================

local function createRoundedFrame(props: {
	Name: string,
	Size: UDim2,
	Position: UDim2,
	Color: Color3?,
	Transparency: number?,
	Parent: Instance,
}): Frame
	local frame = Instance.new("Frame")
	frame.Name = props.Name
	frame.Size = props.Size
	frame.Position = props.Position
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = props.Color or Color3.fromRGB(20, 10, 30)
	frame.BackgroundTransparency = props.Transparency or 0.3
	frame.BorderSizePixel = 0
	frame.Parent = props.Parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(120, 60, 180)
	stroke.Thickness = 1
	stroke.Transparency = 0.5
	stroke.Parent = frame

	return frame
end

local function createTextButton(props: {
	Name: string,
	Size: UDim2,
	Position: UDim2,
	Text: string,
	Color: Color3?,
	TextColor: Color3?,
	Parent: Instance,
}): TextButton
	local btn = Instance.new("TextButton")
	btn.Name = props.Name
	btn.Size = props.Size
	btn.Position = props.Position
	btn.AnchorPoint = Vector2.new(0.5, 0.5)
	btn.BackgroundColor3 = props.Color or Color3.fromRGB(60, 30, 90)
	btn.BorderSizePixel = 0
	btn.Text = props.Text
	btn.TextColor3 = props.TextColor or Color3.new(1, 1, 1)
	btn.Font = Enum.Font.GothamBold
	btn.TextScaled = true
	btn.AutoButtonColor = true
	btn.Parent = props.Parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btn

	-- Minimum touch size
	btn.Size = UDim2.new(
		props.Size.X.Scale,
		math.max(props.Size.X.Offset, 48),
		props.Size.Y.Scale,
		math.max(props.Size.Y.Offset, 48)
	)

	return btn
end

-- ============================================================================
-- HUD Layout
-- ============================================================================

local function buildHUD()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "VoidPetsHUD"
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = LocalPlayer.PlayerGui

	-- VE Counter (top center)
	local veFrame = createRoundedFrame({
		Name = "VEFrame",
		Size = UDim2.fromScale(0.3, 0.06),
		Position = UDim2.fromScale(0.5, 0.06),
		Parent = screenGui,
	})

	veLabel = Instance.new("TextLabel")
	veLabel.Name = "VELabel"
	veLabel.Size = UDim2.fromScale(1, 0.65)
	veLabel.Position = UDim2.fromScale(0, 0)
	veLabel.BackgroundTransparency = 1
	veLabel.Text = "0 VE"
	veLabel.TextColor3 = Color3.fromRGB(200, 140, 255)
	veLabel.TextStrokeTransparency = 0.3
	veLabel.Font = Enum.Font.GothamBold
	veLabel.TextScaled = true
	veLabel.Parent = veFrame

	vePerClickLabel = Instance.new("TextLabel")
	vePerClickLabel.Name = "VEPerClickLabel"
	vePerClickLabel.Size = UDim2.fromScale(1, 0.35)
	vePerClickLabel.Position = UDim2.fromScale(0, 0.65)
	vePerClickLabel.BackgroundTransparency = 1
	vePerClickLabel.Text = "+1 per click"
	vePerClickLabel.TextColor3 = Color3.fromRGB(150, 100, 200)
	vePerClickLabel.Font = Enum.Font.Gotham
	vePerClickLabel.TextScaled = true
	vePerClickLabel.Parent = veFrame

	-- Zone Indicator (top left)
	local zoneFrame = createRoundedFrame({
		Name = "ZoneFrame",
		Size = UDim2.fromScale(0.15, 0.04),
		Position = UDim2.fromScale(0.12, 0.06),
		Parent = screenGui,
	})

	zoneLabel = Instance.new("TextLabel")
	zoneLabel.Name = "ZoneLabel"
	zoneLabel.Size = UDim2.fromScale(1, 1)
	zoneLabel.BackgroundTransparency = 1
	zoneLabel.Text = "Void Nursery"
	zoneLabel.TextColor3 = Color3.fromRGB(160, 60, 220)
	zoneLabel.Font = Enum.Font.GothamBold
	zoneLabel.TextScaled = true
	zoneLabel.Parent = zoneFrame

	-- Pet Slots (bottom left)
	local petSlotsFrame = createRoundedFrame({
		Name = "PetSlots",
		Size = UDim2.fromScale(0.25, 0.08),
		Position = UDim2.fromScale(0.15, 0.92),
		Parent = screenGui,
	})

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 4)
	layout.Parent = petSlotsFrame

	for i = 1, 6 do
		local slot = Instance.new("Frame")
		slot.Name = `PetSlot{i}`
		slot.Size = UDim2.fromScale(0.14, 0.85)
		slot.BackgroundColor3 = Color3.fromRGB(40, 20, 60)
		slot.BackgroundTransparency = 0.5
		slot.Visible = i <= 3
		slot.Parent = petSlotsFrame

		local slotCorner = Instance.new("UICorner")
		slotCorner.CornerRadius = UDim.new(0, 6)
		slotCorner.Parent = slot

		local slotLabel = Instance.new("TextLabel")
		slotLabel.Name = "Label"
		slotLabel.Size = UDim2.fromScale(1, 1)
		slotLabel.BackgroundTransparency = 1
		slotLabel.Text = ""
		slotLabel.TextColor3 = Color3.new(1, 1, 1)
		slotLabel.Font = Enum.Font.GothamBold
		slotLabel.TextScaled = true
		slotLabel.Parent = slot

		table.insert(petSlotFrames, slot)
	end

	-- Inventory Button (bottom right)
	inventoryButton = createTextButton({
		Name = "InventoryBtn",
		Size = UDim2.fromScale(0.1, 0.06),
		Position = UDim2.fromScale(0.9, 0.92),
		Text = "Pets",
		Parent = screenGui,
	})

	inventoryButton.Activated:Connect(function()
		HUDController:ToggleInventory()
	end)

	-- Rebirth Button (right side, hidden initially)
	rebirthButton = createTextButton({
		Name = "RebirthBtn",
		Size = UDim2.fromScale(0.1, 0.06),
		Position = UDim2.fromScale(0.9, 0.82),
		Text = "Rebirth",
		Color = Color3.fromRGB(180, 140, 40),
		Parent = screenGui,
	})
	rebirthButton.Visible = false

	rebirthButton.Activated:Connect(function()
		task.spawn(function()
			local ok, err = RebirthService:DoRebirth():await()
			if not ok then
				warn(`Rebirth failed: {err}`)
			end
		end)
	end)

	-- Auto-Hatch Toggle (near bottom center)
	autoHatchToggle = createTextButton({
		Name = "AutoHatchToggle",
		Size = UDim2.fromScale(0.08, 0.04),
		Position = UDim2.fromScale(0.5, 0.92),
		Text = "Auto: OFF",
		Color = Color3.fromRGB(60, 60, 60),
		Parent = screenGui,
	})

	autoHatchToggle.Activated:Connect(function()
		local EggController = Knit.GetController("EggController")
		local ZoneController = Knit.GetController("ZoneController")
		local isAuto = EggController:IsAutoHatching()
		local currentZone = ZoneController:GetCurrentZone()
		local basicEggId = `BasicEgg{currentZone}`

		if isAuto then
			EggController:SetAutoHatch(false)
			autoHatchToggle.Text = "Auto: OFF"
			autoHatchToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		else
			EggController:SetAutoHatch(true, basicEggId)
			autoHatchToggle.Text = "Auto: ON"
			autoHatchToggle.BackgroundColor3 = Color3.fromRGB(40, 140, 40)
		end
	end)
end

-- ============================================================================
-- Inventory Panel
-- ============================================================================

local function buildInventoryPanel()
	if inventoryFrame then
		return
	end

	inventoryFrame = createRoundedFrame({
		Name = "InventoryPanel",
		Size = UDim2.fromScale(0.6, 0.7),
		Position = UDim2.fromScale(0.5, 0.5),
		Color = Color3.fromRGB(15, 8, 25),
		Transparency = 0.1,
		Parent = screenGui,
	})
	inventoryFrame.Visible = false

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.fromScale(1, 0.08)
	title.Position = UDim2.fromScale(0, 0)
	title.BackgroundTransparency = 1
	title.Text = "Pet Inventory"
	title.TextColor3 = Color3.fromRGB(200, 140, 255)
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.Parent = inventoryFrame

	-- Close button
	local closeBtn = createTextButton({
		Name = "CloseBtn",
		Size = UDim2.fromOffset(40, 40),
		Position = UDim2.new(0.97, 0, 0.04, 0),
		Text = "X",
		Color = Color3.fromRGB(150, 40, 40),
		Parent = inventoryFrame,
	})

	closeBtn.Activated:Connect(function()
		HUDController:ToggleInventory()
	end)

	-- Scrolling pet grid
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "PetGrid"
	scroll.Size = UDim2.fromScale(0.95, 0.85)
	scroll.Position = UDim2.fromScale(0.025, 0.1)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 6
	scroll.ScrollBarImageColor3 = Color3.fromRGB(120, 60, 180)
	scroll.CanvasSize = UDim2.fromScale(0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = inventoryFrame

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(90, 110)
	grid.CellPadding = UDim2.fromOffset(8, 8)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = scroll
end

local function refreshInventory()
	if not inventoryFrame then
		return
	end

	local PetController = Knit.GetController("PetController")
	local inventory = PetController:GetInventory()
	local equipped = PetController:GetEquippedSlots()
	local equippedSet: { [number]: boolean } = {}
	for _, idx in equipped do
		equippedSet[idx] = true
	end

	local scroll = inventoryFrame:FindFirstChild("PetGrid") :: ScrollingFrame?
	if not scroll then
		return
	end

	-- Clear existing
	for _, child in scroll:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	for i, petData in inventory do
		local petDef = VoidPetsConfig.Pets[petData.Type]
		local rarityInfo = VoidPetsConfig.Rarities[petData.Rarity]
		if not petDef or not rarityInfo then
			continue
		end

		local card = Instance.new("Frame")
		card.Name = `Pet_{i}`
		card.BackgroundColor3 = Color3.fromRGB(30, 15, 45)
		card.BorderSizePixel = 0
		card.LayoutOrder = i

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 6)
		cardCorner.Parent = card

		-- Rarity border
		local border = Instance.new("UIStroke")
		border.Color = rarityInfo.Color
		border.Thickness = if equippedSet[i] then 3 else 1
		border.Parent = card

		-- Pet name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.fromScale(1, 0.3)
		nameLabel.Position = UDim2.fromScale(0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = petDef.Name
		nameLabel.TextColor3 = rarityInfo.Color
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextScaled = true
		nameLabel.Parent = card

		-- Rarity + Level
		local infoLabel = Instance.new("TextLabel")
		infoLabel.Size = UDim2.fromScale(1, 0.2)
		infoLabel.Position = UDim2.fromScale(0, 0.3)
		infoLabel.BackgroundTransparency = 1
		infoLabel.Text = `{petData.Rarity} Lv.{petData.Level}`
		infoLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
		infoLabel.Font = Enum.Font.Gotham
		infoLabel.TextScaled = true
		infoLabel.Parent = card

		-- Multiplier
		local levelBonus = 1 + (petData.Level - 1) * VoidPetsConfig.PetConfig.LevelUpMultiplierBonus
		local mult = rarityInfo.Multiplier * levelBonus
		local multLabel = Instance.new("TextLabel")
		multLabel.Size = UDim2.fromScale(1, 0.15)
		multLabel.Position = UDim2.fromScale(0, 0.5)
		multLabel.BackgroundTransparency = 1
		multLabel.Text = `{string.format("%.1f", mult)}x`
		multLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
		multLabel.Font = Enum.Font.Gotham
		multLabel.TextScaled = true
		multLabel.Parent = card

		-- Equip/Unequip button
		local equipBtn = Instance.new("TextButton")
		equipBtn.Size = UDim2.fromScale(0.9, 0.2)
		equipBtn.Position = UDim2.fromScale(0.05, 0.7)
		equipBtn.BackgroundColor3 = if equippedSet[i] then Color3.fromRGB(150, 40, 40) else Color3.fromRGB(40, 100, 40)
		equipBtn.Text = if equippedSet[i] then "Unequip" else "Equip"
		equipBtn.TextColor3 = Color3.new(1, 1, 1)
		equipBtn.Font = Enum.Font.GothamBold
		equipBtn.TextScaled = true
		equipBtn.AutoButtonColor = true
		equipBtn.Parent = card

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 4)
		btnCorner.Parent = equipBtn

		local petIndex = i
		equipBtn.Activated:Connect(function()
			if equippedSet[petIndex] then
				PetController:UnequipPet(petIndex)
			else
				PetController:EquipPet(petIndex)
			end
			task.wait(0.3)
			refreshInventory()
		end)

		card.Parent = scroll
	end
end

-- ============================================================================
-- Update Loop
-- ============================================================================

local function updateHUD()
	local ClickController = Knit.GetController("ClickController")
	local ZoneController = Knit.GetController("ZoneController")
	local PetController = Knit.GetController("PetController")

	-- Update VE
	local ve = ClickController:GetCurrentVE()
	veLabel.Text = `{PlatformUtil.FormatNumber(ve)} VE`

	local vpc = ClickController:GetVEPerClick()
	vePerClickLabel.Text = `+{PlatformUtil.FormatNumber(vpc)} per click`

	-- Update zone
	local zone = ZoneController:GetCurrentZone()
	local zoneDef = VoidPetsConfig.Zones[zone]
	if zoneDef then
		zoneLabel.Text = zoneDef.Name
		zoneLabel.TextColor3 = zoneDef.AccentColor
	end

	-- Update pet slots
	local equipped = PetController:GetEquippedSlots()
	local inventory = PetController:GetInventory()

	for i, slot in petSlotFrames do
		local label = slot:FindFirstChild("Label") :: TextLabel?
		if not label then
			continue
		end

		if i <= #equipped then
			local petData = inventory[equipped[i]]
			if petData then
				local petDef = VoidPetsConfig.Pets[petData.Type]
				local rarityInfo = VoidPetsConfig.Rarities[petData.Rarity]
				label.Text = if petDef then string.sub(petDef.Name, 1, 6) else "?"
				label.TextColor3 = if rarityInfo then rarityInfo.Color else Color3.new(1, 1, 1)
				slot.BackgroundTransparency = 0.3
			else
				label.Text = ""
				slot.BackgroundTransparency = 0.7
			end
		else
			label.Text = ""
			slot.BackgroundTransparency = 0.7
		end
	end

	-- Rebirth button visibility
	task.spawn(function()
		local ok, canRebirth = RebirthService:CanRebirth():await()
		if ok then
			rebirthButton.Visible = canRebirth
		end
	end)
end

-- ============================================================================
-- Public API
-- ============================================================================

function HUDController:ToggleInventory()
	if not inventoryFrame then
		buildInventoryPanel()
	end
	if inventoryFrame then
		inventoryFrame.Visible = not inventoryFrame.Visible
		if inventoryFrame.Visible then
			refreshInventory()
		end
	end
end

function HUDController:RefreshInventory()
	if inventoryFrame and inventoryFrame.Visible then
		refreshInventory()
	end
end

-- ============================================================================
-- Lifecycle
-- ============================================================================

function HUDController:KnitInit()
	RebirthService = Knit.GetService("RebirthService")
	PetService = Knit.GetService("PetService")
end

function HUDController:KnitStart()
	buildHUD()

	-- Update HUD every 0.25 seconds
	task.spawn(function()
		while true do
			updateHUD()
			task.wait(0.25)
		end
	end)

	-- Listen for pet changes to refresh inventory
	PetService.PetAdded:Connect(function()
		self:RefreshInventory()
	end)

	PetService.PetEquipped:Connect(function()
		self:RefreshInventory()
	end)

	PetService.PetUnequipped:Connect(function()
		self:RefreshInventory()
	end)

	-- Rebirth notification
	RebirthService.PlayerRebirthed:Connect(function(_newCount, _newMult)
		-- Flash screen gold
		local flash = Instance.new("Frame")
		flash.Size = UDim2.fromScale(1, 1)
		flash.BackgroundColor3 = Color3.fromRGB(255, 200, 40)
		flash.BackgroundTransparency = 0.3
		flash.Parent = screenGui

		TweenService:Create(flash, TweenInfo.new(1.5), { BackgroundTransparency = 1 }):Play()
		task.delay(1.6, function()
			flash:Destroy()
		end)
	end)

	-- Extra equip slots gamepass check
	task.spawn(function()
		local MonetizationService = Knit.GetService("MonetizationService")
		local ok, hasExtra = MonetizationService:HasGamePass("ExtraEquip"):await()
		if ok and hasExtra then
			for i = 4, 6 do
				if petSlotFrames[i] then
					petSlotFrames[i].Visible = true
				end
			end
		end
	end)
end

return HUDController
