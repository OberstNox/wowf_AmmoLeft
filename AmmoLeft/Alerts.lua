local _, addon = ...

local defaultMessages = { low = "Low ammo!", critical = "Critical ammo!" }

local popup = CreateFrame("Frame", nil, UIParent)
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

local function SetMessage(level)
    local message = addon.options[level .. "Message"]:match("^%s*(.-)%s*$")
    if message == "" then
        message = defaultMessages[level]
    end
    text:SetText((message:gsub("|", "||")))
    text:SetTextColor(unpack(addon.options[level .. "Color"]))
end

local function ShowAlert(level, preview)
    if moving or (not preview and level == "low" and activeLevel == "critical") then
        return
    end
    CancelTimer()
    Place()
    SetMessage(level)
    activeLevel = level
    popup:Show()
    timer = C_Timer.NewTimer(3, function()
        timer, activeLevel = nil, nil
        popup:Hide()
    end)
end

function addon.Notify(level)
    local enabled = addon.options[level .. "Popup"]
    if enabled then
        ShowAlert(level)
    end
    if enabled or level == "critical" then
        addon.PlayWarning()
    end
end

function addon.PreviewAlert(level)
    addon.StopMovingAlert()
    ShowAlert(level, true)
    addon.PlayWarning()
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
