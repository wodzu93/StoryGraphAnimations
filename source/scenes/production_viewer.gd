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

var elements_size = Vector2.ZERO
var current_graph

func _ready():
	window_resize()
	get_tree().get_root().connect("size_changed", self, "window_resize")
	selected_file = open_last_file()
	$HBox/GraphEditLeft/file_selector.select($HBox/GraphEditLeft/file_selector.files.find(selected_file))
	if selected_file:
		load_story()

func window_resize():
	$HBox/GraphEditLeft.rect_size.y  = OS.get_window_size().y/2
	$HBox/GraphEditLeft.rect_size.x  = OS.get_window_size().x/2
	$HBox/GraphEditRight.rect_size.y = OS.get_window_size().y/2
	$HBox/GraphEditRight.rect_size.x = OS.get_window_size().x/2

func load_story():
	if !story.load_JSON("res://json/"+selected_file):
		print("loaded productions: ",story.item_count)
		build_graph()
		save_last_file(selected_file)
	
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
		elements_size.y += 1
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
				elif key == "Connections":
					pass
				else:
					var child = add_vertex( key )
					child.add_child(add_slot("", "center"))
					if parent:
						connect_verticles(parent, child, type, key)
					for new_key in item.keys():
						process_item( item[new_key], new_key, child, type )
					if ["Characters","Items"].has(type):
						elements_size.y += 1
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

#func add_story_block( idx:int, type:String, key:String, graph:GraphEdit):
#	var new_graph_node   = GraphNode.new()
#	new_graph_node.name  = key
#	new_graph_node.title = key
#	new_graph_node.rect_size = Vector2(100, 60)
#	match type:
#		"Characters":
#			characters.append(key)
#			new_graph_node.offset = Vector2( 230, 80 * (idx+1) )
#			new_graph_node.set("custom_colors/title_color", Color.white)
#		"Narration":
#			narration.append(key)
#			new_graph_node.offset = Vector2( 490, 80 * (idx+1) )
#			new_graph_node.set("custom_colors/title_color", Color.orange)
#		"Items":
#			items.append(key)
#			new_graph_node.offset = Vector2( 360, 80 * (idx+1) )
#			new_graph_node.set("custom_colors/title_color", Color.darkgreen)
#		"Locations":
#			locations.append(key)
#			new_graph_node.offset = Vector2( 100, 110 * (idx+1) )
#			new_graph_node.set("custom_colors/title_color", Color.blue)
#	graph.add_child(new_graph_node)
	
#func connect_edges(graph):
#	if !story.get_item_branch("Edges"):
#		return 0
#
#	for edge in story.branch.keys():
#		var parent = graph.get_node(edge)
#		var child = graph.get_node(story.branch[edge])
#		var parent_in_slots = parent.get_connection_input_count()
#		var parent_out_slots = parent.get_connection_output_count()
#		var parent_slots = parent_in_slots + parent_out_slots
#		var child_in_slots  = child.get_connection_input_count()
#		var child_out_slots = child.get_connection_output_count()
#		var child_slots     = child_in_slots + child_out_slots
#
#		print("-----")
#		if edge in characters:
#			parent.add_child(add_slot("location", "left"))
#			child.add_child(add_slot("character", "right"))
#			parent.set_slot(parent_slots, true, 0, Color.white, false, 0, Color.white)
#			child.set_slot(child_slots, false, 0, Color.white, true, 0, Color.white)
#			graph.connect_node( story.branch[edge], child_out_slots, edge, parent_in_slots)
#			parent.offset.x = child.offset.x + 200
#			parent.offset.y = child.offset.y + 50 * (child_slots - 1)
#		elif edge in locations:
#			parent.offset.x = child.offset.x + 100
#			parent.add_child(add_slot("location", "left"))
#			child.add_child(add_slot("location", "right"))
#			parent.set_slot(parent_slots, true, 1, Color.blue, false, 1, Color.blue)
#			child.set_slot(child_slots, false, 1, Color.blue, true, 1, Color.blue)
#			graph.connect_node( story.branch[edge], child_out_slots, edge, parent_in_slots )
#		elif edge in items:
#			if story.branch[edge] in characters:
#				parent.add_child(add_slot("character", "left"))
#			else:
#				parent.add_child(add_slot("location", "left"))
#			child.add_child(add_slot("item", "right"))
#			parent.set_slot(parent_slots, true, 2, Color.darkgreen, false, 2, Color.darkgreen)
#			child.set_slot(child_slots, false, 2, Color.darkgreen, true, 2, Color.darkgreen)
#			graph.connect_node( story.branch[edge], child_out_slots, edge, parent_in_slots )
#			parent.offset.x = child.offset.x + 200
#			parent.offset.y = child.offset.y + 50 * (child_slots - 1)
#		elif edge in narration:
#			if story.branch[edge] in characters:
#				parent.add_child(add_slot("character", "left"))
#			elif story.branch[edge] in locations:
#				parent.add_child(add_slot("location", "left"))
#			else:
#				parent.add_child(add_slot("item", "left"))
#			child.add_child(add_slot("narration", "right"))
#			parent.set_slot(parent_slots, true, 3, Color.orange, false, 3, Color.orange)
#			child.set_slot(child_slots, false, 3, Color.orange, true, 3, Color.orange)
#			parent.offset.x = child.offset.x + 200
#			parent.offset.y = child.offset.y + 50 * (child_slots - 2)
#			graph.connect_node( story.branch[edge], child_out_slots, edge, parent_in_slots )
#		print("-----")
#		print (edge, " in: ", parent_in_slots, " out:", parent_out_slots, "("+ str(parent_slots) +")")
#		print (story.branch[edge], " in: ",child_in_slots, " out:",child_out_slots, "("+ str(child_slots) +")")

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
	current_graph = $HBox/GraphEditRight
	generate_graph_elements("R_Side")

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
	load_story()

