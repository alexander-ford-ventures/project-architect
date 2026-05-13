#!/usr/bin/env bash
source "$(dirname "$0")/lib/test_helpers.sh"

for agent in research-scout document-author decision-revisor claude-md-author claude-tooling-author quality-gate-auditor; do
  CONTENT=$(cat "$REPO_ROOT/agents/${agent}.md")
  assert_contains "$CONTENT" '## Runtime budget' "$agent must have ## Runtime budget section"
  assert_contains "$CONTENT" 'progress message' "$agent must instruct to surface progress messages"
  assert_contains "$CONTENT" 'PARTIAL_COMPLETION' "$agent must define PARTIAL_COMPLETION report shape"
  assert_contains "$CONTENT" 'Scope discipline' "$agent must have scope discipline subsection"
done

test_summary
