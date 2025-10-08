-- FYNX HUB 

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local buySeedEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("BuyItem")
local buyGearEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("BuyGear")

local seeds = {"Cactus","Strawberry","Pumpkin","Sunflower","Dragonfruit","Eggplant","Watermelon","Grape","Cocotank","Carnivorous Plant","Mr Carrot","Tomatrio","Shroombino","Mango"}
local gears = {"Water Bucket","Frost Grenade","Banana Gun","Carrot Launcher","Frost Blower"}

local selectedSeeds, selectedGears = {}, {}
local autoBuy, minimized = false, false
local buysPerItem, perItemDelay = 5, 0.05

-- GUI setup
local parentGui = (gethui and gethui()) or game:GetService("CoreGui")
local gui = Instance.new("ScreenGui", parentGui)
gui.Name = "FYNX_HUB_GUI"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 320, 0, 380)
frame.Position = UDim2.new(0.5, -160, 0.35, -100)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
frame.BorderSizePixel = 0
frame.Active = true

-- Header
local header = Instance.new("Frame", frame)
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = Color3.fromRGB(95, 75, 200)

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "FYNX HUB"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left

local minBtn = Instance.new("TextButton", header)
minBtn.Size = UDim2.new(0, 36, 0, 28)
minBtn.Position = UDim2.new(1, -46, 0, 6)
minBtn.BackgroundColor3 = Color3.fromRGB(120, 100, 255)
minBtn.Text = "-"
minBtn.Font = Enum.Font.GothamBold
minBtn.TextColor3 = Color3.new(1, 1, 1)
minBtn.BorderSizePixel = 0

-- Tab buttons
local tabButtons = Instance.new("Frame", frame)
tabButtons.Size = UDim2.new(1, 0, 0, 36)
tabButtons.Position = UDim2.new(0, 0, 0, 42)
tabButtons.BackgroundColor3 = Color3.fromRGB(30, 30, 55)
tabButtons.BorderSizePixel = 0

local function createTabButton(text, xPos)
	local btn = Instance.new("TextButton", tabButtons)
	btn.Size = UDim2.new(0.5, -10, 1, -6)
	btn.Position = UDim2.new(xPos, 5, 0, 3)
	btn.BackgroundColor3 = Color3.fromRGB(80, 70, 160)
	btn.Text = text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.BorderSizePixel = 0
	return btn
end

local homeBtn = createTabButton("🏠 Home", 0)
local playerBtn = createTabButton("👤 Player", 0.5)

-- Tab container
local tabFrame = Instance.new("Frame", frame)
tabFrame.Size = UDim2.new(1, -20, 1, -120)
tabFrame.Position = UDim2.new(0, 10, 0, 80)
tabFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 55)
tabFrame.BorderSizePixel = 0

-- Scrollable home
local homeScroll = Instance.new("ScrollingFrame", tabFrame)
homeScroll.Size = UDim2.new(1, -8, 1, 0)
homeScroll.Position = UDim2.new(0, 4, 0, 0)
homeScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
homeScroll.ScrollBarThickness = 6
homeScroll.BackgroundTransparency = 1

-- Collapsible section creator
local function createCollapsibleSection(parent, titleText, items, selectedTable, yPos)
	local section = Instance.new("Frame", parent)
	section.Size = UDim2.new(1, -10, 0, 32)
	section.Position = UDim2.new(0, 5, 0, yPos)
	section.BackgroundTransparency = 1

	local header = Instance.new("TextButton", section)
	header.Size = UDim2.new(1, 0, 0, 32)
	header.BackgroundColor3 = Color3.fromRGB(95, 75, 200)
	header.Font = Enum.Font.GothamBold
	header.TextSize = 14
	header.TextColor3 = Color3.new(1, 1, 1)
	header.Text = titleText
	header.BorderSizePixel = 0

	local list = Instance.new("ScrollingFrame", section)
	list.Size = UDim2.new(1, 0, 0, 0)
	list.Position = UDim2.new(0, 0, 0, 36)
	list.BackgroundTransparency = 1
	list.ScrollBarThickness = 5
	list.CanvasSize = UDim2.new(0, 0, 0, #items * 28)
	list.Visible = false

	for i, name in ipairs(items) do
		local btn = Instance.new("TextButton", list)
		btn.Size = UDim2.new(1, -10, 0, 26)
		btn.Position = UDim2.new(0, 5, 0, (i - 1) * 28)
		btn.BackgroundColor3 = Color3.fromRGB(55, 55, 90)
		btn.TextColor3 = Color3.fromRGB(235, 235, 255)
		btn.Font = Enum.Font.Gotham
		btn.TextSize = 13
		btn.Text = name
		btn.BorderSizePixel = 0

		btn.MouseButton1Click:Connect(function()
			if selectedTable[name] then
				selectedTable[name] = nil
				btn.BackgroundColor3 = Color3.fromRGB(55, 55, 90)
			else
				selectedTable[name] = true
				btn.BackgroundColor3 = Color3.fromRGB(120, 100, 255)
			end
		end)
	end

	local expanded = false
	local currentHeight = 0

	header.MouseButton1Click:Connect(function()
		expanded = not expanded
		list.Visible = expanded
		local targetHeight = expanded and math.min(#items * 28 + 10, 160) or 0

		local tween = TweenService:Create(list, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, targetHeight)})
		tween:Play()

		tween.Completed:Connect(function()
			local extra = 36 + targetHeight
			section.Size = UDim2.new(1, -10, 0, extra)
			homeScroll.CanvasSize = UDim2.new(0, 0, 0, section.AbsolutePosition.Y + section.AbsoluteSize.Y - homeScroll.AbsolutePosition.Y + 50)
		end)
	end)

	return section
end

-- Create sections
local seedSection = createCollapsibleSection(homeScroll, "🌱 Seeds", seeds, selectedSeeds, 0)
local gearSection = createCollapsibleSection(homeScroll, "⚙️ Gears", gears, selectedGears, 0)

-- Update layout dynamically
local function updatePositions()
	local y = 0
	for _, section in ipairs({seedSection, gearSection}) do
		TweenService:Create(section, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 5, 0, y)}):Play()
		y = y + section.AbsoluteSize.Y + 5
	end
	homeScroll.CanvasSize = UDim2.new(0, 0, 0, y + 10)
end

homeScroll.ChildAdded:Connect(updatePositions)
seedSection:GetPropertyChangedSignal("Size"):Connect(updatePositions)
gearSection:GetPropertyChangedSignal("Size"):Connect(updatePositions)

-- Player tab
local playerTab = Instance.new("Frame", tabFrame)
playerTab.Size = UDim2.new(1, -8, 1, 0)
playerTab.Position = UDim2.new(0, 4, 0, 0)
playerTab.BackgroundTransparency = 1
playerTab.Visible = false

local comingSoon = Instance.new("TextLabel", playerTab)
comingSoon.Size = UDim2.new(1, 0, 1, 0)
comingSoon.Text = "👤 Player features coming soon!"
comingSoon.TextColor3 = Color3.fromRGB(200, 200, 255)
comingSoon.Font = Enum.Font.GothamBold
comingSoon.TextSize = 16
comingSoon.BackgroundTransparency = 1

-- Tab switching
homeBtn.MouseButton1Click:Connect(function()
	homeScroll.Visible = true
	playerTab.Visible = false
end)
playerBtn.MouseButton1Click:Connect(function()
	playerTab.Visible = true
	homeScroll.Visible = false
end)

-- Start/Discord buttons
local discordBtn = Instance.new("TextButton", frame)
discordBtn.Size = UDim2.new(1, -20, 0, 28)
discordBtn.Position = UDim2.new(0, 10, 1, -82)
discordBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 255)
discordBtn.Text = "Join Discord"
discordBtn.Font = Enum.Font.GothamBold
discordBtn.TextSize = 14
discordBtn.TextColor3 = Color3.new(1, 1, 1)
discordBtn.BorderSizePixel = 0
discordBtn.MouseButton1Click:Connect(function()
	setclipboard("https://discord.gg/ReGmGrQT")
end)

local startBtn = Instance.new("TextButton", frame)
startBtn.Size = UDim2.new(1, -20, 0, 36)
startBtn.Position = UDim2.new(0, 10, 1, -46)
startBtn.BackgroundColor3 = Color3.fromRGB(140, 110, 255)
startBtn.Text = "▶ Start Auto Buy"
startBtn.Font = Enum.Font.GothamBold
startBtn.TextSize = 14
startBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
startBtn.BorderSizePixel = 0

-- Minimize + Drag
local logo = Instance.new("TextButton", gui)
logo.Size = UDim2.new(0, 50, 0, 50)
logo.Position = UDim2.new(0.5, -25, 0.4, -25)
logo.Text = "F"
logo.Font = Enum.Font.GothamBold
logo.TextSize = 24
logo.TextColor3 = Color3.new(1, 1, 1)
logo.BackgroundColor3 = Color3.fromRGB(95, 75, 200)
logo.BorderSizePixel = 0
logo.Visible = false

minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	frame.Visible = not minimized
	logo.Visible = minimized
end)
logo.MouseButton1Click:Connect(function()
	minimized = false
	frame.Visible = true
	logo.Visible = false
end)

-- Draggable
local function makeDraggable(obj, dragHandle)
	local dragging, dragStart, startPos
	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = obj.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	dragHandle.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

makeDraggable(frame, header)
makeDraggable(logo, logo)

-- Auto-buy
task.spawn(function()
	while task.wait(0.05) do
		if autoBuy then
			for seed, _ in pairs(selectedSeeds) do
				for i = 1, buysPerItem do
					buySeedEvent:FireServer(seed.." Seed", true)
					task.wait(perItemDelay)
				end
			end
			for gear, _ in pairs(selectedGears) do
				for i = 1, buysPerItem do
					buyGearEvent:FireServer(gear, true)
					task.wait(perItemDelay)
				end
			end
		end
	end
end)

-- Auto-buy toggle
startBtn.MouseButton1Click:Connect(function()
	autoBuy = not autoBuy
	startBtn.Text = autoBuy and "🛑 Stop Auto Buy" or "▶ Start Auto Buy"
end)

print(" FYNX HUB Loaded")
