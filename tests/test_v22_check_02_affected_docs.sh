#!/usr/bin/env bash
# Author: Alexander Ford <alex@alexfordlabs.com>
# License: MIT
# Project: project-architect (https://github.com/alexfordlabs/project-architect)
source "$(dirname "$0")/lib/test_helpers.sh"

CHECK="$REPO_ROOT/agents/quality-gate-auditor/checks/check_02_affected_docs.sh"
assert_file_exists "$CHECK" "check_02 must exist"

# Clean fixture (clean-bundle from Task 11 has no ADRs — must pass trivially)
RESULT_CLEAN=$(bash "$CHECK" "$REPO_ROOT/tests/fixtures/clean-bundle" "$REPO_ROOT/tests/fixtures/clean-bundle/docs/_architect_state.json")
PASSED_CLEAN=$(echo "$RESULT_CLEAN" | jq -r .passed)
assert_eq "$PASSED_CLEAN" "true" "clean (no ADRs) fixture must pass"

# Missing-doc fixture: must FAIL with the missing doc + ADR id named
RESULT_MISSING=$(bash "$CHECK" "$REPO_ROOT/tests/fixtures/missing-affected-doc" "$REPO_ROOT/tests/fixtures/missing-affected-doc/docs/_architect_state.json")
PASSED_MISSING=$(echo "$RESULT_MISSING" | jq -r .passed)
assert_eq "$PASSED_MISSING" "false" "missing-affected-doc must fail"
DETAIL=$(echo "$RESULT_MISSING" | jq -r .detail)
assert_contains "$DETAIL" "MISSING.md" "detail must name MISSING.md"
assert_contains "$DETAIL" "0001" "detail must name the originating ADR"
SEVERITY=$(echo "$RESULT_MISSING" | jq -r .severity)
assert_eq "$SEVERITY" "BLOCKER" "missing affected_docs must be BLOCKER"

# JSON validity for both paths
for r in "$RESULT_CLEAN" "$RESULT_MISSING"; do
  if echo "$r" | jq -e . >/dev/null 2>&1; then
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    FAIL_MESSAGES+=("FAIL: check output not valid JSON: $r")
  fi
done

# Deferred-doc edge case: a missing doc that IS in state.deferred_docs must NOT be flagged
DEFERRED_TMP=$(mktemp -d)
mkdir -p "$DEFERRED_TMP/docs/decisions"
cat > "$DEFERRED_TMP/docs/decisions/0002-deferred.md" <<'EOF'
---
adr_id: "0002"
title: Deferred ADR
---
EOF
cat > "$DEFERRED_TMP/docs/_architect_state.json" <<'EOF'
{
  "phase": "phase_5",
  "adrs_filed": [
    { "id": "0002", "affected_docs": ["DEFERRED_ON_PURPOSE.md"] }
  ],
  "documents_generated": [],
  "deferred_docs": ["DEFERRED_ON_PURPOSE.md"]
}
EOF
RESULT_DEFERRED=$(bash "$CHECK" "$DEFERRED_TMP" "$DEFERRED_TMP/docs/_architect_state.json")
PASSED_DEFERRED=$(echo "$RESULT_DEFERRED" | jq -r .passed)
assert_eq "$PASSED_DEFERRED" "true" "deferred docs must be treated as resolved"
rm -rf "$DEFERRED_TMP"

# No state.json edge case: must NOT crash, should emit INFO/skip
NOSTATE_TMP=$(mktemp -d)
RESULT_NOSTATE=$(bash "$CHECK" "$NOSTATE_TMP" "$NOSTATE_TMP/missing-state.json")
PASSED_NOSTATE=$(echo "$RESULT_NOSTATE" | jq -r .passed)
assert_eq "$PASSED_NOSTATE" "true" "no state.json must pass (nothing to verify)"
rm -rf "$NOSTATE_TMP"

# Malformed JSON edge case: must NOT silently pass with positive claim
BADJSON_TMP=$(mktemp -d)
mkdir -p "$BADJSON_TMP/docs"
echo '{"truncated":' > "$BADJSON_TMP/docs/_architect_state.json"  # invalid JSON
RESULT_BADJSON=$(bash "$CHECK" "$BADJSON_TMP" "$BADJSON_TMP/docs/_architect_state.json")
PASSED_BADJSON=$(echo "$RESULT_BADJSON" | jq -r .passed)
SEVERITY_BADJSON=$(echo "$RESULT_BADJSON" | jq -r .severity)
DETAIL_BADJSON=$(echo "$RESULT_BADJSON" | jq -r .detail)
# Must pass with INFO severity AND detail must mention "unparseable" or "deferred"
assert_eq "$PASSED_BADJSON" "true" "malformed JSON must pass with INFO (defer to json_valid)"
assert_eq "$SEVERITY_BADJSON" "INFO" "malformed JSON must be INFO severity"
[[ "$DETAIL_BADJSON" == *unparseable* || "$DETAIL_BADJSON" == *deferred* ]] && PASS_COUNT=$((PASS_COUNT+1)) || { FAIL_COUNT=$((FAIL_COUNT+1)); FAIL_MESSAGES+=("FAIL: detail must mention unparseable/deferred"); }
rm -rf "$BADJSON_TMP"

test_summary
