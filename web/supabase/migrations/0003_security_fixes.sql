-- Security fixes from the marketplace security review. Root cause: RLS
-- UPDATE policies written with USING but no WITH CHECK — Postgres reuses
-- USING as the check when WITH CHECK is omitted, which only restricts
-- *which row* you can touch, not *what values* you write to it.

-- ---------------------------------------------------------------------
-- Fix 1 & 2: creators could self-approve listings (bypassing review) and
-- edit price_cents after approval (gutting the platform's fee, since the
-- old policy let them write ANY column on their own row).
--
-- New policy: creators may only update a listing while it's still
-- pending_review, AND the result must still be pending_review. Once a
-- listing is approved, this policy grants creators zero write access to
-- it — status changes only happen through the service-role admin path.
-- ---------------------------------------------------------------------
drop policy if exists "Creators can edit their own listings" on public.skins;

create policy "Creators can edit their own pending listings"
  on public.skins for update
  using (auth.uid() = creator_id and status = 'pending_review')
  with check (auth.uid() = creator_id and status = 'pending_review');

-- ---------------------------------------------------------------------
-- Fix 4: any user could self-grant is_creator and forge
-- stripe_connect_account_id via a direct update to their own profile row,
-- bypassing Stripe Connect onboarding/KYC entirely.
--
-- A trigger (not RLS) enforces this, because triggers apply regardless of
-- which Supabase client performs the write — a WITH CHECK clause alone
-- can't distinguish "the onboarding-completion code path" from "a user
-- calling .update() directly with the same effect", since both currently
-- use a normal per-user session. The app code below is updated to
-- perform these two specific writes via the service-role client, which
-- is what the trigger's exception carves out.
-- ---------------------------------------------------------------------
create function public.prevent_creator_field_self_update()
returns trigger as $$
begin
  if auth.role() = 'service_role' then
    return new;
  end if;

  if (new.is_creator is distinct from old.is_creator)
     or (new.stripe_connect_account_id is distinct from old.stripe_connect_account_id) then
    raise exception 'is_creator and stripe_connect_account_id can only be set by the server';
  end if;

  return new;
end;
$$ language plpgsql security definer set search_path = public;

create trigger prevent_creator_field_self_update
  before update on public.profiles
  for each row execute procedure public.prevent_creator_field_self_update();
