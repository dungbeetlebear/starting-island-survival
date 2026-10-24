"""Check interior terrain and native door teleports against the island fence."""
from pathlib import Path
import os


def run_checks(runtime, check):
    def interiors():
        game=Path(os.environ.get("DS_DATA_DIR", r"D:\soft\Steam\steamapps\common\dont_starve\data"))
        scripts=game/"DLC0003/scripts"
        if not scripts.exists():
            print("SKIP: optional installed-game interior integration (set DS_DATA_DIR)")
            return
        lua=runtime('{casino_landing=true}')
        lua.execute((game/"scripts/class.lua").read_text(encoding="utf-8"))
        lua.execute('package.loaded["class"]=true')
        lua.execute((game/"scripts/vector3.lua").read_text(encoding="utf-8"))
        source=(scripts/"components/interiorspawner.lua").read_text(encoding="utf-8")
        native=source.split("function InteriorSpawner:ExecuteTeleport(doer, destination, direction)",1)[1]
        native=native.split("function InteriorSpawner:FadeInFinished",1)[0]
        lua.globals().NATIVE_INTERIORS=lua.execute("local InteriorSpawner={}\nfunction InteriorSpawner:ExecuteTeleport(doer,destination,direction)"+native+"\nreturn InteriorSpawner")
        lua.execute('''
            GROUND.INTERIOR=34
            WORLD.StartUpdatingComponent=function() end
            WORLD.Map={
                GetTileCoordsAtPoint=function(_,x,y,z) return math.floor(x/4),math.floor(z/4) end,
                GetTileCenterPoint=function(_,x,y,z) return math.floor(x/4)*4,0,math.floor(z/4)*4 end,
                GetTileAtPoint=function(_,x,y,z)
                    if x>=1990 and x<=2010 then return GROUND.INTERIOR end
                    if z==0 and ((x>=0 and x<12) or (x>=40 and x<52) or (x>=80 and x<92)) then return 1 end
                    return 2
                end,
                IsWater=function(_,tile) return tile==2 end,
            }
            local Island=dofile(MOD_ROOT.."/scripts/components/sisland.lua")
            local home=Island(WORLD); home.allow_casino=true
            WORLD.components.sisland=home
            assert(home:Initialize(0,0))
            home:RegisterCasinoIsland(44,0)
            assert(home:IsAllowed(44,0) and home:IsForbidden(84,0))
            assert(home:IsInterior(2000,0) and not home:IsLand(2000,0))
            assert(not home:IsAllowed(2000,0) and not home:IsForbidden(2000,0))
            assert(not home:Initialize(2000,0) and home:CountTiles()==3)
            local function entity(name,x)
                local e={prefab=name,x=x or 0,z=0,components={},events={}}
                e.Transform={GetWorldPosition=function() return e.x,0,e.z end,
                    SetPosition=function(_,x,y,z) e.x,e.z=x,z end,SetRotation=function() end}
                e.Physics={Teleport=function(_,x,y,z) e.x,e.z=x,z end,Stop=function() end}
                e.GetPosition=function(self) return Vector3(self.x,0,self.z) end
                e.IsValid=function() return true end
                e.HasTag=function(_,tag) return name=="woodlegs" and tag=="player" end
                e.PushEvent=function(self,name) if self.events[name] then self.events[name]() end end
                e.ListenForEvent=function(self,name,fn) self.events[name]=fn end
                e.DoPeriodicTask=function(self,period,fn) self.validate=fn end
                return e
            end
            local player=entity("woodlegs")
            GetPlayer=function() return player end
            player.components.inventory={itemslots={},equipslots={}}
            player.Teleport=function(self,target) self.Transform:SetPosition(target.x,0,target.z); return "native" end
            for _,callback in ipairs(HOOKS.player) do callback(player) end
            player.validate(); assert(player._sis_land[1]==0)
            local follower=entity("chester")
            follower.components.follower={CanFollowLeaderToInterior=function() return true end}
            player.components.leader={followers={[follower]=true}}
            local spawner={ExecuteTeleport=NATIVE_INTERIORS.ExecuteTeleport,Teleport=NATIVE_INTERIORS.Teleport,
                PushDirectionEvent=function(self,e,direction) e.direction=direction end}
            WORLD.components.interiorspawner=spawner
            init("component","interiorspawner",spawner)
            TheCamera={GetDownVec=function() return Vector3(0,0,1) end}
            local room=entity("prop_door",2000)
            spawner.current_interior={unique_name="pig_shop_general1"}
            spawner:ExecuteTeleport(player,room,"in")
            assert(player.x==2000 and follower.x==2000 and follower.direction=="in")
            player.validate(); player:PushEvent("newstate")
            assert(player.x==2000 and player._sis_land[1]==0) -- no room ejection or safe-point pollution
            local saved={}; player.OnSave(player,saved)
            player.OnLoad(player,saved)
            assert(player.x==2000 and saved.sis_safe_land[1]==0)
            assert(ACTIONS.BLINK.fn({action=ACTIONS.BLINK,pos={x=2000,z=0}})=="vanilla")
            assert(player:Teleport(Vector3(2004,0,0))=="native" and player.x==2004)
            player.validate(); assert(player._sis_land[1]==0)
            spawner:ExecuteTeleport(player,Vector3(2000,0,0),"in") -- another room
            assert(player.x==2000 and follower.x==2000)
            local exit=entity("pig_shop_general",4)
            exit.components.door={outside=true}
            spawner:ExecuteTeleport(player,exit,"out")
            player.validate()
            assert(player.x==4 and follower.x==4 and player._sis_land[1]==4)
            -- Even a stale interior flag must not disable outdoor enforcement.
            player.x=84; player:PushEvent("newstate"); assert(player.x==4)
            spawner:ExecuteTeleport(player,room,"in")
            spawner:ExecuteTeleport(player,Vector3(84,0,0),"out")
            assert(player.x==4 and follower.x==4) -- correct the shared native destination for pets too
            spawner:ExecuteTeleport(player,room,"in")
            spawner:ExecuteTeleport(player,Vector3(44,0,0),"out")
            player.validate(); assert(player.x==44 and follower.x==44)
            home.allow_casino=false
            spawner:ExecuteTeleport(player,room,"in")
            player.validate(); assert(player.x==2000)
            spawner:ExecuteTeleport(player,Vector3(44,0,0),"out")
            assert(home:IsAllowed(player.x,player.z) and player.x==follower.x)
            assert(not home:IsAllowed(44,0))
            -- NPC-only teleports retain the native behavior.
            spawner:ExecuteTeleport(follower,Vector3(84,0,0),"out")
            assert(follower.x==84)
            assert(ACTIONS.TRAVEL.fn({action=ACTIONS.TRAVEL,target={prefab="volcano"}})==false)
        ''')

    check("native indoor entry/exit, room movement/load, pets and outdoor island enforcement",interiors)
