#include "procedural_art_generator.h"

#include <godot_cpp/classes/fast_noise_lite.hpp>
#include <godot_cpp/classes/image.hpp>

namespace godot {

void ProceduralArtGenerator::_bind_methods() {
    ClassDB::bind_method(D_METHOD("generate_procedural_texture", "width", "height"),
                         &ProceduralArtGenerator::generate_procedural_texture);
}

ProceduralArtGenerator::ProceduralArtGenerator() {}
ProceduralArtGenerator::~ProceduralArtGenerator() {}

Ref<ImageTexture> ProceduralArtGenerator::generate_procedural_texture(int width, int height) {
    Ref<Image> img = Image::create_empty(width, height, false, Image::FORMAT_RGBA8);

    Ref<FastNoiseLite> noise = memnew(FastNoiseLite);
    noise->set_noise_type(FastNoiseLite::TYPE_CELLULAR); // Good for stylized/cracked patterns
    noise->set_frequency(0.05);

    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            float n_val = noise->get_noise_2d(x, y); // Returns -1.0 to 1.0

            // Apply math to make it look "hand-drawn" (Posterization / Thresholding)
            Color pixel_color;
            if (n_val > 0.4f) {
                pixel_color = Color(0.15f, 0.12f, 0.10f); // Dark "ink" line
            } else if (n_val > -0.1f) {
                pixel_color = Color(0.75f, 0.65f, 0.55f); // Base paper/rock tone
            } else {
                pixel_color = Color(0.85f, 0.78f, 0.68f); // Highlight tone
            }

            img->set_pixel(x, y, pixel_color);
        }
    }

    Ref<ImageTexture> texture = ImageTexture::create_from_image(img);
    return texture;
}

} // namespace godot
