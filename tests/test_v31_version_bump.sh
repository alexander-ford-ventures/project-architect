#!/usr/bin/env bash
# Author: Alexander Ford <alex@pseudo-lang.com>
# License: MIT
# Project: project-architect (https://github.com/alexfordlabs/project-architect)

source "$(dirname "$0")/lib/test_helpers.sh"

PLUGIN_JSON="$REPO_ROOT/.claude-plugin/plugin.json"
CHANGELOG="$REPO_ROOT/CHANGELOG.md"
MARKETPLACE_JSON="$REPO_ROOT/.claude-plugin/marketplace.json"
LICENSE_FILE="$REPO_ROOT/LICENSE"

PLUGIN_VERSION=$(jq -r '.version' "$PLUGIN_JSON")
assert_eq "$PLUGIN_VERSION" "3.1.0" "plugin.json version must be 3.1.0"

CHANGELOG_CONTENT=$(cat "$CHANGELOG")

# Current entry
assert_contains "$CHANGELOG_CONTENT" 'v3.1.0' 'CHANGELOG must have v3.1.0 entry'

# Regression checks: prior versions retained
assert_contains "$CHANGELOG_CONTENT" 'v3.0.0' 'CHANGELOG must retain v3.0.0 entry'
assert_contains "$CHANGELOG_CONTENT" 'v2.3.0' 'CHANGELOG must retain v2.3.0 entry'
assert_contains "$CHANGELOG_CONTENT" 'v2.2.1' 'CHANGELOG must retain v2.2.1 entry'
assert_contains "$CHANGELOG_CONTENT" 'v2.2.0' 'CHANGELOG must retain v2.2.0 entry'

# v3.1.0 entry must document the universal research checklist
assert_contains "$CHANGELOG_CONTENT" 'llms.txt' \
    'CHANGELOG v3.1.0 must reference the llms.txt requirement'
assert_contains "$CHANGELOG_CONTENT" 'llms-full.txt' \
    'CHANGELOG v3.1.0 must reference llms-full.txt'
assert_contains "$CHANGELOG_CONTENT" 'llmstxt.org' \
    'CHANGELOG v3.1.0 must cite the llms.txt standard'
assert_contains "$CHANGELOG_CONTENT" 'Universal research checklist' \
    'CHANGELOG v3.1.0 must name the universal research checklist feature'

# v3.1.0 entry must document the brand-asset kit
assert_contains "$CHANGELOG_CONTENT" 'Alex Ford Labs' \
    'CHANGELOG v3.1.0 must reference Alex Ford Labs brand kit'
assert_contains "$CHANGELOG_CONTENT" '.github/assets/brand' \
    'CHANGELOG v3.1.0 must reference the brand kit path'

# Manifest identity
PLUGIN_AUTHOR_NAME=$(jq -r '.author.name' "$PLUGIN_JSON")
PLUGIN_AUTHOR_EMAIL=$(jq -r '.author.email' "$PLUGIN_JSON")
PLUGIN_REPO=$(jq -r '.repository' "$PLUGIN_JSON")
assert_eq "$PLUGIN_AUTHOR_NAME" "Alexander Ford" "plugin.json author.name must be Alexander Ford"
assert_eq "$PLUGIN_AUTHOR_EMAIL" "alex@pseudo-lang.com" "plugin.json author.email must be alex@pseudo-lang.com"
assert_eq "$PLUGIN_REPO" "https://github.com/alexander-ford-ventures/project-architect" \
    "plugin.json repository must point at alexander-ford-ventures"

# Marketplace identifier
MARKETPLACE_NAME=$(jq -r '.name' "$MARKETPLACE_JSON")
assert_eq "$MARKETPLACE_NAME" "alexander-ford-ventures" \
    "marketplace.json name must be 'alexander-ford-ventures'"

# LICENSE
LICENSE_CONTENT=$(cat "$LICENSE_FILE")
assert_contains "$LICENSE_CONTENT" 'Alexander Ford' \
    'LICENSE must carry Alexander Ford as the copyright holder'
assert_contains "$LICENSE_CONTENT" 'alex@pseudo-lang.com' \
    'LICENSE must carry the new email'

# Brand-asset kit landed (sentinel files exist)
assert_file_exists "$REPO_ROOT/.github/assets/brand/lockup/light.svg" \
    "brand kit lockup SVG must exist"
assert_file_exists "$REPO_ROOT/.github/assets/brand/mark/light.svg" \
    "brand kit mark SVG must exist"
assert_file_exists "$REPO_ROOT/.github/assets/brand/social/light-1280x640.png" \
    "brand kit social-preview PNG must exist"
assert_file_exists "$REPO_ROOT/.github/assets/brand/README.md" \
    "brand kit README must exist"

# Old logo/social-preview retired
[ ! -f "$REPO_ROOT/.github/assets/alexander-ford-ventures-logo.svg" ] \
    || { echo "FAIL: legacy alexander-ford-ventures-logo.svg should have been deleted"; exit 1; }
[ ! -f "$REPO_ROOT/.github/social-preview.py" ] \
    || { echo "FAIL: legacy .github/social-preview.py should have been deleted"; exit 1; }
[ ! -f "$REPO_ROOT/.github/social-preview.png" ] \
    || { echo "FAIL: legacy .github/social-preview.png should have been deleted"; exit 1; }

# logo-concepts archived
assert_file_exists "$REPO_ROOT/.github/assets/_archive/logo-concepts/_contact-sheet.png" \
    "logo-concepts must be archived under _archive/"

test_summary
