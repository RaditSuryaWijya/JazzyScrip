local AutoTotem9X = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

-- ============================================
-- NETWORK REMOTES
-- ============================================
local Net = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")
local RE_SpawnTotem = Net:WaitForChild("RE/SpawnTotem")

-- ============================================
-- SETTINGS
-- ============================================
-- ID Totem (Ganti sesuai kebutuhan):
-- 1 = Luck, 2 = Mutation, 3 = Shiny, 11 = Sundial, 12 = Aurora, 10 = Windset
local TARGET_TOTEM_ID = 11 -- Default: Sundial (Contoh)

local TRIANGLE_RADIUS = 58   -- Jarak menyebar (Horizontal)
local VERTICAL_OFFSET = 100  -- Jarak tinggi (Y Axis)
local CENTER_OFFSET = Vector3.new(0, 0, -7.25)
local SPAWN_DELAY = 0.8      -- Delay antar spawn (detik)

local isRunning = false

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Fungsi mencari UUID Totem di Inventory
local function GetTotemUUID(targetId)
    -- Akses data pemain di ReplicatedStorage
    local playerData = ReplicatedStorage:FindFirstChild("PlayerData")
    if not playerData then return nil end
    
    local myData = playerData:FindFirstChild(LP.Name)
    if not myData then return nil end
    
    local inventory = myData:FindFirstChild("Inventory")
    if not inventory then return nil end
    
    local totems = inventory:FindFirstChild("Totems")
    if not totems then return nil end
    
    -- Loop cari totem yang cocok
    for _, item in ipairs(totems:GetChildren()) do
        -- Cek apakah ID item sesuai target (dan belum habis stack-nya jika ada sistem stack)
        if item:GetAttribute("Id") == targetId then
            -- Kembalikan UUID (Nama instance atau attribute UUID)
            return item:GetAttribute("UUID") or item.Name 
        end
    end
    
    return nil
end

-- Teleport & Anchor Function
local function tp(pos)
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        root.Anchored = true -- Kunci agar tidak jatuh
        root.CFrame = CFrame.new(pos)
    end
end

-- ============================================
-- MAIN LOGIC
-- ============================================

function AutoTotem9X.Start()
    if isRunning then return false end
    isRunning = true
    
    task.spawn(function()
        local char = LP.Character or LP.CharacterAdded:Wait()
        local root = char:WaitForChild("HumanoidRootPart")
        
        -- Simpan posisi awal untuk kembali nanti
        local startCFrame = root.CFrame
        local centerPos = root.Position + CENTER_OFFSET
        
        -- 1. Kalkulasi Formasi (Segitiga Dasar)
        local basePositions = {}
        local angles = {90, 210, 330}
        
        for _, angleDeg in ipairs(angles) do
            local angleRad = math.rad(angleDeg)
            local offsetX = TRIANGLE_RADIUS * math.cos(angleRad)
            local offsetZ = TRIANGLE_RADIUS * math.sin(angleRad)
            table.insert(basePositions, centerPos + Vector3.new(offsetX, 0, offsetZ))
        end
        
        -- 2. Kalkulasi 9 Posisi (3 Level Ketinggian)
        local finalPositions = {}
        
        -- Level Tengah (Posisi 1, 2, 3)
        for _, pos in ipairs(basePositions) do table.insert(finalPositions, pos) end
        
        -- Level Atas (Posisi 4, 5, 6)
        for _, pos in ipairs(basePositions) do table.insert(finalPositions, pos + Vector3.new(0, VERTICAL_OFFSET, 0)) end
        
        -- Level Bawah (Posisi 7, 8, 9)
        for _, pos in ipairs(basePositions) do table.insert(finalPositions, pos - Vector3.new(0, VERTICAL_OFFSET, 0)) end
        
        print("🚀 Memulai Auto Spawn 9 Totem (UUID Mode)...")

        -- 3. Eksekusi Loop
        for i, targetPos in ipairs(finalPositions) do
            if not isRunning then break end
            
            -- A. Teleport
            tp(targetPos)
            task.wait(0.2) -- Tunggu sebentar agar posisi server sync
            
            -- B. Cari UUID Totem (Scan ulang setiap kali, karena UUID bisa berubah/hilang setelah dipakai)
            local uuid = GetTotemUUID(TARGET_TOTEM_ID)
            
            if uuid then
                -- C. Spawn Totem via Remote
                pcall(function()
                    RE_SpawnTotem:FireServer(uuid)
                end)
                print("✅ Spawned Totem #" .. i)
            else
                print("⚠️ Stok Totem Habis / Tidak Ditemukan!")
                break -- Berhenti jika totem habis
            end
            
            task.wait(SPAWN_DELAY)
        end
        
        -- 4. Selesai & Kembali
        if root then
            root.Anchored = false
            root.CFrame = startCFrame
        end
        
        isRunning = false
        print("🏁 Selesai!")
    end)
    
    return true
end

function AutoTotem9X.Stop()
    isRunning = false
    -- Safety release
    local char = LP.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.Anchored = false
    end
    return true
end

-- Update ID Totem secara dinamis (untuk integrasi GUI)
function AutoTotem9X.SetTotemID(id)
    TARGET_TOTEM_ID = id
end

function AutoTotem9X.IsRunning()
    return isRunning
end

return AutoTotem9X
