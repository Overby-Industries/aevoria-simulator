-- Faction system + Dual-Entity Protocol (per README.md) + a first pass at
-- account-integrity detection (same-IP-same-faction multi-accounting).
--
-- Design notes:
-- - faction is settable once (from NULL) via a normal user update — this
--   lets existing accounts created before this migration pick a faction
--   retroactively — but is immutable after that, and only the server
--   (service_role, via the linked-franchise creation flow) can set
--   linked_primary_id at all. Both are enforced by extending the trigger
--   from 0003, not by RLS alone.
-- - account_signals and integrity_flags are never exposed to normal
--   clients: RLS is enabled with zero policies for either table, so only
--   the service-role client (which bypasses RLS) can touch them.

create type public.faction as enum ('commonwealth', 'syndicate', 'nomads');

alter table public.profiles
  add column faction public.faction,
  add column linked_primary_id uuid references public.profiles(id);

-- One Independent Franchise (alt) per Primary account.
create unique index profiles_one_alt_per_primary
  on public.profiles (linked_primary_id)
  where linked_primary_id is not null;

-- An alt's faction must differ from its primary's — this is the actual
-- "factions must be completely separate" rule from the README, enforced
-- at the database layer rather than just in application code.
create function public.enforce_alt_faction_differs()
returns trigger as $$
begin
  if new.linked_primary_id is not null then
    if new.linked_primary_id = new.id then
      raise exception 'An account cannot link to itself.';
    end if;
    if new.faction is not null
       and new.faction = (select faction from public.profiles where id = new.linked_primary_id) then
      raise exception 'An Independent Franchise must choose a different faction than its Primary account.';
    end if;
  end if;
  return new;
end;
$$ language plpgsql security definer set search_path = public;

create trigger enforce_alt_faction_differs
  before insert or update on public.profiles
  for each row execute procedure public.enforce_alt_faction_differs();

-- Extends 0003's self-update guard: faction can be set once (from NULL)
-- by a normal user but never changed afterward, and linked_primary_id is
-- always server-only, matching is_creator/stripe_connect_account_id.
create or replace function public.prevent_creator_field_self_update()
returns trigger as $$
begin
  if auth.role() = 'service_role' then
    return new;
  end if;

  if (new.is_creator is distinct from old.is_creator)
     or (new.stripe_connect_account_id is distinct from old.stripe_connect_account_id)
     or (old.faction is not null and new.faction is distinct from old.faction)
     or (new.linked_primary_id is distinct from old.linked_primary_id) then
    raise exception 'is_creator, stripe_connect_account_id, faction (once set), and linked_primary_id can only be set by the server';
  end if;

  return new;
end;
$$ language plpgsql security definer set search_path = public;

-- Extends handle_new_user (0001) to also set faction and linked_primary_id
-- from signup metadata, so a new Independent Franchise account can be
-- created fully-formed via the Admin API in one insert rather than
-- needing a follow-up update (which the trigger above would block anyway
-- for a non-service-role caller).
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, username, faction, linked_primary_id)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)),
    nullif(new.raw_user_meta_data->>'faction', '')::public.faction,
    nullif(new.raw_user_meta_data->>'linked_primary_id', '')::uuid
  );
  return new;
end;
$$ language plpgsql security definer set search_path = public;

-- ---------------------------------------------------------------------
-- account_signals: raw signup-time signals (currently just IP). Kept
-- separate from `profiles` (which is publicly readable) since an IP
-- address is personal data and has no reason to ever be exposed to
-- clients — only used server-side for integrity checks.
-- ---------------------------------------------------------------------
create table public.account_signals (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  signup_ip text,
  created_at timestamptz not null default now()
);
alter table public.account_signals enable row level security;
-- No policies defined on purpose: RLS with zero policies means zero
-- access for anon/authenticated roles. Only service_role (which bypasses
-- RLS entirely) can read or write this table.

-- ---------------------------------------------------------------------
-- integrity_flags: moderation queue. Flags are raised automatically
-- (e.g. same IP + same faction across unrelated accounts) but never
-- take action themselves — a human (admin) reviews and decides. Same
-- lockdown as account_signals: service-role only.
-- ---------------------------------------------------------------------
create type public.flag_status as enum ('open', 'actioned', 'dismissed');

create table public.integrity_flags (
  id uuid primary key default gen_random_uuid(),
  flagged_profile_id uuid not null references public.profiles(id) on delete cascade,
  related_profile_id uuid references public.profiles(id) on delete set null,
  flag_type text not null,
  details jsonb,
  status public.flag_status not null default 'open',
  created_at timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewed_by uuid references public.profiles(id)
);
alter table public.integrity_flags enable row level security;
