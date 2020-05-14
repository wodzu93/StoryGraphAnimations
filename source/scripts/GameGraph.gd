extends Node
class_name GameGraph

var node_style = {"Characters":load("res://resources/box_blue.tres"),
				"Items":load("res://resources/box_yellow.tres"),
				"Narration":load("res://resources/box_grey.tres"),
				"Locations":load("res://resources/box_green.tres"),
				"Connections":load("res://resources/box_green.tres") }

var initials := ParsedJSON.new()
var world    := ParsedJSON.new()

var vertex_position = Vector2()
var current_graph:GraphEdit
var is_graph_node_selected := false
	
func load_initials(file_name):
	var err = initials.load_JSON(file_name)
	precess_initials()
	return err
	
func precess_initials():
	initials.get_root_JSON()
	world.item["Locations"] = {}
	for key in initials.item["Locations"]["Vertex"].keys():
		world.item["Locations"][key] = {}
		var connections = get_initials_connection(key)
		if connections.size() > 0:
			world.item["Locations"][key]["Connections"] = connections
		var characters_in_location = get_initials_characters(key)
		if characters_in_location.size() > 0:
			world.item["Locations"][key]["Characters"] = characters_in_location
		var items_in_location = get_initials_items(key)
		if items_in_location.size() > 0:
			world.item["Locations"][key]["Items"] = items_in_location
	world.item_branch = world.item
	world.item_list = world.item
	
#	print (JSON.print(world.item, "\t"))

func get_initials_connection(parent):
	var connections = {}
	for item in initials.item["Locations"]["Edges"]:
		if item.values()[0] == parent:
			connections[item.keys()[0]] = {}
	return connections
		
func get_initials_characters(parent):
	var characters = {}
	for item in initials.item["Characters"]["Edges"]:
		if item.values()[0] == parent:
			var character_name = item.keys()[0]
			var items_in_character = get_initials_items(character_name)
			if items_in_character.size()>0:
				characters[character_name] = {}
				characters[character_name]["Items"] = items_in_character
	return characters

func get_initials_items(parent):
	var items = {}
	for item in initials.item["Items"]["Edges"]:
		if item.values()[0] == parent:
			items[item.keys()[0]] = get_initials_items(item.keys()[0])
	return items
	

func generate_graph(graph_handle):
	current_graph = graph_handle
	var graph = graph_handle
	var step = (2*PI) / world.item["Locations"].size()
	var i = 0
	for key in world.item["Locations"].keys():
		i += 1
		vertex_position = Vector2(cos(i * step), sin(i * step)) * Vector2(500,300)
		if world.item["Locations"][key].has("Atributes"):
			if world.item["Locations"][key]["Atributes"].has("Position"):
				vertex_position.x = float(world.item["Locations"][key]["Atributes"]["Position"]["x"])
				vertex_position.y = float(world.item["Locations"][key]["Atributes"]["Position"]["y"])
			else:
				
				world.item["Locations"][key]["Atributes"]["Position"] = {"x": vertex_position.x,"y": vertex_position.y}
		else:
			world.item["Locations"][key]["Atributes"] = {}
			world.item["Locations"][key]["Atributes"]["Position"] = {"x": vertex_position.x,"y": vertex_position.y}
		add_vertex(key, "Locations")
	for key in world.item["Locations"].keys():
		
		if world.item["Locations"][key].has("Connections"):
			for child in world.item["Locations"][key]["Connections"]:
				var local_key = key
				var local_child = child
#				if graph.get_node(key).offset.x > graph.get_node(child).offset.x:
#					local_child = key
#					local_key = child
				graph.get_node(local_key).add_child(add_label(local_child, Label.ALIGN_CENTER))
				graph.get_node(local_child).add_child(add_label(local_key, Label.ALIGN_CENTER))
				connect_vertices(graph.get_node(local_key), graph.get_node(local_child))
				
func update_location_position(vertex_name, new_position):
	world.item["Locations"][vertex_name]["Atributes"]["Position"] = {"x": new_position.x,"y": new_position.y}
	world.save_JSON(world.file_name)
	
func show_location(vertex_name):
	var location = world.item["Locations"][vertex_name]
	vertex_position = Vector2( -300, 40 )
	var handle = add_vertex(vertex_name, "Locations")
	vertex_position.x += 100
	if location.has("Connections"):
		handle.add_child(add_label("Road to:", Label.ALIGN_CENTER))
		for key in location["Connections"]:
			handle.add_child(add_label(key, Label.ALIGN_LEFT, Color.darkgreen))
	if location.has("Characters"):
		handle.add_child(add_label("At location:", Label.ALIGN_CENTER))
		get_fragment(location["Characters"], handle, "Characters" )
		
	if location.has("Items"):
		handle.add_child(add_label("Items:", Label.ALIGN_CENTER))
		get_fragment(location["Items"], handle, "Items")

func get_fragment(item, parent, type):
	if typeof(item) == TYPE_DICTIONARY:
		for key in item.keys():
			match key:
				"Atributes", "Narration":
					parent.add_child(add_label(key, Label.ALIGN_CENTER))
				"Items":
					parent.add_child(add_label("Items:", Label.ALIGN_LEFT, Color.black))
					vertex_position.x += 100
					get_fragment(item[key], parent, "Items")
					vertex_position.x -= 100
					vertex_position.y -= 60
				_: 
					vertex_position.x += 100
					var item_handle = add_vertex(key, type)
					if type == "Items":
						item_handle.add_child(add_label("", Label.ALIGN_CENTER))
						parent.add_child(add_label(key, Label.ALIGN_RIGHT, Color.yellow))
					else:
						item_handle.add_child(add_label("", Label.ALIGN_CENTER))
						parent.add_child(add_label(key, Label.ALIGN_RIGHT, Color.blue))
					connect_vertices(parent, item_handle)
					get_fragment(item[key], item_handle, type)
					vertex_position.y += 60
					vertex_position.x -= 100
	else:
#		vertex_position.x += 500
		add_vertex( item, type )
#		vertex_position.x -= 100

func add_vertex(key:String, type:String):
	var new_node       = GraphNode.new()
	new_node.name      = key
	new_node.title     = key
	new_node.rect_size = Vector2(100, 60)
	new_node.offset    = vertex_position 
	new_node.set( "custom_styles/frame", node_style[type] )
	new_node.connect("dragged", current_graph.get_node("../../.."),"_on_vertex_moved")
	current_graph.add_child( new_node )
	return new_node

func connect_vertices(parent, child):
	var parent_in_slots  = parent.get_connection_input_count()
	var parent_out_slots = parent.get_connection_output_count()
	var parent_slots     = parent_in_slots + parent_out_slots
	var child_in_slots   = child.get_connection_input_count()
	var child_out_slots  = child.get_connection_output_count()
	var child_slots      = child_in_slots + child_out_slots
	var color_in         = Color.black
	var color_out        = Color.black
	parent.set_slot(parent_slots, false, 0, color_in, true, 0, color_out)
	child.set_slot(child_slots, true, 0, color_out, false, 0, color_in)
	current_graph.connect_node(  parent.name, parent_out_slots, child.name, child_in_slots )
	
func add_label(name:String, align:int, color:Color = Color.black):
	var label = Label.new()
	label.name = "Label"
	label.align = align
	label.set_text(name)
	label.set("custom_colors/font_color", color)
	return label

func test_production( production:Dictionary ):
	if find_match(production["L_Side"]["Locations"], world.item["Locations"]):
		Globals.event_log.add_text("MATCH: " + production["Title"])
		return OK
	else:
		Globals.event_log.add_text("FAILED to match: " + production["Title"])
		return FAILED
	
func apply_production( production:Dictionary ):
	print ("g: "+JSON.print(production["R_Side"]["Locations"].keys(), "\t"))
	print ("t: "+JSON.print(world.item["Locations"].keys(), "\t"))
	if !test_production( production ):
		return FAILED
	print ("Applying: " + JSON.print(production, "\t"))
	var graph = production["R_Side"]["Locations"]
	var target = world.item["Locations"]

func find_match(graph, target):
	if typeof(graph) != TYPE_DICTIONARY:
		if typeof(target) != TYPE_DICTIONARY:
			if graph != target:
				print (graph+ " NOT "+target )
				return false
		return true
	else:
		for key in graph.keys():
			print (key)
			if key in target.keys():
				if find_match(graph[key] , target[key]) == false:
					return false
			else:
				print (key+ " is NOT in "+JSON.print(target.keys(), "\t") )
				return false
		return true
