---
name: atomic-commit
description: |-
  Split staged/unstaged git changes into one Conventional Commit per file, for any git repo (single-package or monorepo). Self-installs its helper script on first use.
  Examples:
  - user: "commit this" → stage and commit each changed file separately
  - user: "atomic commit" / "commit atomically" → run the one-file-per-commit workflow
  - user: "split my changes into separate commits" → same workflow
  Do NOT use when the user wants a single combined commit, or wants to review/approve the diff first.
---

# atomic-commit: One File Per Commit

One commit per changed file, each with its own Conventional Commits message.
No review loop — stage, verify, commit.

## When NOT to Use

- User wants to review the diff before committing → use `commit-review` if available
- The changes are one indivisible logical unit (e.g. a rename touching an
  interface and all callers) → say so and propose a single commit instead

## Step 0: Locate (or Recreate) the Helper Script

The script is not always beside this `SKILL.md`. When the skill is installed
with `npx skills add`, it typically lives under `~/.agents/skills/...` (rather
than `~/.config/opencode/...`), so resolve its real path first instead of
assuming a fixed location.

1. Prefer the copy next to this skill's own directory:

   ```bash
   SCRIPT="scripts/atomic-commits.sh"   # relative to this skill's own directory
   ```

2. If that doesn't resolve to a real file, find the installed copy:

   ```bash
   find ~ -name atomic-commits.sh 2>/dev/null
   ```

   Use the first match — commonly
   `~/.agents/skills/atomic-commit/scripts/atomic-commits.sh` for
   `npx skills add` installs. Set `SCRIPT` to that absolute path.

3. Only if no copy exists anywhere, recreate it verbatim from
   `references/atomic-commits.sh.md`, `chmod +x` it, and use it.

4. If neither a found copy nor the reference file is available, fall back to
   manual `git add -- <file> && git commit -m "<msg>"` per file, verifying
   `git diff --cached --name-only` shows exactly one file each time.

Once `SCRIPT` points at a real, executable file, continue to Step 1.

## Step 1: Check Git State

```bash
git rev-parse --is-inside-work-tree
git status --short
```

No changes → report "Nothing to commit" and stop.

## Step 2: Read Changed Files

Read each changed file. Write specific messages — not "update file".

## Step 3: Decide Scope

| Repo shape                                   | Scope                                                                                              |
| -------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| Single-package repo                          | Usually none: `fix: handle null input`. Or a module name if boundaries are clear: `fix(auth): ...` |
| Monorepo (`apps/`, `packages/`, `services/`) | The app/package folder name: `feat(dashboard): ...`                                                |
| Ambiguous                                    | Ask once, or default to no scope — never invent a scope                                            |

Types: `feat fix docs style refactor test chore perf ci build`

## Step 4: Build Commits File

Tab-separated (not colon — messages often contain colons):

```bash
printf 'path/to/file\ttype(scope): message\n' >> /tmp/atomic-commits.txt
```

## Step 5: Run

```bash
bash "$SCRIPT" /tmp/atomic-commits.txt
```

Enforces one file staged per commit; aborts and unstages cleanly on any
mismatch; runs from repo root regardless of caller's cwd.

## Step 6: Report

`git log --oneline -n <count>`. Confirm all files committed. Remove
`/tmp/atomic-commits.txt`.

## Bundled Resources

```
atomic-commit/
├── SKILL.md
├── scripts/atomic-commits.sh        # enforcement script
└── references/atomic-commits.sh.md  # fallback copy for self-install
```
