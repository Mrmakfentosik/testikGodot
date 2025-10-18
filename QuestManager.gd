extends Node

var quest_active: bool = false
var killed_enemies: int = 0
var required_kills: int = 3

# Ссылка на твой QuestText
@onready var quest_text: Label = get_tree().root.find_child("QuestText", true, false)

func start_quest():
	quest_active = true
	killed_enemies = 0
	if quest_text:
		quest_text.text = "Задание: убей врагов (0/%d)" % required_kills

func enemy_killed():
	if quest_active:
		killed_enemies += 1
		update_ui()
		if killed_enemies >= required_kills:
			complete_quest()

func update_ui():
	if quest_active and quest_text:
		quest_text.text = "Задание: убей врагов (%d/%d)" % [killed_enemies, required_kills]

func complete_quest():
	quest_active = false
	if quest_text:
		quest_text.text = "Квест выполнен!"
