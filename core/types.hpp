#pragma once
#include <string>
#include <vector>

namespace core {

struct Swarm {
    int id;
    int yield;
    double trust;
};

struct Delegate {
    int id;
    bool bribed;
    double integrity;
};

struct AllocationVote {
    int delegate_id;
    int allocation;
};

struct AlarmEvent {
    std::string type;
    std::string message;
    std::string uid;
};

} // namespace core
