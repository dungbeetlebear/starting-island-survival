from pathlib import Path
import os


def run_checks(runtime, check):
    def switches():
        lua = runtime("{fishbone_vacuum=false}")
        lua.execute('''
            assert(not HOOKS.prefab.twister)
            assert(not HOOKS.component.shopinterior)
            local create=function() end
            local rooms={CreateRoom=create}; init("component","interiorspawner",rooms)
            assert(rooms.CreateRoom==create) -- only the door-safety hook is always installed
            assert(not SIS_CONFIG.alloy_deconstruction and not SIS_CONFIG.hamlet_treasure_creatures)
            assert(not SIS_CONFIG.island_bandits and not SIS_CONFIG.townhall_mayor)
            assert(not SIS_CONFIG.treasure_materials and not SIS_CONFIG.shop_horns)
        ''')
        assert runtime().eval('HOOKS.prefab.twister ~= nil')
        no_dlc = runtime('{alloy_deconstruction=true,hamlet_treasure_creatures=true,'
                         'island_bandits=true,townhall_mayor=true,treasure_materials=true,shop_horns=true}', hamlet=False)
        no_dlc.execute('''
            assert(not SIS_HAS_HAMLET and not PrefabFiles)
            assert(not HOOKS.component.shopinterior)
            local create=function() end
            local rooms={CreateRoom=create}; init("component","interiorspawner",rooms)
            assert(rooms.CreateRoom==create)
            local loot={snake=3,goldnugget=1}; SIS_AdjustDugLoot(loot)
            assert(loot.snake==3 and loot.goldnugget==1)
        ''')
        # DLC flags may be off in the frontend or a plain SW compatibility pack;
        # installed Hamlet content must still be available after entering SW.
        assert runtime(hamlet_enabled=False).eval("SIS_HAS_HAMLET and PrefabFiles ~= nil")
        for mode in ["survival", "porkland", "volcano", "cave"]:
            lua = runtime('{alloy_deconstruction=true,island_bandits=true,townhall_mayor=true,shop_horns=true}', mode=mode)
            lua.execute('''
                for _,callbacks in pairs(HOOKS.component) do
                    for _,fn in ipairs(callbacks) do fn({}) end
                end
                for _,callbacks in pairs(HOOKS.prefab) do
                    for _,fn in ipairs(callbacks) do fn({prefab=MODE}) end
                end
            ''')

    def fauna_and_materials():
        lua = runtime('{hamlet_treasure_creatures=true,treasure_materials=true}')
        lua.execute('''
            local random=math.random
            local choices,index=nil,0
            math.random=function(low,high)
                assert(low==1 and high==20)
                choices=high; index=index+1; return index
            end
            local loot={snake=20,goldnugget=3}
            SIS_AdjustDugLoot(loot)
            assert(choices==20 and index==20 and loot.goldnugget==3)
            local required={"spider","mosquito_poison","snake","primeape","snake_poison","hound",
                "mean_flytrap","antman","antman_warrior","thunderbird","pog",
                "rabid_beetle","weevole","mandrakeman","frog_poison","snake_amphibious","bill",
                "scorpion","gnat","vampirebat"}
            for _,name in ipairs(required) do assert(loot[name]==1,name) end
            assert(not loot.adult_flytrap and not loot.antqueen and not loot.pugalisk
                and not loot.hippoptamoose and not loot.spider_monkey)
            for _,name in ipairs({"glowfly","dungbeetle","peagawk","pigeon","parrot_blue","kingfisher"}) do
                assert(not loot[name],name)
            end
            math.random=random
            LOOT.resources={loot={goldnugget=3},random_loot={papyrus=1,rope=1,gears=1}}
            LOOT.attack={loot={snake=2}}
            local function dig(prefab, name)
                local t={components={workable={}},loot=name,Transform={GetWorldPosition=function() return 0,0,0 end}}
                t.components.workable.onfinish=function(inst)
                    assert(SIS_DUG_TREASURE_DEPTH>0)
                    return SpawnTreasureChest(inst.loot,{inst=inst})
                end
                init("prefab","buriedtreasure",t)
                local worker={prefab=prefab,HasTag=function(_,tag) return tag=="player" and prefab~="tornado" end}
                return t.components.workable.onfinish(t,worker),worker
            end
            local def,worker=dig("woodlegs","resources")
            assert(def.random_loot.clippings==1 and def.random_loot.lightbulb==1)
            assert(not LOOT.resources.random_loot.clippings and not worker._sis_treasure_digs)
            for i=1,50 do
                local resources={clippings=10,lightbulb=7}
                def.custom_lootfn(resources)
                assert(resources.clippings>=1 and resources.clippings<=2)
                assert(resources.lightbulb>=1 and resources.lightbulb<=2)
            end
            dig("wilson","attack")
            local count=0; for _,v in pairs(LAST_GENERATED_LOOT) do count=count+v end
            assert(count==2 and LOOT.attack.loot.snake==2)
            assert(SIS_DUG_TREASURE_DEPTH==0)
            math.random=function(low,high) assert(low==1 and high==20); return 7 end
            local _,tornado=dig("tornado","attack")
            assert(LAST_GENERATED_LOOT.mean_flytrap==2 and not LAST_GENERATED_LOOT.snake)
            assert(not tornado._sis_treasure_digs and SIS_DUG_TREASURE_DEPTH==0)
            math.random=random
            local resources=dig("tornado","resources")
            assert(resources.random_loot.clippings==1 and resources.random_loot.lightbulb==1)
            assert(SpawnTreasureChest("resources",{inst={}})==LOOT.resources)
            assert(GetTreasureLootDefinition("attack")==LOOT.attack)
            local t={components={workable={onfinish=function() error("test failure") end}},Transform={GetWorldPosition=function() return 0,0,0 end}}
            init("prefab","buriedtreasure",t)
            assert(not pcall(t.components.workable.onfinish,t,{prefab="wilson",HasTag=function() return true end}))
            assert(SIS_DUG_TREASURE_DEPTH==0 and GetTreasureLootDefinition("attack")==LOOT.attack)
        ''')
        disabled = runtime()
        disabled.execute('''
            local loot={snake=3,clippings=9}; SIS_AdjustDugLoot(loot)
            assert(loot.snake==3 and loot.clippings==9)
        ''')

    def thunderbirds():
        lua = runtime('{hamlet_treasure_creatures=true}')
        lua.execute('''
            local function bird()
                local e={events=0,fx={Remove=function(self) self.removed=true end},components={},
                    Light={Enable=function(self,value) self.enabled=value end},
                    DoLightning=function(self) self.lightning=true end,
                    PushEvent=function(self) self.events=self.events+1 end,
                    DoTaskInTime=function(_,delay,fn) queue_task(fn) end}
                return e
            end
            local ordinary=bird(); init("prefab","thunderbird",ordinary)
            ordinary:DoLightning(); assert(ordinary.lightning)
            SIS_DUG_TREASURE_DEPTH=1
            local e=bird(); local fx=e.fx; init("prefab","thunderbird",e)
            SIS_DUG_TREASURE_DEPTH=0
            assert(e.cooling_down and not e.charging and e.Light.enabled==false)
            e:DoLightning(); assert(not e.lightning)
            e:PushEvent("start_charging"); assert(e.events==0)
            e:PushEvent("attacked"); assert(e.events==1)
            run_tasks(); assert(fx.removed and not e.fx)
            local data={}; e.OnSave(e,data); assert(data.sis_no_lightning)
            SIS_CONFIG.hamlet_treasure_creatures=false
            local loaded=bird(); init("prefab","thunderbird",loaded); loaded.OnLoad(loaded,data)
            loaded:DoLightning(); assert(not loaded.lightning and loaded.cooling_down)
        ''')

    def alloy_mayor_and_shop():
        lua = runtime('{alloy_deconstruction=true,townhall_mayor=true,shop_horns=true}')
        lua.execute('''
            local recipes={}
            Ingredient=function(name,n) return {type=name,amount=n} end
            GetRecipe=function(name) return recipes[name] end
            DeconstructRecipe=function(name,ingredients)
                recipes[name]={ingredients=ingredients,is_deconstruction_recipe=true}
            end
            GetAllRecipes=function() end
            WORLD.AddComponent=function(self,name) self.components[name]=self.components[name] or {} end
            init("prefab","shipwrecked",WORLD)
            assert(recipes.alloy.is_deconstruction_recipe)
            assert(recipes.alloy.ingredients[1].type=="iron" and recipes.alloy.ingredients[1].amount==4)
            local creates=0
            local interior={CreateRoom=function(_,a,b,c,d,dungeon,room,props)
                creates=creates+1; return props
            end}
            WORLD.prefab="world" -- actual DS adds interiorspawner before the SW wrapper finishes
            init("component","interiorspawner",interior)
            WORLD.prefab="shipwrecked"
            local original={{name="deco_cityhall_desk"}}
            local props=interior:CreateRoom("generic",10,10,10,"pig_shop_cityhall_player123",123,original)
            assert(#props==2 and #original==1 and props[2].name=="pigman_mayor_shopkeep")
            assert(props[2].x_offset==-3 and props[2].z_offset==4)
            assert(#interior:CreateRoom("generic",10,10,10,"pig_shop_cityhall_player123",123,props)==2)
            assert(interior:CreateRoom("generic",10,10,10,"other123",123,original)==original)
            SHOP_DEFS={SHOPTYPES={pig_shop_antiquities={}}}
            for i=1,15 do SHOP_DEFS.SHOPTYPES.pig_shop_antiquities[i]={"dragon_scales","oinc",30} end
            local ordinary={"dragon_scales","oinc",30}
            local shop={GetNewProduct=function() return ordinary end}
            init("component","shopinterior",shop)
            local random=math.random
            for i=1,17 do
                math.random=function(low,high) assert(low==1 and high==17); return i end
                local product=shop:GetNewProduct("pig_shop_antiquities")
                if i<=15 then assert(product==ordinary)
                elseif i==16 then assert(product[1]=="minotaurhorn" and product[3]==50)
                else assert(product[1]=="hippo_antler" and product[3]==30) end
            end
            math.random=function() error("other shop must not roll") end
            assert(shop:GetNewProduct("pig_shop_general")==ordinary)
            math.random=random
            assert(#SHOP_DEFS.SHOPTYPES.pig_shop_antiquities==15)
        ''')

    def bandits():
        lua = runtime('{island_bandits=true,casino_landing=true}')
        lua.execute('''
            Point=function(x,y,z) return {x=x,y=y,z=z} end
            local function entity(name,x)
                local e={prefab=name,valid=true,components={},tags={structure=true},x=x or 0,z=0}
                e.IsValid=function(self) return self.valid end
                e.HasTag=function(self,tag) return self.tags[tag] end
                e.Transform={GetWorldPosition=function() return e.x,0,e.z end,
                    SetPosition=function(_,x,y,z) e.x,e.z=x,z end}
                e.components.inventory={GiveItem=function(_,item) e.item=item end}
                e.DoTaskInTime=function(_,delay,fn) queue_task(fn) end
                return e
            end
            local player=entity("wilson",0)
            GetPlayer=function() return player end
            local island={ready=true,IsHome=function(_,x,z) return x<10 end,
                GetHomePoint=function() return {0,0} end}
            WORLD.components.sisland=island
            local spawns=0
            SpawnPrefab=function(name) spawns=spawns+1; local e=entity(name); e.GUID=spawns; return e end
            local native_updates,chestpoint=0,nil
            local function manager()
                local c={tickperiod=10,deathtime=0,disabled=false,
                    OnSave=function() return {},{"native-ref"} end,OnLoad=function() end,
                    OnPeriodicUpdate=function(self,dt)
                        native_updates=native_updates+1
                        if self.deathtime>0 then self.deathtime=self.deathtime-10 end
                        return "native-result"
                    end,
                    GenerateTreasure=function() error("must replace distant treasure placement") end,
                    SpawnTreasureChest=function(_,pt) chestpoint=pt; return "native-chest" end}
                init("component","banditmanager",c); WORLD.components.banditmanager=c; return c
            end
            local c=manager()
            Ents={entity("pighouse_city"),entity("pig_shop_general"),entity("playerhouse_city"),
                entity("pighouse_city_placer"),entity("pig_shop_spawner"),entity("pig_shop_deli",20)}
            c:OnPeriodicUpdate(); assert(native_updates==0)
            Ents[#Ents+1]=entity("pig_shop_deli")
            player.x=20; c:OnPeriodicUpdate(); assert(native_updates==0)
            player.x=0
            player.components.driver={GetIsDriving=function() return true end}
            c:OnPeriodicUpdate(); assert(native_updates==0)
            player.components.driver=nil
            assert(c:OnPeriodicUpdate()=="native-result" and native_updates==1)
            c:OnPeriodicUpdate(); assert(native_updates==2) -- no custom daily/dusk limit
            Ents[#Ents].tags.burnt=true
            c:OnPeriodicUpdate(); assert(native_updates==2)
            c.deathtime=30
            c:OnPeriodicUpdate(3); assert(c.deathtime==20 and native_updates==3)
            local bandit=entity("pigbandit")
            c:GenerateTreasure(bandit)
            assert(bandit.item.prefab=="banditmap" and bandit.item.treasure==c.treasure)
            assert(c.treasure.x==0 and spawns==2)
            local data,refs=c:OnSave()
            assert(data.sis_island_mode and not data.sis_bandit_day and refs[1]=="native-ref")
            assert(c:SpawnTreasureChest(Point(20,0,0))=="native-chest" and chestpoint.x==0)
            c:SpawnTreasureChest(Point(5,0,0)); assert(chestpoint.x==5)
            local t=entity("bandittreasure",20)
            t.components.workable={onfinish=function(inst) assert(inst.x==0) end}
            init("prefab","bandittreasure",t); run_tasks(); assert(t.x==0)
            t.x=20; t.components.workable.onfinish(t,player); assert(t.x==0)
            SIS_CONFIG.island_bandits=false
            local disabled=manager(); disabled:OnLoad(data)
            disabled:OnPeriodicUpdate(); assert(native_updates==3)
            disabled:SpawnTreasureChest(Point(20,0,0)); assert(chestpoint.x==0)
            -- A foreign manager with the option off is untouched.
            local foreign=manager(); foreign:OnPeriodicUpdate(); assert(native_updates==4)
            local unrelated=entity("bandittreasure",20)
            init("prefab","bandittreasure",unrelated); run_tasks(); assert(unrelated.x==20)
        ''')

    def fishbones():
        lua = runtime()
        lua.execute('''
            local held=false; local delivered=0; local dropped=0; local original_updates=0
            local bone={prefab="packim_fishbone",components={inventoryitem={IsHeld=function() return held end}},
                Transform={GetWorldPosition=function() return 0,0,0 end},Physics={}}
            local removed
            local twister={components={},GetPosition=function() return {x=0,y=0,z=0} end,
                ListenForEvent=function(_,name,fn) if name=="onremove" then removed=fn end end}
            twister.components.inventory={itemslots={},GiveItem=function(self,item)
                delivered=delivered+1; self.itemslots[1]=item; return true end,
                DropItem=function() dropped=dropped+1 end}
            local vacuum={inst=twister,noTags={"irreplaceable","player"},vacuumradius=5,consumeradius=1,
                OnUpdate=function() original_updates=original_updates+1 end}
            twister.components.vacuum=vacuum
            TheSim={FindEntities=function(_,x,y,z,radius,required,excluded)
                for _,tag in ipairs(excluded) do assert(tag~="irreplaceable") end
                return {bone}
            end}
            init("prefab","twister",twister)
            vacuum:OnUpdate(.1); assert(delivered==1 and original_updates==1)
            held=true; vacuum:OnUpdate(.1); assert(delivered==1 and original_updates==2)
            removed(twister); assert(dropped==1)
        ''')

    def native_sources():
        game = Path(os.environ.get("DS_DATA_DIR", r"D:\soft\Steam\steamapps\common\dont_starve\data"))
        scripts = game / "DLC0003/scripts"
        if not scripts.exists():
            print("SKIP: optional installed-game integration (set DS_DATA_DIR)")
            return
        lua = runtime('{alloy_deconstruction=true}')
        for name in lua.globals().PrefabFiles.values():
            assert (scripts / "prefabs" / (name + ".lua")).exists(), name
        staff = (scripts / "prefabs/staff.lua").read_text(encoding="utf-8")
        native_destroy = staff.split("local function destroystructure(staff, target)", 1)[1].split("---------YELLOW STAFF", 1)[0]
        lua.execute('''
            local recipes={alloy={ingredients={{type="iron",amount=4}}}}
            GetRecipe=function(name) return recipes[name] end
            getsoundsforstructure=function() return {} end
            SpawnLootPrefab=function(_,name) assert(name=="iron"); ORE=ORE+1 end
            ORE=0
            TUNING.SANITY_MEDLARGE=20
            local owner={components={sanity={DoDelta=function(_,n) SANITY=n end}}}
            STAFF={components={inventoryitem={owner=owner},finiteuses={Use=function(_,n) USES=n end}},
                SoundEmitter={PlaySound=function() end}}
            TARGET={prefab="alloy",components={stackable={Get=function() TAKEN=1; return TARGET end}},
                Remove=function() REMOVED=true end}
        ''')
        native = lua.execute("local function destroystructure(staff,target)" + native_destroy + "\nreturn destroystructure")
        native(lua.globals().STAFF, lua.globals().TARGET)
        assert lua.globals().ORE == 4 and lua.globals().TAKEN == 1
        assert lua.globals().USES == 1 and lua.globals().SANITY == -20 and lua.globals().REMOVED

        # Execute the installed game's manager, including its real constructor,
        # spawn/currency checks, save references and death cooldown, with our hook.
        lua = runtime('{island_bandits=true}')
        lua.execute('''
            Class=function(ctor)
                local cls={_ctor=ctor}; cls.__index=cls
                return setmetatable(cls,{__call=function(_,inst)
                    local self=setmetatable({},cls); ctor(self,inst); return self
                end})
            end
        ''')
        lua.globals().NATIVE_BANDIT = lua.execute((scripts / "components/banditmanager.lua").read_text(encoding="utf-8"))
        lua.execute('''
            Point=function(x,y,z) return {x=x,y=y,z=z} end
            Vector3=Point
            GROUND.SUBURB,GROUND.COBBLEROAD,GROUND.FOUNDATION,GROUND.LAWN=1,2,3,4
            local tile,phase=1,"day"
            GetGroundTypeAtPosition=function() return tile end
            WORLD.components.clock={IsDusk=function() return phase=="dusk" end,
                IsNight=function() return phase=="night" end}
            WORLD.DoPeriodicTask=function(_,period) assert(period==10); return {} end
            local function entity(name,x)
                local e={prefab=name,components={},x=x or 0,z=0,tags={structure=true}}
                e.Transform={GetWorldPosition=function() return e.x,0,e.z end,
                    SetPosition=function(_,x,y,z) e.x,e.z=x,z end}
                e.HasTag=function(self,tag) return self.tags[tag] end
                e.IsValid=function() return true end
                e.ReturnToScene=function(self) self.returned=true end
                e.components.inventory={itemslots={},GiveItem=function(_,map) e.map=map end,
                    GetItems=function() return {} end}
                return e
            end
            local player=entity("wilson")
            GetPlayer=function() return player end
            local cover=entity("pighouse_city",2)
            local shop=entity("pig_shop_general",4)
            Ents={cover,shop,entity("pig_shop_cityhall_player",6)}
            WORLD.components.sisland={ready=true,IsHome=function(_,x) return x<10 end,
                GetHomePoint=function() return {0,0} end}
            local covers={cover}
            TheSim={FindEntities=function(_,x,y,z,radius,tags)
                assert(radius==40 and tags[1]=="bandit_cover"); return covers
            end}
            TheCamera={headingtarget=0}
            local spawns=0
            SpawnPrefab=function(name) spawns=spawns+1; local e=entity(name); e.GUID=spawns; return e end
            local c=NATIVE_BANDIT(WORLD)
            init("component","banditmanager",c); WORLD.components.banditmanager=c
            local roll,rolls=.15,0
            local random=math.random
            math.random=function(a,b) if a then return 1 end; rolls=rolls+1; return roll end
            local coin={oincvalue=10,components={stackable={StackSize=function() return 10 end}}}
            player.components.inventory.itemslots={coin}
            c:OnPeriodicUpdate(); assert(not c.bandit and rolls==1) -- 100 Oincs, day: 10%
            phase="dusk"
            c:OnPeriodicUpdate(); assert(c.banditactive and rolls==2 and spawns==3) -- 150 effective: 20%
            assert(c.bandit.x==1 and c.bandit.map.treasure==c.treasure and c.treasure.x==0)
            c:OnPeriodicUpdate(); assert(rolls==2) -- already active
            local data,refs=c:OnSave()
            assert(data.sis_island_mode and data.bandit==c.bandit.GUID and refs[1]==data.bandit)
            local restored=NATIVE_BANDIT(WORLD)
            init("component","banditmanager",restored); restored:OnLoad(data)
            restored:LoadPostPass({[c.bandit.GUID]={entity=c.bandit}},data)
            assert(restored.bandit==c.bandit and restored.banditactive)
            c.banditactive=false
            c:OnPeriodicUpdate(); assert(c.bandit.returned and rolls==3 and spawns==3)
            c.banditactive=false
            player.components.inventory.itemslots={}
            phase="night"; roll=0
            c:OnPeriodicUpdate(); assert(not c.banditactive) -- zero money never triggers
            player.components.inventory.overflow={components={container={slots={coin}}}}
            roll=.15; c:OnPeriodicUpdate(); assert(c.banditactive) -- bag included, night 3x
            c.banditactive=false; tile=99
            local before=rolls
            c:OnPeriodicUpdate(); assert(not c.banditactive and rolls==before) -- non-city ground
            tile=GROUND.LAWN; covers={}
            c:OnPeriodicUpdate(); assert(not c.banditactive and spawns==3) -- native cover required
            covers={cover}
            local old=c.bandit
            c:deactivatebandit(old,true)
            assert(c.deathtime==720 and not c.bandit)
            Ents={}; c:OnPeriodicUpdate(3); assert(c.deathtime==710) -- exact native tick behavior
            SIS_CONFIG.island_bandits=false
            c:OnPeriodicUpdate(); assert(c.deathtime==710)
            math.random=random
        ''')

    for name, fn in [
        ("new defaults, off switches, missing Hamlet and non-SW isolation", switches),
        ("20 equal attacking creature choices, unchanged total, resources 1-2, Woodlegs and error cleanup", fauna_and_materials),
        ("non-electric treasure Thunderbirds and saved variants", thunderbirds),
        ("alloy recipe, one indoor mayor and equal horn stock", alloy_mayor_and_shop),
        ("house threshold, native delegation/cooldown, save/off behavior and home-only bandit treasure", bandits),
        ("ground-only Fishbone intake and release", fishbones),
        ("installed-game dependencies, native staff and native Hamlet bandit behavior", native_sources),
    ]:
        check(name, fn)
