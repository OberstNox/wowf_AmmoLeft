local _, addon = ...

local characterKey
local positionKeys = { "x", "y", "popupX", "popupY", "minimapAngle" }

local function WithDefaults(options)
    local profile = CopyTable(options or {})
    profile.lowSound = profile.lowSound or profile.sound
    profile.criticalSound = profile.criticalSound or profile.sound
    profile.sound = nil
    for key, value in pairs(CopyTable(addon.defaults)) do
        if profile[key] == nil then
            profile[key] = value
        end
    end
    return profile
end

function addon.SavePositions()
    local positions = {}
    for _, key in ipairs(positionKeys) do
        positions[key] = AmmoLeftDB[key]
    end
    AmmoLeftProfiles.positions[characterKey] = positions
end

function addon.InitProfiles()
    AmmoLeftDB = type(AmmoLeftDB) == "table" and AmmoLeftDB or {}
    AmmoLeftProfiles = type(AmmoLeftProfiles) == "table" and AmmoLeftProfiles or {}
    AmmoLeftProfiles.profiles = AmmoLeftProfiles.profiles or {}
    AmmoLeftProfiles.positions = AmmoLeftProfiles.positions or {}
    local name, realm = UnitFullName("player")
    characterKey = name .. " - " .. ((realm and realm ~= "") and realm or GetRealmName())
    addon.characterKey = characterKey
    local profiles = AmmoLeftProfiles.profiles
    if not profiles[AmmoLeftDB.profile] then
        local profileName, suffix = characterKey, 2
        while profiles[profileName] do
            profileName = characterKey .. " (" .. suffix .. ")"
            suffix = suffix + 1
        end
        profiles[profileName] = WithDefaults(AmmoLeftDB.options)
        AmmoLeftDB.profile = profileName
        AmmoLeftDB.options = nil
    end
    addon.options = profiles[AmmoLeftDB.profile]
    addon.SavePositions()
end

function addon.SetProfileOptions(options)
    AmmoLeftProfiles.profiles[AmmoLeftDB.profile] = options
    addon.options = options
    if addon.RestockOptionsChanged then addon.RestockOptionsChanged() end
end

function addon.UseProfile(name)
    local profile = AmmoLeftProfiles.profiles[name]
    if not profile then return end
    AmmoLeftDB.profile = name
    addon.options = profile
    addon.Apply(true)
    if addon.RestockOptionsChanged then addon.RestockOptionsChanged() end
end

function addon.NewProfile(name)
    name = name:match("^%s*(.-)%s*$")
    if name == "" or name:find("|", 1, true) or AmmoLeftProfiles.profiles[name] then
        return false
    end
    local profile = CopyTable(addon.options)
    if profile.restockMode == "auto" then profile.restockMode = "manual" end
    AmmoLeftProfiles.profiles[name] = profile
    addon.UseProfile(name)
    return true
end

function addon.CopyProfile(name)
    local profile = AmmoLeftProfiles.profiles[name]
    if not profile or name == AmmoLeftDB.profile then return end
    local options = CopyTable(profile)
    addon.SetProfileOptions(options)
    addon.Apply(true)
end

function addon.CopyPositions(name)
    local positions = AmmoLeftProfiles.positions[name]
    if not positions then return end
    for _, key in ipairs(positionKeys) do
        AmmoLeftDB[key] = positions[key]
    end
    addon.PlaceCounter()
    if addon.PlaceMinimap then addon.PlaceMinimap() end
    addon.SavePositions()
end
