#!/usr/bin/env bash
# install-global.sh — install Bitontree coding standards into the user's
# global Claude Code and Codex configuration, plus a global git commit-msg hook.
#
# Usage:
#   ./scripts/install-global.sh           # interactive
#   ./scripts/install-global.sh --force   # overwrite existing files without asking
#   ./scripts/install-global.sh --dry-run # show what would happen, change nothing
#
# What it does (all via symlink, so future `git pull` updates the rules everywhere):
#   1. ~/.claude/CLAUDE.md           -> <repo>/CLAUDE.md
#   2. ~/.codex/AGENTS.md            -> <repo>/AGENTS.md
#   3. ~/.bitontree-hooks/commit-msg -> <repo>/templates/commit-msg-hook
#      and runs: git config --global core.hooksPath ~/.bitontree-hooks
#
# Re-running is safe.

set -euo pipefail

force=0
dry_run=0
for arg in "$@"; do
  case "${arg}" in
    --force)   force=1 ;;
    --dry-run) dry_run=1 ;;
    -h|--help)
      sed -n '2,20p' "$0"; exit 0 ;;
    *)
      echo "Unknown arg: ${arg}" >&2; exit 1 ;;
  esac
done

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
claude_md="${repo_root}/CLAUDE.md"
agents_md="${repo_root}/AGENTS.md"
hook_src="${repo_root}/templates/commit-msg-hook"

for f in "${claude_md}" "${agents_md}" "${hook_src}"; do
  if [[ ! -f "${f}" ]]; then
    echo "✗ Missing required file: ${f}" >&2
    exit 1
  fi
done

run() {
  if (( dry_run )); then
    echo "[dry-run] $*"
  else
    eval "$@"
  fi
}

link_file() {
  local src="$1" dst="$2"
  local dst_dir
  dst_dir="$(dirname "${dst}")"

  run "mkdir -p '${dst_dir}'"

  if [[ -L "${dst}" ]]; then
    local current
    current="$(readlink "${dst}")"
    if [[ "${current}" == "${src}" ]]; then
      echo "✓ ${dst} already linked"
      return
    fi
    echo "  ${dst} is a symlink to ${current}"
  elif [[ -e "${dst}" ]]; then
    echo "  ${dst} already exists (not a symlink)"
    if (( dry_run )); then
      echo "  [dry-run] would prompt to overwrite (or use --force)."
      return
    fi
    if (( ! force )); then
      read -r -p "    Overwrite? [y/N] " ans || ans=""
      [[ "${ans}" =~ ^[Yy]$ ]] || { echo "  skipped."; return; }
    fi
    local backup="${dst}.bak.$(date +%Y%m%d%H%M%S)"
    echo "  backing up to ${backup}"
    run "mv '${dst}' '${backup}'"
  fi

  run "ln -sf '${src}' '${dst}'"
  echo "✓ linked ${dst} -> ${src}"
}

echo "Bitontree rulebook — global install"
echo "Repo: ${repo_root}"
echo

# 1. Claude Code
link_file "${claude_md}" "${HOME}/.claude/CLAUDE.md"

# 2. Codex
link_file "${agents_md}" "${HOME}/.codex/AGENTS.md"

# 3. Global git commit-msg hook
hooks_dir="${HOME}/.bitontree-hooks"
link_file "${hook_src}" "${hooks_dir}/commit-msg"
run "chmod +x '${hook_src}'"

current_hooks_path="$(git config --global --get core.hooksPath || true)"
if [[ "${current_hooks_path}" == "${hooks_dir}" ]]; then
  echo "✓ git core.hooksPath already set to ${hooks_dir}"
else
  if [[ -n "${current_hooks_path}" ]]; then
    echo "  git core.hooksPath is currently: ${current_hooks_path}"
    if (( dry_run )); then
      echo "  [dry-run] would prompt to replace with ${hooks_dir} (or use --force)."
    elif (( ! force )); then
      read -r -p "    Replace with ${hooks_dir}? [y/N] " ans || ans=""
      [[ "${ans}" =~ ^[Yy]$ ]] || { echo "  skipped hooksPath change."; exit 0; }
      run "git config --global core.hooksPath '${hooks_dir}'"
      echo "✓ set git core.hooksPath -> ${hooks_dir}"
    else
      run "git config --global core.hooksPath '${hooks_dir}'"
      echo "✓ set git core.hooksPath -> ${hooks_dir}"
    fi
  else
    run "git config --global core.hooksPath '${hooks_dir}'"
    echo "✓ set git core.hooksPath -> ${hooks_dir}"
  fi
fi

echo
echo "Done. To verify:"
echo "  ls -l ~/.claude/CLAUDE.md ~/.codex/AGENTS.md ~/.bitontree-hooks/commit-msg"
echo "  git config --global --get core.hooksPath"
