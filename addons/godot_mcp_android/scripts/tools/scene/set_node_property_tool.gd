@tool
extends MCPTool


func get_name() -> String:
	return "set_node_property"


func get_description() -> String:
	return "Set one property on a node in the edited scene."


func get_input_schema() -> Dictionary:
	return {
		"type": "object",
		"properties": {
			"node_path": {"type": "string", "description": "NodePath from the edited scene root. Use . for the root."},
			"property": {"type": "string"},
			"value": {},
		},
		"required": ["node_path", "property", "value"],
		"additionalProperties": false,
	}


func execute(arguments: Dictionary) -> Dictionary:
	var node := resolve_scene_node(String(arguments.get("node_path", ".")))
	if node == null:
		return tool_error("node not found")

	var property_name := String(arguments.get("property", ""))
	node.set(property_name, arguments.get("value"))
	return {
		"ok": true,
		"path": relative_scene_path(node),
		"property": property_name,
	}
