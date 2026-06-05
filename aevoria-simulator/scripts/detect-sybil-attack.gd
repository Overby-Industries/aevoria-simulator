# Example: Detect a Sybil attack
var is_sybil = corruption_detector.detect_sybil_attack("Player1", "FakeAccount1")
if is_sybil:
    print("Sybil attack detected!")

# Example: Detect bribery
var is_bribe = corruption_detector.detect_bribery("Player1", "Player2", 1000)
if is_bribe:
    print("Bribery detected!")

# Example: Get flagged accounts
var flagged = corruption_detector.get_flagged_accounts()
print("Flagged Accounts: ", flagged)