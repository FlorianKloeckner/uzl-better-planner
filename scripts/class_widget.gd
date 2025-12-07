extends Control

signal changed

const SPACE_NODE = preload("res://scenes/space_node.tscn")
const CLASS_WIDGET = preload("res://scenes/ClassWidget.tscn")


var active: bool = false

var start_time: int 
var end_time: int 
var length: int 
var day: int 
var lecture_name: String = "Placeholder"

var conflict: bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not conflict: 
		$ColorRect.color = Color.GRAY
	else:
		$ColorRect.color = Color.PALE_VIOLET_RED
	#this too shall
	pass
func _on_button_pressed() -> void:
	toggle_active()
	get_parent().get_parent().get_parent().set_board()
	
func set_conflict():
	conflict = true

func calculate_height():
	var t:float = end_time - start_time
	t = t*(610.0/600.0)
	custom_minimum_size = Vector2(0, t)
	
func set_up(lecture: Variant):
	set_label(lecture.lecture_name)
	
func set_label(text: String):
	lecture_name = text
	$Label.text = text

func set_times(s:int, e:int):
	start_time = s
	end_time = e
	var end_time_formatted
	var start_time_formatted
	if str(e%60).length() == 1:
		end_time_formatted = str(e/60+8)+":"+str(e%60)+"0"
	else:
		end_time_formatted = str(e/60+8)+":"+str(e%60)
	if str(s%60).length() == 1:
		start_time_formatted = str(s/60+8)+":"+str(s%60)+"0"
	else:
		start_time_formatted = str(s/60+8)+":"+str(s%60)
	$Time.text = start_time_formatted + " - " + end_time_formatted

func toggle_active():
	changed.emit()
	if active:
		active = false
		$ColorRect.color = Color.GRAY
	else:
		active = true
		$ColorRect.color = Color.WHITE
