#!/usr/bin/env bash
# Author: Alexander Ford <alex@pseudo-lang.com>
# License: MIT
# Project: project-architect (https://github.com/alexander-ford-ventures/project-architect)
#
# Test: quality-gate-auditor wired into Phase 4 → Phase 5 transition (v2.2, sketch B)
source "$(dirname "$0")/lib/test_helpers.sh"

SKILL="$REPO_ROOT/skills/project-architect/SKILL.md"
CONTENT=$(cat "$SKILL")

# End of Phase 4 must dispatch the auditor
assert_contains "$CONTENT" 'quality-gate-auditor' 'Phase 4 close must dispatch auditor'
assert_contains "$CONTENT" 'phase_5_seed_items' 'Phase 5 menu must seed from auditor output'

# Phase 5 must check for BLOCKERs before allowing approve
assert_contains "$CONTENT" 'BLOCKER count' 'Phase 5 menu must show BLOCKER count from auditor'

# Phase 4 → 5 transition must reference state.last_audit
assert_contains "$CONTENT" 'last_audit' 'must save auditor output to state.last_audit'

# Auditor dispatch must have the 4 required inputs
assert_contains "$CONTENT" 'project_root' 'auditor dispatch must include project_root'
assert_contains "$CONTENT" 'state_path' 'auditor dispatch must include state_path'
assert_contains "$CONTENT" 'catalog_path' 'auditor dispatch must include catalog_path'
assert_contains "$CONTENT" 'adr_dir' 'auditor dispatch must include adr_dir'

test_summary
