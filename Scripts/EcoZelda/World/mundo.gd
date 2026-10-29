class_name Mundo
extends Node2D
# Escena principal del juego. Controla la limpieza del mapa (el TileMapLayer
# cambia de la fila contaminada a la fila limpia del tileset), la muerte
# del jugador y el final del juego.
#
# Tileset: fila 0 = tiles contaminados, fila 1 = la misma columna pero limpia.
# Una celda limpia nunca vuelve a contaminarse, así que al retroceder el mapa
# se mantiene bonito.

const DESTELLO = preload("res://Scenes/EcoZelda/Objetos/destello.tscn")

@onready var suelo: TileMapLayer = $Suelo
@onready var zonas: Node2D = $Zonas
@onready var player: EcoPlayer = $Player
@onready var camera_2d: Camera2D = $Camera2D
@onready var hud: CanvasLayer = $HUD
@onready var guia: Guia = $Guia
@onready var efectos: Node2D = $Efectos
@onready var arbol_sagrado: ArbolSagrado = $Zonas/Zona3/ArbolSagrado


func _ready() -> void:
	add_to_group("mundo")
	player.sin_vida.connect(_on_player_sin_vida)
	for zona in zonas.get_children():
		zona.restaurada.connect(_on_zona_restaurada)
	hud.conectar(self)
	intro.call_deferred()


func intro() -> void:
	await guia.hablar()
	hud.actualizar_mision()


func zona_actual() -> Zona:
	return zonas.get_child(camera_2d.indice)


# ---------------- LIMPIEZA DEL MAPA ----------------
func limpiar_area(centro: Vector2, radio: int) -> void:
	var celda_centro := suelo.local_to_map(suelo.to_local(centro))
	for dy in range(-radio, radio + 1):
		for dx in range(-radio, radio + 1):
			if dx * dx + dy * dy <= radio * radio + 1:
				limpiar_celda(celda_centro + Vector2i(dx, dy), sqrt(dx * dx + dy * dy) * 0.07)


func limpiar_zona(zona: Zona) -> void:
	# Onda de limpieza que sale desde el jugador hacia toda la zona
	var origen := suelo.local_to_map(suelo.to_local(zona.global_position))
	var celda_jugador := suelo.local_to_map(suelo.to_local(player.global_position))
	for y in zona.tamano_tiles.y:
		for x in zona.tamano_tiles.x:
			var celda := origen + Vector2i(x, y)
			limpiar_celda(celda, Vector2(celda - celda_jugador).length() * 0.05)


func limpiar_celda(celda: Vector2i, retraso: float) -> void:
	if suelo.get_cell_atlas_coords(celda).y != 0:
		return
	if retraso > 0:
		await get_tree().create_timer(retraso, false).timeout
	var atlas := suelo.get_cell_atlas_coords(celda)
	if atlas.y != 0:
		return
	suelo.set_cell(celda, 0, Vector2i(atlas.x, 1))
	if randf() < 0.3:
		crear_destello(suelo.to_global(suelo.map_to_local(celda)))


func crear_destello(posicion: Vector2) -> void:
	var destello = DESTELLO.instantiate()
	destello.global_position = posicion
	efectos.add_child(destello)


func texto_flotante(texto: String, posicion: Vector2, color: Color) -> void:
	var label := Label.new()
	label.text = texto
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	label.position = posicion + Vector2(-6, -16)
	label.z_index = 20
	efectos.add_child(label)
	var tween = label.create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y - 12, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tween.chain().tween_callback(label.queue_free)


# ---------------- VIDA Y FINAL ----------------
func _on_player_sin_vida() -> void:
	player.can_move = false
	await hud.mostrar_dialogo("¡Te quedaste sin energía!\nEl ecosistema te necesita: vuelves a la entrada de la zona.", "OH NO...")
	player.global_position = zona_actual().entrada.global_position
	player.curar_todo()
	player.can_move = true


func _on_zona_restaurada(zona: Zona) -> void:
	GameManager.zonas_restauradas += 1
	hud.actualizar_mision()
	if zona.get_index() == zonas.get_child_count() - 1:
		await arbol_sagrado.restaurar()
		await get_tree().create_timer(1.5).timeout
		await hud.mostrar_dialogo("¡El Árbol Sagrado ha despertado!\nGracias a tu reciclaje el bosque, el río y el claro vuelven a estar llenos de vida.", "ECOSISTEMA RESTAURADO")
		await hud.mostrar_dialogo("Ahora veamos cuánto aprendiste.\nResponde otra vez las 3 preguntas de la trivia.", "TRIVIA FINAL")
		GameManager.terminar_juego()
