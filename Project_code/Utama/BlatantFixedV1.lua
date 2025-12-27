-- ⚠️ BLATANT V2 AUTO FISHING - SMART LOGIC EDITION
-- FIX: Ghost Cast (Kosong ditarik) & Stuck (Tidak mau Charge)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Network initialization
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
    perfectCasts = 0,
    startTime = 0
}

-- [[ PENGATURAN LOGIKA BARU ]]
BlatantV2.Settings = {
    ChargeDelay = 0.15,   -- Waktu tahan klik (Wajib ada agar server baca)
    CompleteDelay = 0.05, -- Jeda sebelum tarik
    CancelDelay = 0.15,   -- Jeda sebelum reset
    PostCastDelay = 0.1   -- Jeda napas antar putaran
}

-- Helper untuk menjalankan fungsi tanpa memblokir thread utama, tapi bisa mengembalikan nilai jika perlu
local function safeInvoke(remote, args)
    local success, result = pcall(function()
        return remote:InvokeServer(unpack(args or {}))
    end)
    return success and result
end

local function safeFire(remote, args)
    task.spawn(function()
        pcall(function()
            remote:FireServer(unpack(args or {}))
        end)
    end)
end

local function ultraSpamLoop()
    while BlatantV2.Active do
        local startTime = tick()
        
        -- 1. CHARGE (Mulai Tahan)
        -- Kita fire event ini, server akan mencatat kita sedang siap melempar
        safeInvoke(RF_ChargeFishingRod, {{[1] = startTime}})
        
        -- Tunggu sebentar agar server memproses status "Charging"
        task.wait(BlatantV2.Settings.ChargeDelay)
        
        -- 2. REQUEST MINIGAME (Lepas/Lempar)
        local releaseTime = tick()
        
        -- [[ LOGIKA PENTING DI SINI ]] --
        -- Kita gunakan InvokeServer (bukan Fire) agar kita tahu apakah lemparan BERHASIL atau GAGAL
        local castResult = RF_RequestMinigame:InvokeServer(1, 0, releaseTime)
        
        -- Cek apakah server menerima lemparan kita?
        if castResult then
            -- A. JIKA SUKSES LEMPAR -> LANJUT TARIK
            BlatantV2.Stats.castCount = BlatantV2.Stats.castCount + 1
            BlatantV2.Stats.perfectCasts = BlatantV2.Stats.perfectCasts + 1
            
            -- Tunggu sebentar (simulasi minigame instan)
            task.wait(BlatantV2.Settings.CompleteDelay)
            
            -- Selesaikan Minigame (Tarik Ikan)
            safeFire(RE_FishingCompleted)
            
            -- Tunggu sebentar sebelum reset posisi
            task.wait(BlatantV2.Settings.CancelDelay)
            
            -- Reset Posisi (Cancel Animation)
            safeInvoke(RF_CancelFishingInputs)
        else
            -- B. JIKA GAGAL LEMPAR (Stuck/Server Lag)
            -- Jangan kirim FishingCompleted! Langsung paksa reset agar tidak stuck.
            
            -- Force Reset
            safeInvoke(RF_CancelFishingInputs)
            
            -- Tunggu lebih lama sedikit agar server "bernapas"
            task.wait(0.2)
        end

        -- Jeda Aman Antar Putaran (Wajib ada agar tidak desync lagi)
        task.wait(BlatantV2.Settings.PostCastDelay)
    end
end

-- Backup listener (Hanya aktif jika script macet total)
RE_MinigameChanged.OnClientEvent:Connect(function(state)
    if not BlatantV2.Active then return end
    
    -- Jika tiba-tiba muncul minigame (berarti loop di atas lolos), selesaikan saja
    if type(state) == "string" and state:lower():find("hook") then
        task.wait(BlatantV2.Settings.CompleteDelay)
        safeFire(RE_FishingCompleted)
        task.wait(BlatantV2.Settings.CancelDelay)
        safeInvoke(RF_CancelFishingInputs)
    end
end)

-- Public API
function BlatantV2.UpdateSettings(completeDelay, cancelDelay)
    if completeDelay then BlatantV2.Settings.CompleteDelay = completeDelay end
    if cancelDelay then BlatantV2.Settings.CancelDelay = cancelDelay end
    print("✅ Settings Updated")
end

function BlatantV2.Start()
    if BlatantV2.Active then return end
    
    BlatantV2.Active = true
    BlatantV2.Stats.castCount = 0
    BlatantV2.Stats.perfectCasts = 0
    BlatantV2.Stats.startTime = tick()
    
    print("🎯 Blatant V2 (Smart Logic) Started")
    
    -- Pastikan status bersih sebelum mulai
    safeInvoke(RF_CancelFishingInputs)
    task.wait(0.2)
    
    task.spawn(ultraSpamLoop)
end

function BlatantV2.Stop()
    if not BlatantV2.Active then return end
    BlatantV2.Active = false
    
    -- Aktifkan kembali auto-fishing bawaan game
    safeInvoke(RF_UpdateAutoFishingState, {true})
    task.wait(0.2)
    
    -- Reset posisi akhir
    safeInvoke(RF_CancelFishingInputs)
    
    print("🎣 Stopped. Total Casts: " .. BlatantV2.Stats.castCount)
end

return BlatantV2