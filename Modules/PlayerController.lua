--!strict

export type Keys = {
	Left: boolean,
	Right: boolean,
	Up: boolean,
	Down: boolean,
	Sprint: boolean,
}

export type PlayerController = {
	Frame: Frame,
	WorldGen: any,
	TileSize: number,
	TileX: number,
	TileY: number,
	PixelX: number,
	PixelY: number,
	VelocityX: number,
	VelocityY: number,
	Grounded: boolean,
	Sprinting: boolean,
	Keys: Keys,
	_inputBeganConn: RBXScriptConnection?,
	_inputEndedConn: RBXScriptConnection?,
}

local UserInputService = game:GetService("UserInputService")

local PlayerController = {}
PlayerController.__index = PlayerController

local GRAVITY = 980
local JUMP_VELOCITY = -420
local FALL_SPEED_LIMIT = 600

function PlayerController.new(playerFrame: Frame, worldGen: any, tileSize: number?): PlayerController
	local self = setmetatable({}, PlayerController) :: PlayerController

	self.Frame = playerFrame
	self.WorldGen = worldGen
	self.TileSize = tileSize or 32

	self.TileX = 1
	self.TileY = 1
	self.PixelX = self.TileX * self.TileSize
	self.PixelY = self.TileY * self.TileSize

	self.VelocityX = 0
	self.VelocityY = 0

	self.Grounded = false
	self.Sprinting = false

	self.Keys = {
		Left = false,
		Right = false,
		Up = false,
		Down = false,
		Sprint = false,
	}

	self._inputBeganConn = UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean): ()
		if gameProcessed then return end
		self:_onInputBegan(input)
	end)

	self._inputEndedConn = UserInputService.InputEnded:Connect(function(input: InputObject, gameProcessed: boolean): ()
		if gameProcessed then return end
		self:_onInputEnded(input)
	end)

	self:_updateFramePosition()

	return self
end

function PlayerController:Destroy(self: PlayerController): ()
	if self._inputBeganConn then
		self._inputBeganConn:Disconnect()
	end
	if self._inputEndedConn then
		self._inputEndedConn:Disconnect()
	end
end

function PlayerController:_onInputBegan(self: PlayerController, input: InputObject): ()
	local code = input.KeyCode
	if code == Enum.KeyCode.A or code == Enum.KeyCode.Left then
		self.Keys.Left = true
	elseif code == Enum.KeyCode.D or code == Enum.KeyCode.Right then
		self.Keys.Right = true
	elseif code == Enum.KeyCode.W or code == Enum.KeyCode.Up then
		self.Keys.Up = true
	elseif code == Enum.KeyCode.S or code == Enum.KeyCode.Down then
		self.Keys.Down = true
	elseif code == Enum.KeyCode.LeftShift or code == Enum.KeyCode.RightShift then
		self.Keys.Sprint = true
	end
end

function PlayerController:_onInputEnded(self: PlayerController, input: InputObject): ()
	local code = input.KeyCode
	if code == Enum.KeyCode.A or code == Enum.KeyCode.Left then
		self.Keys.Left = false
	elseif code == Enum.KeyCode.D or code == Enum.KeyCode.Right then
		self.Keys.Right = false
	elseif code == Enum.KeyCode.W or code == Enum.KeyCode.Up then
		self.Keys.Up = false
	elseif code == Enum.KeyCode.S or code == Enum.KeyCode.Down then
		self.Keys.Down = false
	elseif code == Enum.KeyCode.LeftShift or code == Enum.KeyCode.RightShift then
		self.Keys.Sprint = false
	end
end

function PlayerController:_isSolid(self: PlayerController, tileX: number, tileY: number): boolean
	local tile = self.WorldGen:getTile(tileX, tileY)
	if tile == nil then
		return true
	end
	if type(tile) == "table" then
		if tile.solid ~= nil then
			return tile.solid
		end
		if tile.blocked ~= nil then
			return tile.blocked
		end
		return true
	end
	if type(tile) == "boolean" then
		return tile
	end
	if type(tile) == "number" then
		return tile > 0
	end
	return false
end

function PlayerController:_checkGround(self: PlayerController): boolean
	local feetTileX = (self.PixelX + self.TileSize * 0.5) // self.TileSize
	local feetTileY = (self.PixelY + self.TileSize) // self.TileSize
	return self:_isSolid(feetTileX, feetTileY)
end

function PlayerController:_checkCeiling(self: PlayerController): boolean
	local headTileX = (self.PixelX + self.TileSize * 0.5) // self.TileSize
	local headTileY = self.PixelY // self.TileSize
	return self:_isSolid(headTileX, headTileY)
end

function PlayerController:_checkWallRight(self: PlayerController): boolean
	local tileX = (self.PixelX + self.TileSize) // self.TileSize
	local tileY = (self.PixelY + self.TileSize * 0.5) // self.TileSize
	return self:_isSolid(tileX, tileY)
end

function PlayerController:_checkWallLeft(self: PlayerController): boolean
	local tileX = self.PixelX // self.TileSize
	local tileY = (self.PixelY + self.TileSize * 0.5) // self.TileSize
	return self:_isSolid(tileX, tileY)
end

function PlayerController:_updateFramePosition(self: PlayerController): ()
	local screenX = self.PixelX - self.TileSize * 0.5
	local screenY = self.PixelY - self.TileSize * 0.5
	self.Frame.Position = UDim2.fromOffset(screenX, screenY)
end

function PlayerController:update(self: PlayerController, dt: number): ()
	if dt <= 0 then return end

	self.Sprinting = self.Keys.Sprint
	local moveSpeed = self.Sprinting and 200 or 100

	self.VelocityX = 0
	if self.Keys.Left then
		self.VelocityX = -moveSpeed
	elseif self.Keys.Right then
		self.VelocityX = moveSpeed
	end

	if self.Keys.Up and self.Grounded then
		self.VelocityY = JUMP_VELOCITY
		self.Grounded = false
	elseif not self.Grounded then
		self.VelocityY = math.clamp(self.VelocityY + GRAVITY * dt, -math.huge, FALL_SPEED_LIMIT)
	end

	if self.Keys.Down and self.Grounded then
		self.VelocityY = 0
	end

	local newX = self.PixelX + self.VelocityX * dt
	local newY = self.PixelY + self.VelocityY * dt

	if self.VelocityX > 0 then
		local rightEdge = newX + self.TileSize
		local checkTileX = rightEdge // self.TileSize
		local checkTileY1 = self.PixelY // self.TileSize
		local checkTileY2 = (self.PixelY + self.TileSize - 1) // self.TileSize
		if self:_isSolid(checkTileX, checkTileY1) or self:_isSolid(checkTileX, checkTileY2) then
			newX = checkTileX * self.TileSize - self.TileSize
			self.VelocityX = 0
		end
	elseif self.VelocityX < 0 then
		local leftEdge = newX
		local checkTileX = leftEdge // self.TileSize
		local checkTileY1 = self.PixelY // self.TileSize
		local checkTileY2 = (self.PixelY + self.TileSize - 1) // self.TileSize
		if self:_isSolid(checkTileX, checkTileY1) or self:_isSolid(checkTileX, checkTileY2) then
			newX = (checkTileX + 1) * self.TileSize
			self.VelocityX = 0
		end
	end

	if self.VelocityY < 0 then
		local topEdge = newY
		local checkTileY = topEdge // self.TileSize
		local checkTileX1 = newX // self.TileSize
		local checkTileX2 = (newX + self.TileSize - 1) // self.TileSize
		if self:_isSolid(checkTileX1, checkTileY) or self:_isSolid(checkTileX2, checkTileY) then
			newY = (checkTileY + 1) * self.TileSize
			self.VelocityY = 0
		end
	elseif self.VelocityY > 0 then
		local bottomEdge = newY + self.TileSize
		local checkTileY = bottomEdge // self.TileSize
		local checkTileX1 = newX // self.TileSize
		local checkTileX2 = (newX + self.TileSize - 1) // self.TileSize
		if self:_isSolid(checkTileX1, checkTileY) or self:_isSolid(checkTileX2, checkTileY) then
			newY = checkTileY * self.TileSize - self.TileSize
			self.VelocityY = 0
			self.Grounded = true
		else
			self.Grounded = false
		end
	else
		self.Grounded = self:_checkGround()
	end

	self.PixelX = newX
	self.PixelY = newY

	self.TileX = self.PixelX // self.TileSize + 1
	self.TileY = self.PixelY // self.TileSize + 1

	self:_updateFramePosition()
end

function PlayerController:getCameraOffset(self: PlayerController): { x: number, y: number }
	local screenW = self.Frame.Parent and self.Frame.Parent.AbsoluteSize.X or 800
	local screenH = self.Frame.Parent and self.Frame.Parent.AbsoluteSize.Y or 600
	local centerX = screenW * 0.5
	local centerY = screenH * 0.5
	return {
		x = self.PixelX + self.TileSize * 0.5 - centerX,
		y = self.PixelY + self.TileSize * 0.5 - centerY,
	}
end

function PlayerController:getWorldPosition(self: PlayerController): (number, number)
	return self.TileX, self.TileY
end

return PlayerController
