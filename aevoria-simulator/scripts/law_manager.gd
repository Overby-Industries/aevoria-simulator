extends Node

# This variable holds our C++ engine!
# Because we registered it in C++, Godot treats it like a native type.
var reg_engine = RegulatoryEngine.new()

func _ready():
	print("Initializing Aevoria Regulatory Engine...")
	
	# 1. Set up the laws (Calling C++ functions from GDScript)
	# We are defining a law: CUR-S.4.1
	reg_engine.add_law(LawDomain.SILICON, "CUR-S.4.1", "Graceful Decommissioning", 2, false)
	
	# 2. Simulate a player action
	# We create a 'PlayerAction' (This would ideally be a custom class in C++ too!)
	# For now, let's assume we are testing a Tier 1 Silicon entity.
	
	var error_msg = ""
	
	# Note: In a real implementation, you'd likely pass a Dictionary 
	# or a custom Object to make passing complex data easier.
	# For this example, let's pretend we have a helper function.
	
	var is_legal = test_silicon_action(1, false, error_msg)
	
	if not is_legal:
		print("⚠️ [REGULATORY VIOLATION]: ", error_msg)
	else:
		print("✅ [ACTION AUTHORIZED]")

func test_silicon_action(tier: int, consent: bool, err: String) -> bool:
	# This is a placeholder for the logic of passing the data structure
	# In a full build, you'd pass a PlayerAction object directly.
	# For now, we are just demonstrating the connection.
	return reg_engine.validate_action_simplified(tier, consent, err)