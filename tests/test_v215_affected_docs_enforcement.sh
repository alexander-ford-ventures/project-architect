#!/usr/bin/env bash
# Author: Alexander Ford <alex@alexfordlabs.com>
# License: MIT
# Project: project-architect (https://github.com/alexfordlabs/project-architect)

source "$(dirname "$0")/lib/test_helpers.sh"

SKILL="$REPO_ROOT/skills/project-architect/SKILL.md"
SKILL_CONTENT=$(cat "$SKILL")

# The Phase 4 selection step must mention affected_docs union
assert_contains "$SKILL_CONTENT" 'affected_docs' 'Phase 4 must reference affected_docs'
assert_contains "$SKILL_CONTENT" 'force-include' 'Phase 4 must explicitly force-include ADR affected_docs'

# It must intersect with the catalog (ignore ADR-named docs that aren't in the catalog)
assert_contains "$SKILL_CONTENT" 'intersect' 'Phase 4 must intersect ADR affected_docs with catalog'

# It must mention the union over all ADRs
assert_contains "$SKILL_CONTENT" 'union' 'Phase 4 must union over all adrs_filed entries'

test_summary
