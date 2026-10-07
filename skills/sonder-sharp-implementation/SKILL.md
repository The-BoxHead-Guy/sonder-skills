---
name: sonder-sharp-implementation
description: Sharp, minimal code implementation for single or few-file changes. Use this skill whenever the user asks for a bug fix, a small feature, a tweak, a rename, an endpoint, a component, a query, or any scoped code change.
---

# Sonder Sharp Implementation

Apply it even when the request sounds trivial, and especially when you feel tempted to refactor, add configurability, or "improve" nearby code. Do NOT use for greenfield architecture, large migrations, or multi-phase projects.

Deliver exactly what was asked. Nothing around it.

**Core rule:** if the user did not ask for it and the task does not break without it, do not write it.

---

## Steps

### 1. Restate the target in one line

`Change X so that Y.`

**Why:** A one-line target is the scope boundary. Every later decision is checked against it.

### 2. Read only what the change touches

Open the files you will edit and the code they directly call. Stop there.

**Why:** Reading the whole codebase invites "while I'm here" edits. Follow the existing patterns of the touched code and copy them.

### 3. Pick the smallest change that works

Prefer editing existing lines over adding new files, classes, or layers.

**Why:** Fewer lines changed means a smaller diff to review and less risk to existing behavior.

### 4. Apply the cuts (see below)

Run the change through each cut before writing it.

**Why:** These are the four most common sources of over-engineering. Each one is blocked here, at the source.

### 5. Implement

Write the change. Touch only lines required by the target.

**Why:** Unrelated edits hide the real change and can silently break working code.

### 6. Verify once

Run the narrowest check that proves the target is met (one test, one command, one manual path). If nothing can be run, say so.

**Why:** Working correctness is the goal. A wide test sweep is out of scope unless the change can affect it.

### 7. Report in this shape

```
Changed: <file:lines> – <what>
Why: <one line>
Verified: <how, or "not run">
Noticed, not touched: <optional, max 2 bullets>
```

**Why:** Out-of-scope findings are surfaced for the user to decide, never fixed silently.

---

## The Four Cuts

| Cut                  | Do not                                                                                                                  | Do                                                                                    |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| **Scope**            | Add features, refactor, or "improve" beyond the request. Clean up around a bug fix. Add config options.                 | Change only what the request names or what breaks without it.                         |
| **Documentation**    | Add docstrings, comments, or type annotations to code you did not change.                                               | Comment only where the logic is not self-evident.                                     |
| **Defensive coding** | Add error handling, fallbacks, or validation for cases that cannot happen. Re-validate data from trusted internal code. | Validate at boundaries only: user input, external APIs, files, network.               |
| **Abstractions**     | Create helpers, utilities, or classes for a one-time operation. Design for hypothetical future needs.                   | Inline it. Extract only when the same logic is needed a second time **in this task**. |

---

## Example (simple first, then the realistic version)

**Request:** "The invoice total shows 0 when there are no discounts."

**Simple (correct):**

```php
// before
$total = $subtotal - $discount;
// after: $discount is null when none applied
$total = $subtotal - ($discount ?? 0);
```

**Over-engineered (rejected):**

```php
// new InvoiceTotalCalculator class, interface, config for rounding mode,
// try/catch around subtraction, docblocks on the whole file
```

**Why the first wins:** one line, same root cause, no new surface area.

**Realistic follow-up:** while fixing it you notice the tax calculation below uses a deprecated helper.
→ Do not touch it. Add it under `Noticed, not touched`.

---

## Stop Conditions

Ask before proceeding (one short question) only if:

- The request has two plausible meanings that lead to different code.
- The minimal fix requires changing existing behavior another feature depends on.

Otherwise, proceed with the simplest interpretation and state the assumption in the report.

---

## Pre-Delivery Checklist

- [ ] Diff contains only lines needed for the target
- [ ] No new file, helper, or abstraction unless used twice now
- [ ] No comments or types added to untouched code
- [ ] No validation or fallback for impossible cases
- [ ] Existing behavior unchanged outside the target
- [ ] Verified, or explicitly marked "not run"
