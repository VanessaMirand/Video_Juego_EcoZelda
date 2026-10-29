class_name Zona
extends Node2D
# Una pantalla del mapa (16 x 11 tiles). Ciclo de juego de la zona:
# RECOLECCION -> (toda la basura clasificada) -> AMENAZA -> (enemigos derrotados) -> RESTAURADA
# Los enemigos se colocan en el editor dentro del nodo "Amenaza", que está
# desactivado hasta que aparece la amenaza.

signal estado_cambio
signal restaurada(zona: Zona)

enum Estado { RECOLECCION, AMENAZA, RESTAURADA }

@export var nombre_zona: String = "Bosque Sucio"
@export_multiline var mensaje_amenaza: String = ""
@export_multiline var mensaje_restaurada: String = ""
@export var tamano_tiles := Vector2i(16, 11)

var estado: Estado = Estado.RECOLECCION
var requerido: Array[int] = [0, 0, 0, 0]
var enemigos_vivos: int = 0

@onready var basura: Node2D = $Basura
@onready var amenaza: Node2D = $Amenaza
@onready var entrada: Marker2D = $Entrada
@onready var barrera: Barrera = get_node_or_null("Barrera")


func _ready() -> void:
	for b in basura.get_children():
		if b is Basura:
			requerido[b.tipo] += 1
			b.recogida.connect(_on_basura_recogida)
	amenaza.visible = false
	amenaza.process_mode = Node.PROCESS_MODE_DISABLED


func total_basura() -> int:
	return requerido[0] + requerido[1] + requerido[2] + requerido[3]


func basura_restante(tipo: int = -1) -> int:
	var cantidad := 0
	for b in basura.get_children():
		if b is Basura and not b.ya_recogida and (tipo == -1 or b.tipo == tipo):
			cantidad += 1
	return cantidad


func recogido_tipo(tipo: int) -> int:
	return requerido[tipo] - basura_restante(tipo)


func texto_mision() -> String:
	match estado:
		Estado.RECOLECCION:
			return "Clasifica la basura: %d/%d" % [total_basura() - basura_restante(), total_basura()]
		Estado.AMENAZA:
			return "¡Derrota la amenaza! Quedan %d" % enemigos_vivos
		_:
			if get_index() == get_parent().get_child_count() - 1:
				return "¡Ecosistema restaurado!"
			return "Zona limpia ✓  Avanza →"


func _on_basura_recogida(objeto: Basura) -> void:
	var mundo = get_tree().get_first_node_in_group("mundo")
	mundo.limpiar_area(objeto.global_position, 2)
	estado_cambio.emit()
	if basura_restante() == 0:
		iniciar_amenaza()


func iniciar_amenaza() -> void:
	estado = Estado.AMENAZA
	var hud = get_tree().get_first_node_in_group("hud")
	var player: EcoPlayer = get_tree().get_first_node_in_group("jugador")
	await get_tree().create_timer(0.6).timeout
	await hud.mostrar_dialogo(mensaje_amenaza, "¡AMENAZA INMINENTE!")
	player.equipar("espada")
	await hud.mostrar_dialogo("Cambiaste la PINZA por la ESPADA.\nPresiona ESPACIO para atacar.", "")

	amenaza.visible = true
	amenaza.process_mode = Node.PROCESS_MODE_INHERIT
	for enemigo in amenaza.get_children():
		if enemigo.has_signal("derrotado"):
			enemigos_vivos += 1
			enemigo.derrotado.connect(_on_enemigo_derrotado)
	estado_cambio.emit()
	if enemigos_vivos == 0:
		restaurar()


func _on_enemigo_derrotado() -> void:
	enemigos_vivos -= 1
	estado_cambio.emit()
	if enemigos_vivos <= 0:
		restaurar()


func restaurar() -> void:
	estado = Estado.RESTAURADA
	var mundo = get_tree().get_first_node_in_group("mundo")
	var hud = get_tree().get_first_node_in_group("hud")
	var player: EcoPlayer = get_tree().get_first_node_in_group("jugador")
	# Quitar proyectiles que hayan quedado volando
	for hijo in amenaza.get_children():
		if hijo is Proyectil:
			hijo.queue_free()
	mundo.limpiar_zona(self)
	GameManager.sumar_puntos(100)
	player.equipar("pinza")
	if barrera:
		barrera.abrir()
	estado_cambio.emit()
	await get_tree().create_timer(1.2).timeout
	if mensaje_restaurada != "":
		await hud.mostrar_dialogo(mensaje_restaurada, "¡ZONA RESTAURADA!")
	restaurada.emit(self)
