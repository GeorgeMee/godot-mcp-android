@tool
extends MCPTool


func get_name() -> String:
	return "remove_node"


func get_description() -> String:
	return "Remove a node from the edited scene."


func get_input_schema() -> Dictionary:
	return {
		"type": "object",
		"properties": {
			"node_path": {"type": "string", "description": "NodePath from the edited scene root. Use . for the root."},
		},
		"required": ["node_path"],
		"additionalProperties": false,
	}


func execute(arguments: Dictionary) -> Dictionary:
	var node := resolve_scene_node(String(arguments.get("node_path", ".")))
	if node == null:
		return tool_error("node not found")

	var root := get_edited_scene_root()
	if node == root:
		return tool_error("cannot remove the scene root node")

	var path := relative_scene_path(node)
	node.queue_free()
	return {
		"ok": true,
		"path": path,
	}