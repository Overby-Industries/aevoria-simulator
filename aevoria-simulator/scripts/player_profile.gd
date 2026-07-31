extends Node

## Cross-scene player identity: the ship name a player picks in the
## Assembly Bay and the account-wide badge their purchase history earns
## them, both free-to-set/free-to-see so a non-paying player is never
## locked out of personalizing their ship or profile -- only the badge
## text itself depends on having bought something. Autoloaded (like
## AevoriaAuth/LevelContext) so assembly_bay.gd, situation_table.gd, and
## account_panel.gd can all read the same values without wiring signals
## through every scene transition.
##
## "Paid"/"Founder" aren't real account fields anywhere server-side (see
## aevoria_auth.gd) -- both panels that already call
## AevoriaAuth.fetch_owned_skins() for their own reasons (assembly_bay.gd's
## skin picker, account_panel.gd's "MY SKINS" list) feed the same purchases
## array here via update_from_purchases(), so this stays in sync for free
## without a new network round-trip of its own.

const FOUNDING_CITIZEN_PRODUCT = 'The "Founding Citizen" Commemorative Bundle'
const PROFILE_PATH = "user://player_profile.json"
const DEFAULT_SHIP_NAME = "MyShip"

signal badges_updated

var is_paid: bool = false
var is_founder: bool = false
var active_ship_name: String = DEFAULT_SHIP_NAME

func _ready():
	_load()

func update_from_purchases(purchases: Array) -> void:
	var was_founder = is_founder
	var was_paid = is_paid
	is_paid = not purchases.is_empty()
	is_founder = purchases.any(func(p): return p.get("product_name") == FOUNDING_CITIZEN_PRODUCT)
	if is_paid != was_paid or is_founder != was_founder:
		badges_updated.emit()

## " ★ FOUNDER" / " ✦ PATRON" / "" -- ready to append straight onto a ship
## name or account email label. Founder implies paid (the bundle is a
## purchase) so only the stronger badge shows, never both.
func badge_suffix() -> String:
	if is_founder:
		return " ★ FOUNDER"
	if is_paid:
		return " ✦ PATRON"
	return ""

func set_active_ship_name(ship_name: String) -> void:
	var trimmed = ship_name.strip_edges()
	active_ship_name = trimmed if not trimmed.is_empty() else DEFAULT_SHIP_NAME
	_save()

func _load() -> void:
	if not FileAccess.file_exists(PROFILE_PATH):
		return
	var file = FileAccess.open(PROFILE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if data is Dictionary and typeof(data.get("active_ship_name")) == TYPE_STRING:
		active_ship_name = data["active_ship_name"]

func _save() -> void:
	var file = FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"active_ship_name": active_ship_name}))
	file.close()
