-- track which emotes have fel variants
felVariants = {
    ["arrogantsum"] = {"arrogantsum_fel1", "arrogantsum_fel2", "arrogantsum_fel3"},
    ["chargesum"] = {"chargesum_fel1", "chargesum_fel2", "chargesum_fel3"},
    ["clownsum"] = {"clownsum_fel1", "clownsum_fel2", "clownsum_fel3"},
    ["crazysum"] = {"crazysum_fel1", "crazysum_fel2", "crazysum_fel3"},
    ["fatsum"] = {"fatsum_fel1", "fatsum_fel2", "fatsum_fel3"},
    ["happysum"] = {"happysum_fel1", "happysum_fel2", "happysum_fel3"},
    ["lootsum"] = {"lootsum_fel1", "lootsum_fel2", "lootsum_fel3"},
    ["madsum"] = {"madsum_fel1", "madsum_fel2", "madsum_fel3"},
    ["mapossum"] = {"mapossum_fel1", "mapossum_fel2", "mapossum_fel3"},
    ["sadsum"] = {"sadsum_fel1", "sadsum_fel2", "sadsum_fel3"},
    ["scaredsum"] = {"scaredsum_fel1", "scaredsum_fel2", "scaredsum_fel3"}
}

-- random tooltip texts for fel emotes
local felHoverTexts = {
    "It whispers to you...",
    "The corruption spreads...",
    "The Fel hungers...",
    "Something is watching you...",
    "It grows stronger...",
    "Your mind feels clouded...",
    "Darkness awaits...",
    "The Legion is watching...",
    "You hear distant whispers...",
    "Strange energies flow through it...",
    "A faint green glow pulses within...",
    "You feel a chill down your spine...",
    "It seems to be... changing...",
    "The eyes follow you...",
    "You feel drawn to it...",
    "Must. Eat. Trash.",
    "You will never get Thunderfury...",
}

-- get random hover text
local function GetRandomFelHoverText()
    local index = math.random(1, #felHoverTexts)
    return "|cFF00FF00" .. felHoverTexts[index] .. "|r"  -- green color
end

-- create a set of all fel variant names for quick lookup
local allFelVariants = {}
for _, variants in pairs(felVariants) do
    for _, variant in ipairs(variants) do
        allFelVariants[variant] = true
    end
end

-- create array of fel variants to exclude from autocomplete
local felEmotesToExclude = {}
for _, variants in pairs(felVariants) do
    for _, variant in ipairs(variants) do
        table.insert(felEmotesToExclude, variant)
    end
end

-- only remove emotes from autocomplete (not from the emote registry)
local function remove_from_autocomplete_only(emotes, autocompleteList)
    for i = #autocompleteList, 1, -1 do
        for j = 1, #emotes do
            if autocompleteList[i] == emotes[j] then
                table.remove(autocompleteList, i) --remove from autocomplete suggestions only
                break
            end
        end
    end
end

remove_from_autocomplete_only(felEmotesToExclude, AllTwitchEmoteNames)

-- replace emotes in chat with fel variants
-- get random fel variant
local function GetRandomFelVariant(emote)
    if felVariants[emote] then
        local variants = felVariants[emote]
        return variants[math.random(1, #variants)]
    end
    return emote
end

local function GetDaysSinceInvasion()
    local currentTime = time()
    local invasionTime = 1745193600  -- Monday, 21 April 2025 00:00:00 GMT
    
    local days = 0
    if currentTime > invasionTime then
        days = math.floor((currentTime - invasionTime) / 86400)
    end
    
    return days
end

-- calculate chance based on days since invasion, base is 50% and increases by 1% per day
local felVariantChance = math.min(0.5 + (GetDaysSinceInvasion() * 0.01), 1.0)

-- replace emotes with fel variants in message text
local function ReplaceEmotesWithFelVariants(msg)
    local delimiters = "%s,'<>?-%.!"
    local result = msg
    
    local pattern = "%f[%w]([^" .. delimiters .. "]+)%f[^%w]"
    
    -- process each word in the message
    result = result:gsub(pattern, function(word)
        -- check if this word is a valid emote
        if aftershockEmotes[word] then
            local baseEmote = aftershockEmotes[word]
            -- check if this emote has fel variants
            if felVariants[baseEmote] then
                -- use chance based on days since invasion for this specific occurrence
                if math.random() < felVariantChance then
                    return GetRandomFelVariant(baseEmote)
                end
            end
        end
        return word
    end)
    
    return result
end

-- original functions
local originalSendChatMessage = SendChatMessage
local originalSendMail = SendMail
local originalBNSendWhisper = BNSendWhisper

function SendChatMessage(msg, ...)
    if msg ~= nil then
        -- replace emotes with fel variants
        msg = ReplaceEmotesWithFelVariants(msg)
        
        if Emoticons_Settings["ENABLE_CLICKABLEEMOTES"] then
            msg = TwitchEmotes_Message_StripEscapes(msg) 
        end
        originalSendChatMessage(msg, ...)
    end
end

function SendMail(recipient, subject, msg, ...)
    if msg ~= nil then
        -- replace emotes with fel variants
        msg = ReplaceEmotesWithFelVariants(msg)
        
        if Emoticons_Settings["ENABLE_CLICKABLEEMOTES"] then
            msg = TwitchEmotes_Message_StripEscapes(msg) 
        end
        originalSendMail(recipient, subject, msg, ...)
    end
end

function BNSendWhisper(id, msg, ...)
    if msg ~= nil then
        -- replace emotes with fel variants
        msg = ReplaceEmotesWithFelVariants(msg)

        if Emoticons_Settings["ENABLE_CLICKABLEEMOTES"] then
            msg = TwitchEmotes_Message_StripEscapes(msg) 
        end
        originalBNSendWhisper(id, msg, ...)
    end
end

-- replace tooltips for fel emotes for more fun + to hide actual names for emotes
local originalSetHyperlink = ItemRefTooltip.SetHyperlink

function ItemRefTooltip:SetHyperlink(link)
    if (string.sub(link, 1, 3) == "tel") then
        local emote = string.sub(link, 5)  -- extract emote name from link
        
        if allFelVariants[emote] then
            -- fel tooltip
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            GameTooltip:SetText(GetRandomFelHoverText())
            GameTooltip:Show()
        else
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            GameTooltip:SetText(emote, 255, 210, 0)
            GameTooltip:Show()
        end
    else
        originalSetHyperlink(self, link)
    end
end

local originalOnHyperlinkEnter = Emoticons_OnHyperlinkEnter

function Emoticons_OnHyperlinkEnter(frame, link, message, fontstring, ...)
    local linkType, linkContent = link:match("^([^:]+):(.+)")
    if (linkType) then
        if (linkType == "tel") then
            TwitchEmotes_HoverMessageInfo = fontstring.messageInfo
            
            -- do fucked up tooltips for fel emotes
            if allFelVariants[linkContent] then
                GameTooltip:SetOwner(frame, "ANCHOR_CURSOR")
                GameTooltip:SetText(GetRandomFelHoverText())
                GameTooltip:Show()
            else
                GameTooltip:SetOwner(frame, "ANCHOR_CURSOR")
                GameTooltip:SetText(linkContent, 255, 210, 0)
                GameTooltip:Show()
            end
        end
    end
end

-- make sure not hidden by other addon spam
C_Timer.After(30, function()
    print("|cFFFF0000The possum invasion is coming...|r")
end)

local frame = CreateFrame("FRAME")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        if Emoticons_OnHyperlinkEnter and not originalOnHyperlinkEnter then
            originalOnHyperlinkEnter = Emoticons_OnHyperlinkEnter
            _G.Emoticons_OnHyperlinkEnter = Emoticons_OnHyperlinkEnter
        end
        
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end) 