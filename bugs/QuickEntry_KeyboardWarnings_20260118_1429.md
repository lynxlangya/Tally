# 记账页备注输入键盘日志警告

日期：2026-01-18 14:29

## 症状
- 点击记账页备注输入框后，控制台出现 RTIInputSystemClient / candidate resultset / Reporter disconnected 等日志。
- 使用系统键盘也会出现。

## 复现
1. 进入 QuickEntry（加号）。
2. 选择分类进入金额页。
3. 点击备注输入框。

## 根因
- iOS 输入系统（RTI/Emoji 搜索/候选词）在某些系统版本会输出调试日志。
- 与 App 逻辑无关，不影响输入功能与界面高度。

## 处理
- 无需代码修复；保持现有 `.ignoresSafeArea(.keyboard)` 以确保弹框高度不变。
- 若需减少日志，可在 Xcode Scheme 中设置 `OS_ACTIVITY_MODE=disable`（仅影响日志显示）。

## 涉及文件
- Tally/Features/QuickEntry/QuickEntryView.swift
