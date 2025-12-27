local WebhookModule = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Configuration Storage
WebhookModule.Config = {
    WebhookURL = "",
    DiscordUserID = "",
    EnabledRarities = {},
    DebugMode = false
}

-- Game Data
local ItemsModule = require(ReplicatedStorage:WaitForChild("Items"))
local VariantsModule = require(ReplicatedStorage:WaitForChild("Variants"))

-- Internal State
local isRunning = false
local eventConnection = nil

-- ============================================
-- 🛠️ HELPER FUNCTIONS
-- ============================================

-- 1. HTTP Request Handler (Universal)
local function getHTTPRequest()
    return (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
end
local httpRequest = getHTTPRequest()

-- 2. Format Number (1000 -> 1k, 1000000 -> 1M) - Seperti Referensi
local function formatNumber(n)
    if not n then return "0" end
    n = tonumber(n)
    if not n then return "0" end
    
    if n >= 1000000000 then return string.format("%.2fB", n / 1000000000) end
    if n >= 1000000 then return string.format("%.2fM", n / 1000000) end
    if n >= 1000 then return string.format("%.2fk", n / 1000) end
    
    return tostring(n)
end

-- 3. Get Player Avatar (Headshot) - Seperti Referensi
local function getPlayerAvatar()
    local userId = LocalPlayer.UserId
    local thumbAPI = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds="..userId.."&size=420x420&format=Png&isCircular=false"
    
    -- Default fallback
    local avatarUrl = "https://www.roblox.com/headshot-thumbnail/image?userId="..userId.."&width=420&height=420&format=png"
    
    if httpRequest then
        local success, response = pcall(function()
            return game:HttpGet(thumbAPI)
        end)
        if success then
            local data = HttpService:JSONDecode(response)
            if data and data.data and data.data[1] then
                avatarUrl = data.data[1].imageUrl
            end
        end
    end
    return avatarUrl
end

-- 4. Get Fish Image (Thumbnail)
local function getFishImage(itemId)
    local itemData = ItemsModule[itemId]
    if not itemData then return "" end
    
    local iconId = itemData.Icon or itemData.Image or ""
    -- Extract number from "rbxassetid://12345"
    local assetId = tostring(iconId):match("%d+")
    
    if assetId then
        -- Coba ambil link CDN asli agar muncul di Discord
        return string.format("https://tr.rbxcdn.com/180DAY-%s/420/420/Image/Png", assetId)
    end
    return ""
end

-- 5. Tier Colors (Decimal Colors for Discord)
local TIER_COLORS = {
    [1] = 9807270,   -- Common (Gray)
    [2] = 3066993,   -- Uncommon (Green)
    [3] = 3447003,   -- Rare (Blue)
    [4] = 10181046,  -- Epic (Purple)
    [5] = 15844367,  -- Legendary (Orange)
    [6] = 15548997,  -- Mythic (Red)
    [7] = 16711680,  -- SECRET (Deep Red/Special)
    ["Shiny"] = 16776960 -- Gold
}

-- ============================================
-- 📨 SEND LOGIC
-- ============================================

local function sendToDiscord(itemId, meta, extraData)
    if WebhookModule.Config.WebhookURL == "" or not httpRequest then return end

    -- 1. Ambil Data Ikan dari Module Game
    local itemData = ItemsModule[itemId]
    if not itemData then return end

    -- 2. Filter Rarity
    local tier = itemData.Tier or 1
    local rarityName = "Common" -- Default
    
    -- Cari nama rarity (Manual mapping karena di module mungkin angka)
    local rarityMap = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "SECRET"}
    if rarityMap[tier] then rarityName = rarityMap[tier] end

    -- Cek Config Filter
    local isAllowed = false
    if #WebhookModule.Config.EnabledRarities > 0 then
        for _, allowed in ipairs(WebhookModule.Config.EnabledRarities) do
            if allowed == rarityName then isAllowed = true break end
        end
    else
        isAllowed = true -- Jika tidak ada filter, kirim semua
    end
    
    if not isAllowed then return end

    -- 3. Data Detail (Berat, Harga, Mutasi)
    local weight = meta.Weight or 0
    local price = itemData.Price or 0
    local multiplier = 1
    local mutations = {}
    
    -- Cek Shiny
    local isShiny = (meta.Shiny or (extraData and extraData.Shiny))
    if isShiny then 
        table.insert(mutations, "✨ Shiny") 
        multiplier = multiplier * 2 
    end
    
    -- Cek Big
    if itemData.BigMin and weight >= itemData.BigMin then
        table.insert(mutations, "🦈 Big")
        multiplier = multiplier * 1.2
    end
    
    -- Cek Mutation Lain (Varian)
    local variantId = meta.Variant or (extraData and extraData.Variant)
    if variantId then
        local variantData = VariantsModule[variantId]
        if variantData then
            table.insert(mutations, "🧬 " .. variantData.Name)
            multiplier = multiplier * (variantData.PriceMultiplier or 1)
        end
    end
    
    -- Hitung Harga Akhir
    local finalPrice = math.floor(price * multiplier * (1 + (weight/100))) -- Rumus estimasi
    if meta.Price then finalPrice = meta.Price end -- Gunakan harga server jika ada

    -- 4. Construct Payload (Tampilan Discord)
    local color = TIER_COLORS[tier] or 16777215
    if isShiny then color = TIER_COLORS["Shiny"] end -- Prioritas warna Gold jika Shiny

    local mutationText = #mutations > 0 and table.concat(mutations, ", ") or "None"
    local playerLink = "https://www.roblox.com/users/" .. LocalPlayer.UserId .. "/profile"

    local embed = {
        ["title"] = "🎣 Ikan Baru Ditangkap!",
        ["description"] = string.format("Player **[%s](%s)** berhasil menangkap ikan baru!", LocalPlayer.DisplayName, playerLink),
        ["color"] = color,
        ["thumbnail"] = {
            ["url"] = getFishImage(itemId)
        },
        ["fields"] = {
            {
                ["name"] = "🐟 Fish Name",
                ["value"] = "**" .. itemData.Name .. "**",
                ["inline"] = true
            },
            {
                ["name"] = "💎 Rarity",
                ["value"] = "**" .. rarityName .. "**",
                ["inline"] = true
            },
            {
                ["name"] = "⚖️ Weight",
                ["value"] = "`" .. formatNumber(weight) .. " kg`",
                ["inline"] = true
            },
            {
                ["name"] = "💰 Value",
                ["value"] = "`$" .. formatNumber(finalPrice) .. "`",
                ["inline"] = true
            },
            {
                ["name"] = "🧬 Mutation",
                ["value"] = mutationText,
                ["inline"] = false
            }
        },
        ["footer"] = {
            ["text"] = "Jazzy Hook System • " .. os.date("%H:%M:%S"),
            ["icon_url"] = "https://i.imgur.com/4M7IwwP.png" -- Icon Footer (bisa diganti)
        },
        ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }

    -- Tambahan Mention Discord ID
    local contentMsg = ""
    if WebhookModule.Config.DiscordUserID ~= "" then
        contentMsg = "<@" .. WebhookModule.Config.DiscordUserID .. ">"
    end

    local payload = {
        ["username"] = "Jazzy Fish Notifier", -- Nama Bot
        ["avatar_url"] = getPlayerAvatar(),   -- Foto Profil Bot (Avatar Player)
        ["content"] = contentMsg,
        ["embeds"] = {embed}
    }

    -- 5. Kirim Request
    httpRequest({
        Url = WebhookModule.Config.WebhookURL,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode(payload)
    })
end

-- ============================================
-- 🕹️ MODULE FUNCTIONS
-- ============================================

function WebhookModule:SetWebhookURL(url)
    self.Config.WebhookURL = url
end

function WebhookModule:SetDiscordUserID(id)
    self.Config.DiscordUserID = id
end

function WebhookModule:SetEnabledRarities(rarities)
    self.Config.EnabledRarities = rarities
end

function WebhookModule:IsSupported()
    return httpRequest ~= nil
end

function WebhookModule:Start()
    if isRunning then return end
    if not self.Config.WebhookURL or self.Config.WebhookURL == "" then return end
    
    -- Connect ke Remote Event Asli Game
    -- Logika asli Anda tetap dipertahankan di sini:
    local net = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")
    local notificationEvent = net:WaitForChild("RE/ObtainedNewFishNotification")
    
    if notificationEvent then
        isRunning = true
        eventConnection = notificationEvent.OnClientEvent:Connect(function(itemId, meta, extra)
            -- Jalankan di thread terpisah agar tidak mengganggu main thread
            task.spawn(function()
                sendToDiscord(itemId, meta, extra)
            end)
        end)
        print("✅ Webhook Started (Refined Style)")
    end
    return isRunning
end

function WebhookModule:Stop()
    isRunning = false
    if eventConnection then
        eventConnection:Disconnect()
        eventConnection = nil
    end
end

-- Compatibility functions (agar tidak error dipanggil UI lama)
function WebhookModule:SetDebugMode() end
function WebhookModule:SetSimpleMode() end

return WebhookModule
