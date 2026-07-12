--!strict

export type TileRenderer = {
	ViewportFrame: Frame,
	TileSize: number,
	WorldGen: any,
	ActiveTiles: { [string]: Frame },
	FramePool: { Frame },
	NextPoolIndex: number,
	LastCameraX: number,
	LastCameraY: number,
	LastScreenWidth: number,
	LastScreenHeight: number,
}

local TileRenderer = {}
TileRenderer.__index = TileRenderer

local WorldGenerator = require(script.Parent.WorldGenerator)
local TILE_SIZE = 8

local function createTileFrame(parent: Frame): Frame
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, TILE_SIZE, 0, TILE_SIZE)
	frame.BorderSizePixel = 0
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.Parent = parent
	return frame
end

function TileRenderer.new(viewportFrame: Frame, tileSize: number?, worldGen: any): TileRenderer
	local self = setmetatable({}, TileRenderer) :: TileRenderer

	self.ViewportFrame = viewportFrame
	self.TileSize = tileSize or TILE_SIZE
	self.WorldGen = worldGen
	self.ActiveTiles = {}
	self.FramePool = table.create(0)
	self.NextPoolIndex = 0
	self.LastCameraX = 0
	self.LastCameraY = 0
	self.LastScreenWidth = 0
	self.LastScreenHeight = 0

	return self
end

function TileRenderer:_getFromPool(self: TileRenderer): Frame
	if self.NextPoolIndex > 0 then
		local frame = self.FramePool[self.NextPoolIndex]
		self.FramePool[self.NextPoolIndex] = nil
		self.NextPoolIndex -= 1
		return frame
	end
	return createTileFrame(self.ViewportFrame)
end

function TileRenderer:_returnToPool(self: TileRenderer, frame: Frame): ()
	frame.Visible = false
	self.NextPoolIndex += 1
	self.FramePool[self.NextPoolIndex] = frame
end

function TileRenderer:render(self: TileRenderer, cameraX: number, cameraY: number, screenWidth: number, screenHeight: number): ()
	self.LastCameraX = cameraX
	self.LastCameraY = cameraY
	self.LastScreenWidth = screenWidth
	self.LastScreenHeight = screenHeight

	local tileWidth = math.ceil(screenWidth / self.TileSize) + 2
	local tileHeight = math.ceil(screenHeight / self.TileSize) + 2

	local startTileX = (cameraX // self.TileSize) - 1
	local startTileY = (cameraY // self.TileSize) - 1
	local endTileX = startTileX + tileWidth
	local endTileY = startTileY + tileHeight

	local visibleKeys = {}

	for x = startTileX, endTileX - 1 do
		for y = startTileY, endTileY - 1 do
			visibleKeys[`${x},{y}`] = true
		end
	end

	for tileKey, frame in self.ActiveTiles do
		if not visibleKeys[tileKey] then
			self:_returnToPool(frame)
			self.ActiveTiles[tileKey] = nil
		end
	end

	for x = startTileX, endTileX - 1 do
		for y = startTileY, endTileY - 1 do
			local tileKey = `${x},{y}`
			local tileId = self.WorldGen:getTile(x, y)
			local frame = self.ActiveTiles[tileKey]

			if not frame then
				frame = self:_getFromPool()
				self.ActiveTiles[tileKey] = frame
			end

			local screenX = (x * self.TileSize) - cameraX
			local screenY = (y * self.TileSize) - cameraY

			frame.Position = UDim2.new(0, screenX, 0, screenY)
			frame.Size = UDim2.new(0, self.TileSize, 0, self.TileSize)
			frame.BackgroundColor3 = WorldGenerator.TileColors[tileId] or Color3.new(1, 0, 1)
			frame.Visible = true
		end
	end
end

function TileRenderer:clear(self: TileRenderer): ()
	for tileKey, frame in self.ActiveTiles do
		self:_returnToPool(frame)
		self.ActiveTiles[tileKey] = nil
	end
end

function TileRenderer:getTileAt(self: TileRenderer, screenX: number, screenY: number, cameraX: number, cameraY: number): (number, number)
	local worldX = (screenX + cameraX) // self.TileSize
	local worldY = (screenY + cameraY) // self.TileSize
	return worldX, worldY
end

return TileRenderer
