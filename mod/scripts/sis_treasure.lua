local G = GLOBAL
G.require("map/treasurehunt")
local hat_depth, loot_depth = 0, 0
local dig_context
local active = SIS.GetIsland
local function scoped(fn, enter, leave, ...)
    enter()
    local result = {G.pcall(fn,...)}
    leave()
    if not result[1] then G.error(result[2]) end
    return G.unpack(result,2)
end
SIS.AddPrefabPostInit("woodlegshat",function(hat)
    local fuel = hat.components.fueled
    local old = fuel and fuel.sectionfn
    if old then
        fuel.sectionfn = function(...)
            if not active() then return old(...) end
            return scoped(old,function() hat_depth=hat_depth+1 end,function() hat_depth=hat_depth-1 end,...)
        end
    end
end)
SIS.AddPrefabPostInit("buriedtreasure",function(t)
    t._sis_hat = hat_depth>0
    local save, load = t.OnSave, t.OnLoad
    t.OnSave = function(inst,data)
        if save then save(inst,data) end
        data.sis_hat = inst._sis_hat or nil
    end
    t.OnLoad = function(inst,data,...)
        inst._sis_hat = data and data.sis_hat or false
        if load then return load(inst,data,...) end
    end
    local work=t.components.workable
    local finish=work and work.onfinish
    if finish then
        work.onfinish=function(inst,worker,...)
            local c=active()
            if not c then
                return finish(inst,worker,...)
            end
            -- All native excavation workers share the home island's counter.
            -- Only home excavations count; casino treasure cannot consume pity.
            local x,y,z=inst.Transform:GetWorldPosition()
            local track=c.ready and c:IsHome(x,z)
            local player=G.GetPlayer()
            local digs=c.treasure_digs
            local gold=c.treasure_gold
            -- Choose the original preset with three guaranteed nuggets; do not
            -- tack an extra gold item onto an otherwise unrelated preset.
            if track and SIS_CONFIG.gold_guarantee and digs==4 and player
                and player.prefab~="wickerbottom" and not gold then inst.loot="gems" end
            local previous=dig_context
            local context={generated=false,gold=false}
            local depth=SIS_DUG_TREASURE_DEPTH or 0
            local result={G.pcall(function(...)
                dig_context=context
                SIS_DUG_TREASURE_DEPTH=depth+1
                return finish(inst,worker,...)
            end,...)}
            dig_context=previous
            SIS_DUG_TREASURE_DEPTH=depth
            if not result[1] then G.error(result[2]) end
            if track and context.generated then
                c.treasure_digs=c.treasure_digs+1
                c.treasure_gold=c.treasure_gold or gold or context.gold
            end
            return G.unpack(result,2)
        end
    end
end)

local olddef = G.GetTreasureLootDefinition
G.GetTreasureLootDefinition = function(name)
    local original = olddef(name)
    if (loot_depth==0 and not dig_context) or not original then return original end
    local copy = {}
    for k,v in pairs(original) do copy[k]=v end
    if dig_context then
        local context,custom=dig_context,original.custom_lootfn
        copy.custom_lootfn=function(loot)
            if custom then custom(loot) end
            SIS_AdjustDugLoot(loot)
            context.generated=true
            context.gold=context.gold or (loot.goldnugget or 0)>0
        end
    end
    if dig_context and SIS_CONFIG.treasure_materials and SIS_HAS_HAMLET and original.random_loot
        and (original.random_loot.papyrus or original.random_loot.rope) then
        copy.random_loot={}
        for k,v in pairs(original.random_loot) do copy.random_loot[k]=v end
        copy.random_loot.clippings=1
        copy.random_loot.lightbulb=1
    end
    if loot_depth>0 and original.chance_loot then
        copy.chance_loot = {}
        for k,v in pairs(original.chance_loot) do
            copy.chance_loot[k] = (k=="yellowgem" or k=="greengem") and math.min(1,SIS_CONFIG.gem_multiplier*v) or v
        end
    end
    if loot_depth>0 and original.random_loot then
        local source=copy.random_loot or original.random_loot
        local total, gems = 0,0
        for k,v in pairs(source) do
            total=total+v
            if k=="yellowgem" or k=="greengem" then gems=gems+v end
        end
        if gems>0 and gems<total then
            copy.random_loot={}
            -- Scale the actual combined probability, capping it at 100%.
            -- Preserve relative weights within gems and within other items.
            local multiplier=math.min(SIS_CONFIG.gem_multiplier,total/gems)
            local other_scale=math.max(0,(total-multiplier*gems)/(total-gems))
            for k,v in pairs(source) do
                local weight=(k=="yellowgem" or k=="greengem") and multiplier*v or v*other_scale
                -- Vanilla can select a zero-weight entry when its random
                -- threshold is zero. Omit capped-out entries entirely.
                if weight>0 then copy.random_loot[k]=weight end
            end
        end
    end
    return copy
end
local spawnchest=G.SpawnTreasureChest
G.SpawnTreasureChest=function(name,dropper,...)
    if active() and dropper and dropper.inst._sis_hat then
        return scoped(spawnchest,function() loot_depth=loot_depth+1 end,function() loot_depth=loot_depth-1 end,name,dropper,...)
    end
    return spawnchest(name,dropper,...)
end
