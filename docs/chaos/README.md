# Chaos-experiment reports

One report per experiment. Each follows the scientific method from the resilience lecture.
Manifests live in `platform/chaos-mesh/`.

Report template (`NN-name.md`):

```
# Experiment NN — <title>

- Steady state (SLIs): <the metrics that define "healthy", with values>
- Hypothesis: <what we expect to remain true under the failure>
- Blast radius / one failure injected: <exactly one variable>
- Method: <Chaos Mesh manifest, duration, load applied>

## Observation
<what our OWN dashboards/traces showed — screenshots/links>

## Conclusion
- Hypothesis held? yes/no
- What we changed if it didn't:
```

Planned (capstone minimum):
1. `01-payments-latency.md` — circuit breaker opens, fallback engages, Catalog stays healthy.
2. `02-inventory-podkill.md` — no oversell / double-charge mid-reservation.
3. `03-node-disruption.md` — PDBs + topology spread keep the critical path available.
4. `04-kafka-partition.md` — async pipeline converges after heal; nothing lost/duplicated.
5. `05-pg-failover.md` — checkout impact + recovery within RTO.
