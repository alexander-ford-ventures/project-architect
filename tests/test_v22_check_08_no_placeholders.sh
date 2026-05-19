#!/usr/bin/env bash
# Author: Alexander Ford <alex@pseudo-lang.com>
# License: MIT
# Project: project-architect (https://github.com/alexander-ford-ventures/project-architect)
# Tests for check_08_no_placeholders.sh (Sketch B, check ID B08, BLOCKER).
# Covers the unfilled-placeholder check that scans docs/**/*.md for the
# pattern \{\{[a-z_]+\}\} and blocks Phase 5 when any match is found.

source "$(dirname "$0")/lib/test_helpers.sh"

CHECK="$REPO_ROOT/agents/quality-gate-auditor/checks/check_08_no_placeholders.sh"
assert_file_exists "$CHECK" "check_08 must exist"
assert_executable "$CHECK" "check_08 must be executable"

# Skip remaining functional checks gracefully if jq isn't installed (the check
# uses jq for JSON encoding of the detail field).
if ! command -v jq >/dev/null 2>&1; then
  echo "SKIP: jq not installed; cannot test check_08 fully"
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

# (3) All-clean: tempdir with one .md containing zero {{placeholder}} matches
#     -> BLOCKER pass (the check ran, found nothing, asserts a positive verdict).
ALLOK_TMP=$(mktemp -d)
mkdir -p "$ALLOK_TMP/docs"
printf '# Clean doc\n\nNo placeholders here.\nJust prose.\n' > "$ALLOK_TMP/docs/X.md"
RESULT_ALLOK=$(bash "$CHECK" "$ALLOK_TMP")
PASSED_ALLOK=$(echo "$RESULT_ALLOK" | jq -r .passed)
assert_eq "$PASSED_ALLOK" "true" "all-clean fixture must pass"
SEVERITY_ALLOK=$(echo "$RESULT_ALLOK" | jq -r .severity)
assert_eq "$SEVERITY_ALLOK" "BLOCKER" "all-clean severity must be BLOCKER (this check is a BLOCKER)"
DETAIL_ALLOK=$(echo "$RESULT_ALLOK" | jq -r .detail)
assert_contains "$DETAIL_ALLOK" "all 1 doc" "all-clean detail must mention doc count"
assert_contains "$DETAIL_ALLOK" "no unfilled placeholders" "all-clean detail must label the verdict"
rm -rf "$ALLOK_TMP"

# (4) unfilled-placeholder fixture: docs/A.md contains {{project_name}} -> BLOCKER fail.
RESULT_BAD=$(bash "$CHECK" "$REPO_ROOT/tests/fixtures/unfilled-placeholder")
PASSED_BAD=$(echo "$RESULT_BAD" | jq -r .passed)
assert_eq "$PASSED_BAD" "false" "unfilled-placeholder fixture must FAIL"
SEVERITY_BAD=$(echo "$RESULT_BAD" | jq -r .severity)
assert_eq "$SEVERITY_BAD" "BLOCKER" "unfilled-placeholder failure severity must be BLOCKER"
DETAIL_BAD=$(echo "$RESULT_BAD" | jq -r .detail)
assert_contains "$DETAIL_BAD" "docs/A.md" "bad detail must name A.md"
assert_contains "$DETAIL_BAD" "{{project_name}}" "bad detail must echo the placeholder literal"
assert_contains "$DETAIL_BAD" "unfilled placeholders" "bad detail must label the failure mode"
AUTOFIX_BAD=$(echo "$RESULT_BAD" | jq -r .auto_fixable)
assert_eq "$AUTOFIX_BAD" "true" "unfilled-placeholder must be auto_fixable=true"
REMEDIATION_BAD=$(echo "$RESULT_BAD" | jq -r .remediation)
assert_contains "$REMEDIATION_BAD" "substitute" "remediation must mention substitution"

# (5) Mixed: tempdir with TWO .md files, one clean, one with {{adr_id}} ->
#     BLOCKER fail listing ONLY the dirty file.
MIXED_TMP=$(mktemp -d)
mkdir -p "$MIXED_TMP/docs"
printf '# Good\n\nNo template tokens.\n' > "$MIXED_TMP/docs/good.md"
printf '# Bad\n\nReference: {{adr_id}} matters.\n' > "$MIXED_TMP/docs/bad.md"
RESULT_MIXED=$(bash "$CHECK" "$MIXED_TMP")
PASSED_MIXED=$(echo "$RESULT_MIXED" | jq -r .passed)
assert_eq "$PASSED_MIXED" "false" "mixed fixture must FAIL"
DETAIL_MIXED=$(echo "$RESULT_MIXED" | jq -r .detail)
assert_contains "$DETAIL_MIXED" "bad.md" "mixed detail must name bad.md"
assert_contains "$DETAIL_MIXED" "{{adr_id}}" "mixed detail must echo the {{adr_id}} placeholder"
assert_not_contains "$DETAIL_MIXED" "good.md" "mixed detail must NOT name good.md"
assert_contains "$DETAIL_MIXED" "1 doc" "mixed detail must report count=1"
rm -rf "$MIXED_TMP"

# (6) Pattern discipline: a doc with {{UPPER}} or {{ spaced }} variants must
#     NOT be flagged — the check is intentionally restricted to lowercase +
#     underscores so it doesn't mis-fire on legitimate {{TOC}} markers or
#     Jinja-style "{{ x }}" with spaces (out-of-scope here).
NOMATCH_TMP=$(mktemp -d)
mkdir -p "$NOMATCH_TMP/docs"
{
  printf '# Out-of-scope variants\n\n'
  printf 'Uppercase: {{TOC}} should not match.\n'
  printf 'Spaced: {{ project_name }} should not match.\n'
  printf 'Mixed-case: {{ProjectName}} should not match.\n'
  printf 'Digits-only: {{123}} should not match.\n'
} > "$NOMATCH_TMP/docs/edge.md"
RESULT_NOMATCH=$(bash "$CHECK" "$NOMATCH_TMP")
PASSED_NOMATCH=$(echo "$RESULT_NOMATCH" | jq -r .passed)
assert_eq "$PASSED_NOMATCH" "true" "out-of-scope variants must NOT trigger the check"
SEVERITY_NOMATCH=$(echo "$RESULT_NOMATCH" | jq -r .severity)
assert_eq "$SEVERITY_NOMATCH" "BLOCKER" "out-of-scope-variants severity must be BLOCKER pass"
rm -rf "$NOMATCH_TMP"

# (7) Nested subdirs: ensure recursive scan picks up docs/sub/a.md too.
NESTED_TMP=$(mktemp -d)
mkdir -p "$NESTED_TMP/docs/sub"
printf '# Nested\n\n{{deeply_nested}}\n' > "$NESTED_TMP/docs/sub/a.md"
RESULT_NESTED=$(bash "$CHECK" "$NESTED_TMP")
PASSED_NESTED=$(echo "$RESULT_NESTED" | jq -r .passed)
assert_eq "$PASSED_NESTED" "false" "nested-subdir fixture must FAIL"
DETAIL_NESTED=$(echo "$RESULT_NESTED" | jq -r .detail)
assert_contains "$DETAIL_NESTED" "docs/sub/a.md" "nested detail must name docs/sub/a.md"
assert_contains "$DETAIL_NESTED" "{{deeply_nested}}" "nested detail must echo the placeholder"
rm -rf "$NESTED_TMP"

# (8) JSON-validity loop: every emitted finding must be valid JSON.
for r in "$RESULT_NODOCS" "$RESULT_NOMD" "$RESULT_ALLOK" "$RESULT_BAD" \
         "$RESULT_MIXED" "$RESULT_NOMATCH" "$RESULT_NESTED"; do
  if echo "$r" | jq -e . >/dev/null 2>&1; then
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    FAIL_MESSAGES+=("FAIL: check output not valid JSON: $r")
  fi
done

test_summary
