class_name RunUploader extends Node
## Sends finished run summaries to Supabase. Created by RunTracker.
## Nothing is created or sent until the player says yes on the consent screen (DataConsent).
## Every summary is written to disk first, then sent right away over HTTPS.
## The file is deleted once the server accepts it; anything that fails to send
## (no internet, game closed mid-request) is retried on the next launch and after each run.

const SUPABASE_URL: String = "https://wqcwdqncmphblvutohdn.supabase.co"
## Publishable key: safe to ship. It can only call submit_run, never read data.
const SUPABASE_KEY: String = "sb_publishable__eJbSDTrGjQIDN1baM-Daw_8wBUcYee"
const SUBMIT_PATH: String = "/rest/v1/rpc/submit_run"
const QUEUE_DIR: String = "user://run_queue"
const CONFIG_PATH: String = "user://analytics.cfg"
## Oldest queued runs are dropped past this, so an offline player's disk can't fill up.
const MAX_QUEUED: int = 50
const REQUEST_TIMEOUT: float = 15.0
## build_type for exported builds. Editor runs are always "dev". Switch to "public" for a public release.
const EXPORT_BUILD_TYPE: String = "tester"

const CONSENT_YES: String = "yes"
const CONSENT_NO: String = "no"

## Anonymous and random. Made only after the player agrees; cleared if they opt out.
var player_id: String = ""

## "" until the player answers the consent screen.
var _consent: String = ""

var _http: HTTPRequest
var _sending_path: String = ""

func _ready() -> void:
	# The death screen pauses the tree; uploads must keep going.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_http = HTTPRequest.new()
	_http.timeout = REQUEST_TIMEOUT
	add_child(_http)
	_http.request_completed.connect(_on_http_request_completed)
	DirAccess.make_dir_recursive_absolute(QUEUE_DIR)
	_load_config()
	_send_next()

## True until the player has answered the consent screen once.
func needs_consent() -> bool:
	return _consent.is_empty()

func has_consent() -> bool:
	return _consent == CONSENT_YES

## Yes makes a player ID and starts sending. No deletes the ID and any runs waiting to be sent.
func set_consent(accepted: bool) -> void:
	_consent = CONSENT_YES if accepted else CONSENT_NO
	if accepted:
		if player_id.is_empty():
			player_id = Crypto.new().generate_random_bytes(16).hex_encode()
	else:
		player_id = ""
		_clear_queue()
	_save_config()
	_send_next()

func build_type() -> String:
	return "dev" if OS.has_feature("editor") else EXPORT_BUILD_TYPE

## Queues a summary on disk and starts sending.
func submit(summary: Dictionary) -> void:
	if not has_consent():
		return
	var path: String = "%s/%s.json" % [QUEUE_DIR, summary.get("run_id", str(Time.get_ticks_usec()))]
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("RunUploader: could not write %s (%s)" % [path, FileAccess.get_open_error()])
		return
	file.store_string(JSON.stringify(summary))
	file.close()
	_trim_queue()
	_send_next()

# --- Sending ------------------------------------------------------------------------

func _send_next() -> void:
	if not has_consent() or not _sending_path.is_empty():
		return
	var queued: PackedStringArray = _queued_files()
	if queued.is_empty():
		return
	_sending_path = "%s/%s" % [QUEUE_DIR, queued[0]]
	var text: String = FileAccess.get_file_as_string(_sending_path)
	if not JSON.parse_string(text) is Dictionary:
		push_warning("RunUploader: dropping unreadable %s" % _sending_path)
		_finish_current(true)
		return
	# Sent as stored text: re-encoding a parsed copy would turn every int into a float ("2.0").
	var body: String = '{"payload":' + text + '}'
	var headers: PackedStringArray = [
		"apikey: " + SUPABASE_KEY,
		"Content-Type: application/json",
	]
	var err: Error = _http.request(SUPABASE_URL + SUBMIT_PATH, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		push_warning("RunUploader: request failed to start (%s)" % error_string(err))
		_sending_path = ""

func _on_http_request_completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		# Offline or timed out: keep the file for the next try.
		print("[RunUploader] offline, run kept for later (result %d)" % result)
		_sending_path = ""
		return
	if code >= 200 and code < 300:
		print("[RunUploader] run uploaded: ", body.get_string_from_utf8())
		_finish_current(true)
		return
	var message: String = body.get_string_from_utf8()
	# 4xx means the server will never accept this payload; retrying would loop forever.
	var permanent: bool = code >= 400 and code < 500 and code != 408 and code != 429
	push_warning("RunUploader: server returned %d: %s" % [code, message])
	_finish_current(permanent)

func _finish_current(delete_file: bool) -> void:
	if delete_file:
		DirAccess.remove_absolute(_sending_path)
		_sending_path = ""
		_send_next()
	else:
		_sending_path = ""

# --- Queue and config ---------------------------------------------------------------

func _queued_files() -> PackedStringArray:
	var files: PackedStringArray = []
	for file_name: String in DirAccess.get_files_at(QUEUE_DIR):
		if file_name.ends_with(".json"):
			files.append(file_name)
	return files

func _clear_queue() -> void:
	_http.cancel_request()
	_sending_path = ""
	for file_name: String in _queued_files():
		DirAccess.remove_absolute("%s/%s" % [QUEUE_DIR, file_name])

func _trim_queue() -> void:
	var files: PackedStringArray = _queued_files()
	if files.size() <= MAX_QUEUED:
		return
	var by_age: Array[String] = []
	for file_name: String in files:
		by_age.append(file_name)
	by_age.sort_custom(func(a: String, b: String) -> bool:
		return FileAccess.get_modified_time("%s/%s" % [QUEUE_DIR, a]) < FileAccess.get_modified_time("%s/%s" % [QUEUE_DIR, b]))
	for i: int in by_age.size() - MAX_QUEUED:
		DirAccess.remove_absolute("%s/%s" % [QUEUE_DIR, by_age[i]])

func _load_config() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.load(CONFIG_PATH)
	_consent = str(config.get_value("analytics", "consent", ""))
	# Older builds made an ID without asking. Only keep it once the player has said yes.
	player_id = str(config.get_value("analytics", "player_id", "")) if has_consent() else ""
	if _consent == CONSENT_NO:
		_clear_queue()

func _save_config() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("analytics", "consent", _consent)
	if has_consent():
		config.set_value("analytics", "player_id", player_id)
	config.save(CONFIG_PATH)
