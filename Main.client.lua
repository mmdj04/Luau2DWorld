--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

pcall(function()
	local playerModule = player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 2)
	if playerModule then
		local module = require(playerModule)
		if module.Disable then
			module:Disable()
		elseif module.GetControls then
			local controls = module:GetControls()
			if controls.Disable then
				controls:Disable()
			end
		end
	end
end)

pcall(function()
	local character = player.Character
	if character then
		for _, part in character:GetDescendants() do
			if part:IsA("BasePart") then
				part.Transparency = 1
			elseif part:IsA("Decal") then
				part.Transparency = 1
			end
		end
	end
end)

const screenGui = Instance.new("ScreenGui")
screenGui.Name = "WorldGame"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 999
screenGui.Parent = playerGui

const modules = script:WaitForChild("Modules")
const WorldGenerator = require(modules:WaitForChild("WorldGenerator"))
const PlayerController = require(modules:WaitForChild("PlayerController"))
const LightingSystem = require(modules:WaitForChild("LightingSystem"))
const CaveGenerator = require(modules:WaitForChild("CaveGenerator"))
const HUD = require(modules:WaitForChild("HUD"))
const UICamera = require(modules:WaitForChild("UICamera"))
const UITools = require(modules:WaitForChild("UITools"))
const UIWorldRenderer = require(modules:WaitForChild("UIWorldRenderer"))
const UIInventory = require(modules:WaitForChild("UIInventory"))

const CONFIG = {
	seed = os.time(),
	tileSize = 8,
	worldWidth = 400,
	worldHeight = 150,
	chunkSize = 16,
}

const worldFrame = Instance.new("Frame")
worldFrame.Name = "WorldViewport"
worldFrame.Size = UDim2.fromScale(1, 1)
worldFrame.Position = UDim2.fromScale(0, 0)
worldFrame.BackgroundColor3 = Color3.fromRGB(135, 206, 235)
worldFrame.BorderSizePixel = 0
worldFrame.ZIndex = 1
worldFrame.ClipsDescendants = true
worldFrame.Parent = screenGui

const playerSize = CONFIG.tileSize * 1.5
const playerFrame = Instance.new("Frame")
playerFrame.Name = "Player"
playerFrame.Size = UDim2.fromOffset(playerSize, playerSize)
playerFrame.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
playerFrame.BorderSizePixel = 0
playerFrame.ZIndex = 10
playerFrame.Parent = worldFrame

const playerCorner = Instance.new("UICorner")
playerCorner.CornerRadius = UDim.new(0.3, 0)
playerCorner.Parent = playerFrame

const eyeLeft = Instance.new("Frame")
eyeLeft.Name = "EyeLeft"
eyeLeft.Size = UDim2.fromOffset(3, 3)
eyeLeft.Position = UDim2.fromScale(0.2, 0.2)
eyeLeft.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
eyeLeft.BorderSizePixel = 0
eyeLeft.ZIndex = 11
eyeLeft.Parent = playerFrame

const eyeRight = Instance.new("Frame")
eyeRight.Name = "EyeRight"
eyeRight.Size = UDim2.fromOffset(3, 3)
eyeRight.Position = UDim2.fromScale(0.6, 0.2)
eyeRight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
eyeRight.BorderSizePixel = 0
eyeRight.ZIndex = 11
eyeRight.Parent = playerFrame

const eyeCorner = Instance.new("UICorner")
eyeCorner.CornerRadius = UDim.new(1, 0)
eyeCorner.Parent = eyeLeft
const eyeCorner2 = Instance.new("UICorner")
eyeCorner2.CornerRadius = UDim.new(1, 0)
eyeCorner2.Parent = eyeRight

const worldGen = WorldGenerator.new({
	seed = CONFIG.seed,
	worldWidth = CONFIG.worldWidth,
	worldHeight = CONFIG.worldHeight,
})

print(`[World2D] Gerando terreno...`)
worldGen:generateTrees(0, CONFIG.worldWidth)
worldGen:generateWater(0, CONFIG.worldWidth)

print(`[World2D] Gerando cavernas...`)
const caveGen = CaveGenerator.new(worldGen, CONFIG.seed)
caveGen:generateAll(0, CONFIG.worldWidth)

const spawnX = CONFIG.worldWidth // 2
local spawnY = 1
for y = 0, CONFIG.worldHeight - 1 do
	const tile = worldGen:getTile(spawnX, y)
	if tile == WorldGenerator.Tiles.GRASS or tile == WorldGenerator.Tiles.DIRT then
		spawnY = y - 2
		break
	end
end

print(`[World2D] Spawn em: {spawnX}, {spawnY}`)

const worldRenderer = UIWorldRenderer.new(worldFrame, worldGen, {
	tileSize = CONFIG.tileSize,
	chunkSize = CONFIG.chunkSize,
	poolInitialSize = 512,
	maxChunksVisible = 200,
	renderMargin = 3,
})

const lighting = LightingSystem.new(worldGen)
worldRenderer:setLightingSystem(lighting)

const hud = HUD.new(screenGui, worldGen, CONFIG.tileSize)
const inventory = UIInventory.new(screenGui, 10, 48)

const worldPixelW = CONFIG.worldWidth * CONFIG.tileSize
const worldPixelH = CONFIG.worldHeight * CONFIG.tileSize

const camera = UICamera.new(worldFrame, {
	smoothing = 0.12,
	deadzone = {x = 20, y = 15},
	boundsMin = {x = 0, y = 0},
	boundsMax = {x = worldPixelW, y = worldPixelH},
	zoom = 1,
})

const controller = PlayerController.new(playerFrame, worldGen, CONFIG.tileSize)
controller.TileX = spawnX
controller.TileY = spawnY
controller.PixelX = spawnX * CONFIG.tileSize
controller.PixelY = spawnY * CONFIG.tileSize

local health = 100.0
const maxHealth = 100.0
local minimapTimer = 0.0
const MINIMAP_UPDATE_INTERVAL = 0.5

const exploredTiles: { [string]: boolean } = {}

local lastTime = os.clock()

RunService.Heartbeat:Connect(function(): ()
	const now = os.clock()
	const dt = math.min(now - lastTime, 0.05)
	lastTime = now

	controller:update(dt)

	const px, py = controller:getWorldPosition()
	camera:update(px, py, dt)
	const cam = camera:getOffset()

	const absW = worldFrame.AbsoluteSize.X
	const absH = worldFrame.AbsoluteSize.Y

	worldRenderer:render(cam.x, cam.y, absW, absH)

	playerFrame.Position = UDim2.fromOffset(px - cam.x, py - cam.y)

	lighting:update(px, py, nil)

	for _, chunk in worldRenderer.visibleChunks do
		for i = 1, chunk.active do
			const frame = chunk.frames[i]
			if frame.Visible then
				const framePos = frame.Position
				const tileX = (framePos.X.Offset // CONFIG.tileSize + chunk.x * CONFIG.chunkSize)
				const tileY = (framePos.Y.Offset // CONFIG.tileSize + chunk.y * CONFIG.chunkSize)
				const surfaceY = worldGen:_getSurfaceHeight(tileX)
				const darkness = lighting:getDarkness(tileX, tileY, surfaceY)
				if darkness > 0.01 then
					const tileId = worldGen:getTile(tileX, tileY)
					const baseColor = WorldGenerator.TileColors[tileId] or Color3.new(0, 0, 0)
					frame.BackgroundColor3 = Color3.new(
						math.clamp(baseColor.R * (1 - darkness), 0, 1),
						math.clamp(baseColor.G * (1 - darkness), 0, 1),
						math.clamp(baseColor.B * (1 - darkness), 0, 1)
					)
				end
			end
		end
	end

	const currentTile = worldGen:getTile(px, py)
	if currentTile == WorldGenerator.Tiles.LAVA then
		health -= 30 * dt
		if health <= 0 then
			health = maxHealth
			controller.PixelX = spawnX * CONFIG.tileSize
			controller.PixelY = spawnY * CONFIG.tileSize
			controller.VelocityX = 0
			controller.VelocityY = 0
			camera:shake(12, 0.3)
		end
	end

	if controller.Grounded and controller.VelocityY > 300 then
		health -= (controller.VelocityY - 300) * 0.05
		if health <= 0 then
			health = maxHealth
			controller.PixelX = spawnX * CONFIG.tileSize
			controller.PixelY = spawnY * CONFIG.tileSize
			controller.VelocityX = 0
			controller.VelocityY = 0
			camera:shake(10, 0.25)
		end
	end

	if health < maxHealth and currentTile ~= WorldGenerator.Tiles.LAVA then
		health = math.min(health + 2 * dt, maxHealth)
	end

	hud:updateHealth(health, maxHealth)
	hud:updatePosition(px, py)

	minimapTimer += dt
	if minimapTimer >= MINIMAP_UPDATE_INTERVAL then
		minimapTimer = 0
		hud:updateMinimap(worldGen, px, py, nil, exploredTiles)
	end
end)

print(`[World2D] Mundo carregado!`)
print(`[World2D] Controles:`)
print(`  WASD / Setas - Mover`)
print(`  Shift - Correr`)
print(`  Espaco - Pular`)
print(`  1-9 - Selecionar slot do inventario`)
