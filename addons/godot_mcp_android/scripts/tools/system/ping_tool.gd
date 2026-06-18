@tool
extends MCPTool


func get_name() -> String:
	return "ping"


func get_description() -> String:
	return "Check that the Godot editor plugin is reachable."


func execute(_arguments: Dictionary) -> Dictionary:
	return {"ok": true}
