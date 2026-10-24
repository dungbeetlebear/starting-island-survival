"""Run with Python + lupa; uses Lua 5.1, matching the game's Lua version."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / ".tools" / "python"))
from lupa.lua51 import LuaRuntime


def runtime(config="{}", mode="shipwrecked", locale="en", hamlet=True, hamlet_enabled=True, before_mod=""):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.globals().MOD_ROOT = (ROOT / "mod").as_posix()
    lua.globals().MODE = mode
    lua.globals().GAME_LOCALE = locale
    lua.globals().HAS_HAMLET = hamlet
    lua.globals().HAMLET_ENABLED = hamlet_enabled
    lua.execute("CONFIG = " + config)
    lua.execute((ROOT / "tests" / "harness.lua").read_text(encoding="utf-8"))
    if before_mod:
        lua.execute(before_mod)
    lua.execute('dofile(MOD_ROOT .. "/modmain.lua")')
    return lua


def check(name, fn):
    fn()
    print("PASS:", name)


def syntax_and_metadata():
    lua = LuaRuntime()
    compile_lua = lua.eval("function(s,n) local f,e=loadstring(s,n); assert(f,e) end")
    for path in (ROOT / "mod").rglob("*.lua"):
        compile_lua(path.read_text(encoding="utf-8"), path.name)
    lua.execute((ROOT / "mod" / "modinfo.lua").read_text(encoding="utf-8"))
    lua.execute('''
        assert(shipwrecked_compatible and hamlet_compatible and not dont_starve_compatible
            and not reign_of_giants_compatible and not dst_compatible)
        assert(#configuration_options == 14)
        local expected = {language="auto", octopus_no_cooldown=true, gold_guarantee=true,
            casino_landing=false, gem_multiplier=2, season_length="70_days", coastal_spiderden=true,
            alloy_deconstruction=false,fishbone_vacuum=true,hamlet_treasure_creatures=false,
            island_bandits=false,townhall_mayor=false,treasure_materials=false,shop_horns=false}
        for _, option in ipairs(configuration_options) do
            assert(option.default == expected[option.name], option.name)
            local found=false
            for _, value in ipairs(option.options) do
                if value.data == option.default then found=true end
            end
            assert(found, "missing default option")
            if option.name == "season_length" then assert(#option.options == 2) end
        end
    ''')
    assert not (ROOT / "mod/scripts/sis_attack.lua").exists()


def internationalization():
    for code, expected in [("zh", "zh"), ("zhr", "zh"), ("zh_TW", "zh"),
                           ("en", "en"), ("fr", "en"), (None, "en")]:
        lua = LuaRuntime(unpack_returned_tuples=True)
        load_info = lua.eval('''function(path, locale)
            local info={locale=locale}
            local fn=assert(loadfile(path)); setfenv(fn,info)(); return info
        end''')
        info = load_info((ROOT / "mod/modinfo.lua").as_posix(), code)
        assert info.name == info.sis_i18n[expected].name
        assert info.description == info.sis_i18n[expected].description
        for lang in ["zh", "en"]:
            for option in info.configuration_options.values():
                entry = info.sis_i18n[lang].config[option.name]
                assert entry.label and entry.hover
                assert len(entry.options) == len(option.options)
                assert all(entry.options.values())
            assert info.sis_i18n[lang].messages.home_only
            assert info.sis_i18n[lang].messages.home_casino_only
    for choice, code, expected in [("auto", "zh", "zh"), ("auto", "zhr", "zh"),
                                   ("auto", "en", "en"), ("auto", "fr", "en"),
                                   ("en", "zh", "en"), ("zh", "en", "zh"),
                                   ("invalid", "en", "en")]:
        lua = runtime('{language="' + choice + '"}', locale=code)
        lua.globals().EXPECTED = expected
        lua.execute('''
            local info=KnownModIndex:GetModInfo(modname)
            assert(info.name==info.sis_i18n[EXPECTED].name)
            assert(info.description==info.sis_i18n[EXPECTED].description)
            assert(SIS_Text("home_only")==info.sis_i18n[EXPECTED].messages.home_only)
            assert(SIS_Text("unknown_key")=="unknown_key")
            local spoken
            WORLD.components.sisland={IsForbidden=function() return true end}
            local player={HUD={},components={talker={Say=function(_,text) spoken=text end}}}
            ACTIONS.DISMOUNT.fn({action=ACTIONS.DISMOUNT,pos={x=100,z=0},doer=player})
            assert(spoken==SIS_Text("home_only"))
            SIS_CONFIG.casino_landing=true
            ACTIONS.DISMOUNT.fn({action=ACTIONS.DISMOUNT,pos={x=100,z=0},doer=player})
            assert(spoken==SIS_Text("home_casino_only"))
        ''')
    lua = runtime('{language="en",gold_guarantee=false,casino_landing=true,gem_multiplier=5}')
    lua.execute('''
        local index=KnownModIndex
        local function language(settings)
            for _,v in ipairs(settings) do if v.name=="language" then return v end end
        end
        local info=index:GetModInfo(modname)
        assert(info.name=="Starting Island Survival")
        -- Covers the asynchronous merge callback after LoadModConfigurationOptions returns.
        index:UpdateConfigurationOptions(info.configuration_options,{{name="language",saved="zh"}})
        assert(info.name=="初始岛生存" and SIS_CONFIG.language=="zh")
        assert(info.configuration_options[2].label=="章鱼王交易")
        assert(info.configuration_options[3].saved==false)
        assert(info.configuration_options[4].saved==true)
        assert(info.configuration_options[5].saved==5)
        -- The Mods screen rebuilds modinfo; remember the saved choice.
        local fresh=load_modinfo()
        index.savedata.known_mods[modname].modinfo=fresh
        assert(index:GetModInfo(modname).name=="初始岛生存")
        SAVED_CONFIG={{name="language",saved="en"}}
        index:LoadModConfigurationOptions(modname)
        assert(fresh.name=="Starting Island Survival")
        local called=0
        index:SaveConfigurationOptions(function()
            called=called+1; assert(fresh.name=="初始岛生存")
            assert(index:GetModInfo(modname).name=="初始岛生存")
        end,modname,{{name="language",saved="zh"}})
        assert(called==1 and fresh.name=="初始岛生存")
        index.savedata.known_mods.other={modinfo={name="Other mod",configuration_options={}}}
        index:SaveConfigurationOptions(function() called=called+1 end,"other",{})
        assert(called==2 and index:GetModInfo("other").name=="Other mod")
        assert(index:GetModInfo(modname).name=="初始岛生存")
        local function spinners()
            local values={}; for i=1,7 do values[i]={OnGainFocus=function() end} end
            return values
        end
        local screen={modname=modname,option_offset=0,left_spinners=spinners(),right_spinners=spinners()}
        screen.root={AddChild=function(_,child) screen.help=child; return child end}
        screen.RefreshOptions=function(self) self.left_spinners=spinners(); self.right_spinners=spinners() end
        init("class","screens/modconfigurationscreen",screen)
        screen.left_spinners[3]:OnGainFocus()
        assert(screen.help.text==fresh.sis_i18n.zh.config.gold_guarantee.hover)
        screen:RefreshOptions(); screen.left_spinners[6]:OnGainFocus()
        assert(screen.help.text==fresh.sis_i18n.zh.config.season_length.hover)
        screen.right_spinners[7]:OnGainFocus()
        assert(screen.help.text==fresh.sis_i18n.zh.config.shop_horns.hover)
        init("class","screens/modconfigurationscreen",{modname="other"})
        local details=0
        local menu={modnames={modname},currentmod=1,
            ShowModDetails=function() details=details+1 end}
        init("class","screens/modsscreen",menu); menu:OnBecomeActive()
        assert(details==1)
        GAME_LOCALE="zh"
        index:SaveConfigurationOptions(function() end,modname,{{name="language",saved="auto"}})
        assert(index:GetModInfo(modname).name=="初始岛生存")
        GAME_LOCALE="en"
        assert(index:GetModInfo(modname).name=="Starting Island Survival")
        assert(SIS_Text("home_only")==fresh.sis_i18n.en.messages.home_only)
    ''')
    lua = runtime('{gold_guarantee=false,casino_landing=true,gem_multiplier=3}', locale="zh")
    lua.execute('''
        -- An older configuration has no language row: use Auto and retain gameplay choices.
        SAVED_CONFIG={{name="gold_guarantee",saved=false},
            {name="casino_landing",saved=true},{name="gem_multiplier",saved=3}}
        local settings=KnownModIndex:LoadModConfigurationOptions(modname)
        assert(SIS_CONFIG.language=="auto")
        assert(KnownModIndex:GetModInfo(modname).name=="初始岛生存")
        assert(settings[3].saved==false and settings[4].saved==true and settings[5].saved==3)
    ''')


def isolation_and_toggles():
    for mode in ["survival", "cave", "adventure", "porkland", "volcano"]:
        lua = runtime(mode=mode)
        lua.execute('''
            for _, callbacks in pairs(HOOKS.component) do
                for _, callback in ipairs(callbacks) do callback({}) end
            end
            for _, callbacks in pairs(HOOKS.prefab) do
                for _, callback in ipairs(callbacks) do callback({prefab=MODE}) end
            end
            for _, callback in ipairs(HOOKS.player) do callback({}) end
            assert(not SIS_IsShipwrecked())
            assert(GetDebugString() == "vanilla")
            assert(GetTreasureLootDefinition("sample") == LOOT.sample)
        ''')
    lua = runtime('{octopus_no_cooldown=false, gold_guarantee=false, casino_landing=false, '
                  'gem_multiplier=1, season_length="vanilla", coastal_spiderden=false}')
    lua.execute('''
        assert(not SIS_CONFIG.octopus_no_cooldown and not SIS_CONFIG.gold_guarantee)
        assert(not SIS_CONFIG.casino_landing and not SIS_CONFIG.coastal_spiderden)
        assert(not HOOKS.prefab.octopusking and not HOOKS.component.tradable)
        assert(not HOOKS.prefab.spiderden and not HOOKS.prefab.slotmachine)
        assert(not HOOKS.component.combat)
        WORLD=nil; MODE="survival"; assert(not SIS_IsShipwrecked())
        MODE="shipwrecked"; assert(SIS_IsShipwrecked())
        SaveGameIndex.GetCurrentSaveSlot=function() return nil end
        assert(not SIS_IsShipwrecked())
    ''')


def treasure():
    for multiplier in [1, 1.5, 2, 3, 4, 5, 10]:
        lua = runtime("{gem_multiplier=" + str(multiplier) + "}")
        lua.execute('''
            local ordinary = SpawnTreasureChest("sample", {inst={}})
            assert(ordinary == LOOT.sample)
            local modified = SpawnTreasureChest("sample", {inst={_sis_hat=true}})
            local factor=SIS_CONFIG.gem_multiplier
            near(modified.chance_loot.yellowgem, math.min(1, .2*factor))
            near(modified.chance_loot.greengem, math.min(1, .1*factor))
            near(modified.chance_loot.redgem, .4)
            local r=modified.random_loot
            local total=r.yellowgem+r.greengem+(r.redgem or 0)+(r.bluegem or 0)
            near(total, 10)
            near((r.yellowgem+r.greengem)/total, math.min(1, .3*factor))
            near(r.yellowgem/r.greengem, 2)
            if (r.bluegem or 0)>0 then near(r.redgem/r.bluegem, 4/3) end
            if .3*factor>=1 then assert(not r.redgem and not r.bluegem) end
            near(LOOT.sample.chance_loot.yellowgem, .2)
            near(LOOT.sample.random_loot.yellowgem, 2)
            assert(GetTreasureLootDefinition("sample") == LOOT.sample)
        ''')
    for enabled in [True, False]:
        lua = runtime("{gold_guarantee=" + str(enabled).lower() + "}")
        lua.execute('''
            local function player(prefab)
                return {prefab=prefab, HasTag=function(_, tag) return tag=="player" end}
            end
            local function dig(worker, preset, hat)
                local t={components={workable={}}, loot=preset or "sample"}
                t.components.workable.onfinish=function(inst)
                    return SpawnTreasureChest(inst.loot, {inst=inst})
                end
                init("prefab", "buriedtreasure", t)
                t._sis_hat=hat
                return t.components.workable.onfinish(t, worker), t
            end
            local worker=player("wilson")
            for i=1,4 do local _,t=dig(worker); assert(t.loot=="sample") end
            local _, fifth=dig(worker)
            assert(fifth.loot==(SIS_CONFIG.gold_guarantee and "gems" or "sample"))
            assert(worker._sis_treasure_digs==5)
            local lucky=player("wilson")
            dig(lucky,"gems")
            for i=1,4 do local _,t=dig(lucky); assert(t.loot=="sample") end
            local captain=player("woodlegs"); captain._sis_treasure_digs=4
            local _,t=dig(captain); assert(t.loot=="sample")
        ''')


def seasons():
    for setting, expected in [("70_days", [20, 15, 20, 15]), ("vanilla", [20, 16, 20, 16])]:
        lua = runtime('{season_length="' + setting + '"}')
        lua.execute('''
            local s={IsWetSeason=function() return true end, percent_season=0,
                seasonmode="tropical", current=1, lengths={20,15,20,15}, transitions=0}
            s.GetSeasonLength=function(self) return self.lengths[self.current] end
            s.OnDayComplete=function(self)
                self.percent_season=self.percent_season+1/self:GetSeasonLength()
                if self.percent_season>=1 then
                    self.transitions=self.transitions+1; self.percent_season=0
                    self.current=self.current%4+1
                end
            end
            init("component", "seasonmanager", s)
            DAYS={}
            for season=1,4 do
                local count=0
                repeat s:OnDayComplete(); count=count+1 until s.transitions==season
                DAYS[season]=count
            end
            local setters=0
            WORLD.AddComponent=function(self) self.components.sisland={} end
            WORLD.components.seasonmanager={}
            for _,name in ipairs({"SetMildLength","SetWetLength","SetGreenLength","SetDryLength"}) do
                WORLD.components.seasonmanager[name]=function() setters=setters+1 end
            end
            init("prefab","shipwrecked",WORLD)
            run_tasks()
            assert(setters==(SIS_CONFIG.season_length=="70_days" and 4 or 0))
        ''')
        assert list(lua.globals().DAYS.values()) == expected


def casino():
    lua = runtime('{casino_landing=true}')
    lua.execute('''
        Class=function(ctor)
            local class={}; class.__index=class
            return setmetatable(class,{__call=function(_,inst)
                local self=setmetatable({},class); ctor(self,inst); return self
            end})
        end
        local Island=dofile(MOD_ROOT .. "/scripts/components/sisland.lua")
        -- Three separate islands, each three tiles wide.
        local m={}
        m.GetTileCoordsAtPoint=function(_,x,y,z) return math.floor(x/4),math.floor(z/4) end
        m.GetTileCenterPoint=function(_,x,y,z) return math.floor(x/4)*4,0,math.floor(z/4)*4 end
        m.GetTileAtPoint=function(self,x,y,z)
            local tx,tz=self:GetTileCoordsAtPoint(x,y,z)
            return tz==0 and ((tx>=0 and tx<=2) or (tx>=10 and tx<=12)
                or (tx>=20 and tx<=22)) and 1 or 2
        end
        m.IsWater=function(_,t) return t==2 end
        WORLD.Map=m; WORLD.StartUpdatingComponent=function() end
        local function new(enabled)
            local c=Island(WORLD); c.allow_casino=enabled
            WORLD.components.sisland=c; return c
        end
        local machine={prefab="slotmachine",IsValid=function() return true end,
            Transform={GetWorldPosition=function() return 44,0,0 end}}
        Ents={machine}
        local c=new(true); assert(c:Initialize(0,0))
        assert(c:IsAllowed(0,0) and c:IsAllowed(48,0))
        assert(not c:IsAllowed(80,0) and c:IsForbidden(80,0))
        assert(not c:IsForbidden(40,4) and c:CountTiles()==3)
        local data=c:OnSave()
        Ents={}; local restored=new(true); restored:OnLoad(data)
        assert(restored:IsAllowed(48,0))
        local disabled=new(false); disabled:OnLoad(data)
        assert(disabled:IsForbidden(48,0) and disabled:IsAllowed(0,0))
        local safe=disabled:GetSafePoint({_sis_land={48,0}},false)
        assert(disabled:IsAllowed(safe[1],safe[2]))
        local old={tiles=data.tiles,home=data.home,seahome=data.seahome}
        local upgraded=new(true); upgraded:OnLoad(old)
        -- Machine restores after world OnLoad: its prefab callback fills the map.
        machine.DoTaskInTime=function(_,delay,fn) queue_task(fn) end
        init("prefab","slotmachine",machine); run_tasks()
        assert(upgraded:IsAllowed(48,0) and upgraded:IsForbidden(80,0))
        assert(ACTIONS.DISMOUNT.fn({action=ACTIONS.DISMOUNT,pos={x=48,z=0}})=="vanilla")
        assert(ACTIONS.DISMOUNT.fn({action=ACTIONS.DISMOUNT,pos={x=80,z=0}})==false)
        assert(ACTIONS.BLINK.fn({action=ACTIONS.BLINK,pos={x=48,z=0}})=="vanilla")
        assert(ACTIONS.BLINK.fn({action=ACTIONS.BLINK,pos={x=80,z=0}})==false)
        assert(ACTIONS.TRAVEL.fn({action=ACTIONS.TRAVEL,target={prefab="volcano"}})==false)
        local driver={inst={},OnDismount=function() return "vanilla" end}
        init("component","driver",driver)
        assert(driver:OnDismount(false,{x=48,z=0},false)=="vanilla")
        assert(driver:OnDismount(false,{x=80,z=0},false)==false)
        local staff={CanBlinkToPoint=function() return true end}
        init("component","blinkstaff",staff)
        assert(staff:CanBlinkToPoint({x=48,z=0}) and not staff:CanBlinkToPoint({x=80,z=0}))
        local calls=0; local original=upgraded.RefreshCasinoIslands
        upgraded.RefreshCasinoIslands=function(self) calls=calls+1; original(self) end
        upgraded:OnUpdate(); upgraded:OnUpdate(); assert(calls==0)
        WORLD.components.sisland=disabled
        local px,pz=48,0
        local player={prefab="woodlegs",components={},
            DoPeriodicTask=function() end,ListenForEvent=function() end,
            Transform={GetWorldPosition=function() return px,0,pz end,
                SetPosition=function(_,x,y,z) px,pz=x,z end}}
        for _,callback in ipairs(HOOKS.player) do callback(player) end
        player.OnLoad(player,{sis_safe_land={48,0}})
        assert(disabled:IsAllowed(px,pz))
    ''')


def spiders():
    for existing_coastal in [True, False]:
        lua = runtime()
        lua.globals().EXISTING_COASTAL = existing_coastal
        lua.execute('''
            GROUND={INVALID=-1,IMPASSABLE=-2}
            WORLD.Map={
                GetTileAtPoint=function(_,x,y,z) return math.abs(x)>=40 and 2 or 1 end,
                IsWater=function(_,t) return t==2 end,
                GetTileCoordsAtPoint=function(_,x,y,z) return x/4,z/4 end,
                GetTileCenterPoint=function(_,x,y,z) return x,0,z end,
            }
            local moved=0
            for i=1,5 do
                local x=EXISTING_COASTAL and i==1 and 28 or 0
                local e={IsValid=function() return true end,ListenForEvent=function() end}
                e.Transform={GetWorldPosition=function() return x,0,0 end,
                    SetPosition=function(_,nx,y,z) x=nx; moved=moved+1 end}
                init("prefab","spiderden",e)
                Ents[i]=e
            end
            run_tasks()
            assert(moved==(EXISTING_COASTAL and 0 or 1))
        ''')


def trading():
    lua = runtime()
    lua.execute('''
        local events={}
        local t={enabled=true,Enable=function(self) self.enabled=true end,
            Disable=function(self) self.enabled=false end,
            OnSave=function(self) return {enabled=self.enabled} end,
            OnLoad=function(self,data) self.enabled=data.enabled end}
        local e={components={trader=t},AnimState={
            PlayAnimation=function() end, IsCurrentAnimation=function() return true end},
            SoundEmitter={PlaySound=function() end},
            RemoveEventCallback=function() end,
            ListenForEvent=function(_,name,fn) events[name]=fn end}
        e.event_listening={daytime={[WORLD]={function() t:Enable() end}},
            nighttime={[WORLD]={function() t:Disable() end}}}
        t.CanAccept=function(self,item) return self.enabled and item.acceptable end
        t.onaccept=function(inst)
            t:Disable(); inst.happy=true
            inst.endhappytask={Cancel=function() end}
        end
        t.AcceptGift=function(self,giver,item)
            if not self:CanAccept(item,giver) then return false end
            self.onaccept(e,giver,item); return true
        end
        e.DoTaskInTime=function(_,delay,fn)
            e.pending=fn; return {Cancel=function() end}
        end
        init("prefab","octopusking",e)
        local permanent={acceptable=true,components={}}
        local food={acceptable=true,components={edible={}}}
        local stale={acceptable=true,components={perishable={}}}
        local function finish() NOW=NOW+10; e.pending() end
        assert(t:AcceptGift({},permanent))
        assert(not t:AcceptGift({},permanent) and not t:CanAccept(food,{}))
        finish(); assert(t:CanAccept(permanent,{}))
        assert(t:AcceptGift({},food)); finish()
        assert(not t:CanAccept(food,{}) and not t:CanAccept(stale,{}))
        assert(t:AcceptGift({},permanent)); finish()
        assert(not t:CanAccept(food,{}))
        local saved=t:OnSave(); assert(saved.sis_food_allowed==false)
        t:OnLoad(saved); assert(not t:CanAccept(food,{}))
        events.daytime(); assert(t:CanAccept(food,{}))
        assert(t:AcceptGift({},permanent))
        events.nighttime(); assert(not t:CanAccept(permanent,{}))
        finish(); assert(t:CanAccept(permanent,{}) and not t:CanAccept(food,{}))
    ''')


for name, fn in [
    ("Lua 5.1 syntax and fourteen settings/defaults", syntax_and_metadata),
    ("Chinese/English sandbox metadata, saved language, UI help and gameplay messages", internationalization),
    ("non-Shipwrecked isolation and explicit false settings", isolation_and_toggles),
    ("gem multipliers/caps and fifth-dig gold guarantee", treasure),
    ("70-day cycle versus original 72-day timing", seasons),
    ("whole casino island, other islands, save/load and option changes", casino),
    ("coastal spiderden: zero or at most one move", spiders),
    ("octopus animation lock, daily food gate and save/load", trading),
]:
    check(name, fn)
from hamlet_checks import run_checks as run_hamlet_checks
run_hamlet_checks(runtime, check)
from excavation_checks import run_checks as run_excavation_checks
run_excavation_checks(runtime, check)
from interior_checks import run_checks as run_interior_checks
run_interior_checks(runtime, check)
from asset_checks import run_checks as run_asset_checks
run_asset_checks(runtime, check)
print("All checks passed. In-game verification is still required.")
