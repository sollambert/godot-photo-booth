@tool
extends SubViewport

var old_scene
var queue_camera_transform = false

## Scene to render
@export var scene: PackedScene
## Directory containing input scenes that will be rendered when the Render All button is pressed
@export var input_path: String
## Output path for all rendered images
@export var destination: String
## Button for creating a new render of loaded scene
@export var render: bool = false:
	set(v):
		if destination:
			render_thumbnail(destination)
		render = false
## Button for initiating a render for all objects within input path directory
@export var render_all: bool = false:
	set(v):
		if input_path and destination:
			render_all_thumbnails(input_path, destination)
		render_all = false
## Delay for snapping a new render, can sometimes prevent issues with scene loading and allows time for engine to name instantiated node properly
@export var render_delay: float = 0.25
## Vector to designate camera global position
@export var camera_location: Vector3 = Vector3(1.25, .666, 1.25):
	set(v):
		camera_location = v
		queue_camera_transform = true
## Rotation value for photo booth Camera3D to rotate around world origin from current position
@export var camera_rotation: float = 30:
	set(v):
		camera_rotation = v
		queue_camera_transform = true
## Offset to apply to the y axis of the camera global position after all rotations and transforms are completed 
@export var y_offset: float = 0:
	set(v):
		y_offset = v
		queue_camera_transform = true
## Minimum FOV for photo booth camera perspective
@export var fov_min: float = 1:
	set(v):
		fov_min = v
		adjust_fov()
## Maximum FOV for photo booth camera perspective
@export var fov_max: float = 50.0:
	set(v):
		fov_max = v
		adjust_fov()
## Base FOV value that is multiplied by the maximum of values contained within mesh's AABB size Vector
@export var fov_base: float = 50.0:
	set(v):
		fov_base = v
		adjust_fov()

# Components
var object: MeshInstance3D
var camera: Camera3D
static var timer: Timer

func _ready():
	timer = get_node("Timer")
	timer.wait_time = 0.1
	camera = get_node("Camera3D")
	pass

func _process(_delta):
	# check if camera transform is queued
	if queue_camera_transform:
		camera.global_position = camera_location
		adjust_fov()
		rotate_camera()
		queue_camera_transform = false
	# check if scene to render has changed
	if old_scene != scene:
		old_scene = scene
		if is_instance_valid(object):
			object.queue_free()
		if scene:
			var instance = scene.instantiate()
			if instance is MeshInstance3D:
				object = instance
			else:
				instance.queue_free()
				scene = null
		if object and not object.is_queued_for_deletion():
			self.add_child(object)
			queue_camera_transform = true

# Sets current camera global position, rotates camera around world origin, and applies y_offset to global position
func rotate_camera():
	var rot = deg_to_rad(camera_rotation - 90) + camera.rotation.y
	var origin = Vector3(0,0,0)
	camera.global_translate (-origin)
	camera.transform = camera.transform.rotated(Vector3(0,1,0), -rot)
	camera.global_translate (origin)
	camera.global_position.y += y_offset
	if is_instance_valid(object):
		camera.look_at(object.global_position)

# Calculates and sets current camera FOV
func adjust_fov():
	if is_instance_valid(object):
		var aabb = object.mesh.get_aabb()
		var fov = fov_base * maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
		fov = clampf(fov, fov_min, fov_max)
		camera.set_perspective(fov, camera.near, camera.far)

# Creates thumbnail and saves to provided destination
func render_thumbnail(destination: String) -> void:
	get_texture().get_image().save_png(destination + "/" + object.name + ".png")
	
# Recursively renders all thumbnails in given directory and outputs to destination
func render_all_thumbnails(input_path: String, destination: String):
	var scenes = []
	if !DirAccess.dir_exists_absolute(destination):
		DirAccess.make_dir_recursive_absolute(destination)
	var dir = DirAccess.open(input_path)
	if (dir):
		var sub_dirs = dir.get_directories()
		var files = dir.get_files()
		for file in files:
			scene = load(dir.get_current_dir() + "/" + file)
			timer.start(render_delay)
			await timer.timeout
			render_thumbnail(destination)
		for sub_dir in sub_dirs:
			render_all_thumbnails(dir.get_current_dir() + "/" + sub_dir, destination  + sub_dir)
		pass
