# Chaos Mesh experiments (Phase 6)

One manifest per hypothesis. Each experiment follows the scientific method: define steady
state (the SLIs), state a hypothesis, inject **one** failure, observe, conclude. Reports live
in `docs/chaos/`.

Planned experiments (capstone minimum):

1. `payments-latency.yaml` — latency injection into Payments → Orders circuit breaker opens,
   fallback engages, Catalog browsing stays healthy.
2. `inventory-podkill.yaml` — pod kill on Inventory mid-reservation → idempotency + atomic
   reservation prevent oversell / double-charge.
3. `node-disruption.yaml` — node/AZ-style disruption → PDBs + topology spread keep the
   critical path available.
4. `kafka-partition.yaml` — network partition / Kafka disruption → async pipeline recovers
   and converges once healed; nothing lost or duplicated.
5. `pg-failover.yaml` — kill the CloudNativePG primary → observe checkout impact and recovery
   within the stated RTO.
