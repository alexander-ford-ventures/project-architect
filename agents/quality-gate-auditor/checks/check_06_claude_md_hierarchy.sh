#!/usr/bin/env bash
# Author: Alexander Ford <alex@alexfordlabs.com>
# License: MIT
# Project: project-architect (https://github.com/alexfordlabs/project-architect)
# Check 6 (B06): if state.decisions.project.has_subfolders==true, the project
# must have BOTH a root CLAUDE.md AND >=1 subfolder CLAUDE.md. Catches the
# "root-only CLAUDE.md" anti-pattern (bug #8 from the v2.1.5 md2pdf live test).
#
# Inputs:
#   $1 = PROJECT_ROOT (project directory to scan; defaults to ".")
#   $2 = STATE_PATH   (path to state.json; defaults to PROJECT_ROOT/docs/_architect_state.json)
#
# Truth-table:
#   - state.json missing or unparseable              -> INFO    pass (deferred to json_valid)
#   - has_subfolders != true (false/null/absent)     -> INFO    pass "subfolder hierarchy not required"
#   - has_subfolders==true AND no root CLAUDE.md     -> INFO    pass "no root CLAUDE.md (pre-Phase-7?)"
#   - has_subfolders==true AND root + >=1 subfolder  -> WARNING pass "<N> subfolder CLAUDE.md(s) found"
#   - has_subfolders==true AND root + 0 subfolder    -> WARNING fail "root CLAUDE.md exists but no subfolder CLAUDE.md found"
#
# Severity rationale:
#   - WARNING (not BLOCKER) on the failure path: a flat-but-functional CLAUDE.md
#     hierarchy is sub-optimal but not catastrophic; Phase 5 can still proceed.
#     The author will be nudged to add per-subfolder routers in follow-up.
#   - INFO when the check legitimately has nothing to verify (no state, monolith
#     project, or pre-Phase-7 layout) so the auditor doesn't crow about a check
#     it didn't actually run.
#
# Known limitations:
#   - "Subfolder CLAUDE.md" means EXACTLY one level deep (find -mindepth 2
#     -maxdepth 2). Deeper nested CLAUDE.mds (e.g. src/foo/bar/CLAUDE.md) do
#     NOT satisfy the check on their own — the typical project layout puts
#     routers at src/, tests/, docs/, etc.
#   - Uses an in-line `find` with the same exclusion list as
#     _lib.sh::find_project_files rather than the helper itself, because the
#     helper does not constrain depth. The exclusions are duplicated by design.
#   - auto_fixable=false: deciding *which* subfolders deserve a CLAUDE.md is a
#     judgement call best left to claude-md-author in Phase 7.

set -uo pipefail

# shellcheck source=_lib.sh
source "$(dirname "$0")/_lib.sh"

PROJECT_ROOT="${1:-.}"
STATE_PATH="${2:-${PROJECT_ROOT}/docs/_architect_state.json}"

if [[ ! -f "$STATE_PATH" ]] || ! require_valid_json "$STATE_PATH"; then
  emit_pass "B06" "INFO" "claude_md_hierarchy" \
    "state.json missing or unparseable (deferred to json_valid)"
  exit 0
fi

HAS_SUBFOLDERS=$(jq -r '.decisions.project.has_subfolders // false' "$STATE_PATH" 2>/dev/null)
if [[ "$HAS_SUBFOLDERS" != "true" ]]; then
  emit_pass "B06" "INFO" "claude_md_hierarchy" \
    "subfolder hierarchy not required (has_subfolders!=true)"
  exit 0
fi

ROOT_CLAUDE="${PROJECT_ROOT}/CLAUDE.md"
if [[ ! -f "$ROOT_CLAUDE" ]]; then
  emit_pass "B06" "INFO" "claude_md_hierarchy" \
    "no root CLAUDE.md (project may be pre-Phase-7)"
  exit 0
fi

# Find subfolder CLAUDE.mds — one level down only, excluding standard dirs.
# Exclusions mirror _lib.sh::find_project_files; depth-constraint forces
# in-line find rather than helper reuse.
SUBFOLDER_CLAUDES=()
while IFS= read -r f; do
  [[ -n "$f" ]] && SUBFOLDER_CLAUDES+=("$f")
done < <(
  find "$PROJECT_ROOT" -mindepth 2 -maxdepth 2 -type f -name "CLAUDE.md" \
    -not -path "*/tests/fixtures/*" \
    -not -path "*/.git/*" \
    -not -path "*/node_modules/*" \
    -not -path "*/vendor/*" \
    -not -path "*/target/*" \
    -not -path "*/dist/*" \
    -not -path "*/build/*" \
    -not -path "*/.venv/*" \
    -not -path "*/.tox/*" \
    -not -path "*/__pycache__/*" \
    -not -path "*/.next/*" \
    -not -path "*/.terraform/*" \
    -not -path "*/coverage/*" \
    -not -path "*/.cache/*" \
    -not -path "*/.claude/*" \
    -not -path "*/.serena/*" \
    -not -path "*/.idea/*" \
    -not -path "*/.vscode/*" \
    2>/dev/null
)

if [[ ${#SUBFOLDER_CLAUDES[@]} -eq 0 ]]; then
  emit_fail "B06" "WARNING" "claude_md_hierarchy" \
    "root CLAUDE.md exists but no subfolder CLAUDE.md found (has_subfolders=true → expected >=1)" \
    "create per-subfolder CLAUDE.md files for substantial subdirectories OR set state.decisions.project.has_subfolders=false" \
    false
  exit 0
fi

emit_pass "B06" "WARNING" "claude_md_hierarchy" \
  "${#SUBFOLDER_CLAUDES[@]} subfolder CLAUDE.md(s) found alongside root"
