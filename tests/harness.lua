GLOBAL=_G
modname="workshop-3824478922"
LOC={GetLocaleCode=function() return GAME_LOCALE or "en" end}
function load_modinfo()
    local info={locale=LOC.GetLocaleCode()}
    local fn=assert(loadfile(MOD_ROOT.."/modinfo.lua"))
    setfenv(fn,info)()
    return info
end
modinfo=load_modinfo()
for _,option in ipairs(modinfo.configuration_options) do
    if CONFIG[option.name]~=nil then option.saved=CONFIG[option.name] end
end
KnownModIndex={savedata={known_mods={[modname]={modinfo=modinfo}}}}
function KnownModIndex:GetModInfo(name)
    return self.savedata.known_mods[name] and self.savedata.known_mods[name].modinfo
end
function KnownModIndex:UpdateConfigurationOptions(options,saved)
    for _,v in ipairs(saved or {}) do
        for _,k in ipairs(options) do
            if v.name==k.name and v.saved~=nil then k.saved=v.saved end
        end
    end
end
function KnownModIndex:LoadModConfigurationOptions(name)
    local options=self:GetModInfo(name).configuration_options
    if SAVED_CONFIG then self:UpdateConfigurationOptions(options,SAVED_CONFIG) end
    return options
end
function KnownModIndex:SaveConfigurationOptions(callback,name,settings)
    SAVED_CONFIG=settings
    callback()
    self:LoadModConfigurationOptions(name)
end
WORLD={prefab=MODE,components={sisland={ready=true}}}
NOW=0
GetTime=function() return NOW end
GetWorld=function() return WORLD end
GetPlayer=function() return nil end
GetDebugString=function() return "vanilla" end
GetModConfigData=function(name) return CONFIG[name] end
SaveGameIndex={GetCurrentSaveSlot=function() return 1 end,
    GetCurrentMode=function() return MODE end,
    IsModeShipwrecked=function() return MODE=="shipwrecked" or MODE=="volcano" end}
TUNING={}
FRAMES=1/30
GROUND={INVALID=-1,IMPASSABLE=-2}
Ents={}
ACTIONS={}
for _,name in ipairs({"DISMOUNT","BLINK","MOUNT","SEARCH","TRAVEL","ACTIVATE","JUMPIN","GIVE"}) do
    ACTIONS[name]={fn=function() return "vanilla" end}
end
HOOKS={component={},prefab={},player={},class={}}
local function register(kind,name,fn)
    HOOKS[kind][name]=HOOKS[kind][name] or {}
    table.insert(HOOKS[kind][name],fn)
end
AddComponentPostInit=function(name,fn) register("component",name,fn) end
AddPrefabPostInit=function(name,fn) register("prefab",name,fn) end
AddPlayerPostInit=function(fn) table.insert(HOOKS.player,fn) end
AddClassPostConstruct=function(name,fn) register("class",name,fn) end
function init(kind,name,inst)
    for _,fn in ipairs(HOOKS[kind][name] or {}) do fn(inst) end
end
function near(a,b) assert(math.abs(a-b)<1e-9,tostring(a).." ~= "..tostring(b)) end
local tasks={}
function queue_task(fn) tasks[#tasks+1]=fn end
WORLD.DoTaskInTime=function(_,delay,fn) queue_task(fn) end
function run_tasks()
    local count=0
    while #tasks>0 do
        local fn=table.remove(tasks,1); fn(WORLD)
        count=count+1; assert(count<10000,"task loop")
    end
end
LOOT={sample={chance_loot={yellowgem=.2,greengem=.1,redgem=.4},
    random_loot={yellowgem=2,greengem=1,redgem=4,bluegem=3}},gems={loot={goldnugget=3}}}
GetTreasureLootDefinition=function(name) return LOOT[name] end
SpawnTreasureChest=function(name,dropper)
    local def=GetTreasureLootDefinition(name)
    if def and def.custom_lootfn then def.custom_lootfn(def.loot or {}) end
    return def
end
local original_require=require
require=function(name)
    if name=="map/treasurehunt" then return true end
    if name=="widgets/text" then
        return function(font,size,text)
            return {font=font,size=size,text=text,
                SetString=function(self,value) self.text=value end,
                SetPosition=function() end,SetRegionSize=function() end,SetHAlign=function() end}
        end
    end
    return original_require(name)
end
modimport=function(path) return dofile(MOD_ROOT.."/"..path) end
