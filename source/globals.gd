extends Node

var event_log:EventLog

var last_world_file = ""
var last_actions_file = ""

func save_last_open_files():
	var file = File.new()
	file.open("user://setings.ini", file.WRITE)
	file.store_line(last_world_file)
	file.store_line(last_actions_file)
	file.close()

func load_last_open_files():
	var file = File.new()
	file.open("user://setings.ini", file.READ)
	last_world_file = file.get_line()
	last_actions_file = file.get_line()
	file.close()
