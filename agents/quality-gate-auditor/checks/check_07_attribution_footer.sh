#!/usr/bin/env bash
# Author: Alexander Ford <alex@alexfordlabs.com>
# License: MIT
# Project: project-architect (https://github.com/alexfordlabs/project-architect)
# Check 7 (B07): every docs/*.md file ends with the project-architect
# attribution footer in its last 3 lines.
# Severity: INFO (cosmetic; never blocks Phase 5).
#
# The footer string (canonical):
#   *★ Skillfully made with [project-architect](https://github.com/alexfordlabs/project-architect).*
#
# Inputs:
#   $1 = PROJECT_ROOT (project directory to scan; defaults to ".")
#
# Truth-table:
#   - no docs/ directory                       -> INFO pass "no docs/ directory"
#   - docs/ exists but no .md files            -> INFO pass "no markdown files to check"
#   - all docs/*.md have the footer            -> INFO pass "all N doc(s) have attribution footer"
#   - one or more docs/*.md missing footer     -> INFO fail "N doc(s) missing attribution footer: <relpaths>"
#
# Severity rationale:
#   - INFO for BOTH pass and fail: the footer is cosmetic attribution. A missing
#     footer never blocks Phase 5 and never breaks downstream tooling. The auditor
#     simply nudges the author to append it; auto_fixable=true lets the orchestrator
#     append the footer programmatically when the user opts in.
#
# Known limitations:
#   - Recursively scans every .md file under docs/ (subdirs included), with the
#     same in-line exclusion list as check_06_claude_md_hierarchy. The shared
#     find_project_files helper is NOT used here because it strips
#     tests/fixtures/ paths — which would prevent the check from running against
#     a fixture passed as PROJECT_ROOT.
#   - Match logic: substring "Skillfully made with [project-architect]" must
#     appear in the LAST 3 LINES of the file. This tolerates trailing whitespace
#     or an extra blank line after the footer (common in editors that strip/add
#     trailing newlines) and trivially handles CRLF.
#   - auto_fixable=true: the orchestrator may append the canonical footer to any
#     listed file (the canonical string is stable and unambiguous).

set -uo pipefail

# shellcheck source=_lib.sh
source "$(dirname "$0")/_lib.sh"

PROJECT_ROOT="${1:-.}"
DOCS_DIR="${PROJECT_ROOT}/docs"

if [[ ! -d "$DOCS_DIR" ]]; then
  emit_pass "B07" "INFO" "attribution_footer" "no docs/ directory"
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
  emit_pass "B07" "INFO" "attribution_footer" "no markdown files to check"
  exit 0
fi

# Substring distinct enough to be unique to the canonical footer but tolerant of
# trailing whitespace/punctuation noise. (The full match would require an exact
# byte-for-byte line; substring-in-last-3-lines is the spec.)
FOOTER_SUBSTR="Skillfully made with [project-architect]"

MISSING=()
for f in "${MD_FILES[@]}"; do
  # Read last 3 lines and check substring presence. -F = fixed string (no regex
  # surprise on the bracket); -q = quiet exit-code-only.
  if ! tail -n 3 "$f" 2>/dev/null | grep -qF "$FOOTER_SUBSTR"; then
    MISSING+=("$(relpath "$f")")
  fi
done

if [[ ${#MISSING[@]} -eq 0 ]]; then
  emit_pass "B07" "INFO" "attribution_footer" \
    "all ${#MD_FILES[@]} doc(s) have attribution footer"
  exit 0
fi

# Join failing relpaths with "; " WITHOUT mutating IFS (semgrep-friendly).
JOINED=""
for entry in "${MISSING[@]}"; do
  if [[ -z "$JOINED" ]]; then
    JOINED="$entry"
  else
    JOINED="${JOINED}; ${entry}"
  fi
done

DETAIL="${#MISSING[@]} doc(s) missing attribution footer: ${JOINED}"
# UTF-8-safe character truncation via the _lib.sh helper.
DETAIL_TRUNC=$(truncate_json_string "$DETAIL" 300 | jq -r .)
emit_fail "B07" "INFO" "attribution_footer" "$DETAIL_TRUNC" \
  "append the attribution footer ('*★ Skillfully made with [project-architect](https://github.com/alexfordlabs/project-architect).*') as the last line of each listed doc" \
  true
