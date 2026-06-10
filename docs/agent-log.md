# Agent verification log

> Capstone rule: agentic tools are permitted and encouraged, but the team must **verify** and
> **show where the agent was wrong**. This log records concrete cases where an agent-produced
> artifact was incorrect, unsafe, or subtly wrong, and how we caught and corrected it.
> *Finding the agent's mistakes is the core skill the capstone certifies.*

Format per entry: **what the agent produced → why it was wrong → how we caught it → the fix**.

---

## 1. Helm template syntax leaked into a plain (non-templated) manifest

- **Produced:** `platform/strimzi/kafka-topics.yaml` with a Helm comment
  `{{- /* ... */}}` at the top. These topics are applied directly at platform bootstrap, not
  rendered by Helm.
- **Why wrong:** outside a Helm chart, `{{ ... }}` is not interpreted — it stays as literal
  text and makes the YAML invalid, so `kubectl apply -f` would fail. The agent reused a Helm
  idiom out of its valid context.
- **How caught:** reviewer noticed the file lives under `platform/` (applied with kubectl),
  not under `deploy/charts/` (rendered by Helm).
- **Fix:** replaced the Helm comment with a plain `#` YAML comment.

## 2. Resilience4j starter pinned without verifying Spring Boot 4 compatibility

- **Produced:** `orders` and `payments` `build.gradle.kts` depend on
  `io.github.resilience4j:resilience4j-spring-boot3:2.3.0` while the project targets
  **Spring Boot 4.0.3**.
- **Why potentially wrong:** the `-spring-boot3` starter is published for the Boot 3 line; its
  auto-configuration may not bind on Boot 4 (package/auto-config relocation). Accepting the
  version blindly risks a context-startup failure or silently inactive circuit breakers.
- **How caught:** flagged at authoring time — annotated directly in the build file as
  "verify on first build".
- **Fix (pending Phase 2):** confirm at first `./gradlew build`; if incompatible, switch to a
  Boot-4-compatible Resilience4j release or wire CircuitBreaker/Retry programmatically via the
  core modules.
- **Resolution (2026-06-10): RESOLVED with evidence.** A green `contextLoads` was judged
  insufficient (the auto-configuration could back off silently, leaving `@CircuitBreaker`
  annotations inert), so we added a build-breaking assertion in `OrdersApplicationTests`
  that the `CircuitBreakerRegistry` bean actually exists. It passes on Spring Boot 4.0.3 +
  Resilience4j 2.3.0. Functional open/half-open behaviour is still to be exercised by a
  dedicated test in Phase 2.

## 3. (Reserved) readiness vs liveness probe scoping

- **Watch item:** an agent commonly proposes a `livenessProbe` that transitively checks a
  downstream dependency (DB/Kafka), which causes cascading restarts during a transient
  downstream blip — the exact anti-pattern the capstone calls out.
- **Our current stance:** liveness checks only `/actuator/health/liveness` (process self);
  readiness includes the owned DB (`group.readiness: readinessState,db`) but **not** Kafka, so
  broker blips don't flap the sync entry API. To be re-verified once handlers exist and during
  the latency/partition chaos experiments.
- **Status: OPEN** until validated under chaos.

## 4. Thin `justfile` that ignored the team's established Lab01 convention

- **Produced:** an initial `justfile` with only `test`/`build`/`run`/`image` shortcuts — no
  local DoD verification, no `docker-run`/`docker-stop`/`health-check`, no `.dockerignore`.
- **Why wrong:** Lab01 **explicitly required** (Step 2 + Step 4 + DoD item 4) the `justfile` to
  be the "versioned interface for recurring tasks" with a single recipe that verifies the DoD
  locally end-to-end (build → test → image → run → wait → health → cleanup), and Step 3
  explicitly required a `.dockerignore`. The team's own Lab01 `justfile` already did all this
  (`verify-local`, `act-ci`, JaCoCo, hooks). The agent produced something below the team's own
  established standard.
- **How caught:** teammate flagged that the Lab01 `justfile` was richer; we re-read the Lab01
  brief and confirmed the convention was prescribed, not optional.
- **Fix:** rewrote the `justfile` with `set shell`, `docker-run`/`docker-stop`/`health-check`,
  and a `verify <svc>` / `verify-all` 7-step DoD flow with `trap` cleanup (adapted to 5 services,
  no frontend); added `.dockerignore` to every service. Validated with `just --list`.

## 5. "HA" databases that silently used asynchronous replication — RPO > 0 on the invariant store

- **Produced:** `databases.yaml` Cluster CRs labelled "money path → HA" with `instances: 2`,
  relying on CloudNativePG's **default asynchronous replication**.
- **Why wrong (subtly):** with async replication a primary failover can lose the last
  committed transactions (RPO > 0). For inventory this breaks the exact invariant the design
  claims to protect: a committed reservation can vanish on failover, the seat counter rolls
  back, and the seat is sold twice — "never oversell" would fail precisely under chaos
  experiment #5 (CNPG primary failover). The atomic conditional UPDATE protects against
  *concurrency*, not against *losing committed state*. "More instances" looked like more
  safety while the consistency claim (CP / PC-EC) was not actually implemented.
- **How caught:** design review of the configuration against our own PACELC statement
  ("best configuration" pass, 2026-06-10): we asked "what does a failover do to a committed
  reservation?" and the default answer was "it can disappear".
- **Fix:** `inventory-db` → synchronous replication (3 instances, ANY 1,
  `dataDurability: required`, RPO=0; writes block if the primary is isolated — consistency
  over availability, as stated). `orders-db` → synchronous `preferred` (RPO=0 while healthy,
  degrades to async rather than blocking intake). Documented in `design.md` §4.12; requires
  CNPG ≥ 1.25.

## 6. Lost state transitions: `@Modifying(clearAutomatically = true)` silently dropped unflushed entity changes

- **Produced:** `InventoryService.release()` set `reservation.status = RELEASED` (relying on
  Hibernate dirty checking) and then called the bulk-update `restock()`, whose
  `@Modifying(clearAutomatically = true)` **cleared the persistence context before the status
  change was ever flushed**. The transition was lost: the row stayed `RESERVED` in the DB, so
  a second `release()` restocked the seats AGAIN — double restock, phantom availability,
  oversell risk from the compensation path. Same latent bug in `confirm()` (expired branch)
  and in the reconciler sweep (which would have re-expired the same holds every pass).
- **Why subtle:** every individual piece looks correct; the bug is the *ordering interaction*
  between dirty checking and bulk-update context clearing. The happy-path tests all passed —
  only the idempotency test (`release restocks and is idempotent`, expected 10, got 14)
  exposed it.
- **How caught:** the test suite written alongside the code (2026-06-10), specifically the
  idempotent-replay assertions. This is why idempotency tests are non-negotiable on the
  money path.
- **Fix:** `flushAutomatically = true` on the bulk updates, explicit `save()` of transitions
  before any bulk update, and the sweep persists ALL transitions before the first restock
  (the clear detaches the remaining entities mid-loop). All 12 inventory tests green,
  including 8-thread last-seat and concurrent-duplicate races.

---

_Add new entries as they happen. Aim well past the required three; every caught mistake is
evidence of ownership._
