@tool
extends MCPTool


func get_name() -> String:
	return "save_scene"


func get_description() -> String:
	return "Save the currently edited scene."


func execute(_arguments: Dictionary) -> Dictionary:
	var error := editor_interface.save_scene()
	return {
		"ok": error == OK,
		"error": error_string(error),
	}
