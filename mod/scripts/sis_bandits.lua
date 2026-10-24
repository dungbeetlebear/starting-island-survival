local G=GLOBAL
if not SIS_HAS_HAMLET then return end
local home = SIS.GetIsland
local function houses(c)
    local count=0
    for _,e in pairs(G.Ents) do
        local name=e.prefab or ""
        local housing=name=="pighouse" or string.sub(name,1,9)=="pighouse_"
            or string.sub(name,1,9)=="pig_shop_" or string.sub(name,1,15)=="pig_guard_tower"
        if housing and name~="pig_shop_spawner" and not string.find(name,"_placer",1,true)
            and e:IsValid() and e:HasTag("structure") and not e:HasTag("burnt") and not e:HasTag("rubble") then
            local x,y,z=e.Transform:GetWorldPosition()
            if c:IsHome(x,z) then
                count=count+1
                if count>=3 then return count end
            end
        end
    end
    return count
end

if SIS_CONFIG.island_bandits then
    SIS.AddPrefabPostInit("shipwrecked",function(w)
        if not w.components.banditmanager then w:AddComponent("banditmanager") end
    end)
end

-- Saved managers still obey the current switch after reloading.
SIS.AddComponentPostInit("banditmanager",function(c)
    local update,chest=c.OnPeriodicUpdate,c.SpawnTreasureChest
    c.GenerateTreasure=function(self,bandit,...)
        local island=home()
        local pt=island and island:GetHomePoint()
        if not pt then return end
        local treasure=G.SpawnPrefab("bandittreasure")
        local map=G.SpawnPrefab("banditmap")
        if not treasure or not map then
            if treasure then treasure:Remove() end
            if map then map:Remove() end
            return
        end
        treasure.Transform:SetPosition(pt[1],0,pt[2])
        self.treasure=treasure
        map.treasure,map.treasureguid=treasure,treasure.GUID
        bandit.components.inventory:GiveItem(map)
    end
    c.SpawnTreasureChest=function(self,pt,...)
        local island=home()
        if not island or not island.ready then return end
        if not pt or not island:IsHome(pt.x,pt.z) then
            local safe=island:GetHomePoint()
            if not safe then return end
            pt=G.Point(safe[1],0,safe[2])
        end
        return chest(self,pt,...)
    end
    c.OnPeriodicUpdate=function(self,dt,...)
        if not SIS_CONFIG.island_bandits or self.disabled then return end
        -- Let Hamlet own cooldowns, money/terrain checks, day/night odds,
        -- cover selection, stealing, escaping and existing-bandit reuse.
        if self.deathtime>0 then return update(self,dt,...) end
        local island,p=home(),G.GetPlayer()
        if not island or not island.ready or not p then return end
        local driver=p.components.driver
        if driver and driver:GetIsDriving() then return end
        local x,y,z=p.Transform:GetWorldPosition()
        if not island:IsHome(x,z) or houses(island)<3 then return end
        return update(self,dt,...)
    end
end)

SIS.AddPrefabPostInit("bandittreasure",function(e)
    local function correct()
        local w=G.GetWorld()
        local manager=w and w.components.banditmanager
        if not manager then return true end
        local c=home()
        if not c or not c.ready then return false end
        local x,y,z=e.Transform:GetWorldPosition()
        if not c:IsHome(x,z) then
            local pt=c:GetHomePoint()
            if not pt then return false end
            e.Transform:SetPosition(pt[1],0,pt[2])
        end
        return true
    end
    local finish=e.components.workable and e.components.workable.onfinish
    if finish then
        e.components.workable.onfinish=function(inst,worker,...)
            if not correct() then return end
            return finish(inst,worker,...)
        end
    end
    local function restored()
        if not e:IsValid() then return end
        if not correct() then e:DoTaskInTime(1,restored) end
    end
    e:DoTaskInTime(0,restored)
end)
