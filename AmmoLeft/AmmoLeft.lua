local addonName, addon = ...
local _, class = UnitClass("player")

local defaults = {
    normalColor = { 0.98, 0.94, 0.85 },
    lowColor = { 1, 0.78, 0.27 },
    criticalColor = { 1, 0.34, 0.30 },
    low = 200,
    critical = 50,
    lowSound = "off", criticalSound = "off",
    lowDuration = 3, criticalDuration = 3,
    lowPulse = false, criticalPulse = false,
    restockMode = "manual", restockTarget = 2000, restockCap = 0,
    size = 100,
    opacity = 86,
    lowPopup = false,
    criticalPopup = false,
    lowMessage = "",
    criticalMessage = "",
}
addon.defaults = defaults
function addon.StylePanel(panel, alpha)
    panel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    panel:SetBackdropColor(0.035, 0.075, 0.060, alpha)
    panel:SetBackdropBorderColor(0.68, 0.51, 0.29, 0.9)
end
addon.sounds = {
    { key = "off", label = "Off" },
    { key = "click", label = "Soft click", kit = SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON },
    { key = "raid", label = "Raid warning", kit = SOUNDKIT.RAID_WARNING },
}

function addon.PlayWarning(level)
    for _, sound in ipairs(addon.sounds) do
        if sound.key == addon.options[(level or "critical") .. "Sound"] and sound.kit then
            PlaySound(sound.kit, "Master")
            return
        end
    end
end

local ammoSlot, emptyTexture = C_PaperDollInfo.GetInventorySlotInfo("AmmoSlot")
local fallbackTexture = emptyTexture or "Interface\\Icons\\INV_Misc_Ammo_Arrow_01"

local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
frame:SetSize(104, 38)
frame:SetFrameStrata("MEDIUM")
frame:SetMovable(true)
frame:SetClampedToScreen(true)
frame:RegisterForDrag("LeftButton")
frame:Hide()

frame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
})
frame:SetBackdropBorderColor(0.68, 0.51, 0.29, 0.9)
local glow = frame:CreateTexture(nil, "OVERLAY")
glow:SetAllPoints()
glow:Hide()
local pulse = glow:CreateAnimationGroup()
local fade = pulse:CreateAnimation("Alpha")
fade:SetFromAlpha(0.32)
fade:SetToAlpha(0)
fade:SetDuration(0.45)
pulse:SetScript("OnFinished", function() glow:Hide() end)
function addon.PulseCounter(level)
    if frame:IsShown() then
        pulse:Stop()
        glow:SetColorTexture(unpack(addon.options[level .. "Color"]))
        glow:Show()
        pulse:Play()
    end
end

local icon = frame:CreateTexture(nil, "ARTWORK")
icon:SetSize(26, 26)
icon:SetPoint("LEFT", 6, 0)
icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

local countText = frame:CreateFontString(nil, "OVERLAY", "NumberFontNormalLarge")
countText:SetJustifyH("RIGHT")
local font, fontSize, fontFlags = countText:GetFont()

local function IsReadable(value)
    return not issecretvalue or not issecretvalue(value)
end
addon.IsReadable = IsReadable
addon.ammoSlot = ammoSlot

local iconHover = CreateFrame("Frame", nil, frame)
iconHover:SetAllPoints(icon)
iconHover:SetMouseClickEnabled(false)
iconHover:SetMouseMotionEnabled(true)

local tooltipItem, tooltipEmpty
local function ShowAmmoTooltip()
    GameTooltip:SetOwner(iconHover, "ANCHOR_RIGHT")
    if tooltipItem then
        GameTooltip:SetItemByID(tooltipItem)
    elseif tooltipEmpty then
        GameTooltip:SetText("No ammunition selected")
    else
        GameTooltip:SetText("Ammunition unavailable")
    end
    for _, line in ipairs(addon.ReserveLines(tooltipItem)) do
        GameTooltip:AddLine(line, 0.84, 0.80, 0.67)
    end
    GameTooltip:Show()
end

local function HideAmmoTooltip()
    if GameTooltip:IsOwned(iconHover) then
        GameTooltip:Hide()
    end
end

iconHover:SetScript("OnEnter", ShowAmmoTooltip)
iconHover:SetScript("OnLeave", HideAmmoTooltip)
iconHover:SetScript("OnHide", HideAmmoTooltip)

local previousItem, previousCount
local function Refresh(silent)
    if class ~= "HUNTER" then
        return
    end
    local options = addon.options
    local itemID = GetInventoryItemID("player", ammoSlot)
    local texture = GetInventoryItemTexture("player", ammoSlot)
    local readableItem = IsReadable(itemID)
    local visibleItem = readableItem and itemID or nil
    if visibleItem then
        addon.lastAmmo = visibleItem
    end
    local empty = readableItem and not itemID and IsReadable(texture) and not texture
    tooltipItem, tooltipEmpty = visibleItem, empty
    if GameTooltip:IsOwned(iconHover) then
        ShowAmmoTooltip()
    end
    local count
    if readableItem then
        if itemID then
            -- The Forever ammo slot already counts all carried stacks of this item.
            count = GetInventoryItemCount("player", ammoSlot)
        elseif empty then
            count = 0
        end
    end
    icon:SetTexture(IsReadable(texture) and texture or fallbackTexture)

    if not IsReadable(count) or type(count) ~= "number" then
        countText:SetText("—")
        countText:SetTextColor(0.68, 0.65, 0.59)
        return
    end

    local warningItem = itemID
    if not itemID and previousItem and count == 0 then
        -- The slot can clear when the final projectile is consumed.
        local remaining = C_Item.GetItemCount(previousItem)
        if IsReadable(remaining) and remaining == 0 then
            warningItem = previousItem
        end
    end
    if not silent and warningItem and previousItem == warningItem then
        if previousCount > options.critical and count <= options.critical then
            addon.Notify("critical", count)
        elseif previousCount > options.low and count <= options.low then
            addon.Notify("low", count)
        end
    end
    previousItem, previousCount = itemID, count

    countText:SetText(tostring(count))
    if count <= options.critical then
        countText:SetTextColor(unpack(options.criticalColor))
    elseif count <= options.low then
        countText:SetTextColor(unpack(options.lowColor))
    else
        countText:SetTextColor(unpack(options.normalColor))
    end
end

local function ApplyAppearance()
    local options = addon.options
    local scale = options.size / 100
    frame:SetSize(104 * scale, 38 * scale)
    frame:SetBackdropColor(0.035, 0.075, 0.060, options.opacity / 100)
    icon:SetSize(26 * scale, 26 * scale)
    icon:ClearAllPoints()
    icon:SetPoint("LEFT", 6 * scale, 0)
    countText:ClearAllPoints()
    countText:SetPoint("LEFT", icon, "RIGHT", 7 * scale, 0)
    countText:SetPoint("RIGHT", frame, "RIGHT", -7 * scale, 0)
    countText:SetFont(font, fontSize * scale, fontFlags)
end

function addon.Apply(baseline)
    ApplyAppearance()
    if baseline then
        previousItem, previousCount = nil, nil
    end
    Refresh(true)
end

function addon.ResetOptions()
    addon.SetProfileOptions(CopyTable(defaults))
    addon.Apply(true)
end

local function Place()
    frame:ClearAllPoints()
    local x, y = AmmoLeftDB.x, AmmoLeftDB.y
    if type(x) == "number" and type(y) == "number" then
        frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
    else
        frame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 180)
    end
end

addon.PlaceCounter = Place

local dragging = false
local function UpdateMouse()
    frame:EnableMouse(dragging or IsAltKeyDown())
end

frame:SetScript("OnDragStart", function(self)
    if IsAltKeyDown() then
        HideAmmoTooltip()
        dragging = true
        self:StartMoving()
    end
end)

local function StopDrag(self)
    if not dragging then
        return
    end
    self:StopMovingOrSizing()
    local x, y = self:GetCenter()
    if x and y then
        AmmoLeftDB.x, AmmoLeftDB.y = x - UIParent:GetLeft(), y - UIParent:GetBottom()
    end
    dragging = false
    UpdateMouse()
    addon.SavePositions()
end

frame:SetScript("OnDragStop", StopDrag)
frame:SetScript("OnHide", StopDrag)

local function UpdateCounterVisibility()
    local onTaxi = UnitOnTaxi("player")
    if IsReadable(onTaxi) then
        frame:SetShown(not onTaxi)
    end
end

frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        addon.InitProfiles()
        addon.RegisterSettings()
        self:UnregisterEvent("PLAYER_LOGIN")
        if class ~= "HUNTER" then
            return
        end
        addon.CreateMinimapButton()
        addon.InitRestock()
        Place()
        ApplyAppearance()
        UpdateMouse()
        UpdateCounterVisibility()
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
        self:RegisterEvent("PLAYER_CONTROL_LOST")
        self:RegisterEvent("PLAYER_CONTROL_GAINED")
        self:RegisterEvent("BAG_UPDATE_DELAYED")
        self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
        self:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player")
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        self:RegisterEvent("MODIFIER_STATE_CHANGED")
    elseif event == "PLAYER_ENTERING_WORLD" then
        UpdateCounterVisibility()
    elseif event == "PLAYER_CONTROL_LOST" or event == "PLAYER_CONTROL_GAINED" then
        UpdateCounterVisibility()
        -- Taxi status can lag behind the control event.
        C_Timer.After(0.25, UpdateCounterVisibility)
        return
    elseif event == "MODIFIER_STATE_CHANGED" then
        UpdateMouse()
        return
    end
    Refresh(event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD")
end)

SLASH_AMMOLEFT1 = "/ammoleft"
SlashCmdList.AMMOLEFT = function(message)
    if message:match("^%s*reset%s*$") then
        StopDrag(frame)
        AmmoLeftDB.x, AmmoLeftDB.y = nil, nil
        Place()
        addon.SavePositions()
    else
        Settings.OpenToCategory(addon.category:GetID())
    end
end
