tool
extends VoxelWorldDefault

# Copyright Péter Magyar relintai@gmail.com
# MIT License, might be merged into the Voxelman engine module

# Copyright (c) 2019-2020 Péter Magyar

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

export(Array, MeshDataResource) var meshes : Array

export(bool) var editor_generate : bool = false setget set_editor_generate, get_editor_generate
export(bool) var show_loading_screen : bool = true
export(bool) var generate_on_ready : bool = false

var initial_generation : bool = true

var spawned : bool = false

var _editor_generate : bool

var _player_file_name : String
var _player : Entity

const VIS_UPDATE_INTERVAL = 5
var vis_update : float = 0
var _max_frame_chunk_build_temp : int

func _enter_tree():
	if generate_on_ready and not Engine.is_editor_hint():
		
		if level_generator != null:
			level_generator.setup(self, 80, false, library)
		
		spawn()
		
func _process(delta):
	if initial_generation:
		return
	
	if _player == null:
		set_process(false)
		return
		
	vis_update += delta
	
	if vis_update >= VIS_UPDATE_INTERVAL:
		vis_update = 0
		
		var ppos : Vector3 = _player.get_transform_3d().origin
		
		var cpos : Vector3 = ppos
		var ppx : int = int(cpos.x / (chunk_size_x * voxel_scale))
		var ppy : int = int(cpos.y / (chunk_size_y * voxel_scale))
		var ppz : int = int(cpos.z / (chunk_size_z * voxel_scale))

		cpos.x = ppx
		cpos.y = ppy
		cpos.z = ppz
		
		var count : int = get_chunk_count()
		var i : int = 0
		while i < count:
			var c : VoxelChunk = get_chunk_index(i)
			
			var l : float = (Vector2(cpos.x, cpos.z) - Vector2(c.position_x, c.position_z)).length()
			
			if l > chunk_spawn_range + 2:
#				print("despawn " + str(Vector3(c.position_x, c.position_y, c.position_z)))
				remove_chunk_index(i)
				i -= 1
				count -= 1
#			else:
#				var dx : int = abs(ppx - c.position_x)
#				var dy : int = abs(ppy - c.position_y)
#				var dz : int = abs(ppz - c.position_z)
#
#				var mr : int = max(max(dx, dy), dz)
#
#				if mr <= 1:
#					c.current_lod_level = 0
#				elif mr == 2:
#					c.current_lod_level = 1
#				elif mr == 3:# or mr == 4:
#					c.current_lod_level = 2
#				else:
#					c.current_lod_level = 3

			i += 1
			
		for x in range(-chunk_spawn_range + int(cpos.x), chunk_spawn_range + int(cpos.x)):
			for z in range(-chunk_spawn_range + int(cpos.z), chunk_spawn_range + int(cpos.z)):
				for y in range(-1, 2):
					if not has_chunk(x, y, z):
#						print("spawn " + str(Vector3(x, y, z)))
						create_chunk(x, y, z)

#func _process(delta : float) -> void:
#	if not generation_queue.empty():
#		var chunk : VoxelChunk = generation_queue.front()

#		refresh_chunk_lod_level_data(chunk)

#		level_generator.generate_chunk(chunk)

#		generation_queue.remove(0)
#
#		if generation_queue.empty():
#			emit_signal("generation_finished")
#			initial_generation = false
#
#			if show_loading_screen and not Engine.editor_hint:
#				get_node("..").hide_loading_screen()

func _generation_finished():
	if not Engine.editor_hint:
		max_frame_chunk_build_steps = _max_frame_chunk_build_temp
	
	initial_generation = false
	
#	for i in range(get_chunk_count()):
#		get_chunk_index(i).draw_debug_voxels(555555)
			
	if show_loading_screen and not Engine.editor_hint:
		get_node("..").hide_loading_screen()
		
	#TODO hack, do this properly
	if _player:
		_player.set_physics_process(true)

func get_chunk_lod_level(x : int, y : int, z : int, default : int) -> int:
#	var key : String = str(x) + "," + str(y) + "," + str(z)
	
	var ch : VoxelChunk = get_chunk(x, y, z)
	
	if ch == null:
		return default
	
	return ch.lod_size

func _create_chunk(x : int, y : int, z : int, pchunk : VoxelChunk) -> VoxelChunk:
	var chunk : VoxelChunk = TVVoxelChunk.new()
	
	#chunk.meshing_create_collider = false
	
	chunk.lod_size = 1
#	print("added " + str(Vector3(x, y, z)))
	return ._create_chunk(x, y, z, chunk)
	
func spawn() -> void:
	if not Engine.editor_hint:
		_max_frame_chunk_build_temp = max_frame_chunk_build_steps
		max_frame_chunk_build_steps = 0
	
	for x in range(-chunk_spawn_range, chunk_spawn_range):
		for z in range(-chunk_spawn_range, chunk_spawn_range):
			for y in range(-1, 2):
				create_chunk(x, y, z)

	set_process(true)
	
	
func get_editor_generate() -> bool:
	return _editor_generate
	
func set_editor_generate(value : bool) -> void:
	if value:
		library.refresh_rects()
		
		level_generator.setup(self, current_seed, false, library)
		spawn()
#	else:
#		spawned = false
#		clear()
		
	_editor_generate = value
	
func create_light(x : int, y : int, z : int, size : int, color : Color) -> void:
	var chunkx : int = int(x / chunk_size_x)
	var chunky : int = int(y / chunk_size_y)
	var chunkz : int = int(z / chunk_size_z)
	
	var light : VoxelLight = VoxelLight.new()
	light.color = color
	light.size = size
	light.set_world_position(x, y, z)
	
	add_light(light)

				
func setup_client_seed(pseed : int) -> void:
#	_player_file_name = ""
#	_player = null
	
	Server.sset_seed(pseed)
	
	if level_generator != null:
		level_generator.setup(self, pseed, false, library)
	
	spawn()

func load_character(file_name : String) -> void:
	_player_file_name = file_name
	_player = ESS.entity_spawner.load_player(file_name, Vector3(5, 30, 5), 1) as Entity
	#TODO hack, do this properly
	_player.set_physics_process(false)
	
	set_player(_player.get_body())

	Server.sset_seed(_player.sseed)
	
	if level_generator != null:
		level_generator.setup(self, _player.sseed, true, library)
	
	spawn()
	
	set_process(true)
	
func needs_loading_screen() -> bool:
	return show_loading_screen

func save() -> void:
	if _player == null or _player_file_name == "":
		return

	ESS.entity_spawner.save_player(_player, _player_file_name)
