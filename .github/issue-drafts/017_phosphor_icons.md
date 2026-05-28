# [Polish] Adopt Phosphor Icons (Regular weight) for category + chrome icons

> Depends on: #3 (icon system merged) · Branch: `issue/017-phosphor-icons` · Effort: M

## Why

The current 35 category icons are LLM-hand-drawn SVGs — a stopgap. They don't scale to user-created categories and aren't optically consistent. Switch to [Phosphor Icons](https://phosphoricons.com/) **Regular** weight: 1,200+ professionally-drawn icons, MIT license, consistent geometry.

The integration is cheap because `TallyIcon(name:)` (`Tally/Core/UIComponents/Tally/TallyIcon.swift`) is the single choke point — it loads an xcasset by name, falls back to SF Symbol. We swap the asset catalog + the key namespace; the view itself barely changes.

## Decisions (already made — implement as-is)

1. **Weight**: Phosphor **Regular** ONLY. One weight, globally. Do NOT mix in Bold/Thin/Duotone. (Regular is a filled-outline path with `fill="currentColor"` → template-tints cleanly.)
2. **Source**: pull SVGs from the official repo at build-prep time:
   `https://raw.githubusercontent.com/phosphor-icons/core/main/assets/regular/<name>.svg`
3. **Delivery**: SVG → `Assets.xcassets` ImageSets. **No SPM dependency** (the no-third-party-deps rule in `000_PLAN.md` still holds). `TallyIcon` stays the resolver.
4. **Namespace**: adopt Phosphor kebab-case names (`fork-knife`, `shopping-cart`) as the canonical icon key set. Migrate the old 35 SF-symbol-style keys (`fork.knife`, `cart.fill`) → Phosphor equivalents.
5. **Scope guard**: Phosphor is for **category + settings/chrome icons only**. `TallyMark` (logo), the 3 tab-bar icons, and the FAB glyph stay bespoke — do NOT touch them.

## The 88 category icons (the CategoryEditSheet picker catalog)

Grouped by spending domain. These are the names users browse when creating a custom category.

**餐饮 Food & Drink (11)**
`fork-knife` `coffee` `bowl-food` `hamburger` `pizza` `wine` `beer-stein` `ice-cream` `cooking-pot` `cake` `cookie`

**购物 Shopping (6)**
`shopping-cart` `shopping-bag` `handbag` `tag` `storefront` `receipt`

**居家水电 Home & Utilities (9)**
`house` `couch` `bed` `lightbulb` `lightning` `drop` `flame` `trash` `wrench`

**交通 Transport (9)**
`car` `bus` `train` `airplane-tilt` `gas-pump` `bicycle` `motorcycle` `taxi` `map-pin`

**医疗健康 Health (6)**
`first-aid-kit` `pill` `heartbeat` `syringe` `tooth` `stethoscope`

**教育 Education (5)**
`graduation-cap` `book-open` `books` `notebook` `pencil`

**娱乐 Entertainment (8)**
`film-slate` `music-notes` `game-controller` `popcorn` `television` `headphones` `ticket` `camera`

**运动健身 Fitness (5)**
`barbell` `person-simple-run` `soccer-ball` `basketball` `sneaker-move`

**数码通讯 Tech & Comm (5)**
`wifi-high` `phone` `device-mobile` `laptop` `cloud`

**服饰美容 Clothing & Beauty (5)**
`t-shirt` `pants` `dress` `eyeglasses` `scissors`

**宠物 Pets (3)**
`paw-print` `dog` `cat`

**旅行 Travel (4)**
`suitcase-rolling` `mountains` `tent` `globe-hemisphere-west`

**社交人情 Social (5)**
`heart` `hand-heart` `users-three` `baby` `gift`

**收入理财 Income & Finance (7)**
`briefcase` `money-wavy` `bank` `coins` `credit-card` `wallet` `currency-cny`

**Total: 88.** Verify each name resolves on phosphoricons.com / the core repo; if Phosphor has renamed one between versions, substitute the nearest visual match and note it in the PR.

## Utility / chrome icons (separate from the 88, also Phosphor Regular)

The Profile settings rows and a few nav spots call `TallyIcon(name:)` with SF-symbol keys. Add these so the whole app reads as one icon family:

`repeat` `file-text` `leaf` `gear-six` `bell` `globe` `magnifying-glass` `info`

(Inline chrome SVGs that codex implemented as SwiftUI `Path` / SF Symbols directly — chevrons, plus, close, calendar — are out of scope; only `TallyIcon(name:)` call sites are covered here.)

## Old 35 → Phosphor migration map (apply in seed + data migration + code literals)

```
fork.knife              → fork-knife
cup.and.saucer.fill     → coffee
cup.and.heat.waves.fill → coffee
cart.fill               → shopping-cart
bag.fill                → shopping-bag
house.fill              → house
lightbulb.fill          → lightbulb
drop.fill               → drop
cross.case.fill         → first-aid-kit
pills.fill              → pill
graduationcap.fill      → graduation-cap
book.fill               → book-open
car.fill                → car
tram.fill               → train
airplane                → airplane-tilt
fuelpump.fill           → gas-pump
cup.and.heat.waves.fill → coffee
birthday.cake.fill      → cake
banknote.fill           → money-wavy
creditcard.fill         → credit-card
briefcase.fill          → briefcase
dumbbell.fill           → barbell
figure.walk             → person-simple-run
gift.fill               → gift
film                    → film-slate
music.note              → music-notes
pawprint.fill           → paw-print
leaf.fill               → leaf
wifi                    → wifi-high
phone.fill              → phone
calendar                → (keep as inline / SF Symbol; not a category icon)
repeat                  → repeat
tshirt.fill             → t-shirt
scissors                → scissors
gamecontroller.fill     → game-controller
doc.text.fill           → file-text
```

## Implementation steps

1. **Download SVGs** (Regular). Example loop — run from repo root:
   ```bash
   ICONS="fork-knife coffee bowl-food hamburger pizza wine beer-stein ice-cream cooking-pot cake cookie shopping-cart shopping-bag handbag tag storefront receipt house couch bed lightbulb lightning drop flame trash wrench car bus train airplane-tilt gas-pump bicycle motorcycle taxi map-pin first-aid-kit pill heartbeat syringe tooth stethoscope graduation-cap book-open books notebook pencil film-slate music-notes game-controller popcorn television headphones ticket camera barbell person-simple-run soccer-ball basketball sneaker-move wifi-high phone device-mobile laptop cloud t-shirt pants dress eyeglasses scissors paw-print dog cat suitcase-rolling mountains tent globe-hemisphere-west heart hand-heart users-three baby gift briefcase money-wavy bank coins credit-card wallet currency-cny repeat file-text leaf gear-six bell globe magnifying-glass info"
   for name in $ICONS; do
     dir="Tally/Assets.xcassets/CategoryIcons/${name}.imageset"
     mkdir -p "$dir"
     curl -fsSL "https://raw.githubusercontent.com/phosphor-icons/core/main/assets/regular/${name}.svg" -o "$dir/${name}.svg" \
       || echo "MISSING: $name  (verify name on phosphoricons.com, substitute nearest match)"
   done
   ```
2. **Write `Contents.json`** for each imageset:
   ```json
   {
     "info": { "version": 1, "author": "xcode" },
     "images": [{ "filename": "<name>.svg", "idiom": "universal" }],
     "properties": {
       "preserves-vector-representation": true,
       "template-rendering-intent": "template"
     }
   }
   ```
3. **Delete the old 35 imagesets** (the SF-symbol-named ones: `fork.knife.imageset`, `cart.fill.imageset`, etc.).
4. **Rewrite `TallyIcon.Catalog`** in `Tally/Core/UIComponents/Tally/TallyIcon.swift` — replace the 35 old constants with the 88 category names (kebab-case → camelCase Swift constants), grouped with `// MARK:` comments by domain. Keep `.all` as the full ordered list for the picker. `TallyIcon` view body stays unchanged (still tries asset, falls back to SF Symbol).
5. **Update `CoreDataSeedService`** default category → icon assignments to Phosphor keys (use the migration map above).
6. **Add one-shot migration** `migrateLegacyIconKeys(in:)` in `CoreDataSeedService` (mirror the `migrateLegacyCategoryColors` pattern from #4):
   - Guarded by `UserDefaults` flag `tally.icon.migration.phosphor.v1`
   - Walks all categories, remaps `iconKey` via the table above
   - Unknown keys → left untouched (TallyIcon falls back to SF Symbol, still renders)
   - Called after `seedIfNeeded()` in `PersistenceController.init`
7. **Update hardcoded `TallyIcon(name:)` string literals** in Swift (e.g. `ProfileView.swift` settings rows: `cart.fill`→`shopping-cart`, `repeat`→`repeat`, `doc.text.fill`→`file-text`, `leaf.fill`→`leaf`, `book.fill`→`book-open`, `tram.fill`→`train`). `git grep 'TallyIcon(name:' && git grep '"\(fork\|cart\|house\|...\)'` to find them.
8. **Add the Phosphor LICENSE** (MIT) at `Tally/Assets.xcassets/CategoryIcons/PHOSPHOR_LICENSE.txt` (copy from the core repo). Good hygiene for an App Store ship.

## Files

**Create**:
- `Tally/Assets.xcassets/CategoryIcons/<name>.imageset/{<name>.svg, Contents.json}` × ~96 (88 category + 8 utility)
- `Tally/Assets.xcassets/CategoryIcons/PHOSPHOR_LICENSE.txt`
- `TallyTests/IconMigrationTests.swift`

**Modify**:
- `Tally/Core/UIComponents/Tally/TallyIcon.swift` (rewrite `Catalog`)
- `Tally/Data/CoreDataSeedService.swift` (seed mapping + migration)
- `Tally/Data/PersistenceController.swift` (call migration)
- `Tally/Features/Profile/ProfileView.swift` (settings-row icon keys)
- Any other Swift file with hardcoded old icon-key literals (grep to find)

**Delete**:
- The 35 old `*.imageset` folders (SF-symbol-named)

## Done when

- [ ] All 88 category icons render in the `TallyIcon` gallery preview, tinted correctly (template rendering)
- [ ] All 8 utility icons render; Profile settings rows show Phosphor glyphs
- [ ] Old 35 imagesets are gone; `git status` shows them deleted
- [ ] Existing categories (seeded + any test data) display Phosphor icons after launch (migration ran)
- [ ] `TallyIcon(name:)` with an unmapped legacy key still falls back to SF Symbol without crashing
- [ ] `CategoryEditSheet` icon picker shows the 88-icon grid, browseable (no more than ~88, not 1,200)
- [ ] New test `IconMigrationTests` proves: migration runs once, remaps known keys, preserves unknown keys
- [ ] `xcodebuild -project Tally.xcodeproj -scheme Tally -destination 'platform=iOS Simulator,name=iPhone 17' build` passes
- [ ] `xcodebuild -project Tally.xcodeproj -scheme TallyTests -destination 'platform=iOS Simulator,name=iPhone 17' test` passes
- [ ] PR includes a screenshot of the icon picker grid + the Profile screen (Dark + Light)

## Don't

- Don't touch `TallyMark`, the 3 tab-bar icons, or the FAB glyph — those stay bespoke.
- Don't add an SPM Phosphor package — SVG assets only.
- Don't import all 1,200 Phosphor icons — exactly the curated 88 + 8 utility.
- Don't mix Phosphor weights — Regular everywhere.
- Don't change `CategoryRecord.iconKey` type or schema — it stays a `String`.
- Don't touch the color tokens, the 12 swatches, or `CategoryTile`'s `.soft`/`.solid` logic — the tile still provides the colored background; the icon is just the glyph.

## Notes

- Phosphor Regular SVGs use a 256×256 viewBox with `fill="currentColor"` compound paths → template rendering tints them cleanly, no stroke handling needed.
- If `curl` for a name 404s, that name was renamed/removed in the current Phosphor version. Check phosphoricons.com search, pick the nearest visual match, and record the substitution in the PR body.
- The `.soft` CategoryTile already paints a `catColor@22%` background; a Regular (outline) glyph reads cleanest on it. Don't add a second fill layer.
- PR title: `feat(icons): adopt Phosphor Regular for category + chrome icons`
