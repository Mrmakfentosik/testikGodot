# ЭТОТ СКРИПТ ТЕПЕРЬ ДОЛЖЕН БЫТЬ НА УЗЛЕ "PauseMenu" (CanvasLayer)
extends CanvasLayer

@onready var inventory_panel = $InventoryPanel
@onready var inventory_grid = $InventoryPanel/InventoryGrid
const INVENTORY_SLOT_SCENE = preload("res://Меню/inventory_slot.tscn") # <-- Укажи правильный путь!
# Эта функция будет вызываться для обработки нажатия ESC
func _unhandled_input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		# Включаем или выключаем видимость самого себя
		visible = not visible
		# Ставим или снимаем игру с паузы
		get_tree().paused = visible
		
		# Управляем курсором мыши
		if visible:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			ViewItems()
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func ViewItems():
# Если панель не видна, проверяем, пуст ли инвентарь
	if GameState.inventory.is_empty():
		print("Инвентарь пуст!")
		# Ничего не делаем, если инвентарь пуст
	else:
		# Если в инвентаре есть предметы, показываем панель и обновляем её
		inventory_panel.visible = true
		update_inventory_display()

func _on_exit_menu_button_up() -> void:
	# Обязательно снимаем игру с паузы перед выходом в меню
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Меню/main_menu.tscn")


func _on_start_button_up() -> void:
	visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_exit_button_up() -> void:
	get_tree().quit()


func _on_quests_button_button_up() -> void:
	$Panel/QuestsPanel.visible = not $Panel/QuestsPanel.visible

# Новая функция для кнопки "Инвентарь"
func _on_inventory_button_up():
	inventory_panel.visible = not inventory_panel.visible
	if inventory_panel.visible:
		update_inventory_display()

# Новая функция для обновления отображения инвентаря
func update_inventory_display():
	# Очищаем старые слоты
	for child in inventory_grid.get_children():
		child.queue_free()

	# Создаём новые слоты для каждого предмета
	for item_data in GameState.inventory:
		var slot = INVENTORY_SLOT_SCENE.instantiate()
		inventory_grid.add_child(slot)

		# ВАЖНО: вызываем update_slot и передаём данные
		slot.update_slot(item_data)
		print("✅ update_slot вызван для:", item_data)



func _on_intentory_button_up() -> void:
	# Если панель уже видна, просто прячем её
	if inventory_panel.visible:
		inventory_panel.visible = false
		return # Выходим из функции

	# Если панель не видна, проверяем, пуст ли инвентарь
	if GameState.inventory.is_empty():
		print("Инвентарь пуст!")
		# Ничего не делаем, если инвентарь пуст
		return
	else:
		# Если в инвентаре есть предметы, показываем панель и обновляем её
		inventory_panel.visible = true
		update_inventory_display()
