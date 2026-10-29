extends Control
# Resultados: compara la trivia inicial con la final y muestra lo que
# el jugador recicló durante la partida.

@onready var resumen: RichTextLabel = %Resumen
@onready var mensaje: Label = %Mensaje


func _ready() -> void:
	var gm = GameManager
	var inicio: int = gm.aciertos(gm.respuestas_inicio)
	var fin: int = gm.aciertos(gm.respuestas_final)

	var t := "[b]TRIVIA[/b]   inicio [color=#ffe040]%d/3[/color]  →  final [color=#7ee08a]%d/3[/color]\n" % [inicio, fin]
	for i in gm.PREGUNTAS.size():
		var correcta: int = gm.PREGUNTAS[i]["correcta"]
		t += "  P%d: %s  →  %s\n" % [i + 1, marca(gm.respuestas_inicio, i, correcta), marca(gm.respuestas_final, i, correcta)]
	t += "\n[b]RECICLAJE[/b]\n"
	for i in 4:
		t += "  [color=#%s]■[/color] %s: %d\n" % [gm.COLORES_UI[i].to_html(false), gm.NOMBRES_TIPO[i], gm.recolectado[i]]
	t += "  Errores de clasificación: %d\n" % gm.errores
	t += "\n[b]PUNTAJE[/b] %05d   Enemigos: %d   Tiempo: %d:%02d" % [
		gm.puntaje, gm.enemigos_derrotados, gm.tiempo_total_s / 60, gm.tiempo_total_s % 60]
	resumen.text = t

	if fin > inicio:
		mensaje.text = "¡Aprendiste %d respuesta(s) más que al inicio!" % (fin - inicio)
	elif fin == 3:
		mensaje.text = "¡Perfecto! Eres un verdadero guardián ambiental."
	else:
		mensaje.text = "Recuerda: separar en la fuente salva ecosistemas."


func marca(respuestas: Array[int], i: int, correcta: int) -> String:
	if i >= respuestas.size():
		return "-"
	return "[color=#7ee08a]✓[/color]" if respuestas[i] == correcta else "[color=#ff5050]✗[/color]"


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ACEPTAR"):
		GameManager.ir_a(GameManager.ESCENA_TITULO)
