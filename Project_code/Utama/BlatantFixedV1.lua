-- ⚠️ BLATANT V2 - SMART SYNC EDITION
-- Fix: Mengatasi bug "Loop Tertukar" & "Ghost Cast" dengan validasi server

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Init Network
local netFolder = ReplicatedStorage
    :WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0")
    :WaitForChild("net")

local RF_ChargeFishingRod = netFolder:WaitForChild("RF/ChargeFishingRod")
local RF_RequestMinigame = netFolder:WaitForChild("RF/RequestFishingMinigameStarted")
local RF_CancelFishingInputs = netFolder:WaitForChild("RF/CancelFishingInputs")
local RF_UpdateAutoFishingState = netFolder:WaitForChild("RF/UpdateAutoFishingState")
local RE_FishingCompleted = netFolder:WaitForChild("RE/FishingCompleted")
local RE_MinigameChanged = netFolder:WaitForChild("RE/FishingMinigameChanged")

local BlatantV2 = {}
BlatantV2.Active = false
BlatantV2.Stats = {
    castCount = 0,
    startTime = 0
}

-- [[ PENGATURAN LOGIKA BARU ]]
BlatantV2.Settings = {
    ChargeDelay = 0.15,   -- Waktu tahan klik (Wajib ada agar server mendeteksi)
    CompleteDelay = 0.05, -- Jeda instan sebelum tarik
    CancelDelay = 0.15,   -- Jeda reset animasi
    PostCastDelay = 0.1   -- Jeda napas antar putaran (PENTING untuk anti-stuck)
}

-- Helper: Kirim perintah dan TUNGGU jawaban (Untuk Cast)
local function safeInvoke(remote, args)
    local success, result = pcall(function()
        return remote:InvokeServer(unpack(args or {}))
    end)
    return success and result
end

-- Helper: Kirim perintah TANPA tunggu (Untuk Reset/Charge)
local function safeFire(remote, args)
    task.spawn(function()
        pcall(function()
            remote:FireServer(unpack(args or {}))
        end)
    end)
end

-- [[ LOGIKA UTAMA YANG DIPERBAIKI ]]
local function ultraSpamLoop()
    while BlatantV2.Active do
        local startTime = tick()
        
        -- 1. CHARGE (Isi Tenaga)
        -- Kita pakai FireServer biar cepat
        safeFire(RF_ChargeFishingRod, {[1] = startTime})
        
        -- Tunggu agar server sadar kita sedang charging
        task.wait(BlatantV2.Settings.ChargeDelay)
        
        -- 2. LEMPAR (Request Minigame)
        local releaseTime = tick()
        
        -- [KUNCI PERBAIKAN] Gunakan InvokeServer untuk MEMASTIKAN lemparan berhasil
        -- Variabel 'castSuccess' akan bernilai true jika server menerima lemparan
        local castSuccess = RF_RequestMinigame:InvokeServer(1, 0, releaseTime)
        
        if castSuccess then
            -- [KONDISI A: LEMPARAN BERHASIL]
            -- Baru kita jalankan logika tarik ikan
            BlatantV2.Stats.castCount = BlatantV2.Stats.castCount + 1
            
            -- Tunggu sebentar (simulasi reflex dewa)
            task.wait(BlatantV2.Settings.CompleteDelay)
            
            -- SELESAIKAN MINIGAME
            safeFire(RE_FishingCompleted)
            
            -- Tunggu sebentar sebelum reset
            task.wait(BlatantV2.Settings.CancelDelay)
            
            -- RESET POSISI
            safeFire(RF_CancelFishingInputs)
        else
            -- [KONDISI B: LEMPARAN GAGAL / STUCK]
            -- Server menolak lemparan (mungkin karena cooldown atau lag)
            -- JANGAN KIRIM 'FishingCompleted'! Ini yang bikin bug "kosong ditarik".
            
            -- Lakukan Force Reset agar karakter tidak stuck "memegang pancingan"
            safeFire(RF_CancelFishingInputs)
            
            -- Beri hukuman waktu sedikit agar server "bernapas"
            task.wait(0.2) 
        end

        -- Jeda Napas Antar Loop (Sangat penting agar ping tidak naik dan urutan tidak tertukar)
        task.wait(BlatantV2.Settings.PostCastDelay)
    end
end

-- Backup Listener (Hanya aktif jika script benar-benar macet)
RE_MinigameChanged.OnClientEvent:Connect(function(state)
    if not BlatantV2.Active then return end
    
    -- Jika tiba-tiba muncul UI minigame (artinya loop di atas lolos deteksi)
    if type(state) == "string" and state:lower():find("hook") then
        task.wait(BlatantV2.Settings.CompleteDelay)
        safeFire(RE_FishingCompleted)
        task.wait(BlatantV2.Settings.CancelDelay)
        safeFire(RF_CancelFishingInputs)
    end
end)

-- Public API
function BlatantV2.UpdateSettings(completeDelay, cancelDelay)
    if completeDelay then BlatantV2.Settings.CompleteDelay = completeDelay end
    if cancelDelay then BlatantV2.Settings.CancelDelay = cancelDelay end
end

function BlatantV2.Start()
    if BlatantV2.Active then return end
    
    BlatantV2.Active = true
    BlatantV2.Stats.castCount = 0
    BlatantV2.Stats.startTime = tick()
    
    print("🎯 Blatant V2 (Smart Sync) Started")
    
    -- Reset status karakter sebelum mulai (Anti-Stuck Awal)
    safeFire(RF_CancelFishingInputs)
    task.wait(0.3)
    
    task.spawn(ultraSpamLoop)
end

function BlatantV2.Stop()
    if not BlatantV2.Active then return end
    BlatantV2.Active = false
    
    -- Aktifkan kembali auto-fishing bawaan game agar rod tidak bug
    safeFire(RF_UpdateAutoFishingState, {true})
    task.wait(0.2)
    
    -- Reset posisi akhir
    safeFire(RF_CancelFishingInputs)
    
    print("🎣 Stopped. Total Casts: " .. BlatantV2.Stats.castCount)
end

return BlatantV2