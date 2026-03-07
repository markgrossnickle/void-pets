--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local VoidPetsConfig = require(ReplicatedStorage.Shared.VoidPetsConfig)

local LocalPlayer = Players.LocalPlayer

--[=[
	@class TradeController
	Trade UI: select pets to offer, confirm trades.
]=]
local TradeController = Knit.CreateController({
	Name = "TradeController",
})

local PetService
local tradeGui: ScreenGui?
local activeTrade: {
	Partner: Player?,
	MyOffer: { number },
	PartnerOffer: { number },
	Confirmed: boolean,
}?

-- ============================================================================
-- Trade UI
-- ============================================================================

local function buildTradeUI(): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = "TradeUI"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 50
	gui.Enabled = false
	gui.Parent = LocalPlayer.PlayerGui

	-- Main panel
	local panel = Instance.new("Frame")
	panel.Name = "TradePanel"
	panel.Size = UDim2.fromScale(0.7, 0.7)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.BackgroundColor3 = Color3.fromRGB(15, 8, 25)
	panel.BackgroundTransparency = 0.1
	panel.BorderSizePixel = 0
	panel.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(120, 60, 180)
	stroke.Thickness = 2
	stroke.Parent = panel

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.fromScale(1, 0.08)
	title.BackgroundTransparency = 1
	title.Text = "Trade"
	title.TextColor3 = Color3.fromRGB(200, 140, 255)
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.Parent = panel

	-- My offer side (left)
	local myOfferFrame = Instance.new("Frame")
	myOfferFrame.Name = "MyOffer"
	myOfferFrame.Size = UDim2.fromScale(0.45, 0.7)
	myOfferFrame.Position = UDim2.fromScale(0.025, 0.1)
	myOfferFrame.BackgroundColor3 = Color3.fromRGB(25, 15, 40)
	myOfferFrame.BackgroundTransparency = 0.3
	myOfferFrame.Parent = panel

	local myCorner = Instance.new("UICorner")
	myCorner.CornerRadius = UDim.new(0, 8)
	myCorner.Parent = myOfferFrame

	local myLabel = Instance.new("TextLabel")
	myLabel.Size = UDim2.fromScale(1, 0.1)
	myLabel.BackgroundTransparency = 1
	myLabel.Text = "Your Offer"
	myLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
	myLabel.Font = Enum.Font.GothamBold
	myLabel.TextScaled = true
	myLabel.Parent = myOfferFrame

	local myScroll = Instance.new("ScrollingFrame")
	myScroll.Name = "PetList"
	myScroll.Size = UDim2.fromScale(0.95, 0.85)
	myScroll.Position = UDim2.fromScale(0.025, 0.12)
	myScroll.BackgroundTransparency = 1
	myScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	myScroll.ScrollBarThickness = 4
	myScroll.Parent = myOfferFrame

	local myGrid = Instance.new("UIGridLayout")
	myGrid.CellSize = UDim2.fromOffset(70, 85)
	myGrid.CellPadding = UDim2.fromOffset(4, 4)
	myGrid.Parent = myScroll

	-- Partner offer side (right)
	local partnerOfferFrame = Instance.new("Frame")
	partnerOfferFrame.Name = "PartnerOffer"
	partnerOfferFrame.Size = UDim2.fromScale(0.45, 0.7)
	partnerOfferFrame.Position = UDim2.fromScale(0.525, 0.1)
	partnerOfferFrame.BackgroundColor3 = Color3.fromRGB(25, 15, 40)
	partnerOfferFrame.BackgroundTransparency = 0.3
	partnerOfferFrame.Parent = panel

	local partnerCorner = Instance.new("UICorner")
	partnerCorner.CornerRadius = UDim.new(0, 8)
	partnerCorner.Parent = partnerOfferFrame

	local partnerLabel = Instance.new("TextLabel")
	partnerLabel.Size = UDim2.fromScale(1, 0.1)
	partnerLabel.BackgroundTransparency = 1
	partnerLabel.Text = "Partner's Offer"
	partnerLabel.TextColor3 = Color3.fromRGB(200, 100, 100)
	partnerLabel.Font = Enum.Font.GothamBold
	partnerLabel.TextScaled = true
	partnerLabel.Parent = partnerOfferFrame

	-- Buttons
	local confirmBtn = Instance.new("TextButton")
	confirmBtn.Name = "ConfirmBtn"
	confirmBtn.Size = UDim2.fromScale(0.2, 0.08)
	confirmBtn.Position = UDim2.fromScale(0.3, 0.88)
	confirmBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	confirmBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 40)
	confirmBtn.Text = "Confirm"
	confirmBtn.TextColor3 = Color3.new(1, 1, 1)
	confirmBtn.Font = Enum.Font.GothamBold
	confirmBtn.TextScaled = true
	confirmBtn.AutoButtonColor = true
	confirmBtn.Parent = panel

	local confirmCorner = Instance.new("UICorner")
	confirmCorner.CornerRadius = UDim.new(0, 6)
	confirmCorner.Parent = confirmBtn

	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Name = "CancelBtn"
	cancelBtn.Size = UDim2.fromScale(0.2, 0.08)
	cancelBtn.Position = UDim2.fromScale(0.7, 0.88)
	cancelBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	cancelBtn.BackgroundColor3 = Color3.fromRGB(140, 40, 40)
	cancelBtn.Text = "Cancel"
	cancelBtn.TextColor3 = Color3.new(1, 1, 1)
	cancelBtn.Font = Enum.Font.GothamBold
	cancelBtn.TextScaled = true
	cancelBtn.AutoButtonColor = true
	cancelBtn.Parent = panel

	local cancelCorner = Instance.new("UICorner")
	cancelCorner.CornerRadius = UDim.new(0, 6)
	cancelCorner.Parent = cancelBtn

	cancelBtn.Activated:Connect(function()
		TradeController:CloseTrade()
	end)

	confirmBtn.Activated:Connect(function()
		TradeController:ConfirmTrade()
	end)

	return gui
end

local function populateMyPets()
	if not tradeGui then
		return
	end

	local PetController = Knit.GetController("PetController")
	local inventory = PetController:GetInventory()
	local equipped = PetController:GetEquippedSlots()
	local equippedSet: { [number]: boolean } = {}
	for _, idx in equipped do
		equippedSet[idx] = true
	end

	local scroll = tradeGui:FindFirstChild("TradePanel")
	if not scroll then
		return
	end
	scroll = scroll:FindFirstChild("MyOffer")
	if not scroll then
		return
	end
	scroll = scroll:FindFirstChild("PetList") :: ScrollingFrame?
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
		if equippedSet[i] or petData.Locked then
			continue
		end
		-- Check trade lock
		if petData.TradeLockUntil > os.time() then
			continue
		end

		local petDef = VoidPetsConfig.Pets[petData.Type]
		local rarityInfo = VoidPetsConfig.Rarities[petData.Rarity]
		if not petDef or not rarityInfo then
			continue
		end

		local card = Instance.new("Frame")
		card.Name = `Pet_{i}`
		card.BackgroundColor3 = Color3.fromRGB(30, 15, 45)

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 4)
		cardCorner.Parent = card

		local cardStroke = Instance.new("UIStroke")
		cardStroke.Color = rarityInfo.Color
		cardStroke.Thickness = 1
		cardStroke.Parent = card

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.fromScale(1, 0.4)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = petDef.Name
		nameLabel.TextColor3 = rarityInfo.Color
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextScaled = true
		nameLabel.Parent = card

		local rarLabel = Instance.new("TextLabel")
		rarLabel.Size = UDim2.fromScale(1, 0.25)
		rarLabel.Position = UDim2.fromScale(0, 0.4)
		rarLabel.BackgroundTransparency = 1
		rarLabel.Text = petData.Rarity
		rarLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
		rarLabel.Font = Enum.Font.Gotham
		rarLabel.TextScaled = true
		rarLabel.Parent = card

		-- Toggle selection
		local selected = false
		local selectBtn = Instance.new("TextButton")
		selectBtn.Size = UDim2.fromScale(0.8, 0.25)
		selectBtn.Position = UDim2.fromScale(0.1, 0.7)
		selectBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		selectBtn.Text = "Add"
		selectBtn.TextColor3 = Color3.new(1, 1, 1)
		selectBtn.Font = Enum.Font.Gotham
		selectBtn.TextScaled = true
		selectBtn.AutoButtonColor = true
		selectBtn.Parent = card

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 4)
		btnCorner.Parent = selectBtn

		local petIndex = i
		selectBtn.Activated:Connect(function()
			if not activeTrade then
				return
			end
			selected = not selected
			if selected then
				table.insert(activeTrade.MyOffer, petIndex)
				selectBtn.Text = "Remove"
				selectBtn.BackgroundColor3 = Color3.fromRGB(140, 60, 40)
				cardStroke.Thickness = 3
			else
				for j, idx in activeTrade.MyOffer do
					if idx == petIndex then
						table.remove(activeTrade.MyOffer, j)
						break
					end
				end
				selectBtn.Text = "Add"
				selectBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
				cardStroke.Thickness = 1
			end
		end)

		card.Parent = scroll
	end
end

-- ============================================================================
-- Public API
-- ============================================================================

function TradeController:OpenTrade(partner: Player)
	if activeTrade then
		return
	end

	activeTrade = {
		Partner = partner,
		MyOffer = {},
		PartnerOffer = {},
		Confirmed = false,
	}

	if not tradeGui then
		tradeGui = buildTradeUI()
	end
	tradeGui.Enabled = true

	-- Update partner label
	local panel = tradeGui:FindFirstChild("TradePanel")
	if panel then
		local partnerOffer = panel:FindFirstChild("PartnerOffer")
		if partnerOffer then
			local label = partnerOffer:FindFirstChildOfClass("TextLabel")
			if label then
				label.Text = `{partner.DisplayName}'s Offer`
			end
		end
	end

	populateMyPets()
end

function TradeController:CloseTrade()
	activeTrade = nil
	if tradeGui then
		tradeGui.Enabled = false
	end
end

function TradeController:ConfirmTrade()
	if not activeTrade or not activeTrade.Partner then
		return
	end

	if #activeTrade.MyOffer == 0 then
		warn("Select at least one pet to trade")
		return
	end

	activeTrade.Confirmed = true

	-- In a real implementation, this would go through a server-side trade
	-- negotiation flow. For now, we mark as confirmed.
	local confirmBtn = tradeGui and tradeGui:FindFirstChild("TradePanel")
	if confirmBtn then
		confirmBtn = confirmBtn:FindFirstChild("ConfirmBtn")
		if confirmBtn and confirmBtn:IsA("TextButton") then
			confirmBtn.Text = "Waiting..."
			confirmBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 40)
		end
	end
end

-- ============================================================================
-- Lifecycle
-- ============================================================================

function TradeController:KnitInit()
	PetService = Knit.GetService("PetService")
end

function TradeController:KnitStart()
	-- Listen for trade completion
	PetService.TradeCompleted:Connect(function(tradeData)
		-- Show trade result
		local gui = Instance.new("ScreenGui")
		gui.Name = "TradeResult"
		gui.IgnoreGuiInset = true
		gui.DisplayOrder = 100
		gui.Parent = LocalPlayer.PlayerGui

		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(0.4, 0.06)
		label.Position = UDim2.fromScale(0.3, 0.45)
		label.BackgroundColor3 = Color3.fromRGB(40, 140, 40)
		label.BackgroundTransparency = 0.2
		label.Text = `Trade complete! Received {#tradeData.received} pet(s)`
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.Parent = gui

		local labelCorner = Instance.new("UICorner")
		labelCorner.CornerRadius = UDim.new(0, 8)
		labelCorner.Parent = label

		task.delay(3, function()
			gui:Destroy()
		end)

		TradeController:CloseTrade()
	end)
end

return TradeController
