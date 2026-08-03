extends Node

@onready var alarm_system: AlarmSystem = $AlarmSystem

# Server‑side entry point
func trigger_alarm_rpc(alarm_type, message, corruptor_uid, target_uid, resource):
    if multiplayer.is_server():
        # Trigger locally on the server
        alarm_system.trigger_alarm(alarm_type, message, corruptor_uid, target_uid, resource)

        # Sync to all peers (including newly joined)
        rpc("trigger_alarm_rpc_remote", alarm_type, message, corruptor_uid, target_uid, resource)

# Client‑side handler
@rpc("any_peer")
func trigger_alarm_rpc_remote(alarm_type, message, corruptor_uid, target_uid, resource):
    alarm_system.trigger_alarm(alarm_type, message, corruptor_uid, target_uid, resource)
