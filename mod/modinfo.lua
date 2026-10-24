-- modinfo has locale but no GLOBAL, require or standard Lua libraries.
sis_i18n = {
    zh = {
        name = "初始岛生存",
        description = "仅限海难：只能在出生岛和海上活动。\n非船长出生自带幸运帽。\n交易冷却、金块保底、宝石倍率可配置。\n季节、蜘蛛巢靠岸、赌博机岛登陆可配置。\n退格查看重要倒计时。",
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
        },
        messages = {
            home_only = "只能登陆出生岛。",
            home_casino_only = "只能登陆出生岛和赌博机岛。",
        },
    },
    en = {
        name = "Starting Island Survival",
        description = "Shipwrecked: stay on your home island or at sea.\nNon-Woodlegs start with a Lucky Hat.\nConfigure trades, gold pity and gem odds.\nSet seasons, coastal nests and casino access.\nBackspace: event timers.",
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
version = "1.s"
api_version = 6
priority = -10
dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = true
hamlet_compatible = false
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
}
for i=1,#configuration_options do
    local option = configuration_options[i]
    local translation = text.config[option.name]
    option.label = translation.label
    option.hover = translation.hover
    for j=1,#option.options do option.options[j].description = translation.options[j] end
end
