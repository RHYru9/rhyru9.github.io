-- RhyRu9 FISH IT v1.0
-- DEVELOPER BY RhyRu9
-- Update: 19 Oct 2025 (Telegram Fix)
-- Fitur: 15x Retry System, 3 Detik Wait, Perfect Catch, Anti AFK, Notifikasi Telegram

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
        ChatId = "", -- SIMPAN CHAT ID
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

-- Bot Telegram (FIXED VERSION)
local BotTelegram = {}

function BotTelegram:AmbilChatId(token)
    if not token or token == "" then return nil end
    
    -- GUNAKAN CHAT ID YANG SUDAH DISIMPAN
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
                        Config.Telegram.ChatId = chatId -- SIMPAN UNTUK DIGUNAKAN NANTI
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
    -- DEBUG LOG AWAL
    print("\n[TELEGRAM DEBUG] ========== MULAI ==========")
    print("[TELEGRAM DEBUG] KirimPesan dipanggil")
    
    -- CEK 1: Apakah Telegram aktif?
    if not Config.Telegram.Aktif then 
        print("[TELEGRAM DEBUG] ❌ Config.Telegram.Aktif = FALSE")
        print("[TELEGRAM DEBUG] Solusi: Aktifkan toggle 'Aktifkan Notifikasi Telegram'")
        return 
    end
    print("[TELEGRAM DEBUG] ✅ Telegram aktif")
    
    -- CEK 2: Apakah token ada?
    if Config.Telegram.TokenBot == "" then 
        print("[TELEGRAM DEBUG] ❌ Token bot KOSONG")
        return 
    end
    print("[TELEGRAM DEBUG] ✅ Token bot tersedia")
    
    -- CEK 3: Apakah data ikan valid?
    if not infoIkan.Tingkat then 
        print("[TELEGRAM DEBUG] ❌ infoIkan.Tingkat TIDAK ADA")
        return 
    end
    print("[TELEGRAM DEBUG] ✅ Data ikan valid")
    
    local raritasIkan = tingkatKeRaritas[infoIkan.Tingkat] or "TIDAK DIKETAHUI"
    print("[TELEGRAM DEBUG] 📊 Nama: " .. (infoIkan.Nama or "Unknown"))
    print("[TELEGRAM DEBUG] 📊 Raritas: " .. raritasIkan)
    print("[TELEGRAM DEBUG] 📊 Tier: " .. tostring(infoIkan.Tingkat))
    
    -- CEK 4: Filter raritas
    print("[TELEGRAM DEBUG] Jumlah filter aktif: " .. #Config.Telegram.RaritasTerpilih)
    
    if #Config.Telegram.RaritasTerpilih > 0 then
        print("[TELEGRAM DEBUG] 🔍 Ada filter, mengecek...")
        print("[TELEGRAM DEBUG] Filter: " .. table.concat(Config.Telegram.RaritasTerpilih, ", "))
        
        local harusKirim = false
        for _, raritasTarget in ipairs(Config.Telegram.RaritasTerpilih) do
            local ikanNorm = string.upper(raritasIkan):gsub("%s+", "")
            local targetNorm = string.upper(raritasTarget):gsub("%s+", "")
            
            print("[TELEGRAM DEBUG] Bandingkan: '" .. ikanNorm .. "' vs '" .. targetNorm .. "'")
            
            if ikanNorm == targetNorm then
                harusKirim = true
                print("[TELEGRAM DEBUG] ✅ COCOK!")
                break
            end
        end
        
        if not harusKirim then 
            print("[TELEGRAM DEBUG] ❌ TIDAK COCOK dengan filter, SKIP")
            print("[TELEGRAM DEBUG] Solusi: Matikan semua toggle raritas untuk terima SEMUA ikan")
            print("[TELEGRAM DEBUG] ========== SELESAI ==========\n")
            return 
        end
    else
        print("[TELEGRAM DEBUG] ⚠️ TIDAK ADA FILTER = KIRIM SEMUA")
    end
    
    -- CEK 5: Ambil Chat ID
    print("[TELEGRAM DEBUG] Mengambil Chat ID...")
    local chatId = self:AmbilChatId(Config.Telegram.TokenBot)
    if not chatId then
        warn("[TELEGRAM DEBUG] ❌ GAGAL ambil Chat ID")
        print("[TELEGRAM DEBUG] Solusi: Klik 'Test Kirim Pesan' dulu untuk mendapatkan Chat ID")
        print("[TELEGRAM DEBUG] ========== SELESAI ==========\n")
        return
    end
    print("[TELEGRAM DEBUG] ✅ Chat ID: " .. chatId)
    
    -- CEK 6: Format dan kirim pesan
    local pesan = self:FormatPesan(infoIkan)
    print("[TELEGRAM DEBUG] 📝 Pesan diformat, siap kirim")
    
    local berhasil, error = pcall(function()
        local url = "https://api.telegram.org/bot" .. Config.Telegram.TokenBot .. "/sendMessage"
        local data = HttpService:JSONEncode({
            chat_id = chatId,
            text = pesan,
            parse_mode = "Markdown"
        })
        
        print("[TELEGRAM DEBUG] 🚀 Mengirim pesan...")
        
        local response = nil
        
        if http_request then
            print("[TELEGRAM DEBUG] Method: http_request")
            response = http_request({
                Url = url, 
                Method = "POST", 
                Headers = {["Content-Type"] = "application/json"}, 
                Body = data
            })
        elseif syn and syn.request then
            print("[TELEGRAM DEBUG] Method: syn.request")
            response = syn.request({
                Url = url, 
                Method = "POST", 
                Headers = {["Content-Type"] = "application/json"}, 
                Body = data
            })
        elseif request then
            print("[TELEGRAM DEBUG] Method: request")
            response = request({
                Url = url, 
                Method = "POST", 
                Headers = {["Content-Type"] = "application/json"}, 
                Body = data
            })
        else
            warn("[TELEGRAM DEBUG] ❌ Tidak ada HTTP library!")
            return
        end
        
        if response then
            print("[TELEGRAM DEBUG] ✅ Response diterima")
            if response.StatusCode then
                print("[TELEGRAM DEBUG] Status Code: " .. response.StatusCode)
            end
            if response.Body then
                local responseData = HttpService:JSONDecode(response.Body)
                if responseData.ok then
                    print("[TELEGRAM DEBUG] ✅✅✅ PESAN TERKIRIM KE TELEGRAM!")
                else
                    warn("[TELEGRAM DEBUG] ❌ API Error: " .. tostring(responseData.description or "Unknown"))
                end
            end
        end
    end)
    
    if not berhasil then
        warn("[TELEGRAM DEBUG] ❌ ERROR saat kirim: " .. tostring(error))
    end
    
    print("[TELEGRAM DEBUG] ========== SELESAI ==========\n")
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
    print("[TELEGRAM] Token: " .. string.sub(Config.Telegram.TokenBot, 1, 10) .. "...")
    
    task.wait(0.5)
    
    local chatId = self:AmbilChatId(Config.Telegram.TokenBot)
    if not chatId then
        Rayfield:Notify({
            Title = "❌ Error - Chat ID Tidak Ditemukan",
            Content = "Langkah: 1) Cari bot di Telegram 2) Kirim '/start' 3) Tunggu 5 detik 4) Coba lagi",
            Duration = 6
        })
        print("[TELEGRAM] Gagal: Tidak ada pesan di bot. Kirim '/start' ke bot Anda!")
        return false
    end
    
    Rayfield:Notify({
        Title = "✅ Chat ID Ditemukan!",
        Content = "Chat ID: " .. chatId .. " | Mengirim pesan test...",
        Duration = 3
    })
    print("[TELEGRAM] Chat ID ditemukan: " .. chatId)
    
    local pesan = "🎣 RhyRu9 FISH IT - Test Connection\n\nPlayer: " .. LocalPlayer.Name .. "\nChat ID: " .. chatId .. "\nStatus: Connected ✅\n\nJika Anda melihat pesan ini, setup berhasil!"
    
    local berhasilKirim = false
    local errorDetail = ""
    
    pcall(function()
        local url = "https://api.telegram.org/bot" .. Config.Telegram.TokenBot .. "/sendMessage"
        
        print("[TELEGRAM] Mengirim ke Chat ID: " .. chatId)
        print("[TELEGRAM] URL: " .. string.sub(url, 1, 50) .. "...")
        
        if http_request then
            print("[TELEGRAM] Menggunakan http_request")
            local response = http_request({
                Url = url,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode({
                    chat_id = chatId,
                    text = pesan
                })
            })
            
            if response then
                print("[TELEGRAM] Response Status: " .. tostring(response.StatusCode or "nil"))
                if response.Body then
                    print("[TELEGRAM] Response Body: " .. tostring(response.Body))
                    local responseData = HttpService:JSONDecode(response.Body)
                    if responseData.ok then
                        berhasilKirim = true
                        print("[TELEGRAM] ✅ API confirmed: Message sent!")
                    else
                        errorDetail = tostring(responseData.description or "Unknown error")
                        print("[TELEGRAM] ❌ API error: " .. errorDetail)
                    end
                else
                    print("[TELEGRAM] ⚠️ No response body, but request sent")
                    berhasilKirim = true
                end
            else
                print("[TELEGRAM] ⚠️ No response object, but request sent")
                berhasilKirim = true
            end
            
        elseif syn and syn.request then
            print("[TELEGRAM] Menggunakan syn.request")
            local response = syn.request({
                Url = url,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode({
                    chat_id = chatId,
                    text = pesan
                })
            })
            
            if response and response.Body then
                local responseData = HttpService:JSONDecode(response.Body)
                if responseData.ok then
                    berhasilKirim = true
                else
                    errorDetail = tostring(responseData.description or "Unknown error")
                end
            else
                berhasilKirim = true
            end
            
        elseif request then
            print("[TELEGRAM] Menggunakan request")
            local response = request({
                Url = url,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode({
                    chat_id = chatId,
                    text = pesan
                })
            })
            
            if response and response.Body then
                local responseData = HttpService:JSONDecode(response.Body)
                if responseData.ok then
                    berhasilKirim = true
                else
                    errorDetail = tostring(responseData.description or "Unknown error")
                end
            else
                berhasilKirim = true
            end
        else
            error("No HTTP library available")
        end
    end)
    
    if berhasilKirim then
        Rayfield:Notify({
            Title = "✅ PESAN TERKIRIM!",
            Content = "Chat ID: " .. chatId .. " | BUKA TELEGRAM SEKARANG dan cari chat dengan bot Anda!",
            Duration = 8
        })
        print("[TELEGRAM] ✅ Pesan berhasil dikirim!")
        print("[TELEGRAM] ========================================")
        print("[TELEGRAM] BUKA TELEGRAM ANDA DAN CEK:")
        print("[TELEGRAM] 1. Chat dengan bot (nama bot dari @BotFather)")
        print("[TELEGRAM] 2. Jika tidak ada, cek 'Archived Chats'")
        print("[TELEGRAM] 3. Refresh Telegram (tutup dan buka lagi)")
        print("[TELEGRAM] 4. Chat ID yang digunakan: " .. chatId)
        print("[TELEGRAM] ========================================")
        return true
    else
        Rayfield:Notify({
            Title = "❌ Error Kirim Pesan",
            Content = "Error: " .. errorDetail .. " | Cek console untuk detail",
            Duration = 5
        })
        print("[TELEGRAM] ❌ Gagal mengirim: " .. errorDetail)
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

-- Listener Ikan (DITAMBAHKAN DEBUG LOG)
if IkanTertangkap then
    print("[LISTENER] ✅ Event IkanTertangkap DITEMUKAN dan connected!")
    
    local lastUID = nil
    IkanTertangkap.OnClientEvent:Connect(function(data)
        print("\n[IKAN TERTANGKAP] ========================================")
        print("[IKAN TERTANGKAP] Event TRIGGERED!")
        
        if not data then 
            print("[IKAN TERTANGKAP] ❌ Data kosong")
            return 
        end
        
        local nama = type(data) == "string" and data or (data.Name or "Unknown")
        local tingkat = type(data) == "table" and (data.Tier or 1) or 1
        local id = type(data) == "table" and data.Id or nil
        local kesempatan = type(data) == "table" and (data.Chance or 0) or 0
        local harga = type(data) == "table" and (data.SellPrice or 0) or 0
        
        local uid = nama .. "_" .. tingkat .. "_" .. tick()
        if uid == lastUID then 
            print("[IKAN TERTANGKAP] Duplikat, skip")
            return 
        end
        lastUID = uid
        
        local info = pencariIkan[normalisasiNama(nama)] or {
            Nama = nama, Tingkat = tingkat, Id = id or "?",
            Kesempatan = kesempatan, HargaJual = harga
        }
        
        if not info.Tingkat then info.Tingkat = tingkat end
        
        local raritas = tingkatKeRaritas[info.Tingkat] or "TIDAK DIKETAHUI"
        local tampilKesempatan = info.Kesempatan > 0 and string.format(" (%.6f%%)", info.Kesempatan * 100) or ""
        print(string.format("[IKAN TERTANGKAP] %s | Raritas: %s | Harga: %s koin%s",
            nama, raritas, tostring(info.HargaJual or 0), tampilKesempatan))
        
        print("[IKAN TERTANGKAP] Memanggil BotTelegram:KirimPesan...")
        BotTelegram:KirimPesan(info)
        
        JumlahError = 0
        print("[IKAN TERTANGKAP] ========================================\n")
    end)
else
    warn("[LISTENER] ❌ Event IkanTertangkap TIDAK DITEMUKAN!")
end

-- Fungsi Reset
local function ResetPenuh()
    print("[RESET] Melakukan reset penuh semua status...")
    JumlahError = 0
    task.wait(3)
    print("[RESET] Status bersih, siap mancing lagi")
end

-- SISTEM MANCING OTOMATIS (TIDAK DIUBAH)
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
                    print("[ERROR] Isi daya pancing gagal (" .. JumlahError .. "/" .. MaksimalError .. ") - KRITIS!")
                    if JumlahError >= MaksimalError then
                        print("[RESET] Error isi daya terlalu banyak!")
                        ResetPenuh()
                    end
                    task.wait(2)
                    return
                end

                task.wait(0.3)

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

                print("[TUNGGU] Menunggu 3 detik untuk tangkap...")
                task.wait(3)

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
                    print("[RESET] Terlalu banyak error!")
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

-- Data Pulau (21 lokasi)
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
    
    -- TAB 2: TELEGRAM (UPDATED DENGAN DEBUG)
    local Tab2 = Window:CreateTab("📱 Telegram", 4483362458)
    
    Tab2:CreateSection("Pengaturan Telegram")
    
    Tab2:CreateToggle({
        Name = "Aktifkan Notifikasi Telegram",
        CurrentValue = false,
        Callback = function(v) 
            Config.Telegram.Aktif = v
            print("[CONFIG] Telegram Aktif = " .. tostring(v))
        end
    })
    
    Tab2:CreateInput({
        Name = "Token Bot",
        PlaceholderText = "Masukkan token bot Anda",
        RemoveTextAfterFocusLost = false,
        Callback = function(v) 
            Config.Telegram.TokenBot = v
            print("[CONFIG] Token Bot diset (panjang: " .. #v .. ")")
        end
    })
    
    Tab2:CreateButton({
        Name = "Test Kirim Pesan",
        Callback = function()
            BotTelegram:KirimPesanTest()
        end
    })
    
    Tab2:CreateButton({
        Name = "🐛 Debug Test Ikan UMUM",
        Callback = function()
            print("\n[DEBUG TEST] ==========================================")
            print("[DEBUG TEST] Memulai test notifikasi ikan...")
            print("[DEBUG TEST] Config.Telegram.Aktif: " .. tostring(Config.Telegram.Aktif))
            print("[DEBUG TEST] Config.Telegram.TokenBot tersedia: " .. tostring(Config.Telegram.TokenBot ~= ""))
            print("[DEBUG TEST] Config.Telegram.ChatId: " .. (Config.Telegram.ChatId ~= "" and Config.Telegram.ChatId or "BELUM ADA"))
            print("[DEBUG TEST] Jumlah filter: " .. #Config.Telegram.RaritasTerpilih)
            
            if #Config.Telegram.RaritasTerpilih > 0 then
                print("[DEBUG TEST] Filter aktif: " .. table.concat(Config.Telegram.RaritasTerpilih, ", "))
            else
                print("[DEBUG TEST] TIDAK ADA FILTER (kirim semua)")
            end
            
            -- Simulasi ikan UMUM (paling sering muncul)
            local testIkan = {
                Nama = "Test Common Fish",
                Tingkat = 1, -- UMUM
                Id = 1,
                Kesempatan = 0.5,
                HargaJual = 10
            }
            
            print("[DEBUG TEST] Memanggil BotTelegram:KirimPesan...")
            print("[DEBUG TEST] ==========================================\n")
            
            BotTelegram:KirimPesan(testIkan)
            
            Rayfield:Notify({
                Title = "🐛 Debug Test",
                Content = "Cek Console (Fn+F9) untuk LOG LENGKAP!",
                Duration = 5
            })
        end
    })
    
    Tab2:CreateSection("Cara Setup Telegram")
    
    Tab2:CreateParagraph({
        Title = "⚠️ LANGKAH SETUP WAJIB",
        Content = "1. Buka @BotFather di Telegram\n2. Ketik /newbot dan ikuti instruksi\n3. Salin Token Bot yang diberikan\n4. ⚠️ WAJIB: Cari bot Anda di Telegram\n5. ⚠️ WAJIB: Kirim '/start' ke bot\n6. Tempel token di atas\n7. Klik 'Test Kirim Pesan'\n8. ✅ Aktifkan toggle 'Aktifkan Notifikasi'\n9. Kosongkan SEMUA filter untuk test"
    })
    
    Tab2:CreateLabel("━━━━━━━━━━━━━━━━━━━━")
    Tab2:CreateLabel("📋 TROUBLESHOOTING:")
    Tab2:CreateLabel("• Test berhasil tapi notif ikan TIDAK?")
    Tab2:CreateLabel("  1) CEK toggle 'Aktifkan Notifikasi' ON")
    Tab2:CreateLabel("  2) MATIKAN semua filter raritas")
    Tab2:CreateLabel("  3) Klik 'Debug Test Ikan UMUM'")
    Tab2:CreateLabel("  4) Buka Console: Fn+F9")
    Tab2:CreateLabel("  5) Baca LOG yang muncul")
    Tab2:CreateLabel("• Console menunjukkan dimana masalahnya!")
    
    Tab2:CreateSection("Filter Raritas Notifikasi")
    Tab2:CreateLabel("⚠️ KOSONGKAN SEMUA = Terima SEMUA ikan")
    Tab2:CreateLabel("⚠️ Untuk test: JANGAN pilih apapun!")
    
    Tab2:CreateToggle({
        Name = "RAHASIA (Tier 7)",
        CurrentValue = false,
        Callback = function(v)
            if v then
                table.insert(Config.Telegram.RaritasTerpilih, "RAHASIA")
            else
                for i, val in ipairs(Config.Telegram.RaritasTerpilih) do
                    if val == "RAHASIA" then table.remove(Config.Telegram.RaritasTerpilih, i) break end
                end
            end
            print("[FILTER] Update: " .. (#Config.Telegram.RaritasTerpilih == 0 and "SEMUA IKAN" or table.concat(Config.Telegram.RaritasTerpilih, ", ")))
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
                    if val == "MISTIS" then table.remove(Config.Telegram.RaritasTerpilih, i) break end
                end
            end
            print("[FILTER] Update: " .. (#Config.Telegram.RaritasTerpilih == 0 and "SEMUA IKAN" or table.concat(Config.Telegram.RaritasTerpilih, ", ")))
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
                    if val == "LEGENDARIS" then table.remove(Config.Telegram.RaritasTerpilih, i) break end
                end
            end
            print("[FILTER] Update: " .. (#Config.Telegram.RaritasTerpilih == 0 and "SEMUA IKAN" or table.concat(Config.Telegram.RaritasTerpilih, ", ")))
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
                    if val == "EPIK" then table.remove(Config.Telegram.RaritasTerpilih, i) break end
                end
            end
            print("[FILTER] Update: " .. (#Config.Telegram.RaritasTerpilih == 0 and "SEMUA IKAN" or table.concat(Config.Telegram.RaritasTerpilih, ", ")))
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
        Content = "Developer: RhyRu9\nUpdate: 19 Oktober 2025\nVersi: 1.0 (Telegram Fixed)\n\nScript auto fishing dengan debug log lengkap untuk troubleshooting telegram."
    })
    
    Tab5:CreateSection("Fitur Utama")
    
    Tab5:CreateParagraph({
        Title = "🎣 Sistem Mancing",
        Content = "• 15x Retry pada isi daya pancing\n• Tunggu 3 Detik untuk Perfect Catch\n• Auto Recovery: Reset setelah 3x error\n• Nilai Perfect Catch: (-1.233, 0.994)\n• Jual Otomatis: Setiap 10 detik\n• Anti AFK: Setiap 30 detik"
    })
    
    Tab5:CreateParagraph({
        Title = "📱 Notifikasi Telegram (FIXED + DEBUG)",
        Content = "• Debug Log Lengkap: Setiap step dicatat\n• Chat ID Disimpan: Tidak perlu ambil terus\n• Filter Raritas: Kosongkan untuk ALL\n• Test Button: Test ikan UMUM langsung\n• Console Log: Fn+F9 untuk troubleshoot\n• Info Lengkap: Nama, Raritas, Tier, Harga"
    })
    
    Tab5:CreateSection("Cara Test Telegram")
    
    Tab5:CreateParagraph({
        Title = "Langkah Test yang Benar",
        Content = "1. Masukkan Token Bot\n2. Klik 'Test Kirim Pesan'\n3. Tunggu sampai berhasil\n4. ✅ Aktifkan 'Notifikasi Telegram'\n5. ❌ JANGAN pilih raritas apapun\n6. Klik 'Debug Test Ikan UMUM'\n7. Buka Console (Fn+F9)\n8. Baca log [TELEGRAM DEBUG]\n9. Log akan tunjukkan dimana masalahnya"
    })
    
    Tab5:CreateParagraph({
        Title = "Membaca Debug Log",
        Content = "✅ = Berhasil\n❌ = Gagal (baca solusinya)\n\nContoh masalah:\n• 'Telegram tidak aktif' → Toggle OFF\n• 'Tidak cocok filter' → Ada filter aktif\n• 'Chat ID gagal' → Belum test kirim\n• 'Token kosong' → Isi token dulu"
    })
    
    Tab5:CreateLabel("━━━━━━━━━━━━━━━━━━━━")
    Tab5:CreateLabel("Script by RhyRu9 © 2025")
    Tab5:CreateLabel("Status: ✅ ONLINE")
    Tab5:CreateLabel("Versi: 1.0 (Telegram Debug)")
    
    Rayfield:Notify({
        Title = "✅ UI Dimuat",
        Content = "Telegram dengan Debug Log Lengkap!",
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
    print("  RhyRu9 FISH IT v1.0")
    print("  Developer: RhyRu9")
    print("  Update: 19 Oktober 2025")
    print("  Status: SIAP")
    print("=======================================")
    print("  FITUR LENGKAP:")
    print("  ✅ Tab Mancing (TIDAK DIUBAH)")
    print("  ✅ Tab Telegram (DEBUG LOG LENGKAP)")
    print("  ✅ Tab Teleport (21 Lokasi)")
    print("  ✅ Tab Utilitas (Speed, Fly, NoClip)")
    print("  ✅ Tab Info (Dokumentasi)")
    print("=======================================")
    print("  TELEGRAM DEBUG:")
    print("  • Chat ID disimpan otomatis")
    print("  • Debug log setiap langkah")
    print("  • Tombol test ikan UMUM")
    print("  • Solusi ditampilkan di log")
    print("  • Buka Console: Fn+F9")
    print("=======================================")
    print("  CARA TROUBLESHOOT:")
    print("  1. Aktifkan 'Notifikasi Telegram'")
    print("  2. MATIKAN semua filter raritas")
    print("  3. Klik 'Debug Test Ikan UMUM'")
    print("  4. Buka Console (Fn+F9)")
    print("  5. Cari [TELEGRAM DEBUG]")
    print("  6. Baca ❌ untuk tahu masalahnya")
    print("=======================================")
    print("  STATUS: ✅ ONLINE")
    print("=======================================")
else
    warn("ERROR: " .. tostring(err))
end
