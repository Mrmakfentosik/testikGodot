extends Panel

@onready var item_texture: TextureRect = $MarginContainer/VBoxContainer/ItemTexture
@onready var item_name: Label = $MarginContainer/VBoxContainer/ItemName
@onready var item_bonus: Label = $MarginContainer/VBoxContainer/BonusLabel

func update_slot(item_data: Dictionary) -> void:
	item_name.text = str(item_data.get("name", "???"))

	match str(item_data.get("rarity", "common")):
		"common":
			item_name.add_theme_color_override("font_color", Color.WHITE)
		"uncommon":
			item_name.add_theme_color_override("font_color", Color.LIME)
		"rare":
			item_name.add_theme_color_override("font_color", Color.MEDIUM_PURPLE)
		_:
			item_name.add_theme_color_override("font_color", Color.WHITE)

	var tex: Texture2D = null
	if item_data.has("icon_path"):
		tex = load(item_data["icon_path"]) as Texture2D
	item_texture.texture = tex
	item_texture.visible = tex != null

	if item_data.has("bonus"):
		var bonus := item_data["bonus"] as Dictionary
		var lines: Array[String] = []
		for k in bonus.keys():
			lines.append("%s: +%d%%" % [str(k), int(round(float(bonus[k]) * 100.0))])
		item_bonus.text = "\n".join(lines)
	else:
		item_bonus.text = ""
