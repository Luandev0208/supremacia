class_name TerritoryData
extends RefCounted

var id: String
var display_name: String
var continent_id: String
var neighbor_ids: Array[String]
var owner_id: int = -1
var armies: int = 1

func _init(territory_id: String, territory_name: String, continent: String, neighbors: Array[String]) -> void:
	id = territory_id
	display_name = territory_name
	continent_id = continent
	neighbor_ids = neighbors

func is_neighbor_of(other_id: String) -> bool:
	return other_id in neighbor_ids
