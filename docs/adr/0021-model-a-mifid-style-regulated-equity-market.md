# 0021. Model a MiFID II-style regulated equity market

- **Status:** Accepted
- **Date:** 2026-09-26

## Context

The domain is a securities exchange ([0001](0001-record-architecture-decisions.md)).
Payments were considered and left out: they are ledger-centric, while this project
focuses on high-volume event streaming first. The market model determines the event flow,
the regulatory mapping and the operational rhythm. The model should follow widely
referenced international rules rather than a single national rulebook, so that it is
recognisable to readers from any market.

## Options

| Option | Pros | Cons |
|---|---|---|
| MiFID II-style EU regulated market (continuous trading with volatility interruptions, as on major European venues) | Comprehensive, public rulebook (MiFID II/MiFIR, RTS 11 tick sizes, circuit breakers, RTS 25 clocks); trading hours give maintenance windows | Auctions add complexity if modelled |
| US-style market (Reg NMS, limit up-limit down) | Largest equity market | Rules are tied to a fragmented, multi-venue national market system |
| Single national venue rulebook | Very concrete | Less recognisable internationally |
| Crypto exchange (24/7) | Continuous high volume | No maintenance window; lighter regulation to learn from |

## Decision

Model a **MiFID II-style regulated equity market** with synthetic instruments and
participants (no real market data):

| Rule | Model |
|---|---|
| Trading phases | Pre-trading (orders accepted, no matching) → continuous trading → closed. Opening/closing auctions are a later extension |
| Tick sizes | Tick-size table by price range and liquidity band, inspired by the MiFID II tick-size regime (RTS 11) |
| Volatility controls | Static and dynamic price corridors; a breach triggers a volatility interruption (instrument halt, then resume), inspired by MiFID II Art. 48(5) circuit breakers |
| Order types | Limit and market; day validity; cancel and modify |
| Timestamps | UTC with microsecond granularity, inspired by RTS 25 clock synchronisation |
| Settlement | Post-trade positions with a configurable settlement cycle: T+2 today, T+1 when the EU moves on 11 October 2027 (CSDR amendment). Records only, no cash movement |
| Clock | Simulated clock can run faster than real time so full trading days fit a benchmark run |

## Consequences

- Trading phases drive operations: upgrades and maintenance are planned for the closed
  phase, and HA must hold during continuous trading.
- Tick-size and price-corridor checks are pre-trade controls with tests; volatility
  interruptions are events that every downstream consumer must handle.
- Switching the settlement cycle from T+2 to T+1 is a real, dated change scenario for the
  lifecycle phase.
- Auctions can be added later as their own ADR without changing the pipeline.
