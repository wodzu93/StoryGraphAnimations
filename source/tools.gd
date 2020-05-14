extends Node

func _on_game_graph_pressed():
	get_tree().change_scene_to(load("res://scenes/game_graph.tscn") )

func _on_production_vewer_pressed():
	get_tree().change_scene_to(load("res://scenes/production_viewer.tscn") )


func _on_production_converter_pressed():
	get_tree().change_scene_to(load("res://scenes/production_converter.tscn") )

