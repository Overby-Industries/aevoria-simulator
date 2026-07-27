-- Fix: the 0001 storage read policy's "approved" carve-out only matched
-- storage.objects.name against skins.storage_path. Procedural skins (see
-- 0005_skin_recipes.sql) have storage_path = null and their only file is
-- preview_image_path, so that carve-out never matched them -- meaning
-- once approved, NO visitor other than the creator could actually load a
-- procedural skin's preview image on the marketplace (createSignedUrl is
-- RLS-gated). Broaden the exists-check to match either path column.
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
        and (storage_path = storage.objects.name or preview_image_path = storage.objects.name)
      )
    )
  );
