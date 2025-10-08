-- FYNX HUB

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
if not player then
    warn("FYNX HUB: script must run as a LocalScript (client).")
    return
end

-- helper: waitForChild with timeout (returns nil instead of yielding forever)
local function waitForChildTimeout(parent, name, timeout)
    local start = tick()
    while tick() - start < (timeout or 5) do
        local v = parent:FindFirstChild(name)
        if v then return v end
        task.wait(0.1)
    end
    return nil
end

-- try to find remotes safely (won't hang indefinitely now)
local remotesFolder = waitForChildTimeout(ReplicatedStorage, "Remotes", 3)
local buySeedEvent = remotesFolder and remotesFolder:FindFirstChild("BuyItem") or nil
local buyGearEvent = remotesFolder and remotesFolder:FindFirstChild("BuyGear") or nil
if not remotesFolder then
    warn("FYNX HUB: ReplicatedStorage.Remotes not found (auto-buy disabled).")
elseif not buySeedEvent or not buyGearEvent then
    warn("FYNX HUB: BuyItem/BuyGear remote(s) not found (auto-buy disabled).")
end

-- DATA
local seeds = {"Cactus","Strawberry","Pumpkin","Sunflower","Dragonfruit","Eggplant","Watermelon","Grape","Cocotank","Carnivorous Plant","Mr Carrot","Tomatrio","Shroombino","Mango"}
local gears = {"Water Bucket","Frost Grenade","Banana Gun","Carrot Launcher","Frost Blower"}

local selectedSeeds, selectedGears = {}, {}
local autoBuy = false
local minimized = false
local buysPerItem = 5
local perItemDelay = 0.05

-- player controls
local DEFAULT_WALKSPEED = 16
local savedWalkSpeed = DEFAULT_WALKSPEED
local infiniteJumpEnabled = false

-- click sound helper
local function playClickSound()
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://12221967"
    s.Volume = 0.3
    s.PlayOnRemove = true
    s.Parent = SoundService
    s:Destroy()
end

-- GUI parent: prefer PlayerGui (safe). fallback to gethui() if available, else CoreGui.
local parentGui = player:FindFirstChild("PlayerGui") or ((gethui and gethui()) or game:GetService("CoreGui"))

local gui = Instance.new("ScreenGui")
gui.Name = "FYNX_HUB_GUI"
gui.ResetOnSpawn = false
gui.Parent = parentGui

-- Main frame
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 320, 0, 380)
frame.Position = UDim2.new(0.5, -160, 0.35, -100)
frame.BackgroundColor3 = Color3.fromRGB(25,25,40)
frame.BorderSizePixel = 0
frame.Active = true

-- Header
local header = Instance.new("Frame", frame)
header.Size = UDim2.new(1,0,0,40)
header.Position = UDim2.new(0,0,0,0)
header.BackgroundColor3 = Color3.fromRGB(95,75,200)
header.BorderSizePixel = 0

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1,-50,1,0)
title.Position = UDim2.new(0,10,0,0)
title.BackgroundTransparency = 1
title.Text = "FYNX HUB"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left

local minBtn = Instance.new("TextButton", header)
minBtn.Size = UDim2.new(0,36,0,28)
minBtn.Position = UDim2.new(1,-46,0,6)
minBtn.BackgroundColor3 = Color3.fromRGB(120,100,255)
minBtn.Text = "-"
minBtn.Font = Enum.Font.GothamBold
minBtn.TextColor3 = Color3.fromRGB(255,255,255)
minBtn.BorderSizePixel = 0

-- Tab bar
local tabButtons = Instance.new("Frame", frame)
tabButtons.Size = UDim2.new(1,0,0,36)
tabButtons.Position = UDim2.new(0,0,0,42)
tabButtons.BackgroundColor3 = Color3.fromRGB(30,30,55)
tabButtons.BorderSizePixel = 0

local function createTabButton(text, xPos)
    local btn = Instance.new("TextButton", tabButtons)
    btn.Size = UDim2.new(0.5, -10, 1, -6)
    btn.Position = UDim2.new(xPos, 5, 0, 3)
    btn.BackgroundColor3 = Color3.fromRGB(80,70,160)
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.BorderSizePixel = 0
    return btn
end

local homeBtn = createTabButton("🏠 Home", 0)
local playerBtn = createTabButton("👤 Player", 0.5)

-- tab frame area
local tabFrame = Instance.new("Frame", frame)
tabFrame.Size = UDim2.new(1,-20,1,-120)
tabFrame.Position = UDim2.new(0,10,0,80)
tabFrame.BackgroundColor3 = Color3.fromRGB(30,30,55)
tabFrame.BorderSizePixel = 0

-- HOME scroll (everything in home lives here; auto-resizes)
local homeScroll = Instance.new("ScrollingFrame", tabFrame)
homeScroll.Size = UDim2.new(1,-8,1,0)
homeScroll.Position = UDim2.new(0,4,0,0)
homeScroll.CanvasSize = UDim2.new(0,0,0,0)
homeScroll.ScrollBarThickness = 6
homeScroll.BackgroundTransparency = 1

-- PLAYER container (vertical layout)
local playerTab = Instance.new("Frame", tabFrame)
playerTab.Size = UDim2.new(1,-8,1,0)
playerTab.Position = UDim2.new(0,4,0,0)
playerTab.BackgroundTransparency = 1
playerTab.Visible = false

-- helper to create collapsible sections
local function createCollapsible(parent, titleText, items, selectedTable)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1,-10,0,32)
    container.Position = UDim2.new(0,5,0,0)
    container.BackgroundTransparency = 1

    local headerBtn = Instance.new("TextButton", container)
    headerBtn.Size = UDim2.new(1,0,0,32)
    headerBtn.Position = UDim2.new(0,0,0,0)
    headerBtn.BackgroundColor3 = Color3.fromRGB(95,75,200)
    headerBtn.Font = Enum.Font.GothamBold
    headerBtn.TextSize = 14
    headerBtn.TextColor3 = Color3.fromRGB(255,255,255)
    headerBtn.Text = titleText
    headerBtn.BorderSizePixel = 0

    local list = Instance.new("ScrollingFrame", container)
    list.Size = UDim2.new(1,0,0,0)
    list.Position = UDim2.new(0,0,0,36)
    list.BackgroundTransparency = 1
    list.ScrollBarThickness = 6
    list.CanvasSize = UDim2.new(0,0,0,#items * 28)
    list.Visible = false

    for i, name in ipairs(items) do
        local btn = Instance.new("TextButton", list)
        btn.Size = UDim2.new(1,-10,0,26)
        btn.Position = UDim2.new(0,5,0,(i-1)*28)
        btn.BackgroundColor3 = Color3.fromRGB(55,55,90)
        btn.TextColor3 = Color3.fromRGB(235,235,255)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 13
        btn.Text = name
        btn.BorderSizePixel = 0

        btn.MouseButton1Click:Connect(function()
            if selectedTable[name] then
                selectedTable[name] = nil
                btn.BackgroundColor3 = Color3.fromRGB(55,55,90)
            else
                selectedTable[name] = true
                btn.BackgroundColor3 = Color3.fromRGB(120,100,255)
            end
        end)
    end

    return container, headerBtn, list
end

-- create seed/gear sections
local seedSection, seedHeader, seedList = createCollapsible(homeScroll, "🌱 Seeds", seeds, selectedSeeds)
local gearSection, gearHeader, gearList = createCollapsible(homeScroll, "⚙️ Gears", gears, selectedGears)

-- update positions so gear follows seed; uses tweens for smooth movement
local function recalcPositions()
    local y = 5
    for _, sec in ipairs({seedSection, gearSection}) do
        local target = UDim2.new(0,5,0,y)
        TweenService:Create(sec, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = target}):Play()
        -- use AbsoluteSize when available
        local ht = sec.AbsoluteSize.Y
        if ht == 0 then ht = sec.Size.Y.Offset end
        y = y + ht + 5
    end

    -- small delay to let sizes settle
    task.delay(0.06, function()
        local total = 10
        for _, c in ipairs(homeScroll:GetChildren()) do
            if c:IsA("Frame") then
                total = total + c.AbsoluteSize.Y + 5
            end
        end
        homeScroll.CanvasSize = UDim2.new(0,0,0, math.max(total, homeScroll.AbsoluteSize.Y + 10))
    end)
end

-- toggle helper with tween
local function toggleList(list, container)
    playClickSound()
    local willExpand = not list.Visible
    local targetHeight = willExpand and math.min(list.CanvasSize.Y.Offset + 10, 160) or 0

    if willExpand then list.Visible = true end
    local tween = TweenService:Create(list, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1,0,0,targetHeight)})
    tween:Play()
    tween.Completed:Connect(function()
        if not willExpand then list.Visible = false end
        container.Size = UDim2.new(1, -10, 0, 36 + targetHeight)
        recalcPositions()
    end)
end

seedHeader.MouseButton1Click:Connect(function() toggleList(seedList, seedSection) end)
gearHeader.MouseButton1Click:Connect(function() toggleList(gearList, gearSection) end)

-- keep layout updated when sizes change
seedSection:GetPropertyChangedSignal("AbsoluteSize"):Connect(recalcPositions)
gearSection:GetPropertyChangedSignal("AbsoluteSize"):Connect(recalcPositions)
homeScroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(recalcPositions)
task.delay(0.05, recalcPositions)

-- PLAYER TAB UI (vertical)
local playerScroll = Instance.new("ScrollingFrame", playerTab)
playerScroll.Size = UDim2.new(1,-8,1,0)
playerScroll.Position = UDim2.new(0,4,0,0)
playerScroll.BackgroundTransparency = 1
playerScroll.ScrollBarThickness = 6
playerScroll.CanvasSize = UDim2.new(0,0,0,0)

local function updatePlayerCanvas()
    task.delay(0.05, function()
        local tot = 10
        for _, c in ipairs(playerScroll:GetChildren()) do
            if c:IsA("Frame") then
                tot = tot + c.AbsoluteSize.Y + 5
            end
        end
        playerScroll.CanvasSize = UDim2.new(0,0,0, math.max(tot, playerScroll.AbsoluteSize.Y + 10))
    end)
end

-- WalkSpeed section (vertical)
local function makePlayerSection(parent, title, y)
    local sec = Instance.new("Frame", parent)
    sec.Size = UDim2.new(1, -10, 0, 120)
    sec.Position = UDim2.new(0, 5, 0, y or 5)
    sec.BackgroundTransparency = 1

    local header = Instance.new("TextLabel", sec)
    header.Size = UDim2.new(1, 0, 0, 26)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundTransparency = 1
    header.Text = title
    header.Font = Enum.Font.GothamBold
    header.TextSize = 14
    header.TextColor3 = Color3.fromRGB(240,240,255)
    header.TextXAlignment = Enum.TextXAlignment.Left

    return sec
end

local walkSec = makePlayerSection(playerScroll, "💨 Walk Speed (1-100)", 5)
local speedBox = Instance.new("TextBox", walkSec)
speedBox.Size = UDim2.new(1, -20, 0, 30)
speedBox.Position = UDim2.new(0, 10, 0, 36)
speedBox.PlaceholderText = tostring(DEFAULT_WALKSPEED)
speedBox.Text = ""
speedBox.ClearTextOnFocus = false
speedBox.Font = Enum.Font.Gotham
speedBox.TextSize = 14
speedBox.TextColor3 = Color3.fromRGB(20,20,20)
speedBox.BackgroundColor3 = Color3.fromRGB(235,235,235)
speedBox.BorderSizePixel = 0

local setBtn = Instance.new("TextButton", walkSec)
setBtn.Size = UDim2.new(1, -20, 0, 30)
setBtn.Position = UDim2.new(0, 10, 0, 72)
setBtn.Text = "Set Speed"
setBtn.Font = Enum.Font.GothamBold
setBtn.TextSize = 14
setBtn.TextColor3 = Color3.fromRGB(20,20,20)
setBtn.BackgroundColor3 = Color3.fromRGB(140,110,255)
setBtn.BorderSizePixel = 0

local resetBtn = Instance.new("TextButton", walkSec)
resetBtn.Size = UDim2.new(1, -20, 0, 28)
resetBtn.Position = UDim2.new(0, 10, 0, 72 + 36)
resetBtn.Text = "Reset Speed"
resetBtn.Font = Enum.Font.GothamBold
resetBtn.TextSize = 12
resetBtn.TextColor3 = Color3.fromRGB(20,20,20)
resetBtn.BackgroundColor3 = Color3.fromRGB(200,200,200)
resetBtn.BorderSizePixel = 0

-- infinite jump section
local jumpSec = makePlayerSection(playerScroll, "🕊️ Infinite Jump", 5 + walkSec.Size.Y.Offset + 10)
jumpSec.Size = UDim2.new(1,-10,0,100)
local jumpToggle = Instance.new("TextButton", jumpSec)
jumpToggle.Size = UDim2.new(1,-20,0,36)
jumpToggle.Position = UDim2.new(0,10,0,36)
jumpToggle.Text = "Toggle Infinite Jump (OFF)"
jumpToggle.Font = Enum.Font.GothamBold
jumpToggle.TextSize = 14
jumpToggle.TextColor3 = Color3.fromRGB(255,255,255)
jumpToggle.BackgroundColor3 = Color3.fromRGB(55,55,90)
jumpToggle.BorderSizePixel = 0

updatePlayerCanvas()

-- WalkSpeed functions
local function applyWalkSpeedToHumanoid(humanoid)
    if humanoid and humanoid.Health > 0 then
        humanoid.WalkSpeed = savedWalkSpeed or DEFAULT_WALKSPEED
    end
end

local function setWalkSpeedFromText(text)
    local n = tonumber(text)
    if not n then return false end
    if n < 1 or n > 100 then return false end
    savedWalkSpeed = n
    -- apply to current character
    if player.Character then
        local h = player.Character:FindFirstChildOfClass("Humanoid")
        if h then applyWalkSpeedToHumanoid(h) end
    end
    return true
end

setBtn.MouseButton1Click:Connect(function()
    playClickSound()
    local ok = setWalkSpeedFromText(speedBox.Text)
    if not ok then
        local orig = speedBox.BackgroundColor3
        speedBox.BackgroundColor3 = Color3.fromRGB(255,180,180)
        task.delay(0.6, function() speedBox.BackgroundColor3 = orig end)
    end
end)

resetBtn.MouseButton1Click:Connect(function()
    playClickSound()
    savedWalkSpeed = DEFAULT_WALKSPEED
    speedBox.Text = ""
    if player.Character then
        local h = player.Character:FindFirstChildOfClass("Humanoid")
        if h then applyWalkSpeedToHumanoid(h) end
    end
end)

player.CharacterAdded:Connect(function(char)
    local h = char:WaitForChild("Humanoid", 5)
    if h then
        task.delay(0.1, function() applyWalkSpeedToHumanoid(h) end)
    end
end)

-- Infinite jump logic
local function setInfiniteJump(enabled)
    infiniteJumpEnabled = enabled
    if enabled then
        jumpToggle.BackgroundColor3 = Color3.fromRGB(120,100,255)
        jumpToggle.Text = "Toggle Infinite Jump (ON)"
    else
        jumpToggle.BackgroundColor3 = Color3.fromRGB(55,55,90)
        jumpToggle.Text = "Toggle Infinite Jump (OFF)"
    end
end

setInfiniteJump(false)

jumpToggle.MouseButton1Click:Connect(function()
    playClickSound()
    setInfiniteJump(not infiniteJumpEnabled)
end)

UserInputService.JumpRequest:Connect(function()
    if not infiniteJumpEnabled then return end
    local char = player.Character
    if not char then return end
    local h = char:FindFirstChildOfClass("Humanoid")
    if not h then return end
    h:ChangeState(Enum.HumanoidStateType.Jumping)
end)

-- Auto-buy loop (safe: uses pcall and checks for nil remotes so script won't error)
task.spawn(function()
    while task.wait(0.05) do
        if autoBuy then
            for seed,_ in pairs(selectedSeeds) do
                if buySeedEvent then
                    pcall(function() buySeedEvent:FireServer(seed .. " Seed", true) end)
                    task.wait(perItemDelay)
                end
            end
            for gear,_ in pairs(selectedGears) do
                if buyGearEvent then
                    pcall(function() buyGearEvent:FireServer(gear, true) end)
                    task.wait(perItemDelay)
                end
            end
        end
    end
end)

-- Bottom buttons
local discordBtn = Instance.new("TextButton", frame)
discordBtn.Size = UDim2.new(1,-20,0,28)
discordBtn.Position = UDim2.new(0,10,1,-82)
discordBtn.BackgroundColor3 = Color3.fromRGB(80,80,255)
discordBtn.Text = "Join Discord"
discordBtn.Font = Enum.Font.GothamBold
discordBtn.TextSize = 14
discordBtn.TextColor3 = Color3.fromRGB(255,255,255)
discordBtn.BorderSizePixel = 0
discordBtn.MouseButton1Click:Connect(function()
    playClickSound()
    pcall(function() setclipboard("https://discord.gg/ReGmGrQT") end)
end)

local startBtn = Instance.new("TextButton", frame)
startBtn.Size = UDim2.new(1,-20,0,36)
startBtn.Position = UDim2.new(0,10,1,-46)
startBtn.BackgroundColor3 = Color3.fromRGB(140,110,255)
startBtn.Text = "▶ Start Auto Buy"
startBtn.Font = Enum.Font.GothamBold
startBtn.TextSize = 14
startBtn.TextColor3 = Color3.fromRGB(20,20,20)
startBtn.BorderSizePixel = 0
startBtn.MouseButton1Click:Connect(function()
    playClickSound()
    autoBuy = not autoBuy
    startBtn.Text = autoBuy and "🛑 Stop Auto Buy" or "▶ Start Auto Buy"
end)

-- Minimizing & Logo
local logo = Instance.new("TextButton", gui)
logo.Size = UDim2.new(0,50,0,50)
logo.Position = UDim2.new(0.5, -25, 0.4, -25)
logo.Text = "F"
logo.Font = Enum.Font.GothamBold
logo.TextSize = 24
logo.TextColor3 = Color3.fromRGB(255,255,255)
logo.BackgroundColor3 = Color3.fromRGB(95,75,200)
logo.BorderSizePixel = 0
logo.Visible = false
logo.MouseButton1Click:Connect(function()
    playClickSound()
    minimized = false
    frame.Visible = true
    logo.Visible = false
end)

minBtn.MouseButton1Click:Connect(function()
    playClickSound()
    minimized = not minimized
    frame.Visible = not minimized
    logo.Visible = minimized
end)

-- Tab switching
homeBtn.MouseButton1Click:Connect(function()
    playClickSound()
    homeScroll.Visible = true
    playerTab.Visible = false
end)
playerBtn.MouseButton1Click:Connect(function()
    playClickSound()
    playerTab.Visible = true
    homeScroll.Visible = false
end)

-- Draggable function (works for touch + mouse)
local function makeDraggable(obj, dragHandle)
    local dragging, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

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
            update(input)
        end
    end)
end

makeDraggable(frame, header)
makeDraggable(logo, logo)

-- apply saved walk speed on current character if present
if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
    local h = player.Character:FindFirstChildOfClass("Humanoid")
    if h then
        h.WalkSpeed = savedWalkSpeed
    end
end

-- initial layout updates
recalcPositions()
updatePlayerCanvas()

print("FYNX HUB loaded")
