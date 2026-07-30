# Multiplayer roadmap (not yet built)

Aevoria's vision (see [README.md](../README.md)) is a game where the Aevoric
Commonwealth defends its democracy against the Oligarch Syndicate through
real collective action — quadratic voting, reputation-weighted consensus,
an actual community deciding things together. **None of that exists yet.**
Today the game is entirely single-player: every session's state is a local
file, and "governance" is a scripted tutorial one player walks through
alone. This doc exists so that gap is a known, planned thing rather than a
surprise the next time someone reads the README's promises against the
actual code.

**Deliberately deferred.** The priority right now is making the
single-player game robust and shipping: multiplayer is a large,
infrastructure-heavy addition, and building it before the core loop is
solid risks stalling on something that doesn't ship. This doc is here so
that when the time comes, it's an additive layer on what already exists,
not a rewrite.

## What's true today (the actual current architecture)

- **All player progress is a local file.** `faction_home_base.gd` reads/writes
  `user://factions/<faction_id>.json` — banked commons resources, completed
  levels. There's no server-side copy, no sync, nothing another player could
  see. (Only one faction exists today — `aevoria_commonwealth` in
  `level_catalog.gd` — but the API is already keyed by `faction_id`, so more
  factions competing/allying is a smaller step than voting is.)
- **The CUR compliance engine (`CURComplianceMonitor`, C++) is per-session
  and in-process.** `governance_level.gd`/`advocate_level.gd` register an
  entity, submit events (`monitor.submit_operational(...)`), and read the
  FSM's compliant/violation result back — entirely within one running game,
  gone the moment it closes. There is no concept of "the community" feeding
  events into it; only the one player in that session does.
- **"Voting" doesn't exist as a mechanic anywhere in the codebase** — grep
  for `vote`/`proposal` and the only hits are unrelated alarm-trigger
  scripts. The quadratic-voting/reputation-consensus language in the README
  is the vision, not a built feature.
- **There already is a real shared backend, just not used for this.**
  `aevoria_auth.gd` logs the Godot client into the *same Supabase project
  and account* as the web app (`web/`), and already does authenticated
  `HTTPRequest` calls against it (`fetch_owned_skins()` is the clearest
  worked example — GET `%s/rest/v1/purchases?select=...` with an
  `Authorization: Bearer` header, parsed via a `request_completed` signal).
  This is the seam multiplayer governance would actually hook into.
- **There's also a precedent for public, unauthenticated, community-wide
  reads**: `web/app/api/founders/route.ts` uses `createAdminClient()`
  (service-role, bypasses RLS) to serve an aggregate list — who bought the
  Founding Citizen bundle — to any Godot client with a plain GET, no auth
  needed. `founders_monument.gd` consumes it. A vote tally is the same
  shape of problem: aggregate community data, safe to expose read-only.

## What "multiplayer" should actually mean here

Not realtime netcode. The Commonwealth "voting as a community" doesn't need
players in the same session at the same time — it needs votes to be
durable, shared, and tallied across everyone, the same way a forum poll or
an itch.io devlog comment works. That's **asynchronous, backend-mediated
multiplayer**, not synchronous multiplayer:

- No Godot high-level multiplayer API, no `ENetMultiplayerPeer`, no
  server-authoritative game state, no matchmaking/lobbies.
- Yes: Supabase tables for proposals/votes, REST calls from the Godot
  client (same pattern `aevoria_auth.gd` already uses), and the compliance
  engine treating a passed vote as just another event it's told about.

This is a much smaller build than it sounds like at first, precisely
because the account bridge and the REST-call pattern already exist.

## Sketch of the actual pieces (when it's time to build this)

**Database** — two new tables in `web/supabase/migrations/`, following the
existing migration numbering:
- `proposals`: `id, faction_id, title, description, created_by (references profiles), status (open/passed/failed), opens_at, closes_at`
- `votes`: `proposal_id, user_id, choice, weight, cast_at`, unique on
  `(proposal_id, user_id)` so a player can't vote twice. RLS: any
  authenticated user can insert their own vote row; tallies are read via a
  public aggregate (same `createAdminClient()` pattern as `founders/route.ts`,
  not raw per-vote rows, so nobody's individual vote is exposed to other
  players any more than it needs to be).

**Web side** — a couple of small API routes under `web/app/api/`, mirroring
`founders/route.ts`: list open proposals, submit a vote (this one needs
auth, unlike the founders list), fetch a tally.

**Godot side** — a new autoload, e.g. `community_governance.gd`, built the
same way `aevoria_auth.gd` is: `HTTPRequest` + signals
(`proposals_fetched`, `vote_cast`, `vote_failed`), reusing
`AevoriaAuth.access_token`/`SUPABASE_URL` for the authenticated calls.

**Where it plugs into existing levels** — `governance_level.gd`'s
step-by-step tutorial pattern (`_steps` array, each with a `text` +
`action` closure) is already the right shape for "show the player an open
proposal, let them vote, show them the current tally" — it would just need
one step's `action` to call `CommunityGovernance.cast_vote(...)` instead of
a scripted `monitor.submit_operational(...)` call. A passed proposal could
then be fed into `CURComplianceMonitor` as a registered event the same way
a mining charter's operational events are today — the C++ FSM itself
doesn't need to become network-aware, only what feeds it does.

**What stays single-player on purpose** — ship assembly, mining, resource
processing (`FactionHomeBase`'s local save file) are genuinely personal
progress, not shared world state. Multiplayer only needs to touch the
parts of the game that represent the Commonwealth acting *together* —
governance/voting — not everything.

## Sequencing

Build this after the single-player core loop (levels, store, marketplace)
is fully robust and the itch.io numbers justify the next investment — not
before. When it's time, start with the migration + one API route + a
single hardcoded test proposal end-to-end (Godot → vote → Supabase → tally
displayed back) before building any real proposal-creation UI. Same
"verify end-to-end before building the next layer" discipline as the rest
of this project.
