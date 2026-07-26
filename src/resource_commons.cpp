#include "resource_commons.h"
#include <godot_cpp/variant/utility_functions.hpp>

namespace godot {

/**
 * @brief Constructor.
 * 
 * Initialize internal resource state here. Avoid calling Godot API functions.
 * This is where you would set up default resource values, caches, or internal
 * simulation variables.
 */
ResourceCommons::ResourceCommons() {
    // Example:
    // ore_stockpile = 0.0;
    // energy_reserve = 100.0;
}

/**
 * @brief Destructor.
 * 
 * Clean up any allocated memory or external handles here.
 * Most Godot objects do not require manual cleanup.
 */
ResourceCommons::~ResourceCommons() {
    // Cleanup if needed
}

/**
 * @brief Bind methods and properties to Godot.
 * 
 * This function is called automatically during engine initialization.
 * Use ClassDB::bind_method() to expose C++ methods to GDScript.
 */
void ResourceCommons::_bind_methods() {
    ClassDB::bind_method(D_METHOD("request_resource", "resource", "amount", "requesterUID"),
                         &ResourceCommons::request_resource);

    ClassDB::bind_method(D_METHOD("get_resource_stock", "resource"),
                         &ResourceCommons::get_resource_stock);
}

/**
 * @brief Called when the node enters the scene tree.
 * 
 * Use this for initialization that depends on the scene or other nodes.
 * This is a good place to:
 *  - locate other simulation nodes
 *  - initialize resource networks
 *  - print debug information
 */
void ResourceCommons::_ready() {
    UtilityFunctions::print("ResourceCommons initialized and ready.");
}

/**
 * @brief Called every frame.
 * 
 * @param delta Time since last frame.
 * 
 * Use this for:
 *  - resource simulation ticks
 *  - updating extraction/refinement cycles
 *  - triggering threshold events
 *  - interacting with governance systems
 * 
 * This function will eventually drive the ISRU simulation loop.
 */
void ResourceCommons::_process(double delta) {
    // Example future logic:
    // ore_stockpile += extraction_rate * delta;
    // if (ore_stockpile < critical_threshold) emit_signal("resource_low");
}

/**
 * @brief Adds a granted resource allocation to the commons pool.
 *
 * This currently just credits the pool unconditionally — it does not yet
 * check against CUR resource rules or scarcity thresholds.
 */
void ResourceCommons::request_resource(const String& resource, double amount, const String& requesterUID) {
    std::string resourceStr = resource.utf8().get_data();
    resourceStock[resourceStr] += amount;

    UtilityFunctions::print("Resource granted: ", resource, " +", amount, " (requested by ", requesterUID, ")");
}

/**
 * @brief Returns the current stock of a resource, or 0 if never added.
 */
double ResourceCommons::get_resource_stock(const String& resource) {
    std::string resourceStr = resource.utf8().get_data();
    auto it = resourceStock.find(resourceStr);
    return it != resourceStock.end() ? it->second : 0.0;
}

} // namespace godot
