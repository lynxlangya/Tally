# Tally UI Refactor — Master Plan

## Goal
Replace the entire visual + interaction layer with the Claude Design "cinnabar + ink-and-paper" system while preserving 100% of the architecture (App / Features / Services / Data / Core), domain models, repository protocols, and test infrastructure.

## Source of truth
- `design/tokens.css` — design tokens (colors / spacing / radii / motion)
- `design/components.jsx`, `design/shell.jsx` — atomic component implementations
- `design/screens-*.jsx` — screen layouts (Home / Stats / QuickEntry / Categories / Recurring / Profile / ImportExport / Widgets)
- `design/screenshots/*.png` — visual ground truth (dark mode confirmed)
- `CLAUDE.md`, `AGENTS.md`, `Tally/Core/ArchitectureRules.md` — architecture rules (DO NOT VIOLATE)

## Decisions (already made — don't re-litigate)
1. **Fonts**: SF Pro Display + SF Pro Rounded + `.monospacedDigit()`. No Geist bundled now — can add later as a single change.
2. **Icons**: 36 custom SVGs → `Assets.xcassets` ImageSets. `TallyIcon(name:)` view resolves the asset, with SF Symbol fallback.
3. **Theme**: `Color.tally*` extensions backed by colorsets in xcassets with Any + Dark variants. View code must NOT use hex literals.
4. **Component namespace**: New = `Tally*`. Legacy = `JO*`. Both coexist until #15 deletes `JO*`.
5. **Sheet**: Native `.sheet()` + `presentationDetents` + `presentationCornerRadius(32)` + custom 36×4 handle.
6. **PR strategy**: One branch per issue (`issue/N-slug`). PR to `main`. CI must pass. **Human merge in the morning** — no auto-merge.

## Architecture changes (limited, listed exhaustively)
1. **`Core/Theme/`**: replace 5 legacy files with new Tally tokens (#1).
2. **`Core/UIComponents/Tally/`**: new namespace, 9 atomic components (#2).
3. **`Assets.xcassets/Tokens/`**: new colorsets per token (#1).
4. **`Assets.xcassets/CategoryIcons/`**: 36 SVG imagesets (#3).
5. **`Data/CoreDataSeedService.swift`**: brand-color migration (#4).
6. **`Features/*/View*.swift`**: every screen view rewritten (#6-012).
7. **`TallyWidgets/`**: widget views rewritten (#13).
8. **`Features/AppShell/`**: TabBar + FAB + NavHeader rewrite (#5).

## What stays untouched
- `Tally/Data/` (Repositories, PersistenceController, mappers) — except #4's seed function
- `Tally/Services/` (RecurringService, ImportExportService, etc.)
- `Tally/Core/Domain/` (BillRecord, CategoryRecord, RecurringTaskRecord, Enums, SystemCategories)
- `Tally/Core/Utilities/` (Money, MoneyFormatter, TimePolicy, DayKeyFormatter, AppEvents)
- `Tally/Core/Recurring/` (RecurringScheduler, RepeatRule)
- `Tally/Core/DeepLink/`
- Repository / Service protocols
- `TallyTests/` — tests should keep passing without modification (UI changes are invisible to ViewModel-level tests)
- Bundle IDs, App Group, URL scheme — already correct

## Phase plan
- **Phase 1 — Foundation** (#1-004): tokens, atoms, icons, seed colors. Sequential within (#2 after #1, #4 after #1). Must all complete before Phase 2.
- **Phase 2 — Shell** (#5): tab bar + FAB + nav header. Depends on Phase 1.
- **Phase 3 — Screens** (#6-012): one screen per issue. Depends on Phases 1 + 2. Can run in parallel.
- **Phase 4 — Widgets** (#13). Depends on Phase 1.
- **Phase 5 — Polish** (#14-015): voice copy + app icon + legacy JO* cleanup.

## Hard rules (codex must obey)
1. Don't touch protected directories (see "What stays untouched").
2. Don't add features the issue doesn't list. No drive-by cleanup.
3. Don't write hex color literals in view code — use `Color.tally*`.
4. Don't use exclamation marks in UI copy. No "智能/AI/管家".
5. Run `xcodebuild build` AND `xcodebuild test -scheme TallyTests` before opening a PR. Both must pass.
6. PR description must check off the issue's "Done when" list with proof (file:line or screenshot).
7. Every new component MUST ship with a SwiftUI Preview showing Light + Dark variants.
8. Commit messages: conventional commits (`feat:` / `refactor:` / `chore:`). PR body ends with `Closes #N`.

## Issue index
| #   | Phase | Title                                          | Depends on        | Effort |
| --- | ----- | ---------------------------------------------- | ----------------- | ------ |
| 001 | 1     | Design tokens                                  | —                 | M      |
| 002 | 1     | Atomic components                              | 001               | L      |
| 003 | 1     | Category icon set (36 SVGs)                    | —                 | M      |
| 004 | 1     | Brand-color seed migration                     | 001               | S      |
| 005 | 2     | AppShell — TabBar + FAB + NavHeader            | 001, 002          | M      |
| 006 | 3     | Home screen                                    | 001-005           | M      |
| 007 | 3     | QuickEntry sheet + CategoryPickerSheet         | 001-005           | L      |
| 008 | 3     | Statistics screen                              | 001-005           | M      |
| 009 | 3     | Categories management + CategoryEditSheet      | 001-005           | M      |
| 010 | 3     | Recurring + RecurringFormSheet                 | 001-005           | M      |
| 011 | 3     | Profile screen (+ streak strip)                | 001-005           | M      |
| 012 | 3     | ImportExport screen                            | 001-005           | S      |
| 013 | 4     | Widget redesign (Small + Medium)               | 001-003           | M      |
| 014 | 5     | Brand voice copy pass                          | 006-013           | S      |
| 015 | 5     | App Icon placeholder + legacy JO* cleanup      | 006-014           | S      |
