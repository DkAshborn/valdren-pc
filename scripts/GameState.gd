extends Node

signal changed
signal page_changed(page_id: String)

var state: Dictionary = {}
var current_page := "map"

func _ready() -> void:
    reset_to_menu()

func reset_to_menu() -> void:
    state = {}
    current_page = "menu"
    changed.emit()

func has_game() -> bool:
    return not state.is_empty() and state.has("name")

func new_game(character: Dictionary) -> void:
    var attrs: Dictionary = character.get("attrs", {})
    state = {
        "save_version": 1,
        "name": character.get("name", "Aventureiro"),
        "age": int(character.get("age", 18)),
        "sex": character.get("sex", "masculino"),
        "appearance": character.get("appearance", ""),
        "origin": character.get("origin", "livre"),
        "attrs": {
            "forca": int(attrs.get("forca", 3)),
            "destreza": int(attrs.get("destreza", 3)),
            "agilidade": int(attrs.get("agilidade", 3)),
            "resistencia": int(attrs.get("resistencia", 3)),
            "intelecto": int(attrs.get("intelecto", 3)),
            "carisma": int(attrs.get("carisma", 3))
        },
        "level": 1,
        "xp": 0,
        "gold": 140,
        "reputation": 0,
        "time": 480,
        "location": "praca",
        "hp": 100,
        "hp_max": 100,
        "stamina": 100,
        "stamina_max": 100,
        "mana": 50,
        "mana_max": 50,
        "fome": 0,
        "sede": 0,
        "sujeira": 0,
        "guild": false,
        "rank": 0,
        "inventory": {},
        "equipment": {},
        "quests": {},
        "relations": {},
        "flags": {},
        "known_locations": {"praca": true, "mercado": true, "taverna": true, "guilda": true, "forja": true, "treino": true, "alquimia": true, "costura": true},
        "journal": ["Você chegou a Valdren."]
    }
    current_page = "map"
    changed.emit()

func load_state(loaded: Dictionary) -> void:
    state = loaded.duplicate(true)
    current_page = "map"
    changed.emit()

func set_page(page_id: String) -> void:
    current_page = page_id
    page_changed.emit(page_id)
    changed.emit()

func travel(location_id: String) -> void:
    if not has_game():
        return
    if not GameData.locations().has(location_id):
        return
    state.location = location_id
    state.time = int(state.get("time", 480)) + 20
    var log: Array = state.get("journal", [])
    log.push_front("Você viajou para %s." % GameData.location(location_id).get("name", location_id))
    if log.size() > 60:
        log.resize(60)
    state.journal = log
    current_page = "local"
    changed.emit()

func clock_text() -> String:
    var total := int(state.get("time", 480))
    var day := int(total / 1440) + 1
    var minutes := total % 1440
    var hour := int(minutes / 60)
    var minute := minutes % 60
    return "Dia %d · %02d:%02d" % [day, hour, minute]

func money_text() -> String:
    var copper := int(state.get("gold", 0))
    if copper < 100:
        return "%d cobres" % copper
    var silver := int(copper / 100)
    var rest := copper % 100
    return "%d prata %d cobres" % [silver, rest] if rest > 0 else "%d prata" % silver
