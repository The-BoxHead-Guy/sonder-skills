#!/usr/bin/env bash
# Refresh skills from upstream sources, then show what changed.
# Review the diff and commit manually; this script never commits or pushes.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

echo "Updating skills from upstream (aihero/mattpocock + others)..."
npx --yes skills@latest update

echo
echo "Changed files:"
git status --short
