-- RhyRu9 FISH IT v1.3 - Rayfield Integration
-- DEVELOPER BY RhyRu9
-- Update: 28 Oct 2025 (Integrated with Rayfield UI)

print("Loading RhyRu9 FISH IT v1.3 with Rayfield...")

if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- ==================== SERVICES ====================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

-- ==================== LOAD RAYFIELD ====================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ==================== CONFIGURATION ====================
local Config = {
    AutoFish = false,
    AutoSell = false,
    AntiAFK = false,
    TeleportEnabled = false,
    WalkSpeed = 16,
    JumpPower = 50,
    FlyEnabled = false,
    FlySpeed = 50,
    NoClip = false,
    
    Telegram = {
        Enabled = false,
        BotToken = "",
        ChatId = "",
        RarityFilter = {}
    },
    
    Timing = {
        CastRetry = 3,
        CastDelay = 0.2,
        ChargeRetry = 15,
        ChargeDelay = 0.15,
        MinigameRetry = 5,
        MinigameDelay = 0.1,
        ReelInterval = 0.05,
        ReelDuration = 2.5,
        PostCastWait = 0.3,
        PostReelWait = 0.8,
        BiteTimeout = 30,
        ErrorCooldown = 2
    }
}

-- ==================== STATE MANAGEMENT ====================
local State = {
    Active = false,
    Casting = false,
    WaitingBite = false,
    Reeling = false,
    LastCast = 0,
    BiteDetected = false,
    ErrorCount = 0,
    MaxErrors = 5,
    TotalCasts = 0,
    SuccessfulCatches = 0
}

-- ==================== DATA ====================
local FishData = {}
local FishLookup = {}
local TierToRarity = {
    [1] = "COMMON", [2] = "UNCOMMON", [3] = "RARE",
    [4] = "EPIC", [5] = "LEGENDARY", [6] = "MYTHICAL", [7] = "SECRET"
}

-- ==================== HELPER FUNCTIONS ====================
local function NormalizeName(name)
    if not name then return "" end
    return name:lower():gsub("%s+", ""):gsub("[^%w]", "")
end

local function ResetState()
    State.Casting = false
    State.WaitingBite = false
    State.Reeling = false
    State.BiteDetected = false
    task.wait(0.3)
end

local function HandleError(context)
    State.ErrorCount = State.ErrorCount + 1
    warn(string.format("[ERROR] %s | Count: %d/%d", context, State.ErrorCount, State.MaxErrors))
    
    if State.ErrorCount >= State.MaxErrors then
        print("[SYSTEM] Error threshold reached. Resetting...")
        ResetState()
        State.ErrorCount = 0
        task.wait(Config.Timing.ErrorCooldown)
    else
        task.wait(1)
    end
end

local function SafeFireServer(remote, ...)
    local success, result = pcall(function()
        return remote:FireServer(...)
    end)
    return success, result
end

local function SafeInvokeServer(remote, ...)
    local success, result = pcall(function()
        return remote:InvokeServer(...)
    end)
    return success, result
end

-- ==================== REMOTES ====================
local NetFolder = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")

local function GetRemote(name)
    return NetFolder:FindFirstChild(name)
end

local Remotes = {
    EquipTool = GetRemote("RE/EquipToolFromHotbar"),
    ChargeRod = GetRemote("RF/ChargeFishingRod"),
    StartMinigame = GetRemote("RF/RequestFishingMinigameStarted"),
    FishingComplete = GetRemote("RE/FishingCompleted"),
    SellAll = GetRemote("RF/SellAllItems"),
    FishCaught = GetRemote("RE/FishCaught"),
    TextEffect = GetRemote("RE/ReplicateTextEffect")
}

-- Validate critical remotes
for name, remote in pairs(Remotes) do
    if not remote then
        warn(string.format("[REMOTE] Missing: %s", name))
    end
end

-- ==================== LOAD FISH DATA ====================
local DataFile = "FISHES_DATA.json"
if isfile and isfile(DataFile) then
    local success, decoded = pcall(function()
        return HttpService:JSONDecode(readfile(DataFile))
    end)
    
    if success and decoded then
        FishData = decoded
        for tier = 1, 7 do
            local tierKey = "Tier" .. tier
            if FishData[tierKey] then
                for _, fish in ipairs(FishData[tierKey]) do
                    if fish.Name then
                        FishLookup[NormalizeName(fish.Name)] = fish
                        FishLookup[fish.Name:lower()] = fish
                        if fish.Id then
                            FishLookup["id_" .. tostring(fish.Id)] = fish
                        end
                    end
                end
            end
        end
        print(string.format("[DATA] Loaded %d fish species", #FishData))
    end
end

-- ==================== TELEGRAM BOT ====================
local TelegramBot = {}

function TelegramBot:GetChatId(token)
    if not token or token == "" then return nil end
    if Config.Telegram.ChatId and Config.Telegram.ChatId ~= "" then
        return Config.Telegram.ChatId
    end
    
    local success, result = pcall(function()
        local url = "https://api.telegram.org/bot" .. token .. "/getUpdates"
        local response = nil
        
        if http_request then
            response = http_request({Url = url, Method = "GET"})
        elseif syn and syn.request then
            response = syn.request({Url = url, Method = "GET"})
        elseif request then
            response = request({Url = url, Method = "GET"})
        end
        
        if response and response.Body then
            local data = HttpService:JSONDecode(response.Body)
            if data.ok and data.result and #data.result > 0 then
                for i = #data.result, 1, -1 do
                    local update = data.result[i]
                    if update.message and update.message.chat and update.message.chat.id then
                        local chatId = tostring(update.message.chat.id)
                        Config.Telegram.ChatId = chatId
                        return chatId
                    end
                end
            end
        end
        return nil
    end)
    
    return success and result or nil
end

function TelegramBot:SendNotification(fishInfo)
    if not Config.Telegram.Enabled or Config.Telegram.BotToken == "" then return end
    if not fishInfo.Tier then return end
    
    local rarity = TierToRarity[fishInfo.Tier] or "UNKNOWN"
    
    if #Config.Telegram.RarityFilter > 0 then
        local shouldSend = false
        for _, targetRarity in ipairs(Config.Telegram.RarityFilter) do
            if string.upper(rarity):gsub("%s+", "") == string.upper(targetRarity):gsub("%s+", "") then
                shouldSend = true
                break
            end
        end
        if not shouldSend then return end
    end
    
    local chatId = self:GetChatId(Config.Telegram.BotToken)
    if not chatId then return end
    
    local message = self:FormatMessage(fishInfo)
    
    pcall(function()
        local url = "https://api.telegram.org/bot" .. Config.Telegram.BotToken .. "/sendMessage"
        local data = HttpService:JSONEncode({
            chat_id = chatId,
            text = message,
            parse_mode = "Markdown"
        })
        
        if http_request then
            http_request({
                Url = url,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = data
            })
        end
    end)
end

function TelegramBot:FormatMessage(fishInfo)
    local rarity = TierToRarity[fishInfo.Tier or 1] or "UNKNOWN"
    local chance = (fishInfo.Chance or 0) * 100
    
    local msg = "```\n===== 🎣 FISH CAUGHT =====\n"
    msg = msg .. "Player: " .. LocalPlayer.Name .. "\n"
    msg = msg .. "Fish: " .. (fishInfo.Name or "Unknown") .. "\n"
    msg = msg .. "Rarity: " .. rarity .. "\n"
    msg = msg .. "Tier: " .. (fishInfo.Tier or 1) .. "\n"
    if chance > 0 then
        msg = msg .. "Chance: " .. string.format("%.6f%%", chance) .. "\n"
    end
    if fishInfo.SellPrice then
        msg = msg .. "Value: " .. fishInfo.SellPrice .. " COINS\n"
    end
    msg = msg .. "```"
    return msg
end

function TelegramBot:SendTestMessage()
    if Config.Telegram.BotToken == "" then
        Rayfield:Notify({
            Title = "❌ Error",
            Content = "Bot token is empty!",
            Duration = 3,
            Image = 4483362458
        })
        return false
    end
    
    local chatId = self:GetChatId(Config.Telegram.BotToken)
    if not chatId then
        Rayfield:Notify({
            Title = "❌ Chat ID Failed",
            Content = "Send '/start' to your bot first!",
            Duration = 5,
            Image = 4483362458
        })
        return false
    end
    
    local message = "🎣 RhyRu9 FISH IT v1.3\n\nPlayer: " .. LocalPlayer.Name .. 
                   "\nChat ID: " .. chatId .. "\nStatus: Connected ✅"
    
    local success = pcall(function()
        local url = "https://api.telegram.org/bot" .. Config.Telegram.BotToken .. "/sendMessage"
        
        if http_request then
            http_request({
                Url = url,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode({
                    chat_id = chatId,
                    text = message
                })
            })
        end
    end)
    
    if success then
        Rayfield:Notify({
            Title = "✅ Success",
            Content = "Check your Telegram!",
            Duration = 3,
            Image = 4483362458
        })
        return true
    else
        Rayfield:Notify({
            Title = "❌ Failed",
            Content = "Send error",
            Duration = 3,
            Image = 4483362458
        })
        return false
    end
end

-- ==================== EVENT LISTENERS ====================
if Remotes.TextEffect then
    print("[LISTENER] ✅ TextEffect connected")
    
    Remotes.TextEffect.OnClientEvent:Connect(function(data)
        if not Config.AutoFish or not State.WaitingBite then return end
        if not data or not data.TextData then return end
        
        if data.TextData.EffectType == "Exclaim" then
            print(string.format("\n[🎣 BITE] Detected at %.3f", tick()))
            State.BiteDetected = true
            State.WaitingBite = false
        end
    end)
else
    warn("[LISTENER] ❌ TextEffect NOT FOUND")
end

if Remotes.FishCaught then
    print("[LISTENER] ✅ FishCaught connected")
    
    local lastUID = nil
    Remotes.FishCaught.OnClientEvent:Connect(function(data)
        if not data then return end
        
        local name = type(data) == "string" and data or (data.Name or "Unknown")
        local tier = type(data) == "table" and (data.Tier or 1) or 1
        local id = type(data) == "table" and data.Id or nil
        local chance = type(data) == "table" and (data.Chance or 0) or 0
        local price = type(data) == "table" and (data.SellPrice or 0) or 0
        
        local uid = name .. "_" .. tier .. "_" .. tick()
        if uid == lastUID then return end
        lastUID = uid
        
        local info = FishLookup[NormalizeName(name)] or {
            Name = name,
            Tier = tier,
            Id = id or "?",
            Chance = chance,
            SellPrice = price
        }
        
        if not info.Tier then info.Tier = tier end
        
        local rarity = TierToRarity[info.Tier] or "UNKNOWN"
        print(string.format("[CATCH] %s | %s | %s coins", name, rarity, tostring(info.SellPrice or 0)))
        
        State.SuccessfulCatches = State.SuccessfulCatches + 1
        State.ErrorCount = 0
        
        TelegramBot:SendNotification(info)
        
        State.Reeling = false
    end)
else
    warn("[LISTENER] ❌ FishCaught NOT FOUND")
end

-- ==================== AUTO FISHING SYSTEM ====================
local function CastRod()
    print("\n[CAST] Starting cast sequence...")
    State.Casting = true
    State.BiteDetected = false
    State.WaitingBite = false
    State.TotalCasts = State.TotalCasts + 1
    
    local equipSuccess = false
    for i = 1, Config.Timing.CastRetry do
        local success = SafeFireServer(Remotes.EquipTool, 1)
        if success then
            equipSuccess = true
            print("[CAST] Tool equipped")
            break
        end
        task.wait(Config.Timing.CastDelay)
    end
    
    if not equipSuccess then
        HandleError("Equip failed")
        State.Casting = false
        return false
    end
    
    task.wait(Config.Timing.PostCastWait)
    
    local chargeSuccess = false
    local attempts = 0
    
    while attempts < Config.Timing.ChargeRetry and not chargeSuccess do
        attempts = attempts + 1
        local success, result = SafeInvokeServer(Remotes.ChargeRod, tick())
        
        if success and result then
            chargeSuccess = true
            print(string.format("[CAST] Charged (attempt %d/%d)", attempts, Config.Timing.ChargeRetry))
            break
        end
        
        task.wait(Config.Timing.ChargeDelay)
    end
    
    if not chargeSuccess then
        HandleError("Charge failed after " .. Config.Timing.ChargeRetry .. " attempts")
        State.Casting = false
        return false
    end
    
    task.wait(Config.Timing.PostCastWait)
    
    local minigameSuccess = false
    for i = 1, Config.Timing.MinigameRetry do
        local success = SafeInvokeServer(Remotes.StartMinigame, -1.233184814453125, 0.9945034885633273)
        if success then
            minigameSuccess = true
            print("[CAST] Minigame started (Perfect)")
            break
        end
        task.wait(Config.Timing.MinigameDelay)
    end
    
    if not minigameSuccess then
        HandleError("Minigame start failed")
        State.Casting = false
        return false
    end
    
    State.Casting = false
    State.WaitingBite = true
    State.LastCast = tick()
    print("[CAST] ✅ Success! Waiting for bite...")
    
    return true
end

local function RapidTapReel()
    if State.Reeling then 
        print("[REEL] Already reeling, skip")
        return 
    end
    
    print("[REEL] 🎣 Starting rapid tap sequence...")
    State.Reeling = true
    State.WaitingBite = false
    
    task.wait(0.3)
    
    local tapStart = tick()
    local tapCount = 0
    local maxTaps = math.floor(Config.Timing.ReelDuration / Config.Timing.ReelInterval)
    
    print(string.format("[REEL] Executing %d taps (%dms interval)", maxTaps, Config.Timing.ReelInterval * 1000))
    
    while tick() - tapStart < Config.Timing.ReelDuration and State.Reeling do
        tapCount = tapCount + 1
        
        SafeFireServer(Remotes.FishingComplete)
        
        if tapCount % 10 == 0 then
            local progress = math.floor((tapCount / maxTaps) * 100)
            print(string.format("[REEL] Tap #%d/%d (%d%%)", tapCount, maxTaps, progress))
        end
        
        task.wait(Config.Timing.ReelInterval)
    end
    
    print(string.format("[REEL] ✅ Complete! Total %d taps in %.2fs", tapCount, tick() - tapStart))
    
    SafeFireServer(Remotes.FishingComplete)
    
    task.wait(Config.Timing.PostReelWait)
    ResetState()
end

local function AutoFishingSystem()
    task.spawn(function()
        print("\n╔═══════════════════════════════════════╗")
        print("║   AUTO FISHING SYSTEM v1.3           ║")
        print("║   Event-Based + Optimized Timing     ║")
        print("╚═══════════════════════════════════════╝\n")
        
        while Config.AutoFish do
            State.Active = true
            
            local success, err = pcall(function()
                if not LocalPlayer.Character or not HumanoidRootPart then
                    repeat task.wait(0.5) until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    Character = LocalPlayer.Character
                    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
                end
                
                if not State.WaitingBite and not State.Reeling then
                    if CastRod() then
                        print("[SYSTEM] Cast successful, waiting for bite event...")
                    else
                        print("[SYSTEM] Cast failed, retrying...")
                        task.wait(Config.Timing.ErrorCooldown)
                        return
                    end
                end
                
                if State.WaitingBite then
                    local waitStart = tick()
                    
                    while State.WaitingBite and not State.BiteDetected do
                        task.wait(0.1)
                        
                        if tick() - waitStart > Config.Timing.BiteTimeout then
                            print(string.format("[SYSTEM] Timeout %ds, no bite. Retrying...", Config.Timing.BiteTimeout))
                            ResetState()
                            break
                        end
                    end
                    
                    if State.BiteDetected then
                        print("[SYSTEM] 🎣 Bite detected! Starting rapid tap...")
                        RapidTapReel()
                        task.wait(Config.Timing.PostReelWait)
                    end
                end
            end)
            
            if not success then
                HandleError("Runtime error: " .. tostring(err))
            end
            
            task.wait(0.5)
        end
        
        State.Active = false
        ResetState()
        print("[SYSTEM] Auto fishing stopped")
    end)
end

-- ==================== ADDITIONAL FEATURES ====================
local function AutoSell()
    task.spawn(function()
        while Config.AutoSell do
            pcall(function()
                SafeInvokeServer(Remotes.SellAll)
            end)
            task.wait(10)
        end
    end)
end

local function AntiAFK()
    task.spawn(function()
        while Config.AntiAFK do
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
            task.wait(30)
        end
    end)
end

local function Fly()
    task.spawn(function()
        local bv = Instance.new("BodyVelocity", HumanoidRootPart)
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.MaxForce = Vector3.new(10000, 10000, 10000)
        
        while Config.FlyEnabled do
            local cam = Workspace.CurrentCamera
            local move = Vector3.new(0, 0, 0)
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0, 1, 0) end
            
            bv.Velocity = move * Config.FlySpeed
            task.wait()
        end
        bv:Destroy()
    end)
end

local function NoClip()
    task.spawn(function()
        while Config.NoClip do
            for _, part in pairs(Character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
            task.wait(0.1)
        end
    end)
end

-- ==================== TELEPORT DATA ====================
local IslandData = {
    {Name = "Fisherman's Island", Position = Vector3.new(92, 9, 2768)},
    {Name = "Arrow Lever", Position = Vector3.new(898, 8, -363)},
    {Name = "Sisyphus Statue", Position = Vector3.new(-3740, -136, -1013)},
    {Name = "Ancient Forest", Position = Vector3.new(1481, 11, -302)},
    {Name = "Weather Machine", Position = Vector3.new(-1519, 2, 1908)},
    {Name = "Coral Reef", Position = Vector3.new(-3105, 6, 2218)},
    {Name = "Tropical Island", Position = Vector3.new(-2110, 53, 3649)},
    {Name = "Kohana", Position = Vector3.new(-662, 3, 714)},
    {Name = "Esoteric Island", Position = Vector3.new(2035, 27, 1386)},
    {Name = "Diamond Lever", Position = Vector3.new(1818, 8, -285)},
    {Name = "Underground Chamber", Position = Vector3.new(2098, -92, -703)},
    {Name = "Volcano", Position = Vector3.new(-631, 54, 194)},
    {Name = "Enchantment Chamber", Position = Vector3.new(3255, -1302, 1371)},
    {Name = "Lost Island", Position = Vector3.new(-3717, 5, -1079)},
    {Name = "Sacred Temple", Position = Vector3.new(1475, -22, -630)},
    {Name = "Crater Island", Position = Vector3.new(981, 41, 5080)},
    {Name = "Double Enchantment", Position = Vector3.new(1480, 127, -590)},
    {Name = "Treasure Chamber", Position = Vector3.new(-3599, -276, -1642)},
    {Name = "Crescent Lever", Position = Vector3.new(1419, 31, 78)},
    {Name = "Hourglass Diamond", Position = Vector3.new(1484, 8, -862)},
    {Name = "Snowy Island", Position = Vector3.new(1627, 4, 3288)}
}

local function TeleportToIsland(index)
    if not Config.TeleportEnabled then
        Rayfield:Notify({
            Title = "Error", 
            Content = "Enable teleport first!", 
            Duration = 2,
            Image = 4483362458
        })
        return
    end
    if IslandData[index] and HumanoidRootPart then
        HumanoidRootPart.CFrame = CFrame.new(IslandData[index].Position)
        Rayfield:Notify({
            Title = "Teleport", 
            Content = "To " .. IslandData[index].Name, 
            Duration = 2,
            Image = 4483362458
        })
    end
end

-- ==================== UI CREATION ====================
local Window = Rayfield:CreateWindow({
    Name = "RhyRu9 FISH IT v1.3",
    LoadingTitle = "RhyRu9 FISH IT",
    LoadingSubtitle = "by RhyRu9",
    ConfigurationSaving = {
        FolderName = "RhyRu9FishIT",
        FileName = "FishConfig"
    },
    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = true
    },
    KeySystem = false
})

-- TAB 1: FISHING
local FishingTab = Window:CreateTab("🎣 Fishing", 4483362458)

FishingTab:CreateSection("Auto Fishing System v1.3")

FishingTab:CreateToggle({
    Name = "🔥 Auto Fishing (Event-Based)",
    CurrentValue = false,
    Flag = "AutoFish",
    Callback = function(v)
        Config.AutoFish = v
        if v then
            AutoFishingSystem()
            Rayfield:Notify({
                Title = "🔥 Auto Fishing Started",
                Content = "Event-based detection active!",
                Duration = 3,
                Image = 4483362458
            })
        end
    end
})

FishingTab:CreateToggle({
    Name = "💰 Auto Sell",
    CurrentValue = false,
    Flag = "AutoSell",
    Callback = function(v)
        Config.AutoSell = v
        if v then AutoSell() end
    end
})

FishingTab:CreateToggle({
    Name = "⏰ Anti AFK",
    CurrentValue = false,
    Flag = "AntiAFK",
    Callback = function(v)
        Config.AntiAFK = v
        if v then AntiAFK() end
    end
})

FishingTab:CreateSection("⚡ How It Works")
FishingTab:CreateParagraph({
    Title = "System Features",
    Content = "✅ Real-time bite detection\n✅ 50ms rapid tap system\n✅ 50+ taps in 2.5 seconds\n✅ Auto-reel on '!' signal\n✅ Smart error handling"
})

FishingTab:CreateButton({
    Name = "🔄 Reset Fishing State",
    Callback = function()
        ResetState()
        State.ErrorCount = 0
        Rayfield:Notify({
            Title = "State Reset",
            Content = "Fishing state has been reset!",
            Duration = 2,
            Image = 4483362458
        })
    end
})

-- TAB 2: TELEGRAM
local TelegramTab = Window:CreateTab("📱 Telegram", 4483362458)

TelegramTab:CreateSection("Telegram Settings")

TelegramTab:CreateToggle({
    Name = "Enable Telegram Notifications",
    CurrentValue = false,
    Flag = "TelegramEnabled",
    Callback = function(v) 
        Config.Telegram.Enabled = v
    end
})

TelegramTab:CreateInput({
    Name = "Bot Token",
    PlaceholderText = "Enter your bot token",
    RemoveTextAfterFocusLost = false,
    Flag = "BotToken",
    Callback = function(v) 
        Config.Telegram.BotToken = v
    end
})

TelegramTab:CreateButton({
    Name = "Test Send Message",
    Callback = function()
        TelegramBot:SendTestMessage()
    end
})

TelegramTab:CreateSection("Rarity Filter")
TelegramTab:CreateParagraph({
    Title = "Filter Info",
    Content = "Empty = Accept ALL fish\nEnable specific rarities to filter notifications"
})

local rarityList = {"SECRET", "MYTHICAL", "LEGENDARY", "EPIC", "RARE", "UNCOMMON", "COMMON"}

for _, rarity in ipairs(rarityList) do
    TelegramTab:CreateToggle({
        Name = rarity,
        CurrentValue = false,
        Flag = "Rarity_" .. rarity,
        Callback = function(v)
            if v then
                table.insert(Config.Telegram.RarityFilter, rarity)
            else
                for i, val in ipairs(Config.Telegram.RarityFilter) do
                    if val == rarity then 
                        table.remove(Config.Telegram.RarityFilter, i) 
                        break 
                    end
                end
            end
        end
    })
end

-- TAB 3: TELEPORT
local TeleportTab = Window:CreateTab("📍 Teleport", 4483362458)

TeleportTab:CreateSection("Teleport Settings")

TeleportTab:CreateToggle({
    Name = "Enable Teleport",
    CurrentValue = false,
    Flag = "TeleportEnabled",
    Callback = function(v) Config.TeleportEnabled = v end
})

local islandOptions = {}
for i, island in ipairs(IslandData) do
    table.insert(islandOptions, string.format("%d. %s", i, island.Name))
end

local selectedIslandIndex = 1

TeleportTab:CreateDropdown({
    Name = "Select Island",
    Options = islandOptions,
    CurrentOption = {"1. " .. IslandData[1].Name},
    Flag = "SelectedIsland",
    Callback = function(option)
        if option and #option > 0 then
            local index = tonumber(option[1]:match("^(%d+)%."))
            if index then selectedIslandIndex = index end
        end
    end
})

TeleportTab:CreateButton({
    Name = "Teleport to Selected Island",
    Callback = function() TeleportToIsland(selectedIslandIndex) end
})

TeleportTab:CreateSection("Quick Teleport")

local quickLocations = {
    {1, "📍 Fisherman's Island"},
    {12, "🌋 Volcano"}, 
    {21, "❄️ Snowy Island"},
    {4, "🌳 Ancient Forest"},
    {6, "🐠 Coral Reef"},
    {13, "⚡ Enchantment Chamber"}
}

for _, loc in ipairs(quickLocations) do
    TeleportTab:CreateButton({
        Name = loc[2],
        Callback = function() TeleportToIsland(loc[1]) end
    })
end

-- TAB 4: UTILITIES
local UtilitiesTab = Window:CreateTab("⚡ Utilities", 4483362458)

UtilitiesTab:CreateSection("Character Settings")

UtilitiesTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 500},
    Increment = 1,
    CurrentValue = 16,
    Flag = "WalkSpeed",
    Callback = function(v)
        Config.WalkSpeed = v
        if Humanoid then Humanoid.WalkSpeed = v end
    end
})

UtilitiesTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 500},
    Increment = 5,
    CurrentValue = 50,
    Flag = "JumpPower",
    Callback = function(v)
        Config.JumpPower = v
        if Humanoid then Humanoid.JumpPower = v end
    end
})

UtilitiesTab:CreateButton({
    Name = "Reset to Normal Speed",
    Callback = function()
        if Humanoid then
            Humanoid.WalkSpeed = 16
            Humanoid.JumpPower = 50
            Config.WalkSpeed = 16
            Config.JumpPower = 50
        end
        Rayfield:Notify({
            Title = "Speed Reset",
            Content = "Character speed reset to normal",
            Duration = 2,
            Image = 4483362458
        })
    end
})

UtilitiesTab:CreateSection("Movement Features")

UtilitiesTab:CreateToggle({
    Name = "✈️ Fly Mode",
    CurrentValue = false,
    Flag = "FlyEnabled",
    Callback = function(v)
        Config.FlyEnabled = v
        if v then Fly() end
    end
})

UtilitiesTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 300},
    Increment = 5,
    CurrentValue = 50,
    Flag = "FlySpeed",
    Callback = function(v) Config.FlySpeed = v end
})

UtilitiesTab:CreateToggle({
    Name = "👻 NoClip",
    CurrentValue = false,
    Flag = "NoClip",
    Callback = function(v)
        Config.NoClip = v
        if v then NoClip() end
    end
})

UtilitiesTab:CreateSection("Visual Settings")

UtilitiesTab:CreateButton({
    Name = "💡 Fullbright",
    Callback = function()
        Lighting.Brightness = 2
        Lighting.ClockTime = 12
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Rayfield:Notify({
            Title = "Fullbright",
            Content = "Fullbright enabled!",
            Duration = 2,
            Image = 4483362458
        })
    end
})

UtilitiesTab:CreateButton({
    Name = "🌫️ Remove Fog",
    Callback = function()
        Lighting.FogEnd = 100000
        Rayfield:Notify({
            Title = "Fog Removed",
            Content = "Fog has been removed!",
            Duration = 2,
            Image = 4483362458
        })
    end
})

-- TAB 5: INFO & STATUS
local InfoTab = Window:CreateTab("ℹ️ Info", 4483362458)

InfoTab:CreateSection("System Status")

local statusLabel = InfoTab:CreateLabel("State: IDLE")
local errorLabel = InfoTab:CreateLabel("Errors: 0")
local castsLabel = InfoTab:CreateLabel("Total Casts: 0")
local catchesLabel = InfoTab:CreateLabel("Successful: 0")
local successRateLabel = InfoTab:CreateLabel("Success Rate: 0%")

-- Real-time status updates
task.spawn(function()
    while true do
        local stateText = State.Active and "ACTIVE" or "IDLE"
        if State.Casting then stateText = "CASTING"
        elseif State.WaitingBite then stateText = "WAITING"
        elseif State.Reeling then stateText = "REELING" end
        
        statusLabel:Set("State: " .. stateText)
        errorLabel:Set("Errors: " .. State.ErrorCount)
        castsLabel:Set("Total Casts: " .. State.TotalCasts)
        catchesLabel:Set("Successful: " .. State.SuccessfulCatches)
        
        if State.TotalCasts > 0 then
            local rate = (State.SuccessfulCatches / State.TotalCasts) * 100
            successRateLabel:Set(string.format("Success Rate: %.1f%%", rate))
        end
        
        task.wait(1)
    end
end)

InfoTab:CreateSection("About Script")

InfoTab:CreateParagraph({
    Title = "RhyRu9 FISH IT v1.3",
    Content = "Developer: RhyRu9\nUpdate: 28 October 2025\n\n✨ NEW FEATURES:\n• Fixed event flow\n• Optimized timing\n• Enhanced error handling\n• Real-time statistics\n• Improved reliability"
})

InfoTab:CreateSection("System Information")

InfoTab:CreateParagraph({
    Title = "Event Flow",
    Content = "1. Equip Tool (3x retry)\n2. Charge Rod (15x retry)\n3. Start Minigame (perfect cast)\n4. Wait for '!' event\n5. Rapid tap 50ms (50+ taps)\n6. Catch notification\n7. Auto repeat"
})

InfoTab:CreateSection("Timing Configuration")

InfoTab:CreateLabel(string.format("Cast Retry: %d attempts", Config.Timing.CastRetry))
InfoTab:CreateLabel(string.format("Charge Retry: %d attempts", Config.Timing.ChargeRetry))
InfoTab:CreateLabel(string.format("Reel Interval: %dms", Config.Timing.ReelInterval * 1000))
InfoTab:CreateLabel(string.format("Reel Duration: %.1fs", Config.Timing.ReelDuration))
InfoTab:CreateLabel(string.format("Bite Timeout: %ds", Config.Timing.BiteTimeout))

InfoTab:CreateButton({
    Name = "🔄 Restart Script",
    Callback = function()
        Rayfield:Notify({
            Title = "Restarting...",
            Content = "Script will restart",
            Duration = 2,
            Image = 4483362458
        })
        task.wait(2)
        ResetState()
        Config.AutoFish = false
        task.wait(1)
        Config.AutoFish = true
        AutoFishingSystem()
    end
})

InfoTab:CreateButton({
    Name = "📊 Reset Statistics",
    Callback = function()
        State.TotalCasts = 0
        State.SuccessfulCatches = 0
        Rayfield:Notify({
            Title = "Statistics Reset",
            Content = "All stats cleared",
            Duration = 2,
            Image = 4483362458
        })
    end
})

InfoTab:CreateSection("Controls")

InfoTab:CreateParagraph({
    Title = "Fly Controls",
    Content = "W/A/S/D - Movement\nSpace - Up\nLeft Shift - Down"
})

InfoTab:CreateParagraph({
    Title = "Tips",
    Content = "• Enable Anti-AFK to prevent being kicked\n• Use Auto Sell to automatically sell fish\n• Telegram notifications for rare catches\n• Teleport to different fishing spots\n• Adjust walk speed for faster movement"
})

-- ==================== CHARACTER HANDLER ====================
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
    Humanoid = char:WaitForChild("Humanoid")
    
    task.wait(2)
    
    if Humanoid then
        Humanoid.WalkSpeed = Config.WalkSpeed
        Humanoid.JumpPower = Config.JumpPower
    end
    
    if Config.AutoFish then
        task.wait(2)
        AutoFishingSystem()
    end
    
    if Config.AutoSell then AutoSell() end
    if Config.AntiAFK then AntiAFK() end
    if Config.FlyEnabled then Fly() end
    if Config.NoClip then NoClip() end
end)

-- ==================== ANTI-IDLE ====================
local function PreventIdle()
    task.spawn(function()
        while true do
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
            task.wait(60)
        end
    end)
end

-- ==================== INITIALIZATION ====================
local function Initialize()
    PreventIdle()
    
    if Humanoid then
        Humanoid.WalkSpeed = Config.WalkSpeed
        Humanoid.JumpPower = Config.JumpPower
    end
    
    print([[
    
    ╔═══════════════════════════════════════╗
    ║        RhyRu9 FISH IT v1.3           ║
    ║      EVENT-BASED SYSTEM              ║
    ║                                      ║
    ║  ⚡ Fixed event flow                 ║
    ║  ✅ Optimized timing                 ║
    ║  🔥 50ms rapid tap                   ║
    ║  ✅ Real-time detection              ║
    ║  ✅ Enhanced error handling          ║
    ║  📊 Live statistics                  ║
    ║                                      ║
    ║      Developer: RhyRu9 © 2025        ║
    ╚═══════════════════════════════════════╝
    
    ]])
    
    Rayfield:Notify({
        Title = "✅ RhyRu9 FISH IT v1.3",
        Content = "Event-based system ready!",
        Duration = 5,
        Image = 4483362458
    })
end

-- ==================== ERROR HANDLING ====================
local function GlobalErrorHandler(err)
    warn("[GLOBAL ERROR] " .. tostring(err))
    
    pcall(function()
        ResetState()
        State.ErrorCount = 0
    end)
end

-- ==================== MAIN EXECUTION ====================
xpcall(function()
    Initialize()
end, GlobalErrorHandler)

-- ==================== AUTO-RECOVERY ====================
task.spawn(function()
    while true do
        if Config.AutoFish and not State.Active then
            warn("[AUTO-RECOVERY] System stopped unexpectedly, restarting...")
            AutoFishingSystem()
        end
        task.wait(10)
    end
end)

-- ==================== CLEANUP ====================
game:GetService("Players").PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        print("[CLEANUP] Cleaning up resources...")
        Config.AutoFish = false
        ResetState()
    end
end)

print("[SCRIPT] RhyRu9 FISH IT v1.3 loaded successfully!")
