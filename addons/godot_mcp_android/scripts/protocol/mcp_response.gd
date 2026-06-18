@tool
class_name MCPResponse
extends RefCounted


static func result(id, result: Variant) -> Dictionary:
	return {
		"jsonrpc": "2.0",
		"id": id,
		"result": result,
	}


static func error(id, code: int, message: String) -> Dictionary:
	return {
		"jsonrpc": "2.0",
		"id": id,
		"error": {
			"code": code,
			"message": message,
		},
	}


static func tool_result(id, payload: Variant) -> Dictionary:
	return result(id, {
		"content": [
			{
				"type": "text",
				"text": JSON.stringify(payload),
			}
		],
	})
