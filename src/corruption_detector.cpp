#include "corruption_detector.h"
#include <godot_cpp/variant/utility_functions.hpp>

namespace godot {

/**
 * @brief Bind methods and properties to Godot.
 * 
 * This replaces _register_methods() from Godot 3.
 * All methods exposed to GDScript must be bound here.
 */
void CorruptionDetector::_bind_methods() {
    ClassDB::bind_method(D_METHOD("detect_sybil_attack", "UID", "newAccountUID"),
                         &CorruptionDetector::detect_sybil_attack);

    ClassDB::bind_method(D_METHOD("detect_bribery", "senderUID", "receiverUID", "amount"),
                         &CorruptionDetector::detect_bribery);

    ClassDB::bind_method(D_METHOD("detect_hoarding", "UID", "resource", "amount"),
                         &CorruptionDetector::detect_hoarding);

    ClassDB::bind_method(D_METHOD("flag_account", "UID"),
                         &CorruptionDetector::flag_account);

    ClassDB::bind_method(D_METHOD("get_flagged_accounts"),
                         &CorruptionDetector::get_flagged_accounts);
}

/**
 * @brief Constructor.
 * 
 * Initialize internal state here. Avoid calling Godot API functions.
 */
CorruptionDetector::CorruptionDetector() {}

/**
 * @brief Destructor.
 */
CorruptionDetector::~CorruptionDetector() {}

/**
 * @brief Called when the node enters the scene tree.
 * 
 * Useful for initialization that depends on the scene.
 */
void CorruptionDetector::_ready() {
    UtilityFunctions::print("CorruptionDetector initialized.");
}

/**
 * @brief Detects Sybil attacks (multiple fake identities).
 * 
 * A player is allowed up to 3 accounts. Beyond that, the new account is flagged.
 */
bool CorruptionDetector::detect_sybil_attack(const String& UID, const String& newAccountUID) {
    std::string uidStr = UID.utf8().get_data();
    std::string newAccStr = newAccountUID.utf8().get_data();

    // If the player already has too many accounts, flag the new one
    if (playerAccounts[uidStr].size() >= 3) {
        flag_account(newAccountUID);
        return true;
    }

    // Otherwise, register the new account
    playerAccounts[uidStr].push_back(newAccStr);
    return false;
}

/**
 * @brief Detects bribery attempts.
 * 
 * Any transfer above 500 units is considered suspicious.
 */
bool CorruptionDetector::detect_bribery(const String& senderUID, const String& receiverUID, int amount) {
    if (amount > 500) {
        flag_account(senderUID);
        flag_account(receiverUID);
        return true;
    }
    return false;
}

/**
 * @brief Detects resource hoarding.
 * 
 * Any resource amount above 1000 units is considered hoarding.
 */
bool CorruptionDetector::detect_hoarding(const String& UID, const String& resource, int amount) {
    if (amount > 1000) {
        flag_account(UID);
        return true;
    }
    return false;
}

/**
 * @brief Flags an account for corruption review.
 */
void CorruptionDetector::flag_account(const String& UID) {
    std::string uidStr = UID.utf8().get_data();
    flaggedAccounts.push_back(uidStr);

    UtilityFunctions::print("⚠️ ACCOUNT FLAGGED: ", UID);
}

/**
 * @brief Returns all flagged accounts as a Godot Array.
 */
Array CorruptionDetector::get_flagged_accounts() {
    Array flagged;
    for (const auto& account : flaggedAccounts) {
        flagged.push_back(String(account.c_str()));
    }
    return flagged;
}

} // namespace godot
