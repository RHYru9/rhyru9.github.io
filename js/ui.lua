-- RhyRu9 UI Library - Pure Standalone Edition

local RhyRu9 = {}
RhyRu9.Version = "1.0.0"
RhyRu9.Windows = {}
RhyRu9.Flags = {}
RhyRu9.Presets = {}
RhyRu9.Events = {}

-- Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

-- Theme System
RhyRu9.Themes = {
    Dark = {
        Background = Color3.fromRGB(25, 25, 25),
        Secondary = Color3.fromRGB(35, 35, 35),
        Tertiary = Color3.fromRGB(45, 45, 45),
        Text = Color3.fromRGB(255, 255, 255),
        TextDark = Color3.fromRGB(150, 150, 150),
        Accent = Color3.fromRGB(0, 120, 215),
        Border = Color3.fromRGB(60, 60, 60),
        Hover = Color3.fromRGB(50, 50, 50),
        Success = Color3.fromRGB(76, 175, 80),
        Warning = Color3.fromRGB(255, 152, 0),
        Error = Color3.fromRGB(244, 67, 54)
    },
    Light = {
        Background = Color3.fromRGB(240, 240, 240),
        Secondary = Color3.fromRGB(255, 255, 255),
        Tertiary = Color3.fromRGB(230, 230, 230),
        Text = Color3.fromRGB(0, 0, 0),
        TextDark = Color3.fromRGB(100, 100, 100),
        Accent = Color3.fromRGB(0, 120, 215),
        Border = Color3.fromRGB(200, 200, 200),
        Hover = Color3.fromRGB(245, 245, 245),
        Success = Color3.fromRGB(76, 175, 80),
        Warning = Color3.fromRGB(255, 152, 0),
        Error = Color3.fromRGB(244, 67, 54)
    }
}

RhyRu9.CurrentTheme = RhyRu9.Themes.Dark

-- Utility Functions
local Utility = {}

function Utility:Tween(object, properties, duration)
    local tweenInfo = TweenInfo.new(duration or 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(object, tweenInfo, properties)
    tween:Play()
    return tween
end

function Utility:Round(num)
    return math.floor(num + 0.5)
end

function Utility:CreateDrag(gui)
    local dragging
    local dragInput
    local dragStart
    local startPos

    local function update(input)
        local delta = input.Position - dragStart
        gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = gui.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    gui.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- Logger System
local Logger = {}

function Logger:Log(message, messageType)
    local timestamp = os.date("%H:%M:%S")
    local prefix = "[" .. timestamp .. "] "
    
    if messageType == "ERROR" then
        print(prefix .. "❌ [ERROR] " .. message)
    elseif messageType == "WARN" then
        print(prefix .. "⚠️ [WARN] " .. message)
    elseif messageType == "SUCCESS" then
        print(prefix .. "✅ [SUCCESS] " .. message)
    else
        print(prefix .. "ℹ️ [INFO] " .. message)
    end
end

function Logger:Error(message)
    self:Log(message, "ERROR")
end

function Logger:Warn(message)
    self:Log(message, "WARN")
end

function Logger:Success(message)
    self:Log(message, "SUCCESS")
end

function Logger:Info(message)
    self:Log(message, "INFO")
end

-- Event System
local EventSystem = {}

function EventSystem:Create(eventName)
    if not RhyRu9.Events[eventName] then
        RhyRu9.Events[eventName] = {
            Callbacks = {},
            Fired = 0
        }
    end
    return RhyRu9.Events[eventName]
end

function EventSystem:Connect(eventName, callback)
    local event = self:Create(eventName)
    local connectionId = #event.Callbacks + 1
    event.Callbacks[connectionId] = callback
    
    return {
        Disconnect = function()
            event.Callbacks[connectionId] = nil
        end
    }
end

function EventSystem:Fire(eventName, ...)
    local event = RhyRu9.Events[eventName]
    if event then
        event.Fired = event.Fired + 1
        for _, callback in pairs(event.Callbacks) do
            task.spawn(callback, ...)
        end
    end
end

-- Component System
local Components = {}

function Components:CreateMain()
    local theme = RhyRu9.CurrentTheme
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "RhyRu9UI"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = game:GetService("CoreGui") or game.Players.LocalPlayer:WaitForChild("PlayerGui")
    
    return ScreenGui
end

function Components:CreateWindow(parent, title)
    local theme = RhyRu9.CurrentTheme
    
    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Size = UDim2.new(0, 550, 0, 400)
    Main.Position = UDim2.new(0.5, -275, 0.5, -200)
    Main.BackgroundColor3 = theme.Background
    Main.BorderSizePixel = 0
    Main.Parent = parent
    
    Utility:CreateDrag(Main)
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 8)
    MainCorner.Parent = Main
    
    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = theme.Border
    MainStroke.Thickness = 1
    MainStroke.Parent = Main
    
    -- Topbar
    local Topbar = Instance.new("Frame")
    Topbar.Name = "Topbar"
    Topbar.Size = UDim2.new(1, 0, 0, 40)
    Topbar.BackgroundColor3 = theme.Secondary
    Topbar.BorderSizePixel = 0
    Topbar.Parent = Main
    
    local TopbarCorner = Instance.new("UICorner")
    TopbarCorner.CornerRadius = UDim.new(0, 8)
    TopbarCorner.Parent = Topbar
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(0.7, 0, 1, 0)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = title or "RhyRu9 UI"
    Title.TextColor3 = theme.Text
    Title.TextSize = 16
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Topbar
    
    -- Close Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "CloseBtn"
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -35, 0.5, -15)
    CloseBtn.BackgroundColor3 = theme.Error
    CloseBtn.Text = "×"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.TextSize = 18
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Parent = Topbar
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 6)
    CloseCorner.Parent = CloseBtn
    
    -- Minimize Button
    local MinimizeBtn = Instance.new("TextButton")
    MinimizeBtn.Name = "MinimizeBtn"
    MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
    MinimizeBtn.Position = UDim2.new(1, -70, 0.5, -15)
    MinimizeBtn.BackgroundColor3 = theme.Warning
    MinimizeBtn.Text = "−"
    MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinimizeBtn.TextSize = 18
    MinimizeBtn.Font = Enum.Font.GothamBold
    MinimizeBtn.BorderSizePixel = 0
    MinimizeBtn.Parent = Topbar
    
    local MinimizeCorner = Instance.new("UICorner")
    MinimizeCorner.CornerRadius = UDim.new(0, 6)
    MinimizeCorner.Parent = MinimizeBtn
    
    -- Content Area
    local ContentArea = Instance.new("Frame")
    ContentArea.Name = "ContentArea"
    ContentArea.Size = UDim2.new(1, -20, 1, -60)
    ContentArea.Position = UDim2.new(0, 10, 0, 50)
    ContentArea.BackgroundTransparency = 1
    ContentArea.BorderSizePixel = 0
    ContentArea.Parent = Main
    
    -- Tab List Container
    local TabListContainer = Instance.new("Frame")
    TabListContainer.Name = "TabListContainer"
    TabListContainer.Size = UDim2.new(0, 150, 1, 0)
    TabListContainer.BackgroundTransparency = 1
    TabListContainer.BorderSizePixel = 0
    TabListContainer.Parent = ContentArea
    
    local TabList = Instance.new("ScrollingFrame")
    TabList.Name = "TabList"
    TabList.Size = UDim2.new(1, 0, 1, 0)
    TabList.BackgroundTransparency = 1
    TabList.BorderSizePixel = 0
    TabList.ScrollBarThickness = 4
    TabList.ScrollBarImageColor3 = theme.Accent
    TabList.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabList.Parent = TabListContainer
    
    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Padding = UDim.new(0, 5)
    TabListLayout.Parent = TabList
    
    local TabListPadding = Instance.new("UIPadding")
    TabListPadding.PaddingTop = UDim.new(0, 5)
    TabListPadding.PaddingLeft = UDim.new(0, 5)
    TabListPadding.Parent = TabList
    
    -- Content Container
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Size = UDim2.new(1, -160, 1, 0)
    ContentContainer.Position = UDim2.new(0, 160, 0, 0)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.BorderSizePixel = 0
    ContentContainer.Parent = ContentArea
    
    TabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabList.CanvasSize = UDim2.new(0, 0, 0, TabListLayout.AbsoluteContentSize.Y + 10)
    end)
    
    return {
        Main = Main,
        Topbar = Topbar,
        Title = Title,
        CloseBtn = CloseBtn,
        MinimizeBtn = MinimizeBtn,
        TabList = TabList,
        ContentContainer = ContentContainer
    }
end

function Components:CreateTab(parent, name)
    local theme = RhyRu9.CurrentTheme
    
    local Tab = Instance.new("TextButton")
    Tab.Name = name
    Tab.Size = UDim2.new(1, -10, 0, 35)
    Tab.BackgroundColor3 = theme.Tertiary
    Tab.Text = ""
    Tab.AutoButtonColor = false
    Tab.BorderSizePixel = 0
    Tab.Parent = parent
    
    local TabCorner = Instance.new("UICorner")
    TabCorner.CornerRadius = UDim.new(0, 6)
    TabCorner.Parent = Tab
    
    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.Size = UDim2.new(1, -10, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = theme.TextDark
    Label.TextSize = 14
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Tab
    
    Tab.MouseEnter:Connect(function()
        if not Tab:GetAttribute("Selected") then
            Utility:Tween(Tab, {BackgroundColor3 = theme.Hover})
        end
    end)
    
    Tab.MouseLeave:Connect(function()
        if not Tab:GetAttribute("Selected") then
            Utility:Tween(Tab, {BackgroundColor3 = theme.Tertiary})
        end
    end)
    
    return Tab
end

function Components:CreateTabContent(parent, name)
    local theme = RhyRu9.CurrentTheme
    
    local TabContent = Instance.new("ScrollingFrame")
    TabContent.Name = name
    TabContent.Size = UDim2.new(1, 0, 1, 0)
    TabContent.BackgroundTransparency = 1
    TabContent.BorderSizePixel = 0
    TabContent.ScrollBarThickness = 4
    TabContent.ScrollBarImageColor3 = theme.Accent
    TabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabContent.Visible = false
    TabContent.Parent = parent
    
    local Layout = Instance.new("UIListLayout")
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Padding = UDim.new(0, 10)
    Layout.Parent = TabContent
    
    local Padding = Instance.new("UIPadding")
    Padding.PaddingTop = UDim.new(0, 5)
    Padding.PaddingLeft = UDim.new(0, 5)
    Padding.PaddingRight = UDim.new(0, 5)
    Padding.Parent = TabContent
    
    Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabContent.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 10)
    end)
    
    return TabContent
end

function Components:CreateSection(parent, title)
    local theme = RhyRu9.CurrentTheme
    
    local Section = Instance.new("Frame")
    Section.Name = title
    Section.Size = UDim2.new(1, -10, 0, 40)
    Section.BackgroundColor3 = theme.Secondary
    Section.BorderSizePixel = 0
    Section.Parent = parent
    
    local SectionCorner = Instance.new("UICorner")
    SectionCorner.CornerRadius = UDim.new(0, 6)
    SectionCorner.Parent = Section
    
    local SectionStroke = Instance.new("UIStroke")
    SectionStroke.Color = theme.Border
    SectionStroke.Thickness = 1
    SectionStroke.Parent = Section
    
    local SectionLabel = Instance.new("TextLabel")
    SectionLabel.Name = "Label"
    SectionLabel.Size = UDim2.new(1, -20, 1, 0)
    SectionLabel.Position = UDim2.new(0, 10, 0, 0)
    SectionLabel.BackgroundTransparency = 1
    SectionLabel.Text = title
    SectionLabel.TextColor3 = theme.Text
    SectionLabel.TextSize = 14
    SectionLabel.Font = Enum.Font.GothamBold
    SectionLabel.TextXAlignment = Enum.TextXAlignment.Left
    SectionLabel.Parent = Section
    
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "Content"
    ContentContainer.Size = UDim2.new(1, 0, 0, 0)
    ContentContainer.Position = UDim2.new(0, 0, 1, 5)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.BorderSizePixel = 0
    ContentContainer.Parent = Section
    
    local ContentLayout = Instance.new("UIListLayout")
    ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ContentLayout.Padding = UDim.new(0, 5)
    ContentLayout.Parent = ContentContainer
    
    ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ContentContainer.Size = UDim2.new(1, 0, 0, ContentLayout.AbsoluteContentSize.Y)
        Section.Size = UDim2.new(1, -10, 0, 40 + ContentLayout.AbsoluteContentSize.Y + 5)
    end)
    
    return ContentContainer
end

function Components:CreateButton(parent, config)
    local theme = RhyRu9.CurrentTheme
    
    local Button = Instance.new("TextButton")
    Button.Name = config.Name
    Button.Size = UDim2.new(1, 0, 0, 35)
    Button.BackgroundColor3 = theme.Accent
    Button.Text = ""
    Button.AutoButtonColor = false
    Button.BorderSizePixel = 0
    Button.Parent = parent
    
    local ButtonCorner = Instance.new("UICorner")
    ButtonCorner.CornerRadius = UDim.new(0, 6)
    ButtonCorner.Parent = Button
    
    local ButtonLabel = Instance.new("TextLabel")
    ButtonLabel.Name = "Label"
    ButtonLabel.Size = UDim2.new(1, 0, 1, 0)
    ButtonLabel.BackgroundTransparency = 1
    ButtonLabel.Text = config.Name
    ButtonLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    ButtonLabel.TextSize = 14
    ButtonLabel.Font = Enum.Font.Gotham
    ButtonLabel.Parent = Button
    
    Button.MouseEnter:Connect(function()
        Utility:Tween(Button, {BackgroundColor3 = theme.Accent:Lerp(Color3.fromRGB(255, 255, 255), 0.2)})
    end)
    
    Button.MouseLeave:Connect(function()
        Utility:Tween(Button, {BackgroundColor3 = theme.Accent})
    end)
    
    Button.MouseButton1Down:Connect(function()
        Utility:Tween(Button, {Size = UDim2.new(1, -2, 0, 33)}, 0.1)
    end)
    
    Button.MouseButton1Up:Connect(function()
        Utility:Tween(Button, {Size = UDim2.new(1, 0, 0, 35)}, 0.1)
    end)
    
    Button.MouseButton1Click:Connect(function()
        if config.Callback then
            task.spawn(config.Callback)
        end
        
        EventSystem:Fire("ButtonClicked", config.Name)
    end)
    
    return {
        Frame = Button,
        Fire = function() 
            if config.Callback then
                task.spawn(config.Callback)
            end
        end
    }
end

function Components:CreateToggle(parent, config)
    local theme = RhyRu9.CurrentTheme
    
    local Toggle = Instance.new("Frame")
    Toggle.Name = config.Name
    Toggle.Size = UDim2.new(1, 0, 0, 35)
    Toggle.BackgroundColor3 = theme.Secondary
    Toggle.BorderSizePixel = 0
    Toggle.Parent = parent
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 6)
    ToggleCorner.Parent = Toggle
    
    local ToggleStroke = Instance.new("UIStroke")
    ToggleStroke.Color = theme.Border
    ToggleStroke.Thickness = 1
    ToggleStroke.Parent = Toggle
    
    local ToggleLabel = Instance.new("TextLabel")
    ToggleLabel.Name = "Label"
    ToggleLabel.Size = UDim2.new(0.7, 0, 1, 0)
    ToggleLabel.Position = UDim2.new(0, 10, 0, 0)
    ToggleLabel.BackgroundTransparency = 1
    ToggleLabel.Text = config.Name
    ToggleLabel.TextColor3 = theme.Text
    ToggleLabel.TextSize = 14
    ToggleLabel.Font = Enum.Font.Gotham
    ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    ToggleLabel.Parent = Toggle
    
    -- Toggle Switch
    local ToggleSwitch = Instance.new("TextButton")
    ToggleSwitch.Name = "Switch"
    ToggleSwitch.Size = UDim2.new(0, 40, 0, 20)
    ToggleSwitch.Position = UDim2.new(1, -50, 0.5, -10)
    ToggleSwitch.BackgroundColor3 = theme.Tertiary
    ToggleSwitch.Text = ""
    ToggleSwitch.AutoButtonColor = false
    ToggleSwitch.BorderSizePixel = 0
    ToggleSwitch.Parent = Toggle
    
    local SwitchCorner = Instance.new("UICorner")
    SwitchCorner.CornerRadius = UDim.new(1, 0)
    SwitchCorner.Parent = ToggleSwitch
    
    local ToggleThumb = Instance.new("Frame")
    ToggleThumb.Name = "Thumb"
    ToggleThumb.Size = UDim2.new(0, 16, 0, 16)
    ToggleThumb.Position = UDim2.new(0, 2, 0.5, -8)
    ToggleThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ToggleThumb.BorderSizePixel = 0
    ToggleThumb.Parent = ToggleSwitch
    
    local ThumbCorner = Instance.new("UICorner")
    ThumbCorner.CornerRadius = UDim.new(1, 0)
    ThumbCorner.Parent = ToggleThumb
    
    local State = config.Default or false
    
    local function UpdateToggle()
        if State then
            Utility:Tween(ToggleSwitch, {BackgroundColor3 = theme.Accent}, 0.2)
            Utility:Tween(ToggleThumb, {Position = UDim2.new(1, -18, 0.5, -8)}, 0.2)
        else
            Utility:Tween(ToggleSwitch, {BackgroundColor3 = theme.Tertiary}, 0.2)
            Utility:Tween(ToggleThumb, {Position = UDim2.new(0, 2, 0.5, -8)}, 0.2)
        end
    end
    
    ToggleSwitch.MouseButton1Click:Connect(function()
        State = not State
        UpdateToggle()
        
        if config.Callback then
            task.spawn(config.Callback, State)
        end
        
        EventSystem:Fire("ToggleChanged", config.Name, State)
    end)
    
    -- Initial state
    UpdateToggle()
    
    return {
        Frame = Toggle,
        Set = function(value)
            State = value
            UpdateToggle()
        end,
        GetValue = function() return State end,
        Toggle = function() 
            State = not State
            UpdateToggle()
            if config.Callback then
                task.spawn(config.Callback, State)
            end
        end
    }
end

function Components:CreateSlider(parent, config)
    local theme = RhyRu9.CurrentTheme
    
    local Slider = Instance.new("Frame")
    Slider.Name = config.Name
    Slider.Size = UDim2.new(1, 0, 0, 60)
    Slider.BackgroundColor3 = theme.Secondary
    Slider.BorderSizePixel = 0
    Slider.Parent = parent
    
    local SliderCorner = Instance.new("UICorner")
    SliderCorner.CornerRadius = UDim.new(0, 6)
    SliderCorner.Parent = Slider
    
    local SliderStroke = Instance.new("UIStroke")
    SliderStroke.Color = theme.Border
    SliderStroke.Thickness = 1
    SliderStroke.Parent = Slider
    
    -- Slider Label
    local SliderLabel = Instance.new("TextLabel")
    SliderLabel.Name = "Label"
    SliderLabel.Size = UDim2.new(0.6, 0, 0, 20)
    SliderLabel.Position = UDim2.new(0, 10, 0, 5)
    SliderLabel.BackgroundTransparency = 1
    SliderLabel.Text = config.Name
    SliderLabel.TextColor3 = theme.Text
    SliderLabel.TextSize = 14
    SliderLabel.Font = Enum.Font.Gotham
    SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
    SliderLabel.Parent = Slider
    
    -- Value Label
    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Name = "Value"
    ValueLabel.Size = UDim2.new(0.35, 0, 0, 20)
    ValueLabel.Position = UDim2.new(0.6, 0, 0, 5)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Text = "0"
    ValueLabel.TextColor3 = theme.Text
    ValueLabel.TextSize = 14
    ValueLabel.Font = Enum.Font.Gotham
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValueLabel.Parent = Slider
    
    -- Slider Track
    local SliderTrack = Instance.new("Frame")
    SliderTrack.Name = "Track"
    SliderTrack.Size = UDim2.new(1, -20, 0, 6)
    SliderTrack.Position = UDim2.new(0, 10, 1, -20)
    SliderTrack.BackgroundColor3 = theme.Tertiary
    SliderTrack.BorderSizePixel = 0
    SliderTrack.Parent = Slider
    
    local TrackCorner = Instance.new("UICorner")
    TrackCorner.CornerRadius = UDim.new(1, 0)
    TrackCorner.Parent = SliderTrack
    
    -- Slider Fill
    local SliderFill = Instance.new("Frame")
    SliderFill.Name = "Fill"
    SliderFill.Size = UDim2.new(0, 0, 1, 0)
    SliderFill.BackgroundColor3 = theme.Accent
    SliderFill.BorderSizePixel = 0
    SliderFill.Parent = SliderTrack
    
    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(1, 0)
    FillCorner.Parent = SliderFill
    
    -- Slider Thumb
    local SliderThumb = Instance.new("Frame")
    SliderThumb.Name = "Thumb"
    SliderThumb.Size = UDim2.new(0, 16, 0, 16)
    SliderThumb.Position = UDim2.new(0, -8, 0.5, -8)
    SliderThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SliderThumb.BorderSizePixel = 0
    SliderThumb.Parent = SliderFill
    
    local ThumbCorner = Instance.new("UICorner")
    ThumbCorner.CornerRadius = UDim.new(1, 0)
    ThumbCorner.Parent = SliderThumb
    
    local ThumbStroke = Instance.new("UIStroke")
    ThumbStroke.Color = theme.Accent
    ThumbStroke.Thickness = 2
    ThumbStroke.Parent = SliderThumb
    
    -- Values
    local Min = config.Min or 0
    local Max = config.Max or 100
    local Increment = config.Increment or 1
    local Value = config.Default or Min
    local Suffix = config.Suffix or ""
    
    local Dragging = false
    
    local function UpdateSlider(newValue)
        newValue = math.clamp(newValue, Min, Max)
        newValue = Utility:Round(newValue / Increment) * Increment
        Value = newValue
        
        local Percent = (Value - Min) / (Max - Min)
        
        Utility:Tween(SliderFill, {Size = UDim2.new(Percent, 0, 1, 0)}, 0.1)
        ValueLabel.Text = tostring(Value) .. Suffix
        
        if config.Callback then
            task.spawn(config.Callback, Value)
        end
        
        EventSystem:Fire("SliderChanged", config.Name, Value)
    end
    
    -- Initial Update
    UpdateSlider(Value)
    
    -- Input Handling
    local function HandleInput(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Dragging = true
            Utility:Tween(SliderThumb, {Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(0, -10, 0.5, -10)}, 0.1)
        end
    end
    
    SliderTrack.InputBegan:Connect(HandleInput)
    SliderThumb.InputBegan:Connect(HandleInput)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Dragging = false
            Utility:Tween(SliderThumb, {Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(0, -8, 0.5, -8)}, 0.1)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local Mouse = UserInputService:GetMouseLocation()
            local RelativeX = math.clamp(Mouse.X - SliderTrack.AbsolutePosition.X, 0, SliderTrack.AbsoluteSize.X)
            local Percent = RelativeX / SliderTrack.AbsoluteSize.X
            local NewValue = Min + (Max - Min) * Percent
            UpdateSlider(NewValue)
        end
    end)
    
    return {
        Frame = Slider,
        Set = UpdateSlider,
        GetValue = function() return Value end
    }
end

function Components:CreateInput(parent, config)
    local theme = RhyRu9.CurrentTheme
    
    local Input = Instance.new("Frame")
    Input.Name = config.Name
    Input.Size = UDim2.new(1, 0, 0, 40)
    Input.BackgroundColor3 = theme.Secondary
    Input.BorderSizePixel = 0
    Input.Parent = parent
    
    local InputCorner = Instance.new("UICorner")
    InputCorner.CornerRadius = UDim.new(0, 6)
    InputCorner.Parent = Input
    
    local InputStroke = Instance.new("UIStroke")
    InputStroke.Color = theme.Border
    InputStroke.Thickness = 1
    InputStroke.Parent = Input
    
    local InputLabel = Instance.new("TextLabel")
    InputLabel.Name = "Label"
    InputLabel.Size = UDim2.new(0.4, 0, 1, 0)
    InputLabel.Position = UDim2.new(0, 10, 0, 0)
    InputLabel.BackgroundTransparency = 1
    InputLabel.Text = config.Name
    InputLabel.TextColor3 = theme.Text
    InputLabel.TextSize = 14
    InputLabel.Font = Enum.Font.Gotham
    InputLabel.TextXAlignment = Enum.TextXAlignment.Left
    InputLabel.Parent = Input
    
    -- Input Box Container
    local InputBoxContainer = Instance.new("Frame")
    InputBoxContainer.Name = "InputContainer"
    InputBoxContainer.Size = UDim2.new(0.55, 0, 0, 30)
    InputBoxContainer.Position = UDim2.new(0.43, 0, 0.5, -15)
    InputBoxContainer.BackgroundColor3 = theme.Tertiary
    InputBoxContainer.BorderSizePixel = 0
    InputBoxContainer.Parent = Input
    
    local InputBoxCorner = Instance.new("UICorner")
    InputBoxCorner.CornerRadius = UDim.new(0, 6)
    InputBoxCorner.Parent = InputBoxContainer
    
    local InputBox = Instance.new("TextBox")
    InputBox.Name = "Box"
    InputBox.Size = UDim2.new(1, -10, 1, 0)
    InputBox.Position = UDim2.new(0, 5, 0, 0)
    InputBox.BackgroundTransparency = 1
    InputBox.Text = config.Default or ""
    InputBox.PlaceholderText = config.Placeholder or "Enter text..."
    InputBox.TextColor3 = theme.Text
    InputBox.PlaceholderColor3 = theme.TextDark
    InputBox.TextSize = 13
    InputBox.Font = Enum.Font.Gotham
    InputBox.TextXAlignment = Enum.TextXAlignment.Left
    InputBox.ClearTextOnFocus = false
    InputBox.Parent = InputBoxContainer
    
    -- Focus Effects
    InputBox.Focused:Connect(function()
        Utility:Tween(InputStroke, {Color = theme.Accent, Thickness = 2})
        Utility:Tween(InputBoxContainer, {BackgroundColor3 = theme.Background})
    end)
    
    InputBox.FocusLost:Connect(function(enterPressed)
        Utility:Tween(InputStroke, {Color = theme.Border, Thickness = 1})
        Utility:Tween(InputBoxContainer, {BackgroundColor3 = theme.Tertiary})
        
        if config.Callback then
            task.spawn(config.Callback, InputBox.Text)
        end
        
        EventSystem:Fire("InputChanged", config.Name, InputBox.Text)
    end)
    
    return {
        Frame = Input,
        Set = function(text) InputBox.Text = text end,
        GetValue = function() return InputBox.Text end
    }
end

function Components:CreateDropdown(parent, config)
    local theme = RhyRu9.CurrentTheme
    
    local Dropdown = Instance.new("Frame")
    Dropdown.Name = config.Name
    Dropdown.Size = UDim2.new(1, 0, 0, 40)
    Dropdown.BackgroundColor3 = theme.Secondary
    Dropdown.BorderSizePixel = 0
    Dropdown.ClipsDescendants = false
    Dropdown.Parent = parent
    
    local DropdownCorner = Instance.new("UICorner")
    DropdownCorner.CornerRadius = UDim.new(0, 6)
    DropdownCorner.Parent = Dropdown
    
    local DropdownStroke = Instance.new("UIStroke")
    DropdownStroke.Color = theme.Border
    DropdownStroke.Thickness = 1
    DropdownStroke.Parent = Dropdown
    
    local DropdownLabel = Instance.new("TextLabel")
    DropdownLabel.Name = "Label"
    DropdownLabel.Size = UDim2.new(0.4, 0, 0, 40)
    DropdownLabel.Position = UDim2.new(0, 10, 0, 0)
    DropdownLabel.BackgroundTransparency = 1
    DropdownLabel.Text = config.Name
    DropdownLabel.TextColor3 = theme.Text
    DropdownLabel.TextSize = 14
    DropdownLabel.Font = Enum.Font.Gotham
    DropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
    DropdownLabel.Parent = Dropdown
    
    -- Selected Display
    local SelectedButton = Instance.new("TextButton")
    SelectedButton.Name = "Selected"
    SelectedButton.Size = UDim2.new(0.55, 0, 0, 30)
    SelectedButton.Position = UDim2.new(0.43, 0, 0, 5)
    SelectedButton.BackgroundColor3 = theme.Tertiary
    SelectedButton.Text = ""
    SelectedButton.AutoButtonColor = false
    SelectedButton.BorderSizePixel = 0
    SelectedButton.Parent = Dropdown
    
    local SelectedCorner = Instance.new("UICorner")
    SelectedCorner.CornerRadius = UDim.new(0, 6)
    SelectedCorner.Parent = SelectedButton
    
    local SelectedText = Instance.new("TextLabel")
    SelectedText.Name = "Text"
    SelectedText.Size = UDim2.new(1, -30, 1, 0)
    SelectedText.Position = UDim2.new(0, 10, 0, 0)
    SelectedText.BackgroundTransparency = 1
    SelectedText.Text = config.Default or "Select..."
    SelectedText.TextColor3 = theme.Text
    SelectedText.TextSize = 13
    SelectedText.Font = Enum.Font.Gotham
    SelectedText.TextXAlignment = Enum.TextXAlignment.Left
    SelectedText.Parent = SelectedButton
    
    -- Arrow Icon
    local Arrow = Instance.new("TextLabel")
    Arrow.Name = "Arrow"
    Arrow.Size = UDim2.new(0, 20, 1, 0)
    Arrow.Position = UDim2.new(1, -25, 0, 0)
    Arrow.BackgroundTransparency = 1
    Arrow.Text = "▼"
    Arrow.TextColor3 = theme.TextDark
    Arrow.TextSize = 12
    Arrow.Font = Enum.Font.Gotham
    Arrow.Parent = SelectedButton
    
    -- Options Container
    local OptionsContainer = Instance.new("Frame")
    OptionsContainer.Name = "Options"
    OptionsContainer.Size = UDim2.new(0.55, 0, 0, 0)
    OptionsContainer.Position = UDim2.new(0.43, 0, 0, 40)
    OptionsContainer.BackgroundColor3 = theme.Tertiary
    OptionsContainer.BorderSizePixel = 0
    OptionsContainer.ClipsDescendants = true
    OptionsContainer.Visible = false
    OptionsContainer.ZIndex = 10
    OptionsContainer.Parent = Dropdown
    
    local OptionsCorner = Instance.new("UICorner")
    OptionsCorner.CornerRadius = UDim.new(0, 6)
    OptionsCorner.Parent = OptionsContainer
    
    local OptionsList = Instance.new("ScrollingFrame")
    OptionsList.Name = "List"
    OptionsList.Size = UDim2.new(1, 0, 1, 0)
    OptionsList.BackgroundTransparency = 1
    OptionsList.BorderSizePixel = 0
    OptionsList.ScrollBarThickness = 4
    OptionsList.ScrollBarImageColor3 = theme.Accent
    OptionsList.CanvasSize = UDim2.new(0, 0, 0, 0)
    OptionsList.Parent = OptionsContainer
    
    local OptionsLayout = Instance.new("UIListLayout")
    OptionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    OptionsLayout.Padding = UDim.new(0, 2)
    OptionsLayout.Parent = OptionsList
    
    local OptionsPadding = Instance.new("UIPadding")
    OptionsPadding.PaddingTop = UDim.new(0, 5)
    OptionsPadding.PaddingBottom = UDim.new(0, 5)
    OptionsPadding.PaddingLeft = UDim.new(0, 5)
    OptionsPadding.PaddingRight = UDim.new(0, 5)
    OptionsPadding.Parent = OptionsList
    
    local IsOpen = false
    local CurrentValue = config.Default
    
    -- Create Options
    for _, option in ipairs(config.Options or {}) do
        local OptionButton = Instance.new("TextButton")
        OptionButton.Name = option
        OptionButton.Size = UDim2.new(1, -10, 0, 30)
        OptionButton.BackgroundColor3 = theme.Secondary
        OptionButton.Text = ""
        OptionButton.AutoButtonColor = false
        OptionButton.BorderSizePixel = 0
        OptionButton.Parent = OptionsList
        
        local OptionCorner = Instance.new("UICorner")
        OptionCorner.CornerRadius = UDim.new(0, 4)
        OptionCorner.Parent = OptionButton
        
        local OptionLabel = Instance.new("TextLabel")
        OptionLabel.Size = UDim2.new(1, -10, 1, 0)
        OptionLabel.Position = UDim2.new(0, 10, 0, 0)
        OptionLabel.BackgroundTransparency = 1
        OptionLabel.Text = option
        OptionLabel.TextColor3 = theme.Text
        OptionLabel.TextSize = 13
        OptionLabel.Font = Enum.Font.Gotham
        OptionLabel.TextXAlignment = Enum.TextXAlignment.Left
        OptionLabel.Parent = OptionButton
        
        OptionButton.MouseEnter:Connect(function()
            Utility:Tween(OptionButton, {BackgroundColor3 = theme.Hover})
        end)
        
        OptionButton.MouseLeave:Connect(function()
            Utility:Tween(OptionButton, {BackgroundColor3 = theme.Secondary})
        end)
        
        OptionButton.MouseButton1Click:Connect(function()
            CurrentValue = option
            SelectedText.Text = option
            
            -- Close dropdown
            IsOpen = false
            Utility:Tween(Arrow, {Rotation = 0}, 0.2)
            Utility:Tween(OptionsContainer, {Size = UDim2.new(0.55, 0, 0, 0)}, 0.2)
            task.wait(0.2)
            OptionsContainer.Visible = false
            
            if config.Callback then
                task.spawn(config.Callback, option)
            end
            
            EventSystem:Fire("DropdownChanged", config.Name, option)
        end)
    end
    
    OptionsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        OptionsList.CanvasSize = UDim2.new(0, 0, 0, OptionsLayout.AbsoluteContentSize.Y + 10)
    end)
    
    -- Toggle Dropdown
    SelectedButton.MouseButton1Click:Connect(function()
        IsOpen = not IsOpen
        
        if IsOpen then
            OptionsContainer.Visible = true
            local contentHeight = math.min(OptionsLayout.AbsoluteContentSize.Y + 10, 150)
            Utility:Tween(Arrow, {Rotation = 180}, 0.2)
            Utility:Tween(OptionsContainer, {Size = UDim2.new(0.55, 0, 0, contentHeight)}, 0.2)
            Utility:Tween(Dropdown, {Size = UDim2.new(1, 0, 0, 40 + contentHeight + 5)}, 0.2)
        else
            Utility:Tween(Arrow, {Rotation = 0}, 0.2)
            Utility:Tween(OptionsContainer, {Size = UDim2.new(0.55, 0, 0, 0)}, 0.2)
            Utility:Tween(Dropdown, {Size = UDim2.new(1, 0, 0, 40)}, 0.2)
            task.wait(0.2)
            OptionsContainer.Visible = false
        end
    end)
    
    return {
        Frame = Dropdown,
        Set = function(value)
            CurrentValue = value
            SelectedText.Text = value
        end,
        GetValue = function() return CurrentValue end,
        Refresh = function(newOptions)
            for _, child in ipairs(OptionsList:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end
            
            for _, option in ipairs(newOptions) do
                -- Recreate options (same code as above)
                local OptionButton = Instance.new("TextButton")
                OptionButton.Name = option
                OptionButton.Size = UDim2.new(1, -10, 0, 30)
                OptionButton.BackgroundColor3 = theme.Secondary
                OptionButton.Text = ""
                OptionButton.AutoButtonColor = false
                OptionButton.BorderSizePixel = 0
                OptionButton.Parent = OptionsList
                
                local OptionCorner = Instance.new("UICorner")
                OptionCorner.CornerRadius = UDim.new(0, 4)
                OptionCorner.Parent = OptionButton
                
                local OptionLabel = Instance.new("TextLabel")
                OptionLabel.Size = UDim2.new(1, -10, 1, 0)
                OptionLabel.Position = UDim2.new(0, 10, 0, 0)
                OptionLabel.BackgroundTransparency = 1
                OptionLabel.Text = option
                OptionLabel.TextColor3 = theme.Text
                OptionLabel.TextSize = 13
                OptionLabel.Font = Enum.Font.Gotham
                OptionLabel.TextXAlignment = Enum.TextXAlignment.Left
                OptionLabel.Parent = OptionButton
                
                OptionButton.MouseEnter:Connect(function()
                    Utility:Tween(OptionButton, {BackgroundColor3 = theme.Hover})
                end)
                
                OptionButton.MouseLeave:Connect(function()
                    Utility:Tween(OptionButton, {BackgroundColor3 = theme.Secondary})
                end)
                
                OptionButton.MouseButton1Click:Connect(function()
                    CurrentValue = option
                    SelectedText.Text = option
                    IsOpen = false
                    Utility:Tween(Arrow, {Rotation = 0}, 0.2)
                    Utility:Tween(OptionsContainer, {Size = UDim2.new(0.55, 0, 0, 0)}, 0.2)
                    task.wait(0.2)
                    OptionsContainer.Visible = false
                    
                    if config.Callback then
                        task.spawn(config.Callback, option)
                    end
                end)
            end
        end
    }
end

function Components:CreateLabel(parent, config)
    local theme = RhyRu9.CurrentTheme
    
    local Label = Instance.new("Frame")
    Label.Name = config.Name or "Label"
    Label.Size = UDim2.new(1, 0, 0, 30)
    Label.BackgroundTransparency = 1
    Label.BorderSizePixel = 0
    Label.Parent = parent
    
    local LabelText = Instance.new("TextLabel")
    LabelText.Name = "Text"
    LabelText.Size = UDim2.new(1, -10, 1, 0)
    LabelText.Position = UDim2.new(0, 10, 0, 0)
    LabelText.BackgroundTransparency = 1
    LabelText.Text = config.Text or ""
    LabelText.TextColor3 = theme.TextDark
    LabelText.TextSize = 13
    LabelText.Font = Enum.Font.Gotham
    LabelText.TextXAlignment = Enum.TextXAlignment.Left
    LabelText.TextWrapped = true
    LabelText.Parent = Label
    
    return {
        Frame = Label,
        Set = function(text) LabelText.Text = text end
    }
end

-- ===== NOTIFICATION SYSTEM =====
local Notifications = {}
Notifications.Queue = {}
Notifications.Active = {}
Notifications.Container = nil

function Notifications:Initialize(parent)
    if self.Container then return end
    
    local theme = RhyRu9.CurrentTheme
    
    self.Container = Instance.new("Frame")
    self.Container.Name = "Notifications"
    self.Container.Size = UDim2.new(0, 300, 1, 0)
    self.Container.Position = UDim2.new(1, -310, 0, 10)
    self.Container.BackgroundTransparency = 1
    self.Container.BorderSizePixel = 0
    self.Container.Parent = parent
    
    local Layout = Instance.new("UIListLayout")
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Padding = UDim.new(0, 10)
    Layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    Layout.Parent = self.Container
end

function Notifications:Create(config)
    if not self.Container then return end
    
    local theme = RhyRu9.CurrentTheme
    
    local Notification = Instance.new("Frame")
    Notification.Name = "Notification"
    Notification.Size = UDim2.new(1, 0, 0, 0)
    Notification.BackgroundColor3 = theme.Secondary
    Notification.BorderSizePixel = 0
    Notification.ClipsDescendants = true
    Notification.Parent = self.Container
    
    local NotifCorner = Instance.new("UICorner")
    NotifCorner.CornerRadius = UDim.new(0, 8)
    NotifCorner.Parent = Notification
    
    local NotifStroke = Instance.new("UIStroke")
    NotifStroke.Color = theme.Border
    NotifStroke.Thickness = 1
    NotifStroke.Parent = Notification
    
    -- Accent Bar
    local AccentBar = Instance.new("Frame")
    AccentBar.Name = "Accent"
    AccentBar.Size = UDim2.new(0, 4, 1, 0)
    AccentBar.BackgroundColor3 = config.Type == "Error" and theme.Error or 
                                  config.Type == "Warning" and theme.Warning or
                                  config.Type == "Success" and theme.Success or theme.Accent
    AccentBar.BorderSizePixel = 0
    AccentBar.Parent = Notification
    
    local AccentCorner = Instance.new("UICorner")
    AccentCorner.CornerRadius = UDim.new(0, 8)
    AccentCorner.Parent = AccentBar
    
    -- Cover right side of accent bar
    local AccentCover = Instance.new("Frame")
    AccentCover.Size = UDim2.new(0, 4, 1, 0)
    AccentCover.Position = UDim2.new(1, -4, 0, 0)
    AccentCover.BackgroundColor3 = AccentBar.BackgroundColor3
    AccentCover.BorderSizePixel = 0
    AccentCover.Parent = AccentBar
    
    -- Content Container
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "Content"
    ContentContainer.Size = UDim2.new(1, -15, 1, -10)
    ContentContainer.Position = UDim2.new(0, 10, 0, 5)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.BorderSizePixel = 0
    ContentContainer.Parent = Notification
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, 0, 0, 20)
    Title.BackgroundTransparency = 1
    Title.Text = config.Title or "Notification"
    Title.TextColor3 = theme.Text
    Title.TextSize = 14
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = ContentContainer
    
    -- Content
    local Content = Instance.new("TextLabel")
    Content.Name = "Message"
    Content.Size = UDim2.new(1, 0, 1, -25)
    Content.Position = UDim2.new(0, 0, 0, 22)
    Content.BackgroundTransparency = 1
    Content.Text = config.Content or ""
    Content.TextColor3 = theme.TextDark
    Content.TextSize = 12
    Content.Font = Enum.Font.Gotham
    Content.TextXAlignment = Enum.TextXAlignment.Left
    Content.TextYAlignment = Enum.TextYAlignment.Top
    Content.TextWrapped = true
    Content.Parent = ContentContainer
    
    -- Calculate height
    local textBounds = Content.TextBounds.Y
    local finalHeight = math.max(textBounds + 35, 60)
    
    -- Animate in
    Notification.BackgroundTransparency = 1
    NotifStroke.Transparency = 1
    Title.TextTransparency = 1
    Content.TextTransparency = 1
    
    Utility:Tween(Notification, {Size = UDim2.new(1, 0, 0, finalHeight)}, 0.3)
    Utility:Tween(Notification, {BackgroundTransparency = 0}, 0.3)
    Utility:Tween(NotifStroke, {Transparency = 0}, 0.3)
    Utility:Tween(Title, {TextTransparency = 0}, 0.3)
    Utility:Tween(Content, {TextTransparency = 0.2}, 0.3)
    
    -- Auto dismiss
    local duration = config.Duration or 3
    task.delay(duration, function()
        Utility:Tween(Notification, {BackgroundTransparency = 1}, 0.3)
        Utility:Tween(NotifStroke, {Transparency = 1}, 0.3)
        Utility:Tween(Title, {TextTransparency = 1}, 0.3)
        Utility:Tween(Content, {TextTransparency = 1}, 0.3)
        Utility:Tween(Notification, {Size = UDim2.new(1, 0, 0, 0)}, 0.3)
        task.wait(0.3)
        Notification:Destroy()
    end)
    
    EventSystem:Fire("NotificationShown", config)
end

-- ===== WINDOW CLASS =====
local Window = {}
Window.__index = Window

function RhyRu9:CreateWindow(config)
    config = config or {}
    
    local self = setmetatable({}, Window)
    
    self.Name = config.Name or "RhyRu9 UI"
    self.Tabs = {}
    self.CurrentTab = nil
    self.UI = Components:CreateMain()
    self.Elements = Components:CreateWindow(self.UI, self.Name)
    self.Minimized = false
    self.Hidden = false
    
    -- Initialize Notifications
    Notifications:Initialize(self.UI)
    
    -- Close Button
    self.Elements.CloseBtn.MouseButton1Click:Connect(function()
        self:Destroy()
    end)
    
    -- Minimize Button
    self.Elements.MinimizeBtn.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
    
    table.insert(RhyRu9.Windows, self)
    Logger:Success("Window created: " .. self.Name)
    EventSystem:Fire("WindowCreated", self)
    
    return self
end

function Window:CreateTab(name)
    local Tab = {
        Name = name,
        Elements = {},
        Button = Components:CreateTab(self.Elements.TabList, name),
        Content = Components:CreateTabContent(self.Elements.ContentContainer, name)
    }
    
    table.insert(self.Tabs, Tab)
    
    -- First tab is automatically selected
    if #self.Tabs == 1 then
        self:SelectTab(Tab)
    end
    
    -- Tab Click
    Tab.Button.MouseButton1Click:Connect(function()
        self:SelectTab(Tab)
    end)
    
    -- Enhanced Tab Methods
    local TabMethods = {
        CreateSection = function(_, title)
            return Components:CreateSection(Tab.Content, title)
        end,
        
        CreateButton = function(_, config)
            local element = Components:CreateButton(Tab.Content, config)
            table.insert(Tab.Elements, {Type = "Button", Element = element, Config = config})
            if config.Flag then
                RhyRu9.Flags[config.Flag] = element
            end
            return element
        end,
        
        CreateToggle = function(_, config)
            local element = Components:CreateToggle(Tab.Content, config)
            table.insert(Tab.Elements, {Type = "Toggle", Element = element, Config = config})
            if config.Flag then
                RhyRu9.Flags[config.Flag] = element
            end
            return element
        end,
        
        CreateSlider = function(_, config)
            local element = Components:CreateSlider(Tab.Content, config)
            table.insert(Tab.Elements, {Type = "Slider", Element = element, Config = config})
            if config.Flag then
                RhyRu9.Flags[config.Flag] = element
            end
            return element
        end,
        
        CreateInput = function(_, config)
            local element = Components:CreateInput(Tab.Content, config)
            table.insert(Tab.Elements, {Type = "Input", Element = element, Config = config})
            if config.Flag then
                RhyRu9.Flags[config.Flag] = element
            end
            return element
        end,
        
        CreateDropdown = function(_, config)
            local element = Components:CreateDropdown(Tab.Content, config)
            table.insert(Tab.Elements, {Type = "Dropdown", Element = element, Config = config})
            if config.Flag then
                RhyRu9.Flags[config.Flag] = element
            end
            return element
        end,
        
        CreateLabel = function(_, config)
            local element = Components:CreateLabel(Tab.Content, config)
            table.insert(Tab.Elements, {Type = "Label", Element = element, Config = config})
            return element
        end,
        
        CreateParagraph = function(_, config)
            return TabMethods.CreateLabel(_, {
                Name = config.Title,
                Text = (config.Title and config.Title .. "\n" or "") .. (config.Content or "")
            })
        end,
        
        CreateDivider = function(_)
            local theme = RhyRu9.CurrentTheme
            local Divider = Instance.new("Frame")
            Divider.Name = "Divider"
            Divider.Size = UDim2.new(1, 0, 0, 1)
            Divider.BackgroundColor3 = theme.Border
            Divider.BorderSizePixel = 0
            Divider.Parent = Tab.Content
            return Divider
        end
    }
    
    setmetatable(Tab, {__index = TabMethods})
    
    Logger:Success("Tab created: " .. name)
    EventSystem:Fire("TabCreated", Tab)
    
    return Tab
end

function Window:SelectTab(Tab)
    local theme = RhyRu9.CurrentTheme
    
    -- Hide all tabs
    for _, tab in ipairs(self.Tabs) do
        tab.Content.Visible = false
        tab.Button:SetAttribute("Selected", false)
        Utility:Tween(tab.Button, {BackgroundColor3 = theme.Tertiary})
        Utility:Tween(tab.Button.Label, {TextColor3 = theme.TextDark})
    end
    
    -- Show selected tab
    Tab.Content.Visible = true
    Tab.Button:SetAttribute("Selected", true)
    Utility:Tween(Tab.Button, {BackgroundColor3 = theme.Accent})
    Utility:Tween(Tab.Button.Label, {TextColor3 = Color3.fromRGB(255, 255, 255)})
    
    self.CurrentTab = Tab
    EventSystem:Fire("TabSelected", Tab)
end

function Window:Notify(config)
    Notifications:Create(config)
end

function Window:SetTheme(themeName)
    if RhyRu9.Themes[themeName] then
        RhyRu9.CurrentTheme = RhyRu9.Themes[themeName]
        
        -- Update all UI elements with new theme
        local theme = RhyRu9.CurrentTheme
        
        -- Main elements
        self.Elements.Main.BackgroundColor3 = theme.Background
        self.Elements.Topbar.BackgroundColor3 = theme.Secondary
        self.Elements.Title.TextColor3 = theme.Text
        
        self:Notify({
            Title = "Theme Changed",
            Content = "Theme set to: " .. themeName,
            Type = "Success",
            Duration = 2
        })
        
        EventSystem:Fire("ThemeChanged", themeName)
    else
        Logger:Error("Theme not found: " .. themeName)
    end
end

function Window:Toggle()
    if self.Minimized then
        self.Minimized = false
        Utility:Tween(self.Elements.Main, {Size = UDim2.new(0, 550, 0, 400)}, 0.3)
        self.Elements.TabList.Parent.Visible = true
        self.Elements.ContentContainer.Visible = true
    else
        self.Minimized = true
        Utility:Tween(self.Elements.Main, {Size = UDim2.new(0, 550, 0, 40)}, 0.3)
        task.wait(0.3)
        self.Elements.TabList.Parent.Visible = false
        self.Elements.ContentContainer.Visible = false
    end
end

function Window:Hide()
    self.Hidden = true
    Utility:Tween(self.Elements.Main, {Position = UDim2.new(0.5, -275, 1, 50)}, 0.3)
end

function Window:Show()
    self.Hidden = false
    Utility:Tween(self.Elements.Main, {Position = UDim2.new(0.5, -275, 0.5, -200)}, 0.3)
end

function Window:Destroy()
    EventSystem:Fire("WindowDestroyed", self)
    
    if self.UI then
        Utility:Tween(self.Elements.Main, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
        Utility:Tween(self.Elements.Main, {BackgroundTransparency = 1}, 0.3)
        task.wait(0.3)
        self.UI:Destroy()
    end
    
    for i, win in ipairs(RhyRu9.Windows) do
        if win == self then
            table.remove(RhyRu9.Windows, i)
            break
        end
    end
    
    Logger:Success("Window destroyed: " .. self.Name)
end

-- ===== PRESET SYSTEM =====
function Window:SavePreset(presetName)
    presetName = presetName or "Preset_" .. os.time()
    
    local preset = {
        Name = presetName,
        CreatedAt = os.time(),
        Flags = {}
    }
    
    for flagName, flagData in pairs(RhyRu9.Flags) do
        if flagData.GetValue then
            preset.Flags[flagName] = flagData.GetValue()
        end
    end
    
    RhyRu9.Presets[presetName] = preset
    
    self:Notify({
        Title = "Preset Saved",
        Content = "Preset '" .. presetName .. "' saved!",
        Type = "Success",
        Duration = 2
    })
    
    Logger:Success("Preset saved: " .. presetName)
    EventSystem:Fire("PresetSaved", presetName)
    
    return preset
end

function Window:LoadPreset(presetName)
    local preset = RhyRu9.Presets[presetName]
    
    if not preset then
        self:Notify({
            Title = "Preset Error",
            Content = "Preset '" .. presetName .. "' not found!",
            Type = "Error",
            Duration = 2
        })
        Logger:Error("Preset not found: " .. presetName)
        return false
    end
    
    for flagName, value in pairs(preset.Flags) do
        local flag = RhyRu9.Flags[flagName]
        if flag and flag.Set then
            flag.Set(value)
        end
    end
    
    self:Notify({
        Title = "Preset Loaded",
        Content = "Preset '" .. presetName .. "' loaded!",
        Type = "Success",
        Duration = 2
    })
    
    Logger:Success("Preset loaded: " .. presetName)
    EventSystem:Fire("PresetLoaded", presetName)
    return true
end

function Window:DeletePreset(presetName)
    if RhyRu9.Presets[presetName] then
        RhyRu9.Presets[presetName] = nil
        
        self:Notify({
            Title = "Preset Deleted",
            Content = "Preset '" .. presetName .. "' deleted!",
            Type = "Warning",
            Duration = 2
        })
        
        Logger:Info("Preset deleted: " .. presetName)
        EventSystem:Fire("PresetDeleted", presetName)
        return true
    end
    return false
end

function Window:GetAllPresets()
    local presets = {}
    for name, _ in pairs(RhyRu9.Presets) do
        table.insert(presets, name)
    end
    return presets
end

-- ===== CONFIGURATION SYSTEM =====
function Window:SaveConfiguration(fileName)
    if not (writefile and isfolder and makefolder) then
        self:Notify({
            Title = "Config Error",
            Content = "Executor doesn't support file operations!",
            Type = "Error",
            Duration = 3
        })
        return false
    end
    
    fileName = fileName or self.Name
    local folderName = "RhyRu9_Configs"
    
    if not isfolder(folderName) then
        makefolder(folderName)
    end
    
    local config = {
        Version = RhyRu9.Version,
        Created = os.time(),
        Flags = {}
    }
    
    for flagName, flagData in pairs(RhyRu9.Flags) do
        if flagData.GetValue then
            config.Flags[flagName] = flagData.GetValue()
        end
    end
    
    local success, encoded = pcall(function()
        return HttpService:JSONEncode(config)
    end)
    
    if success then
        writefile(folderName .. "/" .. fileName .. ".json", encoded)
        
        self:Notify({
            Title = "Config Saved",
            Content = "Configuration saved to " .. fileName .. ".json",
            Type = "Success",
            Duration = 2
        })
        
        Logger:Success("Configuration saved: " .. fileName)
        EventSystem:Fire("ConfigurationSaved", fileName)
        return true
    else
        Logger:Error("Failed to encode configuration")
        return false
    end
end

function Window:LoadConfiguration(fileName)
    if not (readfile and isfile) then
        self:Notify({
            Title = "Config Error",
            Content = "Executor doesn't support file operations!",
            Type = "Error",
            Duration = 3
        })
        return false
    end
    
    fileName = fileName or self.Name
    local folderName = "RhyRu9_Configs"
    local filePath = folderName .. "/" .. fileName .. ".json"
    
    if not isfile(filePath) then
        self:Notify({
            Title = "Config Error",
            Content = "Configuration file not found!",
            Type = "Error",
            Duration = 2
        })
        return false
    end
    
    local success, decoded = pcall(function()
        local content = readfile(filePath)
        return HttpService:JSONDecode(content)
    end)
    
    if success and decoded then
        for flagName, value in pairs(decoded.Flags) do
            local flag = RhyRu9.Flags[flagName]
            if flag and flag.Set then
                flag.Set(value)
            end
        end
        
        self:Notify({
            Title = "Config Loaded",
            Content = "Configuration loaded from " .. fileName .. ".json",
            Type = "Success",
            Duration = 2
        })
        
        Logger:Success("Configuration loaded: " .. fileName)
        EventSystem:Fire("ConfigurationLoaded", fileName)
        return true
    else
        self:Notify({
            Title = "Config Error",
            Content = "Failed to load configuration!",
            Type = "Error",
            Duration = 2
        })
        Logger:Error("Failed to decode configuration")
        return false
    end
end

-- ===== GLOBAL FUNCTIONS =====
function RhyRu9:GetFlag(flagName)
    return self.Flags[flagName]
end

function RhyRu9:GetAllFlags()
    local flags = {}
    for name, data in pairs(self.Flags) do
        if data.GetValue then
            flags[name] = data.GetValue()
        end
    end
    return flags
end

function RhyRu9:SetDebugMode(enabled)
    self.DebugMode = enabled
    Logger:Info("Debug mode " .. (enabled and "enabled" or "disabled"))
end

function RhyRu9:DestroyAllWindows()
    for _, window in ipairs(self.Windows) do
        window:Destroy()
    end
    self.Windows = {}
    Logger:Success("All windows destroyed")
end

function RhyRu9:On(eventName, callback)
    return EventSystem:Connect(eventName, callback)
end

function RhyRu9:Fire(eventName, ...)
    EventSystem:Fire(eventName, ...)
end

function RhyRu9:GetEvents()
    local events = {}
    for eventName, eventData in pairs(self.Events) do
        table.insert(events, {
            Name = eventName,
            Connections = 0,
            Fired = eventData.Fired
        })
        
        for _ in pairs(eventData.Callbacks) do
            events[#events].Connections = events[#events].Connections + 1
        end
    end
    return events
end

function RhyRu9:GetStatistics()
    local totalFlags = 0
    for _ in pairs(self.Flags) do
        totalFlags = totalFlags + 1
    end
    
    local totalPresets = 0
    for _ in pairs(self.Presets) do
        totalPresets = totalPresets + 1
    end
    
    local totalEvents = 0
    for _ in pairs(self.Events) do
        totalEvents = totalEvents + 1
    end
    
    return {
        Version = self.Version,
        Windows = #self.Windows,
        TotalFlags = totalFlags,
        TotalPresets = totalPresets,
        TotalEvents = totalEvents,
        Uptime = tick() - (self.StartTime or tick())
    }
end

function RhyRu9:PrintStatistics()
    local stats = self:GetStatistics()
    
    print("╔══════════════════════════════════════════╗")
    print("║    RhyRu9 UI Library - Pure Standalone  ║")
    print("╠══════════════════════════════════════════╣")
    print(string.format("║  Version: %-27s║", stats.Version))
    print(string.format("║  Windows: %-27d║", stats.Windows))
    print(string.format("║  Flags: %-29d║", stats.TotalFlags))
    print(string.format("║  Presets: %-27d║", stats.TotalPresets))
    print(string.format("║  Events: %-28d║", stats.TotalEvents))
    print(string.format("║  Uptime: %-24.1fs║", stats.Uptime))
    print("╚══════════════════════════════════════════╝")
end

-- ===== INITIALIZATION =====
RhyRu9.StartTime = tick()

-- Create Events
EventSystem:Create("WindowCreated")
EventSystem:Create("WindowDestroyed")
EventSystem:Create("TabCreated")
EventSystem:Create("TabSelected")
EventSystem:Create("ButtonClicked")
EventSystem:Create("ToggleChanged")
EventSystem:Create("SliderChanged")
EventSystem:Create("InputChanged")
EventSystem:Create("DropdownChanged")
EventSystem:Create("PresetSaved")
EventSystem:Create("PresetLoaded")
EventSystem:Create("PresetDeleted")
EventSystem:Create("ConfigurationSaved")
EventSystem:Create("ConfigurationLoaded")
EventSystem:Create("ThemeChanged")
EventSystem:Create("NotificationShown")

Logger:Success("RhyRu9 UI Library v" .. RhyRu9.Version .. " - Pure Standalone Edition")
Logger:Success("100% Independent - No External Dependencies!")

-- ===== EXPORT =====
return RhyRu9
