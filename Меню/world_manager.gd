extends CanvasLayer

@onready var menu_panel: Control = $Panel
@onready var quests_panel: Control = $Panel/QuestsPanel
@onready var inventory_panel: Control = $InventoryPanel
@onready var inventory_grid: GridContainer = $InventoryPanel/InventoryGrid

const INVENTORY_SLOT_SCENE: PackedScene = preload("res://Меню/inventory_slot.tscn")

@export var slot_min_width: int = 140

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS        # работать в паузе
	set_process_unhandled_input(true)

	visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	menu_panel.visible = true
	quests_panel.visible = false
	inventory_panel.visible = true

	update_inventory_display()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause_menu()

func _toggle_pause_menu() -> void:
	visible = not visible
	get_tree().paused = visible
	if visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		update_inventory_display()
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func update_inventory_display() -> void:
	for c in inventory_grid.get_children():
		c.free()

	# пустой инвентарь — показываем пустую сетку
	#var w: int = max(1, int(inventory_panel.size.x))
	#inventory_grid.columns = max(1, int(w / slot_min_width))


	for item_data in GameState.inventory:
		var slot := INVENTORY_SLOT_SCENE.instantiate()
		inventory_grid.add_child(slot)
		slot.update_slot(item_data)

# кнопки
func _on_start_button_up() -> void:
	visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_exit_menu_button_up() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://Меню/main_menu.tscn")

func _on_exit_button_up() -> void:
	get_tree().quit()

func _on_quests_button_button_up() -> void:
	quests_panel.visible = not quests_panel.visible
