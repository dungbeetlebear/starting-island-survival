local G = GLOBAL
modimport("scripts/sis_config.lua")
modimport("scripts/sis_i18n.lua")
local function island()
    local w = G.GetWorld()
    return w and w.prefab == "shipwrecked" and w.components.sisland
end
local function point(e)
    if e and e.Transform then
        local x,y,z = e.Transform:GetWorldPosition()
        return {x=x,y=y,z=z}
    end
end
local function forbidden(pos)
    local c = island()
    return c and pos and c:IsForbidden(pos.x, pos.z)
end
local function reject(p)
    if p and p.HUD and p.components.talker then
        p.components.talker:Say(SIS_Text(SIS_CONFIG.casino_landing and "home_casino_only" or "home_only"))
    end
end
local world_exits={}
for _,name in ipairs({"volcano","volcano_exit","shipwrecked_entrance","shipwrecked_exit","portal_shipwrecked",
    "teleportato","teleportato_sw","teleportato_hamlet","porkland_entrance","porkland_exit",
    "pig_ruins_entrance","cave_entrance","cave_entrance_open","cave_exit","adventure_portal"}) do
    world_exits[name]=true
end
local function exit(e) return e and world_exits[e.prefab] end

AddPrefabPostInit("shipwrecked", function(w)
    w:AddComponent("sisland")
    w.components.sisland.allow_casino = SIS_CONFIG.casino_landing
    w:DoTaskInTime(0, function()
        local s = w.components.seasonmanager
        if s and SIS_CONFIG.season_length == "70_days" then
            s:SetMildLength(20); s:SetWetLength(15)
            s:SetGreenLength(20); s:SetDryLength(15)
            s.seasonmode = "tropical"
        end
    end)
end)

if SIS_CONFIG.casino_landing then
    AddPrefabPostInit("slotmachine", function(e)
        e:DoTaskInTime(0, function()
            local c = island()
            if c and e:IsValid() then
                local x,y,z = e.Transform:GetWorldPosition()
                c:RegisterCasinoIsland(x,z)
            end
        end)
    end)
end

-- The original tropical basehassler uses 0.67 and saves that probability.
-- Apply the rule when created, when restored, and when settings override it.
AddComponentPostInit("basehassler", function(h)
    local function shipwrecked()
        return G.SaveGameIndex and G.SaveGameIndex:IsModeShipwrecked()
    end
    local add, load, override = h.AddHassler, h.OnLoad, h.OverrideAttackChance
    if add then
        h.AddHassler = function(self, name, data, ...)
            if name == "TWISTER" and shipwrecked() then
                local copy = {}
                for k,v in pairs(data) do copy[k]=v end
                copy.chance = 1
                data = copy
            end
            return add(self,name,data,...)
        end
    end
    if load then
        h.OnLoad = function(self, ...)
            local result = load(self,...)
            if shipwrecked() and self.hasslers and self.hasslers.TWISTER then
                self.hasslers.TWISTER.chance = 1
            end
            return result
        end
    end
    if override then
        h.OverrideAttackChance = function(self, name, chance, ...)
            if name == "TWISTER" and shipwrecked() then chance=1 end
            return override(self,name,chance,...)
        end
    end
end)

AddComponentPostInit("seasonmanager", function(s)
    if not s.IsWetSeason then return end
    local old=s.OnDayComplete
    s.OnDayComplete=function(self,...)
        if SIS_CONFIG.season_length == "70_days" and island() and self.seasonmode=="tropical" then
            local len=self:GetSeasonLength()
            -- 15 additions of 1/15 can be 0.9999999999999999. Let the
            -- original transition run on day 15, with all its normal events.
            if len>0 and self.percent_season+1/len>=1-1e-8 then
                self.percent_season=1
            end
        end
        return old(self,...)
    end
end)

-- Suppress both mouse hover landing actions and controller landing actions.
local function bad_action(a)
    if not a then return false end
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
AddComponentPostInit("playeractionpicker", function(c)
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
AddComponentPostInit("playercontroller", function(c)
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
AddComponentPostInit("locomotor",function(c)
    local old=c.PushAction
    if old then
        c.PushAction=function(self,act,...)
            if island() and bad_action(act) then reject(self.inst); return false end
            return old(self,act,...)
        end
    end
end)
AddComponentPostInit("blinkstaff",function(c)
    local old=c.CanBlinkToPoint
    c.CanBlinkToPoint=function(self,pos,...)
        if forbidden(pos) then return false end
        return old(self,pos,...)
    end
end)
AddComponentPostInit("activatable",function(c)
    local old=c.DoActivate
    c.DoActivate=function(self,doer,...)
        if island() and exit(self.inst) then reject(doer or G.GetPlayer()); return false end
        return old(self,doer,...)
    end
end)
AddComponentPostInit("driver", function(c)
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

-- Prevent world exits, including the volcano, before they start saving/travelling.
for name in pairs(world_exits) do
    AddPrefabPostInit(name, function(e)
        local a = e.components.activatable
        if a then
            local old = a.OnActivate
            a.OnActivate = function(inst, doer, ...)
                if island() then reject(doer or G.GetPlayer()); return false end
                if old then return old(inst, doer, ...) end
            end
        end
    end)
end
AddComponentPostInit("teleporter", function(c)
    for _, name in ipairs({"Activate", "Teleport"}) do
        local old = c[name]
        c[name] = function(self, obj, ...)
            local home=island()
            if home and home.ready and obj and obj:HasTag("player") and self.targetTeleporter then
                if name=="Activate" then
                    if forbidden(point(self.targetTeleporter)) then reject(obj); return false end
                else
                    -- Validate the actual random offset, not just the exit center.
                    local x,y,z=self.targetTeleporter.Transform:GetWorldPosition()
                    local a=math.random()*360
                    x,z=x+math.sin(a)*self.offset,z+math.cos(a)*self.offset
                    local sea=obj.components.driver and obj.components.driver:GetIsDriving()
                    if forbidden({x=x,z=z}) or (sea and not home:IsWater(x,z)) then
                        local safe=home:GetSafePoint(obj,sea)
                        if not safe then return false end
                        x,y,z=safe[1],0,safe[2]
                    end
                    if obj.Physics then obj.Physics:Teleport(x,y,z)
                    else obj.Transform:SetPosition(x,y,z) end
                    return
                end
            end
            return old(self, obj, ...)
        end
    end
end)

-- Transform and Physics are engine userdata: their methods must never be replaced.
-- Filter the Lua teleport entry point, then correct unexpected moves each frame.
AddPlayerPostInit(function(p)
    local oldteleport = p.Teleport
    if oldteleport then
        p.Teleport = function(self, target, ...)
            local pos = target and (target.GetPosition and target:GetPosition() or target)
            local c=island()
            if c and forbidden(pos) then
                local d=self.components.driver
                local safe=c:GetSafePoint(self,d and d:GetIsDriving())
                if not safe then return false end
                -- Random staff casts have already paid their original costs.
                -- Complete the transition at a legal destination, including fade.
                target=G.Vector3(safe[1],0,safe[2])
            end
            return oldteleport(self, target, ...)
        end
    end
    local correcting=false
    local function validate_position()
        if correcting then return end
        local c = island()
        if not c or not c.ready then return end
        local x,y,z = p.Transform:GetWorldPosition()
        -- Boat physics can overlap a coastal land tile without disembarking.
        -- Keep vanilla steering there; landing is blocked by the action/driver.
        local d = p.components.driver
        if d and d:GetIsDriving() then
            if c:IsWater(x,z) then p._sis_sea={x,z}; return end
            if c:CanSail(x,z) then return end
            local safe=c:GetSafePoint(p,true)
            if safe then
                correcting=true
                if p.Physics then
                    if p.Physics.ClearMotorVelOverride then p.Physics:ClearMotorVelOverride() end
                    if p.Physics.Stop then p.Physics:Stop() end
                    p.Physics:Teleport(safe[1],0,safe[2])
                end
                if p.components.locomotor then p.components.locomotor:Stop(true) end
                correcting=false
            end
            return
        end
        if c:IsAllowed(x,z) then
            p._sis_land = {x,z}
        elseif c:IsForbidden(x,z) then
            local safe = c:GetSafePoint(p,false)
            correcting=true
            if p.Physics then
                if p.Physics.ClearMotorVelOverride then p.Physics:ClearMotorVelOverride() end
                if p.Physics.Stop then p.Physics:Stop() end
                p.Physics:Teleport(safe[1],0,safe[2])
            else p.Transform:SetPosition(safe[1],0,safe[2]) end
            if p.components.locomotor then p.components.locomotor:Stop(true) end
            correcting=false
        end
    end
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
AddPrefabPostInit("beachresurrector", function(e)
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
AddComponentPostInit("resurrector", function(c)
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
AddComponentPostInit("resurrectable",function(c)
    local old=c.FindClosestResurrector
    c.FindClosestResurrector=function(self,cause,...)
        local home=island()
        if home and home.ready and cause=="drowning" then
            local inv=self.inst.components.inventory
            local body=inv and inv:GetEquippedItem(G.EQUIPSLOTS.BODY)
            if self.resurrectionmethod=="amphibious" or self.resurrectionmethod=="ballphins" or
                (body and (body.prefab=="armor_lifejacket" or body.prefab=="amulet")) then
                self.shouldwashuponbeach=true
                local res=G.SpawnPrefab("beachresurrector")
                local safe=home:GetSafePoint(self.inst,false)
                res.Transform:SetPosition(safe[1],0,safe[2])
                res.persists=false
                return res
            end
        end
        return old(self,cause,...)
    end
end)

modimport("scripts/sis_trade.lua")
modimport("scripts/sis_hamlet.lua")
modimport("scripts/sis_treasure.lua")
modimport("scripts/sis_bandits.lua")
if SIS_CONFIG.coastal_spiderden then modimport("scripts/sis_spiders.lua") end
modimport("scripts/sis_timers.lua")
modimport("scripts/sis_characters.lua")
if SIS_CONFIG.fishbone_vacuum then modimport("scripts/sis_vacuum.lua") end
