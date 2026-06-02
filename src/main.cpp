#include <iostream>  
#include <vector>  
#include <random>  
#include "cur_mechanics.hpp"  
#include "attack_vectors.hpp"  

int main() {  
    // SETUP (hardcoded for day 1—we’ll add config later)  
    const int NUM_SWARMS = 5;  
    const int YIELD_PER_SWARM = 100;  
    const int BRIBERY_COST = 30; // Cost to bribe one delegate  
    std::vector<Swarm> swarms = initializeSwarms(NUM_SWARMS, YIELD_PER_SWARM);  
    std::vector<Delegate> delegates = electDelegates(swarms); // CUR sortition  

    std::cout << "=== AEVORIA CUR STRESS TEST: DAY 1 ===\n";  
    std::cout << "Swarm yields: ";  
    for (auto& s : swarms) std::cout << s.yield << " ";  
    std::cout << "\n";  

    // SIMULATE 7 DAYS  
    for (int day = 1; day <= 7; ++day) {  
        std::cout << "\n--- DAY " << day << " ---\n";  

        // 1. Billionaire class attempts bribes  
        int bribes_successful = attempt_bribes(delegates, BRIBERY_COST);  
        std::cout << "Bribes attempted: " << bribes_attempted << ", Successful: " << bribes_successful << "\n";  

        // 2. Delegates vote on allocation (influenced by bribes)  
        std::vector<AllocationVote> votes = delegates_vote(delegates);  

        // 3. CUR RECALL MECHANISM: Swarms check for suspicious voting  
        int recalls_triggered = check_for_recalls(swarms, delegates, votes);  
        std::cout << "Recalls triggered: " << recalls_triggered << "\n";  

        // 4. Apply outcomes:  
        //    - If recall: replace delegate, reset trust  
        //    - Else: allocate resources per votes  
        allocate_resources(swarms, votes);  
        std::cout << "Commons wealth: " << total_commons_wealth << "\n";  
    }  

    // OUTCOME ANALYSIS  
    if (total_commons_wealth > (NUM_SWARMS * YIELD_PER_SWARM * 0.6 * 7)) {  
        std::cout << "\n✅ SUCCESS: CUR prevented oligarchic capture!\n";  
    } else {  
        std::cout << "\n❌ FAILURE: Billionaire class captured >40% of yields.\n";  
        std::cout << "   (Check logs for which delegates were compromised)\n";  
    }  
    return 0;  
}