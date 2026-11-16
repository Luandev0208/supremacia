class_name PlayerData
extends RefCounted

var id: int
var display_name: String
var color: Color
var reserve_armies: int = 0

func _init(player_id: int, player_name: String, player_color: Color) -> void:
	id = player_id
	display_name = player_name
	color = player_color
