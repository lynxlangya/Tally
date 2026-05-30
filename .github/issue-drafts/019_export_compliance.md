# [P1] 出口合规：声明 ITSAppUsesNonExemptEncryption = NO

> 关联：上线前只读扫描 P1-1 · 建议分支 `issue/019-export-compliance` · 工作量 S
> 范围：仅 `Tally/Info.plist`。这是一条发布整改任务，**不受** `000_PLAN.md` UI 重构禁区约束。
> 性质：先复核我的判断，认同再改。

## 背景 / Why

App Store Connect 每次上传都会追问"是否使用加密"。当前仓库**未声明** `ITSAppUsesNonExemptEncryption`，会反复弹出该问询，且容易误答导致出口合规流程卡住。本应用无联网、无自定义加密，应显式声明为豁免（`NO`）。

## 证据 / Evidence

- `grep -rn "ITSAppUsesNonExemptEncryption" Tally Tally.xcodeproj TallyWidgets` → 无任何命中。
- [Tally/Info.plist](../../Tally/Info.plist) 无该键；`Tally.xcodeproj/project.pbxproj` 也无 `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption`。
- 扫描显示零联网、零第三方 SDK（无 SPM/Pods/Carthage/嵌入框架）。

## 复核点 / codex 先验证

1. 独立确认确实无网络/加密调用：
   ```bash
   grep -rn "URLSession\|dataTask\|CryptoKit\|CommonCrypto\|SecKey\|CC_SHA\|AES" Tally Shared TallyWidgets
   ```
   预期：除 DTD/SVG 噪声外无真实加密/网络。若发现真实加密用法，则"NO"不成立，**停下并说明**。

## 修复 / Do

在 [Tally/Info.plist](../../Tally/Info.plist) 顶层 `<dict>` 内加：

```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

## 验收 / Done when

- [ ] `Tally/Info.plist` 含 `ITSAppUsesNonExemptEncryption = false`
- [ ] `xcodebuild ... -scheme Tally build` 通过
- [ ] PR 描述写明已用上面 grep 复核"无加密"成立

## Don't

- 不动 widget target 的 plist（无需）。
- 若实际存在加密/网络，不要硬加 `NO`——先反馈。
