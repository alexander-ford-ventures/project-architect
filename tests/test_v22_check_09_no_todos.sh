#!/usr/bin/env bash
# Author: Alexander Ford <alex@alexfordlabs.com>
# License: MIT
# Project: project-architect (https://github.com/alexfordlabs/project-architect)
# Tests for check_09_no_todos.sh (Sketch B, check ID B09, WARNING).
# Covers the TODO/FIXME/XXX scanner over docs/**/*.md, including the
# BACKLOG.md exclusion (BACKLOG.md is the canonical place for parked
# TODOs and must NOT trip the check).

source "$(dirname "$0")/lib/test_helpers.sh"

CHECK="$REPO_ROOT/agents/quality-gate-auditor/checks/check_09_no_todos.sh"
assert_file_exists "$CHECK" "check_09 must exist"
assert_executable "$CHECK" "check_09 must be executable"

# Skip remaining functional checks gracefully if jq isn't installed (the check
# uses jq for JSON encoding of the detail field).
if ! command -v jq >/dev/null 2>&1; then
  echo "SKIP: jq not installed; cannot test check_09 fully"
  test_summary
  exit 0
fi

# (1) No docs/ directory: a fresh tempdir with no docs/ subtree -> INFO pass.
NODOCS_TMP=$(mktemp -d)
RESULT_NODOCS=$(bash "$CHECK" "$NODOCS_TMP")
PASSED_NODOCS=$(echo "$RESULT_NODOCS" | jq -r .passed)
assert_eq "$PASSED_NODOCS" "true" "no-docs fixture must pass"
SEVERITY_NODOCS=$(echo "$RESULT_NODOCS" | jq -r .severity)
assert_eq "$SEVERITY_NODOCS" "INFO" "no-docs severity must be INFO"
DETAIL_NODOCS=$(echo "$RESULT_NODOCS" | jq -r .detail)
assert_contains "$DETAIL_NODOCS" "no docs/" "no-docs detail must mention 'no docs/'"
rm -rf "$NODOCS_TMP"

# (2) docs/ exists but no .md files: INFO pass.
NOMD_TMP=$(mktemp -d)
mkdir -p "$NOMD_TMP/docs"
RESULT_NOMD=$(bash "$CHECK" "$NOMD_TMP")
PASSED_NOMD=$(echo "$RESULT_NOMD" | jq -r .passed)
assert_eq "$PASSED_NOMD" "true" "docs-empty-of-md fixture must pass"
SEVERITY_NOMD=$(echo "$RESULT_NOMD" | jq -r .severity)
assert_eq "$SEVERITY_NOMD" "INFO" "docs-empty-of-md severity must be INFO"
DETAIL_NOMD=$(echo "$RESULT_NOMD" | jq -r .detail)
assert_contains "$DETAIL_NOMD" "no markdown files" "no-md detail must mention 'no markdown files'"
rm -rf "$NOMD_TMP"

# (3) All-clean: tempdir with one .md containing zero TODO/FIXME/XXX matches
#     -> WARNING pass (the check ran, found nothing, asserts a positive verdict).
ALLOK_TMP=$(mktemp -d)
mkdir -p "$ALLOK_TMP/docs"
printf '# Clean doc\n\nNo markers here.\nJust prose.\n' > "$ALLOK_TMP/docs/X.md"
RESULT_ALLOK=$(bash "$CHECK" "$ALLOK_TMP")
PASSED_ALLOK=$(echo "$RESULT_ALLOK" | jq -r .passed)
assert_eq "$PASSED_ALLOK" "true" "all-clean fixture must pass"
SEVERITY_ALLOK=$(echo "$RESULT_ALLOK" | jq -r .severity)
assert_eq "$SEVERITY_ALLOK" "WARNING" "all-clean severity must be WARNING (positive verdict)"
DETAIL_ALLOK=$(echo "$RESULT_ALLOK" | jq -r .detail)
assert_contains "$DETAIL_ALLOK" "all 1 doc" "all-clean detail must mention doc count"
assert_contains "$DETAIL_ALLOK" "free of TODO/FIXME/XXX" "all-clean detail must label the verdict"
rm -rf "$ALLOK_TMP"

# (4) todo-in-readme fixture: docs/A.md contains a TODO marker -> WARNING fail.
RESULT_BAD=$(bash "$CHECK" "$REPO_ROOT/tests/fixtures/todo-in-readme")
PASSED_BAD=$(echo "$RESULT_BAD" | jq -r .passed)
assert_eq "$PASSED_BAD" "false" "todo-in-readme fixture must FAIL"
SEVERITY_BAD=$(echo "$RESULT_BAD" | jq -r .severity)
assert_eq "$SEVERITY_BAD" "WARNING" "todo-in-readme failure severity must be WARNING (not BLOCKER)"
DETAIL_BAD=$(echo "$RESULT_BAD" | jq -r .detail)
assert_contains "$DETAIL_BAD" "docs/A.md" "bad detail must name A.md"
assert_contains "$DETAIL_BAD" "TODO" "bad detail must echo the marker"
assert_contains "$DETAIL_BAD" "TODO/FIXME/XXX" "bad detail must label the failure mode"
AUTOFIX_BAD=$(echo "$RESULT_BAD" | jq -r .auto_fixable)
assert_eq "$AUTOFIX_BAD" "false" "todo-in-readme must be auto_fixable=false (humans must triage TODOs)"
REMEDIATION_BAD=$(echo "$RESULT_BAD" | jq -r .remediation)
assert_contains "$REMEDIATION_BAD" "BACKLOG.md" "remediation must mention BACKLOG.md as the canonical destination"

# (5) BACKLOG.md must NOT be flagged: a tempdir whose ONLY .md is a BACKLOG.md
#     full of TODOs must come back as the empty-corpus INFO pass (BACKLOG is
#     excluded by design — that's where TODOs are expected to live).
BACKLOG_ONLY_TMP=$(mktemp -d)
mkdir -p "$BACKLOG_ONLY_TMP/docs"
{
  printf '# BACKLOG\n\n'
  printf '%s\n' '- TODO: build the next thing'
  printf '%s\n' '- FIXME: dependency mismatch'
  printf '%s\n' '- XXX: design question for human review'
} > "$BACKLOG_ONLY_TMP/docs/BACKLOG.md"
RESULT_BACKLOG=$(bash "$CHECK" "$BACKLOG_ONLY_TMP")
PASSED_BACKLOG=$(echo "$RESULT_BACKLOG" | jq -r .passed)
assert_eq "$PASSED_BACKLOG" "true" "BACKLOG-only fixture must pass (BACKLOG.md is excluded by design)"
SEVERITY_BACKLOG=$(echo "$RESULT_BACKLOG" | jq -r .severity)
assert_eq "$SEVERITY_BACKLOG" "INFO" "BACKLOG-only severity must be INFO (empty corpus post-exclusion)"
DETAIL_BACKLOG=$(echo "$RESULT_BACKLOG" | jq -r .detail)
assert_contains "$DETAIL_BACKLOG" "BACKLOG.md excluded" "BACKLOG-only detail must mention the exclusion"
rm -rf "$BACKLOG_ONLY_TMP"

# (6) Mixed: tempdir with TWO .md files — one clean prose doc, one with a
#     FIXME — must FAIL listing ONLY the dirty file. Also seeds a BACKLOG.md
#     full of TODOs alongside to confirm the exclusion holds when other
#     .md files are present (not just when BACKLOG.md is the only file).
MIXED_TMP=$(mktemp -d)
mkdir -p "$MIXED_TMP/docs"
printf '# Good\n\nNo markers, just prose.\n' > "$MIXED_TMP/docs/good.md"
printf '# Bad\n\nFIXME: this paragraph needs a citation.\n' > "$MIXED_TMP/docs/bad.md"
printf '%s\n%s\n' '# BACKLOG' '- TODO: future work item' > "$MIXED_TMP/docs/BACKLOG.md"
RESULT_MIXED=$(bash "$CHECK" "$MIXED_TMP")
PASSED_MIXED=$(echo "$RESULT_MIXED" | jq -r .passed)
assert_eq "$PASSED_MIXED" "false" "mixed fixture must FAIL (bad.md has FIXME)"
DETAIL_MIXED=$(echo "$RESULT_MIXED" | jq -r .detail)
assert_contains "$DETAIL_MIXED" "bad.md" "mixed detail must name bad.md"
assert_contains "$DETAIL_MIXED" "FIXME" "mixed detail must echo the FIXME marker"
assert_not_contains "$DETAIL_MIXED" "good.md" "mixed detail must NOT name good.md"
assert_not_contains "$DETAIL_MIXED" "BACKLOG.md" "mixed detail must NOT name BACKLOG.md (excluded by design)"
assert_contains "$DETAIL_MIXED" "1 doc" "mixed detail must report count=1 (only bad.md, not BACKLOG.md)"
rm -rf "$MIXED_TMP"

# (7) Pattern discipline: lowercase "todo" in prose and substring matches
#     like "TODOs are common" must NOT be flagged — the check is
#     case-sensitive and word-boundary-anchored on purpose.
NOMATCH_TMP=$(mktemp -d)
mkdir -p "$NOMATCH_TMP/docs"
{
  printf '# Out-of-scope variants\n\n'
  printf 'Lowercase: the todo list lives in BACKLOG.md.\n'
  printf 'Substring: TODOs are common practice in software docs.\n'
  printf 'Hyphenated: pre-TODO-merge tasks were already done.\n'
  printf 'Adjacent: noting-the-XXXTODO-block style is rare.\n'
} > "$NOMATCH_TMP/docs/edge.md"
RESULT_NOMATCH=$(bash "$CHECK" "$NOMATCH_TMP")
PASSED_NOMATCH=$(echo "$RESULT_NOMATCH" | jq -r .passed)
# Note on word-boundary semantics:
#   - "TODOs" (plural)         : \b breaks on T at start but the trailing 's'
#                                keeps \b from matching after "TODO", so the
#                                exact 4-char token "TODO" doesn't appear as
#                                a standalone word — NO MATCH.
#   - "pre-TODO-merge"         : hyphens are non-word chars, so \b matches
#                                on BOTH sides of "TODO" — MATCH on line 5.
#   - "noting-the-XXXTODO-..." : "XXXTODO" is one alnum token (no internal
#                                boundary), so neither XXX nor TODO matches
#                                as a standalone word — NO MATCH.
#   - "todo" / "fixme" / "xxx" : case-sensitive pattern — NO MATCH.
# Net effect: exactly one match expected, on the hyphenated TODO.
assert_eq "$PASSED_NOMATCH" "false" "hyphenated TODO must trigger (word-boundary holds at hyphen)"
DETAIL_NOMATCH=$(echo "$RESULT_NOMATCH" | jq -r .detail)
assert_contains "$DETAIL_NOMATCH" "edge.md" "edge detail must name edge.md"
assert_contains "$DETAIL_NOMATCH" "5:TODO" "edge detail must point at line 5 (the hyphenated TODO)"
assert_contains "$DETAIL_NOMATCH" "1 doc" "edge detail must report count=1 (only the hyphenated TODO matched)"
rm -rf "$NOMATCH_TMP"

# (8) Lowercase-only fixture: confirm pure lowercase "todo" / "fixme" do NOT
#     trip the check (case-sensitive pattern).
LOWER_TMP=$(mktemp -d)
mkdir -p "$LOWER_TMP/docs"
{
  printf '# Lowercase-only\n\n'
  printf 'The todo list is short. Any fixme notes live in BACKLOG.md.\n'
  printf 'Also xxx is just a placeholder in prose.\n'
} > "$LOWER_TMP/docs/lower.md"
RESULT_LOWER=$(bash "$CHECK" "$LOWER_TMP")
PASSED_LOWER=$(echo "$RESULT_LOWER" | jq -r .passed)
assert_eq "$PASSED_LOWER" "true" "lowercase-only doc must pass (case-sensitive pattern)"
SEVERITY_LOWER=$(echo "$RESULT_LOWER" | jq -r .severity)
assert_eq "$SEVERITY_LOWER" "WARNING" "lowercase-only severity must be WARNING pass"
rm -rf "$LOWER_TMP"

# (9) Nested subdirs: ensure recursive scan picks up docs/sub/a.md too.
NESTED_TMP=$(mktemp -d)
mkdir -p "$NESTED_TMP/docs/sub"
printf '# Nested\n\nXXX: this section needs rewriting.\n' > "$NESTED_TMP/docs/sub/a.md"
RESULT_NESTED=$(bash "$CHECK" "$NESTED_TMP")
PASSED_NESTED=$(echo "$RESULT_NESTED" | jq -r .passed)
assert_eq "$PASSED_NESTED" "false" "nested-subdir fixture must FAIL"
DETAIL_NESTED=$(echo "$RESULT_NESTED" | jq -r .detail)
assert_contains "$DETAIL_NESTED" "docs/sub/a.md" "nested detail must name docs/sub/a.md"
assert_contains "$DETAIL_NESTED" "XXX" "nested detail must echo the XXX marker"
rm -rf "$NESTED_TMP"

# (10) JSON-validity loop: every emitted finding must be valid JSON.
for r in "$RESULT_NODOCS" "$RESULT_NOMD" "$RESULT_ALLOK" "$RESULT_BAD" \
         "$RESULT_BACKLOG" "$RESULT_MIXED" "$RESULT_NOMATCH" \
         "$RESULT_LOWER" "$RESULT_NESTED"; do
  if echo "$r" | jq -e . >/dev/null 2>&1; then
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    FAIL_MESSAGES+=("FAIL: check output not valid JSON: $r")
  fi
done

test_summary
