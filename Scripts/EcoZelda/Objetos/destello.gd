extends AnimatedSprite2D
# Pequeña chispa que aparece cuando una parte del mapa se limpia.

func _ready() -> void:
	play("brillo")
	await animation_finished
	queue_free()
