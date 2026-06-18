@tool
extends MCPTool


func get_name() -> String:
	return "scan_filesystem"


func get_description() -> String:
	return "Ask the Godot editor resource filesystem to rescan project files."


func execute(_arguments: Dictionary) -> Dictionary:
	if editor_interface == null:
		return tool_error("editor interface is unavailable")

	var resource_filesystem := editor_interface.get_resource_filesystem()
	if resource_filesystem == null:
		return tool_error("editor resource filesystem is unavailable")

	resource_filesystem.scan()
	return {
		"ok": true,
		"message": "resource filesystem scan requested",
	}
