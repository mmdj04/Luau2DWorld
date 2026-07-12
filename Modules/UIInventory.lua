--!strict

local UIInventory = {}
UIInventory.__index = UIInventory

export type Item = {
	id: string,
	name: string,
	icon: string,
	description: string,
	quantity: number,
	maxStack: number,
	rarity: "common" | "uncommon" | "rare" | "epic" | "legendary",
	tileId: number?,
}

export type InventorySlot = {
	item: Item?,
	frame: Frame,
	iconLabel: TextLabel,
	countLabel: TextLabel,
	highlight: Frame,
}

export type InventoryConfig = {
	slotCount: number,
	slotSize: number,
	padding: number,
}

export type Inventory = typeof(setmetatable({} :: {
	_container: Frame,
	_slots: { InventorySlot },
	_config: InventoryConfig,
	_selectedSlot: number?,
	_visible: boolean,
}, UIInventory))

local RARITY_ORDER: { [string]: number } = {
	legendary = 5,
	epic = 4,
	rare = 3,
	uncommon = 2,
	common = 1,
}

local RARITY_COLORS: { [string]: Color3 } = {
	common = Color3.fromRGB(158, 158, 158),
	uncommon = Color3.fromRGB(76, 175, 80),
	rare = Color3.fromRGB(33, 150, 243),
	epic = Color3.fromRGB(156, 39, 176),
	legendary = Color3.fromRGB(255, 193, 7),
}

local function createSlot(parent: Frame, index: number, size: number, padding: number): InventorySlot
	local constOffset = (index - 1) * (size + padding)

	local slotFrame = Instance.new("Frame")
	slotFrame.Name = `Slot_{index}`
	slotFrame.Size = UDim2.fromOffset(size, size)
	slotFrame.Position = UDim2.fromOffset(constOffset, 0)
	slotFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	slotFrame.BorderSizePixel = 2
	slotFrame.BorderColor3 = Color3.fromRGB(60, 60, 60)
	slotFrame.Parent = parent

	local highlight = Instance.new("Frame")
	highlight.Name = "Highlight"
	highlight.Size = UDim2.fromScale(1, 1)
	highlight.BackgroundTransparency = 1
	highlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	highlight.BorderSizePixel = 0
	highlight.Parent = slotFrame

	local highlightCorner = Instance.new("UICorner")
	highlightCorner.CornerRadius = UDim.new(0, 4)
	highlightCorner.Parent = highlight

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = slotFrame

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "Icon"
	iconLabel.Size = UDim2.fromScale(1, 1)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = ""
	iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	iconLabel.TextScaled = true
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.Parent = slotFrame

	local countLabel = Instance.new("TextLabel")
	countLabel.Name = "Count"
	countLabel.Size = UDim2.fromScale(0.4, 0.3)
	countLabel.Position = UDim2.fromScale(0.6, 0.7)
	countLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	countLabel.BackgroundTransparency = 0.3
	countLabel.Text = ""
	countLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	countLabel.TextScaled = true
	countLabel.Font = Enum.Font.GothamBold
	countLabel.Visible = false
	countLabel.Parent = slotFrame

	local countCorner = Instance.new("UICorner")
	countCorner.CornerRadius = UDim.new(0, 4)
	countCorner.Parent = countLabel

	return {
		item = nil,
		frame = slotFrame,
		iconLabel = iconLabel,
		countLabel = countLabel,
		highlight = highlight,
	}
end

function UIInventory.new(screenGui: ScreenGui, slotCount: number, slotSize: number): Inventory
	local constPadding = 4
	local constContainerWidth = slotCount * (slotSize + constPadding) - constPadding

	local container = Instance.new("Frame")
	container.Name = "UIInventory"
	container.Size = UDim2.fromOffset(constContainerWidth, slotSize)
	container.Position = UDim2.fromScale(0.5, 1)
	container.AnchorPoint = Vector2.new(0.5, 1)
	container.BackgroundTransparency = 1
	container.Parent = screenGui

	local slots: { InventorySlot } = table.create(slotCount)
	for i = 1, slotCount do
		local slot = createSlot(container, i, slotSize, constPadding)
		slots[i] = slot

		local slotIndex = i
		slotFrame = slot.frame
		slotFrame.InputBegan:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				UIInventory._handleSlotClick(self :: any, slotIndex)
			end
		end)
	end

	local self = setmetatable({}, UIInventory) :: any
	self._container = container
	self._slots = slots
	self._config = {
		slotCount = slotCount,
		slotSize = slotSize,
		padding = constPadding,
	}
	self._selectedSlot = nil
	self._visible = true

	return self
end

function UIInventory:_updateSlotVisual(slot: InventorySlot): ()
	local item = slot.item
	if item then
		slot.iconLabel.Text = item.icon
		local constRarityColor = RARITY_COLORS[item.rarity] or RARITY_COLORS.common
		slot.frame.BorderColor3 = constRarityColor

		if item.quantity > 1 then
			slot.countLabel.Text = `x{item.quantity}`
			slot.countLabel.Visible = true
		else
			slot.countLabel.Visible = false
		end
	else
		slot.iconLabel.Text = ""
		slot.frame.BorderColor3 = Color3.fromRGB(60, 60, 60)
		slot.countLabel.Visible = false
	end
end

function UIInventory:_handleSlotClick(index: number): ()
	if self._selectedSlot == index then
		self._selectedSlot = nil
		self._slots[index].highlight.BackgroundTransparency = 1
	elseif self._selectedSlot then
		self._slots[self._selectedSlot].highlight.BackgroundTransparency = 1
		self._selectedSlot = index
		self._slots[index].highlight.BackgroundTransparency = 0.7
	else
		self._selectedSlot = index
		self._slots[index].highlight.BackgroundTransparency = 0.7
	end
end

function UIInventory._findFirstEmptySlot(self: Inventory): number?
	for i, slot in self._slots do
		if slot.item == nil then
			return i
		end
	end
	return nil
end

function UIInventory._findStackableSlot(self: Inventory, itemData: Item): number?
	if itemData.quantity >= itemData.maxStack then
		return nil
	end

	for i, slot in self._slots do
		if slot.item and slot.item.id == itemData.id and slot.item.quantity < slot.item.maxStack then
			return i
		end
	end
	return nil
end

function UIInventory.addItem(self: Inventory, itemData: Item): (boolean, number?)
	local remaining = itemData.quantity

	local stackableSlot = self:_findStackableSlot(itemData)
	if stackableSlot then
		local slot = self._slots[stackableSlot]
		assert(slot.item, "Stackable slot must have an item")
		local constMaxAdd = slot.item.maxStack - slot.item.quantity
		local constAddAmount = math.min(remaining, constMaxAdd)
		slot.item.quantity += constAddAmount
		remaining -= constAddAmount
		self:_updateSlotVisual(slot)

		if remaining <= 0 then
			return true, stackableSlot
		end
	end

	while remaining > 0 do
		local emptySlot = self:_findFirstEmptySlot()
		if emptySlot == nil then
			return false, nil
		end

		local slot = self._slots[emptySlot]
		local constCreateQty = math.min(remaining, itemData.maxStack)
		slot.item = {
			id = itemData.id,
			name = itemData.name,
			icon = itemData.icon,
			description = itemData.description,
			quantity = constCreateQty,
			maxStack = itemData.maxStack,
			rarity = itemData.rarity,
			tileId = itemData.tileId,
		}
		remaining -= constCreateQty
		self:_updateSlotVisual(slot)
	end

	return true, nil
end

function UIInventory.removeItem(self: Inventory, slotIndex: number, quantity: number): boolean
	local slot = self._slots[slotIndex]
	if not slot or not slot.item then
		return false
	end

	local constRemoveQty = math.min(quantity, slot.item.quantity)
	slot.item.quantity -= constRemoveQty

	if slot.item.quantity <= 0 then
		slot.item = nil
	end

	self:_updateSlotVisual(slot)
	return true
end

function UIInventory.getItem(self: Inventory, slotIndex: number): Item?
	local slot = self._slots[slotIndex]
	if not slot then
		return nil
	end
	return slot.item
end

function UIInventory.swapSlots(self: Inventory, indexA: number, indexB: number): ()
	local slotA = self._slots[indexA]
	local slotB = self._slots[indexB]

	if not slotA or not slotB then
		return
	end

	local constTempItem = slotA.item
	slotA.item = slotB.item
	slotB.item = constTempItem

	self:_updateSlotVisual(slotA)
	self:_updateSlotVisual(slotB)
end

function UIInventory.sortByRarity(self: Inventory): ()
	local collected: { Item } = {}

	for _, slot in self._slots do
		if slot.item then
			table.insert(collected, slot.item)
			slot.item = nil
			self:_updateSlotVisual(slot)
		end
	end

	table.sort(collected, function(a: Item, b: Item): boolean
		local constOrderA = RARITY_ORDER[a.rarity] or 0
		local constOrderB = RARITY_ORDER[b.rarity] or 0
		if constOrderA == constOrderB then
			return a.name < b.name
		end
		return constOrderA > constOrderB
	end)

	for i, item in collected do
		local slot = self._slots[i]
		slot.item = item
		self:_updateSlotVisual(slot)
	end
end

function UIInventory.useItem(self: Inventory, slotIndex: number): Item?
	local slot = self._slots[slotIndex]
	if not slot or not slot.item then
		return nil
	end

	local constUsedItem = {
		id = slot.item.id,
		name = slot.item.name,
		icon = slot.item.icon,
		description = slot.item.description,
		quantity = 1,
		maxStack = slot.item.maxStack,
		rarity = slot.item.rarity,
		tileId = slot.item.tileId,
	}

	slot.item.quantity -= 1
	if slot.item.quantity <= 0 then
		slot.item = nil
	end

	self:_updateSlotVisual(slot)
	return constUsedItem
end

function UIInventory.findItem(self: Inventory, id: string): { slotIndex: number, item: Item }?
	for i, slot in self._slots do
		if slot.item and slot.item.id == id then
			return { slotIndex = i, item = slot.item }
		end
	end
	return nil
end

function UIInventory.getUsedSlots(self: Inventory): number
	local constCount = 0
	for _, slot in self._slots do
		if slot.item then
			constCount += 1
		end
	end
	return constCount
end

function UIInventory.isFull(self: Inventory): boolean
	return self:_findFirstEmptySlot() == nil
end

function UIInventory.clear(self: Inventory): ()
	for _, slot in self._slots do
		slot.item = nil
		self:_updateSlotVisual(slot)
	end
	self._selectedSlot = nil
end

function UIInventory.show(self: Inventory): ()
	self._visible = true
	self._container.Visible = true
end

function UIInventory.hide(self: Inventory): ()
	self._visible = false
	self._container.Visible = false
end

function UIInventory.getSelectedSlot(self: Inventory): number?
	return self._selectedSlot
end

function UIInventory.selectSlot(self: Inventory, index: number?): ()
	if self._selectedSlot then
		self._slots[self._selectedSlot].highlight.BackgroundTransparency = 1
	end

	self._selectedSlot = index

	if index then
		local slot = self._slots[index]
		if slot then
			slot.highlight.BackgroundTransparency = 0.7
		end
	end
end

return UIInventory
