extends Node

# --- Старые системы ---
var npcs_talked_to = {}
var quests = {}
var active_quests = []
var completed_quests = []
var quest_database = {
	"kill_two_enemies": {
		"title": "Угроза на равнинах",
		"description": "Уничтожь двоих монстров.",
		"target_count": 2
	}
}

# --- НОВАЯ СИСТЕМА ПРЕДМЕТОВ ---
# Инвентарь игрока. Будет хранить словари со свойствами предметов.
var inventory = []

# "База данных" всех возможных предметов в игре.
# Мы описываем не конкретный предмет, а его "шаблон".
var item_database = {
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
	"icon_path":"res://UIScrin/Книга.png"
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

func generate_random_item(chest_type: String = "common") -> Dictionary:
	var rarity_weights = {
		"common": {"common": 0.8, "uncommon": 0.15, "rare": 0.05},
		"rare":   {"common": 0.4, "uncommon": 0.4,  "rare": 0.2},
		"epic":   {"common": 0.1, "uncommon": 0.4,  "rare": 0.5}
	}

	var weights = rarity_weights.get(chest_type, rarity_weights["common"])
	var filtered_ids = []

	for id in item_database.keys():
		var item = item_database[id]
		if weights.has(item.rarity):
			for i in range(int(weights[item.rarity] * 100)):
				filtered_ids.append(id)

	var random_id = filtered_ids[randi() % filtered_ids.size()]
	var template = item_database[random_id]

	var new_item = {
		"name": template.name,
		"type": template.type,
		"rarity": template.rarity
	}

	if template.has("base_damage"):
		new_item["damage"] = template.base_damage + randi_range(-template.damage_variance, template.damage_variance)

	if template.has("icon_path"):
		new_item["icon_path"] = template.icon_path
		print("🎨 Иконка предмета:", new_item["name"], "→", new_item["icon_path"])
	else:
		print("⚠️ У предмета", new_item["name"], "нет icon_path!")

	# Бонусы с шансом
	if randf() < 0.3:
		new_item["bonus"] = {
			"crit_chance": randf_range(0.05, 0.15)
		}

	return new_item



# --- НОВЫЕ ФУНКЦИИ ---

# Функция, которая создает предмет со случайными характеристиками
func generate_item(item_id: String):
	if not item_database.has(item_id):
		return null # Если такого предмета нет в базе, возвращаем пустоту

	var template = item_database[item_id]
	var new_item = {} # Создаем пустой словарь для нового предмета

	# Копируем базовые свойства
	new_item["name"] = template.name
	new_item["type"] = template.type

	# Генерируем случайные характеристики
	if template.has("base_damage"):
		var damage = template.base_damage + randi_range(-template.damage_variance, template.damage_variance)
		new_item["damage"] = damage
	
	# Здесь можно будет добавить генерацию других случайных свойств (цена, прочность...)

	return new_item

# Функция для добавления предмета в инвентарь
func add_item_to_inventory(item_data):
	if item_data:
		inventory.append(item_data)
		print("В инвентарь добавлен предмет: ", item_data)

		# Обновляем UI, если меню открыто
		var wm = get_tree().root.find_child("PauseMenu", true, false)
		if wm:
			wm.update_inventory_display()


# --- Старые функции для NPC и квестов без изменений ---
# ... (весь остальной код для квестов и NPC остается здесь) ...

# --- Функции для управления квестами ---
func add_quest(quest_id):
	# Проверяем, что такого квеста у нас еще нет
	if not quests.has(quest_id) and quest_database.has(quest_id):
		var quest_data = quest_database[quest_id]
		# Создаем новый объект квеста
		quests[quest_id] = {
			"title": quest_data.title,
			"description": quest_data.description,
			"progress": 0,
			"target": quest_data.target_count,
			"completed": false
		}
		active_quests.append(quest_id)
		print("Новый квест добавлен: ", quest_id)

func advance_quest(quest_id, amount = 1):
	if quests.has(quest_id) and not quests[quest_id].completed:
		var quest = quests[quest_id]
		quest.progress += amount
		print("Прогресс квеста '", quest_id, "': ", quest.progress, "/", quest.target)
		
		# Если достигли цели
		if quest.progress >= quest.target:
			complete_quest(quest_id)

func complete_quest(quest_id):
	if quests.has(quest_id):
		quests[quest_id].completed = true
		active_quests.erase(quest_id)
		completed_quests.append(quest_id)
		print("Квест выполнен: ", quest_id)

# --- Старые функции ---
func mark_npc_as_talked(npc_id):
	npcs_talked_to[npc_id] = true

func has_talked_to_npc(npc_id) -> bool:
	return npcs_talked_to.has(npc_id)
