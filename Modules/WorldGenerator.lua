--!strict

type TreeEntry = {
	x: number,
	y: number,
	type: string,
}

type WorldConfig = {
	seed: number?,
	worldWidth: number?,
	worldHeight: number?,
}

type WorldGeneratorClass = {
	__index: WorldGeneratorClass,
	new: (config: WorldConfig?) -> WorldGenerator,
	getTile: (self: WorldGenerator, x: number, y: number) -> number,
	setTile: (self: WorldGenerator, x: number, y: number, tile: number) -> (),
	_generateTile: (self: WorldGenerator, x: number, y: number) -> number,
	_getSurfaceHeight: (self: WorldGenerator, x: number) -> number,
	generateTrees: (self: WorldGenerator, startX: number, endX: number) -> {TreeEntry},
	generateWater: (self: WorldGenerator, startX: number, endX: number) -> (),
}

export type WorldGenerator = typeof(setmetatable({} :: {
	seed: number,
	worldWidth: number,
	worldHeight: number,
	terrainNoise: any,
	caveNoise: any,
	oreNoise: any,
	detailNoise: any,
	treeNoise: any,
	biomeNoise: any,
	tiles: {[string]: number},
}, {} :: WorldGeneratorClass))

local Noise = require(script.Parent.Noise)

local WorldGenerator = {}
WorldGenerator.__index = WorldGenerator

const Tiles = {
	AIR       = 0,
	GRASS     = 1,
	DIRT      = 2,
	STONE     = 3,
	SAND      = 4,
	WATER     = 5,
	CAVE_AIR  = 6,
	DEEPSTONE = 7,
	CRYSTAL   = 8,
	LAVA      = 9,
	GOLD      = 10,
	IRON      = 11,
	COAL      = 12,
	WOOD      = 13,
	LEAVES    = 14,
	SNOW      = 15,
	ICE       = 16,
	MOSS      = 17,
	SHALLOW   = 18,
}

WorldGenerator.Tiles = Tiles

const TileColors = {
	[0]  = Color3.fromRGB(135, 206, 235),
	[1]  = Color3.fromRGB(76, 153, 0),
	[2]  = Color3.fromRGB(139, 90, 43),
	[3]  = Color3.fromRGB(128, 128, 128),
	[4]  = Color3.fromRGB(237, 201, 175),
	[5]  = Color3.fromRGB(30, 100, 200),
	[6]  = Color3.fromRGB(20, 20, 30),
	[7]  = Color3.fromRGB(60, 60, 70),
	[8]  = Color3.fromRGB(100, 200, 255),
	[9]  = Color3.fromRGB(255, 80, 20),
	[10] = Color3.fromRGB(255, 215, 0),
	[11] = Color3.fromRGB(180, 130, 100),
	[12] = Color3.fromRGB(50, 50, 50),
	[13] = Color3.fromRGB(101, 67, 33),
	[14] = Color3.fromRGB(34, 139, 34),
	[15] = Color3.fromRGB(240, 248, 255),
	[16] = Color3.fromRGB(173, 216, 230),
	[17] = Color3.fromRGB(50, 120, 50),
	[18] = Color3.fromRGB(70, 160, 220),
}

WorldGenerator.TileColors = TileColors

const BIOME_Y = {
	SURFACE     = 0,
	UNDERGROUND = 10,
	DEEP        = 40,
	CAVE_START  = 15,
	CAVE_END    = 60,
	LAVA_LEVEL  = 70,
}

function WorldGenerator.new(config: WorldConfig?): WorldGenerator
	local self = setmetatable({}, WorldGenerator) :: any
	config = config or {}
	self.seed = config.seed or os.time()
	self.worldWidth = config.worldWidth or 600
	self.worldHeight = config.worldHeight or 200
	self.terrainNoise = Noise.new(self.seed)
	self.caveNoise = Noise.new(self.seed + 1)
	self.oreNoise = Noise.new(self.seed + 2)
	self.detailNoise = Noise.new(self.seed + 3)
	self.treeNoise = Noise.new(self.seed + 4)
	self.biomeNoise = Noise.new(self.seed + 5)
	self.tiles = {}
	return self :: WorldGenerator
end

function WorldGenerator:getTile(x: number, y: number): number
	local key = `${x},{y}`
	if self.tiles[key] ~= nil then
		return self.tiles[key]
	end
	local tile = self:_generateTile(x, y)
	self.tiles[key] = tile
	return tile
end

function WorldGenerator:setTile(x: number, y: number, tile: number): ()
	self.tiles[`${x},{y}`] = tile
end

function WorldGenerator:_generateTile(x: number, y: number): number
	const T = Tiles

	const surfaceHeight = self:_getSurfaceHeight(x)

	const biomeVal = self.biomeNoise:fbm(x * 0.005, 0, 2)

	if y < 0 or y >= self.worldHeight then
		return T.AIR
	end

	if y < surfaceHeight then
		return T.AIR
	end

	if y == surfaceHeight // 1 then
		if biomeVal > 0.3 then
			return T.SNOW
		elseif biomeVal < -0.3 then
			return T.SAND
		else
			return T.GRASS
		end
	end

	if y < surfaceHeight + 4 + (self.detailNoise:perlin2d(x * 0.1, y * 0.1) * 2) // 1 then
		if biomeVal > 0.3 then
			return T.STONE
		end
		return T.DIRT
	end

	if y >= BIOME_Y.CAVE_START and y < BIOME_Y.CAVE_END then
		const caveVal = self.caveNoise:fbm(x * 0.04, y * 0.05, 3)
		const caveWidth = 0.15 + self.caveNoise:perlin2d(x * 0.01, y * 0.01) * 0.1

		if math.abs(caveVal) < caveWidth then
			return T.CAVE_AIR
		end

		const roomNoise = self.caveNoise:perlin2d(x * 0.02, y * 0.02)
		if roomNoise > 0.6 and math.abs(caveVal) < caveWidth * 2.5 then
			return T.CAVE_AIR
		end
	end

	if y >= BIOME_Y.DEEP then
		const deepNoise = self.detailNoise:fbm(x * 0.03, y * 0.03, 2)
		if deepNoise > 0.4 and y >= BIOME_Y.CAVE_START then
			return T.CAVE_AIR
		end
		return T.DEEPSTONE
	end

	const stoneVar = self.detailNoise:perlin2d(x * 0.05, y * 0.05)
	if stoneVar > 0.5 then
		return T.STONE
	end

	if y > BIOME_Y.CAVE_START then
		const oreVal = self.oreNoise:perlin2d(x * 0.08, y * 0.08)

		if oreVal > 0.75 and y > 30 then
			return T.GOLD
		end
		if oreVal > 0.65 and oreVal <= 0.75 and y > 20 then
			return T.IRON
		end
		if oreVal > 0.55 and oreVal <= 0.65 and y > 15 then
			return T.COAL
		end
		if y > BIOME_Y.CAVE_START and y < 50 then
			const crystalVal = self.oreNoise:absPerlin(x * 0.12, y * 0.12)
			if crystalVal < 0.08 then
				return T.CRYSTAL
			end
		end
	end

	if y >= BIOME_Y.LAVA_LEVEL then
		return T.LAVA
	end

	return T.STONE
end

function WorldGenerator:_getSurfaceHeight(x: number): number
	const baseHeight = self.worldHeight * 0.35
	const variation = self.terrainNoise:fbm(x * 0.008, 0, 5) * 30
	const detail = self.detailNoise:perlin2d(x * 0.05, 0) * 5
	return (baseHeight + variation + detail) // 1
end

function WorldGenerator:generateTrees(startX: number, endX: number): {TreeEntry}
	const trees = table.create(0)
	const T = Tiles

	for x = startX, endX do
		const surfaceY = self:_getSurfaceHeight(x)
		const tileAbove = self:_generateTile(x, surfaceY - 1)
		const tileAt = self:_generateTile(x, surfaceY)

		if tileAt == T.GRASS and tileAbove == T.AIR then
			const treeVal = self.treeNoise:perlin2d(x * 0.3, 0)
			if treeVal > 0.55 then
				for ty = 1, 3 do
					self:setTile(x, surfaceY - ty, T.WOOD)
				end
				for dx = -2, 2 do
					for dy = -2, 0 do
						if math.abs(dx) + math.abs(dy) <= 3 then
							self:setTile(x + dx, surfaceY - 3 + dy, T.LEAVES)
						end
					end
				end
				table.insert(trees, {x = x, y = surfaceY, type = "oak"})
			end
		end
	end

	return trees
end

function WorldGenerator:generateWater(startX: number, endX: number): ()
	const T = Tiles
	for x = startX, endX do
		const surfaceY = self:_getSurfaceHeight(x)
		const leftH = self:_getSurfaceHeight(x - 3)
		const rightH = self:_getSurfaceHeight(x + 3)
		const avg = (leftH + rightH) / 2
		if surfaceY > avg + 3 then
			for y = surfaceY, surfaceY + 2 do
				if self:getTile(x, y) == T.AIR then
					self:setTile(x, y, T.WATER)
				end
			end
		end
	end
end

return WorldGenerator
