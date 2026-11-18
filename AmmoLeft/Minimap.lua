local _, addon = ...

function addon.CreateMinimapButton()
    local button = CreateFrame("Button", "AmmoLeftMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetSize(20, 20)
    background:SetPoint("CENTER")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(18, 18)
    icon:SetPoint("CENTER")
    icon:SetAtlas("Ammunition")

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    local function Position()
        local angle = AmmoLeftDB.minimapAngle or math.rad(220)
        local x, y = math.cos(angle), math.sin(angle)
        if GetMinimapShape and GetMinimapShape() == "SQUARE" then
            local edge = math.max(math.abs(x), math.abs(y))
            x, y = x / edge, y / edge
        end
        button:ClearAllPoints()
        button:SetPoint("CENTER", Minimap, "CENTER",
            x * (Minimap:GetWidth() / 2 + 5), y * (Minimap:GetHeight() / 2 + 5))
    end

    local function TrackCursor()
        local centerX, centerY = Minimap:GetCenter()
        if not centerX or not centerY then
            return
        end
        local scale = Minimap:GetEffectiveScale()
        local cursorX, cursorY = GetCursorPosition()
        local x = (cursorX / scale - centerX) / Minimap:GetWidth()
        local y = (cursorY / scale - centerY) / Minimap:GetHeight()
        AmmoLeftDB.minimapAngle = math.atan2(y, x)
        Position()
    end

    button:SetScript("OnClick", function()
        Settings.OpenToCategory(addon.category:GetID())
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("AmmoLeft")
        GameTooltip:AddLine("Click to open settings", 1, 1, 1)
        GameTooltip:AddLine("Drag to move the button", 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:SetScript("OnDragStart", function(self)
        GameTooltip:Hide()
        self:LockHighlight()
        self:SetScript("OnUpdate", TrackCursor)
    end)
    local function StopDrag(self)
        self:SetScript("OnUpdate", nil)
        self:UnlockHighlight()
    end
    button:SetScript("OnDragStop", StopDrag)
    button:SetScript("OnHide", StopDrag)
    Minimap:HookScript("OnSizeChanged", Position)
    Position()
end
