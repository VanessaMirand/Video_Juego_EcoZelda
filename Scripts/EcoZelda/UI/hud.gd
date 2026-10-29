extends CanvasLayer
# HUD de EcoZelda:
#  - Barra superior: vida (corazones), herramienta, puntaje y misión de la zona.
#  - Barra inferior: las 4 canecas SIEMPRE visibles para escoger el color
#    (teclas 1-4, Q/E o clic con el mouse).
#  - Aviso: mensajes cortos de acierto / error al recolectar.
#  - Diálogo: mensajes que pausan el juego hasta presionar ENTER.

signal dialogo_cerrado

const ICONOS = preload("res://Assets/EcoZelda/iconos.png")
const TEX_PINZA = preload("res://Assets/EcoZelda/pinza.png")
const TEX_ESPADA = preload("res://Assets/01_Items/Sword.png")

var mundo: Mundo
var dialogo_abierto: bool = false
var tiempo_abierto: float = 0.0
var tween_aviso: Tween
var tween_texto: Tween

@onready var corazones: HBoxContainer = %Corazones
@onready var icono_herramienta: TextureRect = %IconoHerramienta
@onready var puntaje: Label = %Puntaje
@onready var nombre_zona: Label = %NombreZona
@onready var mision: Label = %Mision
@onready var barra_canecas: ColorRect = %BarraCanecas
@onready var aviso: PanelContainer = %Aviso
@onready var texto_aviso: Label = %TextoAviso
@onready var dialogo: PanelContainer = %Dialogo
@onready var titulo_dialogo: Label = %TituloDialogo
@onready var texto_dialogo: Label = %TextoDialogo
@onready var continuar: Label = %Continuar


func _ready() -> void:
	add_to_group("hud")
	process_mode = Node.PROCESS_MODE_ALWAYS
	aviso.visible = false
	dialogo.visible = false
	GameManager.puntaje_cambio.connect(_on_puntaje_cambio)
	GameManager.caneca_cambio.connect(_on_caneca_cambio)
	for i in 4:
		var caneca: Control = barra_canecas.get_child(i)
		caneca.gui_input.connect(_on_caneca_gui_input.bind(i))
	_on_puntaje_cambio(GameManager.puntaje)
	_on_caneca_cambio(GameManager.caneca_seleccionada)
	actualizar_vida(6, 6)
	actualizar_herramienta("pinza")


func conectar(nuevo_mundo: Mundo) -> void:
	mundo = nuevo_mundo
	mundo.player.vida_cambio.connect(actualizar_vida)
	mundo.player.herramienta_cambio.connect(actualizar_herramienta)
	mundo.camera_2d.zona_cambio.connect(func(_indice): actualizar_mision())
	for zona in mundo.zonas.get_children():
		zona.estado_cambio.connect(actualizar_mision)
	actualizar_mision()


func _process(delta: float) -> void:
	if dialogo_abierto:
		tiempo_abierto += delta
		continuar.modulate.a = 0.5 + 0.5 * sin(tiempo_abierto * 6.0)


func _unhandled_input(event: InputEvent) -> void:
	if dialogo_abierto:
		if (event.is_action_pressed("ACEPTAR") or event.is_action_pressed("ATAQUE")) and tiempo_abierto > 0.25:
			get_viewport().set_input_as_handled()
			cerrar_dialogo()
		return
	for i in 4:
		if event.is_action_pressed("CANECA_%d" % (i + 1)):
			GameManager.seleccionar_caneca(i)
	if event.is_action_pressed("CANECA_SIGUIENTE"):
		GameManager.seleccionar_caneca(GameManager.caneca_seleccionada + 1)
	elif event.is_action_pressed("CANECA_ANTERIOR"):
		GameManager.seleccionar_caneca(GameManager.caneca_seleccionada - 1)


# ---------------- BARRA SUPERIOR ----------------
func actualizar_vida(vida: int, _vida_max: int) -> void:
	for i in corazones.get_child_count():
		var corazon: TextureRect = corazones.get_child(i)
		var medios := clampi(vida - i * 2, 0, 2) # 2 = lleno, 1 = medio, 0 = vacío
		var atlas := AtlasTexture.new()
		atlas.atlas = ICONOS
		atlas.region = Rect2((2 - medios) * 8, 0, 8, 8)
		corazon.texture = atlas


func actualizar_herramienta(herramienta: String) -> void:
	icono_herramienta.texture = TEX_PINZA if herramienta == "pinza" else TEX_ESPADA


func _on_puntaje_cambio(nuevo: int) -> void:
	puntaje.text = "%05d" % nuevo


func actualizar_mision() -> void:
	if mundo == null:
		return
	var zona: Zona = mundo.zona_actual()
	nombre_zona.text = "ZONA %d/%d · %s" % [zona.get_index() + 1, mundo.zonas.get_child_count(), zona.nombre_zona.to_upper()]
	mision.text = zona.texto_mision()
	for i in 4:
		var contador: Label = barra_canecas.get_child(i).get_node("Contador")
		if zona.requerido[i] == 0:
			contador.text = "—"
		else:
			contador.text = "%d/%d" % [zona.recogido_tipo(i), zona.requerido[i]]


# ---------------- BARRA DE CANECAS ----------------
func _on_caneca_cambio(indice: int) -> void:
	for i in 4:
		var caneca: Control = barra_canecas.get_child(i)
		caneca.get_node("Seleccion").visible = i == indice
		var icono: TextureRect = caneca.get_node("Icono")
		icono.position.y = 4
		if i == indice:
			var tween = create_tween()
			tween.tween_property(icono, "position:y", 1.0, 0.08)
			tween.tween_property(icono, "position:y", 4.0, 0.12)


func _on_caneca_gui_input(event: InputEvent, indice: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		GameManager.seleccionar_caneca(indice)


# ---------------- AVISOS Y DIÁLOGOS ----------------
func mostrar_aviso(texto: String, color: Color = Color.WHITE) -> void:
	texto_aviso.text = texto
	texto_aviso.add_theme_color_override("font_color", color)
	aviso.visible = true
	aviso.modulate.a = 1.0
	if tween_aviso:
		tween_aviso.kill()
	tween_aviso = create_tween()
	tween_aviso.tween_interval(2.4)
	tween_aviso.tween_property(aviso, "modulate:a", 0.0, 0.4)
	tween_aviso.tween_callback(aviso.hide)


func texto_flotante(texto: String, posicion: Vector2, color: Color) -> void:
	if mundo:
		mundo.texto_flotante(texto, posicion, color)


func mostrar_dialogo(texto: String, titulo: String = "") -> void:
	while dialogo_abierto:
		await dialogo_cerrado
	dialogo_abierto = true
	tiempo_abierto = 0.0
	aviso.visible = false
	titulo_dialogo.text = titulo
	titulo_dialogo.visible = titulo != ""
	texto_dialogo.text = texto
	texto_dialogo.visible_ratio = 0.0
	dialogo.visible = true
	get_tree().paused = true
	if tween_texto:
		tween_texto.kill()
	tween_texto = create_tween()
	tween_texto.tween_property(texto_dialogo, "visible_ratio", 1.0, texto.length() * 0.018)
	await dialogo_cerrado


func cerrar_dialogo() -> void:
	# Primer ENTER: muestra todo el texto. Segundo ENTER: cierra.
	if texto_dialogo.visible_ratio < 1.0:
		if tween_texto:
			tween_texto.kill()
		texto_dialogo.visible_ratio = 1.0
		return
	dialogo.visible = false
	dialogo_abierto = false
	get_tree().paused = false
	dialogo_cerrado.emit()
