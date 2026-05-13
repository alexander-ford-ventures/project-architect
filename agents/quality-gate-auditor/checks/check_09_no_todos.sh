#!/usr/bin/env bash
# Author: Vladimir Dukelic <vladimir@dukelic.com>
# License: MIT
# Project: project-architect (https://github.com/siliconyouth/project-architect)
# Check 9 (B09): no docs/**/*.md contains a TODO/FIXME/XXX marker.
# Pattern: \b(TODO|FIXME|XXX)\b (case-sensitive, word-boundary).
# Severity: WARNING — TODOs in delivered docs are workflow hints, not broken
# output. They signal "the author parked an unfinished thought here" but the
# document is still usable. Phase 5 can ship, the orchestrator just flags it
# so the reviewer knows where the gaps are.
#
# Inputs:
#   $1 = PROJECT_ROOT (project directory to scan; defaults to ".")
#
# Truth-table:
#   - no docs/ directory                                       -> INFO    pass "no docs/ directory"
#   - docs/ exists but no .md files                            -> INFO    pass "no markdown files to check"
#   - all .md (except BACKLOG.md) free of TODO/FIXME/XXX       -> WARNING pass "all N doc(s) free of TODO/FIXME/XXX markers"
#   - one or more .md (not BACKLOG.md) contain a marker        -> WARNING fail "<count> doc(s) contain TODO/FIXME/XXX: <relpaths + first match>"
#
# Severity rationale:
#   - WARNING (not BLOCKER) on the failure path: a TODO in a generated spec is
#     sub-optimal but the doc is still a useful artifact. The author left a
#     note for someone to finish; that's a process gap, not a broken build.
#   - INFO when the check legitimately has nothing to verify (no docs/ at all,
#     or no .md files) so the auditor doesn't claim a positive verdict on an
#     empty corpus.
#
# BACKLOG.md exclusion rationale:
#   - BACKLOG.md is the project-architect canonical place for known TODOs. By
#     design it collects unfinished work, so flagging it here would generate
#     noise on every audit. We match the basename so any subdir's BACKLOG.md
#     (root, docs/, docs/superpowers/, etc.) is excluded uniformly.
#
# Pattern rationale:
#   - \b(TODO|FIXME|XXX)\b is case-sensitive on purpose: lowercase "todo" in
#     prose ("the todo list is at the end") is a noun, not a marker, and
#     should not trip the check. The word-boundary anchors prevent substring
#     false positives like "TODOs are common practice" or "FOXXXING" — the
#     marker must appear as a standalone token.
#   - Three markers covered (TODO/FIXME/XXX): industry-standard conventions
#     used across editors (VS Code Todo Tree, JetBrains TODO inspections) and
#     linters (eslint-plugin-no-warning-comments). HACK and BUG are also
#     common but excluded here to keep the surface area narrow; if they
#     prove necessary they can be added in a follow-up.
#
# Known limitations:
#   - Recursively scans every .md file under docs/ (subdirs included), with the
#     same in-line exclusion list as check_06/check_07/check_08. The shared
#     find_project_files helper is NOT used here because it strips
#     tests/fixtures/ paths — which would prevent the check from running when
#     PROJECT_ROOT is itself a fixture directory under tests/fixtures/.
#   - Reports only the FIRST matching `line:marker` pair per file in the
#     detail to keep the message bounded. The 300-char truncation via
#     truncate_json_string further protects the JSON envelope on pathological
#     fan-outs (many files, many markers each).
#   - auto_fixable=false: a TODO is a human-written hint about unfinished
#     thought; the orchestrator can't safely "finish" the thought. Someone
#     must read each one and decide to either resolve it, move it to
#     BACKLOG.md, or accept it as a known gap.

set -uo pipefail

# shellcheck source=_lib.sh
source "$(dirname "$0")/_lib.sh"

PROJECT_ROOT="${1:-.}"
DOCS_DIR="${PROJECT_ROOT}/docs"

if [[ ! -d "$DOCS_DIR" ]]; then
  emit_pass "B09" "INFO" "no_todos" "no docs/ directory"
  exit 0
fi

# Collect every .md file under docs/. In-line `find` (not find_project_files)
# because the helper strips tests/fixtures/* paths, which would render the
# check unrunnable when PROJECT_ROOT is itself a fixture directory under
# tests/fixtures/. Exclusions mirror the helper's standard list so a real
# project audit doesn't trip on vendored docs.
MD_FILES=()
while IFS= read -r f; do
  [[ -n "$f" ]] && MD_FILES+=("$f")
done < <(
  find "$DOCS_DIR" -type f -name "*.md" \
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

if [[ ${#MD_FILES[@]} -eq 0 ]]; then
  emit_pass "B09" "INFO" "no_todos" "no markdown files to check"
  exit 0
fi

# Filter out BACKLOG.md (by design the place where TODOs live). Match on
# basename so any subdir's BACKLOG.md is excluded uniformly. We rebuild the
# array rather than mutating in place to keep semgrep + shellcheck happy
# and to make the intent obvious at a glance.
FILTERED=()
for f in "${MD_FILES[@]}"; do
  if [[ "$(basename "$f")" == "BACKLOG.md" ]]; then
    continue
  fi
  FILTERED+=("$f")
done
MD_FILES=("${FILTERED[@]}")

if [[ ${#MD_FILES[@]} -eq 0 ]]; then
  # Only BACKLOG.md existed under docs/, and we excluded it. Treat as a
  # legitimate empty corpus for this check's purposes.
  emit_pass "B09" "INFO" "no_todos" "no markdown files to check (BACKLOG.md excluded by design)"
  exit 0
fi

# Scan each file for the first \b(TODO|FIXME|XXX)\b match. -o = only matching
# part, -n = prefix with line number, -E = extended regex (so the alternation
# group works without backslashes). head -1 keeps the detail bounded.
TODOS=()
for f in "${MD_FILES[@]}"; do
  match=$(grep -onE '\b(TODO|FIXME|XXX)\b' "$f" 2>/dev/null | head -1)
  if [[ -n "$match" ]]; then
    TODOS+=("$(relpath "$f"): $match")
  fi
done

if [[ ${#TODOS[@]} -eq 0 ]]; then
  emit_pass "B09" "WARNING" "no_todos" \
    "all ${#MD_FILES[@]} doc(s) free of TODO/FIXME/XXX markers"
  exit 0
fi

# Join failing entries with "; " WITHOUT mutating IFS (semgrep-friendly).
JOINED=""
for entry in "${TODOS[@]}"; do
  if [[ -z "$JOINED" ]]; then
    JOINED="$entry"
  else
    JOINED="${JOINED}; ${entry}"
  fi
done

DETAIL="${#TODOS[@]} doc(s) contain TODO/FIXME/XXX: ${JOINED}"
# UTF-8-safe character-level truncation via the _lib.sh helper.
DETAIL_TRUNC=$(truncate_json_string "$DETAIL" 300 | jq -r .)
emit_fail "B09" "WARNING" "no_todos" "$DETAIL_TRUNC" \
  "review each TODO/FIXME/XXX: resolve it, move it to BACKLOG.md (the canonical place for parked work), or accept it as a documented known gap" \
  false
