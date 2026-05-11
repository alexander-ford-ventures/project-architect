# Document Templates Reference

Outlines for each document the skill can generate. Use these as structural guides — adapt content based on actual user decisions. Every document should be specific to the project, not generic boilerplate.

## Table of Contents
- [PROJECT_OVERVIEW.md](#project_overviewmd)
- [PROJECT_REQUIREMENTS.md](#project_requirementsmd)
- [AUTHENTICATION_SYSTEM.md](#authentication_systemmd)
- [DATABASE_DESIGN.md](#database_designmd)
- [API_GATEWAY.md](#api_gatewaymd)
- [UI_UX_DESIGN.md](#ui_ux_designmd)
- [PLATFORMS.md](#platformsmd)
- [SECURITY_AND_COMPLIANCE.md](#security_and_compliancemd)
- [DEPLOYMENT.md](#deploymentmd)
- [CI_CD.md](#ci_cdmd)
- [TESTING_STRATEGY.md](#testing_strategymd)
- [THIRD_PARTY_INTEGRATIONS.md](#third_party_integrationsmd)
- [MONITORING_AND_OBSERVABILITY.md](#monitoring_and_observabilitymd)
- [CLAUDE.md](#claudemd)
- [Additional Documents](#additional-documents)

---

## PROJECT_OVERVIEW.md

The master hub document. Always generated. Links to all other documents.

```markdown
# {Project Name}

## Vision
{One paragraph: what it is, who it's for, why it matters}

## Project Type
{Category and subcategory from Phase 1}

## Tech Stack Summary

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| Language | {choice} | {one-line why} |
| Frontend | {choice} | {one-line why} |
| Backend | {choice} | {one-line why} |
| Database | {choice} | {one-line why} |
| Auth | {choice} | {one-line why} |
| Hosting | {choice} | {one-line why} |
| ... | ... | ... |

## Architecture Diagram
{ASCII or mermaid diagram showing major components and data flow}

## Document Index

| Document | Description | Status |
|----------|-------------|--------|
| [PROJECT_REQUIREMENTS.md](PROJECT_REQUIREMENTS.md) | ... | Generated |
| ... | ... | ... |

## Key Decisions Log
{Table of major decisions made during the interview with brief rationale}

## Constraints & Non-Goals
{What is explicitly out of scope for v1}
```

---

## PROJECT_REQUIREMENTS.md

Always generated. Core requirements document.

```markdown
# Project Requirements: {Project Name}

## Problem Statement
{What problem does this solve? For whom?}

## Target Users
{User personas or categories with brief descriptions}

## Functional Requirements

### Core Features (MVP)
1. {Feature}: {description}
   - {sub-requirement}
   - {sub-requirement}
2. ...

### Future Features (Post-MVP)
1. {Feature}: {description}

## Non-Functional Requirements
- **Performance**: {targets — response times, throughput}
- **Scalability**: {expected growth, scaling strategy}
- **Availability**: {uptime target, SLA}
- **Security**: {high-level security requirements}
- **Accessibility**: {WCAG level, requirements}
- **Internationalization**: {languages, locales}

## Technical Constraints
{Pre-existing decisions, required integrations, budget limits}

## Success Metrics
{How to measure if the project is successful}
```

---

## AUTHENTICATION_SYSTEM.md

Generate when authentication is needed.

```markdown
# Authentication System: {Project Name}

## Auth Provider
{Chosen provider and rationale}

## Authentication Methods
{List: email/password, OAuth, magic links, passkeys, MFA, etc.}

## Auth Flow Diagrams

### Sign Up Flow
{Step-by-step flow or diagram}

### Sign In Flow
{Step-by-step flow or diagram}

### Password Reset / Recovery
{Flow description}

## Session Management
- Strategy: {JWT / session cookies / hybrid}
- Token storage: {httpOnly cookies / secure storage}
- Session duration: {expiry, refresh strategy}
- Concurrent session policy: {allow multiple, limit, single}

## Authorization Model
- Model type: {RBAC / ABAC / simple permissions}
- Roles: {list roles and their permissions}
- Resource-level permissions: {description if applicable}

## Multi-Tenancy
{Skip if not applicable}
- Tenant isolation model: {shared DB, schema-per-tenant, DB-per-tenant}
- Tenant identification: {subdomain, path, header}

## OAuth Providers
{List each provider with scopes needed}

## Security Considerations
- Password hashing: {algorithm}
- Rate limiting on auth endpoints
- Account lockout policy
- CSRF protection
- Token rotation strategy

## Implementation Packages
{List specific packages/SDKs to use}
```

---

## DATABASE_DESIGN.md

Generate when data persistence is needed.

```markdown
# Database Design: {Project Name}

## Database Choice
{Engine, hosting provider, rationale}

## ORM / Query Layer
{Chosen ORM/client and rationale}

## Schema Overview

### Entity Relationship Diagram
{Mermaid ERD or ASCII diagram showing entities and relationships}

### Core Entities

#### {Entity Name}
| Column | Type | Constraints | Description |
|--------|------|------------|-------------|
| id | uuid | PK | ... |
| ... | ... | ... | ... |

{Repeat for each entity}

## Relationships
{Describe key relationships: one-to-many, many-to-many, etc.}

## Indexing Strategy
{Key indexes for performance}

## Migration Strategy
- Approach: {code-first / SQL-first / hybrid}
- Tool: {migration tool}
- Naming convention: {timestamp, sequential}

## Data Policies
- Soft deletes: {yes/no, approach}
- Audit logging: {what is tracked}
- Data retention: {policies}
- Backup strategy: {frequency, retention}

## Multi-Tenancy Data Model
{Skip if not applicable — describe isolation approach}

## Seeding & Test Data
{Approach for development and testing data}
```

---

## API_GATEWAY.md

Generate when building APIs.

```markdown
# API Design: {Project Name}

## API Style
{REST / GraphQL / gRPC / tRPC — rationale}

## Base URL & Versioning
- Base URL: {pattern}
- Versioning: {strategy}

## Authentication & Authorization
{How API auth works — reference AUTHENTICATION_SYSTEM.md}

## Endpoints / Operations

### {Resource/Domain}

#### {Operation Name}
- Method: {GET/POST/PUT/DELETE}
- Path: {/api/v1/...}
- Auth: {required/optional/public}
- Request: {body/params schema}
- Response: {schema}
- Errors: {possible error codes}

{Repeat for each endpoint}

## Common Patterns
- Pagination: {strategy and format}
- Filtering: {query parameter conventions}
- Sorting: {convention}
- Error response format: {standard shape}
- Rate limiting: {limits and headers}

## Real-Time
{Skip if not applicable}
- Protocol: {WebSocket / SSE / polling}
- Events: {list of event types}
- Connection management: {reconnect strategy}

## API Documentation
- Tool: {OpenAPI, GraphQL playground, etc.}
- Auto-generation: {approach}

## Webhooks
{Skip if not applicable}
- Events: {list of webhook events}
- Payload format: {structure}
- Retry policy: {strategy}
- Verification: {signature method}
```

---

## UI_UX_DESIGN.md

Generate when there is a frontend.

```markdown
# UI/UX Design: {Project Name}

## Design System
- Approach: {custom / existing system}
- Component library: {choice}
- CSS strategy: {Tailwind, CSS Modules, etc.}

## Layout & Navigation
- Layout pattern: {sidebar, top nav, dashboard, etc.}
- Navigation structure: {main nav items, hierarchy}
- Responsive strategy: {breakpoints, mobile-first}

## Key Pages / Screens
{List each major page/screen with purpose and key components}

### {Page Name}
- Purpose: {what the user does here}
- Key components: {list}
- Data requirements: {what data is displayed/edited}

## Theme & Styling
- Color palette: {primary, secondary, accent, neutrals}
- Typography: {font families, scale}
- Dark mode: {yes/no, strategy}
- Spacing system: {scale}
- Border radius: {convention}

## State Management
- Global state: {tool and what's stored}
- Server state: {data fetching library}
- Form state: {form library}
- URL state: {query params, search}

## Rendering Strategy
{SSR, SSG, CSR, ISR — which pages use which}

## Accessibility
- Target: {WCAG level}
- Key requirements: {keyboard nav, screen reader, contrast}

## Internationalization
{Skip if not applicable}
- Languages: {list}
- i18n library: {choice}
- RTL support: {yes/no}

## Performance Targets
- LCP: {target}
- FID/INP: {target}
- CLS: {target}
- Bundle size budget: {target}
```

---

## PLATFORMS.md

Generate for multi-platform projects.

```markdown
# Platform Strategy: {Project Name}

## Supported Platforms

| Platform | Language/Framework | Priority | Target Version |
|----------|-------------------|----------|----------------|
| {platform} | {tech} | {P0/P1/P2} | {min version} |

## Code Sharing Strategy
{What is shared across platforms: business logic, API clients, types, UI components?}
{Monorepo structure, shared packages, code generation}

## Platform-Specific Considerations

### {Platform Name}
- Distribution: {App Store, direct download, web, etc.}
- Platform APIs used: {list native APIs}
- Permissions required: {list}
- Offline strategy: {approach}
- Storage: {local storage approach}
- Push notifications: {approach}
- Deep linking: {scheme}

{Repeat per platform}

## Sync Strategy
{How data syncs across platforms — if applicable}

## Release Strategy
- Versioning: {semver, calendar, etc.}
- Release cadence: {per platform}
- Update mechanism: {auto-update, store update, etc.}
```

---

## SECURITY_AND_COMPLIANCE.md

Generate when security is important or regulations apply.

```markdown
# Security & Compliance: {Project Name}

## Threat Model
{High-level threats and attack surfaces}

## Regulatory Requirements
{GDPR, HIPAA, SOC2, PCI-DSS — specific obligations}

## Data Classification
| Data Type | Classification | Encryption | Retention |
|-----------|---------------|------------|-----------|
| {type} | {public/internal/confidential/restricted} | {at-rest/in-transit/both/none} | {policy} |

## Encryption
- In transit: {TLS version, certificate management}
- At rest: {algorithm, key management}
- End-to-end: {if applicable — approach}
- Post-quantum: {if applicable — algorithms}

## Secret Management
- Strategy: {env vars / vault / managed service}
- Tool: {Infisical, Vault, AWS Secrets Manager, etc.}
- Rotation policy: {frequency}

## Input Validation & Sanitization
- Strategy: {schema validation library, approach}
- XSS prevention: {approach}
- SQL injection prevention: {parameterized queries, ORM}
- CSRF protection: {strategy}

## Dependency Security
- Vulnerability scanning: {tool}
- Update policy: {frequency}
- Lock file: {enforced}

## Access Control
{Reference AUTHENTICATION_SYSTEM.md for auth details}
- Principle of least privilege implementation
- API key management
- Service-to-service authentication

## Privacy
- Data collection: {what is collected, consent mechanism}
- Data deletion: {right to delete implementation}
- Data export: {right to portability}
- Cookie policy: {approach}

## Incident Response
- Logging: {what is logged for security events}
- Alerting: {trigger conditions}
- Response plan: {high-level steps}

## Compliance Checklist
{Specific checklist items based on applicable regulations}
```

---

## DEPLOYMENT.md

```markdown
# Deployment: {Project Name}

## Environments

| Environment | Purpose | URL Pattern | Infrastructure |
|-------------|---------|-------------|----------------|
| Development | Local dev | localhost:{port} | {local setup} |
| Staging | Pre-production testing | {url} | {provider} |
| Production | Live | {url} | {provider} |

## Infrastructure

### {Service/Component}
- Provider: {hosting provider}
- Configuration: {key settings}
- Scaling: {strategy}
- Region(s): {deployment regions}

## Domain & DNS
- Domain: {domain name}
- DNS provider: {provider}
- SSL/TLS: {certificate approach}

## Environment Variables
{List all required env vars with descriptions — NOT values}

| Variable | Description | Required | Source |
|----------|-------------|----------|--------|
| {VAR_NAME} | {what it's for} | {yes/no} | {where to get it} |

## Deployment Process
{Step-by-step deployment procedure — reference CI_CD.md for automation}

## Rollback Strategy
{How to roll back a bad deployment}

## Preview Deployments
{Per-PR / per-branch preview approach if applicable}
```

---

## CI_CD.md

```markdown
# CI/CD Pipeline: {Project Name}

## CI/CD Platform
{GitHub Actions, GitLab CI, etc.}

## Pipeline Stages

### On Pull Request
1. {step}: {description}
2. ...

### On Merge to Main
1. {step}: {description}
2. ...

### On Release Tag
1. {step}: {description}
2. ...

## Quality Gates
- Tests: {must pass, coverage threshold}
- Linting: {rules}
- Type checking: {must pass}
- Security scanning: {tool}
- Build: {must succeed}

## Branch Strategy
- Main branch: {name, protection rules}
- Feature branches: {naming convention}
- Release branches: {if applicable}

## Secrets Management in CI
{How secrets are provided to CI — reference SECURITY_AND_COMPLIANCE.md}

## Artifact Management
{Build artifacts, container registry, package registry}
```

---

## TESTING_STRATEGY.md

```markdown
# Testing Strategy: {Project Name}

## Testing Philosophy
{Approach: testing pyramid, testing trophy, pragmatic}

## Testing Stack

| Type | Tool | Coverage Target |
|------|------|----------------|
| Unit | {framework} | {target} |
| Integration | {framework} | {target} |
| E2E | {framework} | {target} |
| Visual/Snapshot | {tool} | {scope} |

## Test Structure
- Directory convention: {co-located, __tests__, tests/}
- Naming convention: {*.test.ts, *.spec.ts}
- Fixtures/mocks: {approach and location}

## Key Testing Scenarios
{List critical paths that must be tested}

## Test Data Strategy
- Factories: {approach}
- Database: {test DB approach — in-memory, test container, seeded}
- External services: {mocking strategy}

## CI Integration
{Reference CI_CD.md — when tests run, parallelization}

## Performance Testing
{Skip if not applicable — load testing approach and tools}
```

---

## THIRD_PARTY_INTEGRATIONS.md

```markdown
# Third-Party Integrations: {Project Name}

## Integration Overview

| Service | Purpose | Type | Priority |
|---------|---------|------|----------|
| {service} | {what it's used for} | {SDK/API/Webhook} | {P0/P1/P2} |

## Integration Details

### {Service Name}
- Purpose: {what it provides}
- Package/SDK: {npm package, pip package, etc.}
- Auth method: {API key, OAuth, etc.}
- Key endpoints/methods: {list primary operations}
- Rate limits: {known limits}
- Fallback strategy: {what happens if service is down}
- Cost: {pricing tier/estimate}

{Repeat for each integration}

## Event/Webhook Processing
{Incoming webhooks — event types, validation, processing}

## Background Jobs & Queues
{Async processing — job types, queue system, retry policies}

## Scheduled Tasks
{Cron jobs, scheduled functions — what runs when}
```

---

## MONITORING_AND_OBSERVABILITY.md

```markdown
# Monitoring & Observability: {Project Name}

## Monitoring Stack

| Concern | Tool | Purpose |
|---------|------|---------|
| Error tracking | {tool} | {catch and alert on errors} |
| APM | {tool} | {performance monitoring} |
| Logging | {tool} | {log aggregation} |
| Uptime | {tool} | {availability monitoring} |
| Analytics | {tool} | {user behavior tracking} |

## Logging Strategy
- Format: {structured JSON, plaintext}
- Levels: {when to use each level}
- PII handling: {scrubbing/masking approach}
- Retention: {how long logs are kept}

## Alerting Rules
| Alert | Condition | Severity | Channel |
|-------|-----------|----------|---------|
| {name} | {trigger condition} | {critical/warning/info} | {Slack/email/PagerDuty} |

## Dashboards
{Key dashboards to create and what they show}

## Health Checks
- Endpoint: {/health, /ready}
- Checks: {DB connectivity, external service availability}

## Performance Budgets
{Key metrics and their acceptable thresholds}
```

---

## CLAUDE.md

Generated at the end, synthesizing all decisions into a concise Claude Code configuration file.

```markdown
# {Project Name}

## Project Overview
{One-sentence description}

## Tech Stack
{Concise list — language, framework, database, auth, hosting}

## Project Structure
{Key directories and their purposes}

## Development Commands
- Install: {command}
- Dev: {command}
- Build: {command}
- Test: {command}
- Lint: {command}

## Code Conventions
- {Convention 1}
- {Convention 2}
- ...

## Architecture Notes
{Key architectural decisions that affect how code should be written}

## Key Files
- {path}: {purpose}
- ...
```

---

## Additional Documents

Generate these when the project warrants them:

| Document | When to Generate |
|----------|-----------------|
| `BILLING_AND_PAYMENTS.md` | Monetization, subscriptions, usage-based pricing |
| `EMAIL_AND_NOTIFICATIONS.md` | Email templates, notification channels, preferences |
| `FILE_STORAGE.md` | File upload, media processing, CDN |
| `AI_AND_ML.md` | AI features, model serving, RAG, embeddings |
| `REAL_TIME.md` | WebSocket/SSE, live collaboration, presence |
| `SEARCH.md` | Full-text search, faceted search, search indexing |
| `CACHING_STRATEGY.md` | Cache layers, invalidation, CDN caching |
| `INTERNATIONALIZATION.md` | Multi-language, locale handling, RTL |
| `ACCESSIBILITY.md` | WCAG compliance, screen reader, keyboard navigation |
| `DATA_PIPELINE.md` | ETL, data warehousing, analytics pipeline |
| `BACKGROUND_JOBS.md` | Queue processing, scheduled tasks, workers |
| `MOBILE_SPECIFIC.md` | App store guidelines, push notifications, deep links |
| `DESKTOP_SPECIFIC.md` | Distribution, auto-update, system integration |
