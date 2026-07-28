-- Procedural skins: a skin's "content" can now be either an uploaded file
-- (storage_path, the original path) or a small parametric recipe rendered
-- by ProceduralArtGenerator on the Godot side and by a matching GLSL shader
-- in the web customizer's live preview. Run after 0004.

alter table public.skins
  alter column storage_path drop not null,
  add column recipe jsonb;

-- Every skin must have SOME content, one way or the other.
alter table public.skins
  add constraint skins_has_content
  check (storage_path is not null or recipe is not null);
