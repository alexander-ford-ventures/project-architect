---
name: project-architect
description: >
  Comprehensive project architecture planning and documentation generator.
  Interviews the user in phases to capture vision, tech stack, and architecture
  decisions, then generates tailored planning documents and CLAUDE.md.
  Use when the user wants to: (1) set up a new project, (2) scaffold project
  docs, (3) initialize project architecture, (4) plan a new project,
  (5) create project documentation, (6) design a system architecture,
  (7) choose a tech stack, or (8) bootstrap a project with planning documents.
  Works for all project types: web apps, mobile, CLI tools, libraries, APIs,
  multi-platform systems, desktop apps, AI/ML applications, and more.
---

# Project Architect

Interview the user in phases, make decisions, generate architecture documents and CLAUDE.md.

## Workflow

```
Phase 1: Vision & Scope → Phase 2: Tech Stack → Phase 3: Architecture Deep Dive → Document Generation → CLAUDE.md
```

Each phase uses `AskUserQuestion` to gather decisions. Earlier answers determine which later questions to ask and which documents to generate.

### Resumability

The user may not complete all phases in one session. At the end of each phase:
1. Summarize decisions made so far
2. List which phases remain
3. Save progress to `docs/_architect_state.json` (decisions log — delete after all docs generated)

If the user returns and says "continue project setup" or similar, read `docs/_architect_state.json` to resume.

## Phase 1: Vision & Scope

Gather foundational information. Read [references/questioning-flow.md](references/questioning-flow.md) section "Phase 1" for the full question set.

**Ask in this order:**
1. **Project identity** — name, one-sentence description, problem statement
2. **Project type** — web app, mobile, CLI, library, multi-platform, etc.
3. **Target users & scale** — who, how many, where
4. **Platforms** — which platforms, browser/device requirements
5. **Constraints & priorities** — budget, timeline, team, regulations, existing decisions
6. **Core features** — top 3-5 features for MVP, explicit non-goals

**Rules:**
- Ask 2-4 questions at a time using `AskUserQuestion` (never overwhelm)
- Adapt follow-up questions based on answers (see routing rules in questioning-flow.md)
- If project type is "library/SDK", skip platforms, auth, database, UI questions later
- If project type is "CLI tool", skip frontend, styling, payments questions later
- Capture all decisions in a running log

**Phase 1 complete when:** Project type, target users, scale, constraints, and core features are known.

## Phase 2: Tech Stack Decisions

Present technology options for each relevant category. Read [references/tech-stack-options.md](references/tech-stack-options.md) for options and trade-offs.

**Ask in this order** (skip categories that don't apply based on Phase 1):
1. **Language & runtime**
2. **Frontend framework** (skip if no frontend)
3. **Backend framework** (skip if client-only)
4. **Database** (skip if no persistence)
5. **ORM / query layer** (ask after database chosen)
6. **Authentication** (skip if no user accounts)
7. **Hosting & deployment** (frontend and backend separately)
8. **Package manager & tooling**
9. **Styling & UI** (skip if no frontend)
10. **Payments** (skip if no monetization)
11. **Email & notifications** (skip if not needed)
12. **File storage** (skip if no file handling)
13. **AI/ML integration** (skip if no AI features)

**Rules:**
- Present 2-4 options per category with one-line trade-offs
- Do NOT strongly recommend — list options, user decides
- If user has pre-existing decisions (from Phase 1 constraints), confirm and skip
- Group related decisions together (e.g., database + ORM in same question set)

**Phase 2 complete when:** All relevant technology choices are made.

## Phase 3: Architecture Deep Dive

Deeper questions for areas that need detailed planning. Read [references/questioning-flow.md](references/questioning-flow.md) section "Phase 3" for the full question set.

**Only ask about areas that are relevant** (determined by Phase 1 & 2):
- Auth deep dive → if auth was selected
- Database design → if database was selected
- API design → if building an API
- Security architecture → if security flagged or regulated industry
- Frontend architecture → if frontend exists
- Testing strategy → for all non-trivial projects
- DevOps & deployment → if deploying beyond localhost
- Monitoring → if scale > MVP
- Third-party integrations → if external services mentioned

**Rules:**
- This phase may be shorter for simple projects (CLI, library)
- For complex projects (multi-platform, enterprise), this is the longest phase
- Ask 2-3 questions at a time, not all at once

**Phase 3 complete when:** Sufficient detail exists to generate all relevant documents.

## Document Generation

After all phases are complete, generate documents. Read [references/document-templates.md](references/document-templates.md) for document structures.

### Document Selection

Dynamically select which documents to generate based on project needs:

| Document | Generate When |
|----------|--------------|
| `PROJECT_OVERVIEW.md` | Always |
| `PROJECT_REQUIREMENTS.md` | Always |
| `AUTHENTICATION_SYSTEM.md` | User accounts / auth needed |
| `DATABASE_DESIGN.md` | Data persistence needed |
| `API_GATEWAY.md` | API / backend service |
| `UI_UX_DESIGN.md` | Frontend exists |
| `PLATFORMS.md` | Multi-platform project |
| `SECURITY_AND_COMPLIANCE.md` | Security important or regulated |
| `DEPLOYMENT.md` | Deploying beyond localhost |
| `CI_CD.md` | Automated pipeline needed |
| `TESTING_STRATEGY.md` | Non-trivial project |
| `THIRD_PARTY_INTEGRATIONS.md` | External services used |
| `MONITORING_AND_OBSERVABILITY.md` | Scale > MVP or reliability matters |
| Additional docs | See "Additional Documents" in document-templates.md |

### Generation Rules

1. Create `docs/` directory in the project root
2. Generate `PROJECT_OVERVIEW.md` first (the master hub)
3. Generate remaining documents in dependency order
4. Each document must reference specific decisions from the interview — no generic boilerplate
5. Include diagrams (mermaid or ASCII) where they add clarity
6. Cross-reference between documents (e.g., API_GATEWAY.md links to AUTHENTICATION_SYSTEM.md)
7. After all docs, delete `docs/_architect_state.json` (progress file no longer needed)

### CLAUDE.md Generation

Generate `CLAUDE.md` in the project root as the final step. This file configures future Claude Code sessions.

Include:
- Project name and one-line description
- Complete tech stack (language, framework, database, auth, hosting, key packages)
- Project structure (key directories and their purposes)
- Development commands (install, dev, build, test, lint)
- Code conventions derived from tech stack choices
- Key architectural decisions that affect coding patterns
- Links to relevant docs/ files for deeper context

Keep CLAUDE.md concise — it's loaded into every conversation. Reference `docs/` files for details.

## Output Location

All documents go to `docs/` in the project root:
```
project-root/
├── CLAUDE.md
└── docs/
    ├── PROJECT_OVERVIEW.md
    ├── PROJECT_REQUIREMENTS.md
    ├── AUTHENTICATION_SYSTEM.md
    ├── DATABASE_DESIGN.md
    └── ...
```

## Important Behaviors

- **Never generate documents without completing the interview** — partial information leads to generic docs
- **Be adaptive** — a CLI tool needs 3-4 documents, a multi-platform SaaS might need 10+
- **No boilerplate** — every section must contain project-specific decisions. If a section has nothing specific to say, omit it
- **Capture rationale** — for each tech choice, briefly note why it was chosen over alternatives
- **Respect existing decisions** — if the user says "I'm using PostgreSQL", don't ask about databases, just confirm and move on
