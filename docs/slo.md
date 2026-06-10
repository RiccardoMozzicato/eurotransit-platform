# SLOs / SLIs for the money path (g03) — Phase 4

> Team-authored. Centered on **checkout** (the critical path). Draft targets below are
> placeholders to be confirmed against measured baselines.

## Checkout success-rate SLO
- **SLI:** fraction of `POST /api/orders` flows that reach `CONFIRMED` (or a correct terminal
  state such as `REJECTED` for genuine sold-out) without a 5xx / internal error, measured at the
  gateway + Orders.
- **SLO (draft):** ≥ 99.0% over a rolling 28-day window.
- **Error budget:** 1.0% → ~6.7h/28d. Burn-rate alerts (fast 1h/5m + slow 6h/30m windows).

## Checkout latency SLO
- **SLI:** time from `POST /api/orders` accepted (202) to `order-confirmed` published,
  p95 (and the synchronous ack latency separately, p99).
- **SLO (draft):** ack p99 ≤ 300 ms; end-to-end confirm p95 ≤ 5 s.

## Where each SLI is measured (decision, 2026-06-10)
- **Ack latency** (`POST /api/orders` → 202): at **Traefik** (edge truth — what the user
  experiences) and at Orders (`http_server_requests`).
- **End-to-end confirm latency** (202 → `CONFIRMED`) and **success rate**: **business metrics
  emitted by Orders**, which owns the order state machine. They cannot be derived from HTTP
  metrics because the flow crosses Kafka stages.
- **Pipeline backlog** (Kafka consumer lag): leading indicator for e2e latency — dashboard /
  diagnostics only, never paged.
- Tracing: **Tempo** behind an **OTel Collector** gateway; trace context propagated through
  Kafka headers (see `platform/observability/README.md`).

## What we deliberately do NOT alert on
- CPU/memory alone (cause-based). We alert on **symptoms** (success-rate / latency burn) tied to
  these SLOs, per the observability lecture.

## RTO (for the CloudNativePG failover experiment)
- **Target (draft):** checkout success-rate recovers to SLO within ≤ 60 s of a primary failover.

_To finalise: instrument SLIs (Micrometer), define Prometheus recording + burn-rate rules,
wire Grafana SLO panels, validate targets against load-test baselines._
