---
name: review-changes
description: |-
  Full review loop for uncommitted changes: gather diff/files, run correctness-review and context-review, fix any blocking issues via fix-review-findings, re-review, repeat up to 3 cycles. Ends with a clean PASS or a reported failure. Does not commit anything.
  Examples:
  - user: "review my changes" → run this end-to-end, no commit
  - user: "check and review, I'll commit myself" → run this
  - Used by commit-review as its review phase before committing
  Do NOT use when the user wants changes committed too — use commit-review for that.
---

# review-changes: Review → Fix → Re-review

Runs changed code through review until it's clean, or reports why it isn't.
Read-and-fix only; never touches git commit/add.

## Phase 0: Pre-Flight

```bash
git status --short
git diff --name-only        # unstaged
git diff --cached --name-only  # staged
git ls-files --others --exclude-standard  # untracked
git diff
git diff --cached
```

Read the full content of every changed file — including staged and
untracked ones (`git diff` alone shows neither).

No changes → emit the Phase 4 report block immediately with verdict
`NO CHANGES` and stop.

## Phase 1: Initial Review

Run both, in parallel if the environment supports it:

- `correctness-review` — logic/quality/safety
- `context-review` — history/cross-references/build

**Gate**: both verdicts PASS → done, report PASS (skip to Phase 4).
Either verdict FAIL, or any blocking_issues present → Phase 2. (A FAIL
with an empty blocking_issues list still goes to Phase 2 — treat it as
blocking until a re-review says otherwise.)

## Phase 2: Fix

Pass the combined blocking issues from both reviews to `fix-review-findings`.

## Phase 3: Re-review

Re-run every review that returned blocking_issues in Phase 1, or whose
fix report says a finding could not be fixed, against the updated
files/diff. (Minimum: `correctness-review`; add `context-review` whenever
it FAILed in Phase 1 or its target files changed.)

- All re-run reviews PASS **and** no outstanding unfixed blocking_issues
  remain → Phase 4.
- Any re-run FAIL, or any unfixed blocking_issue remains → back to
  Phase 2.
- Cap at 3 review-fix cycles total. If still failing after 3, stop and
  report to the user with the outstanding findings — do not loop forever,
  do not silently pass failing changes.

## Phase 4: Report

```markdown
## review-changes Result

- **Files reviewed**: N
- **Verdict**: PASS / FAIL / NO CHANGES (after X cycles)
- **Fixes applied**: N (if any)

### Review Findings

| File | Severity | Issue | Fixed? |
| ---- | -------- | ----- | ------ |
```

Include every finding from Phase 1 (and re-reviews) with its Fixed?
status (`yes` / `no — reason`) — callers such as `commit-summary` need
per-finding status even on a PASS-after-fixes run. Omit the table only
when no findings were ever raised.

If the caller is `commit-review`, return this result to it rather than
printing it as the final answer.
