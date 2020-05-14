extends Node2D


var story:ParsedJSON = ParsedJSON.new()
var dictionary = {}

func _ready():
	story.load_JSON('res://translations/dictionary_pol-ang.json')
	print("Translation: ", story.item_count)
	dictionary = story.item
	story.load_JSON('res://json/produkcje_zes04_polaczone.json_converted.json')
	print("loaded productions: ", story.item_count)
	
	if typeof(story.item) == TYPE_DICTIONARY:
		print("dictionary")
	if typeof(story.item) == TYPE_ARRAY:
		for item in story.item:
			for key in item['L_Side'].keys():
				item['L_Side'][key] = process_subtree(item['L_Side'][key])
			for key in item['R_Side'].keys():
				item['R_Side'][key] = process_subtree(item['R_Side'][key])
	story.save_JSON('res://translations/translated/wynik.json')
	
func process_subtree(tree):
	if typeof(tree) == TYPE_STRING:
		return translate_string(tree)
	else:
		var new_tree = {}
		for key in tree.keys():
			new_tree[translate_string(key)] = process_subtree(tree[key])
		return new_tree
	
func translate_string ( value:String ) -> String:
	if value.length():
		if dictionary.has(value.to_lower()):
			return dictionary[value.to_lower()]
		else:
			for key in dictionary.keys():
				if dictionary[key] == value.to_lower():
					return dictionary[key]
				else:
#					return "Missing translation for: " + value
					return value
	else:
		return value
	

