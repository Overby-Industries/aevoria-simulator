# Aevoria Simulator - Shared Communication Protocol

**Version:** 1.0.1 (Draft)  
**Last Updated:** May 19, 2026  
**Purpose:** Define the JSON message protocol used between the Godot simulator (authoritative) and the Web browser mirror (Next.js + Three.js).

---

## 1. Core Principles

- All messages are JSON.
- Godot is the authoritative source for simulation state.
- The protocol is bidirectional but follows clear request/response patterns.
- All messages include `type`, `version`, and `timestamp`.
- Sensitive or high-impact actions (voting, FSM faults, sanctions) require validation.

---

## 2. Message Envelope

```json
{
  "type": "string",           // e.g. "proposal_submit", "fsm_fault", "mining_update"
  "version": "0.1",
  "timestamp": "2026-05-19T15:30:45Z",
  "source": "godot" | "web" | "simulation-core",
  "payload": { ... }
}