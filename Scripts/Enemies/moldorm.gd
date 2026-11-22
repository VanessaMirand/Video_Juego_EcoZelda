extends CharacterBody2D

@export var speed: float = 50.0
@export var segment_delay: int = 13 # Fotogramas de retraso entre segmentos
@export var rotation_speed: float = 4.0 # Velocidad del serpenteo

var direction: Vector2
var position_history: Array[Vector2] = []
var active_segments: Array[Node] = []
var time_passed: float = 0.0

@onready var segments_container = $Segmentos

func _ready():
	# 1. Iniciar dirección aleatoria diagonal
	direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	
	# 2. Guardar los segmentos iniciales en el array
	for child in segments_container.get_children():
		active_segments.append(child)
		
	# 3. Llenar el historial inicial con la posición actual para evitar saltos
	for i in range(active_segments.size() * segment_delay + 1):
		position_history.append(global_position)

func _physics_process(delta):
	time_passed += delta
	
	# --- SISTEMA DE MOVIMIENTO Y REBOTE ---
	# Ondulación senoidal para el movimiento errático
	var wiggle = sin(time_passed * rotation_speed) * 0.9
	direction = direction.rotated(wiggle * delta).normalized()
	
	velocity = direction * speed
	
	# Físicas de choque integradas (Para rebotar contra las rocas/cuerpos sólidos)
	var collision = move_and_collide(velocity * delta)
	if collision:
		direction = direction.bounce(collision.get_normal())
		
	# --- SISTEMA DE EFECTO GUSANO ---
	# Registrar la posición actual de la cabeza
	position_history.push_front(global_position)
	
	# Limitar el tamaño del historial a lo estrictamente necesario
	var max_history_size = active_segments.size() * segment_delay + 1
	if position_history.size() > max_history_size:
		position_history.pop_back()
		
	# Mover cada segmento a su posición histórica correspondiente
	for i in range(active_segments.size()):
		var history_index = (i + 1) * segment_delay
		if history_index < position_history.size():
			active_segments[i].global_position = position_history[history_index]

# --- SISTEMA DE REBOTE CONTRA LÍMITES DE PANTALLA (Area2D) ---
func _on_hitbox_area_entered(area: Area2D) -> void:
	# Verificamos qué área de transición tocó usando su nombre
	if "UP" in area.name:
		direction.y = abs(direction.y) # Rebota forzando el movimiento hacia abajo
	elif "DOWN" in area.name:
		direction.y = -abs(direction.y) # Rebota forzando el movimiento hacia arriba
	elif "LEFT" in area.name:
		direction.x = abs(direction.x) # Rebota forzando el movimiento a la derecha
	elif "RIGHT" in area.name:
		direction.x = -abs(direction.x) # Rebota forzando el movimiento a la izquierda


func _on_detector_limites_area_entered(area: Area2D) -> void:
	if "UP" in area.name:
		direction.y = abs(direction.y) # Fuerza dirección abajo
	elif "DOWN" in area.name:
		direction.y = -abs(direction.y) # Fuerza dirección arriba
	elif "LEFT" in area.name:
		direction.x = abs(direction.x) # Fuerza dirección derecha
	elif "RIGHT" in area.name:
		direction.x = -abs(direction.x) # Fuerza dirección izquierda

func _on_random_direction_timer_timeout() -> void:
	# Generar un nuevo vector diagonal aleatorio
	direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	
	# Elegir un tiempo aleatorio para el próximo cambio 
	var timer = $RandomDirectionTimer
	timer.wait_time = randf_range(1.0, 5.0)
	
# ---------------- SISTEMA DE DAMAGE SECUENCIAL -------
func take_damage(_amount: int = 1) -> void:
	SoundManager.play_sfx("enemy_hit")
	
	if active_segments.size() > 0:
		# Eliminar el último segmento del array
		var last_segment = active_segments.pop_back()
		last_segment.queue_free() # Destruir el nodo    
		# Aumentar un poco la velocidad (opcional, como en muchos juegos retro)
		speed += 15.0 
	else:
		# Si ya no hay segmentos, muere la cabeza
		queue_free()
