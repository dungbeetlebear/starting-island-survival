-- modinfo has locale but no GLOBAL, require or standard Lua libraries.
sis_i18n = {
    zh = {
        name = "初始岛生存",
        description = "仅限海难：只能在出生岛和海上活动。\n非船长出生自带幸运帽。\n交易、保底、季节与登陆等可配置。\n可选哈姆雷特挖宝、城镇和商店拓展。\n退格查看重要倒计时。",
        config = {
            language = {
                label = "语言 / Language",
                hover = "选择跟随游戏、中文或英文。保存后重新打开配置页刷新文字，进入世界后应用游戏提示。退格调试面板使用英文，避免原版调试字体缺字。",
                options = {"跟随游戏 / Auto", "中文", "English"},
            },
            octopus_no_cooldown = {
                label = "章鱼王交易",
                hover = "仅无新鲜度、非食物物品可取消每日冷却；仍需等待交易动画和奖励完成。食物保留原版每日额度。",
                options = {"无每日冷却", "原版冷却"},
            },
            gold_guarantee = {
                label = "挖宝金块保底",
                hover = "非船长前四次挖宝未出金块时，第五次使用含3个金块的原版宝藏。关闭时仍记录挖宝历史，重新开启不重置次数。",
                options = {"有保底", "无保底"},
            },
            casino_landing = {
                label = "赌博机岛登陆",
                hover = "允许时可登陆赌博机所在的整座岛；其他岛屿仍受独岛限制。关闭后，岛上的角色读档时返回允许的安全位置。",
                options = {"不可登陆", "可以登陆"},
            },
            gem_multiplier = {
                label = "黄绿宝石倍率",
                hover = "仅调整幸运帽宝藏的黄、绿宝石概率。1倍为原版，概率最高100%；普通宝藏不受影响。",
                options = {"1倍（原版）", "1.5倍", "2倍", "3倍", "4倍", "5倍", "10倍"},
            },
            season_length = {
                label = "季节时间",
                hover = "70天：温和季20、风季15、雨季20、火山季15天。原版时间保留游戏换季时序及世界季节设置。",
                options = {"原版时间", "70天（15/15）"},
            },
            coastal_spiderden = {
                label = "蜘蛛巢靠岸",
                hover = "全图至少一个巢在船炮射程内。已有符合条件的巢时不搬动，否则最多移动一个；关闭不复原旧档位置。",
                options = {"至少一个", "不调整"},
            },
            alloy_deconstruction = {
                label = "铸铁块拆解",
                hover = "允许拆解法杖将每个铸铁块分解为4个铁矿石，保留原版法杖消耗；不添加可制作配方。需要哈姆雷特内容。",
                options = {"关闭", "开启"},
            },
            fishbone_vacuum = {
                label = "豹卷风吸鱼骨",
                hover = "允许豹卷风吸入地上的鱼骨，背包和手持鱼骨不受影响；死亡或移除时释放鱼骨。关闭恢复原版。",
                options = {"允许吸入", "原版"},
            },
            hamlet_treasure_creatures = {
                label = "挖宝哈姆雷特怪物",
                hover = "铲子、风向标、船炮和爆炸挖宝均生效。原怪物名额均分给有攻击力的小型生物，不增加总量，排除无辜动物和大型生物；捕蝇草最小，雷鸟无电。需要安装哈姆雷特。",
                options = {"关闭", "开启"},
            },
            island_bandits = {
                label = "城镇盗贼猪人",
                hover = "初始岛至少3栋住宅或商店，歪斜小木屋不计数。沿用哈姆雷特钱币、城市地皮、附近城镇猪屋、昼夜概率和冷却规则；宝藏仅在初始岛。需要哈姆雷特。",
                options = {"关闭", "开启"},
            },
            townhall_mayor = {
                label = "市政厅自带市长",
                hover = "新建玩家市政厅的室内自带一位市长，随房间保存，读档不重复生成；不补发旧市政厅。需要哈姆雷特内容。",
                options = {"关闭", "开启"},
            },
            treasure_materials = {
                label = "挖宝植物材料",
                hover = "铲子、风向标、船炮和爆炸挖宝均生效。在含纸张或绳索的随机资源池加入树篱修剪物和荧光果，抽中时各1至2个；赌博机直接奖励不变。需要哈姆雷特。",
                options = {"关闭", "开启"},
            },
            shop_horns = {
                label = "奇物店出售角",
                hover = "售卖龙鳞的奇物商店加入守护者之角（50呼噜币）和河鹿角（30呼噜币），与原商品均匀抽取；刷新后可能上架。需要哈姆雷特。",
                options = {"关闭", "开启"},
            },
        },
        messages = {
            home_only = "只能登陆出生岛。",
            home_casino_only = "只能登陆出生岛和赌博机岛。",
        },
    },
    en = {
        name = "Starting Island Survival",
        description = "Shipwrecked: stay on your home island or at sea.\nNon-Woodlegs start with a Lucky Hat.\nConfigure trades, gold pity, seasons and access.\nOptional Hamlet treasure, town and shop features.\nBackspace: event timers.",
        config = {
            language = {
                label = "语言 / Language",
                hover = "Use the game language, Chinese or English. Apply and reopen this menu to refresh text; re-enter the world for gameplay messages. Debug timers stay in English to avoid missing font glyphs.",
                options = {"Auto / 跟随游戏", "中文", "English"},
            },
            octopus_no_cooldown = {
                label = "Octopus trades",
                hover = "Remove the daily limit only for non-food items without freshness. Wait for the trade animation and reward to finish. Food keeps its vanilla daily limit.",
                options = {"No daily limit", "Vanilla limit"},
            },
            gold_guarantee = {
                label = "Gold guarantee",
                hover = "For non-Woodlegs: if the first four digs yield no gold, the fifth uses a vanilla preset with 3 gold nuggets. Dig history is still recorded while disabled; toggling does not reset it.",
                options = {"Guaranteed", "Vanilla"},
            },
            casino_landing = {
                label = "Casino landing",
                hover = "Allow landing anywhere on the slot machine's island. Other islands remain blocked. Disable to return players on that island to a permitted safe point on load.",
                options = {"Blocked", "Allowed"},
            },
            gem_multiplier = {
                label = "Gem chance",
                hover = "Yellow and green gem chance in Lucky Hat treasures only. 1x is vanilla; chances cap at 100%. Ordinary treasures are unchanged.",
                options = {"1x (vanilla)", "1.5x", "2x", "3x", "4x", "5x", "10x"},
            },
            season_length = {
                label = "Season length",
                hover = "70-day year: Mild 20, Hurricane 15, Monsoon 20, Dry 15 days. Vanilla keeps the original season transitions and world season settings.",
                options = {"Vanilla", "70-day year"},
            },
            coastal_spiderden = {
                label = "Coastal nests",
                hover = "Ensure at least one spider den is in boat cannon range. Move none if one already qualifies; otherwise move at most one. Disabling does not undo saved positions.",
                options = {"At least one", "Unchanged"},
            },
            alloy_deconstruction = {
                label = "Alloy salvage",
                hover = "Deconstruction Staff: one Alloy returns 4 Iron Ore, with vanilla staff costs. Adds no crafting recipe. Hamlet content required.",
                options = {"Off", "On"},
            },
            fishbone_vacuum = {
                label = "Fishbone vacuum",
                hover = "Sealnado can inhale ground Fishbones, releasing them on death or removal. Held Fishbones remain safe. Off restores vanilla behavior.",
                options = {"Allowed", "Vanilla"},
            },
            hamlet_treasure_creatures = {
                label = "Treasure monsters",
                hover = "Shovels, wind staffs, cannons and explosions share monster slots equally with small attacking Hamlet creatures. No innocent wildlife or large creatures. Small Flytraps, non-electric Thunderbirds. Hamlet required.",
                options = {"Off", "On"},
            },
            island_bandits = {
                label = "Town bandits",
                hover = "Require 3+ home-island homes/shops, excluding Slanty Shanties. Use Hamlet's money, city ground, nearby town-pig-house cover, day/night odds and cooldown rules. Treasure stays on the starting island. Hamlet required.",
                options = {"Off", "On"},
            },
            townhall_mayor = {
                label = "Town Hall mayor",
                hover = "New player Town Halls include one indoor mayor, saved with the room. No duplicate on reload or retrofit of old halls. Hamlet content required.",
                options = {"Off", "On"},
            },
            treasure_materials = {
                label = "Plant loot",
                hover = "Shovels, wind staffs, cannons and explosions: add Clippings and Light Bulbs to treasure pools with Papyrus/Rope, 1-2 each when selected. Direct slot-machine prizes unchanged. Hamlet required.",
                options = {"Off", "On"},
            },
            shop_horns = {
                label = "Shop horns",
                hover = "The Antiques shop may stock Guardian's Horn (50 Oincs) and Hippopotamoose Antler (30), equally with existing stock on restock. Hamlet content required.",
                options = {"Off", "On"},
            },
        },
        messages = {
            home_only = "You can only land on your starting island.",
            home_casino_only = "You can only land on your starting island or the casino island.",
        },
    },
}

-- Saved language overrides are applied by sis_i18n.lua once settings load.
local chinese = locale == "zh" or locale == "zhr" or locale == "zht"
    or locale == "zh_CN" or locale == "zh_TW" or locale == "zh-CN" or locale == "zh-TW"
local text = sis_i18n[chinese and "zh" or "en"]
name = text.name
description = text.description
author = "Starting Island Survival"
version = "1.w"
api_version = 6
priority = -10
dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = true
-- Hamlet-compatible Shipwrecked saves can have ONLY the Hamlet flag enabled.
-- This permits the engine to load the mod for that content pack; sis_config
-- still scopes all gameplay to the actual Shipwrecked world prefab.
hamlet_compatible = true
dst_compatible = false
forumthread = ""
icon_atlas = "modicon.xml"
icon = "modicon.tex"
server_filter_tags = {"shipwrecked", "starting island", "single island", "独岛生存"}

-- Stable names, data and defaults preserve settings from previous versions.
configuration_options = {
    {name="language", default="auto", options={{data="auto"}, {data="zh"}, {data="en"}}},
    {name="octopus_no_cooldown", default=true, options={{data=true}, {data=false}}},
    {name="gold_guarantee", default=true, options={{data=true}, {data=false}}},
    {name="casino_landing", default=false, options={{data=false}, {data=true}}},
    {name="gem_multiplier", default=2, options={{data=1}, {data=1.5}, {data=2}, {data=3}, {data=4}, {data=5}, {data=10}}},
    {name="season_length", default="70_days", options={{data="vanilla"}, {data="70_days"}}},
    {name="coastal_spiderden", default=true, options={{data=true}, {data=false}}},
    {name="alloy_deconstruction", default=false, options={{data=false}, {data=true}}},
    {name="fishbone_vacuum", default=true, options={{data=true}, {data=false}}},
    {name="hamlet_treasure_creatures", default=false, options={{data=false}, {data=true}}},
    {name="island_bandits", default=false, options={{data=false}, {data=true}}},
    {name="townhall_mayor", default=false, options={{data=false}, {data=true}}},
    {name="treasure_materials", default=false, options={{data=false}, {data=true}}},
    {name="shop_horns", default=false, options={{data=false}, {data=true}}},
}
for i=1,#configuration_options do
    local option = configuration_options[i]
    local translation = text.config[option.name]
    option.label = translation.label
    option.hover = translation.hover
    for j=1,#option.options do option.options[j].description = translation.options[j] end
end
