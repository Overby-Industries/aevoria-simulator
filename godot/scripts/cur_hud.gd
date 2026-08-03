extends CanvasLayer

## Combines the compliance dashboard and the violation log into one overlay.
## The integrator calls set_monitor() once the CURComplianceMonitor it wants
## to watch exists -- this node does no NodePath resolution of its own.

@onready var fsm_display = $FSMDisplay
@onready var violation_log = $ViolationLog

func set_monitor(monitor: CURComplianceMonitor):
	fsm_display.set_monitor(monitor)
	violation_log.set_monitor(monitor)
