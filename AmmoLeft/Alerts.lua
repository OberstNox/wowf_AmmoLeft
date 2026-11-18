local _, addon = ...

local defaultMessages = { low = "Low ammo!", critical = "Critical ammo!" }

local popup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
popup:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
popup:SetBackdropColor(0.035, 0.075, 0.060, 0.93)
popup:SetSize(380, 100)
popup:SetFrameStrata("TOOLTIP")
popup:SetMovable(true)
popup:SetClampedToScreen(true)
popup:RegisterForDrag("LeftButton")
popup:Hide()

local text = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
text:SetPoint("LEFT", 12, 0)
text:SetPoint("RIGHT", -12, 0)
text:SetHeight(64)
text:SetJustifyH("CENTER")

local done = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
done:SetSize(130, 24)
done:SetPoint("BOTTOM")
done:SetText("Done moving")
done:Hide()

local timer, activeLevel, moving, dragging

local function CancelTimer()
    if timer then
        timer:Cancel()
        timer = nil
    end
end

local function Place()
    local x, y = AmmoLeftDB.popupX, AmmoLeftDB.popupY
    popup:ClearAllPoints()
    if type(x) == "number" and type(y) == "number" then
        popup:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
    else
        popup:SetPoint("TOP", UIParent, "TOP", 0, -120)
    end
end

local function SetMessage(level, count)
    local message = addon.options[level .. "Message"]:match("^%s*(.-)%s*$")
    if message == "" then
        message = defaultMessages[level]
    end
    message = message:gsub("{count}", tostring(count or addon.options[level]))
    text:SetText((message:gsub("|", "||")))
    text:SetTextColor(unpack(addon.options[level .. "Color"]))
    popup:SetBackdropBorderColor(unpack(addon.options[level .. "Color"]))
end

local function ShowAlert(level, preview, count)
    if moving or (not preview and level == "low" and activeLevel == "critical") then
        return
    end
    CancelTimer()
    Place()
    SetMessage(level, count)
    activeLevel = level
    popup:Show()
    timer = C_Timer.NewTimer(addon.options[level .. "Duration"], function()
        timer, activeLevel = nil, nil
        popup:Hide()
    end)
end

function addon.Notify(level, count)
    local enabled = addon.options[level .. "Popup"]
    if enabled then
        ShowAlert(level, false, count)
    end
    if enabled or level == "critical" then
        addon.PlayWarning(level)
    end
    if addon.options[level .. "Pulse"] then addon.PulseCounter(level) end
end

function addon.PreviewAlert(level)
    addon.StopMovingAlert()
    ShowAlert(level, true)
    addon.PlayWarning(level)
    if addon.options[level .. "Pulse"] then addon.PulseCounter(level) end
end

local function StopDrag(self)
    if not dragging then
        return
    end
    dragging = nil
    self:StopMovingOrSizing()
    local x, y = self:GetCenter()
    if x and y then
        AmmoLeftDB.popupX = x - UIParent:GetLeft()
        AmmoLeftDB.popupY = y - UIParent:GetBottom()
        addon.SavePositions()
    end
end

function addon.StartMovingAlert()
    if moving then
        return
    end
    CancelTimer()
    activeLevel = nil
    moving = true
    Place()
    SetMessage("low")
    popup:EnableMouse(true)
    done:Show()
    popup:Show()
end

function addon.StopMovingAlert()
    if moving then
        StopDrag(popup)
        moving = nil
        popup:EnableMouse(false)
        done:Hide()
        popup:Hide()
    end
end

popup:EnableMouse(false)
popup:SetScript("OnDragStart", function(self)
    if moving then
        dragging = true
        self:StartMoving()
    end
end)
popup:SetScript("OnDragStop", StopDrag)
done:SetScript("OnClick", addon.StopMovingAlert)
