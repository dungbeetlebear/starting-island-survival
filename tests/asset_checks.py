"""Validate native display atlas/build bindings and persisted shop images."""
from pathlib import Path
import os
import xml.etree.ElementTree as ET


def run_checks(runtime, check):
    def shop_assets():
        lua=runtime()
        assets={(a.type,a.file):a.param for a in lua.globals().Assets.values()}
        for name in ['inventoryimages','inventoryimages_2']:
            assert ('ATLAS','images/'+name+'.xml') in assets
            assert ('IMAGE','images/'+name+'.tex') in assets
            assert assets['ATLAS_BUILD','images/'+name+'.xml']==256
        for kind,file in [('SOUNDPACKAGE','sound/dontstarve_DLC003.fev'),
                          ('SOUND','sound/DLC003_sfx.fsb'),('SOUND','sound/DLC003_AMB_stream.fsb')]:
            assert (kind,file) in assets
        files=set(lua.globals().PrefabFiles.values())
        assert {'shop_pedestals','shelf','shelf_slot','prop_door'} <= files
        assert runtime(hamlet=False).eval('Assets == nil')
        game=Path(os.environ.get('DS_DATA_DIR',r'D:\soft\Steam\steamapps\common\dont_starve\data'))
        scripts=game/'DLC0003/scripts'
        if not scripts.exists():
            print('SKIP: optional native atlas display integration (set DS_DATA_DIR)')
            return
        for kind,file in assets:
            assert any((base/file).exists() for base in [game/'DLC0003',game/'DLC0002',game/'DLC0001',game]), file
        atlas_names={}
        for name in ['inventoryimages','inventoryimages_2']:
            atlas='images/'+name+'.xml'
            atlas_names[atlas]={e.attrib['name'] for e in ET.parse(game/'DLC0003'/atlas).iter('Element')}
        lua.globals().ATLAS_CONTAINS=lambda atlas,name: name in atlas_names.get(atlas,set())
        lua.execute('''
            local loaded={}
            for _,a in ipairs(Assets) do if a.type=="ATLAS_BUILD" then loaded[a.file]=true end end
            TheSim={AtlasContains=function(_,atlas,name) return ATLAS_CONTAINS(atlas,name) end}
            CHECK_SYMBOL=function(_,slot,atlas,name)
                assert(loaded[atlas],"unloaded animation atlas: "..atlas)
                assert(ATLAS_CONTAINS(atlas,name),"missing symbol: "..name)
                DRAWN[slot]={atlas=atlas,name=name}
            end
            DRAWN={}
            DISPLAY={AnimState={OverrideSymbol=CHECK_SYMBOL,ClearOverrideSymbol=function() end,
                PlayAnimation=function() end},AddTag=function() end}
        ''')
        simutil=(scripts/'simutil.lua').read_text(encoding='utf-8')
        lookup=simutil.split('local inventoryItemAtlasLookup = {}',1)[1].split('function ReplaceEntity',1)[0]
        lua.execute('local inventoryItemAtlasLookup={}'+lookup)
        pedestal=(scripts/'prefabs/shop_pedestals.lua').read_text(encoding='utf-8')
        setters=pedestal.split('local function SetImage(inst, ent)',1)[1].split('local function SpawnInventory',1)[0]
        load=pedestal.split('local function onload(inst, data)',1)[1].split('local function setobstical',1)[0]
        methods=lua.execute('local function SetImage(inst,ent)'+setters+'\nlocal function onload(inst,data)'+load+'\nreturn {image=SetImage,cost=SetCost,load=onload}')
        lua.globals().NATIVE_DISPLAY=methods
        lua.execute('''
            for _,name in ipairs({"rope","ratatouille","wormlight","hippo_antler","minotaurhorn"}) do
                local item={prefab=name,components={inventoryitem={GetImage=function() return name..".tex" end}}}
                NATIVE_DISPLAY.image(DISPLAY,item)
                assert(DRAWN.SWAP_SIGN.name==name..".tex" and DISPLAY.imagename==name)
            end
            assert(DRAWN.SWAP_SIGN.atlas=="images/inventoryimages.xml")
            NATIVE_DISPLAY.cost(DISPLAY,"oinc",30)
            assert(DRAWN.SWAP_COST.name=="cost-30.tex")
            -- An existing shop restores the two images from its existing save.
            NATIVE_DISPLAY.load(DISPLAY,{imagename="wormlight",costprefab="oinc",cost=50})
            assert(DRAWN.SWAP_SIGN.atlas=="images/inventoryimages_2.xml")
            assert(DRAWN.SWAP_SIGN.name=="wormlight.tex" and DRAWN.SWAP_COST.name=="cost-50.tex")
        ''')
        shelf=(scripts/'prefabs/shelf.lua').read_text(encoding='utf-8')
        setter=shelf.split('local function SetImage(inst, ent, slot)',1)[1].split('local function SetImageFromName',1)[0]
        lua.globals().NATIVE_SHELF=lua.execute('local function SetImage(inst,ent,slot)'+setter+'\nreturn SetImage')
        lua.execute('''
            local item={components={inventoryitem={GetImage=function() return "wormlight.tex" end}}}
            NATIVE_SHELF(DISPLAY,item,"SWAP_img1")
            assert(DRAWN.SWAP_img1.atlas=="images/inventoryimages_2.xml")
            assert(DRAWN.SWAP_img1.name=="wormlight.tex")
        ''')

    check('shop/shelf animation atlas preloads, native price/product images and saved stock restore',shop_assets)
