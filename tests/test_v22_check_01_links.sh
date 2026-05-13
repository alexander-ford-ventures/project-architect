#!/usr/bin/env bash
source "$(dirname "$0")/lib/test_helpers.sh"

CHECK="$REPO_ROOT/agents/quality-gate-auditor/checks/check_01_links.sh"
assert_file_exists "$CHECK" "check_01_links.sh must exist"

# Clean fixture: passed=true
RESULT_CLEAN=$(bash "$CHECK" "$REPO_ROOT/tests/fixtures/clean-bundle" "$REPO_ROOT/tests/fixtures/clean-bundle/docs/_architect_state.json")
PASSED_CLEAN=$(echo "$RESULT_CLEAN" | jq -r .passed)
assert_eq "$PASSED_CLEAN" "true" "clean fixture must pass"

# Broken fixture: passed=false
RESULT_BROKEN=$(bash "$CHECK" "$REPO_ROOT/tests/fixtures/broken-link" "$REPO_ROOT/tests/fixtures/broken-link/docs/_architect_state.json")
PASSED_BROKEN=$(echo "$RESULT_BROKEN" | jq -r .passed)
assert_eq "$PASSED_BROKEN" "false" "broken-link fixture must fail"
SEVERITY_BROKEN=$(echo "$RESULT_BROKEN" | jq -r .severity)
assert_eq "$SEVERITY_BROKEN" "BLOCKER" "broken link must be a BLOCKER"
DETAIL_BROKEN=$(echo "$RESULT_BROKEN" | jq -r .detail)
assert_contains "$DETAIL_BROKEN" "does-not-exist.md" "detail must name the broken link target"

# Verify detail has no trailing newline (regression: was '\n' from here-string
# pattern jq -Rs . <<<"$DETAIL", which appended '\n' to the JSON-encoded string).
# Check the raw JSON output for an escaped \n in the detail field — we extract
# the detail substring with jq's .detail | @json so we see the encoded form.
DETAIL_ENCODED=$(echo "$RESULT_BROKEN" | jq -r '.detail | @json')
assert_not_contains "$DETAIL_ENCODED" "\\n\"" "detail must not end with an escaped newline"

# No-docs branch: run against a directory with no docs/ subdir
NO_DOCS_TMP=$(mktemp -d)
RESULT_NODOCS=$(bash "$CHECK" "$NO_DOCS_TMP" "$NO_DOCS_TMP/state.json")
PASSED_NODOCS=$(echo "$RESULT_NODOCS" | jq -r .passed)
SEVERITY_NODOCS=$(echo "$RESULT_NODOCS" | jq -r .severity)
assert_eq "$PASSED_NODOCS" "true" "no-docs branch must pass"
assert_eq "$SEVERITY_NODOCS" "INFO" "no-docs branch must be INFO severity"
rm -rf "$NO_DOCS_TMP"

# URL + absolute-path skip: doc with https:// and /etc/passwd targets must NOT be flagged broken
URL_TMP=$(mktemp -d)
mkdir -p "$URL_TMP/docs"
cat > "$URL_TMP/docs/A.md" <<'EOF_FIXTURE'
# A
[GH](https://github.com) [abs](/etc/passwd) [email](mailto:a@b.c) [proto](//cdn.example.com/x.js)
EOF_FIXTURE
RESULT_URLS=$(bash "$CHECK" "$URL_TMP" "$URL_TMP/docs/state.json")
PASSED_URLS=$(echo "$RESULT_URLS" | jq -r .passed)
assert_eq "$PASSED_URLS" "true" "URLs and absolute paths must be skipped"
rm -rf "$URL_TMP"

# Aggregate output validity: each result must be valid JSON
for r in "$RESULT_CLEAN" "$RESULT_BROKEN" "$RESULT_NODOCS" "$RESULT_URLS"; do
  if echo "$r" | jq -e . >/dev/null 2>&1; then
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    FAIL_MESSAGES+=("FAIL: check output is not valid JSON: $r")
  fi
done

test_summary
