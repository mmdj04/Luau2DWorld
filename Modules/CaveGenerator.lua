--!strict

export type WorldGen = {
	getTile: (self: WorldGen, x: number, y: number) -> number,
	setTile: (self: WorldGen, x: number, y: number, tile: number) -> (),
	worldHeight: number,
}

type TunnelEntry = {
	x: number,
	y: number,
}

type CaveGenerator = {
	worldGen: WorldGen,
	rng: any,
	generateStalactites: (self: CaveGenerator, startX: number, endX: number) -> (),
	generateUndergroundLakes: (self: CaveGenerator, startX: number, endX: number) -> (),
	generateCrystalCaves: (self: CaveGenerator, startX: number, endX: number) -> (),
	generateLavaPools: (self: CaveGenerator, startX: number, endX: number) -> (),
	generateTreasureRooms: (self: CaveGenerator, startX: number, endX: number) -> number,
	generateTunnels: (self: CaveGenerator, startX: number, endX: number) -> number,
	generateAll: (self: CaveGenerator, startX: number, endX: number) -> (number, number),
}

local CaveGenerator = {}
CaveGenerator.__index = CaveGenerator

const TILES: { [string]: number } = {
	AIR = 0,
	DIRT = 1,
	STONE = 2,
	HARDSTONE = 3,
	BEDROCK = 4,
	WATER = 5,
	CAVE_AIR = 6,
	GRASS = 7,
	CRYSTAL = 8,
	LAVA = 9,
	GOLD = 10,
	COAL = 11,
	COPPER = 12,
	IRON = 13,
	DIAMOND = 14,
	WOOD = 15,
	LEAVES = 16,
	SAND = 17,
	SHALLOW = 18,
}

function CaveGenerator.new(worldGen: WorldGen, seed: number): CaveGenerator
	const self = setmetatable({}, CaveGenerator) :: any
	self.worldGen = worldGen
	self.rng = Random.new(seed)
	return self :: CaveGenerator
end

local function _random(self: CaveGenerator, min: number, max: number): number
	return self.rng:NextInteger(min, max)
end

local function _randomFloat(self: CaveGenerator, min: number, max: number): number
	return self.rng:NextNumber(min, max)
end

function CaveGenerator.generateStalactites(self: CaveGenerator, startX: number, endX: number): ()
	const height: number = self.worldGen.worldHeight or 200
	const surfaceLine: number = (height * 0.3) // 1

	for x = startX, endX do
		const caveY_start: number = surfaceLine + 20
		const foundCave = { value = false, y = caveY_start }

		for y = surfaceLine + 5, height - 10 do
			const tile: number = self.worldGen:getTile(x, y)
			if tile == TILES.CAVE_AIR then
				foundCave.y = y
				foundCave.value = true
				break
			end
		end

		if foundCave.value then
			const ceilingY: number = foundCave.y - 1
			if self.worldGen:getTile(x, ceilingY) ~= TILES.AIR then
				const length: number = _random(self, 2, 8)
				for i = 1, length do
					const ty: number = ceilingY + i
					const tile: number = self.worldGen:getTile(x, ty)
					if tile == TILES.CAVE_AIR or tile == TILES.AIR then
						self.worldGen:setTile(x, ty, TILES.STONE)
					else
						break
					end
				end

				if _random(self, 1, 100) <= 30 then
					const spread: number = _random(self, 1, 3)
					for dx = -spread, spread do
						const sLen: number = _random(self, 1, math.max(1, length - 2))
						for i = 1, sLen do
							const ty: number = ceilingY + i
							const tile: number = self.worldGen:getTile(x + dx, ty)
							if tile == TILES.CAVE_AIR or tile == TILES.AIR then
								self.worldGen:setTile(x + dx, ty, TILES.STONE)
							else
								break
							end
						end
					end
				end
			end
		end
	end

	for x = startX, endX do
		const caveFloor = { value = 0 }

		for y = surfaceLine + 30, height - 5 do
			const tile: number = self.worldGen:getTile(x, y)
			if tile == TILES.STONE or tile == TILES.DIRT or tile == TILES.HARDSTONE then
				caveFloor.value = y
				break
			end
		end

		if caveFloor.value > 0 then
			const stalagLength: number = _random(self, 2, 6)
			for i = 1, stalagLength do
				const ty: number = caveFloor.value - i
				const tile: number = self.worldGen:getTile(x, ty)
				if tile == TILES.CAVE_AIR or tile == TILES.AIR then
					self.worldGen:setTile(x, ty, TILES.STONE)
				else
					break
				end
			end
		end
	end
end

function CaveGenerator.generateUndergroundLakes(self: CaveGenerator, startX: number, endX: number): ()
	const height: number = self.worldGen.worldHeight or 200
	const surfaceLine: number = (height * 0.3) // 1

	for x = startX, endX do
		const caveStartY = { value = 0 }

		for y = surfaceLine + 15, height - 20 do
			const tile: number = self.worldGen:getTile(x, y)
			if tile == TILES.CAVE_AIR then
				if caveStartY.value == 0 then
					caveStartY.value = y
				end
			elseif (tile == TILES.STONE or tile == TILES.DIRT or tile == TILES.HARDSTONE) and caveStartY.value > 0 then
				const caveHeight: number = y - caveStartY.value
				if caveHeight >= 4 and _random(self, 1, 100) <= 15 then
					const lakeWidth: number = _random(self, 5, 15)
					const lakeDepth: number = math.min(_random(self, 2, 4), caveHeight - 2)
					const waterLevel: number = y - lakeDepth

					for lx = x - lakeWidth // 2, x + lakeWidth // 2 do
						for ly = waterLevel, y - 1 do
							const existingTile: number = self.worldGen:getTile(lx, ly)
							if existingTile == TILES.CAVE_AIR or existingTile == TILES.AIR then
								self.worldGen:setTile(lx, ly, TILES.WATER)
							end
						end

						for ly = y - lakeDepth - 1, y - 1 do
							const tile: number = self.worldGen:getTile(lx, ly)
							if tile == TILES.CAVE_AIR then
								self.worldGen:setTile(lx, ly, TILES.WATER)
							end
						end
					end

					for lx = x - lakeWidth // 2 - 1, x + lakeWidth // 2 + 1 do
						const shoreTile: number = self.worldGen:getTile(lx, y)
						if shoreTile == TILES.WATER then
							self.worldGen:setTile(lx, y, TILES.SHALLOW)
						end
					end

					x = x + lakeWidth
				end
				caveStartY.value = 0
			end
		end
	end
end

function CaveGenerator.generateCrystalCaves(self: CaveGenerator, startX: number, endX: number): ()
	const height: number = self.worldGen.worldHeight or 200
	const surfaceLine: number = (height * 0.3) // 1

	for x = startX, endX do
		for y = surfaceLine + 20, height - 10 do
			const tile: number = self.worldGen:getTile(x, y)
			if tile == TILES.CAVE_AIR then
				const adjacentStone = { value = 0 }
				for dx = -1, 1 do
					for dy = -1, 1 do
						if dx ~= 0 or dy ~= 0 then
							const adjTile: number = self.worldGen:getTile(x + dx, y + dy)
							if adjTile == TILES.STONE or adjTile == TILES.HARDSTONE then
								adjacentStone.value += 1
							end
						end
					end
				end

				if adjacentStone.value >= 3 and _random(self, 1, 100) <= 8 then
					self.worldGen:setTile(x, y, TILES.CRYSTAL)

					const clusterSize: number = _random(self, 3, 10)
					for _ = 1, clusterSize do
						const cx: number = x + _random(self, -2, 2)
						const cy: number = y + _random(self, -2, 2)
						const tile: number = self.worldGen:getTile(cx, cy)
						if tile == TILES.CAVE_AIR then
							const nearWall = { value = false }
							for dx2 = -1, 1 do
								for dy2 = -1, 1 do
									const adjTile2: number = self.worldGen:getTile(cx + dx2, cy + dy2)
									if adjTile2 == TILES.STONE or adjTile2 == TILES.HARDSTONE or adjTile2 == TILES.CRYSTAL then
										nearWall.value = true
									end
								end
							end
							if nearWall.value then
								self.worldGen:setTile(cx, cy, TILES.CRYSTAL)
							end
						end
					end
				end
			end
		end
	end
end

function CaveGenerator.generateLavaPools(self: CaveGenerator, startX: number, endX: number): ()
	const height: number = self.worldGen.worldHeight or 200
	const deepThreshold: number = (height * 0.7) // 1

	for x = startX, endX do
		const caveStartY = { value = 0 }

		for y = deepThreshold, height - 5 do
			const tile: number = self.worldGen:getTile(x, y)
			if tile == TILES.CAVE_AIR or tile == TILES.AIR then
				if caveStartY.value == 0 then
					caveStartY.value = y
				end
			elseif (tile == TILES.STONE or tile == TILES.HARDSTONE) and caveStartY.value > 0 then
				const caveHeight: number = y - caveStartY.value
				if caveHeight >= 3 and _random(self, 1, 100) <= 10 then
					const lavaWidth: number = _random(self, 3, 10)
					const lavaDepth: number = math.min(_random(self, 1, 3), caveHeight - 1)

					for lx = x - lavaWidth // 2, x + lavaWidth // 2 do
						for ly = y - lavaDepth, y - 1 do
							const existingTile: number = self.worldGen:getTile(lx, ly)
							if existingTile == TILES.CAVE_AIR or existingTile == TILES.AIR or existingTile == TILES.WATER then
								self.worldGen:setTile(lx, ly, TILES.LAVA)
							end
						end
					end

					for lx = x - lavaWidth // 2, x + lavaWidth // 2 do
						for ly = y - lavaDepth - 1, y - lavaDepth do
							const tile: number = self.worldGen:getTile(lx, ly)
							if tile == TILES.WATER then
								self.worldGen:setTile(lx, ly, TILES.STONE)
							end
						end
					end

					if _random(self, 1, 100) <= 25 then
						const gemX: number = x + _random(self, -lavaWidth // 2, lavaWidth // 2)
						const gemY: number = y - lavaDepth - 1
						const tile: number = self.worldGen:getTile(gemX, gemY)
						if tile == TILES.STONE then
							self.worldGen:setTile(gemX, gemY, TILES.DIAMOND)
						end
					end

					x = x + lavaWidth
				end
				caveStartY.value = 0
			end
		end
	end
end

function CaveGenerator.generateTreasureRooms(self: CaveGenerator, startX: number, endX: number): number
	const height: number = self.worldGen.worldHeight or 200
	const surfaceLine: number = (height * 0.3) // 1
	const roomsGenerated = { value = 0 }

	for x = startX + 5, endX - 5, 20 do
		if _random(self, 1, 100) <= 6 then
			const roomWidth: number = _random(self, 5, 9)
			const roomHeight: number = _random(self, 4, 7)
			const roomY = { value = 0 }

			for y = surfaceLine + 25, height - 20 do
				const tile: number = self.worldGen:getTile(x, y)
				if tile == TILES.CAVE_AIR then
					roomY.value = y - 1
					break
				end
			end

			if roomY.value > 0 then
				const canPlace = { value = true }
				for rx = x - 1, x + roomWidth + 1 do
					for ry = roomY.value - 1, roomY.value + roomHeight + 1 do
						const tile: number = self.worldGen:getTile(rx, ry)
						if tile ~= TILES.STONE and tile ~= TILES.DIRT and tile ~= TILES.HARDSTONE then
							canPlace.value = false
							break
						end
					end
					if not canPlace.value then break end
				end

				if canPlace.value then
					for rx = x, x + roomWidth do
						for ry = roomY.value, roomY.value + roomHeight do
							self.worldGen:setTile(rx, ry, TILES.CAVE_AIR)
						end
					end

					for rx = x - 1, x + roomWidth + 1 do
						self.worldGen:setTile(rx, roomY.value - 1, TILES.STONE)
						self.worldGen:setTile(rx, roomY.value + roomHeight + 1, TILES.STONE)
					end
					for ry = roomY.value, roomY.value + roomHeight do
						self.worldGen:setTile(x - 1, ry, TILES.STONE)
						self.worldGen:setTile(x + roomWidth + 1, ry, TILES.STONE)
					end

					const treasureX: number = x + roomWidth // 2
					const treasureY: number = roomY.value + roomHeight - 1
					self.worldGen:setTile(treasureX, treasureY, TILES.GOLD)
					self.worldGen:setTile(treasureX + 1, treasureY, TILES.GOLD)
					self.worldGen:setTile(treasureX - 1, treasureY, TILES.GOLD)

					if _random(self, 1, 100) <= 40 then
						const gemX: number = x + _random(self, 1, roomWidth - 1)
						const gemY: number = roomY.value + _random(self, 0, 1)
						self.worldGen:setTile(gemX, gemY, TILES.DIAMOND)
					end

					if _random(self, 1, 100) <= 30 then
						for cx = x, x + roomWidth do
							for cy = roomY.value, roomY.value + roomHeight do
								const tile: number = self.worldGen:getTile(cx, cy)
								if tile == TILES.CAVE_AIR and _random(self, 1, 100) <= 15 then
									self.worldGen:setTile(cx, cy, TILES.CRYSTAL)
								end
							end
						end
					end

					const doorX: number = x + roomWidth // 2
					for dy = -1, 1 do
						for dx = -1, 1 do
							const tile: number = self.worldGen:getTile(doorX + dx, roomY.value + roomHeight + 1 + dy)
							if tile == TILES.STONE then
								self.worldGen:setTile(doorX + dx, roomY.value + roomHeight + 1 + dy, TILES.CAVE_AIR)
							end
						end
					end

					roomsGenerated.value += 1
				end
			end
		end
	end

	return roomsGenerated.value
end

function CaveGenerator.generateTunnels(self: CaveGenerator, startX: number, endX: number): number
	const height: number = self.worldGen.worldHeight or 200
	const surfaceLine: number = (height * 0.3) // 1
	const tunnelCount = { value = 0 }

	const tunnelEntries: { TunnelEntry } = {}
	for x = startX, endX do
		for y = surfaceLine + 10, height - 15 do
			const tile: number = self.worldGen:getTile(x, y)
			if tile == TILES.CAVE_AIR and _random(self, 1, 100) <= 1 then
				table.insert(tunnelEntries, { x = x, y = y })
			end
		end
	end

	for i = 1, #tunnelEntries - 1 do
		const entryA: TunnelEntry = tunnelEntries[i]
		const entryB: TunnelEntry = tunnelEntries[i + 1]
		const dist: number = math.abs(entryB.x - entryA.x) + math.abs(entryB.y - entryA.y)

		if dist <= 60 and _random(self, 1, 100) <= 40 then
			const tunnelWidth: number = _random(self, 1, 2)
			const cx = { value = entryA.x }
			const cy = { value = entryA.y }
			const targetX: number = entryB.x
			const targetY: number = entryB.y
			const steps = { value = 0 }
			const maxSteps: number = dist * 3

			while (math.abs(cx.value - targetX) > 1 or math.abs(cy.value - targetY) > 1) and steps.value < maxSteps do
				steps.value += 1

				for dx = -tunnelWidth, tunnelWidth do
					for dy = -tunnelWidth, tunnelWidth do
						const tile: number = self.worldGen:getTile(cx.value + dx, cy.value + dy)
						if tile == TILES.STONE or tile == TILES.DIRT or tile == TILES.HARDSTONE then
							self.worldGen:setTile(cx.value + dx, cy.value + dy, TILES.CAVE_AIR)
						end
					end
				end

				if _random(self, 1, 100) <= 5 then
					const branchLen: number = _random(self, 3, 8)
					const bx = { value = cx.value }
					const by = { value = cy.value }
					const bdir: number = _random(self, 0, 3)
					for _ = 1, branchLen do
						if bdir == 0 then bx.value += 1
						elseif bdir == 1 then bx.value -= 1
						elseif bdir == 2 then by.value += 1
						else by.value -= 1
						end
						for dx2 = -1, 1 do
							for dy2 = -1, 1 do
								const bTile: number = self.worldGen:getTile(bx.value + dx2, by.value + dy2)
								if bTile == TILES.STONE or bTile == TILES.DIRT then
									self.worldGen:setTile(bx.value + dx2, by.value + dy2, TILES.CAVE_AIR)
								end
							end
						end
					end
				end

				const moveX: number = if cx.value < targetX then 1 elseif cx.value > targetX then -1 else 0
				const moveY: number = if cy.value < targetY then 1 elseif cy.value > targetY then -1 else 0

				if _random(self, 1, 100) <= 60 then
					cx.value += moveX
				else
					cy.value += moveY
				end
			end

			tunnelCount.value += 1
		end
	end

	for x = startX, endX do
		for y = surfaceLine + 10, height - 10 do
			const tile: number = self.worldGen:getTile(x, y)
			if tile == TILES.CAVE_AIR then
				const wallCount = { value = 0 }
				for dx = -2, 2 do
					for dy = -2, 2 do
						if dx ~= 0 or dy ~= 0 then
							const adjTile: number = self.worldGen:getTile(x + dx, y + dy)
							if adjTile == TILES.STONE or adjTile == TILES.HARDSTONE or adjTile == TILES.DIRT then
								wallCount.value += 1
							end
						end
					end
				end
				if wallCount.value >= 20 and _random(self, 1, 100) <= 3 then
					const resources: { number } = { TILES.COAL, TILES.COPPER, TILES.IRON, TILES.GOLD }
					const weights: { number } = { 40, 30, 20, 10 }
					const totalWeight: number = weights[1] + weights[2] + weights[3] + weights[4]
					const roll: number = _random(self, 1, totalWeight)
					const cumulative = { value = 0 }
					const chosenResource = { value = TILES.COAL }
					for idx, w in weights do
						cumulative.value += w
						if roll <= cumulative.value then
							chosenResource.value = resources[idx]
							break
						end
					end
					self.worldGen:setTile(x, y, chosenResource.value)
				end
			end
		end
	end

	return tunnelCount.value
end

function CaveGenerator.generateAll(self: CaveGenerator, startX: number, endX: number): (number, number)
	self:generateStalactites(startX, endX)
	self:generateUndergroundLakes(startX, endX)
	self:generateCrystalCaves(startX, endX)
	self:generateLavaPools(startX, endX)
	const rooms: number = self:generateTreasureRooms(startX, endX)
	const tunnels: number = self:generateTunnels(startX, endX)
	return rooms, tunnels
end

return CaveGenerator
