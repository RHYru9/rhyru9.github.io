-- RhyRu9 FISH IT - FIXED VERSION WITH AUTO RETRY (NO MENU)
-- DEVELOPER BY RhyRu9
-- Auto Retry: Error Detection + Perfect Catch Reset
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
    
    -- Auto Retry Config
    AutoRetryEnabled = true,
    ErrorThreshold = 5,
    ResetInterval = 1800, -- 30 menit
    
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

-- Auto Retry Tracking
local ErrorCount = 0
local LastErrorReset = tick()
local SessionStartTime = tick()

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
        print("[✅] Fish data loaded from " .. fishFile)
        
        -- Build lookup table
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

-- ===== TELEGRAM BOT (FIXED) =====
local Hooked = {}

function Hooked:SendTelegramMessage(fishInfo)
    if not Config.Hooked.Enabled then return end
    
    if Config.Hooked.BotToken == "" or Config.Hooked.ChatID == "" then
        warn("[❌ TELEGRAM] Bot Token or Chat ID not set!")
        return
    end
    
    if not fishInfo.Tier then
        warn("[❌ TELEGRAM] Missing fish tier data!")
        return
    end
    
    local fishRarity = tierToRarity[fishInfo.Tier] or "UNKNOWN"
    
    -- Check if rarity matches target
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
    
    print("[✅ TELEGRAM] Sending notification for " .. (fishInfo.Name or "Unknown"))
    
    -- Format message
    local message = self:FormatTelegramMessage(fishInfo)
    
    -- Send to Telegram
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
        print("[✅ TELEGRAM] Notification sent!")
    else
        warn("[❌ TELEGRAM] Failed: " .. tostring(result))
    end
end

function Hooked:FormatTelegramMessage(fishInfo)
    local fishRarity = tierToRarity[fishInfo.Tier or 1] or "UNKNOWN"
    local chancePercent = (fishInfo.Chance or 0) * 100
    local playerName = LocalPlayer.Name
    
    local message = "```\n"
    message = message .. "┌─────────────────────────────\n"
    message = message .. "│  🎣 RhyRu9 FISH IT - CAUGHT!\n"
    message = message .. "├─────────────────────────────\n"
    message = message .. "│  👤 PLAYER: " .. playerName .. "\n"
    message = message .. "│  🐟 FISH: " .. (fishInfo.Name or "Unknown") .. "\n"
    message = message .. "│  ⭐ RARITY: " .. fishRarity .. "\n"
    message = message .. "│  📊 TIER: " .. tostring(fishInfo.Tier or 1) .. "\n"
    
    if fishInfo.Chance and chancePercent > 0 then
        if chancePercent < 0.001 then
            message = message .. "│  🎲 CHANCE: " .. string.format("%.8f%%", chancePercent) .. "\n"
        else
            message = message .. "│  🎲 CHANCE: " .. string.format("%.6f%%", chancePercent) .. "\n"
        end
    end
    
    if fishInfo.SellPrice then
        message = message .. "│  💰 VALUE: " .. tostring(fishInfo.SellPrice) .. " COINS\n"
    end
    
    message = message .. "└─────────────────────────────\n"
    message = message .. "```"
    
    return message
end

-- Fish Catch Listener
local lastCatchUID = nil

local function FindFishData(fishName, fishTier, fishId)
    local fishInfo = nil
    
    if fishName and fishName ~= "Unknown" then
        fishInfo = fishLookup[normalizeName(fishName)] or
                  fishLookup[fishName:lower()]
    end
    
    if not fishInfo and fishId then
        fishInfo = fishLookup["id_" .. tostring(fishId)]
    end
    
    if not fishInfo and fishTier then
        local tierKey = "Tier" .. fishTier
        if fishData[tierKey] then
            for _, fish in ipairs(fishData[tierKey]) do
                if fish.Name == fishName or 
                   normalizeName(fish.Name) == normalizeName(fishName) then
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
        print(string.format("[🎣 CAUGHT] %s | Rarity: %s | Price: %s coins%s",
            fishName, rarity, tostring(sellPrice), chanceDisplay))
        
        Hooked:SendTelegramMessage(fishInfo)
        ErrorCount = 0
    end)
else
    warn("[❌] FishCaught remote not found!")
end

-- ===== PERFECT CATCH (FASTER) =====
local PerfectCatchActive = false

local function ResetPerfectCatch()
    print("[⚠️  AUTO RETRY] Mendeteksi ERROR! Reset perfect catch values...")
    PerfectCatchActive = false
    task.wait(1)
    PerfectCatchActive = true
    print("[✅ AUTO RETRY] Perfect catch direset & diaktifkan kembali")
    
    Rayfield:Notify({
        Title = "⚠️ Auto Retry Triggered",
        Content = "Perfect catch values reset karena error detected",
        Duration = 3
    })
end

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
            Content = "Enabled with FASTER speed!",
            Duration = 2
        })
    end
end

-- ===== AUTO FISHING V1 (FASTER CATCH) WITH AUTO RETRY =====
local FishingActive = false

local function AutoFishingV1()
    task.spawn(function()
        print("[AUTO FISHING] Started - FAST MODE with AUTO RETRY")
        
        while Config.AutoFishingV1 do
            FishingActive = true
            
            local sessionTime = tick() - SessionStartTime
            
            -- Check if need reset after 30 minutes
            if sessionTime > Config.ResetInterval and Config.AutoRetryEnabled then
                print("[⚠️  AUTO RETRY] 30 menit runtime tercapai! Reset perfect catch...")
                ResetPerfectCatch()
                SessionStartTime = tick()
            end
            
            local success, err = pcall(function()
                if not LocalPlayer.Character or not HumanoidRootPart then
                    repeat task.wait(0.5) until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    Character = LocalPlayer.Character
                    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
                end

                -- Equip tool
                local equipOk = pcall(function()
                    EquipTool:FireServer(1)
                end)
                
                if not equipOk then
                    ErrorCount = ErrorCount + 1
                    print("[❌] Gagal equip tool (Error: " .. ErrorCount .. "/" .. Config.ErrorThreshold .. ")")
                    
                    if ErrorCount >= Config.ErrorThreshold and Config.AutoRetryEnabled then
                        ResetPerfectCatch()
                        ErrorCount = 0
                    end
                    task.wait(0.5)
                    return
                end
                
                task.wait(0.1)

                -- Charge rod (AGGRESSIVE RETRY)
                local charged = false
                for attempt = 1, 10 do
                    local ok, result = pcall(function()
                        return ChargeRod:InvokeServer(tick())
                    end)
                    if ok and result then 
                        charged = true 
                        print("[✅] Charge rod OK (attempt " .. attempt .. ")")
                        break 
                    end
                    print("[⏳] Retry charge rod... (attempt " .. attempt .. "/10)")
                    task.wait(0.1)
                end
                
                if not charged then
                    -- Fallback: Try one more time dengan delay lebih lama
                    task.wait(0.5)
                    local ok, result = pcall(function()
                        return ChargeRod:InvokeServer(tick())
                    end)
                    if ok and result then
                        charged = true
                        print("[✅] Charge rod OK (fallback)")
                    end
                end
                
                if not charged then
                    ErrorCount = ErrorCount + 1
                    print("[❌] Gagal charge rod (Error: " .. ErrorCount .. "/" .. Config.ErrorThreshold .. ")")
                    
                    if ErrorCount >= Config.ErrorThreshold and Config.AutoRetryEnabled then
                        print("[⚠️  CHARGE ROD] Terlalu banyak error! Reset perfect catch...")
                        ResetPerfectCatch()
                        ErrorCount = 0
                    end
                    task.wait(1)
                    return
                end

                task.wait(0.1)

                -- Start minigame with perfect catch
                local started = false
                for attempt = 1, 3 do
                    local ok, result = pcall(function()
                        return StartMini:InvokeServer(-1.233184814453125, 0.9945034885633273)
                    end)
                    if ok then 
                        started = true 
                        break 
                    end
                    task.wait(0.05)
                end
                
                if not started then
                    ErrorCount = ErrorCount + 1
                    print("[❌] Gagal start minigame (Error: " .. ErrorCount .. "/" .. Config.ErrorThreshold .. ")")
                    
                    if ErrorCount >= Config.ErrorThreshold and Config.AutoRetryEnabled then
                        ResetPerfectCatch()
                        ErrorCount = 0
                    end
                    task.wait(0.5)
                    return
                end

                -- FASTER CATCH: Reduced delay
                task.wait(Config.CatchDelay)

                -- Finish fishing
                local finishOk = pcall(function()
                    FinishFish:FireServer()
                end)
                
                if not finishOk then
                    ErrorCount = ErrorCount + 1
                    print("[❌] Gagal finish fish (Error: " .. ErrorCount .. "/" .. Config.ErrorThreshold .. ")")
                    
                    if ErrorCount >= Config.ErrorThreshold and Config.AutoRetryEnabled then
                        ResetPerfectCatch()
                        ErrorCount = 0
                    end
                    task.wait(0.5)
                    return
                end
                
                task.wait(0.1)
            end)

            if not success then
                ErrorCount = ErrorCount + 1
                warn("[❌] Error (" .. ErrorCount .. "/" .. Config.ErrorThreshold .. "): " .. tostring(err))
                
                if ErrorCount >= Config.ErrorThreshold and Config.AutoRetryEnabled then
                    ResetPerfectCatch()
                    ErrorCount = 0
                else
                    task.wait(0.5)
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

-- ===== TELEPORT SYSTEM (WITH TOGGLE) =====
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
            Content = "Enable teleport in settings first!",
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
    -- ===== FISHING TAB =====
    local Tab1 = Window:CreateTab("🎣 Fishing", 4483362458)
    
    Tab1:CreateSection("Auto Fishing (With Auto Retry)")
    
    Tab1:CreateToggle({
        Name = "Auto Fishing (FAST MODE)",
        CurrentValue = false,
        Callback = function(Value)
            Config.AutoFishingV1 = Value
            if Value then
                AutoFishingV1()
                Rayfield:Notify({
                    Title = "Auto Fishing",
                    Content = "Started dengan AUTO RETRY enabled!",
                    Duration = 3
                })
            end
        end
    })
    
    Tab1:CreateSlider({
        Name = "Catch Speed (Lower = Faster)",
        Range = {0.01, 1},
        Increment = 0.01,
        CurrentValue = 0.05,
        Callback = function(Value)
            Config.CatchDelay = Value
        end
    })
    
    Tab1:CreateToggle({
        Name = "Perfect Catch (Manual)",
        CurrentValue = false,
        Callback = function(Value)
            TogglePerfectCatch(Value)
        end
    })
    
    Tab1:CreateToggle({
        Name = "Auto Sell Fish",
        CurrentValue = false,
        Callback = function(Value)
            Config.AutoSell = Value
            if Value then AutoSell() end
        end
    })
    
    Tab1:CreateSection("Anti AFK")
    
    Tab1:CreateToggle({
        Name = "Anti AFK (Prevent Kick)",
        CurrentValue = false,
        Callback = function(Value)
            Config.AntiAFK = Value
            if Value then 
                AntiAFK()
                Rayfield:Notify({
                    Title = "Anti AFK",
                    Content = "Enabled - You won't be kicked!",
                    Duration = 2
                })
            end
        end
    })
    
    -- ===== TELEPORT TAB =====
    local Tab2 = Window:CreateTab("📍 Teleport", 4483362458)
    
    Tab2:CreateSection("Teleport Settings")
    
    Tab2:CreateToggle({
        Name = "Enable Teleport",
        CurrentValue = false,
        Callback = function(Value)
            Config.TeleportEnabled = Value
            Rayfield:Notify({
                Title = "Teleport",
                Content = Value and "Enabled!" or "Disabled!",
                Duration = 2
            })
        end
    })
    
    Tab2:CreateSection("Islands")
    
    local IslandOptions = {}
    for i, island in ipairs(IslandsData) do
        table.insert(IslandOptions, string.format("%d. %s", i, island.Name))
    end
    
    local IslandDrop = Tab2:CreateDropdown({
        Name = "Select Island",
        Options = IslandOptions,
        CurrentOption = {IslandOptions[1]},
        Callback = function(Option) end
    })
    
    Tab2:CreateButton({
        Name = "Teleport to Island",
        Callback = function()
            local selected = IslandDrop.CurrentOption[1]
            local index = tonumber(selected:match("^(%d+)%."))
            
            if index then
                TeleportToIsland(index)
            end
        end
    })
    
    Tab2:CreateSection("Teleport to Player")
    
    Tab2:CreateToggle({
        Name = "Enable Teleport to Player",
        CurrentValue = false,
        Callback = function(Value)
            Config.TeleportToPlayerEnabled = Value
            Rayfield:Notify({
                Title = "Teleport to Player",
                Content = Value and "Enabled!" or "Disabled!",
                Duration = 2
            })
        end
    })
    
    local Players_List = {}
    local PlayerDrop = Tab2:CreateDropdown({
        Name = "Select Player",
        Options = {"Click 'Load Players' first"},
        CurrentOption = {"Click 'Load Players' first"},
        Callback = function(Option) end
    })
    
    Tab2:CreateButton({
        Name = "Load Players",
        Callback = function()
            Players_List = {}
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    table.insert(Players_List, player.Name)
                end
            end
            
            if #Players_List == 0 then
                Players_List = {"No players online"}
            end
            
            PlayerDrop:Refresh(Players_List)
            Rayfield:Notify({
                Title = "Players Loaded",
                Content = string.format("Found %d players", #Players_List),
                Duration = 2
            })
        end
    })
    
    Tab2:CreateButton({
        Name = "Teleport to Player",
        Callback = function()
            if not Config.TeleportToPlayerEnabled then
                Rayfield:Notify({
                    Title = "Teleport Disabled",
                    Content = "Enable 'Teleport to Player' first!",
                    Duration = 2
                })
                return
            end
            
            local selected = PlayerDrop.CurrentOption[1]
            if selected == "Click 'Load Players' first" or selected == "No players online" then
                Rayfield:Notify({
                    Title = "Error",
                    Content = "Load players first!",
                    Duration = 2
                })
                return
            end
            
            local player = Players:FindFirstChild(selected)
            
            if player and player.Character then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    HumanoidRootPart.CFrame = hrp.CFrame * CFrame.new(0, 3, 0)
                    Rayfield:Notify({
                        Title = "Teleported",
                        Content = "Teleported to " .. selected,
                        Duration = 2
                    })
                else
                    Rayfield:Notify({
                        Title = "Error",
                        Content = "Player character not found!",
                        Duration = 2
                    })
                end
            else
                Rayfield:Notify({
                    Title = "Error",
                    Content = "Player not found or left!",
                    Duration = 2
                })
            end
        end
    })
    
    -- ===== UTILITY TAB =====
    local Tab3 = Window:CreateTab("⚡ Utility", 4483362458)
    
    Tab3:CreateSection("Speed Settings")
    
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
    
    Tab3:CreateButton({
        Name = "Reset Speed",
        Callback = function()
            if Humanoid then
                Humanoid.WalkSpeed = 16
                Humanoid.JumpPower = 50
                Rayfield:Notify({Title = "Speed Reset", Content = "Back to normal", Duration = 2})
            end
        end
    })
    
    -- ===== TELEGRAM TAB =====
    local Tab4 = Window:CreateTab("🔔 Telegram", 4483362458)
    
    Tab4:CreateSection("Telegram Bot Settings")
    
    Tab4:CreateToggle({
        Name = "Enable Telegram Notifications",
        CurrentValue = false,
        Callback = function(Value)
            Config.Hooked.Enabled = Value
        end
    })
    
    Tab4:CreateInput({
        Name = "Bot Token",
        PlaceholderText = "Enter bot token",
        RemoveTextAfterFocusLost = false,
        Callback = function(Value)
            Config.Hooked.BotToken = Value
        end
    })
    
    Tab4:CreateInput({
        Name = "Chat ID",
        PlaceholderText = "Enter chat ID",
        RemoveTextAfterFocusLost = false,
        Callback = function(Value)
            Config.Hooked.ChatID = Value
        end
    })
    
    Tab4:CreateDropdown({
        Name = "Target Rarities",
        Options = {"COMMON", "UNCOMMON", "RARE", "EPIC", "LEGENDARY", "MYTHIC", "SECRET"},
        CurrentOption = {},
        MultipleOptions = true,
        Callback = function(Value)
            Config.Hooked.TargetRarities = Value
        end
    })
    
    Tab4:CreateButton({
        Name = "Test Telegram",
        Callback = function()
            local testFish = {
                Name = "Test Fish",
                Tier = 5,
                Id = "TEST",
                Chance = 0.001,
                SellPrice = 1000
            }
            Hooked:SendTelegramMessage(testFish)
            Rayfield:Notify({Title = "Test Sent", Content = "Check your Telegram!", Duration = 2})
        end
    })
    
    -- ===== INFO TAB =====
    local Tab5 = Window:CreateTab("ℹ️ Info", 4483362458)
    
    Tab5:CreateSection("Script Information")
    
    Tab5:CreateParagraph({
        Title = "RhyRu9 FISH IT - AUTO RETRY",
        Content = "Developer: RhyRu9\nVersion: Fully Automatic\nDate: 17 Oct 2025"
    })
    
    Tab5:CreateSection("🔄 Auto Retry System (OTOMATIS)")
    
    Tab5:CreateParagraph({
        Title = "✅ Fitur Auto Retry",
        Content = "• Error Detection - Deteksi error otomatis\n• Perfect Catch Reset - Reset setiap error\n• 30 Menit Reset - Refresh state setiap 30 min\n• Error Threshold - Reset setelah 5 error\n• Fully Automatic - Tidak perlu intervensi!"
    })
    
    Tab5:CreateParagraph({
        Title = "⚡ Cara Kerja",
        Content = "1. Jalankan Auto Fishing\n2. System monitor error otomatis\n3. Jika error 5x → Perfect catch reset\n4. Setiap 30 menit → Session reset\n5. Tetap catch terus tanpa gangguan!"
    })
    
    Tab5:CreateParagraph({
        Title = "📊 Status Monitor",
        Content = "Error Count: " .. tostring(ErrorCount) .. "/5\nSession Time: " .. string.format("%.0f", tick() - SessionStartTime) .. " detik"
    })
    
    Rayfield:Notify({
        Title = "✅ RhyRu9 FISH IT AUTO RETRY",
        Content = "Fully automatic mode loaded! Tinggal enable Auto Fishing",
        Duration = 4
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
    
    if Config.PerfectCatch then
        task.wait(1)
        TogglePerfectCatch(true)
    end
end)

-- Main Execution
local success, err = pcall(function()
    CreateUI()
end)

if success then
    print("=======================================")
    print("  RhyRu9 FISH IT - AUTO RETRY")
    print("  ✅ Perfect Catch - FASTER (0.05s)")
    print("  ✅ Error Detection - Otomatis")
    print("  ✅ Perfect Catch Reset - Auto")
    print("  ✅ 30 Menit Session Reset - Auto")
    print("  ✅ Telegram Bot - Working")
    print("  ✅ Anti AFK - Enabled")
    print("=======================================")
else
    warn("ERROR: " .. tostring(err))
end
