#include "cur_mechanics.hpp"

#include <string>

namespace core {

void delegates_vote(SimulationState& state) {
    // Placeholder: each non-bribed delegate casts a neutral allocation vote.
    // Replace with real CUR-compliant voting logic.
    state.votes.clear();
    for (const Delegate& delegate : state.delegates) {
        if (!delegate.bribed) {
            state.votes.push_back({delegate.id, 0});
        }
    }
}

void check_for_recalls(SimulationState& state) {
    // Placeholder: flag any delegate whose integrity has dropped below a
    // recall threshold so governance can review it.
    for (const Delegate& delegate : state.delegates) {
        if (delegate.integrity < 0.2) {
            AlarmEvent event;
            event.type = "Recall Threshold";
            event.message = "Delegate integrity critically low.";
            event.uid = std::to_string(delegate.id);
            state.alarms.push_back(event);
        }
    }
}

void allocate_resources(SimulationState& state) {
    // Placeholder: sum swarm yields into the commons wealth pool.
    for (const Swarm& swarm : state.swarms) {
        state.commons_wealth += swarm.yield;
    }
}

} // namespace core
