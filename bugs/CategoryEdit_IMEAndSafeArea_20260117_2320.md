# 类别编辑弹框：输入法限制 + 底部安全区

日期：2026-01-17 23:20

## 症状

1. 中文输入法（拼音）在输入超过限制时被截断（例如输入 “motuoche” 会停在 “motuo”）。
2. 弹框底部出现安全区留白，要求移除。

## 根因

- SwiftUI `TextField` 在每次变更时直接截断，且该逻辑在输入法组合态（marked text）期间也会触发。
- 底部操作区使用了 `proxy.safeAreaInsets.bottom`，与设计需求不符。

## 修复

- 使用 `JOLimitedTextField`（UIKit 封装），仅在无组合态时限制长度。
- 移除底部安全区 padding。
- 忽略底部容器安全区，使弹框内容可贴近屏幕底部。

## 涉及文件

- JustOne/Core/UIComponents/JOLimitedTextField.swift
- JustOne/Features/Categories/CategoryEditSheet.swift
