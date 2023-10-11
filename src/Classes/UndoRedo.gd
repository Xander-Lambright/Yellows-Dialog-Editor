extends Node
class_name UndoSystem

enum ACTION_TYPES {
	MULTI_MOVE,
	MULTI_CREATE,
	CREATE_DIALOG,
	DELETE_DIALOG,
	MOVE_DIALOG,
	MOVE_RESPONSE,
	MOVE_COLOR_ORG,
	CREATE_RESPONSE,
	DELETE_RESPONSE,
	CREATE_COLOR_ORG,
	DELETE_COLOR_ORG,
	MULTI_DELETE,
	CONNECT_NODES,
	DISCONNECT_NODES,
	SWAP_RESPONSES
	}

signal undo_saved
signal redo_saved

signal request_action_move_dialog_node
signal request_action_add_dialog_node
signal request_action_delete_dialog_node

signal request_action_move_response_node
signal request_action_add_response_node
signal request_action_delete_response_node
signal request_action_swap_response_nodes

signal request_action_add_color_organizer
signal request_action_move_color_organizer
signal request_action_delete_color_organizer

signal request_action_connect_nodes
signal request_action_disconnect_nodes


#These signals are not 'actions', meaning they are not commited to the UndoRedo history.
#For example, undoing a delete dialog should not commit the creation of all of it's response nodes
#to the undo history.
signal request_add_response
signal request_connect_nodes

var currentUndoCategoryName : String
var undoRedoHistories : Dictionary

var undo_history = []
var redo_history = []
@export var dialog_editor : DialogGraphEdit

var ignore_all_changes := false


func load_category_undo_redo_history(category_name):
	ignore_all_changes = false
	if undoRedoHistories.has(category_name):
		currentUndoCategoryName = category_name
	else:
		undoRedoHistories[category_name] = {
			"undo_history" = [],
			"redo_history" = []
		}
	currentUndoCategoryName = category_name
	
	

func add_to_undo(type,node,args = []):
	if ignore_all_changes:
		return
	var undo_action
	match type:
		ACTION_TYPES.CREATE_DIALOG :
			undo_action = create_action_add_dialog(node)
		ACTION_TYPES.DELETE_DIALOG :
			undo_action = create_action_delete_dialog(node.node_index)
		ACTION_TYPES.MOVE_DIALOG:
			undo_action = create_action_move_dialog(node.node_index,args[0])
		
		ACTION_TYPES.MOVE_RESPONSE:
			undo_action = create_action_move_response(node.node_index,args[0])
		ACTION_TYPES.CREATE_RESPONSE :
			undo_action = create_action_add_response(node)
		ACTION_TYPES.DELETE_RESPONSE :
			undo_action = create_action_delete_response(node.node_index)
		ACTION_TYPES.SWAP_RESPONSES :
			undo_action = create_action_swap_responses(args[0],args[1],args[2],args[3])
		
		ACTION_TYPES.MOVE_COLOR_ORG:
			undo_action = create_action_move_color_organizer(node.node_index,args[0])
		ACTION_TYPES.CREATE_COLOR_ORG :
			undo_action = create_action_add_color_organizer(node)
		ACTION_TYPES.DELETE_COLOR_ORG :
			undo_action = create_action_delete_color_organizer(node.node_index)
		
		ACTION_TYPES.MULTI_MOVE:
			undo_action = create_action_move_multiple_nodes(args[0],args[1],args[2])
		ACTION_TYPES.MULTI_CREATE:
			undo_action = create_action_create_multiple_nodes(args[0],args[1],args[2])
		ACTION_TYPES.MULTI_DELETE:
			undo_action = create_action_delete_multiple_nodes(args[0],args[1],args[2])
			
		ACTION_TYPES.CONNECT_NODES:
			undo_action = create_action_connect_nodes(args[0],args[1])
		ACTION_TYPES.DISCONNECT_NODES:
			undo_action = create_action_disconnect_nodes(args[0],args[1])
	undoRedoHistories[currentUndoCategoryName].undo_history.append(undo_action)
	undoRedoHistories[currentUndoCategoryName].redo_history.clear()

func undo():
	if 	undoRedoHistories[currentUndoCategoryName].undo_history.is_empty():
		print("Nothing to undo")
		return
	var action = undoRedoHistories[currentUndoCategoryName].undo_history.back()
	var redo
	prints("Undo Action",ACTION_TYPES.find_key(action.type))
	match action.type:
		ACTION_TYPES.CREATE_DIALOG :
			redo = create_action_delete_dialog(action.dialog_data.node_index)
			execute_action_add_dialog(action)
		ACTION_TYPES.DELETE_DIALOG :
			redo = create_action_add_dialog(dialog_editor.current_dialog_index_map[action.node_index].save())
			execute_action_delete_dialog(action)
		ACTION_TYPES.MOVE_DIALOG:
			redo = create_action_move_dialog(action.node_index,dialog_editor.current_dialog_index_map[action.node_index].position_offset)
			execute_action_move_dialog(action)
		
		ACTION_TYPES.CREATE_RESPONSE :
			redo = create_action_delete_response(action.response_data.node_index)
			execute_action_add_response(action)
		ACTION_TYPES.DELETE_RESPONSE :
			redo = create_action_add_response(dialog_editor.current_response_index_map[action.node_index].save())
			execute_action_delete_response(action)
		ACTION_TYPES.MOVE_RESPONSE:
			redo = create_action_move_response(action.node_index,dialog_editor.current_response_index_map[action.node_index].position_offset)
			execute_action_move_response(action)		
		ACTION_TYPES.SWAP_RESPONSES:
			redo = create_action_swap_responses(action.overlap_index,action.original_index,action.to,action.from)
			execute_action_swap_response(action)
		
		ACTION_TYPES.CREATE_COLOR_ORG :
			redo = create_action_delete_color_organizer(action.color_org_data.node_index)
			execute_action_add_color_organizer(action)
		ACTION_TYPES.DELETE_COLOR_ORG :
			redo = create_action_add_color_organizer(dialog_editor.current_color_organizer_index_map[action.node_index].save())
			execute_action_delete_color_organizer(action)
		ACTION_TYPES.MOVE_COLOR_ORG:
			redo = create_action_move_color_organizer(action.node_index,dialog_editor.current_color_organizer_index_map[action.node_index].position_offset)
			execute_action_move_color_organizer(action)	
		
		ACTION_TYPES.MULTI_CREATE :
			redo = create_action_delete_multiple_nodes(action.dialog_data,action.response_data,action.color_organizer_data)
			execute_action_add_multiple_nodes(action)
		ACTION_TYPES.MULTI_DELETE :
			redo = create_action_create_multiple_nodes(action.dialogs,action.responses,action.color_organizers)
			execute_action_delete_multiple_nodes(action)
		ACTION_TYPES.MULTI_MOVE:
			redo = create_redo_action_move_multiple_nodes(action.dialogs,action.responses,action.color_organizers)
			execute_action_multi_move(action)
			
		ACTION_TYPES.CONNECT_NODES:
			redo = create_action_disconnect_nodes(action.dialog_index,action.response_index)
			execute_action_connect_nodes(action.dialog_index,action.response_index)
		ACTION_TYPES.DISCONNECT_NODES:
			redo = create_action_connect_nodes(action.dialog_index,action.response_index)
			execute_action_disconnect_nodes(action.dialog_index,action.response_index)
	undoRedoHistories[currentUndoCategoryName].redo_history.append(redo)
	undoRedoHistories[currentUndoCategoryName].undo_history.pop_back()

			
func redo():
	if 	undoRedoHistories[currentUndoCategoryName].redo_history.is_empty():
		print("Nothing to redo")
		return
	var action = undoRedoHistories[currentUndoCategoryName].redo_history.back()
	var undo
	prints("Redo Action",ACTION_TYPES.find_key(action.type))
	match action.type:
		ACTION_TYPES.CREATE_DIALOG :
			undo = create_action_delete_dialog(action.dialog_data.node_index)
			execute_action_add_dialog(action)
		ACTION_TYPES.DELETE_DIALOG :
			undo = create_action_add_dialog(dialog_editor.current_dialog_index_map[action.node_index].save())
			execute_action_delete_dialog(action)
		ACTION_TYPES.MOVE_DIALOG:
			undo = create_action_move_dialog(action.node_index,dialog_editor.current_dialog_index_map[action.node_index].position_offset)
			execute_action_move_dialog(action)
			
		ACTION_TYPES.CREATE_RESPONSE :
			undo = create_action_delete_response(action.response_data.node_index)
			execute_action_add_response(action)
		ACTION_TYPES.DELETE_RESPONSE :
			undo = create_action_add_response(dialog_editor.current_response_index_map[action.node_index].save())
			execute_action_delete_response(action)
		ACTION_TYPES.MOVE_RESPONSE:
			undo = create_action_move_response(action.node_index,dialog_editor.current_response_index_map[action.node_index].position_offset)
			execute_action_move_response(action)
		ACTION_TYPES.SWAP_RESPONSES:
			undo = create_action_swap_responses(action.overlap_index,action.original_index,action.to,action.from)
			execute_action_swap_response(action)
		
		ACTION_TYPES.CREATE_COLOR_ORG :
			undo = create_action_delete_color_organizer(action.color_org_data.node_index)
			execute_action_add_color_organizer(action)
		ACTION_TYPES.DELETE_COLOR_ORG :
			undo = create_action_add_color_organizer(dialog_editor.current_color_organizer_index_map[action.node_index].save())
			execute_action_delete_color_organizer(action)
		ACTION_TYPES.MOVE_COLOR_ORG:
			undo = create_action_move_color_organizer(action.node_index,dialog_editor.current_color_organizer_index_map[action.node_index].position_offset)
			execute_action_move_color_organizer(action)	
		
		ACTION_TYPES.MULTI_CREATE :
			undo = create_action_delete_multiple_nodes(action.dialog_data,action.response_data,action.color_organizer_data)
			execute_action_add_multiple_nodes(action)
		ACTION_TYPES.MULTI_DELETE :
			undo = create_action_create_multiple_nodes(action.dialogs,action.responses,action.color_organizers)
			execute_action_delete_multiple_nodes(action)
		ACTION_TYPES.MULTI_MOVE:
			undo = create_redo_action_move_multiple_nodes(action.dialogs,action.responses,action.color_organizers)
			execute_action_multi_move(action)
		
		ACTION_TYPES.CONNECT_NODES:
			undo = create_action_disconnect_nodes(action.dialog_index,action.response_index)
			execute_action_connect_nodes(action.dialog_index,action.response_index)
		ACTION_TYPES.DISCONNECT_NODES:
			undo = create_action_connect_nodes(action.dialog_index,action.response_index)
			execute_action_disconnect_nodes(action.dialog_index,action.response_index)
			
	
	undoRedoHistories[currentUndoCategoryName].undo_history.append(undo)
	undoRedoHistories[currentUndoCategoryName].redo_history.pop_back()

####Create Actions####
#These create the dictionaries that are added onto the undo/redo stack


#Dialog

func create_action_add_dialog(dialog_data : Dictionary) -> Dictionary:
	var action = {
		"type" : ACTION_TYPES.CREATE_DIALOG,
		"dialog_data" : dialog_data
	}
	return action
func create_action_delete_dialog(node_index : int) -> Dictionary:
	var action = {
		"type" : ACTION_TYPES.DELETE_DIALOG,
		"node_index" : node_index
	}
	return action
func create_action_move_dialog(node_index : int, prev_position : Vector2) -> Dictionary:
	var action = {
		"type" : ACTION_TYPES.MOVE_DIALOG,
		"node_index" : node_index,
		"prev_position" : prev_position
	}
	return action
	
#Responses
func create_action_add_response(response_data : Dictionary) -> Dictionary:
	var action = {
		"type" : ACTION_TYPES.CREATE_RESPONSE,
		"response_data" : response_data
	}
	return action
func create_action_delete_response(node_index : int) -> Dictionary:
	var action = {
		"type" : ACTION_TYPES.DELETE_RESPONSE,
		"node_index" : node_index
	}
	return action
func create_action_move_response(node_index : int, prev_position : Vector2) -> Dictionary:
	var action = {
		"type" : ACTION_TYPES.MOVE_RESPONSE,
		"node_index" : node_index,
		"prev_position" : prev_position
	}
	return action

func create_action_swap_responses(original_index,overlap_index,from,to):
	var action = {
		"type" : ACTION_TYPES.SWAP_RESPONSES,
		"original_index" : original_index,
		"overlap_index" : overlap_index,
		"from" : from,
		"to" : to
	}
	return action

#Color Organizers
func create_action_add_color_organizer(color_org_data : Dictionary) -> Dictionary:
	var action = {
		"type" : ACTION_TYPES.CREATE_COLOR_ORG,
		"color_org_data" : color_org_data
	}
	return action
func create_action_delete_color_organizer(node_index : int) -> Dictionary:
	var action = {
		"type" : ACTION_TYPES.DELETE_COLOR_ORG,
		"node_index" : node_index
	}
	return action
func create_action_move_color_organizer(node_index: int, prev_position : Vector2):
	var action = {
		"type" : ACTION_TYPES.MOVE_COLOR_ORG,
		"node_index" : node_index,
		"prev_position" : prev_position
	}
	return action
	
	
func create_action_move_multiple_nodes(dialogs,responses,color_organizers):
	var action = {
		"type" : ACTION_TYPES.MULTI_MOVE,
		"dialogs" : dialogs,
		"responses" : responses,
		"color_organizers" : color_organizers
	}
	return action

func create_action_create_multiple_nodes(dialogs,responses,color_organizers):
	var dialogs_data = []
	var responses_data = []
	var color_organizers_data = []
	for dialog in dialogs:
		dialogs_data.append(dialog_editor.current_dialog_index_map[dialog].save())
	for response in responses:
		responses_data.append(dialog_editor.current_response_index_map[response].save())
	for col_org in color_organizers:
		color_organizers_data.append(dialog_editor.current_color_organizer_index_map[col_org].save())
	var action = {
		"type" : ACTION_TYPES.MULTI_CREATE,
		"dialog_data" : dialogs_data,
		"response_data" : responses_data,
		"color_organizer_data" : color_organizers_data
	}
	return action
	
func  create_action_delete_multiple_nodes(dialogs,responses,color_organizers):
	var dialogs_index = []
	var responses_index = []
	var color_organizers_index = []
	
	
	
	for dialog in dialogs:
		if dialog is Dictionary:
			dialogs_index.append(dialog.node_index)
		else:
			dialogs_index.append(dialog)
	for response in responses:
		if response is Dictionary:
			responses_index.append(response.node_index)
		else:
			responses_index.append(response)
	for color_org in color_organizers:
		if color_org is Dictionary:
			color_organizers_index.append(color_org.node_index)
		else:
			color_organizers_index.append(color_org)
	var action = {
		"type" : ACTION_TYPES.MULTI_DELETE,
		"dialogs" : dialogs_index,
		"responses" : responses_index,
		"color_organizers" : color_organizers_index
	}
	return action
	



#Special function because it needs to loop through multiple nodes	
func create_redo_action_move_multiple_nodes(dialogs : Dictionary,responses : Dictionary,color_organizers : Dictionary):
	var redo_dialogs = {}
	var redo_responses = {}
	var redo_color_orgs = {}
	for dialog in dialogs.keys():
		redo_dialogs[dialog] = dialog_editor.current_dialog_index_map[dialog].position_offset
	for response in responses.keys():
		redo_responses[response] = dialog_editor.current_response_index_map[response].position_offset
	for color_org in color_organizers.keys():
		redo_color_orgs[color_org] = dialog_editor.current_color_organizer_index_map[color_org].position_offset
	var action = {
		"type" : ACTION_TYPES.MULTI_MOVE,
		"dialogs" : redo_dialogs,
		"responses" : redo_responses,
		"color_organizers" : redo_color_orgs
	}
	return action

func create_action_connect_nodes(dialog_index,response_index):
	var action = {
		"type" : ACTION_TYPES.CONNECT_NODES,
		"dialog_index" : dialog_index,
		"response_index" : response_index,
	}
	return action
func create_action_disconnect_nodes(dialog_index,response_index):
	var action = {
		"type" : ACTION_TYPES.DISCONNECT_NODES,
		"dialog_index" : dialog_index,
		"response_index" : response_index,
	}
	return action

##Execute Actions##
#These actually execute the necessary code to enact an undo/redo

#Dialog
func execute_action_add_dialog(action):
	var recreated_dialog = GlobalDeclarations.DIALOG_NODE.instantiate()
	var node_data = action.dialog_data
	recreated_dialog.position_offset = Vector2(node_data["position_offset.x"],node_data["position_offset.y"])
	for i in node_data.keys():
		if i == "position_offset.x" or i == "position_offset.y" or i == "filename" or i == "quest_availabilities" or i == "dialog_availabilities" or i == "faction_availabilities" or i == "scoreboard_availabilities" or i == "faction_changes" or i == "response_options" or i == "mail":
			continue
		recreated_dialog.set(i, node_data[i])
	recreated_dialog.time_availability = node_data["time_availability"]
	recreated_dialog.min_level_availability = node_data["min_level_availability"]
	for i in 4:
		recreated_dialog.quest_availabilities[i].set_id(node_data["quest_availabilities"][i].quest_id)
		recreated_dialog.quest_availabilities[i].set_availability(node_data["quest_availabilities"][i].availability_type)
		recreated_dialog.dialog_availabilities[i].set_id(node_data["dialog_availabilities"][i].dialog_id)
		recreated_dialog.dialog_availabilities[i].set_availability(node_data["dialog_availabilities"][i].availability_type)
		
	for i in 2:
		recreated_dialog.faction_availabilities[i].set_id(node_data["faction_availabilities"][i].faction_id)
		recreated_dialog.faction_availabilities[i].set_stance(node_data["faction_availabilities"][i].stance_type)
		recreated_dialog.faction_availabilities[i].set_operator(node_data["faction_availabilities"][i].availability_operator)
		
		recreated_dialog.faction_changes[i].set_id(node_data["faction_changes"][i].faction_id)
		recreated_dialog.faction_changes[i].set_points(node_data["faction_changes"][i].points)
		
		recreated_dialog.scoreboard_availabilities[i].set_objective_name(node_data["scoreboard_availabilities"][i].objective_name)
		recreated_dialog.scoreboard_availabilities[i].set_comparison_type(node_data["scoreboard_availabilities"][i].comparison_type)
		recreated_dialog.scoreboard_availabilities[i].set_value(node_data["scoreboard_availabilities"][i].value)
	recreated_dialog.mail.sender = node_data["mail"].sender
	recreated_dialog.mail.subject = node_data["mail"].subject
	recreated_dialog.mail.items_slots = JSON.parse_string(node_data["mail"].items)
	recreated_dialog.mail.pages = JSON.parse_string(node_data["mail"].pages) as Array[String]
	recreated_dialog.mail.quest_id = node_data["mail"].quest_id
	emit_signal("request_action_add_dialog_node",recreated_dialog,true,false)
	for response_data in node_data["response_options"]:
		var recreated_response = create_response_node_from_data(response_data)
		emit_signal("request_add_response",recreated_dialog,recreated_response,false)
		var connected_dialog
		if recreated_response.to_dialog_id != -1:
			connected_dialog = find_dialog_node_from_id(recreated_response.to_dialog_id)
		
		if recreated_response.to_dialog_id > 0 && connected_dialog != null:
			emit_signal("request_connect_nodes",recreated_response,0,connected_dialog,0,false)
	for response_index in node_data["connected_response_indexes"]:
		if dialog_editor.current_response_index_map.has(response_index):
			emit_signal("request_connect_nodes",dialog_editor.current_response_index_map[response_index],0,recreated_dialog,0,false)
		else:
			dialogs_that_need_to_be_connected[recreated_dialog.node_index] = node_data["connected_response_indexes"]

var dialogs_that_need_to_be_connected = {}

func execute_action_delete_dialog(action):
	emit_signal("request_action_delete_dialog_node",dialog_editor.current_dialog_index_map[action.node_index],true,false)
		
func execute_action_move_dialog(action):
	emit_signal("request_action_move_dialog_node",action.node_index,action.prev_position)
	
#Responses
func execute_action_add_response(action : Dictionary):
	var recreated_response = create_response_node_from_data(action.response_data)
	var parent_dialog = find_dialog_node_from_id(action.response_data["parent_dialog_id"])
	request_action_add_response_node.emit(parent_dialog,recreated_response,false)
	var connected_dialog
	if recreated_response.to_dialog_id != -1:
		connected_dialog = find_dialog_node_from_id(recreated_response.to_dialog_id)
		
	if recreated_response.to_dialog_id > 0 && connected_dialog != null:
		emit_signal("request_connect_nodes",recreated_response,0,connected_dialog,0,false)	
	for dialog in dialogs_that_need_to_be_connected.keys():
		if recreated_response.node_index in dialogs_that_need_to_be_connected[dialog]:
			emit_signal("request_connect_nodes",recreated_response,0,dialog_editor.current_dialog_index_map[dialog],0,false)	
			dialogs_that_need_to_be_connected[dialog].erase(recreated_response.node_index)
			if dialogs_that_need_to_be_connected[dialog].is_empty():
				dialogs_that_need_to_be_connected.erase(dialog)

func execute_action_delete_response(action):
	emit_signal("request_action_delete_response_node",dialog_editor.current_response_index_map[action.node_index].parent_dialog,dialog_editor.current_response_index_map[action.node_index],false)	

func execute_action_move_response(action):
	emit_signal("request_action_move_response_node",action.node_index,action.prev_position)
	
func execute_action_swap_response(action):
	var original_response = dialog_editor.current_response_index_map[action.original_index]
	var overlapping_response = dialog_editor.current_response_index_map[action.overlap_index]
	
	emit_signal("request_action_swap_response_nodes",original_response,overlapping_response,action.from,action.to,false)
#Color Organizers
func execute_action_add_color_organizer(action: Dictionary):
	var node_data = action.color_org_data
	var recreated_color_organizer : ColorOrganizer = GlobalDeclarations.COLOR_ORGANIZER.instantiate()
	recreated_color_organizer.initial_offset = Vector2(node_data["position_offset.x"],node_data["position_offset.y"])
	recreated_color_organizer.box_color  = GlobalDeclarations.int_to_color(node_data["color"])
	recreated_color_organizer.custom_minimum_size = Vector2(node_data["min_size_x"],node_data["min_size_y"])
	recreated_color_organizer.text = node_data["text"]
	if node_data.has("locked"):
		recreated_color_organizer.locked = bool(node_data["locked"])
	emit_signal("request_action_add_color_organizer",recreated_color_organizer,true,false)

func execute_action_delete_color_organizer(action):
	emit_signal("request_action_delete_color_organizer",dialog_editor.current_color_organizer_index_map[action.node_index],false)

func execute_action_move_color_organizer(action):
	emit_signal("request_action_move_color_organizer",action.node_index,action.prev_position)

func execute_action_add_multiple_nodes(action):
	for dialog in action.dialog_data:
		execute_action_add_dialog({"dialog_data":dialog})
		print(action.dialog_data)
	for response in action.response_data:
		execute_action_add_response({"response_data":response})
	for color_org in action.color_organizer_data:
		execute_action_add_color_organizer({"color_org_data":color_org})

func execute_action_delete_multiple_nodes(action):
	for dialog in action.dialogs:
		emit_signal("request_action_delete_dialog_node",dialog_editor.current_dialog_index_map[dialog],true,false)
	for response in action.responses:
		print(dialog_editor.current_response_index_map)
		emit_signal("request_action_delete_response_node",dialog_editor.current_response_index_map[response].parent_dialog,dialog_editor.current_response_index_map[response],false)
	for col_org in action.color_organizers:
		emit_signal("request_action_delete_color_organizer",dialog_editor.current_color_organizer_index_map[col_org],false)

func execute_action_multi_move(action):
	for dialog in action.dialogs:
		emit_signal("request_action_move_dialog_node",dialog,action.dialogs[dialog])
	for response in action.responses:
		emit_signal("request_action_move_response_node",response,action.responses[response])
	for color_org in action.color_organizers:
		emit_signal("request_action_move_color_organizer",color_org,action.color_organizers[color_org])


func execute_action_connect_nodes(dialog_index,response_index):
	emit_signal("request_action_connect_nodes",dialog_editor.current_response_index_map[response_index],0,dialog_editor.current_dialog_index_map[dialog_index],0,false)

func execute_action_disconnect_nodes(dialog_index,response_index):
	emit_signal("request_action_disconnect_nodes",dialog_editor.current_response_index_map[response_index],0,dialog_editor.current_dialog_index_map[dialog_index],0,false)


#Isolated Useful Methods		
func create_response_node_from_data(response_data):
	var currently_loaded_response ResponseNode = GlobalDeclarations.RESPONSE_NODE.instantiate()
	currently_loaded_response.slot = response_data["slot"]
	currently_loaded_response.color_decimal = response_data["color_decimal"]
	currently_loaded_response.to_dialog_id = response_data["to_dialog_id"]
	currently_loaded_response.command = response_data["command"]
	currently_loaded_response.set_option_from_index(response_data.option_type)
	currently_loaded_response.response_title = response_data["response_title"]
	currently_loaded_response.position_offset = Vector2(response_data["position_offset_x"],response_data["position_offset_y"])
	return currently_loaded_response

func find_dialog_node_from_id(id : int):
	var dialog_nodes = get_tree().get_nodes_in_group("Dialogs")
	for dialog in dialog_nodes:
		if dialog.dialog_id == id:
			return dialog
	return null
			




func _on_category_panel_category_loading_initiated(_ignore):
	ignore_all_changes = true

func _on_dialog_editor_dialog_node_added(dialog):
	add_to_undo(ACTION_TYPES.DELETE_DIALOG,dialog)

func _on_dialog_editor_dialog_moved(dialog,from):
	add_to_undo(ACTION_TYPES.MOVE_DIALOG,dialog,[from])

func _on_dialog_editor_dialog_node_deleted(dialog_data):
	add_to_undo(ACTION_TYPES.CREATE_DIALOG,dialog_data)


func _on_dialog_editor_response_moved(response,from):
	add_to_undo(ACTION_TYPES.MOVE_RESPONSE,response,[from])


func _on_dialog_editor_response_node_added(response):
	add_to_undo(ACTION_TYPES.DELETE_RESPONSE,response)


func _on_dialog_editor_response_node_deleted(response_data):
	add_to_undo(ACTION_TYPES.CREATE_RESPONSE,response_data)


func _on_dialog_editor_color_organizer_added(col_org):
	add_to_undo(ACTION_TYPES.DELETE_COLOR_ORG,col_org)



func _on_dialog_editor_color_organizer_deleted(col_org_data):
	add_to_undo(ACTION_TYPES.CREATE_COLOR_ORG,col_org_data)


func _on_dialog_editor_color_organizer_moved(col_org,from):
	add_to_undo(ACTION_TYPES.MOVE_COLOR_ORG,col_org,[from])


func _on_dialog_editor_multiple_nodes_moved(dialogs,responses,color_organizers):
	add_to_undo(ACTION_TYPES.MULTI_MOVE,null,[dialogs,responses,color_organizers])


func _on_dialog_editor_multiple_nodes_deleted(dialogs,responses,color_organizers):
	var dialogs_data = []
	var responses_data = []
	var color_organizers_data = []
	for dialog in dialogs:
		dialogs_data.append(dialog.node_index)
	for response in responses:
		if !response.parent_dialog in dialogs:
			responses_data.append(response.node_index)
	for col_org in color_organizers:
		color_organizers_data.append(col_org.node_index)
	add_to_undo(ACTION_TYPES.MULTI_CREATE,null,[dialogs_data,responses_data,color_organizers_data])


func _on_dialog_editor_multiple_nodes_created(dialogs,responses):
	add_to_undo(ACTION_TYPES.MULTI_DELETE,null,[dialogs,responses,[]])


func _on_dialog_editor_nodes_connected(from,to):
	var dialog_index
	var response_index
	if from.node_type == "Dialog Node":
		dialog_index = from.node_index
		response_index = to.node_index
	else:
		dialog_index = to.node_index
		response_index = from.node_index
	add_to_undo(ACTION_TYPES.DISCONNECT_NODES,null,[dialog_index,response_index])


func _on_dialog_editor_nodes_disconnected(from,to):
	var dialog_index
	var response_index
	if from.node_type == "Dialog Node":
		dialog_index = from.node_index
		response_index = to.node_index
	else:
		dialog_index = to.node_index
		response_index = from.node_index
	add_to_undo(ACTION_TYPES.CONNECT_NODES,null,[dialog_index,response_index])


func _on_dialog_editor_response_nodes_swapped(original,overlap,from,to):
	add_to_undo(ACTION_TYPES.SWAP_RESPONSES,null,[original.node_index,overlap.node_index,from,to])


func _on_dialog_file_system_index_category_deleted(category_name):
	undoRedoHistories.erase(category_name)


func _on_dialog_file_system_index_category_renamed(old_name,new_name):
	undoRedoHistories.erase(old_name)
