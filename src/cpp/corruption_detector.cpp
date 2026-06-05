#include "corruption_detector.h"
#include <gdextension_interface.h>
#include <godot.hpp>

using namespace godot;

void CorruptionDetector::_register_methods() {
    register_method("_init", &CorruptionDetector::_init);
    register_method("detect_sybil_attack", &CorruptionDetector::detect_sybil_attack);
    register_method("detect_bribery", &CorruptionDetector::detect_bribery);
    register_method("detect_hoarding", &CorruptionDetector::detect_hoarding);
    register_method("flag_account", &CorruptionDetector::flag_account);
    register_method("get_flagged_accounts", &CorruptionDetector::get_flagged_accounts);
}

CorruptionDetector::CorruptionDetector() {
    // Constructor
}

CorruptionDetector::~CorruptionDetector() {
    // Destructor
}

void CorruptionDetector::_init() {
    // Initialization
}

bool CorruptionDetector::detect_sybil_attack(const String& UID, const String& newAccountUID) {
    std::string uidStr = UID.utf8().get_data();
    if (playerAccounts[uidStr].size() >= 3) { // Max 3 accounts per player
        flag_account(newAccountUID);
        return true;
    }
    playerAccounts[uidStr].push_back(newAccountUID.utf8().get_data());
    return false;
}

bool CorruptionDetector::detect_bribery(const String& senderUID, const String& receiverUID, int amount) {
    if (amount > 500) { // Threshold for suspicious transfers
        flag_account(senderUID);
        flag_account(receiverUID);
        return true;
    }
    return false;
}

bool CorruptionDetector::detect_hoarding(const String& UID, const String& resource, int amount) {
    if (amount > 1000) { // Threshold for hoarding
        flag_account(UID);
        return true;
    }
    return false;
}

void CorruptionDetector::flag_account(const String& UID) {
    flaggedAccounts.push_back(UID.utf8().get_data());
    Godot::print("⚠️ ACCOUNT FLAGGED: " + UID);
}

Array CorruptionDetector::get_flagged_accounts() {
    Array flagged;
    for (const auto& account : flaggedAccounts) {
        flagged.push_back(account.c_str());
    }
    return flagged;
}