#pragma once

#include <godot_cpp/classes/image_texture.hpp>
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/dictionary.hpp>

namespace godot {

/**
 * @brief ProceduralArtGenerator
 *
 * Stateless utility for generating procedural textures (asteroid surfaces,
 * ISRU-adjacent materials, skins, etc.) from noise fields. Exposed to
 * GDScript so scenes can request a generated texture without needing their
 * own C++.
 *
 * generate_procedural_texture() takes a "recipe" Dictionary rather than
 * individual parameters — this is deliberately the same shape a skin
 * recipe takes in the marketplace (web/lib/skin-recipe.ts), so a skin
 * bought there reproduces identically here. Recipe keys:
 *   "seed"        int, default 0
 *   "frequency"   float, default 0.05
 *   "dark_color"  Color, default (0.15, 0.12, 0.10)
 *   "base_color"  Color, default (0.75, 0.65, 0.55)
 *   "highlight_color" Color, default (0.85, 0.78, 0.68)
 * Any missing key falls back to the original hardcoded default, so old
 * callers passing an empty Dictionary get the original look unchanged.
 */
class ProceduralArtGenerator : public RefCounted {
    GDCLASS(ProceduralArtGenerator, RefCounted)

protected:
    static void _bind_methods();

public:
    ProceduralArtGenerator();
    ~ProceduralArtGenerator();

    /**
     * @brief Generates a stylized, hand-drawn-looking procedural texture
     * using cellular noise and posterized color thresholds.
     *
     * @param recipe Dictionary of generation parameters; see class docs.
     * @param width Texture width in pixels.
     * @param height Texture height in pixels.
     * @return A ready-to-use ImageTexture.
     */
    Ref<ImageTexture> generate_procedural_texture(const Dictionary &recipe, int width, int height);
};

} // namespace godot
