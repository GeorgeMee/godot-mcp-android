@tool
extends MCPTool


func get_name() -> String:
	return "get_node_property"


func get_description() -> String:
	return "Get one property from a node in the edited scene."


func get_input_schema() -> Dictionary:
	return {
		"type": "object",
		"properties": {
			"node_path": {"type": "string", "description": "NodePath from the edited scene root. Use . for the root."},
			"property": {"type": "string"},
		},
		"required": ["node_path", "property"],
		"additionalProperties": false,
	}


func execute(arguments: Dictionary) -> Dictionary:
	var node := resolve_scene_node(String(arguments.get("node_path", ".")))
	if node == null:
		return tool_error("node not found")

	var property_name := String(arguments.get("property", ""))
	if property_name == "":
		return tool_error("property is required")

	var value = node.get(property_name)
	return {
		"ok": true,
		"path": relative_scene_path(node),
		"property": property_name,
		"value": value,
	}