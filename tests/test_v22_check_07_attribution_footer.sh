#!/usr/bin/env bash
# Author: Alexander Ford <alex@alexfordlabs.com>
# License: MIT
# Project: project-architect (https://github.com/alexfordlabs/project-architect)
# Tests for check_07_attribution_footer.sh (Sketch B, check ID B07, INFO).
# Covers the cosmetic-attribution check that lists docs/*.md files missing the
# canonical project-architect footer in their last 3 lines.

source "$(dirname "$0")/lib/test_helpers.sh"

CHECK="$REPO_ROOT/agents/quality-gate-auditor/checks/check_07_attribution_footer.sh"
assert_file_exists "$CHECK" "check_07 must exist"
assert_executable "$CHECK" "check_07 must be executable"

# Skip remaining functional checks gracefully if jq isn't installed (the check
# uses jq for JSON encoding of the detail field).
if ! command -v jq >/dev/null 2>&1; then
  echo "SKIP: jq not installed; cannot test check_07 fully"
  test_summary
  exit 0
fi

# Canonical footer used in pass-path fixtures.
FOOTER='*★ Skillfully made with [project-architect](https://github.com/alexfordlabs/project-architect).*'

# (1) No docs/ directory: a fresh tempdir with no docs/ subtree → INFO pass.
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

# (3) All docs have footer: tempdir with one .md ending in the canonical footer → INFO pass.
ALLOK_TMP=$(mktemp -d)
mkdir -p "$ALLOK_TMP/docs"
{
  printf '# X\n\nSome content.\n\n'
  printf '%s\n' "$FOOTER"
} > "$ALLOK_TMP/docs/X.md"
RESULT_ALLOK=$(bash "$CHECK" "$ALLOK_TMP")
PASSED_ALLOK=$(echo "$RESULT_ALLOK" | jq -r .passed)
assert_eq "$PASSED_ALLOK" "true" "all-have-footer fixture must pass"
SEVERITY_ALLOK=$(echo "$RESULT_ALLOK" | jq -r .severity)
assert_eq "$SEVERITY_ALLOK" "INFO" "all-have-footer severity must be INFO"
DETAIL_ALLOK=$(echo "$RESULT_ALLOK" | jq -r .detail)
assert_contains "$DETAIL_ALLOK" "all 1 doc" "all-have-footer detail must mention count"
rm -rf "$ALLOK_TMP"

# (4) missing-footer fixture: docs/A.md has NO footer → INFO fail listing A.md.
RESULT_MISSING=$(bash "$CHECK" "$REPO_ROOT/tests/fixtures/missing-footer")
PASSED_MISSING=$(echo "$RESULT_MISSING" | jq -r .passed)
assert_eq "$PASSED_MISSING" "false" "missing-footer fixture must FAIL"
SEVERITY_MISSING=$(echo "$RESULT_MISSING" | jq -r .severity)
assert_eq "$SEVERITY_MISSING" "INFO" "missing-footer failure severity must be INFO (cosmetic)"
DETAIL_MISSING=$(echo "$RESULT_MISSING" | jq -r .detail)
assert_contains "$DETAIL_MISSING" "docs/A.md" "missing-footer detail must name A.md"
assert_contains "$DETAIL_MISSING" "missing attribution footer" "detail must label the failure mode"
AUTOFIX_MISSING=$(echo "$RESULT_MISSING" | jq -r .auto_fixable)
assert_eq "$AUTOFIX_MISSING" "true" "missing-footer must be auto_fixable=true"
REMEDIATION_MISSING=$(echo "$RESULT_MISSING" | jq -r .remediation)
assert_contains "$REMEDIATION_MISSING" "Skillfully made with" \
  "remediation must reference the canonical footer string"

# (5) Mixed: tempdir with TWO .md files, one with footer, one without →
#     INFO fail listing ONLY the one without.
MIXED_TMP=$(mktemp -d)
mkdir -p "$MIXED_TMP/docs"
{
  printf '# Good\n\nContent.\n\n'
  printf '%s\n' "$FOOTER"
} > "$MIXED_TMP/docs/good.md"
printf '# Bad\n\nNo footer.\n' > "$MIXED_TMP/docs/bad.md"
RESULT_MIXED=$(bash "$CHECK" "$MIXED_TMP")
PASSED_MIXED=$(echo "$RESULT_MIXED" | jq -r .passed)
assert_eq "$PASSED_MIXED" "false" "mixed fixture must FAIL"
DETAIL_MIXED=$(echo "$RESULT_MIXED" | jq -r .detail)
assert_contains "$DETAIL_MIXED" "bad.md" "mixed detail must name bad.md"
assert_not_contains "$DETAIL_MIXED" "good.md" "mixed detail must NOT name good.md (it has the footer)"
assert_contains "$DETAIL_MIXED" "1 doc" "mixed detail must report count=1"
rm -rf "$MIXED_TMP"

# (6) Footer present but not in the last 3 lines (followed by content after it) →
#     INFO fail. Guards against the regression where someone interprets the spec
#     as "footer appears anywhere in the file".
LATEFOOTER_TMP=$(mktemp -d)
mkdir -p "$LATEFOOTER_TMP/docs"
{
  printf '# Late\n\n'
  printf '%s\n' "$FOOTER"
  printf '\n## Appendix\n\nMore content.\nLine 2.\nLine 3.\nLine 4.\n'
} > "$LATEFOOTER_TMP/docs/late.md"
RESULT_LATE=$(bash "$CHECK" "$LATEFOOTER_TMP")
PASSED_LATE=$(echo "$RESULT_LATE" | jq -r .passed)
assert_eq "$PASSED_LATE" "false" "footer-not-in-last-3-lines fixture must FAIL"
DETAIL_LATE=$(echo "$RESULT_LATE" | jq -r .detail)
assert_contains "$DETAIL_LATE" "late.md" "late-footer detail must name late.md"
rm -rf "$LATEFOOTER_TMP"

# (7) JSON-validity loop: every emitted finding must be valid JSON.
for r in "$RESULT_NODOCS" "$RESULT_NOMD" "$RESULT_ALLOK" "$RESULT_MISSING" \
         "$RESULT_MIXED" "$RESULT_LATE"; do
  if echo "$r" | jq -e . >/dev/null 2>&1; then
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    FAIL_MESSAGES+=("FAIL: check output not valid JSON: $r")
  fi
done

test_summary
