
local encounterJournalDifficulty = 16
local encounterJournalInstance = 16

local instanceItemLevelMap = {
    [1148] = { -- Uldir
        [16] = 385,
        [15] = 370,
        [14] = 355,
        [17] = 340,
    },
    [1352] = { -- BoD
        [16] = 415,
        [15] = 400,
        [14] = 385,
        [17] = 370,
    },
    
}

local difficultyMap = {
    [16] = 385,
    [15] = 370,
    [14] = 355,
    [17] = 340,
}

local slotMap = {
    ["Head"] = 'head',
    ["Neck"] = 'neck',
    ["Shoulder"] = 'shoulder',
    ["Back"] = 'back',
    ["Chest"] = 'chest',
    ["Shirt"] = 'shirt',
    ["Tabard"] = 'tabard',
    ["Wrist"] = 'wrist',
    ["Hands"] = 'hands',
    ["Waist"] = 'waist',
    ["Legs"] = 'legs',
    ["Feet"] = 'feet',
    ["Ranged"] = 'main_hand',
    ["Two-Hand"] = 'main_hand',
    ["Off Hand"] = 'off_hand',
    ["Held In Off-hand"] = 'off_hand',
}

local function table_length(t)
    local count = 0
    for k, v in pairs(t) do
        count = count + 1
    end
    return count
end

local function GetAzeritePowerPermuts(tierInfos, mySpecID)
    local done = {}
    local finalTier = table_length(tierInfos)
    local function _r(tier, last)
        -- if our tier is greater than the final tier put us in the done array and return
        if tier > finalTier then
            -- strip trailing '/'
            last = last:sub(1, -2)
            table.insert(done, last)
            return
        end
        for _, powerID in pairs(tierInfos[tier].azeritePowerIDs) do
            -- make sure the power is usable by our spec
            if C_AzeriteEmpoweredItem.IsPowerAvailableForSpec(powerID, mySpecID) then
                -- prepend the powerid
                local next = powerID .. "/" .. last
                _r(tier + 1, next)
            end
        end
    end
    _r(1, "")
    return done
end

-- Dialogue that enables the user to name a new profile
StaticPopupDialogs["ARWIC_SIMCDJ_NO_ILVLS"] = {
    text = "The instance '%s' has no predefined item level values, please enter an item level.",
    button1 = "OK",
    button2 = "Cancel",
    OnAccept = function(sender)
        local itemLevel = sender.editBox:GetNumber()
        local output = ARWIC_SIMCDJ_GetVisibleItemStrings(itemLevel)
        ARWIC_SIMCDJ_DisplayOutput(output)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    hasEditBox = true,
    enterClicksFirstButton = true,
}
local function StaticPopupShow_NoItemLevel(instnaceName)
    StaticPopup_Show("ARWIC_SIMCDJ_NO_ILVLS", instnaceName)
end


function ARWIC_SIMCDJ_GetVisibleItemStrings(forcedIlvl)
    local itemLevel = 0
    if type(forcedIlvl) == "number" and forcedIlvl ~= 0 then
        itemLevel = forcedIlvl
    else
        local dungeonName, _, _, _, _, _, dungeonAreaMapID = EJ_GetInstanceInfo()
        local itemLevelMap = instanceItemLevelMap[dungeonAreaMapID]
        if itemLevelMap ~= nil then
            itemLevel = itemLevelMap[encounterJournalDifficulty]
        else
            StaticPopupShow_NoItemLevel(dungeonName)
            return -- leave here because the static popup will recall this method later with a forced ilvl
        end
    end

    local output = ""
    local playerName = UnitName("player")

    for i = 1, EJ_GetNumLoot() do
        local itemID, encounterID, itemName, _, slot = EJ_GetLootInfoByIndex(i)
        if slot ~= nil and slot ~= "" then -- Dont try and create copy profiles for non armour/weapon items like mounts and pets
            local encounterName = EJ_GetEncounterInfo(encounterID)
            local encounterName = encounterName:gsub("%W","") -- strip characters that break simc
            local itemName = itemName:gsub("%W",""):sub(10) -- strip characters that break simc
            if slot == "Finger" then
                -- slot 1
                output = format("%s\ncopy=%s - %s - %s,%s", output, encounterName, "Finger (1)", itemName, playerName)
                output = format("%s\n%s=,id=%s,ilevel=%d\n", output, "finger1", itemID, itemLevel)
                -- slot 2
                output = format("%s\ncopy=%s - %s - %s,%s", output, encounterName, "Finger (2)", itemName, playerName)
                output = format("%s\n%s=,id=%s,ilevel=%d\n", output, "finger2", itemID, itemLevel)
            elseif slot == "Trinket" then
                -- slot 1
                output = format("%s\ncopy=%s - %s - %s,%s", output, encounterName, "Trinket (1)", itemName, playerName)
                output = format("%s\n%s=,id=%s,ilevel=%d\n", output, "trinket1", itemID, itemLevel)
                -- slot 2
                output = format("%s\ncopy=%s - %s - %s,%s", output, encounterName, "Trinket (2)", itemName, playerName)
                output = format("%s\n%s=,id=%s,ilevel=%d\n", output, "trinket2", itemID, itemLevel)
            elseif slot == "One-Hand" then
                -- main hand
                output = format("%s\ncopy=%s - %s - %s,%s", output, encounterName, "One Hand (1)", itemName, playerName)
                output = format("%s\n%s=,id=%s,ilevel=%d\n", output, "main_hand", itemID, itemLevel)
                -- off hand
                output = format("%s\ncopy=%s - %s - %s,%s", output, encounterName, "One Hand (2)", itemName, playerName)
                output = format("%s\n%s=,id=%s,ilevel=%d\n", output, "off_hand", itemID, itemLevel)
            elseif C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItemByID(itemID) then
                local currentSpecID = GetSpecializationInfo(GetSpecialization())
                local tierInfos = C_AzeriteEmpoweredItem.GetAllTierInfoByItemID(itemID)
                local azeritePowerPermuts = GetAzeritePowerPermuts(tierInfos, currentSpecID)
                for _, powers in pairs(azeritePowerPermuts) do
                    output = format("%s\ncopy=%s - %s - %s (%s),%s", output, encounterName, slot, itemName, powers, playerName)
                    output = format("%s\n%s=,id=%s,ilevel=%d,azerite_powers=%s\n", output, slotMap[slot], itemID, itemLevel, powers)
                end
            else
                output = format("%s\ncopy=%s - %s - %s,%s", output, encounterName, slot, itemName, playerName)
                output = format("%s\n%s=,id=%s,ilevel=%d\n", output, slotMap[slot], itemID, itemLevel)
            end
        end
    end

    return output
end

function ARWIC_SIMCDJ_DisplayOutput(output)
    if output == nil then
        return
    end
    local mainFrame = ARWIC_SIMCDJ_mainFrame
    local editBox = ARWIC_SIMCDJ_editBox
    local scrollContent = ARWIC_SIMCDJ_scrollContent
    local scrollbar = ARWIC_SIMCDJ_scrollbar
    if ARWIC_SIMCDJ_mainFrame == nil then
        mainFrame = CreateFrame("Frame", "ARWIC_SIMCDJ_mainFrame", UIParent)
        mainFrame.texture = mainFrame:CreateTexture(nil, "BACKGROUND")
        mainFrame.texture:SetColorTexture(0.1, 0.1, 0.1, 0.9)
        mainFrame.texture:SetAllPoints(mainFrame)
        table.insert(UISpecialFrames, mainFrame:GetName())
        mainFrame:SetPoint("CENTER",0,0)
        mainFrame:SetSize(500,400)
        mainFrame:SetFrameStrata("DIALOG")

        local closeButton = CreateFrame("BUTTON", "ARWIC_SIMCDJ_closeButton", mainFrame, "UIPanelCloseButton")
        closeButton:SetPoint("TOPRIGHT", 0, 0)
        closeButton:SetWidth(20)
        closeButton:SetHeight(20)
        closeButton:SetScript("OnClick", function()
            mainFrame:Hide()
        end)

        --scrollframe 
        scrollframe = CreateFrame("ScrollFrame", nil, mainFrame) 
        scrollframe:SetPoint("TOPLEFT", 10, -10) 
        scrollframe:SetPoint("BOTTOMRIGHT", -10, 10) 
        mainFrame.scrollframe = scrollframe 

        --scrollbar 
        scrollbar = CreateFrame("Slider", "ARWIC_SIMCDJ_scrollbar", scrollframe, "UIPanelScrollBarTemplate") 
        scrollbar:SetPoint("TOPLEFT", mainFrame, "TOPRIGHT", -20, -40) 
        scrollbar:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMRIGHT", -20, 20) 
        scrollbar:SetMinMaxValues(1, 5000) 
        scrollbar:SetValueStep(1) 
        scrollbar.scrollStep = 1 
        scrollbar:SetValue(0) 
        scrollbar:SetWidth(16) 
        scrollbar:SetScript("OnValueChanged", function (self, value) 
            self:GetParent():SetVerticalScroll(value) 
        end) 
        mainFrame.scrollbar = scrollbar 
        mainFrame:SetScript("OnMouseWheel", function(self, arg1)
            scrollbar:SetValue(scrollbar:GetValue() - 100 * arg1)
        end)

        --content frame 
        local scrollContent = CreateFrame("Frame", "ARWIC_SIMCDJ_scrollContent", scrollframe) 
        scrollContent:SetSize(mainFrame:GetWidth(), mainFrame:GetHeight())
        scrollframe.content = scrollContent 
        scrollframe:SetScrollChild(scrollContent)
        
        editBox = CreateFrame("EditBox", "ARWIC_SIMCDJ_editBox", scrollContent)
        editBox:SetMultiLine(true)
        editBox:SetAllPoints(scrollContent)
        editBox:SetFont("fonts/ARIALN.ttf", 12)
        editBox:SetScript("OnEscapePressed", function(self)
            self:ClearFocus()
        end)
        editBox:SetScript("OnTextChanged", function(self)
            ARWIC_SIMCDJ_scrollbar:SetMinMaxValues(1, 5000)
        end)
    end
    mainFrame:Show()
    editBox:SetText(output)
    editBox:HighlightText()
    scrollbar:SetValue(1)
end

local function BuildUI()
    local editBox = ARWIC_SIMCDJ_ilvlEditBox
    local btn = ARWIC_SIMCDJ_ejButton
    if ARWIC_SIMCDJ_ilvlEditBox == nil then
        editBox = CreateFrame("EditBox", "ARWIC_SIMCDJ_ilvlEditBox", EncounterJournal, "InputBoxTemplate")
        editBox:SetPoint("TOPRIGHT", EncounterJournal, -105, 0)
        editBox:SetWidth(40)
        editBox:SetHeight(20)
        editBox:SetNumeric(true)
        editBox:SetFont("fonts/ARIALN.ttf", 12)
        editBox:SetAutoFocus(false)
        editBox:SetFrameStrata("HIGH")
        editBox:SetScript("OnEscapePressed", function(self)
            self:ClearFocus()
        end)
        editBox:SetScript("OnEnterPressed", function(self)
            self:ClearFocus()
            local output = ARWIC_SIMCDJ_GetVisibleItemStrings(self:GetNumber())
            ARWIC_SIMCDJ_DisplayOutput(output)
        end)
        editBox:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine("Custom item level. Leave blank to default to selected difficulty for supported instances.", 1, 1, 1, true)
            GameTooltip:Show()
        end)
        editBox:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)

        btn = CreateFrame("BUTTON", "ARWIC_SIMCDJ_ejButton", ARWIC_SIMCDJ_ilvlEditBox, "UIPanelButtonTemplate")
        btn:SetPoint("LEFT", editBox, "RIGHT")
        btn:SetPoint("TOP", editBox, "TOP")
        btn:SetPoint("BOTTOM", editBox, "BOTTOM")
        btn:SetFrameStrata("HIGH")
        btn:SetWidth(80)
        btn:SetHeight(20)
        btn:SetText("Simc")
        btn:SetScript("OnClick", function()
            ARWIC_SIMCDJ_ilvlEditBox:ClearFocus()
            local output = ARWIC_SIMCDJ_GetVisibleItemStrings(ARWIC_SIMCDJ_ilvlEditBox:GetNumber())
            ARWIC_SIMCDJ_DisplayOutput(output)
        end)
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine("Generates Simulationcraft input for the currently visible loot table", 1, 1, 1, true)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
    end
end

SLASH_ARWIC_SIMCDDJ1 = "/simcdj"
SlashCmdList["ARWIC_SIMCDDJ"] = function(args)
    local forcedIlvl = tonumber(args)
    local output = ARWIC_SIMCDJ_GetVisibleItemStrings(forcedIlvl)
    ARWIC_SIMCDJ_DisplayOutput(output)
end 

local events = {}
events["ADDON_LOADED"] = function(self, addonName)
    if addonName == "Blizzard_EncounterJournal" then
        BuildUI()
    end
end
events["EJ_DIFFICULTY_UPDATE"] = function(self, diffID)
    encounterJournalDifficulty = diffID
end

local function RegisterEvents()
    -- register events
    local eventFrame = CreateFrame("FRAME", "ARWIC_SIMCDJ_eventFrame")
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        events[event](self, ...)
    end)
    for k, v in pairs(events) do
        eventFrame:RegisterEvent(k)
    end
end
RegisterEvents()
