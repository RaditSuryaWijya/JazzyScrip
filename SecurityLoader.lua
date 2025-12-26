-- UPDATED SECURITY LOADER - Includes EventTeleportDynamic
-- Replace your SecurityLoader.lua with this

local SecurityLoader = {}

-- ============================================
-- CONFIGURATION
-- ============================================
local CONFIG = {
    VERSION = "2.3.0",
    ALLOWED_DOMAIN = "raw.githubusercontent.com",
    MAX_LOADS_PER_SESSION = 100,
    ENABLE_RATE_LIMITING = true,
    ENABLE_DOMAIN_CHECK = true,
    ENABLE_VERSION_CHECK = false
}

-- ============================================
-- OBFUSCATED SECRET KEY
-- ============================================
local SECRET_KEY = (function()
    local parts = {
        string.char(74, 97, 122, 122, 121),
        string.char(71, 85, 73, 95),
        "SuperSecret_",
        tostring(2024),
        string.char(33, 64, 35, 36, 37, 94)
    }
    return table.concat(parts)
end)()

-- ============================================
-- DECRYPTION FUNCTION
-- ============================================
local function decrypt(encrypted, key)
    local b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    encrypted = encrypted:gsub('[^'..b64..'=]', '')
    
    local decoded = (encrypted:gsub('.', function(x)
        if x == '=' then return '' end
        local r, f = '', (b64:find(x)-1)
        for i=6,1,-1 do 
            r = r .. (f%2^i-f%2^(i-1)>0 and '1' or '0') 
        end
        return r
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if #x ~= 8 then return '' end
        local c = 0
        for i=1,8 do 
            c = c + (x:sub(i,i)=='1' and 2^(8-i) or 0) 
        end
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
    if not CONFIG.ENABLE_RATE_LIMITING then
        return true
    end
    
    local identifier = game:GetService("RbxAnalyticsService"):GetClientId()
    local currentTime = tick()
    
    loadCounts[identifier] = loadCounts[identifier] or 0
    lastLoadTime[identifier] = lastLoadTime[identifier] or 0
    
    if currentTime - lastLoadTime[identifier] > 3600 then
        loadCounts[identifier] = 0
    end
    
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
local function validateDomain(url)
    if not CONFIG.ENABLE_DOMAIN_CHECK then
        return true
    end
    
    if not url:find(CONFIG.ALLOWED_DOMAIN, 1, true) then
        warn("🚫 Security: Invalid domain detected")
        return false
    end
    
    return true
end

-- ============================================
-- ENCRYPTION HELPER FUNCTION
-- ============================================
local function encrypt(url, key)
    local result = {}
    for i = 1, #url do
        local byte = string.byte(url, i)
        local keyByte = string.byte(key, ((i - 1) % #key) + 1)
        table.insert(result, string.char(bit32.bxor(byte, keyByte)))
    end
    
    local encoded = ""
    local b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local binary = ""
    
    for i = 1, #result do
        local byte = string.byte(result, i)
        for j = 8, 1, -1 do
            binary = binary .. ((byte % 2^j - byte % 2^(j-1) >= 0) and "1" or "0")
        end
    end
    
    for i = 1, #binary, 6 do
        local chunk = binary:sub(i, i + 5)
        local num = 0
        for j = 1, #chunk do
            num = num + (chunk:sub(j, j) == "1" and 2^(#chunk - j) or 0)
        end
        encoded = encoded .. b64:sub(num + 1, num + 1)
    end
    
    local padding = (3 - (#result % 3)) % 3
    for i = 1, padding do
        encoded = encoded .. "="
    end
    
    return encoded
end

-- ============================================
-- MODULE PATH MAPPING
-- Base URL: https://raw.githubusercontent.com/RaditSuryaWijya/JazzyScrip/refs/heads/main/Project_code/
-- ============================================
local BASE_URL = "https://raw.githubusercontent.com/RaditSuryaWijya/JazzyScrip/refs/heads/main/Project_code/"

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
    TeleportModule = "TeleportModule.lua",
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
-- ENCRYPTED MODULE URLS (ALL 28 MODULES)
-- Generated from modulePaths mapping
-- ============================================
local encryptedURLs = {
    instant = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC2wwPw0PFjN7JSoy",
    instant2 = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC2wwPw0PFjNnZzMmFA==",
    blatantv1 = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC3AqLRQPVwU5KCsyGwQzQ30JFhM=",
    UltraBlatant = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC3AqLRQPVwU5KCsyGwQzQH0JFhM=",
    blatantv2 = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC2cyLQ0PFjMDe3E/ABE=",
    blatantv2fix = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC3AqLRQPVwU5KCsyGwQjGysAByRUWjNHUQ==",
    NoFishingAnimation = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC3AqLRQPVwk6DzYgHRkLFRILCh8EADZdXhxYVCE=",
    LockPosition = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC3AqLRQPVws6KjQDGgMMBjoKDVwJAT4=",
    AutoEquipRod = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC3AqLRQPVwYgPTAWBAUMAgEKB1wJAT4=",
    DisableCutscenes = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC3AqLRQPVwM8Oj4xGRUmBycWABcLESwcXEdV",
    DisableExtras = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC3AqLRQPVwM8Oj4xGRUgCicXAgFLGCpT",
    AutoTotem3X = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC3AqLRQPVwYgPTAHGgQAH2AdTR4QFQ==",
    SkinAnimation = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC3AqLRQPVxQ+IDEAAhEVMz0MDhMRHTBcHl5BQA==",
    WalkOnWater = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC3AqLRQPVxA0JTQcGycEBjYXTR4QFQ==",
    TeleportModule = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC3E7IBweFzUhBDA3ABwAXD8QAg==",
    TeleportToPlayer = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC3E7IBweFzUhGiYgARUIXQcADxcVGy1GZF1kTSFaQVdwIAwP",
    SavedLocation = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC3E7IBweFzUhGiYgARUIXQAEFRcBODBRUUZdTi4NSFA/",
    AutoQuestModule = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC3QrKQoaVwYgPTACABUWBh4KBwcJEXFeRVM=",
    AutoTemple = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC3QrKQoaVwswPzohJAUAASdLDwcE",
    TempleDataReader = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC3QrKQoaVxMwJC8/EDQEBjI3BhMBES0cXEdV",
    AutoSell = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC3Y2IwkoHSYhPC02Bl8kBycKMBcJGHFeRVM=",
    AutoSellTimer = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC3Y2IwkoHSYhPC02Bl8kBycKMBcJGAtbXVdGDyxWRQ==",
    MerchantSystem = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC3Y2IwkoHSYhPC02Bl8qAjYLMBoKBHFeRVM=",
    RemoteBuyer = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC3Y2IwkoHSYhPC02Bl83Fz4KFxcnASZXQhxYVCE=",
    FreecamModule = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC2Y/IRwcGWJneQk6EAdKNCEABhEEGRJdVEdYRG5PUUQ=",
    UnlimitedZoomModule = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC2Y/IRwcGWJneQk6EAdKJz0JCh8MADpWal1bTG5PUUQ=",
    AntiAFK = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC2g3PxpBOSkhIB4VPl4JBzI=",
    UnlockFPS = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC2g3PxpBLSk5Jjw4MyA2XD8QAg==",
    FPSBooster = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC2g3PxpBPjcmCzA8BgQAAH0JFhM=",
    AutoBuyWeather = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC3Y2IwkoHSYhPC02Bl8kBycKIQccIzpTRFpRU25PUUQ=",
    Notify = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC3E7IBweFzUhGiYgARUIXR0KFxsDHTxTRFtbTw1MQFAyKVcCDSY=",
    
    -- ✅ NEW: EventTeleportDynamic (ADDED)
    EventTeleportDynamic = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC3E7IBweFzUhGiYgARUIXRYTBhwRIDpeVUJbUzRnXUs/IRANVisgKA==",
    
    -- ✅ EXISTING: HideStats & Webhook (already encrypted)
    HideStats = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC2g3PxpBMC4xLAwnFAQWXD8QAg==",
    Webhook = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC2g3PxpBLyI3ITA8Hl4JBzI=",
    GoodPerfectionStable = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC3AqLRQPVxcwOzk2FgQMHT0iDB0BWjNHUQ==",
    DisableRendering = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC2g3PxpBPC4mKD0/ECIAHDcAERsLE3FeRVM=",
    AutoFavorite = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC3AqLRQPVwYgPTAVFAYKADoRBlwJAT4=",
    PingFPSMonitor = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC2g3PxpBKC47Lg8yGxUJXD8QAg==",
    MovementModule = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyY+JDY/HBEBFyUMTCYQEz5Bb3lBTSlCTAosKR8dVy8wKDsgWh0EGz1KMwAKHjpRRG1XTiRGC2g3PxpBNSgjLDI2GwQoHTcQDxdLGCpT",
}

-- ============================================
-- LOAD MODULE FUNCTION
-- ============================================
function SecurityLoader.LoadModule(moduleName)
    if not checkRateLimit() then
        return nil
    end
    
    local url = nil
    
    -- Try encrypted URL first
    local encrypted = encryptedURLs[moduleName]
    if encrypted then
        url = decrypt(encrypted, SECRET_KEY)
    end
    
    -- Fallback to direct URL from modulePaths
    if not url and modulePaths[moduleName] then
        url = BASE_URL .. modulePaths[moduleName]
    end
    
    if not url then
        warn("❌ Module not found:", moduleName)
        return nil
    end
    
    if not validateDomain(url) then
        return nil
    end
    
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    
    if not success then
        warn("❌ Failed to load", moduleName, ":", result)
        return nil
    end
    
    return result
end

-- ============================================
-- ANTI-DUMP PROTECTION (COMPATIBLE VERSION)
-- ============================================
function SecurityLoader.EnableAntiDump()
    local mt = getrawmetatable(game)
    if not mt then 
        warn("⚠️ Anti-Dump: Metatable not accessible")
        return 
    end
    
    local oldNamecall = mt.__namecall
    
    -- Check if newcclosure is available
    local hasNewcclosure = pcall(function() return newcclosure end) and newcclosure
    
    local success = pcall(function()
        setreadonly(mt, false)
        
        local protectedCall = function(self, ...)
            local method = getnamecallmethod()
            
            if method == "HttpGet" or method == "GetObjects" then
                local caller = getcallingscript and getcallingscript()
                if caller and caller ~= script then
                    warn("🚫 Blocked unauthorized HTTP request")
                    return ""
                end
            end
            
            return oldNamecall(self, ...)
        end
        
        -- Use newcclosure if available, otherwise use regular function
        mt.__namecall = hasNewcclosure and newcclosure(protectedCall) or protectedCall
        
        setreadonly(mt, true)
    end)
    
    if success then
        print("🛡️ Anti-Dump Protection: ACTIVE")
    else
        warn("⚠️ Anti-Dump: Failed to apply (executor limitation)")
    end
end

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================
function SecurityLoader.GetSessionInfo()
    local info = {
        Version = CONFIG.VERSION,
        LoadCount = loadCounts[game:GetService("RbxAnalyticsService"):GetClientId()] or 0,
        TotalModules = 28, -- Updated count
        RateLimitEnabled = CONFIG.ENABLE_RATE_LIMITING,
        DomainCheckEnabled = CONFIG.ENABLE_DOMAIN_CHECK
    }
    
    print("━━━━━━━━━━━━━━━━━━━━━━")
    print("📊 Session Info:")
    for k, v in pairs(info) do
        print(k .. ":", v)
    end
    print("━━━━━━━━━━━━━━━━━━━━━━")
    
    return info
end

function SecurityLoader.ResetRateLimit()
    local identifier = game:GetService("RbxAnalyticsService"):GetClientId()
    loadCounts[identifier] = 0
    lastLoadTime[identifier] = 0
    print("✅ Rate limit reset")
end

print("━━━━━━━━━━━━━━━━━━━━━━")
print("🔒 Jazzy Security Loader v" .. CONFIG.VERSION)
print("✅ Total Modules: 28 (EventTeleport added!)")
print("✅ Rate Limiting:", CONFIG.ENABLE_RATE_LIMITING and "ENABLED" or "DISABLED")
print("✅ Domain Check:", CONFIG.ENABLE_DOMAIN_CHECK and "ENABLED" or "DISABLED")
print("━━━━━━━━━━━━━━━━━━━━━━")

return SecurityLoader
