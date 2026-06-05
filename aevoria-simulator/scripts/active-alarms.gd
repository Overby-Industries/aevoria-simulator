var active_alarms = alarm_system.get_active_alarms()
for alarm in active_alarms:
    print("Alarm: ", alarm["alarmType"], " | ", alarm["message"])