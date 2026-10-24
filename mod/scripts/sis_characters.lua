local G=GLOBAL
local active = SIS.GetIsland

SIS.AddPlayerPostInit(function(p)
    if not active() or p.prefab=="woodlegs" then return end
    -- Let the original new-world inventory grant run once. Never give items
    -- from a periodic task or OnLoad, which would duplicate them on every load.
    local inv=p.components.inventory
    if inv then
        local items={}
        for _,name in ipairs(inv.starting_inventory or {}) do items[#items+1]=name end
        local function add(name)
            for _,v in ipairs(items) do if v==name then return end end
            items[#items+1]=name
        end
        add("woodlegshat")
        if p.prefab~="wickerbottom" then add("shovel") end
        inv.starting_inventory=items
    end

    -- LOST recipes are known while wearing the Brain of Thought. Retain
    -- the captain's original nautical tab, materials and boat placement data.
    local hat=G.Recipe("woodlegshat",{G.Ingredient("fabric",3),G.Ingredient("boneshard",4),G.Ingredient("dubloon",10)},
        G.RECIPETABS.NAUTICAL,G.TECH.LOST,G.RECIPE_GAME_TYPE.SHIPWRECKED,nil,nil,true)
    local boat=G.Recipe("woodlegsboat",{G.Ingredient("boatcannon",1),G.Ingredient("boards",4),G.Ingredient("dubloon",4)},
        G.RECIPETABS.NAUTICAL,G.TECH.LOST,G.RECIPE_GAME_TYPE.SHIPWRECKED,"woodlegsboat_placer",nil,true,nil,true,4)
    hat.sortkey=1
    boat.sortkey=2
    G.GetAllRecipes(true)

end)
