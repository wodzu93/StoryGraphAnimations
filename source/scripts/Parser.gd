extends Object
class_name ParsedJSON

var file_name = ""
#var file_path = ""

var result_json
var result = {}

var item      = {}
var item_list = []

var item_count:int = 0
var item_current_id:int = 0

var item_branch = {}

func load_JSON(file_name):
	self.file_name = file_name
	var file = File.new()
	var err = file.open(file_name, file.READ)
	if !err == OK:
		print("Failed to load file: "+ file_name)
		return FAILED
#	assert (err == OK, "Failed to load JSON file")
	var json = file.get_as_text()
	result_json = JSON.parse(json)
	file.close()

	if result_json.error == OK: 
		item_list = result_json.result
		item_count = item_list.size()
		if item_count <= item_current_id:
			item_current_id = item_count-1
		get_root_JSON()
		return OK
#		get_item()
	else:  # If parse has errors
		print("Parsing Failed:")
		print("Error: ", result_json.error)
		print("Error Line: ", result_json.error_line)
		print("Error String: ", result_json.error_string)
		return FAILED
#		assert(result_json.error == OK, "JSON failed to load")
	
func save_JSON(file_name):
	var file = File.new()
	var err  = file.open(file_name, File.WRITE)
	assert (err == OK || err == ERR_FILE_NOT_FOUND, "Error opening file: "+file_name+", error code: " + str(err))

	file.store_string(JSON.print(item_list, "\t"))
	file.close()
	
func get_root_JSON():
	item = item_list
	item_branch     = item

func get_item():
	check_loaded_JSON()
	item = item_list[ item_current_id ]
	item_branch     = item
	return item

func get_next_item():
	if item_current_id + 1 < item_count:
		item_current_id += 1
	else:
		assert("item out of range")
	get_item()

func get_prev_item():
	if item_current_id  > 0:
		item_current_id -= 1
	else:
		assert("item out of range")
	get_item()

func get_item_branch( path:String ):
	if item_branch.has(path):
		item_branch = item_branch[path]
		return FAILED
	else:
		return OK

func check_loaded_JSON():
	assert (item_list != null, "JSON file is not correct" ) 
	assert (item_count > 0, "JSON file is empty")
