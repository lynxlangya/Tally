# [P2] 发布前确认：iOS 26.2 最低版本 + iPad 布局 + 启动屏

> 关联：上线前只读扫描 P2-2 / P2-7 · 建议分支 `issue/024-release-confirm` · 工作量 S–M
> 范围：`Tally.xcodeproj/project.pbxproj`（配置）+ 模拟器人工回归。
> 性质：以**核对 / 报告**为主，配置类可顺手改；UI 回归需跑模拟器。

## 背景 / Why

三处发布前需要人确认的点，集中在这条里复核，避免上架后才发现：最低系统设得过高会挡掉绝大多数设备；支持 iPad 但布局未经回归；启动屏是自动空白页。

## A. iOS 26.2 最低版本是否刻意

- 证据：`IPHONEOS_DEPLOYMENT_TARGET = 26.2`，见 [project.pbxproj:460](../../Tally.xcodeproj/project.pbxproj)（Debug）与 :518（Release）；`README.md` / `CLAUDE.md` / `AGENTS.md` 均把 26.2 写为既定事实。
- 复核点：确认这是**刻意**（只面向最新系统）而非"默认跟随 Xcode 最新"误设。26.2 会把 26.0 / 26.1 及更早系统的用户全部挡在外面。
- 处理：若刻意 → 在 PR 注明、关闭本节；若误设 → 下调到目标受众的合理版本并重跑 build。

## B. iPad 布局回归

- 证据：`TARGETED_DEVICE_FAMILY = "1,2"`（[project.pbxproj:559](../../Tally.xcodeproj/project.pbxproj)，iPhone+iPad）；App 全局隐藏系统 tab bar 用自定义 tab bar + FAB（[TallyApp.swift:29](../../Tally/TallyApp.swift) `UITabBar.appearance().isHidden = true`）。
- 复核点：在 iPad 模拟器（及台前调度 / 分屏）跑一遍主要页面，确认自定义 tab bar / FAB / sheet / 列表布局不破版、不被安全区裁切。
  ```bash
  xcodebuild -project Tally.xcodeproj -scheme Tally \
    -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' build
  ```
  （机型名以 `xcrun simctl list devices available iPad` 为准）
- 处理：截图记录；若破版，单独开修复 issue（本条只负责发现+报告）。

## C. 启动屏

- 证据：`INFOPLIST_KEY_UILaunchScreen_Generation = YES`（[project.pbxproj:543](../../Tally.xcodeproj/project.pbxproj)）→ 自动空白启动屏。
- 复核点：是否要做品牌化启动屏（Logo / 底色）。属体验增强，非阻断。
- 处理：给"做/不做"结论即可；若做，范围另议。

## 验收 / Done when

- [ ] A：给出 26.2 是否刻意的结论（刻意则关闭，误设则已下调并 build 通过）
- [ ] B：iPad 主要页面截图 + 破版清单（无破版则注明"已回归通过"）
- [ ] C：启动屏"做/不做"结论
- [ ] 任何配置改动后 `xcodebuild build` 通过

## Don't

- 不在本条里重做 iPad UI（只发现+报告，破版另开 issue）。
- 改 deployment target 时记得同步 4 个 target（Tally / Widgets / Tests / UITests）一致性。
