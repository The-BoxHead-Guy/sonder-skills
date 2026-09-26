---
name: atomic-commit
description: "Atomic git commits: one file per commit using conventional commits. Triggers: /atomic-commit, atomic commit, commit atomically, one file per commit.lightweight alternative to commit-review (no review loop)."
---

# atomic-commit: One File Per Commit

Lightweight atomic commit workflow. No review loop — just stage, verify, commit.

## When to Use

- User says "commit", "commit this", "commit all", "atomic commit"
- Multiple files changed and each needs its own commit
- Quick commit without full review cycle

## When NOT to Use

- User wants review before commit → use `commit-review` instead

## Procedure

### Step 1: Check Git State

```bash
git status --short
git diff --name-only
git ls-files --others --exclude-standard
```

If NO uncommitted changes → report "Nothing to commit" and stop.

### Step 2: Read Changed Files

Read every changed file to understand the changes and write good commit messages.

### Step 3: Build Commits File

Create `/tmp/atomic-commits.txt` with format:

```
path/to/file:type(scope): commit message
```

**Commit types**: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `perf`, `ci`, `build`

**Scope**: Project name from file path (e.g., `api`, `dashboard`, `scaem`, `carnets`)

**Rules**:

- ONE file per line
- ONE commit per file
- Descriptive message following Conventional Commits

### Step 4: Run Atomic Commits Script

```bash
bash .opencode/scripts/atomic-commits.sh /tmp/atomic-commits.txt
```

The script enforces:

- Exactly 1 file staged per commit
- Aborts all if verification fails
- Cleans up after itself

### Step 5: Report Results

List each commit hash and message. Confirm all files committed.

## Key Principles

1. **One file per commit** — no exceptions
2. **Conventional Commits** — `type(scope): message`
3. **No review loop** — this is the fast path
4. **Script enforcement** — atomic-commits.sh validates staging
