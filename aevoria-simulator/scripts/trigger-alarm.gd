extends Node

@onready var alarm_system: AlarmSystem = $AlarmSystem

func _ready():
    # Example: Trigger a bribery alarm
    alarm_system.trigger_alarm(
        "Suspicious Bribery",
        "Player X sent 1000 CCs to Player Y before Vote #123.",
        "Billionaire_42",
        "Voter_99",
        "1000 CCs"
    )
