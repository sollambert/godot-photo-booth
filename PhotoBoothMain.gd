@tool
extends EditorPlugin
class_name PhotoBooth

var dock = preload("res://addons/godot-photo-booth/PhotoBoothDock.tscn").instantiate()
static var editor: EditorInterface

static var queue_tab_change = false

func _process(_delta):
	if queue_tab_change:
		editor.set_main_screen_editor("3D")
		queue_tab_change = false

func _enter_tree():
	add_control_to_dock(DOCK_SLOT_LEFT_BL, dock)
	editor = get_editor_interface()

static func open_photo_booth():
	editor.open_scene_from_path("res://addons/godot-photo-booth/PhotoBooth.tscn")
	queue_tab_change = true
