-- RhyRu9 FISH IT - FIXED VERSION WITH CORRECT RETRY LOGIC
-- DEVELOPER BY RhyRu9
-- Fixed: Charge Rod Retry (15x), 3 Detik Wait, Full Reset Logic
-- Updated: 17 Oct 2025

print("Loading RhyRu9 FISH IT - FIXED VERSION...")

if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

-- Rayfield Setup
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "RhyRu9 FISH IT - FIXED",
    LoadingTitle = "RhyRu9 FISH IT - FIXED VERSION",
    LoadingSubtitle = "DEVELOPER BY RhyRu9",
    ConfigurationSaving = { Enabled = false },
})

-- Configuration
local Config = {
    AutoFishingV1 = false,
    PerfectCatch = false,
    FastCatch = true,
    CatchDelay = 0.05,
    AutoSell = false,
    AntiAFK = false,
    TeleportEnabled = false,
    TeleportToPlayerEnabled = false,
    SelectedIsland = nil,
    WalkSpeed = 16,
    JumpPower = 50,
    
    -- Telegram Config
    Hooked = {
        Enabled = false,
        BotToken = "",
        ChatID = "",
        TargetRarities = {}
    }
}

-- Fish Data
local fishFile = "FISHES_DATA.json"
local fishData = {}
local fishLookup = {}

local tierToRarity = {
    [1] = "COMMON",
    [2] = "UNCOMMON", 
    [3] = "RARE",
    [4] = "EPIC",
    [5] = "LEGENDARY",
    [6] = "MYTHIC",
    [7] = "SECRET"
}

-- Error Tracking
local ErrorCount = 0
local MaxErrors = 3

-- Helper Functions
local function normalizeName(name)
    if not name then return "" end
    return name:lower():gsub("%s+", ""):gsub("[^%w]", "")
end

-- Remotes Path
local net = ReplicatedStorage:WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0")
    :WaitForChild("net")

local function GetRemote(name)
    return net:FindFirstChild(name)
end

-- Remotes
local EquipTool = GetRemote("RE/EquipToolFromHotbar")
local ChargeRod = GetRemote("RF/ChargeFishingRod")
local StartMini = GetRemote("RF/RequestFishingMinigameStarted")
local FinishFish = GetRemote("RE/FishingCompleted")
local SellRemote = GetRemote("RF/SellAllItems")
local FishCaught = GetRemote("RE/FishCaught")
local VirtualUser = game:GetService("VirtualUser")

-- Load Fish Data
if isfile(fishFile) then
    local success, decoded = pcall(function()
        local raw = readfile(fishFile)
        return HttpService:JSONDecode(raw)
    end)
    
    if success and decoded then
        fishData = decoded
        print("[OK] Fish data loaded from " .. fishFile)
        
        fishLookup = {}
        for tier = 1, 7 do
            local tierKey = "Tier" .. tier
            if fishData[tierKey] then
                for _, fish in ipairs(fishData[tierKey]) do
                    if fish.Name then
                        local normalizedName = normalizeName(fish.Name)
                        fishLookup[normalizedName] = fish
                        fishLookup[fish.Name:lower()] = fish
                        if fish.Id then
                            fishLookup["id_" .. tostring(fish.Id)] = fish
                        end
                    end
                end
            end
        end
    end
end

-- ===== TELEGRAM BOT =====
local Hooked = {}

function Hooked:SendTelegramMessage(fishInfo)
    if not Config.Hooked.Enabled then return end
    
    if Config.Hooked.BotToken == "" or Config.Hooked.ChatID == "" then
        warn("[TELEGRAM] Bot Token or Chat ID not set!")
        return
    end
    
    if not fishInfo.Tier then
        warn("[TELEGRAM] Missing fish tier data!")
        return
    end
    
    local fishRarity = tierToRarity[fishInfo.Tier] or "UNKNOWN"
    
    if #Config.Hooked.TargetRarities > 0 then
        local shouldSend = false
        
        for _, targetRarity in ipairs(Config.Hooked.TargetRarities) do
            local normalizedTarget = string.upper(tostring(targetRarity)):gsub("%s+", "")
            local normalizedFish = string.upper(tostring(fishRarity)):gsub("%s+", "")
            
            if normalizedFish == normalizedTarget then
                shouldSend = true
                break
            end
        end
        
        if not shouldSend then
            return
        end
    end
    
    print("[TELEGRAM] Sending notification for " .. (fishInfo.Name or "Unknown"))
    
    local message = self:FormatTelegramMessage(fishInfo)
    
    local success, result = pcall(function()
        local telegramURL = "https://api.telegram.org/bot" .. Config.Hooked.BotToken .. "/sendMessage"
        local data = {
            chat_id = Config.Hooked.ChatID,
            text = message,
            parse_mode = "Markdown"
        }
        
        local jsonData = HttpService:JSONEncode(data)
        
        if http_request then
            return http_request({
                Url = telegramURL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = jsonData
            })
        elseif syn and syn.request then
            return syn.request({
                Url = telegramURL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = jsonData
            })
        else
            return HttpService:PostAsync(telegramURL, jsonData)
        end
    end)
    
    if success then
        print("[TELEGRAM] Notification sent!")
    else
        warn("[TELEGRAM] Failed: " .. tostring(result))
    end
end

function Hooked:FormatTelegramMessage(fishInfo)
    local fishRarity = tierToRarity[fishInfo.Tier or 1] or "UNKNOWN"
    local chancePercent = (fishInfo.Chance or 0) * 100
    local playerName = LocalPlayer.Name
    
    local message = "```\n"
    message = message .. "===== RhyRu9 FISH IT =====\n"
    message = message .. "Player: " .. playerName .. "\n"
    message = message .. "Fish: " .. (fishInfo.Name or "Unknown") .. "\n"
    message = message .. "Rarity: " .. fishRarity .. "\n"
    message = message .. "Tier: " .. tostring(fishInfo.Tier or 1) .. "\n"
    
    if fishInfo.Chance and chancePercent > 0 then
        message = message .. "Chance: " .. string.format("%.6f%%", chancePercent) .. "\n"
    end
    
    if fishInfo.SellPrice then
        message = message .. "Value: " .. tostring(fishInfo.SellPrice) .. " COINS\n"
    end
    
    message = message .. "```"
    
    return message
end

-- Fish Catch Listener
local lastCatchUID = nil

local function FindFishData(fishName, fishTier, fishId)
    local fishInfo = nil
    
    if fishName and fishName ~= "Unknown" then
        fishInfo = fishLookup[normalizeName(fishName)] or fishLookup[fishName:lower()]
    end
    
    if not fishInfo and fishId then
        fishInfo = fishLookup["id_" .. tostring(fishId)]
    end
    
    if not fishInfo and fishTier then
        local tierKey = "Tier" .. fishTier
        if fishData[tierKey] then
            for _, fish in ipairs(fishData[tierKey]) do
                if fish.Name == fishName or normalizeName(fish.Name) == normalizeName(fishName) then
                    fishInfo = fish
                    break
                end
            end
        end
    end
    
    return fishInfo
end

if FishCaught then
    FishCaught.OnClientEvent:Connect(function(data)
        if not data then return end

        local fishName = "Unknown"
        local fishTier = 1
        local fishId = nil
        local fishChance = 0
        local fishPrice = 0
        
        if type(data) == "string" then
            fishName = data
        elseif type(data) == "table" then
            fishName = data.Name or "Unknown"
            fishTier = data.Tier or 1
            fishId = data.Id
            fishChance = data.Chance or 0
            fishPrice = data.SellPrice or 0
        end
        
        local uniqueID = fishName .. "_" .. tostring(fishTier) .. "_" .. tostring(tick())
        
        if uniqueID == lastCatchUID then
            return
        end
        lastCatchUID = uniqueID

        local fishInfo = FindFishData(fishName, fishTier, fishId)
        
        if not fishInfo then
            fishInfo = {
                Name = fishName,
                Tier = fishTier,
                Id = fishId or "?",
                Chance = fishChance,
                SellPrice = fishPrice
            }
        end
        
        if not fishInfo.Tier then
            fishInfo.Tier = fishTier
        end
        
        local tier = fishInfo.Tier
        local rarity = tierToRarity[tier] or "UNKNOWN"
        local sellPrice = fishInfo.SellPrice or 0
        local chance = fishInfo.Chance or 0
        
        local chanceDisplay = chance > 0 and string.format(" (%.6f%%)", chance * 100) or ""
        print(string.format("[CAUGHT] %s | Rarity: %s | Price: %s coins%s",
            fishName, rarity, tostring(sellPrice), chanceDisplay))
        
        Hooked:SendTelegramMessage(fishInfo)
        ErrorCount = 0
    end)
else
    warn("[ERROR] FishCaught remote not found!")
end

-- ===== PERFECT CATCH =====
local PerfectCatchActive = false

local function TogglePerfectCatch(enabled)
    Config.PerfectCatch = enabled
    PerfectCatchActive = enabled
    
    if enabled then
        local mt = getrawmetatable(game)
        if not mt then return end
        setreadonly(mt, false)
        local old = mt.__namecall
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "InvokeServer" and self == StartMini then
                if PerfectCatchActive and not Config.AutoFishingV1 then
                    return old(self, -1.233184814453125, 0.9945034885633273)
                end
            end
            return old(self, ...)
        end)
        setreadonly(mt, true)
        
        Rayfield:Notify({
            Title = "Perfect Catch",
            Content = "Enabled!",
            Duration = 2
        })
    end
end

-- ===== FULL RESET FUNCTION =====
local function FullReset()
    print("[RESET] Melakukan full reset semua state...")
    ErrorCount = 0
    task.wait(3)
    print("[RESET] State bersih, siap memancing lagi")
end

-- ===== AUTO FISHING V1 =====
local FishingActive = false

local function AutoFishingV1()
    task.spawn(function()
        print("[AUTO FISHING] Started - Correct Retry Logic")
        
        while Config.AutoFishingV1 do
            FishingActive = true
            
            local success, err = pcall(function()
                if not LocalPlayer.Character or not HumanoidRootPart then
                    repeat task.wait(0.5) until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    Character = LocalPlayer.Character
                    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
                end

                -- Step 1: EQUIP TOOL
                local equipSuccess = false
                for i = 1, 3 do
                    local ok = pcall(function()
                        EquipTool:FireServer(1)
                    end)
                    if ok then
                        equipSuccess = true
                        print("[EQUIP] Success")
                        break
                    end
                    task.wait(0.2)
                end
                
                if not equipSuccess then
                    ErrorCount = ErrorCount + 1
                    print("[ERROR] Equip gagal (" .. ErrorCount .. "/" .. MaxErrors .. ")")
                    if ErrorCount >= MaxErrors then
                        FullReset()
                    end
                    task.wait(1)
                    return
                end
                
                task.wait(0.3)

                -- Step 2: CHARGE ROD (AGGRESSIVE RETRY - 15 attempts)
                local chargeSuccess = false
                local chargeAttempts = 0
                
                while chargeAttempts < 15 and not chargeSuccess do
                    chargeAttempts = chargeAttempts + 1
                    
                    local ok, result = pcall(function()
                        return ChargeRod:InvokeServer(tick())
                    end)
                    
                    if ok and result then
                        chargeSuccess = true
                        print("[CHARGE] Success (attempt " .. chargeAttempts .. ")")
                        break
                    end
                    
                    print("[CHARGE] Retry " .. chargeAttempts .. "/15...")
                    task.wait(0.15)
                end
                
                if not chargeSuccess then
                    ErrorCount = ErrorCount + 1
                    print("[ERROR] Charge Rod gagal (" .. ErrorCount .. "/" .. MaxErrors .. ") - CRITICAL!")
                    if ErrorCount >= MaxErrors then
                        print("[RESET] Charge Rod error terlalu banyak!")
                        FullReset()
                    end
                    task.wait(2)
                    return
                end

                task.wait(0.3)

                -- Step 3: START MINIGAME (PERFECT CATCH)
                local startSuccess = false
                for i = 1, 5 do
                    local ok = pcall(function()
                        return StartMini:InvokeServer(-1.233184814453125, 0.9945034885633273)
                    end)
                    if ok then
                        startSuccess = true
                        print("[START] Minigame started")
                        break
                    end
                    task.wait(0.1)
                end
                
                if not startSuccess then
                    ErrorCount = ErrorCount + 1
                    print("[ERROR] Start minigame gagal (" .. ErrorCount .. "/" .. MaxErrors .. ")")
                    if ErrorCount >= MaxErrors then
                        FullReset()
                    end
                    task.wait(1)
                    return
                end

                -- Step 4: WAIT 3 DETIK UNTUK CATCH
                print("[WAIT] Menunggu 3 detik untuk catch...")
                task.wait(3)

                -- Step 5: FINISH FISHING
                local finishSuccess = false
                for i = 1, 3 do
                    local ok = pcall(function()
                        FinishFish:FireServer()
                    end)
                    if ok then
                        finishSuccess = true
                        print("[FINISH] Fish caught!")
                        break
                    end
                    task.wait(0.1)
                end
                
                if not finishSuccess then
                    ErrorCount = ErrorCount + 1
                    print("[ERROR] Finish gagal (" .. ErrorCount .. "/" .. MaxErrors .. ")")
                    if ErrorCount >= MaxErrors then
                        FullReset()
                    end
                    task.wait(1)
                    return
                end
                
                -- SUCCESS - RESET ERROR COUNTER
                ErrorCount = 0
                task.wait(0.2)
            end)

            if not success then
                ErrorCount = ErrorCount + 1
                warn("[ERROR] Lua error (" .. ErrorCount .. "/" .. MaxErrors .. "): " .. tostring(err))
                
                if ErrorCount >= MaxErrors then
                    print("[RESET] Terlalu banyak error!")
                    FullReset()
                else
                    task.wait(1)
                end
            end
        end
        
        FishingActive = false
        ErrorCount = 0
        print("[AUTO FISHING] Stopped")
    end)
end

-- ===== AUTO SELL =====
local function AutoSell()
    task.spawn(function()
        while Config.AutoSell do
            pcall(function()
                SellRemote:InvokeServer()
            end)
            task.wait(10)
        end
    end)
end

-- ===== ANTI AFK =====
local function AntiAFK()
    task.spawn(function()
        print("[ANTI AFK] Started")
        while Config.AntiAFK do
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
            task.wait(30)
        end
        print("[ANTI AFK] Stopped")
    end)
end

-- ===== TELEPORT SYSTEM =====
local IslandsData = {
    {Name = "Fisherman Island", Position = Vector3.new(92, 9, 2768)},
    {Name = "Arrow Lever", Position = Vector3.new(898, 8, -363)},
    {Name = "Sisyphus Statue", Position = Vector3.new(-3740, -136, -1013)},
    {Name = "Ancient Jungle", Position = Vector3.new(1481, 11, -302)},
    {Name = "Weather Machine", Position = Vector3.new(-1519, 2, 1908)},
    {Name = "Coral Refs", Position = Vector3.new(-3105, 6, 2218)},
    {Name = "Tropical Island", Position = Vector3.new(-2110, 53, 3649)},
    {Name = "Kohana", Position = Vector3.new(-662, 3, 714)},
    {Name = "Esoteric Island", Position = Vector3.new(2035, 27, 1386)},
    {Name = "Diamond Lever", Position = Vector3.new(1818, 8, -285)},
    {Name = "Underground Cellar", Position = Vector3.new(2098, -92, -703)},
    {Name = "Volcano", Position = Vector3.new(-631, 54, 194)},
    {Name = "Enchant Room", Position = Vector3.new(3255, -1302, 1371)},
    {Name = "Lost Isle", Position = Vector3.new(-3717, 5, -1079)},
    {Name = "Sacred Temple", Position = Vector3.new(1475, -22, -630)},
    {Name = "Creater Island", Position = Vector3.new(981, 41, 5080)},
    {Name = "Double Enchant Room", Position = Vector3.new(1480, 127, -590)},
    {Name = "Treassure Room", Position = Vector3.new(-3599, -276, -1642)},
    {Name = "Crescent Lever", Position = Vector3.new(1419, 31, 78)},
    {Name = "Hourglass Diamond Lever", Position = Vector3.new(1484, 8, -862)},
    {Name = "Snow Island", Position = Vector3.new(1627, 4, 3288)}
}

local function TeleportToIsland(index)
    if not Config.TeleportEnabled then
        Rayfield:Notify({
            Title = "Teleport Disabled",
            Content = "Enable teleport first!",
            Duration = 2
        })
        return
    end
    
    if IslandsData[index] and HumanoidRootPart then
        HumanoidRootPart.CFrame = CFrame.new(IslandsData[index].Position)
        Rayfield:Notify({
            Title = "Teleported",
            Content = "To " .. IslandsData[index].Name,
            Duration = 2
        })
    end
end

-- ===== UI CREATION =====
local function CreateUI()
    local Tab1 = Window:CreateTab("Fishing", 4483362458)
    
    Tab1:CreateSection("Auto Fishing")
    
    Tab1:CreateToggle({
        Name = "Auto Fishing",
        CurrentValue = false,
        Callback = function(Value)
            Config.AutoFishingV1 = Value
            if Value then
                AutoFishingV1()
                Rayfield:Notify({
                    Title = "Auto Fishing Started",
                    Content = "Running with correct retry logic!",
                    Duration = 3
                })
            end
        end
    })
    
    Tab1:CreateSlider({
        Name = "Catch Speed",
        Range = {0.01, 1},
        Increment = 0.01,
        CurrentValue = 0.05,
        Callback = function(Value)
            Config.CatchDelay = Value
        end
    })
    
    Tab1:CreateToggle({
        Name = "Perfect Catch",
        CurrentValue = false,
        Callback = function(Value)
            TogglePerfectCatch(Value)
        end
    })
    
    Tab1:CreateToggle({
        Name = "Auto Sell",
        CurrentValue = false,
        Callback = function(Value)
            Config.AutoSell = Value
            if Value then AutoSell() end
        end
    })
    
    Tab1:CreateToggle({
        Name = "Anti AFK",
        CurrentValue = false,
        Callback = function(Value)
            Config.AntiAFK = Value
            if Value then AntiAFK() end
        end
    })
    
    local Tab2 = Window:CreateTab("Teleport", 4483362458)
    
    Tab2:CreateSection("Teleport Settings")
    
    Tab2:CreateToggle({
        Name = "Enable Teleport",
        CurrentValue = false,
        Callback = function(Value)
            Config.TeleportEnabled = Value
        end
    })
    
    local IslandOptions = {}
    for i, island in ipairs(IslandsData) do
        table.insert(IslandOptions, string.format("%d. %s", i, island.Name))
    end
    
    local IslandDrop = Tab2:CreateDropdown({
        Name = "Select Island",
        Options = IslandOptions,
        CurrentOption = {IslandOptions[1]},
    })
    
    Tab2:CreateButton({
        Name = "Teleport",
        Callback = function()
            local selected = IslandDrop.CurrentOption[1]
            local index = tonumber(selected:match("^(%d+)%."))
            if index then
                TeleportToIsland(index)
            end
        end
    })
    
    local Tab3 = Window:CreateTab("Utility", 4483362458)
    
    Tab3:CreateSlider({
        Name = "Walk Speed",
        Range = {16, 500},
        Increment = 1,
        CurrentValue = 16,
        Callback = function(Value)
            Config.WalkSpeed = Value
            if Humanoid then
                Humanoid.WalkSpeed = Value
            end
        end
    })
    
    Tab3:CreateSlider({
        Name = "Jump Power",
        Range = {50, 500},
        Increment = 5,
        CurrentValue = 50,
        Callback = function(Value)
            Config.JumpPower = Value
            if Humanoid then
                Humanoid.JumpPower = Value
            end
        end
    })
    
    local Tab4 = Window:CreateTab("Info", 4483362458)
    
    Tab4:CreateParagraph({
        Title = "RhyRu9 FISH IT",
        Content = "Charge Rod: 15x Retry\nWait: 3 Detik\nFull Reset: 3x Error\nVersion: Corrected"
    })
    
    Rayfield:Notify({
        Title = "RhyRu9 FISH IT",
        Content = "Loaded with correct retry logic!",
        Duration = 3
    })
end

-- Character Respawn Handler
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
    Humanoid = char:WaitForChild("Humanoid")
    
    task.wait(2)
    
    if Humanoid then
        Humanoid.WalkSpeed = Config.WalkSpeed
        Humanoid.JumpPower = Config.JumpPower
    end
    
    if Config.AutoFishingV1 then
        task.wait(2)
        AutoFishingV1()
    end
    
    if Config.AutoSell then
        task.wait(1)
        AutoSell()
    end
    
    if Config.AntiAFK then
        task.wait(1)
        AntiAFK()
    end
end)

-- Main Execution
local success, err = pcall(function()
    CreateUI()
end)

if success then
    print("=======================================")
    print("  RhyRu9 FISH IT - CORRECT LOGIC")
    print("  Charge Rod: 15x Retry")
    print("  Wait: 3 Detik untuk Catch")
    print("  Full Reset: 3x Error")
    print("  Status: OK")
    print("=======================================")
else
    warn("ERROR: " .. tostring(err))
end
