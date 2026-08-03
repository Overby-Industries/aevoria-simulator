extends Node

## The game launches fullscreen by default (project.godot's
## display/window/size/mode) to avoid the fixed-position corner HUD
## panels overlapping each other at small windowed sizes. That would trap
## anyone who wants windowed mode without this -- F11 is the standard PC
## game convention for toggling it, so it's handled once here globally
## rather than duplicated in every level script.

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		var window = get_window()
		if window.mode == Window.MODE_FULLSCREEN or window.mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
			window.mode = Window.MODE_WINDOWED
		else:
			window.mode = Window.MODE_FULLSCREEN
