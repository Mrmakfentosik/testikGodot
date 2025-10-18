extends Node

@export var base_damage: float = 5.0
@export var crit_chance: float = 0.20
@export var crit_multiplier: float = 2.0

var bonus_damage_percent: float = 0.0
var bonus_melee_area_percent: float = 0.0
var health_regen_per_second: float = 0.5

var player

func _ready():
	player = get_parent()

func _process(delta):
	if health_regen_per_second > 0:
		# Теперь вызываем heal() напрямую у родителя (игрока)
		player.heal(health_regen_per_second * delta)

func get_total_damage() -> float:
	return base_damage * (1.0 + bonus_damage_percent)

func get_total_crit_chance() -> float:
	return crit_chance

func apply_damage_buff(percent_increase: float):
	bonus_damage_percent += percent_increase

func apply_melee_area_buff(percent_increase: float):
	bonus_melee_area_percent += percent_increase
	if player and player.has_node("Camera3D/MeleeArea"):
		var melee_area_shape = player.get_node("Camera3D/MeleeArea/CollisionShape3D").shape
		melee_area_shape.size *= (1.0 + percent_increase)
