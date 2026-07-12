--!strict

type SlotData = {
	frame: Frame,
	icon: TextLabel,
	name: TextLabel,
	itemName: string?,
}

export type HUD = {
	screenGui: ScreenGui,
	worldGen: any,
	tileSize: number,
	visible: boolean,
	uiRoot: Frame,
	healthContainer: Frame,
	healthBarFill: Frame,
	healthText: TextLabel,
	positionDisplay: TextLabel,
	minimapBg: Frame,
	minimapCanvas: Frame,
	minimapDots: { Frame },
	inventoryBar: Frame,
	inventorySlots: { SlotData },
	controlsHint: TextLabel,
	nextSlot: number,
}

const MINIMAP_SIZE = 150
const MINIMAP_SCALE = 2
const HEALTH_BAR_WIDTH = 200
const HEALTH_BAR_HEIGHT = 20
const INVENTORY_SLOT_SIZE = 40
const INVENTORY_SLOT_COUNT = 10
const INVENTORY_PADDING = 4

const MINIMAP_TILE_COLORS: { [number]: Color3 } = {
	[0]  = Color3.fromRGB(135, 206, 235),
	[1]  = Color3.fromRGB(110, 85, 50),
	[2]  = Color3.fromRGB(80, 60, 40),
	[3]  = Color3.fromRGB(60, 60, 60),
	[4]  = Color3.fromRGB(50, 50, 50),
	[5]  = Color3.fromRGB(30, 100, 200),
	[6]  = Color3.fromRGB(40, 40, 50),
	[7]  = Color3.fromRGB(50, 50, 50),
	[8]  = Color3.fromRGB(140, 80, 220),
	[9]  = Color3.fromRGB(220, 60, 20),
	[10] = Color3.fromRGB(240, 200, 40),
	[18] = Color3.fromRGB(60, 140, 200),
}

local HUD = {}
HUD.__index = HUD

function HUD.new(screenGui: ScreenGui, worldGen: any, tileSize: number): HUD
	local self = setmetatable({}, HUD) :: any
	self.screenGui = screenGui
	self.worldGen = worldGen
	self.tileSize = tileSize
	self.visible = true

	local uiRoot = Instance.new("Frame")
	uiRoot.Name = "HUDRoot"
	uiRoot.Size = UDim2.new(1, 0, 1, 0)
	uiRoot.BackgroundTransparency = 1
	uiRoot.BorderSizePixel = 0
	uiRoot.Parent = screenGui
	self.uiRoot = uiRoot

	self:_createHealthBar()
	self:_createPositionDisplay()
	self:_createMinimap()
	self:_createInventoryBar()
	self:_createControlsHint()

	return self :: HUD
end

function HUD._createHealthBar(self: HUD): ()
	local container = Instance.new("Frame")
	container.Name = "HealthContainer"
	container.Position = UDim2.new(0, 20, 0, 20)
	container.Size = UDim2.new(0, HEALTH_BAR_WIDTH + 4, 0, HEALTH_BAR_HEIGHT + 30)
	container.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	container.BackgroundTransparency = 0.3
	container.BorderSizePixel = 0
	container.Parent = self.uiRoot

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = container

	local label = Instance.new("TextLabel")
	label.Name = "HealthLabel"
	label.Position = UDim2.new(0, 0, 0, 0)
	label.Size = UDim2.new(1, 0, 0, 12)
	label.BackgroundTransparency = 1
	label.Text = "HP"
	label.TextColor3 = Color3.fromRGB(220, 220, 220)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = Enum.Font.GothamBold
	label.TextSize = 10
	label.Parent = container

	local barBg = Instance.new("Frame")
	barBg.Name = "HealthBarBackground"
	barBg.Position = UDim2.new(0, 2, 0, 14)
	barBg.Size = UDim2.new(1, -4, 0, HEALTH_BAR_HEIGHT)
	barBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	barBg.BorderSizePixel = 0
	barBg.Parent = container

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 3)
	barCorner.Parent = barBg

	local barFill = Instance.new("Frame")
	barFill.Name = "HealthBarFill"
	barFill.Position = UDim2.new(0, 0, 0, 0)
	barFill.Size = UDim2.new(1, 0, 1, 0)
	barFill.BackgroundColor3 = Color3.fromRGB(40, 180, 60)
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 3)
	fillCorner.Parent = barFill

	local healthText = Instance.new("TextLabel")
	healthText.Name = "HealthText"
	healthText.Position = UDim2.new(0, 0, 0, 0)
	healthText.Size = UDim2.new(1, 0, 1, 0)
	healthText.BackgroundTransparency = 1
	healthText.Text = "100 / 100"
	healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
	healthText.Font = Enum.Font.GothamBold
	healthText.TextSize = 11
	healthText.Parent = barBg

	self.healthContainer = container
	self.healthBarFill = barFill
	self.healthText = healthText
end

function HUD._createPositionDisplay(self: HUD): ()
	local container = Instance.new("TextLabel")
	container.Name = "PositionDisplay"
	container.Position = UDim2.new(0, 20, 0, 20 + HEALTH_BAR_HEIGHT + 34)
	container.Size = UDim2.new(0, HEALTH_BAR_WIDTH + 4, 0, 24)
	container.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	container.BackgroundTransparency = 0.3
	container.BorderSizePixel = 0
	container.Text = "Tile: 0, 0"
	container.TextColor3 = Color3.fromRGB(200, 200, 200)
	container.Font = Enum.Font.Gotham
	container.TextSize = 11
	container.TextXAlignment = Enum.TextXAlignment.Left
	container.Parent = self.uiRoot

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = container

	self.positionDisplay = container
end

function HUD._createMinimap(self: HUD): ()
	local minimapBg = Instance.new("Frame")
	minimapBg.Name = "MinimapBackground"
	minimapBg.Position = UDim2.new(1, -(MINIMAP_SIZE + 20), 0, 20)
	minimapBg.Size = UDim2.new(0, MINIMAP_SIZE + 8, 0, MINIMAP_SIZE + 8)
	minimapBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	minimapBg.BackgroundTransparency = 0.2
	minimapBg.BorderSizePixel = 2
	minimapBg.BorderColor3 = Color3.fromRGB(100, 100, 100)
	minimapBg.Parent = self.uiRoot

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 6)
	bgCorner.Parent = minimapBg

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "MinimapTitle"
	titleLabel.Position = UDim2.new(0, 0, 1, 4)
	titleLabel.Size = UDim2.new(1, 0, 0, 14)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "MAP"
	titleLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 9
	titleLabel.Parent = minimapBg

	local canvasFrame = Instance.new("Frame")
	canvasFrame.Name = "MinimapCanvas"
	canvasFrame.Position = UDim2.new(0, 4, 0, 4)
	canvasFrame.Size = UDim2.new(0, MINIMAP_SIZE, 0, MINIMAP_SIZE)
	canvasFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	canvasFrame.BorderSizePixel = 0
	canvasFrame.ClipsDescendants = true
	canvasFrame.Parent = minimapBg

	self.minimapBg = minimapBg
	self.minimapCanvas = canvasFrame
	self.minimapDots = {}
end

function HUD._createInventoryBar(self: HUD): ()
	local totalWidth = INVENTORY_SLOT_COUNT * (INVENTORY_SLOT_SIZE + INVENTORY_PADDING) + INVENTORY_PADDING
	local bar = Instance.new("Frame")
	bar.Name = "InventoryBar"
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Position = UDim2.new(0.5, 0, 1, -16)
	bar.Size = UDim2.new(0, totalWidth, 0, INVENTORY_SLOT_SIZE + INVENTORY_PADDING * 2 + 18)
	bar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	bar.BackgroundTransparency = 0.3
	bar.BorderSizePixel = 0
	bar.Parent = self.uiRoot

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 6)
	barCorner.Parent = bar

	local barLabel = Instance.new("TextLabel")
	barLabel.Name = "InventoryLabel"
	barLabel.Position = UDim2.new(0, 0, 0, 2)
	barLabel.Size = UDim2.new(1, 0, 0, 12)
	barLabel.BackgroundTransparency = 1
	barLabel.Text = "INVENTORY"
	barLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	barLabel.Font = Enum.Font.GothamBold
	barLabel.TextSize = 8
	barLabel.Parent = bar

	self.inventorySlots = table.create(INVENTORY_SLOT_COUNT)

	for i = 1, INVENTORY_SLOT_COUNT do
		local slotX = INVENTORY_PADDING + (i - 1) * (INVENTORY_SLOT_SIZE + INVENTORY_PADDING)
		local slot = Instance.new("Frame")
		slot.Name = `Slot{i}`
		slot.Position = UDim2.new(0, slotX, 0, INVENTORY_PADDING + 14)
		slot.Size = UDim2.new(0, INVENTORY_SLOT_SIZE, 0, INVENTORY_SLOT_SIZE)
		slot.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
		slot.BorderSizePixel = 0
		slot.Parent = bar

		local slotCorner = Instance.new("UICorner")
		slotCorner.CornerRadius = UDim.new(0, 4)
		slotCorner.Parent = slot

		local icon = Instance.new("TextLabel")
		icon.Name = "Icon"
		icon.Position = UDim2.new(0, 0, 0, 0)
		icon.Size = UDim2.new(1, 0, 1, 0)
		icon.BackgroundTransparency = 1
		icon.Text = ""
		icon.TextColor3 = Color3.fromRGB(255, 255, 255)
		icon.Font = Enum.Font.GothamBold
		icon.TextSize = 18
		icon.Parent = slot

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "ItemName"
		nameLabel.Position = UDim2.new(0, 0, 1, 2)
		nameLabel.Size = UDim2.new(1, 0, 0, 12)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = ""
		nameLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
		nameLabel.Font = Enum.Font.Gotham
		nameLabel.TextSize = 7
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		nameLabel.Parent = slot

		self.inventorySlots[i] = { frame = slot, icon = icon, name = nameLabel, itemName = nil }
	end

	self.inventoryBar = bar
	self.nextSlot = 1
end

function HUD._createControlsHint(self: HUD): ()
	local hint = Instance.new("TextLabel")
	hint.Name = "ControlsHint"
	hint.AnchorPoint = Vector2.new(0.5, 1)
	hint.Position = UDim2.new(0.5, 0, 1, -16 - INVENTORY_SLOT_SIZE - INVENTORY_PADDING * 2 - 18 - 8)
	hint.Size = UDim2.new(0, 500, 0, 20)
	hint.BackgroundTransparency = 1
	hint.Text = "WASD / Arrow Keys: Move  |  Space: Jump  |  E: Interact"
	hint.TextColor3 = Color3.fromRGB(160, 160, 160)
	hint.Font = Enum.Font.Gotham
	hint.TextSize = 11
	hint.TextTransparency = 0.3
	hint.Parent = self.uiRoot

	self.controlsHint = hint
end

function HUD.updateHealth(self: HUD, current: number, max: number): ()
	if max <= 0 then return end
	local ratio = math.clamp(current / max, 0, 1)
	self.healthBarFill.Size = UDim2.new(ratio, 0, 1, 0)
	self.healthText.Text = `{math.floor(current)} / {math.floor(max)}`

	if ratio > 0.5 then
		self.healthBarFill.BackgroundColor3 = Color3.fromRGB(40, 180, 60)
	elseif ratio > 0.25 then
		self.healthBarFill.BackgroundColor3 = Color3.fromRGB(220, 160, 30)
	else
		self.healthBarFill.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
	end
end

function HUD.updatePosition(self: HUD, x: number, y: number): ()
	self.positionDisplay.Text = `Tile: {math.floor(x)}, {math.floor(y)}`
end

function HUD.updateMinimap(self: HUD, worldGen: any, playerX: number, playerY: number, _tilesTable: any, exploredTiles: { [string]: boolean }?): ()
	for _, dot in self.minimapDots do
		if dot and dot.Parent then
			dot:Destroy()
		end
	end
	self.minimapDots = table.create(0)

	local halfView = MINIMAP_SIZE // (2 * MINIMAP_SCALE)
	local playerTileX = playerX // 1
	local playerTileY = playerY // 1

	for dy = -halfView, halfView do
		for dx = -halfView, halfView do
			local wx = playerTileX + dx
			local wy = playerTileY + dy
			local key = `{wx},{wy}`

			if not exploredTiles or exploredTiles[key] then
				local tileId = 0
				if worldGen and worldGen.getTile then
					tileId = worldGen:getTile(wx, wy)
				end

				local px = (dx + halfView) * MINIMAP_SCALE
				local py = (dy + halfView) * MINIMAP_SCALE

				local dot = Instance.new("Frame")
				dot.Size = UDim2.new(0, MINIMAP_SCALE, 0, MINIMAP_SCALE)
				dot.Position = UDim2.new(0, px, 0, py)
				dot.BackgroundColor3 = MINIMAP_TILE_COLORS[tileId] or Color3.fromRGB(80, 80, 80)
				dot.BorderSizePixel = 0
				dot.Parent = self.minimapCanvas

				table.insert(self.minimapDots, dot)
			end
		end
	end

	local playerDotX = halfView * MINIMAP_SCALE
	local playerDotY = halfView * MINIMAP_SCALE
	local playerDot = Instance.new("Frame")
	playerDot.Name = "PlayerMarker"
	playerDot.Size = UDim2.new(0, 4, 0, 4)
	playerDot.Position = UDim2.new(0, playerDotX - 1, 0, playerDotY - 1)
	playerDot.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	playerDot.BorderSizePixel = 0
	playerDot.ZIndex = 5
	playerDot.Parent = self.minimapCanvas

	local pdCorner = Instance.new("UICorner")
	pdCorner.CornerRadius = UDim.new(0, 2)
	pdCorner.Parent = playerDot

	table.insert(self.minimapDots, playerDot)
end

function HUD.addItem(self: HUD, itemName: string, icon: string): boolean
	if self.nextSlot > INVENTORY_SLOT_COUNT then return false end
	local slot = self.inventorySlots[self.nextSlot]
	if not slot then return false end
	slot.itemName = itemName
	slot.icon.Text = icon
	slot.name.Text = itemName
	slot.frame.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
	self.nextSlot += 1
	return true
end

function HUD.show(self: HUD): ()
	self.visible = true
	self.uiRoot.Visible = true
end

function HUD.hide(self: HUD): ()
	self.visible = false
	self.uiRoot.Visible = false
end

return HUD
