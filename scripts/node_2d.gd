extends Control

const SPACE_NODE = preload("res://scenes/space_node.tscn")
const CLASS_WIDGET = preload("res://scenes/ClassWidget.tscn")
@onready var file_dialog: FileDialog = $FileDialog


var current_file_path #= "xml-files/data.xml"
var parser = XMLParser.new()
var start_time: String
var node_name: String
var end_time: String

var time_scaler:float = ((650.0-40.0)/600.0 )

func _ready():
	loadSave()
	#if current_file_path != "" and current_file_path != null:
		#rebuild()

func loadSave():
	if FileAccess.file_exists("user://backup/save.xml"):
		current_file_path = "user://backup/save.xml"
		rebuild()
	if FileAccess.file_exists("user://savegame.save"):
		var save_file = FileAccess.open("user://savegame.save", FileAccess.READ)
		while save_file.get_position() < save_file.get_length():
			var json_string = save_file.get_line()
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			if not parse_result == OK:
				print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
				continue
			var data = json.data
			for child in $ScrollContainer/Lecture_list.get_children():
				if child.lecture_name == data["lecture_name"] and data["is_active"]:
					child.toggle_active()
	set_board()
			
			
	
func save():
	#just save the activity of the lecture list container children so we can 
	#assign them back after loading the xml
	var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	for child in $ScrollContainer/Lecture_list.get_children():
		var json_string = {
			"lecture_name" : child.lecture_name,
			"is_active": child.active
		}
		json_string = JSON.stringify(json_string)
		save_file.store_line(json_string)
	pass
	
func rebuild() -> void:
	for n in $ScrollContainer/Lecture_list.get_children():
		$ScrollContainer/Lecture_list.remove_child(n)
		n.queue_free() 
	
	var lecture_list = parse_xml(current_file_path)
	for l in lecture_list:
		var instance:Variant = CLASS_WIDGET.instantiate()
		instance.set_label(l[0])
		
		instance.set_times(_convert_time(l[1]), _convert_time(l[2]))
		instance.day = int(l[3][0]) - 1
		$ScrollContainer/Lecture_list.add_child(instance)
		
		instance.changed.connect(_on_class_widget_changed)
	set_board()

func set_board():
	clear_board()
	var children = $ScrollContainer/Lecture_list.get_children()
	var lectures: Array = []
	for child in children:
		if child.active:
			lectures.append(child)
	lectures = sort_lectures(lectures)
		
	
	for i in range(lectures.size()):
		var day_list = lectures[i]
		#var sweep_list = sweep_line(day_list)
		var day:Variant = get_day_by_index(i)
		var latest_time = 0
		
		var groups = create_groups(day_list)
		var max_latest_time = 0
		for group in groups:
			var box = HBoxContainer.new()
			day.add_child(box)
			for lecture in group:
				max_latest_time = max(max_latest_time, lecture.end_time)
				var vbox = VBoxContainer.new()
				vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				vbox.add_theme_constant_override("separation", 0)
				add_space(vbox, lecture.start_time - latest_time)
				add_lecture(vbox, lecture, len(group) > 1)
				box.add_child(vbox)
			latest_time = max_latest_time
			max_latest_time = 0
			

func clear_board():
	for i in range(5):
		var day:Variant = get_day_by_index(i)
		for child in day.get_children():
			child.free()
	

func create_groups(day_list):
	var groups = []
	var current_group = []
	var current_end = -INF
	
	for lecture in day_list:
		var start = lecture.start_time
		var end = lecture.end_time
		
		if current_group.is_empty():
			current_group.append(lecture)
			current_end = end
		elif start < current_end:
			current_group.append(lecture)
			current_end = max(current_end, end)
		else:
			groups.append(current_group.duplicate())
			current_group.clear()
			current_group.append(lecture)
			current_end = end
	if not current_group.is_empty():
		groups.append(current_group)
	return groups
	

func get_day_by_index(index: int):
	if index == 0:
		return $HBoxContainer/VBoxContainer/Monday
	if index == 1:
		return $HBoxContainer/VBoxContainer2/Tuesday
	if index == 2:
		return $HBoxContainer/VBoxContainer3/Wednesday
	if index == 3:
		return $HBoxContainer/VBoxContainer4/Thursday
	if index == 4:
		return $HBoxContainer/VBoxContainer5/Friday
	print("wrong day index" + str(index))
	return -1

func add_space(day: Variant, amount: int):
	var instance = SPACE_NODE.instantiate()
	instance.custom_minimum_size = Vector2(0, amount*time_scaler)
	day.add_child(instance)

func add_lecture(day:Variant, lecture:Variant, conflict:bool):
	var instance = CLASS_WIDGET.instantiate()
	instance.set_times(lecture.start_time, lecture.end_time)
	instance.set_label(lecture.lecture_name)
	instance.calculate_height()
	if conflict:
		instance.set_conflict()
	day.add_child(instance)

func sort_lectures(lectures):
	#split lectures by day:
	var l = [Array(), Array(), Array(), Array(), Array()]
	for lec in lectures:
		var day = lec.day
		l.get(day).append(lec)
		l.set(day, l.get(day))
	for day:Array in l:
		day.sort_custom(func(a,b): return a.start_time < b.start_time)
		
	return l 
	
	

func _convert_time(time: String):
	var result:int = int(time.split(":")[0])*60
	result += int(time.split(":")[1])
	result -= 480
	return result
	
	
	

func parse_xml(file_path: String):
	var output: Array = []
	var day: Array = []
	parser.open(file_path)
	while parser.read() != ERR_FILE_EOF:
		if parser.get_node_name() == "Lecture" and parser.get_node_type() == parser.NODE_ELEMENT:
			node_name = parser.get_node_name()
			while not (parser.get_node_name() == "Lecture" and parser.get_node_type() == parser.NODE_ELEMENT_END):
				parser.read()
				if parser.get_node_name() == "name" and parser.get_node_type() == parser.NODE_ELEMENT:
					parser.read()
					node_name = parser.get_node_data()
				if parser.get_node_name() == "starttime" and parser.get_node_type() == parser.NODE_ELEMENT:
					parser.read()
					start_time = parser.get_node_data()
				if parser.get_node_name() == "endtime" and parser.get_node_type() == parser.NODE_ELEMENT:
					parser.read()
					end_time = parser.get_node_data()
				if parser.get_node_name() == "repeat" and parser.get_node_type() == parser.NODE_ELEMENT:
					parser.read()
					if parser.get_node_data().split(" ")[0] == "w1":
						day.append(parser.get_node_data().split(" ")[1])
			print("The Lecture: " + node_name + " (" + start_time + " - " + end_time + ")")
			if not day.is_empty():
				output.append([node_name, start_time, end_time, day.duplicate()])
				day.clear()
	return output
	

func _compare_events(a,b):
	if a[0] == b[0]:
		if a[1] == "end" and b[1] == "start":
			return true
		if a[1] == "start" and b[1] == "end":
			return false
		return false
		
	return a[0] < b[0]


func _on_file_dialog_confirmed() -> void:
	current_file_path = $FileDialog.current_path
	DirAccess.make_dir_recursive_absolute("user://backup")
	DirAccess.open("user://").copy($FileDialog.current_path, "user://backup/save.xml")
	rebuild()
	


func _on_ui_buttons_open_xml_dialog() -> void:
	file_dialog.show()


func _on_ui_buttons_save() -> void:
	save()

func _on_class_widget_changed():
	$"UI Buttons".unsave()
	
