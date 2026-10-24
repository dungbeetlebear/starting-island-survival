local G=GLOBAL
local brains=G.setmetatable({},{__mode="k"})
SIS.AddPrefabPostInit("coral_brain_rock",function(e) brains[e]=true end)

-- Remember whether this green season's first rain has happened, across saves.
SIS.AddComponentPostInit("seasonmanager",function(s)
    if not s.IsGreenSeason then return end
    local green,precip,save,load=s.StartGreen,s.StartPrecip,s.OnSave,s.OnLoad
    s.StartGreen=function(self,...)
        self._sis_first_rain=false
        return green(self,...)
    end
    s.StartPrecip=function(self,...)
        if self:IsGreenSeason() then self._sis_first_rain=true end
        return precip(self,...)
    end
    s.OnSave=function(self,...)
        local data,refs=save(self,...)
        data.sis_first_rain=self._sis_first_rain or false
        return data,refs
    end
    s.OnLoad=function(self,data,...)
        local result=load(self,data,...)
        self._sis_first_rain=data and data.sis_first_rain or false
        return result
    end
end)

local function raineta(s)
    if s.precipmode=="never" then return nil end
    if s.precip or s.precipmode=="always" then return 0 end
    local day=G.TUNING.TOTAL_DAY_TIME
    local length=s:GetSeasonLength(G.SEASONS.GREEN)
    local base_days=s:GetDaysIntoSeason()
    local phase=G.GetClock():GetNormTime()
    local start=base_days+phase
    local moisture=s.atmo_moisture
    local elapsed=0
    -- Mirror UpdateDynamicPrecip in one-second steps without consuming RNG or
    -- changing weather. The day-based rate changes discretely at dawn.
    while start+elapsed/day<length do
        local days=base_days+math.floor(phase+elapsed/day)
        if days>5 then
            local p=(days-5)/(length-5)
            local rate=(3+(1-math.sin(math.pi*p))*.75)*s.base_atmo_moisture_rate
            moisture=moisture+rate
        end
        if moisture>=s.moisture_limit then return elapsed end
        elapsed=elapsed+1
    end
end
local function seconds(n)
    n=math.ceil(math.max(0,n))
    return string.format("%dm %02ds",math.floor(n/60),n%60)
end
local last_update,last_text,last_world=-1,"",nil
local function timers()
    local w,p=G.GetWorld(),G.GetPlayer()
    if not w or not w.components.sisland or not p then return "" end
    if w~=last_world then last_update=-1; last_world=w end
    local now=G.GetTime()
    if now-last_update<.25 then return last_text end
    local rows={}
    local function add(label,time,suffix)
        if time and time>0 then rows[#rows+1]=label..seconds(time)..(suffix or "") end
    end
    local kr=p.components.krakener
    if kr and not kr.kraken then
        local cooldown=kr:TimeUntilCanSpawn()
        add("Kraken: Can Spawn In: ",cooldown)
    end
    local s=w.components.seasonmanager
    local vm=w.components.volcanomanager
    if s and s:IsDrySeason() and vm then
        local seg=vm:GetNumSegmentsUntilEruption()
        if seg then
            local segment=G.TUNING.TOTAL_DAY_TIME/16
            local within=(G.GetClock():GetNormTime()*G.TUNING.TOTAL_DAY_TIME)%segment
            add("Volcano: Eruption In: ",seg*segment-within)
        end
    end
    if s and s:IsWetSeason() then
        local bh=w.components.basehassler
        local h=bh and bh.hasslers.TWISTER
        if h and h.HASSLER_STATE~="DORMANT" then
            local t=h.timer+(h.HASSLER_STATE=="WAITING" and h.warnduration or 0)
            add("Twister: "..h.HASSLER_STATE.." In: ",t)
        end
    end
    if s and s:IsGreenSeason() and not s._sis_first_rain then
        local t=raineta(s)
        add("First Rain: In: ",t)
    end
    local pending={}
    for e in pairs(brains) do
        if e:IsValid() then
            local pick=e.components.pickable
            if pick and not pick.canbepicked and (pick.targettime or pick.paused) then
                local x,y,z=e.Transform:GetWorldPosition()
                pending[#pending+1]={e=e,x=x,z=z,pick=pick}
            end
        end
    end
    table.sort(pending,function(a,b) if a.x==b.x then return a.z<b.z end return a.x<b.x end)
    for _,b in ipairs(pending) do
        local t=b.pick.paused and b.pick.pause_time or (b.pick.targettime-now)
        add(string.format("Brain Coral (%d, %d): Regen in: ",math.floor(b.x),math.floor(b.z)),t,b.pick.paused and " paused" or "")
    end
    last_update=now
    last_text=#rows>0 and "\n-------SINGLE-ISLAND----------------------\n"..table.concat(rows,"\n") or ""
    return last_text
end
local olddebug=G.GetDebugString
G.GetDebugString=function(...)
    return olddebug(...)..timers()
end
