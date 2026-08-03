extends Node

# RegulatoryEngine extends RefCounted, not Node, so it can't live in the
# scene tree as a $NodePath child — it's instantiated directly instead.
var reg_engine: RegulatoryEngine

func _ready():
    print("Initializing Aevoria Regulatory Engine...")

    reg_engine = RegulatoryEngine.new()

    # 1. Set up the laws
    reg_engine.add_law(
        RegulatoryEngine.SILICON,
        "CUR-S.4.1",
        "Graceful Decommissioning",
        2,
        false
    )

    # 2. Simulate a player action
    var error_msg = test_silicon_action(1, false)

    if error_msg != "":
        print("⚠️ [REGULATORY VIOLATION]: ", error_msg)
    else:
        print("✅ [ACTION AUTHORIZED]")

func test_silicon_action(tier: int, consent: bool) -> String:
    # Calls the simplified C++ validation method — returns "" if legal,
    # or the violation message if not.
    return reg_engine.validate_action_simplified(tier, consent)
