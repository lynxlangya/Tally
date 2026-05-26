# [P1] Brand-color seed migration for default categories

> Depends on: #1 · Blocks: 006-012 · Branch: `issue/004-seed-brand-colors` · Effort: S

## Why
Default categories were seeded with old palette `colorHex` values. The new design uses 12 brand swatches. Make new installs use the new palette and gently upgrade existing installs.

## Do
1. In `Tally/Data/CoreDataSeedService.swift`, build a mapping from default category name → swatch token. Use the mapping in `design/data.jsx:5-30` as the canonical source:
   ```
   午餐         → catPersimmon
   咖啡         → catOchre
   晚餐         → catTerracotta
   日用         → catMoss
   通勤         → catSlate
   房租         → catIndigo
   水电         → catOchre
   网络         → catTeal
   医疗         → catRose
   教育         → catPlum
   衣物         → catSage
   观影         → catTerracotta
   音乐         → catPlum
   宠物         → catOlive
   旅行         → catTeal
   礼物         → catRose
   游戏         → catIndigo
   未分类       → catAsh
   薪资         → catMoss
   奖金         → catOchre
   副业         → catTeal
   理财         → catSlate
   ```
2. Resolve each swatch to a hex int (e.g. `Color.catPersimmon` → `0xD6864A`). Define this lookup as a helper in the seed service so the single source of truth is `Color+Tally.swift`. (Hint: hardcode the hex map alongside the `Color.cat*` declarations and import here.)
3. New-install seeding (`seedIfNeeded()`): use the new mapping.
4. Existing-install upgrade — new function `migrateLegacyCategoryColors(in context: NSManagedObjectContext)`:
   - Guarded by `UserDefaults.standard.bool(forKey: "tally.color.migration.v1")`
   - Fetches all `Category` rows where `isSystem == true`
   - For each, if `name` matches the brand mapping, overwrite `colorHex`
   - Skips user-created (`isSystem == false`) categories
   - Sets the UserDefaults key on success
5. Call `migrateLegacyCategoryColors` immediately after `seedIfNeeded` in `PersistenceController.init`.

## Design
- `design/data.jsx:5-30` (canonical name → swatch)
- `design/tokens.css:84-97` (swatch hex values)

## Files
**Modify**:
- `Tally/Data/CoreDataSeedService.swift`
- `Tally/Data/PersistenceController.swift` (only to call the new migration)

**Create**:
- `TallyTests/CategorySeedColorTests.swift` — proves migration runs once + skips user categories

## Done when
- [ ] New install (`PersistenceController(inMemory: true)`) produces default categories with the new swatch hex values
- [ ] A simulated existing install (categories pre-populated with old hex) gets upgraded on next launch
- [ ] User-created custom categories (`isSystem == false`) keep their original `colorHex`
- [ ] `UserDefaults` migration flag prevents re-running on subsequent launches (verified by test)
- [ ] `xcodebuild test -scheme TallyTests` passes — including the new test

## Don't
- Don't change `CategoryRecord` model schema.
- Don't touch CoreData migration .xcmappingmodel files.
- Don't migrate user-created categories' colors.

## Notes
- `colorHex` field is `Int?` in the model. Hex value `0xC84A38` (no `#`) is the canonical storage form.
- If a brand mapping has multiple defaults pointing to the same swatch (e.g. 水电 + 奖金 both use ochre), that's intentional — preserve.
