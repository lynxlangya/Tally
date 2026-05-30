# [P2] App 图标去除 alpha 通道（兜底规避 ITMS-90717）

> 关联：上线前只读扫描 P2-1 · 建议分支 `issue/020-icon-flatten-alpha` · 工作量 S
> 范围：`Tally/Assets.xcassets/*.appiconset/icon-1024.png`。发布整改任务，不受 UI 重构禁区约束。
> 性质：**这条我已从 P1 降级为 P2，请 codex 给独立第二意见——到底要不要改。**

## 背景 / Why

App Store 营销图标不允许含 alpha / 透明通道（否则可能触发上传校验 ITMS-90717）。源 PNG 当前是 RGBA（带 alpha 通道）。但编译产物里 actool 已把图标标记为不透明，所以**实际很可能不会被拦**——这正是需要复核的点。

## 证据 / Evidence

- 源图带 alpha：
  ```bash
  sips -g hasAlpha -g format Tally/Assets.xcassets/AppIcon.appiconset/icon-1024.png
  # hasAlpha: yes / format: png（8-bit RGBA）
  ```
- 编译产物已不透明（来自上次 build 的 DerivedData）：
  ```bash
  APP=$(ls -d ~/Library/Developer/Xcode/DerivedData/Tally-*/Build/Products/Debug-iphonesimulator/Tally.app | head -1)
  xcrun --sdk iphoneos assetutil --info "$APP/Assets.car" | grep -A2 -i appicon
  # 渲染项标记 "Opaque": true（主图标 + 3 个备用图标 AppIconInk/InkNote/Moon 同）
  ```
- 备用图标在 [Tally/Info.plist](../../Tally/Info.plist) 的 `CFBundleAlternateIcons` 注册（AppIconInk / AppIconInkNote / AppIconMoon）。

## 复核点 / codex 先判断

- `Assets.car` 中 `Opaque: true` 是否足以认定"上传不会被 ITMS-90717 拦"？
  - 若**认同**：可将本 issue 标记为"无需改/低优先"，只在 PR/评论写明依据后关闭。
  - 若**保守**：按下面"修复"把 4 个源图压平为不透明 RGB。

## 修复 / Do（若决定改）

把以下 4 个文件重新导出为**不带 alpha 的 RGB** PNG（视觉不变，底色铺成图标原本的背景色）：

- `Tally/Assets.xcassets/AppIcon.appiconset/icon-1024.png`
- `Tally/Assets.xcassets/AppIconInk.appiconset/icon-1024.png`
- `Tally/Assets.xcassets/AppIconInkNote.appiconset/icon-1024.png`
- `Tally/Assets.xcassets/AppIconMoon.appiconset/icon-1024.png`

参考压平命令（择一，需肉眼复核底色正确）：
```bash
# 用 sips 重采样到 RGB（可能需先确认背景色）
sips -s format png --deleteColorManagementProperties in.png --out out.png
# 或用 ImageMagick 压白底/指定底色：
magick in.png -background '#<icon-bg-hex>' -alpha remove -alpha off out.png
```

## 验收 / Done when

- [ ] 4 个 `icon-1024.png` 的 `sips -g hasAlpha` 均为 `no`
- [ ] 图标视觉无可见差异（肉眼 / 与 `design/` 参考对比）
- [ ] `xcodebuild ... -scheme Tally build` 通过
- [ ] PR 写明结论：是采纳压平，还是判定"Opaque:true 已足够"而关闭

## Don't

- 不改图标视觉设计、不换图。
- 不动 `Contents.json` 的结构（单尺寸 1024 + 三外观保持）。
