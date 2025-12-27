-- [[ WEBHOOK MODULE - FIXED & STABLE ]]
local WebhookModule = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- Configuration Storage
WebhookModule.Config = {
    WebhookURL = "",
    DiscordUserID = "",
    EnabledRarities = {},
    DebugMode = false
}

-- Game Data
-- Gunakan pcall saat require modul game untuk mencegah crash jika path berubah
local ItemsModule = nil
local VariantsModule = nil

pcall(function()
    ItemsModule = require(ReplicatedStorage:WaitForChild("Items", 10))
    VariantsModule = require(ReplicatedStorage:WaitForChild("Variants", 10))
end)

-- Internal State
local isRunning = false
local eventConnection = nil

-- ============================================
-- 🛠️ HELPER FUNCTIONS
-- ============================================

local function getHTTPRequest()
    return (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
end
local httpRequest = getHTTPRequest()

local function formatNumber(n)
    if not n then return "0" end
    n = tonumber(n)
    if not n then return "0" end
    if n >= 1000000000 then return string.format("%.2fB", n / 1000000000) end
    if n >= 1000000 then return string.format("%.2fM", n / 1000000) end
    if n >= 1000 then return string.format("%.2fk", n / 1000) end
    return tostring(n)
end

-- Safe Avatar Grabber
local function getPlayerAvatar()
    local userId = LocalPlayer.UserId
    local thumbAPI = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds="..userId.."&size=420x420&format=Png&isCircular=false"
    local avatarUrl = "https://www.roblox.com/headshot-thumbnail/image?userId="..userId.."&width=420&height=420&format=png"
    
    if httpRequest then
        pcall(function()
            local response = game:HttpGet(thumbAPI)
            local data = HttpService:JSONDecode(response)
            if data and data.data and data.data[1] then
                avatarUrl = data.data[1].imageUrl
            end
        end)
    end
    return avatarUrl
end

-- Safe Image Grabber
local function getFishImage(itemId)
    if not ItemsModule then return "" end
    local itemData = ItemsModule[itemId]
    if not itemData then return "" end
    
    local iconId = itemData.Icon or itemData.Image or ""
    local assetId = tostring(iconId):match("%d+")
    
    if assetId then
        return string.format("https://tr.rbxcdn.com/180DAY-%s/420/420/Image/Png", assetId)
    end
    return ""
end

local TIER_COLORS = {
    [1] = 9807270, [2] = 3066993, [3] = 3447003, [4] = 10181046,
    [5] = 15844367, [6] = 15548997, [7] = 16711680, ["Shiny"] = 16776960
}

local RARITY_MAP = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "SECRET"}

-- ============================================
-- 📨 SEND LOGIC
-- ============================================

local function sendToDiscord(itemId, meta, extraData)
    if not httpRequest or WebhookModule.Config.WebhookURL == "" then return end
    if not ItemsModule then return end -- Game modules not loaded

    local itemData = ItemsModule[itemId]
    if not itemData then return end

    -- Filter Logic
    local tier = itemData.Tier or 1
    local rarityName = RARITY_MAP[tier] or "Common"
    
    local isAllowed = (#WebhookModule.Config.EnabledRarities == 0)
    for _, allowed in ipairs(WebhookModule.Config.EnabledRarities) do
        if allowed == rarityName then isAllowed = true break end
    end
    
    if not isAllowed then return end

    -- Data Logic
    local weight = meta.Weight or 0
    local price = itemData.Price or 0
    local multiplier = 1
    local mutations = {}
    
    local isShiny = (meta.Shiny or (extraData and extraData.Shiny))
    if isShiny then 
        table.insert(mutations, "✨ Shiny") 
        multiplier = multiplier * 2 
    end
    
    if itemData.BigMin and weight >= itemData.BigMin then
        table.insert(mutations, "🦈 Big")
        multiplier = multiplier * 1.2
    end
    
    -- Variant Logic
    local variantId = meta.Variant or (extraData and extraData.Variant)
    if variantId and VariantsModule then
        local variantData = VariantsModule[variantId]
        if variantData then
            table.insert(mutations, "🧬 " .. variantData.Name)
            multiplier = multiplier * (variantData.PriceMultiplier or 1)
        end
    end
    
    local finalPrice = meta.Price or math.floor(price * multiplier * (1 + (weight/100)))

    -- Payload Construction
    local color = isShiny and TIER_COLORS["Shiny"] or TIER_COLORS[tier] or 16777215
    local mutationText = #mutations > 0 and table.concat(mutations, ", ") or "None"
    
    -- [[ FIX: CONTENT MESSAGE ]]
    local contentMsg = ""
    if WebhookModule.Config.DiscordUserID ~= "" then
        contentMsg = "<@" .. WebhookModule.Config.DiscordUserID .. ">"
    end

    local payload = {
        username = "Jazzy Fish Notifier",
        avatar_url = getPlayerAvatar(),
        content = contentMsg, -- Content moved here (outside embed)
        embeds = {{
            title = "🎣 Ikan Baru Ditangkap!",
            description = "Player **" .. LocalPlayer.DisplayName .. "** berhasil menangkap ikan baru!",
            color = color,
            thumbnail = { url = getFishImage(itemId) },
            fields = {
                { name = "🐟 Fish Name", value = "**" .. itemData.Name .. "**", inline = true },
                { name = "💎 Rarity", value = "**" .. rarityName .. "**", inline = true },
                { name = "⚖️ Weight", value = "`" .. formatNumber(weight) .. " kg`", inline = true },
                { name = "💰 Value", value = "`$" .. formatNumber(finalPrice) .. "`", inline = true },
                { name = "🧬 Mutation", value = mutationText, inline = false }
            },
            footer = {
                text = "Jazzy Hook System • " .. os.date("%H:%M:%S")
                -- Removed Icon URL to prevent error if link broken
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }

    -- Sending
    pcall(function()
        httpRequest({
            Url = WebhookModule.Config.WebhookURL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(payload)
        })
    end)
end

-- ============================================
-- 🕹️ MODULE FUNCTIONS
-- ============================================

function WebhookModule:SetWebhookURL(url) self.Config.WebhookURL = url end
function WebhookModule:SetDiscordUserID(id) self.Config.DiscordUserID = id end
function WebhookModule:SetEnabledRarities(rarities) self.Config.EnabledRarities = rarities end
function WebhookModule:IsSupported() return httpRequest ~= nil end
function WebhookModule:SetDebugMode() end -- Compatibility
function WebhookModule:SetSimpleMode() end -- Compatibility

function WebhookModule:Start()
    if isRunning then return end
    if not httpRequest or self.Config.WebhookURL == "" then return end
    
    local net = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")
    local notificationEvent = net:WaitForChild("RE/ObtainedNewFishNotification")
    
    if notificationEvent then
        isRunning = true
        eventConnection = notificationEvent.OnClientEvent:Connect(function(itemId, meta, extra)
            task.spawn(function() sendToDiscord(itemId, meta, extra) end)
        end)
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

return WebhookModule
