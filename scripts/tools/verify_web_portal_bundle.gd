extends Node

# 网页门户（docs/index.html）契约回归。
#
# 1) fileSizes 必须等于 docs/index.pck / docs/index.wasm 的真实字节数。
#    Godot 用声明值累加下载总量，而进度回调里的 current 统计的是真实字节数：
#    声明偏小会让进度条在 pck 刚开始下载时就冲到 100% 然后长期卡住，
#    声明偏大则永远到不了 100%。export_web_to_docs.bat 会自动回填，
#    这个检查用于兜住"忘记同步"的情况。
# 2) 加载层 #status 必须盖在焦点提示 #click-to-focus 之上，否则资源下载期间
#    玩家看到的是"Click to Start"而不是下载进度。

const PORTAL_HTML_PATH := "res://docs/index.html"
const BUNDLE_FILES: Array[String] = ["index.pck", "index.wasm"]
const LOADER_SELECTOR := "#status"
const FOCUS_SELECTOR := "#click-to-focus"

var failures: Array[String] = []


func _ready() -> void:
	var html := _read_text(PORTAL_HTML_PATH)
	if html.is_empty():
		failures.append("web portal page is missing or unreadable: %s" % PORTAL_HTML_PATH)
		_finish()
		return

	_verify_bundle_sizes(html)
	_verify_overlay_order(html)
	_finish()


func _verify_bundle_sizes(html: String) -> void:
	for file_name in BUNDLE_FILES:
		var declared := _match_int(html, "\"%s\"\\s*:\\s*(\\d+)" % file_name.replace(".", "\\."))
		_expect(declared > 0, "index.html must declare a positive fileSizes entry for %s" % file_name)
		if declared <= 0:
			continue
		var bundle_path := "res://docs/%s" % file_name
		var bundle := FileAccess.open(bundle_path, FileAccess.READ)
		if bundle == null:
			failures.append("web bundle is missing: %s" % bundle_path)
			continue
		var real_size := bundle.get_length()
		bundle.close()
		_expect(
			declared == real_size,
			"%s: index.html declares %d bytes but the file is %d bytes" % [file_name, declared, real_size]
		)


func _verify_overlay_order(html: String) -> void:
	var loader_z := _match_int(html, "%s\\s*\\{[^}]*?z-index\\s*:\\s*(\\d+)" % LOADER_SELECTOR)
	var focus_z := _match_int(html, "%s\\s*\\{[^}]*?z-index\\s*:\\s*(\\d+)" % FOCUS_SELECTOR)
	_expect(loader_z > 0 and focus_z > 0, "portal CSS must declare a z-index for both the loader and the focus prompt")
	if loader_z <= 0 or focus_z <= 0:
		return
	_expect(
		loader_z > focus_z,
		"loading overlay (z-index %d) must sit above the focus prompt (z-index %d)" % [loader_z, focus_z]
	)


func _match_int(text: String, pattern: String) -> int:
	var regex := RegEx.new()
	if regex.compile(pattern) != OK:
		return -1
	var result := regex.search(text)
	if result == null:
		return -1
	var raw := result.get_string(1)
	if raw.is_empty():
		return -1
	return int(raw)


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _finish() -> void:
	if failures.is_empty():
		print("Web portal bundle regression passed.")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
