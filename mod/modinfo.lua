name = "初始岛生存 | Starting Island Survival"
description = [[
仅限海难：只能在出生岛和海上活动。
非船长出生自带幸运帽。
交易冷却、金块保底、宝石倍率可配置。
季节、蜘蛛巢靠岸、赌博机岛登陆可配置。
退格查看重要倒计时。
]]
author = "Starting Island Survival"
version = "1.r"
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

configuration_options = {
    {
        name = "octopus_no_cooldown",
        label = "章鱼王非食物交易",
        hover = "仅限无新鲜度、非食物物品；无每日冷却仍需等待交易动画完成。",
        options = {
            {description = "无每日冷却", data = true},
            {description = "原版冷却", data = false},
        },
        default = true,
    },
    {
        name = "gold_guarantee",
        label = "挖宝金块保底",
        hover = "非船长前四次挖宝未出金块时，第五次使用含3个金块的原版宝藏。",
        options = {
            {description = "有保底", data = true},
            {description = "无保底", data = false},
        },
        default = true,
    },
    {
        name = "casino_landing",
        label = "赌博机岛登陆",
        hover = "允许时可登陆赌博机所在的整座岛；其他岛屿仍受独岛限制。",
        options = {
            {description = "不可登陆", data = false},
            {description = "可以登陆", data = true},
        },
        default = false,
    },
    {
        name = "gem_multiplier",
        label = "幸运帽黄绿宝石倍率",
        hover = "调整幸运帽宝藏的黄、绿宝石概率，1倍为原版，单项概率最高100%。",
        options = {
            {description = "1倍（原版）", data = 1},
            {description = "1.5倍", data = 1.5},
            {description = "2倍", data = 2},
            {description = "3倍", data = 3},
            {description = "4倍", data = 4},
            {description = "5倍", data = 5},
            {description = "10倍", data = 10},
        },
        default = 2,
    },
    {
        name = "season_length",
        label = "季节时间",
        hover = "70天为温和季20、风季15、雨季20、火山季15天；原版保留游戏时序及世界设置。",
        options = {
            {description = "原版时间", data = "vanilla"},
            {description = "风季/火山季15天", data = "70_days"},
        },
        default = "70_days",
    },
    {
        name = "coastal_spiderden",
        label = "蜘蛛巢靠岸",
        hover = "保底全图至少一个巢在船炮射程内；已有符合条件的巢时不移动其他巢。",
        options = {
            {description = "至少一个", data = true},
            {description = "不调整", data = false},
        },
        default = true,
    },
}
