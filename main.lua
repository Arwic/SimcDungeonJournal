local OFFSET_ITEM_ID = 1
local OFFSET_ENCHANT_ID = 2
local OFFSET_GEM_ID_1 = 3
local OFFSET_GEM_ID_2 = 4
local OFFSET_GEM_ID_3 = 5
local OFFSET_GEM_ID_4 = 6
local OFFSET_GEM_BASE = OFFSET_GEM_ID_1
local OFFSET_SUFFIX_ID = 7
local OFFSET_FLAGS = 11
local OFFSET_CONTEXT = 12
local OFFSET_BONUS_ID = 13
local OFFSET_UPGRADE_ID = 14 -- Flags = 0x4

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
    ["Finger"] = 'finger1',
    ["Trinket"] = 'trinket1',
    ["Ranged"] = 'main_hand',
    ["off_hand"] = 'off_hand',
    ["ammo"] = 'ammo'
}

local function table_length(t)
    local count = 0
    for k, v in pairs(t) do
        count = count + 1
    end
    return count
end

local function GetAllBossItemLinks()
    -- reset output
    local output = ""
    local itemLevel = 385
    local playerName = UnitName("player")

    for i = 1, EJ_GetNumLoot() do
        local itemID, encounterID, itemName, _, slot = EJ_GetLootInfoByIndex(i)
        local encounterName = EJ_GetEncounterInfo(encounterID)
        local encounterName = encounterName:gsub("%W","")
        
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
        elseif C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItemByID(itemID) then
            local currentSpecID = GetSpecializationInfo(GetSpecialization())
            local tierInfos = C_AzeriteEmpoweredItem.GetAllTierInfoByItemID(itemID)
            local azeritePowerPerms = {}
            -- :)
            for _, t1 in pairs(tierInfos[1].azeritePowerIDs) do
                if C_AzeriteEmpoweredItem.IsPowerAvailableForSpec(t1, currentSpecID) then
                    for _, t2 in pairs(tierInfos[2].azeritePowerIDs) do
                        if C_AzeriteEmpoweredItem.IsPowerAvailableForSpec(t2, currentSpecID) then
                            for _, t3 in pairs(tierInfos[3].azeritePowerIDs) do
                                if C_AzeriteEmpoweredItem.IsPowerAvailableForSpec(t3, currentSpecID) then
                                    for _, t4 in pairs(tierInfos[4].azeritePowerIDs) do
                                        if C_AzeriteEmpoweredItem.IsPowerAvailableForSpec(t4, currentSpecID) then
                                            table.insert(azeritePowerPerms, format("%d/%d/%d/%d",t4,t3,t2,t1))
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
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
    local mainFrame = CreateFrame("Frame", "ARWIC_SIMCDJ_mainFrame", UIParent)
    mainFrame:SetPoint("CENTER",0,0)
    mainFrame:SetSize(500,400)
    mainFrame.texture = mainFrame:CreateTexture(nil, "BACKGROUND")
    mainFrame.texture:SetColorTexture(0.1, 0.1, 0.1, 0.9)
    mainFrame.texture:SetAllPoints(mainFrame)
    mainFrame:Show()

    local closeButton = CreateFrame("BUTTON", "ARWIC_SIMCDJ_closeButton", mainFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", 0, 0)
    closeButton:SetWidth(20)
    closeButton:SetHeight(20)
    closeButton:SetScript("OnClick", function()
        mainFrame:Hide()
    end)

    local editBox = CreateFrame("EditBox", "ARWIC_SIMCDJ_editBox", mainFrame)
    editBox:SetMultiLine(true)
    editBox:SetAllPoints(mainFrame)
    editBox:SetFont("fonts/ARIALN.ttf", 20)
    editBox:SetText(output)
end

SLASH_ARWIC_SIMCDDJ1 = "/simcdj"
SlashCmdList["ARWIC_SIMCDDJ"] = function(msg)
    local output = GetAllBossItemLinks()
    DisplayOutput(output)
end 
