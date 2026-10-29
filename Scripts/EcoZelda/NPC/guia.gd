class_name Guia
extends StaticBody2D
# Anciano guardián del bosque: explica la misión y las canecas.
# Sus textos se pueden editar desde el Inspector (dialogos).

@export_multiline var dialogos: PackedStringArray = []

var jugador_cerca: bool = false
var hablando: bool = false

@onready var zona_hablar: Area2D = $ZonaHablar
@onready var aviso: Label = $Aviso


func _ready() -> void:
	aviso.visible = false
	zona_hablar.body_entered.connect(_on_zona_hablar_body_entered)
	zona_hablar.body_exited.connect(_on_zona_hablar_body_exited)


func _on_zona_hablar_body_entered(body: Node2D) -> void:
	if body is EcoPlayer:
		jugador_cerca = true
		aviso.visible = true


func _on_zona_hablar_body_exited(body: Node2D) -> void:
	if body is EcoPlayer:
		jugador_cerca = false
		aviso.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if jugador_cerca and not hablando and event.is_action_pressed("ACEPTAR"):
		get_viewport().set_input_as_handled()
		hablar()


func hablar() -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if hud == null or hablando:
		return
	hablando = true
	for texto in dialogos:
		await hud.mostrar_dialogo(texto, "ANCIANO")
	hablando = false
