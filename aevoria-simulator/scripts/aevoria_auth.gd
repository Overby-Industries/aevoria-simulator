extends Node

## Bridges the Godot client to the same Supabase project the web app uses --
## no custom backend needed. Supabase's own REST Auth API handles
## login/refresh directly, and PostgREST + RLS (the exact same policies the
## web app already relies on -- see web/supabase/migrations/0001_init.sql)
## scope entitlement queries to the logged-in player automatically.
##
## SUPABASE_URL/ANON_KEY are the same public-safe values already shipped in
## the web app's client-side bundle -- protected by RLS, not secrecy, same
## security model as any other Supabase client (web, mobile, or this).
##
## Debug builds (editor play, template_debug) default to the dev/test
## Supabase project -- same one the web app's Preview deployments use --
## so local testing never touches real player accounts or live purchases.
## The itch.io release build is always template_release, never a debug
## build, so players always get production with no flag needed. Pass
## "--prod-backend" to a debug build to force production instead (e.g. to
## reproduce a live-only bug) without doing a full release export.
##
## This is also the seam any future community-voting/multiplayer feature
## would build on -- SUPABASE_URL/access_token + the same HTTPRequest+signal
## pattern fetch_owned_skins() below uses. See docs/MULTIPLAYER_ROADMAP.md.

const PROD_SUPABASE_URL = "https://hpskqefglvjmdegkptfl.supabase.co"
const PROD_SUPABASE_ANON_KEY = "sb_publishable_axQ9YhS3uCmq8oJw0-jbnw_I0G3B3ai"
const DEV_SUPABASE_URL = "https://beacfrhrumsegqtxkqlr.supabase.co"
const DEV_SUPABASE_ANON_KEY = "sb_publishable_NIKvNVr0cy8ymdHT9nOk9A_AkNZZj9s"

var SUPABASE_URL: String
var SUPABASE_ANON_KEY: String
var SESSION_PATH: String

signal login_succeeded(user_info: Dictionary)
signal login_failed(message: String)
signal logged_out
signal skins_fetched(skins: Array)
signal skins_fetch_failed(message: String)

var access_token: String = ""
var refresh_token: String = ""
var user_id: String = ""
var user_email: String = ""

var _login_request: HTTPRequest
var _refresh_request: HTTPRequest
var _skins_request: HTTPRequest

func _ready():
	_resolve_backend()

	_login_request = HTTPRequest.new()
	add_child(_login_request)
	_login_request.request_completed.connect(_on_login_response)

	_refresh_request = HTTPRequest.new()
	add_child(_refresh_request)
	_refresh_request.request_completed.connect(_on_refresh_response)

	_skins_request = HTTPRequest.new()
	add_child(_skins_request)
	_skins_request.request_completed.connect(_on_skins_response)

	_load_session()

func _resolve_backend():
	var use_prod = not OS.is_debug_build() or "--prod-backend" in OS.get_cmdline_args()
	if use_prod:
		SUPABASE_URL = PROD_SUPABASE_URL
		SUPABASE_ANON_KEY = PROD_SUPABASE_ANON_KEY
		SESSION_PATH = "user://session.cfg"
	else:
		SUPABASE_URL = DEV_SUPABASE_URL
		SUPABASE_ANON_KEY = DEV_SUPABASE_ANON_KEY
		# Separate session file so a dev-project login (a different
		# auth.users table entirely) never collides with a saved
		# production session on the same machine.
		SESSION_PATH = "user://session_dev.cfg"

func is_logged_in() -> bool:
	return access_token != ""

# --- login -----------------------------------------------------------------

func login(email: String, password: String):
	var url = "%s/auth/v1/token?grant_type=password" % SUPABASE_URL
	var headers = [
		"apikey: %s" % SUPABASE_ANON_KEY,
		"Content-Type: application/json",
	]
	var body = JSON.stringify({"email": email, "password": password})
	var err = _login_request.request(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		login_failed.emit("Could not start login request (error %d)." % err)

func _on_login_response(_result, response_code, _headers, body):
	var text = body.get_string_from_utf8()
	var data = JSON.parse_string(text)
	if response_code != 200 or data == null:
		var message = "Login failed."
		if data is Dictionary and data.has("error_description"):
			message = data["error_description"]
		elif data is Dictionary and data.has("msg"):
			message = data["msg"]
		SystemLog.log("Login failed: %s" % message)
		login_failed.emit(message)
		return

	access_token = data.get("access_token", "")
	refresh_token = data.get("refresh_token", "")
	var user = data.get("user", {})
	user_id = user.get("id", "")
	user_email = user.get("email", "")
	_save_session()
	SystemLog.log("Authenticated as %s." % user_email)
	login_succeeded.emit({"id": user_id, "email": user_email})

# --- session persistence + silent refresh -----------------------------------

func _save_session():
	var cfg = ConfigFile.new()
	cfg.set_value("session", "refresh_token", refresh_token)
	cfg.set_value("session", "user_id", user_id)
	cfg.set_value("session", "user_email", user_email)
	cfg.save(SESSION_PATH)

func _load_session():
	var cfg = ConfigFile.new()
	if cfg.load(SESSION_PATH) != OK:
		return
	var saved_refresh = cfg.get_value("session", "refresh_token", "")
	if saved_refresh == "":
		return
	refresh_token = saved_refresh
	user_id = cfg.get_value("session", "user_id", "")
	user_email = cfg.get_value("session", "user_email", "")
	_refresh_now()

func _refresh_now():
	var url = "%s/auth/v1/token?grant_type=refresh_token" % SUPABASE_URL
	var headers = [
		"apikey: %s" % SUPABASE_ANON_KEY,
		"Content-Type: application/json",
	]
	var body = JSON.stringify({"refresh_token": refresh_token})
	_refresh_request.request(url, headers, HTTPClient.METHOD_POST, body)

func _on_refresh_response(_result, response_code, _headers, body):
	var text = body.get_string_from_utf8()
	var data = JSON.parse_string(text)
	if response_code != 200 or data == null:
		# Stored refresh token is stale/invalid -- clear it so we don't keep
		# retrying every launch; the player just logs in again.
		access_token = ""
		refresh_token = ""
		_clear_session_file()
		return

	access_token = data.get("access_token", "")
	refresh_token = data.get("refresh_token", refresh_token)
	var user = data.get("user", {})
	if user.has("id"):
		user_id = user.get("id", "")
	if user.has("email"):
		user_email = user.get("email", "")
	_save_session()
	SystemLog.log("Session restored for %s." % user_email)
	login_succeeded.emit({"id": user_id, "email": user_email})

func logout():
	SystemLog.log("Logged out.")
	access_token = ""
	refresh_token = ""
	user_id = ""
	user_email = ""
	_clear_session_file()
	logged_out.emit()

func _clear_session_file():
	if FileAccess.file_exists(SESSION_PATH):
		DirAccess.remove_absolute(SESSION_PATH)

# --- entitlements ------------------------------------------------------------

func fetch_owned_skins():
	if not is_logged_in():
		skins_fetch_failed.emit("Not logged in.")
		return
	# RLS on `purchases` ("Buyers can view their own purchases") already
	# scopes this to the caller -- no manual buyer_id filter needed, same as
	# the web app never needs one either.
	var url = "%s/rest/v1/purchases?select=amount_cents,created_at,product_name,skins(id,title,description,recipe,preview_image_path,storage_path)" % SUPABASE_URL
	var headers = [
		"apikey: %s" % SUPABASE_ANON_KEY,
		"Authorization: Bearer %s" % access_token,
	]
	var err = _skins_request.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		skins_fetch_failed.emit("Could not start skins request (error %d)." % err)

func _on_skins_response(_result, response_code, _headers, body):
	var text = body.get_string_from_utf8()
	var data = JSON.parse_string(text)
	if response_code != 200 or not (data is Array):
		SystemLog.log("Could not load owned items from the Commonwealth account.")
		skins_fetch_failed.emit("Could not load owned skins.")
		return
	SystemLog.log("Loaded %d owned item(s)." % data.size())
	skins_fetched.emit(data)
