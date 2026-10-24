local G = GLOBAL
SIS = {}

-- modmain also loads in the frontend, before a save/world has been selected.
-- Check at callback time, rather than returning early during mod loading.
function SIS.IsShipwrecked(inst)
    if inst and inst.prefab == "shipwrecked" then return true end
    local world = GLOBAL.GetWorld()
    -- Base-world components (notably interiorspawner) are constructed before
    -- the wrapper prefab assigns "shipwrecked". Use the selected save mode
    -- during that short phase, while still rejecting finished other worlds.
    if world and world.prefab and world.prefab~="world" then
        return world.prefab == "shipwrecked"
    end
    local index = GLOBAL.SaveGameIndex
    return index and index:GetCurrentSaveSlot()
        and index:GetCurrentMode() == "shipwrecked" or false
end

-- Scope this mod's initializers, including those in imported scripts. This
-- changes only this mod's environment, not the game's registration functions.
function SIS.AddComponentPostInit(name, fn)
    AddComponentPostInit(name, function(inst, ...)
        if SIS.IsShipwrecked() then return fn(inst, ...) end
    end)
end
function SIS.AddPrefabPostInit(name, fn)
    AddPrefabPostInit(name, function(inst, ...)
        if SIS.IsShipwrecked(inst) then return fn(inst, ...) end
    end)
end
function SIS.AddPlayerPostInit(fn)
    AddPlayerPostInit(function(inst, ...)
        if SIS.IsShipwrecked() then return fn(inst, ...) end
    end)
end

function SIS.GetIsland()
    local world=G.GetWorld()
    return world and world.prefab=="shipwrecked" and world.components.sisland
end

function SIS.Position(entity)
    if entity and entity.Transform then
        local x,y,z=entity.Transform:GetWorldPosition()
        return {x=x,y=y,z=z}
    end
end

function SIS.IsForbidden(pos)
    local island=SIS.GetIsland()
    return island and pos and island:IsForbidden(pos.x,pos.z)
end

function SIS.Reject(player)
    if player and player.HUD and player.components.talker then
        player.components.talker:Say(SIS_Text(SIS_CONFIG.casino_landing and "home_casino_only" or "home_only"))
    end
end
