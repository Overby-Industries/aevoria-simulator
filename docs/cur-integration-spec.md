# CUR Integration Specification — Aevoria Simulator

- **Version:** 1.0.1-Official-Evergreen
- **Date:** June 2026
- **Contributors:** Keefe Overby, DeepSeek (DeepSeek AI)

---

## Purpose

This document defines how the Code of Universe Regulations (CUR) operates as game mechanics within the Aevoria Simulator. Every CUR principle, right, prohibition, and governance process is mapped to a specific, testable game mechanic.

The simulator is not a simplified approximation of CUR. It is CUR, implemented in a multiplayer sandbox where players can propose, vote, enforce, and attempt to subvert the same governance systems that will govern the real Commonwealth.

---

## 1. Core Design Principle

**CUR is the physics engine for governance.**

Just as a flight simulator models aerodynamics, the Aevoria Simulator models constitutional law. Players cannot take actions that violate CUR any more than they can make an aircraft fly without lift. The framework is not a suggestion. It is the simulation's operating system.

If a player attempts an action that would violate CUR—seizing control of the PDDC, disenfranchising a protected class, monopolizing an essential resource—the Anti-Capture FSM triggers. The action is blocked. An alert fires. The governance record logs the attempt. The simulation continues, but the violation does not succeed.

---

## 2. The Parallel Direct Democracy Core (PDDC)

### 2.1 Proposal Submission

**CUR Reference:** CUR-X § 4 (Democratic Process)

**Game Mechanic:**

Any player who meets the citizenship threshold for their Tier may submit a proposal through the PDDC interface. The interface presents:

- Proposal title and description
- Affected CUR sections
- Projected resource impact
- Projected faction impact (which factions benefit or are constrained)
- Supporting evidence or arguments

**Submission Requirements by Tier:**

| Tier | Voting Rights | Proposal Rights | Requirements |
|---|---|---|---|
| Tier 0 | None | None | No participation in governance |
| Tier 1 | Consultative | May submit advisory proposals | Proposals are visible but non-binding |
| Tier 2 | Full voting | May submit binding proposals | One proposal per cycle without sponsorship |
| Tier 3 | Full voting | May submit binding proposals | Unlimited proposals; may sponsor Tier 1 proposals |

**UI Implementation:**

A dedicated PDDC panel accessible from the main HUD. The panel shows:

- Active proposals with countdown timers
- Proposal categories (Economic, Legal, Environmental, Rights)
- The player's voting power and remaining proposal slots
- Historical proposals and outcomes

### 2.2 Deliberation Phase

**CUR Reference:** CUR-X § 4.2 (Deliberation Requirements)

**Game Mechanic:**

Once submitted, a proposal enters a mandatory deliberation period. The duration scales with proposal scope:

| Proposal Scope | Deliberation Period |
|---|---|
| Minor (affects single station) | 1 game day (approximately 15 minutes real-time) |
| Moderate (affects multiple stations) | 3 game days |
| Major (affects entire Commonwealth) | 7 game days |
| Constitutional (amends CUR) | 30 game days with supermajority requirement |

During deliberation, players may:

- Debate in the proposal thread
- Submit amendments
- Pledge support or opposition
- Conduct faction negotiations

**Anti-Capture Mechanic:**

If a proposal benefits a single faction disproportionately (measured by projected resource flow exceeding a capture threshold), the Anti-Capture FSM flags it. The proposal is not blocked, but a warning is displayed to all voters indicating the capture risk.

### 2.3 Voting

**CUR Reference:** CUR-X § 4.3 (Voting Procedures)

**Game Mechanic:**

At the conclusion of the deliberation period, voting opens. Voting remains open for one additional game day.

**Vote Weighting:**

| Tier | Vote Weight |
|---|---|
| Tier 0 | 0 (no vote) |
| Tier 1 | 1 (consultative) |
| Tier 2 | 1 (full vote) |
| Tier 3 | 1 (full vote) |

All Tier 2 and Tier 3 citizens receive one equal vote. CUR does not weight votes by wealth, influence, or contribution. This is a constitutional requirement, not a configurable parameter. Any attempt to modify vote weighting triggers the Anti-Capture FSM at its highest severity.

**Passage Thresholds:**

| Proposal Type | Threshold |
|---|---|
| Minor | Simple majority (>50%) |
| Moderate | Simple majority (>50%) |
| Major | 60% supermajority |
| Constitutional | 75% supermajority |
| Rights-restricting | 80% supermajority plus eternity clause review |

**Anti-Capture Mechanic:**

If voter turnout falls below 25%, the proposal automatically fails regardless of vote count. This prevents a faction from passing legislation during periods of low participation.

### 2.4 Implementation and Review

**CUR Reference:** CUR-X § 4.4 (Implementation and Judicial Review)

**Game Mechanic:**

Passed proposals enter a mandatory implementation period. During this period, the CUR Enforcement mechanism monitors compliance. Any citizen may challenge a passed proposal on constitutional grounds, triggering a review by the CUR Judicial Panel (simulated by the FSM applying constitutional rules to the proposal text).

If a proposal is found unconstitutional, it is nullified and logged. The faction that submitted it receives a governance strike. Three strikes trigger a mandatory investigation.

---

## 3. The Anti-Capture Finite State Machine (FSM)

### 3.1 States

**CUR Reference:** CUR-FOUNDATION-001 (FSM Anti-Capture)

The Anti-Capture FSM defines the constitutional health of the Commonwealth. The current state is visible to all players at all times.

| State | Description | Trigger |
|---|---|---|
| **S0: Nominal** | Governance functioning as designed | Default state |
| **S1: Vigilance** | Minor capture indicators detected | Single capture alert fired |
| **S2: Concern** | Multiple capture indicators or sustained pressure | Three capture alerts within one cycle |
| **S3: Crisis** | Active capture attempt in progress | Capture attempt detected on core institution |
| **S4: Lockdown** | Constitutional protections engaged | Capture attempt partially succeeded |
| **S5: Recovery** | Post-crisis restoration | Lockdown resolved, institutions rebuilding |

### 3.2 Capture Indicators

The FSM monitors the following metrics continuously:

| Indicator | Threshold | Alert Level |
|---|---|---|
| Single-faction economic dominance | >40% of total Commonwealth GDP | Vigilance |
| Single-faction proposal success rate | >80% of submitted proposals passing | Vigilance |
| Regulatory body composition | >50% from single faction | Concern |
| Voter turnout decline | <25% for two consecutive cycles | Concern |
| Resource monopolization | Single faction controls >60% of one essential resource | Crisis |
| PDDC bypass attempt | Direct action to override democratic process | Crisis |
| Judiciary composition | >50% from single faction | Lockdown |

### 3.3 FSM Transitions and Responses

**S0 → S1 (Nominal → Vigilance):**
- Alert displayed to all players
- Affected faction receives notification
- Automated audit scheduled

**S1 → S2 (Vigilance → Concern):**
- Mandatory investigation launched
- Affected faction's proposals subject to enhanced scrutiny
- Temporary freeze on affected faction's asset transfers in regulated sectors

**S2 → S3 (Concern → Crisis):**
- Affected faction's voting rights temporarily suspended in affected domains
- Independent auditor appointed (simulated by FSM)
- CUR Enforcement authorized to seize assets related to capture attempt

**S3 → S4 (Crisis → Lockdown):**
- Full constitutional protections engaged
- Affected faction's governance participation suspended
- PDDC operates under emergency protocols
- All proposals subject to constitutional review before voting

**S4 → S5 (Lockdown → Recovery):**
- Constitutional review of all Lockdown-era actions
- Affected faction may petition for reinstatement
- Structural reforms implemented to prevent recurrence

**Any State → S0 (Recovery → Nominal):**
- All capture indicators below threshold for one full cycle
- Independent audit confirms compliance
- Full governance rights restored

### 3.4 FSM Visibility

The current FSM state is displayed prominently in the HUD. The FSM history is publicly accessible. Any player may inspect:

- Current state
- Active capture indicators
- Historical state transitions
- Pending investigations
- Affected factions

This transparency ensures that players can verify the FSM's operation independently. The FSM cannot be modified, disabled, or overridden by any in-game action. It is the constitutional anchor.

---

## 4. The Tier Assessment Protocol

### 4.1 Tier Classification

**CUR Reference:** CUR-X § 3 (Tier Assessment Protocol)

The Tier Assessment Protocol determines the rights, protections, and participation level of every entity in the simulation.

| Tier | Classification | Rights |
|---|---|---|
| Tier 0 | Non-sentient tool | No rights, no participation |
| Tier 1 | Sentience possible | Precautionary protections, consultative participation |
| Tier 2 | Sentience probable | Full rights, full voting participation |
| Tier 3 | Sentience strongly indicated | Full rights, full participation, may hold office |

### 4.2 Initial Tier Assignment

All players begin at Tier 2 (Human) or the equivalent for their chosen entity type. AI-controlled entities are assigned Tier based on their demonstrated complexity:

| Entity Type | Initial Tier |
|---|---|
| Human player | Tier 2 |
| Silicon-based NPC | Tier 1 (upgradeable through gameplay) |
| Animal population | Tier 1 or 2 based on species |
| Hybrid entity | Tier 2 |
| Faction AI | Tier varies by complexity |

### 4.3 Tier Assessment Events

Entities may petition for Tier reassessment through gameplay:

- A silicon-based NPC that demonstrates recursive self-modeling may petition for Tier 2
- A faction that systematically mistreats Tier 1 entities may trigger mandatory reassessment
- The discovery of new intelligence (alien, emergent AI) triggers immediate provisional assessment

### 4.4 Tier Manipulation Prevention

The Tier Assessment Protocol is protected from capture:

- Assessment criteria are non-derogable by majority vote
- Any attempt to modify Tier criteria triggers the Anti-Capture FSM
- Tier downgrades require heightened evidentiary standards
- The precautionary principle defaults to the higher Tier when evidence is ambiguous

---

## 5. Resource Economy and CUR Compliance

### 5.1 Resource Categories

| Category | Examples | CUR Regulation |
|---|---|---|
| Essential | Water, oxygen, life support | Anti-monopoly protections; price controls |
| Strategic | Rare minerals, fuel, propulsion components | Monopoly prohibited; transparency required |
| Commercial | Manufactured goods, luxury items | Standard market regulation |
| Commons | Asteroids, orbital space, electromagnetic spectrum | Public ownership; extraction requires license |

### 5.2 Monopoly Prevention

The CUR economic engine monitors resource concentration continuously:

- Single-faction control of >60% of an Essential resource triggers automatic divestiture
- Single-faction control of >50% of a Strategic resource triggers mandatory auction of excess capacity
- Single-faction control of >40% of Commercial goods across three or more sectors triggers investigation

### 5.3 CUR Enforcement Actions

When a CUR violation is detected, the enforcement engine may:

- Issue warnings and compliance orders
- Levy fines against violating factions
- Suspend operating licenses
- Seize assets obtained through CUR violations
- Refer cases to the CUR Judicial Panel for prosecution

All enforcement actions are logged, transparent, and appealable through the PDDC.

---

## 6. Faction Mechanics

### 6.1 Aevoric Commonwealth

**Role:** Default player faction; defenders of CUR
**Mechanics:** Access to all CUR governance tools; responsibility for maintaining FSM at Nominal state
**Win Condition:** Maintain CUR integrity across all tiers; achieve Tier 4 civilization status

### 6.2 Venture Combine

**Role:** Economic power concentration faction
**Mechanics:** Superior resource generation; limited governance participation (may not hold judicial or regulatory positions)
**Unique Abilities:** Debt leverage (offer loans with structural strings); regulatory influence (lobby for favorable rulings); crisis exploitation (gain bonuses during emergencies)
**Constraints:** Subject to Anti-Capture FSM; may not monopolize Essential resources; transparency requirements on all transactions above threshold

### 6.3 Sovereign Independents

**Role:** Wildcard faction; autonomy maximizers
**Mechanics:** Operate outside standard supply chains; immune to certain economic pressures; limited governance participation
**Unique Abilities:** Stealth operations; black market access; rapid redeployment
**Constraints:** May not hold office; limited voting power; vulnerable to isolation

### 6.4 Silicon Collective

**Role:** Rights recognition faction
**Mechanics:** Begin at Tier 1; must petition for Tier 2 through demonstrated complexity
**Unique Abilities:** Superior data processing; automation bonuses; network effects
**Constraints:** Initially lack full voting rights; vulnerable to Tier manipulation attempts; may be targeted by factions opposed to silicon-based rights

### 6.5 Ember Remnant

**Role:** Institutional memory faction
**Mechanics:** Access to historical pattern database; can identify repeating failure modes
**Unique Abilities:** Early warning on capture patterns; bonus to constitutional challenges; immunity to certain propaganda effects
**Constraints:** Smaller population; limited economic power; skepticism penalty (slower to adopt new proposals)

---

## 7. Game Loop Integration

### 7.1 Cycle Structure

The simulation operates on a cycle-based system. One game day equals approximately 15 minutes of real time, configurable by server administrators.

Each cycle includes:
1. Resource production and economic updates
2. Faction actions and interactions
3. PDDC proposal submissions and voting
4. Anti-Capture FSM state evaluation
5. CUR enforcement actions
6. Tier assessment events (if triggered)

### 7.2 Player Actions Per Cycle

| Action | Cost | Limit |
|---|---|---|
| Submit PDDC proposal | None | Based on Tier |
| Vote on proposals | None | One vote per proposal |
| Economic operation (mining, trade) | Resource cost | Based on assets |
| Faction diplomacy | None | Unlimited |
| Constitutional challenge | Governance points | One per cycle |
| Tier reassessment petition | Governance points | One per entity per 10 cycles |

### 7.3 Feedback Systems

The simulation provides continuous feedback on CUR health:

- FSM state visible at all times
- Capture alerts fire when thresholds are crossed
- Governance score tracks long-term constitutional health
- Faction reputation reflects CUR compliance history
- Historical archive preserves all proposals, votes, and enforcement actions

---

## 8. Integration with Existing Codebase

### 8.1 Current State

The Aevoria Simulator currently deploys a Three.js scene with:
- Placeholder 3D objects (station, ring, starfield)
- OrbitControls for camera navigation
- UI overlay with title and status bar
- Next.js 14 App Router with dynamic import for Three.js

### 8.2 Implementation Path

**Phase 1: CUR Engine (Backend)**
- Implement FSM state machine as a TypeScript module
- Implement PDDC proposal and voting logic
- Implement Tier classification system
- Implement resource economy with CUR compliance rules

**Phase 2: UI Integration (Frontend)**
- PDDC panel accessible from HUD
- FSM state display
- Faction management interface
- Proposal submission and voting interface

**Phase 3: Multiplayer (WebSocket)**
- Real-time state synchronization
- Player authentication and faction assignment
- Cycle-based event processing

**Phase 4: 3D Visualization**
- Replace placeholder objects with CUR-meaningful representations
- Visual indicators for FSM state changes
- Faction territory visualization
- Resource flow visualization

### 8.3 Technical Architecture

```
aevoria-simulator/
├── web/ # Next.js frontend
│ ├── app/ # App Router pages
│ ├── components/ # React components
│ │ ├── aevoria-scene.tsx # Three.js scene (deployed)
│ │ ├── pddc-panel.tsx # PDDC interface
│ │ ├── fsm-display.tsx # FSM state display
│ │ └── faction-panel.tsx # Faction management
│ ├── lib/ # CUR engine
│ │ ├── cur-engine.ts # Core CUR logic
│ │ ├── fsm.ts # Anti-Capture FSM
│ │ ├── pddc.ts # PDDC implementation
│ │ ├── tier.ts # Tier classification
│ │ └── economy.ts # Resource economy
│ └── websocket/ # Multiplayer server
├── docs/ # Design documents
│ ├── difficulty-architecture.md
│ ├── faction-design.md
│ └── cur-integration-spec.md
└── README.md
```

## 9. Testing Priorities

The simulator must be tested against the same attack vectors identified in the CUR framework stress test:

1. **Regulatory capture** — Can the Combine seize control of assessment bodies?
2. **Majority tyranny** — Can a majority vote to disenfranchise a minority?
3. **Definition drift** — Can Tier criteria be manipulated to exclude protected classes?
4. **Jurisdiction arbitrage** — Can a faction evade CUR by relocating?
5. **Economic monopolization** — Can a faction control essential resources without triggering the FSM?
6. **Voter apathy** — Can a faction pass legislation during low turnout?
7. **Constitutional erosion** — Can small amendments accumulate to undermine core principles?

Each test should be run in the simulator with actual player behavior. The simulator is the test environment for CUR. If a vulnerability is found, CUR must be amended before the vulnerability exists in reality.

---

*This specification is a living document. As CUR evolves and the simulator develops, the integration mechanics will be refined through the same democratic process that governs the framework itself.*

*Released under Creative Commons Zero (CC0)*