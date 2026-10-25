class_name FieldStage3D
extends SubViewportContainer
## Décor 3D d'une scène de terrain, vu à hauteur d'yeux depuis une caméra fixe.
##
## Le décor est décrit dans res://data/field/stages/<art>.json (même nom que le
## décor 2D de FieldArt, qui reste la solution de secours). Chaque objet charge
## son modèle importé (.glb dans res://assets/models/field/) s'il existe, sinon
## il est construit en formes simples (boîtes, cylindres...) aux couleurs du
## thème : le jeu reste jouable tant que les modèles ne sont pas livrés. Une
## forme peut aussi recevoir une image ("texture"), si le fichier existe.
## Cahier des charges des modèles et images : docs/design/ASSETS_3D.md.
##
## Les objets liés à un choix ("option") sont cliquables : le clic émet
## spot_pressed(option_id). Aucune règle ici : FieldScreen décide quoi en faire.
## Rendu volontairement en basse définition (stretch_shrink), à la manière des
## premiers jeux 3D. Couleurs : type de thème "IntroArt" (et "IdPhoto" pour la peau).

signal spot_pressed(option_id: String)

const STAGE_DIR := "res://data/field/stages/"

var stage: Dictionary = {}
## Identifiants des choix encore possibles (les autres objets ne réagissent plus).
var active_spots: Array = []

var _viewport: SubViewport
var _world: Node3D
var _camera: Camera3D
var _base_basis := Basis()
var _look := Vector2.ZERO
var _look_target := Vector2.ZERO
## option_id -> {"node": Node3D, "aabb": AABB monde}
var _spots := {}
var _hovered := ""
var _highlight: StandardMaterial3D


static func stage_path(art: String) -> String:
	return STAGE_DIR + art + ".json"


static func has_stage(art: String) -> bool:
	return art != "" and FileAccess.file_exists(stage_path(art))


func _init() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(320, 150)
	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	_viewport.msaa_3d = Viewport.MSAA_DISABLED
	_viewport.handle_input_locally = false
	add_child(_viewport)


## Construit le décor. subject : données du sujet de la scène (modèle éventuel).
func load_stage(art: String, subject: Dictionary = {}) -> bool:
	clear()
	stage = DataLoader.load_json(stage_path(art)) if has_stage(art) else {}
	if stage.is_empty():
		return false
	stretch_shrink = int(stage.get("pixel_size", 3))
	_world = Node3D.new()
	_viewport.add_child(_world)
	_build_environment()
	for light in stage.get("lights", []):
		_world.add_child(_make_light(light))
	for prop: Dictionary in stage.get("props", []):
		var node := _make_prop(prop, subject)
		_world.add_child(node)
		if prop.has("option"):
			_spots[prop.option] = {"node": node, "aabb": AABB()}
	_build_camera()
	_compute_spot_boxes()
	return true


func clear() -> void:
	if _world:
		_viewport.remove_child(_world)
		_world.queue_free()
	_world = null
	_camera = null
	_spots.clear()
	_hovered = ""
	_look = Vector2.ZERO
	_look_target = Vector2.ZERO


func get_spot_ids() -> Array:
	return _spots.keys()


func set_active_spots(ids: Array) -> void:
	active_spots = ids
	if not _hovered in active_spots:
		_set_hovered("")


## Objet visé par un point du contrôle (coordonnées locales), ou "".
func spot_at(local_position: Vector2) -> String:
	if _camera == null:
		return ""
	var point := local_position / float(stretch_shrink)
	var origin := _camera.project_ray_origin(point)
	var direction := _camera.project_ray_normal(point)
	var best := ""
	var best_distance := INF
	for option_id in _spots:
		if not option_id in active_spots:
			continue
		var hit: Variant = _spots[option_id].aabb.intersects_ray(origin, direction)
		if hit != null and origin.distance_to(hit) < best_distance:
			best_distance = origin.distance_to(hit)
			best = option_id
	return best


## Position à l'écran (coordonnées locales) du centre d'un objet : pour les tests
## et pour la bulle d'aide.
func spot_screen_position(option_id: String) -> Vector2:
	if _camera == null or not _spots.has(option_id):
		return Vector2(-1, -1)
	return _camera.unproject_position(_spots[option_id].aabb.get_center()) * float(stretch_shrink)


func press_spot(option_id: String) -> void:
	if option_id in active_spots and _spots.has(option_id):
		spot_pressed.emit(option_id)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		_aim(event.position)
		_set_hovered(spot_at(event.position))
	elif (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) \
			or (event is InputEventScreenTouch and event.pressed):
		_aim(event.position)
		var option_id := spot_at(event.position)
		if option_id != "":
			accept_event()
			press_spot(option_id)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_look_target = Vector2.ZERO
		_set_hovered("")


## Le regard suit le pointeur, dans les limites du décor (on ne se déplace pas).
func _aim(local_position: Vector2) -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var centered := (local_position / size - Vector2(0.5, 0.5)) * 2.0
	_look_target = centered.clamp(Vector2(-1, -1), Vector2(1, 1))


func _process(delta: float) -> void:
	if _camera == null:
		return
	_look = _look.lerp(_look_target, clampf(delta * 3.0, 0.0, 1.0))
	var limits: Array = stage.get("camera", {}).get("look_limits_deg", [12, 6])
	_camera.basis = _base_basis \
			* Basis(Vector3.UP, deg_to_rad(-_look.x * float(limits[0]))) \
			* Basis(Vector3.RIGHT, deg_to_rad(-_look.y * float(limits[1])))


func _set_hovered(option_id: String) -> void:
	if option_id == _hovered:
		return
	if _spots.has(_hovered):
		_set_overlay(_spots[_hovered].node, null)
	_hovered = option_id
	if _spots.has(_hovered):
		_set_overlay(_spots[_hovered].node, _highlight)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if option_id != "" else Control.CURSOR_ARROW


func _set_overlay(node: Node, material: Material) -> void:
	if node is GeometryInstance3D:
		node.material_overlay = material
	for child in node.get_children():
		_set_overlay(child, material)


func _color(name: String) -> Color:
	if name.begins_with("skin"):
		return get_theme_color("skin", "IdPhoto")
	return get_theme_color(name, "IntroArt")


func _vec(values: Variant, default := Vector3.ZERO) -> Vector3:
	if values is Array and values.size() == 3:
		return Vector3(values[0], values[1], values[2])
	return default


func _build_environment() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = _color(stage.get("background", "sky"))
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = _color(stage.get("ambient", "sky_low"))
	environment.ambient_light_energy = float(stage.get("ambient_energy", 1.0))
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	_world.add_child(world_environment)
	_highlight = StandardMaterial3D.new()
	_highlight.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_highlight.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_highlight.albedo_color = Color(_color("accent"), 0.35)


func _build_camera() -> void:
	var settings: Dictionary = stage.get("camera", {})
	_camera = Camera3D.new()
	# Angle horizontal : toute la largeur du décor reste visible, quel que soit
	# le format de l'écran (le cadre est plus haut que large sur certains écrans).
	_camera.keep_aspect = Camera3D.KEEP_WIDTH
	_camera.fov = float(settings.get("fov", 75))
	_world.add_child(_camera)
	_camera.position = _vec(settings.get("position"), Vector3(0, 1.6, 2))
	_camera.look_at(_vec(settings.get("look_at"), Vector3.ZERO))
	_base_basis = _camera.basis
	_camera.current = true


func _make_light(light: Dictionary) -> Light3D:
	var node: Light3D
	match light.get("type", "omni"):
		"spot":
			node = SpotLight3D.new()
			node.spot_range = float(light.get("range", 5))
			node.spot_angle = float(light.get("angle", 35))
		"directional":
			node = DirectionalLight3D.new()
		_:
			node = OmniLight3D.new()
			node.omni_range = float(light.get("range", 5))
	node.light_color = _color(light.get("color", "window"))
	node.light_energy = float(light.get("energy", 1.0))
	node.shadow_enabled = light.get("shadow", false)
	node.position = _vec(light.get("position"))
	node.rotation_degrees = _vec(light.get("rotation_deg"))
	return node


## Un objet du décor : le modèle importé s'il existe, sinon ses formes de secours.
func _make_prop(prop: Dictionary, subject: Dictionary) -> Node3D:
	var model: String = subject.get("model", "") if prop.get("role", "") == "subject" else prop.get("model", "")
	var node: Node3D = null
	if model != "" and ResourceLoader.exists(model):
		var packed := load(model) as PackedScene
		if packed:
			node = packed.instantiate() as Node3D
	if node == null:
		node = Node3D.new()
		for part: Dictionary in prop.get("parts", []):
			node.add_child(_make_part(part))
	node.name = prop.get("id", "prop")
	node.position = _vec(prop.get("position"))
	node.rotation_degrees = _vec(prop.get("rotation_deg"))
	node.scale = _vec(prop.get("scale"), Vector3.ONE)
	return node


func _make_part(part: Dictionary) -> MeshInstance3D:
	# Taille [l, h, p] ; pour un cylindre, une sphère ou une capsule : [diamètre, hauteur].
	var dimensions: Array = part.get("size", [1, 1, 1])
	var size := Vector3(dimensions[0], dimensions[1], dimensions[2] if dimensions.size() > 2 else dimensions[0])
	var mesh: PrimitiveMesh
	match part.get("shape", "box"):
		"cylinder":
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = size.x / 2.0
			cylinder.bottom_radius = float(part.get("bottom", size.x)) / 2.0
			cylinder.height = size.y
			cylinder.radial_segments = 12
			mesh = cylinder
		"sphere":
			var sphere := SphereMesh.new()
			sphere.radius = size.x / 2.0
			sphere.height = size.y
			sphere.radial_segments = 12
			sphere.rings = 6
			mesh = sphere
		"capsule":
			var capsule := CapsuleMesh.new()
			capsule.radius = size.x / 2.0
			capsule.height = size.y
			capsule.radial_segments = 12
			mesh = capsule
		_:
			var box := BoxMesh.new()
			box.size = size
			mesh = box
	var material := StandardMaterial3D.new()
	var color := _color(part.get("color", "paper"))
	if part.has("darken"):
		color = color.darkened(float(part.darken))
	material.albedo_color = color
	# Texture facultative (image fournie dans res://assets/textures/field/) :
	# "tile" la répète tous les N mètres (murs, sols), sinon elle couvre chaque face.
	var texture_path: String = part.get("texture", "")
	if texture_path != "" and ResourceLoader.exists(texture_path):
		material.albedo_texture = load(texture_path)
		material.albedo_color = Color.WHITE
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
		if part.has("tile"):
			material.uv1_triplanar = true
			material.uv1_scale = Vector3.ONE / maxf(float(part.tile), 0.01)
	if part.get("glow", false):
		material.emission_enabled = true
		material.emission = color
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = _vec(part.get("offset"))
	instance.rotation_degrees = _vec(part.get("rotation_deg"))
	return instance


## Boîtes de clic des objets, en coordonnées monde (fusion de leurs maillages,
## ou "hit_box" [l, h, p] centrée sur l'objet si le décor la précise).
func _compute_spot_boxes() -> void:
	for prop: Dictionary in stage.get("props", []):
		if not prop.has("option") or not _spots.has(prop.option):
			continue
		var node: Node3D = _spots[prop.option].node
		var box := AABB()
		if prop.has("hit_box"):
			var extent := _vec(prop.hit_box)
			box = AABB(node.global_position - extent / 2.0, extent)
		else:
			var boxes: Array[AABB] = []
			_collect_aabbs(node, boxes)
			for i in boxes.size():
				box = boxes[i] if i == 0 else box.merge(boxes[i])
		_spots[prop.option].aabb = box


func _collect_aabbs(node: Node, boxes: Array[AABB]) -> void:
	if node is VisualInstance3D:
		boxes.append(node.global_transform * node.get_aabb())
	for child in node.get_children():
		_collect_aabbs(child, boxes)
