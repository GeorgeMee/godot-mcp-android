@tool
extends MCPTool

const DEFAULT_MAX_RESULTS := 200


func get_name() -> String:
	return "list_files"


func get_description() -> String:
	return "List files and directories under a project-relative path."


func get_input_schema() -> Dictionary:
	return {
		"type": "object",
		"properties": {
			"path": {"type": "string", "description": "Project-relative path or res:// path. Defaults to project root."},
			"recursive": {"type": "boolean", "description": "Whether to recurse into subdirectories."},
			"max_results": {"type": "number", "description": "Maximum number of entries to return."},
		},
		"additionalProperties": false,
	}


func execute(arguments: Dictionary) -> Dictionary:
	var path := String(arguments.get("path", "."))
	if not is_safe_project_path(path):
		return tool_error("path must stay inside res://")

	var max_results := int(arguments.get("max_results", DEFAULT_MAX_RESULTS))
	if max_results <= 0:
		max_results = DEFAULT_MAX_RESULTS

	var entries: Array = []
	var normalized := normalize_project_path(path)
	var root := "res://" if normalized == "." or normalized == "" else "res://%s" % normalized
	var error := _list_dir(root, bool(arguments.get("recursive", false)), max_results, entries)
	if error != OK:
		return tool_error("failed to list files: %s" % error_string(error))

	return {
		"ok": true,
		"path": root,
		"entries": entries,
		"truncated": entries.size() >= max_results,
	}


func _list_dir(path: String, recursive: bool, max_results: int, entries: Array) -> Error:
	if entries.size() >= max_results:
		return OK

	var dir := DirAccess.open(path)
	if dir == null:
		return DirAccess.get_open_error()

	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if entries.size() >= max_results:
			break
		if name == "." or name == "..":
			name = dir.get_next()
			continue

		var child_path := path.path_join(name)
		var is_directory := dir.current_is_dir()
		entries.append({
			"path": child_path,
			"name": name,
			"type": "directory" if is_directory else "file",
		})

		if recursive and is_directory:
			var error := _list_dir(child_path, recursive, max_results, entries)
			if error != OK:
				dir.list_dir_end()
				return error

		name = dir.get_next()

	dir.list_dir_end()
	return OK
