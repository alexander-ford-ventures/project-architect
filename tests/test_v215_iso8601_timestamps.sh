#!/usr/bin/env bash
# Author: Alexander Ford <alex@alexfordlabs.com>
# License: MIT
# Project: project-architect (https://github.com/alexfordlabs/project-architect)

source "$(dirname "$0")/lib/test_helpers.sh"

SKILL="$REPO_ROOT/skills/project-architect/SKILL.md"
SCHEMA="$REPO_ROOT/skills/project-architect/references/state-schema.md"

# Test 1: SKILL.md uses `date -u +"%Y-%m-%dT%H:%M:%SZ"` (the canonical ISO8601 UTC)
SKILL_CONTENT=$(cat "$SKILL")
assert_contains "$SKILL_CONTENT" 'date -u +"%Y-%m-%dT%H:%M:%SZ"' 'SKILL.md must use ISO8601 UTC date format'

# Test 2: schema doc has explicit "ISO8601" + "never date-only" guidance
SCHEMA_CONTENT=$(cat "$SCHEMA")
assert_contains "$SCHEMA_CONTENT" 'ISO8601' 'state-schema.md must document ISO8601 requirement'
assert_contains "$SCHEMA_CONTENT" 'never date-only' 'state-schema.md must explicitly forbid date-only timestamps'

test_summary
