local addonName, addon = ...
local frame = CreateFrame("Frame")

-- Function to find action slot by keybind
local function FindSlotByKeybind(key)
    -- Normalize the key format
    key = key:upper()
        :gsub("^%s*(.-)%s*$", "%1")  -- Trim whitespace
        :gsub("SHIFT%+", "SHIFT%-")
        :gsub("CTRL%+", "CTRL%-")
        :gsub("ALT%+", "ALT%-")
    
    print("KeybindAddon: Looking for binding '" .. key .. "'")
    
    -- Special case for CTRL bindings
    if key:match("^CTRL%-[123]$") then
        local num = key:match("CTRL%-(%d)")
        if num then
            local buttonIndex = tonumber(num)
            -- CTRL-1, CTRL-2, CTRL-3 should map to Bar 3, buttons 1, 2, 3
            -- Bar 3 uses MULTIACTIONBAR3BUTTON and starts at offset 24
            local slot = buttonIndex + 24
            print("KeybindAddon: Special mapping for CTRL-" .. num .. " to slot " .. slot .. " (MULTIACTIONBAR3BUTTON" .. buttonIndex .. ")")
            return slot
        end
    end
    
    -- Map of all action bars and their slot offsets
    local actionBars = {
        {prefix = "ACTIONBUTTON", offset = 0},       -- Bar 1 (1-12)
        {prefix = "MULTIACTIONBAR1BUTTON", offset = 12},  -- Bar 2 (13-24)
        {prefix = "MULTIACTIONBAR3BUTTON", offset = 24},  -- Bar 3 (25-36)
        {prefix = "MULTIACTIONBAR4BUTTON", offset = 36},  -- Bar 4 (37-48)
        {prefix = "MULTIACTIONBAR2BUTTON", offset = 48},  -- Bar 5 (49-60)
        {prefix = "EXTRAACTIONBUTTON", offset = 60},      -- Bar 6 (61-72)
    }
    
    -- Try GetBindingByKey first (most reliable for complex bindings)
    local bindingAction = GetBindingByKey(key)
    if bindingAction then
        print("KeybindAddon: Found binding action via GetBindingByKey: " .. bindingAction)
        for _, bar in ipairs(actionBars) do
            for buttonIndex = 1, 12 do
                if bindingAction == bar.prefix .. buttonIndex then
                    local slot = buttonIndex + bar.offset
                    print("KeybindAddon: Matched binding action to slot " .. slot)
                    return slot
                end
            end
        end
    end
    
    -- Try GetBindingAction next
    local action = GetBindingAction(key, true)
    if action and action ~= "" then
        print("KeybindAddon: Direct binding action found via GetBindingAction: " .. action)
        local prefix, buttonIndex = action:match("(.+)(%d+)$")
        if prefix and buttonIndex then
            buttonIndex = tonumber(buttonIndex)
            for _, bar in ipairs(actionBars) do
                if prefix == bar.prefix then
                    local slot = buttonIndex + bar.offset
                    print("KeybindAddon: Matched direct binding to slot " .. slot)
                    return slot
                end
            end
        end
    end
    
    -- Check each action bar button's binding as last resort
    print("KeybindAddon: Checking all action bar buttons for binding '" .. key .. "'")
    for _, bar in ipairs(actionBars) do
        for buttonIndex = 1, 12 do
            local buttonName = bar.prefix .. buttonIndex
            for bindingIndex = 1, 10 do  -- Check up to 10 possible bindings per button
                local binding = select(bindingIndex, GetBindingKey(buttonName))
                if binding then
                    binding = binding:upper()
                        :gsub("SHIFT%+", "SHIFT%-")
                        :gsub("CTRL%+", "CTRL%-")
                        :gsub("ALT%+", "ALT%-")
                    
                    print("KeybindAddon: Checking " .. buttonName .. " with binding '" .. binding .. "'")
                    
                    if binding == key then
                        local slot = buttonIndex + bar.offset
                        print("KeybindAddon: Found match! Slot: " .. slot)
                        return slot
                    end
                    
                    -- Try alternate forms of the same key
                    local altKey = key:gsub("%-", "+")
                    local altBinding = binding:gsub("%-", "+")
                    if altBinding == altKey then
                        local slot = buttonIndex + bar.offset
                        print("KeybindAddon: Found match with alternate format! Slot: " .. slot)
                        return slot
                    end
                else
                    break
                end
            end
        end
    end
    
    print("KeybindAddon: No matching slot found for key '" .. key .. "'")
    return nil
end

-- Function to parse CSV string
local function ParseCSV(csvString)
    local bindings = {}
    print("KeybindAddon: Starting CSV parsing")
    
    for line in csvString:gmatch("[^\r\n]+") do
        local key, spellInput = line:match("([^,]+),(.+)")
        if key and spellInput then
            key = key:gsub("^%s*(.-)%s*$", "%1")
            spellInput = spellInput:gsub("^%s*(.-)%s*$", "%1")
            
            print("KeybindAddon: Processing line: '" .. key .. "', '" .. spellInput .. "'")
            
            local isCtrlKey = key:upper():match("CTRL")
            if isCtrlKey then
                print("KeybindAddon: Detected CTRL key, ensuring proper format")
                key = key:upper()
                    :gsub("CTRL%+", "CTRL%-")
                    :gsub("CTRL%s+", "CTRL%-")
                print("KeybindAddon: Normalized CTRL key to '" .. key .. "'")
            end
            
            local slot = FindSlotByKeybind(key)
            if slot then
                local spellId = tonumber(spellInput)
                if not spellId then
                    local spellInfo = C_Spell.GetSpellInfo(spellInput)
                    if spellInfo then
                        spellId = spellInfo.spellID
                        print("KeybindAddon: Resolved spell name '" .. spellInput .. "' to ID " .. spellId)
                    else
                        print("KeybindAddon: Could not find spell named '" .. spellInput .. "'")
                    end
                end
                if spellId then
                    bindings[slot] = spellId
                    print("KeybindAddon: Mapped key '" .. key .. "' to action slot " .. slot .. " for spell ID " .. spellId)
                end
            else
                print("KeybindAddon: Could not find action slot for key '" .. key .. "'")
                
                if isCtrlKey then
                    local num = key:match("[Cc][Tt][Rr][Ll].?(%d)")
                    if num then
                        local suggestedSlot = tonumber(num) + 24
                        print("KeybindAddon: CTRL+" .. num .. " should map to slot " .. suggestedSlot .. " (Bar 3/MULTIACTIONBAR3BUTTON" .. num .. ")")
                        print("KeybindAddon: Using forced mapping for CTRL key")
                        
                        local spellIdValue = tonumber(spellInput)
                        if not spellIdValue then
                            local spellInfo = C_Spell.GetSpellInfo(spellInput)
                            spellIdValue = spellInfo and spellInfo.spellID
                        end
                        
                        if spellIdValue then
                            bindings[suggestedSlot] = spellIdValue
                            print("KeybindAddon: Forced mapping of '" .. key .. "' to slot " .. suggestedSlot)
                        else
                            print("KeybindAddon: Could not resolve spell: " .. spellInput)
                        end
                    else
                        print("KeybindAddon: Could not extract number from CTRL key: " .. key)
                    end
                end
            end
        else
            print("KeybindAddon: Could not parse line: " .. line)
        end
    end
    return bindings
end

-- Function to place spells on action bars
local function PlaceSpells(bindings)
    if not bindings then return end
    
    print("KeybindAddon: Placing spells on action bars...")
    
    local slots = {}
    for slot in pairs(bindings) do
        table.insert(slots, slot)
    end
    table.sort(slots)
    
    local currentIndex = 1
    local function ProcessNextSpell()
        local slot = slots[currentIndex]
        if not slot then
            print("KeybindAddon: Spell placement completed")
            return
        end
        
        local spellId = bindings[slot]
        print("KeybindAddon: Processing slot " .. slot .. " for spell ID " .. spellId)
        
        local spell = Spell:CreateFromSpellID(spellId)
        spell:ContinueOnSpellLoad(function()
            C_Spell.PickupSpell(spellId)
            
            if GetCursorInfo() then
                PlaceAction(slot)
                local spellInfo = C_Spell.GetSpellInfo(spellId)
                local spellName = spellInfo and spellInfo.name or "Unknown"
                print("KeybindAddon: Placed " .. spellName .. " (ID: " .. spellId .. ") on action slot " .. slot)
            else
                print("KeybindAddon: Could not pick up spell with ID " .. spellId)
            end
            
            ClearCursor()
            
            currentIndex = currentIndex + 1
            C_Timer.After(0.1, ProcessNextSpell)
        end)
    end
    
    ProcessNextSpell()
end

-- Create simple UI frame
local function CreateUI()
    local f = CreateFrame("Frame", "KeybindAddonFrame", UIParent, "BackdropTemplate")
    f:SetSize(500, 400)
    f:SetPoint("CENTER")
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()

    -- Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -20)
    title:SetText("AutoKeybinder")

    -- Instructions
    local instructions = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    instructions:SetPoint("TOP", 0, -45)
    instructions:SetText("Format: key,SPELL_NAME\nExample: 1,Chaos Bolt")

    -- Close button
    local closeButton = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -2, -2)

    -- Create scroll frame for text input
    local scrollFrame = CreateFrame("ScrollFrame", "KeybindAddonScrollFrame", f, "InputScrollFrameTemplate")
    scrollFrame:SetSize(300, 200)
    scrollFrame:SetPoint("TOP", 0, -100)
    
    -- Get the edit box from the scroll frame
    local editBox = scrollFrame.EditBox
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(300)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetScript("OnEscapePressed", function() f:Hide() end)
    editBox:SetCountInvisibleLetters(false)
    
    -- Set default text with examples of both ID and name
    -- editBox:SetText("1,Chaos Bolt\n2,Conflagrate\n3,Immolate")

    -- Apply button
    local applyButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    applyButton:SetSize(100, 30)
    applyButton:SetPoint("BOTTOM", 0, 40)
    applyButton:SetText("Apply")
    applyButton:SetScript("OnClick", function()
        local text = editBox:GetText()
        if text ~= "" then
            local bindings = ParseCSV(text)
            if bindings then
                PlaceSpells(bindings)
            else
                print("KeybindAddon: Failed to parse CSV data!")
            end
        end
    end)
    
    -- Add a subtle link to the keybind planner spreadsheet
    local linkButton = CreateFrame("Button", nil, f)
    linkButton:SetSize(300, 20)
    linkButton:SetPoint("BOTTOM", 0, 15)
    
    local linkText = linkButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    linkText:SetPoint("CENTER")
    linkText:SetText("Need help with keybinds? Click here.")
    linkText:SetTextColor(0.5, 0.7, 1.0)
    
    linkButton:SetScript("OnClick", function()
        StaticPopup_Show("AUTOKEYBINDER_EXTERNAL_LINK", "https://docs.google.com/spreadsheets/d/1mGMkLzNWzreBuRsGgZc5bhMcZFSubhQaBm40_xuI8z4/edit?usp=sharing")
    end)
    
    linkButton:SetScript("OnEnter", function(self)
        linkText:SetTextColor(0.7, 0.9, 1.0)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Open The War Within Keybind Planner")
        GameTooltip:Show()
    end)
    
    linkButton:SetScript("OnLeave", function(self)
        linkText:SetTextColor(0.5, 0.7, 1.0)
        GameTooltip:Hide()
    end)

    return f
end

-- Create dialog for external links
StaticPopupDialogs["AUTOKEYBINDER_EXTERNAL_LINK"] = {
    text = "Copy this link to visit the keybind planner:\n",
    button2 = "Cancel",
    hasEditBox = true,
    editBoxWidth = 350,
    OnShow = function(self, data)
        local text = self.text:GetText()
        local url = self.text.text_arg1
        self.editBox:SetText(url or "")
        self.editBox:SetFocus()
        self.editBox:HighlightText()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Create UI frame
local uiFrame = CreateUI()

-- Function to list all keybindings
local function ListAllBindings()
    print("KeybindAddon: Listing all keybindings:")
    print("----------------------------------------")
    
    -- Map of all action bars with their names and slot offsets
    local actionBars = {
        {name = "Main Action Bar (1)", prefix = "ACTIONBUTTON", offset = 0},
        {name = "Bottom Right Bar (2)", prefix = "MULTIACTIONBAR1BUTTON", offset = 12},
        {name = "Right Bar 1 (3)", prefix = "MULTIACTIONBAR3BUTTON", offset = 24},
        {name = "Bottom Left Bar (4)", prefix = "MULTIACTIONBAR4BUTTON", offset = 36},
        {name = "Right Bar 2 (5)", prefix = "MULTIACTIONBAR2BUTTON", offset = 48},
        {name = "Extra Action Bar (6)", prefix = "EXTRAACTIONBUTTON", offset = 60},
    }
    
    -- Check each action bar
    for _, bar in ipairs(actionBars) do
        print("\n" .. bar.name .. ":")
        for i = 1, 12 do
            local buttonName = bar.prefix .. i
            local slot = i + bar.offset
            
            -- Get all bindings for this button
            local bindings = {GetBindingKey(buttonName)}
            if #bindings > 0 then
                for j, binding in ipairs(bindings) do
                    print(string.format("Slot %d (%s): %s", slot, buttonName, binding:upper()))
                end
            end
        end
    end
    
    print("\nDynamic Binding Tests:")
    print("Testing various key formats to confirm they map to the right slots:")
    local testBindings = {
        "1", "2", "3",
        "SHIFT-1", "SHIFT-2", "SHIFT-3",
        "CTRL-1", "CTRL-2", "CTRL-3",
        "ALT-1", "ALT-2", "ALT-3"
    }
    
    for _, binding in ipairs(testBindings) do
        local slot = FindSlotByKeybind(binding)
        if slot then
            print(string.format("Binding '%s' maps to slot %d", binding, slot))
        else
            print(string.format("No slot found for binding '%s'", binding))
        end
    end
    
    print("----------------------------------------")
end

-- Slash commands
SLASH_KEYBIND1 = "/autokb"
SLASH_KEYBIND2 = "/akb"
SlashCmdList["KEYBIND"] = function(msg)
    if msg == "" then
        uiFrame:Show()
    elseif msg == "list" then
        ListAllBindings()
    elseif msg:match("^place%s+(%d+)%s+(%d+)$") then
        local spellId, slotNumber = msg:match("^place%s+(%d+)%s+(%d+)$")
        spellId = tonumber(spellId)
        slotNumber = tonumber(slotNumber)
        
        if spellId and slotNumber then
            local bindings = {[slotNumber] = spellId}
            PlaceSpells(bindings)
        end
    end
end

-- Test command for spell info
SLASH_TESTKB1 = "/testkb"
SlashCmdList["TESTKB"] = function(msg)
    local spellId = 348 -- Immolate
    print("Testing spell ID:", spellId)
    print("Is spell cached:", C_Spell.IsSpellDataCached(spellId))
    print("GetSpellInfo:", GetSpellInfo(spellId))
    
    -- Also test with C_Spell.GetSpellInfo
    local spellInfo = C_Spell.GetSpellInfo(spellId)
    if spellInfo then
        print("C_Spell.GetSpellInfo results:")
        for k, v in pairs(spellInfo) do
            print(" -", k .. ":", v)
        end
    else
        print("C_Spell.GetSpellInfo returned nil")
    end
end 