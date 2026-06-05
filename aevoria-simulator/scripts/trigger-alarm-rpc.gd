# Sync an alarm to all players
func trigger_alarm_rpc(alarmType, message, corruptorUID, targetUID, resource):
    if multiplayer.is_server():
        alarm_system.trigger_alarm(alarmType, message, corruptorUID, targetUID, resource)
        rpc("trigger_alarm_rpc", alarmType, message, corruptorUID, targetUID, resource)

@rpc("any_peer")
func trigger_alarm_rpc(alarmType, message, corruptorUID, targetUID, resource):
    alarm_system.trigger_alarm(alarmType, message, corruptorUID, targetUID, resource)