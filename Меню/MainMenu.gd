extends Control

func _on_start_button_up():
	# Укажи здесь путь к твоей основной игровой сцене
	get_tree().change_scene_to_file("res://Мир/word.tscn")


func _on_exit_button_up() -> void:
	get_tree().quit()
