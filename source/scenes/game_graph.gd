extends Node

var result_json
var result = {}
var productions

var characters = []
var locations  = []
var narration  = []
var items      = []

var story:ParsedJSON = ParsedJSON.new()

func _ready():
	window_resize()
	get_tree().get_root().connect("size_changed", self, "window_resize")
	story.load_JSON('res://json_game/initials.json')
	
	print("loaded productions: ",story.item_count)
	
	set_dissabled_buttons()
	generate_graph()
	
func window_resize():
	$HBox/GraphEdit.rect_size.y = OS.get_window_size().y/2
	$HBox/GraphEdit.rect_size.x = OS.get_window_size().x/2
	$HBox/GraphEdit.rect_size.y = OS.get_window_size().y/2
	$HBox/GraphEdit.rect_size.x = OS.get_window_size().x/2
	
func generate_graph():

	clear_data()
	
	$HBox/GraphEdit/Title.text = story.item["Title"] 
	story.get_root_JSON()
	story.get_item_branch("Locations")
	add_vertices("Locations")
	
	story.get_root_JSON()
	story.get_item_branch("Locations")
	connect_edges("Locations")
	story.get_root_JSON()
	story.get_item_branch("Characters")
	add_vertices("Characters")
	story.get_root_JSON()
	story.get_item_branch("Characters")
	connect_edges("Characters")
	story.get_root_JSON()
	story.get_item_branch("Items")
	add_vertices("Items")
	story.get_root_JSON()
	story.get_item_branch("Items")
	connect_edges("Items")
	
#	position_loacations()
	
	position_orphan_nodes()

func position_loacations():
	var location_list = locations
	var max_conection = 0
	var loaction_node
	### get loaction with max connections
	var layers = { '0': 0 }
	var layer:int = 0
	var next_layer:int = 0
	for location in location_list:
		var location_node = $HBox/GraphEdit.get_node(location)
		if location_node.get_connection_input_count() + location_node.get_connection_output_count() > max_conection:
			max_conection = location_node.get_connection_input_count() + location_node.get_connection_output_count()
			loaction_node = location_node

	loaction_node.offset = Vector2.ZERO
	var connections = $HBox/GraphEdit.get_connection_list()
	while 1:
		var next_location_node = null
#		print("processing ", loaction_node.name, " node")
		for connection in connections:
			if connection.get('from') == loaction_node.name:
				if next_location_node == null:
					if location_list.has($HBox/GraphEdit.get_node(connection.get('to')).name):
						next_location_node = $HBox/GraphEdit.get_node(connection.get('to'))
						next_layer = layer+1
#						print("getting :", next_location_node.name)
				if layers.has(str(layer+1)):
					layers[str(layer+1)] += 60
				else: 
					layers[str(layer+1)] = layers[str(layer)]
				$HBox/GraphEdit.get_node(connection.get('to')).offset = loaction_node.offset + Vector2(160, layers[str(layer+1)])
				layers[str(layer)] += 10
				
			if connection.get('to') == loaction_node.name:
				if next_location_node == null:
					if location_list.has($HBox/GraphEdit.get_node(connection.get('from')).name):
						next_location_node = $HBox/GraphEdit.get_node(connection.get('from'))
						next_layer = layer-1
#						print("getting :", next_location_node.name)
				if layers.has(str(layer-1)):
					layers[str(layer-1)] += 60
				else: 
					layers[str(layer-1)] = layers[str(layer)]
				$HBox/GraphEdit.get_node(connection.get('from')).offset = loaction_node.offset + Vector2(-160, layers[str(layer-1)])
				layers[str(layer)] += 10
		loaction_node.offset.y = -layers[str(layer)]
		if next_location_node == null:
			break
		else:
			layer = next_layer
			next_layer = 0
			location_list.erase(loaction_node.name)
			loaction_node = next_location_node
		
func add_vertices( type:String ):
	if story.get_item_branch("Vertex"):
		for vertex in story.item_branch.keys(): 
			var idx = 0 
			if story.item_branch[vertex]:
				for key in story.item_branch[vertex].keys():
					idx += 1
					add_story_block( idx, type, key )

func add_story_block( idx:int, type:String, key:String ):
	var new_graph_node = GraphNode.new()
	new_graph_node.name = key
	new_graph_node.title = key
	new_graph_node.rect_size = Vector2(100, 60)
	match type:
		"Characters":
			characters.append(key)
			new_graph_node.offset = Vector2( 230, 80 * (idx+1) )
			new_graph_node.set("custom_colors/title_color", Color.white)
			$HBox/GraphEdit.add_child(new_graph_node)
		"Narration":
			narration.append(key)
			new_graph_node.offset = Vector2( 490, 80 * (idx+1) )
			new_graph_node.set("custom_colors/title_color", Color.orange)
			$HBox/GraphEdit.add_child(new_graph_node)
		"Locations":
			locations.append(key)
			new_graph_node.offset = Vector2( 100, 110 * (idx+1) )
			new_graph_node.set("custom_colors/title_color", Color.blue)
			$HBox/GraphEdit.add_child(new_graph_node)
		"Items":
			items.append(key)
#			new_graph_node.offset = Vector2( 360, 80 * (idx+1) )
#			new_graph_node.set("custom_colors/title_color", Color.darkgreen)
#			$HBox/GraphEdit.add_child(new_graph_node)
	
func connect_edges( type:String ):
	if !story.get_item_branch("Edges"):
		return 0
	for edge in story.item_branch:
		var edge_color:Color
		if edge.keys()[0] in locations :
			edge_color = Color.aquamarine
		elif  edge.keys()[0] in characters :
			edge_color = Color.white
		elif edge.keys()[0] in narration :
			edge_color = Color.orange
		else:
			edge_color = Color.black
		
		
		if edge.keys()[0] in items :
			var slots_in = $HBox/GraphEdit.get_node(edge.values()[0]).get_connection_input_count()
			var slots_out = $HBox/GraphEdit.get_node(edge.values()[0]).get_connection_output_count()
			var slots = slots_in + slots_out
			$HBox/GraphEdit.get_node(edge.values()[0]).add_child(add_slot( edge.keys()[0], "left", Color.yellow))
#			$HBox/GraphEdit.get_node(edge.values()[0]).set_slot(slots, false, 3, Color.darkgreen, false, 3, Color.darkgreen)
		else:
#		print(edge, " ",edge.keys()[0],  " ",edge.values()[0])
			var key = edge.keys()[0]
			var value = edge.values()[0]
			var parent = $HBox/GraphEdit.get_node(key)
			var parent_in_slots = parent.get_connection_input_count()
			var parent_out_slots = parent.get_connection_output_count()
			var parent_slots = parent_in_slots + parent_out_slots
			
			
			var child  = $HBox/GraphEdit.get_node(value)
			var child_in_slots  = child.get_connection_input_count()
			var child_out_slots = child.get_connection_output_count()
			var child_slots     = child_in_slots + child_out_slots
	
			parent.add_child(add_slot(value, "left", edge_color))
			child.add_child(add_slot(key, "right", edge_color))
			print (edge_color)
			parent.set_slot(parent_slots, true, 2, edge_color, false, 2, edge_color)
			child.set_slot(child_slots, false, 2, edge_color, true, 2, edge_color)
			$HBox/GraphEdit.connect_node( value, child_out_slots, key, parent_in_slots )
			parent.offset.x = child.offset.x + 200
			parent.offset.y = child.offset.y + 50 * ( child_slots - 1 )

func add_slot(name:String, align:String, color:Color = Color.white):
		var slot = Label.new()
		slot.set("custom_colors/font_color", color)
		slot.set_text(name)
		match align:
			"left":
				slot.align = Label.ALIGN_LEFT
			"right":
				slot.align = Label.ALIGN_RIGHT
		return slot

func position_orphan_nodes():
	var orphan_index:int = 0
	for node in $HBox/GraphEdit.get_children():
		if node is GraphNode:
			if node.get_connection_input_count() + node.get_connection_output_count() == 0:
				node.offset.y = orphan_index * -55
				node.offset.x = -600
				orphan_index +=1

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

#
#func load_item_prev():
#	story.get_prev_item()
#	set_dissabled_buttons()
#	clear_graph()
#	generate_graph("L_Side",$HBox/GraphEditLeft)
#	generate_graph("R_Side",$HBox/GraphEditRight)

func set_dissabled_buttons():
	if story.item_current_id == 0:
		$HBox/GraphEdit/Previous.disabled = true
	else:
		$HBox/GraphEdit/Previous.disabled = false
		
	if story.item_current_id == story.item_count-1:
		$HBox/GraphEdit/Next.disabled = false
	else:
		$HBox/GraphEdit/Next.disabled = true

func _on_GraphEdit_connection_request(from, from_slot, to, to_slot):
	print (from," ", from_slot," ", to," ", to_slot)



func _on_Home_pressed():
	get_tree().change_scene_to(load("res://main.tscn") )

