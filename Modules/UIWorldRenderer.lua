--!strict

export type Chunk = {
	x: number,
	y: number,
	frames: {Frame},
	active: number,
	dirty: boolean,
}

export type RendererConfig = {
	tileSize: number,
	chunkSize: number,
	poolInitialSize: number,
	maxChunksVisible: number,
	renderMargin: number,
}

export type WorldGen = {
	getTile: (self: WorldGen, x: number, y: number) -> (number, Color3)?,
}

export type LightingSystem = {
	applyToFrame: (self: LightingSystem, tileX: number, tileY: number, frame: Frame) -> (),
}

local UIWorldRenderer = {}
UIWorldRenderer.__index = UIWorldRenderer

local function createChunk(chunkX: number, chunkY: number, config: RendererConfig): Chunk
	const tileSize = config.tileSize
	const chunkSize = config.chunkSize
	const framesPerChunk = chunkSize * chunkSize
	const frames = table.create(framesPerChunk) :: {Frame}

	for i = 1, framesPerChunk do
		const frame = Instance.new("Frame")
		frame.Size = UDim2.fromOffset(tileSize, tileSize)
		frame.BorderSizePixel = 0
		frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		frame.Visible = false
		frames[i] = frame
	end

	return {
		x = chunkX,
		y = chunkY,
		frames = frames,
		active = 0,
		dirty = true,
	}
end

local function getChunkKey(chunkX: number, chunkY: number): string
	return `${chunkX},{chunkY}`
end

local function renderChunk(
	worldGen: WorldGen,
	chunk: Chunk,
	camX: number,
	camY: number,
	screenW: number,
	screenH: number,
	tileSize: number,
	chunkSize: number,
	margin: number,
	lighting: LightingSystem?
): ()
	const worldPixelX = chunk.x * chunkSize * tileSize
	const worldPixelY = chunk.y * chunkSize * tileSize
	const chunkPixelW = chunkSize * tileSize
	const chunkPixelH = chunkSize * tileSize
	const viewMinX = camX - margin * tileSize
	const viewMinY = camY - margin * tileSize
	const viewMaxX = camX + screenW + margin * tileSize
	const viewMaxY = camY + screenH + margin * tileSize

	if worldPixelX + chunkPixelW < viewMinX or worldPixelX > viewMaxX then
		return
	end
	if worldPixelY + chunkPixelH < viewMinY or worldPixelY > viewMaxY then
		return
	end

	const startTileX = chunk.x * chunkSize
	const startTileY = chunk.y * chunkSize
	const baseTileX = math.max(startTileX, math.floor(viewMinX // tileSize))
	const baseTileY = math.max(startTileY, math.floor(viewMinY // tileSize))
	const endTileX = math.min(startTileX + chunkSize - 1, math.ceil(viewMaxX // tileSize))
	const endTileY = math.min(startTileY + chunkSize - 1, math.ceil(viewMaxY // tileSize))

	var activeCount = 0

	for tileY = baseTileY, endTileY do
		for tileX = baseTileX, endTileX do
			const result = worldGen:getTile(tileX, tileY)
			if result then
				const tileType, color = result[1], result[2]
				activeCount += 1

				if activeCount <= #chunk.frames then
					const frame = chunk.frames[activeCount]
					const localX = tileX - startTileX
					const localY = tileY - startTileY
					frame.Position = UDim2.fromOffset(localX * tileSize, localY * tileSize)
					frame.BackgroundColor3 = color
					frame.Visible = true

					if lighting then
						lighting:applyToFrame(tileX, tileY, frame)
					end
				end
			end
		end
	end

	for i = activeCount + 1, #chunk.frames do
		chunk.frames[i].Visible = false
	end

	chunk.active = activeCount
	chunk.dirty = false
end

local function updateVisibleChunks(
	state: any,
	camX: number,
	camY: number,
	screenW: number,
	screenH: number
): ()
	const tileSize = state.config.tileSize
	const chunkSize = state.config.chunkSize
	const margin = state.config.renderMargin

	const minChunkX = math.floor((camX - margin * tileSize) // (chunkSize * tileSize))
	const minChunkY = math.floor((camY - margin * tileSize) // (chunkSize * tileSize))
	const maxChunkX = math.ceil((camX + screenW + margin * tileSize) // (chunkSize * tileSize))
	const maxChunkY = math.ceil((camY + screenH + margin * tileSize) // (chunkSize * tileSize))

	const maxChunks = state.config.maxChunksVisible
	var count = 0

	for chunkY = minChunkY, maxChunkY do
		for chunkX = minChunkX, maxChunkX do
			if count >= maxChunks then
				break
			end

			const key = getChunkKey(chunkX, chunkY)
			var chunk = state.chunkMap[key]

			if not chunk then
				chunk = createChunk(chunkX, chunkY, state.config)
				state.chunkMap[key] = chunk
				table.insert(state.chunks, chunk)
			end

			table.insert(state.visibleChunks, chunk)
			count += 1
		end

		if count >= maxChunks then
			break
		end
	end
end

function UIWorldRenderer.new(
	worldFrame: Frame,
	worldGen: WorldGen,
	config: RendererConfig?
)
	const cfg = config or {
		tileSize = 32,
		chunkSize = 16,
		poolInitialSize = 256,
		maxChunksVisible = 100,
		renderMargin = 2,
	}

	const chunkPixelSize = cfg.chunkSize * cfg.tileSize

	const state = {
		worldFrame = worldFrame,
		worldGen = worldGen,
		config = cfg,
		chunks = {} :: {Chunk},
		chunkMap = {} :: {[string]: Chunk},
		chunkWidth = chunkPixelSize,
		chunkHeight = chunkPixelSize,
		lastCameraX = 0,
		lastCameraY = 0,
		lastScreenW = 0,
		lastScreenH = 0,
		framePool = {} :: {Frame},
		framePoolSize = 0,
		lightingSystem = nil :: LightingSystem?,
		dirtyChunks = {} :: {string},
		visibleChunks = {} :: {Chunk},
	}

	const poolSize = cfg.poolInitialSize
	state.framePool = table.create(poolSize)
	state.framePoolSize = poolSize

	for i = 1, poolSize do
		const frame = Instance.new("Frame")
		frame.Size = UDim2.fromOffset(cfg.tileSize, cfg.tileSize)
		frame.BorderSizePixel = 0
		frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		frame.Visible = false
		state.framePool[i] = frame
	end

	setmetatable(state, UIWorldRenderer)
	return state
end

function UIWorldRenderer.render(
	self: any,
	cameraX: number,
	cameraY: number,
	screenW: number,
	screenH: number
): ()
	const camDelta = math.abs(cameraX - self.lastCameraX) + math.abs(cameraY - self.lastCameraY)
	const sizeDelta = math.abs(screenW - self.lastScreenW) + math.abs(screenH - self.lastScreenH)
	const movementThreshold = self.config.tileSize * 0.25

	if camDelta < movementThreshold and sizeDelta < 1 and #self.dirtyChunks == 0 then
		return
	end

	self.lastCameraX = cameraX
	self.lastCameraY = cameraY
	self.lastScreenW = screenW
	self.lastScreenH = screenH

	for _, chunk in self.visibleChunks do
		chunk.dirty = false
	end
	table.clear(self.visibleChunks)

	updateVisibleChunks(self, cameraX, cameraY, screenW, screenH)

	for _, chunk in self.visibleChunks do
		renderChunk(
			self.worldGen,
			chunk,
			cameraX, cameraY,
			screenW, screenH,
			self.config.tileSize,
			self.config.chunkSize,
			self.config.renderMargin,
			self.lightingSystem
		)
	end

	table.clear(self.dirtyChunks)
end

function UIWorldRenderer.invalidateChunk(self: any, chunkX: number, chunkY: number): ()
	const key = getChunkKey(chunkX, chunkY)
	const chunk = self.chunkMap[key]

	if chunk then
		chunk.dirty = true
		table.insert(self.dirtyChunks, key)
	end
end

function UIWorldRenderer.invalidateTile(self: any, tileX: number, tileY: number): ()
	const chunkSize = self.config.chunkSize
	UIWorldRenderer.invalidateChunk(self, tileX // chunkSize, tileY // chunkSize)
end

function UIWorldRenderer.clear(self: any): ()
	for _, chunk in self.chunks do
		for i = 1, #chunk.frames do
			chunk.frames[i].Visible = false
		end
		chunk.active = 0
		chunk.dirty = true
	end
	table.clear(self.dirtyChunks)
end

function UIWorldRenderer.getTileAtScreen(
	self: any,
	screenX: number,
	screenY: number,
	cameraX: number,
	cameraY: number
): (number, number)
	const tileSize = self.config.tileSize
	return (cameraX + screenX) // tileSize, (cameraY + screenY) // tileSize
end

function UIWorldRenderer.getActiveChunkCount(self: any): number
	var count = 0
	for _, chunk in self.visibleChunks do
		if chunk.active > 0 then
			count += 1
		end
	end
	return count
end

function UIWorldRenderer.getFramePoolSize(self: any): number
	var total = 0
	for _, chunk in self.chunks do
		total += #chunk.frames
	end
	return total + self.framePoolSize
end

function UIWorldRenderer.setLightingSystem(self: any, lighting: LightingSystem): ()
	self.lightingSystem = lighting
end

function UIWorldRenderer.applyLighting(self: any, tileX: number, tileY: number, frame: Frame): ()
	if self.lightingSystem then
		self.lightingSystem:applyToFrame(tileX, tileY, frame)
	end
end

return UIWorldRenderer
