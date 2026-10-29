class_name ArbolSagrado
extends StaticBody2D
# Árbol Sagrado de la última zona: está marchito (frame 0)
# y revive (frame 1) cuando todo el ecosistema queda restaurado.

@onready var sprite_2d: Sprite2D = $Sprite2D


func restaurar() -> void:
	var mundo = get_tree().get_first_node_in_group("mundo")
	var tween = create_tween()
	tween.tween_property(sprite_2d, "modulate", Color(3, 3, 3), 0.4)
	await tween.finished
	sprite_2d.frame = 1
	tween = create_tween()
	tween.tween_property(sprite_2d, "modulate", Color.WHITE, 0.6)
	if mundo:
		for i in 10:
			mundo.crear_destello(global_position + Vector2(randf_range(-20, 20), randf_range(-40, 0)))
	# Brillo suave permanente
	var brillo = create_tween().set_loops()
	brillo.tween_property(sprite_2d, "modulate", Color(1.25, 1.25, 1.1), 1.0)
	brillo.tween_property(sprite_2d, "modulate", Color.WHITE, 1.0)
