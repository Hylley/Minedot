extends Node
class_name packer


static var modules := {}
signal new_module_loaded(module_body : Dictionary)


func _ready() -> void:
	load_module('res://minedot.dpack')


func load_module(path) -> Dictionary:
	var module = JSON.parse_string(packer.unzip(path, 'map.json').get_string_from_utf8())
	var title = module.module

	modules[title] = module
	modules[title].path = path

	new_module_loaded.emit(modules[title])

	return modules[title]


static func unzip(path : String, filename : String) -> PackedByteArray:
	var reader := ZIPReader.new()

	if reader.open(path) != OK:
		push_error('Could not open resource: ' + filename + ' of ' + path + ';')
		return PackedByteArray()

	var res := reader.read_file(filename)
	reader.close()
	return res
