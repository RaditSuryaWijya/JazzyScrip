-- [[ SECURITY LOADER: FINAL FIX (BOM REMOVAL & SMART VALIDATION) ]]
-- Fixes:
-- 1. U+feff Syntax Error (BOM Removal)
-- 2. False Positive "404" error on Vector3 coordinates
-- 3. HTML Error Page handling

local SecurityLoader = {}

-- ============================================
-- CONFIGURATION
-- ============================================
local CONFIG = {
    VERSION = "2.3.3-FinalFix",
    ALLOWED_DOMAIN = "raw.githubusercontent.com",
    MAX_LOADS_PER_SESSION = 100,
    ENABLE_RATE_LIMITING = true,
    ENABLE_DOMAIN_CHECK = false, -- Disabled for compatibility
    USE_DIRECT_URLS = true
}

-- ============================================
-- BASE URL (DEFAULT)
-- ============================================
local BASE_URL = "https://raw.githubusercontent.com/RaditSuryaWijya/JazzyScrip/refs/heads/main/Project_code/"

-- ============================================
-- MODULE PATHS
-- ============================================
local modulePaths = {
    instant = "Instant.lua",
    instant2 = "Instant2.lua",
    blatantv1 = "Utama/BlatantV1.lua",
    UltraBlatant = "Utama/BlatantV2.lua",
    blatantv2 = "BlatantV2.lua",
    blatantv2fix = "Utama/BlatantFixedV1.lua",
    NoFishingAnimation = "Utama/NoFishingAnimation.lua",
    LockPosition = "Utama/LockPosition.lua",
    AutoEquipRod = "Utama/AutoEquipRod.lua",
    DisableCutscenes = "Utama/DisableCutscenes.lua",
    DisableExtras = "Utama/DisableExtras.lua",
    AutoTotem3X = "Utama/AutoTotem3x.lua",
    SkinAnimation = "Utama/SkinSwapAnimation.lua",
    WalkOnWater = "Utama/WalkOnWater.lua",
    TeleportModule = "TeleportSystem/TeleportModule.lua",
    TeleportToPlayer = "TeleportSystem/TeleportToPlayer.lua",
    SavedLocation = "TeleportSystem/SavedLocation.lua",
    AutoQuestModule = "Quest/AutoQuestModule.lua",
    AutoTemple = "Quest/LeverQuest.lua",
    TempleDataReader = "Quest/TempleDataReader.lua",
    AutoSell = "ShopFeatures/AutoSell.lua",
    AutoSellTimer = "ShopFeatures/AutoSellTimer.lua",
    MerchantSystem = "ShopFeatures/OpenShop.lua",
    RemoteBuyer = "ShopFeatures/RemoteBuyer.lua",
    FreecamModule = "Camera View/FreecamModule.lua",
    UnlimitedZoomModule = "Camera View/UnlimitedZoom.lua",
    AntiAFK = "Misc/AntiAFK.lua",
    UnlockFPS = "Misc/UnlockFPS.lua",
    FPSBooster = "Misc/FpsBooster.lua",
    AutoBuyWeather = "ShopFeatures/AutoBuyWeather.lua",
    Notify = "Notification.lua",
    EventTeleportDynamic = "TeleportSystem/EventTeleportDynamic.lua",
    HideStats = "Misc/HideStats.lua",
    Webhook = "Misc/Webhook.lua",
    GoodPerfectionStable = "Utama/PerfectionGood.lua",
    DisableRendering = "Misc/DisableRendering.lua",
    AutoFavorite = "Utama/AutoFavorite.lua",
    PingFPSMonitor = "Misc/PingPanel.lua",
    MovementModule = "Misc/MovementModule.lua",
}

-- ============================================
-- RATE LIMITING
-- ============================================
local loadCounts = {}
local lastLoadTime = {}

local function checkRateLimit()
    if not CONFIG.ENABLE_RATE_LIMITING then return true end
    local identifier = game:GetService("RbxAnalyticsService"):GetClientId()
    local currentTime = tick()
    loadCounts[identifier] = (loadCounts[identifier] or 0)
    lastLoadTime[identifier] = (lastLoadTime[identifier] or 0)
    
    if currentTime - lastLoadTime[identifier] > 3600 then loadCounts[identifier] = 0 end
    if loadCounts[identifier] >= CONFIG.MAX_LOADS_PER_SESSION then
        warn("⚠️ Rate limit exceeded.")
        return false
    end
    loadCounts[identifier] = loadCounts[identifier] + 1
    lastLoadTime[identifier] = currentTime
    return true
end

-- ============================================
-- LOAD MODULE FUNCTION (CORE FIX)
-- ============================================
function SecurityLoader.LoadModule(moduleName)
    if not checkRateLimit() then return nil end
    
    local path = modulePaths[moduleName]
    if not path then
        warn("❌ Module path not found:", moduleName)
        return nil
    end

    -- 1. Construct URL
    local finalURL = BASE_URL .. path

    -- [[ AUTO-FIX URL ]]
    -- Hapus 'refs/heads/' secara otomatis untuk menghindari error HTML 404
    -- Ini aman dilakukan untuk semua modul di Raw GitHub
    finalURL = finalURL:gsub("refs/heads/", "")

    local success, result = pcall(function()
        -- Request Script
        local scriptContent = game:HttpGet(finalURL, true)
        
        if not scriptContent or scriptContent == "" then
            error("Empty content received")
        end
        
        -- [[ FIX 1: BOM REMOVAL (U+feff Error Fix) ]]
        -- Membersihkan karakter sampah di awal file
        if scriptContent:sub(1, 3) == "\239\187\191" then
            scriptContent = scriptContent:sub(4)
        end
        
        -- [[ FIX 2: SMART VALIDATION (TeleportModule Fix) ]]
        -- Kita HAPUS pengecekan "404" yang menyebabkan False Positive pada koordinat
        -- Kita ganti dengan pengecekan tag HTML yang spesifik di awal file
        if scriptContent:find("^%s*<!DOCTYPE") or scriptContent:find("^%s*<html") then
             local preview = scriptContent:sub(1, 100)
             warn("⚠️ HTML Detected in " .. moduleName .. ":\n" .. preview)
             error("HTML Error Page Received (Invalid URL)")
        end

        -- Execute
        local func, loadErr = loadstring(scriptContent, moduleName)
        if not func then 
            error("Syntax Error: " .. tostring(loadErr)) 
        end
        
        return func()
    end)
    
    if not success then
        warn("❌ Failed to load", moduleName)
        -- warn("   URL:", finalURL) -- Uncomment untuk debug URL
        warn("   Error:", result)
        return nil
    end
    
    return result
end

-- ============================================
-- UTILS
-- ============================================
function SecurityLoader.GetSessionInfo()
    return {Version = CONFIG.VERSION}
end

print("━━━━━━━━━━━━━━━━━━━━━━")
print("🔒 Jazzy Security Loader v" .. CONFIG.VERSION)
print("✅ BOM Removal Active (U+feff Fix)")
print("✅ Smart Validation Active (Coordinate Safe)")
print("━━━━━━━━━━━━━━━━━━━━━━")

return SecurityLoader
