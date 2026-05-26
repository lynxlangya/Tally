# 类别编辑弹框：键盘警告 + 布局上移

日期：2026-01-17 23:11

## 症状

- 模拟器：点击名称输入框出现大量 CHHapticPattern 警告（缺少 hapticpatternlibrary.plist）。
- 真机：点击名称输入框时弹框内容上移；期望弹框保持位置，键盘覆盖底部。

## 复现

1. 打开“类别管理”→“新增分类”。
2. 点击名称输入框。

## 根因

- 模拟器警告来自系统键盘触感生成器 UIKBFeedbackGenerator；模拟器不包含 haptic pattern 文件；非 App 代码触发。
- 弹框布局响应键盘安全区，底部操作区与内容被顶起。

## 修复

- 通过忽略键盘安全区保持弹框稳定：
  - `CategoryEditSheet` 使用 `.ignoresSafeArea(.keyboard, edges: .bottom)`。
- 模拟器警告：App 侧无法修复，如需静默可在模拟器设置中关闭键盘触感。

## 涉及文件

- Tally/Features/Categories/CategoryEditSheet.swift
