-- Shared mod-environment settings. Only nil means an option is missing;
-- false is a deliberate choice and must never fall back to the default.
local function option(name, default)
    local value = GetModConfigData(name)
    if value == nil then return default end
    return value
end

SIS_CONFIG = {
    language = option("language", "auto"),
    octopus_no_cooldown = option("octopus_no_cooldown", true),
    gold_guarantee = option("gold_guarantee", true),
    casino_landing = option("casino_landing", false),
    gem_multiplier = option("gem_multiplier", 2),
    season_length = option("season_length", "70_days"),
    coastal_spiderden = option("coastal_spiderden", true),
}

-- modmain also loads in the frontend, before a save/world has been selected.
-- Check at callback time, rather than returning early during mod loading.
SIS_IsShipwrecked = function(inst)
    if inst and inst.prefab == "shipwrecked" then return true end
    local world = GLOBAL.GetWorld()
    if world then return world.prefab == "shipwrecked" end
    local index = GLOBAL.SaveGameIndex
    return index and index:GetCurrentSaveSlot()
        and index:GetCurrentMode() == "shipwrecked" or false
end

-- Scope this mod's initializers, including those in imported scripts. This
-- changes only this mod's environment, not the game's registration functions.
local component, prefab, player = AddComponentPostInit, AddPrefabPostInit, AddPlayerPostInit
AddComponentPostInit = function(name, fn)
    component(name, function(inst, ...)
        if SIS_IsShipwrecked() then return fn(inst, ...) end
    end)
end
AddPrefabPostInit = function(name, fn)
    prefab(name, function(inst, ...)
        if SIS_IsShipwrecked(inst) then return fn(inst, ...) end
    end)
end
AddPlayerPostInit = function(fn)
    player(function(inst, ...)
        if SIS_IsShipwrecked() then return fn(inst, ...) end
    end)
end
