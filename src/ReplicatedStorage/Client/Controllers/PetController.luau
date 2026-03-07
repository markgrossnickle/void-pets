--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)

local VoidPetsConfig = require(ReplicatedStorage.Shared.VoidPetsConfig)
local PlatformUtil = require(ReplicatedStorage.Shared.PlatformUtil)

local LocalPlayer = Players.LocalPlayer

--[=[
	@class PetController
	Pet visuals, floating orbit, inventory data management on the client.
]=]
local PetController = Knit.CreateController({
	Name = "PetController",
})

local PetService
local petModels: { [number]: Model } = {}
local petTroves: { [number]: any } = {}
local inventory: { any } = {}
local equippedSlots: { number } = {}
local orbitOffset = 0

-- ============================================================================
-- Pet Visual Creation
-- ============================================================================

local function createPetModel(petData: any, index: number): Model
	local petDef = VoidPetsConfig.Pets[petData.Type]
	local rarityInfo = VoidPetsConfig.Rarities[petData.Rarity]
	if not petDef or not rarityInfo then
		warn(`PetController: Unknown pet type or rarity: {petData.Type} / {petData.Rarity}`)
		-- Fallback
		petDef = { Shape = "Sphere", Name = "Unknown" }
		rarityInfo = VoidPetsConfig.Rarities.Common
	end

	local model = Instance.new("Model")
	model.Name = petDef.Name or petData.Type

	-- Body
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Anchored = true
	body.CanCollide = false
	body.Size = if petDef.Shape == "Sphere" then Vector3.new(1.5, 1.5, 1.5) else Vector3.new(1.5, 1.5, 1.5)
	body.Shape = if petDef.Shape == "Sphere" then Enum.PartType.Ball else Enum.PartType.Block
	body.Color = rarityInfo.Color
	body.Material = Enum.Material.SmoothPlastic
	body.TopSurface = Enum.SurfaceType.Smooth
	body.BottomSurface = Enum.SurfaceType.Smooth
	body.Parent = model

	-- Eyes (two small neon Parts)
	for _, offset in { Vector3.new(-0.3, 0.2, -0.7), Vector3.new(0.3, 0.2, -0.7) } do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Anchored = true
		eye.CanCollide = false
		eye.Size = Vector3.new(0.25, 0.3, 0.15)
		eye.Shape = Enum.PartType.Ball
		eye.Color = Color3.new(1, 1, 1)
		eye.Material = Enum.Material.Neon
		eye.CFrame = body.CFrame * CFrame.new(offset)
		eye.Parent = model
	end

	-- Aura particle
	local particle = Instance.new("ParticleEmitter")
	particle.Color = ColorSequence.new(rarityInfo.Color)
	particle.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) })
	particle.Lifetime = NumberRange.new(0.5, 1)
	particle.Rate = if PlatformUtil.IsMobile() then 5 else 10
	particle.Speed = NumberRange.new(0.5, 1)
	particle.SpreadAngle = Vector2.new(180, 180)
	particle.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	particle.Parent = body

	-- Level indicator (BillboardGui)
	if petData.Level > 1 then
		local bbg = Instance.new("BillboardGui")
		bbg.Size = UDim2.fromOffset(60, 20)
		bbg.StudsOffset = Vector3.new(0, 1.2, 0)
		bbg.AlwaysOnTop = true
		bbg.Parent = body

		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = `Lv.{petData.Level}`
		label.TextColor3 = rarityInfo.Color
		label.TextStrokeTransparency = 0.5
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.Parent = bbg
	end

	model.PrimaryPart = body
	return model
end

-- ============================================================================
-- Pet Orbit / Floating
-- ============================================================================

local function updatePetPositions(_dt: number)
	local character = LocalPlayer.Character
	if not character then
		return
	end
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then
		return
	end

	local basePos = rootPart.Position
	local totalPets = #equippedSlots
	local time = os.clock()

	for i, petIndex in equippedSlots do
		local model = petModels[petIndex]
		if not model or not model.PrimaryPart then
			continue
		end

		local angleOffset = (i - 1) / math.max(totalPets, 1) * math.pi * 2
		local angle = angleOffset + time * 0.8 + orbitOffset

		local radius = VoidPetsConfig.PetConfig.OrbitRadius
		local bobHeight = math.sin(time * VoidPetsConfig.PetConfig.BobSpeed + i) * VoidPetsConfig.PetConfig.BobHeight

		local x = math.cos(angle) * radius
		local z = math.sin(angle) * radius
		local targetPos = basePos + Vector3.new(x, 2 + bobHeight, z)

		-- Smooth lerp
		local currentPos = model.PrimaryPart.Position
		local newPos = currentPos:Lerp(targetPos, 0.1)
		local lookDir = (basePos - newPos) * Vector3.new(1, 0, 1)
		if lookDir.Magnitude > 0.01 then
			model:PivotTo(CFrame.lookAt(newPos, newPos + lookDir))
		else
			model:PivotTo(CFrame.new(newPos))
		end
	end
end

-- ============================================================================
-- Spawn / Despawn Equipped Pets
-- ============================================================================

local function spawnEquippedPets()
	-- Despawn existing
	for idx, model in petModels do
		model:Destroy()
		if petTroves[idx] then
			petTroves[idx]:Destroy()
		end
	end
	table.clear(petModels)
	table.clear(petTroves)

	for _, petIndex in equippedSlots do
		local petData = inventory[petIndex]
		if petData then
			local model = createPetModel(petData, petIndex)
			model.Parent = workspace
			petModels[petIndex] = model

			local trove = Trove.new()
			trove:Add(model)
			petTroves[petIndex] = trove
		end
	end
end

-- ============================================================================
-- Public API
-- ============================================================================

function PetController:GetInventory()
	return inventory
end

function PetController:GetEquippedSlots()
	return equippedSlots
end

function PetController:EquipPet(petIndex: number)
	PetService:EquipPet(petIndex)
end

function PetController:UnequipPet(petIndex: number)
	PetService:UnequipPet(petIndex)
end

function PetController:LevelUpPet(petIndex: number)
	return PetService:LevelUpPet(petIndex)
end

function PetController:ToggleLock(petIndex: number)
	return PetService:ToggleLock(petIndex)
end

function PetController:GetPetMultiplier(): number
	local ok, mult = PetService:GetPetMultiplier():await()
	return if ok then mult else 1
end

-- ============================================================================
-- Lifecycle
-- ============================================================================

function PetController:KnitInit()
	PetService = Knit.GetService("PetService")
end

function PetController:KnitStart()
	-- Initial sync
	task.spawn(function()
		local ok1, pets = PetService:GetPets():await()
		local ok2, slots = PetService:GetEquippedSlots():await()
		if ok1 then
			inventory = pets
		end
		if ok2 then
			equippedSlots = slots
		end
		spawnEquippedPets()
	end)

	-- Listen for updates
	PetService.PetAdded:Connect(function(petIndex, petData)
		inventory[petIndex] = petData
	end)

	PetService.PetEquipped:Connect(function(slots)
		equippedSlots = slots
		spawnEquippedPets()
	end)

	PetService.PetUnequipped:Connect(function(slots)
		equippedSlots = slots
		spawnEquippedPets()
	end)

	PetService.PetLeveledUp:Connect(function(_petIndex, _newLevel)
		-- Re-fetch inventory for updated levels
		task.spawn(function()
			local ok, pets = PetService:GetPets():await()
			if ok then
				inventory = pets
				spawnEquippedPets()
			end
		end)
	end)

	PetService.InventorySync:Connect(function(pets, slots)
		inventory = pets
		equippedSlots = slots
		spawnEquippedPets()
	end)

	-- Orbit update
	RunService.Heartbeat:Connect(updatePetPositions)

	-- Respawn pets on character added
	LocalPlayer.CharacterAdded:Connect(function()
		task.wait(1)
		spawnEquippedPets()
	end)
end

return PetController
