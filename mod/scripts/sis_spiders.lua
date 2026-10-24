local G = GLOBAL
local desired = SIS_CONFIG.coastal_spiderden
if desired <= 0 then return end
-- cannonshot.lua sets throwable.maxdistance=20; the boat cannon is craftable
-- in Shipwrecked. This is longer than the 12-unit targeted weapons.
local RANGE = math.max(20,G.TUNING.BOOMERANG_DISTANCE or 12,G.TUNING.SPEAR_LAUNCHER_ATTACK_RANGE or 12)-1
local function land(m,x,z)
    local t=m:GetTileAtPoint(x,0,z)
    return t~=G.GROUND.INVALID and t~=G.GROUND.IMPASSABLE and t~=G.GROUND.INTERIOR and not m:IsWater(t)
end
local function water(m,x,z)
    local t=m:GetTileAtPoint(x,0,z)
    if t==G.GROUND.INVALID or t==G.GROUND.IMPASSABLE or not m:IsWater(t) then return false end
    -- A boat must fit at the firing position, not merely touch a water tile.
    for _,d in ipairs({{.75,0},{-.75,0},{0,.75},{0,-.75}}) do
        if not m:IsWater(m:GetTileAtPoint(x+d[1],0,z+d[2])) then return false end
    end
    return true
end
local function reachable(m,x,z)
    for r=3,RANGE,2 do
        for i=0,31 do
            local a=i*2*math.pi/32
            if water(m,x+math.cos(a)*r,z+math.sin(a)*r) then return true end
        end
    end
    return false
end
local nests=G.setmetatable({},{__mode="k"})
local queued,working=false,false
local check
local function schedule()
    if queued or working then return end
    local w=G.GetWorld()
    if not w or not w.components.sisland then return end
    queued=true
    w:DoTaskInTime(1,check)
end
check=function(w)
    queued=false
    local c=w.components.sisland
    if not c then return end
    if not c.ready then schedule(); return end
    local m=w.Map
    local candidates,coastal={},0
    for e in pairs(nests) do
        if e:IsValid() then
            local x,y,z=e.Transform:GetWorldPosition()
            if reachable(m,x,z) then coastal=coastal+1
            else candidates[#candidates+1]=e end
        end
    end
    local missing=desired-coastal
    if missing<=0 then return end
    local function unoccupied(nest,x,z)
        for e in pairs(nests) do
            if e~=nest and e:IsValid() then
                local ex,ey,ez=e.Transform:GetWorldPosition()
                if (x-ex)^2+(z-ez)^2<16 then return false end
            end
        end
        if G.TheSim then
            for _,e in ipairs(G.TheSim:FindEntities(x,0,z,2,{"structure"})) do
                if e~=nest then return false end
            end
        end
        return true
    end
    local candidate=0
    local function searchnext()
        candidate=candidate+1
        local e=candidates[candidate]
        if not e or missing<=0 then working=false; return end
        if not e:IsValid() then searchnext(); return end
        working=true
        local x,y,z=e.Transform:GetWorldPosition()
        local sx,sy,sz=m:GetTileCenterPoint(x,0,z)
        local queue,seen,head={{sx,sz}},{},1
        local function step()
            if not e:IsValid() then searchnext(); return end
            -- Bound each task; a large island must not block the loading frame.
            local budget=8
            while head<=#queue and budget>0 do
                local p=queue[head]; head=head+1; budget=budget-1
                local tx,tz=m:GetTileCoordsAtPoint(p[1],0,p[2])
                local k=tx..":"..tz
                if not seen[k] then
                    seen[k]=true
                    if land(m,p[1],p[2]) then
                        if reachable(m,p[1],p[2]) and unoccupied(e,p[1],p[2]) then
                            e.Transform:SetPosition(p[1],0,p[2])
                            missing=missing-1
                            searchnext()
                            return
                        end
                        for _,d in ipairs({{4,0},{-4,0},{0,4},{0,-4}}) do
                            queue[#queue+1]={p[1]+d[1],p[2]+d[2]}
                        end
                    end
                end
            end
            if head<=#queue then w:DoTaskInTime(G.FRAMES,step)
            else searchnext() end
        end
        step()
    end
    searchnext()
end
SIS.AddPrefabPostInit("spiderden",function(e)
    nests[e]=true
    e:ListenForEvent("onremove",function() nests[e]=nil; schedule() end)
    schedule()
end)
