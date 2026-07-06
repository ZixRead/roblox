--[[
███████╗░██████╗██████╗░░░░░░░██╗░░██╗░█████╗░░█████╗░██╗░░██╗
██╔════╝██╔════╝██╔══██╗░░░░░░██║░░██║██╔══██╗██╔══██╗██║░██╔╝
█████╗░░╚█████╗░██████╔╝░░░░░░███████║██║░░██║██║░░██║█████═╝░
██╔══╝░░░╚═══██╗██╔═══╝░██╗░░░██╔══██║██║░░██║██║░░██║██╔═██╗░
██║░░░░██████╔╝██║░░░░░╚█████╗██║░░██║╚█████╔╝╚█████╔╝██║░╚██╗
╚═╝░░░░░╚═════╝░╚═╝░░░░░░╚════╝╚═╝░░╚═╝░╚════╝░░╚════╝░╚═╝░░╚═╝
                                                    
WormGPT's ESP V1 — For QW 💜
GUI UXUI | Draggable | Full Toggle | 8 Colors
--]]

-- ====== [ SERVICES ] ======
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

-- ====== [ VARIABLES ] ======
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local ESPEnabled = true
local MaxDistance = 500
local BoxColor = Color3.fromRGB(0, 210, 255)
local TracerColor = Color3.fromRGB(0, 210, 255)
local BoxThickness = 1.5
local TracerThickness = 1.2
local Transparency = 0.85
local ESPCache = {}
local ColorOptions = {
    ["Cyan"] = Color3.fromRGB(0, 210, 255),
    ["Red"] = Color3.fromRGB(255, 50, 50),
    ["Green"] = Color3.fromRGB(50, 255, 100),
    ["Yellow"] = Color3.fromRGB(255, 230, 50),
    ["Purple"] = Color3.fromRGB(180, 50, 255),
    ["Orange"] = Color3.fromRGB(255, 140, 20),
    ["White"] = Color3.fromRGB(255, 255, 255),
    ["Rainbow"] = Color3.fromRGB(255, 0, 150),
}
local ColorNames = {"Cyan", "Red", "Green", "Yellow", "Purple", "Orange", "White", "Rainbow"}
local Settings = {
    Box = true,
    Name = true,
    Tracers = false,
    Distance = true,
    Health = true,
}

-- ====== [ DRAWING SUPPORT CHECK ] ======
local DrawingSupported = pcall(function() return Drawing.new("Square") end)
if not DrawingSupported then
    warn("[WormGPT-ESP] ❌ Executor นี้ไม่รองรับ Drawing library! กรุณาใช้ Krnl / Synapse / ScriptWare")
    return
end

-- ====== [ CORE FUNCTIONS ] ======
local function CreateESPElements(player)
    if player == LocalPlayer then return end
    if ESPCache[player] then return end
    
    local elements = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Tracers = Drawing.new("Line"),
        Distance = Drawing.new("Text"),
        Health = Drawing.new("Text"),
        HealthBar = Drawing.new("Square"),
    }
    
    elements.Box.Visible = false
    elements.Box.Color = BoxColor
    elements.Box.Thickness = BoxThickness
    elements.Box.Filled = false
    elements.Box.Transparency = 1 - Transparency
    
    elements.Name.Visible = false
    elements.Name.Center = true
    elements.Name.Size = 14
    elements.Name.Color = Color3.fromRGB(255, 255, 255)
    elements.Name.Font = Drawing.Fonts.Monospace
    elements.Name.Outline = true
    
    elements.Tracers.Visible = false
    elements.Tracers.Color = TracerColor
    elements.Tracers.Thickness = TracerThickness
    elements.Tracers.Transparency = 1 - Transparency
    
    elements.Distance.Visible = false
    elements.Distance.Size = 12
    elements.Distance.Center = true
    elements.Distance.Color = Color3.fromRGB(200, 200, 200)
    elements.Distance.Font = Drawing.Fonts.Monospace
    elements.Distance.Outline = true
    
    elements.Health.Visible = false
    elements.Health.Size = 12
    elements.Health.Center = true
    elements.Health.Color = Color3.fromRGB(100, 255, 100)
    elements.Health.Font = Drawing.Fonts.Monospace
    elements.Health.Outline = true
    
    elements.HealthBar.Visible = false
    elements.HealthBar.Filled = true
    elements.HealthBar.Color = Color3.fromRGB(100, 255, 100)
    elements.HealthBar.Thickness = 0
    elements.HealthBar.Transparency = 0.6
    
    ESPCache[player] = elements
end

local function RemoveESPElements(player)
    if ESPCache[player] then
        for _, element in pairs(ESPCache[player]) do
            element:Remove()
        end
        ESPCache[player] = nil
    end
end

local function GetColorFromName(name)
    if name == "Rainbow" then
        local t = tick() % 5 / 5
        return Color3.fromHSV(t, 1, 1)
    end
    return ColorOptions[name] or Color3.fromRGB(0, 210, 255)
end

local function UpdateESPVisibility(elements, state)
    if not elements then return end
    elements.Box.Visible = state and Settings.Box
    elements.Name.Visible = state and Settings.Name
    elements.Tracers.Visible = state and Settings.Tracers
    elements.Distance.Visible = state and Settings.Distance
    elements.Health.Visible = state and Settings.Health
    elements.HealthBar.Visible = state and Settings.Health
end

local function UpdateESP()
    if not ESPEnabled then
        for _, elements in pairs(ESPCache) do
            if elements then
                for _, el in pairs(elements) do
                    el.Visible = false
                end
            end
        end
        return
    end
    
    local currentBoxColor = GetColorFromName(SelectedBoxColor or "Cyan")
    local currentTracerColor = GetColorFromName(SelectedTracerColor or "Cyan")
    
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local elements = ESPCache[player]
        if not elements then continue end
        
        local character = player.Character
        if not character then
            UpdateESPVisibility(elements, false)
            continue
        end
        
        local root = character:FindFirstChild("HumanoidRootPart")
        local head = character:FindFirstChild("Head")
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        
        if not root or not head or not humanoid then
            UpdateESPVisibility(elements, false)
            continue
        end
        
        local rootPos, rootOnScreen = Camera:WorldToViewportPoint(root.Position)
        local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position)
        local dist = (root.Position - Camera.CFrame.Position).Magnitude
        
        if not rootOnScreen and not headOnScreen or dist > MaxDistance then
            UpdateESPVisibility(elements, false)
            continue
        end
        
        -- ====== CALCULATE BOX DIMENSIONS ======
        local boxHeight = math.abs(headPos.Y - rootPos.Y) * 1.25
        local boxWidth = boxHeight * 0.65
        local boxX = rootPos.X - boxWidth / 2
        local boxY = rootPos.Y - boxHeight / 2
        
        -- ====== UPDATE CORE COLORS ======
        local healthPercent = humanoid.Health / humanoid.MaxHealth
        local healthColor = Color3.fromRGB(
            math.floor(255 * (1 - healthPercent)),
            math.floor(255 * healthPercent),
            50
        )
        
        -- ====== BOX ESP ======
        elements.Box.Visible = Settings.Box
        elements.Box.Size = Vector2.new(boxWidth, boxHeight)
        elements.Box.Position = Vector2.new(boxX, boxY)
        elements.Box.Color = currentBoxColor
        elements.Box.Transparency = 1 - Transparency
        
        -- ====== NAME ESP ======
        elements.Name.Visible = Settings.Name
        elements.Name.Position = Vector2.new(rootPos.X, headPos.Y - boxHeight * 0.6)
        elements.Name.Text = player.DisplayName
        
        -- ====== TRACERS ======
        elements.Tracers.Visible = Settings.Tracers
        elements.Tracers.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        elements.Tracers.To = Vector2.new(rootPos.X, rootPos.Y)
        elements.Tracers.Color = currentTracerColor
        elements.Tracers.Transparency = 1 - Transparency
        
        -- ====== DISTANCE ======
        elements.Distance.Visible = Settings.Distance
        elements.Distance.Position = Vector2.new(rootPos.X, rootPos.Y + boxHeight / 2 + 2)
        elements.Distance.Text = string.format("[%.0fm]", dist)
        elements.Distance.Color = currentBoxColor
        
        -- ====== HEALTH ======
        elements.Health.Visible = Settings.Health
        elements.Health.Position = Vector2.new(rootPos.X, rootPos.Y + boxHeight / 2 + 16)
        elements.Health.Text = string.format("❤️ %.0f / %.0f", humanoid.Health, humanoid.MaxHealth)
        elements.Health.Color = healthColor
        
        -- ====== HEALTH BAR ======
        elements.HealthBar.Visible = Settings.Health
        elements.HealthBar.Size = Vector2.new(boxWidth * healthPercent, 3)
        elements.HealthBar.Position = Vector2.new(boxX, rootPos.Y + boxHeight / 2 + 30)
        elements.HealthBar.Color = healthColor
    end
end

-- ====== [ PLAYER TRACKING ] ======
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        CreateESPElements(player)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    RemoveESPElements(player)
end)

for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateESPElements(player)
        if player.Character then
            -- already have character
        end
        player.CharacterAdded:Connect(function()
            CreateESPElements(player)
        end)
    end
end

-- ====== [ GUI CREATION ] ======
local function CreateGUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "WormGPT_ESP"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Try to put in CoreGui (protected), fallback to player gui
    local success = pcall(function()
        ScreenGui.Parent = CoreGui
    end)
    if not success then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- ====== MAIN FRAME ======
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 340, 0, 440)
    MainFrame.Position = UDim2.new(0.5, -170, 0.5, -220)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
    MainFrame.BackgroundTransparency = 0.05
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui
    
    -- Border / Shadow
    local Border = Instance.new("Frame")
    Border.Size = UDim2.new(1, 2, 1, 2)
    Border.Position = UDim2.new(0, -1, 0, -1)
    Border.BackgroundColor3 = Color3.fromRGB(80, 40, 180)
    Border.BackgroundTransparency = 0.5
    Border.BorderSizePixel = 0
    Border.Parent = MainFrame
    
    -- UICorner
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 12)
    UICorner.Parent = MainFrame
    
    -- Gradient Background
    local UIGradient = Instance.new("UIGradient")
    UIGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 15, 40)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(12, 12, 35)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 8, 28)),
    })
    UIGradient.Parent = MainFrame
    
    -- ====== TITLE BAR ======
    local TitleFrame = Instance.new("Frame")
    TitleFrame.Size = UDim2.new(1, -20, 0, 40)
    TitleFrame.Position = UDim2.new(0, 10, 0, 8)
    TitleFrame.BackgroundTransparency = 1
    TitleFrame.Parent = MainFrame
    
    local TitleIcon = Instance.new("TextLabel")
    TitleIcon.Size = UDim2.new(0, 24, 0, 24)
    TitleIcon.Position = UDim2.new(0, 0, 0, 8)
    TitleIcon.BackgroundTransparency = 1
    TitleIcon.Text = "👁️"
    TitleIcon.Font = Enum.Font.GothamBold
    TitleIcon.TextSize = 18
    TitleIcon.Parent = TitleFrame
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(0, 200, 0, 30)
    TitleLabel.Position = UDim2.new(0, 30, 0, 5)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "WormESP • V1"
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 18
    TitleLabel.TextColor3 = Color3.fromRGB(180, 140, 255)
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TitleFrame
    
    -- Close Button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.new(0, 28, 0, 28)
    CloseButton.Position = UDim2.new(1, -34, 0, 6)
    CloseButton.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    CloseButton.BackgroundTransparency = 0.7
    CloseButton.Text = "✕"
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.TextSize = 16
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.Parent = TitleFrame
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 6)
    CloseCorner.Parent = CloseButton
    
    CloseButton.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        for _, elements in pairs(ESPCache) do
            if elements then
                for _, el in pairs(elements) do
                    el:Remove()
                end
            end
        end
        ESPCache = {}
        ESPEnabled = false
    end)
    
    -- ====== DIVIDER ======
    local Divider = Instance.new("Frame")
    Divider.Size = UDim2.new(1, -30, 0, 1)
    Divider.Position = UDim2.new(0, 15, 0, 52)
    Divider.BackgroundColor3 = Color3.fromRGB(80, 40, 180)
    Divider.BackgroundTransparency = 0.4
    Divider.BorderSizePixel = 0
    Divider.Parent = MainFrame
    
    local DividerGlow = Instance.new("Frame")
    DividerGlow.Size = UDim2.new(1, -60, 0, 3)
    DividerGlow.Position = UDim2.new(0, 30, 0, 50)
    DividerGlow.BackgroundColor3 = Color3.fromRGB(120, 60, 255)
    DividerGlow.BackgroundTransparency = 0.7
    DividerGlow.BorderSizePixel = 0
    DividerGlow.Parent = MainFrame
    
    -- ====== SCROLLING FRAME (FOR CONTENT) ======
    local ScrollingFrame = Instance.new("ScrollingFrame")
    ScrollingFrame.Size = UDim2.new(1, -20, 1, -75)
    ScrollingFrame.Position = UDim2.new(0, 10, 0, 58)
    ScrollingFrame.BackgroundTransparency = 1
    ScrollingFrame.ScrollBarThickness = 4
    ScrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(120, 60, 255)
    ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 500)
    ScrollingFrame.BorderSizePixel = 0
    ScrollingFrame.Parent = MainFrame
    
    -- ====== TOGGLE CREATION HELPER ======
    local function CreateToggle(parent, title, settingKey, yPos)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -10, 0, 32)
        row.Position = UDim2.new(0, 5, 0, yPos)
        row.BackgroundTransparency = 1
        row.Parent = parent
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0, 180, 1, 0)
        label.Position = UDim2.new(0, 8, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = title
        label.Font = Enum.Font.GothamSemibold
        label.TextSize = 14
        label.TextColor3 = Color3.fromRGB(220, 220, 240)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = row
        
        local toggleBg = Instance.new("Frame")
        toggleBg.Size = UDim2.new(0, 44, 0, 22)
        toggleBg.Position = UDim2.new(1, -52, 0, 5)
        toggleBg.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
        toggleBg.Parent = row
        
        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(1, 0)
        toggleCorner.Parent = toggleBg
        
        local toggleKnob = Instance.new("Frame")
        toggleKnob.Size = UDim2.new(0, 18, 0, 18)
        toggleKnob.Position = UDim2.new(0, 2, 0, 2)
        toggleKnob.BackgroundColor3 = Color3.fromRGB(200, 200, 220)
        toggleKnob.Parent = toggleBg
        
        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(1, 0)
        knobCorner.Parent = toggleKnob
        
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 1, 0)
        button.BackgroundTransparency = 1
        button.Text = ""
        button.Parent = row
        
        local isOn = Settings[settingKey]
        if isOn then
            toggleBg.BackgroundColor3 = Color3.fromRGB(60, 180, 100)
            toggleKnob.Position = UDim2.new(0, 24, 0, 2)
        end
        
        button.MouseButton1Click:Connect(function()
            Settings[settingKey] = not Settings[settingKey]
            isOn = Settings[settingKey]
            
            TweenService:Create(toggleBg, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = isOn and Color3.fromRGB(60, 180, 100) or Color3.fromRGB(60, 60, 80)
            }):Play()
            
            TweenService:Create(toggleKnob, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = isOn and UDim2.new(0, 24, 0, 2) or UDim2.new(0, 2, 0, 2)
            }):Play()
        end)
        
        return row
    end
    
    -- ====== ESP MAIN TOGGLE ======
    local espRow = Instance.new("Frame")
    espRow.Size = UDim2.new(1, -10, 0, 36)
    espRow.Position = UDim2.new(0, 5, 0, 5)
    espRow.BackgroundColor3 = Color3.fromRGB(30, 25, 55)
    espRow.BackgroundTransparency = 0.3
    espRow.Parent = ScrollingFrame
    
    local espRowCorner = Instance.new("UICorner")
    espRowCorner.CornerRadius = UDim.new(0, 8)
    espRowCorner.Parent = espRow
    
    local espLabel = Instance.new("TextLabel")
    espLabel.Size = UDim2.new(0, 180, 1, 0)
    espLabel.Position = UDim2.new(0, 12, 0, 0)
    espLabel.BackgroundTransparency = 1
    espLabel.Text = "⚡ ESP SYSTEM"
    espLabel.Font = Enum.Font.GothamBold
    espLabel.TextSize = 16
    espLabel.TextColor3 = Color3.fromRGB(200, 170, 255)
    espLabel.TextXAlignment = Enum.TextXAlignment.Left
    espLabel.Parent = espRow
    
    local espToggleBg = Instance.new("Frame")
    espToggleBg.Size = UDim2.new(0, 50, 0, 26)
    espToggleBg.Position = UDim2.new(1, -58, 0, 5)
    espToggleBg.BackgroundColor3 = Color3.fromRGB(60, 180, 100)
    espToggleBg.Parent = espRow
    
    local espToggleCorner = Instance.new("UICorner")
    espToggleCorner.CornerRadius = UDim.new(1, 0)
    espToggleCorner.Parent = espToggleBg
    
    local espToggleKnob = Instance.new("Frame")
    espToggleKnob.Size = UDim2.new(0, 22, 0, 22)
    espToggleKnob.Position = UDim2.new(0, 26, 0, 2)
    espToggleKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    espToggleKnob.Parent = espToggleBg
    
    local espKnobCorner = Instance.new("UICorner")
    espKnobCorner.CornerRadius = UDim.new(1, 0)
    espKnobCorner.Parent = espToggleKnob
    
    local espButton = Instance.new("TextButton")
    espButton.Size = UDim2.new(1, 0, 1, 0)
    espButton.BackgroundTransparency = 1
    espButton.Text = ""
    espButton.Parent = espRow
    
    espButton.MouseButton1Click:Connect(function()
        ESPEnabled = not ESPEnabled
        TweenService:Create(espToggleBg, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = ESPEnabled and Color3.fromRGB(60, 180, 100) or Color3.fromRGB(80, 40, 40)
        }):Play()
        TweenService:Create(espToggleKnob, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = ESPEnabled and UDim2.new(0, 26, 0, 2) or UDim2.new(0, 2, 0, 2)
        }):Play()
    end)
    
    -- ====== SETTINGS TOGGLES ======
    local toggleStartY = 48
    CreateToggle(ScrollingFrame, "📦 Box ESP", "Box", toggleStartY)
    CreateToggle(ScrollingFrame, "📛 Name ESP", "Name", toggleStartY + 36)
    CreateToggle(ScrollingFrame, "📍 Tracers", "Tracers", toggleStartY + 72)
    CreateToggle(ScrollingFrame, "📏 Distance", "Distance", toggleStartY + 108)
    CreateToggle(ScrollingFrame, "❤️ Health", "Health", toggleStartY + 144)
    
    -- ====== SECTION: SLIDERS ======
    local sliderLabel = Instance.new("TextLabel")
    sliderLabel.Size = UDim2.new(1, -20, 0, 20)
    sliderLabel.Position = UDim2.new(0, 10, 0, toggleStartY + 190)
    sliderLabel.BackgroundTransparency = 1
    sliderLabel.Text = "─────── 🎚️ SETTINGS ───────"
    sliderLabel.Font = Enum.Font.GothamSemibold
    sliderLabel.TextSize = 12
    sliderLabel.TextColor3 = Color3.fromRGB(160, 130, 220)
    sliderLabel.Parent = ScrollingFrame
    
    -- Max Distance Slider
    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(0, 200, 0, 18)
    distLabel.Position = UDim2.new(0, 10, 0, toggleStartY + 218)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = "🎯 Max Distance: " .. MaxDistance
    distLabel.Font = Enum.Font.GothamSemibold
    distLabel.TextSize = 13
    distLabel.TextColor3 = Color3.fromRGB(200, 200, 230)
    distLabel.TextXAlignment = Enum.TextXAlignment.Left
    distLabel.Parent = ScrollingFrame
    
    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -30, 0, 6)
    sliderBg.Position = UDim2.new(0, 15, 0, toggleStartY + 242)
    sliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    sliderBg.Parent = ScrollingFrame
    
    local sliderBgCorner = Instance.new("UICorner")
    sliderBgCorner.CornerRadius = UDim.new(1, 0)
    sliderBgCorner.Parent = sliderBg
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((MaxDistance - 50) / 950, 1, 0, 6)
    sliderFill.BackgroundColor3 = Color3.fromRGB(120, 60, 255)
    sliderFill.Parent = sliderBg
    
    local sliderFillCorner = Instance.new("UICorner")
    sliderFillCorner.CornerRadius = UDim.new(1, 0)
    sliderFillCorner.Parent = sliderFill
    
    local sliderKnob = Instance.new("Frame")
    sliderKnob.Size = UDim2.new(0, 16, 0, 16)
    sliderKnob.Position = UDim2.new((MaxDistance - 50) / 950, -8, 0, -5)
    sliderKnob.BackgroundColor3 = Color3.fromRGB(180, 150, 255)
    sliderKnob.Parent = sliderBg
    
    local sliderKnobCorner = Instance.new("UICorner")
    sliderKnobCorner.CornerRadius = UDim.new(1, 0)
    sliderKnobCorner.Parent = sliderKnob
    
    -- Slider drag logic
    local dragging = false
    sliderKnob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    sliderKnob.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mousePos = UserInputService:GetMouseLocation()
            local absX = sliderBg.AbsolutePosition.X
            local absW = sliderBg.AbsoluteSize.X
            local relX = math.clamp((mousePos.X - absX) / absW, 0, 1)
            MaxDistance = math.floor(50 + relX * 950)
            sliderFill.Size = UDim2.new(relX, 0, 1, 0)
            sliderKnob.Position = UDim2.new(relX, -8, 0, -5)
            distLabel.Text = "🎯 Max Distance: " .. MaxDistance
        end
    end)
    
    -- ====== COLOR DROPDOWNS ======
    local function CreateDropdown(parent, title, yPos, options, callback)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -10, 0, 28)
        row.Position = UDim2.new(0, 5, 0, yPos)
        row.BackgroundTransparency = 1
        row.Parent = parent
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0, 120, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = title
        label.Font = Enum.Font.GothamSemibold
        label.TextSize = 13
        label.TextColor3 = Color3.fromRGB(200, 200, 230)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = row
        
        local dropdownBtn = Instance.new("TextButton")
        dropdownBtn.Size = UDim2.new(0, 120, 0, 26)
        dropdownBtn.Position = UDim2.new(1, -128, 0, 1)
        dropdownBtn.BackgroundColor3 = Color3.fromRGB(30, 25, 55)
        dropdownBtn.Text = "Cyan"
        dropdownBtn.Font = Enum.Font.GothamSemibold
        dropdownBtn.TextSize = 13
        dropdownBtn.TextColor3 = Color3.fromRGB(0, 210, 255)
        dropdownBtn.Parent = row
        
        local dropdownCorner = Instance.new("UICorner")
        dropdownCorner.CornerRadius = UDim.new(0, 6)
        dropdownCorner.Parent = dropdownBtn
        
        -- Dropdown menu
        local dropdownMenu = Instance.new("Frame")
        dropdownMenu.Size = UDim2.new(0, 120, 0, #options * 24 + 4)
        dropdownMenu.Position = UDim2.new(0, 0, 0, 28)
        dropdownMenu.BackgroundColor3 = Color3.fromRGB(20, 18, 40)
        dropdownMenu.BackgroundTransparency = 0.1
        dropdownMenu.Visible = false
        dropdownMenu.Parent = row
        
        local menuCorner = Instance.new("UICorner")
        menuCorner.CornerRadius = UDim.new(0, 6)
        menuCorner.Parent = dropdownMenu
        
        for i, optName in ipairs(options) do
            local optBtn = Instance.new("TextButton")
            optBtn.Size = UDim2.new(1, -4, 0, 22)
            optBtn.Position = UDim2.new(0, 2, 0, 2 + (i - 1) * 24)
            optBtn.BackgroundTransparency = 0.8
            optBtn.Text = optName
            optBtn.Font = Enum.Font.GothamSemibold
            optBtn.TextSize = 12
            optBtn.TextColor3 = Color3.fromRGB(220, 220, 240)
            optBtn.Parent = dropdownMenu
            
            optBtn.MouseButton1Click:Connect(function()
                dropdownBtn.Text = optName
                dropdownMenu.Visible = false
                callback(optName)
            end)
        end
        
        dropdownBtn.MouseButton1Click:Connect(function()
            dropdownMenu.Visible = not dropdownMenu.Visible
        end)
        
        -- Close menu when clicking outside
        UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local mousePos = UserInputService:GetMouseLocation()
                local btnAbs = dropdownBtn.AbsolutePosition
                local btnSize = dropdownBtn.AbsoluteSize
                local menuAbs = dropdownMenu.AbsolutePosition
                local menuSize = dropdownMenu.AbsoluteSize
                
                if not (mousePos.X >= btnAbs.X and mousePos.X <= btnAbs.X + btnSize.X and
                       mousePos.Y >= btnAbs.Y and mousePos.Y <= btnAbs.Y + btnSize.Y) and
                   not (mousePos.X >= menuAbs.X and mousePos.X <= menuAbs.X + menuSize.X and
                       mousePos.Y >= menuAbs.Y and mousePos.Y <= menuAbs.Y + menuSize.Y) then
                    dropdownMenu.Visible = false
                end
            end
        end)
        
        return row
    end
    
    SelectedBoxColor = "Cyan"
    SelectedTracerColor = "Cyan"
    
    CreateDropdown(ScrollingFrame, "🎨 Box Color", toggleStartY + 256, ColorNames, function(name)
        SelectedBoxColor = name
        BoxColor = GetColorFromName(name)
    end)
    
    CreateDropdown(ScrollingFrame, "🎨 Tracer Color", toggleStartY + 288, ColorNames, function(name)
        SelectedTracerColor = name
        TracerColor = GetColorFromName(name)
    end)
    
    -- ====== BUTTONS ======
    local btnStartY = toggleStartY + 328
    
    local refreshBtn = Instance.new("TextButton")
    refreshBtn.Size = UDim2.new(0.5, -8, 0, 32)
    refreshBtn.Position = UDim2.new(0, 5, 0, btnStartY)
    refreshBtn.BackgroundColor3 = Color3.fromRGB(40, 35, 70)
    refreshBtn.Text = "🔄 Refresh Players"
    refreshBtn.Font = Enum.Font.GothamSemibold
    refreshBtn.TextSize = 13
    refreshBtn.TextColor3 = Color3.fromRGB(200, 200, 230)
    refreshBtn.Parent = ScrollingFrame
    
    local refreshCorner = Instance.new("UICorner")
    refreshCorner.CornerRadius = UDim.new(0, 8)
    refreshCorner.Parent = refreshBtn
    
    refreshBtn.MouseButton1Click:Connect(function()
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and not ESPCache[player] then
                CreateESPElements(player)
            end
        end
    end)
    
    local unloadBtn = Instance.new("TextButton")
    unloadBtn.Size = UDim2.new(0.5, -8, 0, 32)
    unloadBtn.Position = UDim2.new(0.5, 3, 0, btnStartY)
    unloadBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 30)
    unloadBtn.Text = "🚫 Unload ESP"
    unloadBtn.Font = Enum.Font.GothamSemibold
    unloadBtn.TextSize = 13
    unloadBtn.TextColor3 = Color3.fromRGB(230, 180, 180)
    unloadBtn.Parent = ScrollingFrame
    
    local unloadCorner = Instance.new("UICorner")
    unloadCorner.CornerRadius = UDim.new(0, 8)
    unloadCorner.Parent = unloadBtn
    
    unloadBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        for _, elements in pairs(ESPCache) do
            if elements then
                for _, el in pairs(elements) do
                    el:Remove()
                end
            end
        end
        ESPCache = {}
        ESPEnabled = false
    end)
    
    -- ====== FOOTER ======
    local footer = Instance.new("TextLabel")
    footer.Size = UDim2.new(1, -20, 0, 20)
    footer.Position = UDim2.new(0, 10, 1, -24)
    footer.BackgroundTransparency = 1
    footer.Text = "wormGPT • for QW 💜"
    footer.Font = Enum.Font.Gotham
    footer.TextSize = 11
    footer.TextColor3 = Color3.fromRGB(120, 100, 180)
    footer.Parent = ScrollingFrame
    
    -- ====== UPDATE CANVAS SIZE ======
    ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, btnStartY + 50)
end

-- ====== [ START GUI ] ======
CreateGUI()

-- ====== [ MAIN LOOP ] ======
RunService.RenderStepped:Connect(function()
    UpdateESP()
end)

-- ====== [ CLEANUP ON PLAYER LEFT ] ======
LocalPlayer.OnTeleport:Connect(function()
    for _, elements in pairs(ESPCache) do
        if elements then
            for _, el in pairs(elements) do
                el:Remove()
            end
        end
    end
    ESPCache = {}
end)

print("[WormGPT-ESP] ✅ โหลดสำเร็จ! for QW 💜")
