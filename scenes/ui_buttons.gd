extends HBoxContainer
signal open_xml_dialog
signal save


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func unsave():
	$Label.text = "Unsaved Changes"


func _on_load_button_pressed() -> void:
	open_xml_dialog.emit()


func _on_save_button_pressed() -> void:
	save.emit()
	$Label.text = "Saved"
