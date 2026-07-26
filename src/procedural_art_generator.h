#pragma once

#include <godot_cpp/classes/image_texture.hpp>
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>

namespace godot {

/**
 * @brief ProceduralArtGenerator
 *
 * Stateless utility for generating procedural textures (asteroid surfaces,
 * ISRU-adjacent materials, etc.) from noise fields. Exposed to GDScript so
 * scenes can request a generated texture without needing their own C++.
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
     * @param width Texture width in pixels.
     * @param height Texture height in pixels.
     * @return A ready-to-use ImageTexture.
     */
    Ref<ImageTexture> generate_procedural_texture(int width, int height);
};

} // namespace godot
