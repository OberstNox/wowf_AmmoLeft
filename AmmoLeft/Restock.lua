local _, addon = ...
local readable = addon.IsReadable
local panel, summary, button
local visit, order, displayed, waiting, merchantHooked

local function FormatCost(copper)
    return C_CurrencyInfo.GetCoinTextureString(copper)
end

local function Number(value)
    if readable(value) and type(value) == "number" then return value end
end

local function Quote()
    local item = addon.RestockItem()
    if not item then return nil, "Select compatible ammunition first." end
    local target = addon.options.restockTarget
    local carried = Number(C_Item.GetItemCount(item))
    if not carried then return nil, "Waiting for ammunition data." end
    if carried >= target then return nil, ("%d / %d ammo · Stocked"):format(carried, target) end
    for index = 1, GetMerchantNumItems() do
        local id = GetMerchantItemID(index)
        if Number(id) == item then
            local info = C_MerchantFrame.GetItemInfo(index)
            if not readable(info) or not info then return nil, "Waiting for merchant data.", true end
            local price, bundle, stock = Number(info.price), Number(info.stackCount), Number(info.numAvailable)
            local maxUnits = Number(GetMerchantItemMaxStack(index))
            if not price or price < 0 or not bundle or bundle < 1 or not stock or not maxUnits then
                return nil, "Waiting for merchant data.", true
            end
            if not readable(info.isPurchasable) or not readable(info.isUsable)
                or not readable(info.hasExtendedCost) or not readable(info.currencyID)
                or not info.isPurchasable or not info.isUsable or info.hasExtendedCost or info.currencyID then
                return nil, "This ammunition is unavailable for a coin purchase."
            end
            local room, money = addon.AmmoCapacity(item), Number(GetMoney())
            if not room or not money then return nil, "Waiting for inventory data.", true end
            local wanted = math.ceil((target - carried) / bundle)
            local count = math.min(wanted, math.floor(room / bundle))
            if stock >= 0 then count = math.min(count, math.floor(stock / bundle)) end
            if price > 0 then count = math.min(count, math.floor(money / price)) end
            local perCall = math.floor(maxUnits / bundle)
            if count < 1 or perCall < 1 then return nil, "No full bundle available or affordable." end
            return { item = item, index = index, count = count, wanted = wanted, carried = carried,
                bundle = bundle, price = price, perCall = perCall, target = target,
                name = C_Item.GetItemNameByID(item) or "Ammunition" }
        end
    end
    return nil, "This merchant does not sell your selected ammunition."
end

local function Finish(reason)
    local finished = order
    order = nil
    if finished then
        local message = ("Confirmed: %d ammo for %s."):format(finished.units, FormatCost(finished.spent))
        if reason then message = message .. " " .. reason end
        print("Ammoleft Forever: " .. message)
        if visit then
            visit.result = message
            if finished.pending then visit.unconfirmed = true end
        end
    end
end

local function SendNext()
    local current = order
    if not current or current.pending then return end
    if not visit or not MerchantFrame:IsShown() or MerchantFrame.selectedTab == 2 then
        Finish("Merchant window changed.")
        return
    end
    local q = Quote()
    if not q or q.item ~= current.item or q.index ~= current.index or q.price ~= current.price
        or q.bundle ~= current.bundle or q.carried ~= current.lastCount then
        Finish("Stock or purchase terms changed.")
        return
    end
    local bundles = math.min(q.perCall, current.remaining)
    if q.count < current.remaining or (current.cap and current.spent + bundles * q.price > current.cap) then
        Finish("The remaining purchase is unavailable.")
        return
    end
    current.pending = bundles
    current.before = q.carried
    BuyMerchantItem(q.index, bundles * q.bundle)
    C_Timer.After(2, function()
        if order == current and current.pending == bundles and current.before == q.carried then
            Finish("Purchase confirmation timed out.")
            addon.RefreshRestock()
        end
    end)
end

local function Start(q, cap)
    visit.result = nil
    order = { item = q.item, index = q.index, price = q.price, bundle = q.bundle,
        remaining = q.count, units = 0, spent = 0, cap = cap, lastCount = q.carried }
    SendNext()
end

function addon.RefreshRestock()
    if not visit or not MerchantFrame or not MerchantFrame:IsShown()
        or MerchantFrame.selectedTab == 2 or addon.options.restockMode == "off" then
        displayed = nil
        waiting = false
        panel:Hide()
        return
    end
    panel:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", 4, -24)
    panel:Show()
    if order then
        displayed = nil
        summary:SetText("Restocking…")
        button:Disable()
        return
    end
    if visit.unconfirmed then
        displayed = nil
        summary:SetText(visit.result)
        button:Disable()
        return
    end
    local q, reason, retry = Quote()
    waiting = retry
    displayed = q
    if q then
        summary:SetText(("%s\n%d / %d ammo · Need %d\nBuy %d for %s%s"):format(q.name, q.carried, q.target,
            q.target - q.carried, q.count * q.bundle, FormatCost(q.count * q.price),
            q.count < q.wanted and " (partial)" or ""))
    else
        summary:SetText(visit.result or reason)
    end
    button:SetEnabled(q ~= nil)
end

function addon.RestockOptionsChanged()
    if not visit then return end
    visit.autoAttempted = true
    Finish("Restock settings changed.")
    addon.RefreshRestock()
end

function addon.InitRestock()
    panel = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    panel:SetSize(230, 138)
    panel:SetFrameStrata("DIALOG")
    panel:SetClampedToScreen(true)
    addon.StylePanel(panel, 0.97)
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 14, -12)
    title:SetText("Ammo restock")
    summary = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    summary:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    summary:SetPoint("RIGHT", -12, 0)
    summary:SetJustifyH("LEFT")
    button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    button:SetPoint("BOTTOMLEFT", 12, 10)
    button:SetSize(104, 24)
    button:SetText("Restock")
    button:SetScript("OnClick", function()
        if order or not visit or not displayed or not MerchantFrame:IsShown() or MerchantFrame.selectedTab == 2 then return end
        local q = Quote()
        if not q or q.item ~= displayed.item or q.index ~= displayed.index or q.count ~= displayed.count
            or q.bundle ~= displayed.bundle or q.price ~= displayed.price then
            addon.RefreshRestock()
            return
        end
        visit.autoAttempted = true
        Start(q)
        addon.RefreshRestock()
    end)
    panel:Hide()

    local events = CreateFrame("Frame")
    for _, event in ipairs({ "MERCHANT_SHOW", "MERCHANT_CLOSED", "MERCHANT_UPDATE", "BAG_UPDATE_DELAYED",
        "PLAYER_MONEY", "PLAYER_EQUIPMENT_CHANGED", "ITEM_DATA_LOAD_RESULT" }) do events:RegisterEvent(event) end
    events:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player")
    events:SetScript("OnEvent", function(_, event)
        if event == "MERCHANT_SHOW" then
            if not visit then visit = {} end
            if not merchantHooked and MerchantFrame_Update then
                hooksecurefunc("MerchantFrame_Update", addon.RefreshRestock)
                merchantHooked = true
            end
        elseif event == "MERCHANT_CLOSED" then
            Finish("Merchant closed.")
            visit, displayed = nil, nil
        end
        if order and order.pending and event == "BAG_UPDATE_DELAYED" then
            local count = Number(C_Item.GetItemCount(order.item))
            local expected = order.pending * order.bundle
            local received = count and count - order.before
            if received and received == expected then
                order.units = order.units + expected
                order.spent = order.spent + order.pending * order.price
                order.remaining = order.remaining - order.pending
                order.pending, order.lastCount = nil, count
                if order.remaining == 0 then
                    Finish()
                else
                    local current = order
                    C_Timer.After(0.2, function()
                        if order == current then SendNext() end
                    end)
                end
            elseif received and received ~= 0 then
                Finish("Inventory changed unexpectedly.")
            end
        end
        addon.RefreshRestock()
        if visit and not visit.autoAttempted and addon.options.restockMode == "auto"
            and addon.options.restockCap > 0 and (displayed or not waiting) then
            visit.autoAttempted = true
            local q = displayed
            if q and q.count == q.wanted and q.count * q.price <= addon.options.restockCap then
                Start(q, addon.options.restockCap)
                addon.RefreshRestock()
            end
        end
    end)
end
