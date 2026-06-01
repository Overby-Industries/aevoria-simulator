extends Node

var multiplayer = MultiplayerAPI.new()
var is_host = false
var peers = []

func _ready():
    add_child(multiplayer)
    multiplayer.connect("multiplayer_connected", self, "_on_peer_connected")
    multiplayer.connect("multiplayer_disconnected", self, "_on_peer_disconnected")

    if is_host:
        multiplayer.create_server(1234)  # Host on port 1234
    else:
        # In a real game, you'd get the host IP from a matchmaking server
        multiplayer.connect_to_server("127.0.0.1", 1234)

func _on_peer_connected(peer_id):
    peers.append(peer_id)
    print("Peer connected: ", peer_id)

func _on_peer_disconnected(peer_id):
    peers.erase(peer_id)
    print("Peer disconnected: ", peer_id)

func _process(delta):
    multiplayer.poll()