GLOBAL=_G
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
HOOKS={component={},prefab={},player={}}
local function register(kind,name,fn)
    HOOKS[kind][name]=HOOKS[kind][name] or {}
    table.insert(HOOKS[kind][name],fn)
end
AddComponentPostInit=function(name,fn) register("component",name,fn) end
AddPrefabPostInit=function(name,fn) register("prefab",name,fn) end
AddPlayerPostInit=function(fn) table.insert(HOOKS.player,fn) end
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
    return original_require(name)
end
modimport=function(path) return dofile(MOD_ROOT.."/"..path) end
