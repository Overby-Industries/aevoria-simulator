extends Node

@onready var reg_engine: RegulatoryEngine = $RegulatoryEngine

func _ready():
    print("Initializing Aevoria Regulatory Engine...")

    # 1. Set up the laws
    reg_engine.add_law(
        LawDomain.SILICON,
        "CUR-S.4.1",
        "Graceful Decommissioning",
        2,
        false
    )

    # 2. Simulate a player action
    var error_msg := ""

    var is_legal = test_silicon_action(1, false, error_msg)

    if not is_legal:
        print("⚠️ [REGULATORY VIOLATION]: ", error_msg)
    else:
        print("✅ [ACTION AUTHORIZED]")

func test_silicon_action(tier: int, consent: bool, err: String) -> bool:
    # Calls a simplified C++ validation method
    return reg_engine.validate_action_simplified(tier, consent, err)
