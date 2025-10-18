extends StaticBody3D

# Мы удалили @export var item_id_inside, так как предмет будет случайным

@onready var interaction_prompt = $InteractionPrompt
var player_in_range = false
var is_opened = false

func _input(event):
	if player_in_range and not is_opened and Input.is_action_just_pressed("Ui_use"):
		open_chest()

func open_chest():
	is_opened = true
	interaction_prompt.visible = false
	print("Случайный сундук открыт!")

	# --- ВОТ ГЛАВНОЕ ИЗМЕНЕНИЕ ---
	# 1. Получаем все ключи (ID предметов) из нашей базы данных
	var all_item_ids = GameState.item_database.keys()
	
	# 2. Выбираем случайный ID из этого списка
	var random_item_id = all_item_ids.pick_random()
	
	# 3. Генерируем предмет по этому случайному ID
	var new_item = GameState.generate_item(random_item_id)
	
	# 4. Добавляем его в инвентарь
	GameState.add_item_to_inventory(new_item)
	
	# Код для смены цвета остается без изменений
	var shared_material = $MeshInstance3D.get_active_material(0)
	var unique_material = shared_material.duplicate()
	$MeshInstance3D.set_surface_override_material(0, unique_material)
	unique_material.albedo_color = Color.DARK_GRAY

# Все функции ниже остаются без изменений
func _on_interaction_zone_body_entered(body):
	if body.is_in_group("player") and not is_opened:
		player_in_range = true
		interaction_prompt.visible = true

func _on_interaction_zone_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		interaction_prompt.visible = false
