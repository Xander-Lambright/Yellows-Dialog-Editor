class_name category_loader
extends Node

signal clear_editor_request
signal update_current_category
signal add_dialog
signal add_response
signal request_connect_nodes
signal no_ydec_found
signal request_add_color_organizer

signal editor_offset_loaded
signal zoom_loaded
signal category_finished_loading

var loaded_dialogs = []
var loaded_responses = []	

func load_temp(data):
		emit_signal("clear_editor_request")
		for dict in data:
			if dict.has("editor_offset.x"):
				load_editor_settings(dict)
			elif dict.get("node_type") == "Dialog Node":
				load_dialog_data(dict)	
			else:
				load_color_category(dict)
		connect_all_responses()
		queue_free()
		DisplayServer.window_set_title(CurrentEnvironment.current_directory+"/"+CurrentEnvironment.current_category_name+" | CNPC Dialog Editor")
		return OK



func load_category(category_name):
	var current_category_path = CurrentEnvironment.current_directory+"/dialogs/"+category_name+"/"+category_name+".ydec"
	var save_category
	if not FileAccess.file_exists(current_category_path):
		emit_signal("no_ydec_found",category_name)
		return ERR_DOES_NOT_EXIST
	else:
		save_category = FileAccess.open(current_category_path,FileAccess.READ)
		emit_signal("clear_editor_request")
		if save_category.get_error() != OK:
			printerr("There was an error in opening the YDEC file.")
			return ERR_FILE_CANT_READ
		else:
			while(save_category.get_position() < save_category.get_length()):
				var test_json_conv = JSON.new()
				test_json_conv.parse(save_category.get_line())
				var node_data : Dictionary = test_json_conv.get_data()
				if node_data.has("editor_offset.x"):
					load_editor_settings(node_data)
				elif node_data.get("node_type") == "Dialog Node":
					load_dialog_data(node_data)	
				elif node_data.get("node_type") == "Color Organizer":
					load_color_category(node_data)
					
			connect_all_responses()
			save_category.close()
			emit_signal("update_current_category",category_name)
			DisplayServer.window_set_title(CurrentEnvironment.current_directory+"/"+category_name+" | CNPC Dialog Editor")
			emit_signal("category_finished_loading")
		return OK

func load_editor_settings(node_data):
	emit_signal("zoom_loaded",node_data["zoom"])
	emit_signal("editor_offset_loaded",Vector2(node_data["editor_offset.x"],node_data["editor_offset.y"]))
	
func load_color_category(node_data):
	var loaded_color_organizer : color_organizer = GlobalDeclarations.COLOR_ORGANIZER.instantiate()
	loaded_color_organizer.initial_offset = Vector2(node_data["position_offset.x"],node_data["position_offset.y"])
	loaded_color_organizer.box_color  = GlobalDeclarations.int_to_color(node_data["color"])
	loaded_color_organizer.custom_minimum_size = Vector2(node_data["min_size_x"],node_data["min_size_y"])
	loaded_color_organizer.text = node_data["text"]
	if node_data.has("locked"):
		loaded_color_organizer.locked = bool(node_data["locked"])
	emit_signal("request_add_color_organizer",loaded_color_organizer,true)
	
func load_dialog_data(node_data : Dictionary):
	var currently_loaded_dialog = create_new_dialog_node_from_ydec(node_data)
	emit_signal("add_dialog",currently_loaded_dialog,true)
	if node_data.has("response_options"):
		for response_data in node_data["response_options"]:
			var currently_loaded_response = create_response_node_from_ydec(response_data)
			emit_signal("add_response",currently_loaded_dialog,currently_loaded_response)
			loaded_responses.append(currently_loaded_response)
	loaded_dialogs.append(currently_loaded_dialog)
	
func connect_all_responses():
	for response in loaded_responses:
		var connected_dialog
		for dialog in loaded_dialogs:
			if dialog.dialog_id == response.to_dialog_id:
				connected_dialog = dialog
		if response.to_dialog_id > 0 && connected_dialog != null:
			emit_signal("request_connect_nodes",response,0,connected_dialog,0)


func create_new_dialog_node_from_ydec(node_data : Dictionary):
	var currently_loaded_dialog := GlobalDeclarations.DIALOG_NODE.instantiate()
	if !node_data.has("position_offset.x"):
		printerr("Line does not contain offset data, considered to be invalid")
		return currently_loaded_dialog
	currently_loaded_dialog.position_offset = Vector2(node_data["position_offset.x"],node_data["position_offset.y"])
	for i in node_data.keys():
		if i == "position_offset.x" or i == "position_offset.y" or i == "filename" or i == "quest_availabilities" or i == "dialog_availabilities" or i == "faction_availabilities" or i == "scoreboard_availabilities" or i == "faction_changes" or i == "response_options" or i == "mail":
			continue
		currently_loaded_dialog.set(i, node_data[i])
	currently_loaded_dialog.time_availability = node_data["time_availability"]
	currently_loaded_dialog.min_level_availability = node_data["min_level_availability"]
	for i in 4:
		currently_loaded_dialog.quest_availabilities[i].set_id(node_data["quest_availabilities"][i].quest_id)
		currently_loaded_dialog.quest_availabilities[i].set_availability(node_data["quest_availabilities"][i].availability_type)
		currently_loaded_dialog.dialog_availabilities[i].set_id(node_data["dialog_availabilities"][i].dialog_id)
		currently_loaded_dialog.dialog_availabilities[i].set_availability(node_data["dialog_availabilities"][i].availability_type)
		
	for i in 2:
		currently_loaded_dialog.faction_availabilities[i].set_id(node_data["faction_availabilities"][i].faction_id)
		currently_loaded_dialog.faction_availabilities[i].set_stance(node_data["faction_availabilities"][i].stance_type)
		currently_loaded_dialog.faction_availabilities[i].set_operator(node_data["faction_availabilities"][i].availability_operator)
		
		currently_loaded_dialog.faction_changes[i].set_id(node_data["faction_changes"][i].faction_id)
		currently_loaded_dialog.faction_changes[i].set_points(node_data["faction_changes"][i].points)
		
		currently_loaded_dialog.scoreboard_availabilities[i].set_objective_name(node_data["scoreboard_availabilities"][i].objective_name)
		currently_loaded_dialog.scoreboard_availabilities[i].set_comparison_type(node_data["scoreboard_availabilities"][i].comparison_type)
		currently_loaded_dialog.scoreboard_availabilities[i].set_value(node_data["scoreboard_availabilities"][i].value)
	currently_loaded_dialog.mail.sender = node_data["mail"].sender
	currently_loaded_dialog.mail.subject = node_data["mail"].subject
	currently_loaded_dialog.mail.items_slots = JSON.parse_string(node_data["mail"].items)
	currently_loaded_dialog.mail.pages = JSON.parse_string(node_data["mail"].pages) as Array[String]
	currently_loaded_dialog.mail.quest_id = node_data["mail"].quest_id
	return currently_loaded_dialog

func create_response_node_from_ydec(response_data):
	var currently_loaded_response ResponseNode = GlobalDeclarations.RESPONSE_NODE.instantiate()
	currently_loaded_response.slot = response_data.slot
	currently_loaded_response.color_decimal = response_data.color_decimal
	currently_loaded_response.to_dialog_id = response_data.to_dialog_id
	currently_loaded_response.command = response_data.command
	currently_loaded_response.set_option_from_index(response_data.option_type)
	currently_loaded_response.response_title = response_data.response_title
	currently_loaded_response.position_offset = Vector2(response_data.position_offset_x,response_data.position_offset_y)
	return currently_loaded_response
	
