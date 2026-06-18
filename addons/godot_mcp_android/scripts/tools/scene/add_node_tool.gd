@tool
extends MCPTool


func get_name() -> String:
	return "add_node"


func get_description() -> String:
	return "Add a node to the edited scene."


func get_input_schema() -> Dictionary:
	return {
		"type": "object",
		"properties": {
			"parent_path": {"type": "string", "description": "NodePath from the edited scene root. Use . for the root."},
			"type": {"type": "string", "description": "Godot class name, for example Node2D, Sprite2D, or Label."},
			"name": {"type": "string", "description": "New node name."},
		},
		"required": ["parent_path", "type", "name"],
		"additionalProperties": false,
	}


func execute(arguments: Dictionary) -> Dictionary:
	var parent := resolve_scene_node(String(arguments.get("parent_path", ".")))
	if parent == null:
		return tool_error("parent node not found")

	var type_name := String(arguments.get("type", "Node"))
	var node_name := String(arguments.get("name", type_name))
	var node := ClassDB.instantiate(type_name)
	if node == null or not node is Node:
		return tool_error("cannot instantiate node type: %s" % type_name)

	node.name = node_name
	parent.add_child(node)
	node.owner = get_edited_scene_root()
	return {
		"ok": true,
		"path": relative_scene_path(node),
	}
