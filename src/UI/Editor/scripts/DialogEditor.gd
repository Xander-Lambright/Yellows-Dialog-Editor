extends GraphEdit

class_name DialogGraphEdit

signal no_dialog_selected
signal dialog_selected
signal editor_cleared
signal finished_loading

signal request_save
signal import_category_canceled

signal dialog_node_added
signal dialog_node_deleted

signal request_add_dialog_to_environment_index
signal request_remove_dialog_from_environment_index

signal response_node_added
signal response_node_deleted
signal response_nodes_swapped

signal color_organizer_added
signal color_organizer_deleted

signal dialog_moved
signal response_moved
signal color_organizer_moved
signal multiple_nodes_created
signal multiple_nodes_moved
signal multiple_nodes_deleted

signal nodes_connected
signal nodes_disconnected

signal node_double_clicked
signal unsaved_changes
signal save_all

signal request_undo
signal request_redo

var node_index := 0
var response_node_index := 0
var color_organizer_node_index := 0

var selected_dialogs : Array[GraphNode]= []
var selected_responses :Array[GraphNode]= []
var selected_color_organizers :Array[GraphNode] = []
var previous_zoom := 1

var all_loaded_dialogs : Array[GraphNode]= []

var currentUndoRedo : UndoRedo
var allUndoRedos : Dictionary

var current_dialog_index_map = {}
var current_response_index_map = {}
var current_color_organizer_index_map = {}

var ignore_double_clicks := false

var multi_select_mouse_mode = false


func _ready():
	add_valid_connection_type(GlobalDeclarations.CONNECTION_TYPES.PORT_FROM_RESPONSE,GlobalDeclarations.CONNECTION_TYPES.PORT_INTO_DIALOG)
	add_valid_connection_type(GlobalDeclarations.CONNECTION_TYPES.PORT_INTO_RESPONSE,GlobalDeclarations.CONNECTION_TYPES.PORT_FROM_DIALOG)
	remove_valid_connection_type(GlobalDeclarations.CONNECTION_TYPES.PORT_FROM_DIALOG,GlobalDeclarations.CONNECTION_TYPES.PORT_INTO_RESPONSE)
	add_valid_left_disconnect_type(GlobalDeclarations.CONNECTION_TYPES.PORT_INTO_DIALOG)
	add_valid_right_disconnect_type(GlobalDeclarations.CONNECTION_TYPES.PORT_FROM_RESPONSE)
	set_process_input(false)



func delete_all_selected_nodes():
	var deleted_dialogs = selected_dialogs.duplicate()
	var deleted_responses = selected_responses.duplicate()
	var deleted_color_organizers = selected_color_organizers.duplicate()
	emit_signal("multiple_nodes_deleted",deleted_dialogs,deleted_responses,deleted_color_organizers)
	CurrentEnvironment.handle_subtracting_dialog_id(selected_dialogs)
	for i in deleted_responses:
		if selected_dialogs.has(i.parent_dialog):
			continue
		i.delete_self(false)	
	for i in deleted_dialogs:
		i.delete_self(true,false)
	for i in deleted_color_organizers:
		delete_color_organizer(i,false)
		
		



func add_dialog_node(new_dialog : DialogNode = GlobalDeclarations.DIALOG_NODE.instantiate(), use_exact_offset : bool = false,commit_to_undo := true) -> DialogNode:
	#Adds a new dialog node into the editor.
	if new_dialog.node_index == -1:
		new_dialog.node_index = node_index
	node_index += 1
	if new_dialog.dialog_id == -1:
		CurrentEnvironment.highest_id += 1
		new_dialog.dialog_id = CurrentEnvironment.highest_id
		
		
	if new_dialog.position_offset == Vector2.ZERO:
		new_dialog.position_offset = get_window().size/3
	if !use_exact_offset: 
		#Adjust the offset so that it's relative to the current position of the graph's view.
		new_dialog.position_offset = (new_dialog.position_offset+scroll_offset)/zoom	
	new_dialog.connect("add_response_request", Callable(self, "add_response_node"))
	new_dialog.connect("request_delete_response_node", Callable(self, "delete_response_node"))
	new_dialog.connect("request_deletion", Callable(self, "delete_dialog_node"))
	new_dialog.connect("set_self_as_selected", Callable(self, "select_node"))
	new_dialog.connect("node_double_clicked", Callable(self, "handle_double_click").bind(new_dialog))
	new_dialog.connect("position_offset_changed",Callable(self,"relay_unsaved_changes"))

	new_dialog.connect("request_set_scroll_offset", Callable(self, "set_scroll_offset"))
	new_dialog.connect("unsaved_changes", Callable(self, "relay_unsaved_changes"))
	emit_signal("request_add_dialog_to_environment_index",new_dialog)
	if commit_to_undo:
		emit_signal("dialog_node_added",new_dialog)
	current_dialog_index_map[new_dialog.node_index] = new_dialog
	add_child(new_dialog)
	return new_dialog

func relay_unsaved_changes():
	emit_signal("unsaved_changes",CurrentEnvironment.current_category_name)

func delete_dialog_node(dialog : DialogNode,remove_from_global_index := false,commit_to_undo := true):
	if commit_to_undo && selected_dialogs.size() < 2:
		dialog_node_deleted.emit(dialog.save())
	if selected_dialogs.find(dialog,0) != -1:
		selected_dialogs.erase(dialog)
	set_last_selected_node_as_selected()
	if remove_from_global_index:
		emit_signal("request_remove_dialog_from_environment_index",dialog.dialog_id)
		CurrentEnvironment.handle_subtracting_dialog_id([dialog])
	dialog.delete_response_options()
	current_dialog_index_map.erase(dialog.node_index)
	dialog.queue_free()
	relay_unsaved_changes()
	node_index -=1
	

	

func add_response_node(parent_dialog : DialogNode, new_response : ResponseNode = GlobalDeclarations.RESPONSE_NODE.instantiate(),commit_to_undo := true) -> ResponseNode:
	
	var new_offset
	if new_response.node_index == -1:
		new_response.node_index = response_node_index
	response_node_index +=1
	if new_response.position_offset!=Vector2(0,0):
		new_offset = new_response.position_offset
	elif parent_dialog.response_options.size() == 0:
		new_offset = parent_dialog.position_offset +Vector2(400,0)
	else:
		new_offset = Vector2(parent_dialog.response_options[parent_dialog.response_options.size()-1].position_offset.x,parent_dialog.response_options[parent_dialog.response_options.size()-1].position_offset.y+300)
	parent_dialog.response_options.append(new_response)
	new_response.position_offset = new_offset
	new_response.slot = parent_dialog.response_options.size()-1
	new_response.parent_dialog = parent_dialog
	new_response.connect("request_delete_self", Callable(self, "delete_response_node"))
	new_response.connect("connect_to_dialog_request", Callable(self, "connect_nodes"))
	new_response.connect("disconnect_from_dialog_request", Callable(self, "disconnect_nodes"))
	new_response.connect("request_connection_line_shown", Callable(self, "show_connection_line"))
	new_response.connect("request_connection_line_hidden", Callable(self, "hide_connection_line"))
	new_response.connect("request_set_scroll_offset", Callable(self, "set_scroll_offset"))
	new_response.connect("request_add_dialog", Callable(self, "add_dialog_node"))
	new_response.connect("set_self_as_selected", Callable(self, "select_node"))
	new_response.connect("dragged", Callable(self, "response_node_dragged").bind(new_response))
	new_response.connect("response_double_clicked", Callable(self, "handle_double_click").bind(new_response))
	new_response.connect("position_offset_changed",Callable(self,"relay_unsaved_changes"))
	new_response.connect("unsaved_change",Callable(self,"relay_unsaved_changes"))
	add_child(new_response)
	current_response_index_map[new_response.node_index] = new_response
	connect_node(parent_dialog.get_name(),0,new_response.get_name(),0)
	relay_unsaved_changes()
	if commit_to_undo:
		emit_signal("response_node_added",new_response)
	return new_response

func delete_response_node(dialog : DialogNode,response : ResponseNode, commit_to_undo := true):

	if commit_to_undo:
		emit_signal("response_node_deleted",response.save())
	dialog.delete_response_node(response.slot,response)
	disconnect_node(dialog.get_name(),0,response.get_name(),0)
	if response.connected_dialog != null:
		disconnect_node(response.get_name(),0,response.connected_dialog.get_name(),0)
		response.connected_dialog.remove_connected_response(response)
		response.connected_dialog = null
	if selected_responses.find(response) != -1:
		selected_responses.erase(response)
	response.queue_free()
	current_response_index_map.erase(response.node_index)
	relay_unsaved_changes()
	response_node_index -=1
	

var color_organizers = [] #Used to fix a bug where color organizers are made last, so dont allow mouse through them

func add_color_organizer(col_org :ColorOrganizer= GlobalDeclarations.COLOR_ORGANIZER.instantiate(), use_exact_offset : bool = false,commit_to_undo := true):
	if col_org.node_index == -1:
		col_org.node_index = color_organizer_node_index
	color_organizer_node_index += 1

	current_color_organizer_index_map[col_org.node_index] = col_org
	col_org.position_offset = col_org.initial_offset
	if col_org.initial_offset == Vector2.ZERO:
		col_org.position_offset = get_window().size/3
	if !use_exact_offset:
		col_org.position_offset = (col_org.position_offset+scroll_offset)/zoom
	add_child(col_org)
	color_organizers.append(col_org)
	if commit_to_undo:
		color_organizer_added.emit(col_org)
	
func delete_color_organizer(col_org : ColorOrganizer,commit_to_undo := true):
	current_color_organizer_index_map.erase(col_org.node_index)
	if commit_to_undo:
		color_organizer_deleted.emit(col_org.save())
	col_org.queue_free()
	color_organizer_node_index -= 1
	if selected_color_organizers.find(col_org) != -1:
		selected_color_organizers.erase(col_org)
	
	

func response_node_dragged(from: Vector2,to : Vector2,response_node):
	print(response_node.overlapping_response)
	if selected_dialogs.size() == 0 && Input.is_action_pressed("swap_responses") && response_node.overlapping_response != null:
		handle_swapping_responses(response_node,response_node.overlapping_response,from,to)
		
var multi_drag_started = false
var already_emitted_multi_drag = false
var dialog_multi_drag_start_positions = {}
var response_multi_drag_start_positions = {}	
var color_organizer_multi_drag_start_position = {}	

func handle_multi_drag_undo_signal(count_responses):
	for dialog in selected_dialogs:
		dialog_multi_drag_start_positions[dialog.node_index] = dialog.position_offset
		for option in dialog.response_options:
			response_multi_drag_start_positions[option.node_index] = option.position_offset
	for response in selected_responses:
		if !response_multi_drag_start_positions.has(response.node_index):
			response_multi_drag_start_positions[response.node_index] = response.position_offset
	for color_org in selected_color_organizers:
		color_organizer_multi_drag_start_position[color_org.node_index] = color_org.position_offset

	
func _on_begin_node_move():
	var count_responses :bool = (GlobalDeclarations.hold_shift_for_individual_movement != Input.is_action_pressed("drag_responses_key"))
	handle_multi_drag_undo_signal(count_responses)
	multi_drag_started = false
	emit_signal("multiple_nodes_moved",dialog_multi_drag_start_positions,response_multi_drag_start_positions,color_organizer_multi_drag_start_position)
	dialog_multi_drag_start_positions = {}
	response_multi_drag_start_positions = {}	
	color_organizer_multi_drag_start_position = {}

func connect_nodes(from : GraphNode, from_slot : int, to: GraphNode, to_slot : int,commit_to_undo := true):
	
	var response : ResponseNode
	var dialog : DialogNode
	if from.node_type == "Player Response Node":
		response = from
		dialog = to
	else:
		response = to
		dialog = from
	if response.connected_dialog != null:
		disconnect_node(response.get_name(),from_slot,response.connected_dialog.get_name(),to_slot)
	response.connected_dialog = dialog
	if response.position_offset.distance_to(dialog.position_offset) < GlobalDeclarations.hide_connection_distance:
		connect_node(from.get_name(),from_slot,to.get_name(),to_slot)
	dialog.add_connected_response(response)
	relay_unsaved_changes()
	if commit_to_undo:
		emit_signal("nodes_connected",from,to)

	
func disconnect_nodes(from: GraphNode, from_slot : int, to: GraphNode, to_slot : int, commit_to_undo := true):
	
	var response : ResponseNode
	var dialog : DialogNode
	
	if from.node_type == "Player Response Node":
		response = from
		dialog = to
	else:
		response = to
		dialog = from
	
	if response.connected_dialog == dialog:
		response.set_connection_shown()
		disconnect_node(from.get_name(),from_slot,to.get_name(),to_slot)
		dialog.remove_connected_response(response)
		response.reveal_button()	
		response.connected_dialog = null	
	relay_unsaved_changes()
	if commit_to_undo:
		emit_signal("nodes_disconnected",from,to)

func hide_connection_line(from: GraphNode,to: GraphNode):
	disconnect_node(from.name,0,to.name,0)

func show_connection_line(from: GraphNode,to: GraphNode):
	connect_node(from.name,0,to.name,0)


func handle_swapping_responses(response_node : ResponseNode ,overlapping_response : ResponseNode,from : Vector2 ,to: Vector2,commit_to_undo := true):
		var initial_slot := response_node.slot
		var initial_parent := response_node.parent_dialog
		var initial_offset := from
		
		#Switch Slots
		response_node.slot = overlapping_response.slot
		overlapping_response.slot = initial_slot
	
		
		var tween := get_tree().create_tween()
		var initial_tween := get_tree().create_tween()
		tween.tween_property(response_node,"position_offset",overlapping_response.position_offset,.1).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
		initial_tween.tween_property(overlapping_response,"position_offset",from,.1).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
		
		#Remove from parents array
		response_node.parent_dialog.response_options.erase(response_node)
		disconnect_node(response_node.parent_dialog.get_name(),0,response_node.name,0)
		
		
		overlapping_response.parent_dialog.response_options.erase(overlapping_response)
		disconnect_node(overlapping_response.parent_dialog.get_name(),0,overlapping_response.get_name(),0)
		
		
		#Switch to other parents array. Make sure slot isn't invalid
		if response_node.parent_dialog.response_options.size() >= overlapping_response.slot:
			response_node.parent_dialog.response_options.insert(overlapping_response.slot,overlapping_response)
		else:
			response_node.parent_dialog.response_options.append(overlapping_response)
		connect_node(response_node.parent_dialog.get_name(),0,overlapping_response.get_name(),0)
		
		if overlapping_response.parent_dialog.response_options.size() >= response_node.slot:
			overlapping_response.parent_dialog.response_options.insert(response_node.slot,response_node)
		else:
			overlapping_response.parent_dialog.response_options.append(response_node)
		connect_node(overlapping_response.parent_dialog.get_name(),0,response_node.get_name(),0)
		
		#Switch Parents
		response_node.parent_dialog = overlapping_response.parent_dialog
		overlapping_response.parent_dialog = initial_parent
		
		if commit_to_undo:
			emit_signal("response_nodes_swapped",response_node,overlapping_response,from,to)
			
	
func set_category_zoom(new_zoom : float):
	zoom = new_zoom

func set_scroll_offset(new_offset : Vector2):
	var tween := get_tree().create_tween()
	tween.tween_property(self,"scroll_offset",(new_offset * zoom)-Vector2(get_window().size)/2,.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)


func set_last_selected_node_as_selected():
	if selected_dialogs.size() < 1:
		emit_signal("no_dialog_selected")
	else:
		if selected_dialogs.back().node_type == "Dialog Node":
			emit_signal("dialog_selected",selected_dialogs.back())

	
func save():
	return {
		"editor_offset.x" : scroll_offset.x,
		"editor_offset.y" : scroll_offset.y,
		"zoom" : zoom
	}	
	
func on_no_dialogs(category_name):
	clear_editor()
	emit_signal("finished_loading",category_name)
	visible = true

func scan_for_changes(category_name):
	var new_category_importer = category_importer.new()
	new_category_importer.connect("request_add_dialog", Callable(self, "add_dialog_node"))
	new_category_importer.connect("request_add_response", Callable(self, "add_response_node"))
	new_category_importer.connect("request_connect_nodes", Callable(self, "connect_nodes"))
	add_child(new_category_importer)
	new_category_importer.scan_category_for_changes(category_name)
	relay_unsaved_changes()
	
func import_canceled():
	visible = false
	CurrentEnvironment.current_category_name = null
	CurrentEnvironment.allow_save_state = false
	emit_signal("import_category_canceled")
	
		
func clear_editor():
	color_organizers = []
	selected_responses = []
	selected_dialogs = []
	var save_nodes = get_tree().get_nodes_in_group("Save")
	var response_nodes = get_tree().get_nodes_in_group("Response_Nodes")
	for i in save_nodes:
		i.delete_self(false)
		i.queue_free()
	for i in response_nodes:
		i.delete_self()
		i.queue_free()	
	node_index = 0
	response_node_index = 0
	emit_signal("editor_cleared")
	


func _on_DialogEditor_connection_request(from, from_slot, to, to_slot):
	connect_nodes(get_node(String(from)), from_slot, get_node(String(to)), to_slot)

func _on_DialogEditor_disconnection_request(from, from_slot, to, to_slot):
	disconnect_nodes(get_node(String(from)), from_slot, get_node(String(to)), to_slot)

func select_node(node):
	node.draggable = true
	if Input.is_action_pressed("select_multiple") || multi_select_mouse_mode:
		if !selected_responses.has(node) and node.node_type == "Player Response Node":
			selected_responses.append(node)
		if !selected_dialogs.has(node) and node.node_type == "Dialog Node" :
			selected_dialogs.append(node)
		if !selected_color_organizers.has(node) and node.node_type == "Color Organizer" :
			selected_color_organizers.append(node)
	else:
		if not (selected_dialogs.size() + selected_responses.size() + selected_color_organizers.size() > 1):
			for dialog in selected_dialogs:
				dialog.selected = false
			for response in selected_responses:
				response.selected = false
			for col_org in selected_color_organizers:
				col_org.selected = false
			selected_responses.clear()
			selected_dialogs.clear()
			selected_color_organizers.clear()
		if !selected_responses.has(node) and node.node_type == "Player Response Node":
			selected_responses.append(node)
				
		if !selected_dialogs.has(node) and node.node_type == "Dialog Node" :
			selected_dialogs.append(node)
		if !selected_color_organizers.has(node) and node.node_type == "Color Organizer" :
			selected_color_organizers.append(node)
	if node.node_type == "Dialog Node":
		emit_signal("dialog_selected",node)
		

func unselect_node(node):
	if node.node_type == "Player Response Node":
		selected_responses.erase(node)
	if node.node_type == "Color Organizer":
		selected_color_organizers.erase(node)
	if node.node_type == "Dialog Node":
		selected_dialogs.erase(node)
		set_last_selected_node_as_selected()
		if double_clicked:
			node.selected = true


var double_clicked = false

func handle_double_click(node):
	double_clicked = true
	multi_select_mouse_mode = true
	if node.node_type == "Dialog Node":
		if !ignore_double_clicks:
			for response in node.response_options:
				if !response.selected:
					response.selected = true
					#selected_responses.append(response)
					handle_double_click(response)
		else:
			node.selected = false
		emit_signal("node_double_clicked",node)
		
				
	if node.node_type == "Player Response Node":
		if !ignore_double_clicks:
			if node.connected_dialog != null and !node.connected_dialog.selected:
				if !node.connection_hidden:
					node.connected_dialog.selected = true
					handle_double_click(node.connected_dialog)
					node.connected_dialog.emit_signal("node_double_clicked")
					#selected_dialogs.append(node.connected_dialog)
	multi_select_mouse_mode = false
			


func _on_CategoryImporter_clear_editor_request():
	clear_editor()


func _on_SaveLoad_clear_editor_request():
	clear_editor()

func add_responses_and_dialogs_to_selected_nodes():
	var temp_dialog_node_index = node_index
	var temp_response_node_index = response_node_index
	var dialogs= []
	var responses = []
	for dialog in selected_dialogs:
		
		responses.append(temp_response_node_index)
		temp_response_node_index += 1
		dialog.add_response_node(false)
		
		
	for response in selected_responses:
		
		dialogs.append(temp_dialog_node_index)
		temp_dialog_node_index += 1
		
		response.add_new_connected_dialog(false) 
		
		
	emit_signal("multiple_nodes_created",dialogs,responses)

func handle_input(event : InputEvent):
	if event.is_action_pressed("add_dialog_at_mouse"):
		var new_dialog_node : DialogNode = GlobalDeclarations.DIALOG_NODE.instantiate()
		new_dialog_node.position_offset = get_local_mouse_position()
		add_dialog_node(new_dialog_node)
	if event.is_action_pressed("create_response"):
		add_responses_and_dialogs_to_selected_nodes()
		
	if Input.is_action_just_pressed("delete_nodes"):
		delete_all_selected_nodes()
	if event.is_action_pressed("focus_below"):
		match get_viewport().gui_get_focus_owner().get_name(): 
			"ResponseText":
				var response : ResponseNode = get_viewport().gui_get_focus_owner().get_parent().get_parent().get_parent()
				if response.slot != response.parent_dialog.response_options.size()-1:
					response.parent_dialog.response_options[response.slot+1].set_focus_on_title()
			"TitleText":
				var dialog : DialogNode= get_viewport().gui_get_focus_owner().get_parent().get_parent().get_parent()
				dialog.set_focus_on_text()	
	if Input.is_action_just_pressed("focus_above"):
		match get_viewport().gui_get_focus_owner().get_name(): 
			"ResponseText":
				var response : ResponseNode = get_viewport().gui_get_focus_owner().get_parent().get_parent().get_parent()
				if response.slot != 0:
					response.parent_dialog.response_options[response.slot-1].set_focus_on_title()
			"DialogText":
				var dialog : DialogNode = get_viewport().gui_get_focus_owner().get_parent().get_parent().get_parent()
				dialog.set_focus_on_title()
	if Input.is_action_just_pressed("focus_left"):
		
		if selected_responses.size() == 1 && selected_dialogs.size() == 0:
			var response : ResponseNode = selected_responses[0]
			if Input.is_action_pressed("focus_cycle"):
				
				var response_index : int = response.connected_dialog.connected_responses.find(response)
				var next_response_index = response_index
				print(next_response_index)
				if response_index == response.connected_dialog.connected_responses.size()-1:
					next_response_index = 0
				else:
					next_response_index += 1
				response.connected_dialog.connected_responses[next_response_index].set_focus_on_title()
			else:
				response.parent_dialog.set_focus_on_text()
		elif selected_responses.size() == 0 && selected_dialogs.size() == 1:
			var dialog : DialogNode= selected_dialogs[0]
			if dialog.connected_responses.size() != 0:
				dialog.connected_responses[0].set_focus_on_title()
	if Input.is_action_just_pressed("focus_right"):
	
		if selected_responses.size() == 1 && selected_dialogs.size() == 0:
			var response : ResponseNode = selected_responses[0]
			if response.connected_dialog == null:
				return
			if Input.is_action_pressed("focus_cycle"):
				var response_index : int = response.connected_dialog.connected_responses.find(response)
				var next_response_index = response_index
				if response_index == 0:
					next_response_index = response.connected_dialog.connected_responses.size()-1
				else:
					next_response_index -= 1
				response.connected_dialog.connected_responses[next_response_index].set_focus_on_title()
			else:
				response.connected_dialog.set_focus_on_text()
		elif selected_responses.size() == 0 && selected_dialogs.size() == 1:
			var dialog : DialogNode = selected_dialogs[0]
			if dialog.response_options.size() != 0:
				dialog.response_options[0].set_focus_on_title()

func _on_DialogEditor_gui_input(event):
	var undo_redo_delay = 0
	var undo_redo_started = false
	if Input.is_action_just_pressed("ui_undo") && not Input.is_action_pressed("ui_redo"):
		emit_signal("request_undo")
	if Input.is_action_just_pressed("ui_redo"):
		emit_signal("request_redo")
	if Input.is_action_just_released("ui_undo"):
		undo_redo_delay = 10
		undo_redo_started = false
	if Input.is_action_just_released("ui_redo"):
		undo_redo_delay = 10
		undo_redo_started = false
	if event is InputEventMouseMotion && Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		multi_select_mouse_mode = true
	if Input.is_action_just_released("drag"):
		multi_select_mouse_mode = false
	if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_WHEEL_UP:
		if !Input.is_action_pressed("zoom_key"):
			accept_event()
		else:
			zoom += .02
	if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		if !Input.is_action_pressed("zoom_key"):
			accept_event()
		else:
			zoom -= .02
	if Input.is_action_pressed("zoom_in"):
		zoom += 0.2
	if Input.is_action_pressed("zoom_out"):
		zoom -= 0.2
	if Input.is_key_pressed(KEY_CTRL):
		if Input.is_action_pressed("ui_left"):
			set_scroll_ofs(scroll_offset-Vector2(10,0))
		if Input.is_action_pressed("ui_right"):
			set_scroll_ofs(scroll_offset+Vector2(10,0))
		if Input.is_action_pressed("ui_up"):
			set_scroll_ofs(scroll_offset-Vector2(0,10))
		if Input.is_action_pressed("ui_down"):
			set_scroll_ofs(scroll_offset+Vector2(0,10))
	if Input.is_action_just_pressed("show_minimap"):	
		minimap_enabled = !minimap_enabled
	



func _on_CategoryPanel_current_category_deleted():
	clear_editor()
	visible = false



func _on_InformationPanel_availability_mode_entered() -> void:
	ignore_double_clicks = true


func _on_InformationPanel_availability_mode_exited() -> void:
	ignore_double_clicks = false

	
func reindex_ids():
	EnvironmentIndexer.new().find_highest_index(true)
	for child in get_children():
		if child is GraphNode && child.node_type == "Dialog Node":
			CurrentEnvironment.highest_id +=1
			child.set_dialog_id(CurrentEnvironment.highest_id) 


func _on_category_panel_request_dialog_ids_reassigned():
	reindex_ids()


func _on_autosave_timer_timeout():
	pass # Replace with function body.


func _on_editor_settings_snap_enabled_changed(value):
	use_snap = value


func _on_double_click_timer_timeout():
	double_clicked = false


func _on_undo_system_request_action_move_dialog_node(index : int, new_position : Vector2):
	current_dialog_index_map[index].position_offset = new_position
	current_dialog_index_map[index].do_not_send_position_changed_signal = true

func _on_undo_system_request_action_move_response_node(index: int, new_position : Vector2):
		current_response_index_map[index].position_offset = new_position
		current_response_index_map[index].do_not_send_position_changed_signal = true

func _on_undo_system_request_action_move_color_organizer(index: int, new_position : Vector2):
	current_color_organizer_index_map[index].position_offset = new_position
	current_response_index_map[index].do_not_send_position_changed_signal = true






