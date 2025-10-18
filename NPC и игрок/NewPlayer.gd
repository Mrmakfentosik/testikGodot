extends CharacterBody3D

# --- Переменные ---
@export var speed = 5.0
@export var jump_velocity = 4.5
@export var acceleration = 30.0
@export var dash_speed: float = 20.0
@export var mouse_sensitivity = 0.2
@export var max_health: int = 100

var current_health: int
var is_dashing = false
var is_dead = false
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# --- Ссылки на дочерние узлы ---
@onready var camera = $Camera3D
@onready var melee_area = $Camera3D/MeleeArea
@onready var swing_sound = $SwingSound
@onready var dash_cooldown_timer = $DashCooldownTimer
@onready var dash_duration_timer = $DashDurationTimer
@onready var stats = $PlayerStats

# --- Ссылки на UI ---
var health_bar: ProgressBar
var death_screen: Panel
var restart_timer: Timer

const DAMAGE_NUMBER_SCENE = preload("res://Урон/damage_number.tscn")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	current_health = max_health
	health_bar = get_tree().root.find_child("HealthBar", true, false)
	update_health_display()
	
	death_screen = get_tree().root.find_child("DeathScreen", true, false)
	restart_timer = get_tree().root.find_child("RestartTimer", true, false)
	if restart_timer:
		restart_timer.timeout.connect(restart_level)

func _input(event):
	if is_dead: return

	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		camera.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		attack()

func _physics_process(delta):
	if is_dead:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y -= gravity * delta


	if Input.is_action_just_pressed("dash") and dash_cooldown_timer.is_stopped():
		var dash_input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		var dash_direction_3d = (transform.basis * Vector3(dash_input.x, 0, dash_input.y)).normalized()
		
		if dash_direction_3d == Vector3.ZERO:
			dash_direction_3d = -transform.basis.z
		
		velocity.x = dash_direction_3d.x * dash_speed
		velocity.z = dash_direction_3d.z * dash_speed
		
		is_dashing = true
		dash_cooldown_timer.start()
	else:
		var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

		if direction:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * acceleration)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * acceleration)
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)

		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = jump_velocity

	move_and_slide()

func attack():
	var bodies_in_area = melee_area.get_overlapping_bodies()
	var did_hit = false

	for body in bodies_in_area:
		if body.is_in_group("enemies"):
			var total_damage = stats.get_total_damage()
			var crit_chance = stats.get_total_crit_chance()
			var is_critical = false
			
			if randf() < crit_chance:
				is_critical = true
				total_damage *= stats.crit_multiplier
			
			var number_instance = DAMAGE_NUMBER_SCENE.instantiate()
			get_tree().root.add_child(number_instance)
			number_instance.global_position = body.global_position + Vector3.UP * 1.0
			number_instance.setup(total_damage, is_critical)
			
			body.take_damage(total_damage)
			did_hit = true
			break
	
	if not did_hit:
		swing_sound.play()

func take_damage(amount: int):
	if is_dead: return
	current_health -= amount
	if current_health < 0: current_health = 0
	
	if health_bar:
		var tween = create_tween()
		tween.tween_property(health_bar, "value", current_health, 0.3)
		
	if current_health <= 0 and not is_dead:
		die()

func heal(amount: float):
	if is_dead: return
	current_health += amount
	if current_health > max_health: current_health = max_health
	update_health_display()

func die():
	if is_dead: return
	is_dead = true
	
	if death_screen: death_screen.visible = true
	if restart_timer: restart_timer.start()
	
	set_process_input(false)
	set_physics_process(false)

func restart_level():
	get_tree().reload_current_scene()

func update_health_display():
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

func _on_dash_duration_timer_timeout():
	is_dashing = false
