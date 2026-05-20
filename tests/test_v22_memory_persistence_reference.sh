#!/usr/bin/env bash
# Author: Alexander Ford <alex@alexfordlabs.com>
# License: MIT
# Project: project-architect (https://github.com/alexfordlabs/project-architect)

source "$(dirname "$0")/lib/test_helpers.sh"

REF="$REPO_ROOT/skills/project-architect/references/memory-persistence.md"
SCHEMA="$REPO_ROOT/skills/project-architect/references/state-schema.md"

assert_file_exists "$REF" "memory-persistence.md must exist"

REF_CONTENT=$(cat "$REF")
assert_contains "$REF_CONTENT" 'cadence' 'must describe write cadence per phase'
assert_contains "$REF_CONTENT" 'MEMORY.md' 'must describe MEMORY.md index format'
assert_contains "$REF_CONTENT" 'Phase 0a' 'must mention Phase 0a (first write)'
assert_contains "$REF_CONTENT" 'Phase 6' 'must mention Phase 6 (major update at lock)'
assert_contains "$REF_CONTENT" 'memory_pointer' 'must reference state.memory_pointer'

SCHEMA_CONTENT=$(cat "$SCHEMA")
assert_contains "$SCHEMA_CONTENT" 'memory_pointer' 'state-schema must document memory_pointer'
assert_contains "$SCHEMA_CONTENT" 'last_synced' 'memory_pointer must have last_synced field'

test_summary
