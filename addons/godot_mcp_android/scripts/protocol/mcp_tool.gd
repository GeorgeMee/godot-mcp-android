@tool
class_name MCPTool
extends RefCounted

var editor_interface: EditorInterface


func _init(p_editor_interface: EditorInterface) -> void:
	editor_interface = p_editor_interface


func get_name() -> String:
	return ""


func get_description() -> String:
	return ""


func get_input_schema() -> Dictionary:
	return {
		"type": "object",
		"properties": {},
		"additionalProperties": false,
	}


func get_definition() -> Dictionary:
	return {
		"name": get_name(),
		"description": get_description(),
		"inputSchema": get_input_schema(),
	}


func execute(_arguments: Dictionary) -> Dictionary:
	return {
		"ok": false,
		"error": "tool not implemented: %s" % get_name(),
	}


func get_edited_scene_root() -> Node:
	return editor_interface.get_edited_scene_root()


func resolve_scene_node(path: String) -> Node:
	var root := get_edited_scene_root()
	if root == null:
		return null
	if path == "." or path == "" or path == str(root.name):
		return root
	return root.get_node_or_null(NodePath(path))


func relative_scene_path(node: Node) -> String:
	var root := get_edited_scene_root()
	if root == null or node == root:
		return "."
	return str(root.get_path_to(node))


func tool_error(message: String) -> Dictionary:
	return {
		"ok": false,
		"error": message,
	}


func normalize_project_path(path: String) -> String:
	var cleaned := path.strip_edges().replace("\\", "/")
	if cleaned.begins_with("res://"):
		cleaned = cleaned.trim_prefix("res://")
	while cleaned.begins_with("/"):
		cleaned = cleaned.substr(1)
	return cleaned.simplify_path()


func globalize_project_path(path: String) -> String:
	return ProjectSettings.globalize_path("res://%s" % normalize_project_path(path))


func is_safe_project_path(path: String) -> bool:
	var normalized := normalize_project_path(path)
	if normalized == "" or normalized == ".":
		return true
	if normalized.begins_with("../") or normalized == "..":
		return false
	if normalized.is_absolute_path():
		return false
	return true
