#!/usr/bin/env bash
source "$(dirname "$0")/lib/test_helpers.sh"

AGENT="$REPO_ROOT/agents/quality-gate-auditor.md"
RUN_ALL="$REPO_ROOT/agents/quality-gate-auditor/run_all.sh"
CHECKS_DIR="$REPO_ROOT/agents/quality-gate-auditor/checks"

assert_file_exists "$AGENT" "auditor agent file must exist"
assert_file_exists "$RUN_ALL" "auditor run_all.sh must exist"
assert_dir_exists "$CHECKS_DIR" "checks/ directory must exist"

# Agent file must have correct frontmatter
CONTENT=$(cat "$AGENT")
assert_contains "$CONTENT" 'name: quality-gate-auditor' 'agent must declare correct name'
assert_contains "$CONTENT" 'model: opus' 'agent must use opus model'
assert_contains "$CONTENT" 'tools: [Read, Bash, Grep, Glob]' 'agent must be read-only (no Edit/Write)'

# run_all.sh must be executable
assert_executable "$RUN_ALL" "run_all.sh must be executable"

test_summary
