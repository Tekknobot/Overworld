extends Area2D

@export var direction = Vector2.LEFT

var last_position: Vector2
var this_position: Vector2

var pos : Vector2
var old_pos : Vector2
var moving : bool

var moved = false

var tile_pos

@export var unit_team: int
@export var unit_name: String
@export var unit_movement: int
@export var unit_attack_range: int
@export var unit_type: String
@export var unit_num: int
@export var unit_status: String
@export var selected = false

@onready var root = $"."
@export  var healthbar : ProgressBar
@export  var levelbar : ProgressBar

@onready var godzillastream = $"../GodzillaStream"

var attacked = false
var zombies = []
var humans = []
var godzilla = []
var all_units = []

var structures: Array[Area2D]
var buildings = []
var towers = []
var stadiums = []
var districts = []

var landmines = []

var only_once = true

var kill_count = 0
var coord

var in_water = false

@onready var Map = $"../TileMap"
var play_once = false

# Called when the node enters the scene tree for the first time.
func _ready():
	zombies = get_tree().get_nodes_in_group("zombies")
	humans = get_tree().get_nodes_in_group("humans")
	godzilla = get_tree().get_nodes_in_group("godzilla")
	
	all_units.append_array(zombies)
	all_units.append_array(humans)
	all_units.append_array(godzilla)

	buildings = get_tree().get_nodes_in_group("buildings")
	towers = get_tree().get_nodes_in_group("towers")
	stadiums = get_tree().get_nodes_in_group("stadiums")
	districts = get_tree().get_nodes_in_group("districts")

	structures.append_array(buildings)
	structures.append_array(towers)
	structures.append_array(stadiums)
	structures.append_array(districts)
	
	old_pos = global_position;
	pos = global_position;
	
	await get_tree().create_timer(1).timeout
	check_water()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	#set pos to current position
	pos = global_position;
	if pos - old_pos:
		moving = true;
	else:
		moving = false;
	#create old pos from pos
	old_pos = pos;
		
	# Face towards moving direction
	last_position = this_position
	this_position = self.position

	if Map.moving == true:
		if this_position.x > last_position.x:
			scale.x = -1
			direction = Vector2.RIGHT
		if this_position.x < last_position.x:
			scale.x = 1	
			direction = Vector2.LEFT
		
	self.tile_pos = get_node("../TileMap").local_to_map(self.position)
	self.coord = self.tile_pos

	# Z index layering
	self.z_index = (tile_pos.x + tile_pos.y) + 1
	
	#A star
	if self.is_in_group("dead"):
		pass
	else:
		get_node("../TileMap").astar_grid.set_point_solid(tile_pos, true)	

	if self.moved == true and self.attacked == true:
		self.modulate = Color8(110, 110, 110)
	else:
		self.modulate = Color8(255, 255, 255)

	var unit_global_position = self.position
	var unit_pos = get_node("../TileMap").local_to_map(unit_global_position)

	if self.unit_name == "Godzilla":
		if levelbar.value >= levelbar.max_value:
			if play_once == false:
				play_once = true
				play_roar()				
			levelbar.value = 0
			healthbar.value = levelbar.max_value
			var tween: Tween = create_tween()
			tween.tween_property(self, "modulate:v", 1, 0.5).from(5)					
			
		if healthbar.value <= 0:
			if play_once == false:
				play_once = true
				play_roar()
				
			self.get_child(0).play("death")
			var tween: Tween = create_tween()
			tween.tween_property(self, "modulate:v", 1, 0.5).from(5)	
			await get_tree().create_timer(0.68).timeout		
			self.position.y -= 1500	
			self.self_modulate.a = 0			

func get_closest_attack_humans():
	play_once = false
	var all_players = get_tree().get_nodes_in_group("humans")
	var closest_player = null
 
	if (all_players.size() > 0):
		closest_player = all_players[0]
		for player in all_players:
			var distance_to_this_player = global_position.distance_squared_to(player.global_position)	
			var distance_to_closest_player = global_position.distance_squared_to(closest_player.global_position)
			if (distance_to_this_player < distance_to_closest_player):
				closest_player = player
				
	return closest_player

func get_closest_attack_cpu():
	play_once = false
	var all_players = get_tree().get_nodes_in_group("cpu")
	var closest_player = null
 
	if (all_players.size() > 0):
		closest_player = all_players[0]
		for player in all_players:
			var distance_to_this_player = global_position.distance_squared_to(player.global_position)	
			var distance_to_closest_player = global_position.distance_squared_to(closest_player.global_position)
			if (distance_to_this_player < distance_to_closest_player):
				closest_player = player
				
	return closest_player

func get_closest_attack_structure():
	play_once = false
	var all_structures = get_tree().get_nodes_in_group("structures")
	var closest_structure = null
 
	if (all_structures.size() > 0):
		closest_structure = all_structures[0]
		for structure in all_structures:
			if structure.is_in_group("demolished"):
				return
			else:
				pass
			var distance_to_this_player = global_position.distance_squared_to(structure.global_position)	
			var distance_to_closest_player = global_position.distance_squared_to(closest_structure.global_position)
			if (distance_to_this_player < distance_to_closest_player):
				closest_structure = structure
				
	return closest_structure

func get_closest_attack_godzilla():
	play_once = false
	var all_godzilla = get_tree().get_nodes_in_group("godzilla")
	var closest_godzilla = null
 
	if (all_godzilla.size() > 0):
		closest_godzilla = all_godzilla[0]
		for godzilla in all_godzilla:
			var distance_to_this_player = global_position.distance_squared_to(godzilla.global_position)	
			var distance_to_closest_godzilla = global_position.distance_squared_to(closest_godzilla.global_position)
			if (distance_to_this_player < distance_to_closest_godzilla):
				closest_godzilla = godzilla
				
	return closest_godzilla

func check_water():
	if get_node("../TileMap").get_cell_source_id(0, self.tile_pos) == 0:
		self.get_child(0).play("water")	
		self.in_water = true
		return true
		
func check_land():
	if get_node("../TileMap").get_cell_source_id(0, self.tile_pos) != 0:
		self.get_child(0).play("default")	
		self.in_water = false
		return true		
	
func play_roar():
	godzillastream.stream = godzillastream.map_sfx[9]
	godzillastream.play()	
