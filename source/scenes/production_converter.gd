extends Node

var selected_file = ""

var result_json
var result = {}
var productions

var characters = []
var locations  = []
var narration  = []
var items      = []

var story:ParsedJSON = ParsedJSON.new()
var converted_story:ParsedJSON = ParsedJSON.new()

var elements_size = Vector2.ZERO
var current_graph

func _ready():
	window_resize()
	get_tree().get_root().connect("size_changed", self, "window_resize")
	$HBox/GraphEditLeft/file_selector.select($HBox/GraphEditLeft/file_selector.files.find(selected_file))
	if selected_file:
		story.load_JSON("res://json/"+selected_file)
		print("loaded productions: ",story.item_count)
		convert_production()

func convert_production():
	story.get_item()
	converted_story.item_list = []
		
	for i in story.item_count:
		converted_story.item = {}
		converted_story.item_branch = converted_story.item
		if story.item.has("Title"):
			converted_story.item["Title"] = story.item["Title"]
		else:
			converted_story.item["Title"] = ""
		if story.item.has("Title_Generic"):
			converted_story.item["Title_Generic"] = story.item["Title_Generic"]
		else:
			converted_story.item["Title_Generic"] = ""
		if story.item.has("Id"):
			converted_story.item["Id"] = story.item["Id"]
		else:
			converted_story.item["Id"] = str(i)
		converted_story.item["Description"] = ""
		story.get_item_branch("L_Side")
		converted_story.item["L_Side"] = {"Locations":{}}
		for key in story.item_branch["Vertex"]["Locations"].keys(): 
			var value = story.item_branch["Vertex"]["Locations"][key]
			converted_story.item["L_Side"]["Locations"][key] = add_fragment({},key, value)
			
		story.get_item()
		story.get_item_branch("R_Side")
		converted_story.item["R_Side"] = {"Locations":{}}
		for key in story.item_branch["Vertex"]["Locations"].keys(): 
			var value = story.item_branch["Vertex"]["Locations"][key]
			converted_story.item["R_Side"]["Locations"][key] = add_fragment({},key, value)
		
		print (JSON.print(converted_story.item, "\t"))
		converted_story.item_list.append( converted_story.item )
		story.get_next_item()
		
	converted_story.save_JSON("res://json/"+selected_file+"_converted.json")
	
func add_fragment( fragment, key, value):
	var edges = find_edge(key)
	if edges.size() > 0:
		for child in edges:
			var connection = find_vertex(child)
#			print ("for: ", key, " ",child, " is: ", connection[0]," and value : ", value)
			if connection[0]:
				if !fragment.has(connection[0]):
					fragment[connection[0]] = {}
				fragment[connection[0]][child] = add_fragment( {}, child, "" ) 
			if connection[1]:
				print (connection[1])
				if !fragment.has("Attributes"):
					fragment[connection[0]][child]["Attributes"] = {}
				fragment[connection[0]][child]["Attributes"][connection[1]] = ""
	return fragment

func find_vertex(vertex):
	var value = ""
	var type = ""
	for key in story.item_branch["Vertex"].keys():
		if key != "Locations":
			if typeof(story.item_branch["Vertex"][key]) == TYPE_DICTIONARY:
				if story.item_branch["Vertex"][key].has(vertex):
	#				print (key," ",value)
					value = story.item_branch["Vertex"][key][vertex]
					type = key
#			else:
#				value = story.item_branch["Vertex"][key]
#				type = key
	return [type,value]

func find_edge(parent):
	var children = []
	for key in story.item_branch["Edges"].keys():
		if story.item_branch["Edges"][key] == parent:
			children.append( key )
	return children

func load_story():
	story.load_JSON("res://json/"+selected_file)
	print("loaded productions: ",story.item_count)
	build_graph()
#	save_last_file( selected_file )

func generate_graph_elements(production_side:String):
	clear_data()
	story.get_item()
	current_graph.get_node("Title").text = production_side +": "+ story.item["Title"] 
	story.get_item_branch(production_side)
	story.get_item_branch("Locations")
	elements_size = Vector2.ZERO
	for key in story.item_branch.keys(): 
		elements_size.x = 0
		process_item(story.item_branch[key], key, 0, "Locations")

func process_item(item, key, parent, type):
	if typeof(item) == TYPE_DICTIONARY:
		match key:
			"Attributes", "Characters", "Items", "Narration":
				elements_size.x += 1
				for new_key in item.keys():
					process_item( item[new_key], new_key, parent, key )
				elements_size.x -= 1
			_: 
				if type == "Attributes":
					if item.has(key):
						parent.get_node("Label").text += "["+key+":"+item[key]+"]"
					else:
						parent.get_node("Label").text += "["+key+"]"
				elif  type == "Narration":
					var label = Label.new()
					label.set_text("["+key+"]")
					label.align = Label.ALIGN_CENTER
					label.set("custom_colors/font_color",Color.brown)
					parent.add_child(label)
				else:
					var child = add_vertex( key )
					child.add_child(add_slot("", "center"))
					if parent:
						connect_verticles(parent, child, type, key)
					for new_key in item.keys():
						process_item( item[new_key], new_key, child, type )

	elif !["Attributes","Characters","Items","Narration" ].has(key):
		if type == "Attributes":
			if item :
				parent.get_node("Label").text += "["+key+":"+item+"]"
			else:
				parent.get_node("Label").text += "["+key+"]"
			elements_size.y += 1
		elif  type == "Narration":
			var label = Label.new()
			label.set_text("["+key+"]")
			label.align = Label.ALIGN_CENTER
			label.set("custom_colors/font_color",Color.brown)
			parent.add_child(label)
			elements_size.y += 1
		else:
			var child = add_vertex( key )
			child.add_child(add_slot("", "center"))
			elements_size.y += 1
			if parent:
				connect_verticles(parent, child, type, key)

func add_vertex(key:String):
	var new_graph_node = GraphNode.new()
	new_graph_node.name = key
	new_graph_node.title = key
	new_graph_node.rect_size = Vector2(100, 60)
	locations.append(key)
	new_graph_node.offset = Vector2( 130 * elements_size.x, 60 * elements_size.y ) 
	new_graph_node.set("custom_colors/title_color", Color.blue)
	current_graph.add_child(new_graph_node)
	return new_graph_node

func connect_verticles(parent, child, type, key):
	var parent_in_slots  = parent.get_connection_input_count()
	var parent_out_slots = parent.get_connection_output_count()
	var parent_slots     = parent_in_slots + parent_out_slots
	var child_in_slots   = child.get_connection_input_count()
	var child_out_slots  = child.get_connection_output_count()
	var child_slots      = child_in_slots + child_out_slots
	var color_in         = Color.white
	var color_out        = Color.blue
	parent.add_child(add_slot(key, "right"))
	
	parent.set_slot(parent_slots, false, 0, color_in, true, 0, color_out)
	child.set_slot(child_slots, true, 0, color_out, false, 0, color_in)
	current_graph.connect_node(  parent.name, parent_out_slots, child.name, child_in_slots )

func add_slot(name:String, align:String):
	var slot = Label.new()
	slot.name = "Label"
	slot.set_text(name)
	match align:
		"left":  slot.align = Label.ALIGN_LEFT
		"right": slot.align = Label.ALIGN_RIGHT
		"center": slot.align = Label.ALIGN_CENTER
	return slot
		
func save_last_file(file_name):
	var file = File.new()
	file.open("user://setings.ini", file.WRITE)
	file.store_string(file_name)
	
func open_last_file():
	var file = File.new()
	file.open("user://setings.ini", file.READ)
	return file.get_line()

func build_graph():
	set_dissabled_buttons()
	clear_graph()
	current_graph = $HBox/GraphEditLeft
	generate_graph_elements("L_Side")
#	current_graph = $HBox/GraphEditRight
#	generate_graph_elements("R_Side")

func clear_graph():
	$HBox/GraphEditLeft.clear_connections()
	$HBox/GraphEditRight.clear_connections()
	for node in $HBox/GraphEditLeft.get_children():
		if node is GraphNode:
			node.clear_all_slots()
			node.free()
	for node in $HBox/GraphEditRight.get_children():
		if node is GraphNode:
			node.clear_all_slots()
			node.free()

func clear_data():
	characters = []
	locations = []
	items     = []
	narration = []

func load_production_next():
	story.get_next_item()
	build_graph()

func load_production_prev():
	story.get_prev_item()
	build_graph()

func set_dissabled_buttons():
	if story.item_current_id == 0:
		$HBox/GraphEditLeft/Previous.disabled = true
	else:
		$HBox/GraphEditLeft/Previous.disabled = false
	if story.item_current_id < story.item_count-1:
		$HBox/GraphEditLeft/Next.disabled = false
	else:
		$HBox/GraphEditLeft/Next.disabled = true

func _on_GraphEdit_connection_request(from, from_slot, to, to_slot):
	print (from," ", from_slot," ", to," ", to_slot)
	
func _on_GraphEditLeft_scroll_offset_changed(ofs):
	$HBox/GraphEditRight.scroll_offset = ofs
	$HBox/GraphEditRight.zoom = $HBox/GraphEditLeft.zoom

func _on_GraphEditRight_scroll_offset_changed(ofs):
	$HBox/GraphEditLeft.scroll_offset = ofs
	$HBox/GraphEditLeft.zoom = $HBox/GraphEditRight.zoom


func _on_Home_pressed():
	get_tree().change_scene_to(load("res://main.tscn") )

func _on_file_selector_item_selected(id):
	selected_file = $HBox/GraphEditLeft/file_selector.files[id]
	if selected_file:
		story.load_JSON("res://json/"+selected_file)
		print("loaded productions: ",story.item_count)
		convert_production()

func window_resize():
	$HBox/GraphEditLeft.rect_size.y  = OS.get_window_size().y/2
	$HBox/GraphEditLeft.rect_size.x  = OS.get_window_size().x/2
	$HBox/GraphEditRight.rect_size.y = OS.get_window_size().y/2
	$HBox/GraphEditRight.rect_size.x = OS.get_window_size().x/2
