extends StaticBody3D

@export var npc_id: String = "Strazhnik_Petya"
@export var dialogue_lines: Array[String] = [
	"Привет, путник!",
	"Добро пожаловать в мой мир."
]
@export var dialogue_panel: Panel
@export var dialogue_label: Label

# --- НОВИНКА: Ссылка на нашу 3D-подсказку ---
@onready var interaction_prompt = $InteractionPrompt

var player_in_range = false
var dialogue_active = false
var dialogue_finished = false
var current_line_index = 0

func _ready():
	if dialogue_panel:
		dialogue_panel.visible = false
	if GameState.has_talked_to_npc(npc_id):
		dialogue_finished = true

func _on_area_3d_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		# --- НОВИНКА: Показываем подсказку, если диалог не закончен ---
		if not dialogue_finished:
			interaction_prompt.visible = true

func _on_area_3d_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		# --- НОВИНКА: Прячем подсказку, когда игрок уходит ---
		interaction_prompt.visible = false
		end_dialogue()

func _input(event):
	if player_in_range and Input.is_action_just_pressed("Ui_use"):
		if dialogue_finished:
			# Когда все сказано, мы больше не прячем подсказку, она и так не появится
			dialogue_label.text = "Я все сказал."
			dialogue_panel.visible = true
		elif not dialogue_active:
			start_dialogue()
		else:
			advance_dialogue()

func start_dialogue():
	# --- НОВИНКА: Прячем подсказку, когда начинается диалог ---
	interaction_prompt.visible = false
	dialogue_active = true
	current_line_index = 0
	dialogue_panel.visible = true
	dialogue_label.text = dialogue_lines[current_line_index]

func advance_dialogue():
	current_line_index += 1
	if current_line_index < dialogue_lines.size():
		dialogue_label.text = dialogue_lines[current_line_index]
	else:
		dialogue_finished = true
		GameState.mark_npc_as_talked(npc_id)
		end_dialogue()
		var quest_manager = get_tree().get_first_node_in_group("quest_manager")
		if quest_manager and not quest_manager.quest_active:
			quest_manager.start_quest()


func end_dialogue():
	dialogue_active = false
	if dialogue_panel:
		dialogue_panel.visible = false
