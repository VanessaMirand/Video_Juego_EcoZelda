extends "res://Scripts/Enemies/moldorm.gd"
# Gusano de Basura: reutiliza el movimiento del Moldorm del proyecto
# (serpenteo + segmentos que siguen a la cabeza) y le agrega daño y señal de derrota.

signal derrotado

var invulnerable: bool = false


func _ready():
	super._ready()
	add_to_group("enemigo")
	# Los segmentos cuelgan de un Node, así que no heredan la visibilidad
	# del nodo Amenaza: se esconden hasta que el gusano empieza a moverse.
	for segmento in active_segments:
		segmento.visible = false


func _physics_process(delta):
	super._physics_process(delta)
	for segmento in active_segments:
		segmento.visible = true


func recibir_danio(_origen: Vector2) -> void:
	if invulnerable:
		return
	invulnerable = true
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(4, 4, 4), 0.05)
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)

	var mundo = get_tree().get_first_node_in_group("mundo")
	if active_segments.is_empty():
		set_physics_process(false)
		if mundo:
			for i in 6:
				mundo.crear_destello(global_position + Vector2(randf_range(-12, 12), randf_range(-12, 12)))
		GameManager.enemigos_derrotados += 1
		GameManager.sumar_puntos(150)
		derrotado.emit()
		queue_free()
		return

	if mundo:
		mundo.crear_destello((active_segments.back() as Node2D).global_position)
	take_damage()
	await get_tree().create_timer(0.35).timeout
	invulnerable = false
