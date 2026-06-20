@tool
class_name MCPHttpServer
extends RefCounted

const MCPDispatcher := preload("res://addons/godot_mcp_android/scripts/protocol/mcp_dispatcher.gd")

const SETTING_BIND_HOST := "godot_mcp_android/bind_host"
const SETTING_HTTP_PORT := "godot_mcp_android/http_port"

var bind_host := "127.0.0.1"
var port := 8765

var _editor_interface: EditorInterface
var _dispatcher: MCPDispatcher
var _server := TCPServer.new()
var _clients: Array[Dictionary] = []


func _init(editor_interface: EditorInterface) -> void:
	_editor_interface = editor_interface
	_dispatcher = MCPDispatcher.new(_editor_interface)


func start() -> Error:
	_apply_settings()
	return _server.listen(port, bind_host)


func configure(host: String, p_port: int) -> void:
	bind_host = host
	port = p_port


func restart() -> Error:
	stop()
	return start()


func _apply_settings() -> void:
	bind_host = ProjectSettings.get_setting(SETTING_BIND_HOST, bind_host)
	port = ProjectSettings.get_setting(SETTING_HTTP_PORT, port)


func stop() -> void:
	for client in _clients:
		var peer: StreamPeerTCP = client.peer
		if peer != null:
			peer.disconnect_from_host()
	_clients.clear()
	_server.stop()


func poll() -> void:
	while _server.is_connection_available():
		var peer := _server.take_connection()
		peer.set_no_delay(true)
		_clients.append({
			"peer": peer,
			"buffer": PackedByteArray(),
		})

	for index in range(_clients.size() - 1, -1, -1):
		var client := _clients[index]
		var peer: StreamPeerTCP = client["peer"]
		if peer.get_status() == StreamPeerTCP.STATUS_NONE or peer.get_status() == StreamPeerTCP.STATUS_ERROR:
			_clients.remove_at(index)
			continue

		var available := peer.get_available_bytes()
		if available <= 0:
			continue

		var chunk := peer.get_data(available)
		if chunk[0] != OK:
			_send_response(peer, 500, {"error": "failed to read request"})
			_clients.remove_at(index)
			continue

		var buffer: PackedByteArray = client["buffer"]
		buffer.append_array(chunk[1])
		client["buffer"] = buffer
		_clients[index] = client

		var request_text := buffer.get_string_from_utf8()
		if not _has_complete_http_request(request_text):
			continue

		var response := _handle_http_request(request_text)
		_send_response(peer, response.status, response.body)
		peer.disconnect_from_host()
		_clients.remove_at(index)


func _has_complete_http_request(request_text: String) -> bool:
	var header_end := request_text.find("\r\n\r\n")
	if header_end == -1:
		return false

	var content_length := _get_content_length(request_text.substr(0, header_end))
	if content_length == 0:
		return true

	var body_start := header_end + 4
	return request_text.length() >= body_start + content_length


func _handle_http_request(request_text: String) -> Dictionary:
	var header_end := request_text.find("\r\n\r\n")
	if header_end == -1:
		return _http_result(400, {"error": "malformed HTTP request"})

	var header_text := request_text.substr(0, header_end)
	var header_lines := header_text.split("\r\n")
	if header_lines.is_empty():
		return _http_result(400, {"error": "missing request line"})

	var request_line := String(header_lines[0]).split(" ")
	if request_line.size() < 2:
		return _http_result(400, {"error": "malformed request line"})

	var method := String(request_line[0])
	var path := String(request_line[1])
	if method == "GET" and path == "/health":
		return _http_result(200, {
			"ok": true,
			"name": "godot-mcp-android",
			"transport": "http-json-rpc",
		})

	if method != "POST" or (path != "/rpc" and path != "/"):
		return _http_result(404, {"error": "use POST /, POST /rpc, or GET /health"})

	var content_length := _get_content_length(header_text)
	var body := request_text.substr(header_end + 4, content_length)
	var parsed = JSON.parse_string(body)
	if typeof(parsed) != TYPE_DICTIONARY:
		return _http_result(400, {"error": "request body must be a JSON object"})

	var result := _dispatcher.handle(parsed)
	return _http_result(200, result)


func _get_content_length(header_text: String) -> int:
	for line in header_text.split("\r\n"):
		var separator := String(line).find(":")
		if separator == -1:
			continue

		var key := String(line).substr(0, separator).strip_edges().to_lower()
		if key == "content-length":
			return String(line).substr(separator + 1).strip_edges().to_int()

	return 0


func _send_response(peer: StreamPeerTCP, status: int, body: Variant) -> void:
	var status_text := "OK" if status < 400 else "Error"
	var body_text := JSON.stringify(body)
	var response := "HTTP/1.1 %d %s\r\n" % [status, status_text]
	response += "Content-Type: application/json; charset=utf-8\r\n"
	response += "Access-Control-Allow-Origin: *\r\n"
	response += "Connection: close\r\n"
	response += "Content-Length: %d\r\n\r\n" % body_text.to_utf8_buffer().size()
	response += body_text
	peer.put_data(response.to_utf8_buffer())


func _http_result(status: int, body: Variant) -> Dictionary:
	return {
		"status": status,
		"body": body,
	}
