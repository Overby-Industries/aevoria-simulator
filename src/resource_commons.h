#pragma once

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

namespace godot {

/**
 * @brief ResourceCommons
 * 
 * This class represents the shared resource-management layer for the Aevoria Simulator.
 * It acts as a central hub for:
 *  - tracking resource availability
 *  - coordinating extraction, refinement, and distribution
 *  - enforcing CUR-compliant resource rules
 *  - providing signals and hooks for other systems (ISRU, governance, factions)
 * 
 * In the full simulator, this node will likely:
 *  - maintain global resource state
 *  - expose APIs for other modules (DirectDemocracyOS, RegulatoryEngine, etc.)
 *  - run periodic updates in _process() to simulate resource flow
 *  - emit signals when thresholds or scarcity events occur
 */
class ResourceCommons : public Node {
    GDCLASS(ResourceCommons, Node)

private:
    // ---------------------------------------------------------------------
    // Member Variables
    // ---------------------------------------------------------------------
    // Add your resource-tracking variables here.
    // Example:
    //
    // double ore_stockpile = 0.0;
    // double energy_reserve = 0.0;
    // Dictionary extraction_nodes;
    //
    // These will eventually integrate with:
    //  - ISRU simulation
    //  - governance decisions
    //  - faction behavior
    //  - crisis protocols
    // ---------------------------------------------------------------------

protected:
    /**
     * @brief Bind methods and properties to Godot.
     * 
     * This function is called automatically during engine initialization.
     * Use ClassDB::bind_method() to expose C++ methods to GDScript.
     */
    static void _bind_methods();

public:
    /**
     * @brief Constructor.
     * 
     * Initialize internal state here. Avoid calling Godot API functions.
     */
    ResourceCommons();

    /**
     * @brief Destructor.
     * 
     * Clean up resources here if needed.
     */
    ~ResourceCommons();

    /**
     * @brief Called when the node enters the scene tree.
     * 
     * Use this for initialization that depends on the scene or other nodes.
     */
    void _ready() override;

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
     */
    void _process(double delta) override;
};

} // namespace godot
