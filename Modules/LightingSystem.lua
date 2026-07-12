--!strict

export type WorldGen = {
	getTile: (self: WorldGen, x: number, y: number) -> number,
	setTile: (self: WorldGen, x: number, y: number, tile: number) -> (),
	worldHeight: number,
}

type LightingSystem = {
	_worldGen: WorldGen,
	_explored: { [string]: boolean },
	_visibilityRadius: number,
	_exploredDimRadius: number,
	_playerX: number,
	_playerY: number,
}

local LightingSystem = {}
LightingSystem.__index = LightingSystem

const MAX_EXPLORED_OPACITY: number = 0.45
const CAVE_BASE_DARKNESS: number = 0.65
const SURFACE_BASE_DARKNESS: number = 0.1
const UNEXPLORED_COLOR: Color3 = Color3.fromRGB(5, 5, 10)
const VISIBILITY_RADIUS: number = 8
const EXPLORED_DIM_RADIUS: number = 16

local function distance(x1: number, y1: number, x2: number, y2: number): number
	const dx: number = x1 - x2
	const dy: number = y1 - y2
	return math.sqrt(dx * dx + dy * dy)
end

function LightingSystem.new(worldGen: WorldGen): LightingSystem
	const self = setmetatable({}, LightingSystem) :: any
	self._worldGen = worldGen
	self._explored = {}
	self._visibilityRadius = VISIBILITY_RADIUS
	self._exploredDimRadius = EXPLORED_DIM_RADIUS
	self._playerX = 0
	self._playerY = 0
	return self :: LightingSystem
end

function LightingSystem.isVisible(self: LightingSystem, x: number, y: number): boolean
	const key: string = `{x},{y}`
	return self._explored[key] == true
end

function LightingSystem.isExplored(self: LightingSystem, x: number, y: number): boolean
	const key: string = `{x},{y}`
	return self._explored[key] ~= nil
end

function LightingSystem.getDarkness(self: LightingSystem, x: number, y: number, surfaceY: number): number
	const key: string = `{x},{y}`
	const explored: boolean = self._explored[key] ~= nil
	const dist: number = distance(x, y, self._playerX, self._playerY)
	const isCave: boolean = y > surfaceY
	const baseDarkness: number = if isCave then CAVE_BASE_DARKNESS else SURFACE_BASE_DARKNESS

	if dist <= self._visibilityRadius then
		const factor: number = math.clamp(dist / self._visibilityRadius, 0, 1)
		const darkness: number = baseDarkness * factor * factor
		return math.clamp(darkness, 0, 1)
	elseif explored then
		const factor: number = math.clamp((dist - self._visibilityRadius) / (self._exploredDimRadius - self._visibilityRadius), 0, 1)
		const darkness: number = baseDarkness + (MAX_EXPLORED_OPACITY - baseDarkness) * factor
		return math.clamp(darkness, 0, 1)
	else
		return 1
	end
end

function LightingSystem.applyToFrame(self: LightingSystem, frame: Frame, darkness: number): ()
	const r: number = math.clamp(frame.BackgroundColor3.R * (1 - darkness) + UNEXPLORED_COLOR.R * darkness, 0, 1)
	const g: number = math.clamp(frame.BackgroundColor3.G * (1 - darkness) + UNEXPLORED_COLOR.G * darkness, 0, 1)
	const b: number = math.clamp(frame.BackgroundColor3.B * (1 - darkness) + UNEXPLORED_COLOR.B * darkness, 0, 1)
	frame.BackgroundColor3 = Color3.new(r, g, b)
end

function LightingSystem.getOverlayColor(self: LightingSystem, tileX: number, tileY: number, surfaceY: number): Color3
	const darkness: number = self:getDarkness(tileX, tileY, surfaceY)
	return Color3.new(
		UNEXPLORED_COLOR.R * darkness,
		UNEXPLORED_COLOR.G * darkness,
		UNEXPLORED_COLOR.B * darkness
	)
end

function LightingSystem.update(self: LightingSystem, playerTileX: number, playerTileY: number, _viewportTiles: number): ()
	self._playerX = playerTileX
	self._playerY = playerTileY
	const radius: number = self._exploredDimRadius
	const minX: number = (playerTileX - radius) // 1
	const maxX: number = (playerTileX + radius) // 1
	const minY: number = (playerTileY - radius) // 1
	const maxY: number = (playerTileY + radius) // 1

	for ty = minY, maxY do
		for tx = minX, maxX do
			const dist: number = distance(tx, ty, playerTileX, playerTileY)
			if dist <= self._visibilityRadius then
				self._explored[`{tx},{ty}`] = true
			elseif dist <= self._exploredDimRadius then
				const key: string = `{tx},{ty}`
				if self._explored[key] == nil then
					self._explored[key] = false
				end
			end
		end
	end
end

return LightingSystem
