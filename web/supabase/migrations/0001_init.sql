-- Aevoria Simulator — initial schema
-- Run this in the Supabase SQL Editor (Dashboard > SQL Editor > New query).

-- ---------------------------------------------------------------------
-- profiles: one row per authenticated user, auto-created on signup
-- ---------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique,
  avatar_url text,
  -- Set once a creator completes Stripe Connect onboarding (Tier 2 payouts).
  stripe_connect_account_id text,
  is_creator boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Profiles are viewable by everyone"
  on public.profiles for select
  using (true);

create policy "Users can update their own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- Auto-create a profile row whenever someone signs up via Supabase Auth.
create function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, username)
  values (new.id, coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)));
  return new;
end;
$$ language plpgsql security definer set search_path = public;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ---------------------------------------------------------------------
-- skins: Tier 2 "Modder's Cooperative" marketplace listings
-- ---------------------------------------------------------------------
create type public.skin_status as enum ('pending_review', 'approved', 'rejected');

create table public.skins (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  description text,
  price_cents integer not null check (price_cents >= 0),
  storage_path text not null,
  preview_image_path text,
  status public.skin_status not null default 'pending_review',
  stripe_product_id text,
  stripe_price_id text,
  created_at timestamptz not null default now()
);

alter table public.skins enable row level security;

create policy "Approved skins are viewable by everyone, own listings always visible"
  on public.skins for select
  using (status = 'approved' or auth.uid() = creator_id);

create policy "Creators can list their own skins"
  on public.skins for insert
  with check (auth.uid() = creator_id);

create policy "Creators can edit their own listings"
  on public.skins for update
  using (auth.uid() = creator_id);

-- ---------------------------------------------------------------------
-- purchases: records the revenue split from MONETIZATION_STRATEGY.md
-- (creator payout / platform fee). Written server-side only, via the
-- Stripe webhook handler using the service role key — no insert policy
-- is defined here on purpose, since regular users should never write
-- these rows directly.
-- ---------------------------------------------------------------------
create table public.purchases (
  id uuid primary key default gen_random_uuid(),
  buyer_id uuid not null references public.profiles(id) on delete cascade,
  skin_id uuid not null references public.skins(id) on delete restrict,
  stripe_payment_intent_id text not null unique,
  amount_cents integer not null,
  platform_fee_cents integer not null,
  creator_payout_cents integer not null,
  created_at timestamptz not null default now()
);

alter table public.purchases enable row level security;

create policy "Buyers can view their own purchases"
  on public.purchases for select
  using (auth.uid() = buyer_id);

create policy "Creators can view purchases of their own skins"
  on public.purchases for select
  using (auth.uid() = (select creator_id from public.skins where id = skin_id));

-- ---------------------------------------------------------------------
-- Storage: bucket for uploaded skin/texture files
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('skins', 'skins', false)
on conflict (id) do nothing;

-- Files are expected at path "{user_id}/{filename}" — only the owner
-- can upload into their own folder.
create policy "Creators can upload into their own folder"
  on storage.objects for insert
  with check (bucket_id = 'skins' and auth.uid()::text = (storage.foldername(name))[1]);

-- Anyone can read a file once its listing is approved; the owner can
-- always read their own (still-pending) files.
create policy "Approved skin files are readable, own files always readable"
  on storage.objects for select
  using (
    bucket_id = 'skins'
    and (
      auth.uid()::text = (storage.foldername(name))[1]
      or exists (
        select 1 from public.skins
        where storage_path = storage.objects.name
        and status = 'approved'
      )
    )
  );
