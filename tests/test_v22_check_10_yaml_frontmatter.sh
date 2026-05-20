#!/usr/bin/env bash
# Author: Alexander Ford <alex@alexfordlabs.com>
# License: MIT
# Project: project-architect (https://github.com/alexfordlabs/project-architect)
# Tests for check_10_yaml_frontmatter.py (Sketch B, check ID B10, BLOCKER).
#
# This is the FIRST Python check in the suite. It validates that every
# docs/**/*.md file with leading `---`-bounded YAML frontmatter parses
# via yaml.safe_load. A parse failure is a BLOCKER (downstream consumers
# such as catalog discovery, ADR indexing, and claude-md-author template
# substitution rely on the frontmatter being well-formed).
#
# Truth-table covered here:
#   - no docs/ dir         -> INFO    pass
#   - no .md files         -> INFO    pass
#   - no frontmatter at all-> BLOCKER pass "0 frontmatter blocks found"
#   - all valid frontmatter-> BLOCKER pass "all N frontmatter block(s) valid"
#   - some invalid         -> BLOCKER fail "<count> file(s) have invalid frontmatter: ..."
#
# Graceful skip:
#   - If PyYAML is unavailable on the test host, the check emits an INFO
#     pass and exits 0. The test detects this case and SKIPs the rest
#     rather than reporting bogus failures on hosts without PyYAML.

source "$(dirname "$0")/lib/test_helpers.sh"

CHECK="$REPO_ROOT/agents/quality-gate-auditor/checks/check_10_yaml_frontmatter.py"
assert_file_exists "$CHECK" "check_10 must exist"
assert_executable "$CHECK" "check_10 must be executable"

# jq is required to introspect the JSON envelope every check emits.
if ! command -v jq >/dev/null 2>&1; then
  echo "SKIP: jq not installed; cannot test check_10 fully"
  test_summary
  exit 0
fi

# Graceful skip if PyYAML missing — the check itself degrades to an INFO pass,
# which means we can't meaningfully test the BLOCKER fail/pass paths. Stop
# here rather than asserting against the degraded output.
if ! python3 -c 'import yaml' 2>/dev/null; then
  echo "SKIP: PyYAML not installed; cannot fully test check_10"
  # Still verify the check degrades correctly to an INFO pass.
  RESULT_NOLIB=$(python3 "$CHECK" "$REPO_ROOT/tests/fixtures/clean-bundle")
  PASSED_NOLIB=$(echo "$RESULT_NOLIB" | jq -r .passed)
  SEV_NOLIB=$(echo "$RESULT_NOLIB" | jq -r .severity)
  assert_eq "$PASSED_NOLIB" "true" "PyYAML-missing path must pass"
  assert_eq "$SEV_NOLIB" "INFO" "PyYAML-missing path must be INFO (graceful skip)"
  test_summary
  exit 0
fi

# (1) bad-yaml-frontmatter fixture: docs/A.md has a malformed mapping
#     (key2 indented by 1 space, key1 by 2) -> BLOCKER fail listing A.md.
RESULT_BAD=$(python3 "$CHECK" "$REPO_ROOT/tests/fixtures/bad-yaml-frontmatter")
PASSED_BAD=$(echo "$RESULT_BAD" | jq -r .passed)
SEVERITY_BAD=$(echo "$RESULT_BAD" | jq -r .severity)
ID_BAD=$(echo "$RESULT_BAD" | jq -r .id)
CHECK_NAME_BAD=$(echo "$RESULT_BAD" | jq -r .check)
DETAIL_BAD=$(echo "$RESULT_BAD" | jq -r .detail)
REMEDIATION_BAD=$(echo "$RESULT_BAD" | jq -r .remediation)
AUTOFIX_BAD=$(echo "$RESULT_BAD" | jq -r .auto_fixable)
assert_eq "$PASSED_BAD" "false" "bad-yaml-frontmatter must FAIL"
assert_eq "$SEVERITY_BAD" "BLOCKER" "bad-yaml-frontmatter severity must be BLOCKER"
assert_eq "$ID_BAD" "B10" "bad-yaml-frontmatter id must be B10"
assert_eq "$CHECK_NAME_BAD" "yaml_frontmatter" "bad-yaml-frontmatter check name must be yaml_frontmatter"
assert_contains "$DETAIL_BAD" "A.md" "bad detail must name A.md"
assert_contains "$DETAIL_BAD" "invalid frontmatter" "bad detail must label the failure mode"
assert_contains "$REMEDIATION_BAD" "YAML" "remediation must mention YAML"
assert_eq "$AUTOFIX_BAD" "false" "bad-yaml-frontmatter must be auto_fixable=false (humans must triage YAML errors)"

# (2) clean-bundle fixture: has docs/A.md and docs/B.md but NO frontmatter
#     -> BLOCKER pass "0 frontmatter blocks found".
RESULT_CLEAN=$(python3 "$CHECK" "$REPO_ROOT/tests/fixtures/clean-bundle")
PASSED_CLEAN=$(echo "$RESULT_CLEAN" | jq -r .passed)
SEVERITY_CLEAN=$(echo "$RESULT_CLEAN" | jq -r .severity)
DETAIL_CLEAN=$(echo "$RESULT_CLEAN" | jq -r .detail)
assert_eq "$PASSED_CLEAN" "true" "clean-bundle (no frontmatter) must PASS"
assert_eq "$SEVERITY_CLEAN" "BLOCKER" "clean-bundle severity must be BLOCKER (positive verdict)"
assert_contains "$DETAIL_CLEAN" "0 frontmatter blocks found" "clean-bundle detail must report empty corpus"

# (3) Healthy frontmatter: temp project with one .md whose frontmatter parses
#     -> BLOCKER pass "all 1 frontmatter block(s) valid".
HEALTHY_TMP=$(mktemp -d)
mkdir -p "$HEALTHY_TMP/docs"
cat > "$HEALTHY_TMP/docs/A.md" <<'EOF_FIX'
---
title: Good
status: accepted
date: 2026-05-13
tags:
  - architecture
  - decision
---

# Body

Valid frontmatter — yaml.safe_load returns a mapping.
EOF_FIX
RESULT_HEALTHY=$(python3 "$CHECK" "$HEALTHY_TMP")
PASSED_HEALTHY=$(echo "$RESULT_HEALTHY" | jq -r .passed)
SEVERITY_HEALTHY=$(echo "$RESULT_HEALTHY" | jq -r .severity)
DETAIL_HEALTHY=$(echo "$RESULT_HEALTHY" | jq -r .detail)
assert_eq "$PASSED_HEALTHY" "true" "healthy frontmatter must PASS"
assert_eq "$SEVERITY_HEALTHY" "BLOCKER" "healthy frontmatter severity must be BLOCKER (positive verdict)"
assert_contains "$DETAIL_HEALTHY" "all 1 frontmatter block" "healthy detail must report count=1"
rm -rf "$HEALTHY_TMP"

# (4) No docs/ directory -> INFO pass.
NODOCS_TMP=$(mktemp -d)
RESULT_NODOCS=$(python3 "$CHECK" "$NODOCS_TMP")
PASSED_NODOCS=$(echo "$RESULT_NODOCS" | jq -r .passed)
SEV_NODOCS=$(echo "$RESULT_NODOCS" | jq -r .severity)
DETAIL_NODOCS=$(echo "$RESULT_NODOCS" | jq -r .detail)
assert_eq "$PASSED_NODOCS" "true" "no docs/ must pass"
assert_eq "$SEV_NODOCS" "INFO" "no docs/ must be INFO"
assert_contains "$DETAIL_NODOCS" "no docs/" "no-docs detail must mention 'no docs/'"
rm -rf "$NODOCS_TMP"

# (5) docs/ exists but no .md files -> INFO pass.
NOMD_TMP=$(mktemp -d)
mkdir -p "$NOMD_TMP/docs"
RESULT_NOMD=$(python3 "$CHECK" "$NOMD_TMP")
PASSED_NOMD=$(echo "$RESULT_NOMD" | jq -r .passed)
SEV_NOMD=$(echo "$RESULT_NOMD" | jq -r .severity)
DETAIL_NOMD=$(echo "$RESULT_NOMD" | jq -r .detail)
assert_eq "$PASSED_NOMD" "true" "docs/ without .md must pass"
assert_eq "$SEV_NOMD" "INFO" "docs/ without .md must be INFO"
assert_contains "$DETAIL_NOMD" "no markdown files" "no-md detail must mention 'no markdown files'"
rm -rf "$NOMD_TMP"

# (6) Mixed: two .md files — one valid frontmatter, one without frontmatter
#     -> should report exactly 1 valid block. Files without frontmatter are
#     simply skipped (they don't claim to have one, so they're not in scope).
MIXED_TMP=$(mktemp -d)
mkdir -p "$MIXED_TMP/docs"
cat > "$MIXED_TMP/docs/with.md" <<'EOF_MIX'
---
title: Has frontmatter
---
# Body
EOF_MIX
printf '# No frontmatter here\n\nJust prose.\n' > "$MIXED_TMP/docs/without.md"
RESULT_MIXED=$(python3 "$CHECK" "$MIXED_TMP")
PASSED_MIXED=$(echo "$RESULT_MIXED" | jq -r .passed)
DETAIL_MIXED=$(echo "$RESULT_MIXED" | jq -r .detail)
assert_eq "$PASSED_MIXED" "true" "mixed (1 with FM, 1 without) must PASS"
assert_contains "$DETAIL_MIXED" "all 1 frontmatter block" "mixed detail must report count=1 (only with.md counted)"
rm -rf "$MIXED_TMP"

# (7) Nested subdirs: ensure recursive scan picks up docs/sub/a.md frontmatter.
NESTED_TMP=$(mktemp -d)
mkdir -p "$NESTED_TMP/docs/sub"
cat > "$NESTED_TMP/docs/sub/a.md" <<'EOF_NEST'
---
title: Nested
bad_indent:
  key1: value
 key2: oops
---
# Body
EOF_NEST
RESULT_NESTED=$(python3 "$CHECK" "$NESTED_TMP")
PASSED_NESTED=$(echo "$RESULT_NESTED" | jq -r .passed)
DETAIL_NESTED=$(echo "$RESULT_NESTED" | jq -r .detail)
assert_eq "$PASSED_NESTED" "false" "nested-subdir bad frontmatter must FAIL"
assert_contains "$DETAIL_NESTED" "sub/a.md" "nested detail must name docs/sub/a.md"
rm -rf "$NESTED_TMP"

# (8) JSON-validity loop: every emitted finding must be valid JSON.
for r in "$RESULT_BAD" "$RESULT_CLEAN" "$RESULT_HEALTHY" \
         "$RESULT_NODOCS" "$RESULT_NOMD" "$RESULT_MIXED" "$RESULT_NESTED"; do
  if echo "$r" | jq -e . >/dev/null 2>&1; then
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    FAIL_MESSAGES+=("FAIL: check output not valid JSON: $r")
  fi
done

test_summary
