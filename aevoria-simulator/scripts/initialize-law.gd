extends Node

var reg_engine = RegulatoryEngine.new()

func _ready():
    # 1. Initialize the CUR (The Law)
    # CUR-S.4.1: Silicon entities must be Tier 2 to perform decommissioning.
    reg_engine.add_law(LawDomain.SILICON, "CUR-S.4.1", "Graceful Decommissioning Tier Requirement", 2, false)
    
    # CUR-H.2.5: Human interaction requires consent.
    reg_engine.add_law(LawDomain.HUMAN, "CUR-H.2.5", "Mandatory Consent", 0, true)

    # 2. Test an ILLEGAL action (A Tier 1 Silicon entity trying to decommission)
    var illegal_action = PlayerAction.new()
    illegal_action.actor_domain = LawDomain.SILICON
    illegal_action.actor_tier = 1 # Too low!
    illegal_action.action_type = "decommission"
    
    var error_msg = ""
    var is_legal = reg_engine.validate_action(illegal_action, error_msg)
    
    if not is_legal:
        print("ALARM: " + error_msg) # Output: ALARM: Violation: CUR-S.4.1 - Actor tier too low.
    else:
        print("Action authorized.")

    # 3. Test a LEGAL action
    var legal_action = PlayerAction.new()
    legal_action.actor_domain = LawDomain.HUMAN
    legal_action.actor_tier = 0
    legal_action.has_consent = true
    
    if reg_engine.validate_action(legal_action, error_msg):
        print("Human action authorized.")