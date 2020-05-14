extends OptionButton

var files = []
export(String, DIR)  var rootPath = "res://json/"

func _ready():
	update_list()
	
func update_list():
	self.clear()
	files = []
	var dir = Directory.new()
	dir.open(rootPath)
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		if dir.dir_exists(rootPath +'/'+ file):
			continue
		elif not file.begins_with("."):
			files.append(file)
			add_item(file)

	dir.list_dir_end()
