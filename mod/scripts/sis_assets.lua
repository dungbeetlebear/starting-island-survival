-- Shipwrecked does not preload Porkland's shop/display dependencies. A normal
-- inventory icon is not an animation symbol: shelves and price signs require
-- ATLAS_BUILD for BOTH native inventory atlases before their first override.
-- Pin the native resources to this mod's load/unload lifetime; do not rewrite
-- GetInventoryItemAtlas or change shop items, prices, saves or restock timers.
Assets=Assets or {}
for _,file in ipairs({"images/inventoryimages.xml","images/inventoryimages_2.xml"}) do
    Assets[#Assets+1]=Asset("ATLAS",file)
    Assets[#Assets+1]=Asset("IMAGE",string.gsub(file,"%.xml$",".tex"))
    Assets[#Assets+1]=Asset("ATLAS_BUILD",file,256)
end
-- The Porkland world normally loads these; a Shipwrecked world never does.
Assets[#Assets+1]=Asset("SOUNDPACKAGE","sound/dontstarve_DLC003.fev")
Assets[#Assets+1]=Asset("SOUND","sound/DLC003_sfx.fsb")
Assets[#Assets+1]=Asset("SOUND","sound/DLC003_AMB_stream.fsb")

for _,name in ipairs({"shop_pedestals","shelf","shelf_slot","prop_door"}) do
    PrefabFiles[#PrefabFiles+1]=name
end
