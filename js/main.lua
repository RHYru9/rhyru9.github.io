-- RhyRu9 FISH IT - VERSI LENGKAP FINAL
-- DEVELOPER BY RhyRu9
-- Update: 18 Oct 2025 - COMPLETE VERSION
-- Fitur: 15x Retry, 3 Detik Wait, Perfect Catch, Anti AFK, Telegram Notifications

print("Memuat RhyRu9 FISH IT - VERSI LENGKAP FINAL...")

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
    Name = "RhyRu9 FISH IT - LENGKAP",
    LoadingTitle = "RhyRu9 FISH IT - VERSI LENGKAP",
    LoadingSubtitle = "DEVELOPER BY RhyRu9",
    ConfigurationSaving = { Enabled = false },
})

-- Konfigurasi
local Config = {
    PemancingOtomatis = false,
    TangkapanSempurna = false,
    JualOtomatis = false,
    AntiAFK = false,
    TeleportAktif = false,
    KecepatanJalan = 16,
    KekuatanLompat = 50,
    FlyEnabled = false,
    FlySpeed = 50,
    NoClip = false,
    
    Telegram = {
        Aktif = false,
        TokenBot = "",
        IDChat = "",
        RaritasTerpilih = {}
    }
}

-- Data
local JumlahError = 0
local MaksimalError = 3
local dataIkan = {}
local pencariIkan = {}
local tingkatKeRaritas = {
    [1] = "UMUM", [2] = "TIDAK UMUM", [3] = "LANGKA",
    [4] = "EPIK", [5] = "LEGENDARIS", [6] = "MISTIS", [7] = "RAHASIA"
}

-- Fungsi Pembantu
local function normalisasiNama(nama)
    if not nama then return "" end
    return nama:lower():gsub("%s+", ""):gsub("[^%w]", "")
end

-- Remotes
local net = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")

local function AmbilRemote(nama)
    return net:FindFirstChild(nama)
end

local EquipAlat = AmbilRemote("RE/EquipToolFromHotbar")
local PasakRod = AmbilRemote("RF/ChargeFishingRod")
local MulaiMini = AmbilRemote("RF/RequestFishingMinigameStarted")
local SelesaiBayak = AmbilRemote("RE/FishingCompleted")
local JualSemua = AmbilRemote("RF/SellAllItems")
local IkanTangkap = AmbilRemote("RE/FishCaught")

-- Muat Data Ikan
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
    end
end

-- Bot Telegram
local BotTelegram = {}

function BotTelegram:KirimPesanTelegram(infoIkan)
    if not Config.Telegram.Aktif then return end
    if Config.Telegram.TokenBot == "" or Config.Telegram.IDChat == "" then return end
    if not infoIkan.Tingkat then return end
    
    local raritasIkan = tingkatKeRaritas[infoIkan.Tingkat] or "TIDAK DIKETAHUI"
    
    if #Config.Telegram.RaritasTerpilih > 0 then
        local harusKirim = false
        for _, raritasTarget in ipairs(Config.Telegram.RaritasTerpilih) do
            if string.upper(raritasIkan):gsub("%s+", "") == string.upper(raritasTarget):gsub("%s+", "") then
                harusKirim = true
                break
            end
        end
        if not harusKirim then return end
    end
    
    local pesan = self:FormatPesanTelegram(infoIkan)
    
    pcall(function()
        local url = "https://api.telegram.org/bot" .. Config.Telegram.TokenBot .. "/sendMessage"
        local data = HttpService:JSONEncode({
            chat_id = Config.Telegram.IDChat,
            text = pesan,
            parse_mode = "Markdown"
        })
        
        if http_request then
            http_request({Url = url, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = data})
        elseif syn and syn.request then
            syn.request({Url = url, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = data})
        end
    end)
end

function BotTelegram:FormatPesanTelegram(infoIkan)
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

-- Listener Ikan
if IkanTangkap then
    local lastUID = nil
    IkanTangkap.OnClientEvent:Connect(function(data)
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
        local tampilKesempatan = info.Kesempatan > 0 and string.format(" (%.6f%%)", info.Kesempatan * 100) or ""
        print(string.format("[TANGKAP] %s | Raritas: %s | Harga: %s koin%s",
            nama, raritas, tostring(info.HargaJual or 0), tampilKesempatan))
        
        BotTelegram:KirimPesanTelegram(info)
        JumlahError = 0
    end)
end

-- Fungsi Reset
local function ResetPenuh()
    print("[RESET] Melakukan reset penuh semua status...")
    JumlahError = 0
    task.wait(3)
    print("[RESET] Status bersih, siap memancing lagi")
end

-- ===== PEMANCING OTOMATIS (LOGIKA RHYRU9 - 15X RETRY + 3 DETIK WAIT) =====
local PemancingAktif = false

local function PemancingOtomatisV1()
    task.spawn(function()
        print("[PEMANCING OTOMATIS] Dimulai - Logika RhyRu9 (15x Retry + 3s Wait)")
        
        while Config.PemancingOtomatis do
            PemancingAktif = true
            
            local sukses, err = pcall(function()
                -- Validasi karakter
                if not LocalPlayer.Character or not HumanoidRootPart then
                    repeat task.wait(0.5) until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    Character = LocalPlayer.Character
                    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
                end

                -- LANGKAH 1: PASANG ALAT (3x retry)
                local equipSukses = false
                for i = 1, 3 do
                    local ok = pcall(function()
                        EquipAlat:FireServer(1)
                    end)
                    if ok then
                        equipSukses = true
                        print("[PASANG] Berhasil")
                        break
                    end
                    task.wait(0.2)
                end
                
                if not equipSukses then
                    JumlahError = JumlahError + 1
                    print("[ERROR] Pasang gagal (" .. JumlahError .. "/" .. MaksimalError .. ")")
                    if JumlahError >= MaksimalError then
                        ResetPenuh()
                    end
                    task.wait(1)
                    return
                end
                
                task.wait(0.3)

                -- LANGKAH 2: PASAK ROD (15X RETRY AGRESIF - LOGIKA RHYRU9)
                local pasakSukses = false
                local upayaPasak = 0
                
                while upayaPasak < 15 and not pasakSukses do
                    upayaPasak = upayaPasak + 1
                    
                    local ok, hasil = pcall(function()
                        return PasakRod:InvokeServer(tick())
                    end)
                    
                    if ok and hasil then
                        pasakSukses = true
                        print("[PASAK] Berhasil (upaya " .. upayaPasak .. "/15)")
                        break
                    end
                    
                    print("[PASAK] Coba ulang " .. upayaPasak .. "/15...")
                    task.wait(0.15)
                end
                
                if not pasakSukses then
                    JumlahError = JumlahError + 1
                    print("[ERROR] Pasak Rod gagal (" .. JumlahError .. "/" .. MaksimalError .. ") - KRITIS!")
                    if JumlahError >= MaksimalError then
                        print("[RESET] Error Pasak Rod terlalu banyak!")
                        ResetPenuh()
                    end
                    task.wait(2)
                    return
                end

                task.wait(0.3)

                -- LANGKAH 3: MULAI MINIGAME (PERFECT CATCH - LOGIKA RHYRU9)
                local mulaiSukses = false
                for i = 1, 5 do
                    local ok = pcall(function()
                        return MulaiMini:InvokeServer(-1.233184814453125, 0.9945034885633273)
                    end)
                    if ok then
                        mulaiSukses = true
                        print("[MULAI] Minigame dimulai (Perfect Catch)")
                        break
                    end
                    task.wait(0.1)
                end
                
                if not mulaiSukses then
                    JumlahError = JumlahError + 1
                    print("[ERROR] Mulai minigame gagal (" .. JumlahError .. "/" .. MaksimalError .. ")")
                    if JumlahError >= MaksimalError then
                        ResetPenuh()
                    end
                    task.wait(1)
                    return
                end

                -- LANGKAH 4: TUNGGU 3 DETIK (LOGIKA RHYRU9)
                print("[TUNGGU] Menunggu 3 detik untuk tangkap...")
                task.wait(3)

                -- LANGKAH 5: SELESAI PEMANCING
                local selesaiSukses = false
                for i = 1, 3 do
                    local ok = pcall(function()
                        SelesaiBayak:FireServer()
                    end)
                    if ok then
                        selesaiSukses = true
                        print("[SELESAI] Ikan tertangkap!")
                        break
                    end
                    task.wait(0.1)
                end
                
                if not selesaiSukses then
                    JumlahError = JumlahError + 1
                    print("[ERROR] Selesai gagal (" .. JumlahError .. "/" .. MaksimalError .. ")")
                    if JumlahError >= MaksimalError then
                        ResetPenuh()
                    end
                    task.wait(1)
                    return
                end
                
                -- BERHASIL - RESET ERROR
                JumlahError = 0
                task.wait(0.2)
            end)

            if not sukses then
                JumlahError = JumlahError + 1
                warn("[ERROR] Error Lua (" .. JumlahError .. "/" .. MaksimalError .. "): " .. tostring(err))
                
                if JumlahError >= MaksimalError then
                    print("[RESET] Terlalu banyak error!")
                    ResetPenuh()
                else
                    task.wait(1)
                end
            end
        end
        
        PemancingAktif = false
        JumlahError = 0
        print("[PEMANCING OTOMATIS] Berhenti")
    end)
end

-- Auto Sell
local function JualOtomatis()
    task.spawn(function()
        while Config.JualOtomatis do
            pcall(function() JualSemua:InvokeServer() end)
            task.wait(10)
        end
    end)
end

-- ===== ANTI AFK (LOGIKA RHYRU9) =====
local function AntiAFK()
    task.spawn(function()
        print("[ANTI AFK] Dimulai (RhyRu9 Logic)")
        while Config.AntiAFK do
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
            task.wait(30) -- Setiap 30 detik seperti RhyRu9
        end
        print("[ANTI AFK] Berhenti")
    end)
end

-- Fly System
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

-- NoClip
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

-- Data Pulau (21 lokasi dari RhyRu9)
local DataPulau = {
    {Nama = "Pulau Nelayan", Posisi = Vector3.new(92, 9, 2768)},
    {Nama = "Arrow Lever", Posisi = Vector3.new(898, 8, -363)},
    {Nama = "Patung Sisyphus", Posisi = Vector3.new(-3740, -136, -1013)},
    {Nama = "Hutan Kuno", Posisi = Vector3.new(1481, 11, -302)},
    {Nama = "Mesin Cuaca", Posisi = Vector3.new(-1519, 2, 1908)},
    {Nama = "Terumbu Karang", Posisi = Vector3.new(-3105, 6, 2218)},
    {Nama = "Pulau Tropis", Posisi = Vector3.new(-2110, 53, 3649)},
    {Nama = "Kohana", Posisi = Vector3.new(-662, 3, 714)},
    {Nama = "Pulau Esoterik", Posisi = Vector3.new(2035, 27, 1386)},
    {Nama = "Diamond Lever", Posisi = Vector3.new(1818, 8, -285)},
    {Nama = "Ruang Bawah Tanah", Posisi = Vector3.new(2098, -92, -703)},
    {Nama = "Gunung Berapi", Posisi = Vector3.new(-631, 54, 194)},
    {Nama = "Ruang Pesona", Posisi = Vector3.new(3255, -1302, 1371)},
    {Nama = "Pulau Hilang", Posisi = Vector3.new(-3717, 5, -1079)},
    {Nama = "Kuil Suci", Posisi = Vector3.new(1475, -22, -630)},
    {Nama = "Pulau Crater", Posisi = Vector3.new(981, 41, 5080)},
    {Nama = "Ruang Pesona Ganda", Posisi = Vector3.new(1480, 127, -590)},
    {Nama = "Ruang Harta", Posisi = Vector3.new(-3599, -276, -1642)},
    {Nama = "Crescent Lever", Posisi = Vector3.new(1419, 31, 78)},
    {Nama = "Hourglass Diamond Lever", Posisi = Vector3.new(1484, 8, -862)},
    {Nama = "Pulau Salju", Posisi = Vector3.new(1627, 4, 3288)}
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

-- ===== UI CREATION =====
local function BuatUI()
    -- TAB 1: PEMANCING
    local Tab1 = Window:CreateTab("🎣 Pemancing", 4483362458)
    
    Tab1:CreateSection("Pemancing Otomatis")
    
    Tab1:CreateToggle({
        Name = "Pemancing Otomatis (RhyRu9)",
        CurrentValue = false,
        Callback = function(v)
            Config.PemancingOtomatis = v
            if v then
                PemancingOtomatisV1()
                Rayfield:Notify({
                    Title = "Pemancing Dimulai",
                    Content = "15x Retry + 3s Wait + Perfect Catch!",
                    Duration = 3
                })
            end
        end
    })
    
    Tab1:CreateToggle({
        Name = "Jual Otomatis (10 detik)",
        CurrentValue = false,
        Callback = function(v)
            Config.JualOtomatis = v
            if v then JualOtomatis() end
        end
    })
    
    Tab1:CreateToggle({
        Name = "Anti AFK (30 detik)",
        CurrentValue = false,
        Callback = function(v)
            Config.AntiAFK = v
            if v then AntiAFK() end
        end
    })
    
    Tab1:CreateSection("Informasi Sistem")
    Tab1:CreateLabel("Logika: RhyRu9 (15x Retry)")
    Tab1:CreateLabel("Wait Time: 3 Detik")
    Tab1:CreateLabel("Perfect Catch: Aktif")
    Tab1:CreateLabel("Max Error: 3x sebelum reset")
    
    -- TAB 2: TELEGRAM
    local Tab2 = Window:CreateTab("📱 Telegram", 4483362458)
    
    Tab2:CreateSection("Pengaturan Telegram")
    
    Tab2:CreateToggle({
        Name = "Aktifkan Telegram",
        CurrentValue = false,
        Callback = function(v) Config.Telegram.Aktif = v end
    })
    
    Tab2:CreateInput({
        Name = "Token Bot",
        PlaceholderText = "Masukkan token bot",
        RemoveTextAfterFocusLost = false,
        Callback = function(v) Config.Telegram.TokenBot = v end
    })
    
    Tab2:CreateInput({
        Name = "ID Chat",
        PlaceholderText = "Masukkan chat ID",
        RemoveTextAfterFocusLost = false,
        Callback = function(v) Config.Telegram.IDChat = v end
    })
    
    Tab2:CreateSection("Pilih Raritas untuk Notifikasi")
    
    Tab2:CreateToggle({
        Name = "RAHASIA (Tier 7)",
        CurrentValue = false,
        Callback = function(v)
            if v then
                table.insert(Config.Telegram.RaritasTerpilih, "RAHASIA")
            else
                for i, val in ipairs(Config.Telegram.RaritasTerpilih) do
                    if val == "RAHASIA" then table.remove(Config.Telegram.RaritasTerpilih, i) end
                end
            end
        end
    })
    
    Tab2:CreateToggle({
        Name = "MISTIS (Tier 6)",
        CurrentValue = false,
        Callback = function(v)
            if v then
                table.insert(Config.Telegram.RaritasTerpilih, "MISTIS")
            else
                for i, val in ipairs(Config.Telegram.RaritasTerpilih) do
                    if val == "MISTIS" then table.remove(Config.Telegram.RaritasTerpilih, i) end
                end
            end
        end
    })
    
    Tab2:CreateToggle({
        Name = "LEGENDARIS (Tier 5)",
        CurrentValue = false,
        Callback = function(v)
            if v then
                table.insert(Config.Telegram.RaritasTerpilih, "LEGENDARIS")
            else
                for i, val in ipairs(Config.Telegram.RaritasTerpilih) do
                    if val == "LEGENDARIS" then table.remove(Config.Telegram.RaritasTerpilih, i) end
                end
            end
        end
    })
    
    Tab2:CreateToggle({
        Name = "EPIK (Tier 4)",
        CurrentValue = false,
        Callback = function(v)
            if v then
                table.insert(Config.Telegram.RaritasTerpilih, "EPIK")
            else
                for i, val in ipairs(Config.Telegram.RaritasTerpilih) do
                    if val == "EPIK" then table.remove(Config.Telegram.RaritasTerpilih, i) end
                end
            end
        end
    })
    
    -- TAB 3: TELEPORT
    local Tab3 = Window:CreateTab("📍 Teleport", 4483362458)
    
    Tab3:CreateSection("Pengaturan Teleport")
    
    Tab3:CreateToggle({
        Name = "Aktifkan Teleport",
        CurrentValue = false,
        Callback = function(v) Config.TeleportAktif = v end
    })
    
    local opsiBulau = {}
    for i, pulau in ipairs(DataPulau) do
        table.insert(opsiBulau, string.format("%d. %s", i, pulau.Nama))
    end
    
    local indeksPulauTerpilih = 1
    
    Tab3:CreateDropdown({
        Name = "Pilih Pulau",
        Options = opsiBulau,
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
    
    Tab3:CreateButton({
        Name = "📍 Pulau Nelayan",
        Callback = function() TeleportKePulau(1) end
    })
    
    Tab3:CreateButton({
        Name = "🌋 Gunung Berapi",
        Callback = function() TeleportKePulau(12) end
    })
    
    Tab3:CreateButton({
        Name = "❄️ Pulau Salju",
        Callback = function() TeleportKePulau(21) end
    })
    
    -- TAB 4: UTILITY
    local Tab4 = Window:CreateTab("⚡ Utility", 4483362458)
    
    Tab4:CreateSection("Kecepatan Karakter")
    
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
        Name = "Reset ke Normal",
        Callback = function()
            if Humanoid then
                Humanoid.WalkSpeed = 16
                Humanoid.JumpPower = 50
                Config.KecepatanJalan = 16
                Config.KekuatanLompat = 50
                Rayfield:Notify({Title = "Reset", Content = "Kecepatan normal", Duration = 2})
            end
        end
    })
    
    Tab4:CreateSection("Fitur Tambahan")
    
    Tab4:CreateToggle({
        Name = "Fly Mode",
        CurrentValue = false,
        Callback = function(v)
            Config.FlyEnabled = v
            if v then Fly() end
        end
    })
    
    Tab4:CreateSlider({
        Name = "Fly Speed",
        Range = {10, 300},
        Increment = 5,
        CurrentValue = 50,
        Callback = function(v) Config.FlySpeed = v end
    })
    
    Tab4:CreateToggle({
        Name = "NoClip",
        CurrentValue = false,
        Callback = function(v)
            Config.NoClip = v
            if v then NoClip() end
        end
    })
    
    Tab4:CreateButton({
        Name = "Fullbright",
        Callback = function()
            Lighting.Brightness = 2
            Lighting.ClockTime = 12
            Lighting.FogEnd = 100000
            Lighting.Ambient = Color3.new(1, 1, 1)
            Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
            Rayfield:Notify({Title = "Fullbright", Content = "Pencahayaan maksimal!", Duration = 2})
        end
    })
    
    Tab4:CreateButton({
        Name = "Remove Fog",
        Callback = function()
            Lighting.FogEnd = 100000
            Lighting.FogStart = 0
            Rayfield:Notify({Title = "Fog Removed", Content = "Jarak pandang maksimal!", Duration = 2})
        end
    })
    
    Tab4:CreateButton({
        Name = "Respawn Karakter",
        Callback = function()
            if LocalPlayer.Character then
                LocalPlayer.Character:BreakJoints()
                Rayfield:Notify({Title = "Respawn", Content = "Karakter respawn...", Duration = 2})
            end
        end
    })
    
    -- TAB 5: INFO
    local Tab5 = Window:CreateTab("ℹ️ Info", 4483362458)
    
    Tab5:CreateSection("Tentang Script")
    
    Tab5:CreateParagraph({
        Title = "RhyRu9 FISH IT - LENGKAP",
        Content = "Developer: RhyRu9\nUpdate: 18 Oktober 2025\nVersi: 1.0 Final\n\nScript auto fishing terlengkap dengan sistem RhyRu9 yang stabil dan efisien."
    })
    
    Tab5:CreateSection("Fitur Utama")
    
    Tab5:CreateParagraph({
        Title = "🎣 Sistem Pemancing",
        Content = "• Logika RhyRu9: 15x Retry pada Rod Charge\n• Wait Time: 3 Detik untuk Perfect Catch\n• Auto Recovery: Reset otomatis setelah 3x error\n• Perfect Catch: Nilai optimal (-1.233, 0.994)\n• Auto Sell: Setiap 10 detik\n• Anti AFK: Setiap 30 detik"
    })
    
    Tab5:CreateParagraph({
        Title = "📱 Telegram Notifications",
        Content = "• Filter by Rarity: RAHASIA, MISTIS, LEGENDARIS, EPIK\n• Info Lengkap: Nama, Raritas, Tingkat, Kesempatan, Harga\n• Real-time: Notifikasi instant saat tangkap\n• Custom: Pilih raritas yang diinginkan"
    })
    
    Tab5:CreateParagraph({
        Title = "📍 Sistem Teleport",
        Content = "• 21 Lokasi: Semua pulau tersedia\n• Teleport Cepat: 3 lokasi populer\n• Safety Check: Validasi sebelum teleport\n• Dropdown Menu: Pilih pulau dengan mudah"
    })
    
    Tab5:CreateParagraph({
        Title = "⚡ Utility Features",
        Content = "• Speed Control: Walk Speed (16-500)\n• Jump Control: Jump Power (50-500)\n• Fly Mode: WASD + Space/Shift\n• NoClip: Tembus dinding\n• Fullbright: Pencahayaan maksimal\n• Remove Fog: Jarak pandang unlimited"
    })
    
    Tab5:CreateSection("Cara Menggunakan")
    
    Tab5:CreateParagraph({
        Title = "Setup Telegram (Opsional)",
        Content = "1. Buka @BotFather di Telegram\n2. Ketik /newbot, ikuti instruksi\n3. Salin Token Bot\n4. Buka @userinfobot untuk Chat ID\n5. Masukkan di tab Telegram\n6. Pilih raritas ikan"
    })
    
    Tab5:CreateParagraph({
        Title = "Mulai Memancing",
        Content = "1. Pergi ke lokasi fishing\n2. Aktifkan Pemancing Otomatis\n3. Aktifkan Auto Sell (opsional)\n4. Aktifkan Anti AFK\n5. Monitor di console (F9)"
    })
    
    Tab5:CreateSection("Informasi Teknis")
    
    Tab5:CreateParagraph({
        Title = "Sistem Error Handling",
        Content = "Max Error: 3x sebelum Full Reset\nRetry: 15x untuk Rod Charge\nCooldown: 3 detik setelah reset\nRecovery: Otomatis restart setelah error\n\nStatus: ✅ STABIL"
    })
    
    Tab5:CreateLabel("━━━━━━━━━━━━━━━━━━━━")
    Tab5:CreateLabel("Script by RhyRu9 © 2025")
    Tab5:CreateLabel("Status: ✅ ONLINE")
    Tab5:CreateLabel("Versi: 1.0 Final")
    
    Rayfield:Notify({
        Title = "✅ UI Loaded",
        Content = "Semua tab berhasil dimuat! Sistem RhyRu9 siap!",
        Duration = 3
    })
end

-- Character Respawn Handler
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
    Humanoid = char:WaitForChild("Humanoid")
    
    task.wait(2)
    
    -- Reapply settings
    if Humanoid then
        Humanoid.WalkSpeed = Config.KecepatanJalan
        Humanoid.JumpPower = Config.KekuatanLompat
    end
    
    -- Restart features if active
    if Config.PemancingOtomatis then
        task.wait(2)
        PemancingOtomatisV1()
    end
    
    if Config.JualOtomatis then
        task.wait(1)
        JualOtomatis()
    end
    
    if Config.AntiAFK then
        task.wait(1)
        AntiAFK()
    end
    
    if Config.FlyEnabled then
        task.wait(1)
        Fly()
    end
    
    if Config.NoClip then
        task.wait(1)
        NoClip()
    end
end)

-- Main Execution
local sukses, err = pcall(function()
    BuatUI()
end)

if sukses then
    print("=======================================")
    print("  RhyRu9 FISH IT - VERSI LENGKAP")
    print("  Developer: RhyRu9")
    print("  Update: 18 Oktober 2025")
    print("  Status: READY")
    print("=======================================")
    print("  FITUR LENGKAP:")
    print("  ✅ Tab Pemancing (RhyRu9 Logic)")
    print("  ✅ Tab Telegram (Notifications)")
    print("  ✅ Tab Teleport (21 Lokasi)")
    print("  ✅ Tab Utility (Speed, Fly, NoClip)")
    print("  ✅ Tab Info (Dokumentasi)")
    print("=======================================")
    print("  SISTEM PEMANCING:")
    print("  • Logika: RhyRu9 (15x Retry)")
    print("  • Wait: 3 Detik Perfect Catch")
    print("  • Auto Sell: 10 Detik")
    print("  • Anti AFK: 30 Detik")
    print("  • Error Handler: 3x Max")
    print("=======================================")
    print("  STATUS: ✅ ONLINE")
    print("=======================================")
else
    warn("ERROR: " .. tostring(err))
end
