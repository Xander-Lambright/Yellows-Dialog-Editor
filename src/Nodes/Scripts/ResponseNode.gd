class_name response_node
extends GraphNode

@export var _response_text_node_path: NodePath
@export var _color_picker_node_path: NodePath
@export var _option_type_node_path: NodePath
@export var _command_text_node_path: NodePath
@export var _new_dialog_button_path: NodePath
@export var _remote_connection_container_path: NodePath
@export var _remote_connection_text_path: NodePath
@export var _remote_connection_disconnect_button_path: NodePath
@export var _remote_connection_jump_button_path: NodePath

@onready var ResponseTextNode := get_node(_response_text_node_path)
@onready var ColorPickerNode := get_node(_color_picker_node_path)
@onready var OptionTypeNode := get_node(_option_type_node_path)
@onready var CommandTextNode := get_node(_command_text_node_path)
@onready var NewDialogButtonNode := get_node(_new_dialog_button_path)
@onready var RemoteConnectionContainer := get_node(_remote_connection_container_path)
@onready var RemoteConnectionText := get_node(_remote_connection_text_path)
@onready var RemoteConnectionDisconnectButton := get_node(_remote_connection_disconnect_button_path)
@onready var RemoteConnectionJumpButton := get_node(_remote_connection_jump_button_path)




signal set_self_as_selected
signal request_delete_self
signal connect_to_dialog_request
signal disconnect_from_dialog_request
signal request_connection_line_shown
signal request_connection_line_hidden
signal request_add_dialog
signal request_set_scroll_offset
signal response_double_clicked
signal unsaved_change


var node_type : String = "Player Response Node"

var slot : int = -1: set = set_response_slot


var response_title : String = ''
var color_decimal :int = 16777215: set = set_color_decimal
var command :String = '': set = set_meta_pressed
var connected_dialog : dialog_node = null: set = set_connected_dialog
var to_dialog_id = -1: set = set_to_dialog_id
var option_type = 0: set = set_option_type

var parent_dialog : dialog_node

var total_height : int

var connection_hidden := false
var overlapping_response : response_node = null


func _ready():
	ColorPickerNode.color = GlobalDeclarations.int_to_color(color_decimal)
	#set_slot(1,true,GlobalDeclarations.CONNECTION_TYPES.PORT_INTO_RESPONSE,GlobalDeclarations.response_left_slot_color,true,GlobalDeclarations.CONNECTION_TYPES.PORT_FROM_RESPONSE,GlobalDeclarations.response_right_slot_color)
	$HBoxContainer/VBoxContainer/OptionTypeButton.select(option_type)
	ResponseTextNode.text = response_title

func get_option_id_from_index(index : int):
	return $HBoxContainer/VBoxContainer/OptionTypeButton.get_item_id(index)


func set_option_from_json_index(option_int : int):
	if not is_inside_tree(): await self.ready
	set_option_type(OptionTypeNode.get_item_index(option_int))

func set_focus_on_title():
	if not is_inside_tree(): await self.ready
	ResponseTextNode.grab_focus()
	emit_signal("set_self_as_selected",self)
	emit_signal("request_set_scroll_offset",position_offset)

func set_response_slot(value : int):
	slot = value
	title = "Response Option "+str(value+1) 
	emit_signal("unsaved_change")
	

func set_option_type(new_type : int):
	option_type = new_type
	if not is_inside_tree(): await self.ready
	if new_type == 2:
		CommandTextNode.visible = true
	else:
		CommandTextNode.visible = false
		size.y = 215
	if new_type == 0:
		reveal_button()
		set_slot_enabled_right(1,true)
	else:
		hide_button()
		set_slot_enabled_right(1,false)
		if connected_dialog != null:
			emit_signal("disconnect_from_dialog_request",self,0,connected_dialog,0)
	emit_signal("unsaved_change")
	
func set_color_decimal(new_color : int):
	color_decimal = new_color
	emit_signal("unsaved_change")

func set_meta_pressed(new_command : String):
	command = new_command
	if not is_inside_tree(): await self.ready
	CommandTextNode.text = new_command
	emit_signal("unsaved_change")

func set_connected_dialog(new_connected_dialog : dialog_node):
	connected_dialog = new_connected_dialog
	if not is_inside_tree(): await self.ready
	if connected_dialog != null:
		hide_button()
		update_connection_text()
		check_dialog_distance()
		to_dialog_id = connected_dialog.dialog_id
	else:
		reveal_button()


func set_to_dialog_id(new_id : int):
	to_dialog_id = new_id

func set_connection_text(dialog_name : String,dialog_node_index: int):
	if not is_inside_tree(): await self.ready
	RemoteConnectionText.text = "Connected to "+dialog_name+" | Node "+str(dialog_node_index)
	
func reveal_button():
	if option_type == 0:
		NewDialogButtonNode.modulate = Color(1,1,1,1)

	
func hide_button():
	NewDialogButtonNode.modulate = Color(1,1,1,0)
	

func update_connection_text():
	if connected_dialog != null:
		var format_string := "Connected to %s | Node "+str(connected_dialog.node_index)
		RemoteConnectionText.text = format_string % connected_dialog.dialog_title.left(10)

func check_dialog_distance():
	if connected_dialog != null:
		if position_offset.distance_to(connected_dialog.position_offset) > GlobalDeclarations.hide_connection_distance && !connection_hidden:
			set_connection_hidden()	
		if position_offset.distance_to(connected_dialog.position_offset) < GlobalDeclarations.hide_connection_distance && connection_hidden:
			set_connection_shown()

func set_connection_hidden():
	emit_signal("request_connection_line_hidden",self,connected_dialog)
	connection_hidden = true
	RemoteConnectionContainer.visible = true
	set_slot_color_right(0,GlobalDeclarations.response_right_slot_color_hidden)
	set_slot_enabled_right(1,false)
	connected_dialog.set_slot_color_left(0,GlobalDeclarations.dialog_left_slot_color_hidden)
	update_connection_text()

func set_connection_shown():
	emit_signal("request_connection_line_shown",self,connected_dialog)
	connection_hidden = false
	set_slot_color_right(0,GlobalDeclarations.response_right_slot_color)
	connected_dialog.set_slot_color_left(0,GlobalDeclarations.dialog_left_slot_color)
	set_slot_enabled_right(1,true)
	RemoteConnectionContainer.visible = false
	

func disconnect_from_dialog():
	connected_dialog.remove_connected_response(self)
	emit_signal("disconnect_from_dialog_request",self,0,connected_dialog,0)
	connected_dialog = null
	to_dialog_id = -1
	RemoteConnectionContainer.visible = false

func delete_self():
	if(connected_dialog != null):
		connected_dialog.remove_connected_response(self)
	emit_signal("request_delete_self",slot,self)
	




func _on_PlayerResponseNode_gui_input(event):
	if event is InputEventMouseButton and event.double_click:
		emit_signal("response_double_clicked")


func _on_PlayerResponseNode_close_request():
	delete_self()
	

func _on_AddNewDialog_pressed():
	add_new_connected_dialog()

func add_new_connected_dialog():
	if option_type != 0:
		return
	var new_dialog : dialog_node = GlobalDeclarations.DIALOG_NODE.instantiate()
	new_dialog.position_offset = position_offset + Vector2(GlobalDeclarations.DIALOG_NODE_HORIZONTAL_OFFSET,0)
	if ResponseTextNode.text != '':
		new_dialog.dialog_title = ResponseTextNode.text
	connected_dialog = new_dialog
	new_dialog.connected_responses.append(self)
	emit_signal("request_add_dialog",new_dialog,true)
	emit_signal("connect_to_dialog_request",self,0,connected_dialog,0)

func _on_OptionButton_item_selected(index : int):
	set_option_type(index)


func _on_ColorPickerButton_color_changed(color : Color):
	var colorHex = "0x"+String(color.to_html(false))
	color_decimal = colorHex.hex_to_int()
	


func _on_ResponseText_text_changed(new_text : String):
	response_title = ResponseTextNode.text
	emit_signal("unsaved_change")

func _on_CommandText_text_changed():
	command = CommandTextNode.text
	emit_signal("unsaved_change")


func _on_DisconnectButton_pressed():
	disconnect_from_dialog()


func _on_JumpButton_pressed():
	var dialog_location = connected_dialog.position_offset
	emit_signal("request_set_scroll_offset",dialog_location)
	connected_dialog.emit_signal("set_self_as_selected",connected_dialog)


func _on_ResponseNodeArea_area_entered(area : Area2D):
	overlapping_response = area.get_parent()
	

func _on_ResponseNodeArea_area_exited(_area : Area2D):
	if !$ResponseNodeArea.get_overlapping_areas().is_empty():
		overlapping_response = $ResponseNodeArea.get_overlapping_areas().back().get_parent()
	else:
		overlapping_response = null


func _on_PlayerResponseNode_offset_changed():
	check_dialog_distance()
	
	
func get_full_tree(all_children : Array = []) -> Array:
	if connected_dialog != null and connected_dialog.original_parent == self:
		all_children.append(connected_dialog)
		all_children = connected_dialog.get_full_tree(all_children)
	return all_children


