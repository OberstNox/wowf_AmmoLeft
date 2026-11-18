local _, addon = ...
local rangedSlot = C_PaperDollInfo.GetInventorySlotInfo("RangedSlot")
local readable = addon.IsReadable

local function WeaponAmmo()
    local id = GetInventoryItemID("player", rangedSlot)
    if not readable(id) or not id then return end
    local _, _, _, _, _, class, subtype = C_Item.GetItemInfoInstant(id)
    if class ~= Enum.ItemClass.Weapon then return end
    local weapon = Enum.ItemWeaponSubclass
    local ammo = Enum.ItemProjectileSubclass or { Arrow = 2, Bullet = 3 }
    if subtype == weapon.Guns then return ammo.Bullet end
    if subtype == weapon.Bows or subtype == weapon.Crossbow then return ammo.Arrow end
end

local function Matches(id, ammo)
    local _, _, _, _, _, class, subtype = C_Item.GetItemInfoInstant(id)
    return class == Enum.ItemClass.Projectile and subtype == ammo
end

function addon.RestockItem()
    local item = GetInventoryItemID("player", addon.ammoSlot)
    if not readable(item) then return end
    if not item then
        local texture = GetInventoryItemTexture("player", addon.ammoSlot)
        if not readable(texture) or texture then return end
        item = addon.lastAmmo
    end
    local ammo = WeaponAmmo()
    if item and ammo and Matches(item, ammo) then return item end
end

function addon.ReserveLines(activeItem)
    local ammo = WeaponAmmo()
    local lines = {}
    if not ammo then return lines end
    if activeItem then
        local count = GetInventoryItemCount("player", addon.ammoSlot)
        if readable(count) and type(count) == "number" then
            lines[#lines + 1] = ("Active: %d"):format(count)
        end
    end
    local counts = {}
    for bag = 0, NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local id = C_Container.GetContainerItemID(bag, slot)
            if readable(id) and id and id ~= activeItem and Matches(id, ammo) then
                local info = C_Container.GetContainerItemInfo(bag, slot)
                if readable(info) and info and readable(info.stackCount) then
                    counts[id] = (counts[id] or 0) + info.stackCount
                end
            end
        end
    end
    local reserves = {}
    for id, count in pairs(counts) do
        local name = C_Item.GetItemNameByID(id) or ("Item %d"):format(id)
        reserves[#reserves + 1] = ("%s: %d"):format(name, count)
    end
    table.sort(reserves)
    lines[#lines + 1] = #reserves > 0 and "Compatible reserves" or "No compatible reserves"
    for _, line in ipairs(reserves) do lines[#lines + 1] = line end
    return lines
end

function addon.AmmoCapacity(item)
    local _, _, _, _, _, _, _, stackSize = C_Item.GetItemInfo(item)
    local family = C_Item.GetItemFamily(item)
    if not readable(stackSize) or not stackSize or stackSize < 1 or not readable(family) then return end
    local capacity = 0
    for bag = 0, NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4 do
        local free, bagFamily = C_Container.GetContainerNumFreeSlots(bag)
        if not readable(free) or not readable(bagFamily) then return end
        if free and bagFamily and (bagFamily == 0 or bit.band(family or 0, bagFamily) ~= 0) then
            capacity = capacity + free * stackSize
        end
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local id = C_Container.GetContainerItemID(bag, slot)
            if not readable(id) then return end
            if id == item then
                local info = C_Container.GetContainerItemInfo(bag, slot)
                if not readable(info) or not info or not readable(info.stackCount)
                    or type(info.stackCount) ~= "number" then return end
                capacity = capacity + math.max(0, stackSize - info.stackCount)
            end
        end
    end
    return capacity
end
