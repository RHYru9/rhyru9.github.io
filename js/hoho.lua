-- RhyRu9 FISH IT v1.2
-- DEVELOPER BY RhyRu9
-- Update: 22 Oct 2025 (Event-Based Fishing + Rapid Tap System)
-- CRITICAL CHANGES: Deteksi real-time + Rapid Tap 50ms!

print("Memuat RhyRu9 FISH IT v1.2...")

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
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

-- Rayfield Setup
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "RhyRu9 FISH IT v1.2",
    LoadingTitle = "RhyRu9 FISH IT",
    LoadingSubtitle = "RAPID TAP SYSTEM",
    ConfigurationSaving = { Enabled = false },
})

-- ==================== KONFIGURASI ====================
local Config = {
    MancingOtomatis = false,
    TangkapanSempurna = false,
    JualOtomatis = false,
    AntiAFK = false,
    TeleportAktif = false,
    KecepatanJalan = 16,
    KekuatanLompat = 50,
    FlyAktif = false,
    KecepatanFly = 50,
    NoClip = false,
    
    Telegram = {
        Aktif = false,
        TokenBot = "",
        ChatId = "",
        RaritasTerpilih = {}
    }
}

-- ==================== STATE MANAGEMENT ====================
local FishingState = {
    IsActive = false,
    IsCasting = false,
    IsWaitingBite = false,
    IsReeling = false,
    LastCastTime = 0,
    BiteDetected = false,
    ErrorCount = 0,
    MaxErrors = 3
}

-- ==================== DATA ====================
local dataIkan = {}
local pencariIkan = {}
local tingkatKeRaritas = {
    [1] = "UMUM", [2] = "TIDAK UMUM", [3] = "LANGKA",
    [4] = "EPIK", [5] = "LEGENDARIS", [6] = "MISTIS", [7] = "RAHASIA"
}

-- ==================== HELPER FUNCTIONS ====================
local function normalisasiNama(nama)
    if not nama then return "" end
    return nama:lower():gsub("%s+", ""):gsub("[^%w]", "")
end

local function ResetFishingState()
    print("[STATE] Reset state fishing...")
    FishingState.IsCasting = false
    FishingState.IsWaitingBite = false
    FishingState.IsReeling = false
    FishingState.BiteDetected = false
    task.wait(0.5)
end

local function HandleError(context)
    FishingState.ErrorCount = FishingState.ErrorCount + 1
    warn(string.format("[ERROR] %s - Count: %d/%d", context, FishingState.ErrorCount, FishingState.MaxErrors))
    
    if FishingState.ErrorCount >= FishingState.MaxErrors then
        print("[RESET] Terlalu banyak error, reset penuh...")
        ResetFishingState()
        FishingState.ErrorCount = 0
        task.wait(3)
    else
        task.wait(1)
    end
end

-- ==================== REMOTES ====================
local net = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")

local function AmbilRemote(nama)
    return net:FindFirstChild(nama)
end

local EquipAlat = AmbilRemote("RE/EquipToolFromHotbar")
local ChargeRod = AmbilRemote("RF/ChargeFishingRod")
local MulaiMini = AmbilRemote("RF/RequestFishingMinigameStarted")
local SelesaiMancing = AmbilRemote("RE/FishingCompleted")
local JualSemua = AmbilRemote("RF/SellAllItems")
local IkanTertangkap = AmbilRemote("RE/FishCaught")
local TextEffect = AmbilRemote("RE/ReplicateTextEffect")  -- ← KEY EVENT!

-- ==================== LOAD DATA IKAN ====================
local berkasTerbuka = "FISHES_DATA.json"
if isfile(berkasTerbuka) then
    local sukses, terdekode = pcall(function()
        return HttpService:JSONDecode(readfile(berkasTerbuka))
    end)
    if sukses and terdekode then
        dataIkan = terdekode
        for tingkat = 1, 7 do
            local kunciTingkat = "Tier" .. tingkat
            if dataIkan[kunciTingkat] then
                for _, ikan in ipairs(dataIkan[kunciTingkat]) do
                    if ikan.Name then
                        pencariIkan[normalisasiNama(ikan.Name)] = ikan
                        pencariIkan[ikan.Name:lower()] = ikan
                        if ikan.Id then
                            pencariIkan["id_" .. tostring(ikan.Id)] = ikan
                        end
                    end
                end
            end
        end
        print("[DATA] " .. #dataIkan .. " ikan dimuat")
    end
end

-- ==================== BOT TELEGRAM ====================
local BotTelegram = {}

function BotTelegram:AmbilChatId(token)
    if not token or token == "" then return nil end
    
    if Config.Telegram.ChatId and Config.Telegram.ChatId ~= "" then
        return Config.Telegram.ChatId
    end
    
    local sukses, hasil = pcall(function()
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
    
    return sukses and hasil or nil
end

function BotTelegram:KirimPesan(infoIkan)
    if not Config.Telegram.Aktif then return end
    if Config.Telegram.TokenBot == "" then return end
    if not infoIkan.Tingkat then return end
    
    local raritasIkan = tingkatKeRaritas[infoIkan.Tingkat] or "TIDAK DIKETAHUI"
    
    -- Filter raritas
    if #Config.Telegram.RaritasTerpilih > 0 then
        local harusKirim = false
        for _, raritasTarget in ipairs(Config.Telegram.RaritasTerpilih) do
            local ikanNorm = string.upper(raritasIkan):gsub("%s+", "")
            local targetNorm = string.upper(raritasTarget):gsub("%s+", "")
            
            if ikanNorm == targetNorm then
                harusKirim = true
                break
            end
        end
        
        if not harusKirim then return end
    end
    
    local chatId = self:AmbilChatId(Config.Telegram.TokenBot)
    if not chatId then return end
    
    local pesan = self:FormatPesan(infoIkan)
    
    pcall(function()
        local url = "https://api.telegram.org/bot" .. Config.Telegram.TokenBot .. "/sendMessage"
        local data = HttpService:JSONEncode({
            chat_id = chatId,
            text = pesan,
            parse_mode = "Markdown"
        })
        
        if http_request then
            http_request({
                Url = url, 
                Method = "POST", 
                Headers = {["Content-Type"] = "application/json"}, 
                Body = data
            })
        elseif syn and syn.request then
            syn.request({
                Url = url, 
                Method = "POST", 
                Headers = {["Content-Type"] = "application/json"}, 
                Body = data
            })
        elseif request then
            request({
                Url = url, 
                Method = "POST", 
                Headers = {["Content-Type"] = "application/json"}, 
                Body = data
            })
        end
    end)
end

function BotTelegram:FormatPesan(infoIkan)
    local raritas = tingkatKeRaritas[infoIkan.Tingkat or 1] or "TIDAK DIKETAHUI"
    local persen = (infoIkan.Kesempatan or 0) * 100
    
    local msg = "```\n===== RhyRu9 FISH IT =====\n"
    msg = msg .. "Pemain: " .. LocalPlayer.Name .. "\n"
    msg = msg .. "Ikan: " .. (infoIkan.Nama or "Unknown") .. "\n"
    msg = msg .. "Raritas: " .. raritas .. "\n"
    msg = msg .. "Tingkat: " .. (infoIkan.Tingkat or 1) .. "\n"
    if persen > 0 then
        msg = msg .. "Kesempatan: " .. string.format("%.6f%%", persen) .. "\n"
    end
    if infoIkan.HargaJual then
        msg = msg .. "Nilai: " .. infoIkan.HargaJual .. " KOIN\n"
    end
    msg = msg .. "```"
    return msg
end

function BotTelegram:KirimPesanTest()
    if Config.Telegram.TokenBot == "" then
        Rayfield:Notify({
            Title = "❌ Error",
            Content = "Token bot kosong!",
            Duration = 3
        })
        return false
    end
    
    local chatId = self:AmbilChatId(Config.Telegram.TokenBot)
    if not chatId then
        Rayfield:Notify({
            Title = "❌ Chat ID Gagal",
            Content = "Kirim '/start' ke bot Anda dulu!",
            Duration = 5
        })
        return false
    end
    
    local pesan = "🎣 RhyRu9 FISH IT v1.2\n\nPlayer: " .. LocalPlayer.Name .. "\nChat ID: " .. chatId .. "\nStatus: Connected ✅"
    
    local berhasil = pcall(function()
        local url = "https://api.telegram.org/bot" .. Config.Telegram.TokenBot .. "/sendMessage"
        
        if http_request then
            http_request({
                Url = url,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode({
                    chat_id = chatId,
                    text = pesan
                })
            })
        end
    end)
    
    if berhasil then
        Rayfield:Notify({
            Title = "✅ Berhasil!",
            Content = "Cek Telegram Anda!",
            Duration = 3
        })
        return true
    else
        Rayfield:Notify({
            Title = "❌ Gagal",
            Content = "Error saat kirim",
            Duration = 3
        })
        return false
    end
end

-- ==================== EVENT LISTENERS ====================

-- LISTENER: Deteksi Ikan Gigit! (REAL-TIME)
if TextEffect then
    print("[LISTENER] ✅ TextEffect connected - Deteksi gigit real-time!")
    
    TextEffect.OnClientEvent:Connect(function(data)
        if not Config.MancingOtomatis then return end
        if not data or not data.TextData then return end
        
        -- CEK: Apakah ini "!" (Exclaim)?
        if data.TextData.EffectType == "Exclaim" then
            print("\n[🎣 GIGIT!] ========================================")
            print("[GIGIT] IKAN MENGGIGIT! Efek '!' terdeteksi!")
            print("[GIGIT] Waktu deteksi: " .. tick())
            
            -- Set flag bite detected
            FishingState.BiteDetected = true
            FishingState.IsWaitingBite = false
            
            print("[GIGIT] Flag bite = TRUE, siap reel in!")
            print("[GIGIT] ========================================\n")
        end
    end)
else
    warn("[LISTENER] ❌ TextEffect TIDAK DITEMUKAN!")
end

-- LISTENER: Ikan Tertangkap
if IkanTertangkap then
    print("[LISTENER] ✅ IkanTertangkap connected!")
    
    local lastUID = nil
    IkanTertangkap.OnClientEvent:Connect(function(data)
        if not data then return end
        
        local nama = type(data) == "string" and data or (data.Name or "Unknown")
        local tingkat = type(data) == "table" and (data.Tier or 1) or 1
        local id = type(data) == "table" and data.Id or nil
        local kesempatan = type(data) == "table" and (data.Chance or 0) or 0
        local harga = type(data) == "table" and (data.SellPrice or 0) or 0
        
        local uid = nama .. "_" .. tingkat .. "_" .. tick()
        if uid == lastUID then return end
        lastUID = uid
        
        local info = pencariIkan[normalisasiNama(nama)] or {
            Nama = nama, Tingkat = tingkat, Id = id or "?",
            Kesempatan = kesempatan, HargaJual = harga
        }
        
        if not info.Tingkat then info.Tingkat = tingkat end
        
        local raritas = tingkatKeRaritas[info.Tingkat] or "TIDAK DIKETAHUI"
        print(string.format("[IKAN] %s | %s | %s koin", nama, raritas, tostring(info.HargaJual or 0)))
        
        BotTelegram:KirimPesan(info)
        
        -- Reset error counter pada success
        FishingState.ErrorCount = 0
        FishingState.IsReeling = false
    end)
else
    warn("[LISTENER] ❌ IkanTertangkap TIDAK DITEMUKAN!")
end

-- ==================== SISTEM MANCING EVENT-BASED + RAPID TAP ====================

local function CastRod()
    print("[CAST] Memulai lempar pancing...")
    FishingState.IsCasting = true
    FishingState.BiteDetected = false
    FishingState.IsWaitingBite = false
    
    -- Step 1: Equip tool
    local equipSukses = false
    for i = 1, 3 do
        local ok = pcall(function()
            EquipAlat:FireServer(1)
        end)
        if ok then
            equipSukses = true
            print("[CAST] Equip berhasil")
            break
        end
        task.wait(0.2)
    end
    
    if not equipSukses then
        HandleError("Equip gagal")
        FishingState.IsCasting = false
        return false
    end
    
    task.wait(0.3)
    
    -- Step 2: Charge rod (15x retry)
    local chargeSukses = false
    local upaya = 0
    
    while upaya < 15 and not chargeSukses do
        upaya = upaya + 1
        
        local ok, hasil = pcall(function()
            return ChargeRod:InvokeServer(tick())
        end)
        
        if ok and hasil then
            chargeSukses = true
            print("[CAST] Charge berhasil (upaya " .. upaya .. "/15)")
            break
        end
        
        task.wait(0.15)
    end
    
    if not chargeSukses then
        HandleError("Charge gagal setelah 15x")
        FishingState.IsCasting = false
        return false
    end
    
    task.wait(0.3)
    
    -- Step 3: Start minigame
    local mulaiSukses = false
    for i = 1, 5 do
        local ok = pcall(function()
            return MulaiMini:InvokeServer(-1.233184814453125, 0.9945034885633273)
        end)
        if ok then
            mulaiSukses = true
            print("[CAST] Minigame dimulai (Perfect Catch)")
            break
        end
        task.wait(0.1)
    end
    
    if not mulaiSukses then
        HandleError("Minigame start gagal")
        FishingState.IsCasting = false
        return false
    end
    
    -- Cast success!
    FishingState.IsCasting = false
    FishingState.IsWaitingBite = true
    FishingState.LastCastTime = tick()
    print("[CAST] ✅ Berhasil! Menunggu ikan gigit...")
    
    return true
end

local function RapidTapReel()
    if FishingState.IsReeling then 
        print("[RAPID-TAP] Sudah reeling, skip")
        return 
    end
    
    print("[RAPID-TAP] 🎣 Memulai RAPID TAPPING SYSTEM...")
    FishingState.IsReeling = true
    FishingState.IsWaitingBite = false
    
    -- Tunggu sebentar sebelum mulai tapping (simulasi reaksi manusia)
    task.wait(0.3)
    
    -- RAPID TAPPING SYSTEM - 50ms interval
    local tapStart = tick()
    local tapDuration = 2.5 -- 2.5 detik rapid tap
    local tapCount = 0
    local maxTaps = math.floor(tapDuration / 0.05) -- 50 taps
    
    print(string.format("[RAPID-TAP] Akan melakukan %d taps (50ms interval)", maxTaps))
    
    while tick() - tapStart < tapDuration and FishingState.IsReeling do
        tapCount = tapCount + 1
        
        -- Fire reel command setiap 50ms
        pcall(function()
            SelesaiMancing:FireServer()
        end)
        
        -- Progress feedback
        if tapCount % 10 == 0 then
            local progress = math.floor((tapCount / maxTaps) * 100)
            print(string.format("[RAPID-TAP] Tap #%d/%d (%d%%)", tapCount, maxTaps, progress))
        end
        
        task.wait(0.05) -- ⚡ 50 MILISECOND DELAY - CORE FEATURE!
    end
    
    print(string.format("[RAPID-TAP] ✅ Selesai! Total %d taps dalam %.2f detik", tapCount, tick() - tapStart))
    
    -- Final reel untuk memastikan
    pcall(function()
        SelesaiMancing:FireServer()
    end)
    
    task.wait(0.3)
    ResetFishingState()
end

local function SistemMancingOtomatis()
    task.spawn(function()
        print("\n╔═══════════════════════════════════════╗")
        print("║   RAPID TAP FISHING SYSTEM v1.2     ║")
        print("║   50ms Tapping + Event Detection!    ║")
        print("╚═══════════════════════════════════════╝\n")
        
        while Config.MancingOtomatis do
            FishingState.IsActive = true
            
            local sukses, err = pcall(function()
                -- Pastikan karakter ada
                if not LocalPlayer.Character or not HumanoidRootPart then
                    repeat task.wait(0.5) until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    Character = LocalPlayer.Character
                    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
                end
                
                -- Cast pancing
                if not FishingState.IsWaitingBite and not FishingState.IsReeling then
                    if CastRod() then
                        print("[MAIN] Cast berhasil, menunggu bite event...")
                    else
                        print("[MAIN] Cast gagal, retry...")
                        task.wait(2)
                        return
                    end
                end
                
                -- Tunggu sampai ikan gigit (event-based!)
                if FishingState.IsWaitingBite then
                    local waitStart = tick()
                    local maxWait = 30 -- Maksimal 30 detik
                    
                    while FishingState.IsWaitingBite and not FishingState.BiteDetected do
                        task.wait(0.1)
                        
                        -- Timeout protection
                        if tick() - waitStart > maxWait then
                            print("[MAIN] Timeout 30s, tidak ada gigitan. Retry...")
                            ResetFishingState()
                            break
                        end
                    end
                    
                    -- Kalau bite detected, REEL DENGAN RAPID TAP!
                    if FishingState.BiteDetected then
                        print("[MAIN] 🎣 Bite terdeteksi! Memulai RAPID TAPPING...")
                        RapidTapReel()
                        task.wait(0.8) -- Cooldown lebih pendek sebelum cast lagi
                    end
                end
                
            end)
            
            if not sukses then
                HandleError("Error Lua: " .. tostring(err))
            end
            
            task.wait(0.5)
        end
        
        FishingState.IsActive = false
        ResetFishingState()
        print("[MAIN] Sistem mancing dihentikan")
    end)
end

-- ==================== FITUR TAMBAHAN ====================

local function JualOtomatis()
    task.spawn(function()
        while Config.JualOtomatis do
            pcall(function() JualSemua:InvokeServer() end)
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
        
        while Config.FlyAktif do
            local cam = Workspace.CurrentCamera
            local move = Vector3.new(0, 0, 0)
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0, 1, 0) end
            
            bv.Velocity = move * Config.KecepatanFly
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
local DataPulau = {
    {Nama = "Fisherman's Island", Posisi = Vector3.new(92, 9, 2768)},
    {Nama = "Arrow Lever", Posisi = Vector3.new(898, 8, -363)},
    {Nama = "Sisyphus Statue", Posisi = Vector3.new(-3740, -136, -1013)},
    {Nama = "Ancient Forest", Posisi = Vector3.new(1481, 11, -302)},
    {Nama = "Weather Machine", Posisi = Vector3.new(-1519, 2, 1908)},
    {Nama = "Coral Reef", Posisi = Vector3.new(-3105, 6, 2218)},
    {Nama = "Tropical Island", Posisi = Vector3.new(-2110, 53, 3649)},
    {Nama = "Kohana", Posisi = Vector3.new(-662, 3, 714)},
    {Nama = "Esoteric Island", Posisi = Vector3.new(2035, 27, 1386)},
    {Nama = "Diamond Lever", Posisi = Vector3.new(1818, 8, -285)},
    {Nama = "Underground Chamber", Posisi = Vector3.new(2098, -92, -703)},
    {Nama = "Volcano", Posisi = Vector3.new(-631, 54, 194)},
    {Nama = "Enchantment Chamber", Posisi = Vector3.new(3255, -1302, 1371)},
    {Nama = "Lost Island", Posisi = Vector3.new(-3717, 5, -1079)},
    {Nama = "Sacred Temple", Posisi = Vector3.new(1475, -22, -630)},
    {Nama = "Crater Island", Posisi = Vector3.new(981, 41, 5080)},
    {Nama = "Double Enchantment Chamber", Posisi = Vector3.new(1480, 127, -590)},
    {Nama = "Treasure Chamber", Posisi = Vector3.new(-3599, -276, -1642)},
    {Nama = "Crescent Lever", Posisi = Vector3.new(1419, 31, 78)},
    {Nama = "Hourglass Diamond Lever", Posisi = Vector3.new(1484, 8, -862)},
    {Nama = "Snowy Island", Posisi = Vector3.new(1627, 4, 3288)}
}

local function TeleportKePulau(indeks)
    if not Config.TeleportAktif then
        Rayfield:Notify({Title = "Error", Content = "Aktifkan teleport dulu!", Duration = 2})
        return
    end
    if DataPulau[indeks] and HumanoidRootPart then
        HumanoidRootPart.CFrame = CFrame.new(DataPulau[indeks].Posisi)
        Rayfield:Notify({Title = "Teleport", Content = "Ke " .. DataPulau[indeks].Nama, Duration = 2})
    end
end

-- ==================== UI CREATION ====================
local function BuatUI()
    -- TAB 1: MANCING
    local Tab1 = Window:CreateTab("🎣 Mancing", 4483362458)
    
    Tab1:CreateSection("Rapid Tap Fishing System")
    
    Tab1:CreateToggle({
        Name = "🔥 Mancing Otomatis (Rapid Tap 50ms!)",
        CurrentValue = false,
        Callback = function(v)
            Config.MancingOtomatis = v
            if v then
                SistemMancingOtomatis()
                Rayfield:Notify({
                    Title = "🔥 Rapid Tap Started!",
                    Content = "50ms tapping system aktif!",
                    Duration = 3
                })
            end
        end
    })
    
    Tab1:CreateToggle({
        Name = "Jual Otomatis",
        CurrentValue = false,
        Callback = function(v)
            Config.JualOtomatis = v
            if v then JualOtomatis() end
        end
    })
    
    Tab1:CreateToggle({
        Name = "Anti AFK",
        CurrentValue = false,
        Callback = function(v)
            Config.AntiAFK = v
            if v then AntiAFK() end
        end
    })
    
    Tab1:CreateSection("⚡ Cara Kerja V1.2")
    Tab1:CreateLabel("✅ Deteksi REAL-TIME kapan ikan gigit")
    Tab1:CreateLabel("✅ Rapid Tap System 50ms interval")
    Tab1:CreateLabel("✅ 50+ taps dalam 2.5 detik")
    Tab1:CreateLabel("✅ Auto-reel saat '!' muncul")
    Tab1:CreateLabel("✅ 15x retry system + error handling")
    
    Tab1:CreateButton({
        Name = "🔄 Reset Fishing State",
        Callback = function()
            ResetFishingState()
            FishingState.ErrorCount = 0
            Rayfield:Notify({
                Title = "State Reset",
                Content = "Fishing state telah direset!",
                Duration = 2
            })
        end
    })

    -- TAB 2: TELEGRAM
    local Tab2 = Window:CreateTab("📱 Telegram", 4483362458)
    
    Tab2:CreateSection("Pengaturan Telegram")
    
    Tab2:CreateToggle({
        Name = "Aktifkan Notifikasi Telegram",
        CurrentValue = false,
        Callback = function(v) 
            Config.Telegram.Aktif = v
        end
    })
    
    Tab2:CreateInput({
        Name = "Token Bot",
        PlaceholderText = "Masukkan token bot Anda",
        RemoveTextAfterFocusLost = false,
        Callback = function(v) 
            Config.Telegram.TokenBot = v
        end
    })
    
    Tab2:CreateButton({
        Name = "Test Kirim Pesan",
        Callback = function()
            BotTelegram:KirimPesanTest()
        end
    })
    
    Tab2:CreateSection("Filter Raritas")
    Tab2:CreateLabel("Kosongkan semua = Terima SEMUA ikan")
    
    local raritasList = {"RAHASIA", "MISTIS", "LEGENDARIS", "EPIK", "LANGKA", "TIDAK UMUM", "UMUM"}
    
    for _, raritas in ipairs(raritasList) do
        Tab2:CreateToggle({
            Name = raritas,
            CurrentValue = false,
            Callback = function(v)
                if v then
                    table.insert(Config.Telegram.RaritasTerpilih, raritas)
                else
                    for i, val in ipairs(Config.Telegram.RaritasTerpilih) do
                        if val == raritas then 
                            table.remove(Config.Telegram.RaritasTerpilih, i) 
                            break 
                        end
                    end
                end
            end
        })
    end

    -- TAB 3: TELEPORT
    local Tab3 = Window:CreateTab("📍 Teleport", 4483362458)
    
    Tab3:CreateSection("Pengaturan Teleport")
    
    Tab3:CreateToggle({
        Name = "Aktifkan Teleport",
        CurrentValue = false,
        Callback = function(v) Config.TeleportAktif = v end
    })
    
    local opsiPulau = {}
    for i, pulau in ipairs(DataPulau) do
        table.insert(opsiPulau, string.format("%d. %s", i, pulau.Nama))
    end
    
    local indeksPulauTerpilih = 1
    
    Tab3:CreateDropdown({
        Name = "Pilih Pulau",
        Options = opsiPulau,
        CurrentOption = {"1. " .. DataPulau[1].Nama},
        Callback = function(Opsi)
            if Opsi and #Opsi > 0 then
                local indeks = tonumber(Opsi[1]:match("^(%d+)%."))
                if indeks then indeksPulauTerpilih = indeks end
            end
        end
    })
    
    Tab3:CreateButton({
        Name = "Teleport ke Pulau Terpilih",
        Callback = function() TeleportKePulau(indeksPulauTerpilih) end
    })
    
    Tab3:CreateSection("Teleport Cepat")
    
    -- Grid layout untuk tombol teleport cepat
    local quickLocations = {
        {1, "📍 Fisherman's Island"},
        {12, "🌋 Volcano"}, 
        {21, "❄️ Snowy Island"},
        {4, "🌳 Ancient Forest"},
        {6, "🐠 Coral Reef"},
        {13, "⚡ Enchantment Chamber"}
    }
    
    for _, loc in ipairs(quickLocations) do
        Tab3:CreateButton({
            Name = loc[2],
            Callback = function() TeleportKePulau(loc[1]) end
        })
    end

    -- TAB 4: UTILITAS
    local Tab4 = Window:CreateTab("⚡ Utilitas", 4483362458)
    
    Tab4:CreateSection("Karakter")
    
    Tab4:CreateSlider({
        Name = "Kecepatan Jalan",
        Range = {16, 500},
        Increment = 1,
        CurrentValue = 16,
        Callback = function(v)
            Config.KecepatanJalan = v
            if Humanoid then Humanoid.WalkSpeed = v end
        end
    })
    
    Tab4:CreateSlider({
        Name = "Kekuatan Lompat",
        Range = {50, 500},
        Increment = 5,
        CurrentValue = 50,
        Callback = function(v)
            Config.KekuatanLompat = v
            if Humanoid then Humanoid.JumpPower = v end
        end
    })
    
    Tab4:CreateButton({
        Name = "Reset Kecepatan Normal",
        Callback = function()
            if Humanoid then
                Humanoid.WalkSpeed = 16
                Humanoid.JumpPower = 50
                Config.KecepatanJalan = 16
                Config.KekuatanLompat = 50
            end
        end
    })
    
    Tab4:CreateSection("Fitur Tambahan")
    
    Tab4:CreateToggle({
        Name = "Mode Terbang",
        CurrentValue = false,
        Callback = function(v)
            Config.FlyAktif = v
            if v then Fly() end
        end
    })
    
    Tab4:CreateSlider({
        Name = "Kecepatan Terbang",
        Range = {10, 300},
        Increment = 5,
        CurrentValue = 50,
        Callback = function(v) Config.KecepatanFly = v end
    })
    
    Tab4:CreateToggle({
        Name = "NoClip",
        CurrentValue = false,
        Callback = function(v)
            Config.NoClip = v
            if v then NoClip() end
        end
    })
    
    Tab4:CreateSection("Visual")
    
    Tab4:CreateButton({
        Name = "Fullbright",
        Callback = function()
            Lighting.Brightness = 2
            Lighting.ClockTime = 12
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
        end
    })
    
    Tab4:CreateButton({
        Name = "Hapus Kabut",
        Callback = function()
            Lighting.FogEnd = 100000
        end
    })

    -- TAB 5: INFO & STATUS
    local Tab5 = Window:CreateTab("ℹ️ Info", 4483362458)
    
    Tab5:CreateSection("Status Sistem")
    
    local statusLabel = Tab5:CreateLabel("Fishing State: IDLE")
    local errorLabel = Tab5:CreateLabel("Error Count: 0")
    local biteLabel = Tab5:CreateLabel("Last Bite: Never")
    local tapLabel = Tab5:CreateLabel("Tap Speed: 50ms")
    
    -- Update status real-time
    task.spawn(function()
        while true do
            statusLabel:SetText("Fishing State: " .. (
                FishingState.IsActive and "ACTIVE" or "IDLE"
            ))
            errorLabel:SetText("Error Count: " .. FishingState.ErrorCount)
            tapLabel:SetText("Tap Speed: 50ms")
            
            if FishingState.BiteDetected then
                biteLabel:SetText("Last Bite: " .. os.date("%H:%M:%S"))
            end
            
            task.wait(1)
        end
    end)
    
    Tab5:CreateSection("Tentang Script")
    
    Tab5:CreateParagraph({
        Title = "RhyRu9 FISH IT v1.2",
        Content = "Developer: RhyRu9\nUpdate: 22 Oktober 2025\n\n✨ FITUR BARU:\n• Rapid Tap System (50ms)\n• Event-Based Fishing\n• Real-time Bite Detection\n• Enhanced Error Handling"
    })
    
    Tab5:CreateSection("Cara Kerja")
    
    Tab5:CreateParagraph({
        Title = "Rapid Tap System",
        Content = "1. Cast rod → Tunggu event\n2. Deteksi '!' (RE/ReplicateTextEffect)\n3. Rapid Tap 50ms (50+ taps)\n4. Auto reel dengan tapping cepat\n5. Tunggu notifikasi ikan tertangkap\n6. Repeat otomatis"
    })
    
    Tab5:CreateButton({
        Name = "🔄 Restart Script",
        Callback = function()
            Rayfield:Notify({
                Title = "Restarting...",
                Content = "Script akan di-restart",
                Duration = 2
            })
            task.wait(2)
            -- Simulasi restart
            ResetFishingState()
            Config.MancingOtomatis = false
            task.wait(1)
            Config.MancingOtomatis = true
            SistemMancingOtomatis()
        end
    })
end

-- ==================== CHARACTER HANDLER ====================
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
    Humanoid = char:WaitForChild("Humanoid")
    
    task.wait(2)
    
    -- Restore settings
    if Humanoid then
        Humanoid.WalkSpeed = Config.KecepatanJalan
        Humanoid.JumpPower = Config.KekuatanLompat
    end
    
    -- Restart systems if they were active
    if Config.MancingOtomatis then
        task.wait(2)
        SistemMancingOtomatis()
    end
    
    if Config.JualOtomatis then
        JualOtomatis()
    end
    
    if Config.AntiAFK then
        AntiAFK()
    end
    
    if Config.FlyAktif then
        Fly()
    end
    
    if Config.NoClip then
        NoClip()
    end
end)

-- ==================== ANTI-IDLE ====================
local function PreventIdle()
    task.spawn(function()
        while true do
            -- Prevent game from thinking we're idle
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
            task.wait(60) -- Every minute
        end
    end)
end

-- ==================== INITIALIZATION ====================
local function Initialize()
    BuatUI()
    
    -- Start anti-idle
    PreventIdle()
    
    -- Apply initial character settings
    if Humanoid then
        Humanoid.WalkSpeed = Config.KecepatanJalan
        Humanoid.JumpPower = Config.KekuatanLompat
    end
    
    print([[
    
    ╔═══════════════════════════════════════╗
    ║        RhyRu9 FISH IT v1.2           ║
    ║         RAPID TAP SYSTEM             ║
    ║                                      ║
    ║  ⚡ Rapid Tap 50ms Interval          ║
    ║  ✅ Real-time Bite Detection         ║
    ║  🔥 50+ Taps dalam 2.5 Detik        ║
    ║  ✅ Enhanced Error Handling          ║
    ║  ✅ Telegram Notifications           ║
    ║                                      ║
    ║      Developer: RhyRu9 © 2025        ║
    ╚═══════════════════════════════════════╝
    
    ]])
    
    Rayfield:Notify({
        Title = "✅ RhyRu9 FISH IT v1.2 Loaded",
        Content = "Rapid Tap System Ready!",
        Duration = 5
    })
end

-- ==================== ERROR HANDLING ====================
local function GlobalErrorHandler(err)
    warn("[GLOBAL ERROR] " .. tostring(err))
    
    -- Attempt recovery
    pcall(function()
        ResetFishingState()
        FishingState.ErrorCount = 0
    end)
end

-- ==================== MAIN EXECUTION ====================
xpcall(function()
    Initialize()
end, GlobalErrorHandler)

-- Auto-reconnect if script stops unexpectedly
task.spawn(function()
    while true do
        if Config.MancingOtomatis and not FishingState.IsActive then
            warn("[AUTO-RECOVERY] Fishing stopped unexpectedly, restarting...")
            SistemMancingOtomatis()
        end
        task.wait(10)
    end
end)
