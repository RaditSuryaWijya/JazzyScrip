local WebhookModule = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- [[ 1. HTTP REQUEST HELPER ]]
local function getHTTPRequest()
    local requestFunctions = {
        request, http_request, (syn and syn.request), (fluxus and fluxus.request),
        (http and http.request), (solara and solara.request),
        (game and game.HttpGet and function(opts)
            if opts.Method == "GET" then return {Body = game:HttpGet(opts.Url)} end
        end)
    }
    for _, func in ipairs(requestFunctions) do
        if func and type(func) == "function" then return func end
    end
    return nil
end
local httpRequest = getHTTPRequest()

WebhookModule.Config = {
    WebhookURL = "",
    DiscordUserID = "",
    DebugMode = false,
    EnabledRarities = {},
    UseSimpleMode = false
}

local ItemsModule, VariantsModule

-- Load Game Data Safely
pcall(function()
    ItemsModule = require(ReplicatedStorage:WaitForChild("Items", 10))
    VariantsModule = require(ReplicatedStorage:WaitForChild("Variants", 10))
end)

-- Constants
local TIER_NAMES = { [1]="Common", [2]="Uncommon", [3]="Rare", [4]="Epic", [5]="Legendary", [6]="Mythic", [7]="SECRET" }
local TIER_COLORS = { [1]=9807270, [2]=3066993, [3]=3447003, [4]=10181046, [5]=15844367, [6]=15548997, [7]=16711680, ["Shiny"]=16776960 }
local isRunning = false
local eventConnection = nil

-- [[ 3. HELPER FUNCTIONS ]]

local function getPlayerDisplayName()
    return LocalPlayer.DisplayName or LocalPlayer.Name
end

local function formatNumber(n)
    if not n then return "0" end
    n = tonumber(n)
    if not n then return "0" end
    local function clean(str) return str:gsub("%.?0+$", "") end
    if n >= 1000000000 then return clean(string.format("%.2fB", n/1000000000)) end
    if n >= 1000000 then return clean(string.format("%.2fM", n/1000000)) end
    if n >= 1000 then return clean(string.format("%.2fk", n/1000)) end
    return clean(string.format("%.2f", n))
end

-- Avatar Helper (Untuk Footer/Author Icon)
local function getPlayerAvatar()
    local userId = LocalPlayer.UserId
    local thumbAPI = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds="..userId.."&size=420x420&format=Png&isCircular=false"
    local avatarUrl = "https://i.imgur.com/4M7IwwP.png"
    
    if httpRequest then
        local success, response = pcall(function() return httpRequest({Url=thumbAPI, Method="GET"}) end)
        if success and response and response.Body then
            local data = HttpService:JSONDecode(response.Body)
            if data and data.data and data.data[1] then avatarUrl = data.data[1].imageUrl end
        end
    end
    return avatarUrl
end

-- Image Helper (Untuk Gambar Ikan)
local function getFishImage(itemId)
    if not ItemsModule then return "" end
    local itemData = ItemsModule[itemId]
    if not itemData then return "" end
    
    local iconId = itemData.Icon or itemData.Image or ""
    local assetId = tostring(iconId):match("%d+")
    
    if assetId then 
        return "https://tr.rbxcdn.com/180DAY-" .. assetId .. "/420/420/Image/Png" 
    end
    return "https://i.imgur.com/8yZqFqM.png"
end

-- [[ 4. SEND FUNCTION ]]
local function sendToDiscord(itemId, meta, extraData)
    if not httpRequest or WebhookModule.Config.WebhookURL == "" or not ItemsModule then return end

    local itemData = ItemsModule[itemId]
    if not itemData then return end

    -- Filter Logic
    local tier = itemData.Tier or 1
    local rarityName = TIER_NAMES[tier] or "Common"
    
    if #WebhookModule.Config.EnabledRarities > 0 then
        local allowed = false
        for _, r in ipairs(WebhookModule.Config.EnabledRarities) do
            if r == rarityName then allowed = true break end
        end
        if not allowed then return end
    end

    -- Data Calculation
    local weight = meta.Weight or 0
    local price = itemData.Price or 0
    local multiplier = 1
    local mutList = {}
    
    local isShiny = (meta.Shiny or (extraData and extraData.Shiny))
    if isShiny then 
        table.insert(mutList, "✨ Shiny") 
        multiplier = multiplier * 2 
    end
    
    if itemData.BigMin and weight >= itemData.BigMin then
        table.insert(mutList, "🦈 Big")
        multiplier = multiplier * 1.2
    end
    
    local variantId = meta.Variant or (extraData and extraData.Variant)
    if variantId and VariantsModule then
        local v = VariantsModule[variantId]
        if v then
            table.insert(mutList, "🧬 " .. v.Name)
            multiplier = multiplier * (v.PriceMultiplier or 1)
        end
    end
    
    local finalPrice = meta.Price or math.floor(price * multiplier * (1 + (weight/100)))
    local color = isShiny and TIER_COLORS["Shiny"] or TIER_COLORS[tier] or 16777215
    local mutationText = #mutList > 0 and table.concat(mutList, ", ") or "None"
    
    -- Format Strings
    local playerName = getPlayerDisplayName()
    local chanceText = (itemData.Chance and "1 in " .. formatNumber(itemData.Chance)) or "Unknown"
    local imageUrl = getFishImage(itemId)
    
    -- [[ BAGIAN CUSTOM: Definisi Variabel untuk Payload ]]
    
    -- 1. Pesan Utama (CongratsMsg)
    local congratsMsg = "**" .. itemData.Name .. "** dengan chance **" .. chanceText .. "** berhasil diamankan."
    
    -- 2. Mention
    local mention = ""
    if WebhookModule.Config.DiscordUserID ~= "" then
        mention = "<@" .. WebhookModule.Config.DiscordUserID .. "> "
    end
    
    -- 3. Fields (Detail)
    local fields = {
        { name = "Fish Name :", value = "> " .. itemData.Name, inline = false },
        { name = "Fish Tier :", value = "> " .. rarityName, inline = false },
        { name = "Weight :", value = string.format("> %.2f Kg", weight), inline = false },
        { name = "Mutation :", value = "> " .. mutationText, inline = false },
        { name = "Sell Price :", value = "> $" .. formatNumber(finalPrice), inline = false }
    }

    -- 4. Avatar
    local playerAvatarUrl = getPlayerAvatar()
    local playerProfileLink = "https://www.roblox.com/users/" .. LocalPlayer.UserId .. "/profile"

    -- [[ PAYLOAD (STRUKTUR YANG ANDA MINTA) ]]
    local payload = {
        ["username"] = "Fish Tracker V20.1", -- Nama Bot
        ["avatar_url"] = playerAvatarUrl,    -- Avatar Bot = Avatar Player
        ["content"] = mention,               -- Mention di luar embed agar bunyi
        
        embeds = {{
            author = {
                name = "🎣 Ikan Baru Ditangkap! di akun " .. playerName, -- Judul Custom
                icon_url = playerAvatarUrl, -- Icon kecil di sebelah judul
                url = playerProfileLink
            },
            description = congratsMsg, -- Pesan Custom
            color = color,
            fields = fields,
            image = {
                url = imageUrl -- Gambar Besar di Bawah
            },
            footer = {
                text = "Jazzyx Webhook • " .. os.date("%m/%d/%Y %H:%M"),
                icon_url = "https://i.imgur.com/shnNZuT.png"
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }
    
    pcall(function()
        httpRequest({
            Url = WebhookModule.Config.WebhookURL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(payload)
        })
    end)
end

-- [[ 5. MODULE INTERFACE ]]
function WebhookModule:SetWebhookURL(url) self.Config.WebhookURL = url end
function WebhookModule:SetDiscordUserID(id) self.Config.DiscordUserID = id end
function WebhookModule:SetDebugMode(enabled) self.Config.DebugMode = enabled end
function WebhookModule:SetEnabledRarities(rarities) self.Config.EnabledRarities = rarities end
function WebhookModule:SetSimpleMode(enabled) self.Config.UseSimpleMode = enabled end
function WebhookModule:GetTierNames() return TIER_NAMES end
function WebhookModule:GetConfig() return self.Config end
function WebhookModule:IsSupported() return httpRequest ~= nil end
function WebhookModule:IsRunning() return isRunning end

function WebhookModule:Start()
    if isRunning then return false end
    if not self.Config.WebhookURL or self.Config.WebhookURL == "" or not httpRequest then return false end
    if not ItemsModule then return false end -- Pastikan data game sudah load
    
    local success, Event = pcall(function()
        return ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/ObtainedNewFishNotification"]
    end)
    
    if not success or not Event then return false end
    
    eventConnection = Event.OnClientEvent:Connect(function(itemId, metadata, extraData)
        task.spawn(function() sendToDiscord(itemId, metadata, extraData) end)
    end)
    
    isRunning = true
    return true
end

function WebhookModule:Stop()
    if not isRunning then return false end
    if eventConnection then eventConnection:Disconnect() eventConnection = nil end
    isRunning = false
    return true
end

return WebhookModule
