# [P2] 英文本地化补全（4 条格式串 + 预置分类英文名评估）

> 关联：上线前只读扫描 P2-4 / P2-6 · 建议分支 `issue/021-en-localization` · 工作量 S
> 范围：`Shared/Resources/Localizable.xcstrings`（Part A）；`Tally/Data/CoreDataSeedService.swift`（Part B，需产品确认）。
> 发布整改任务，不受 UI 重构禁区约束。

## 背景 / Why

`Localizable.xcstrings` 的 `sourceLanguage = zh-Hans`，中文覆盖 100%；但有 4 条字符串缺英文本地化（`state: new`），其中一条会把中文全角逗号带进英文界面。另外预置分类名是中文硬编码，英文环境下仍显示中文。

## 证据 / Evidence

- 4 条缺 en 的键（均为占位/拼接格式串）：
  ```
  '%@ · %@'      -> 缺 en
  '%@ · %lld%%'  -> 缺 en
  '%@ %@'        -> 缺 en
  '%@，%@'       -> 缺 en（注意：中文全角逗号「，」）
  ```
  复现：
  ```bash
  python3 - <<'PY'
  import json
  d=json.load(open('Shared/Resources/Localizable.xcstrings'))
  for k,e in d['strings'].items():
      for lang,u in e.get('localizations',{}).items():
          if u.get('stringUnit',{}).get('state')=='new':
              print(lang,repr(k))
  PY
  ```
- 预置分类名中文硬编码：[CoreDataSeedService.swift:174-211](../../Tally/Data/CoreDataSeedService.swift)（晚餐/午餐/咖啡/房租…）。

## Part A（建议直接做）— 补 4 条英文

- 为 4 个键补 en：`%1$@ · %2$@`、`%1$@ · %2$lld%%`、`%1$@ %2$@`、`%1$@, %2$@`（英文用半角逗号 `, `）。
- 把对应 `state` 置为 `translated`。

## Part B（需产品确认，可单独跟进）— 预置分类英文名

- 现状：英文环境下分类仍显示「晚餐」等中文。
- 决策点：本应用是 CNY / 中文优先；是否值得为英文用户翻译预置分类？
  - 若**不做**：在 PR 注明"刻意保留中文分类名"，本 part 关闭。
  - 若**做**：方案需谨慎——分类名是 Core Data 落库数据（不是纯 UI 文案），不能简单按 locale 切显示，否则破坏已记账单的分类归属。建议仅对"预置且用户未改名"的分类做显示层映射，**不改库内 name**。属较大改动，建议另开 issue。

## 验收 / Done when

- [ ] Part A：4 条键有 en 值且 `state=translated`，英文界面不再出现全角「，」
- [ ] `xcodebuild ... -scheme TallyTests test` 通过（含 `MoneyFormatterTests` 等）
- [ ] Part B：给出"做/不做"结论；若做，仅显示层映射、不动库内 `name`

## Don't

- 不改 `sourceLanguage`。
- Part B 不要直接改 `CoreDataSeedService` 里已落库的 `name` 字段（会影响存量数据归类）。
