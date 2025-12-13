extends Control

signal changed
signal updated 

const SPACE_NODE = preload("res://scenes/space_node.tscn")
const CLASS_WIDGET = preload("res://scenes/ClassWidget.tscn")

var linked_lecture #widget linked to lecture_list
var linked_list_lecture

var active: bool = false

var start_time: int 
var end_time: int 
var length: int 
var day: int 
var lecture_name: String = "Placeholder"
var is_widget = false

var hours_start
var minutes_start
var hours_end
var minutes_end


var conflict: bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not conflict: 
		$ColorRect.color = Color.GRAY
	else:
		$ColorRect.color = Color.PALE_VIOLET_RED
	#this too shall
	

func set_is_widget(b: bool):
	is_widget = b
	
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
	


func set_times(s:int, e:int): #only to be called by the widget
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
	set_options_buttons_time(start_time_formatted, end_time_formatted)

func set_options_buttons_time(s,e):
	hours_start = $ConfirmationDialog/HBoxContainer/HoursStart
	minutes_start =$ConfirmationDialog/HBoxContainer/MinutesStart
	hours_end = $ConfirmationDialog/HBoxContainer/HoursEnd
	minutes_end = $ConfirmationDialog/HBoxContainer/MinutesEnd
	
	
	
	var h_start = s.split(":")[0]
	var m_start = s.split(":")[1]
	var h_end = e.split(":")[0]
	var m_end = e.split(":")[1]
	hours_start.select(hours_start.get_item_index(int(h_start)))
	minutes_start.select(minutes_start.get_item_index(int(m_start)))
	hours_end.select(hours_end.get_item_index(int(h_end)))
	minutes_end.select(minutes_end.get_item_index(int(m_end)))
	
	
	
func toggle_active():
	changed.emit()
	if active:
		active = false
		$ColorRect.color = Color.GRAY
	else:
		active = true
		$ColorRect.color = Color.WHITE
		
func convert_pretty_time_to_time(time: String):
	var result:int = int(time.split(":")[0])*60
	print(time + "time")
	result += int(time.split(":")[1])
	result -= 480
	print(result)
	return result


func _on_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not is_widget:
				toggle_active()
				get_parent().get_parent().get_parent().set_board()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			print("show context menu here")
			$ConfirmationDialog.visible = true
			$ConfirmationDialog.position = event.global_position


func _on_confirmation_dialog_confirmed() -> void:
	var start = str(hours_start.get_item_text(hours_start.selected)) + ":" + minutes_start.get_item_text(minutes_start.selected)
	var end = str(hours_end.get_item_text(hours_end.selected)) + ":" + minutes_end.get_item_text(minutes_start.selected)
	start = convert_pretty_time_to_time(start)
	end = convert_pretty_time_to_time(end)
	linked_lecture.set_times(start, end)
	updated.emit()
