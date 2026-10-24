-- Frozen membership of the original spawn island; no ground or puddle entities added.
local Island = Class(function(self, inst)
    self.inst = inst
    self.tiles = {}
    self.ready = false
    self.inst:StartUpdatingComponent(self)
end)

local function key(x, z) return x .. ":" .. z end

function Island:IsLand(x, z)
    local m = self.inst.Map
    local t = m:GetTileAtPoint(x, 0, z)
    return t ~= GROUND.INVALID and t ~= GROUND.IMPASSABLE and not m:IsWater(t)
end

function Island:IsAllowed(x, z)
    if not self.ready then return false end
    local tx, tz = self.inst.Map:GetTileCoordsAtPoint(x, 0, z)
    return self.tiles[key(tx, tz)] == true and self:IsLand(x, z)
end

function Island:IsForbidden(x, z)
    return self.ready and self:IsLand(x, z) and not self:IsAllowed(x, z)
end

function Island:IsWater(x,z)
    local m=self.inst.Map
    local t=m:GetTileAtPoint(x,0,z)
    return t~=GROUND.INVALID and t~=GROUND.IMPASSABLE and m:IsWater(t)
end

function Island:CanSail(x,z)
    if self:IsWater(x,z) or self:IsAllowed(x,z) then return true end
    -- A one-tile coastal margin accounts for vanilla boat collision geometry.
    -- It allows grazing a shore while still aboard, never disembarking there.
    for i=0,15 do
        local a=i*math.pi/8
        if self:IsWater(x+4*math.cos(a),z+4*math.sin(a)) then return true end
    end
    return false
end

function Island:GetSafePoint(player,sea)
    if not self.ready then return nil end
    local preferred=player and (sea and player._sis_sea or player._sis_land)
    if preferred and ((sea and self:IsWater(preferred[1],preferred[2])) or
        (not sea and self:IsAllowed(preferred[1],preferred[2]))) then return preferred end
    if not sea then
        if FindWalkableOffset and Vector3 then
            local origin=Vector3(self.home[1],0,self.home[2])
            for _,radius in ipairs({2,4,8}) do
                local offset=FindWalkableOffset(origin,0,radius,16,true,false)
                if offset then
                    local p=origin+offset
                    if self:IsAllowed(p.x,p.z) then return {p.x,p.z} end
                end
            end
        end
        return self.home
    end
    if self.seahome and self:IsWater(self.seahome[1],self.seahome[2]) then return self.seahome end
    -- Older saves have no cached coast. Search their frozen home tiles once.
    local hx,hz=self.inst.Map:GetTileCoordsAtPoint(self.home[1],0,self.home[2])
    for tile in pairs(self.tiles) do
        local tx,tz=string.match(tile,"^(%-?%d+):(%-?%d+)$")
        if tx and tz then
            local x,z=self.home[1]+4*(tonumber(tx)-hx),self.home[2]+4*(tonumber(tz)-hz)
            for _,d in ipairs({{4,0},{-4,0},{0,4},{0,-4}}) do
                if self:IsWater(x+d[1],z+d[2]) then
                    self.seahome={x+d[1],z+d[2]}
                    return self.seahome
                end
            end
        end
    end
end

function Island:Initialize(x, z)
    if not self:IsLand(x, z) then return false end
    local m = self.inst.Map
    local sx, sy, sz = m:GetTileCenterPoint(x, 0, z)
    local q, seen, head = {{sx, sz}}, {}, 1
    local dirs = {{4,0},{-4,0},{0,4},{0,-4}}
    while head <= #q do
        local p = q[head]
        head = head + 1
        local tx, tz = m:GetTileCoordsAtPoint(p[1], 0, p[2])
        local k = key(tx, tz)
        if not seen[k] then
            seen[k] = true
            if self:IsLand(p[1], p[2]) then
                self.tiles[k] = true
                for _, d in ipairs(dirs) do
                    q[#q+1] = {p[1]+d[1], p[2]+d[2]}
                end
            elseif not self.seahome and self:IsWater(p[1],p[2]) then
                self.seahome={p[1],p[2]}
            end
        end
    end
    self.home = {sx, sz}
    self.ready = true
    print("[SingleIsland] Spawn island locked, tiles:", self:CountTiles())
    return true
end

function Island:CountTiles()
    local n = 0
    for _ in pairs(self.tiles) do n = n + 1 end
    return n
end

function Island:OnUpdate()
    if self.ready then return end
    -- Spawnpoint exists during a new world's initial load, but does not persist.
    for _, e in pairs(Ents) do
        if e.prefab == "spawnpoint" then
            local x, y, z = e.Transform:GetWorldPosition()
            if self:Initialize(x, z) then return end
        end
    end
    local p = GetPlayer()
    -- Never silently bind an established save to its current, arbitrary island.
    if p and GetClock():GetNumCycles() == 0 then
        local x, y, z = p.Transform:GetWorldPosition()
        self:Initialize(x, z)
    elseif p and not self.warned then
        self.warned = true
        print("[SingleIsland] No saved home island. Start a NEW Shipwrecked world.")
    end
end

function Island:OnSave()
    if self.ready then return {tiles=self.tiles, home=self.home, seahome=self.seahome} end
end

function Island:OnLoad(data)
    if data and data.tiles and data.home then
        self.tiles, self.home, self.ready = data.tiles, data.home, true
        self.seahome=data.seahome
    end
end

function Island:GetDebugString()
    return self.ready and ("Home tiles: " .. self:CountTiles()) or "Requires a new Shipwrecked world"
end

return Island
