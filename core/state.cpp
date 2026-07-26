#include "state.hpp"

namespace core {

SimulationState initialize_state(int num_swarms, int yield_per_swarm) {
    SimulationState state;
    state.day = 0;
    state.commons_wealth = 0;

    for (int i = 0; i < num_swarms; ++i) {
        Swarm swarm;
        swarm.id = i;
        swarm.yield = yield_per_swarm;
        swarm.trust = 1.0;
        state.swarms.push_back(swarm);
    }

    return state;
}

} // namespace core
