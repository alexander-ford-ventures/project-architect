#!/usr/bin/env bash
# Author: Vladimir Dukelic <vladimir@dukelic.com>
# License: MIT
# Project: project-architect (https://github.com/siliconyouth/project-architect)

source "$(dirname "$0")/lib/test_helpers.sh"

PLUGIN_JSON="$REPO_ROOT/.claude-plugin/plugin.json"
CHANGELOG="$REPO_ROOT/CHANGELOG.md"

PLUGIN_VERSION=$(jq -r '.version' "$PLUGIN_JSON")
assert_eq "$PLUGIN_VERSION" "2.3.0" "plugin.json version must be 2.3.0"

CHANGELOG_CONTENT=$(cat "$CHANGELOG")
assert_contains "$CHANGELOG_CONTENT" 'v2.3.0' 'CHANGELOG must have v2.3.0 entry'
assert_contains "$CHANGELOG_CONTENT" 'v2.2.1' 'CHANGELOG must retain v2.2.1 entry (regression check)'
assert_contains "$CHANGELOG_CONTENT" 'v2.2.0' 'CHANGELOG must retain v2.2.0 entry (regression check)'

# The v2.3.0 entry must mention all 6 PL sub_types by name.
assert_contains "$CHANGELOG_CONTENT" 'general_purpose_language' 'CHANGELOG v2.3.0 must mention general_purpose_language sub_type'
assert_contains "$CHANGELOG_CONTENT" 'domain_specific_language' 'CHANGELOG v2.3.0 must mention domain_specific_language sub_type'
assert_contains "$CHANGELOG_CONTENT" 'query_language' 'CHANGELOG v2.3.0 must mention query_language sub_type'
assert_contains "$CHANGELOG_CONTENT" 'configuration_language' 'CHANGELOG v2.3.0 must mention configuration_language sub_type'
assert_contains "$CHANGELOG_CONTENT" 'educational_language' 'CHANGELOG v2.3.0 must mention educational_language sub_type'
assert_contains "$CHANGELOG_CONTENT" 'transpiler_target' 'CHANGELOG v2.3.0 must mention transpiler_target sub_type'

# The v2.3.0 entry must mention at least 3 of the 7 PL templates.
assert_contains "$CHANGELOG_CONTENT" 'LANGUAGE_GRAMMAR' 'CHANGELOG v2.3.0 must mention LANGUAGE_GRAMMAR template'
assert_contains "$CHANGELOG_CONTENT" 'SEMANTICS' 'CHANGELOG v2.3.0 must mention SEMANTICS template'
assert_contains "$CHANGELOG_CONTENT" 'TYPE_SYSTEM' 'CHANGELOG v2.3.0 must mention TYPE_SYSTEM template'
assert_contains "$CHANGELOG_CONTENT" 'BOOTSTRAP_PLAN' 'CHANGELOG v2.3.0 must mention BOOTSTRAP_PLAN template'
assert_contains "$CHANGELOG_CONTENT" 'STABILITY_AND_RFC' 'CHANGELOG v2.3.0 must mention STABILITY_AND_RFC template'

# "programming language" must be visible in the entry.
assert_contains "$CHANGELOG_CONTENT" 'programming language' 'CHANGELOG v2.3.0 must mention "programming language"'

# Decision axes are part of the headline framing.
assert_contains "$CHANGELOG_CONTENT" 'impl_strategy' 'CHANGELOG v2.3.0 must mention impl_strategy decision axis'
assert_contains "$CHANGELOG_CONTENT" 'host_runtime' 'CHANGELOG v2.3.0 must mention host_runtime decision axis'

test_summary
