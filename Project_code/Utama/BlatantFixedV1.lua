-- ⚠️ BLATANT V2 - STABLE FAST EDITION (REMASTERED)
-- Fix: Ghost Cast, Loop Tertukar, & Stuck Character

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

-- Network Initialization
local netFolder = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")

local RF_ChargeFishingRod = netFolder:WaitForChild("RF/ChargeFishingRod")
local RF_RequestMinigame = netFolder:WaitForChild("RF/RequestFishingMinigameStarted")
local RF_CancelFishingInputs = netFolder:WaitForChild("RF/CancelFishingInputs")
local RF_UpdateAutoFishingState = netFolder:WaitForChild("RF/UpdateAutoFishingState")
local RE_FishingCompleted = netFolder:WaitForChild("RE/FishingCompleted")
local RE_MinigameChanged = netFolder:WaitForChild("RE/FishingMinigameChanged")

local fishing = {
    Running = false,
    Stats = { Casts = 0, Catches = 0 },
    -- [[ PENGATURAN "SWEET SPOT" ]]
    Settings = {
        ChargeDelay = 0.15,   -- Wajib 0.15+ agar server mendeteksi charge
        CompleteDelay = 0.05, -- Jeda sebelum tarik ikan
        CancelDelay = 0.15,   -- Jeda reset animasi
        PostCastDelay = 0.1   -- Jeda napas antar putaran
    }
}

_G.FishingScript = fishing

local function log(msg)
    print("[⚡Fishing] " .. msg)
end

-- Helper: Fire & Forget (Cepat)
local function safeFire(remote, args)
    task.spawn(function()
        pcall(function() remote:FireServer(unpack(args or {})) end)
    end)
end

-- [[ LOGIKA UTAMA (SMART LOOP) ]] --
local function runFishingLoop()
    while fishing.Running do
        local startTime = tick()
        
        -- 1. CHARGE (Isi Tenaga)
        safeFire(RF_ChargeFishingRod, {[1] = startTime})
        
        -- Tunggu agar server memproses status "Charging"
        task.wait(fishing.Settings.ChargeDelay)
        
        -- 2. LEMPAR (Request Minigame)
        local releaseTime = tick()
        
        -- [VALIDASI] Kita tanya server: "Lemparan sukses gak?"
        local success, castResult = pcall(function()
            return RF_RequestMinigame:InvokeServer(1, 0, releaseTime)
        end)
        
        if success and castResult then
            -- [KONDISI A: SUKSES] Server menerima lemparan
            fishing.Stats.Casts = fishing.Stats.Casts + 1
            
            -- Tunggu sebentar (Reflex Manusia)
            task.wait(fishing.Settings.CompleteDelay)
            
            -- TARIK IKAN
            safeFire(RE_FishingCompleted)
            fishing.Stats.Catches = fishing.Stats.Catches + 1
            
            -- RESET POSISI
            task.wait(fishing.Settings.CancelDelay)
            safeFire(RF_CancelFishingInputs)
        else
            -- [KONDISI B: GAGAL] Server menolak (Cooldown/Lag)
            -- JANGAN TARIK IKAN! Langsung reset agar tidak stuck.
            safeFire(RF_CancelFishingInputs)
            
            -- Hukuman waktu agar server bernapas
            task.wait(0.25)
        end

        -- Jeda Napas Antar Loop (Penting untuk Sinkronisasi)
        task.wait(fishing.Settings.PostCastDelay)
    end
end

-- Backup Listener (Hanya jaga-jaga jika script macet total)
RE_MinigameChanged.OnClientEvent:Connect(function(state)
    if not fishing.Running then return end
    
    -- Jika tiba-tiba muncul minigame (berarti loop lolos), selesaikan saja
    if type(state) == "string" and state:lower():find("hook") then
        task.wait(fishing.Settings.CompleteDelay)
        safeFire(RE_FishingCompleted)
        task.wait(fishing.Settings.CancelDelay)
        safeFire(RF_CancelFishingInputs)
    end
end)

-- [[ FUNGSI KONTROL ]] --

function fishing.Start()
    if fishing.Running then return end
    fishing.Running = true
    fishing.Stats.Casts = 0
    fishing.Stats.Catches = 0
    
    log("🚀 ULTRA SPEED (STABLE) ACTIVATED!")
    
    -- Reset status awal
    safeFire(RF_CancelFishingInputs)
    task.wait(0.3)
    
    -- Jalankan Loop di thread terpisah
    task.spawn(runFishingLoop)
end

function fishing.Stop()
    if not fishing.Running then return end
    fishing.Running = false
    
    -- Aktifkan kembali auto-fishing game & Reset
    safeFire(RF_UpdateAutoFishingState, {true})
    task.wait(0.2)
    safeFire(RF_CancelFishingInputs)
    
    log("🛑 STOPPED | Stats: " .. fishing.Stats.Catches .. " catches")
end

function fishing.UpdateSettings(k, v)
    if fishing.Settings[k] then fishing.Settings[k] = v end
end

return fishing