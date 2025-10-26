extends Control

const SPACE_NODE = preload("res://scenes/space_node.tscn")
const CLASS_WIDGET = preload("res://scenes/ClassWidget.tscn")

var parser = XMLParser.new()
var start_time: String
var node_name: String
var end_time: String
var day: String

var time_scaler:float = (650.0-40.0)/600.0 

func set_board():
	clear_board()
	var children = $ScrollContainer/Lecture_list.get_children()
	var lectures: Array = []
	for child in children:
		if child.active:
			lectures.append(child)
	lectures = sort_lectures(lectures)
		
	
	for i in range(lectures.size()):
		print(i)
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
				add_lecture(vbox, lecture)
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

func add_lecture(day:Variant, lecture:Variant):
	var instance = CLASS_WIDGET.instantiate()
	instance.set_times(lecture.start_time, lecture.end_time)
	instance.set_label(lecture.lecture_name)
	instance.calculate_height()
	day.add_child(instance)

func sort_lectures(lectures):
	#split lectures by day:
	var l = [Array(), Array(), Array(), Array(), Array()]
	for lec in lectures:
		var day = lec.day
		print(lec.name)
		print(day)
		l.get(day).append(lec)
		l.set(day, l.get(day))
	for day:Array in l:
		day.sort_custom(func(a,b): return a.start_time < b.start_time)
		
	return l 


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var lecture_list = parse_xml()
	for l in lecture_list:
		var instance:Variant = CLASS_WIDGET.instantiate()
		instance.set_label(l[0])
		
		instance.set_times(_convert_time(l[1]), _convert_time(l[2]))
		instance.day = int(l[3]) - 1
		$ScrollContainer/Lecture_list.add_child(instance)
	set_board()

func _convert_time(time: String):
	var result:int = int(time.split(":")[0])*60
	result += int(time.split(":")[1])
	result -= 480
	return result
	
	
	

func parse_xml():
	var output: Array = []
	parser.open("xml-files/data.xml")
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
					day = parser.get_node_data().split(" ")[1]
			print("The Lecture: " + node_name + " (" + start_time + " - " + end_time + ")")
			output.append([node_name, start_time, end_time, day])
	return output
	

func _compare_events(a,b):
	if a[0] == b[0]:
		if a[1] == "end" and b[1] == "start":
			return true
		if a[1] == "start" and b[1] == "end":
			return false
		return false
		
	return a[0] < b[0]
