extends Panel

signal hide_information_panel
signal show_information_panel

signal request_store_current_category
signal request_switch_to_stored_category
signal availability_mode_entered
signal availability_mode_exited
signal ready_to_set_availability
signal unsaved_change

@export var dialog_settings_tab_path: NodePath
@export var category_panel_path : NodePath

@export var hide_npc_checkbox_path: NodePath
@export var show_wheel_checkbox_path: NodePath
@export var disable_esc_checkbox_path: NodePath
@export var title_label_path: NodePath
@export var command_edit_path: NodePath
@export var playsound_edit_path: NodePath
@export var faction_changes_1_path: NodePath
@export var faction_changes_2_path: NodePath
@export var start_quest_path: NodePath
@export var dialog_text_edit_path: NodePath

@export var availability_quests_path: NodePath
@export var availability_dialogs_path: NodePath 
@export var availability_factions_path: NodePath 
@export var availability_scoreboard_path: NodePath
@export var availability_time_path: NodePath
@export var availability_level_path: NodePath

@export var mail_data_path : NodePath


@export var toggle_visiblity_path: NodePath

@export var dialog_editor_path: NodePath


@onready var DialogSettingsTab := get_node(dialog_settings_tab_path)
@onready var CategoryPanel := get_node(category_panel_path)

@onready var HideNpcCheckbox := get_node(hide_npc_checkbox_path)
@onready var ShowWheelCheckbox := get_node(show_wheel_checkbox_path)
@onready var DisableEscCheckbox := get_node(disable_esc_checkbox_path)
@onready var TitleLabel := get_node(title_label_path)
@onready var CommandEdit := get_node(command_edit_path)
@onready var PlaysoundEdit := get_node(playsound_edit_path)
@onready var FactionChanges1 := get_node(faction_changes_1_path)
@onready var FactionChanges2 := get_node(faction_changes_2_path)
@onready var StartQuest := get_node(start_quest_path)
@onready var DialogTextEdit := get_node(dialog_text_edit_path)

@onready var AvailabilityQuests := get_node(availability_quests_path)
@onready var AvailabilityDialogs := get_node(availability_dialogs_path)
@onready var AvailabilityFactions := get_node(availability_factions_path)
@onready var AvailabilityScoreboard := get_node(availability_scoreboard_path)
@onready var AvailabilityTime := get_node(availability_time_path)
@onready var AvailabilityLevel := get_node(availability_level_path)

@onready var ToggleVisibility := get_node(toggle_visiblity_path)
@onready var DialogEditor : GraphEdit = get_node(dialog_editor_path)
@onready var MailData := get_node(mail_data_path)

var current_dialog : DialogNode
var dialog_availability_mode := false
var exiting_availability_mode := false
var availability_slot : int
var stored_current_dialog_id : int
var glob_node_selected_id : int

func _ready(): 
	set_quest_dict()
	for i in 4:
		AvailabilityQuests.get_child(i).connect("id_changed", Callable(self, "quest_id_changed"))
		AvailabilityQuests.get_child(i).connect("type_changed", Callable(self, "quest_type_changed"))
		AvailabilityDialogs.get_child(i).connect("id_changed", Callable(self, "dialog_id_changed"))
		AvailabilityDialogs.get_child(i).connect("type_changed", Callable(self, "dialog_type_changed"))
		AvailabilityDialogs.get_child(i).connect("enter_dialog_availability_mode", Callable(self, "enter_dialog_availability_mode").bind(AvailabilityDialogs.get_child(i)))
	for i in 2:
		AvailabilityFactions.get_child(i).connect("id_changed", Callable(self, "faction_id_changed"))
		AvailabilityFactions.get_child(i).connect("stance_changed", Callable(self, "faction_stance_changed"))
		AvailabilityFactions.get_child(i).connect("isisnot_changed", Callable(self, "faction_isisnot_changed"))
		
		AvailabilityScoreboard.get_child(i).connect("objective_name_changed", Callable(self, "scoreboard_objective_name_changed"))
		AvailabilityScoreboard.get_child(i).connect("comparison_type_changed", Callable(self, "scoreboard_comparison_type_changed"))
		AvailabilityScoreboard.get_child(i).connect("value_changed", Callable(self, "scoreboard_value_changed"))

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if dialog_availability_mode:
			exit_dialog_availability_mode()



func set_quest_dict():
	var access_to_quests = get_tree().get_nodes_in_group("quest_access")
	for node in access_to_quests:
		node.quest_dict = quest_indexer.new().index_quest_categories()

func disconnect_current_dialog(dialog : DialogNode,_bool : bool,_ignore : bool):
	if current_dialog == dialog:
		dialog.disconnect("text_changed", Callable(self, "update_text"))
		dialog.disconnect("request_deletion", Callable(self, "disconnect_current_dialog"))
		current_dialog.disconnect("title_changed", Callable(self, "update_title"))
	current_dialog = null


func dialog_selected(dialog):
	if !dialog_availability_mode:
		load_dialog_settings(dialog)
		
		
		
func enter_dialog_availability_mode(availability_scene):
	stored_current_dialog_id = current_dialog.dialog_id
	availability_slot = AvailabilityDialogs.get_children().find(availability_scene)
	dialog_availability_mode = true
	emit_signal("hide_information_panel")
	emit_signal("request_store_current_category")
	emit_signal("availability_mode_entered")
	ToggleVisibility.button_pressed = false
	ToggleVisibility.text = "<"
	print("Availability Mode Entered")

	
func set_dialog_availability_from_selected_node(node_selected : GraphNode):
	if dialog_availability_mode:
		glob_node_selected_id = node_selected.dialog_id
		var new_timer = Timer.new()
		add_child(new_timer)
		new_timer.start(0.3)
		await new_timer.timeout
		new_timer.queue_free()
		#I know that using a delay is a bad solution for a race condition,
		#but I'm not even really sure what the race condition is. This little
		#delay prevents the node that was chosen for the dialog availability
		#remaining selected if it's within the same category
		if node_selected.is_inside_tree():
			node_selected.set_self_as_unselected()
		exit_dialog_availability_mode()
		
		
		
func exit_dialog_availability_mode():
	exiting_availability_mode = true
	emit_signal("request_switch_to_stored_category")
	emit_signal("show_information_panel")

	
	
	

func _on_category_panel_finished_loading(_ignore):
	if exiting_availability_mode:
		var initial_dialog : GraphNode = find_dialog_node_from_id(stored_current_dialog_id)
		emit_signal("availability_mode_exited")
		load_dialog_settings(initial_dialog)
		initial_dialog.dialog_availabilities[availability_slot].dialog_id = glob_node_selected_id
		AvailabilityDialogs.get_child(availability_slot).set_id(glob_node_selected_id)
		initial_dialog.selected = true
		initial_dialog.draggable = false
		
		
		emit_signal("unsaved_change")
		
		print("Availability Mode Exited")			
		dialog_availability_mode = false
		exiting_availability_mode = false
		

func find_dialog_node_from_id(id : int):
	var dialog_nodes = get_tree().get_nodes_in_group("Save")
	for dialog in dialog_nodes:
		if dialog.dialog_id == id:
			return dialog
			


	
	
	

func set_title_text(title_text : String,node_index : int):
	if title_text.length() > 35:
		title_text = title_text.left(35)+"..."
	TitleLabel.text = title_text+"| Node "+str(node_index)

		
func load_dialog_settings(dialog : DialogNode):
	DialogSettingsTab.visible = true
	if current_dialog != dialog:
		if current_dialog != null && is_instance_valid(current_dialog) && current_dialog.is_connected("text_changed", Callable(self, "update_text")):
			current_dialog.disconnect("text_changed", Callable(self, "update_text"))
			current_dialog.disconnect("request_deletion", Callable(self, "disconnect_current_dialog"))
			current_dialog.disconnect("title_changed", Callable(self, "update_title"))
		current_dialog = dialog
		if !current_dialog.is_connected("text_changed", Callable(self, "update_text")):
			current_dialog.connect("text_changed", Callable(self, "update_text"))
			current_dialog.connect("request_deletion", Callable(self, "disconnect_current_dialog"))
			current_dialog.connect("title_changed", Callable(self, "update_title").bind(current_dialog))
	set_title_text(current_dialog.dialog_title,current_dialog.node_index)	
	HideNpcCheckbox.button_pressed = current_dialog.hide_npc
	ShowWheelCheckbox.button_pressed = current_dialog.show_wheel
	DisableEscCheckbox.button_pressed = current_dialog.disable_esc
	CommandEdit.text = current_dialog.command
	PlaysoundEdit.text = current_dialog.sound
	StartQuest.set_id(current_dialog.start_quest)
	DialogTextEdit.text = current_dialog.text
	
	FactionChanges1.set_id(current_dialog.faction_changes[0].faction_id)
	FactionChanges1.set_points(current_dialog.faction_changes[0].points)
	FactionChanges2.set_id(current_dialog.faction_changes[1].faction_id)
	FactionChanges2.set_points(current_dialog.faction_changes[1].points)
	
	AvailabilityTime.get_node("Panel/OptionButton").selected = current_dialog.time_availability
	AvailabilityLevel.get_node("Panel/SpinBox").value = current_dialog.min_level_availability
	
	for i in 4:
		AvailabilityQuests.get_child(i).set_id(current_dialog.quest_availabilities[i].quest_id)
		AvailabilityQuests.get_child(i).set_availability_type(current_dialog.quest_availabilities[i].availability_type)
		AvailabilityDialogs.get_child(i).set_id(current_dialog.dialog_availabilities[i].dialog_id)
		AvailabilityDialogs.get_child(i).set_availability_type(current_dialog.dialog_availabilities[i].availability_type)
		AvailabilityDialogs.get_child(i).set_choose_dialog_disbaled_proper()
	for i in 2:
		AvailabilityFactions.get_child(i).set_id(current_dialog.faction_availabilities[i].faction_id)
		AvailabilityFactions.get_child(i).set_stance(current_dialog.faction_availabilities[i].stance_type)
		AvailabilityFactions.get_child(i).set_isisnot(current_dialog.faction_availabilities[i].availability_operator)
		
		AvailabilityScoreboard.get_child(i).set_objective_name(current_dialog.scoreboard_availabilities[i].objective_name)
		AvailabilityScoreboard.get_child(i).set_comparison_type(current_dialog.scoreboard_availabilities[i].comparison_type)
		AvailabilityScoreboard.get_child(i).set_value(current_dialog.scoreboard_availabilities[i].value)
	MailData.load_mail_data(current_dialog.mail)
		
func scoreboard_objective_name_changed(child ,obj_name : String):
	current_dialog.scoreboard_availabilities[AvailabilityScoreboard.get_children().find(child)].objective_name = obj_name
	emit_signal("unsaved_change")
func scoreboard_comparison_type_changed(child,type : int):
	current_dialog.scoreboard_availabilities[AvailabilityScoreboard.get_children().find(child)].comparison_type = type
	emit_signal("unsaved_change")
	
func scoreboard_value_changed(child ,value : int):
	current_dialog.scoreboard_availabilities[AvailabilityScoreboard.get_children().find(child)].value = value
	emit_signal("unsaved_change")		
func faction_id_changed(child ,id : int):
	current_dialog.faction_availabilities[AvailabilityFactions.get_children().find(child)].faction_id = id
	emit_signal("unsaved_change")
func faction_stance_changed(child,stance:int):
	current_dialog.faction_availabilities[AvailabilityFactions.get_children().find(child)].stance_type = stance
	emit_signal("unsaved_change")
func faction_isisnot_changed(child ,isisnot : int):
	current_dialog.faction_availabilities[AvailabilityFactions.get_children().find(child)].availability_operator = isisnot
	emit_signal("unsaved_change")

func dialog_id_changed(child,id : int):
	current_dialog.dialog_availabilities[AvailabilityDialogs.get_children().find(child)].dialog_id = id
	emit_signal("unsaved_change")
	
func dialog_type_changed(child,type : int):
	current_dialog.dialog_availabilities[AvailabilityDialogs.get_children().find(child)].availability_type = type
	emit_signal("unsaved_change")



func quest_id_changed(child,id : int):
	current_dialog.quest_availabilities[AvailabilityQuests.get_children().find(child)].quest_id = id
	emit_signal("unsaved_change")

	
func quest_type_changed(child,type : int):
	current_dialog.quest_availabilities[AvailabilityQuests.get_children().find(child)].availability_type = type
	emit_signal("unsaved_change")
#Dialog Changes

func _on_HideNPC_pressed():
	current_dialog.hide_npc = HideNpcCheckbox.button_pressed
	emit_signal("unsaved_change")
	
func _on_ShowDialogWheel_pressed():
	current_dialog.show_wheel = ShowWheelCheckbox.button_pressed
	emit_signal("unsaved_change")

func _on_DisableEsc_pressed():
	current_dialog.disable_esc = DisableEscCheckbox.button_pressed
	emit_signal("unsaved_change")


func _on_FactionChange_faction_id_changed(id : int):
	current_dialog.faction_changes[0].faction_id = id
	emit_signal("unsaved_change")

func _on_FactionChange2_faction_id_changed(id : int):
	current_dialog.faction_changes[1].faction_id = id
	emit_signal("unsaved_change")

func _on_FactionChange2_faction_points_changed(points : int):
	current_dialog.faction_changes[1].points = points
	emit_signal("unsaved_change")

func _on_FactionChange_faction_points_changed(points : int):
	current_dialog.faction_changes[0].points = points
	emit_signal("unsaved_change")

func _on_Command_text_changed():
	current_dialog.command = CommandEdit.text
	emit_signal("unsaved_change")

func _on_TimeButton_item_selected(index : int):
	current_dialog.time_availability = index
	emit_signal("unsaved_change")

func _on_LevelSpinBox_value_changed(value : int):
	current_dialog.min_level_availability = value
	emit_signal("unsaved_change")



func _on_DialogText_text_changed():
	current_dialog.set_dialog_text(DialogTextEdit.text)
	emit_signal("unsaved_change")

func update_text():
	DialogTextEdit.text = current_dialog.text

func update_title(_text):
	set_title_text(current_dialog.dialog_title,current_dialog.node_index)

func _on_StartQuest_id_changed(value : int):
	current_dialog.start_quest = value
	emit_signal("unsaved_change")


func no_dialog_selected():
	DialogSettingsTab.visible = false


func _on_ToggleVisiblity_toggled(button_pressed : bool):
	if !button_pressed:
		emit_signal("hide_information_panel")
		ToggleVisibility.text = "<"
	else:
		emit_signal("show_information_panel")
		ToggleVisibility.text = ">"


	
	


func _on_DialogEditor_finished_loading(_category_name : String):
	emit_signal("ready_to_set_availability")



func _on_availability_timer_timeout() -> void:
	#fixes a dumb issue where the information panel doesn't update, by just delaying iy
	pass


func _on_soundfile_text_changed():
	current_dialog.sound = PlaysoundEdit.text



