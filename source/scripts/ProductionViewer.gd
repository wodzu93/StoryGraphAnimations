extends Node
class_name ProductionViewer

var node_style = {"Characters":load("res://resources/box_blue.tres"),
				"Items":load("res://resources/box_yellow.tres"),
				"Narration":load("res://resources/box_grey.tres"),
				"Locations":load("res://resources/box_green.tres"),
				"Connections":load("res://resources/box_green.tres") }

var production_list:ParsedJSON = ParsedJSON.new()
var elements_size := Vector2.ZERO
var graph_handle:GraphEdit
var current:Dictionary

func load_production_list(filename):
	if !filename:
		Globals.event_log.add_text("No such file: " + filename)
		return

	if !production_list.load_JSON("res://json_game/"+filename):
		Globals.event_log.add_text("loaded "+filename+" with productions: " + str(production_list.item_count) )
		print(production_list.item_current_id)
#		print (JSON.print(production_list.item_list[22], "\t"))
		load_current()

func load_current():
	current = production_list.get_item()

func load_next():
	production_list.get_next_item()
	current = production_list.item

func load_prev():
	production_list.get_prev_item()
	current = production_list.item

func get_current():
	return current
	
func build_graph(production_side:String):
	graph_handle.get_node("title").text = production_side +": "+ current["Title"] 
	
	var partial = current[production_side]["Locations"]
	elements_size = Vector2.ZERO
	for key in partial.keys(): 
		elements_size.x = 0
		process_item(partial[key], key, 0, "Locations")
		elements_size.y += 1
		
func process_item(item, key, parent, type):
	if typeof(item) == TYPE_DICTIONARY:
		match key:
			"Attributes", "Characters", "Items", "Narration", "Connections":
				elements_size.x += 1
				for new_key in item.keys():
					process_item( item[new_key], new_key, parent, key )
				elements_size.x -= 1
			_: 
				if type == "Attributes":
					if parent.get_node("Label").text:
						parent.get_node("Label").text+= "\n"
					if item.has(key):
						parent.get_node("Label").text += "["+key+":"+item[key]+"]"
					else:
						parent.get_node("Label").text += "["+key+"]"
				elif  type == "Narration":
					parent.add_child( add_label("["+key+"]", Label.ALIGN_CENTER, Color.brown) )
				else:
					var child = add_vertex( key, type )
					child.add_child( add_label("", Label.ALIGN_CENTER) )
					if parent:
						connect_vertices(parent, child, type, key)
					for new_key in item.keys():
						process_item( item[new_key], new_key, child, type )
					if ["Characters","Items"].has(type):
						elements_size.y += 1

	elif !["Attributes","Characters","Items","Narration" ].has(key):
		if type == "Attributes":
			if parent.get_node("Label").text:
				parent.get_node("Label").text+= "\n"
			if item :
				parent.get_node("Label").text += "["+key+":"+item+"]"
			else:
				parent.get_node("Label").text += "["+key+"]"
#			elements_size.y += 1
		elif  type == "Narration":
			parent.add_child( add_label("["+key+"]", Label.ALIGN_CENTER, Color.brown) )
			elements_size.y += 1
		else:
			var child = add_vertex( key, type )
			child.add_child( add_label("", Label.ALIGN_CENTER) )
			elements_size.y += 1
			if parent:
				connect_vertices(parent, child, type, key)
	else:
		print ("this happened: ", key)

func add_vertex(key:String, type:String):
	var new_node := GraphNode.new()
	new_node.name = key
	new_node.title = key
	new_node.rect_size = Vector2(100, 60)
	new_node.offset = Vector2( 200 * elements_size.x, 60 * elements_size.y ) 
	new_node.set("custom_styles/frame", node_style[type] )
	graph_handle.add_child(new_node)
	return new_node

func connect_vertices(parent, child, type, key):
	var parent_in_slots  = parent.get_connection_input_count()
	var parent_out_slots = parent.get_connection_output_count()
	var parent_slots     = parent_in_slots + parent_out_slots
	var child_in_slots   = child.get_connection_input_count()
	var child_out_slots  = child.get_connection_output_count()
	var child_slots      = child_in_slots + child_out_slots
	var color_in         = Color.black
	var color_out        = Color.black
	parent.add_child( add_label(key, Label.ALIGN_RIGHT) )
	if elements_size.x == 1:
		parent.set_slot(parent_slots+1, false, 0, color_in, true, 0, color_out)
	else:
		parent.set_slot(parent_slots, false, 0, color_in, true, 0, color_out)
	child.set_slot(child_slots, true, 0, color_out, false, 0, color_in)
	graph_handle.connect_node(  parent.name, parent_out_slots, child.name, child_in_slots )

func add_label(name:String, align:int, color:Color = Color.black):
	var label = Label.new()
	label.set("custom_colors/font_color", color)
	label.name = "Label"
	label.set_text(name)
	label.align = align
	return label

