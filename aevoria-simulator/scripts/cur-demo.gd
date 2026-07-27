extends Node

# Demonstrates the CUR compliance FSM: register an operational licence,
# submit a compliant event, then an over-budget one that opens a violation.
# Connects to the monitor's signals so the transition and the violation both
# print through the normal Godot signal path, not a direct return-value read.

@onready var monitor: CURComplianceMonitor = $CURComplianceMonitor
@onready var hud = $CurHud

func _ready():
	monitor.transition_accepted.connect(_on_transition_accepted)
	monitor.violation_detected.connect(_on_violation_detected)
	hud.set_monitor(monitor)

	var charter = monitor.register_entity(
		"charter-helga-07", monitor.EC_ECONOMIC, monitor.SUBJ_OPERATIONAL_LICENSE)

	monitor.submit_operational(charter, monitor.EV_MINING_OPERATION,
		{"debris_units": 40, "debris_limit": 100}, 1)

	monitor.submit_operational(charter, monitor.EV_MINING_OPERATION,
		{"debris_units": 400, "debris_limit": 100}, 2)

func _on_transition_accepted(entity_id, _axis, from_state, to_state, _trigger, citation):
	print("[CUR] ", entity_id, ": ", from_state, " -> ", to_state, " (", citation, ")")

func _on_violation_detected(entity_id, violation_id, citation):
	print("[CUR] violation on ", entity_id, ": ", violation_id, " — ", citation)
