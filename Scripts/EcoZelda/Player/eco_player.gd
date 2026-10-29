class_name EcoPlayer
extends CharacterBody2D
# Eco-Knight: el Link de EcoZelda. Usa la PINZA para recoger residuos
# y cambia a la ESPADA cuando aparece una amenaza.

signal vida_cambio(vida: int, vida_max: int)
signal herramienta_cambio(herramienta: String)
signal sin_vida

@export var SPEED: float = 70.0
@export var vida_max: int = 6 # 6 medios corazones = 3 corazones

var is_attaking: bool = false
var facing_direction := Vector2.DOWN
var can_move: bool = true
var herramienta: String = "pinza" # "pinza" o "espada"
var vida: int = 6
var invulnerable: bool = false
var empuje := Vector2.ZERO

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var pinza: Sprite2D = $Pinza
@onready var area_pinza: Area2D = $AreaPinza
@onready var area_espada: Area2D = $AreaEspada
@onready var hurtbox: Area2D = $Hurtbox


func _ready() -> void:
	add_to_group("jugador")
	vida = vida_max
	pinza.visible = false


func _physics_process(delta: float) -> void:
	revisar_contacto_enemigos()

	if Input.is_action_just_pressed("ATAQUE") and can_move and not is_attaking:
		if herramienta == "pinza":
			usar_pinza()
		else:
			attack()

	# El empuje (al recibir daño) se aplica aunque no se pueda caminar
	empuje = empuje.move_toward(Vector2.ZERO, 500 * delta)

	if is_attaking or not can_move:
		velocity = empuje
		move_and_slide()
		return

	var direction = Input.get_vector(
		"IZQUIERDA",
		"DERECHA",
		"ARRIBA",
		"ABAJO")
	velocity = direction * SPEED + empuje

	if direction == Vector2.ZERO:
		play_direccion("walk")
		animated_sprite_2d.pause()
		move_and_slide()
		return

	#Validar la dirección hacia donde se mueve el personaje
	if direction.x > 0:
		facing_direction = Vector2.RIGHT
	elif direction.x < 0:
		facing_direction = Vector2.LEFT
	elif direction.y > 0:
		facing_direction = Vector2.DOWN
	elif direction.y < 0:
		facing_direction = Vector2.UP
	play_direccion("walk")

	move_and_slide()


func play_direccion(prefijo: String) -> void:
	if facing_direction == Vector2.UP:
		animated_sprite_2d.play(prefijo + "_up")
	elif facing_direction == Vector2.DOWN:
		animated_sprite_2d.play(prefijo + "_down")
	elif facing_direction == Vector2.LEFT:
		animated_sprite_2d.play(prefijo + "_left")
	elif facing_direction == Vector2.RIGHT:
		animated_sprite_2d.play(prefijo + "_right")


# ---------------- PINZA RECOLECTORA ----------------
func usar_pinza() -> void:
	is_attaking = true
	play_direccion("walk")
	animated_sprite_2d.pause()
	animated_sprite_2d.frame = 0

	# Ubicar la pinza y su área hacia donde mira el personaje
	pinza.flip_h = facing_direction == Vector2.LEFT
	pinza.rotation = 0.0
	if facing_direction == Vector2.RIGHT:
		pinza.position = Vector2(10, 3)
	elif facing_direction == Vector2.LEFT:
		pinza.position = Vector2(-10, 3)
	elif facing_direction == Vector2.DOWN:
		pinza.rotation = PI / 2
		pinza.position = Vector2(3, 11)
	elif facing_direction == Vector2.UP:
		pinza.rotation = -PI / 2
		pinza.position = Vector2(-3, -11)
	area_pinza.position = facing_direction * 12
	pinza.visible = true

	await get_tree().physics_frame
	await get_tree().physics_frame
	var basura := basura_mas_cercana()
	if basura:
		basura.intentar_recoger(GameManager.caneca_seleccionada)

	await get_tree().create_timer(0.2).timeout
	pinza.visible = false
	is_attaking = false


func basura_mas_cercana() -> Basura:
	var mejor: Basura = null
	var mejor_distancia := INF
	for area in area_pinza.get_overlapping_areas():
		if area is Basura and not area.ya_recogida:
			var d := global_position.distance_to(area.global_position)
			if d < mejor_distancia:
				mejor_distancia = d
				mejor = area
	return mejor


# ---------------- ESPADA ----------------
func attack() -> void:
	is_attaking = true
	area_espada.position = facing_direction * 14
	area_espada.rotation = 0.0 if facing_direction.y == 0 else PI / 2
	play_direccion("sword")

	await get_tree().physics_frame
	await get_tree().physics_frame
	var golpeados: Array = []
	for objetivo in area_espada.get_overlapping_bodies() + area_espada.get_overlapping_areas():
		var enemigo = buscar_enemigo(objetivo)
		if enemigo and not enemigo in golpeados:
			golpeados.append(enemigo)
			enemigo.recibir_danio(global_position)

	await animated_sprite_2d.animation_finished
	is_attaking = false


# Sube por los padres hasta encontrar el nodo que sabe recibir daño
# (sirve para los segmentos del Gusano de Basura)
func buscar_enemigo(nodo: Node) -> Node:
	while nodo and not nodo.has_method("recibir_danio"):
		nodo = nodo.get_parent()
	if nodo == self:
		return null
	return nodo


func equipar(nueva: String) -> void:
	herramienta = nueva
	herramienta_cambio.emit(herramienta)


# ---------------- VIDA ----------------
func revisar_contacto_enemigos() -> void:
	if invulnerable:
		return
	for objetivo in hurtbox.get_overlapping_bodies() + hurtbox.get_overlapping_areas():
		if buscar_enemigo(objetivo):
			recibir_danio(1, objetivo.global_position)
			return


func recibir_danio(cantidad: int, origen: Vector2) -> void:
	if invulnerable or vida <= 0:
		return
	vida = max(0, vida - cantidad)
	vida_cambio.emit(vida, vida_max)
	empuje = (global_position - origen).normalized() * 160
	if vida == 0:
		sin_vida.emit()
		return
	invulnerable = true
	var tween = create_tween().set_loops(6)
	tween.tween_property(animated_sprite_2d, "modulate:a", 0.2, 0.06)
	tween.tween_property(animated_sprite_2d, "modulate:a", 1.0, 0.06)
	await tween.finished
	invulnerable = false


func curar_todo() -> void:
	vida = vida_max
	vida_cambio.emit(vida, vida_max)


func move_transition_player(direction: Vector2, distance: float) -> void:
	can_move = false
	facing_direction = direction
	play_direccion("walk")
	var tween = create_tween()
	tween.tween_property(self, "position", position + direction * distance, 0.5)
	await tween.finished
