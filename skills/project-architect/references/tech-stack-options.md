# Tech Stack Options Reference

Concise option lists with trade-offs for each technology category. Present relevant options to the user, let them decide.

## Table of Contents
- [Frontend Frameworks](#frontend-frameworks)
- [Backend Frameworks](#backend-frameworks)
- [Databases](#databases)
- [ORMs & Query Builders](#orms--query-builders)
- [Authentication](#authentication)
- [Hosting & Deployment](#hosting--deployment)
- [CSS & Styling](#css--styling)
- [Component Libraries](#component-libraries)
- [State Management](#state-management)
- [Testing](#testing)
- [CI/CD](#cicd)
- [Monitoring & Observability](#monitoring--observability)
- [Payments](#payments)
- [Email & Notifications](#email--notifications)
- [File Storage](#file-storage)
- [AI & ML](#ai--ml)
- [Package Managers](#package-managers)

---

## Frontend Frameworks

### Web
| Option | Best For | Trade-off |
|--------|----------|-----------|
| **Next.js** | Full-stack React apps, SSR/SSG | Feature-rich but complex, Vercel-optimized |
| **Nuxt** | Vue ecosystem, SSR/SSG | Great DX, smaller ecosystem than React |
| **SvelteKit** | Performance-critical, simpler mental model | Smaller ecosystem, fewer developers |
| **Remix** | Nested routing, progressive enhancement | React-based, smaller community than Next |
| **Astro** | Content-heavy sites, multi-framework | Not ideal for highly interactive SPAs |

### Mobile
| Option | Best For | Trade-off |
|--------|----------|-----------|
| **React Native / Expo** | JS teams, code sharing with web | Not truly native, bridge overhead |
| **Flutter** | Beautiful cross-platform UI, single codebase | Dart language, large binary size |
| **SwiftUI** | iOS-first, best native experience | Apple only |
| **Jetpack Compose** | Android-first, modern Android | Android only |
| **.NET MAUI** | .NET teams, enterprise | Smaller community, Microsoft ecosystem |

### Desktop
| Option | Best For | Trade-off |
|--------|----------|-----------|
| **Tauri** | Small bundle, Rust backend, web frontend | Rust knowledge helpful, younger ecosystem |
| **Electron** | Maximum web compatibility, large ecosystem | Large memory/bundle, security surface |
| **SwiftUI** | macOS native | Apple only |
| **WinUI 3 / WPF** | Windows native | Windows only |

---

## Backend Frameworks

### Node.js / TypeScript
| Option | Best For | Trade-off |
|--------|----------|-----------|
| **Hono** | Edge-first, multi-runtime, lightweight | Newer, smaller ecosystem |
| **Fastify** | Performance, schema validation | More setup than Express |
| **Express** | Simplicity, massive ecosystem | Dated patterns, no built-in types |
| **NestJS** | Enterprise, structured architecture | Heavy, opinionated, Angular-like |
| **tRPC** | Type-safe APIs with TypeScript frontend | Requires TypeScript client |

### Python
| Option | Best For | Trade-off |
|--------|----------|-----------|
| **FastAPI** | Modern async APIs, auto-docs | Async complexity, Pydantic learning curve |
| **Django** | Batteries-included, admin panel | Monolithic, heavier for small APIs |
| **Flask** | Simplicity, microservices | Minimal built-in features |

### Go
| Option | Best For | Trade-off |
|--------|----------|-----------|
| **Chi** | Lightweight, idiomatic | Minimal features, manual wiring |
| **Gin** | Performance, familiar API | Less idiomatic Go |
| **Echo** | Balance of features and performance | Smaller community than Gin |

### Rust
| Option | Best For | Trade-off |
|--------|----------|-----------|
| **Axum** | Tokio ecosystem, tower middleware | Steep learning curve |
| **Actix-web** | Raw performance | Actor model can be complex |

### Edge / Serverless
| Option | Best For | Trade-off |
|--------|----------|-----------|
| **Cloudflare Workers** | Edge-first, global low latency | V8 isolates, some Node API gaps |
| **AWS Lambda** | AWS ecosystem, event-driven | Cold starts, vendor lock-in |
| **Vercel Functions** | Next.js integration | Vercel ecosystem |
| **Supabase Edge Functions** | Supabase integration, Deno | Supabase-coupled |

---

## Databases

### Relational
| Option | Best For | Trade-off |
|--------|----------|-----------|
| **PostgreSQL** | General purpose, extensions (pgvector, PostGIS) | Self-managed complexity |
| **Supabase (Postgres)** | Managed Postgres + auth + storage + realtime | Vendor coupling, pricing at scale |
| **Neon (Postgres)** | Serverless Postgres, branching | Newer, cold starts on free tier |
| **PlanetScale (MySQL)** | Serverless MySQL, branching | MySQL not Postgres, no FK enforcement |
| **SQLite / Turso** | Embedded, edge, local-first | Limited concurrent writes, simpler |
| **CockroachDB** | Distributed SQL, global scale | Complex, expensive at scale |

### Document
| Option | Best For | Trade-off |
|--------|----------|-----------|
| **MongoDB** | Flexible schema, document-oriented | No ACID joins, schema drift |
| **Firestore** | Firebase ecosystem, real-time | Vendor lock-in, query limitations |
| **DynamoDB** | AWS, massive scale, key-value + document | Complex pricing, rigid access patterns |

### Key-Value / Cache
| Option | Best For | Trade-off |
|--------|----------|-----------|
| **Redis / Upstash** | Caching, sessions, queues | Data loss risk (in-memory default) |
| **Cloudflare KV** | Edge key-value, global reads | Eventually consistent, write latency |

### Vector
| Option | Best For | Trade-off |
|--------|----------|-----------|
| **pgvector** | Postgres users, unified DB | Scaling limits vs dedicated vector DB |
| **Pinecone** | Managed, easy to use | Expensive, vendor lock-in |
| **Weaviate** | Self-hosted, hybrid search | Operational complexity |
| **Qdrant** | Performance, Rust-based | Smaller ecosystem |

---

## ORMs & Query Builders

### TypeScript
| Option | Best For | Trade-off |
|--------|----------|-----------|
| **Drizzle** | Type-safe, SQL-like, lightweight | Newer, migration story evolving |
| **Prisma** | Schema-first, great DX, migrations | Performance overhead, large engine binary |
| **Kysely** | Type-safe query builder, no codegen | Manual migrations, lower-level |
| **TypeORM** | Decorator-based, familiar to Java/C# devs | Performance issues, maintenance concerns |

### Python
| Option | Best For | Trade-off |
|--------|----------|-----------|
| **SQLAlchemy** | Flexible, powerful, async support | Steep learning curve |
| **Django ORM** | Django projects, batteries included | Django-coupled |

---

## Authentication

### Managed
| Option | Best For | Trade-off |
|--------|----------|-----------|
| **Clerk** | Best DX, prebuilt components | Pricing at scale, vendor lock-in |
| **Auth0** | Enterprise, extensive features | Complex, expensive |
| **Supabase Auth** | Supabase users, Row Level Security | Supabase-coupled |
| **Firebase Auth** | Firebase ecosystem | Google lock-in |
| **Kinde** | Simple, generous free tier | Smaller ecosystem |

### Self-Hosted / Library
| Option | Best For | Trade-off |
|--------|----------|-----------|
| **Better Auth** | TypeScript, flexible, self-hosted | Newer, smaller community |
| **Auth.js (NextAuth)** | Next.js projects | Complex configuration, session-focused |
| **Lucia** | Lightweight, any framework | Manual implementation, discontinued maintenance |
| **Keycloak** | Enterprise SSO, self-hosted | Heavy, Java-based, complex setup |
| **Ory** | Cloud-native identity, API-first | Steep learning curve |

---

## Hosting & Deployment

### Frontend
| Option | Best For | Trade-off |
|--------|----------|-----------|
| **Vercel** | Next.js, great DX, preview deploys | Pricing at scale, some lock-in |
| **Cloudflare Pages** | Edge-first, generous free tier | Fewer framework integrations |
| **Netlify** | Static/Jamstack, forms, functions | Less capable edge |
| **AWS Amplify** | AWS ecosystem | Complex setup |

### Backend
| Option | Best For | Trade-off |
|--------|----------|-----------|
| **Cloudflare Workers** | Edge, global, low-latency | V8 runtime limitations |
| **Railway** | Simple PaaS, databases included | Pricing, limited regions |
| **Fly.io** | Global edge, containers | Ops complexity, pricing changes |
| **AWS (ECS/Lambda)** | Full control, enterprise | Complex, expensive for small projects |
| **GCP Cloud Run** | Containers, Google ecosystem | Google lock-in |

---

## CSS & Styling
| Option | Best For | Trade-off |
|--------|----------|-----------|
| **Tailwind CSS** | Utility-first, rapid UI development | Verbose class names, learning curve |
| **CSS Modules** | Scoped CSS, framework-agnostic | No utility classes, more files |
| **vanilla-extract** | Type-safe CSS-in-TS, zero runtime | Build step required, TS coupling |
| **UnoCSS** | Customizable utilities, fast | Smaller community than Tailwind |

---

## Component Libraries
| Option | Best For | Trade-off |
|--------|----------|-----------|
| **shadcn/ui** | Customizable, copy-paste, Radix-based | React only, manual updates |
| **Radix UI** | Accessible primitives, unstyled | React only, needs styling |
| **MUI** | Material Design, comprehensive | Heavy, opinionated design |
| **Ant Design** | Enterprise dashboards, rich components | Large bundle, Chinese origin docs |
| **Headless UI** | Tailwind Labs, accessible | Limited component set |

---

## State Management
| Option | Best For | Trade-off |
|--------|----------|-----------|
| **Zustand** | Simple, lightweight, React | Limited devtools vs Redux |
| **Jotai** | Atomic state, fine-grained updates | Different mental model |
| **Redux Toolkit** | Complex state, time-travel debugging | Boilerplate, overkill for simple apps |
| **TanStack Query** | Server state, caching, mutations | Only for async/server state |
| **Valtio** | Proxy-based, mutable API | Less predictable updates |

---

## Testing
| Type | Options |
|------|---------|
| **Unit (JS/TS)** | Vitest (fast, Vite-native), Jest (established, large ecosystem) |
| **Unit (Python)** | pytest (standard), unittest (built-in) |
| **Unit (Go)** | testing (built-in), testify (assertions) |
| **E2E** | Playwright (multi-browser, fast), Cypress (great DX, single-tab) |
| **API** | Supertest, httpx, Bruno, Insomnia |
| **Visual** | Chromatic, Percy, Playwright screenshots |
| **Mobile** | Detox (React Native), XCTest (iOS), Espresso (Android) |

---

## CI/CD
| Option | Best For | Trade-off |
|--------|----------|-----------|
| **GitHub Actions** | GitHub users, large marketplace | YAML complexity, debugging |
| **GitLab CI** | GitLab users, built-in | GitLab ecosystem |
| **CircleCI** | Performance, Docker layers | Pricing, config complexity |
| **Buildkite** | Scale, self-hosted agents | Setup complexity |

---

## Monitoring & Observability
| Concern | Options |
|---------|---------|
| **Error tracking** | Sentry (standard), Bugsnag, Datadog |
| **APM** | Datadog, New Relic, Grafana Cloud |
| **Logging** | Datadog, Loki/Grafana, CloudWatch, Axiom |
| **Uptime** | Better Uptime, Checkly, Pingdom |
| **Analytics** | PostHog (OSS, full-stack), Plausible (privacy), Mixpanel, Amplitude |

---

## Payments
| Option | Best For | Trade-off |
|--------|----------|-----------|
| **Stripe** | Full-featured, developer-first | Complex pricing, US-centric |
| **Lemon Squeezy** | Simple, MoR (handles tax) | Fewer features than Stripe |
| **Paddle** | B2B SaaS, MoR | Limited customization |
| **RevenueCat** | Mobile subscriptions | Mobile only |

---

## Email & Notifications
| Concern | Options |
|---------|---------|
| **Transactional email** | Resend (modern DX), SendGrid (established), Postmark (deliverability), AWS SES (cheap) |
| **Push notifications** | OneSignal, Firebase Cloud Messaging, APNs direct |
| **Multi-channel** | Novu (OSS), Knock, Courier |

---

## File Storage
| Option | Best For | Trade-off |
|--------|----------|-----------|
| **Cloudflare R2** | S3-compatible, no egress fees | Cloudflare ecosystem |
| **AWS S3** | Standard, massive ecosystem | Egress costs |
| **Supabase Storage** | Supabase users, RLS integration | Supabase-coupled |
| **UploadThing** | Simple file uploads in TypeScript | Limited to uploads, T3-ecosystem |
| **MinIO** | Self-hosted S3-compatible | Operational complexity |

---

## AI & ML
| Concern | Options |
|---------|---------|
| **LLM Provider** | Anthropic Claude (best reasoning), OpenAI (ecosystem), Google Gemini (multimodal), Ollama (local) |
| **AI SDK** | Vercel AI SDK (streaming, multi-provider), LangChain (chains, agents), LlamaIndex (RAG-focused) |
| **Vector DB** | pgvector (unified), Pinecone (managed), Weaviate (hybrid search) |
| **Embeddings** | OpenAI text-embedding-3, Cohere embed, local sentence-transformers |

---

## Package Managers
| Option | Best For | Trade-off |
|--------|----------|-----------|
| **pnpm** | Monorepos, disk space, strict | Different node_modules structure |
| **bun** | Speed, all-in-one runtime | Compatibility gaps, newer |
| **npm** | Universal, no setup | Slower, flat node_modules |
| **yarn** | Berry (PnP), workspaces | PnP compatibility issues |
