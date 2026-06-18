@tool
class_name MCPDispatcher
extends RefCounted

const MCPResponse := preload("res://addons/godot_mcp_android/scripts/protocol/mcp_response.gd")
const MCPToolRegistry := preload("res://addons/godot_mcp_android/scripts/protocol/mcp_tool_registry.gd")

var _registry: MCPToolRegistry


func _init(editor_interface: EditorInterface) -> void:
	_registry = MCPToolRegistry.new(editor_interface)


func handle(request: Dictionary) -> Dictionary:
	var id = request.get("id", null)
	var method := String(request.get("method", ""))
	var params := request.get("params", {})

	match method:
		"initialize":
			return MCPResponse.result(id, {
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
			return MCPResponse.result(id, {
				"tools": _registry.list_tool_definitions(),
			})
		"tools/call":
			if typeof(params) != TYPE_DICTIONARY:
				return MCPResponse.error(id, -32602, "tools/call params must be an object")
			return _call_tool(id, params)
		_:
			return MCPResponse.error(id, -32601, "method not found: %s" % method)


func _call_tool(id, params: Dictionary) -> Dictionary:
	var name := String(params.get("name", ""))
	var arguments := params.get("arguments", {})
	if not _registry.has_tool(name):
		return MCPResponse.error(id, -32602, "unknown tool: %s" % name)
	if typeof(arguments) != TYPE_DICTIONARY:
		return MCPResponse.error(id, -32602, "tool arguments must be an object")

	var tool := _registry.get_tool(name)
	return MCPResponse.tool_result(id, tool.execute(arguments))
