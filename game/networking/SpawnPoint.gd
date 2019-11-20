extends Spatial

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

export (bool) var use_gui : bool = false
export (bool) var multi_player : bool = false
export (NodePath) var gui_path : NodePath
export (NodePath) var host_button_path : NodePath

export (NodePath) var address_line_edit_path : NodePath
export (NodePath) var port_line_edit_path : NodePath

export (NodePath) var connect_button_path : NodePath
export (NodePath) var naturalist_button_path : NodePath

export (NodePath) var terrarin_path : NodePath

var gui : Node
var host_button : Button
var address_line_edit : LineEdit
var port_line_edit : LineEdit
var connect_button : Button
var naturalist_button : Button

var player : Entity
var terrarin : VoxelWorld

var spawned : bool = false

var player_master : PlayerMaster

func _ready():
	gui = get_node(gui_path)
	host_button = get_node(host_button_path)
	host_button.connect("pressed", self, "_on_host_button_clicked")
	
	address_line_edit = get_node(address_line_edit_path)
	port_line_edit = get_node(port_line_edit_path)
	
	connect_button = get_node(connect_button_path)
	connect_button.connect("pressed", self, "_on_client_button_clicked")
	
	naturalist_button = get_node(naturalist_button_path)
	naturalist_button.connect("pressed", self, "_on_client_naturalist_button_clicked")
	
	terrarin = get_node(terrarin_path) as VoxelWorld
	
	Server.connect("cplayer_master_created", self, "_cplayer_master_created")
	
	if not multi_player:
		set_process(true)
	else:
		set_process(false)
		
		if use_gui:
			gui.visible = true
	
func _process(delta):
	set_process(false)
	
	spawn()
	
func spawn():
	if not spawned:
		spawned = true
		
		if get_tree().network_peer == null:
			player = Entities.spawn_player(1, Vector3(10, 20, 10), "Player", "1", 1)
			call_deferred("set_terrarin_player")
#
#		Entities.spawn_mob(1, 50, Vector3(20, 6, 20))
#		Entities.spawn_mob(1, 50, Vector3(54, 6, 22))
#		Entities.spawn_mob(1, 50, Vector3(76, 6, 54))

func set_terrarin_player():
	terrarin.set_player(player as Spatial)

func _on_host_button_clicked():
	get_tree().connect("network_peer_connected", self, "_network_peer_connected")
	get_tree().connect("network_peer_disconnected", self, "_network_peer_disconnected")
	
	Server.start_hosting()
	
	spawn()
	
func _on_client_button_clicked():
	
	var addr : String = "127.0.0.1" if address_line_edit.text == "" else address_line_edit.text
	var port : int = 0 if port_line_edit.text == "" else int(port_line_edit.text)

	Server.connect_to_server(addr, port)
	
	

func _network_peer_connected(id : int):
	print(id)
	
func _network_peer_disconnected(id : int):
	print(id)
	
func _cplayer_master_created(pplayer_master):
	player_master = pplayer_master as PlayerMaster
	
func _on_client_naturalist_button_clicked():
	#Network.is
	#set_class
	
	gui.visible = false
	
	if get_tree().network_peer != null:
		Server.set_class()
	else:
		spawn()
		
		
		
