---
template_name: BACKGROUND_JOBS
generate_when: "decisions.background_jobs.enabled == true"
required_decisions:
  - background_jobs.queue
optional_decisions:
  - background_jobs.scheduling
  - background_jobs.idempotency
  - background_jobs.retry_policy
depends_on: []
revision_triggers:
  - background_jobs.queue
  - background_jobs.scheduling
---

# Background Jobs: {{project_name}}

## Queue / Broker Choice
Selected queue/broker (Inngest, Trigger.dev, Temporal, BullMQ + Redis, SQS, Cloudflare Queues, RabbitMQ, Sidekiq, Celery) with rationale, hosting model, and ordering/exactly-once semantics.

## Job Types
Table: job | trigger | frequency | priority | owner. Pulled from `background_jobs.*` decisions. Marks long-running, fan-out, and CPU/memory-heavy jobs.

## Idempotency Strategy
Idempotency-key conventions (per-event, per-business-action), dedupe window/storage, replay-safety guarantees, side-effect compensation when needed.

## Retry Policy
Per-job retry budgets, backoff curve (exponential with jitter), max attempts, partial-progress checkpointing, retryable vs terminal error classification.

## Dead-Letter Queues
DLQ destination, alerting on entry, re-drive tooling, manual-resolution UX, retention policy on dead jobs.

## Scheduling
Cron-style recurring jobs vs event-driven, durable scheduling layer, time-zone handling, drift/missed-run policy, distributed-lock strategy to prevent duplicate fires.

## Concurrency Limits
Global, per-tenant, and per-queue concurrency caps, fair-scheduling rules, autoscaling signal (queue depth, age, latency).

## Monitoring
Per-job latency/error dashboards, queue-depth alerts, oldest-pending-message age, success-rate SLOs, integration with the broader observability stack.

## Revision Log
(none yet)
