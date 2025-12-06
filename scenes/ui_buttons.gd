extends HBoxContainer
signal open_xml_dialog


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func _on_load_button_pressed() -> void:
	open_xml_dialog.emit()
