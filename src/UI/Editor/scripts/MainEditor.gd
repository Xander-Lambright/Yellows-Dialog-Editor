extends Control

signal input_recieved

var unsaved_categories = []


@export var _dialog_editor_path: NodePath
@export var _category_list_path: NodePath
@export var _information_panel_path: NodePath
@export var _dialog_settings_tabs_path: NodePath
@export var _top_panel_path: NodePath



@onready var DialogEditor := get_node(_dialog_editor_path)
@onready var InformationPanel := get_node(_information_panel_path)
@onready var DialogSettingsPanel := get_node(_dialog_settings_tabs_path)
@onready var CategoryList := get_node(_category_list_path)
@onready var TopPanel := get_node(_top_panel_path)


func _ready():
	if !FileAccess.file_exists(CurrentEnvironment.current_directory+"/environment_settings.json"):
		FileAccess.open(CurrentEnvironment.current_directory+"/environment_settings.json",FileAccess.WRITE)
	var file := FileAccess.open(CurrentEnvironment.current_directory+"/environment_settings.json",FileAccess.READ)
	var test_json_conv := JSON.new()
	test_json_conv.parse(file.get_line())
	var loaded_list = test_json_conv.get_data()
	if loaded_list is Dictionary:
		$DialogList.all_loaded_dialogs = loaded_list
	else:
		push_warning("Loaded Dialogs List not valid.")
	var faction_choosers := get_tree().get_nodes_in_group("faction_access")
	var fact_loader := faction_loader.new()
	var fact_dict := fact_loader.get_faction_data(CurrentEnvironment.current_directory)
	for node in faction_choosers:
		node.load_faction_data(fact_dict)
	get_tree().auto_accept_quit = false
	$AutosaveTimer.start(GlobalDeclarations.autosave_time*60)
	$DialogEditor.use_snap = GlobalDeclarations.snap_enabled
	
func _input(event : InputEvent):
	emit_signal("input_recieved", event)
	

func update_current_directory(new_path : String):
	CurrentEnvironment.current_directory = new_path
	var file_acess_group := get_tree().get_nodes_in_group("File Access")
	for node in file_acess_group:
		node.update_current_directory(new_path)

func update_current_category(category_name : String):
	CurrentEnvironment.current_category_name = category_name


func _on_DialogEditor_editor_cleared():
	InformationPanel.current_dialog = null

func export_dialog_list():
	var file := FileAccess.open(CurrentEnvironment.current_directory+"/environment_settings.json",FileAccess.WRITE)

	file.store_line(JSON.stringify($DialogList.all_loaded_dialogs))
	
func save_factions_list():
	var file := FileAccess.open(CurrentEnvironment.current_directory+"/environment_settings.json",FileAccess.WRITE)
	file.get_line()
	file.store_line("JSON.new().stringify($DialogList.all_loaded_dialogstes")

	
func give_factions_to_nodes(json : String):
	var file = FileAccess.open(json,FileAccess.READ)
	
	var test_json_conv = JSON.new()
	test_json_conv.parse(file.get_as_text())
	var json_parsed : Dictionary = test_json_conv.get_data()
	file.close()
	if test_json_conv.error == OK:
		var faction_choosers := get_tree().get_nodes_in_group("faction_access")
		for node in faction_choosers:
			node.load_faction_data(json_parsed)
	else:
		printerr("Bad JSON File")


var is_quit_return_to_home := false

func _on_HomeButton_pressed():
	if unsaved_categories.is_empty():
		get_parent().add_child(load("res://src/UI/LandingScreen.tscn").instantiate())
		queue_free()
	else:
		$UnsavedPanel.visible = true
		is_quit_return_to_home = true

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		is_quit_return_to_home = false
		if unsaved_categories.is_empty():
			get_tree().quit()
		else:
			$UnsavedPanel.visible = true
					
func add_to_unsaved_categories(category):
	if !unsaved_categories.has(category) && category != null:
		unsaved_categories.append(category)

func remove_from_unsaved_categories(category):
	unsaved_categories.erase(category)


func _on_no_save_pressed():
	if is_quit_return_to_home:
		get_parent().add_child(load("res://src/UI/LandingScreen.tscn").instantiate())
		get_tree().auto_accept_quit = true
		queue_free()
		
	else:
		get_tree().quit()


func _on_save_and_close_pressed():
	$CategoryPanel.save_all_categories()
	if is_quit_return_to_home:
		get_parent().add_child(load("res://src/UI/LandingScreen.tscn").instantiate())
		get_tree().auto_accept_quit = true
		queue_free()
	else:
		get_tree().quit()


func _on_cancel_pressed():
	$UnsavedPanel.visible = false


func _on_category_panel_category_succesfully_saved(category_name):
	remove_from_unsaved_categories(category_name)





func _on_dialog_editor_node_double_clicked(_ignore):
	$DoubleClickTimer.start()


