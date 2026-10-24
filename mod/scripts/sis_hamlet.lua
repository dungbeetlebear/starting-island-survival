local G=GLOBAL
-- Enabled DLC flags describe the selected compatibility pack, not whether its
-- installed prefabs can load. They also change while the frontend selects a save.
SIS_HAS_HAMLET=G.PORKLAND_DLC and G.IsDLCInstalled
    and G.IsDLCInstalled(G.PORKLAND_DLC) or false
SIS_DUG_TREASURE_DEPTH=0

-- Also load dependencies when options are off: creatures, maps and mayors
-- created in an earlier session must still restore safely from saved games.
if SIS_HAS_HAMLET then
    PrefabFiles=PrefabFiles or {}
    for _,name in ipairs({"mean_flytrap","antman","antman_warrior","thunderbird","pog",
        "rabid_beetle","weevole","mandrakeman","frog","snake","bill",
        "scorpion","gnat","vampirebat",
        "pigbandit","banditmap","pigbanditexit","pigman_city","clippings","lightbulb",
        "minotaurhorn","hippo_antler","iron","alloy","oinc","oinc10","armor_metal","halberd","hats"}) do
        PrefabFiles[#PrefabFiles+1]=name
    end
    modimport("scripts/sis_assets.lua")
end

local original_monsters={"spider","mosquito_poison","snake","primeape","snake_poison","hound"}
local creatures={"spider","mosquito_poison","snake","primeape","snake_poison","hound",
    "mean_flytrap","antman","antman_warrior","thunderbird","pog",
    "rabid_beetle","weevole","mandrakeman","frog_poison","snake_amphibious","bill",
    "scorpion","gnat","vampirebat"}

SIS_AdjustDugLoot=function(loot)
    if not SIS_HAS_HAMLET then return end
    if SIS_CONFIG.hamlet_treasure_creatures then
        local count=0
        for _,name in ipairs(original_monsters) do count=count+(loot[name] or 0); loot[name]=nil end
        -- Each original monster slot chooses from the same uniform pool.
        -- Neither the frequency of monster treasures nor their size increases.
        for i=1,count do
            local name=creatures[math.random(1,#creatures)]
            loot[name]=(loot[name] or 0)+1
        end
    end
    if SIS_CONFIG.treasure_materials then
        for _,name in ipairs({"clippings","lightbulb"}) do
            if (loot[name] or 0)>0 then loot[name]=math.random(1,2) end
        end
    end
end

-- Preserve native staff costs, four-ore smelting ratio and one-item stack
-- handling, using a deconstruction-only recipe rather than a craftable recipe.
if SIS_HAS_HAMLET and SIS_CONFIG.alloy_deconstruction then
    AddPrefabPostInit("shipwrecked",function()
        if not G.GetRecipe("alloy") then
            G.DeconstructRecipe("alloy",{G.Ingredient("iron",4)})
            G.GetAllRecipes(true)
        end
    end)
end

if SIS_HAS_HAMLET then
    AddPrefabPostInit("thunderbird",function(e)
        local function uncharge(inst)
            inst.cooling_down=true
            inst.charging=false
            inst.lightning_target=nil
            inst.DoLightning=function() end
            inst.special_action=function() return false end
            if not inst._sis_no_charge_events then
                inst._sis_no_charge_events=true
                local push=inst.PushEvent
                inst.PushEvent=function(self,event,...)
                    if event=="start_charging" then return end
                    return push(self,event,...)
                end
            end
            if inst.Light then inst.Light:Enable(false) end
            -- Native FX is scheduled during prefab creation, before this task.
            inst:DoTaskInTime(.2,function()
                if inst.fx then inst.fx:Remove(); inst.fx=nil end
            end)
        end
        local save,load=e.OnSave,e.OnLoad
        e.OnSave=function(inst,data,...)
            if save then save(inst,data,...) end
            data.sis_no_lightning=inst._sis_no_lightning or nil
        end
        e.OnLoad=function(inst,data,...)
            local result
            if load then result=load(inst,data,...) end
            inst._sis_no_lightning=data and data.sis_no_lightning or false
            if inst._sis_no_lightning then uncharge(inst) end
            return result
        end
        if SIS_CONFIG.hamlet_treasure_creatures and SIS_DUG_TREASURE_DEPTH>0 then
            e._sis_no_lightning=true
            uncharge(e)
        end
    end)
end

if SIS_HAS_HAMLET and SIS_CONFIG.townhall_mayor then
    AddComponentPostInit("interiorspawner",function(c)
        local create=c.CreateRoom
        c.CreateRoom=function(self,interior,width,height,depth,dungeon,room,props,...)
            local prefix="pig_shop_cityhall_player"
            if type(dungeon)=="string" and string.sub(dungeon,1,#prefix)==prefix then
                local copy,has_mayor={},false
                for _,v in ipairs(props or {}) do
                    copy[#copy+1]=v
                    if v.name=="pigman_mayor_shopkeep" then has_mayor=true end
                end
                if not has_mayor then
                    copy[#copy+1]={name="pigman_mayor_shopkeep",x_offset=-3,z_offset=4}
                end
                props=copy
            end
            -- The room owns/saves the NPC. Never spawn an extra mayor on load.
            return create(self,interior,width,height,depth,dungeon,room,props,...)
        end
    end)
end

if SIS_HAS_HAMLET and SIS_CONFIG.shop_horns then
    AddComponentPostInit("shopinterior",function(c)
        local product=c.GetNewProduct
        local stock=G.require("prefabs/pig_shop_defs").SHOPTYPES
        c.GetNewProduct=function(self,shoptype,...)
            local item=product(self,shoptype,...)
            local pool=stock[shoptype]
            if shoptype=="pig_shop_antiquities" and item and pool then
                local roll=math.random(1,#pool+2)
                if roll==#pool+1 then return {"minotaurhorn","oinc",50} end
                if roll==#pool+2 then return {"hippo_antler","oinc",30} end
            end
            return item
        end
    end)
end
