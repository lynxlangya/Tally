# [P1] Category icon set — 36 custom SVGs + TallyIcon view

> Depends on: — (can parallelize with #1, #2) · Blocks: 006-012 · Branch: `issue/003-icon-set` · Effort: M

## Why
The design uses hand-drawn icons (fork.knife, cart.fill, etc.) styled to brand. Each must share stroke weight + fill alpha. Native SF Symbols don't carry the brand language.

## Do
1. Open `design/components.jsx` lines 75-287. Each entry in `CAT_ICONS` is an SVG `<g>` block with the icon's paths.
2. For each of the 36 entries (keys: `fork.knife`, `cup.and.saucer.fill`, `cart.fill`, `bag.fill`, `house.fill`, `lightbulb.fill`, `drop.fill`, `cross.case.fill`, `pills.fill`, `graduationcap.fill`, `book.fill`, `car.fill`, `tram.fill`, `airplane`, `fuelpump.fill`, `cup.and.heat.waves.fill`, `birthday.cake.fill`, `banknote.fill`, `creditcard.fill`, `briefcase.fill`, `dumbbell.fill`, `figure.walk`, `gift.fill`, `film`, `music.note`, `pawprint.fill`, `leaf.fill`, `wifi`, `phone.fill`, `calendar`, `repeat`, `tshirt.fill`, `scissors`, `gamecontroller.fill`, `doc.text.fill`), create:
   - `Tally/Assets.xcassets/CategoryIcons/<name>.imageset/<name>.svg` — 24×24 viewBox wrapping the `<g>` content from the source
   - `Tally/Assets.xcassets/CategoryIcons/<name>.imageset/Contents.json` with:
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
3. Build `Tally/Core/UIComponents/Tally/TallyIcon.swift`:
   ```swift
   struct TallyIcon: View {
       let name: String
       var size: CGFloat = 20

       var body: some View {
           if UIImage(named: name) != nil {
               Image(name).renderingMode(.template).resizable().frame(width: size, height: size)
           } else {
               Image(systemName: name).font(.system(size: size * 0.9, weight: .regular))
           }
       }
   }
   ```
4. Add an enum or struct `TallyIcon.Catalog` exposing all 36 names as static `String` constants so feature code can use compile-time-safe references (e.g. `TallyIcon.Catalog.forkKnife`).
5. Add a `TallyIconGalleryPreview` SwiftUI Preview showing all 36 in a grid for visual QA.

## Design
- `design/components.jsx:75-287` (CAT_ICONS map)

## Files
**Create**:
- `Tally/Assets.xcassets/CategoryIcons/<name>.imageset/{<name>.svg, Contents.json}` × 36
- `Tally/Core/UIComponents/Tally/TallyIcon.swift`

## Done when
- [ ] All 36 icons render via `TallyIcon(name: "fork.knife")` in the Preview gallery
- [ ] Unknown name (e.g. `TallyIcon(name: "no.such.icon")`) falls back to SF Symbol without crashing
- [ ] Icons template-tint correctly (color follows `.foregroundStyle()` / `.tint()`)
- [ ] `xcodebuild build` passes

## Don't
- Don't change `CategoryRecord.iconKey` schema. Keys remain plain strings.
- Don't add icons that aren't in the source `CAT_ICONS` map.
- Don't try to convert SF Symbols into PDFs — use the source SVG paths verbatim.

## Notes
- 24×24 viewBox, stroke `1.6`, fillOpacity `0.16-0.18` (preserve exact values from source per icon).
- Strip JS-specific attributes (`fillOpacity` → `fill-opacity`, no `currentColor` literal — SwiftUI template rendering handles tint).
- For SVGs that mix stroke + fill (most of these), keep `stroke="currentColor"` and `fill="currentColor"` so template rendering tints both.
