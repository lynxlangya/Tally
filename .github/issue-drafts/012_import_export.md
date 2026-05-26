# [P3] ImportExport screen rebuild

> Depends on: #1-#5 · Branch: `issue/012-import-export` · Effort: S

## Why
4 actions + recent log. Simple visual but must match the cinnabar-tint primary CTA.

## Do
1. Rewrite `Tally/Features/Settings/ImportExportView.swift`:

   **Header**:
   - `TallyNavHeader(title: "导入与导出", onBack: dismiss)`
   - Eyebrow "当前数据" + large 32pt number (record count) + sub "条记录"
   - Sub-line: "跨度 YYYY/M/D — YYYY/M/D · X 天"

   **Action cards** (per `design/screens-others.jsx:403-431`):
   - 4 buttons stacked, 10pt gap:
     1. **导出 CSV** — primary: `tallyAccentTint` bg, 0.5pt accent-derived border, icon container `tallyAccent` bg + `tallyAccentInk` fg, title in `tallyAccent`
     2. **导出备份 JSON** — neutral: `tallySurface` bg, regular line border
     3. **导入备份** — neutral
     4. **导入 CSV** — neutral
   - Each card: 36pt rounded icon tile + title (size 15, weight 600) + sub (size 12, faint) + chevron, 16pt padding
   - Icons: upload arrow for export actions, download arrow for import actions

   **Recent log card** (per `design/screens-others.jsx:434-446`):
   - Eyebrow "最近记录"
   - Card with 2-3 most-recent entries, separated by 0.5pt lines
   - Each entry: 6pt status dot (moss for ok, ochre for warn, terracotta for error) + title + meta (date · time · count · errors) + chevron

2. Wire each action to existing `ImportExportService` methods:
   - 导出 CSV → `exportCSV(request:)`
   - 导出备份 JSON → `exportBackup(request:)`
   - 导入备份 → file picker → `previewImportBackup(from:)` → confirm sheet → `importBackup(from:)`
   - 导入 CSV → file picker → `previewImportCSV(from:)` → confirm sheet → `importCSV(from:)`

3. After any successful import, post `NotificationCenter.default.post(name: .billDidChange, object: nil)` (this should already happen via existing service, verify).

4. **Recent log persistence** — add `ImportExportLog` lightweight struct + `[ImportExportLog]` stored in `UserDefaults` (key `tally.importexport.log`). Cap at last 20 entries. Update ViewModel to read/write this.

5. Add `currentRecordCount: Int` and `dateRange: (Date, Date)?` computed properties to `ImportExportViewModel`.

## Design
- `design/screens-others.jsx:382-464`

## Files
**Modify**:
- `Tally/Features/Settings/ImportExportView.swift`
- `Tally/Features/Settings/ImportExportViewModel.swift`

**Create**:
- `Tally/Features/Settings/ImportExportLog.swift` (struct + UserDefaults helpers)

## Done when
- [ ] All 4 actions wire to existing service methods
- [ ] Successful import refreshes Home (notification fires)
- [ ] Recent log persists across app launches
- [ ] Primary CTA visually distinct (cinnabar-tint vs neutral)
- [ ] `xcodebuild test -scheme TallyTests` passes — existing `ImportExportViewModelTests` and `CSVImportPipelineTests` must continue to pass

## Don't
- Don't change `ImportExportService` protocol or `DefaultImportExportService` behavior.
- Don't add cloud sync UI here — out of scope.
- Don't add export-to-PDF (ExportFormat enum has `.pdf` but pipeline doesn't implement it).

## Notes
- File-picker presentation: use `.fileImporter(...)` and `.fileExporter(...)`.
- For ImportPreview confirm sheet, keep the existing implementation if any — visual style updates only.
- Status dot colors are referenced via `Color.catMoss`, `.catOchre`, `.catTerracotta` (already defined in #1).
