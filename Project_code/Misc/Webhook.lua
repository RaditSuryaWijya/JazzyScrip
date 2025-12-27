local WebhookModule = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local function getHTTPRequest()
    local requestFunctions = {
        request, http_request, (syn and syn.request), (fluxus and fluxus.request), (http and http.request), (solara and solara.request),
        (game and game.HttpGet and function(opts) if opts.Method == "GET" then return {Body = game:HttpGet(opts.Url)} end end)
    }
    for _, func in ipairs(requestFunctions) do if func and type(func) == "function" then return func end end
    return nil
end

local httpRequest = getHTTPRequest()

WebhookModule.Config = { WebhookURL = "", DiscordUserID = "", DebugMode = false, EnabledRarities = {}, UseSimpleMode = false }
local Items, Variants

local function loadGameModules()
    return pcall(function()
        Items = require(ReplicatedStorage:WaitForChild("Items"))
        Variants = require(ReplicatedStorage:WaitForChild("Variants"))
    end)
end

local TIER_NAMES = { [1]="Common", [2]="Uncommon", [3]="Rare", [4]="Epic", [5]="Legendary", [6]="Mythic", [7]="SECRET" }
local TIER_COLORS = { [1]=9807270, [2]=3066993, [3]=3447003, [4]=10181046, [5]=15844367, [6]=15548997, [7]=16711680 }
local isRunning = false
local eventConnection = nil

local function getPlayerDisplayName() return LocalPlayer.DisplayName or LocalPlayer.Name end

-- [[ NEW: Fungsi untuk mengambil Avatar Pemain ]] --
local function getPlayerAvatar()
    local userId = LocalPlayer.UserId
    local thumbAPI = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds="..userId.."&size=420x420&format=Png&isCircular=false"
    local avatarUrl = "https://i.imgur.com/4M7IwwP.png" -- Default fallback
    
    if httpRequest then
        local success, response = pcall(function() return game:HttpGet(thumbAPI) end)
        if success then
            local data = HttpService:JSONDecode(response)
            if data and data.data and data.data[1] then avatarUrl = data.data[1].imageUrl end
        end
    end
    return avatarUrl
end

-- [[ NEW: Fungsi Format Angka (1k, 1M) ]] --
local function formatNumber(n)
    if not n then return "0" end
    n = tonumber(n)
    if not n then return "0" end
    local function clean(str) return str:gsub("%.?0+$", "") end
    if n >= 1000000000 then return clean(string.format("%.2f", n / 1000000000)) .. "B" end
    if n >= 1000000 then return clean(string.format("%.2f", n / 1000000)) .. "M" end
    if n >= 1000 then return clean(string.format("%.2f", n / 1000)) .. "k" end
    return clean(string.format("%.2f", n))
end

local function getFishImageUrl(fish)
    local assetId = nil
    if fish.Data.Icon then assetId = tostring(fish.Data.Icon):match("%d+")
    elseif fish.Data.ImageId then assetId = tostring(fish.Data.ImageId)
    elseif fish.Data.Image then assetId = tostring(fish.Data.Image):match("%d+") end
    
    if assetId then return "https://tr.rbxcdn.com/180DAY-" .. tostring(assetId) .. "/420/420/Image/Png" end
    return "https://i.imgur.com/8yZqFqM.png"
end

local function getFish(itemId)
    if not Items then return nil end
    for _, f in pairs(Items) do if f.Data and f.Data.Id == itemId then return f end end
end

local function getVariant(id)
    if not id or not Variants then return nil end
    local idStr = tostring(id)
    for _, v in pairs(Variants) do
        if v.Data and (tostring(v.Data.Id) == idStr or tostring(v.Data.Name) == idStr) then return v end
    end
    return nil
end

local function send(fish, meta, extra)
    if not WebhookModule.Config.WebhookURL or WebhookModule.Config.WebhookURL == "" or not httpRequest then return end

    local tier = fish.Data.Tier or 1
    local tierName = TIER_NAMES[tier] or "Unknown"
    
    -- Filter Rarity
    if WebhookModule.Config.EnabledRarities and #WebhookModule.Config.EnabledRarities > 0 then
        local isEnabled = false
        for _, enabledTier in ipairs(WebhookModule.Config.EnabledRarities) do
            if enabledTier == tierName then isEnabled = true break end
        end
        if not isEnabled then return end
    end

    local finalPrice = fish.SellPrice or 0
    local variantId = (extra and (extra.Variant or extra.Mutation or extra.VariantId)) or (meta and (meta.Variant or meta.Mutation or meta.VariantId))
    local isShiny = (meta and meta.Shiny) or (extra and extra.Shiny)
    local mutList = {}

    if isShiny then 
        finalPrice = finalPrice * 2 
        table.insert(mutList, "✨ Shiny")
    end

    if variantId then
        local v = getVariant(variantId)
        if v then
            finalPrice = finalPrice * (v.SellMultiplier or 1)
            table.insert(mutList, "🧬 " .. v.Data.Name)
        else
            table.insert(mutList, "🧬 " .. tostring(variantId))
        end
    end
    
    -- Check Big
    if fish.Data.BigMin and meta.Weight and meta.Weight >= fish.Data.BigMin then
        finalPrice = finalPrice * 1.2
        table.insert(mutList, "🦈 Big")
    end

    local weightText = formatNumber(meta.Weight or 0) .. " kg"
    local priceText = "$" .. formatNumber(math.floor(finalPrice))
    local chanceText = (fish.Data.Chance and "1 in " .. formatNumber(fish.Data.Chance)) or "Unknown"
    local mutationText = #mutList > 0 and table.concat(mutList, ", ") or "None"
    
    -- [[ PAYLOAD UPDATE START ]] --
    local playerAvatarUrl = getPlayerAvatar()
    local playerName = LocalPlayer.DisplayName
    local playerProfileLink = "https://www.roblox.com/users/" .. LocalPlayer.UserId .. "/profile"
    local imageUrl = getFishImageUrl(fish)
    local color = TIER_COLORS[tier] or 16777215
    if isShiny then color = 16776960 end -- Gold for Shiny

    local description = "**" .. fish.Data.Name .. "** dengan chance **" .. chanceText .. "** berhasil diamankan."
    
    local mention = ""
    if WebhookModule.Config.DiscordUserID ~= "" then
        mention = "<@" .. WebhookModule.Config.DiscordUserID .. ">"
    end

    local payload = {
        ["username"] = "Jazzy Fish Notifier",
        ["avatar_url"] = playerAvatarUrl,
        ["content"] = mention, -- Mention ditaruh di content agar nge-ping
        ["embeds"] = {{
            ["title"] = "🎣 Ikan Baru Ditangkap! di akun " .. playerName,
            ["description"] = description,
            ["color"] = color,
            ["author"] = {["name"] = "Player: " .. playerName, ["url"] = playerProfileLink},
            ["thumbnail"] = {["url"] = imageUrl}, -- Gambar ikan di kanan atas (Thumbnail)
            ["fields"] = {
                {["name"] = "💎 Rarity", ["value"] = "**" .. tierName .. "**", ["inline"] = true},
                {["name"] = "🎲 Chance", ["value"] = "**" .. chanceText .. "**", ["inline"] = true},
                {["name"] = "⚖️ Weight", ["value"] = "`" .. weightText .. "`", ["inline"] = true},
                {["name"] = "💰 Sell Price", ["value"] = "`" .. priceText .. "`", ["inline"] = true},
                {["name"] = "🧬 Mutation", ["value"] = "**" .. mutationText .. "**", ["inline"] = false}
            },
            ["footer"] = {["text"] = "Jazzy GUI v2.3 | " .. os.date("%H:%M:%S")},
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }
    -- [[ PAYLOAD UPDATE END ]] --

    pcall(function()
        httpRequest({
            Url = WebhookModule.Config.WebhookURL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(payload)
        })
    end)
end

-- Module Interface (Jangan Diubah)
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
    if not loadGameModules() then return false end

    local success, Event = pcall(function()
        return ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/ObtainedNewFishNotification"]
    end)

    if not success or not Event then return false end

    eventConnection = Event.OnClientEvent:Connect(function(itemId, metadata, extraData)
        local fish = getFish(itemId)
        if fish then
            task.spawn(function() send(fish, metadata, extraData) end)
        end
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
