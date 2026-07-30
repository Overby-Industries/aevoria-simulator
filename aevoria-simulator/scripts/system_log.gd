extends Node

## Global scrolling event log -- registered as the SystemLog autoload so
## any script, in any scene, can call `SystemLog.log("...")` and have it
## show up in the console-style HUD panel (console_log_panel.gd) without
## wiring a signal through every intermediate node. This is meant to
## show *real* things happening in the sim (logins, level completions,
## resource rewards) -- not a debug/print replacement.

signal message_logged(entry: Dictionary)

const MAX_ENTRIES = 200

var _entries: Array = []

func log(text: String) -> void:
	var entry = {"time": Time.get_time_string_from_system(), "text": text}
	_entries.append(entry)
	if _entries.size() > MAX_ENTRIES:
		_entries.pop_front()
	message_logged.emit(entry)

## Used to backfill a freshly-opened console_log_panel.gd with whatever
## already happened this session before the panel existed (e.g. the
## login that happens during the very first frame).
func get_recent(n: int) -> Array:
	var start = max(0, _entries.size() - n)
	return _entries.slice(start)
