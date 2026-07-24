# 薯星幸存者

一个使用 Swift、SwiftUI 和 SpriteKit 制作的原生 iOS 生存射击游戏。当前版本已经包含完整的 20 波战役、局内构筑与可保存的局外成长。

## 游戏画面

<p align="center">
  <img src="Artifacts/title-screen.png" width="22%" alt="标题与基地界面">
  <img src="Artifacts/gameplay.png" width="22%" alt="战斗画面">
  <img src="Artifacts/final-shop.png" width="22%" alt="波间商店">
  <img src="Artifacts/final-victory.png" width="22%" alt="胜利结算">
</p>

## 已实现

- 6 名可解锁角色，每名角色有不同初始武器和被动
- 8 类武器、5 级武器强化和最多 6 武器同时开火
- 18 种属性道具与可刷新的波间商店
- 7 类敌人，包含远程、分裂、重甲与 Boss
- 3 张战区地图，具有不同收益、速度和环境危险
- 20 波战役，每 5 波出现 Boss
- 无伤奖励、暴击、吸血、闪避、再生、反伤等构筑机制
- 星核结算、3 条永久升级路线和跨局存档
- 角色、地图与世界观档案的渐进解锁
- 开始、暂停、失败、胜利、再次挑战完整流程
- 射击、受击、拾取、购买、Boss 与结算程序化音效和触觉反馈
- 原创代码绘制美术与应用图标，无第三方素材依赖

## 运行

需要 Xcode 15 或更新版本，部署目标为 iOS 17.0。

1. 使用 Xcode 打开 `RogSurvivor.xcodeproj`。
2. 选择任意 iPhone 模拟器。
3. 点击 Run。

命令行构建：

```sh
xcodebuild \
  -project RogSurvivor.xcodeproj \
  -scheme RogSurvivor \
  -sdk iphonesimulator \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## 操作

- 按住屏幕任意非按钮区域，拖动虚拟摇杆移动。
- 武器会自动攻击距离最近的敌人。
- 每波倒计时结束后清理剩余敌人，即可进入商店。
- 商店中可以购买武器、升级现有武器或强化角色属性。
- 第 20 波结束后完成本轮战役。

完整的内容与平衡设计见 [GAME_DESIGN.md](GAME_DESIGN.md)。
