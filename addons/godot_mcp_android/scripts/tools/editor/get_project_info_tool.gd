@tool
extends MCPTool


func get_name() -> String:
	return "get_project_info"


func get_description() -> String:
	return "Return basic information about the current Godot project and editor context."


func execute(_arguments: Dictionary) -> Dictionary:
	var root := get_edited_scene_root()
	return {
		"ok": true,
		"project_name": String(ProjectSettings.get_setting("application/config/name", "")),
		"project_path": ProjectSettings.globalize_path("res://"),
		"main_scene": String(ProjectSettings.get_setting("application/run/main_scene", "")),
		"edited_scene_root": null if root == null else {
			"name": root.name,
			"type": root.get_class(),
			"scene_file_path": root.scene_file_path,
		},
	}
