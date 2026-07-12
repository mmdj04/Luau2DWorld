--!strict

local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

export type Vec2 = {
	x: number,
	y: number,
}

export type FrameProps = {
	Name: string?,
	Size: {x: number, y: number}?,
	Position: {x: number, y: number}?,
	AnchorPoint: Vec2?,
	Color: Color3?,
	Transparency: number?,
	BorderSizePixel: number?,
	BorderColor3: Color3?,
	Parent: Instance?,
	CornerRadius: number?,
	ZIndex: number?,
	Gradient: {Color: ColorSequence, Rotation: number}?,
}

export type LabelProps = {
	Text: string?,
	Font: Enum.Font?,
	TextSize: number?,
	TextColor: Color3?,
	Size: {x: number, y: number}?,
	Position: {x: number, y: number}?,
	AnchorPoint: Vec2?,
	Parent: Instance?,
	BackgroundTransparency: number?,
	TextScaled: boolean?,
	ZIndex: number?,
}

local UITools = {}

const BRIGHTNESS_HOVER = 1.15
const BRIGHTNESS_CLICK = 0.85
const HOVER_SPEED = 0.15
const CLICK_SPEED = 0.05

local function adjustBrightness(color: Color3, factor: number): Color3
	return Color3.new(
		math.clamp(color.R * factor, 0, 1),
		math.clamp(color.G * factor, 0, 1),
		math.clamp(color.B * factor, 0, 1)
	)
end

function UITools.createFrame(props: FrameProps): Frame
	const frame = Instance.new("Frame")
	frame.Name = props.Name or "Frame"

	if props.Size then
		frame.Size = UDim2.fromScale(props.Size.x, props.Size.y)
	end
	if props.Position then
		frame.Position = UDim2.fromScale(props.Position.x, props.Position.y)
	end
	if props.AnchorPoint then
		frame.AnchorPoint = Vector2.new(props.AnchorPoint.x, props.AnchorPoint.y)
	end
	if props.Color then
		frame.BackgroundColor3 = props.Color
	end
	frame.BackgroundTransparency = props.Transparency or 0
	frame.BorderSizePixel = props.BorderSizePixel or 0
	if props.BorderColor3 then
		frame.BorderColor3 = props.BorderColor3
	end
	if props.ZIndex then
		frame.ZIndex = props.ZIndex
	end
	if props.CornerRadius and props.CornerRadius > 0 then
		const corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, props.CornerRadius)
		corner.Parent = frame
	end
	if props.Gradient then
		const gradient = Instance.new("UIGradient")
		gradient.Color = props.Gradient.Color
		gradient.Rotation = props.Gradient.Rotation or 0
		gradient.Parent = frame
	end
	if props.Parent then
		frame.Parent = props.Parent
	end
	return frame
end

function UITools.createLabel(props: LabelProps): TextLabel
	const label = Instance.new("TextLabel")
	label.Name = "Label"
	if props.Text then
		label.Text = props.Text
	end
	label.Font = props.Font or Enum.Font.Gotham
	label.TextSize = props.TextSize or 14
	if props.TextColor then
		label.TextColor3 = props.TextColor
	else
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
	if props.Size then
		label.Size = UDim2.fromScale(props.Size.x, props.Size.y)
	end
	if props.Position then
		label.Position = UDim2.fromScale(props.Position.x, props.Position.y)
	end
	if props.AnchorPoint then
		label.AnchorPoint = Vector2.new(props.AnchorPoint.x, props.AnchorPoint.y)
	end
	label.BackgroundTransparency = props.BackgroundTransparency or 1
	label.TextScaled = props.TextScaled or false
	if props.ZIndex then
		label.ZIndex = props.ZIndex
	end
	if props.Parent then
		label.Parent = props.Parent
	end
	return label
end

function UITools.tweenFrame(
	frame: Frame,
	properties: {[string]: any},
	duration: number,
	style: Enum.EasingStyle?,
	direction: Enum.EasingDirection?
): Tween
	const info = TweenInfo.new(
		duration,
		style or Enum.EasingStyle.Quad,
		direction or Enum.EasingDirection.Out
	)
	const tween = game:GetService("TweenService"):Create(frame, info, properties)
	tween:Play()
	return tween
end

function UITools.worldToScreen(
	worldX: number,
	worldY: number,
	cameraX: number,
	cameraY: number,
	tileSize: number
): (number, number)
	const sx = (worldX * tileSize - cameraX)
	const sy = (worldY * tileSize - cameraY)
	return sx, sy
end

function UITools.screenToWorld(
	screenX: number,
	screenY: number,
	cameraX: number,
	cameraY: number,
	tileSize: number
): (number, number)
	const wx = (screenX + cameraX) // tileSize
	const wy = (screenY + cameraY) // tileSize
	return wx, wy
end

function UITools.lerp(a: number, b: number, t: number): number
	return a + (b - a) * math.clamp(t, 0, 1)
end

function UITools.lerpColor(colorA: Color3, colorB: Color3, t: number): Color3
	const ct = math.clamp(t, 0, 1)
	return Color3.new(
		colorA.R + (colorB.R - colorA.R) * ct,
		colorA.G + (colorB.G - colorA.G) * ct,
		colorA.B + (colorB.B - colorA.B) * ct
	)
end

function UITools.smoothDamp(
	current: number,
	target: number,
	velocity: {number},
	smoothTime: number,
	dt: number
): number
	const omega = 2 / math.clamp(smoothTime, 0.0001, math.huge)
	const x = omega * dt
	const exp = 1 / (1 + x + 0.48 * x * x + 0.235 * x * x * x)
	const change = current - target
	const temp = (velocity[1] + omega * change) * dt
	velocity[1] = (velocity[1] - omega * temp) * exp
	local output = target + (change + temp) * exp
	if (target - current > 0) == (output > target) then
		output = target
		velocity[1] = (output - target) / dt
	end
	return output
end

function UITools.createButton(
	props: FrameProps,
	onClick: (() -> ())?
): Frame
	const button = UITools.createFrame(props)

	local hoverConnection: RBXScriptConnection?
	local leaveConnection: RBXScriptConnection?
	local downConnection: RBXScriptConnection?
	local upConnection: RBXScriptConnection?

	if props.Color then
		const baseColor = props.Color

		hoverConnection = button.InputBegan:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				UITools.tweenFrame(button, {BackgroundColor3 = adjustBrightness(baseColor, BRIGHTNESS_HOVER)}, HOVER_SPEED)
			end
		end)

		leaveConnection = button.InputEnded:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				UITools.tweenFrame(button, {BackgroundColor3 = baseColor}, HOVER_SPEED)
			end
		end)

		downConnection = button.InputBegan:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				UITools.tweenFrame(button, {BackgroundColor3 = adjustBrightness(baseColor, BRIGHTNESS_CLICK)}, CLICK_SPEED)
			end
		end)

		upConnection = button.InputEnded:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				UITools.tweenFrame(button, {BackgroundColor3 = adjustBrightness(baseColor, BRIGHTNESS_HOVER)}, CLICK_SPEED)
			end
		end)
	end

	if onClick then
		button.InputBegan:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				onClick()
			end
		end)
	end

	return button
end

function UITools.formatNumber(n: number): string
	if n >= 1_000_000 then
		return `"{string.format("%.1f", n / 1_000_000)}M"`
	elseif n >= 1_000 then
		return `"{string.format("%.1f", n / 1_000)}K"`
	end
	return tostring(n)
end

return UITools
