extends Button
signal rename_category_request
signal delete_category_request
signal reimport_category_request


var index := 0

signal open_category_request

func _ready():
	pass
	


func _on_Button_pressed():
	emit_signal("open_category_request",self)


func _on_Button_gui_input(event : InputEvent):
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				$PopupMenu.position = get_global_mouse_position()
				$PopupMenu.popup()


func _on_PopupMenu_mouse_exited():
	$PopupMenu.visible = false


func _on_PopupMenu_index_pressed(button_index : int):
	match button_index:
		0:
			$LineEdit.visible = true
			$LineEdit.grab_focus()
			$LineEdit.text = text
			$LineEdit.caret_column = $LineEdit.text.length()
		2:
			emit_signal("reimport_category_request",text)
		3:
			emit_signal("delete_category_request",text)
		





func _on_LineEdit_text_entered(new_text: String):
	$LineEdit.visible = false
	emit_signal("rename_category_request",text,new_text)
