-- RhyRu9 FISH IT v1.0
-- DEVELOPER BY RhyRu9
-- Update: 19 Oct 2025
-- Fitur: 15x Retry System, 3 Detik Wait, Perfect Catch, Anti AFK, Notifikasi Telegram (FIXED)

print("Memuat RhyRu9 FISH IT v1.0...")

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
    Name = "RhyRu9 FISH IT v1.0",
    LoadingTitle = "RhyRu9 FISH IT",
    LoadingSubtitle = "DEVELOPER BY RhyRu9",
    ConfigurationSaving = { Enabled = false },
})

-- Konfigurasi
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
        ChatId = "", -- SIMPAN Chat ID
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
local ChargeRod = AmbilRemote("RF/ChargeFishingRod")
local MulaiMini = AmbilRemote("RF/RequestFishingMinigameStarted")
local SelesaiMancing = AmbilRemote("RE/FishingCompleted")
local JualSemua = AmbilRemote("RF/SellAllItems")
local IkanTertangkap = AmbilRemote("RE/FishCaught")

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

function BotTelegram:AmbilChatId(token)
    if not token or token == "" then return nil end
    
    -- Jika sudah ada Chat ID tersimpan, gunakan itu
    if Config.Telegram.ChatId and Config.Telegram.ChatId ~= "" then
        print("[TELEGRAM] Menggunakan Chat ID tersimpan: " .. Config.Telegram.ChatId)
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
                        print("[TELEGRAM] Chat ID ditemukan: " .. chatId)
                        Config.Telegram.ChatId = chatId -- SIMPAN
                        return chatId
                    end
                end
            else
                warn("[TELEGRAM] Tidak ada pesan ditemukan. Kirim pesan '/start' ke bot Anda!")
                return nil
            end
        end
        
        return nil
    end)
    
    if sukses and hasil then 
        return hasil 
    else
        warn("[TELEGRAM] Gagal mengambil Chat ID: " .. tostring(hasil))
        return nil
    end
end

function BotTelegram:KirimPesan(infoIkan)
    print("[TELEGRAM] === KirimPesan dipanggil ===")
    
    if not Config.Telegram.Aktif then 
        print("[TELEGRAM] ❌ Telegram tidak aktif")
        return 
    end
    
    if Config.Telegram.TokenBot == "" then 
        print("[TELEGRAM] ❌ Token bot kosong")
        return 
    end
    
    if not infoIkan.Tingkat then 
        print("[TELEGRAM] ❌ Tingkat ikan tidak ada")
        return 
    end
    
    local raritasIkan = tingkatKeRaritas[infoIkan.Tingkat] or "TIDAK DIKETAHUI"
    print("[TELEGRAM] 📊 Ikan: " .. (infoIkan.Nama or "Unknown") .. " | Raritas: " .. raritasIkan .. " | Tier: " .. tostring(infoIkan.Tingkat))
    
    -- FILTER: Jika ada filter aktif, cek cocok atau tidak
    if #Config.Telegram.RaritasTerpilih > 0 then
        print("[TELEGRAM] 🔍 Filter aktif: " .. table.concat(Config.Telegram.RaritasTerpilih, ", "))
        
        local harusKirim = false
        for _, raritasTarget in ipairs(Config.Telegram.RaritasTerpilih) do
            local ikanNormalized = string.upper(raritasIkan):gsub("%s+", "")
            local targetNormalized = string.upper(raritasTarget):gsub("%s+", "")
            
            if ikanNormalized == targetNormalized then
                harusKirim = true
                print("[TELEGRAM] ✅ COCOK dengan filter: " .. raritasTarget)
                break
            end
        end
        
        if not harusKirim then 
            print("[TELEGRAM] ❌ Tidak cocok filter, skip")
            return 
        end
    else
        print("[TELEGRAM] ⚠️ Tidak ada filter, KIRIM SEMUA IKAN")
    end
    
    -- Ambil Chat ID (akan pakai yang tersimpan jika ada)
    local chatId = self:AmbilChatId(Config.Telegram.TokenBot)
    if not chatId then
        warn("[TELEGRAM] ❌ Tidak dapat mengambil Chat ID")
        return
    end
    
    local pesan = self:FormatPesan(infoIkan)
    print("[TELEGRAM] 📝 Mengirim ke Chat ID: " .. chatId)
    
    local berhasil, error = pcall(function()
        local url = "https://api.telegram.org/bot" .. Config.Telegram.TokenBot .. "/sendMessage"
        local data = HttpService:JSONEncode({
            chat_id = chatId,
            text = pesan,
            parse_mode = "Markdown"
        })
        
        local response = nil
        
        if http_request then
            print("[TELEGRAM] 🚀 Mengirim via http_request...")
            response = http_request({
                Url = url, 
                Method = "POST", 
                Headers = {["Content-Type"] = "application/json"}, 
                Body = data
            })
        elseif syn and syn.request then
            print("[TELEGRAM] 🚀 Mengirim via syn.request...")
            response = syn.request({
                Url = url, 
                Method = "POST", 
                Headers = {["Content-Type"] = "application/json"}, 
                Body = data
            })
        elseif request then
            print("[TELEGRAM] 🚀 Mengirim via request...")
            response = request({
                Url = url, 
                Method = "POST", 
                Headers = {["Content-Type"] = "application/json"}, 
                Body = data
            })
        else
            warn("[TELEGRAM] ❌ Tidak ada HTTP library!")
            return
        end
        
        if response then
            print("[TELEGRAM] ✅ Response: " .. tostring(response.StatusCode or "OK"))
            if response.Body then
                local responseData = HttpService:JSONDecode(response.Body)
                if responseData.ok then
                    print("[TELEGRAM] ✅ API Confirmed: Message sent!")
                else
                    warn("[TELEGRAM] ❌ API Error: " .. tostring(responseData.description or "Unknown"))
                end
            end
        end
    end)
    
    if not berhasil then
        warn("[TELEGRAM] ❌ ERROR: " .. tostring(error))
    else
        print("[TELEGRAM] ✅ Selesai!")
    end
    
    print("[TELEGRAM] === KirimPesan selesai ===\n")
end

function BotTelegram:KirimPesanTest()
    if Config.Telegram.TokenBot == "" then
        Rayfield:Notify({
            Title = "❌ Error Telegram",
            Content = "Token Bot masih kosong!",
            Duration = 3
        })
        return false
    end
    
    Rayfield:Notify({
        Title = "🔄 Proses...",
        Content = "Mencoba mengambil Chat ID...",
        Duration = 2
    })
    
    print("[TELEGRAM] Mencoba mengambil Chat ID...")
    task.wait(0.5)
    
    local chatId = self:AmbilChatId(Config.Telegram.TokenBot)
    if not chatId then
        Rayfield:Notify({
            Title = "❌ Error - Chat ID Tidak Ditemukan",
            Content = "Kirim '/start' ke bot Anda!",
            Duration = 6
        })
        return false
    end
    
    Rayfield:Notify({
        Title = "✅ Chat ID Ditemukan!",
        Content = "Chat ID: " .. chatId,
        Duration = 3
    })
    
    local pesan = "🎣 RhyRu9 FISH IT - Test Connection\n\nPlayer: " .. LocalPlayer.Name .. "\nChat ID: " .. chatId .. "\nStatus: Connected ✅"
    
    local berhasilKirim = false
    
    pcall(function()
        local url = "https://api.telegram.org/bot" .. Config.Telegram.TokenBot .. "/sendMessage"
        
        local response = nil
        if http_request then
            response = http_request({
                Url = url,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode({
                    chat_id = chatId,
                    text = pesan
                })
            })
        elseif syn and syn.request then
            response = syn.request({
                Url = url,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode({
                    chat_id = chatId,
                    text = pesan
                })
            })
        elseif request then
            response = request({
                Url = url,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode({
                    chat_id = chatId,
                    text = pesan
                })
            })
        end
        
        if response then
            berhasilKirim = true
        end
    end)
    
    if berhasilKirim then
        Rayfield:Notify({
            Title = "✅ PESAN TERKIRIM!",
            Content = "Cek Telegram sekarang!",
            Duration = 5
        })
        print("[TELEGRAM] ✅ Test message berhasil!")
        return true
    else
        Rayfield:Notify({
            Title = "❌ Error Kirim Pesan",
            Content = "Cek console untuk detail",
            Duration = 5
        })
        return false
    end
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

-- Listener Ikan (PERBAIKAN)
if IkanTertangkap then
    print("[LISTENER] Event IkanTertangkap connected!")
    
    local lastUID = nil
    
    IkanTertangkap.OnClientEvent:Connect(function(data)
        print("\n[IKAN TERTANGKAP] Event triggered!")
        
        if not data then 
            print("[IKAN TERTANGKAP] Data kosong!")
            return 
        end
        
        local nama = type(data) == "string" and data or (data.Name or "Unknown")
        local tingkat = type(data) == "table" and (data.Tier or 1) or 1
        local id = type(data) == "table" and data.Id or nil
        local kesempatan = type(data) == "table" and (data.Chance or 0) or 0
        local harga = type(data) == "table" and (data.SellPrice or 0) or 0
        
        local uid = nama .. "_" .. tingkat .. "_" .. tick()
        if uid == lastUID then 
            print("[IKAN TERTANGKAP] Duplicate, skip")
            return 
        end
        lastUID = uid
        
        local info = pencariIkan[normalisasiNama(nama)] or {
            Nama = nama, 
            Tingkat = tingkat, 
            Id = id or "?",
            Kesempatan = kesempatan, 
            HargaJual = harga
        }
        
        if not info.Tingkat then info.Tingkat = tingkat end
        
        local raritas = tingkatKeRaritas[info.Tingkat] or "TIDAK DIKETAHUI"
        local tampilKesempatan = info.Kesempatan > 0 and string.format(" (%.6f%%)", info.Kesempatan * 100) or ""
        
        print(string.format("[IKAN TERTANGKAP] %s | Raritas: %s | Harga: %s koin%s",
            nama, raritas, tostring(info.HargaJual or 0), tampilKesempatan))
        
        -- KIRIM KE TELEGRAM
        print("[IKAN TERTANGKAP] Memanggil BotTelegram:KirimPesan...")
        BotTelegram:KirimPesan(info)
        
        JumlahError = 0
    end)
else
    warn("[LISTENER] Event IkanTertangkap TIDAK DITEMUKAN!")
end

-- Fungsi Reset
local function ResetPenuh()
    print("[RESET] Melakukan reset penuh semua status...")
    JumlahError = 0
    task.wait(3)
    print("[RESET] Status bersih, siap mancing lagi")
end

-- SISTEM MANCING OTOMATIS
local MancingAktif = false

local function SistemMancingOtomatis()
    task.spawn(function()
        print("[MANCING OTOMATIS] Dimulai - 15x Retry System + 3s Wait")
        
        while Config.MancingOtomatis do
            MancingAktif = true
            
            local sukses, err = pcall(function()
                if not LocalPlayer.Character or not HumanoidRootPart then
                    repeat task.wait(0.5) until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    Character = LocalPlayer.Character
                    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
                end

                -- LANGKAH 1: PASANG ALAT
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

                -- LANGKAH 2: ISI DAYA PANCING (15X RETRY)
                local chargeSukses = false
                local upayaCharge = 0
                
                while upayaCharge < 15 and not chargeSukses do
                    upayaCharge = upayaCharge + 1
                    
                    local ok, hasil = pcall(function()
                        return ChargeRod:InvokeServer(tick())
                    end)
                    
                    if ok and hasil then
                        chargeSukses = true
                        print("[ISI DAYA] Berhasil (upaya " .. upayaCharge .. "/15)")
                        break
                    end
                    
                    print("[ISI DAYA] Coba ulang " .. upayaCharge .. "/15...")
                    task.wait(0.15)
                end
                
                if not chargeSukses then
                    JumlahError = JumlahError + 1
                    print("[ERROR] Isi daya gagal (" .. JumlahError .. "/" .. MaksimalError .. ")")
                    if JumlahError >= MaksimalError then
                        ResetPenuh()
                    end
                    task.wait(2)
                    return
                end

                task.wait(0.3)

                -- LANGKAH 3: MULAI MINIGAME
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

                -- LANGKAH 4: TUNGGU 3 DETIK
                print("[TUNGGU] Menunggu 3 detik...")
                task.wait(3)

                -- LANGKAH 5: SELESAI MANCING
                local selesaiSukses = false
                for i = 1, 3 do
                    local ok = pcall(function()
                        SelesaiMancing:FireServer()
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
                
                JumlahError = 0
                task.wait(0.2)
            end)

            if not sukses then
                JumlahError = JumlahError + 1
                warn("[ERROR] Error Lua (" .. JumlahError .. "/" .. MaksimalError .. "): " .. tostring(err))
                
                if JumlahError >= MaksimalError then
                    ResetPenuh()
                else
                    task.wait(1)
                end
            end
        end
        
        MancingAktif = false
        JumlahError = 0
        print("[MANCING OTOMATIS] Berhenti")
    end)
end

-- Jual Otomatis
local function JualOtomatis()
    task.spawn(function()
        while Config.JualOtomatis do
            pcall(function() JualSemua:InvokeServer() end)
            task.wait(10)
        end
    end)
end

-- Anti AFK
local function AntiAFK()
    task.spawn(function()
        print("[ANTI AFK] Dimulai")
        while Config.AntiAFK do
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
            task.wait(30)
        end
        print("[ANTI AFK] Berhenti")
    end)
end

-- Sistem Fly
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

-- Data Pulau
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

-- PEMBUATAN UI
local function BuatUI()
    -- TAB 1: MANCING
    local Tab1 = Window:CreateTab("🎣 Mancing", 4483362458)
    
    Tab1:CreateSection("Sistem Mancing Otomatis")
    
    Tab1:CreateToggle({
        Name = "Mancing Secara Otomatis",
        CurrentValue = false,
        Callback = function(v)
            Config.MancingOtomatis = v
            if v then
                SistemMancingOtomatis()
                Rayfield:Notify({
                    Title = "Mancing Dimulai",
                    Content = "15x Retry + 3s Wait + Perfect Catch!",
                    Duration = 3
                })
            end
        end
    })
    
    Tab1:CreateToggle({
        Name = "Jual Otomatis (Setiap 10 detik)",
        CurrentValue = false,
        Callback = function(v)
            Config.JualOtomatis = v
            if v then JualOtomatis() end
        end
    })
    
    Tab1:CreateToggle({
        Name = "Anti AFK (Setiap 30 detik)",
        CurrentValue = false,
        Callback = function(v)
            Config.AntiAFK = v
            if v then AntiAFK() end
        end
    })
    
    Tab1:CreateSection("Informasi Sistem")
    Tab1:CreateLabel("Sistem Retry: 15x pada isi daya pancing")
    Tab1:CreateLabel("Waktu Tunggu: 3 Detik")
    Tab1:CreateLabel("Perfect Catch: Aktif")
    Tab1:CreateLabel("Maksimal Error: 3x sebelum reset")
    
    -- TAB 2: TELEGRAM
    local Tab2 = Window:CreateTab("📱 Telegram", 4483362458)
    
    Tab2:CreateSection("Pengaturan Telegram")
    
    Tab2:CreateToggle({
        Name = "Aktifkan Notifikasi Telegram",
        CurrentValue = false,
        Callback = function(v) Config.Telegram.Aktif = v end
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
    
    Tab2:CreateButton({
        Name = "🐛 Test Notif Ikan (Debug)",
        Callback = function()
            print("\n[DEBUG] === TEST NOTIFIKASI IKAN ===")
            print("[DEBUG] Telegram Aktif: " .. tostring(Config.Telegram.Aktif))
            print("[DEBUG] Token tersedia: " .. tostring(Config.Telegram.TokenBot ~= ""))
            print("[DEBUG] Chat ID tersimpan: " .. tostring(Config.Telegram.ChatId ~= ""))
            print("[DEBUG] Filter aktif: " .. #Config.Telegram.RaritasTerpilih .. " raritas")
            
            if #Config.Telegram.RaritasTerpilih > 0 then
                print("[DEBUG] Filter: " .. table.concat(Config.Telegram.RaritasTerpilih, ", "))
            else
                print("[DEBUG] Filter: TIDAK ADA (kirim semua)")
            end
            
            -- Simulasi ikan LEGENDARIS
            local testIkan = {
                Nama = "Test Golden Fish",
                Tingkat = 5, -- LEGENDARIS
                Id = 999,
                Kesempatan = 0.001,
                HargaJual = 50000
            }
            
            print("[DEBUG] Memanggil KirimPesan dengan data test...")
            BotTelegram:KirimPesan(testIkan)
            
            Rayfield:Notify({
                Title = "Test Debug",
                Content = "Cek console (Fn+F9) untuk detail!",
                Duration = 5
            })
        end
    })
    
    Tab2:CreateSection("Cara Setup Telegram")
    
    Tab2:CreateParagraph({
        Title = "⚠️ PENTING - Langkah Setup",
        Content = "1. Buka @BotFather di Telegram\n2. Ketik /newbot dan ikuti instruksi\n3. Salin Token Bot yang diberikan\n4. WAJIB: Cari bot Anda di Telegram\n5. WAJIB: Kirim pesan '/start' ke bot\n6. Tempel token di atas\n7. Klik 'Test Kirim Pesan'\n\n⚠️ HARUS kirim '/start' dulu!"
    })
    
    Tab2:CreateLabel("Troubleshooting:")
    Tab2:CreateLabel("• Test berhasil tapi notif ikan tidak?")
    Tab2:CreateLabel("  → Cek toggle 'Aktifkan Notifikasi'")
    Tab2:CreateLabel("  → Cek filter raritas (kosongkan untuk ALL)")
    Tab2:CreateLabel("  → Klik 'Test Notif Ikan' untuk debug")
    Tab2:CreateLabel("• Console: Fn+F9 untuk detail log")
    
    Tab2:CreateSection("Pilih Raritas untuk Notifikasi")
    Tab2:CreateLabel("⚠️ Kosongkan SEMUA = Terima SEMUA ikan")
    
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
            print("[FILTER] Raritas sekarang: " .. (#Config.Telegram.RaritasTerpilih == 0 and "SEMUA" or table.concat(Config.Telegram.RaritasTerpilih, ", ")))
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
            print("[FILTER] Raritas sekarang: " .. (#Config.Telegram.RaritasTerpilih == 0 and "SEMUA" or table.concat(Config.Telegram.RaritasTerpilih, ", ")))
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
            print("[FILTER] Raritas sekarang: " .. (#Config.Telegram.RaritasTerpilih == 0 and "SEMUA" or table.concat(Config.Telegram.RaritasTerpilih, ", ")))
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
            print("[FILTER] Raritas sekarang: " .. (#Config.Telegram.RaritasTerpilih == 0 and "SEMUA" or table.concat(Config.Telegram.RaritasTerpilih, ", ")))
        end
    })
    
    Tab2:CreateToggle({
        Name = "LANGKA (Tier 3)",
        CurrentValue = false,
        Callback = function(v)
            if v then
                table.insert(Config.Telegram.RaritasTerpilih, "LANGKA")
            else
                for i, val in ipairs(Config.Telegram.RaritasTerpilih) do
                    if val == "LANGKA" then table.remove(Config.Telegram.RaritasTerpilih, i) end
                end
            end
            print("[FILTER] Raritas sekarang: " .. (#Config.Telegram.RaritasTerpilih == 0 and "SEMUA" or table.concat(Config.Telegram.RaritasTerpilih, ", ")))
        end
    })
    
    Tab2:CreateToggle({
        Name = "TIDAK UMUM (Tier 2)",
        CurrentValue = false,
        Callback = function(v)
            if v then
                table.insert(Config.Telegram.RaritasTerpilih, "TIDAK UMUM")
            else
                for i, val in ipairs(Config.Telegram.RaritasTerpilih) do
                    if val == "TIDAK UMUM" then table.remove(Config.Telegram.RaritasTerpilih, i) end
                end
            end
            print("[FILTER] Raritas sekarang: " .. (#Config.Telegram.RaritasTerpilih == 0 and "SEMUA" or table.concat(Config.Telegram.RaritasTerpilih, ", ")))
        end
    })
    
    Tab2:CreateToggle({
        Name = "UMUM (Tier 1) - Untuk Testing",
        CurrentValue = false,
        Callback = function(v)
            if v then
                table.insert(Config.Telegram.RaritasTerpilih, "UMUM")
            else
                for i, val in ipairs(Config.Telegram.RaritasTerpilih) do
                    if val == "UMUM" then table.remove(Config.Telegram.RaritasTerpilih, i) end
                end
            end
            print("[FILTER] Raritas sekarang: " .. (#Config.Telegram.RaritasTerpilih == 0 and "SEMUA" or table.concat(Config.Telegram.RaritasTerpilih, ", ")))
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
    
    Tab3:CreateButton({
        Name = "📍 Fisherman's Island",
        Callback = function() TeleportKePulau(1) end
    })
    
    Tab3:CreateButton({
        Name = "🌋 Volcano",
        Callback = function() TeleportKePulau(12) end
    })
    
    Tab3:CreateButton({
        Name = "❄️ Snowy Island",
        Callback = function() TeleportKePulau(21) end
    })
    
    -- TAB 4: UTILITAS
    local Tab4 = Window:CreateTab("⚡ Utilitas", 4483362458)
    
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
                Rayfield:Notify({Title = "Reset", Content = "Kecepatan kembali normal", Duration = 2})
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
    
    Tab4:CreateButton({
        Name = "Fullbright",
        Callback = function()
            Lighting.Brightness = 2
            Lighting.ClockTime = 12
            Lighting.FogEnd = 100000
            Lighting.Ambient = Color3.new(1, 1, 1)
            Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
            Rayfield:Notify({Title = "Fullbright", Content = "Pencahayaan maksimal aktif!", Duration = 2})
        end
    })
    
    Tab4:CreateButton({
        Name = "Hapus Kabut",
        Callback = function()
            Lighting.FogEnd = 100000
            Lighting.FogStart = 0
            Rayfield:Notify({Title = "Kabut Dihapus", Content = "Jarak pandang maksimal!", Duration = 2})
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
        Title = "RhyRu9 FISH IT v1.0",
        Content = "Developer: RhyRu9\nRilis: 19 Oktober 2025\nVersi: 1.0 (Fixed Telegram)\n\nScript auto fishing lengkap dengan sistem retry canggih dan notifikasi telegram."
    })
    
    Tab5:CreateSection("Fitur Utama")
    
    Tab5:CreateParagraph({
        Title = "🎣 Sistem Mancing",
        Content = "• 15x Retry pada isi daya pancing\n• Tunggu 3 Detik untuk Perfect Catch\n• Auto Recovery: Reset setelah 3x error\n• Nilai Perfect Catch: (-1.233, 0.994)\n• Jual Otomatis: Setiap 10 detik\n• Anti AFK: Setiap 30 detik"
    })
    
    Tab5:CreateParagraph({
        Title = "📱 Notifikasi Telegram (FIXED)",
        Content = "• Filter Raritas: Pilih atau kosongkan untuk ALL\n• Info Lengkap: Nama, Raritas, Tingkat, Kesempatan, Harga\n• Real-time: Notifikasi instant saat tangkap\n• Custom: Pilih raritas yang diinginkan\n• Auto Chat ID: Disimpan otomatis\n• Debug: Tombol test untuk troubleshooting"
    })
    
    Tab5:CreateParagraph({
        Title = "📍 Sistem Teleport",
        Content = "• 21 Lokasi: Semua pulau tersedia\n• Teleport Cepat: 3 lokasi populer\n• Pengecekan Keamanan: Validasi sebelum teleport\n• Menu Dropdown: Pilih pulau dengan mudah"
    })
    
    Tab5:CreateSection("Cara Menggunakan")
    
    Tab5:CreateParagraph({
        Title = "Setup Telegram (Opsional)",
        Content = "1. Buka @BotFather di Telegram\n2. Ketik /newbot dan ikuti instruksi\n3. Salin Token Bot yang diberikan\n4. Kirim pesan '/start' ke bot Anda\n5. Tempel token di tab Telegram\n6. Klik 'Test Kirim Pesan'\n7. Aktifkan toggle 'Aktifkan Notifikasi'\n8. Pilih raritas (atau kosongkan untuk ALL)"
    })
    
    Tab5:CreateParagraph({
        Title = "Mulai Mancing",
        Content = "1. Pergi ke lokasi memancing\n2. Aktifkan Mancing Secara Otomatis\n3. Aktifkan Jual Otomatis (opsional)\n4. Aktifkan Anti AFK\n5. Pantau notifikasi di layar dan Telegram"
    })
    
    Tab5:CreateSection("Troubleshooting Telegram")
    
    Tab5:CreateParagraph({
        Title = "Test berhasil tapi notif ikan tidak?",
        Content = "1. Cek toggle 'Aktifkan Notifikasi Telegram' ON\n2. Klik 'Test Notif Ikan (Debug)'\n3. Buka Console (Fn+F9) lihat log:\n   - Apakah Telegram aktif?\n   - Apakah ada filter?\n   - Apakah ikan cocok filter?\n4. Solusi: KOSONGKAN semua filter raritas\n5. Coba tangkap ikan UMUM untuk test\n6. Lihat log [IKAN TERTANGKAP] dan [TELEGRAM]"
    })
    
    Tab5:CreateLabel("━━━━━━━━━━━━━━━━━━━━")
    Tab5:CreateLabel("Script by RhyRu9 © 2025")
    Tab5:CreateLabel("Status: ✅ ONLINE (Telegram Fixed)")
    Tab5:CreateLabel("Versi: 1.0")
    
    Rayfield:Notify({
        Title = "✅ UI Dimuat",
        Content = "Semua tab berhasil dimuat!",
        Duration = 3
    })
end

-- Handler Respawn Karakter
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
    Humanoid = char:WaitForChild("Humanoid")
    
    task.wait(2)
    
    if Humanoid then
        Humanoid.WalkSpeed = Config.KecepatanJalan
        Humanoid.JumpPower = Config.KekuatanLompat
    end
    
    if Config.MancingOtomatis then
        task.wait(2)
        SistemMancingOtomatis()
    end
    
    if Config.JualOtomatis then
        task.wait(1)
        JualOtomatis()
    end
    
    if Config.AntiAFK then
        task.wait(1)
        AntiAFK()
    end
    
    if Config.FlyAktif then
        task.wait(1)
        Fly()
    end
    
    if Config.NoClip then
        task.wait(1)
        NoClip()
    end
end)

-- Eksekusi Utama
local sukses, err = pcall(function()
    BuatUI()
end)

if sukses then
    print("=======================================")
    print("  RhyRu9 FISH IT v1.0 (TELEGRAM FIXED)")
    print("  Developer: RhyRu9")
    print("  Rilis: 19 Oktober 2025")
    print("  Status: SIAP")
    print("=======================================")
    print("  FITUR LENGKAP:")
    print("  ✅ Tab Mancing (15x Retry System)")
    print("  ✅ Tab Telegram (Notifikasi + Debug)")
    print("  ✅ Tab Teleport (21 Lokasi)")
    print("  ✅ Tab Utilitas (Speed, Fly, NoClip)")
    print("  ✅ Tab Info (Dokumentasi)")
    print("=======================================")
    print("  PERBAIKAN TELEGRAM:")
    print("  • Chat ID disimpan otomatis")
    print("  • Debug log lengkap")
    print("  • Filter raritas diperbaiki")
    print("  • Tombol test notif ikan")
    print("  • Kosongkan filter = terima SEMUA")
    print("=======================================")
    print("  CARA TEST TELEGRAM:")
    print("  1. Aktifkan 'Notifikasi Telegram'")
    print("  2. JANGAN pilih raritas apapun")
    print("  3. Klik 'Test Notif Ikan (Debug)'")
    print("  4. Buka Console: Fn+F9")
    print("  5. Lihat log detail")
    print("=======================================")
    print("  STATUS: ✅ ONLINE")
    print("=======================================")
else
    warn("ERROR: " .. tostring(err))
end
