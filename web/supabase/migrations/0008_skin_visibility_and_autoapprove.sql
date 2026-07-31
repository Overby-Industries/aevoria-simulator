-- Supports two things at once:
--
-- 1. Auto-approve: procedural skins can now be approved by the system at
--    submission time instead of waiting on a human reviewer (see
--    app/(app)/creator/create/actions.ts) -- safe because the shader can
--    only ever render a 3-solid-color cellular pattern, so the imagery risk
--    a human review queue exists for is structurally impossible here. The
--    file-upload path that could have produced arbitrary imagery has been
--    removed entirely (app/(app)/creator/upload deleted).
--
-- 2. Personal-use skins: a creator can now save a skin for their own use in
--    the simulator without listing it on the marketplace at all -- no
--    Stripe product/price gets created for these, and they never appear in
--    /marketplace or /admin/review.
--
-- Both still respect 0003's "creators can only insert/update their own row
-- while pending_review, and the result must still be pending_review" RLS
-- policy -- a creator's own client still can never self-approve. The actual
-- approve step (whether human-triggered via admin/review/actions.ts or
-- system-triggered via creator/create/actions.ts) always runs through the
-- service-role admin client, same as it already did for human approval.

alter table public.skins
  add column is_public boolean not null default true;

comment on column public.skins.is_public is
  'false = personal-use only, never listed on the marketplace or shown in review. Still owned/usable in-sim by its creator regardless of is_public.';

-- 0006's read policy let anyone load an approved skin's file (needed for
-- marketplace thumbnails), preserving only "creator can always read their
-- own" as the other carve-out. Add is_public = true to the approved
-- carve-out so an approved-but-private skin's preview image isn't served
-- through that same public/unauthenticated path -- the creator's own-files
-- carve-out still covers them seeing it themselves.
drop policy "Approved skin files are readable, own files always readable" on storage.objects;

create policy "Approved skin files are readable, own files always readable"
  on storage.objects for select
  using (
    bucket_id = 'skins'
    and (
      auth.uid()::text = (storage.foldername(name))[1]
      or exists (
        select 1 from public.skins
        where status = 'approved'
        and is_public = true
        and (storage_path = storage.objects.name or preview_image_path = storage.objects.name)
      )
    )
  );
