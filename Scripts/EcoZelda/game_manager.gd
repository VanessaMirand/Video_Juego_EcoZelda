extends Node
# Autoload "GameManager": guarda el progreso de toda la partida de EcoZelda
# (trivia inicial/final, puntaje, residuos clasificados y caneca seleccionada).

signal puntaje_cambio(nuevo_puntaje: int)
signal caneca_cambio(indice: int)
signal recolectado_cambio

enum Tipo { PLASTICO, PAPEL, ORGANICO, METAL }

const NOMBRES_TIPO: Array[String] = ["Plástico", "Papel y cartón", "Orgánico", "Metal"]
const COLORES_CANECA: Array[String] = ["AZUL", "GRIS", "VERDE", "AMARILLA"]
const COLORES_UI: Array[Color] = [
	Color("2a6cf0"), Color("9a9aa4"), Color("2eaa3a"), Color("f0c020")]

const ESCENA_TITULO := "res://Scenes/EcoZelda/UI/titulo.tscn"
const ESCENA_TRIVIA := "res://Scenes/EcoZelda/UI/trivia.tscn"
const ESCENA_MUNDO := "res://Scenes/EcoZelda/World/mundo.tscn"
const ESCENA_RESULTADOS := "res://Scenes/EcoZelda/UI/resultados.tscn"

# Las mismas 3 preguntas se hacen al inicio y al final (TRIVIA)
const PREGUNTAS: Array[Dictionary] = [
	{
		"pregunta": "¿En qué caneca va una botella plástica?",
		"opciones": ["Verde", "Azul", "Gris", "Amarilla"],
		"correcta": 1,
		"explicacion": "La caneca AZUL recibe plásticos: botellas, bolsas y envases.",
	},
	{
		"pregunta": "¿Qué residuo va en la caneca VERDE (orgánicos)?",
		"opciones": ["Lata de aluminio", "Periódico", "Cáscara de banano", "Bolsa plástica"],
		"correcta": 2,
		"explicacion": "Los restos de comida y cáscaras son orgánicos: se convierten en abono.",
	},
	{
		"pregunta": "¿Qué es la economía circular?",
		"opciones": [
			"Tirar la basura al río",
			"Comprar y botar más rápido",
			"Quemar los residuos",
			"Reusar y reciclar los materiales",
		],
		"correcta": 3,
		"explicacion": "En la economía circular los materiales no se botan: vuelven a la cadena de uso.",
	},
]

var trivia_final: bool = false
var respuestas_inicio: Array[int] = []
var respuestas_final: Array[int] = []

var puntaje: int = 0
var errores: int = 0
var recolectado: Array[int] = [0, 0, 0, 0]
var enemigos_derrotados: int = 0
var zonas_restauradas: int = 0
var caneca_seleccionada: int = 0
var tiempo_inicio_ms: int = 0
var tiempo_total_s: int = 0

# Si es false, el juego nunca dibuja las formas de colisión (círculos y cuadros
# azules), aunque en el editor esté marcado "Depurar > Formas de colisión visibles".
const MOSTRAR_COLISIONES: bool = false


func _ready() -> void:
	if not MOSTRAR_COLISIONES:
		get_tree().debug_collisions_hint = false


func reiniciar() -> void:
	trivia_final = false
	respuestas_inicio.clear()
	respuestas_final.clear()
	puntaje = 0
	errores = 0
	recolectado = [0, 0, 0, 0]
	enemigos_derrotados = 0
	zonas_restauradas = 0
	caneca_seleccionada = 0
	tiempo_inicio_ms = Time.get_ticks_msec()


func seleccionar_caneca(indice: int) -> void:
	caneca_seleccionada = wrapi(indice, 0, 4)
	caneca_cambio.emit(caneca_seleccionada)


func sumar_puntos(cantidad: int) -> void:
	puntaje = max(0, puntaje + cantidad)
	puntaje_cambio.emit(puntaje)


func registrar_acierto(tipo: int) -> void:
	recolectado[tipo] += 1
	sumar_puntos(10)
	recolectado_cambio.emit()


func registrar_error() -> void:
	errores += 1
	sumar_puntos(-5)


func aciertos(respuestas: Array[int]) -> int:
	var total := 0
	for i in range(min(respuestas.size(), PREGUNTAS.size())):
		if respuestas[i] == PREGUNTAS[i]["correcta"]:
			total += 1
	return total


func terminar_juego() -> void:
	tiempo_total_s = int((Time.get_ticks_msec() - tiempo_inicio_ms) / 1000.0)
	trivia_final = true
	ir_a(ESCENA_TRIVIA)


func ir_a(ruta: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file.call_deferred(ruta)
