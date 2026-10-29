extends Camera2D
# Cámara por pantallas como en el Zelda clásico: cuando el jugador cruza
# el borde de una zona, la cámara se desliza a la siguiente.
# El offset (0, -32) deja espacio para el HUD superior.

signal zona_cambio(indice: int)

@export var ancho_zona: int = 256
@export var numero_zonas: int = 3

var indice: int = 0
var moviendo_camara: bool = false

@onready var player: EcoPlayer = $"../Player"


func _ready() -> void:
	position.x = indice * ancho_zona


func _physics_process(_delta: float) -> void:
	if moviendo_camara:
		return
	var nuevo := clampi(floori(player.global_position.x / ancho_zona), 0, numero_zonas - 1)
	if nuevo != indice:
		transicion(nuevo)


func transicion(nuevo: int) -> void:
	moviendo_camara = true
	var direccion := Vector2.RIGHT if nuevo > indice else Vector2.LEFT
	indice = nuevo
	zona_cambio.emit(indice)
	player.move_transition_player(direccion, 14)

	var tween = create_tween()
	tween.tween_property(self, "position:x", float(indice * ancho_zona), 0.7)
	await tween.finished

	player.can_move = true
	moviendo_camara = false
