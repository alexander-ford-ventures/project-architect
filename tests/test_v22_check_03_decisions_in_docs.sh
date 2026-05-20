#!/usr/bin/env bash
# Author: Alexander Ford <alex@alexfordlabs.com>
# License: MIT
# Project: project-architect (https://github.com/alexfordlabs/project-architect)
source "$(dirname "$0")/lib/test_helpers.sh"

CHECK="$REPO_ROOT/agents/quality-gate-auditor/checks/check_03_decisions_in_docs.sh"
assert_file_exists "$CHECK" "check_03 must exist"

# Clean fixture (no decisions in state → trivial pass)
RESULT_CLEAN=$(bash "$CHECK" "$REPO_ROOT/tests/fixtures/clean-bundle" "$REPO_ROOT/tests/fixtures/clean-bundle/docs/_architect_state.json")
PASSED_CLEAN=$(echo "$RESULT_CLEAN" | jq -r .passed)
assert_eq "$PASSED_CLEAN" "true" "clean fixture (no decisions) must pass"

# Not-mentioned fixture: must FAIL with WARNING and name the undocumented decision(s)
RESULT_NOT_MENTIONED=$(bash "$CHECK" "$REPO_ROOT/tests/fixtures/decision-not-mentioned" "$REPO_ROOT/tests/fixtures/decision-not-mentioned/docs/_architect_state.json")
PASSED_NOT_MENTIONED=$(echo "$RESULT_NOT_MENTIONED" | jq -r .passed)
assert_eq "$PASSED_NOT_MENTIONED" "false" "not-mentioned fixture must fail"
SEVERITY=$(echo "$RESULT_NOT_MENTIONED" | jq -r .severity)
assert_eq "$SEVERITY" "WARNING" "must be WARNING severity"
DETAIL=$(echo "$RESULT_NOT_MENTIONED" | jq -r .detail)
# Detail should name at least one undocumented decision — either the key or the value
if [[ "$DETAIL" == *"rust"* || "$DETAIL" == *"language"* ]]; then
  PASS_COUNT=$((PASS_COUNT+1))
else
  FAIL_COUNT=$((FAIL_COUNT+1))
  FAIL_MESSAGES+=("FAIL: detail must mention rust or language")
fi

# Mentioned-in-doc edge case: if the doc mentions the value, must NOT flag
MENTIONED_TMP=$(mktemp -d)
mkdir -p "$MENTIONED_TMP/docs"
cat > "$MENTIONED_TMP/docs/OVERVIEW.md" <<'EOF_FIXTURE'
# Overview
We use rust as the language.
EOF_FIXTURE
cat > "$MENTIONED_TMP/docs/_architect_state.json" <<'EOF_STATE'
{
  "decisions": {
    "tech_stack": { "language": "rust" }
  }
}
EOF_STATE
RESULT_MENTIONED=$(bash "$CHECK" "$MENTIONED_TMP" "$MENTIONED_TMP/docs/_architect_state.json")
PASSED_MENTIONED=$(echo "$RESULT_MENTIONED" | jq -r .passed)
assert_eq "$PASSED_MENTIONED" "true" "mentioned-decision fixture must pass"
rm -rf "$MENTIONED_TMP"

# Metadata-only decisions are skipped (ADR id, alternatives_considered, status, date, etc.)
META_TMP=$(mktemp -d)
mkdir -p "$META_TMP/docs"
cat > "$META_TMP/docs/OVERVIEW.md" <<'EOF_FIXTURE'
# Overview
Nothing relevant here.
EOF_FIXTURE
cat > "$META_TMP/docs/_architect_state.json" <<'EOF_STATE'
{
  "decisions": {
    "tech_stack": {
      "adr": "0001",
      "status": "accepted",
      "date": "2026-05-13",
      "alternatives_considered": ["a", "b"]
    }
  }
}
EOF_STATE
RESULT_META=$(bash "$CHECK" "$META_TMP" "$META_TMP/docs/_architect_state.json")
PASSED_META=$(echo "$RESULT_META" | jq -r .passed)
assert_eq "$PASSED_META" "true" "metadata-only decisions must be skipped"
rm -rf "$META_TMP"

# No state.json edge case
NOSTATE_TMP=$(mktemp -d)
RESULT_NOSTATE=$(bash "$CHECK" "$NOSTATE_TMP" "$NOSTATE_TMP/missing.json")
PASSED_NOSTATE=$(echo "$RESULT_NOSTATE" | jq -r .passed)
assert_eq "$PASSED_NOSTATE" "true" "no state.json must pass (nothing to verify)"
SEV_NOSTATE=$(echo "$RESULT_NOSTATE" | jq -r .severity)
assert_eq "$SEV_NOSTATE" "INFO" "no-state must be INFO severity"
rm -rf "$NOSTATE_TMP"

# All check outputs must be valid JSON
for r in "$RESULT_CLEAN" "$RESULT_NOT_MENTIONED" "$RESULT_MENTIONED" "$RESULT_META" "$RESULT_NOSTATE"; do
  if echo "$r" | jq -e . >/dev/null 2>&1; then
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    FAIL_MESSAGES+=("FAIL: check output not valid JSON: $r")
  fi
done

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
