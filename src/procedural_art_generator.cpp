#include "procedural_art_generator.h"

#include <godot_cpp/classes/fast_noise_lite.hpp>
#include <godot_cpp/classes/image.hpp>

namespace godot {

void ProceduralArtGenerator::_bind_methods() {
    ClassDB::bind_method(D_METHOD("generate_procedural_texture", "recipe", "width", "height"),
                         &ProceduralArtGenerator::generate_procedural_texture);
}

ProceduralArtGenerator::ProceduralArtGenerator() {}
ProceduralArtGenerator::~ProceduralArtGenerator() {}

Ref<ImageTexture> ProceduralArtGenerator::generate_procedural_texture(const Dictionary &recipe, int width, int height) {
    Ref<Image> img = Image::create_empty(width, height, false, Image::FORMAT_RGBA8);

    Ref<FastNoiseLite> noise = memnew(FastNoiseLite);
    noise->set_noise_type(FastNoiseLite::TYPE_CELLULAR); // Good for stylized/cracked patterns
    // The default cellular_return_type (RETURN_DISTANCE) never leaves
    // roughly [-0.9, -0.18] in practice for any seed/frequency tested —
    // confirmed empirically, not assumed — which put every pixel in this
    // function's original hardcoded "highlight" band 100% of the time. The
    // texture was never actually showing the intended posterized pattern.
    // RETURN_DISTANCE2 has a real spread across zero ([-0.7, 0.07]
    // measured), which is what the thresholds below are calibrated against.
    noise->set_cellular_return_type(FastNoiseLite::RETURN_DISTANCE2);
    noise->set_seed(int(recipe.get("seed", 0)));
    noise->set_frequency(float(double(recipe.get("frequency", 0.05))));

    Color dark_color = recipe.get("dark_color", Color(0.15f, 0.12f, 0.10f));
    Color base_color = recipe.get("base_color", Color(0.75f, 0.65f, 0.55f));
    Color highlight_color = recipe.get("highlight_color", Color(0.85f, 0.78f, 0.68f));

    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            float n_val = noise->get_noise_2d(x, y); // Returns -1.0 to 1.0

            // Apply math to make it look "hand-drawn" (Posterization / Thresholding).
            // Thresholds calibrated against RETURN_DISTANCE2's real value
            // range (see note above), not the arbitrary 0.4/-0.1 the
            // original RETURN_DISTANCE version used — those never fired.
            Color pixel_color;
            if (n_val > -0.05f) {
                pixel_color = dark_color; // "ink" line — sparse, ~0-2% of pixels
            } else if (n_val > -0.4f) {
                pixel_color = base_color; // base paper/rock tone — majority
            } else {
                pixel_color = highlight_color; // highlight tone — secondary accent
            }

            img->set_pixel(x, y, pixel_color);
        }
    }

    Ref<ImageTexture> texture = ImageTexture::create_from_image(img);
    return texture;
}

} // namespace godot
