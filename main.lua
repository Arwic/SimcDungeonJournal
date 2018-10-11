
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

local function GetAzeritePowerPerms(tierInfos, mySpecID)
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

local function GetVisibleItemStrings()
    local output = ""
    local itemLevel = 385
    local playerName = UnitName("player")

    for i = 1, EJ_GetNumLoot() do
        local itemID, encounterID, itemName, _, slot = EJ_GetLootInfoByIndex(i)
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
            local azeritePowerPerms = GetAzeritePowerPerms(tierInfos, currentSpecID)
            for _, powers in pairs(azeritePowerPerms) do
                output = format("%s\ncopy=%s - %s - %s (%s),%s", output, encounterName, slot, itemName, powers, playerName)
                output = format("%s\n%s=,id=%s,ilevel=%d,azerite_powers=%s\n", output, slotMap[slot], itemID, itemLevel, powers)
            end
        else
            output = format("%s\ncopy=%s - %s - %s,%s", output, encounterName, slot, itemName, playerName)
            output = format("%s\n%s=,id=%s,ilevel=%d\n", output, slotMap[slot], itemID, itemLevel)
        end
    end

    --print(output)
    return output
end

local function DisplayOutput(output)
    local mainFrame
    if ARWIC_SIMCDJ_mainFrame == nil then
        mainFrame = CreateFrame("Frame", "ARWIC_SIMCDJ_mainFrame", UIParent)
    else
        mainFrame = ARWIC_SIMCDJ_mainFrame
    end
    mainFrame:SetPoint("CENTER",0,0)
    mainFrame:SetSize(500,400)
    mainFrame.texture = mainFrame:CreateTexture(nil, "BACKGROUND")
    mainFrame.texture:SetColorTexture(0.1, 0.1, 0.1, 0.9)
    mainFrame.texture:SetAllPoints(mainFrame)
    mainFrame:Show()

    local closeButton
    if ARWIC_SIMCDJ_closeButton == nil then
        closeButton = CreateFrame("BUTTON", "ARWIC_SIMCDJ_closeButton", mainFrame, "UIPanelCloseButton")
    else
        closeButton = ARWIC_SIMCDJ_closeButton
    end
    closeButton:SetPoint("TOPRIGHT", 0, 0)
    closeButton:SetWidth(20)
    closeButton:SetHeight(20)
    closeButton:SetScript("OnClick", function()
        mainFrame:Hide()
    end)

    local editBox
    if ARWIC_SIMCDJ_editBox == nil then
        editBox = CreateFrame("EditBox", "ARWIC_SIMCDJ_editBox", mainFrame)
    else
        editBox = ARWIC_SIMCDJ_editBox
    end
    editBox:SetMultiLine(true)
    editBox:SetAllPoints(mainFrame)
    editBox:SetFont("fonts/ARIALN.ttf", 12)
    editBox:SetText(output)
end

SLASH_ARWIC_SIMCDDJ1 = "/simcdj"
SlashCmdList["ARWIC_SIMCDDJ"] = function(msg)
    local output = GetVisibleItemStrings()
    DisplayOutput(output)
end 
