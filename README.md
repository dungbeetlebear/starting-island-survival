# 初始岛生存

《饥荒》单机海难模组。当前版本 **2.0**，从新建海难世界开始使用。

- `mod/`：本地测试及 Steam 创意工坊上传文件。
- `WORKSHOP_DESCRIPTION.md`：中英文工坊介绍，按玩家提供的文案整理。
- `tests/`：Lua 5.1 逻辑及本机原版脚本集成检查。

游戏安装目录及存档由玩家管理，本仓库不自动覆盖。

## 代码结构

| 文件 | 职责 |
| --- | --- |
| `modmain.lua` | 模块加载顺序 |
| `sis_config.lua` / `sis_runtime.lua` | 设置、海难作用域和共享入口 |
| `sis_world.lua` / `components/sisland.lua` | 世界规则、出生岛范围及世界记录 |
| `sis_access.lua` / `sis_player.lua` | 操作限制、传送落点、角色及复活救援 |
| `sis_treasure.lua` | 宝藏概率、出金记录及保底 |
| `sis_hamlet.lua` / `sis_bandits.lua` | 哈姆雷特生物、商店、市政厅和盗贼 |
| `sis_trade.lua` / `sis_vacuum.lua` | 章鱼王交易和鱼骨吸入 |
| `sis_spiders.lua` / `sis_timers.lua` | 蜘蛛巢数量及倒计时 |
| `sis_characters.lua` | 开局物品与思维帽配方 |
| `sis_i18n.lua` / `sis_assets.lua` | 界面语言及资源声明 |

模组通过 `SIS.Add*PostInit` 显式注册海难回调，岛屿规则集中在 `sisland`，其他功能读取同一份世界状态。

## 检查

```powershell
python -m pip install --target .tools/python lupa
python tests/run_checks.py
```

本机原版脚本默认位于 `D:/soft/Steam/steamapps/common/dont_starve/data`，也可用 `DS_DATA_DIR` 指定。没有游戏源码时跳过相应集成检查。测试不会启动游戏或修改存档，图形显示和完整游玩仍需实机验证。

## 版本与存档

2.0清理了旧版本的个人挖宝记录迁移及历史标志，要求新档；这一版内的正常存读档、配置选择和已生成内容的恢复仍受支持。蜘蛛巢配置为不调整或至少1至5个，默认1个。其余玩法见 `mod/README.md`。

源码与讨论：https://github.com/dungbeetlebear/starting-island-survival
