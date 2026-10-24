# 逻辑检查

使用 Python 和 `lupa` 的 Lua 5.1 运行时。在工作区根目录运行：

```powershell
python -m pip install --target .tools/python lupa
python tests/run_checks.py
```

本工作区已在 `.tools/python` 准备好检查依赖，不属于上传内容。

检查包含：全部 Mod Lua 文件语法、六项设置的默认值、非海难世界隔离、显式关闭设置、七档宝石倍率与概率上限、第五次挖宝保底、船长例外、四季时序、赌博机岛范围、读档后开关变更、蜘蛛巢搬动数量、章鱼王动画锁及食物每日额度。

这些检查使用模拟的游戏对象，不会启动游戏或修改存档。仍需在游戏内确认设置界面、交易动画和完整游玩行为。
