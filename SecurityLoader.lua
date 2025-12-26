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
    ENABLE_DOMAIN_CHECK = false,  -- DISABLED: Domain validation bypassed
    ENABLE_VERSION_CHECK = false,
    USE_DIRECT_URLS = true  -- Skip encrypted URLs, use direct URLs from modulePaths
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
-- DOMAIN VALIDATION (BYPASSED)
-- ============================================
local function validateDomain(url)
    -- Domain validation disabled - always return true
    if not CONFIG.ENABLE_DOMAIN_CHECK then
        return true
    end
    
    -- Skip validation for BASE_URL
    if url and url:find(BASE_URL, 1, true) then
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
-- MODULE URLS (DIRECT URLs - NO ENCRYPTION)
-- Base URL: https://raw.githubusercontent.com/RaditSuryaWijya/JazzyScrip/refs/heads/main/Project_code/
-- ============================================
local encryptedURLs = {
    instant = BASE_URL .. "Instant.lua",
    instant2 = BASE_URL .. "Instant2.lua",
    blatantv1 = BASE_URL .. "Utama/BlatantV1.lua",
    UltraBlatant = BASE_URL .. "Utama/BlatantV2.lua",
    blatantv2 = BASE_URL .. "BlatantV2.lua",
    blatantv2fix = BASE_URL .. "Utama/BlatantFixedV1.lua",
    NoFishingAnimation = BASE_URL .. "Utama/NoFishingAnimation.lua",
    LockPosition = BASE_URL .. "Utama/LockPosition.lua",
    AutoEquipRod = BASE_URL .. "Utama/AutoEquipRod.lua",
    DisableCutscenes = BASE_URL .. "Utama/DisableCutscenes.lua",
    DisableExtras = BASE_URL .. "Utama/DisableExtras.lua",
    AutoTotem3X = BASE_URL .. "Utama/AutoTotem3x.lua",
    SkinAnimation = BASE_URL .. "Utama/SkinSwapAnimation.lua",
    WalkOnWater = BASE_URL .. "Utama/WalkOnWater.lua",
    TeleportModule = BASE_URL .. "TeleportModule.lua",
    TeleportToPlayer = BASE_URL .. "TeleportSystem/TeleportToPlayer.lua",
    SavedLocation = BASE_URL .. "TeleportSystem/SavedLocation.lua",
    AutoQuestModule = BASE_URL .. "Quest/AutoQuestModule.lua",
    AutoTemple = BASE_URL .. "Quest/LeverQuest.lua",
    TempleDataReader = BASE_URL .. "Quest/TempleDataReader.lua",
    AutoSell = BASE_URL .. "ShopFeatures/AutoSell.lua",
    AutoSellTimer = BASE_URL .. "ShopFeatures/AutoSellTimer.lua",
    MerchantSystem = BASE_URL .. "ShopFeatures/OpenShop.lua",
    RemoteBuyer = BASE_URL .. "ShopFeatures/RemoteBuyer.lua",
    FreecamModule = BASE_URL .. "Camera View/FreecamModule.lua",
    UnlimitedZoomModule = BASE_URL .. "Camera View/UnlimitedZoom.lua",
    AntiAFK = BASE_URL .. "Misc/AntiAFK.lua",
    UnlockFPS = BASE_URL .. "Misc/UnlockFPS.lua",
    FPSBooster = BASE_URL .. "Misc/FpsBooster.lua",
    AutoBuyWeather = BASE_URL .. "ShopFeatures/AutoBuyWeather.lua",
    Notify = BASE_URL .. "Notification.lua",
    EventTeleportDynamic = BASE_URL .. "TeleportSystem/EventTeleportDynamic.lua",
    HideStats = BASE_URL .. "Misc/HideStats.lua",
    Webhook = BASE_URL .. "Misc/Webhook.lua",
    GoodPerfectionStable = BASE_URL .. "Utama/PerfectionGood.lua",
    DisableRendering = BASE_URL .. "Misc/DisableRendering.lua",
    AutoFavorite = BASE_URL .. "Utama/AutoFavorite.lua",
    PingFPSMonitor = BASE_URL .. "Misc/PingPanel.lua",
    MovementModule = BASE_URL .. "Misc/MovementModule.lua",
}

-- ============================================
-- LOAD MODULE FUNCTION
-- ============================================
function SecurityLoader.LoadModule(moduleName)
    if not checkRateLimit() then
        return nil
    end
    
    local url = nil
    
        -- Get URL from encryptedURLs (now contains direct URLs)
    local encrypted = encryptedURLs[moduleName]
    if encrypted then
        -- Check if it's a direct URL (starts with http) or encrypted string
        if encrypted:sub(1, 4) == "http" then
            -- Direct URL - use as is
            url = encrypted
        else
            -- Encrypted string - decrypt it
            local decrypted = decrypt(encrypted, SECRET_KEY)
            if decrypted and validateDomain(decrypted) then
                url = decrypted
            end
        end
    end
    
    -- Fallback to direct URL from modulePaths (always valid)
    if not url and modulePaths[moduleName] then
        url = BASE_URL .. modulePaths[moduleName]
    end
    
    if not url then
        warn("❌ Module not found:", moduleName)
        warn("   Available modules:", table.concat(modulePaths and {} or {}, ", "))
        return nil
    end
    
    -- Debug: Show URL being used (only for first few modules to avoid spam)
    if moduleName == "Notify" or moduleName == "HideStats" or moduleName == "Webhook" then
        print("🔍 Loading", moduleName, "from:", url)
    end
    
    -- Final validation (bypassed if ENABLE_DOMAIN_CHECK = false)
    if not validateDomain(url) then
        warn("🚫 Security: Invalid domain for module:", moduleName)
        warn("   URL:", url)
        warn("   Expected domain:", CONFIG.ALLOWED_DOMAIN)
        -- Continue anyway if domain check is disabled
        if not CONFIG.ENABLE_DOMAIN_CHECK then
            warn("   ⚠️ Domain check disabled - continuing anyway")
        else
        return nil
        end
    end
    
    -- Load module with better error handling
    local success, result = pcall(function()
        -- Get the script content
        local scriptContent = nil
        local httpSuccess, httpResult = pcall(function()
            -- Try sync first (most executors)
            scriptContent = game:HttpGet(url)
            return scriptContent
        end)
        
        if not httpSuccess or not scriptContent or scriptContent == "" then
            -- Try async if sync failed
            local asyncSuccess, asyncResult = pcall(function()
                return game:HttpGet(url, true)
            end)
            if asyncSuccess and asyncResult then
                scriptContent = asyncResult
            else
                error("HTTP request failed: " .. tostring(httpResult or asyncResult or "Unknown error"))
            end
        end
        
        if not scriptContent or scriptContent == "" then
            error("Empty script content from URL: " .. url)
        end
        
        -- Debug: Check what we actually got (for all modules to diagnose)
        print("📄 Module:", moduleName)
        print("📄 URL:", url)
        print("📄 Content length:", #scriptContent, "chars")
        
        -- Check if it's HTML error page (404, etc)
        if scriptContent:find("<!DOCTYPE") or scriptContent:find("<html") or scriptContent:find("404") or scriptContent:find("Not Found") or scriptContent:find("Page not found") then
            local preview = scriptContent:sub(1, 500)
            warn("⚠️ Received HTML error page instead of Lua code!")
            warn("   Preview:", preview)
            error("HTML error page received - file might not exist at: " .. url .. "\n   Make sure file is uploaded to GitHub repository!")
        end
        
        -- Check if content looks like Lua code
        if not scriptContent:find("local") and not scriptContent:find("function") and not scriptContent:find("return") then
            warn("⚠️ Content doesn't look like Lua code for:", moduleName)
            warn("   First 200 chars:", scriptContent:sub(1, 200))
            warn("   ⚠️ File might be empty or corrupted!")
        end
        
        -- Show first/last chars for debugging
        if moduleName == "Notify" or moduleName == "Webhook" or moduleName == "HideStats" then
            print("📄 First 200 chars:", scriptContent:sub(1, 200):gsub("\n", "\\n"):gsub("\r", "\\r"))
            print("📄 Last 100 chars:", scriptContent:sub(-100):gsub("\n", "\\n"):gsub("\r", "\\r"))
        end
        
        -- Clean script content (remove BOM, trim whitespace, remove null bytes)
        -- Remove UTF-8 BOM if present
        if scriptContent:sub(1, 3) == string.char(239, 187, 191) then
            scriptContent = scriptContent:sub(4)
        end
        -- Remove null bytes (sometimes appear in corrupted downloads)
        scriptContent = scriptContent:gsub("%z", "")
        -- Remove leading/trailing whitespace (but keep content)
        scriptContent = scriptContent:gsub("^%s+", ""):gsub("%s+$", "")
        
        -- Validate content is not empty after cleaning
        if not scriptContent or scriptContent == "" then
            error("Script content is empty after cleaning for: " .. moduleName)
        end
        
        -- Load and execute the script
        -- Try different loadstring methods for compatibility
        local loadedScript, loadError = nil, nil
        
        -- Method 1: Standard loadstring
        loadedScript, loadError = loadstring(scriptContent)
        
        -- Method 2: loadstring with chunkname (some executors)
        if not loadedScript then
            loadedScript, loadError = loadstring(scriptContent, moduleName)
        end
        
        -- Method 3: Try load() if available
        if not loadedScript and load then
            local success, result = pcall(function()
                return load(scriptContent)
            end)
            if success and result then
                loadedScript = result
            end
        end
        
        if not loadedScript then
            local errorMsg = "❌ loadstring returned nil for: " .. moduleName
            errorMsg = errorMsg .. "\n   URL: " .. url
            errorMsg = errorMsg .. "\n   Content length: " .. tostring(#scriptContent) .. " chars"
            
            if loadError then
                errorMsg = errorMsg .. "\n   Syntax error: " .. tostring(loadError)
            end
            
            -- Show content preview
            if #scriptContent > 0 then
                local preview = scriptContent:sub(1, 300):gsub("\n", "\\n"):gsub("\r", "\\r")
                errorMsg = errorMsg .. "\n   First 300 chars: " .. preview
            else
                errorMsg = errorMsg .. "\n   ⚠️ Content is EMPTY - file might not exist on GitHub!"
            end
            
            -- Check for common issues
            if scriptContent:find("<!DOCTYPE") or scriptContent:find("<html") or scriptContent:find("404") then
                errorMsg = errorMsg .. "\n   ⚠️ Received HTML error page (404 Not Found?)"
                errorMsg = errorMsg .. "\n   💡 Pastikan file sudah di-upload ke GitHub repository!"
                errorMsg = errorMsg .. "\n   💡 Cek URL di browser: " .. url
            elseif not scriptContent:find("local") and not scriptContent:find("function") then
                errorMsg = errorMsg .. "\n   ⚠️ Content doesn't look like Lua code!"
                errorMsg = errorMsg .. "\n   💡 File mungkin kosong atau corrupt!"
            end
            
            error(errorMsg)
        end
        
        -- Execute the script
        local execResult = loadedScript()
        
        if execResult == nil then
            warn("⚠️ Module", moduleName, "executed but returned nil")
            warn("   This might be OK if module uses global variables")
            -- Return empty table as fallback
            return {}
        end
        
        -- Verify result is valid
        if type(execResult) ~= "table" and type(execResult) ~= "function" then
            warn("⚠️ Module", moduleName, "returned unexpected type:", type(execResult))
            -- Wrap in table if needed
            if type(execResult) == "nil" then
                return {}
            end
        end
        
        return execResult
    end)
    
    if not success then
        warn("❌ Failed to load", moduleName)
        warn("   URL:", url)
        warn("   Error:", result)
        return nil
    end
    
    if not result then
        warn("⚠️ Module", moduleName, "loaded but returned nil")
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
print("⚠️ Domain Check:", CONFIG.ENABLE_DOMAIN_CHECK and "ENABLED" or "DISABLED (BYPASSED)")
print("✅ Direct URLs:", CONFIG.USE_DIRECT_URLS and "ENABLED" or "DISABLED")
print("━━━━━━━━━━━━━━━━━━━━━━")

return SecurityLoader
