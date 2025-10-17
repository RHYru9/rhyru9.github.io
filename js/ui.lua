local RhyRu9 = {}
RhyRu9.__index = RhyRu9
RhyRu9.Version = "3.1.0"
RhyRu9.Flags = {}
RhyRu9.Windows = {}
RhyRu9.Events = {}
RhyRu9.Presets = {}
RhyRu9.DebugMode = false
RhyRu9._internal = {}

-- ===== SERVICES =====
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- ===== LOAD RAYFIELD =====
local Rayfield
local RayfieldLoadSuccess, RayfieldError = pcall(function()
    Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not RayfieldLoadSuccess then
    warn("❌ RhyRu9 Error: Failed to load Rayfield - " .. tostring(RayfieldError))
    return nil
end

-- ===== UTILITY FUNCTIONS =====
local Utility = {}

function Utility:ValidateString(value, default)
    if type(value) == "string" and #value > 0 then
        return value
    end
    return default or "Unnamed"
end

function Utility:ValidateNumber(value, min, max, default)
    if type(value) == "number" then
        if min and value < min then return min end
        if max and value > max then return max end
        return value
    end
    return default or 0
end

function Utility:ValidateBoolean(value, default)
    if type(value) == "boolean" then
        return value
    end
    return default or false
end

function Utility:ValidateTable(value, default)
    if type(value) == "table" then
        return value
    end
    return default or {}
end

function Utility:ValidateCallback(callback)
    if type(callback) == "function" then
        return callback
    end
    return function() end
end

function Utility:ValidateColor(color)
    if typeof(color) == "Color3" then
        return color
    elseif type(color) == "table" and color.R and color.G and color.B then
        return Color3.fromRGB(color.R, color.G, color.B)
    end
    return Color3.fromRGB(255, 255, 255)
end

function Utility:SafeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        if RhyRu9.DebugMode then
            warn("⚠️ RhyRu9 Callback Error: " .. tostring(result))
        end
        return false, result
    end
    return true, result
end

function Utility:DeepCopy(original)
    local copy
    if type(original) == 'table' then
        copy = {}
        for key, value in next, original, nil do
            copy[Utility:DeepCopy(key)] = Utility:DeepCopy(value)
        end
        setmetatable(copy, Utility:DeepCopy(getmetatable(original)))
    else
        copy = original
    end
    return copy
end

function Utility:GenerateID()
    return HttpService:GenerateGUID(false)
end

function Utility:Timestamp()
    return os.time()
end

-- ===== DEBUG LOGGER =====
local Logger = {}

function Logger:Log(level, message)
    if not RhyRu9.DebugMode then return end
    
    local prefix = {
        ["INFO"] = "ℹ️",
        ["WARN"] = "⚠️",
        ["ERROR"] = "❌",
        ["SUCCESS"] = "✅"
    }
    
    print(string.format("[RhyRu9 %s] %s %s", level, prefix[level] or "•", message))
end

function Logger:Info(message)
    self:Log("INFO", message)
end

function Logger:Warn(message)
    self:Log("WARN", message)
end

function Logger:Error(message)
    self:Log("ERROR", message)
end

function Logger:Success(message)
    self:Log("SUCCESS", message)
end

-- ===== EVENT SYSTEM =====
local EventSystem = {}

function EventSystem:Create(eventName)
    if not RhyRu9.Events[eventName] then
        RhyRu9.Events[eventName] = {
            Callbacks = {},
            Fired = 0
        }
        Logger:Info("Event created: " .. eventName)
    end
end

function EventSystem:Connect(eventName, callback)
    if not RhyRu9.Events[eventName] then
        self:Create(eventName)
    end
    
    local id = Utility:GenerateID()
    RhyRu9.Events[eventName].Callbacks[id] = callback
    
    return {
        Disconnect = function()
            RhyRu9.Events[eventName].Callbacks[id] = nil
        end
    }
end

function EventSystem:Fire(eventName, ...)
    if not RhyRu9.Events[eventName] then return end
    
    RhyRu9.Events[eventName].Fired = RhyRu9.Events[eventName].Fired + 1
    
    for _, callback in pairs(RhyRu9.Events[eventName].Callbacks) do
        Utility:SafeCall(callback, ...)
    end
end

-- ===== PERFORMANCE MONITOR =====
local Performance = {}
Performance.Stats = {
    ElementsCreated = 0,
    CallbacksFired = 0,
    ErrorsOccurred = 0,
    StartTime = tick()
}

function Performance:RecordElement()
    self.Stats.ElementsCreated = self.Stats.ElementsCreated + 1
end

function Performance:RecordCallback()
    self.Stats.CallbacksFired = self.Stats.CallbacksFired + 1
end

function Performance:RecordError()
    self.Stats.ErrorsOccurred = self.Stats.ErrorsOccurred + 1
end

function Performance:GetUptime()
    return tick() - self.Stats.StartTime
end

function Performance:GetStats()
    return {
        ElementsCreated = self.Stats.ElementsCreated,
        CallbacksFired = self.Stats.CallbacksFired,
        ErrorsOccurred = self.Stats.ErrorsOccurred,
        Uptime = self:GetUptime(),
        Windows = #RhyRu9.Windows,
        Flags = #RhyRu9.Flags
    }
end

-- ===== WINDOW CLASS =====
local Window = {}
Window.__index = Window

function RhyRu9:CreateWindow(WindowSettings)
    WindowSettings = Utility:ValidateTable(WindowSettings, {})
    
    local self = setmetatable({}, Window)
    
    -- Validate Settings
    self.Name = Utility:ValidateString(WindowSettings.Name, "RhyRu9 Window")
    self.Tabs = {}
    self.CurrentTab = nil
    self.Elements = {}
    self.Groups = {}
    self.ID = Utility:GenerateID()
    self.CreatedAt = Utility:Timestamp()
    
    -- Create Rayfield Window
    local success, result = pcall(function()
        return Rayfield:CreateWindow(WindowSettings)
    end)
    
    if not success then
        Logger:Error("Failed to create window - " .. tostring(result))
        Performance:RecordError()
        return nil
    end
    
    self.RayfieldWindow = result
    table.insert(RhyRu9.Windows, self)
    
    Logger:Success("Window created: " .. self.Name)
    EventSystem:Fire("WindowCreated", self)
    
    return self
end

function Window:CreateTab(TabName, Icon)
    TabName = Utility:ValidateString(TabName, "New Tab")
    
    local Tab = {
        Name = TabName,
        Icon = Icon,
        Sections = {},
        Elements = {},
        ID = Utility:GenerateID(),
        Visible = true,
        Enabled = true,
        Order = #self.Tabs + 1
    }
    
    -- Create Rayfield Tab
    local success, result = pcall(function()
        return self.RayfieldWindow:CreateTab(TabName, Icon or 0)
    end)
    
    if not success then
        Logger:Error("Failed to create tab '" .. TabName .. "' - " .. tostring(result))
        Performance:RecordError()
        return nil
    end
    
    Tab.RayfieldTab = result
    table.insert(self.Tabs, Tab)
    
    if not self.CurrentTab then
        self.CurrentTab = Tab
    end
    
    -- Enhanced Tab Methods
    local TabMethods = {
        -- Section
        CreateSection = function(_, SectionName)
            return self:CreateSection(Tab, SectionName)
        end,
        
        -- Divider
        CreateDivider = function(_)
            return self:CreateDivider(Tab)
        end,
        
        -- Label
        CreateLabel = function(_, LabelText, Icon, Color, IgnoreTheme)
            return self:CreateLabel(Tab, LabelText, Icon, Color, IgnoreTheme)
        end,
        
        -- Paragraph
        CreateParagraph = function(_, ParagraphSettings)
            return self:CreateParagraph(Tab, ParagraphSettings)
        end,
        
        -- Button
        CreateButton = function(_, ButtonSettings)
            return self:CreateButton(Tab, ButtonSettings)
        end,
        
        -- Toggle
        CreateToggle = function(_, ToggleSettings)
            return self:CreateToggle(Tab, ToggleSettings)
        end,
        
        -- Slider
        CreateSlider = function(_, SliderSettings)
            return self:CreateSlider(Tab, SliderSettings)
        end,
        
        -- Input
        CreateInput = function(_, InputSettings)
            return self:CreateInput(Tab, InputSettings)
        end,
        
        -- Dropdown
        CreateDropdown = function(_, DropdownSettings)
            return self:CreateDropdown(Tab, DropdownSettings)
        end,
        
        -- ColorPicker
        CreateColorPicker = function(_, ColorPickerSettings)
            return self:CreateColorPicker(Tab, ColorPickerSettings)
        end,
        
        -- Keybind
        CreateKeybind = function(_, KeybindSettings)
            return self:CreateKeybind(Tab, KeybindSettings)
        end,
        
        -- Tab Management
        Hide = function(_)
            return self:HideTab(Tab)
        end,
        
        Show = function(_)
            return self:ShowTab(Tab)
        end,
        
        Enable = function(_)
            return self:EnableTab(Tab)
        end,
        
        Disable = function(_)
            return self:DisableTab(Tab)
        end,
        
        SetOrder = function(_, order)
            return self:SetTabOrder(Tab, order)
        end,
        
        -- Element Management
        GetElements = function(_)
            return Tab.Elements
        end,
        
        FindElement = function(_, name)
            return self:FindElement(Tab, name)
        end,
        
        ClearElements = function(_)
            return self:ClearTabElements(Tab)
        end
    }
    
    setmetatable(Tab, {__index = TabMethods})
    
    Logger:Success("Tab created: " .. TabName)
    EventSystem:Fire("TabCreated", Tab)
    
    return Tab
end

-- ===== TAB MANAGEMENT =====
function Window:HideTab(Tab)
    Tab.Visible = false
    Logger:Info("Tab hidden: " .. Tab.Name)
    EventSystem:Fire("TabHidden", Tab)
end

function Window:ShowTab(Tab)
    Tab.Visible = true
    Logger:Info("Tab shown: " .. Tab.Name)
    EventSystem:Fire("TabShown", Tab)
end

function Window:EnableTab(Tab)
    Tab.Enabled = true
    Logger:Info("Tab enabled: " .. Tab.Name)
end

function Window:DisableTab(Tab)
    Tab.Enabled = false
    Logger:Info("Tab disabled: " .. Tab.Name)
end

function Window:SetTabOrder(Tab, order)
    Tab.Order = order
    table.sort(self.Tabs, function(a, b) return a.Order < b.Order end)
    Logger:Info("Tab order changed: " .. Tab.Name .. " -> " .. order)
end

function Window:GetTabByName(name)
    for _, tab in ipairs(self.Tabs) do
        if tab.Name == name then
            return tab
        end
    end
    return nil
end

-- ===== ELEMENT WRAPPER =====
local function WrapElement(element, elementType, Tab, settings)
    if not element then return nil end
    
    local wrapped = {
        Type = elementType,
        Name = settings.Name or "Unnamed",
        ID = Utility:GenerateID(),
        RayfieldElement = element,
        Tab = Tab,
        Visible = true,
        Enabled = true,
        Settings = settings,
        CreatedAt = Utility:Timestamp(),
        Dependencies = {}
    }
    
    table.insert(Tab.Elements, wrapped)
    
    -- Enhanced methods
    wrapped.Hide = function()
        wrapped.Visible = false
        Logger:Info("Element hidden: " .. wrapped.Name)
    end
    
    wrapped.Show = function()
        wrapped.Visible = true
        Logger:Info("Element shown: " .. wrapped.Name)
    end
    
    wrapped.Enable = function()
        wrapped.Enabled = true
        Logger:Info("Element enabled: " .. wrapped.Name)
    end
    
    wrapped.Disable = function()
        wrapped.Enabled = false
        Logger:Info("Element disabled: " .. wrapped.Name)
    end
    
    wrapped.AddDependency = function(flag, condition)
        table.insert(wrapped.Dependencies, {Flag = flag, Condition = condition})
    end
    
    wrapped.CheckDependencies = function()
        for _, dep in ipairs(wrapped.Dependencies) do
            local flagValue = RhyRu9:GetFlag(dep.Flag)
            if flagValue and not dep.Condition(flagValue.CurrentValue or flagValue.CurrentKeybind) then
                return false
            end
        end
        return true
    end
    
    Performance:RecordElement()
    EventSystem:Fire("ElementCreated", wrapped)
    
    return wrapped
end

-- ===== SECTION =====
function Window:CreateSection(Tab, SectionName)
    SectionName = Utility:ValidateString(SectionName, "Section")
    
    local success, result = pcall(function()
        return Tab.RayfieldTab:CreateSection(SectionName)
    end)
    
    if not success then
        Logger:Error("Failed to create section - " .. tostring(result))
        Performance:RecordError()
        return nil
    end
    
    local section = {Name = SectionName, Element = result}
    table.insert(Tab.Sections, section)
    
    return result
end

-- ===== DIVIDER =====
function Window:CreateDivider(Tab)
    local success, result = pcall(function()
        return Tab.RayfieldTab:CreateDivider()
    end)
    
    if not success then
        Logger:Error("Failed to create divider - " .. tostring(result))
        Performance:RecordError()
        return nil
    end
    
    return result
end

-- ===== LABEL =====
function Window:CreateLabel(Tab, LabelText, Icon, Color, IgnoreTheme)
    LabelText = Utility:ValidateString(LabelText, "Label")
    
    local success, result = pcall(function()
        return Tab.RayfieldTab:CreateLabel(
            LabelText,
            Icon,
            Color and Utility:ValidateColor(Color) or nil,
            Utility:ValidateBoolean(IgnoreTheme, false)
        )
    end)
    
    if not success then
        Logger:Error("Failed to create label - " .. tostring(result))
        Performance:RecordError()
        return nil
    end
    
    return WrapElement(result, "Label", Tab, {Name = LabelText})
end

-- ===== PARAGRAPH =====
function Window:CreateParagraph(Tab, ParagraphSettings)
    ParagraphSettings = Utility:ValidateTable(ParagraphSettings, {})
    
    local Settings = {
        Title = Utility:ValidateString(ParagraphSettings.Title, "Paragraph"),
        Content = Utility:ValidateString(ParagraphSettings.Content, "Content")
    }
    
    local success, result = pcall(function()
        return Tab.RayfieldTab:CreateParagraph(Settings)
    end)
    
    if not success then
        Logger:Error("Failed to create paragraph - " .. tostring(result))
        Performance:RecordError()
        return nil
    end
    
    return WrapElement(result, "Paragraph", Tab, Settings)
end

-- ===== BUTTON =====
function Window:CreateButton(Tab, ButtonSettings)
    ButtonSettings = Utility:ValidateTable(ButtonSettings, {})
    
    local originalCallback = Utility:ValidateCallback(ButtonSettings.Callback)
    
    local Settings = {
        Name = Utility:ValidateString(ButtonSettings.Name, "Button"),
        Callback = function()
            Performance:RecordCallback()
            Utility:SafeCall(originalCallback)
            EventSystem:Fire("ButtonClicked", Settings.Name)
        end
    }
    
    local success, result = pcall(function()
        return Tab.RayfieldTab:CreateButton(Settings)
    end)
    
    if not success then
        Logger:Error("Failed to create button - " .. tostring(result))
        Performance:RecordError()
        return nil
    end
    
    return WrapElement(result, "Button", Tab, Settings)
end

-- ===== TOGGLE =====
function Window:CreateToggle(Tab, ToggleSettings)
    ToggleSettings = Utility:ValidateTable(ToggleSettings, {})
    
    local currentValue = ToggleSettings.CurrentValue
    if currentValue == nil and ToggleSettings.Default ~= nil then
        currentValue = ToggleSettings.Default
    end
    
    local originalCallback = Utility:ValidateCallback(ToggleSettings.Callback)
    
    local Settings = {
        Name = Utility:ValidateString(ToggleSettings.Name, "Toggle"),
        CurrentValue = Utility:ValidateBoolean(currentValue, false),
        Flag = ToggleSettings.Flag,
        Callback = function(Value)
            Performance:RecordCallback()
            Utility:SafeCall(originalCallback, Value)
            EventSystem:Fire("ToggleChanged", Settings.Name, Value)
        end
    }
    
    local success, result = pcall(function()
        return Tab.RayfieldTab:CreateToggle(Settings)
    end)
    
    if not success then
        Logger:Error("Failed to create toggle - " .. tostring(result))
        Performance:RecordError()
        return nil
    end
    
    if Settings.Flag then
        RhyRu9.Flags[Settings.Flag] = result
    end
    
    return WrapElement(result, "Toggle", Tab, Settings)
end

-- ===== SLIDER =====
function Window:CreateSlider(Tab, SliderSettings)
    SliderSettings = Utility:ValidateTable(SliderSettings, {})
    
    local currentValue = SliderSettings.CurrentValue
    if currentValue == nil and SliderSettings.Default ~= nil then
        currentValue = SliderSettings.Default
    end
    
    local min, max
    if SliderSettings.Range and type(SliderSettings.Range) == "table" then
        min = SliderSettings.Range[1] or 0
        max = SliderSettings.Range[2] or 100
    else
        min = SliderSettings.Min or 0
        max = SliderSettings.Max or 100
    end
    
    local originalCallback = Utility:ValidateCallback(SliderSettings.Callback)
    
    local Settings = {
        Name = Utility:ValidateString(SliderSettings.Name, "Slider"),
        Range = {
            Utility:ValidateNumber(min, nil, nil, 0),
            Utility:ValidateNumber(max, nil, nil, 100)
        },
        Increment = Utility:ValidateNumber(SliderSettings.Increment, nil, nil, 1),
        Suffix = SliderSettings.Suffix or "",
        CurrentValue = Utility:ValidateNumber(currentValue, min, max, min),
        Flag = SliderSettings.Flag,
        Callback = function(Value)
            Performance:RecordCallback()
            Utility:SafeCall(originalCallback, Value)
            EventSystem:Fire("SliderChanged", Settings.Name, Value)
        end
    }
    
    local success, result = pcall(function()
        return Tab.RayfieldTab:CreateSlider(Settings)
    end)
    
    if not success then
        Logger:Error("Failed to create slider - " .. tostring(result))
        Performance:RecordError()
        return nil
    end
    
    if Settings.Flag then
        RhyRu9.Flags[Settings.Flag] = result
    end
    
    return WrapElement(result, "Slider", Tab, Settings)
end

-- ===== INPUT =====
function Window:CreateInput(Tab, InputSettings)
    InputSettings = Utility:ValidateTable(InputSettings, {})
    
    local placeholder = InputSettings.PlaceholderText or InputSettings.Placeholder or ""
    local originalCallback = Utility:ValidateCallback(InputSettings.Callback)
    
    local Settings = {
        Name = Utility:ValidateString(InputSettings.Name, "Input"),
        CurrentValue = Utility:ValidateString(InputSettings.CurrentValue, ""),
        PlaceholderText = placeholder,
        RemoveTextAfterFocusLost = Utility:ValidateBoolean(InputSettings.RemoveTextAfterFocusLost, false),
        Flag = InputSettings.Flag,
        Callback = function(Text)
            Performance:RecordCallback()
            Utility:SafeCall(originalCallback, Text)
            EventSystem:Fire("InputChanged", Settings.Name, Text)
        end
    }
    
    local success, result = pcall(function()
        return Tab.RayfieldTab:CreateInput(Settings)
    end)
    
    if not success then
        Logger:Error("Failed to create input - " .. tostring(result))
        Performance:RecordError()
        return nil
    end
    
    if Settings.Flag then
        RhyRu9.Flags[Settings.Flag] = result
    end
    
    return WrapElement(result, "Input", Tab, Settings)
end

-- ===== DROPDOWN =====
function Window:CreateDropdown(Tab, DropdownSettings)
    DropdownSettings = Utility:ValidateTable(DropdownSettings, {})
    
    local options = Utility:ValidateTable(DropdownSettings.Options, {"Option 1"})
    local currentOption = DropdownSettings.CurrentOption
    
    if type(currentOption) == "string" then
        currentOption = {currentOption}
    elseif type(currentOption) ~= "table" then
        currentOption = {options[1]}
    end
    
    local originalCallback = Utility:ValidateCallback(DropdownSettings.Callback)
    
    local Settings = {
        Name = Utility:ValidateString(DropdownSettings.Name, "Dropdown"),
        Options = options,
        CurrentOption = currentOption,
        MultipleOptions = Utility:ValidateBoolean(DropdownSettings.MultipleOptions, false),
        Flag = DropdownSettings.Flag,
        Callback = function(Option)
            Performance:RecordCallback()
            Utility:SafeCall(originalCallback, Option)
            EventSystem:Fire("DropdownChanged", Settings.Name, Option)
        end
    }
    
    local success, result = pcall(function()
        return Tab.RayfieldTab:CreateDropdown(Settings)
    end)
    
    if not success then
        Logger:Error("Failed to create dropdown - " .. tostring(result))
        Performance:RecordError()
        return nil
    end
    
    if Settings.Flag then
        RhyRu9.Flags[Settings.Flag] = result
    end
    
    return WrapElement(result, "Dropdown", Tab, Settings)
end

-- ===== COLOR PICKER =====
function Window:CreateColorPicker(Tab, ColorPickerSettings)
    ColorPickerSettings = Utility:ValidateTable(ColorPickerSettings, {})
    
    local originalCallback = Utility:ValidateCallback(ColorPickerSettings.Callback)
    
    local Settings = {
        Name = Utility:ValidateString(ColorPickerSettings.Name, "Color Picker"),
        Color = Utility:ValidateColor(ColorPickerSettings.Color or Color3.fromRGB(255, 255, 255)),
        Flag = ColorPickerSettings.Flag,
        Callback = function(Color)
            Performance:RecordCallback()
            Utility:SafeCall(originalCallback, Color)
            EventSystem:Fire("ColorChanged", Settings.Name, Color)
        end
    }
    
    local success, result = pcall(function()
        return Tab.RayfieldTab:CreateColorPicker(Settings)
    end)
    
    if not success then
        Logger:Error("Failed to create color picker - " .. tostring(result))
        Performance:RecordError()
        return nil
    end
    
    if Settings.Flag then
        RhyRu9.Flags[Settings.Flag] = result
    end
    
    return WrapElement(result, "ColorPicker", Tab, Settings)
end

-- ===== KEYBIND =====
function Window:CreateKeybind(Tab, KeybindSettings)
    KeybindSettings = Utility:ValidateTable(KeybindSettings, {})
    
    local originalCallback = Utility:ValidateCallback(KeybindSettings.Callback)
    
    local Settings = {
        Name = Utility:ValidateString(KeybindSettings.Name, "Keybind"),
        CurrentKeybind = Utility:ValidateString(KeybindSettings.CurrentKeybind, "Q"),
        HoldToInteract = Utility:ValidateBoolean(KeybindSettings.HoldToInteract, false),
        Flag = KeybindSettings.Flag,
        Callback = function(Keybind)
            Performance:RecordCallback()
            Utility:SafeCall(originalCallback, Keybind)
            EventSystem:Fire("KeybindPressed", Settings.Name, Keybind)
        end
    }
    
    local success, result = pcall(function()
        return Tab.RayfieldTab:CreateKeybind(Settings)
    end)
    
    if not success then
        Logger:Error("Failed to create keybind - " .. tostring(result))
        Performance:RecordError()
        return nil
    end
    
    if Settings.Flag then
        RhyRu9.Flags[Settings.Flag] = result
    end
    
    return WrapElement(result, "Keybind", Tab, Settings)
end

-- ===== NOTIFICATION SYSTEM =====
function Window:Notify(NotificationSettings)
    NotificationSettings = Utility:ValidateTable(NotificationSettings, {})
    
    local content = NotificationSettings.Content or NotificationSettings.Message or "Notification"
    
    local Settings = {
        Title = Utility:ValidateString(NotificationSettings.Title, "RhyRu9"),
        Content = content,
        Duration = Utility:ValidateNumber(NotificationSettings.Duration, 1, 30, 3),
        Image = NotificationSettings.Image or NotificationSettings.Icon
    }
    
    local success = pcall(function()
        Rayfield:Notify(Settings)
    end)
    
    if not success then
        Logger:Error("Failed to send notification")
        Performance:RecordError()
    else
        EventSystem:Fire("NotificationSent", Settings)
    end
end

-- ===== THEME SYSTEM =====
function Window:SetTheme(ThemeName)
    ThemeName = Utility:ValidateString(ThemeName, "Default")
    
    if self.RayfieldWindow and self.RayfieldWindow.ModifyTheme then
        local success = pcall(function()
            self.RayfieldWindow.ModifyTheme(ThemeName)
        end)
        
        if success then
            self:Notify({
                Title = "Theme Changed",
                Content = "Theme set to: " .. ThemeName,
                Duration = 2
            })
            EventSystem:Fire("ThemeChanged", ThemeName)
        else
            Logger:Error("Failed to change theme")
            Performance:RecordError()
        end
    end
end

-- ===== PRESET SYSTEM =====
function Window:SavePreset(presetName)
    presetName = Utility:ValidateString(presetName, "Preset_" .. os.time())
    
    local preset = {
        Name = presetName,
        CreatedAt = Utility:Timestamp(),
        Flags = {}
    }
    
    for flagName, flagData in pairs(RhyRu9.Flags) do
        preset.Flags[flagName] = {
            CurrentValue = flagData.CurrentValue,
            CurrentKeybind = flagData.CurrentKeybind,
            CurrentOption = flagData.CurrentOption,
            Color = flagData.Color
        }
    end
    
    RhyRu9.Presets[presetName] = preset
    
    self:Notify({
        Title = "Preset Saved",
        Content = "Preset '" .. presetName .. "' saved successfully!",
        Duration = 2
    })
    
    Logger:Success("Preset saved: " .. presetName)
    EventSystem:Fire("PresetSaved", presetName)
end

function Window:LoadPreset(presetName)
    local preset = RhyRu9.Presets[presetName]
    
    if not preset then
        self:Notify({
            Title = "Preset Error",
            Content = "Preset '" .. presetName .. "' not found!",
            Duration = 2
        })
        Logger:Error("Preset not found: " .. presetName)
        return false
    end
    
    for flagName, flagData in pairs(preset.Flags) do
        local flag = RhyRu9.Flags[flagName]
        if flag then
            if flagData.CurrentValue ~= nil then
                flag:Set(flagData.CurrentValue)
            elseif flagData.CurrentKeybind then
                flag:Set(flagData.CurrentKeybind)
            elseif flagData.CurrentOption then
                flag:Set(flagData.CurrentOption)
            elseif flagData.Color then
                flag:Set(flagData.Color)
            end
        end
    end
    
    self:Notify({
        Title = "Preset Loaded",
        Content = "Preset '" .. presetName .. "' loaded successfully!",
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

-- ===== CONFIGURATION BACKUP =====
function Window:BackupConfiguration(backupName)
    backupName = backupName or "Backup_" .. os.date("%Y%m%d_%H%M%S")
    
    local backup = {
        Name = backupName,
        Timestamp = Utility:Timestamp(),
        Flags = Utility:DeepCopy(RhyRu9.Flags),
        Presets = Utility:DeepCopy(RhyRu9.Presets),
        WindowSettings = {
            Name = self.Name,
            Theme = self.CurrentTheme or "Default"
        }
    }
    
    if not _G.RhyRu9Backups then
        _G.RhyRu9Backups = {}
    end
    
    _G.RhyRu9Backups[backupName] = backup
    
    self:Notify({
        Title = "Backup Created",
        Content = "Configuration backed up as '" .. backupName .. "'",
        Duration = 2
    })
    
    Logger:Success("Backup created: " .. backupName)
    return backup
end

function Window:RestoreConfiguration(backupName)
    if not _G.RhyRu9Backups or not _G.RhyRu9Backups[backupName] then
        self:Notify({
            Title = "Restore Error",
            Content = "Backup '" .. backupName .. "' not found!",
            Duration = 2
        })
        Logger:Error("Backup not found: " .. backupName)
        return false
    end
    
    local backup = _G.RhyRu9Backups[backupName]
    
    -- Restore flags
    for flagName, flagData in pairs(backup.Flags) do
        if RhyRu9.Flags[flagName] then
            RhyRu9.Flags[flagName] = flagData
        end
    end
    
    -- Restore presets
    RhyRu9.Presets = Utility:DeepCopy(backup.Presets)
    
    self:Notify({
        Title = "Restore Complete",
        Content = "Configuration restored from '" .. backupName .. "'",
        Duration = 2
    })
    
    Logger:Success("Configuration restored: " .. backupName)
    EventSystem:Fire("ConfigurationRestored", backupName)
    return true
end

function Window:GetAllBackups()
    if not _G.RhyRu9Backups then return {} end
    
    local backups = {}
    for name, backup in pairs(_G.RhyRu9Backups) do
        table.insert(backups, {
            Name = name,
            Timestamp = backup.Timestamp,
            Date = os.date("%Y-%m-%d %H:%M:%S", backup.Timestamp)
        })
    end
    return backups
end

-- ===== ELEMENT SEARCH & MANAGEMENT =====
function Window:FindElement(Tab, name)
    for _, element in ipairs(Tab.Elements) do
        if element.Name == name then
            return element
        end
    end
    return nil
end

function Window:FindElementByID(id)
    for _, tab in ipairs(self.Tabs) do
        for _, element in ipairs(tab.Elements) do
            if element.ID == id then
                return element
            end
        end
    end
    return nil
end

function Window:SearchElements(query)
    query = string.lower(query)
    local results = {}
    
    for _, tab in ipairs(self.Tabs) do
        for _, element in ipairs(tab.Elements) do
            if string.find(string.lower(element.Name), query, 1, true) then
                table.insert(results, element)
            end
        end
    end
    
    return results
end

function Window:GetElementsByType(elementType)
    local results = {}
    
    for _, tab in ipairs(self.Tabs) do
        for _, element in ipairs(tab.Elements) do
            if element.Type == elementType then
                table.insert(results, element)
            end
        end
    end
    
    return results
end

function Window:ClearTabElements(Tab)
    Tab.Elements = {}
    Logger:Info("Cleared elements from tab: " .. Tab.Name)
    EventSystem:Fire("TabCleared", Tab)
end

-- ===== ELEMENT GROUPS =====
function Window:CreateGroup(groupName)
    if not self.Groups[groupName] then
        self.Groups[groupName] = {
            Name = groupName,
            Elements = {},
            Enabled = true
        }
        Logger:Success("Group created: " .. groupName)
    end
    return self.Groups[groupName]
end

function Window:AddToGroup(groupName, element)
    if not self.Groups[groupName] then
        self:CreateGroup(groupName)
    end
    
    table.insert(self.Groups[groupName].Elements, element)
    element.Group = groupName
    Logger:Info("Element added to group: " .. groupName)
end

function Window:EnableGroup(groupName)
    local group = self.Groups[groupName]
    if not group then return false end
    
    group.Enabled = true
    for _, element in ipairs(group.Elements) do
        if element.Enable then
            element:Enable()
        end
    end
    
    Logger:Info("Group enabled: " .. groupName)
    EventSystem:Fire("GroupEnabled", groupName)
    return true
end

function Window:DisableGroup(groupName)
    local group = self.Groups[groupName]
    if not group then return false end
    
    group.Enabled = false
    for _, element in ipairs(group.Elements) do
        if element.Disable then
            element:Disable()
        end
    end
    
    Logger:Info("Group disabled: " .. groupName)
    EventSystem:Fire("GroupDisabled", groupName)
    return true
end

function Window:ToggleGroup(groupName)
    local group = self.Groups[groupName]
    if not group then return false end
    
    if group.Enabled then
        return self:DisableGroup(groupName)
    else
        return self:EnableGroup(groupName)
    end
end

-- ===== BULK OPERATIONS =====
function Window:SetMultipleFlags(flagsTable)
    for flagName, value in pairs(flagsTable) do
        local flag = RhyRu9.Flags[flagName]
        if flag and flag.Set then
            flag:Set(value)
        end
    end
    
    Logger:Success("Set multiple flags: " .. #flagsTable)
    EventSystem:Fire("BulkFlagsSet", flagsTable)
end

function Window:GetMultipleFlags(flagNames)
    local results = {}
    
    for _, flagName in ipairs(flagNames) do
        local flag = RhyRu9.Flags[flagName]
        if flag then
            results[flagName] = flag.CurrentValue or flag.CurrentKeybind or flag.CurrentOption or flag.Color
        end
    end
    
    return results
end

function Window:ResetAllFlags()
    for _, flag in pairs(RhyRu9.Flags) do
        if flag.Set then
            if flag.CurrentValue ~= nil then
                flag:Set(false)
            elseif flag.CurrentKeybind then
                flag:Set("Q")
            elseif flag.CurrentOption then
                flag:Set({})
            end
        end
    end
    
    self:Notify({
        Title = "Flags Reset",
        Content = "All flags have been reset to default values!",
        Duration = 2
    })
    
    Logger:Success("All flags reset")
    EventSystem:Fire("AllFlagsReset")
end

-- ===== CHANGELOG SYSTEM =====
function Window:ShowChangelog(changelog)
    if type(changelog) == "table" then
        local changelogText = ""
        for version, changes in pairs(changelog) do
            changelogText = changelogText .. version .. ":\n"
            for _, change in ipairs(changes) do
                changelogText = changelogText .. "  • " .. change .. "\n"
            end
            changelogText = changelogText .. "\n"
        end
        
        self:Notify({
            Title = "Changelog",
            Content = changelogText,
            Duration = 10
        })
    elseif type(changelog) == "string" then
        self:Notify({
            Title = "Changelog",
            Content = changelog,
            Duration = 10
        })
    end
end

-- ===== AUTO-UPDATE CHECKER =====
function Window:CheckForUpdates(versionUrl, currentVersion)
    if not versionUrl or not currentVersion then
        Logger:Warn("Update check requires versionUrl and currentVersion")
        return
    end
    
    local success, result = pcall(function()
        local response = game:HttpGet(versionUrl)
        local latestVersion = response:match("%d+%.%d+%.%d+")
        
        if latestVersion and latestVersion ~= currentVersion then
            self:Notify({
                Title = "Update Available",
                Content = "New version " .. latestVersion .. " is available!\nCurrent: " .. currentVersion,
                Duration = 5,
                Image = 4335487866
            })
            
            Logger:Info("Update available: " .. latestVersion)
            EventSystem:Fire("UpdateAvailable", latestVersion, currentVersion)
            return true, latestVersion
        else
            Logger:Info("No updates available")
            return false, currentVersion
        end
    end)
    
    if not success then
        Logger:Error("Failed to check for updates: " .. tostring(result))
    end
    
    return false, currentVersion
end

-- ===== CONFIGURATION SYSTEM =====
function Window:LoadConfiguration()
    if self.RayfieldWindow and self.RayfieldWindow.LoadConfiguration then
        local success = pcall(function()
            self.RayfieldWindow:LoadConfiguration()
        end)
        
        if success then
            self:Notify({
                Title = "Configuration Loaded",
                Content = "Settings restored successfully!",
                Duration = 2
            })
            Logger:Success("Configuration loaded")
            EventSystem:Fire("ConfigurationLoaded")
        else
            Logger:Error("Failed to load configuration")
            Performance:RecordError()
        end
    end
end

function Window:SaveConfiguration()
    if self.RayfieldWindow and self.RayfieldWindow.SaveConfiguration then
        local success = pcall(function()
            self.RayfieldWindow:SaveConfiguration()
        end)
        
        if success then
            self:Notify({
                Title = "Configuration Saved",
                Content = "Settings saved successfully!",
                Duration = 2
            })
            Logger:Success("Configuration saved")
            EventSystem:Fire("ConfigurationSaved")
        end
    end
end

-- ===== VISIBILITY CONTROL =====
function Window:SetVisibility(Visible)
    if self.RayfieldWindow and self.RayfieldWindow.SetVisibility then
        pcall(function()
            self.RayfieldWindow:SetVisibility(Utility:ValidateBoolean(Visible, true))
        end)
        
        EventSystem:Fire("VisibilityChanged", Visible)
    end
end

function Window:IsVisible()
    if self.RayfieldWindow and self.RayfieldWindow.IsVisible then
        return self.RayfieldWindow:IsVisible()
    end
    return false
end

function Window:Toggle()
    self:SetVisibility(not self:IsVisible())
end

-- ===== DESTROY WINDOW =====
function Window:Destroy()
    if self.RayfieldWindow and self.RayfieldWindow.Destroy then
        pcall(function()
            self.RayfieldWindow:Destroy()
        end)
    end
    
    -- Remove from windows table
    for i, win in ipairs(RhyRu9.Windows) do
        if win == self then
            table.remove(RhyRu9.Windows, i)
            break
        end
    end
    
    Logger:Info("Window destroyed: " .. self.Name)
    EventSystem:Fire("WindowDestroyed", self)
end

-- ===== PERFORMANCE MONITORING =====
function Window:GetPerformanceStats()
    return Performance:GetStats()
end

function Window:ShowPerformanceStats()
    local stats = self:GetPerformanceStats()
    
    local message = string.format(
        "Elements: %d\nCallbacks: %d\nErrors: %d\nUptime: %.1fs\nWindows: %d",
        stats.ElementsCreated,
        stats.CallbacksFired,
        stats.ErrorsOccurred,
        stats.Uptime,
        stats.Windows
    )
    
    self:Notify({
        Title = "Performance Stats",
        Content = message,
        Duration = 5,
        Image = 4483362458
    })
end

function Window:ResetPerformanceStats()
    Performance.Stats = {
        ElementsCreated = 0,
        CallbacksFired = 0,
        ErrorsOccurred = 0,
        StartTime = tick()
    }
    
    Logger:Success("Performance stats reset")
end

-- ===== GLOBAL FUNCTIONS =====
function RhyRu9:GetFlag(FlagName)
    return self.Flags[FlagName]
end

function RhyRu9:GetAllFlags()
    return self.Flags
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

-- ===== EVENT MANAGEMENT =====
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
            Connections = #eventData.Callbacks,
            Fired = eventData.Fired
        })
    end
    return events
end

-- ===== UTILITY EXPORTS =====
function RhyRu9:ExportConfiguration()
    local export = {
        Version = self.Version,
        Timestamp = Utility:Timestamp(),
        Flags = {},
        Presets = self.Presets
    }
    
    for flagName, flagData in pairs(self.Flags) do
        export.Flags[flagName] = {
            CurrentValue = flagData.CurrentValue,
            CurrentKeybind = flagData.CurrentKeybind,
            CurrentOption = flagData.CurrentOption,
            Color = flagData.Color
        }
    end
    
    return HttpService:JSONEncode(export)
end

function RhyRu9:ImportConfiguration(jsonString)
    local success, data = pcall(function()
        return HttpService:JSONDecode(jsonString)
    end)
    
    if not success then
        Logger:Error("Failed to import configuration: Invalid JSON")
        return false
    end
    
    if data.Flags then
        for flagName, flagData in pairs(data.Flags) do
            local flag = self.Flags[flagName]
            if flag and flag.Set then
                if flagData.CurrentValue ~= nil then
                    flag:Set(flagData.CurrentValue)
                elseif flagData.CurrentKeybind then
                    flag:Set(flagData.CurrentKeybind)
                elseif flagData.CurrentOption then
                    flag:Set(flagData.CurrentOption)
                elseif flagData.Color then
                    flag:Set(flagData.Color)
                end
            end
        end
    end
    
    if data.Presets then
        self.Presets = data.Presets
    end
    
    Logger:Success("Configuration imported")
    return true
end

-- ===== QUICK ACTIONS =====
function RhyRu9:QuickToggle(flagName)
    local flag = self.Flags[flagName]
    if flag and flag.CurrentValue ~= nil and flag.Set then
        flag:Set(not flag.CurrentValue)
        return flag.CurrentValue
    end
    return nil
end

function RhyRu9:QuickSetAll(flagNames, value)
    for _, flagName in ipairs(flagNames) do
        local flag = self.Flags[flagName]
        if flag and flag.Set then
            flag:Set(value)
        end
    end
    
    Logger:Success("Quick set " .. #flagNames .. " flags to " .. tostring(value))
end

-- ===== STATISTICS =====
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
        Performance = Performance:GetStats()
    }
end

function RhyRu9:PrintStatistics()
    local stats = self:GetStatistics()
    
    print("╔══════════════════════════════════════════╗")
    print("║        RhyRu9 UI Library Stats          ║")
    print("╠══════════════════════════════════════════╣")
    print(string.format("║  Version: %-27s║", stats.Version))
    print(string.format("║  Windows: %-27d║", stats.Windows))
    print(string.format("║  Flags: %-29d║", stats.TotalFlags))
    print(string.format("║  Presets: %-27d║", stats.TotalPresets))
    print(string.format("║  Events: %-28d║", stats.TotalEvents))
    print(string.format("║  Elements Created: %-18d║", stats.Performance.ElementsCreated))
    print(string.format("║  Callbacks Fired: %-19d║", stats.Performance.CallbacksFired))
    print(string.format("║  Errors: %-28d║", stats.Performance.ErrorsOccurred))
    print(string.format("║  Uptime: %-24.1fs║", stats.Performance.Uptime))
    print("╚══════════════════════════════════════════╝")
end

-- ===== INITIALIZATION =====
EventSystem:Create("WindowCreated")
EventSystem:Create("TabCreated")
EventSystem:Create("ElementCreated")
EventSystem:Create("ButtonClicked")
EventSystem:Create("ToggleChanged")
EventSystem:Create("SliderChanged")
EventSystem:Create("InputChanged")
EventSystem:Create("DropdownChanged")
EventSystem:Create("ColorChanged")
EventSystem:Create("KeybindPressed")
EventSystem:Create("PresetSaved")
EventSystem:Create("PresetLoaded")
EventSystem:Create("ConfigurationLoaded")
EventSystem:Create("ConfigurationSaved")
EventSystem:Create("ThemeChanged")
EventSystem:Create("UpdateAvailable")
EventSystem:Create("TabHidden")
EventSystem:Create("TabShown")
EventSystem:Create("GroupEnabled")
EventSystem:Create("GroupDisabled")
EventSystem:Create("AllFlagsReset")
EventSystem:Create("BulkFlagsSet")
EventSystem:Create("TabCleared")
EventSystem:Create("WindowDestroyed")
EventSystem:Create("VisibilityChanged")
EventSystem:Create("NotificationSent")

Logger:Success("RhyRu9 UI Library v" .. RhyRu9.Version .. " loaded!")

-- ===== EXPORT =====
return RhyRu9
