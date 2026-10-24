# 初始岛生存（单机海难）1.u

首次使用请新建海难世界。出生岛记录、最近的安全位置和挖宝记录随存档保存。

仅支持海难世界；原版大陆、巨人国、哈姆雷特、洞穴和火山内部不启用本 Mod 的玩法调整。引擎兼容声明允许海难和哈姆雷特内容包，以便“海难＋哈姆雷特兼容”的存档能加载；具体玩法仍检查实际世界类型，不会在哈姆雷特世界生效。

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
| 铸铁块拆解 | 关闭 / 开启；每块返还4铁矿石 | 关闭 |
| 豹卷风吸鱼骨 | 允许吸入 / 原版 | 允许吸入 |
| 挖宝哈姆雷特怪物 | 关闭 / 开启；小型、有攻击力的生物 | 关闭 |
| 城镇盗贼猪人 | 关闭 / 开启；沿用哈姆雷特原机制 | 关闭 |
| 市政厅自带市长 | 关闭 / 开启；新建市政厅自带一位 | 关闭 |
| 挖宝植物材料 | 关闭 / 开启；修剪物、荧光果各1至2个 | 关闭 |
| 奇物店出售角 | 关闭 / 开启；守护者之角、河鹿角 | 关闭 |

修改设置后重新进入世界生效。“原版时间”保留原版换季时序及世界季节设置；关闭蜘蛛巢调整不会复原旧档已保存的位置。金块保底关闭时仍记录挖宝历史，重新开启不会重置次数或补发已错过的第五次保底。

语言选择作用于模组名称、简介、配置及禁止登陆提示。保存后重新打开配置页可刷新配置文字；新启用 Mod 时需按原版流程重启。两列配置下方显示当前选中项的中英文说明。退格调试面板保留英文，以避免原版调试字体缺字。

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
- 默认开启金块保底：非船长亲手用铲子挖掘的前四个宝箱如果都没出现过金块，第五次改用原版gems预设，固定含3个金块。并非额外往任意箱子里塞金子。此前已出过金块则不触发保底。
- 次数和金块记录随角色保存，读档不会重置。船长保留原版。旧档在0.1.4之前的挖掘无法追溯，从更新后的挖掘开始记录。
- 出生赠品由原版新世界出生流程发放，旧档读取不补发；测试赠品需要新开世界。

## 可选哈姆雷特拓展

下列拓展均默认关闭，需要安装哈姆雷特内容，仅在海难世界生效。鱼骨吸入独立控制，默认开启。

- **铸铁块拆解**：拆解法杖每次消耗堆叠中的1个铸铁块，返还4个铁矿石，理智与法杖次数消耗沿用原版。只增加拆解规则，不加入制作配方。
- **挖宝哈姆雷特怪物**：沿用原宝藏的怪物出现机会和总数量，每个怪物名额在20种生物间等概率抽取。原有6种为蜘蛛、毒蚊、普通蛇、猿猴、毒蛇、猎犬；新增14种为最小阶段利齿捕蝇草、工蚁、兵蚁、无电雷鸟、狐狸（Pog）、狂暴甲虫、象鼻鼠虫、曼德拉长老、箭毒蛙、哈姆雷特蛇、鸭嘴豪猪、蝎子、蚊群、吸血蝙蝠。普通发光飞虫、蜣螂、孔雀、鸽子等无辜动物不加入；不含Boss和大型生物。挖出的雷鸟保持无电状态，存档重载后仍无电；普通雷鸟不受影响。这个开关同时适用于船长及其他角色，并覆盖铲子、风向标、船炮、火药、椰子炸弹及其他成功挖开埋藏宝藏的原版方式。
- **城镇盗贼猪人**：初始岛至少有3栋完好的住宅、商店、市政厅或守卫塔，歪斜小木屋不计数；随后直接沿用哈姆雷特的原版机制。原版每10秒检查，要求角色位于城市地皮，附近有可作掩体的城镇猪屋；携带钱币（含背包）越多，出现概率越高，黄昏与夜晚按原版提高，击杀后按原版冷却。原版偷窃、逃跑、重现、藏宝奖励和存档关联均保留。藏宝图指向的地点及挖出的箱子仅在初始岛，允许赌博机岛登陆也不会开放该岛藏宝。关闭后停止新的袭击，已存在的盗贼、地图及宝藏不删除。
- **市政厅自带市长**：新建玩家市政厅的室内预置一位市长，跟随房间保存；读档不重复添加，不补发旧市政厅。
- **挖宝植物材料**：向原有含纸张或绳索的随机资源池加入树篱修剪物及荧光果；每种被抽中时给1至2个。保持原宝藏的抽取次数，赌博机直接发放的奖品不变；同样覆盖铲子、风向标、船炮和爆炸。
- **奇物店出售角**：售卖龙鳞的奇物商店增加守护者之角（50呼噜币）和河鹿角（30呼噜币），刷新商品时与原商品等概率抽取，不替换已经摆出的商品。关闭后不再新增这两种商品，已有商品保留。

## 其他调整

- 默认取消章鱼王接受的非食物、无新鲜度物品的每日交易冷却，可在设置中恢复原版冷却。无冷却时每次交付后锁定给予，完整播放原版happy、grabchest、抛箱，再回到idle时解锁下一笔。清除旧睡眠回调，避免睡眠打断打捞；昼夜变化也不会中断正在进行的交易。奖励仍由原版抛箱任务生成，不能在动画期间塞入第二件物品。
- 食物的每日额度单独保存；交易非食物不会重置食物额度。没有新鲜度但带edible组件的食物也保留每日冷却。
- 幸运帽宝箱的黄绿宝石概率默认翻倍，可自行选择倍率，1倍为原版。单项概率上限100%；加权随机池达到上限时只在黄绿宝石之间按原有比例抽取。普通宝藏保留原概率。
- 默认四季20／15／20／15天，全年70天，也可选择原版时间。暴风卷风出现概率100%，保留原版时间、预警和袭击次数。
- 默认开启、可配置关闭：地上的鱼骨可被暴风卷风拉入并收纳，保留唯一物品标记及鸟切斯特关联。卷风死亡按原版掉落，非死亡移除时也会释放鱼骨；手持、背包内的鱼骨不被直接夺走。
- 全图保底一个蜘蛛巢能从海上用船炮攻击，已满足则不搬动，否则只调整一个巢。旧版已经移动并保存的巢不自动复原。
- 蜘蛛巢靠岸可关闭。船炮射程较远，小岛上多个巢天然在射程内属于正常情况，代码不会把所有巢搬向海岸。
- 退格面板显示海妖、季节事件、已摘智慧果的倒计时，采用24m 06s格式，使用ASCII单位避免调试字体缺字；海妖冷却归零或已在场时隐藏。

海妖冷却归零后仍需满足原版深海拖网条件。首雨时间为预计值。源码逻辑检查不替代完整实机游玩验证。

1.u：修复风向标、船炮、炸药等间接挖宝跳过新增掉落的问题；修复内容包状态误判和哈姆雷特兼容的海难存档跳过加载的问题。个人金块保底仍只统计角色亲手挖掘。更新测试目录后须完全退出并重启游戏；未挖开的旧宝藏也会生效。

1.t：新增7项设置；哈姆雷特小型怪物挖宝、原版城镇盗贼（藏宝限定初始岛）、铸铁块拆解、新建市政厅市长、植物材料和奇物店角均可独立开启；鱼骨吸入可关闭。新增项中英双语，详细说明移至两列设置下方。

1.s：新增跟随游戏／中文／English 语言选项，中英文名称、简介、配置、详细说明和禁止登陆提示；保存配置后刷新模组简介，并在配置右栏显示选中项的说明。

1.r：新增六项玩法设置及赌博机岛登陆例外；移除 F 自动攻击跳过墙；兼容声明及运行时检查限定为海难世界。

## English

Single-player Shipwrecked only. Choose **Language → Auto / 中文 / English** in mod configuration. Auto follows Chinese game locales and falls back to English for other languages. Apply and reopen configuration to update its text; re-enter your world for gameplay messages. Enable the mod and restart the game when first installing it.

Configuration defaults: unlimited daily Octopus King trades for non-food items without freshness; fifth-dig gold guarantee for non-Woodlegs; casino landing blocked; 2x Lucky Hat yellow/green gem chance; a 70-day year (20/15/20/15); at least one spider den within boat cannon range. Existing gameplay settings carry over unchanged. Disabling coastal nests does not undo saved positions. Ordinary treasure loot is unaffected by the gem multiplier.

The native Backspace debug panel keeps English labels and ASCII time units to avoid missing debug-font glyphs. The mod's description, configuration and landing messages support both Chinese and English. The F-key wall-skipping modification has been removed.


Version 1.t adds seven settings. **Fishbone vacuum defaults to On; all six other new settings default to Off.** Hamlet content must be installed for the Hamlet extensions, which still apply only in Shipwrecked worlds.

- Alloy salvage uses the native Deconstruction Staff: consume one Alloy from a stack, return 4 Iron Ore, and keep normal staff costs.
- Treasure monsters share the original slots equally across 20 choices: 6 original monsters plus Snaptooth Seedling (smallest stage), worker and warrior ants, non-electric Thunderbird, Pog, Rabid Beetle, Weevole, Elder Mandrake, Poison Dartfrog, Hamlet snake, Platapine, Scorpion, Gnat Swarm and Vampire Bat. No innocent wildlife, bosses or large creatures. Existing monster encounter frequency and total count are preserved, including Woodlegs digs. The non-electric Thunderbird state persists on reload.
- Town bandits use Hamlet's original money, city ground, nearby town-pig-house cover, day/night odds, stealing, escape, treasure rewards and death cooldown rules. The additional requirement is at least three intact qualifying homes/shops/guard towers on the starting island, excluding Slanty Shanties. Treasure locations and chests stay on the starting island, regardless of casino access. Disabling stops new attacks without deleting existing bandits or maps.
- Newly built player Town Halls include one indoor mayor, saved with the room. Existing halls are not retrofitted.
- Plant loot adds Clippings and Light Bulbs to dug treasure resource pools with Papyrus or Rope. Each selected material yields 1-2; direct slot-machine prizes are unchanged.
- Antiques shops may stock Guardian's Horn (50 Oincs) and Hippopotamoose Antler (30 Oincs), equally with existing stock on future restocks. Existing displayed products are preserved.


Version 1.u fixes missing optional drops when wind staff tornadoes, cannon shots or explosives excavate treasure. New loot now applies to every native completed buried-treasure excavation, while personal gold-pity history still tracks player shovel digs only. Installed Hamlet content no longer depends on the currently selected DLC flag. The engine compatibility declaration allows Hamlet-compatible Shipwrecked saves to load the mod; actual Hamlet worlds remain unaffected. Replace the local test mod and fully restart the game before testing; existing undug treasures use the updated rules.

### 盗贼概率细则 / Bandit odds

玩家物品栏和背包的呼噜币价值合计后，白天不变、黄昏乘1.5、夜间乘3，再按下表决定每次检查的概率；需同时满足初始岛至少3栋合格建筑、城市地皮和附近城镇猪屋掩体。城市地皮为郊区、石板路、基础地皮或草坪。地皮和掩体条件全部沿用原版；歪斜小木屋不计建筑数，其他岛的建筑也不计。原版难度倍率继续生效。

Native checks run every 10 seconds. Total Oinc value includes the backpack. Effective wealth is multiplied by 1.5 at dusk or 3 at night before selecting the tier below. Native city ground, nearby town-pig-house cover and difficulty modifiers still apply, in addition to the three-building requirement on the starting island.

| 有效钱币价值 / Effective Oinc value | 每次检查概率 / Chance per check |
| --- | --- |
| 0 | 0% |
| 1–9 | 1% |
| 10–49 | 2.5% |
| 50–99 | 5% |
| 100–149 | 10% |
| ≥150 | 20% |
