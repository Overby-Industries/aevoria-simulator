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
```

## 3. Core Message Types
Governance & Democracy

- `proposal_submit` – Citizen submits a new proposal
- `proposal_update` – Proposal status changed
- `vote_cast` – Player casts a vote
- `vote_results` – Results after voting period

Finite State Machine (CUR Integration)

- `fsm_state_update` – Current FSM state of the Commonwealth
- `fsm_fault` – A Fault has been triggered
- `fsm_protected_mode` – System entered Protected (Safe) Mode
- `fsm_recovery` – Recovery from Protected Mode

Simulation State

- `simulation_tick` – Periodic full state snapshot
- `mining_update` – Helga SSTO + miner swarm status
- `economy_update` – Resource levels, Commons Reserve, dividends
- `faction_activity` – Billionaire class or other faction actions

Player / Entity Events

- `citizen_action` – General player action
- `audit_request` – Player or AI requests audit
- `sanction_proposed` – Proposal to sanction an entity


## 4. Example Messages
FSM Fault Example

```
JSON{
  "type": "fsm_fault",
  "version": "0.1",
  "timestamp": "2026-05-19T15:32:10Z",
  "payload": {
    "faultId": "FC-47291",
    "category": "capture_attempt",
    "description": "Coordinated attempt to bypass Type A entrenched provision",
    "affectedDomain": "General_Assembly",
    "actionTaken": "reverted_to_safe_state",
    "protectedModeDuration": 7200
  }
}
Mining Update Example
JSON{
  "type": "mining_update",
  "payload": {
    "helgaStatus": "in_transit",
    "minerSwarmsActive": 12,
    "resourcesExtracted": {
      "nickelIron": 12450,
      "pgms": 87,
      "volatiles": 3420
    },
    "containmentIntegrity": 98.7
  }
}
```