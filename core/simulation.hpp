#pragma once
#include "state.hpp"

namespace core {

class Simulation {
public:
    Simulation(int num_swarms, int yield_per_swarm);

    // Advance simulation by one day
    void step_day();

    // Access current state
    const SimulationState& get_state() const;

private:
    SimulationState state;

    // Internal helpers
    void run_bribery_phase();
    void run_voting_phase();
    void run_recall_phase();
    void apply_allocations();
};

} // namespace core
