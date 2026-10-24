local G = GLOBAL
local island, point, forbidden, reject = SIS.GetIsland, SIS.Position, SIS.IsForbidden, SIS.Reject

local world_exits={}
for _,name in ipairs({"volcano","volcano_exit","shipwrecked_entrance","shipwrecked_exit","portal_shipwrecked",
    "teleportato","teleportato_sw","teleportato_hamlet","porkland_entrance","porkland_exit",
    "pig_ruins_entrance","cave_entrance","cave_entrance_open","cave_exit","adventure_portal"}) do
    world_exits[name]=true
end
local function exit(e) return e and world_exits[e.prefab] end

-- Suppress both mouse hover landing actions and controller landing actions.
local function bad_action(a)
    if not a or not island() then return false end
    if a.action == G.ACTIONS.DISMOUNT or a.action == G.ACTIONS.BLINK then
        return forbidden(a.pos)
    end
    if (G.ACTIONS.MOUNT and a.action==G.ACTIONS.MOUNT) or
       (G.ACTIONS.SEARCH and a.action==G.ACTIONS.SEARCH) then
        local p=point(a.target)
        local c=island()
        return c and c.ready and p and not c:CanSail(p.x,p.z) and forbidden(p)
    end
    if (G.ACTIONS.TRAVEL and a.action==G.ACTIONS.TRAVEL) or
       (G.ACTIONS.ACTIVATE and a.action==G.ACTIONS.ACTIVATE) then return exit(a.target) end
    if G.ACTIONS.JUMPIN and a.action==G.ACTIONS.JUMPIN then
        local t=a.target and a.target.components.teleporter
        return exit(a.target) or (t and forbidden(point(t.targetTeleporter)))
    end
    return false
end
SIS.AddComponentPostInit("playeractionpicker", function(c)
    for _, name in ipairs({"GetClickActions", "GetRightClickActions"}) do
        local old = c[name]
        c[name] = function(self, ...)
            local list = old(self, ...)
            if list then
                for i = #list, 1, -1 do
                    if bad_action(list[i]) then table.remove(list, i) end
                end
            end
            return list
        end
    end
end)
SIS.AddComponentPostInit("playercontroller", function(c)
    local old = c.GetGroundUseAction
    if old then
        c.GetGroundUseAction = function(self, ...)
            local l,r = old(self, ...)
            return not bad_action(l) and l or nil, not bad_action(r) and r or nil
        end
    end
end)
for _, name in ipairs({"DISMOUNT", "BLINK", "TRAVEL", "ACTIVATE", "JUMPIN", "MOUNT", "SEARCH"}) do
    local a = G.ACTIONS[name]
    if a then
        local old = a.fn
        a.fn = function(act)
            if island() and bad_action(act) then reject(act.doer); return false end
            return old(act)
        end
    end
end
SIS.AddComponentPostInit("locomotor",function(c)
    local old=c.PushAction
    if old then
        c.PushAction=function(self,act,...)
            if island() and bad_action(act) then reject(self.inst); return false end
            return old(self,act,...)
        end
    end
end)
SIS.AddComponentPostInit("blinkstaff",function(c)
    local old=c.CanBlinkToPoint
    c.CanBlinkToPoint=function(self,pos,...)
        if forbidden(pos) then return false end
        return old(self,pos,...)
    end
end)
SIS.AddComponentPostInit("activatable",function(c)
    local old=c.DoActivate
    c.DoActivate=function(self,doer,...)
        if island() and exit(self.inst) then reject(doer or G.GetPlayer()); return false end
        return old(self,doer,...)
    end
end)
SIS.AddComponentPostInit("driver", function(c)
    local old = c.OnDismount
    c.OnDismount = function(self, death, pos, boat_to_boat)
        if not death and not boat_to_boat and forbidden(pos or point(self.inst)) then
            reject(self.inst); return false
        end
        return old(self, death, pos, boat_to_boat)
    end
    for _,name in ipairs({"OnMount","OnSearch"}) do
        local mount=c[name]
        if mount then
            c[name]=function(self,target,...)
                local home,pos=island(),point(target)
                if home and home.ready and pos and forbidden(pos) and not home:CanSail(pos.x,pos.z) then
                    reject(self.inst); return false
                end
                return mount(self,target,...)
            end
        end
    end
end)

-- Keep native teleporter callbacks, random offsets and follower handling.
SIS.AddComponentPostInit("teleporter", function(c)
    local activate, teleport = c.Activate, c.Teleport
    c.Activate = function(self, doer, ...)
        if doer and doer:HasTag("player") and forbidden(point(self.targetTeleporter)) then
            reject(doer)
            return false
        end
        return activate(self, doer, ...)
    end
    c.Teleport = function(self, obj, ...)
        local result = teleport(self, obj, ...)
        if obj and obj._sis_validate_position then obj._sis_validate_position() end
        return result
    end
end)

-- Doors use the interior spawner's Physics teleport, bypassing Entity:Teleport.
-- Preserve the native room/camera transition and move followers with the same
-- corrected exterior destination if an exit points to a forbidden island.
SIS.AddComponentPostInit("interiorspawner", function(c)
    local execute=c.ExecuteTeleport
    if not execute then return end
    c.ExecuteTeleport=function(self,doer,destination,direction,...)
        local home=island()
        if home and home.ready and doer and doer:HasTag("player") then
            local pos=destination and (destination.prefab and point(destination) or destination)
            if forbidden(pos) then
                local safe=home:GetSafePoint(doer,false)
                if not safe then return false end
                destination=G.Vector3(safe[1],0,safe[2])
            end
        end
        return execute(self,doer,destination,direction,...)
    end
end)
