extends Node

var data: Dictionary = {}

func _ready() -> void:
    var path := "res://data/valdren_data.json"
    if not FileAccess.file_exists(path):
        push_error("Banco de dados de Valdren não encontrado: " + path)
        return
    var file := FileAccess.open(path, FileAccess.READ)
    var parsed = JSON.parse_string(file.get_as_text())
    if typeof(parsed) != TYPE_DICTIONARY:
        push_error("valdren_data.json inválido")
        return
    data = parsed

func section(name: String) -> Dictionary:
    return data.get(name, {})

func locations() -> Dictionary:
    return section("locations")

func location(id: String) -> Dictionary:
    return locations().get(id, {})

func npcs() -> Dictionary:
    return section("npcs")

func npc(id: String) -> Dictionary:
    return npcs().get(id, {})

func items() -> Dictionary:
    return section("items")

func item(id: String) -> Dictionary:
    return items().get(id, {})
