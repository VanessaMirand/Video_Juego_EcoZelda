class_name Barrera
extends StaticBody2D
# Montón de basura que bloquea la salida de la zona.
# Desaparece cuando la zona queda restaurada.

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D


func abrir() -> void:
	collision_shape_2d.set_deferred("disabled", true)
	var mundo = get_tree().get_first_node_in_group("mundo")
	if mundo:
		for i in 4:
			mundo.crear_destello(global_position + Vector2(randf_range(-6, 6), randf_range(-14, 14)))
	var tween = create_tween().set_parallel()
	tween.tween_property(sprite_2d, "scale", Vector2(1.4, 0.1), 0.5)
	tween.tween_property(sprite_2d, "modulate:a", 0.0, 0.5)
	await tween.finished
	queue_free()
