#include "simulation_controller.h"
#include <godot_cpp/variant/utility_functions.hpp>

#include "alarm_system.h"
#include "corruption_detector.h"
#include "resource_commons.h"

namespace godot {

void SimulationController::_bind_methods() {
    ClassDB::bind_method(D_METHOD("reset_simulation", "swarms", "yield"),
                         &SimulationController::reset_simulation);
}

SimulationController::SimulationController()
    : sim(5, 100) // default values
{}

SimulationController::~SimulationController() {}

void SimulationController::_ready() {
    UtilityFunctions::print("SimulationController ready.");

    // Auto-locate subsystems in the scene tree
    alarm_system = get_node_or_null("AlarmSystem");
    corruption_detector = get_node_or_null("CorruptionDetector");
    resource_commons = get_node_or_null("ResourceCommons");

    if (!alarm_system)
        UtilityFunctions::print("⚠️ AlarmSystem not found in scene.");
    if (!corruption_detector)
        UtilityFunctions::print("⚠️ CorruptionDetector not found in scene.");
    if (!resource_commons)
        UtilityFunctions::print("⚠️ ResourceCommons not found in scene.");
}

void SimulationController::_process(double delta) {
    sim.step_day();
    const auto& state = sim.get_state();

    // Example: print commons wealth
    UtilityFunctions::print("Commons wealth: ", state.commons_wealth);

    // Example: forward alarms to Godot AlarmSystem
    if (alarm_system) {
        for (const auto& alarm : state.alarms) {
            AlarmSystem* as = Object::cast_to<AlarmSystem>(alarm_system);
            if (as) {
                as->trigger_alarm(
                    String(alarm.type.c_str()),
                    String(alarm.message.c_str()),
                    String(alarm.uid.c_str()),
                    "", // target UID optional
                    ""  // resource optional
                );
            }
        }
    }

    // Example: corruption detection integration
    if (corruption_detector) {
        CorruptionDetector* cd = Object::cast_to<CorruptionDetector>(corruption_detector);
        if (cd) {
            // You can call cd->detect_bribery(), etc. based on state
        }
    }

    // Example: resource commons integration
    if (resource_commons) {
        ResourceCommons* rc = Object::cast_to<ResourceCommons>(resource_commons);
        if (rc) {
            // rc->update_resources(state.commons_wealth);
        }
    }
}

void SimulationController::reset_simulation(int swarms, int yield) {
    sim = core::Simulation(swarms, yield);
    UtilityFunctions::print("Simulation reset.");
}

} // namespace godot
