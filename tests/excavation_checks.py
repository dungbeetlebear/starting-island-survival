"""Exercise installed-game excavation paths, keeping the native worker objects."""
from pathlib import Path
import os


def run_checks(runtime, check):
    def native_excavation():
        game=Path(os.environ.get("DS_DATA_DIR", r"D:\soft\Steam\steamapps\common\dont_starve\data"))
        scripts=game/"DLC0003/scripts"
        if not scripts.exists():
            print("SKIP: optional installed-game excavation integration (set DS_DATA_DIR)")
            return
        setup = """
            local original=require
            require=function(name)
                if name=="spawnutil" or name=="class" then return true end
                return original(name)
            end
        """ + (scripts/"map/treasurehunt.lua").read_text(encoding="utf-8") + """
            SpawnTreasureChest=function(name,dropper)
                LAST_GENERATED_LOOT=GetTreasureLootList(name)
                LAST_DEPTH=SIS_DUG_TREASURE_DEPTH
                return LAST_GENERATED_LOOT
            end
        """
        lua=runtime('{hamlet_treasure_creatures=true,treasure_materials=true}',
                    hamlet_enabled=False,before_mod=setup)
        lua.execute((game/"scripts/class.lua").read_text(encoding="utf-8"))
        lua.execute((game/"scripts/vector3.lua").read_text(encoding="utf-8"))
        lua.globals().NATIVE_WORKABLE=lua.execute((scripts/"components/workable.lua").read_text(encoding="utf-8"))
        lua.globals().NATIVE_EXPLOSIVE=lua.execute((scripts/"components/explosive.lua").read_text(encoding="utf-8"))
        buried=(scripts/"prefabs/buriedtreasure.lua").read_text(encoding="utf-8")
        finish=buried.split("local function onfinishcallback(inst, worker)",1)[1].split("local function onsave",1)[0]
        lua.globals().NATIVE_FINISH=lua.execute("local function finish(inst,worker)"+finish+"\nreturn finish")
        tornado=(scripts/"stategraphs/SGtornado.lua").read_text(encoding="utf-8")
        destroy=tornado.split("local function destroystuff(inst)",1)[1].split("local states=",1)[0]
        lua.globals().NATIVE_TORNADO=lua.execute("local function destroy(inst)"+destroy+"\nreturn destroy")
        lua.execute('''
            ACTIONS.DIG,ACTIONS.CHOP,ACTIONS.NET,ACTIONS.FISH={},{},{},{}
            table.contains=function(values,value)
                for _,v in ipairs(values) do if v==value then return true end end
                return false
            end
            TheCamera={GetRightVec=function() return Vector3(1,0,0) end}
            local function entity(name)
                local e={prefab=name,components={},valid=true}
                e.HasTag=function(_,tag) return name=="wilson" and tag=="player" end
                e.PushEvent=function() end
                e.IsValid=function(self) return self.valid end
                e.Remove=function(self) self.valid=false end
                e.RemoveComponent=function(self,key) self.components[key]=nil end
                e.GetPosition=function() return Vector3(0,0,0) end
                e.Transform={GetWorldPosition=function() return 0,0,0 end,SetPosition=function() end}
                return e
            end
            local player=entity("wilson")
            player.components.playercontroller={ShakeCamera=function() end}
            GetPlayer=function() return player end
            GetClock=function() return {DoLightningLighting=function() end} end
            WORLD.PushEvent=function() end
            SpawnPrefab=function(name) return entity(name) end
            local target
            TheSim={FindEntities=function() return {target} end}
            WORLD.components.sisland.treasure_digs=10
            local material="clippings"
            weighted_random_choice=function(weights)
                if weights[material] then return material end
                return next(weights)
            end
            local original_random=math.random
            math.random=function(low,high)
                if high==20 then return 7 end -- smallest Snaptooth
                if high==2 then return 2 end -- requested 1-2 quantity
                if low then return low end
                return .5
            end
            local function dig(method,preset)
                target=entity("buriedtreasure")
                target.loot=preset
                target.SoundEmitter={PlaySound=function() end}
                target.MiniMapEntity={SetEnabled=function() end}
                target.components.hole={}
                target.components.lootdropper={DropLoot=function() end,inst=target}
                local work=NATIVE_WORKABLE(target)
                target.components.workable=work
                work:SetWorkAction(ACTIONS.DIG); work:SetWorkLeft(1)
                work:SetOnFinishCallback(NATIVE_FINISH)
                init("prefab","buriedtreasure",target)
                local worker=method=="shovel" and player or entity(method)
                if method=="tornado" then
                    worker.WINDSTAFF_CASTER=player
                    NATIVE_TORNADO(worker)
                elseif method=="shovel" or method=="other_worker" then
                    work:WorkedBy(worker,1)
                else
                    local explosive=NATIVE_EXPLOSIVE(worker)
                    explosive:OnBurnt()
                end
                assert(not target.valid and LAST_DEPTH==1 and SIS_DUG_TREASURE_DEPTH==0,method)
                assert(not worker._sis_treasure_digs or method=="shovel")
                return LAST_GENERATED_LOOT
            end
            for _,method in ipairs({"shovel","tornado","cannonshot","woodlegs_cannonshot",
                "gunpowder","coconade","other_worker"}) do
                local monsters=dig(method,"snaketrap")
                assert(monsters.mean_flytrap==3 and not monsters.snake,method)
                for _,name in ipairs({"clippings","lightbulb"}) do
                    material=name
                    local loot=dig(method,"SuperTelescope")
                    assert(loot[name]==2,method.." "..name)
                end
            end
            SIS_CONFIG.hamlet_treasure_creatures=false
            SIS_CONFIG.treasure_materials=false
            assert(dig("tornado","snaketrap").snake==3)
            assert(not dig("cannonshot","SuperTelescope").lightbulb)
            assert(GetTreasureLootDefinition("snaketrap").loot.snake==3)
            assert(not GetTreasureLootDefinition("SuperTelescope").random_loot.clippings)
            for _,method in ipairs({"shovel","tornado","cannonshot","woodlegs_cannonshot",
                "gunpowder","coconade","other_worker"}) do
                WORLD.components.sisland.treasure_digs=0
                WORLD.components.sisland.treasure_gold=false
                for i=1,4 do dig("tornado","snaketrap") end
                assert(WORLD.components.sisland.treasure_digs==4)
                local loot=dig(method,"snaketrap")
                assert(loot.goldnugget==3,method.." fifth excavation")
                assert(WORLD.components.sisland.treasure_digs==5 and WORLD.components.sisland.treasure_gold)
                WORLD.components.sisland.treasure_digs=0
                WORLD.components.sisland.treasure_gold=false
                dig(method,"gems")
                for i=2,4 do dig("tornado","snaketrap") end
                assert(dig(method,"snaketrap").snake==3,method.." early gold")
                assert(WORLD.components.sisland.treasure_digs==5 and WORLD.components.sisland.treasure_gold)
            end
            math.random=original_random
        ''')
        # The engine checks compatibility-pack flags, not the world prefab:
        # a Hamlet-compatible SW save may have CAPY=false and PORKLAND=true.
        source=(game/"scripts/modindex.lua").read_text(encoding="utf-8")
        method=source.split("function ModIndex:IsModCompatibleWithMode(modname, dlcmode)",1)[1].split("function ModIndex:HasModConfigurationOptions",1)[0]
        lua.globals().NATIVE_COMPATIBLE=lua.execute("return function(self,modname,dlcmode)"+method)
        lua.execute('''
            REIGN_OF_GIANTS,CAPY_DLC,PORKLAND_DLC=1,2,3
            IsDLCEnabled=function(index) return index==PORKLAND_DLC end
            assert(NATIVE_COMPATIBLE(KnownModIndex,modname))
            IsDLCEnabled=function(index) return index==CAPY_DLC end
            assert(NATIVE_COMPATIBLE(KnownModIndex,modname))
        ''')

    check("native shovel, wind staff, cannon/bomb excavation, installed DLC and linked-SW loading",native_excavation)
