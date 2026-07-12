-- DebugConsole (standalone LocalScript)
-- Colocar DIRECTAMENTE em StarterGui (nao dentro de Luau2DWorld)
-- Funciona mesmo que o jogo quebre

local Players = game:GetService("Players")
local LogService = game:GetService("LogService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local MAX_LINES = 300
local allLines = {}

local gui = Instance.new("ScreenGui")
gui.Name = "DebugConsole"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 9999
gui.Parent = playerGui

local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "Toggle"
toggleBtn.Size = UDim2.fromOffset(40, 40)
toggleBtn.Position = UDim2.fromOffset(8, 8)
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
toggleBtn.Text = ">"
toggleBtn.TextColor3 = Color3.fromRGB(0, 255, 100)
toggleBtn.TextScaled = true
toggleBtn.Font = Enum.Font.Code
toggleBtn.BorderSizePixel = 0
toggleBtn.ZIndex = 9999
toggleBtn.Parent = gui

local tCorner = Instance.new("UICorner")
tCorner.CornerRadius = UDim.new(0, 6)
tCorner.Parent = toggleBtn

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromScale(0.6, 0.5)
panel.Position = UDim2.fromScale(0.2, 0.05)
panel.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
panel.BackgroundTransparency = 0.02
panel.BorderSizePixel = 0
panel.Visible = false
panel.ZIndex = 9998
panel.Parent = gui

local pCorner = Instance.new("UICorner")
pCorner.CornerRadius = UDim.new(0, 8)
pCorner.Parent = panel

local pStroke = Instance.new("UIStroke")
pStroke.Color = Color3.fromRGB(50, 50, 60)
pStroke.Thickness = 1
pStroke.Parent = panel

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.fromScale(1, 0.07)
topBar.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
topBar.BorderSizePixel = 0
topBar.ZIndex = 9999
topBar.Parent = panel

local topCover = Instance.new("Frame")
topCover.Size = UDim2.fromScale(1, 0.5)
topCover.Position = UDim2.fromScale(0, 0.5)
topCover.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
topCover.BorderSizePixel = 0
topCover.ZIndex = 9999
topCover.Parent = topBar

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 8)
topCorner.Parent = topBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.fromScale(0.4, 1)
titleLabel.Position = UDim2.fromScale(0.02, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Console"
titleLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.Code
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 10000
titleLabel.Parent = topBar

local copyBtn = Instance.new("TextButton")
copyBtn.Size = UDim2.fromScale(0.18, 0.65)
copyBtn.Position = UDim2.fromScale(0.55, 0.175)
copyBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 180)
copyBtn.Text = "COPY"
copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
copyBtn.TextScaled = true
copyBtn.Font = Enum.Font.GothamBold
copyBtn.BorderSizePixel = 0
copyBtn.ZIndex = 10000
copyBtn.Parent = topBar

local copyCorner = Instance.new("UICorner")
copyCorner.CornerRadius = UDim.new(0, 4)
copyCorner.Parent = copyBtn

local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.fromScale(0.18, 0.65)
clearBtn.Position = UDim2.fromScale(0.76, 0.175)
clearBtn.BackgroundColor3 = Color3.fromRGB(160, 40, 40)
clearBtn.Text = "CLEAR"
clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearBtn.TextScaled = true
clearBtn.Font = Enum.Font.GothamBold
clearBtn.BorderSizePixel = 0
clearBtn.ZIndex = 10000
clearBtn.Parent = topBar

local clearCorner = Instance.new("UICorner")
clearCorner.CornerRadius = UDim.new(0, 4)
clearCorner.Parent = clearBtn

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "Log"
scroll.Size = UDim2.fromScale(1, 0.92)
scroll.Position = UDim2.fromScale(0, 0.08)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100)
scroll.CanvasSize = UDim2.fromScale(0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ZIndex = 9999
scroll.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 1)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

local sPad = Instance.new("UIPadding")
sPad.PaddingLeft = UDim.new(0, 6)
sPad.PaddingTop = UDim.new(0, 4)
sPad.PaddingBottom = UDim.new(0, 4)
sPad.Parent = scroll

local lineCounter = 0

local function addLine(text, color)
	lineCounter += 1

	local label = Instance.new("TextLabel")
	label.Name = "L" .. lineCounter
	label.Size = UDim2.fromScale(1, 0)
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or Color3.fromRGB(200, 200, 200)
	label.TextScaled = false
	label.TextSize = 12
	label.Font = Enum.Font.Code
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.ZIndex = 10000
	label.LayoutOrder = lineCounter
	label.Parent = scroll

	table.insert(allLines, text)

	if #allLines > MAX_LINES then
		local old = scroll:FindFirstChild("L" .. (lineCounter - MAX_LINES))
		if old then
			old:Destroy()
		end
		table.remove(allLines, 1)
	end

	scroll.CanvasPosition = Vector2.new(0, scroll.AbsoluteCanvasSize.Y)
end

local function formatArgs(...)
	local parts = {}
	local n = select("#", ...)
	for i = 1, n do
		parts[i] = tostring(select(i, ...))
	end
	return table.concat(parts, "\t")
end

local savedPrint = print
local savedWarn = warn
local savedError = error

print = function(...)
	savedPrint(...)
	addLine(formatArgs(...), Color3.fromRGB(200, 200, 200))
end

warn = function(...)
	savedWarn(...)
	addLine("[WARN] " .. formatArgs(...), Color3.fromRGB(255, 200, 50))
end

LogService.MessageOut:Connect(function(msg, msgType)
	if msgType == Enum.MessageType.MessageOutput then
		addLine(msg, Color3.fromRGB(180, 180, 180))
	elseif msgType == Enum.MessageType.MessageWarning then
		addLine("[WARN] " .. msg, Color3.fromRGB(255, 200, 50))
	elseif msgType == Enum.MessageType.MessageError then
		addLine("[ERROR] " .. msg, Color3.fromRGB(255, 70, 70))
	end
end)

toggleBtn.MouseButton1Click:Connect(function()
	panel.Visible = not panel.Visible
	toggleBtn.Text = panel.Visible and "X" or ">"
end)

copyBtn.MouseButton1Click:Connect(function()
	local text = table.concat(allLines, "\n")

	pcall(function()
		if setclipboard then
			setclipboard(text)
		elseif syn and syn clipboard then
			syn.clipboard.set(text)
		else
			local temp = Instance.new("BindableEvent")
			temp.Name = "CopyEvent"
			temp.Parent = game:GetService("CoreGui")
			temp:Fire(text)
			temp:Destroy()
		end
	end)

	addLine("[SYSTEM] Console copied to clipboard!", Color3.fromRGB(0, 200, 100))
end)

clearBtn.MouseButton1Click:Connect(function()
	for _, child in scroll:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	allLines = {}
	lineCounter = 0
end)

addLine("=== Debug Console Active ===", Color3.fromRGB(0, 255, 100))
addLine("Capturing all output...", Color3.fromRGB(100, 200, 255))
