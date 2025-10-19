extends Node

# --- Старые системы ---
var npcs_talked_to: Dictionary = {}
var quests: Dictionary = {}
var active_quests: Array[String] = []
var completed_quests: Array[String] = []
var quest_database := {
	"kill_two_enemies": {
		"title": "Угроза на равнинах",
		"description": "Уничтожь двоих монстров.",
		"target_count": 2
	}
}

# --- НОВАЯ СИСТЕМА ПРЕДМЕТОВ ---
var inventory: Array = []   # массив словарей-предметов

var item_database := {
	"simple_sword": {
		"name": "Простой меч",
		"type": "weapon",
		"base_damage": 10,
		"damage_variance": 3,
		"rarity": "common",
		"icon_path": "res://UIScrin/Sword.png"
	},
	"buff_damage_10": {
		"name": "Бафф: +10% урона",
		"type": "buff",
		"buff_type": "damage",
		"value": 0.10,
		"rarity": "common",
		"icon_path": "res://UIScrin/Книга.png"
	},
	"rusty_axe": {
		"name": "Ржавый топор",
		"type": "weapon",
		"base_damage": 14,
		"damage_variance": 5,
		"rarity": "uncommon"
	},
	"magic_staff": {
		"name": "Магический посох",
		"type": "weapon",
		"base_damage": 8,
		"damage_variance": 2,
		"rarity": "rare"
	}
}

func _ready() -> void:
	randomize()  # чтобы дроп не повторялся каждый запуск

# Случайный предмет по типу сундука
func generate_random_item(chest_type: String = "common") -> Dictionary:
	var rarity_weights := {
		"common": {"common": 0.8, "uncommon": 0.15, "rare": 0.05},
		"rare":   {"common": 0.4, "uncommon": 0.4,  "rare": 0.2},
		"epic":   {"common": 0.1, "uncommon": 0.4,  "rare": 0.5}
	}

	var weights: Dictionary = rarity_weights.get(chest_type, rarity_weights["common"])
	var filtered_ids: Array[String] = []

	# фильтрация по редкости (ВАЖНО: доступ к словарю через ["ключ"])
	for id in item_database.keys():
		var item: Dictionary = item_database[id]
		if weights.has(item["rarity"]):
			# взвешенная выборка
			var times := int(weights[item["rarity"]] * 100.0)
			for i in range(times):
				filtered_ids.append(id)

	if filtered_ids.is_empty():
		push_warning("generate_random_item: нет подходящих предметов для chest_type=%s" % chest_type)
		return {}

	var random_id: String = filtered_ids[randi() % filtered_ids.size()]
	var template: Dictionary = item_database[random_id]

	var new_item: Dictionary = {
		"name": template["name"],
		"type": template["type"],
		"rarity": template["rarity"]
	}

	if template.has("base_damage"):
		new_item["damage"] = int(template["base_damage"]) + randi_range(-int(template["damage_variance"]), int(template["damage_variance"]))

	if template.has("icon_path"):
		new_item["icon_path"] = template["icon_path"]
		print("🎨 Иконка предмета:", new_item["name"], "→", new_item["icon_path"])
	else:
		print("⚠️ У предмета", new_item["name"], "нет icon_path!")

	# Бонусы с шансом
	if randf() < 0.3:
		new_item["bonus"] = {
			"crit_chance": randf_range(0.05, 0.15)
		}

	return new_item

# Создание предмета по id (вариант без весов)
func generate_item(item_id: String) -> Dictionary:
	if not item_database.has(item_id):
		push_warning("generate_item: item_id '%s' не найден" % item_id)
		return {}
	var template: Dictionary = item_database[item_id]
	var new_item: Dictionary = {
		"name": template["name"],
		"type": template["type"]
	}
	if template.has("base_damage"):
		new_item["damage"] = int(template["base_damage"]) + randi_range(-int(template["damage_variance"]), int(template["damage_variance"]))
	if template.has("icon_path"):
		new_item["icon_path"] = template["icon_path"]
	return new_item

# Добавление в инвентарь + обновление UI, если открыто
func add_item_to_inventory(item_data: Dictionary) -> void:
	if item_data.is_empty():
		return
	inventory.append(item_data)
	print("В инвентарь добавлен:", item_data)

	var pause_menu := get_tree().root.find_child("PauseMenu", true, false)
	if pause_menu and pause_menu.has_method("_update_inventory_display"):
		pause_menu.call("_update_inventory_display")

# --- КВЕСТЫ (без изменений по логике, только доступы к словарям) ---
func add_quest(quest_id: String) -> void:
	if not quests.has(quest_id) and quest_database.has(quest_id):
		var quest_data: Dictionary = quest_database[quest_id]
		quests[quest_id] = {
			"title": quest_data["title"],
			"description": quest_data["description"],
			"progress": 0,
			"target": quest_data["target_count"],
			"completed": false
		}
		active_quests.append(quest_id)
		print("Новый квест добавлен:", quest_id)

func advance_quest(quest_id: String, amount: int = 1) -> void:
	if quests.has(quest_id) and not quests[quest_id]["completed"]:
		var quest: Dictionary = quests[quest_id]
		quest["progress"] += amount
		print("Прогресс квеста '", quest_id, "': ", quest["progress"], "/", quest["target"])
		if quest["progress"] >= quest["target"]:
			complete_quest(quest_id)

func complete_quest(quest_id: String) -> void:
	if quests.has(quest_id):
		quests[quest_id]["completed"] = true
		active_quests.erase(quest_id)
		completed_quests.append(quest_id)
		print("Квест выполнен:", quest_id)

# --- Старые функции ---
func mark_npc_as_talked(npc_id: String) -> void:
	npcs_talked_to[npc_id] = true

func has_talked_to_npc(npc_id: String) -> bool:
	return npcs_talked_to.has(npc_id)
