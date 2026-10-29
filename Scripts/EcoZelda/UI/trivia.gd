extends Control
# Trivia de 3 preguntas (A, B, C, D). Se juega al INICIO y al FINAL
# con las mismas preguntas para medir lo aprendido.
# Responder: teclas 1-4 o A-D, flechas + ENTER, o clic con el mouse.

@onready var titulo: Label = %Titulo
@onready var progreso: Label = %Progreso
@onready var pregunta: Label = %Pregunta
@onready var opciones: VBoxContainer = %Opciones
@onready var retro: Label = %Retro

var indice: int = 0
var respondiendo: bool = false
var respuestas: Array[int] = []


func _ready() -> void:
	titulo.text = "TRIVIA FINAL" if GameManager.trivia_final else "TRIVIA INICIAL"
	for i in 4:
		var boton: Button = opciones.get_child(i)
		boton.pressed.connect(responder.bind(i))
	mostrar_pregunta()


func mostrar_pregunta() -> void:
	var datos: Dictionary = GameManager.PREGUNTAS[indice]
	progreso.text = "Pregunta %d de %d" % [indice + 1, GameManager.PREGUNTAS.size()]
	pregunta.text = datos["pregunta"]
	retro.text = ""
	for i in 4:
		var boton: Button = opciones.get_child(i)
		boton.text = "%s) %s" % ["ABCD"[i], datos["opciones"][i]]
		boton.disabled = false
		boton.modulate = Color.WHITE
	opciones.get_child(0).grab_focus()
	respondiendo = false


func _unhandled_input(event: InputEvent) -> void:
	if respondiendo or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_1, KEY_A:
			responder(0)
		KEY_2, KEY_B:
			responder(1)
		KEY_3, KEY_C:
			responder(2)
		KEY_4, KEY_D:
			responder(3)


func responder(opcion: int) -> void:
	if respondiendo:
		return
	respondiendo = true
	respuestas.append(opcion)
	var datos: Dictionary = GameManager.PREGUNTAS[indice]
	for i in 4:
		opciones.get_child(i).disabled = true

	if GameManager.trivia_final:
		# Al final sí se muestra si acertó y por qué
		var correcta: int = datos["correcta"]
		opciones.get_child(correcta).modulate = Color(0.5, 1.0, 0.5)
		if opcion == correcta:
			retro.text = "¡Correcto! " + datos["explicacion"]
		else:
			opciones.get_child(opcion).modulate = Color(1.0, 0.45, 0.45)
			retro.text = "Incorrecto. " + datos["explicacion"]
		await get_tree().create_timer(2.6).timeout
	else:
		opciones.get_child(opcion).modulate = Color(1.0, 1.0, 0.5)
		retro.text = "Respuesta guardada. Al final del juego verás si acertaste."
		await get_tree().create_timer(0.9).timeout

	indice += 1
	if indice < GameManager.PREGUNTAS.size():
		mostrar_pregunta()
	else:
		terminar()


func terminar() -> void:
	if GameManager.trivia_final:
		GameManager.respuestas_final = respuestas
		GameManager.ir_a(GameManager.ESCENA_RESULTADOS)
	else:
		GameManager.respuestas_inicio = respuestas
		GameManager.ir_a(GameManager.ESCENA_MUNDO)
