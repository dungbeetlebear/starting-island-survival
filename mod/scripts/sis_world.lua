local G = GLOBAL
local island = SIS.GetIsland

SIS.AddPrefabPostInit("shipwrecked", function(w)
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
    SIS.AddPrefabPostInit("slotmachine", function(e)
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
SIS.AddComponentPostInit("basehassler", function(h)
    local shipwrecked=SIS.IsShipwrecked
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

SIS.AddComponentPostInit("seasonmanager", function(s)
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
