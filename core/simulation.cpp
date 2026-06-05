#include "simulation.hpp"
#include "cur_mechanics.hpp"
#include "attack_vectors.hpp"

namespace core {

Simulation::Simulation(int num_swarms, int yield_per_swarm) {
    state = initialize_state(num_swarms, yield_per_swarm);
}

void Simulation::step_day() {
    run_bribery_phase();
    run_voting_phase();
    run_recall_phase();
    apply_allocations();
}

const SimulationState& Simulation::get_state() const {
    return state;
}

void Simulation::run_bribery_phase() {
    attempt_bribes(state);
}

void Simulation::run_voting_phase() {
    delegates_vote(state);
}

void Simulation::run_recall_phase() {
    check_for_recalls(state);
}

void Simulation::apply_allocations() {
    allocate_resources(state);
}

} // namespace core
