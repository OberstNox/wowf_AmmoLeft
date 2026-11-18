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

local function RegisterPopupSettings(parentCategory)
    local panel = CreateFrame("Frame")
    Label(panel, "Pop-up alerts", 16, -16, "GameFontNormalLarge")
    Label(panel, "Leave a message blank to use the default text.", 16, -45, "GameFontHighlightSmall")
    local controls = {}

    for index, entry in ipairs({
        { level = "low", label = "Low" },
        { level = "critical", label = "Critical" },
    }) do
        local level = entry.level
        local y = -72 - (index - 1) * 78
        local enabledKey, messageKey = level .. "Popup", level .. "Message"
        local check = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        check:SetPoint("TOPLEFT", 14, y)
        check:SetScript("OnClick", function(self)
            addon.options[enabledKey] = not not self:GetChecked()
        end)
        Label(panel, entry.label, 46, y - 8)

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
        controls[index] = { check = check, box = box, enabledKey = enabledKey, messageKey = messageKey }
    end

    Button(panel, "Move pop-up", 16, -241, 130, addon.StartMovingAlert)
    Label(panel, "Both alerts use the same position.", 16, -275, "GameFontHighlightSmall")
    panel:SetScript("OnShow", function()
        for _, control in ipairs(controls) do
            control.check:SetChecked(addon.options[control.enabledKey])
            control.box:SetText(addon.options[control.messageKey])
        end
    end)
    panel:SetScript("OnHide", addon.StopMovingAlert)
    return Settings.RegisterCanvasLayoutSubcategory(parentCategory, panel, "Pop-up alerts")
end

function addon.RegisterSettings()
    local panel = CreateFrame("Frame")
    local title = C_AddOns.GetAddOnMetadata(addonName, "Title")
    local version = C_AddOns.GetAddOnMetadata(addonName, "Version")
    local author = C_AddOns.GetAddOnMetadata(addonName, "Author")
    Label(panel, title, 16, -16, "GameFontNormalLarge")
    Label(panel, version .. " by " .. author, 16, -42, "GameFontHighlightSmall")
    Label(panel, "Alt + left-drag moves the counter.", 16, -61, "GameFontHighlightSmall")

    Label(panel, "Count colors", 16, -91, "GameFontNormal")
    local swatches = {}
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
                    swatches[key]:SetVertexColor(unpack(addon.options[key]))
                end,
                cancelFunc = function()
                    addon.options[key] = previous
                    addon.Apply()
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

    Label(panel, "Warning sound", 16, -252, "GameFontNormal")
    local sound = CreateFrame("DropdownButton", nil, panel, "WowStyle1DropdownTemplate")
    sound:SetPoint("TOPLEFT", 16, -271)
    sound:SetWidth(166)
    sound:SetupMenu(function(_, root)
        for _, entry in ipairs(addon.sounds) do
            if entry.key == "off" or entry.kit then
                root:CreateRadio(entry.label, function(key)
                    return addon.options.sound == key
                end, function(key)
                    addon.options.sound = key
                end, entry.key)
            end
        end
    end)
    Button(panel, "Preview sound", 195, -271, 115, addon.PlayWarning)

    local syncing = false
    local function Slider(key, title, y, minimum, maximum)
        Label(panel, title, 16, y - 5)
        local slider = CreateFrame("Slider", nil, panel, "MinimalSliderWithSteppersTemplate")
        slider:SetPoint("TOPLEFT", 142, y)
        slider:SetSize(170, 24)
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
            end
        end)
        return slider
    end

    local size = Slider("size", "Counter size", -311, 75, 150)
    local opacity = Slider("opacity", "Background opacity", -344, 0, 100)

    local function SyncControls()
        for key, swatch in pairs(swatches) do
            swatch:SetVertexColor(unpack(addon.options[key]))
        end
        lowBox:SetText(tostring(addon.options.low))
        criticalBox:SetText(tostring(addon.options.critical))
        errorText:SetText("")
        sound:GenerateMenu()
        syncing = true
        size:SetValue(addon.options.size)
        opacity:SetValue(addon.options.opacity)
        syncing = false
    end

    Button(panel, "Restore defaults", 16, -387, 133, function()
        addon.ResetOptions()
        SyncControls()
    end)
    panel:SetScript("OnShow", SyncControls)
    addon.category = Settings.RegisterCanvasLayoutCategory(panel, title)
    local popupCategory = RegisterPopupSettings(addon.category)
    Button(panel, "Pop-up alerts", 160, -387, 133, function()
        Settings.OpenToCategory(popupCategory:GetID())
    end)
    Settings.RegisterAddOnCategory(addon.category)
end
