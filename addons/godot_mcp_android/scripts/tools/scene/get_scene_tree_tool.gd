@tool
extends MCPTool


func get_name() -> String:
	return "get_scene_tree"


func get_description() -> String:
	return "Return the edited scene root and its descendants."


func execute(_arguments: Dictionary) -> Dictionary:
	var root := get_edited_scene_root()
	if root == null:
		return {"root": null}

	return {"root": _serialize_node(root, root)}


func _serialize_node(node: Node, scene_root: Node) -> Dictionary:
	var children: Array = []
	for child in node.get_children():
		if child is Node:
			children.append(_serialize_node(child, scene_root))

	return {
		"name": node.name,
		"type": node.get_class(),
		"path": "." if node == scene_root else str(scene_root.get_path_to(node)),
		"child_count": children.size(),
		"children": children,
	}
