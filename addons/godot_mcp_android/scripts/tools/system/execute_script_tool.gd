@tool
extends MCPTool


func get_name() -> String:
	return "execute_script"


func get_description() -> String:
	return "Execute a GDScript expression and return the result."


func get_input_schema() -> Dictionary:
	return {
		"type": "object",
		"properties": {
			"script": {"type": "string", "description": "GDScript code to execute. Use return to pass a value back."},
		},
		"required": ["script"],
		"additionalProperties": false,
	}


func execute(arguments: Dictionary) -> Dictionary:
	var source := String(arguments.get("script", ""))
	if source == "":
		return tool_error("script is required")

	var expression := Expression.new()
	var error := expression.parse(source, ["editor_interface", "get_edited_scene_root", "print", "push_error", "push_warning"])
	if error != OK:
		return tool_error("parse error: %s" % expression.get_error_text())

	var scene_root: Node = null
	if editor_interface != null:
		scene_root = editor_interface.get_edited_scene_root()

	var result = expression.execute([
		editor_interface,
		scene_root,
		func(x): print(x),
		func(x): push_error(x),
		func(x): push_warning(x),
	], null, true)

	if expression.has_execute_failed():
		return tool_error("runtime error: %s" % expression.get_error_text())

	return {
		"ok": true,
		"result": result,
	}