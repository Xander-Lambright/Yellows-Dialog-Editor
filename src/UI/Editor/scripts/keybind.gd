extends HBoxContainer

var action_name : String
var key_bind
var assigning_keybind := false

func assign_action(action : String):
	action_name = action
	key_bind = InputMap.action_get_events(action_name)
	var keybind_label = ''
	for event in key_bind:
		keybind_label +=event.as_text()
	$Label.text = action
	$Button.text = keybind_label




func _on_button_pressed():
	$Button.text = ""
	GlobalDeclarations.assigning_keybind = true
	assigning_keybind = true
	
func _input(event):
	if event is InputEventKey && assigning_keybind:
		InputMap.action_erase_events(action_name)
		InputMap.action_add_event(action_name,event)
		$Button.text = event.as_text()	
	if event is InputEventKey && event.is_released():
		assigning_keybind = false
		GlobalDeclarations.assigning_keybind = false
