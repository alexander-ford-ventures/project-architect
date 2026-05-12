---
template_name: CACHING_STRATEGY
generate_when: "decisions.scale >= \"growth\" OR decisions.caching.enabled == true"
required_decisions: []
optional_decisions:
  - caching.edge
  - caching.app_cache
  - caching.db_cache
  - caching.invalidation_strategy
depends_on: []
revision_triggers:
  - caching.edge
  - caching.app_cache
  - caching.db_cache
---

# Caching Strategy: {{project_name}}

## Cache Layers
Overview of every cache layer in the stack (edge → app → DB → client) with the role each plays, the TTL class, and the owner of invalidation.

## CDN Caching
CDN provider (Cloudflare, Fastly, CloudFront, Vercel Edge), what's cached at the edge (static assets, HTML, API responses, images), cache keys, surrogate keys, and ESI/edge-functions usage.

## Application Cache
In-process (LRU/SWR), shared Redis/Valkey/Memcached, or platform cache (Vercel Cache, Cloudflare Cache API). Document hot keys, eviction policy, and serialization format.

## Database Query Cache
DB-level caching choices (Postgres prepared statements, MySQL query cache off, materialized views, pg_repack), connection-level pooled caches, ORM query cache configuration.

## Invalidation Strategy
TTL-only, event-driven (write → publish invalidation), tag-based (Cloudflare cache tags, Vercel cache tags), version/cache-buster, or hybrid. Document who owns the invalidation event and how races are handled.

## Cache-Warming
Pre-warm strategies (cron, build-time, on-deploy, request-driven), warm-cache deployment policy, cold-start mitigation.

## Monitoring
Hit-rate dashboards per layer, miss-cost dashboards, alerting thresholds, sampling for stampede/thundering-herd detection.

## Revision Log
(none yet)
