extends CharacterBody3D

@export var max_health: int = 100
var current_health: int

@export var move_speed: float = 3.0
@export var attack_damage: int = 10
var player = null
var is_chasing = false
var player_in_attack_range = false

#Эфект
const HIT_EFFECT = preload("res://Эфекты/hit_effect.tscn")

# --- НОВИНКА: Флаг, что враг мертв ---
var is_dead = false

# --- НОВИНКА: Ссылка на "GPS-навигатор" ---
@onready var nav_agent = $NavigationAgent3D

@onready var health_label = $HealthLabel
@onready var chase_timer = $ChaseTimer
@onready var attack_timer = $AttackTimer
# Добавим ссылки на звуки, чтобы не искать их каждый раз
@onready var hit_sound = $HitSound
@onready var death_sound = $DeathSound

func _ready():
	current_health = max_health
	update_health_label()

func _physics_process(delta):
	# Если враг мертв или не видит игрока, он не двигается
	if is_dead or not player:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	# --- НОВАЯ ЛОГИКА ДВИЖЕНИЯ С НАВИГАЦИЕЙ ---
	# 1. Устанавливаем цель для навигатора (позицию игрока)
	nav_agent.target_position = player.global_position
	
	# 2. Получаем следующую точку на проложенном пути
	var next_path_position = nav_agent.get_next_path_position()
	
	# 3. Рассчитываем направление к этой точке
	var direction = global_position.direction_to(next_path_position)
	
	# 4. Двигаемся в этом направлении
	velocity = direction * move_speed
	
	# 5. Применяем движение
	move_and_slide()
	
	# Заставляем врага всегда смотреть на игрока по горизонтали
	look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z))

func attempt_attack():
	# --- ИЗМЕНЕНИЕ: Не атакуем, если мертвы ---
	if is_dead:
		return
	if player_in_attack_range and attack_timer.is_stopped():
		attack_timer.start()

func _on_attack_timer_timeout():
	# --- ИЗМЕНЕНИЕ: Не наносим урон, если мертвы ---
	if is_dead:
		return
	if player_in_attack_range and player:
		player.take_damage(attack_damage)
		attempt_attack()

func take_damage(amount: int):
	# --- ИЗМЕНЕНИЕ: Не получаем урон, если мертвы ---
	if is_dead:
		return

	hit_sound.play()
	
	var effect_instance = HIT_EFFECT.instantiate()
	get_tree().root.add_child(effect_instance)
	effect_instance.global_position = global_position
# --- ВОТ ВАЖНАЯ СТРОЧКА ---
	effect_instance.restart() # Эта команда перезапускает и запускает one-shot эффект
	
	current_health -= amount
	if current_health < 0:
		current_health = 0
	
	update_health_label()
	
	if current_health <= 0:
		die()

func die():
	# --- ИЗМЕНЕНИЕ: Проверяем, не умерли ли мы уже ---
	if is_dead:
		return
	is_dead = true # Устанавливаем флаг смерти
	death_sound.play()
	
	set_process(false)
	set_physics_process(false)
	
	$CollisionShape3D.disabled = true
	$DetectionZone.monitoring = false
	$AttackZone.monitoring = false
	
	var tween = create_tween()
	tween.tween_property(self, "rotation:x", deg_to_rad(90), 0.5).set_trans(Tween.TRANS_QUART)
	
	await tween.finished
	queue_free()
	var quest_manager = get_tree().get_first_node_in_group("quest_manager")
	if quest_manager:
		quest_manager.enemy_killed()
	

# --- Остальные функции без изменений ---
func _on_detection_zone_body_entered(body):
	if body.is_in_group("player"):
		player = body
		is_chasing = true
		chase_timer.stop()

func _on_detection_zone_body_exited(body):
	if body.is_in_group("player"):
		chase_timer.start()

func _on_attack_zone_body_entered(body):
	if body.is_in_group("player"):
		player_in_attack_range = true
		attempt_attack()

func _on_attack_zone_body_exited(body):
	if body.is_in_group("player"):
		player_in_attack_range = false

func _on_chase_timer_timeout():
	is_chasing = false
	player = null

func update_health_label():
	if health_label:
		health_label.text = str(current_health) + " / " + str(max_health)
