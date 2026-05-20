#!/usr/bin/env bash
# Author: Alexander Ford <alex@alexfordlabs.com>
# License: MIT
# Project: project-architect (https://github.com/alexfordlabs/project-architect)
source "$(dirname "$0")/lib/test_helpers.sh"

declare -A EXPECTED_TYPICAL=( [research-scout]=5 [document-author]=3 [decision-revisor]=5 [claude-md-author]=3 [claude-tooling-author]=10 [quality-gate-auditor]=5 )
declare -A EXPECTED_MAX=( [research-scout]=15 [document-author]=10 [decision-revisor]=12 [claude-md-author]=8 [claude-tooling-author]=20 [quality-gate-auditor]=12 )

for agent in research-scout document-author decision-revisor claude-md-author claude-tooling-author quality-gate-auditor; do
  AGENT_FILE="$REPO_ROOT/agents/${agent}.md"
  assert_file_exists "$AGENT_FILE" "$agent agent file must exist"
  CONTENT=$(cat "$AGENT_FILE")
  assert_contains "$CONTENT" 'runtime_budget:' "$agent must have runtime_budget frontmatter"
  assert_contains "$CONTENT" "typical_minutes: ${EXPECTED_TYPICAL[$agent]}" "$agent must have typical_minutes=${EXPECTED_TYPICAL[$agent]}"
  assert_contains "$CONTENT" "max_minutes: ${EXPECTED_MAX[$agent]}" "$agent must have max_minutes=${EXPECTED_MAX[$agent]}"
done

test_summary
