class_name Proyectil
extends Area2D
# Tapa plástica (Octorok) o bola de lodo (Espectro) que lanzan los enemigos.

@export var velocidad: float = 90.0
@export var es_lodo: bool = false

var direccion := Vector2.RIGHT

@onready var sprite_2d: Sprite2D = $Sprite2D


func _ready() -> void:
	sprite_2d.frame = 1 if es_lodo else 0
	body_entered.connect(_on_body_entered)
	await get_tree().create_timer(3.0).timeout
	queue_free()


func _physics_process(delta: float) -> void:
	position += direccion * velocidad * delta
	sprite_2d.rotation += 10 * delta


func _on_body_entered(body: Node2D) -> void:
	if body is EcoPlayer:
		body.recibir_danio(1, global_position)
	queue_free()
