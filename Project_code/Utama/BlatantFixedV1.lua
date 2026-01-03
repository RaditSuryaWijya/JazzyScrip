-- ⚡ BLATANT FIXED V1 - STABLE ROTATION (STATE ENFORCED)
-- Fixes: Loop Tertukar, Ghost Cast, Wrong Arguments
-- Feature: Force State 'Seated' & Animation ID 178130996 (Sesuai Log Spy)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

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
local RE_FishingStopped = netFolder:WaitForChild("RE/FishingStopped")

-- Module Definition
local BlatantFixedV1 = {}
BlatantFixedV1.Active = false
BlatantFixedV1.CurrentSeat = nil
BlatantFixedV1.OriginalStats = { WalkSpeed = 16, JumpPower = 50 } 
BlatantFixedV1.Stats = {
    castCount = 0,
    startTime = 0
}

-- [[ SETTINGAN FIX ]]
BlatantFixedV1.Settings = {
    ChargeDelay = 0.15,   
    CompleteDelay = 0.05, 
    CancelDelay = 0.15,   
    ReCastDelay = 0.05    
}

-- State tracking
local FishingState = {
    isInCycle = false
}

----------------------------------------------------------------
-- CORE FUNCTIONS
----------------------------------------------------------------

local function safeFire(func)
    task.spawn(function()
        local success, err = pcall(func)
    end)
end

-- Fungsi Memaksa State Sesuai Log Spy
local function enforceSeatedState()
    local char = LocalPlayer.Character
    local human = char and char:FindFirstChild("Humanoid")
    
    -- Cek 1: Apakah Humanoid ada?
    if not human then return end
    
    -- Cek 2: Apakah State sesuai log (Seated)?
    if human:GetState() ~= Enum.HumanoidStateType.Seated then
        -- Jika tidak duduk, kita paksa duduk lagi di kursi kita
        if BlatantFixedV1.CurrentSeat then
            BlatantFixedV1.CurrentSeat:Sit(human)
        end
    end
end

-- [[ LOGIKA UTAMA ]] --
local function fishingLoop()
    while BlatantFixedV1.Active do
        FishingState.isInCycle = true
        local startTime = tick()
        
        -- [UPDATE] Pastikan State 'Seated' aktif setiap awal putaran
        enforceSeatedState()
        
        -- [LANGKAH 1: PRE-RESET]
        safeFire(function() RF_CancelFishingInputs:InvokeServer() end)
        task.wait(0.05) 
        
        -- [LANGKAH 2: CHARGE]
        safeFire(function() 
            RF_ChargeFishingRod:InvokeServer({[10] = startTime}) 
        end)
        
        task.wait(BlatantFixedV1.Settings.ChargeDelay)
        
        -- [LANGKAH 3: CAST]
        local releaseTime = tick()
        safeFire(function() 
            RF_RequestMinigame:InvokeServer(10, 0, releaseTime) 
        end)
        
        BlatantFixedV1.Stats.castCount = BlatantFixedV1.Stats.castCount + 1
        
        -- [LANGKAH 4: CATCH]
        task.wait(BlatantFixedV1.Settings.CompleteDelay)
        
        safeFire(function() 
            RE_FishingCompleted:FireServer() 
        end)
        
        -- [LANGKAH 5: POST-RESET]
        task.wait(BlatantFixedV1.Settings.CancelDelay)
        
        safeFire(function() 
            RF_CancelFishingInputs:InvokeServer() 
        end)
        
        FishingState.isInCycle = false
        
        task.wait(BlatantFixedV1.Settings.ReCastDelay)
    end
    
    FishingState.isInCycle = false
end

RE_MinigameChanged.OnClientEvent:Connect(function(state)
    if not BlatantFixedV1.Active then return end
    
    if type(state) == "string" and state:lower():find("hook") then
        task.wait(BlatantFixedV1.Settings.CompleteDelay)
        safeFire(function() RE_FishingCompleted:FireServer() end)
        task.wait(BlatantFixedV1.Settings.CancelDelay)
        safeFire(function() RF_CancelFishingInputs:InvokeServer() end)
    end
end)

----------------------------------------------------------------
-- PUBLIC API
----------------------------------------------------------------

function BlatantFixedV1.UpdateSettings(completeDelay, cancelDelay, reCastDelay)
    if completeDelay then BlatantFixedV1.Settings.CompleteDelay = completeDelay end
    if cancelDelay then BlatantFixedV1.Settings.CancelDelay = cancelDelay end
    if reCastDelay then BlatantFixedV1.Settings.ReCastDelay = reCastDelay end
    print("✅ BlatantFixedV1 Settings Updated")
end

function BlatantFixedV1.Start()
    if BlatantFixedV1.Active then return false end
    
    BlatantFixedV1.Active = true
    BlatantFixedV1.Stats.castCount = 0
    BlatantFixedV1.Stats.startTime = tick()
    FishingState.isInCycle = false
    
    print("🚀 BlatantFixedV1 (State Enforced) Started")
    
    -- [[ IMPLEMENTASI LOG SPY ]] --
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local human = char and char:FindFirstChild("Humanoid")

    if root and human then
        -- Simpan stats asli
        BlatantFixedV1.OriginalStats.WalkSpeed = human.WalkSpeed
        BlatantFixedV1.OriginalStats.JumpPower = human.JumpPower or 50

        -- Kunci Gerakan (Biar State tidak berubah jadi Running/Jumping)
        human.WalkSpeed = 0
        human.JumpPower = 0
        
        -- Bersihkan kursi lama
        if BlatantFixedV1.CurrentSeat then 
            BlatantFixedV1.CurrentSeat:Destroy()
            BlatantFixedV1.CurrentSeat = nil
        end

        -- Buat Kursi (Sesuai log: ClassName Seat)
        local seat = Instance.new("Seat")
        seat.Name = "chair"          -- [UBAH NAMA] Sesuai log kamu biar persis
        seat.Transparency = 1        
        seat.CanCollide = false     
        seat.Anchored = true         
        seat.Size = Vector3.new(1, 1, 1)
        seat.CFrame = root.CFrame    
        seat.Parent = workspace      

        -- Paksa Duduk (Ini otomatis memicu Animasi ID: 178130996)
        seat:Sit(human)
        BlatantFixedV1.CurrentSeat = seat
    end
    -- [[ END IMPLEMENTASI ]] --
    
    -- Reset Network
    safeFire(function() RF_CancelFishingInputs:InvokeServer() end)
    safeFire(function() RF_UpdateAutoFishingState:InvokeServer(true) end)
    
    task.wait(0.2)
    task.spawn(fishingLoop)
    return true
end

function BlatantFixedV1.Stop()
    if not BlatantFixedV1.Active then return false end
    
    BlatantFixedV1.Active = false
    FishingState.isInCycle = false
    
    -- Cleanup Network
    safeFire(function() RF_UpdateAutoFishingState:InvokeServer(true) end)
    task.wait(0.2)
    safeFire(function() RF_CancelFishingInputs:InvokeServer() end)
    
    -- Cleanup Seat & State
    if BlatantFixedV1.CurrentSeat then
        BlatantFixedV1.CurrentSeat:Destroy()
        BlatantFixedV1.CurrentSeat = nil
    end
    
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        -- Kembalikan kemampuan gerak
        char.Humanoid.WalkSpeed = BlatantFixedV1.OriginalStats.WalkSpeed
        char.Humanoid.JumpPower = BlatantFixedV1.OriginalStats.JumpPower
        
        -- Paksa Ubah State ke Jumping (Berdiri)
        char.Humanoid.Sit = false
        char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
    
    print("🛑 Stopped. Casts: " .. BlatantFixedV1.Stats.castCount)
    return true
end

function BlatantFixedV1.GetStats()
    local runtime = math.floor(tick() - BlatantFixedV1.Stats.startTime)
    local cps = runtime > 0 and math.floor(BlatantFixedV1.Stats.castCount / runtime * 10) / 10 or 0
    
    return {
        castCount = BlatantFixedV1.Stats.castCount,
        runtime = runtime,
        cps = cps,
        isActive = BlatantFixedV1.Active,
        isInCycle = FishingState.isInCycle
    }
end

return BlatantFixedV1
