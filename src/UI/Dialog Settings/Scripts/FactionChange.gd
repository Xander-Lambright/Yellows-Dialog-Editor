extends Control

signal faction_id_changed
signal faction_points_changed

var faction_data := {}

func _ready():
	$Panel/ChooseFaction.load_faction_data(faction_data)
	$Panel/Factionpoints.prefix = tr("ADD")
	$Panel/Factionpoints.suffix = tr("POINTS_ABBRV")

func load_faction_data(data : Dictionary):
	faction_data = data

func set_points(value : int):
	$Panel/Factionpoints.value = value

func set_id(value : int):
	$Panel/FactionID.value = value
	
func _on_FactionID_value_changed(value : int):
	$Panel/ChooseFaction.set_faction_name_from_id(value)
	emit_signal("faction_id_changed",value)
	
func _on_Factionpoints_value_changed(value : int):
	emit_signal("faction_points_changed",value)
	
func _input(_event : InputEvent):
	if Input.is_key_pressed(KEY_ENTER):
		$Panel/Factionpoints.get_line_edit().release_focus()
