extends Sprite2D

@export var max_speed = 400

@onready var label: Label = $Label

# Al instanciar los jugadores en main vamos a llamar a este metodo setup, y vamos a recibir un objeto de 
# clase playerData con la informacion de nuestro jugador

func setup(player_data: Statics.PlayerData):
	# Notar que como dependemos de label, label debe haberse inicializado antes de lanzar el metodo
	# setup. Para ello simplemente hay que asegurarnos de instanciar antes de llamar a setup
	label.text = player_data.name
	
	# Para RPC necesitamos que los nombres de los nodos sean unicos (Asi se identifica el mismo nodo entre
	# diferentes instancias de juego (peers)
	name = str(player_data.id) 
	
	self_modulate = Color.RED if player_data.role == Statics.Role.ROLE_A else Color.BLUE
	
	# Seteamos la autoridad de la instancia de cliente o server (peer), sobre este jugador (nodo).
	# player_data.id es el id de la instancia de godot a la que se le asigna la autoridad
	# de este nodo. (1 es el server). 
	
	# Estamos diciendo que este nodo le pertenece a la instancia de godot con ese id, y cualquier 
	# aparicion del mismo nodo en otras instancias es "simulada" c/r a la que si tiene autoridad.
	set_multiplayer_authority(player_data.id)

func _input(event:InputEvent) -> void:
	# Para inputs relacionados a movimiento y fisicas, preferir _physics_process y usar Input.accion
	
	if is_multiplayer_authority():
		if event.is_action_pressed("test"):
			# Solo la instancia de server/cliente con autoridad sobre el personaje (nodo) va a reaccionar al
			# input (en esta instancia de godot (peer)). Si no, ambos nodos actuarian sobre el mismo input.
			
			# al llamar al metodo con rpc hacemos que se envie una request mediante rpc, en vez de 
			# simplemente llamar al metodo. Si hacemos un llamado rpc general de este modo, el llamado
			# se envia a todas las instancias simuladas del nodo o peers de juego conectados.
			test.rpc()
			
			# Tambien se puede hacer un llamado rpc a una instancia de godot/juego especifica mediante
			# su id (En este caso enviamos al server, con id 1). El llamado solo se hace sobre esa instancia 
			# de juego (peer).
			test.rpc_id(1)
			
			# Si hacemos un llamado rpc_id sobre el mismo peer (nodo en un peer se llama a si mismo con rpc), 
			# asegurarse que rpc este configurado con call_local, si no no va a pasar nada.

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		var move_input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		# Equivalente a get_axis pero para dos ejes
		
		position += max_speed * move_input * delta
		sync_pos.rpc(position)

##############################################################################################################

# Configuramos el siguiente metodo/funcion para realizar/recibir llamados rpc
# hay distintas flags para configurar el comportamiento

# authority: solo puede ser llamado por instancia con autoridad.
# any_peer: Puede ser llamado tanto por instancias con o sin autoridad

# call_remote: Solo se va a ejecutar metodo sobre nodo equivalente en instancias que no correspondan
# a la instancia desde la que se llama (mismo id). Es decir, se va a ejecutar para todas las instancias simuladas 
# de un mismo nodo en otros peers (cliente o server), pero no para si mismo.

# call_local: lo mismo que call_remote, pero tambien se ejecuta para si mismo (Para la misma id de instancia)

# unreliable: No se asegura que no se pierdan llamados al enviarse por la red. (Mas rapido)
# reliable: Se asegura la llegada en orden y de forma confiable de los llamados en red (mas lento)
# channel: permite establecer canales diferentes por los que enviar los llamados

@rpc("authority", "call_local")
func test():
	Debug.log("Test %s" % [label.text], 10)

@rpc("authority", "call_remote", "unreliable_ordered")
func sync_pos(pos: Vector2) -> void:
	# position = pos (Puede no ser buena idea simplemente setear lo que se recibe, se puede perder algun paquete)
	# asi hacemos que movimiento no se vea tan cortado o lageado si hay problemas
	
	# Suele ser mejor hacer una interpolacion
	position = lerp(position, pos, 0.5)
