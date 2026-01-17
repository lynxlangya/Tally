# 类别编辑：名称输入框高度跳变

日期：2026-01-17 23:27

## 症状

- 输入文字后名称输入行高度变大。

## 根因

- 清空按钮按条件插入布局，导致文本非空时行的固有高度变化。
- 占位文案未显式设置字体，可能导致占位与真实文本基线/高度不一致。

## 修复

- 用叠加方式放置清空按钮并预留右侧空间，保持布局高度稳定。
- 在 `JOLimitedTextField` 中显式设置占位文字字体。

## 涉及文件

- JustOne/Features/Categories/CategoryEditSheet.swift
- JustOne/Core/UIComponents/JOLimitedTextField.swift
