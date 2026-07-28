extends Node

@onready var direct_democracy_os: DirectDemocracyOS = $DirectDemocracyOS
@onready var resource_commons: ResourceCommons = $ResourceCommons
@onready var alarm_system: AlarmSystem = $AlarmSystem
@onready var corruption_detector: CorruptionDetector = $CorruptionDetector
@onready var my_class: MyClass = $MyClass

func _ready():
    print("All C++ GDExtension classes loaded successfully.")
    _build_back_button()

func _build_back_button():
    var canvas = CanvasLayer.new()
    add_child(canvas)

    var button = Button.new()
    button.text = "Back to Level Select"
    button.theme = ThemeBootstrap.theme
    button.set_anchors_preset(Control.PRESET_TOP_LEFT)
    button.position = Vector2(20, 620)
    button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn"))
    canvas.add_child(button)
