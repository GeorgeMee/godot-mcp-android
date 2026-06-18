@tool
class_name MCPDispatcher
extends RefCounted

var _editor_interface: EditorInterface
var _tools: Dictionary = {}


func _init(editor_interface: EditorInterface) -> void:
	_editor_interface = editor_interface
	_register_tools()


func handle(request: Dictionary) -> Dictionary:
	var id = request.get("id", null)
	var method := String(request.get("method", ""))
	var params := request.get("params", {})

	match method:
		"initialize":
			return _result(id, {
				"protocolVersion": "2024-11-05",
				"serverInfo": {
					"name": "godot-mcp-android",
					"version": "0.1.0",
				},
				"capabilities": {
					"tools": {},
				},
			})
		"tools/list":
			return _result(id, {
				"tools": _tools.values(),
			})
		"tools/call":
			if typeof(params) != TYPE_DICTIONARY:
				return _error(id, -32602, "tools/call params must be an object")
			return _call_tool(id, params)
		_:
			return _error(id, -32601, "method not found: %s" % method)


func _register_tools() -> void:
	_add_tool(
		"ping",
		"Check that the Godot editor plugin is reachable.",
		{
			"type": "object",
			"properties": {},
			"additionalProperties": false,
		}
	)
	_add_tool(
		"get_scene_tree",
		"Return the edited scene root and its descendants.",
		{
			"type": "object",
			"properties": {},
			"additionalProperties": false,
		}
	)
	_add_tool(
		"add_node",
		"Add a node to the edited scene.",
		{
			"type": "object",
			"properties": {
				"parent_path": {"type": "string", "description": "NodePath from the edited scene root. Use . for the root."},
				"type": {"type": "string", "description": "Godot class name, for example Node2D, Sprite2D, or Label."},
				"name": {"type": "string", "description": "New node name."},
			},
			"required": ["parent_path", "type", "name"],
			"additionalProperties": false,
		}
	)
	_add_tool(
		"set_node_property",
		"Set one property on a node in the edited scene.",
		{
			"type": "object",
			"properties": {
				"node_path": {"type": "string", "description": "NodePath from the edited scene root. Use . for the root."},
				"property": {"type": "string"},
				"value": {},
			},
			"required": ["node_path", "property", "value"],
			"additionalProperties": false,
		}
	)
	_add_tool(
		"save_scene",
		"Save the currently edited scene.",
		{
			"type": "object",
			"properties": {},
			"additionalProperties": false,
		}
	)


func _add_tool(name: String, description: String, input_schema: Dictionary) -> void:
	_tools[name] = {
		"name": name,
		"description": description,
		"inputSchema": input_schema,
	}


func _call_tool(id, params: Dictionary) -> Dictionary:
	var name := String(params.get("name", ""))
	var arguments := params.get("arguments", {})
	if not _tools.has(name):
		return _error(id, -32602, "unknown tool: %s" % name)
	if typeof(arguments) != TYPE_DICTIONARY:
		return _error(id, -32602, "tool arguments must be an object")

	match name:
		"ping":
			return _tool_result(id, {"ok": true})
		"get_scene_tree":
			return _tool_result(id, _get_scene_tree())
		"add_node":
			return _tool_result(id, _add_node(arguments))
		"set_node_property":
			return _tool_result(id, _set_node_property(arguments))
		"save_scene":
			return _tool_result(id, _save_scene())
		_:
			return _error(id, -32602, "unimplemented tool: %s" % name)


func _get_scene_tree() -> Dictionary:
	var root := _get_edited_scene_root()
	if root == null:
		return {"root": null}

	return {"root": _serialize_node(root, root)}


func _add_node(arguments: Dictionary) -> Dictionary:
	var parent := _resolve_node(String(arguments.get("parent_path", ".")))
	if parent == null:
		return _tool_error("parent node not found")

	var type_name := String(arguments.get("type", "Node"))
	var node_name := String(arguments.get("name", type_name))
	var node := ClassDB.instantiate(type_name)
	if node == null or not node is Node:
		return _tool_error("cannot instantiate node type: %s" % type_name)

	node.name = node_name
	parent.add_child(node)
	node.owner = _get_edited_scene_root()
	return {
		"ok": true,
		"path": _relative_path(node),
	}


func _set_node_property(arguments: Dictionary) -> Dictionary:
	var node := _resolve_node(String(arguments.get("node_path", ".")))
	if node == null:
		return _tool_error("node not found")

	var property_name := String(arguments.get("property", ""))
	node.set(property_name, arguments.get("value"))
	return {
		"ok": true,
		"path": _relative_path(node),
		"property": property_name,
	}


func _save_scene() -> Dictionary:
	var error := _editor_interface.save_scene()
	return {
		"ok": error == OK,
		"error": error_string(error),
	}


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


func _resolve_node(path: String) -> Node:
	var root := _get_edited_scene_root()
	if root == null:
		return null
	if path == "." or path == "" or path == str(root.name):
		return root
	return root.get_node_or_null(NodePath(path))


func _get_edited_scene_root() -> Node:
	return _editor_interface.get_edited_scene_root()


func _relative_path(node: Node) -> String:
	var root := _get_edited_scene_root()
	if root == null or node == root:
		return "."
	return str(root.get_path_to(node))


func _tool_result(id, payload: Variant) -> Dictionary:
	return _result(id, {
		"content": [
			{
				"type": "text",
				"text": JSON.stringify(payload),
			}
		],
	})


func _tool_error(message: String) -> Dictionary:
	return {
		"ok": false,
		"error": message,
	}


func _result(id, result: Variant) -> Dictionary:
	return {
		"jsonrpc": "2.0",
		"id": id,
		"result": result,
	}


func _error(id, code: int, message: String) -> Dictionary:
	return {
		"jsonrpc": "2.0",
		"id": id,
		"error": {
			"code": code,
			"message": message,
		},
	}
