local G=GLOBAL
local function home()
    local w=G.GetWorld()
    return w and w.components.sisland
end
local function houses(c)
    local result={}
    for _,e in pairs(G.Ents) do
        local name=e.prefab or ""
        local housing=name=="pighouse" or string.sub(name,1,9)=="pighouse_"
            or string.sub(name,1,9)=="pig_shop_" or string.sub(name,1,15)=="pig_guard_tower"
        if housing and name~="pig_shop_spawner" and not string.find(name,"_placer",1,true)
            and e:IsValid() and e:HasTag("structure") and not e:HasTag("burnt") and not e:HasTag("rubble") then
            local x,y,z=e.Transform:GetWorldPosition()
            if c:IsHome(x,z) then result[#result+1]=e end
        end
    end
    return result
end

if SIS_HAS_HAMLET and SIS_CONFIG.island_bandits then
    AddPrefabPostInit("shipwrecked",function(w)
        if not w.components.banditmanager then w:AddComponent("banditmanager") end
    end)
end

-- Keep this wrapper even with the option off so a saved island manager cannot
-- revert to vanilla city-road spawning when the user disables the feature.
AddComponentPostInit("banditmanager",function(c)
    local update,generate,chest=c.OnPeriodicUpdate,c.GenerateTreasure,c.SpawnTreasureChest
    local save,load=c.OnSave,c.OnLoad
    c._sis_island_mode=SIS_HAS_HAMLET and SIS_CONFIG.island_bandits or false
    c.OnSave=function(self,...)
        local data,refs=save(self,...)
        data=data or {}
        data.sis_island_mode=self._sis_island_mode or nil
        return data,refs
    end
    c.OnLoad=function(self,data,...)
        local result=load(self,data,...)
        self._sis_island_mode=self._sis_island_mode or (data and data.sis_island_mode) or false
        return result
    end
    c.GenerateTreasure=function(self,bandit,...)
        if not self._sis_island_mode then return generate(self,bandit,...) end
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
        if self._sis_island_mode then
            local island=home()
            if not island or not island.ready then return end
            if not pt or not island:IsHome(pt.x,pt.z) then
                local safe=island:GetHomePoint()
                if not safe then return end
                pt=G.Point(safe[1],0,safe[2])
            end
        end
        return chest(self,pt,...)
    end
    c.OnPeriodicUpdate=function(self,dt,...)
        if not self._sis_island_mode then return update(self,dt,...) end
        if not SIS_CONFIG.island_bandits or self.disabled then return end
        -- Let Hamlet own cooldowns, money/terrain checks, day/night odds,
        -- cover selection, stealing, escaping and existing-bandit reuse.
        if self.deathtime>0 then return update(self,dt,...) end
        local island,p=home(),G.GetPlayer()
        if not island or not island.ready or not p then return end
        local driver=p.components.driver
        if driver and driver:GetIsDriving() then return end
        local x,y,z=p.Transform:GetWorldPosition()
        if not island:IsHome(x,z) or #houses(island)<3 then return end
        return update(self,dt,...)
    end
end)

if SIS_HAS_HAMLET then
    AddPrefabPostInit("bandittreasure",function(e)
        local function correct()
            local w=G.GetWorld()
            local manager=w and w.components.banditmanager
            if not manager or not manager._sis_island_mode then return true end
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
end
