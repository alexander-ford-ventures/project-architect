#!/usr/bin/env bash
# Author: Vladimir Dukelic <vladimir@dukelic.com>
# License: MIT
# Project: project-architect (https://github.com/siliconyouth/project-architect)
# Tests for check_13_state_drift.sh (Sketch B, check ID B13, WARNING).
#
# Catches state-drift: someone committed code but did NOT refresh
# state.last_updated_at. The check compares state.last_updated_at to the
# unix epoch of the HEAD commit (git log -1 --format=%ct). If HEAD is more
# than 60 seconds ahead of state.last_updated_at, drift is reported.
#
# Truth-table covered here:
#   - non-git directory                                   -> INFO    pass "not a git repository"
#   - drift fixture (state lags HEAD by 1 year)           -> WARNING fail naming the lag
#   - fresh state (last_updated_at == HEAD time)          -> WARNING pass within 60s
#   - no state.json                                       -> INFO    pass (deferred to json_valid)
#   - state.last_updated_at missing                       -> INFO    pass (early phase)

source "$(dirname "$0")/lib/test_helpers.sh"

CHECK="$REPO_ROOT/agents/quality-gate-auditor/checks/check_13_state_drift.sh"
assert_file_exists "$CHECK" "check_13 must exist"
assert_executable "$CHECK" "check_13 must be executable"

# Skip remaining functional checks gracefully if jq isn't installed.
if ! command -v jq >/dev/null 2>&1; then
  echo "SKIP: jq not installed; cannot test check_13 fully"
  test_summary
  exit 0
fi

# Skip if git missing (extremely unlikely on dev hosts but guard anyway).
if ! command -v git >/dev/null 2>&1; then
  echo "SKIP: git not installed; cannot test check_13"
  test_summary
  exit 0
fi

# (1) Non-git directory: random tempdir without .git. Expected INFO pass.
NONGIT_TMP=$(mktemp -d)
RESULT_NONGIT=$(bash "$CHECK" "$NONGIT_TMP")
PASSED_NONGIT=$(echo "$RESULT_NONGIT" | jq -r .passed)
SEVERITY_NONGIT=$(echo "$RESULT_NONGIT" | jq -r .severity)
ID_NONGIT=$(echo "$RESULT_NONGIT" | jq -r .id)
CHECK_NAME_NONGIT=$(echo "$RESULT_NONGIT" | jq -r .check)
DETAIL_NONGIT=$(echo "$RESULT_NONGIT" | jq -r .detail)
assert_eq "$PASSED_NONGIT" "true" "non-git dir must PASS"
assert_eq "$SEVERITY_NONGIT" "INFO" "non-git dir must be INFO"
assert_eq "$ID_NONGIT" "B13" "id must be B13"
assert_eq "$CHECK_NAME_NONGIT" "state_drift" "check name must be state_drift"
assert_contains "$DETAIL_NONGIT" "not a git" "non-git detail must say 'not a git'"
rm -rf "$NONGIT_TMP"

# (2) Drift fixture: create a git repo, copy the fixture, commit, then run.
#     state.last_updated_at is 2024-01-01 — guaranteed to lag any modern HEAD.
DRIFT_TMP=$(mktemp -d)
(
  cd "$DRIFT_TMP" || exit 1
  git init -q
  git -c user.email=t@t -c user.name=t commit --allow-empty -q -m "init"
  mkdir -p docs
  cp "$REPO_ROOT/tests/fixtures/state-drift/docs/_architect_state.json" docs/
  git add docs
  git -c user.email=t@t -c user.name=t commit -q -m "add stale state"
)
RESULT_DRIFT=$(bash "$CHECK" "$DRIFT_TMP")
PASSED_DRIFT=$(echo "$RESULT_DRIFT" | jq -r .passed)
SEVERITY_DRIFT=$(echo "$RESULT_DRIFT" | jq -r .severity)
DETAIL_DRIFT=$(echo "$RESULT_DRIFT" | jq -r .detail)
REMEDIATION_DRIFT=$(echo "$RESULT_DRIFT" | jq -r .remediation)
AUTOFIX_DRIFT=$(echo "$RESULT_DRIFT" | jq -r .auto_fixable)
assert_eq "$PASSED_DRIFT" "false" "state-drift fixture must FAIL"
assert_eq "$SEVERITY_DRIFT" "WARNING" "drift severity must be WARNING"
assert_contains "$DETAIL_DRIFT" "lags" "detail must mention drift ('lags')"
assert_contains "$REMEDIATION_DRIFT" "last_updated_at" "remediation must mention last_updated_at"
assert_eq "$AUTOFIX_DRIFT" "true" "drift must be auto_fixable (mechanical rewrite)"
rm -rf "$DRIFT_TMP"

# (3) Fresh state: last_updated_at == HEAD commit time. Expected WARNING pass.
HEALTHY_TMP=$(mktemp -d)
(
  cd "$HEALTHY_TMP" || exit 1
  git init -q
  mkdir -p docs
  NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  printf '{"last_updated_at":"%s"}\n' "$NOW" > docs/_architect_state.json
  git add docs
  git -c user.email=t@t -c user.name=t commit -q -m "fresh state"
)
RESULT_HEALTHY=$(bash "$CHECK" "$HEALTHY_TMP")
PASSED_HEALTHY=$(echo "$RESULT_HEALTHY" | jq -r .passed)
SEVERITY_HEALTHY=$(echo "$RESULT_HEALTHY" | jq -r .severity)
assert_eq "$PASSED_HEALTHY" "true" "fresh state (within 60s) must PASS"
assert_eq "$SEVERITY_HEALTHY" "WARNING" "healthy severity must be WARNING (check ran)"
rm -rf "$HEALTHY_TMP"

# (4) No state.json: git repo present but no docs/_architect_state.json.
#     Expected INFO pass (deferred to json_valid).
NOSTATE_TMP=$(mktemp -d)
(
  cd "$NOSTATE_TMP" || exit 1
  git init -q
  git -c user.email=t@t -c user.name=t commit --allow-empty -q -m "init"
)
RESULT_NOSTATE=$(bash "$CHECK" "$NOSTATE_TMP")
PASSED_NOSTATE=$(echo "$RESULT_NOSTATE" | jq -r .passed)
SEVERITY_NOSTATE=$(echo "$RESULT_NOSTATE" | jq -r .severity)
DETAIL_NOSTATE=$(echo "$RESULT_NOSTATE" | jq -r .detail)
assert_eq "$PASSED_NOSTATE" "true" "no state.json must PASS"
assert_eq "$SEVERITY_NOSTATE" "INFO" "no state.json must be INFO"
assert_contains "$DETAIL_NOSTATE" "deferred" "no-state detail must mention deferral"
rm -rf "$NOSTATE_TMP"

# (5) state.last_updated_at absent: state.json present but no last_updated_at
#     key (e.g. early phase 0a). Expected INFO pass.
NOTSAVED_TMP=$(mktemp -d)
(
  cd "$NOTSAVED_TMP" || exit 1
  git init -q
  mkdir -p docs
  printf '{"phase":"phase_0"}\n' > docs/_architect_state.json
  git add docs
  git -c user.email=t@t -c user.name=t commit -q -m "init early phase"
)
RESULT_NOTSAVED=$(bash "$CHECK" "$NOTSAVED_TMP")
PASSED_NOTSAVED=$(echo "$RESULT_NOTSAVED" | jq -r .passed)
SEVERITY_NOTSAVED=$(echo "$RESULT_NOTSAVED" | jq -r .severity)
DETAIL_NOTSAVED=$(echo "$RESULT_NOTSAVED" | jq -r .detail)
assert_eq "$PASSED_NOTSAVED" "true" "missing last_updated_at must PASS"
assert_eq "$SEVERITY_NOTSAVED" "INFO" "missing last_updated_at must be INFO"
assert_contains "$DETAIL_NOTSAVED" "last_updated_at" "detail must mention last_updated_at"
rm -rf "$NOTSAVED_TMP"

# (6) Malformed state.json: INFO pass (deferred to json_valid).
MALFORMED_TMP=$(mktemp -d)
(
  cd "$MALFORMED_TMP" || exit 1
  git init -q
  mkdir -p docs
  printf '{this is not json\n' > docs/_architect_state.json
  git add docs
  git -c user.email=t@t -c user.name=t commit -q -m "broken state"
)
RESULT_MALFORMED=$(bash "$CHECK" "$MALFORMED_TMP")
PASSED_MALFORMED=$(echo "$RESULT_MALFORMED" | jq -r .passed)
SEVERITY_MALFORMED=$(echo "$RESULT_MALFORMED" | jq -r .severity)
assert_eq "$PASSED_MALFORMED" "true" "malformed state.json must PASS (deferred)"
assert_eq "$SEVERITY_MALFORMED" "INFO" "malformed-state severity must be INFO"
rm -rf "$MALFORMED_TMP"

# (7) Unparseable last_updated_at (string, but not ISO8601). Expected INFO
#     pass (deferred to iso8601_timestamps).
UNPARSE_TMP=$(mktemp -d)
(
  cd "$UNPARSE_TMP" || exit 1
  git init -q
  mkdir -p docs
  printf '{"last_updated_at":"not-a-date"}\n' > docs/_architect_state.json
  git add docs
  git -c user.email=t@t -c user.name=t commit -q -m "bad timestamp"
)
RESULT_UNPARSE=$(bash "$CHECK" "$UNPARSE_TMP")
PASSED_UNPARSE=$(echo "$RESULT_UNPARSE" | jq -r .passed)
SEVERITY_UNPARSE=$(echo "$RESULT_UNPARSE" | jq -r .severity)
DETAIL_UNPARSE=$(echo "$RESULT_UNPARSE" | jq -r .detail)
assert_eq "$PASSED_UNPARSE" "true" "unparseable last_updated_at must PASS (deferred)"
assert_eq "$SEVERITY_UNPARSE" "INFO" "unparseable severity must be INFO"
assert_contains "$DETAIL_UNPARSE" "iso8601_timestamps" "unparseable detail must mention iso8601_timestamps deferral"
rm -rf "$UNPARSE_TMP"

# (8) JSON-validity loop: every emitted finding must itself be valid JSON.
for r in "$RESULT_NONGIT" "$RESULT_DRIFT" "$RESULT_HEALTHY" "$RESULT_NOSTATE" \
         "$RESULT_NOTSAVED" "$RESULT_MALFORMED" "$RESULT_UNPARSE"; do
  if echo "$r" | jq -e . >/dev/null 2>&1; then
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    FAIL_MESSAGES+=("FAIL: check output not valid JSON: $r")
  fi
done

test_summary
