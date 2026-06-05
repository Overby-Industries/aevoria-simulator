#pragma once
#include "types.hpp"
#include <vector>

namespace core {

struct SimulationState {
    std::vector<Swarm> swarms;
    std::vector<Delegate> delegates;
    std::vector<AllocationVote> votes;

    int day = 0;
    int commons_wealth = 0;

    std::vector<AlarmEvent> alarms;
};

SimulationState initialize_state(int num_swarms, int yield_per_swarm);

} // namespace core
