# [P3] Categories management + CategoryEditSheet

> Depends on: #1-#5 · Branch: `issue/009-categories` · Effort: M

## Why
Custom categories are how users personalize. The edit sheet exposes the 12-swatch palette + 36-icon catalog cleanly.

## Do
1. Rewrite `Tally/Features/Categories/CategoriesView.swift` (and any subviews):
   - `TallyNavHeader(title: "分类", trailing: + 36pt button)`
   - `Segmented(value: type, options: [.expense, .income])` (20pt vertical padding)
   - 3-column grid of categories filtered by `type`:
     - 56pt `CategoryTile` (radius 18)
     - Optional small usage-count badge at top-right (18pt circle, ink-dim text, on `tallyBg`, 0.5pt line)
     - Name below, size 12, ink, weight 500
   - "新分类" dashed tile at end
   - Tap any tile opens `CategoryEditSheet`

2. Rewrite `Tally/Features/Categories/CategoryEditSheet.swift`:
   - 86% height `tallySheet`
   - Header: 取消 / 编辑分类 / 完成 (完成 in cinnabar weight 600)
   - 72pt `CategoryTile(filled: .solid, radius: 22)` preview at top
   - Editable name field, centered, 18pt weight 600, underline 0.5pt `tallyLineHi`
   - Eyebrow "颜色" + 6-column grid of 12 swatches as `aspectRatio(1)` squares with 14pt radius
     - Active swatch: 4pt outer ring (`box-shadow: 0 0 0 2px bg, 0 0 0 4px swatch`)
   - Eyebrow "图标" + 6-column grid of 36 icons:
     - Each cell: `aspectRatio(1)` rounded square, 10pt radius
     - Inactive: `tallySurface2` bg + `tallyInkDim` icon
     - Active: `tallyAccentTint` bg + `tallyAccent` icon

3. Wire to `CategoriesViewModel` (keep public API):
   - 完成 calls `categoryRepository.update(...)` for existing or `.create(...)` for new
   - Deleting a category must invoke `categoryRepository.delete(id:migrateTo: systemCategoryId)` (preserve existing behavior — bills get migrated to "未分类")

## Design
- `design/screens-others.jsx:5-137`

## Files
**Modify**:
- `Tally/Features/Categories/CategoriesView.swift`
- `Tally/Features/Categories/CategoriesViewModel.swift` (keep API)
- `Tally/Features/Categories/CategoryEditSheet.swift`
- `Tally/Features/Categories/CategoryGridItem.swift` (or merge into the new tile rendering)

## Done when
- [ ] All system + user categories render in the grid
- [ ] Tapping a tile opens the edit sheet pre-filled
- [ ] Saving updates the category via repository
- [ ] Active swatch shows the 4pt outer ring
- [ ] Active icon shows accent tint bg
- [ ] Delete (where exposed) migrates bills correctly
- [ ] `xcodebuild test -scheme TallyTests` passes

## Don't
- Don't change `CategoryRecord` schema.
- Don't expose deletion of system categories ("未分类" is undeletable).
- Don't add an icon search bar — 36 icons fit on screen with scroll.
- Don't add category folders/groups.

## Notes
- The "新分类" tile leads to the same `CategoryEditSheet` with an empty pre-fill.
- The usage-count badge is best computed lazily (avoid eager aggregation on every render). For now, show a placeholder count via the existing data on the ViewModel; if not available, omit the badge.
