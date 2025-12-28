-- ⚠️ BLATANT V2 - STABLE FAST EDITION (FIXED ARGUMENTS)
-- Fix: Argumen Remote disesuaikan dengan versi game saat ini

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
    Stats = { Casts = 0 },
    Settings = {
        ChargeDelay = 0.15,   -- Wajib ada
        CompleteDelay = 0.05, -- Jeda sebelum tarik
        CancelDelay = 0.15,   -- Jeda reset
        PostCastDelay = 0.1   -- Jeda antar loop
    }
}

_G.FishingScript = fishing

local function log(msg)
    print("[⚡Fishing] " .. msg)
end

local function safeFire(remote, args)
    task.spawn(function()
        pcall(function() remote:FireServer(unpack(args or {})) end)
    end)
end

-- [[ LOGIKA UTAMA (ARGUMENTS FIXED) ]] --
local function runFishingLoop()
    while fishing.Running do
        local startTime = tick()
        
        -- 1. CHARGE (Isi Tenaga)
        -- [FIX] Menggunakan index [10] sesuai script asli game
        pcall(function()
            RF_ChargeFishingRod:InvokeServer({[10] = startTime})
        end)
        
        task.wait(fishing.Settings.ChargeDelay)
        
        -- 2. LEMPAR (Request Minigame)
        local releaseTime = tick()
        
        -- [FIX] Menggunakan power 10 (atau 9) sesuai script asli
        -- Kita gunakan pcall agar jika gagal tidak mematikan script
        local success, result = pcall(function()
            -- Arg 1: Power (10), Arg 2: Cursor (0), Arg 3: Time
            return RF_RequestMinigame:InvokeServer(10, 0, releaseTime)
        end)
        
        fishing.Stats.Casts = fishing.Stats.Casts + 1
        
        -- 3. EKSEKUSI (BLATANT MODE)
        -- Kita tidak menunggu "result" true/false karena kadang server tidak return apa-apa
        -- Kita langsung asumsikan berhasil (Blatant Style)
        
        task.wait(fishing.Settings.CompleteDelay)
        
        -- TARIK IKAN
        safeFire(RE_FishingCompleted)
        
        -- RESET POSISI
        task.wait(fishing.Settings.CancelDelay)
        safeFire(RF_CancelFishingInputs)

        -- Jeda Napas
        task.wait(fishing.Settings.PostCastDelay)
    end
end

-- Backup Listener (Jika macet)
RE_MinigameChanged.OnClientEvent:Connect(function(state)
    if not fishing.Running then return end
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
    
    log("🚀 BLATANT V2 STARTED (ARGUMENT FIXED)")
    
    -- Reset awal
    safeFire(RF_CancelFishingInputs)
    task.wait(0.3)
    
    task.spawn(runFishingLoop)
end

function fishing.Stop()
    if not fishing.Running then return end
    fishing.Running = false
    
    -- Cleanup
    safeFire(RF_UpdateAutoFishingState, {true})
    task.wait(0.2)
    safeFire(RF_CancelFishingInputs)
    
    log("🛑 STOPPED")
end

function fishing.UpdateSettings(k, v)
    if fishing.Settings[k] then fishing.Settings[k] = v end
end

return fishing