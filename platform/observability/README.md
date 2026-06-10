# Observability (Pillar D) — pinned decisions + Phase 4 work

Continues Lab05. **Decisions pinned during design (team, 2026-06-10 — "Decisione 11"):**

- **Tracing backend: Grafana Tempo** (not Jaeger). Native Grafana integration — traces,
  metrics and dashboards in one UI for the demo ("where did this order spend its time?") —
  and exemplar support (jump from a latency spike in a metric straight to the trace that
  caused it). The track allows either; Jaeger would add a separate UI to operate.
- **OpenTelemetry Collector** as a gateway in the `observability` namespace; services export
  OTLP (4318) and stay backend-agnostic. One place for batching/sampling config.
- **Metrics:** Micrometer → Prometheus (kube-prometheus-stack) via ServiceMonitor/PodMonitor.
- **Dashboards:** money-path overview, per-service **RED**, infra **USE/Golden-Signals**,
  **Kafka consumer lag** (leading indicator of pipeline latency), CNPG. Provisioned **as
  code** from this repo (Grafana sidecar ConfigMaps) — GitOps applies to dashboards too.
- **Alerts:** only **symptom-based multi-window burn-rate** alerts on the two checkout SLOs
  (fast 1h/5m + slow 6h/30m). CPU/memory/lag never page — they stay on dashboards as
  diagnostics ("alert on burn / user-visible symptoms, not CPU").
- **Logs:** structured JSON on stdout with traceId/spanId injected (log↔trace correlation).
  No mandatory aggregation stack (Loki = optional bonus; the track does not require it).
- **Sampling:** 100% + exemplars (demo-scale traffic; real production would discuss
  tail-based sampling — good point for the oral).
- SLI placement is documented in `docs/slo.md`.

**Phase 4 to-do:** kube-prometheus-stack values; Tempo + OTel Collector manifests;
ServiceMonitors for the five services; recording rules + burn-rate alert rules; the
dashboards themselves.
