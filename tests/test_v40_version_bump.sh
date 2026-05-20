#!/usr/bin/env bash
# Author: Alexander Ford <alex@alexfordlabs.com>
# License: MIT
# Project: project-architect (https://github.com/alexfordlabs/project-architect)

source "$(dirname "$0")/lib/test_helpers.sh"

PLUGIN_JSON="$REPO_ROOT/.claude-plugin/plugin.json"
CHANGELOG="$REPO_ROOT/CHANGELOG.md"
MARKETPLACE_JSON="$REPO_ROOT/.claude-plugin/marketplace.json"
LICENSE_FILE="$REPO_ROOT/LICENSE"

PLUGIN_VERSION=$(jq -r '.version' "$PLUGIN_JSON")
assert_eq "$PLUGIN_VERSION" "4.0.0" "plugin.json version must be 4.0.0"

CHANGELOG_CONTENT=$(cat "$CHANGELOG")

# Current entry
assert_contains "$CHANGELOG_CONTENT" 'v4.0.0' 'CHANGELOG must have v4.0.0 entry'

# Regression checks: prior versions retained
assert_contains "$CHANGELOG_CONTENT" 'v3.1.0' 'CHANGELOG must retain v3.1.0 entry'
assert_contains "$CHANGELOG_CONTENT" 'v3.0.0' 'CHANGELOG must retain v3.0.0 entry'
assert_contains "$CHANGELOG_CONTENT" 'v2.3.0' 'CHANGELOG must retain v2.3.0 entry'
assert_contains "$CHANGELOG_CONTENT" 'v2.2.1' 'CHANGELOG must retain v2.2.1 entry'

# v4.0.0 entry must document the repository move + pseudo-workspace consolidation
assert_contains "$CHANGELOG_CONTENT" 'alexfordlabs/project-architect' \
    'CHANGELOG v4.0.0 must reference alexfordlabs canonical home'
assert_contains "$CHANGELOG_CONTENT" 'pseudo-workspace' \
    'CHANGELOG v4.0.0 must reference the pseudo-workspace consolidation'
assert_contains "$CHANGELOG_CONTENT" 'alex@alexfordlabs.com' \
    'CHANGELOG v4.0.0 must reference the new author email'

# Manifest identity — post-migration
PLUGIN_AUTHOR_NAME=$(jq -r '.author.name' "$PLUGIN_JSON")
PLUGIN_AUTHOR_EMAIL=$(jq -r '.author.email' "$PLUGIN_JSON")
PLUGIN_REPO=$(jq -r '.repository' "$PLUGIN_JSON")
assert_eq "$PLUGIN_AUTHOR_NAME" "Alexander Ford" "plugin.json author.name must be Alexander Ford"
assert_eq "$PLUGIN_AUTHOR_EMAIL" "alex@alexfordlabs.com" "plugin.json author.email must be alex@alexfordlabs.com"
assert_eq "$PLUGIN_REPO" "https://github.com/alexfordlabs/project-architect" \
    "plugin.json repository must point at alexfordlabs"

# Marketplace metadata
MARKETPLACE_NAME=$(jq -r '.name' "$MARKETPLACE_JSON")
MARKETPLACE_OWNER_NAME=$(jq -r '.owner.name' "$MARKETPLACE_JSON")
MARKETPLACE_OWNER_EMAIL=$(jq -r '.owner.email' "$MARKETPLACE_JSON")
MARKETPLACE_OWNER_URL=$(jq -r '.owner.url' "$MARKETPLACE_JSON")
assert_eq "$MARKETPLACE_NAME" "alexfordlabs" "marketplace.json name must be alexfordlabs"
assert_eq "$MARKETPLACE_OWNER_NAME" "Alexander Ford" "marketplace.json owner.name must be Alexander Ford"
assert_eq "$MARKETPLACE_OWNER_EMAIL" "alex@alexfordlabs.com" "marketplace.json owner.email must be alex@alexfordlabs.com"
assert_contains "$MARKETPLACE_OWNER_URL" "alexfordlabs/project-architect" \
    "marketplace.json owner.url must reference alexfordlabs"

# LICENSE copyright
LICENSE_CONTENT=$(cat "$LICENSE_FILE")
assert_contains "$LICENSE_CONTENT" "alex@alexfordlabs.com" \
    "LICENSE copyright must reference alex@alexfordlabs.com"

# Anti-regression: no legacy identity strings in tracked files (excluding historical sections).
# Scan ONLY tracked files (mirrors gitleaks scope — untracked + gitignored excluded).
# Historical-preservation files (CHANGELOG, HANDOFF, .gitleaks self, docs/superpowers, docs/tests,
# tests/fixtures, _archive) intentionally retain old identity strings.
LEAKS=$(
    cd "$REPO_ROOT" && git ls-files | \
    grep -v -E '^(CHANGELOG\.md|HANDOFF\.md|README\.md|\.gitleaks\.toml)$' | \
    grep -v -E '^(docs/superpowers/(plans|specs|test-plans)|docs/tests|tests/fixtures|.*_archive)/' | \
    xargs -I {} grep -l 'pseudo-lang\.com\|alexander-ford-ventures\|vladimir@dukelic\|Vladimir Dukelic' {} 2>/dev/null \
    || true
)
assert_eq "$LEAKS" "" "no legacy identity strings should remain in tracked code/config files outside historical-preservation areas"

# Brand kit sentinel files (preserved from v3.1.0)
assert_file_exists "$REPO_ROOT/.github/assets/brand/README.md" \
    "Alex Ford Labs brand-kit README must exist (v3.1.0 deliverable preserved)"
assert_file_exists "$REPO_ROOT/.github/assets/brand/social/light-1280x640.png" \
    "Alex Ford Labs brand-kit social-preview must exist"

# NEW in v4.0.0 — gitleaks + pre-commit configs
assert_file_exists "$REPO_ROOT/.gitleaks.toml" \
    ".gitleaks.toml must exist (workspace-canonical secret-scan config)"
assert_file_exists "$REPO_ROOT/.pre-commit-config.yaml" \
    ".pre-commit-config.yaml must exist (gitleaks v8.30.1 hook)"

GITLEAKS_CONTENT=$(cat "$REPO_ROOT/.gitleaks.toml")
assert_contains "$GITLEAKS_CONTENT" 'identity-correlation-vladimir-dukelic' \
    '.gitleaks.toml must include the vladimir-dukelic identity-correlation rule'
assert_contains "$GITLEAKS_CONTENT" 'identity-correlation-pseudo-lang' \
    '.gitleaks.toml must include the pseudo-lang identity-correlation rule'

PRECOMMIT_CONTENT=$(cat "$REPO_ROOT/.pre-commit-config.yaml")
assert_contains "$PRECOMMIT_CONTENT" 'gitleaks' \
    '.pre-commit-config.yaml must wire the gitleaks hook'
assert_contains "$PRECOMMIT_CONTENT" 'v8.30.1' \
    '.pre-commit-config.yaml must pin gitleaks v8.30.1'

test_summary
