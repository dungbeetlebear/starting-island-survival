"""Check native access, timer lifecycle and non-electric Thunderbird effects."""
from pathlib import Path
import os


def run_checks(runtime, check):
    game = Path(os.environ.get("DS_DATA_DIR", r"D:\soft\Steam\steamapps\common\dont_starve\data"))
    scripts = game / "DLC0003/scripts"

    def access():
        if not scripts.exists():
            print("SKIP: installed-game teleport integration (set DS_DATA_DIR)")
            return
        lua = runtime(before_mod="ORIGINAL_PREFAB=AddPrefabPostInit; ORIGINAL_COMPONENT=AddComponentPostInit; ORIGINAL_PLAYER=AddPlayerPostInit")
        lua.execute("assert(AddPrefabPostInit==ORIGINAL_PREFAB and AddComponentPostInit==ORIGINAL_COMPONENT and AddPlayerPostInit==ORIGINAL_PLAYER)")
        assert runtime('{coastal_spiderden=false}').eval('SIS_CONFIG.coastal_spiderden') == 1
        lua.execute((game / "scripts/class.lua").read_text(encoding="utf-8"))
        lua.globals().NATIVE_TELEPORTER = lua.execute((scripts / "components/teleporter.lua").read_text(encoding="utf-8"))
        lua.globals().NATIVE_ACTIVATABLE = lua.execute((game / "scripts/components/activatable.lua").read_text(encoding="utf-8"))
        lua.execute('''
            local function entity(name,x)
                local e={prefab=name,x=x or 0,components={}}
                e.Transform={GetWorldPosition=function() return e.x,0,0 end,
                    SetPosition=function(_,x,y,z) e.x=x end}
                e.Physics={Teleport=function(_,x,y,z) e.x=x end,Stop=function() end}
                e.HasTag=function(_,tag) return name=="woodlegs" and tag=="player" end
                e.DoPeriodicTask=function() end
                e.ListenForEvent=function() end
                return e
            end
            local p=entity("woodlegs")
            local home={ready=true,IsInterior=function() return false end,
                IsForbidden=function(_,x) return x>50 end,
                IsAllowed=function(_,x) return x<=50 end,
                GetSafePoint=function() return {4,0} end}
            WORLD.components.sisland=home
            for _,callback in ipairs(HOOKS.player) do callback(p) end
            p._sis_validate_position()
            local t=NATIVE_TELEPORTER(entity("wormhole"))
            init("component","teleporter",t)
            t.targetTeleporter=entity("wormhole",84)
            local activated=0
            t.onActivate=function() activated=activated+1 end
            assert(t:Activate(p)==false and activated==0 and p.x==0)
            local follower=entity("follower")
            t:Teleport(follower); assert(follower.x>50)
            t:Teleport(p); assert(p.x==4) -- native direct teleport followed by validation
            t.targetTeleporter=entity("wormhole",20)
            t.offset=0
            GetVisualTileType=function() return 1 end
            GetMap=function() return {IsWater=function() return false end} end
            t:Activate(p)
            assert(activated==1 and p.x==20 and p._sis_land[1]==20)
            t.targetTeleporter=entity("wormhole",49)
            t.offset=2
            local random=math.random; math.random=function() return math.pi/720 end
            t:Teleport(p); assert(p.x==4) -- original offset crosses island boundary
            math.random=random
            local volcano=entity("volcano")
            local calls=0
            local a=NATIVE_ACTIVATABLE(volcano,function() calls=calls+1 end)
            init("component","activatable",a)
            assert(a:DoActivate(p)==false and a.inactive and calls==0)
            local normal=NATIVE_ACTIVATABLE(entity("ordinary"),function() calls=calls+1 end)
            init("component","activatable",normal)
            normal:DoActivate(p); assert(not normal.inactive and calls==1)
        ''')

    def rescue():
        if not scripts.exists():
            print("SKIP: installed-game drowning rescue (set DS_DATA_DIR)")
            return
        lua = runtime()
        lua.execute((game / "scripts/class.lua").read_text(encoding="utf-8"))
        lua.execute('package.loaded["class"]=true')
        lua.execute((game / "scripts/vector3.lua").read_text(encoding="utf-8"))
        lua.globals().NATIVE_RESURRECTABLE = lua.execute((scripts / "components/resurrectable.lua").read_text(encoding="utf-8"))
        source = (scripts / "prefabs/beachresurrector.lua").read_text(encoding="utf-8")
        native = source.split("local function doresurrect(inst, dude)", 1)[1].split("local function fn()", 1)[0]
        lua.globals().NATIVE_RESCUE = lua.execute("return function(inst,dude)" + native)
        lua.execute('''
            PI=math.pi; GROUND.IMPASSABLE=-2; GROUND.INVALID=-1
            EQUIPSLOTS={BODY="body"}
            local tasks,items={},{}
            scheduler={ExecuteInTime=function(_,time,fn) tasks[#tasks+1]=fn end}
            TUNING.RESURRECT_HEALTH=50; TUNING.STARTING_TEMP=30
            WORLD.Map={GetTileAtPoint=function() return 1 end,IsWater=function() return false end}
            WORLD.components.sisland={ready=true,IsAllowed=function(_,x) return x==4 end,
                GetSafePoint=function() return {4,0} end}
            TheFrontEnd={Fade=function() end}
            TheCamera={SetDistance=function() end,SetDefault=function() end}
            GetRecipe=function() return {ingredients={{type="log",amount=3}}} end
            FindWalkableOffset=function() return nil end
            local next_days=0
            GetClock=function() return {MakeNextDay=function() next_days=next_days+1 end} end
            local function entity(name)
                local e={prefab=name,x=100,z=0,components={}}
                e.Transform={GetWorldPosition=function() return e.x,0,e.z end,
                    SetPosition=function(_,x,y,z) e.x,e.z=x,z end}
                e.GetPosition=function() return Vector3(e.x,0,e.z) end
                e.AddTag=function() end
                e.RemoveTag=function() end
                e.GetDistanceSqToInst=function(self,other) return (self.x-other.x)^2+(self.z-other.z)^2 end
                e.IsPosSurroundedByLand=function() return true end
                e.DoTaskInTime=function(_,delay,fn) tasks[#tasks+1]=function() fn(e) end end
                return e
            end
            SpawnPrefab=function(name)
                local e=entity(name)
                if name=="beachresurrector" then
                    e.doresurrect=NATIVE_RESCUE
                    init("prefab",name,e); Ents[#Ents+1]=e
                else items[#items+1]=e end
                return e
            end
            local p=entity("woodlegs")
            local jacket={prefab="armor_lifejacket",Remove=function(self) self.removed=true end}
            local body=jacket
            p.components.inventory={GetEquippedItem=function() return body end,
                RemoveItem=function(_,item) body=nil; return item end}
            p.components.hunger={Pause=function(self) self.paused=true end,
                Resume=function(self) self.paused=false end,SetPercent=function() end}
            p.components.health={Respawn=function(self,value) self.respawned=value end}
            p.components.sanity={SetPercent=function() end}
            p.sg={GoToState=function(self,state) self.state=state end}
            local r=NATIVE_RESURRECTABLE(p)
            local find=r.FindClosestResurrector
            init("component","resurrectable",r)
            assert(r.FindClosestResurrector==find) -- eligibility and selection remain native
            assert(r:CanResurrect("drowning") and r.resurrectionmethod=="lifejacket")
            local beach=r:FindClosestResurrector("drowning")
            assert(beach and r.shouldwashuponbeach)
            beach:doresurrect(p)
            assert(beach.x==4 and jacket.removed and not body and #items==3)
            for _,item in ipairs(items) do assert(item.x==4 and item.z==0) end
            while #tasks>0 do table.remove(tasks,1)() end
            assert(p.x==4 and next_days==1 and p.sg.state=="wakeup")
            assert(p.components.health.respawned==50 and not p.components.hunger.paused)
            for _,method in ipairs({"amphibious","ballphins"}) do
                r.resurrectionmethod=method
                assert(r:FindClosestResurrector("drowning") and r.shouldwashuponbeach)
            end
        ''')

    def timers():
        lua = runtime()
        lua.execute('''
            TUNING.TOTAL_DAY_TIME=480
            local phase="dry"
            GetClock=function() return {GetNormTime=function() return 0 end} end
            local cooldown,eruption,warning=10,1,20
            local p={components={krakener={TimeUntilCanSpawn=function() return cooldown end}}}
            GetPlayer=function() return p end
            local s={IsDrySeason=function() return phase=="dry" end,
                IsWetSeason=function() return phase=="wet" end,
                IsGreenSeason=function() return phase=="green" end,
                StartGreen=function() end,StartPrecip=function() end,
                OnSave=function() return {},{"native"} end,OnLoad=function() end}
            init("component","seasonmanager",s)
            WORLD.components.seasonmanager=s
            WORLD.components.volcanomanager={GetNumSegmentsUntilEruption=function() return eruption end}
            local h={timer=warning,HASSLER_STATE="WAITING",warnduration=10}
            WORLD.components.basehassler={hasslers={TWISTER=h}}
            local pick={canbepicked=false,targettime=20}
            local coral={IsValid=function() return true end,components={pickable=pick},
                Transform={GetWorldPosition=function() return 8,0,12 end}}
            init("prefab","coral_brain_rock",coral)
            local text=GetDebugString()
            assert(text:find("Kraken:") and text:find("Volcano:") and text:find("Brain Coral"))
            NOW=30; cooldown=0; eruption=0
            assert(GetDebugString()=="vanilla")
            NOW=31; phase="wet"; h.timer=0; h.warnduration=0
            assert(GetDebugString()=="vanilla")
            NOW=32; h.timer=30
            assert(GetDebugString():find("Twister:") and not GetDebugString():find("0m 00s"))
            NOW=33; phase="green"; s.precip=true
            assert(GetDebugString()=="vanilla")
            s:StartGreen(); assert(not s._sis_first_rain)
            s:StartPrecip(); assert(s._sis_first_rain)
            local data,refs=s:OnSave(); assert(data.sis_first_rain and refs[1]=="native")
            s._sis_first_rain=false; s:OnLoad(data); assert(s._sis_first_rain)
        ''')

    def thunderbird_fx():
        if not scripts.exists():
            print("SKIP: installed-game Thunderbird effects (set DS_DATA_DIR)")
            return
        lua = runtime('{hamlet_treasure_creatures=true}')
        source = (scripts / "prefabs/thunderbird.lua").read_text(encoding="utf-8")
        native = source.split("local function fx_fn()", 1)[1].split('return Prefab(', 1)[0]
        lua.globals().NATIVE_FX = lua.execute("return function()" + native)
        spawn = source.split("local function spawnfx(inst)", 1)[1].split("local function fn()", 1)[0]
        lua.globals().NATIVE_SPAWN_FX = lua.execute("return function(inst)" + spawn)
        lua.execute('''
            CreateEntity=function()
                local fx={pending={}}
                fx.Transform={SetPosition=function() end}
                fx.AnimState={SetBank=function() end,SetBuild=function() end,SetSortOrder=function() end}
                fx.entity={AddTransform=function() return fx.Transform end,
                    AddAnimState=function() return fx.AnimState end}
                fx.AddTag=function() end
                fx.DoTaskInTime=function(self,delay,fn) self.pending[#self.pending+1]=fn end
                fx.CancelAllPendingTasks=function(self) self.pending={} end
                fx.Hide=function(self) self.hidden=true end
                return fx
            end
            local function bird()
                return {SpawnChild=function() return NATIVE_FX() end,
                    Light={Enable=function() end},PushEvent=function() end}
            end
            SIS_DUG_TREASURE_DEPTH=1
            local e=bird(); init("prefab","thunderbird",e)
            SIS_DUG_TREASURE_DEPTH=0
            NATIVE_SPAWN_FX(e)
            assert(e.fx.hidden and #e.fx.pending==0)
            local normal=bird(); init("prefab","thunderbird",normal)
            NATIVE_SPAWN_FX(normal)
            assert(not normal.fx.hidden and #normal.fx.pending==1)
            local data={}; e.OnSave(e,data)
            local restored=bird(); init("prefab","thunderbird",restored); restored.OnLoad(restored,data)
            NATIVE_SPAWN_FX(restored)
            assert(restored.fx.hidden and #restored.fx.pending==0)
        ''')

    check("native teleport offsets/callbacks, immediate player validation and world-exit activation", access)
    check("native drowning eligibility, safe beach supplies, jacket cost and next-day rescue", rescue)
    check("positive-only timers, empty panel and first-rain save lifecycle", timers)
    check("native Thunderbird FX initialization for ordinary, treasure and saved birds", thunderbird_fx)
