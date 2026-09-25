---
name: plan-executor
description: >-
  Use this skill whenever the user wants to execute, implement, or work through an existing *markdown* plan file with checkbox tasks and gates — e.g. "execute this plan", "let's start implementing plan-refund-handling.md", "work through the roadmap we made", "continue the plan from where we left off", "implement phase 2, phase 1's gate already passed". Expects the plan-generator format — phases, `- [ ]` checkbox tasks, and `**Gate:**` verification lines (handwritten plans in the same shape also work). Walks phases in order, checks off tasks, and actually verifies each gate before continuing. Not for planning itself (use plan-generator if no plan file exists yet), not for reviewing/critiquing a plan without executing it, and not for non-software plans (infra rollout stages, deployment plans not in this markdown checkbox format) — ask the user to confirm the artifact if it's unclear whether it matches this shape.
license: MIT
metadata:
  pairs_with: plan-generator
  input_type: markdown-plan
  contract_version: "1"
---

# Plan Executor

## When to use me

Trigger on: a request to execute, implement, resume, or continue a plan that already exists as a markdown checkbox file — with or without a filename given.

Do NOT trigger on: implementation requests that explicitly skip planning ("just do it directly, no plan doc"), explaining/walking-through requests with no plan file involved, reviewing a plan without executing it, or plans belonging to a different domain/format (e.g. an infra rollout stage list that isn't in this checkbox+gate markdown shape — confirm the format with the user rather than assuming).

## Why this exists

A plan only earns its keep if execution actually respects it. The main failure mode this skill guards against is silent drift: skipping ahead past a phase that didn't really finish, or treating a gate as a formality instead of an actual checkpoint. Slower, verified progress beats fast progress that quietly breaks phase 2 while working on phase 4.

## Expected input

A markdown file matching the `plan-generator` contract: phases, `- [ ]` tasks, ending in `- [ ] **Gate:** ...`. If the plan given isn't in this shape — no checkboxes, no gates, just prose — don't force it. Either help reformat it into checkboxes first, or execute more loosely while telling the user the gate discipline below doesn't fully apply.

## Process

Work through phases **in order**. Batch small, obviously-related tasks if useful, but never cross a gate without checking it.

1. **Read the whole plan first.** Don't start phase 1 blind — later phases may inform how earlier ones should be built (e.g. phase 3 needs a specific interface, so build phase 1 to support it).
2. **Take the next unchecked task**, do the work, flip its box to `- [x]` in the plan file as you go. This keeps the file an accurate, live progress record — useful if the session is interrupted and resumes later.
3. **At a gate, actually verify the stated condition** — run the tests, hit the endpoint, check the migration. Never mark a gate `[x]` on the assumption that the preceding tasks probably worked.
4. **On gate failure:**
   - Attempt one fix, using what you know about why it failed. Worth doing — many failures are small (typo, missed import, off-by-one) and not worth interrupting the user for.
   - Re-run the same verification.
   - Passes now → mark `[x]`, continue normally.
   - Still fails → **stop and tell the user**: what failed, what you tried, why the retry didn't fix it. Do not attempt a second autonomous fix — a failure surviving one informed retry is telling you something about the plan or approach, not just a typo, and that's worth a human's judgment.
5. **If the plan itself turns out to be wrong** mid-execution (a phase's premise is false, a task no longer makes sense given what's been learned) — stop and flag it. Don't push through or silently reinterpret the plan out from under the user.

## Definition of done

Every checkbox in the file is `- [x]`, gates included. If execution stops partway (gate failure, session end), leave the file exactly as-is — accurate checkbox state is the resumption point, not something to summarize separately elsewhere.

On finishing a phase, a short one-line note to the user is worth it before moving on — not a full stop-and-ask, just enough that they're not surprised by how far execution has gone if they check back in.
