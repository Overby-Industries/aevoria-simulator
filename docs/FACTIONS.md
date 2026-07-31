# Factions

Working lore reference for level design. The mechanical distinction between
the three factions (`level_catalog.gd`'s `AEVORIA_COMMONWEALTH` /
`OLIGARCH_COMBINE` / `NOMAD_FLOTILLA`) already encodes most of this; this
document is the reasoning behind it so future levels stay consistent
without re-deriving it each time.

There are no military mechanics anywhere in this game, on purpose. CUR has
no army. Every consequence in this game is one of: a score moving
(VCI/CRI), a violation logged, a sanction from CUR-X.4 §4.9(b)
(restructuring, authorisation suspension/withdrawal), or a loss of
standing -- becoming, functionally, a pariah. That constraint is the whole
design problem these three factions solve differently.

## Aevoria Commonwealth

The CUR-chartered polity. Citizenship means every operational licence,
every mining charter, every institution runs through the compliance FSM
by default -- not because a soldier makes them, but because standing
inside the Commonwealth *is* being inside CUR's jurisdiction. The existing
levels (First Violation, The Reef's Advocate, The Standing Review) are all
this: what it looks like to operate somewhere CUR's full machinery
applies from the start.

## Oligarch Combine

Not Commonwealth citizens. The Combine is a corporate-captured
sovereignty of its own -- a separate Earth-descended government, run the
way concentrated capital runs a government when nothing checks it. They
have their own courts, their own currency, their own laws, and none of
those are CUR's business.

What *is* CUR's business: CUR's jurisdiction is resource-and-conduct
based, not citizenship-based (see `governance_level.gd`'s note that "every
entity that touches shared resources runs through the CUR compliance
FSM"). The moment a Combine charter extracts from a Commonwealth-adjacent
claim, trades into the Commonwealth commons, or otherwise touches shared
resources CUR administers, that conduct is inside CUR's reach even though
the Combine itself never signed on to anything. That's why
`oligarch_boardroom.gd` scores the Combine on Capture Risk (CRI) at all --
CRI's own text is explicit that it applies "on the same basis as
concentration within a governance institution" (CUR-X.4 §4.2(d)), which is
exactly the hook that lets CUR see a corporation the same way it sees a
captured agency.

The Commonwealth would clearly prefer the Combine bind itself to CUR
outright. It has no way to make that happen -- no military, no
extradition, nothing but §4.9(b)'s toolbox: restructuring, authorisation
suspension, authorisation withdrawal. Run the Combine's CRI up far enough
against confirmed determinations and the endpoint is authorisation
withdrawn entirely -- at which point a Combine operator has no standing
left to lose and functionally converges with the Flotilla's condition:
outside CUR, unprotected, a pariah. That's the arc "Boardroom Capture"
sets up for later levels: keep choosing the corrupt option and the place
you end up isn't punishment, it's exile.

## Nomad Flotilla

Rejects both governments. Not Commonwealth, not Combine-aligned -- the
Flotilla works the parts of Earth's nomadic regions and deep space that
neither government administers, on purpose, so neither one's jurisdiction
ever attaches. They don't touch Commonwealth-shared resources or Combine
markets in any way CUR or anyone else's courts can see.

That's a harder trade than it looks. Staying outside CUR's reach means
CUR literally cannot see them -- not "won't help," *can't*, the same way
`update_capture_risk` never gets called against an entity that was never
registered. No CRI, no advocate system (CUR-E §1.6 has nothing to
appoint for), no obligation register protecting them the way CUR-H.7
protects a Commonwealth citizen under restriction. Pariah status isn't a
sanction imposed on the Flotilla -- it's what's left when nobody's
jurisdiction reaches you at all: no protection either. `the_long_drift.gd`
is built around that directly -- the only score that exists for a Nomad
run is the Flotilla's own Vital Continuity Index, because nobody else is
keeping a ledger on their behalf.

## Why this shape, not a military one

A "the Commonwealth defeats the Combine" story is a war game with CUR
skinning on top. What's actually interesting here -- and the reason CUR
exists as a diagnostic-only, no-gating system throughout this codebase
(`VitalContinuityModel::may_gate_service_access()` and the capture-risk
equivalent both return `false` unconditionally, on purpose) -- is a
world where the only lever against concentrated power is *visibility plus
standing*: sanctions, exile, refusal to recognize a claim. No tanks. That
constraint is what makes the Combine's arc worth building out (how far can
a captured institution go before it loses recognized standing entirely?)
and the Flotilla's arc worth building out (what does staying permanently
unrecognized actually cost, leg after leg?) instead of just being a reskin
of each other.
