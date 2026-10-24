-- Preserve deliberate false choices; invalid value types use the default.
local function option(name, default)
    local value = GetModConfigData(name)
    if type(value) ~= type(default) then return default end
    return value
end

SIS_CONFIG = {
    language = option("language", "auto"),
    octopus_no_cooldown = option("octopus_no_cooldown", true),
    gold_guarantee = option("gold_guarantee", true),
    casino_landing = option("casino_landing", false),
    gem_multiplier = option("gem_multiplier", 2),
    season_length = option("season_length", "70_days"),
    coastal_spiderden = option("coastal_spiderden", 1),
    alloy_deconstruction = option("alloy_deconstruction", false),
    fishbone_vacuum = option("fishbone_vacuum", true),
    hamlet_treasure_creatures = option("hamlet_treasure_creatures", false),
    island_bandits = option("island_bandits", false),
    townhall_mayor = option("townhall_mayor", false),
    treasure_materials = option("treasure_materials", false),
    shop_horns = option("shop_horns", false),
}
