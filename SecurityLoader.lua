-- UPDATED SECURITY LOADER (FIXED VALIDATION)
-- Fix: Menghapus deteksi "404" yang menyebabkan False Positive pada koordinat Vector3

local SecurityLoader = {}

-- ============================================
-- CONFIGURATION
-- ============================================
local CONFIG = {
    VERSION = "2.3.1-Fix", -- Updated Version
    ALLOWED_DOMAIN = "raw.githubusercontent.com",
    MAX_LOADS_PER_SESSION = 100,
    ENABLE_RATE_LIMITING = true,
    ENABLE_DOMAIN_CHECK = false,  -- DISABLED for compatibility
    ENABLE_VERSION_CHECK = false,
    USE_DIRECT_URLS = true
}

-- ============================================
-- SECRET KEY (Bypassed logic for simplicity)
-- ============================================
local SECRET_KEY = "JazzyGUI_SuperSecret_2024!@#$%^"

-- ============================================
-- DECRYPTION FUNCTION
-- ============================================
local function decrypt(encrypted, key)
    -- (Fungsi decrypt dibiarkan sama)
    local b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    encrypted = encrypted:gsub('[^'..b64..'=]', '')
    local decoded = (encrypted:gsub('.', function(x)
        if x == '=' then return '' end
        local r, f = '', (b64:find(x)-1)
        for i=6,1,-1 do r = r .. (f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if #x ~= 8 then return '' end
        local c = 0
        for i=1,8 do c = c + (x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
    local result = {}
    for i = 1, #decoded do
        local byte = string.byte(decoded, i)
        local keyByte = string.byte(key, ((i - 1) % #key) + 1)
        table.insert(result, string.char(bit32.bxor(byte, keyByte)))
    end
    return table.concat(result)
end

-- ============================================
-- RATE LIMITING
-- ============================================
local loadCounts = {}
local lastLoadTime = {}

local function checkRateLimit()
    if not CONFIG.ENABLE_RATE_LIMITING then return true end
    local identifier = game:GetService("RbxAnalyticsService"):GetClientId()
    local currentTime = tick()
    loadCounts[identifier] = loadCounts[identifier] or 0
    lastLoadTime[identifier] = lastLoadTime[identifier] or 0
    if currentTime - lastLoadTime[identifier] > 3600 then loadCounts[identifier] = 0 end
    if loadCounts[identifier] >= CONFIG.MAX_LOADS_PER_SESSION then
        warn("⚠️ Rate limit exceeded. Please wait before reloading.")
        return false
    end
    loadCounts[identifier] = loadCounts[identifier] + 1
    lastLoadTime[identifier] = currentTime
    return true
end

-- ============================================
-- DOMAIN VALIDATION
-- ============================================
local BASE_URL = "https://raw.githubusercontent.com/RaditSuryaWijya/JazzyScrip/main/Project_code/"

local function validateDomain(url)
    if not CONFIG.ENABLE_DOMAIN_CHECK then return true end
    if url and url:find(BASE_URL, 1, true) then return true end
    if not url:find(CONFIG.ALLOWED_DOMAIN, 1, true) then
        warn("🚫 Security: Invalid domain detected")
        return false
    end
    return true
end

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
-- LOAD MODULE FUNCTION (FIXED)
-- ============================================
function SecurityLoader.LoadModule(moduleName)
    if not checkRateLimit() then return nil end
    
    local url = nil
    if modulePaths[moduleName] then
        url = BASE_URL .. modulePaths[moduleName]
    end
    
    if not url then
        warn("❌ Module not found:", moduleName)
        return nil
    end
    
    if moduleName == "TeleportModule" then
        print("🔍 Loading TeleportModule from:", url)
    end
    
    local success, result = pcall(function()
        local scriptContent = game:HttpGet(url, true)
        
        if not scriptContent or scriptContent == "" then
            error("Empty content")
        end
        
        -- [[ BAGIAN PERBAIKAN VALIDASI ]] --
        -- Kita HAPUS pengecekan "404" dan "Not Found" yang polos
        -- Kita ganti dengan pengecekan tag HTML yang lebih spesifik
        if scriptContent:find("^%s*<!DOCTYPE") or scriptContent:find("^%s*<html") then
             local preview = scriptContent:sub(1, 200)
             warn("⚠️ HTML Detected:\n" .. preview)
             error("HTML error page received (Invalid URL/Repo Private)")
        end

        -- Tetap cek apakah itu Lua (ada function/local/return)
        if not scriptContent:find("local") and not scriptContent:find("function") and not scriptContent:find("return") then
             -- Pengecekan tambahan: jika isinya sangat pendek mungkin json error
             if #scriptContent < 50 then
                 warn("⚠️ Content suspicious:\n" .. scriptContent)
             end
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
        warn("   Error:", result)
        return nil
    end
    
    return result
end

-- ============================================
-- UTILS & INIT
-- ============================================
function SecurityLoader.GetSessionInfo()
    return {Version = CONFIG.VERSION}
end

print("━━━━━━━━━━━━━━━━━━━━━━")
print("🔒 Jazzy Security Loader v" .. CONFIG.VERSION)
print("✅ Validation Logic Fixed (Coordinates Safe)")
print("━━━━━━━━━━━━━━━━━━━━━━")

return SecurityLoader
