# [P5] Brand voice copy pass

> Depends on: #6-#13 · Branch: `issue/014-voice-copy` · Effort: S

## Why
The redesign isn't done until copy matches the brand voice: **declarative, no exclamations, no "AI/智能/管家", no formal 您**.

## Do
1. Scan every UI string in `.swift` files (not in `Tests/`):
   ```
   grep -rn '！' Tally/ TallyWidgets/ Shared/ --include='*.swift'
   ```
   Remove every `！` from UI strings. Keep punctuation appropriate (`。` or no terminator for buttons).

2. Find and replace banned wording (case-insensitive where possible):
   - `智能` → remove the word; reframe the sentence
   - `AI` → remove
   - `财务管家` / `理财管家` / `账务管家` → remove or replace with "Tally"
   - `轻松搞定` → "记一笔"
   - `预算焦虑` → remove the framing entirely
   - `您` → `你` (informal)
   - `请输入` → just the placeholder noun (e.g. `请输入金额` → `金额`)
   - `亲爱的` / `用户朋友` → remove

3. Buttons / CTAs use verb-first, no time marker:
   - `立即保存` → `保存`
   - `马上导出` → `导出`
   - `去设置` → `打开设置` or just `设置`

4. Empty states use design's voice — examples from `design/screenshots/ds-overview.png`:
   - For empty days: "今天还没有刻痕。"
   - For empty bills overall: "一根刻痕，一笔账。"
   - For empty categories (impossible since "未分类" always exists): N/A
   - For empty recurring: "还没有定时账单。"
   - For empty search results: "没有匹配的账目。"

5. Tagline / about copy (if About screen has any):
   - "一秒记完一笔。"
   - "关掉应用，记账继续。"
   - "你拥有的，不是预算焦虑。"

6. Localization: this issue is **zh-Hans only**. If a `Localizable.strings` exists, update only zh-Hans entries. Don't add English translations.

## Design
- `design/screenshots/ds-overview.png` (brand voice reference)

## Files
**Modify**: Whichever view files have hardcoded UI strings (probably 20-30 files across `Tally/Features/` and `TallyWidgets/`).

**Don't touch**: test files (`TallyTests/*.swift`), comments, log messages.

## Done when
- [ ] `grep -rn '！' Tally/ TallyWidgets/ Shared/ --include='*.swift' | grep -v Tests` returns zero matches in UI strings
- [ ] `grep -rn '智能\|AI\|管家\|轻松搞定' Tally/ TallyWidgets/ --include='*.swift'` returns zero matches in UI strings
- [ ] `grep -rn '您' Tally/ TallyWidgets/ --include='*.swift'` returns zero matches in UI strings
- [ ] `xcodebuild test -scheme TallyTests` passes (no test should depend on specific copy strings)

## Don't
- Don't change ViewModel logic.
- Don't translate to English.
- Don't add new strings beyond what the design implies — restrict scope to copy edits.
- Don't touch UI of the screens — visual changes belong to per-screen issues.

## Notes
- Tests that assert specific copy strings should be updated to match new strings — this is acceptable scope here (modifying TallyTests/ for assertions about copy).
- Be careful with `！` in regex-matched test strings vs UI strings — don't touch test fixtures.
