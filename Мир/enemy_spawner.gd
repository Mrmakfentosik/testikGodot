extends Node3D

# --- НАСТРОЙКИ СПАУНА ---
const ENEMY_SCENE = preload("res://Враги/enemy.tscn")

@export var min_spawn_radius: float = 15.0
@export var max_spawn_radius: float = 25.0
# Новая переменная: высота, с которой мы "роняем" луч
@export var spawn_height: float = 10.0 

var player = null
@onready var spawn_timer = $SpawnTimer

func _ready():
	player = get_tree().get_first_node_in_group("player")
	spawn_timer.start()

func _on_spawn_timer_timeout():
	if not player:
		return
	
	# 1. Рассчитываем случайную точку В ВОЗДУХЕ над игроком
	var random_direction = Vector3.RIGHT.rotated(Vector3.UP, randf_range(0, TAU))
	var random_distance = randf_range(min_spawn_radius, max_spawn_radius)
	var ray_start_point = player.global_position + random_direction * random_distance
	ray_start_point.y += spawn_height # Поднимаем точку высоко вверх

	# 2. "Стреляем" лучом вниз из этой точки
	var space_state = get_world_3d().direct_space_state
	# Создаем параметры для луча: откуда, куда, и что он должен видеть (только слой 1)
	var query = PhysicsRayQueryParameters3D.create(ray_start_point, ray_start_point - Vector3.UP * 50, 1)
	var result = space_state.intersect_ray(query)
	
	# 3. Проверяем результат
	if result:
		# Если луч во что-то попал, используем точку столкновения как место спауна
		var spawn_position = result.position
		
		# 4. Создаем врага, как и раньше
		var new_enemy = ENEMY_SCENE.instantiate()
		get_parent().add_child(new_enemy)
		new_enemy.global_position = spawn_position
		
		
