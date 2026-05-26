# Codex `/goal` — Tally UI Refactor

Copy the block below into your Codex `/goal` invocation. The prompt is self-contained: codex reads it, then reads the issue, then executes.

---

## Prompt to feed Codex `/goal`

```
You are executing a planned UI refactor for the Tally iOS app — a single-currency (CNY) personal bookkeeping app, SwiftUI + Core Data + WidgetKit, iOS 26.2 deployment target, Xcode 26.5.

## Read first, in this order

1. `/CLAUDE.md` and `/AGENTS.md` — architecture rules and constraints
2. `/.github/issue-drafts/000_PLAN.md` — master plan with phase ordering, hard rules, and what NOT to touch
3. The specific issue you've been assigned (e.g. `#5`). Fetch via `gh issue view <N>` or read `/.github/issue-drafts/00N_*.md` — the GitHub issue body mirrors that file
4. Files referenced in the issue under `design/` for visual specs

## How to work

- ONE issue at a time. Don't start another until the current one is merged.
- Open a branch named exactly as the issue says (`issue/N-slug`).
- Implement strictly to the issue spec. Don't add features the issue doesn't list. Don't fix unrelated code "while you're here."
- Use the existing project layout and architecture. Never create files outside the paths the issue specifies.
- Read `design/tokens.css` for exact hex / size / timing whenever the issue references a token.
- Read the relevant `design/screens-*.jsx` and `design/components.jsx` for layout, padding, transitions — these are precise to the pixel.

## Build & test (mandatory before opening PR)

```bash
xcodebuild -project Tally.xcodeproj -scheme Tally \
  -destination 'platform=iOS Simulator,name=iPhone 17' build

xcodebuild -project Tally.xcodeproj -scheme TallyTests \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

Both MUST pass. If a test fails because of your change, fix the underlying cause — don't disable the test. If a test failure is unrelated (pre-existing), call it out in the PR description.

## Hard NO

- DON'T touch: `Tally/Data/` (except #4), `Tally/Services/`, `Tally/Core/Domain/`, `Tally/Core/Utilities/`, `Tally/Core/Recurring/`, `Tally/Core/DeepLink/`, repository / service protocols
- DON'T hardcode color hex literals in view code — use `Color.tally*` from `#1`
- DON'T use exclamation marks (`！`) in any UI copy
- DON'T write "智能" / "AI" / "管家" / "轻松搞定" / "理财神器" in any UI copy
- DON'T use formal `您` — use `你`
- DON'T add features the issue doesn't list
- DON'T add third-party dependencies
- DON'T auto-merge PRs — wait for human review

## Brand voice (for any UI copy you write)

- Declarative short sentences. No exclamation marks.
- Examples to model: "一秒记完一笔。" / "一根刻痕，一笔账。" / "关掉应用，记账继续。" / "下次 6 月 1 日" / "已记 142 天"
- CTAs: verb-first, no time marker — "保存" / "导出" / "新建"
- Avoid: "请输入", "亲爱的", "立即/马上", "您", emoji-as-icon

## Commit & PR

- Conventional commit messages: `feat(home): ...`, `refactor(theme): ...`, `chore(icons): ...`
- One commit per logical unit; don't squash to one giant commit
- PR title format: `[#N] Issue title`
- PR body MUST include:
  1. The issue's "Done when" checklist with each item marked `- [x]` and proof (file:line, screenshot, or test name)
  2. `Closes #N` so the issue auto-closes on merge
  3. Any deviations from the issue spec, justified
- Add screenshots for visual issues (any screen rebuild — #5-013)

## Visual verification

For screen-level issues (#6-013), open the simulator, navigate to the screen, and capture a screenshot. Compare side-by-side with `design/screenshots/*.png` (dark mode reference). Acceptable visual delta: ≤ 4pt on any padding, ≤ 1pt on any radius, exact color match on tokens.

## When stuck

- If the issue spec is ambiguous, prefer the design file source (`design/screens-*.jsx`) — it has exact numbers.
- If the design and existing repository protocol clash, the protocol wins (don't break the data layer to match visual whims).
- If you discover the issue spec is wrong (e.g. references a non-existent file), open a comment on the issue and stop — don't guess.

Now: read the issue you've been assigned and begin.
```

---

## How to launch codex for each issue

For each issue (#1 through #15), the workflow is:

```bash
# In codex shell, point it at the issue:
/goal "Execute issue #1 (Tally UI refactor). Read /.github/issue-drafts/CODEX_GOAL_PROMPT.md for context, then read /.github/issue-drafts/001_design_tokens.md for the task. Follow the rules exactly. Open a PR when done."
```

Replace the issue number for each subsequent goal. Codex completes one, opens a PR, then you fire the next goal.

## Recommended issue execution order

Strict phase order (each phase must be merged before the next starts):

1. **Phase 1 — Foundation** (must merge before Phase 2):
   - `/goal` #1 → wait for PR → merge → `/goal` #2 → wait → merge → `/goal` #3 → wait → merge → `/goal` #4 → wait → merge
   - These four CAN be parallelized as separate codex sessions if you trust the dependency graph (003 has no deps; 002 needs 001 first; 004 needs 001 first)

2. **Phase 2** — `/goal` #5 → merge

3. **Phase 3** (can parallelize after Phase 2 is in):
   - `/goal` #6, #7, #8, #9, #10, #11, #12 — can run in parallel codex sessions

4. **Phase 4** — `/goal` #13 (parallel to Phase 3)

5. **Phase 5** (sequential, must be after Phases 1-4):
   - `/goal` #14 → merge → `/goal` #15 → merge

## Sanity check before fire-and-forget

After each codex PR opens, read the PR description's checklist + screenshots before merging. If anything feels off, comment on the PR with specific feedback; codex will iterate.

Don't merge PRs that:
- Skip the `Done when` checklist
- Have failing CI
- Modify protected directories listed in `000_PLAN.md`'s "What stays untouched" section
- Hardcode color hex literals (search the diff for `Color(red:`, `Color(hex:`, `#[A-F0-9]{6}` literals)
- Use exclamation marks in UI strings
