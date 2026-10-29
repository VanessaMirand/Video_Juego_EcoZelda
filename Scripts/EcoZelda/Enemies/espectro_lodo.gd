extends CharacterBody2D
# Espectro de Lodo: persigue al jugador cuando está cerca y lanza bolas de lodo.

signal derrotado

const PROYECTIL = preload("res://Scenes/EcoZelda/Objetos/proyectil.tscn")

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

@export var SPEED: float = 24.0
@export var vida: int = 6
@export var distancia_vision: float = 150.0
@export var tiempo_disparo: float = 2.2

var direction := Vector2.LEFT
var empuje := Vector2.ZERO
var timer_disparo: float = 1.5
var timer_paseo: float = 0.0


func _ready() -> void:
	add_to_group("enemigo")
	animated_sprite_2d.play("flotar")


func _physics_process(delta: float) -> void:
	var jugador = get_tree().get_first_node_in_group("jugador")
	var ve_jugador: bool = jugador and global_position.distance_to(jugador.global_position) < distancia_vision

	if ve_jugador:
		direction = global_position.direction_to(jugador.global_position)
	else:
		timer_paseo -= delta
		if timer_paseo <= 0:
			timer_paseo = randf_range(1.0, 2.5)
			direction = Vector2.from_angle(randf() * TAU)

	animated_sprite_2d.flip_h = direction.x > 0
	empuje = empuje.move_toward(Vector2.ZERO, 400 * delta)
	velocity = direction * SPEED + empuje
	move_and_slide()

	timer_disparo -= delta
	if ve_jugador and timer_disparo <= 0:
		timer_disparo = tiempo_disparo
		var proyectil = PROYECTIL.instantiate()
		proyectil.es_lodo = true
		proyectil.velocidad = 70.0
		proyectil.direccion = direction
		proyectil.position = position + direction * 10
		get_parent().add_child(proyectil)


func recibir_danio(origen: Vector2) -> void:
	vida -= 1
	empuje = (global_position - origen).normalized() * 160
	var tween = create_tween()
	tween.tween_property(animated_sprite_2d, "modulate", Color(4, 4, 4), 0.05)
	tween.tween_property(animated_sprite_2d, "modulate", Color.WHITE, 0.1)
	# Se encoge un poco con cada golpe: el lodo se va secando
	animated_sprite_2d.scale = Vector2.ONE * (0.6 + 0.4 * vida / 6.0)
	if vida <= 0:
		set_physics_process(false)
		var mundo = get_tree().get_first_node_in_group("mundo")
		if mundo:
			for i in 5:
				mundo.crear_destello(global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10)))
		GameManager.enemigos_derrotados += 1
		GameManager.sumar_puntos(100)
		derrotado.emit()
		queue_free()
