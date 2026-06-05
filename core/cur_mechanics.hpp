#pragma once
#include "state.hpp"

namespace core {

void delegates_vote(SimulationState& state);
void check_for_recalls(SimulationState& state);
void allocate_resources(SimulationState& state);

} // namespace core
