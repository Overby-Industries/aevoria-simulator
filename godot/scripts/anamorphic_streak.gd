extends RefCounted

## Shared "anamorphic lens streak" texture baker -- the horizontal blue
## bar shape a real anamorphic lens produces (Star Trek/Interstellar-
## style), originally built inside hero_backdrop.gd for the Level Select
## sun flare and factored out here so any other scene (hangar_backdrop.gd's
## ceiling fixtures, currently) can reuse the exact same shape instead of
## re-deriving it.
##
## GradientTexture2D can only fade along ONE axis at a time (its "fill" is
## either radial -- fades every direction, an oval when stretched -- or
## linear along one line -- flat/solid ends, no taper), so a shape that's
## soft top-to-bottom AND tapers to a point at the left/right ends needs
## both axes to fade independently. That's baked by hand into a plain
## Image instead: alpha at each pixel is
## `vertical_falloff(y) * horizontal_taper(x)`, i.e. two independent 1D
## falloffs multiplied together, which GradientTexture2D alone can't
## express.

const TEX_SIZE := Vector2i(256, 32)
# Fraction of the texture's width, on EACH side, spent tapering down to a
# point -- e.g. 0.32 means the outer 32% on the left and outer 32% on the
# right both ramp to zero, leaving a solid ~36% in the middle. Bigger =
# more needle-like tips; smaller = blunter, more rectangular ends.
const TAPER_FRACTION := 0.32

static func make_texture() -> ImageTexture:
	var w := TEX_SIZE.x
	var h := TEX_SIZE.y
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for x in range(w):
		var u := float(x) / float(w - 1)  # 0 at left edge, 1 at right edge
		var h_alpha := _horizontal_taper(u)
		for y in range(h):
			var v := float(y) / float(h - 1)  # 0 at top, 1 at bottom
			var v_alpha := _vertical_falloff(v)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, h_alpha * v_alpha))
	return ImageTexture.create_from_image(img)

# 1 across the solid middle, smoothstep-ramping to 0 at both ends over the
# outer TAPER_FRACTION -- this is what puts an actual point on each tip
# instead of a hard flat cutoff.
static func _horizontal_taper(u: float) -> float:
	var a := 1.0
	if u < TAPER_FRACTION:
		a = u / TAPER_FRACTION
	elif u > 1.0 - TAPER_FRACTION:
		a = (1.0 - u) / TAPER_FRACTION
	a = clampf(a, 0.0, 1.0)
	return a * a * (3.0 - 2.0 * a)  # smoothstep, avoids a visible crease at the taper start

# Brightest at the vertical center (v = 0.5), fading to 0 at top/bottom --
# squared so the line reads tight/bright in the middle rather than a broad
# smear.
static func _vertical_falloff(v: float) -> float:
	var d := absf(v - 0.5) * 2.0  # 0 at center, 1 at top/bottom edge
	var a := clampf(1.0 - d, 0.0, 1.0)
	return a * a
