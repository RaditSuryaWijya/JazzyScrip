-- [[ BLATANT FIXED V1 - STABLE FAST EDITION ]]
-- Filename: BlatantFixedV1.lua
-- Fixes: Argument Error, Ghost Cast, & Character Stuck

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

local BlatantFixedV1 = {}
BlatantFixedV1.Active = false
BlatantFixedV1.Stats = {
    castCount = 0,
    startTime = 0
}

-- [[ PENGATURAN "SWEET SPOT" (STABIL & CEPAT) ]]
BlatantFixedV1.Settings = {
    ChargeDelay = 0.15,   -- Wajib 0.15+ agar server mendeteksi charge
    CompleteDelay = 0.05, -- Jeda sebelum tarik ikan
    CancelDelay = 0.15,   -- Jeda reset animasi
    PostCastDelay = 0.1   -- Jeda napas antar putaran
}

local function safeFire(remote, args)
    task.spawn(function()
        pcall(function() remote:FireServer(unpack(args or {})) end)
    end)
end

-- [[ LOGIKA UTAMA (SMART LOOP) ]] --
local function runFishingLoop()
    while BlatantFixedV1.Active do
        local startTime = tick()
        
        -- 1. CHARGE (Isi Tenaga)
        -- Menggunakan index [10] sesuai script asli game
        pcall(function()
            RF_ChargeFishingRod:InvokeServer({[10] = startTime})
        end)
        
        -- Tunggu agar server memproses status "Charging"
        task.wait(BlatantFixedV1.Settings.ChargeDelay)
        
        -- 2. LEMPAR (Request Minigame)
        local releaseTime = tick()
        
        -- [VALIDASI] Kita tanya server: "Lemparan sukses gak?"
        -- Menggunakan Power 10
        local success, castResult = pcall(function()
            return RF_RequestMinigame:InvokeServer(10, 0, releaseTime)
        end)
        
        if success and castResult then
            -- [KONDISI A: SUKSES] Server menerima lemparan
            BlatantFixedV1.Stats.castCount = BlatantFixedV1.Stats.castCount + 1
            
            -- Tunggu sebentar (Reflex Manusia)
            task.wait(BlatantFixedV1.Settings.CompleteDelay)
            
            -- TARIK IKAN
            safeFire(RE_FishingCompleted)
            
            -- RESET POSISI
            task.wait(BlatantFixedV1.Settings.CancelDelay)
            safeFire(RF_CancelFishingInputs)
        else
            -- [KONDISI B: GAGAL] Server menolak (Cooldown/Lag)
            -- JANGAN TARIK IKAN! Langsung reset agar tidak stuck.
            safeFire(RF_CancelFishingInputs)
            
            -- Hukuman waktu agar server bernapas
            task.wait(0.25)
        end

        -- Jeda Napas Antar Loop (Penting untuk Sinkronisasi)
        task.wait(BlatantFixedV1.Settings.PostCastDelay)
    end
end

-- Backup Listener (Hanya jaga-jaga jika script macet total)
RE_MinigameChanged.OnClientEvent:Connect(function(state)
    if not BlatantFixedV1.Active then return end
    
    -- Jika tiba-tiba muncul minigame (berarti loop lolos), selesaikan saja
    if type(state) == "string" and state:lower():find("hook") then
        task.wait(BlatantFixedV1.Settings.CompleteDelay)
        safeFire(RE_FishingCompleted)
        task.wait(BlatantFixedV1.Settings.CancelDelay)
        safeFire(RF_CancelFishingInputs)
    end
end)

----------------------------------------------------------------
-- PUBLIC API
----------------------------------------------------------------

function BlatantFixedV1.UpdateSettings(completeDelay, cancelDelay)
    if completeDelay then BlatantFixedV1.Settings.CompleteDelay = completeDelay end
    if cancelDelay then BlatantFixedV1.Settings.CancelDelay = cancelDelay end
    print("✅ BlatantFixedV1 Settings Updated")
end

function BlatantFixedV1.Start()
    if BlatantFixedV1.Active then return end
    
    BlatantFixedV1.Active = true
    BlatantFixedV1.Stats.castCount = 0
    BlatantFixedV1.Stats.startTime = tick()
    
    print("🚀 BlatantFixedV1 (Stable) Started")
    
    -- Reset status awal
    safeFire(RF_CancelFishingInputs)
    task.wait(0.3)
    
    -- Jalankan Loop di thread terpisah
    task.spawn(runFishingLoop)
end

function BlatantFixedV1.Stop()
    if not BlatantFixedV1.Active then return end
    
    BlatantFixedV1.Active = false
    
    -- Aktifkan kembali auto-fishing game & Reset
    safeFire(RF_UpdateAutoFishingState, {true})
    task.wait(0.2)
    safeFire(RF_CancelFishingInputs)
    
    print("🛑 BlatantFixedV1 Stopped. Casts: " .. BlatantFixedV1.Stats.castCount)
end

return BlatantFixedV1