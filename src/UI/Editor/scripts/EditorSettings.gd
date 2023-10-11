extends Panel

signal snap_enabled_changed
signal autosave_time_changed

@onready var keybind_scene = load("res://src/UI/Editor/keybind.tscn")


@export var hide_connection_slider_path : NodePath
@export var hold_shift_check_path : NodePath
@export var auto_save_path : NodePath
@export var enable_grid_check_path : NodePath
@export var autosave_max_files_path : NodePath
@export var allow_more_than_six_path : NodePath
@export var keybinds_scroll_path : NodePath
@export var default_directory_label_path : NodePath
@export var default_directory_file_dialog_path : NodePath

@onready var HideConnectionSlider : HSlider= get_node(hide_connection_slider_path)
@onready var HoldShiftCheck :Button= get_node(hold_shift_check_path)
@onready var AutoSave = get_node(auto_save_path)
@onready var EnableGridCheck : CheckButton = get_node(enable_grid_check_path)
@onready var AutoSaveMaxFiles : SpinBox = get_node(autosave_max_files_path)
@onready var AllowMoreThanSix : CheckButton = get_node(allow_more_than_six_path)
@onready var KeybindsScroll : VBoxContainer = get_node(keybinds_scroll_path)
@onready var DefaultDirectoryLabel : Label = get_node(default_directory_label_path)
@onready var DefaultDirectoryFileDialog : FileDialog = get_node(default_directory_file_dialog_path)


func _ready():
	HideConnectionSlider.value = GlobalDeclarations.hide_connection_distance
	HoldShiftCheck.button_pressed = GlobalDeclarations.hold_shift_for_individual_movement
	AutoSave.value = GlobalDeclarations.autosave_time
	EnableGridCheck.button_pressed = GlobalDeclarations.snap_enabled
	AutoSaveMaxFiles.value = GlobalDeclarations.autosave_max_files
	AllowMoreThanSix.button_pressed = GlobalDeclarations.allow_above_six_responses
	DefaultDirectoryLabel.text = "Default Directory: "+GlobalDeclarations.default_user_directory
	DefaultDirectoryFileDialog.current_dir = GlobalDeclarations.default_user_directory
	for action in GlobalDeclarations.actions:
		var keybind_instance = keybind_scene.instantiate()
		keybind_instance.assign_action(action)
		KeybindsScroll.add_child(keybind_instance)
		
	
	
	
	
func _on_h_slider_value_changed(value : int):
	HideConnectionSlider.get_node("ValueEdit").text = str(value)
	GlobalDeclarations.hide_connection_distance = value


func _on_value_edit_text_submitted(new_text : String):
	HideConnectionSlider.value = int(new_text)
	


func _on_resetbutton_pressed():
	HideConnectionSlider.value = 1000


func _on_button_pressed():
	get_tree().paused = false
	GlobalDeclarations.save_config()
	visible = false
	


func _on_editor_settings_button_pressed():
	visible = true
	get_tree().paused = true


func _on_check_button_toggled(button_pressed):
	GlobalDeclarations.hold_shift_for_individual_movement = button_pressed


func _on_undo_button_toggled(button_pressed):
	GlobalDeclarations.snap_enabled = button_pressed
	emit_signal("snap_enabled_changed",button_pressed)


func _on_autosave_value_edit_text_changed(new_text):
	AutoSave.value = int(new_text)


func _on_autosave_resetbutton_pressed():
	AutoSave.value = 3


func _on_autosave_h_slider_changed(value):
	GlobalDeclarations.autosave_time = value
	autosave_time_changed.emit()
	AutoSave.get_node("ValueEdit").text = str(GlobalDeclarations.autosave_time)


func _on_autosave_max_files_value_changed(value):
	GlobalDeclarations.autosave_max_files = value


func _on_allow_six_check_button_toggled(button_pressed):
	GlobalDeclarations.allow_above_six_responses = button_pressed


func _on_change_directorybutton_button_up():
	DefaultDirectoryFileDialog.current_dir = GlobalDeclarations.default_user_directory
	DefaultDirectoryFileDialog.popup_centered()


func _on_file_dialog_dir_selected(dir):
	GlobalDeclarations.default_user_directory = dir
	DefaultDirectoryLabel.text = "Default Directory: "+GlobalDeclarations.default_user_directory

func _on_file_dialog_canceled():
	DefaultDirectoryFileDialog.visible = false
