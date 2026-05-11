# Questioning Flow Reference

Phased interview flow for project architecture discovery. Each phase builds on previous answers. Skip questions that are irrelevant based on prior answers.

## Table of Contents
- [Phase 1: Vision & Scope](#phase-1-vision--scope)
- [Phase 2: Tech Stack Decisions](#phase-2-tech-stack-decisions)
- [Phase 3: Architecture Deep Dive](#phase-3-architecture-deep-dive)
- [Question Routing Rules](#question-routing-rules)

---

## Phase 1: Vision & Scope

Ask these first. Answers determine which Phase 2/3 questions to ask and which documents to generate.

### 1.1 Project Identity
- What is the project name?
- One-sentence description: what does it do and for whom?
- What problem does it solve? Why does it need to exist?

### 1.2 Project Type
Determine the category (affects entire downstream flow):
- **Web application** (SaaS, dashboard, marketplace, social platform, content site)
- **Mobile application** (iOS, Android, cross-platform)
- **Multi-platform system** (web + mobile + desktop + API)
- **API / Backend service** (REST, GraphQL, gRPC, event-driven)
- **CLI tool / Developer tool**
- **Library / SDK / Package**
- **Desktop application** (macOS, Windows, Linux, cross-platform)
- **Embedded / IoT**
- **AI/ML application** (model serving, RAG, agents)
- **Other** (describe)

### 1.3 Target Users & Scale
- Who are the primary users? (consumers, businesses, developers, internal team)
- Expected scale: hobby/personal, startup MVP, growth-stage, enterprise?
- Geographic scope: single region, multi-region, global?
- Concurrent users estimate: <100, 100-10K, 10K-1M, 1M+?

### 1.4 Platforms & Clients
Only ask if project type involves client applications:
- Which platforms? (Web, iOS, Android, macOS, Windows, Linux)
- Browser support requirements? (evergreen only, legacy IE support)
- Offline capability needed?
- PWA or native?

### 1.5 Constraints & Priorities
- Budget constraints? (free tier only, moderate, enterprise budget)
- Timeline: prototype/MVP or production-grade from day one?
- Team size: solo developer, small team (2-5), larger team?
- Regulatory requirements? (GDPR, HIPAA, SOC2, PCI-DSS, none)
- Vendor lock-in tolerance: prefer open source, okay with managed services, no preference?
- Any pre-existing decisions? (e.g., "must use PostgreSQL", "must deploy to AWS")

### 1.6 Core Features (High-Level)
- List the 3-5 most important features/capabilities
- Any features explicitly out of scope for v1?
- Real-time requirements? (chat, live updates, collaboration)
- Content/media handling? (file uploads, images, video, documents)

---

## Phase 2: Tech Stack Decisions

Present options based on Phase 1 answers. For each category, list 2-4 options with one-line trade-off descriptions. Let the user decide.

### 2.1 Languages & Runtime
Ask based on project type:
- **Web frontend**: TypeScript, JavaScript, Dart (Flutter Web)
- **Web backend**: TypeScript/Node.js, Python, Go, Rust, Java/Kotlin, Ruby, Elixir, C#
- **Mobile**: Swift (iOS), Kotlin (Android), React Native, Flutter, .NET MAUI
- **Desktop**: Swift (macOS), C# (Windows), Rust, Electron, Tauri
- **CLI**: Rust, Go, Python, TypeScript (with Bun/Node)

### 2.2 Frontend Framework
Skip if no frontend. Ask based on platform:
- **Web**: Next.js, Nuxt, SvelteKit, Remix, Astro, plain React/Vue/Svelte
- **Mobile**: SwiftUI, Jetpack Compose, React Native, Flutter, Expo
- **Desktop**: SwiftUI, WPF/WinUI, Tauri, Electron

### 2.3 Backend / API Framework
Skip if purely client-side:
- **Node.js**: Express, Fastify, Hono, NestJS, tRPC
- **Python**: FastAPI, Django, Flask
- **Go**: Gin, Echo, Chi, standard library
- **Rust**: Axum, Actix-web, Rocket
- **Serverless/Edge**: Cloudflare Workers, AWS Lambda, Vercel Functions, Supabase Edge Functions

### 2.4 Database
Skip if no data persistence needed:
- **Relational**: PostgreSQL, MySQL, SQLite, CockroachDB
- **Managed Postgres**: Supabase, Neon, PlanetScale (MySQL), Railway
- **Document**: MongoDB, Firestore, DynamoDB
- **Key-Value**: Redis, Upstash, Cloudflare KV
- **Vector** (if AI/search): pgvector, Pinecone, Weaviate, Qdrant
- **Edge/Embedded**: SQLite (Turso/Litestream), Cloudflare D1, Durable Objects

### 2.5 ORM / Database Client
Ask after database is chosen:
- **TypeScript**: Drizzle, Prisma, Kysely, TypeORM
- **Python**: SQLAlchemy, Django ORM, Tortoise
- **Go**: GORM, sqlc, Ent
- **Rust**: Diesel, SeaORM, sqlx

### 2.6 Authentication
Skip if no user accounts:
- **Managed**: Clerk, Auth0, Supabase Auth, Firebase Auth, Kinde
- **Self-hosted**: Better Auth, Lucia, NextAuth/Auth.js, Keycloak, Ory
- **Enterprise SSO**: Okta, Azure AD, WorkOS
- Follow up: Which auth methods? (email/password, OAuth providers, magic links, passkeys, MFA)

### 2.7 Hosting & Deployment
- **Frontend hosting**: Vercel, Cloudflare Pages, Netlify, AWS Amplify, self-hosted
- **Backend hosting**: Cloudflare Workers, AWS (ECS/Lambda), GCP (Cloud Run), Railway, Fly.io, self-hosted
- **Container orchestration** (if applicable): Kubernetes, Docker Compose, ECS
- **CDN**: Cloudflare, CloudFront, Fastly, Vercel Edge

### 2.8 Package Manager & Tooling
- **JavaScript/TypeScript**: npm, pnpm, yarn, bun
- **Python**: pip, uv, poetry, pdm
- **Rust**: cargo
- **Go**: go modules
- **Monorepo tool** (if applicable): Turborepo, Nx, pnpm workspaces

### 2.9 Styling & UI
Skip if no frontend:
- **CSS approach**: Tailwind CSS, CSS Modules, styled-components, vanilla CSS, UnoCSS
- **Component library**: shadcn/ui, Radix, MUI, Ant Design, Chakra UI, Headless UI, none
- **Design system**: custom, existing (Material, Apple HIG), none

### 2.10 Payments & Billing
Skip if no monetization:
- Stripe, Lemon Squeezy, Paddle, RevenueCat (mobile), custom

### 2.11 Email & Notifications
Skip if not needed:
- **Email**: Resend, SendGrid, Postmark, AWS SES, Plunk
- **Push notifications**: OneSignal, Firebase Cloud Messaging, APNs
- **Multi-channel**: Novu, Knock, Courier

### 2.12 File Storage
Skip if no file handling:
- Cloudflare R2, AWS S3, Supabase Storage, Uploadthing, Minio

### 2.13 AI / ML Integration
Skip if no AI features:
- **LLM provider**: Anthropic Claude, OpenAI, Google Gemini, local (Ollama)
- **AI SDK**: Vercel AI SDK, LangChain, LlamaIndex, custom
- **Embeddings/RAG**: pgvector, Pinecone, Weaviate

---

## Phase 3: Architecture Deep Dive

Based on Phase 1 & 2 answers, dive deeper into areas that need architectural decisions.

### 3.1 Authentication Deep Dive
Only if auth was selected:
- Session management: JWT, session cookies, or hybrid?
- Token storage strategy: httpOnly cookies, secure storage (mobile)?
- Role-based access control (RBAC) or attribute-based (ABAC)?
- Multi-tenancy model: shared DB, schema-per-tenant, DB-per-tenant?
- OAuth providers to support: Google, GitHub, Apple, Microsoft, others?

### 3.2 Database Design Approach
Only if database was selected:
- Normalization level: fully normalized, practical denormalization, event-sourced?
- Migration strategy: code-first (ORM generates), SQL-first, hybrid?
- Key entities and their relationships (high-level ERD)?
- Soft deletes or hard deletes?
- Audit logging needs?
- Multi-tenancy data isolation approach?

### 3.3 API Design
Only if building an API:
- API style: REST, GraphQL, gRPC, tRPC, or hybrid?
- Versioning strategy: URL path, header, none?
- Rate limiting approach?
- Pagination strategy: cursor-based, offset, keyset?
- API documentation: OpenAPI/Swagger, GraphQL introspection, manual?
- WebSocket or SSE for real-time?

### 3.4 Security Architecture
Ask if security was flagged as important or for enterprise/regulated projects:
- Encryption at rest and in transit requirements?
- Secret management: environment variables, vault (Infisical, HashiCorp Vault)?
- Input validation and sanitization approach?
- CORS policy?
- CSP (Content Security Policy)?
- Dependency vulnerability scanning?
- Post-quantum cryptography needs?
- Zero-knowledge / end-to-end encryption requirements?

### 3.5 Frontend Architecture
Only if frontend exists:
- State management: React Context, Zustand, Redux, Jotai, signals?
- Data fetching: TanStack Query, SWR, tRPC, Apollo (GraphQL)?
- Routing approach: file-based (Next.js/Nuxt), manual?
- SSR, SSG, CSR, or ISR strategy?
- Internationalization (i18n) needed?
- Accessibility (a11y) requirements?
- Form handling: React Hook Form, Formik, native?

### 3.6 Testing Strategy
- Unit testing framework: Vitest, Jest, pytest, Go testing?
- Integration/API testing: Supertest, Playwright API testing?
- E2E testing: Playwright, Cypress, Detox (mobile)?
- Coverage target: percentage or critical paths only?
- CI test automation?

### 3.7 DevOps & Deployment
- Environment tiers: dev, staging, production?
- CI/CD: GitHub Actions, GitLab CI, CircleCI, Buildkite?
- Infrastructure as Code: Terraform, Pulumi, SST, CDK?
- Container strategy: Docker, Podman, none (serverless)?
- Preview deployments: per-PR, per-branch?
- Blue-green or canary deployments?

### 3.8 Monitoring & Observability
Ask if scale > MVP or if reliability is important:
- Error tracking: Sentry, Bugsnag, Datadog?
- Logging: structured logging, log aggregation?
- APM: Datadog, New Relic, Grafana Cloud?
- Uptime monitoring: Better Uptime, Checkly, Pingdom?
- Analytics: PostHog, Mixpanel, Amplitude, Plausible?

### 3.9 Third-Party Integrations
Ask if external services were mentioned:
- Which external APIs/services need integration?
- Webhook handling needs?
- Queue/event system: Redis queues, SQS, Inngest, Trigger.dev?
- Background job processing?
- Cron/scheduled tasks?

---

## Question Routing Rules

Use these rules to skip irrelevant questions:

| Phase 1 Answer | Skip |
|---|---|
| Project type = Library/SDK | Skip auth, database, hosting, UI, payments, notifications |
| Project type = CLI tool | Skip frontend, UI, payments (usually), styling |
| No user accounts needed | Skip all auth questions |
| No data persistence | Skip database and ORM questions |
| No frontend | Skip styling, UI components, frontend architecture |
| No monetization | Skip payments & billing |
| Budget = free tier only | Bias toward open-source and self-hosted options |
| Scale = hobby/personal | Skip monitoring, enterprise security, multi-tenancy |
| Team = solo | Simplify CI/CD, skip team collaboration tooling |
| No regulatory requirements | Simplify security section |
| Offline needed = yes | Include sync strategy, local-first architecture |
| Real-time needed = yes | Include WebSocket/SSE architecture |
| AI features = yes | Include AI/ML section, vector DB |
