#pragma once

// Shared part-category vocabulary for the modular kit-bashing system
// (PartDefinition / AssemblyBlueprint / PartAssembler). One flat enum
// covers ships, droids, and habitat/life-support builds -- one socket
// system serves all of them rather than a category hierarchy per asset
// type.

#include <cstdint>

namespace godot {

enum PartCategory {
    PART_CAT_HULL_SEGMENT = 0,
    PART_CAT_CHASSIS,
    PART_CAT_LEG,
    PART_CAT_THRUSTER,
    PART_CAT_DRILL_ARM,
    PART_CAT_MANIPULATOR_ARM,
    PART_CAT_CARGO_POD,
    PART_CAT_SENSOR_POD,
    PART_CAT_SOLAR_ARRAY,
    PART_CAT_RADIATOR,
    PART_CAT_HABITAT_RING,
    PART_CAT_HYDROPONICS_BAY,
    PART_CAT_O2_SCRUBBER,
    PART_CAT_WATER_RECLAIMER,
    PART_CAT_WASTE_RECYCLER,
    PART_CAT_POWER_CELL,
    PART_CAT_COSMETIC,
    PART_CAT_COUNT
};

// A socket's "accepts" field is a bitmask of these, built with this helper
// so callers never hand-roll (1 << category) and risk drifting out of sync
// with the enum above.
inline uint32_t part_category_bit(int category) {
    return (category >= 0 && category < PART_CAT_COUNT) ? (1u << uint32_t(category)) : 0u;
}

}  // namespace godot
