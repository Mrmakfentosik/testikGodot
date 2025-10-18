extends Panel

@onready var item_texture = $ItemTexture
@onready var item_name = $ItemName
@onready var item_bonus = $BonusLabel

func update_slot(item_data: Dictionary):
	# Имя
	item_name.text = item_data.get("name", "???")

	# Цвет по редкости
	match item_data.get("rarity", "common"):
		"common":   item_name.add_theme_color_override("font_color", Color.WHITE)
		"uncommon": item_name.add_theme_color_override("font_color", Color.LIME)
		"rare":     item_name.add_theme_color_override("font_color", Color.MEDIUM_PURPLE)

	# Иконка
	if item_data.has("icon_path"):
		var tex = load(item_data.icon_path)
		print("Загружаем:", item_data.icon_path, " → ", tex)
		if tex:
			item_texture.texture = tex
	else:
		print("❌ load() вернул null")

	# Бонусы
	if item_data.has("bonus"):
		var bonus_text = ""
		for key in item_data.bonus.keys():
			bonus_text += key + ": +" + str(round(item_data.bonus[key] * 100)) + "%\n"
		item_bonus.text = bonus_text
	else:
		item_bonus.text = ""
