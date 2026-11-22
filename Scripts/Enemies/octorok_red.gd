extends CharacterBody2D

# Necesitamos una referencia a las animaciones
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

# Referencia a los raycast
@onready var ray_cast_2d_up: RayCast2D = $RayCast2D_UP
@onready var ray_cast_2d_2_down: RayCast2D = $RayCast2D2_DOWN
@onready var ray_cast_2d_3_left: RayCast2D = $RayCast2D3_LEFT
@onready var ray_cast_2d_4_right: RayCast2D = $RayCast2D4_RIGHT

# Una variable para aplicar velocidad de movimiento
@export var SPEED : float = 30.0
@export var max_hp : int = 1

var hp : int = 1

# Variable para almacenar la dirección hacia donde se desplaza el enemigo
var direction : Vector2 = Vector2.DOWN

var array_direction: Array = [
	Vector2.UP,
	Vector2.DOWN,
	Vector2.LEFT,
	Vector2.RIGHT
]

# Se ejecuta una sola vez cuando inicia el juego
func _ready() -> void:
	hp = max_hp
	direction = array_direction.pick_random()

# Evalúa en todo momento el código
func _physics_process(delta: float) -> void:
	# Validar la dirección hacia donde mira el enemigo
	if direction.x > 0:
		animated_sprite_2d.play("walk_right")
	elif direction.x < 0:
		animated_sprite_2d.play("walk_left")
	elif direction.y < 0:
		animated_sprite_2d.play("walk_up")
	elif direction.y > 0:
		animated_sprite_2d.play("walk_down")

	# Luego aplico velocidad al enemigo
	velocity = direction * SPEED
	move_and_slide()

	# Validar la dirección hacia donde se mueve el enemigo y verificamos si el raycast detecta un elemento sólido
	if direction == Vector2.UP and ray_cast_2d_up.is_colliding():
		change_direction()
	elif direction == Vector2.DOWN and ray_cast_2d_2_down.is_colliding():
		change_direction()
	elif direction == Vector2.LEFT and ray_cast_2d_3_left.is_colliding():
		change_direction()
	elif direction == Vector2.RIGHT and ray_cast_2d_4_right.is_colliding():
		change_direction()

# Crear el método
func change_direction() -> void:
	var avaliable_directions: Array = []

	# Validamos cada uno de los raycast y los que no detecten colisión hacia esa dirección
	# Guardamos ese vector en el arreglo
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

func take_damage(amount: int = 1) -> void:
	hp -= amount
	SoundManager.play_sfx("enemy_hit")

	if hp <= 0:
		queue_free()
	
