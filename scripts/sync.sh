#!/usr/bin/env bash
# sync.sh — keep CLAUDE.md and AGENTS.md byte-identical.
#
# CLAUDE.md is the source of truth. Run this after editing it.
# Also run as a CI check: `./scripts/sync.sh --check` exits non-zero if drifted.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
src="${repo_root}/CLAUDE.md"
dst="${repo_root}/AGENTS.md"

mode="apply"
if [[ "${1:-}" == "--check" ]]; then
  mode="check"
fi

if [[ ! -f "${src}" ]]; then
  echo "✗ ${src} missing." >&2
  exit 1
fi

if [[ "${mode}" == "check" ]]; then
  if ! diff -q "${src}" "${dst}" >/dev/null 2>&1; then
    echo "✗ AGENTS.md is out of sync with CLAUDE.md" >&2
    echo "  Run scripts/sync.sh to fix." >&2
    diff "${src}" "${dst}" || true
    exit 1
  fi
  echo "✓ AGENTS.md matches CLAUDE.md"
  exit 0
fi

cp "${src}" "${dst}"
echo "✓ synced ${dst} from ${src}"
