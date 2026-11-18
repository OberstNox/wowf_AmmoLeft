local _, class = UnitClass("player")
if class ~= "HUNTER" then
    return
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
countText:SetPoint("LEFT", icon, "RIGHT", 7, 0)
countText:SetPoint("RIGHT", frame, "RIGHT", -7, 0)
countText:SetJustifyH("RIGHT")

local function IsReadable(value)
    return not issecretvalue or not issecretvalue(value)
end

local function Refresh()
    local itemID = GetInventoryItemID("player", ammoSlot)
    local texture = GetInventoryItemTexture("player", ammoSlot)
    local count
    if IsReadable(itemID) and IsReadable(texture) then
        if itemID then
            -- The Forever ammo slot already counts all carried stacks of this item.
            count = GetInventoryItemCount("player", ammoSlot)
        elseif not texture then
            count = 0
        end
    end
    icon:SetTexture(IsReadable(texture) and texture or fallbackTexture)

    if not IsReadable(count) or type(count) ~= "number" then
        countText:SetText("—")
        countText:SetTextColor(0.68, 0.65, 0.59)
        return
    end

    countText:SetText(tostring(count))
    if count <= 50 then
        countText:SetTextColor(1, 0.34, 0.30)
    elseif count <= 200 then
        countText:SetTextColor(1, 0.78, 0.27)
    else
        countText:SetTextColor(0.98, 0.94, 0.85)
    end
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
        Place()
        UpdateMouse()
        self:Show()
        self:UnregisterEvent("PLAYER_LOGIN")
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
    Refresh()
end)

SLASH_AMMOLEFT1 = "/ammoleft"
SlashCmdList.AMMOLEFT = function(message)
    if message:match("^%s*reset%s*$") then
        StopDrag(frame)
        AmmoLeftDB.x, AmmoLeftDB.y = nil, nil
        Place()
    else
        print("AmmoLeft: Alt + left-drag to move. /ammoleft reset restores the default position.")
    end
end
