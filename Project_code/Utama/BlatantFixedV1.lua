-- ⚠️ BLATANT V2 - STABLE FAST EDITION
-- Tuned for Speed WITHOUT crashing/stuck

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

-- [[ PENGATURAN "SWEET SPOT" ]]
-- Settingan ini seimbang antara Kecepatan dan Kestabilan Server
BlatantV2.Settings = {
    ChargeDelay = 0.15,   -- Waktu tahan pancingan (Jangan di bawah 0.1!)
    CompleteDelay = 0.05, -- Jeda instan sebelum tarik
    CancelDelay = 0.15,   -- Jeda reset animasi
    PostCastDelay = 0.1   -- Jeda napas antar lemparan
}

local function safeFire(remote, args)
    task.spawn(function()
        pcall(function()
            remote:FireServer(unpack(args or {}))
        end)
    end)
end

local function safeInvoke(remote, args)
    local success, result = pcall(function()
        return remote:InvokeServer(unpack(args or {}))
    end)
    return success and result
end

local function ultraSpamLoop()
    while BlatantV2.Active do
        local startTime = tick()
        
        -- 1. CHARGE (Mulai)
        safeFire(RF_ChargeFishingRod, {[1] = startTime})
        
        -- Tunggu agar server sadar kita sedang charging
        task.wait(BlatantV2.Settings.ChargeDelay)
        
        -- 2. LEMPAR (Request Minigame)
        local releaseTime = tick()
        
        -- [[ PERUBAHAN UTAMA: VALIDASI ]]
        -- Kita WAJIB pakai InvokeServer di sini untuk memastikan lemparan valid
        local castResult = RF_RequestMinigame:InvokeServer(1, 0, releaseTime)
        
        -- 3. LOGIKA SMART (Anti-Ghost & Anti-Stuck)
        if castResult then
            -- [SUKSES] Server menerima lemparan -> BARU KITA TARIK
            BlatantV2.Stats.castCount = BlatantV2.Stats.castCount + 1
            BlatantV2.Stats.perfectCasts = BlatantV2.Stats.perfectCasts + 1
            
            -- Tunggu sebentar (simulasi reflex manusia super cepat)
            task.wait(BlatantV2.Settings.CompleteDelay)
            
            -- Tarik Ikan
            safeFire(RE_FishingCompleted)
            
            -- Tunggu reset
            task.wait(BlatantV2.Settings.CancelDelay)
            safeFire(RF_CancelFishingInputs)
        else
            -- [GAGAL] Server menolak lemparan (biasanya karena cooldown/lag)
            -- JANGAN tarik ikan! Langsung reset paksa agar tidak stuck.
            safeFire(RF_CancelFishingInputs)
            
            -- Beri hukuman waktu sedikit agar server tidak spam error
            task.wait(0.25) 
        end

        -- Jeda Napas (Penting agar Ping tidak naik dan urutan tidak tertukar)
        task.wait(BlatantV2.Settings.PostCastDelay)
    end
end

-- Backup Listener (Jaga-jaga jika script macet)
RE_MinigameChanged.OnClientEvent:Connect(function(state)
    if not BlatantV2.Active then return end
    
    -- Jika tiba-tiba muncul UI minigame (artinya loop di atas lolos)
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
    print("✅ Settings Updated")
end

function BlatantV2.Start()
    if BlatantV2.Active then return end
    
    BlatantV2.Active = true
    BlatantV2.Stats.castCount = 0
    BlatantV2.Stats.perfectCasts = 0
    BlatantV2.Stats.startTime = tick()
    
    print("🎯 Blatant V2 (Stable-Fast) Started")
    
    -- Reset status karakter sebelum mulai
    safeFire(RF_CancelFishingInputs)
    task.wait(0.25)
    
    task.spawn(ultraSpamLoop)
end

function BlatantV2.Stop()
    if not BlatantV2.Active then return end
    BlatantV2.Active = false
    
    -- Aktifkan kembali auto-fishing bawaan game agar rod tidak bug
    safeFire(RF_UpdateAutoFishingState, {true})
    task.wait(0.2)
    
    -- Reset posisi
    safeFire(RF_CancelFishingInputs)
    
    print("🎣 Stopped. Total: " .. BlatantV2.Stats.castCount)
end

return BlatantV2