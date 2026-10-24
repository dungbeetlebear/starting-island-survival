# 初始岛生存（单机海难）1.s

首次使用请新建海难世界。出生岛记录、最近的安全位置和挖宝记录随存档保存。

仅支持海难世界；原版大陆、巨人国、哈姆雷特、洞穴和火山内部不启用本 Mod 的玩法调整。

## Mod 设置

| 设置 | 可选项 | 默认 |
| --- | --- | --- |
| 语言 / Language | 跟随游戏 / 中文 / English | 跟随游戏 |
| 章鱼王非食物交易 | 无每日冷却 / 原版冷却 | 无每日冷却 |
| 挖宝金块保底 | 有保底 / 无保底 | 有保底 |
| 赌博机岛登陆 | 不可登陆 / 可以登陆 | 不可登陆 |
| 幸运帽黄绿宝石倍率 | 1 / 1.5 / 2 / 3 / 4 / 5 / 10倍 | 2倍 |
| 季节时间 | 原版时间 / 风季、火山季各15天，全年70天 | 全年70天 |
| 蜘蛛巢靠岸 | 至少一个 / 不调整 | 至少一个 |

修改设置后重新进入世界生效。“原版时间”保留原版换季时序及世界季节设置；关闭蜘蛛巢调整不会复原旧档已保存的位置。金块保底关闭时仍记录挖宝历史，重新开启不会重置次数或补发已错过的第五次保底。

语言选择作用于模组名称、简介、配置及禁止登陆提示。保存后重新打开配置页可刷新配置文字；新启用 Mod 时需按原版流程重启。配置右栏显示当前选中项的中英文说明。退格调试面板保留英文，以避免原版调试字体缺字。

## 独岛限制

- 鼠标、手柄和排队动作均检查登陆、闪现；其他岛不能下船。
- 可选允许登陆赌博机所在的整座连通岛屿，其他岛仍禁止登陆。赌博机岛范围与出生岛范围分别保存；关闭后，岛上的角色读档时返回允许的安全位置。
- 正常贴岸行船保留碰撞余量，不反复拉回。船被直接移到其他岛深处时才退回最近安全海面；船与船切换不能用来进入其他岛深处。
- 随机传送魔杖、传送底座与角色Teleport检查实际目标。非法落点改为出生岛安全位置，乘船状态则返回合法海面。已发生的原版耐久、理智等消耗照常结算。
- 虫洞和百慕大传送检查目标及随机偏移。指向其他岛的入口禁止使用。
- 救生衣、海豚、两栖落水救援直接创建出生岛的救援点；保留原版物品消耗、次日惩罚和状态结算。
- 远岛的复活石、肉身人偶等复活锚点在执行消耗前移到出生岛，确保延迟动画阶段不会再把角色送到其他岛。
- 火山、哈姆雷特、大陆、洞穴、冒险与传送机出口禁止使用。
- 读档、状态切换与逐帧位置校验处理击退、卷风抛出、变身和其他直接改坐标的异常落地。对绕过标准接口的任意外部脚本，纠正可能发生在下一帧，不能承诺这些脚本完全没有瞬时视觉跳变。

## 非船长开局与挖宝

- 非船长出生赠送一个幸运帽。船长和老奶奶不额外赠送铲子，其他角色赠送一把普通铲子。原版角色出生物品保留。
- 非船长佩戴思维帽时可制作海腿号和幸运帽，保留原版材料、航海栏和船的水上放置规则；幸运帽sortkey=1、海腿号sortkey=2，与船长原版位置一致；不会永久解锁配方。
- 默认开启金块保底：非船长前四次实际挖出的宝箱如果都没出现过金块，第五次改用原版gems预设，固定含3个金块。并非额外往任意箱子里塞金子。此前已出过金块则不触发保底。
- 次数和金块记录随角色保存，读档不会重置。船长保留原版。旧档在0.1.4之前的挖掘无法追溯，从更新后的挖掘开始记录。
- 出生赠品由原版新世界出生流程发放，旧档读取不补发；测试赠品需要新开世界。

## 其他调整

- 默认取消章鱼王接受的非食物、无新鲜度物品的每日交易冷却，可在设置中恢复原版冷却。无冷却时每次交付后锁定给予，完整播放原版happy、grabchest、抛箱，再回到idle时解锁下一笔。清除旧睡眠回调，避免睡眠打断打捞；昼夜变化也不会中断正在进行的交易。奖励仍由原版抛箱任务生成，不能在动画期间塞入第二件物品。
- 食物的每日额度单独保存；交易非食物不会重置食物额度。没有新鲜度但带edible组件的食物也保留每日冷却。
- 幸运帽宝箱的黄绿宝石概率默认翻倍，可自行选择倍率，1倍为原版。单项概率上限100%；加权随机池达到上限时只在黄绿宝石之间按原有比例抽取。普通宝藏保留原概率。
- 默认四季20／15／20／15天，全年70天，也可选择原版时间。暴风卷风出现概率100%，保留原版时间、预警和袭击次数。
- 地上的鱼骨可被暴风卷风拉入并收纳，保留唯一物品标记及鸟切斯特关联。卷风死亡按原版掉落，非死亡移除时也会释放鱼骨；手持、背包内的鱼骨不被直接夺走。
- 全图保底一个蜘蛛巢能从海上用船炮攻击，已满足则不搬动，否则只调整一个巢。旧版已经移动并保存的巢不自动复原。
- 蜘蛛巢靠岸可关闭。船炮射程较远，小岛上多个巢天然在射程内属于正常情况，代码不会把所有巢搬向海岸。
- 退格面板显示海妖、季节事件、已摘智慧果的倒计时，采用24m 06s格式，使用ASCII单位避免调试字体缺字；海妖冷却归零或已在场时隐藏。

海妖冷却归零后仍需满足原版深海拖网条件。首雨时间为预计值。源码逻辑检查不替代完整实机游玩验证。

1.s：新增跟随游戏／中文／English 语言选项，中英文名称、简介、配置、详细说明和禁止登陆提示；保存配置后刷新模组简介，并在配置右栏显示选中项的说明。

1.r：新增六项玩法设置及赌博机岛登陆例外；移除 F 自动攻击跳过墙；兼容声明及运行时检查限定为海难世界。

## English

Single-player Shipwrecked only. Choose **Language → Auto / 中文 / English** in mod configuration. Auto follows Chinese game locales and falls back to English for other languages. Apply and reopen configuration to update its text; re-enter your world for gameplay messages. Enable the mod and restart the game when first installing it.

Configuration defaults: unlimited daily Octopus King trades for non-food items without freshness; fifth-dig gold guarantee for non-Woodlegs; casino landing blocked; 2x Lucky Hat yellow/green gem chance; a 70-day year (20/15/20/15); at least one spider den within boat cannon range. Existing gameplay settings carry over unchanged. Disabling coastal nests does not undo saved positions. Ordinary treasure loot is unaffected by the gem multiplier.

The native Backspace debug panel keeps English labels and ASCII time units to avoid missing debug-font glyphs. The mod's description, configuration and landing messages support both Chinese and English. The F-key wall-skipping modification has been removed.
