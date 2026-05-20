<!--
Author: Alexander Ford <alex@pseudo-lang.com>
Repository: https://github.com/alexander-ford-ventures/project-architect (current canonical)
                → https://github.com/alexfordlabs/project-architect (post-migration target)
License: MIT
-->

# HANDOFF — `project-architect` → `alexfordlabs/project-architect`

> Migration plan for moving this folder into a `pseudo-workspace` consolidation under **Alex Ford Labs**, and shifting the canonical GitHub home from `alexander-ford-ventures/project-architect` to `alexfordlabs/project-architect`.

## At-a-glance state (2026-05-20)

| Aspect | Current | Target after migration |
|---|---|---|
| **Plugin version** | `3.1.0` | `4.0.0` (major bump — identity changes) |
| **Folder path** | `/Users/vladimir/projects/project-architect` | `/Users/vladimir/projects/pseudo-workspace/project-architect` (or wherever `pseudo-workspace` lives) |
| **Canonical GitHub** | [`alexander-ford-ventures/project-architect`](https://github.com/alexander-ford-ventures/project-architect) (PUBLIC, ACTIVE) | [`alexfordlabs/project-architect`](https://github.com/alexfordlabs/project-architect) (does not yet exist) |
| **Legacy mirror** | [`siliconyouth/project-architect`](https://github.com/siliconyouth/project-architect) (PUBLIC, ARCHIVED, redirect README) | unchanged — keep as legacy mirror |
| **Older mirror** | `alexander-ford-ventures/project-architect` | becomes legacy mirror — archive + redirect README, mirror the siliconyouth pattern |
| **Marketplace ID** | `@alexander-ford-ventures` | `@alexfordlabs` |
| **Author** | Alexander Ford `<alex@pseudo-lang.com>` | unchanged |
| **Brand identity** | Alex Ford Labs (AF / LABS, Geist Mono ExtraBold, V5 B&W) | unchanged — already shipped |
| **Test count** | 69 / 69 green | should stay 69 (retire/replace `test_v31_version_bump.sh` → `test_v40_version_bump.sh`) |

## Migration steps

Follow these in order. Each step is independently safe; the destructive ones (git remote re-target, GitHub repo create, archive flip) are flagged.

### Phase 1 — Repository skeleton at the new org

**(Destructive: creates a new public GitHub repo.)**

```bash
# 1. Confirm the alexfordlabs org exists and you can create repos there
gh api orgs/alexfordlabs --jq '.login + " · " + .description'
gh api user/memberships/orgs/alexfordlabs --jq '.state + " · role=" + .role'
# Expect: 'active · role=admin'

# 2. Create the new repo (PUBLIC, no auto-init)
gh repo create alexfordlabs/project-architect --public \
    --description "Project architecture orchestrator for Claude Code — interviews you across 11 phases, dispatches 6 specialised subagents, files ADRs, generates design docs + per-folder CLAUDE.md + .claude/ tooling + 3 router slash commands. Supports 19+ project types including programming language design." \
    --homepage "https://alexfordlabs.com"
```

### Phase 2 — Folder relocation (local filesystem)

```bash
# 3. Decide the new path
NEW_PARENT=/Users/vladimir/projects/pseudo-workspace    # adjust if different
mkdir -p "$NEW_PARENT"

# 4. Move the folder (NOT cp — preserve git history + working state)
mv /Users/vladimir/projects/project-architect "$NEW_PARENT/project-architect"

# 5. Verify
cd "$NEW_PARENT/project-architect" && git log --oneline -3 && bash tests/run_all.sh
# Expect: Test files passed: 69 / All tests passed.
```

### Phase 3 — Git remote retarget

```bash
# 6. Rename the current 'origin' (= alexander-ford-ventures) to legacy mirror role,
#    and add the new alexfordlabs as 'origin'
cd "$NEW_PARENT/project-architect"
git remote rename origin alexanderfordventures            # keep the older repo reachable
git remote add origin git@github.com:alexfordlabs/project-architect.git
git remote -v
# origin              git@github.com:alexfordlabs/project-architect.git              (fetch+push)
# alexanderfordventures git@github.com:alexander-ford-ventures/project-architect.git (fetch+push)
# siliconyouth        git@github.com:siliconyouth/project-architect.git              (fetch+push)
```

### Phase 4 — Identity sweep across files (v4.0.0 release prep)

```bash
# 7. Run a Python sweep similar to the v3.0.0 one. Patterns:
#    siliconyouth/project-architect         → already migrated to alexander-ford-ventures
#    alexander-ford-ventures/project-architect → alexfordlabs/project-architect
#    @alexander-ford-ventures               → @alexfordlabs
#    "alexander-ford-ventures" (JSON value) → "alexfordlabs"
#    Alexander Ford Ventures (org name)     → Alex Ford Labs
#
# Exclude (same exclusion list as v3.0.0 sweep): docs/superpowers/{plans,specs,test-plans}/*,
# docs/tests/*, tests/fixtures/*, CHANGELOG.md (history), .remember/, .git/, _archive/.
```

> A reusable sweep script lived at `/tmp/rename_sweep.py` during the v3.0.0 work. Worth re-writing it from scratch with the new patterns — the historical version is gone with /tmp.

### Phase 5 — Brand asset path-string consistency

The brand kit's `README.md` and `build_brand.py` already reference `alexfordlabs/project-architect` as the future repo, so they're forward-compatible. Verify:

```bash
grep -rn 'alexfordlabs\|alexander-ford-ventures' .github/assets/brand/ | head -10
```

### Phase 6 — Test rotation

Retire-and-replace the version-bump test per the canonical pattern:

```bash
git rm tests/test_v31_version_bump.sh
# Write tests/test_v40_version_bump.sh asserting:
#   plugin.json version = "4.0.0"
#   plugin.json repository = https://github.com/alexfordlabs/project-architect
#   marketplace.json name = "alexfordlabs"
#   CHANGELOG must have v4.0.0 entry mentioning org move
#   Brand-kit sentinel files still exist
```

### Phase 7 — Release commit

```bash
# 8. Bump plugin.json: 3.1.0 → 4.0.0
# 9. Prepend CHANGELOG.md v4.0.0 entry (move from alexander-ford-ventures → alexfordlabs)
# 10. Update README: "What's new in v4.0.0", collapse v3.1.0 into <details>, repoint all paths
# 11. Update .claude-plugin/marketplace.json: "name": "alexfordlabs", owner.url, etc.
# 12. ONE release commit:
git add -A
git commit -m "$(cat <<'EOF'
chore(release): v4.0.0 — repository move to alexfordlabs + pseudo-workspace consolidation
[full body — see CLAUDE.md "Release workflow" for canonical commit-message shape]
EOF
)"
git tag -a v4.0.0 -m "..."
```

### Phase 8 — Push + release

```bash
# 13. Push to the new canonical origin
git push -u origin main
git push origin v4.0.0
# Also mirror to alexanderfordventures for archival, BEFORE archiving it:
git push alexanderfordventures main
git push alexanderfordventures v4.0.0

# 14. GitHub Release on the new repo
gh release create v4.0.0 --repo alexfordlabs/project-architect \
    --title "v4.0.0 — Repository move to alexfordlabs + pseudo-workspace consolidation" \
    --notes-file - < <(sed -n '/^## v4.0.0/,/^## v3.1.0/p' CHANGELOG.md | sed '$d')

# 15. Update alexander-ford-ventures repo's README with a MOVED notice (same pattern as siliconyouth),
#     then archive it (visibility stays PUBLIC for redirect discoverability):
gh repo edit alexander-ford-ventures/project-architect \
    --description "📦 MOVED → alexfordlabs/project-architect (v4.0.0+). Archived. v2.x–v3.x mirror." \
    --homepage "https://github.com/alexfordlabs/project-architect"
gh repo archive alexander-ford-ventures/project-architect --yes
```

### Phase 9 — GitHub social-preview re-upload

Browser-only step (GitHub doesn't expose social-preview upload via API):

1. Open <https://github.com/alexfordlabs/project-architect/settings>
2. Scroll to **Social preview**
3. Upload `.github/assets/brand/social/light-1280x640.png`
4. Repeat at <https://github.com/alexander-ford-ventures/project-architect/settings> (so the redirect repo also shows the AF Labs branding when shared)

### Phase 10 — Memory directory copy

Claude Code's project-memory directory is keyed by absolute project path. After moving the folder, the memory dir for the new path needs to be populated from the old one:

```bash
# Old: ~/.claude/projects/-Users-vladimir-projects-project-architect/memory/
# New: ~/.claude/projects/-Users-vladimir-projects-pseudo-workspace-project-architect/memory/
#      (slash → dash escaping is the convention)

OLD_MEM=~/.claude/projects/-Users-vladimir-projects-project-architect/memory
NEW_MEM=~/.claude/projects/-Users-vladimir-projects-pseudo-workspace-project-architect/memory
mkdir -p "$NEW_MEM"
cp -r "$OLD_MEM"/* "$NEW_MEM"/

# Optionally, after a few sessions confirm the new location is sticking:
# mv "$OLD_MEM" "$OLD_MEM.archived-$(date -u +%Y%m%d)"
```

### Phase 11 — Verify the install path end-to-end

In a fresh Claude Code session:

```
/plugin
# Should detect the move; you may need to re-add the new marketplace:
claude plugin uninstall project-architect@alexander-ford-ventures   # only if old install was active
claude plugin marketplace add alexfordlabs/project-architect
claude plugin install project-architect@alexfordlabs
/reload-plugins
/project-architect
```

The Preflight banner should print `v4.0.0`, all 6 recommended plugins present, version-freshness green.

## Rollback contract

If anything goes wrong in Phases 7–9, the rollback is non-destructive:

- The `alexander-ford-ventures/project-architect` mirror still has the full history through v3.1.0
- The local `alexanderfordventures` remote can be re-promoted to `origin` with `git remote rename`
- `gh repo unarchive` un-flips visibility
- The `siliconyouth/project-architect` mirror is unaffected throughout

If anything goes wrong in Phases 1–6 (pre-commit), there's nothing to roll back — just discard local changes.

## What the new session needs to know

The shipping checkpoint memory at `~/.claude/projects/-Users-vladimir-projects-project-architect/memory/project_v31_handoff_2026-05-20.md` is the full briefing. After the memory directory copy in Phase 10, the same memory will load automatically when a Claude Code session is opened at the new path.

---

*★ Skillfully made with [project-architect](https://github.com/alexander-ford-ventures/project-architect).*
