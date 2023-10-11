extends Node

signal dialog_title_changed
signal dialog_added_to_list

var all_loaded_dialogs := {}

func get_title_from_index(index : int) -> String:
	if index > all_loaded_dialogs.size() or index < 0:
		printerr("DIALOGLIST : Given Index is outside the range " + str(index))
		return "Unindexed Dialog"
	else:
		return all_loaded_dialogs[index]
		
func get_title_from_id(id : int) -> String:
	if all_loaded_dialogs.has(id):
		return all_loaded_dialogs.get(id)
	return "Unindexed Dialog"

func add_dialog_to_loaded(dialog : DialogNode):
	if all_loaded_dialogs.has(dialog.dialog_id):
		return
	all_loaded_dialogs[dialog.dialog_id] = dialog.dialog_title
	emit_signal("dialog_added_to_list")
	if !dialog.is_connected("title_changed", Callable(self, "update_changed_dialog_title")):
		dialog.connect("title_changed", Callable(self, "update_changed_dialog_title").bind(dialog))
	
	
			
func update_changed_dialog_title(dialog : DialogNode) -> void:
	all_loaded_dialogs[dialog.dialog_id] = dialog.dialog_title
	emit_signal("dialog_title_changed")
			
			
func dialog_deleted(dialog_id : int) -> void:
	
	all_loaded_dialogs.erase(dialog_id)


func dialog_node_added(dialog : DialogNode) -> void:
	add_dialog_to_loaded(dialog)


func _on_DialogAvailability_request_dialog_list_injection(dialog_availability) -> void:
	dialog_availability.dialog_list = self
