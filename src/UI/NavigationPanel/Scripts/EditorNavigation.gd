extends Panel
signal save_category_request
signal export_category_request
signal reimport_category_request
signal scan_for_changes_request
signal assign_new_ids_request

func _ready():
	$TopPanelContainer/MenuButton.get_popup().connect("id_pressed",Callable(self,"category_menu_pressed"))

func _on_SaveButton_pressed():
	emit_signal("save_category_request")



func _on_ExportButton_pressed():
	emit_signal("export_category_request")


func _on_ReimportButton_pressed():
	emit_signal("reimport_category_request")
	


func _on_ScanButton_pressed():
	emit_signal("scan_for_changes_request")


func _on_DialogEditor_finished_loading(category_name : String):
	$TopPanelContainer.visible = true


func category_menu_pressed(id):
	match id:
		0:
			emit_signal("reimport_category_request")
		1:
			emit_signal("scan_for_changes_request")
		2:
			emit_signal("assign_new_ids_request")

func _input(event):
	if $TopPanelContainer.visible && !GlobalDeclarations.assigning_keybind:
		if Input.is_action_just_pressed("save"):
			emit_signal("save_category_request")
		if Input.is_action_just_pressed("export"):
			emit_signal("export_category_request")
		if Input.is_action_just_pressed("reimport_category"):
			emit_signal("reimport_category_request")
		if Input.is_action_just_pressed("scan_for_changes"):
			emit_signal("scan_for_changes_request")
