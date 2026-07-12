--!strict

export type Keys = {
	Left: boolean,
	Right: boolean,
	Up: boolean,
	Down: boolean,
	Sprint: boolean,
	Jump: boolean,
}

export type MobileInput = {
	joystickFrame: Frame,
	joystickKnob: Frame,
	active: boolean,
	touchId: number?,
	startPos: Vector2,
	currentPos: Vector2,
	jumpFrame: Frame,
	jumpPressed: boolean,
	jumpTouchId: number?,
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
	Mobile: MobileInput,
	_inputBeganConn: RBXScriptConnection?,
	_inputEndedConn: RBXScriptConnection?,
	_inputChangedConn: RBXScriptConnection?,
	_isMobile: boolean,
}

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local PlayerController = {}
PlayerController.__index = PlayerController

const GRAVITY = 980
const JUMP_VELOCITY = -420
const FALL_SPEED_LIMIT = 600
const JOYSTICK_SIZE = 120
const JOYSTICK_KNOB_SIZE = 50
const JOYSTICK_DEADZONE = 10
const MOVE_SPEED = 100
const SPRINT_SPEED = 200
const JUMP_BUTTON_SIZE = 70

local function isMobile(): boolean
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function createJoystick(parent: Frame): MobileInput
	const container = Instance.new("Frame")
	container.Name = "MobileJoystick"
	container.Size = UDim2.fromOffset(JOYSTICK_SIZE, JOYSTICK_SIZE)
	container.Position = UDim2.fromScale(0, 0.5)
	container.AnchorPoint = Vector2.new(0, 0.5)
	container.BackgroundTransparency = 0.5
	container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	container.BorderSizePixel = 0
	container.ZIndex = 100
	container.Parent = parent

	const containerCorner = Instance.new("UICorner")
	containerCorner.CornerRadius = UDim.new(0.5, 0)
	containerCorner.Parent = container

	const knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.Size = UDim2.fromOffset(JOYSTICK_KNOB_SIZE, JOYSTICK_KNOB_SIZE)
	knob.Position = UDim2.fromScale(0.5, 0.5)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.BackgroundTransparency = 0.3
	knob.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
	knob.BorderSizePixel = 0
	knob.ZIndex = 101
	knob.Parent = container

	const knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(0.5, 0)
	knobCorner.Parent = knob

	const jumpFrame = Instance.new("TextButton")
	jumpFrame.Name = "JumpButton"
	jumpFrame.Size = UDim2.fromOffset(JUMP_BUTTON_SIZE, JUMP_BUTTON_SIZE)
	jumpFrame.Position = UDim2.fromScale(1, 0.5)
	jumpFrame.AnchorPoint = Vector2.new(1, 0.5)
	jumpFrame.BackgroundTransparency = 0.4
	jumpFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	jumpFrame.Text = "JUMP"
	jumpFrame.TextColor3 = Color3.fromRGB(255, 255, 255)
	jumpFrame.TextScaled = true
	jumpFrame.Font = Enum.Font.GothamBold
	jumpFrame.BorderSizePixel = 0
	jumpFrame.ZIndex = 100
	jumpFrame.Parent = parent

	const jumpCorner = Instance.new("UICorner")
	jumpCorner.CornerRadius = UDim.new(0.5, 0)
	jumpCorner.Parent = jumpFrame

	return {
		joystickFrame = container,
		joystickKnob = knob,
		active = false,
		touchId = nil,
		startPos = Vector2.new(0, 0),
		currentPos = Vector2.new(0, 0),
		jumpFrame = jumpFrame,
		jumpPressed = false,
		jumpTouchId = nil,
	}
end

function PlayerController.new(playerFrame: Frame, worldGen: any, tileSize: number?): PlayerController
	const self = setmetatable({}, PlayerController) :: PlayerController

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
		Jump = false,
	}

	self._isMobile = isMobile()

	const parentGui = playerFrame.Parent
	if parentGui and self._isMobile then
		self.Mobile = createJoystick(parentGui)
	else
		self.Mobile = {
			joystickFrame = Instance.new("Frame"),
			joystickKnob = Instance.new("Frame"),
			active = false,
			touchId = nil,
			startPos = Vector2.new(0, 0),
			currentPos = Vector2.new(0, 0),
			jumpFrame = Instance.new("TextButton"),
			jumpPressed = false,
			jumpTouchId = nil,
		}
	end

	self._inputBeganConn = UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean): ()
		if gameProcessed then return end
		self:_onInputBegan(input)
	end)

	self._inputEndedConn = UserInputService.InputEnded:Connect(function(input: InputObject, gameProcessed: boolean): ()
		self:_onInputEnded(input)
	end)

	self._inputChangedConn = UserInputService.InputChanged:Connect(function(input: InputObject, gameProcessed: boolean): ()
		self:_onInputChanged(input)
	end)

	if self._isMobile then
		self:_setupMobileInput()
	end

	self:_updateFramePosition()

	return self
end

function PlayerController:_setupMobileInput(self: PlayerController): ()
	const mobile = self.Mobile

	mobile.joystickFrame.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.Touch then
			mobile.active = true
			mobile.touchId = input.KeyCode
			mobile.startPos = input.Position
			mobile.currentPos = input.Position
		end
	end)

	mobile.joystickFrame.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.Touch then
			mobile.active = false
			mobile.touchId = nil
			mobile.joystickKnob.Position = UDim2.fromScale(0.5, 0.5)
			mobile.startPos = Vector2.new(0, 0)
			mobile.currentPos = Vector2.new(0, 0)
			self.Keys.Left = false
			self.Keys.Right = false
		end
	end)

	mobile.jumpFrame.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.Touch then
			mobile.jumpPressed = true
			mobile.jumpTouchId = input.KeyCode
			self.Keys.Jump = true
			self.Keys.Up = true
		end
	end)

	mobile.jumpFrame.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.Touch then
			mobile.jumpPressed = false
			mobile.jumpTouchId = nil
			self.Keys.Jump = false
			self.Keys.Up = false
		end
	end)
end

function PlayerController:Destroy(self: PlayerController): ()
	if self._inputBeganConn then
		self._inputBeganConn:Disconnect()
	end
	if self._inputEndedConn then
		self._inputEndedConn:Disconnect()
	end
	if self._inputChangedConn then
		self._inputChangedConn:Disconnect()
	end
end

function PlayerController:_onInputBegan(self: PlayerController, input: InputObject): ()
	if input.UserInputType == Enum.UserInputType.Keyboard then
		const code = input.KeyCode
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
		elseif code == Enum.KeyCode.Space then
			self.Keys.Jump = true
			self.Keys.Up = true
		end
	end
end

function PlayerController:_onInputEnded(self: PlayerController, input: InputObject): ()
	if input.UserInputType == Enum.UserInputType.Keyboard then
		const code = input.KeyCode
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
		elseif code == Enum.KeyCode.Space then
			self.Keys.Jump = false
			self.Keys.Up = false
		end
	end
end

function PlayerController:_onInputChanged(self: PlayerController, input: InputObject): ()
	if self._isMobile and self.Mobile.active then
		if input.UserInputType == Enum.UserInputType.Touch then
			self.Mobile.currentPos = input.Position

			const delta = self.Mobile.currentPos - self.Mobile.startPos
			const dist = delta.Magnitude
			const maxDist = JOYSTICK_SIZE * 0.5

			if dist > JOYSTICK_DEADZONE then
				const clampedDist = math.min(dist, maxDist)
				const angle = math.atan2(delta.Y, delta.X)
				const knobX = math.cos(angle) * clampedDist / maxDist
				const knobY = math.sin(angle) * clampedDist / maxDist

				self.Mobile.joystickKnob.Position = UDim2.fromScale(0.5 + knobX * 0.4, 0.5 + knobY * 0.4)

				const threshold = 0.3
				self.Keys.Left = knobX < -threshold
				self.Keys.Right = knobX > threshold
			else
				self.Mobile.joystickKnob.Position = UDim2.fromScale(0.5, 0.5)
				self.Keys.Left = false
				self.Keys.Right = false
			end
		end
	end
end

function PlayerController:_isSolid(self: PlayerController, tileX: number, tileY: number): boolean
	const tile = self.WorldGen:getTile(tileX, tileY)
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
	const feetTileX = (self.PixelX + self.TileSize * 0.5) // self.TileSize
	const feetTileY = (self.PixelY + self.TileSize) // self.TileSize
	return self:_isSolid(feetTileX, feetTileY)
end

function PlayerController:_updateFramePosition(self: PlayerController): ()
	const screenX = self.PixelX - self.TileSize * 0.5
	const screenY = self.PixelY - self.TileSize * 0.5
	self.Frame.Position = UDim2.fromOffset(screenX, screenY)
end

function PlayerController:update(self: PlayerController, dt: number): ()
	if dt <= 0 then return end

	self.Sprinting = self.Keys.Sprint
	const moveSpeed = self.Sprinting and SPRINT_SPEED or MOVE_SPEED

	self.VelocityX = 0
	if self.Keys.Left then
		self.VelocityX = -moveSpeed
	elseif self.Keys.Right then
		self.VelocityX = moveSpeed
	end

	if (self.Keys.Up or self.Keys.Jump) and self.Grounded then
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
		const rightEdge = newX + self.TileSize
		const checkTileX = rightEdge // self.TileSize
		const checkTileY1 = self.PixelY // self.TileSize
		const checkTileY2 = (self.PixelY + self.TileSize - 1) // self.TileSize
		if self:_isSolid(checkTileX, checkTileY1) or self:_isSolid(checkTileX, checkTileY2) then
			newX = checkTileX * self.TileSize - self.TileSize
			self.VelocityX = 0
		end
	elseif self.VelocityX < 0 then
		const leftEdge = newX
		const checkTileX = leftEdge // self.TileSize
		const checkTileY1 = self.PixelY // self.TileSize
		const checkTileY2 = (self.PixelY + self.TileSize - 1) // self.TileSize
		if self:_isSolid(checkTileX, checkTileY1) or self:_isSolid(checkTileX, checkTileY2) then
			newX = (checkTileX + 1) * self.TileSize
			self.VelocityX = 0
		end
	end

	if self.VelocityY < 0 then
		const topEdge = newY
		const checkTileY = topEdge // self.TileSize
		const checkTileX1 = newX // self.TileSize
		const checkTileX2 = (newX + self.TileSize - 1) // self.TileSize
		if self:_isSolid(checkTileX1, checkTileY) or self:_isSolid(checkTileX2, checkTileY) then
			newY = (checkTileY + 1) * self.TileSize
			self.VelocityY = 0
		end
	elseif self.VelocityY > 0 then
		const bottomEdge = newY + self.TileSize
		const checkTileY = bottomEdge // self.TileSize
		const checkTileX1 = newX // self.TileSize
		const checkTileX2 = (newX + self.TileSize - 1) // self.TileSize
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
	const screenW = self.Frame.Parent and self.Frame.Parent.AbsoluteSize.X or 800
	const screenH = self.Frame.Parent and self.Frame.Parent.AbsoluteSize.Y or 600
	const centerX = screenW * 0.5
	const centerY = screenH * 0.5
	return {
		x = self.PixelX + self.TileSize * 0.5 - centerX,
		y = self.PixelY + self.TileSize * 0.5 - centerY,
	}
end

function PlayerController:getWorldPosition(self: PlayerController): (number, number)
	return self.TileX, self.TileY
end

return PlayerController
