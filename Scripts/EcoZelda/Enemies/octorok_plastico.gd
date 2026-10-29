extends CharacterBody2D
# Monstruo Plástico: el Octorok de EcoZelda. Camina usando sus 4 RayCast2D
# (igual que el Octorok Red del proyecto) y dispara tapas plásticas.

signal derrotado

const PROYECTIL = preload("res://Scenes/EcoZelda/Objetos/proyectil.tscn")

#Necesitamos una referencia a las animaciones
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

#Referencia a los raycast
@onready var ray_cast_2d_up: RayCast2D = $RayCast2D_UP
@onready var ray_cast_2d_2_down: RayCast2D = $RayCast2D2_DOWN
@onready var ray_cast_2d_3_left: RayCast2D = $RayCast2D3_LEFT
@onready var ray_cast_2d_4_right: RayCast2D = $RayCast2D4_RIGHT

@export var SPEED: float = 30.0
@export var vida: int = 2
@export var tiempo_disparo: float = 2.5

var direction: Vector2 = Vector2.DOWN
var empuje := Vector2.ZERO
var timer_disparo: float = 0.0

var array_direction: Array = [
	Vector2.UP,
	Vector2.DOWN,
	Vector2.LEFT,
	Vector2.RIGHT]


func _ready() -> void:
	add_to_group("enemigo")
	direction = array_direction.pick_random()
	timer_disparo = randf_range(1.0, tiempo_disparo)


func _physics_process(delta: float) -> void:
	#Validar la dirección hacia donde mira el enemigo
	if direction.x > 0:
		animated_sprite_2d.play("walk_right")
	elif direction.x < 0:
		animated_sprite_2d.play("walk_left")
	elif direction.y < 0:
		animated_sprite_2d.play("walk_up")
	elif direction.y > 0:
		animated_sprite_2d.play("walk_down")

	empuje = empuje.move_toward(Vector2.ZERO, 500 * delta)
	velocity = direction * SPEED + empuje
	move_and_slide()

	#Si el raycast hacia donde camina detecta algo sólido, cambia de dirección
	if direction == Vector2.UP and ray_cast_2d_up.is_colliding():
		change_direction()
	elif direction == Vector2.DOWN and ray_cast_2d_2_down.is_colliding():
		change_direction()
	elif direction == Vector2.LEFT and ray_cast_2d_3_left.is_colliding():
		change_direction()
	elif direction == Vector2.RIGHT and ray_cast_2d_4_right.is_colliding():
		change_direction()

	timer_disparo -= delta
	if timer_disparo <= 0:
		timer_disparo = tiempo_disparo
		disparar()


func change_direction() -> void:
	var avaliable_directions: Array = []
	if not ray_cast_2d_up.is_colliding():
		avaliable_directions.append(Vector2.UP)
	if not ray_cast_2d_2_down.is_colliding():
		avaliable_directions.append(Vector2.DOWN)
	if not ray_cast_2d_3_left.is_colliding():
		avaliable_directions.append(Vector2.LEFT)
	if not ray_cast_2d_4_right.is_colliding():
		avaliable_directions.append(Vector2.RIGHT)
	if avaliable_directions.is_empty():
		return
	direction = avaliable_directions.pick_random()


func disparar() -> void:
	var proyectil = PROYECTIL.instantiate()
	proyectil.direccion = direction
	proyectil.position = position + direction * 8
	get_parent().add_child(proyectil)


func recibir_danio(origen: Vector2) -> void:
	vida -= 1
	empuje = (global_position - origen).normalized() * 200
	var tween = create_tween()
	tween.tween_property(animated_sprite_2d, "modulate", Color(4, 4, 4), 0.05)
	tween.tween_property(animated_sprite_2d, "modulate", Color.WHITE, 0.1)
	if vida <= 0:
		morir()


func morir() -> void:
	set_physics_process(false)
	var mundo = get_tree().get_first_node_in_group("mundo")
	if mundo:
		mundo.crear_destello(global_position)
	GameManager.enemigos_derrotados += 1
	GameManager.sumar_puntos(50)
	derrotado.emit()
	queue_free()
