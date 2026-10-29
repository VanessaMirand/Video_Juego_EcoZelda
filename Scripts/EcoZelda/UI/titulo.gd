extends Control
# Pantalla de título de EcoZelda.

@onready var presiona: Label = %Presiona

var tiempo: float = 0.0


func _process(delta: float) -> void:
	tiempo += delta
	presiona.modulate.a = 0.4 + 0.6 * absf(sin(tiempo * 3.0))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ACEPTAR") or event.is_action_pressed("ATAQUE"):
		GameManager.reiniciar()
		GameManager.ir_a(GameManager.ESCENA_TRIVIA)
