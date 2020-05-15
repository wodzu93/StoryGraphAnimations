extends Control

var game_graph        = GameGraph.new()
var production_viewer = ProductionViewer.new()

onready var game_graph_handle := $VSplit/HBox/game_graph
onready var vertex_view_handle := $VSplit/HBox/vertex_view
onready var graph_left_handle := $VSplit/HSplit/LPanel/HSplit/GraphLeft
onready var graph_right_handle := $VSplit/HSplit/RPanel/HSplit/GraphRight
onready var json_edit_left_handle := $VSplit/HSplit/LPanel/HSplit/TextEdit
onready var json_edit_right_handle := $VSplit/HSplit/RPanel/HSplit/TextEdit

onready var event_log := $GUI/Control/event_log
onready var world_selector := $GUI/Control/world_selector
onready var actions_selector := $GUI/Control/actions_selector

var selected_file := ""

var selected_vertex:GraphNode

func _ready():
	Globals.event_log = event_log
	Globals.load_last_open_files()

	if Globals.last_world_file:
		var file_id =  world_selector.files.find(Globals.last_world_file)
		if file_id >= 0:
			world_selector.select(file_id)
		else:
			file_id = 0
		Globals.last_world_file =  world_selector.get_item_text(file_id)
		load_world()

	if Globals.last_actions_file:
		var file_id =  actions_selector.files.find(Globals.last_actions_file)
		if file_id >= 0:
			actions_selector.select(file_id)
		else:
			file_id = 0
		Globals.last_actions_file =  actions_selector.get_item_text(file_id)
		load_production()
	
func load_world():
	clear_graph(game_graph_handle)
	game_graph.world.load_JSON(world_selector.rootPath +'/'+Globals.last_world_file)
	game_graph.generate_graph(game_graph_handle)
	event_log.clear()
	event_log.add_text("Game graph complete")
	game_graph.world.save_JSON(world_selector.rootPath +'/'+Globals.last_world_file)
	Globals.save_last_open_files()
	
func load_production():
	production_viewer.load_production_list(Globals.last_actions_file)
	production_viewer.graph_handle = graph_left_handle
	clear_graph(production_viewer.graph_handle)
	production_viewer.build_graph("L_Side")
	json_edit_left_handle.text = JSON.print(production_viewer.production_list.item["L_Side"], "\t")
	
	production_viewer.graph_handle = graph_right_handle
	clear_graph(production_viewer.graph_handle)
	production_viewer.build_graph("R_Side")
	json_edit_right_handle.text = JSON.print(production_viewer.production_list.item["R_Side"], "\t")
	
	set_dissabled_buttons()
	
func clear_graph(graph_handle):
	graph_handle.clear_connections()
	for node in graph_handle.get_children():
		if node is GraphNode:
			node.clear_all_slots()
			node.free()

func set_dissabled_buttons():
	if production_viewer.production_list.item_current_id == 0:
		$GUI/Control/previous.disabled = true
	else:
		$GUI/Control/previous.disabled = false
	if production_viewer.production_list.item_current_id < production_viewer.production_list.item_count-1:
		$GUI/Control/next.disabled = false
	else:
		$GUI/Control/next.disabled = true
		
func _on_actions_selector_item_selected(id):
	Globals.last_actions_file = actions_selector.files[id]
	production_viewer.load_production_list(Globals.last_actions_file)
	load_production()
	Globals.save_last_open_files()

func _on_world_selector_item_selected(id):
	Globals.last_world_file = world_selector.files[id]
	$GUI/Control/world_selector/LineEdit.text = Globals.last_world_file
	load_world()
	Globals.save_last_open_files()

func _on_vertex_moved(from, to):
	game_graph.update_location_position(selected_vertex.name, to)
	game_graph.world.save_JSON(game_graph.world.file_name)

func _on_GraphEditLeft_scroll_offset_changed(ofs):
	graph_right_handle.scroll_offset = ofs
	graph_right_handle.zoom = graph_left_handle.zoom

func _on_GraphEditRight_scroll_offset_changed(ofs):
	graph_left_handle.scroll_offset = ofs
	graph_left_handle.zoom = graph_right_handle.zoom

func _on_game_graph_node_selected(node):
	selected_vertex = node
	game_graph.is_graph_node_selected = true
	game_graph.current_graph = vertex_view_handle
	clear_graph(game_graph.current_graph)
	game_graph.current_graph.visible = true
	game_graph.show_location(node.name)

func _on_game_graph_gui_input(event):
	#graph node unselected
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			if game_graph.is_graph_node_selected:
				game_graph.is_graph_node_selected = false
			else:
				game_graph.current_graph = vertex_view_handle
				clear_graph(vertex_view_handle)
				game_graph.current_graph.visible = false

func _on_save_world_pressed():
	game_graph.world.save_JSON(world_selector.rootPath +'/'+ $GUI/Control/world_selector/LineEdit.text)
	world_selector.update_list()

func _on_apply_pressed():
	game_graph.apply_production(production_viewer.current)
	game_graph.world.save_JSON(world_selector.rootPath +'/test_world.json')
	
func _on_previous_pressed():
	production_viewer.load_prev()
	load_production()
	game_graph.test_production(production_viewer.current)

func _on_next_pressed():
	production_viewer.load_next()
	load_production()
	game_graph.test_production(production_viewer.current)

func _on_initials_pressed():
	$load_initials.popup(Rect2(300,300,300,300))

func _on_load_initials_file_selected(path:String):
	Globals.last_world_file = path.get_file()
	var error = game_graph.load_initials(path)
	if error != OK:
		event_log.add_text("Failed loading initials")
	else:
		event_log.add_text("Loaded initials.json")
	game_graph.world.save_JSON("res://json_game/world/"+Globals.last_world_file)
	
	load_world()
	
