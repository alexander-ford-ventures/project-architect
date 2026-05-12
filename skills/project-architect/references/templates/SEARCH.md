---
template_name: SEARCH
generate_when: "decisions.search.enabled == true"
required_decisions:
  - search.engine
optional_decisions:
  - search.indexing_strategy
  - search.faceting
  - search.semantic
  - search.relevance_tuning
depends_on: []
revision_triggers:
  - search.engine
  - search.indexing_strategy
---

<!--
Author: Vladimir Dukelic <vladimir@dukelic.com>
Repository: https://github.com/siliconyouth/project-architect
License: MIT
-->

# Search: {{project_name}}

## Search Engine Choice
Engine selected (Postgres FTS, Meilisearch, Typesense, Algolia, Elasticsearch, OpenSearch, Turbopuffer) with rationale, hosting model, and license/cost considerations.

## Indexing Strategy
Synchronous (write-through), asynchronous (queue/CDC), or scheduled batch reindexing. Document source-of-truth → index pipeline and consistency guarantees.

## Index Schema
Per-collection schema: field types, tokenizers/analyzers, synonyms, stop-words, language analyzers, stored vs searchable fields.

## Query Patterns
Supported query shapes (full-text, prefix, faceted/filtered, geo, semantic/vector, hybrid lexical+vector). Document the public query DSL exposed to clients.

## Relevance Tuning
Boosts, business rules, personalization signals, learning-to-rank if any, click-data feedback loop.

## Performance Targets
p50/p95/p99 query latency, index-build time, indexing throughput, expected QPS. Link to `PERFORMANCE_BUDGETS.md`.

## Reindexing Strategy
Zero-downtime reindex (dual-write + alias swap), schema-evolution playbook, backfill order, snapshot/restore.

## Revision Log
(none yet)

---

*Skillfully made with [project-architect](https://github.com/siliconyouth/project-architect).*
