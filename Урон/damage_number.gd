extends Label3D

# Эта функция будет вызываться извне, чтобы настроить цифру
func setup(damage_amount: int, is_critical: bool):
	text = str(damage_amount)
	
	# Если удар критический, делаем текст больше и ярче
	if is_critical:
		font_size = 180
		modulate = Color.YELLOW
	
	# Создаем анимацию (Tween)
	var tween = create_tween()
	# Анимируем движение вверх на 1.5 метра за 0.8 секунды
	tween.tween_property(self, "position:y", position.y + 1.5, 0.8).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	# Параллельно анимируем исчезновение (от полной видимости до полной прозрачности)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.8)
	
	# Когда анимация закончится, удаляем узел
	await tween.finished
	queue_free()
