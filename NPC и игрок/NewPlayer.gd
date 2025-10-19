extends CharacterBody3D

# ------------------ ДВИЖЕНИЕ / ДЭШ ------------------
@export var speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var acceleration: float = 30.0
@export var dash_speed: float = 20.0
@export var dash_time: float = 0.12
@export var dash_cooldown: float = 0.35
@export var mouse_sensitivity: float = 0.2

# ------------------ ЗДОРОВЬЕ ------------------
@export var max_health: int = 100

# ------------------ БОЙ (параметры) ------------------
@export var attack_cooldown: float = 0.35
@export var attack_window_start: float = 0.08   # через сколько после клика включить хитбокс
@export var attack_window_end: float = 0.22     # когда выключить хитбокс
@export var knockback_strength: float = 6.0
#@export var hitstop_time: float = 0.06          # микропаузa при попадании

# ------------------ СОСТОЯНИЕ ------------------
var current_health: int = 0
var is_dead: bool = false

# дэш
var is_dashing: bool = false
var dash_dir: Vector3 = Vector3.ZERO
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity") as float

# атака (внутреннее состояние)
var _is_attacking: bool = false
var _window_active: bool = false
var _attack_queued: bool = false
var _hit_this_swing: Dictionary = {}        # Set-подобно: ключ = Node, значение = true

# ------------------ СЦЕНЫ ------------------
const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://Урон/damage_number.tscn")

# ------------------ УЗЛЫ СЦЕНЫ ------------------
@onready var camera: Camera3D = $Camera3D
@onready var melee_area: Area3D = $Camera3D/MeleeArea
@onready var swing_sound: AudioStreamPlayer3D = $SwingSound
@onready var dash_cooldown_timer: Timer = $DashCooldownTimer
@onready var dash_duration_timer: Timer = $DashDurationTimer
@onready var attack_cd_timer: Timer = $AttackCooldown
@onready var stats: Node = $PlayerStats   # оставляем Node: внутри вызываем через call()

# ------------------ УЗЛЫ UI ------------------
var health_bar: ProgressBar
var death_screen: Panel
var restart_timer: Timer

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	current_health = max_health

	# Таймеры дэша
	dash_duration_timer.one_shot = true
	dash_cooldown_timer.one_shot = true
	dash_duration_timer.wait_time = dash_time
	dash_cooldown_timer.wait_time = dash_cooldown
	if not dash_duration_timer.timeout.is_connected(_on_dash_duration_timer_timeout):
		dash_duration_timer.timeout.connect(_on_dash_duration_timer_timeout)

	# Таймер атаки
	attack_cd_timer.one_shot = true
	attack_cd_timer.wait_time = attack_cooldown
	melee_area.monitoring = false   # хитбокс выключен по умолчанию

	# UI
	health_bar = get_tree().root.find_child("HealthBar", true, false) as ProgressBar
	death_screen = get_tree().root.find_child("DeathScreen", true, false) as Panel
	restart_timer = get_tree().root.find_child("RestartTimer", true, false) as Timer
	if restart_timer and not restart_timer.timeout.is_connected(_on_restart_timeout):
		restart_timer.timeout.connect(_on_restart_timeout)
	_update_health_ui()

func _input(event: InputEvent) -> void:
	if is_dead:
		return

	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		camera.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90.0), deg_to_rad(90.0))

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_attack()

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	# Гравитация
	if not is_on_floor():
		velocity.y -= gravity * delta

	if is_dashing:
		# фикс. направление и постоянная скорость
		velocity.x = dash_dir.x * dash_speed
		velocity.z = dash_dir.z * dash_speed
	else:
		# Обычное движение
		var input2: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		var wish_dir: Vector3 = (transform.basis * Vector3(input2.x, 0.0, input2.y)).normalized()

		if wish_dir != Vector3.ZERO:
			var t: float = clamp(acceleration * delta, 0.0, 1.0)
			velocity.x = lerp(velocity.x, wish_dir.x * speed, t)
			velocity.z = lerp(velocity.z, wish_dir.z * speed, t)
		else:
			var decel: float = acceleration * delta
			velocity.x = move_toward(velocity.x, 0.0, decel)
			velocity.z = move_toward(velocity.z, 0.0, decel)

		# Прыжок
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = jump_velocity

		# Старт дэша
		if Input.is_action_just_pressed("dash") and dash_cooldown_timer.is_stopped():
			var dir3d: Vector3 = wish_dir
			if dir3d == Vector3.ZERO:
				dir3d = -transform.basis.z  # вперёд по взгляду
			_start_dash(dir3d)

	# Во время активного окна проверяем попадания
	if _window_active:
		var bodies: Array = melee_area.get_overlapping_bodies()
		for body in bodies:
			if _hit_this_swing.has(body):
				continue
			if body is Node and body.is_in_group("enemies"):
				_hit_this_swing[body] = true
				_hit_enemy(body)

	move_and_slide()

# ------------------ ДЭШ ------------------
func _start_dash(dir: Vector3) -> void:
	is_dashing = true
	dash_dir = dir.normalized()
	dash_duration_timer.start()
	dash_cooldown_timer.start()

func _on_dash_duration_timer_timeout() -> void:
	is_dashing = false

# ------------------ АТАКА ------------------
func _try_attack() -> void:
	if _is_attacking:
		_attack_queued = true
		return
	if not attack_cd_timer.is_stopped():
		return
	_start_attack()

func _start_attack() -> void:
	_is_attacking = true
	_window_active = false
	_hit_this_swing.clear()
	swing_sound.play()

	# окно урона
	_activate_hitbox_delayed()
	_finish_attack_delayed()

	# КД
	attack_cd_timer.start()

func _activate_hitbox_delayed() -> void:
	# старт окна
	await get_tree().create_timer(attack_window_start).timeout
	_window_active = true
	melee_area.monitoring = true

	# конец окна
	var dur: float = max(0.0, attack_window_end - attack_window_start)
	await get_tree().create_timer(dur).timeout
	_window_active = false
	melee_area.monitoring = false

func _finish_attack_delayed() -> void:
	await get_tree().create_timer(attack_window_end).timeout
	_is_attacking = false

	# простая комбо-очередь: если кликом поставили очередь — повторим удар
	if _attack_queued:
		_attack_queued = false
		if not attack_cd_timer.is_stopped():
			await attack_cd_timer.timeout
		_start_attack()

func _hit_enemy(enemy: Node) -> void:
	# урон/крит из твоих статов
	var total_damage: float = 0.0
	var crit_chance: float = 0.0
	var crit_mult: float = 1.0

	if stats:
		if stats.has_method("get_total_damage"):
			total_damage = float(stats.call("get_total_damage"))
		if stats.has_method("get_total_crit_chance"):
			crit_chance = float(stats.call("get_total_crit_chance"))
		# безопасно читаем экспортную переменную без has_variable()
		var v = stats.get("crit_multiplier")    # вернёт null, если свойства нет
		if v != null:
			crit_mult = float(v)

	var is_critical: bool = randf() < crit_chance
	if is_critical:
		total_damage *= crit_mult

	enemy.call_deferred("take_damage", total_damage)

	var kb_dir: Vector3 = -transform.basis.z * knockback_strength
	if enemy.has_method("apply_knockback"):
		enemy.call_deferred("apply_knockback", kb_dir)

	#_do_hitstop(hitstop_time)

	if DAMAGE_NUMBER_SCENE:
		var num := DAMAGE_NUMBER_SCENE.instantiate() as Node3D
		if num:
			get_tree().root.add_child(num)
			if enemy is Node3D:
				num.global_position = (enemy as Node3D).global_position + Vector3.UP
			num.call_deferred("setup", total_damage, is_critical)


func _do_hitstop(dur: float) -> void:
	var prev: float = Engine.time_scale
	Engine.time_scale = 0.05
	# процессим всегда, игнорируя time_scale
	await get_tree().create_timer(dur, false, true).timeout
	Engine.time_scale = prev

# ------------------ ЗДОРОВЬЕ / СМЕРТЬ ------------------
func take_damage(amount: int) -> void:
	if is_dead:
		return
	current_health -= amount
	if current_health < 0:
		current_health = 0
	_update_health_ui()
	if current_health <= 0:
		_die()

func heal(amount: float) -> void:
	if is_dead:
		return
	current_health = min(current_health + int(round(amount)), max_health)
	_update_health_ui()

func _die() -> void:
	if is_dead:
		return
	is_dead = true
	if death_screen:
		death_screen.visible = true
	if restart_timer:
		restart_timer.start()
	set_process_input(false)
	set_physics_process(false)

func _on_restart_timeout() -> void:
	get_tree().reload_current_scene()

func _update_health_ui() -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
