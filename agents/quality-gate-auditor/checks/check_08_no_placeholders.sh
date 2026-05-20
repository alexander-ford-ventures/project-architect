#!/usr/bin/env bash
# Author: Alexander Ford <alex@alexfordlabs.com>
# License: MIT
# Project: project-architect (https://github.com/alexfordlabs/project-architect)
# Check 8 (B08): no docs/**/*.md contains an unfilled {{placeholder}} literal.
# Pattern: \{\{[a-z_]+\}\} (lowercase + underscores; case-sensitive).
# Severity: BLOCKER — shipping a generated doc with unsubstituted
# {{project_name}}-style markers means the template engine failed and the
# downstream artifact is broken output. Phase 5 must not progress.
#
# Inputs:
#   $1 = PROJECT_ROOT (project directory to scan; defaults to ".")
#
# Truth-table:
#   - no docs/ directory                       -> INFO    pass "no docs/ directory"
#   - docs/ exists but no .md files            -> INFO    pass "no markdown files to check"
#   - no .md contains {{placeholder}}          -> BLOCKER pass "all N doc(s) have no unfilled placeholders"
#   - one or more .md contain {{placeholder}}  -> BLOCKER fail "<count> doc(s) contain unfilled placeholders: <relpaths + first match>"
#
# Severity rationale:
#   - BLOCKER on the failure path: a literal "{{project_name}}" in a shipped doc
#     is a broken template. It cannot be a warning — it indicates that the
#     orchestrator handed off a half-rendered template, which is a Phase-5 stop.
#   - INFO when the check legitimately has nothing to verify (no docs/ at all,
#     or no .md files) so the auditor doesn't claim a positive verdict on an
#     empty corpus.
#
# Pattern rationale:
#   - {{[a-z_]+}} matches our internal template-token convention (lowercase
#     name + underscore, e.g. {{project_name}}, {{adr_id}}). Uppercase
#     "{{TOC}}" and Jinja-style "{{ project_name }}" with spaces are NOT
#     flagged — they are out of scope for this check (covered elsewhere or
#     legitimate in third-party content embedded under docs/).
#
# Known limitations:
#   - Recursively scans every .md file under docs/ (subdirs included), with the
#     same in-line exclusion list as check_06/check_07. The shared
#     find_project_files helper is NOT used here because it strips
#     tests/fixtures/ paths — which would prevent the check from running when
#     PROJECT_ROOT is itself a fixture directory under tests/fixtures/.
#   - Reports only the FIRST matching `line:placeholder` pair per file in the
#     detail to keep the message bounded. The 300-char truncation via
#     truncate_json_string further protects the JSON envelope on pathological
#     fan-outs (many files, many matches each).
#   - auto_fixable=true: the orchestrator can dispatch decision-revisor to fill
#     in each {{key}} from state.decisions or rerun the template-substitution
#     step. The placeholder names themselves are mechanical to enumerate.

set -uo pipefail

# shellcheck source=_lib.sh
source "$(dirname "$0")/_lib.sh"

PROJECT_ROOT="${1:-.}"
DOCS_DIR="${PROJECT_ROOT}/docs"

if [[ ! -d "$DOCS_DIR" ]]; then
  emit_pass "B08" "INFO" "no_placeholders" "no docs/ directory"
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
  emit_pass "B08" "INFO" "no_placeholders" "no markdown files to check"
  exit 0
fi

# Scan each file for the first {{[a-z_]+}} match. -o = only matching part,
# -n = prefix with line number, -E = extended regex (so \{ doesn't need escape
# differences between BRE/ERE platforms). head -1 keeps the detail bounded.
PLACEHOLDERS=()
for f in "${MD_FILES[@]}"; do
  match=$(grep -onE '\{\{[a-z_]+\}\}' "$f" 2>/dev/null | head -1)
  if [[ -n "$match" ]]; then
    PLACEHOLDERS+=("$(relpath "$f"): $match")
  fi
done

if [[ ${#PLACEHOLDERS[@]} -eq 0 ]]; then
  emit_pass "B08" "BLOCKER" "no_placeholders" \
    "all ${#MD_FILES[@]} doc(s) have no unfilled placeholders"
  exit 0
fi

# Join failing entries with "; " WITHOUT mutating IFS (semgrep-friendly).
JOINED=""
for entry in "${PLACEHOLDERS[@]}"; do
  if [[ -z "$JOINED" ]]; then
    JOINED="$entry"
  else
    JOINED="${JOINED}; ${entry}"
  fi
done

DETAIL="${#PLACEHOLDERS[@]} doc(s) contain unfilled placeholders: ${JOINED}"
# UTF-8-safe character-level truncation via the _lib.sh helper.
DETAIL_TRUNC=$(truncate_json_string "$DETAIL" 300 | jq -r .)
emit_fail "B08" "BLOCKER" "no_placeholders" "$DETAIL_TRUNC" \
  "substitute each {{...}} placeholder with its real value (typically by dispatching decision-revisor or rerunning template substitution)" \
  true
