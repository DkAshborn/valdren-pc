extends Control

const BG = Color("#0b1211")
const PANEL = Color("#15221f")
const TEXT = Color("#e8eeeb")
const MUTED = Color("#9fafaa")
const GOLD = Color("#d7bd78")

var page := "menu"
var name_edit: LineEdit
var points := {"forca":3,"destreza":3,"agilidade":3,"resistencia":3,"intelecto":3,"carisma":3}
var point_labels := {}

func _ready() -> void:
    GameState.changed.connect(_draw_ui)
    _draw_ui()

func clear_ui() -> void:
    for c in get_children():
        c.queue_free()

func label(text:String, size:int=16, color:Color=TEXT) -> Label:
    var l=Label.new()
    l.text=text
    l.add_theme_font_size_override("font_size",size)
    l.add_theme_color_override("font_color",color)
    l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    return l

func button(text:String, action:Callable) -> Button:
    var b=Button.new()
    b.text=text
    b.custom_minimum_size=Vector2(0,44)
    b.pressed.connect(action)
    return b

func base_screen() -> VBoxContainer:
    clear_ui()
    var bg=ColorRect.new()
    bg.color=BG
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    var margin=MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left",50)
    margin.add_theme_constant_override("margin_right",50)
    margin.add_theme_constant_override("margin_top",35)
    margin.add_theme_constant_override("margin_bottom",35)
    add_child(margin)
    var scroll=ScrollContainer.new()
    margin.add_child(scroll)
    var v=VBoxContainer.new()
    v.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    v.add_theme_constant_override("separation",12)
    scroll.add_child(v)
    return v

func _draw_ui() -> void:
    if not GameState.has_game():
        show_menu()
        return
    match page:
        "map": show_map()
        "character": show_character()
        "inventory": show_inventory()
        "journal": show_journal()
        _: show_map()

func show_menu() -> void:
    page="menu"
    var v=base_screen()
    var title=label("VALDREN",52,GOLD)
    title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    v.add_child(title)
    var sub=label("Versão nativa para Windows em Godot",18,MUTED)
    sub.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    v.add_child(sub)
    v.add_child(HSeparator.new())
    v.add_child(button("Novo jogo",show_creation))
    var cont=button("Continuar",load_game)
    cont.disabled=not SaveManager.has_save()
    v.add_child(cont)
    v.add_child(label("Esta é a primeira build nativa. Os sistemas do jogo web serão migrados por etapas.",14,MUTED))

func show_creation() -> void:
    var v=base_screen()
    v.add_child(label("CRIAR PERSONAGEM",34,GOLD))
    name_edit=LineEdit.new()
    name_edit.placeholder_text="Nome do personagem"
    name_edit.text="Ashborn"
    v.add_child(name_edit)
    v.add_child(label("Distribua 6 pontos:",16))
    for key in points.keys():
        var row=HBoxContainer.new()
        var n=label(attr_name(key),16)
        n.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        row.add_child(n)
        row.add_child(button("-",change_point.bind(key,-1)))
        var value=label(str(points[key]),18,GOLD)
        value.custom_minimum_size=Vector2(50,44)
        value.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
        value.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
        point_labels[key]=value
        row.add_child(value)
        row.add_child(button("+",change_point.bind(key,1)))
        v.add_child(row)
    v.add_child(button("Entrar em Valdren",create_game))
    v.add_child(button("Voltar",show_menu))

func attr_name(k:String) -> String:
    return {"forca":"Força","destreza":"Destreza","agilidade":"Agilidade","resistencia":"Resistência","intelecto":"Intelecto","carisma":"Carisma"}.get(k,k)

func used_points() -> int:
    var n=0
    for x in points.values():
        n += int(x)-3
    return n

func change_point(key:String, delta:int) -> void:
    if delta>0 and used_points()>=6:
        return
    if delta<0 and int(points[key])<=3:
        return
    points[key]=int(points[key])+delta
    point_labels[key].text=str(points[key])

func create_game() -> void:
    if used_points()!=6:
        return
    GameState.new_game({"name":name_edit.text.strip_edges(),"attrs":points.duplicate(true)})
    SaveManager.save_game()
    page="map"
    _draw_ui()

func nav(v:VBoxContainer) -> void:
    var row=HBoxContainer.new()
    v.add_child(row)
    row.add_child(button("Mapa",go.bind("map")))
    row.add_child(button("Personagem",go.bind("character")))
    row.add_child(button("Inventário",go.bind("inventory")))
    row.add_child(button("Diário",go.bind("journal")))
    row.add_child(button("Salvar",save_game))
    row.add_child(button("Menu",GameState.reset_to_menu))
    v.add_child(HSeparator.new())

func go(p:String) -> void:
    page=p
    _draw_ui()

func header(v:VBoxContainer,title:String,desc:String="") -> void:
    nav(v)
    v.add_child(label(title,32,GOLD))
    if not desc.is_empty():
        v.add_child(label(desc,15,MUTED))
    v.add_child(label("%s  |  %s" % [GameState.clock_text(),GameState.money_text()],14,MUTED))

func show_map() -> void:
    page="map"
    var v=base_screen()
    header(v,"Mapa de Valdren","Escolha um local para viajar.")
    for id in GameData.locations().keys():
        var loc:Dictionary=GameData.location(id)
        var b=button("%s  ·  %s" % [loc.get("name",id),loc.get("zone","Valdren")],travel.bind(str(id)))
        v.add_child(b)

func travel(id:String) -> void:
    GameState.travel(id)
    show_location()

func show_location() -> void:
    var v=base_screen()
    var loc=GameData.location(str(GameState.state.location))
    header(v,str(loc.get("name","Valdren")),str(loc.get("desc","")))
    var npcs:Array=loc.get("npcs",[])
    if not npcs.is_empty():
        v.add_child(label("Pessoas aqui",20,GOLD))
        for npc_id in npcs:
            var n=GameData.npc(str(npc_id))
            v.add_child(label("• %s · %s" % [n.get("name",npc_id),n.get("role","NPC")],15))
    v.add_child(button("Voltar ao mapa",go.bind("map")))

func show_character() -> void:
    page="character"
    var v=base_screen()
    header(v,str(GameState.state.name),"Nível %d" % int(GameState.state.level))
    for k in GameState.state.attrs.keys():
        v.add_child(label("%s: %d" % [attr_name(k),int(GameState.state.attrs[k])],17))
    v.add_child(HSeparator.new())
    v.add_child(label("Vida: %d/%d" % [GameState.state.hp,GameState.state.hp_max]))
    v.add_child(label("Stamina: %d/%d" % [GameState.state.stamina,GameState.state.stamina_max]))
    v.add_child(label("Mana: %d/%d" % [GameState.state.mana,GameState.state.mana_max]))
    v.add_child(label("Fome: %d   Sede: %d   Sujeira: %d" % [GameState.state.fome,GameState.state.sede,GameState.state.sujeira],15,MUTED))

func show_inventory() -> void:
    page="inventory"
    var v=base_screen()
    header(v,"Inventário","Estrutura pronta para receber os itens migrados.")
    var inv:Dictionary=GameState.state.get("inventory",{})
    if inv.is_empty():
        v.add_child(label("Inventário vazio.",16,MUTED))
    for id in inv.keys():
        var item=GameData.item(str(id))
        v.add_child(label("%s × %s" % [item.get("name",id),str(inv[id])]))

func show_journal() -> void:
    page="journal"
    var v=base_screen()
    header(v,"Diário")
    for entry in GameState.state.get("journal",[]):
        v.add_child(label(str(entry),16))

func save_game() -> void:
    SaveManager.save_game()

func load_game() -> void:
    if SaveManager.load_game():
        page="map"
        _draw_ui()
