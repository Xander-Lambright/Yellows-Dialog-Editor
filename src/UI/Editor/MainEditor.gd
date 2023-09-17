extends Control

var unsaved_change := false

@export var _dialog_editor_path: NodePath
@export var _category_list_path: NodePath
@export var _information_panel_path: NodePath
@export var _dialog_settings_tabs_path: NodePath
@export var _top_panel_path: NodePath



@onready var DialogEditor = get_node(_dialog_editor_path)
@onready var InformationPanel = get_node(_information_panel_path)
@onready var DialogSettingsPanel = get_node(_dialog_settings_tabs_path)
@onready var CategoryList = get_node(_category_list_path)
@onready var TopPanel = get_node(_top_panel_path)


func _ready():
	if !FileAccess.file_exists(CurrentEnvironment.current_directory+"/environment_settings.json"):
		FileAccess.open(CurrentEnvironment.current_directory+"/environment_settings.json",FileAccess.WRITE)
	var file = FileAccess.open(CurrentEnvironment.current_directory+"/environment_settings.json",FileAccess.READ)
	var test_json_conv = JSON.new()
	test_json_conv.parse(file.get_line())
	var loaded_list = test_json_conv.get_data()
	if loaded_list is Dictionary:
		$DialogList.all_loaded_dialogs = loaded_list
	else:
		push_warning("Loaded Dialogs List not valid.")
	var faction_choosers = get_tree().get_nodes_in_group("faction_access")
	var fact_loader = faction_loader.new()
	var fact_dict = fact_loader.get_faction_data(CurrentEnvironment.current_directory)
	for node in faction_choosers:
		node.load_faction_data(fact_dict)
	get_tree().auto_accept_quit = false
	
func _input(event):
	if event.is_action_pressed("add_dialog_at_mouse"):
		var new_dialog_node = GlobalDeclarations.DIALOG_NODE.instantiate()
		new_dialog_node.position_offset = get_local_mouse_position()
		DialogEditor.add_dialog_node(new_dialog_node)
	if event.is_action_pressed("create_response"):
		for dialog in DialogEditor.selected_nodes:
			dialog.add_response_node()
	if event.is_action_pressed("focus_response_below"):
		if get_viewport().gui_get_focus_owner().get_name() != "ResponseText":
			return
		else:
			var response = get_viewport().gui_get_focus_owner().get_parent().get_parent().get_parent()
			if response.slot != response.parent_dialog.response_options.size():
				response.parent_dialog.response_options[response.slot].set_focus_on_title()		
	if Input.is_action_just_pressed("focus_response_above"):
		if get_viewport().gui_get_focus_owner().get_name() != "ResponseText":
			return
		else:
			var response = get_viewport().gui_get_focus_owner().get_parent().get_parent().get_parent()
			if response.slot != 1:
				response.parent_dialog.response_options[response.slot-2].set_focus_on_title()
				


func update_current_directory(new_path):
	CurrentEnvironment.current_directory = new_path
	var file_acess_group = get_tree().get_nodes_in_group("File Access")
	for node in file_acess_group:
		node.update_current_directory(new_path)

func update_current_category(category_name):
	CurrentEnvironment.current_category_name = category_name


func _on_DialogEditor_editor_cleared():
	InformationPanel.current_dialog = null





func _on_DialogFileSystemIndex_category_deleted():
	pass # Replace with function body.


func export_dialog_list():
	var file = FileAccess.open(CurrentEnvironment.current_directory+"/environment_settings.json",FileAccess.WRITE)

	file.store_line(JSON.new().stringify($DialogList.all_loaded_dialogs))
	
func save_factions_list():
	var file = FileAccess.open(CurrentEnvironment.current_directory+"/environment_settings.json",FileAccess.WRITE)
	file.get_line()
	file.store_line("JSON.new().stringify($DialogList.all_loaded_dialogstes")


func import_faction_popup():
	var faction_loader = load("res://src/UI/Util/FactionLoader.tscn").instantiate()
	add_child(faction_loader)
	faction_loader.connect("faction_json_selected", Callable(self, "give_factions_to_nodes"))
	faction_loader.popup()
	
func give_factions_to_nodes(json):
	print(json)
	var file = FileAccess.open(json,FileAccess.READ)
	
	var test_json_conv = JSON.new()
	test_json_conv.parse(file.get_as_text())
	var json_parsed = test_json_conv.get_data()
	file.close()
	if json_parsed.error == OK:
		var faction_choosers = get_tree().get_nodes_in_group("faction_access")
		for node in faction_choosers:
			node.load_faction_data(json_parsed)
	else:
		printerr("Bad JSON File")


func _on_FactionChange2_faction_id_changed():
	pass # Replace with function body.

var is_quit_return_to_home := false

func _on_HomeButton_pressed():
	if !unsaved_change:
		get_parent().add_child(load("res://src/UI/LandingScreen.tscn").instantiate())
		queue_free()
	else:
		$UnsavedPanel.visible = true
		is_quit_return_to_home = true

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		is_quit_return_to_home = false
		if !unsaved_change:
			get_tree().quit()
		else:
			$UnsavedPanel.visible = true
					
func set_unsaved_changes(value:bool):
	unsaved_change = value



func _on_no_save_pressed():
	if is_quit_return_to_home:
		get_parent().add_child(load("res://src/UI/LandingScreen.tscn").instantiate())
		get_tree().auto_accept_quit = true
		queue_free()
		
	else:
		get_tree().quit()


func _on_save_and_close_pressed():
	$CategoryPanel.save_category_request()
	if is_quit_return_to_home:
		get_parent().add_child(load("res://src/UI/LandingScreen.tscn").instantiate())
		get_tree().auto_accept_quit = true
		queue_free()
	else:
		get_tree().quit()


func _on_cancel_pressed():
	$UnsavedPanel.visible = false
