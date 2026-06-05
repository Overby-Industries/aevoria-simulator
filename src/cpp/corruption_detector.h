#ifndef CORRUPTION_DETECTOR_H
#define CORRUPTION_DETECTOR_H

#include <gdextension_interface.h>
#include <godot.hpp>
#include <Godot.hpp>
#include <Node.hpp>
#include <unordered_map>
#include <vector>
#include <string>

using namespace godot;

class CorruptionDetector : public Node {
    GODOT_CLASS(CorruptionDetector, Node)

private:
    std::unordered_map<std::string, std::vector<std::string>> playerAccounts; // UID -> [account UIDs]
    std::unordered_map<std::string, int> playerCCs; // UID -> CCs
    std::vector<std::string> flaggedAccounts;

public:
    static void _register_methods();

    CorruptionDetector();
    ~CorruptionDetector();

    void _init();

    // Methods to expose to GDScript
    bool detect_sybil_attack(const String& UID, const String& newAccountUID);
    bool detect_bribery(const String& senderUID, const String& receiverUID, int amount);
    bool detect_hoarding(const String& UID, const String& resource, int amount);
    void flag_account(const String& UID);
    Array get_flagged_accounts();
};

#endif // CORRUPTION_DETECTOR_H