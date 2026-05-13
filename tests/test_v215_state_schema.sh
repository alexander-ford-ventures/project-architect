#!/usr/bin/env bash
# Author: Vladimir Dukelic <vladimir@dukelic.com>
# License: MIT
# Project: project-architect (https://github.com/siliconyouth/project-architect)

source "$(dirname "$0")/lib/test_helpers.sh"

# Test 1: state-schema.md mentions that schema_version != plugin_version
SCHEMA_DOC="$REPO_ROOT/skills/project-architect/references/state-schema.md"
assert_file_exists "$SCHEMA_DOC" "state-schema.md must exist"

CONTENT=$(cat "$SCHEMA_DOC")
assert_contains "$CONTENT" 'schema_version' 'schema_version must be documented'
assert_contains "$CONTENT" '"2.0"' 'schema_version "2.0" must be the documented value'

# Test 2: state-schema.md explicitly notes the separation from plugin_version
assert_contains "$CONTENT" 'separate from' 'doc must explicitly note schema_version is separate from plugin_version'

# Test 3: SKILL.md Preflight has the explicit schema_version write
SKILL="$REPO_ROOT/skills/project-architect/SKILL.md"
SKILL_CONTENT=$(cat "$SKILL")
assert_contains "$SKILL_CONTENT" '"schema_version": "2.0"' 'SKILL.md Preflight must initialize schema_version to "2.0", not the plugin version'

test_summary
