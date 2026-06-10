# Blameless postmortem — live incident (template)

> To be filled after the live presentation incident. Blameless: focus on the system and the
> signals, not on individuals.

- **Date / duration:**
- **Summary:** (1–2 sentences: what users experienced)
- **Impact:** (SLO/error-budget burned; orders affected; was the "never oversell" invariant held?)

## Timeline (UTC)
| Time | Event | Signal that showed it |
|---|---|---|
| | failure injected | |
| | first alert fired | (which burn-rate alert) |
| | mitigation applied | |
| | recovery confirmed | (SLI back within SLO) |

## What happened
(Steady state → what we injected/observed → how the system responded.)

## Detection
(Which SLI/alert/dashboard/trace surfaced it, and how fast.)

## Recovery
(What we did; RTO observed vs target.)

## What went well / what didn't

## Action items
| Action | Owner | Status |
|---|---|---|
