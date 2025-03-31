extends Node2D

# Obtenemos la escena que contiene nuestro player generico
@export var player_scene: PackedScene

@onready var markers = $Markers
@onready var players: Node2D = $Players

func _ready() -> void:
	# Instanciamos a nuestros players y los hacemos hijos del nodo Players
	# Game.players es un autoload que contiene elementos de clase PlayerData
	# que representan a los jugadores conectados (incluyendo al server)
	
	#for player in Game.players:
	#	var player_inst = player_scene.instantiate()
	#	players.add_child(player_inst)
	#	player_inst.setup(player)
	
	for i in Game.players.size():
		var player = Game.players[i]
		var player_inst = player_scene.instantiate()
		players.add_child(player_inst)
		player_inst.setup(player)
		player_inst.global_position = markers.get_child(i).global_position
