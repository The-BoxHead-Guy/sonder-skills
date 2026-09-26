<pre align="center">
███████╗   ██████╗   ███╗   ██╗  ██████╗   ███████╗  ██████╗
██╔════╝  ██╔═══██╗  ████╗  ██║  ██╔══██╗  ██╔════╝  ██╔══██╗
███████╗  ██║   ██║  ██╔██╗ ██║  ██║  ██║  █████╗    ██████╔╝
╚════██║  ██║   ██║  ██║╚██╗██║  ██║  ██║  ██╔══╝    ██╔══██╗
███████║  ╚██████╔╝  ██║ ╚████║  ██████╔╝  ███████╗  ██║  ██║
╚══════╝   ╚═════╝   ╚═╝  ╚═══╝  ╚═════╝   ╚══════╝  ╚═╝  ╚═╝
</pre>

<div align="center">

**Agent-grade workflows for AI-based development.**

`9` skills · `608` lines of pure instruction · `0` runtime dependencies

[![skills](https://img.shields.io/badge/skills-9-brightgreen?style=flat-square&logo=superuser)](skills/)
[![agent](https://img.shields.io/badge/agents-OpenCode-black?style=flat-square)](https://opencode.ai)
[![contract](https://img.shields.io/badge/contracts-machine--parsed-blue?style=flat-square)](skills/plan-generator/SKILL.md)

</div>

---

## This Is Why Your Workflow Is A Mess, Use sonder-skills

Language models are brilliant and unreliable in equal measure. Give one a raw
prompt and you get code that _mostly_ works, committed in one lump, with no
plan, no review, and no trace of what was assumed.

**sonder-skills** is a loadout of composable, machine-parseable workflows that
turn a raw LLM into something closer to an engineer with a process: it plans
before it types, reviews before it commits, fails closed instead of faking
green, and leaves a paper trail a human can audit.

No framework. No daemon. No API key. Just markdown that tells the agent
_exactly_ what to do, in what order, and when to stop.

---

## The Arsenal

Every skill is a self-contained `SKILL.md` — trigger conditions, an explicit
process, hard gates, and a defined output contract. The model doesn't
_imagine_ a workflow; it executes one.

### ★ Core Three

The load-bearing trio — plan the work, run the pipeline, ship the result.

<table>
<tr><td>

**★ [`plan-generator`](skills/plan-generator/SKILL.md)**
Turns a vague feature request into a **spec → phased roadmap → verification
gates**, written to one markdown file. Cheap planning up front so a
misunderstanding doesn't compound into three wrong files.

</td><td>

**★ [`plan-executor`](skills/plan-executor/SKILL.md)**
Walks that file phase by phase, ticks `- [ ]` boxes to `- [x]`, and
**actually verifies each `Gate:`** before moving on. Never skips.
Never fakes it.

</td></tr>
<tr><td colspan="2">

**★ [`commit-review`](skills/commit-review/SKILL.md)**
The full pipeline: review the changes, fix them, commit them atomically,
summarize the run. Orchestrates three specialist skills and does no
reviewing, fixing, or committing itself. Invoking it **is** the commit
authorization.

</td></tr>
</table>

### The Specialists

Each one is useful alone and orchestration-ready as a stage in something
bigger.

| Skill                                                        | What it hijacks                                                                                                                                        |
| ------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [`correctness-review`](skills/correctness-review/SKILL.md)   | Logic, quality, safety, pattern consistency. Returns a structured `PASS`/`FAIL` verdict with tagged findings. Reads, never writes.                     |
| [`context-review`](skills/context-review/SKILL.md)           | The pass pure code-reading misses: git history, cross-references, diagnostics, build status. Also `PASS`/`FAIL`.                                       |
| [`fix-review-findings`](skills/fix-review-findings/SKILL.md) | Takes an exact findings list and fixes **only those** — grouped per file, one delegated subagent per file, verified after each. No drive-by refactors. |
| [`review-changes`](skills/review-changes/SKILL.md)           | The loop: **review → fix → re-review**, capped at 3 cycles, ending in `PASS`, `FAIL`, or `NO CHANGES`.                                                 |
| [`atomic-commit`](skills/atomic-commit/SKILL.md)             | One file, one Conventional Commit, written from the actual diff — never `update stuff`. Self-installs its own helper script on first use.              |
| [`commit-summary`](skills/commit-summary/SKILL.md)           | Formats findings + fixes + commits into a structured report. Formatting only — it touches nothing.                                                     |

---

## System Map

```
                       ┌─────────────────────────────────────────┐
                       │            commit-review                │
                       │        (review → ship → report)         │
                       └────────┬───────────┬───────────┬────────┘
                                │           │           │
                ┌───────────────▼──┐  ┌─────▼──────┐  ┌─▼─────────────┐
                │  review-changes  │  │ atomic-     │  │ commit-       │
                │ review⇄fix⇄re-run│  │ commit      │  │ summary       │
                └───┬─────────┬────┘  └────────────┘  └───────────────┘
                    │         │
        ┌───────────▼──┐  ┌───▼──────────────┐     ┌──────────────────┐
        │ correctness- │  │ context-review   │     │  plan-generator  │
        │ review       │  │ history ⨯ build  │     │  spec▸roadmap▸   │
        └───────┬──────┘  └──────────────────┘     │  gates           │
                │                                  └────────┬─────────┘
                └────────────►┌──────────────────┐◄─────────┘
                              │ fix-review-      │   shared contract:
                              │ findings         │   - [ ] tasks,
                              │ (delegated subs) │   **Gate:** lines
                              └──────────────────┘         │
                                                           ▼
                                                  ┌──────────────────┐
                                                  │  plan-executor   │
                                                  └──────────────────┘
```

Two hard composition rules run through the whole set:

1. **Separation of powers** — reviewers never fix, fixers never review,
   reviewers and fixers never touch git. One skill, one responsibility.
2. **Fail closed** — a review still failing after 3 cycles stops the
   pipeline. Nothing gets committed on a red verdict. Ever.

---

## Install

Add the whole loadout to any project with one command:

```bash
npx skills add The-BoxHead-Guy/sonder-skills
```

or, if you're team pnpm:

```bash
pnpm dlx skills add The-BoxHead-Guy/sonder-skills
```

That's it — the skills are discovered and routed on natural language from
there.

---

## Contribution

Working from source, hacking on skills, or sending changes back?

```bash
git clone git@github.com:The-BoxHead-Guy/sonder-skills.git
```

Register the local `skills/` folder for discovery:

```jsonc
// opencode.json
{
  "$schema": "https://opencode.ai/config.json",
  "skills": { "paths": ["./skills"] },
}
```

Or vendor individual skills into your own repo so every agent working there
inherits the process:

```bash
mkdir -p .opencode/skills
cp -r sonder-skills/skills/{plan-generator,plan-executor,atomic-commit} .opencode/skills/
```

Each skill is a plain directory — `SKILL.md` plus optional `scripts/` and
`references/`. Copy what you need, delete what you don't, edit the process.
There is nothing to install and nothing to break.

**To contribute a skill:** keep the shape the rest of the set relies on —
frontmatter `name` + explicit `description` with triggers and anti-triggers,
numbered phases, concrete gates, and a defined output block. One skill, one
responsibility. Open a PR.

---

<div align="center">

**trust the process, not the temperature.**

_read the diffs · tick the gates · fail closed · commit clean_

</div>
