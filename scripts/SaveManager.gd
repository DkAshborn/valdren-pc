extends Node

const SAVE_FILE := "user://valdren_save.json"

func save_path() -> String:
    return ProjectSettings.globalize_path(SAVE_FILE)

func has_save() -> bool:
    return FileAccess.file_exists(SAVE_FILE)

func save_game() -> bool:
    if not GameState.has_game():
        return false
    var file := FileAccess.open(SAVE_FILE, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(GameState.state))
    return true

func load_game() -> bool:
    if not has_save():
        return false
    var file := FileAccess.open(SAVE_FILE, FileAccess.READ)
    var parsed = JSON.parse_string(file.get_as_text())
    if typeof(parsed) != TYPE_DICTIONARY:
        return false
    GameState.load_state(parsed)
    return true
