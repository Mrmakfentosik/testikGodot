extends Node

@onready var interaction_prompt = $InteractionPrompt
var player_in_range = false
var is_opened = false # Флаг, чтобы сундук нельзя было открыть дважды

@export var chest_type: String = "common" # варианты: common, rare, epic

func set_chest_color():
	var mat = $MeshInstance3D.get_active_material(0).duplicate()
	match chest_type:
		"common": mat.albedo_color = Color("8B4513") # коричневый
		"rare": mat.albedo_color = Color("C0C0C0") # серебро
		"epic": mat.albedo_color = Color("FFD700") # золото
	$MeshInstance3D.set_surface_override_material(0, mat)
func _ready():
	set_chest_color()

func _input(event):
	# Если игрок рядом, сундук не открыт и нажимается 'E'
	if player_in_range and not is_opened and Input.is_action_just_pressed("Ui_use"):
		open_chest()

func open_chest():
	if is_opened: return
	is_opened = true
	interaction_prompt.visible = false

	var new_item = GameState.generate_random_item(chest_type)
	GameState.add_item_to_inventory(new_item)

	var mat = $MeshInstance3D.get_active_material(0).duplicate()
	mat.albedo_color = Color.DARK_GRAY
	$MeshInstance3D.set_surface_override_material(0, mat)

	print("Сундук [", chest_type, "] дал предмет: ", new_item)




func _on_interaction_zone_body_entered(body):
	if body.is_in_group("player") and not is_opened:

		player_in_range = true
		interaction_prompt.visible = true

func _on_interaction_zone_body_exited(body):
	if body.is_in_group("player"):
		
		player_in_range = false
		interaction_prompt.visible = false
