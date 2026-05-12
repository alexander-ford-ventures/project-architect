---
template_name: REAL_TIME
generate_when: "decisions.realtime.enabled == true"
required_decisions:
  - realtime.protocol
optional_decisions:
  - realtime.broker
  - realtime.presence
  - realtime.scaling_strategy
depends_on: []
revision_triggers:
  - realtime.protocol
  - realtime.broker
---

# Real-Time: {{project_name}}

## Transport Protocol
Chosen transport (WebSocket, SSE, WebRTC, WebTransport, MQTT) with rationale. Note framing/encoding (JSON, MessagePack, protobuf, CBOR) and TLS/QUIC choices.

## Event Types & Schema
Canonical event catalog (type, payload schema, direction client↔server, idempotency expectations). Pulled from the message contracts spec.

## Connection Lifecycle
Auth handshake (token in upgrade, first-message auth), reconnect/backoff strategy, heartbeat/ping intervals, graceful close, resume semantics.

## Presence Model
If applicable: how online status is computed and broadcast, presence storage (Redis pub/sub, Durable Object, Ably/Pusher channel), TTL on stale connections.

## Scaling Strategy
Horizontal scaling pattern: sticky sessions vs stateless workers + broker, fan-out (Redis pub/sub, NATS, Cloudflare Durable Objects, Ably), regional sharding.

## Backpressure & Rate Limits
Per-connection send/receive limits, server-side drop/coalesce policy, slow-consumer handling, abuse detection.

## Revision Log
(none yet)
