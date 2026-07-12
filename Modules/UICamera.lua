--!strict

export type Vec2 = {
	x: number,
	y: number,
}

export type CameraConfig = {
	smoothing: number,
	deadzone: Vec2,
	boundsMin: Vec2,
	boundsMax: Vec2,
	zoom: number,
}

export type UICamera = {
	_worldFrame: Frame,
	_config: CameraConfig,
	_offsetX: number,
	_offsetY: number,
	_velocityX: number,
	_velocityY: number,
	_shakeIntensity: number,
	_shakeDuration: number,
	_shakeTimer: number,
	_shakeOffsetX: number,
	_shakeOffsetY: number,
}

local UICamera = {}
UICamera.__index = UICamera

const DEFAULT_SMOOTHING = 0.15
const DEFAULT_DEADZONE_X = 32
const DEFAULT_DEADZONE_Y = 32
const SHAKE_EXPONENT = 2

local function smoothDamp(current: number, target: number, velocity: number, smoothing: number, dt: number): (number, number)
	const response = smoothing * 60
	const factor = math.clamp(response * dt, 0, 1)
	const newVelocity = math.lerp(velocity, (target - current) * response, factor)
	const newPosition = current + newVelocity * dt
	return newPosition, newVelocity
end

function UICamera.new(worldFrame: Frame, config: CameraConfig?): UICamera
	const self = setmetatable({}, UICamera) :: any

	self._worldFrame = worldFrame

	const cfg = config or {}
	self._config = {
		smoothing = cfg.smoothing or DEFAULT_SMOOTHING,
		deadzone = {
			x = cfg.deadzone and cfg.deadzone.x or DEFAULT_DEADZONE_X,
			y = cfg.deadzone and cfg.deadzone.y or DEFAULT_DEADZONE_Y,
		},
		boundsMin = {
			x = cfg.boundsMin and cfg.boundsMin.x or -1e9,
			y = cfg.boundsMin and cfg.boundsMin.y or -1e9,
		},
		boundsMax = {
			x = cfg.boundsMax and cfg.boundsMax.x or 1e9,
			y = cfg.boundsMax and cfg.boundsMax.y or 1e9,
		},
		zoom = cfg.zoom or 1,
	}

	const absSize = worldFrame.AbsoluteSize
	self._offsetX = absSize.X * 0.5
	self._offsetY = absSize.Y * 0.5
	self._velocityX = 0
	self._velocityY = 0
	self._shakeIntensity = 0
	self._shakeDuration = 0
	self._shakeTimer = 0
	self._shakeOffsetX = 0
	self._shakeOffsetY = 0

	return self :: UICamera
end

function UICamera:update(self: UICamera, targetX: number, targetY: number, dt: number): ()
	if dt <= 0 then return end

	const absSize = self._worldFrame.AbsoluteSize
	const screenW = absSize.X
	const screenH = absSize.Y
	const halfW = screenW * 0.5 / self._config.zoom
	const halfH = screenH * 0.5 / self._config.zoom

	const currentCenterX = self._offsetX + halfW
	const currentCenterY = self._offsetY + halfH

	const diffX = targetX - currentCenterX
	const diffY = targetY - currentCenterY

	local goalOffsetX = self._offsetX
	local goalOffsetY = self._offsetY

	if diffX > self._config.deadzone.x then
		goalOffsetX = targetX - self._config.deadzone.x - halfW
	elseif diffX < -self._config.deadzone.x then
		goalOffsetX = targetX + self._config.deadzone.x - halfW
	end

	if diffY > self._config.deadzone.y then
		goalOffsetY = targetY - self._config.deadzone.y - halfH
	elseif diffY < -self._config.deadzone.y then
		goalOffsetY = targetY + self._config.deadzone.y - halfH
	end

	const newX, newVelX = smoothDamp(self._offsetX, goalOffsetX, self._velocityX, self._config.smoothing, dt)
	const newY, newVelY = smoothDamp(self._offsetY, goalOffsetY, self._velocityY, self._config.smoothing, dt)

	self._offsetX = newX
	self._offsetY = newY
	self._velocityX = newVelX
	self._velocityY = newVelY

	const minX = self._config.boundsMin.x
	const minY = self._config.boundsMin.y
	const maxX = self._config.boundsMax.x - screenW / self._config.zoom
	const maxY = self._config.boundsMax.y - screenH / self._config.zoom

	self._offsetX = math.clamp(self._offsetX, minX, maxX)
	self._offsetY = math.clamp(self._offsetY, minY, maxY)

	if self._shakeTimer > 0 then
		self._shakeTimer -= dt
		const progress = math.clamp(self._shakeTimer / self._shakeDuration, 0, 1)
		const decay = progress ^ SHAKE_EXPONENT
		const intensity = self._shakeIntensity * decay
		self._shakeOffsetX = (math.random() * 2 - 1) * intensity
		self._shakeOffsetY = (math.random() * 2 - 1) * intensity
	else
		self._shakeOffsetX = 0
		self._shakeOffsetY = 0
	end
end

function UICamera:shake(self: UICamera, intensity: number, duration: number): ()
	self._shakeIntensity = intensity
	self._shakeDuration = duration
	self._shakeTimer = duration
end

function UICamera:getOffset(self: UICamera): Vec2
	return {
		x = self._offsetX + self._shakeOffsetX,
		y = self._offsetY + self._shakeOffsetY,
	}
end

function UICamera:setBounds(self: UICamera, min: Vec2, max: Vec2): ()
	self._config.boundsMin = { x = min.x, y = min.y }
	self._config.boundsMax = { x = max.x, y = max.y }
end

function UICamera:screenToWorld(self: UICamera, sx: number, sy: number): (number, number)
	const offset = self:getOffset()
	const wx = sx / self._config.zoom + offset.x
	const wy = sy / self._config.zoom + offset.y
	return wx, wy
end

function UICamera:worldToScreen(self: UICamera, wx: number, wy: number): (number, number)
	const offset = self:getOffset()
	const sx = (wx - offset.x) * self._config.zoom
	const sy = (wy - offset.y) * self._config.zoom
	return sx, sy
end

function UICamera:isVisible(self: UICamera, worldX: number, worldY: number, margin: number?): boolean
	const m = margin or 0
	const offset = self:getOffset()
	const absSize = self._worldFrame.AbsoluteSize
	const viewW = absSize.X / self._config.zoom
	const viewH = absSize.Y / self._config.zoom

	return worldX >= offset.x - m
		and worldX <= offset.x + viewW + m
		and worldY >= offset.y - m
		and worldY <= offset.y + viewH + m
end

return UICamera
