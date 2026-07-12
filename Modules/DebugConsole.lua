--!strict

local DebugConsole = {}
DebugConsole.__index = DebugConsole

function DebugConsole.new(screenGui)
	local self = setmetatable({}, DebugConsole)

	self._visible = false
	self._maxLines = 200
	self._lines = {}

	local container = Instance.new("Frame")
	container.Name = "DebugConsole"
	container.Size = UDim2.fromScale(0.5, 0.4)
	container.Position = UDim2.fromScale(0.25, 0.05)
	container.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	container.BackgroundTransparency = 0.05
	container.BorderSizePixel = 0
	container.Visible = false
	container.ZIndex = 500
	container.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = container

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(60, 60, 70)
	stroke.Thickness = 1
	stroke.Parent = container

	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.fromScale(1, 0.08)
	titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
	titleBar.BorderSizePixel = 0
	titleBar.ZIndex = 501
	titleBar.Parent = container

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 8)
	titleCorner.Parent = titleBar

	local titleCover = Instance.new("Frame")
	titleCover.Size = UDim2.fromScale(1, 0.5)
	titleCover.Position = UDim2.fromScale(0, 0.5)
	titleCover.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
	titleCover.BorderSizePixel = 0
	titleCover.ZIndex = 501
	titleCover.Parent = titleBar

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.fromScale(0.6, 1)
	titleLabel.Position = UDim2.fromScale(0.02, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "Console Output"
	titleLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.ZIndex = 502
	titleLabel.Parent = titleBar

	local copyBtn = Instance.new("TextButton")
	copyBtn.Name = "CopyBtn"
	copyBtn.Size = UDim2.fromScale(0.15, 0.7)
	copyBtn.Position = UDim2.fromScale(0.65, 0.15)
	copyBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 200)
	copyBtn.Text = "COPY"
	copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	copyBtn.TextScaled = true
	copyBtn.Font = Enum.Font.GothamBold
	copyBtn.BorderSizePixel = 0
	copyBtn.ZIndex = 502
	copyBtn.Parent = titleBar

	local copyCorner = Instance.new("UICorner")
	copyCorner.CornerRadius = UDim.new(0, 4)
	copyCorner.Parent = copyBtn

	copyBtn.MouseButton1Click:Connect(function()
		self:_copyAll()
	end)

	local clearBtn = Instance.new("TextButton")
	clearBtn.Name = "ClearBtn"
	clearBtn.Size = UDim2.fromScale(0.12, 0.7)
	clearBtn.Position = UDim2.fromScale(0.82, 0.15)
	clearBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	clearBtn.Text = "CLEAR"
	clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	clearBtn.TextScaled = true
	clearBtn.Font = Enum.Font.GothamBold
	clearBtn.BorderSizePixel = 0
	clearBtn.ZIndex = 502
	clearBtn.Parent = titleBar

	local clearCorner = Instance.new("UICorner")
	clearCorner.CornerRadius = UDim.new(0, 4)
	clearCorner.Parent = clearBtn

	clearBtn.MouseButton1Click:Connect(function()
		self:clear()
	end)

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "Log"
	scrollFrame.Size = UDim2.fromScale(1, 0.9)
	scrollFrame.Position = UDim2.fromScale(0, 0.1)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 4
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
	scrollFrame.CanvasSize = UDim2.fromScale(0, 0)
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollFrame.ZIndex = 501
	scrollFrame.Parent = container

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 2)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = scrollFrame

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 6)
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 4)
	padding.Parent = scrollFrame

	self._container = container
	self._scrollFrame = scrollFrame
	self._lineCount = 0

	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Name = "ToggleConsole"
	toggleBtn.Size = UDim2.fromOffset(36, 36)
	toggleBtn.Position = UDim2.fromScale(0, 0)
	toggleBtn.AnchorPoint = Vector2.new(0, 0)
	toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	toggleBtn.Text = ">"
	toggleBtn.TextColor3 = Color3.fromRGB(0, 255, 100)
	toggleBtn.TextScaled = true
	toggleBtn.Font = Enum.Font.Code
	toggleBtn.BorderSizePixel = 0
	toggleBtn.ZIndex = 600
	toggleBtn.Parent = screenGui

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0, 6)
	toggleCorner.Parent = toggleBtn

	toggleBtn.MouseButton1Click:Connect(function()
		self:toggle()
	end)

	self._toggleBtn = toggleBtn

	return self
end

function DebugConsole:toggle()
	self._visible = not self._visible
	self._container.Visible = self._visible
	self._toggleBtn.Text = self._visible and "X" or ">"
end

function DebugConsole:show()
	self._visible = true
	self._container.Visible = true
	self._toggleBtn.Text = "X"
end

function DebugConsole:hide()
	self._visible = false
	self._container.Visible = false
	self._toggleBtn.Text = ">"
end

function DebugConsole:log(message, msgType)
	msgType = msgType or "info"

	local color = Color3.fromRGB(200, 200, 200)
	local prefix = ""

	if msgType == "error" then
		color = Color3.fromRGB(255, 80, 80)
		prefix = "[ERROR] "
	elseif msgType == "warn" then
		color = Color3.fromRGB(255, 200, 50)
		prefix = "[WARN] "
	elseif msgType == "info" then
		color = Color3.fromRGB(100, 200, 255)
	elseif msgType == "print" then
		color = Color3.fromRGB(200, 200, 200)
	end

	self._lineCount += 1

	local label = Instance.new("TextLabel")
	label.Name = "Line" .. self._lineCount
	label.Size = UDim2.fromScale(1, 0)
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.BackgroundTransparency = 1
	label.Text = prefix .. message
	label.TextColor3 = color
	label.TextScaled = false
	label.TextSize = 13
	label.Font = Enum.Font.Code
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.TextTransparency = 0
	label.ZIndex = 502
	label.LayoutOrder = self._lineCount
	label.Parent = self._scrollFrame

	table.insert(self._lines, prefix .. message)

	if #self._lines > self._maxLines then
		local firstChild = self._scrollFrame:FindFirstChild("Line1")
		if firstChild then
			firstChild:Destroy()
		end
		table.remove(self._lines, 1)
	end

	self._scrollFrame.CanvasPosition = Vector2.new(0, self._scrollFrame.AbsoluteCanvasSize.Y)
end

function DebugConsole:clear()
	for _, child in self._scrollFrame:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	self._lines = {}
	self._lineCount = 0
end

function DebugConsole:_copyAll()
	local allText = table.concat(self._lines, "\n")

	pcall(function()
		local clipboard = Instance.new("BindableFunction")
		clipboard.Name = "ClipboardCopy"
		clipboard.Parent = game:GetService("CoreGui")

		local HttpService = game:GetService("HttpService")
		local json = HttpService:JSONEncode({text = allText})

		clipboard:Invoke(json)
		clipboard:Destroy()
	end)

	self:log("Console output copied!", "info")
end

function DebugConsole:hookOutput()
	local originalPrint = print
	local originalWarn = warn
	local originalError = error

	local console = self

	local function formatArgs(...)
		local args = {...}
		local parts = {}
		for i, v in args do
			parts[i] = tostring(v)
		end
		return table.concat(parts, "\t")
	end

	print = function(...)
		originalPrint(...)
		console:log(formatArgs(...), "print")
	end

	warn = function(...)
		originalWarn(...)
		console:log(formatArgs(...), "warn")
	end

	game:GetService("LogService").MessageOut:Connect(function(message, messageType)
		if messageType == Enum.MessageType.MessageOutput then
			console:log(message, "print")
		elseif messageType == Enum.MessageType.MessageWarning then
			console:log(message, "warn")
		elseif messageType == Enum.MessageType.MessageError then
			console:log(message, "error")
		end
	end)
end

return DebugConsole
