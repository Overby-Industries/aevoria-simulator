extends Node

@onready var direct_democracy_os = null
@onready var resource_commons = null
@onready var alarm_system = null          # New class
@onready var corruption_detector = null  # New class
@onready var my_class = null

func _ready():
    if GDNativeLibrary.load("libaevoria", "libaevoria.windows.x86_64.dll", true) == OK:
        direct_democracy_os = GDNativeLibrary.get_native_handle("DirectDemocracyOS")
        resource_commons = GDNativeLibrary.get_native_handle("ResourceCommons")
        alarm_system = GDNativeLibrary.get_native_handle("AlarmSystem")          # New class
        corruption_detector = GDNativeLibrary.get_native_handle("CorruptionDetector")  # New class
        my_class = GDNativeLibrary.get_native_handle("MyClass")
        print("Loaded MyClass successfully!")
        print("GDNative libraries loaded successfully!")
    else:
        print("Failed to load GDNative libraries!")