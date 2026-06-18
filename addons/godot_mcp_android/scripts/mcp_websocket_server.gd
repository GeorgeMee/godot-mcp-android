@tool
class_name MCPWebSocketServer
extends RefCounted

const MCPDispatcher := preload("res://addons/godot_mcp_android/scripts/mcp_dispatcher.gd")

var bind_host := "127.0.0.1"
var port := 8766

var _editor_interface: EditorInterface
var _dispatcher: MCPDispatcher
var _server := TCPServer.new()
var _clients: Array[WebSocketPeer] = []


func _init(editor_interface: EditorInterface) -> void:
	_editor_interface = editor_interface
	_dispatcher = MCPDispatcher.new(_editor_interface)


func start() -> Error:
	return _server.listen(port, bind_host)


func stop() -> void:
	for websocket in _clients:
		if websocket != null:
			websocket.close()
	_clients.clear()
	_server.stop()


func poll() -> void:
	while _server.is_connection_available():
		var stream := _server.take_connection()
		stream.set_no_delay(true)

		var websocket := WebSocketPeer.new()
		var error := websocket.accept_stream(stream)
		if error != OK:
			stream.disconnect_from_host()
			continue

		_clients.append(websocket)

	for index in range(_clients.size() - 1, -1, -1):
		var websocket := _clients[index]
		websocket.poll()

		var state := websocket.get_ready_state()
		if state == WebSocketPeer.STATE_CLOSED:
			_clients.remove_at(index)
			continue

		if state != WebSocketPeer.STATE_OPEN:
			continue

		while websocket.get_available_packet_count() > 0:
			var packet := websocket.get_packet()
			var request_text := packet.get_string_from_utf8()
			var response := _handle_message(request_text)
			websocket.send_text(JSON.stringify(response))


func _handle_message(request_text: String) -> Dictionary:
	var parsed = JSON.parse_string(request_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {
			"jsonrpc": "2.0",
			"id": null,
			"error": {
				"code": -32700,
				"message": "parse error: request message must be a JSON object",
			},
		}

	return _dispatcher.handle(parsed)
