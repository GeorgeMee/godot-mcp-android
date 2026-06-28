@tool
class_name MCPToolRegistry
extends RefCounted

const PingTool := preload("res://addons/godot_mcp_android/scripts/tools/system/ping_tool.gd")
const ExecuteScriptTool := preload("res://addons/godot_mcp_android/scripts/tools/system/execute_script_tool.gd")
const GetSceneTreeTool := preload("res://addons/godot_mcp_android/scripts/tools/scene/get_scene_tree_tool.gd")
const AddNodeTool := preload("res://addons/godot_mcp_android/scripts/tools/scene/add_node_tool.gd")
const SetNodePropertyTool := preload("res://addons/godot_mcp_android/scripts/tools/scene/set_node_property_tool.gd")
const GetNodePropertyTool := preload("res://addons/godot_mcp_android/scripts/tools/scene/get_node_property_tool.gd")
const RemoveNodeTool := preload("res://addons/godot_mcp_android/scripts/tools/scene/remove_node_tool.gd")
const SaveSceneTool := preload("res://addons/godot_mcp_android/scripts/tools/scene/save_scene_tool.gd")
const GetProjectInfoTool := preload("res://addons/godot_mcp_android/scripts/tools/editor/get_project_info_tool.gd")
const ListFilesTool := preload("res://addons/godot_mcp_android/scripts/tools/filesystem/list_files_tool.gd")
const ReadFileTool := preload("res://addons/godot_mcp_android/scripts/tools/filesystem/read_file_tool.gd")
const WriteFileTool := preload("res://addons/godot_mcp_android/scripts/tools/filesystem/write_file_tool.gd")
const EditFileTool := preload("res://addons/godot_mcp_android/scripts/tools/filesystem/edit_file_tool.gd")
const GrepTool := preload("res://addons/godot_mcp_android/scripts/tools/filesystem/grep_tool.gd")
const ScanFilesystemTool := preload("res://addons/godot_mcp_android/scripts/tools/diagnostics/scan_filesystem_tool.gd")
const GetResourceUidTool := preload("res://addons/godot_mcp_android/scripts/tools/diagnostics/get_resource_uid_tool.gd")
const ValidateResourceTool := preload("res://addons/godot_mcp_android/scripts/tools/diagnostics/validate_resource_tool.gd")
const GetEditorLogTool := preload("res://addons/godot_mcp_android/scripts/tools/diagnostics/get_editor_log_tool.gd")

var _tools: Dictionary = {}


func _init(editor_interface: EditorInterface) -> void:
	register(PingTool.new(editor_interface))
	register(ExecuteScriptTool.new(editor_interface))
	register(GetSceneTreeTool.new(editor_interface))
	register(AddNodeTool.new(editor_interface))
	register(SetNodePropertyTool.new(editor_interface))
	register(GetNodePropertyTool.new(editor_interface))
	register(RemoveNodeTool.new(editor_interface))
	register(SaveSceneTool.new(editor_interface))
	register(GetProjectInfoTool.new(editor_interface))
	register(ListFilesTool.new(editor_interface))
	register(ReadFileTool.new(editor_interface))
	register(WriteFileTool.new(editor_interface))
	register(EditFileTool.new(editor_interface))
	register(GrepTool.new(editor_interface))
	register(ScanFilesystemTool.new(editor_interface))
	register(GetResourceUidTool.new(editor_interface))
	register(ValidateResourceTool.new(editor_interface))
	register(GetEditorLogTool.new(editor_interface))


func register(tool: MCPTool) -> void:
	_tools[tool.get_name()] = tool


func has_tool(name: String) -> bool:
	return _tools.has(name)


func get_tool(name: String) -> MCPTool:
	return _tools.get(name)


func list_tool_definitions() -> Array:
	var definitions: Array = []
	for tool in _tools.values():
		definitions.append(tool.get_definition())
	return definitions
