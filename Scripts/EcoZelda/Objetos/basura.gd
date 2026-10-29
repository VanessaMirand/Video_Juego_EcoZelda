@tool
class_name Basura
extends Area2D
# Residuo que se recoge con la pinza. Solo se recoge si la caneca
# seleccionada en la barra inferior es la correcta para su tipo.

signal recogida(basura: Basura)

enum Tipo { PLASTICO, PAPEL, ORGANICO, METAL }

const NOMBRES: Array = [
	["Botella plástica", "Bolsa plástica"],
	["Periódico", "Caja de cartón"],
	["Cáscara de banano", "Manzana mordida"],
	["Lata de aluminio", "Lata aplastada"],
]

@export var tipo: Tipo = Tipo.PLASTICO:
	set(valor):
		tipo = valor
		actualizar_sprite()
@export_range(0, 1) var variante: int = 0:
	set(valor):
		variante = valor
		actualizar_sprite()

var ya_recogida: bool = false

@onready var sprite_2d: Sprite2D = $Sprite2D


func _ready() -> void:
	actualizar_sprite()
	if Engine.is_editor_hint():
		return
	add_to_group("basura")
	# Pequeño "flotado" para que se note en el mapa
	var tween = create_tween().set_loops()
	tween.tween_property(sprite_2d, "position:y", -1.0, 0.6).set_delay(randf() * 0.5)
	tween.tween_property(sprite_2d, "position:y", 0.0, 0.6)


func actualizar_sprite() -> void:
	if not is_node_ready():
		return
	sprite_2d.region_enabled = true
	sprite_2d.region_rect = Rect2((tipo * 2 + variante) * 16, 0, 16, 16)


func nombre() -> String:
	return NOMBRES[tipo][variante]


func intentar_recoger(caneca: int) -> void:
	if ya_recogida:
		return
	var hud = get_tree().get_first_node_in_group("hud")
	if caneca == tipo:
		ya_recogida = true
		GameManager.registrar_acierto(tipo)
		if hud:
			hud.mostrar_aviso("¡Bien! %s → caneca %s" % [nombre(), GameManager.COLORES_CANECA[tipo]], GameManager.COLORES_UI[tipo])
			hud.texto_flotante("+10", global_position, Color("ffe040"))
		recogida.emit(self)
		monitorable = false
		var tween = create_tween().set_parallel()
		tween.tween_property(self, "position:y", position.y - 12, 0.3)
		tween.tween_property(self, "scale", Vector2(0.2, 0.2), 0.3)
		tween.tween_property(self, "modulate:a", 0.0, 0.3)
		await tween.finished
		queue_free()
	else:
		GameManager.registrar_error()
		if hud:
			hud.mostrar_aviso("✗ ERROR: %s no va en la caneca %s.\nVa en la %s (%s)." % [
				nombre(), GameManager.COLORES_CANECA[caneca],
				GameManager.COLORES_CANECA[tipo], GameManager.NOMBRES_TIPO[tipo]], Color("ff4040"))
			hud.texto_flotante("-5", global_position, Color("ff4040"))
		# Sacudir el residuo para mostrar el error
		var tween = create_tween()
		for i in 3:
			tween.tween_property(sprite_2d, "position:x", 2.0, 0.04)
			tween.tween_property(sprite_2d, "position:x", -2.0, 0.04)
		tween.tween_property(sprite_2d, "position:x", 0.0, 0.04)
