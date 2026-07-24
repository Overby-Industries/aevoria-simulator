extends Node

@onready var direct_democracy_os: DirectDemocracyOS = $DirectDemocracyOS
@onready var resource_commons: ResourceCommons = $ResourceCommons
@onready var alarm_system: AlarmSystem = $AlarmSystem
@onready var corruption_detector: CorruptionDetector = $CorruptionDetector
@onready var my_class: MyClass = $MyClass

func _ready():
    print("All C++ GDExtension classes loaded successfully.")
