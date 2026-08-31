# 一起停车吧

使用 Godot 4.x 和 GDScript 开发的轻社交桌面挂机停车游戏。

项目目前处于 `0.1.0-alpha` 可玩原型阶段，已经可以完成派车、计时收益、主动召回、8 小时自动返回和本地存档闭环。

## 项目入口

- [规格索引](spec/README.md)
- [游戏机制规格](spec/game-mechanics.md)
- [视觉规格](spec/visual-spec.md)
- [开发规范](spec/development-standard.md)
- [第一版验收规范](spec/acceptance-v0.1.md)
- [Agent 协作规则](AGENTS.md)

## 运行与验证

使用 Godot 4.7.2 或兼容的 Godot 4.x 版本打开 `project.godot`，运行主场景即可开始。

自动验收命令：

```powershell
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/demo_test_runner.gd
```

当前 Demo 测试覆盖初始状态、8 小时封顶、停车与召回、满车位、重复保护、车辆购买、等级锁、目标奖励、NPC 来访、场地分成、友好贴纸、自动返回、损坏存档、存档恢复和完成里程碑。

## 当前原则

- 没有 Steam 好友或网络连接时仍可完整游玩。
- MVP 优先验证停车、收益、成长与小窗体验。
- 使用虚构车辆和本地化文本，避免品牌与语言绑定。
- 真实联机、Steam 市场和付费内容均不属于首个 MVP。
