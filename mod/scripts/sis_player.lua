local G = GLOBAL
local island, point, forbidden = SIS.GetIsland, SIS.Position, SIS.IsForbidden

-- Transform and Physics are engine userdata: their methods must never be replaced.
-- Filter the Lua teleport entry point, then correct unexpected moves each frame.
SIS.AddPlayerPostInit(function(p)
    local oldteleport = p.Teleport
    if oldteleport then
        p.Teleport = function(self, target, ...)
            local pos = target and (target.GetPosition and target:GetPosition() or target)
            local c=island()
            if c and forbidden(pos) then
                local d=self.components.driver
                local safe=c:GetSafePoint(self,d and d:GetIsDriving())
                if not safe then return false end
                -- Keep the native transition and its costs, using a legal destination.
                target=G.Vector3(safe[1],0,safe[2])
            end
            return oldteleport(self, target, ...)
        end
    end
    local correcting=false
    local function move_to(safe)
        if not safe then return end
        correcting=true
        if p.Physics then
            if p.Physics.ClearMotorVelOverride then p.Physics:ClearMotorVelOverride() end
            if p.Physics.Stop then p.Physics:Stop() end
            p.Physics:Teleport(safe[1],0,safe[2])
        else
            p.Transform:SetPosition(safe[1],0,safe[2])
        end
        if p.components.locomotor then p.components.locomotor:Stop(true) end
        correcting=false
    end
    local function validate_position()
        if correcting then return end
        local c = island()
        if not c or not c.ready then return end
        local x,y,z = p.Transform:GetWorldPosition()
        -- Keep indoor movement, room changes and indoor loads native. Never
        -- overwrite the last outdoor safe point with the shared room origin.
        if c:IsInterior(x,z) then return end
        -- Boat physics can overlap a coastal land tile without disembarking.
        -- Keep vanilla steering there; landing is blocked by the action/driver.
        local d = p.components.driver
        if d and d:GetIsDriving() then
            if c:IsWater(x,z) then p._sis_sea={x,z}; return end
            if c:CanSail(x,z) then return end
            move_to(c:GetSafePoint(p,true))
            return
        end
        if c:IsAllowed(x,z) then
            p._sis_land = {x,z}
        elseif c:IsForbidden(x,z) then
            move_to(c:GetSafePoint(p,false))
        end
    end
    p._sis_validate_position=validate_position
    p:DoPeriodicTask(G.FRAMES,validate_position)
    p:ListenForEvent("newstate",validate_position)
    local save,load=p.OnSave,p.OnLoad
    p.OnSave=function(inst,data,...)
        if save then save(inst,data,...) end
        data.sis_safe_land=inst._sis_land
        data.sis_safe_sea=inst._sis_sea
    end
    p.OnLoad=function(inst,data,...)
        inst._sis_land=data and data.sis_safe_land
        inst._sis_sea=data and data.sis_safe_sea
        local result
        if load then result=load(inst,data,...) end
        validate_position()
        return result
    end
end)

-- Rescue mechanics are preserved, including costs and the next-day penalty.
-- Their beach destination is replaced before supplies/animation are spawned.
SIS.AddPrefabPostInit("beachresurrector", function(e)
    local old = e.doresurrect
    e.doresurrect = function(inst, p, ...)
        local c = island()
        if c and c.ready then
            local x,y,z = inst.Transform:GetWorldPosition()
            if not c:IsAllowed(x,z) then
                local safe=c:GetSafePoint(p,false)
                inst.Transform:SetPosition(safe[1],0,safe[2])
            end
        end
        return old(inst,p,...)
    end
end)
SIS.AddComponentPostInit("resurrector", function(c)
    local old = c.Resurrect
    c.Resurrect = function(self,p,...)
        local home = island()
        if home and home.ready and forbidden(point(self.inst)) then
            -- Vanilla callbacks read the stone/statue position again after a
            -- delay. Move the consumed anchor first so every delayed phase is safe.
            local safe=home:GetSafePoint(p,false)
            self.inst.Transform:SetPosition(safe[1],0,safe[2])
        end
        return old(self,p,...)
    end
end)
