#pragma once

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include "../core/simulation.hpp"

namespace godot {

class SimulationController : public Node {
    GDCLASS(SimulationController, Node)

private:
    core::Simulation sim;

    // Optional: references to other Godot systems
    Node* alarm_system = nullptr;
    Node* corruption_detector = nullptr;
    Node* resource_commons = nullptr;

protected:
    static void _bind_methods();

public:
    SimulationController();
    ~SimulationController();

    void _ready() override;
    void _process(double delta) override;

    // Expose a method to reset or configure the simulation
    void reset_simulation(int swarms, int yield);
};

} // namespace godot
