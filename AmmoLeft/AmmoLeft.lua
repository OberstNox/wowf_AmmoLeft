local addonName, addon = ...
local _, class = UnitClass("player")

local defaults = {
    normalColor = { 0.98, 0.94, 0.85 },
    lowColor = { 1, 0.78, 0.27 },
    criticalColor = { 1, 0.34, 0.30 },
    low = 200,
    critical = 50,
    sound = "off",
    size = 100,
    opacity = 86,
}
addon.defaults = defaults
addon.sounds = {
    { key = "off", label = "Off" },
    { key = "click", label = "Soft click", kit = SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON },
    { key = "raid", label = "Raid warning", kit = SOUNDKIT.RAID_WARNING },
}

function addon.PlayWarning()
    for _, sound in ipairs(addon.sounds) do
        if sound.key == addon.options.sound and sound.kit then
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
frame:SetBackdropColor(0.055, 0.046, 0.038, 0.86)
frame:SetBackdropBorderColor(0.55, 0.43, 0.26, 0.9)

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

local previousItem, previousCount
local function Refresh(silent)
    if class ~= "HUNTER" then
        return
    end
    local options = addon.options
    local itemID = GetInventoryItemID("player", ammoSlot)
    local texture = GetInventoryItemTexture("player", ammoSlot)
    local readableItem = IsReadable(itemID)
    local count
    if readableItem then
        if itemID then
            -- The Forever ammo slot already counts all carried stacks of this item.
            count = GetInventoryItemCount("player", ammoSlot)
        elseif IsReadable(texture) and not texture then
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
    if not silent and warningItem and previousItem == warningItem
        and previousCount > options.critical and count <= options.critical then
        addon.PlayWarning()
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
    frame:SetBackdropColor(0.055, 0.046, 0.038, options.opacity / 100)
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
    AmmoLeftDB.options = CopyTable(defaults)
    addon.options = AmmoLeftDB.options
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

local dragging = false
local function UpdateMouse()
    frame:EnableMouse(dragging or IsAltKeyDown())
end

frame:SetScript("OnDragStart", function(self)
    if IsAltKeyDown() then
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
end

frame:SetScript("OnDragStop", StopDrag)
frame:SetScript("OnHide", StopDrag)

frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        AmmoLeftDB = type(AmmoLeftDB) == "table" and AmmoLeftDB or {}
        AmmoLeftDB.options = type(AmmoLeftDB.options) == "table" and AmmoLeftDB.options or {}
        addon.options = AmmoLeftDB.options
        for key, value in pairs(defaults) do
            if addon.options[key] == nil then
                addon.options[key] = type(value) == "table" and CopyTable(value) or value
            end
        end
        addon.RegisterSettings()
        self:UnregisterEvent("PLAYER_LOGIN")
        if class ~= "HUNTER" then
            return
        end
        addon.CreateMinimapButton()
        Place()
        ApplyAppearance()
        UpdateMouse()
        self:Show()
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
        self:RegisterEvent("BAG_UPDATE_DELAYED")
        self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
        self:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player")
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        self:RegisterEvent("MODIFIER_STATE_CHANGED")
    elseif event == "MODIFIER_STATE_CHANGED" then
        UpdateMouse()
        return
    end
    Refresh(event == "PLAYER_LOGIN")
end)

SLASH_AMMOLEFT1 = "/ammoleft"
SlashCmdList.AMMOLEFT = function(message)
    if message:match("^%s*reset%s*$") then
        StopDrag(frame)
        AmmoLeftDB.x, AmmoLeftDB.y = nil, nil
        Place()
    else
        Settings.OpenToCategory(addon.category:GetID())
    end
end
