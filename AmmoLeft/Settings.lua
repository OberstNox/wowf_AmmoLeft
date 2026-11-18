local addonName, addon = ...

local function Label(parent, text, x, y, font)
    local label = parent:CreateFontString(nil, "ARTWORK", font or "GameFontHighlight")
    label:SetPoint("TOPLEFT", x, y)
    label:SetText(text)
    return label
end

local function Button(parent, text, x, y, width, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", x, y)
    button:SetSize(width, 24)
    button:SetText(text)
    button:SetScript("OnClick", onClick)
    return button
end

local function NumberBox(parent, x, y)
    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetPoint("TOPLEFT", x, y)
    box:SetSize(85, 24)
    box:SetAutoFocus(false)
    box:SetNumeric(true)
    box:SetMaxLetters(9)
    box:SetScript("OnEscapePressed", box.ClearFocus)
    return box
end

local function Panel()
    local panel = CreateFrame("Frame", nil, nil, "BackdropTemplate")
    addon.StylePanel(panel, 0.96)
    return panel
end

local function Dropdown(panel, x, y, width, choices, selected, choose)
    local control = CreateFrame("DropdownButton", nil, panel, "WowStyle1DropdownTemplate")
    control:SetPoint("TOPLEFT", x, y)
    control:SetWidth(width)
    control:SetupMenu(function(_, root)
        for _, choice in ipairs(choices()) do
            root:CreateRadio(choice.label, selected, choose, choice.key)
        end
    end)
    return control
end

local function TextBox(panel, x, y, width, length)
    local box = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    box:SetPoint("TOPLEFT", x, y)
    box:SetSize(width, 24)
    box:SetAutoFocus(false)
    box:SetMaxLetters(length)
    box:SetScript("OnEscapePressed", box.ClearFocus)
    return box
end

local function RegisterPopupSettings(parentCategory)
    local panel = Panel()
    Label(panel, "Alerts", 16, -16, "GameFontNormalLarge")
    Label(panel, "Leave the message blank for the default. {count} inserts the ammo count.", 16, -45, "GameFontHighlightSmall")
    local controls = {}

    for index, entry in ipairs({
        { level = "low", label = "Low" },
        { level = "critical", label = "Critical" },
    }) do
        local level = entry.level
        local y = -72 - (index - 1) * 138
        local enabledKey, messageKey = level .. "Popup", level .. "Message"
        local check = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        check:SetPoint("TOPLEFT", 14, y)
        check:SetScript("OnClick", function(self)
            addon.options[enabledKey] = not not self:GetChecked()
        end)
        Label(panel, entry.label .. " pop-up", 46, y - 8)

        local box = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
        box:SetPoint("TOPLEFT", 21, y - 34)
        box:SetSize(244, 24)
        box:SetAutoFocus(false)
        box:SetMaxLetters(100)
        box:SetScript("OnEnterPressed", box.ClearFocus)
        box:SetScript("OnEscapePressed", box.ClearFocus)
        box:SetScript("OnTextChanged", function(self, userInput)
            if userInput then
                addon.options[messageKey] = self:GetText()
            end
        end)
        Button(panel, "Preview " .. entry.label, 281, y - 34, 125, function()
            box:ClearFocus()
            addon.PreviewAlert(level)
        end)
        local soundKey, durationKey, pulseKey = level .. "Sound", level .. "Duration", level .. "Pulse"
        local sound = Dropdown(panel, 16, y - 69, 152, function()
            local choices = {}
            for _, entrySound in ipairs(addon.sounds) do
                if entrySound.key == "off" or entrySound.kit then choices[#choices + 1] = entrySound end
            end
            return choices
        end, function(key) return addon.options[soundKey] == key end,
            function(key) addon.options[soundKey] = key end)
        local duration = NumberBox(panel, 184, y - 70)
        duration:SetWidth(42)
        duration:SetMaxLetters(2)
        Label(panel, "sec", 236, y - 75)
        duration:SetScript("OnEditFocusLost", function(self)
            local value = tonumber(self:GetText())
            if value and value >= 1 and value <= 15 and value % 1 == 0 then
                addon.options[durationKey] = value
            end
            self:SetText(tostring(addon.options[durationKey]))
        end)
        duration:SetScript("OnEnterPressed", duration.ClearFocus)
        local pulse = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        pulse:SetPoint("TOPLEFT", 275, y - 65)
        pulse:SetScript("OnClick", function(self) addon.options[pulseKey] = not not self:GetChecked() end)
        Label(panel, "Pulse counter", 307, y - 73)
        controls[index] = function()
            check:SetChecked(addon.options[enabledKey])
            box:SetText(addon.options[messageKey])
            sound:GenerateMenu()
            duration:SetText(tostring(addon.options[durationKey]))
            pulse:SetChecked(addon.options[pulseKey])
        end
    end

    Button(panel, "Move pop-up", 16, -345, 130, addon.StartMovingAlert)
    Label(panel, "Both alerts use the same position.", 16, -379, "GameFontHighlightSmall")
    panel:SetScript("OnShow", function()
        for _, sync in ipairs(controls) do sync() end
    end)
    panel:SetScript("OnHide", addon.StopMovingAlert)
    return Settings.RegisterCanvasLayoutSubcategory(parentCategory, panel, "Alerts")
end

local function ProfileChoices(values, exclude)
    local choices = {}
    for key in pairs(values) do
        if key ~= exclude then choices[#choices + 1] = { key = key, label = key } end
    end
    table.sort(choices, function(a, b) return a.label < b.label end)
    return choices
end

local function RegisterProfiles(parent)
    local panel = Panel()
    Label(panel, "Profiles", 16, -16, "GameFontNormalLarge")
    local status = Label(panel, "", 16, -45)
    local function Sync()
        status:SetText("Active profile: " .. AmmoLeftDB.profile)
    end
    Label(panel, "Use profile", 16, -82)
    Dropdown(panel, 146, -76, 260, function()
        return ProfileChoices(AmmoLeftProfiles.profiles)
    end, function(key) return AmmoLeftDB.profile == key end, function(key)
        addon.UseProfile(key)
        Sync()
    end)
    Label(panel, "New profile", 16, -121)
    local name = TextBox(panel, 151, -114, 158, 40)
    Button(panel, "Create", 318, -114, 88, function()
        if addon.NewProfile(name:GetText()) then name:SetText(""); Sync()
        else status:SetText("Enter a unique, non-empty profile name.") end
    end)

    local source
    Label(panel, "Copy from", 16, -162)
    Dropdown(panel, 146, -156, 260, function()
        return ProfileChoices(AmmoLeftProfiles.profiles, AmmoLeftDB.profile)
    end, function(key) return source == key end, function(key)
        source = key
        status:SetText("Copy " .. key .. " into " .. AmmoLeftDB.profile .. "?")
    end)
    Button(panel, "Confirm copy", 146, -190, 126, function()
        if source and source ~= AmmoLeftDB.profile then
            addon.CopyProfile(source)
            status:SetText("Copied " .. source .. " into " .. AmmoLeftDB.profile .. ".")
        end
    end)

    local positionSource
    Label(panel, "Copy positions", 16, -243)
    Dropdown(panel, 146, -237, 260, function()
        return ProfileChoices(AmmoLeftProfiles.positions, addon.characterKey)
    end, function(key) return positionSource == key end, function(key) positionSource = key end)
    Button(panel, "Copy positions", 146, -271, 126, function()
        if positionSource then
            addon.CopyPositions(positionSource)
            status:SetText("Positions copied from " .. positionSource .. ".")
        end
    end)
    panel:SetScript("OnShow", Sync)
    return Settings.RegisterCanvasLayoutSubcategory(parent, panel, "Profiles")
end

local function RegisterRestock(parent)
    local panel = Panel()
    Label(panel, "Restock", 16, -16, "GameFontNormalLarge")
    Label(panel, "Restock buys bundles of your selected ammunition.", 16, -45)
    Label(panel, "Mode", 16, -83)
    local modes = {
        { key = "off", label = "Off" }, { key = "manual", label = "Manual" }, { key = "auto", label = "Auto" },
    }
    local mode = addon.options.restockMode
    local dropdown = Dropdown(panel, 157, -78, 180, function() return modes end,
        function(key) return mode == key end, function(key) mode = key end)
    Label(panel, "Ammo target", 16, -121)
    local target = NumberBox(panel, 162, -114)
    Label(panel, "Auto cap (copper)", 16, -158)
    local cap = NumberBox(panel, 162, -151)
    Label(panel, "100 copper = 1 silver. The cap applies per merchant visit.", 16, -187, "GameFontHighlightSmall")
    local status = Label(panel, "", 16, -252)
    Button(panel, "Apply restock", 16, -215, 125, function()
        local amount, limit = tonumber(target:GetText()), tonumber(cap:GetText())
        if not amount or amount < 1 or amount % 1 ~= 0 or not limit or limit < 0 or limit % 1 ~= 0
            or (mode == "auto" and limit == 0) then
            status:SetText("Enter a positive ammo target and a positive cap for Auto.")
            return
        end
        addon.options.restockMode, addon.options.restockTarget, addon.options.restockCap = mode, amount, limit
        addon.RestockOptionsChanged()
        status:SetText("Restock settings saved.")
    end)
    panel:SetScript("OnShow", function()
        mode = addon.options.restockMode
        dropdown:GenerateMenu()
        target:SetText(tostring(addon.options.restockTarget))
        cap:SetText(tostring(addon.options.restockCap))
        status:SetText("")
    end)
    return Settings.RegisterCanvasLayoutSubcategory(parent, panel, "Restock")
end

function addon.RegisterSettings()
    local panel = Panel()
    local title = C_AddOns.GetAddOnMetadata(addonName, "Title")
    local version = C_AddOns.GetAddOnMetadata(addonName, "Version")
    local author = C_AddOns.GetAddOnMetadata(addonName, "Author")
    Label(panel, title, 16, -16, "GameFontNormalLarge")
    Label(panel, version .. " by " .. author, 16, -42, "GameFontHighlightSmall")
    Label(panel, "Alt + left-drag moves the counter.", 16, -61, "GameFontHighlightSmall")

    Label(panel, "Count colors", 16, -91, "GameFontNormal")
    local swatches = {}
    local SyncPreview
    for i, entry in ipairs({
        { key = "normalColor", label = "Normal" },
        { key = "lowColor", label = "Low" },
        { key = "criticalColor", label = "Critical" },
    }) do
        local key = entry.key
        local x = 16 + (i - 1) * 118
        local button = Button(panel, entry.label, x, -111, 106, function()
            local previous = addon.options[key]
            local r, g, b = unpack(previous)
            ColorPickerFrame:SetupColorPickerAndShow({
                r = r, g = g, b = b, hasOpacity = false,
                swatchFunc = function()
                    addon.options[key] = { ColorPickerFrame:GetColorRGB() }
                    addon.Apply()
                    SyncPreview()
                    swatches[key]:SetVertexColor(unpack(addon.options[key]))
                end,
                cancelFunc = function()
                    addon.options[key] = previous
                    addon.Apply()
                    SyncPreview()
                    swatches[key]:SetVertexColor(unpack(previous))
                end,
            })
        end)
        local swatch = button:CreateTexture(nil, "OVERLAY")
        swatch:SetColorTexture(1, 1, 1)
        swatch:SetSize(10, 10)
        swatch:SetPoint("LEFT", 9, 0)
        swatches[key] = swatch
    end

    Label(panel, "Ammo thresholds", 16, -153, "GameFontNormal")
    Label(panel, "Low", 16, -178)
    Label(panel, "Critical", 133, -178)
    local lowBox = NumberBox(panel, 21, -195)
    local criticalBox = NumberBox(panel, 138, -195)
    local errorText = Label(panel, "", 16, -223)
    errorText:SetTextColor(1, 0.34, 0.30)

    local function SaveThresholds()
        local low, critical = tonumber(lowBox:GetText()), tonumber(criticalBox:GetText())
        if not low or not critical or critical < 0 or critical >= low
            or low > 999999999 or low % 1 ~= 0 or critical % 1 ~= 0 then
            errorText:SetText("Enter whole numbers with Critical below Low.")
            return
        end
        lowBox:ClearFocus()
        criticalBox:ClearFocus()
        errorText:SetText("")
        addon.options.low, addon.options.critical = low, critical
        addon.Apply(true)
    end

    Button(panel, "Apply thresholds", 244, -195, 126, SaveThresholds)
    lowBox:SetScript("OnEnterPressed", SaveThresholds)
    criticalBox:SetScript("OnEnterPressed", SaveThresholds)

    Label(panel, "Appearance", 16, -252, "GameFontNormal")
    Label(panel, "Counter preview", 16, -374, "GameFontNormal")
    Label(panel, "Sample ammo count", 16, -393, "GameFontHighlightSmall")
    local preview = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    preview:SetPoint("LEFT", panel, "TOPLEFT", 142, -384)
    local previewIcon = preview:CreateTexture(nil, "ARTWORK")
    previewIcon:SetPoint("LEFT", 6, 0)
    previewIcon:SetTexture(C_AddOns.GetAddOnMetadata(addonName, "IconTexture"))
    local previewCount = preview:CreateFontString(nil, "OVERLAY", "NumberFontNormalLarge")
    previewCount:SetPoint("RIGHT", -7, 0)
    previewCount:SetText("1,350")
    local previewFont, previewSize, previewFlags = previewCount:GetFont()
    SyncPreview = function()
        local scale = addon.options.size / 100
        preview:SetSize(104 * scale, 38 * scale)
        previewIcon:SetSize(26 * scale, 26 * scale)
        previewCount:SetFont(previewFont, previewSize * scale, previewFlags)
        previewCount:SetTextColor(unpack(addon.options.normalColor))
        addon.StylePanel(preview, addon.options.opacity / 100)
    end

    local syncing = false
    local function Slider(key, title, y, minimum, maximum)
        Label(panel, title, 16, y - 5)
        local slider = CreateFrame("Slider", nil, panel, "MinimalSliderWithSteppersTemplate")
        slider:SetPoint("TOPLEFT", 142, y)
        slider:SetSize(132, 24)
        local right = MinimalSliderWithSteppersMixin.Label.Right
        slider:Init(addon.options[key], minimum, maximum, maximum - minimum, {
            [right] = CreateMinimalSliderFormatter(right, function(value)
                return string.format("%.0f%%", value)
            end),
        })
        slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
            if not syncing then
                addon.options[key] = math.floor(value + 0.5)
                addon.Apply()
                SyncPreview()
            end
        end)
        return slider
    end

    local size = Slider("size", "Counter size", -279, 75, 150)
    local opacity = Slider("opacity", "Background opacity", -316, 0, 100)

    local function SyncControls()
        for key, swatch in pairs(swatches) do
            swatch:SetVertexColor(unpack(addon.options[key]))
        end
        lowBox:SetText(tostring(addon.options.low))
        criticalBox:SetText(tostring(addon.options.critical))
        errorText:SetText("")
        syncing = true
        size:SetValue(addon.options.size)
        opacity:SetValue(addon.options.opacity)
        syncing = false
        SyncPreview()
    end

    Button(panel, "Restore defaults", 16, -433, 133, function()
        addon.ResetOptions()
        SyncControls()
    end)
    panel:SetScript("OnShow", SyncControls)
    addon.category = Settings.RegisterCanvasLayoutCategory(panel, title)
    local popupCategory = RegisterPopupSettings(addon.category)
    local profilesCategory = RegisterProfiles(addon.category)
    local restockCategory = RegisterRestock(addon.category)
    for index, entry in ipairs({
        { "Alerts", popupCategory }, { "Profiles", profilesCategory }, { "Restock", restockCategory },
    }) do
        local destination = entry[2]
        Button(panel, entry[1], 160 + (index - 1) * 88, -433, 82, function()
            Settings.OpenToCategory(destination:GetID())
        end)
    end
    Settings.RegisterAddOnCategory(addon.category)
end
