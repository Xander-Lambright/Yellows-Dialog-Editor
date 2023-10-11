class_name category_exporter
extends Node


func _ready():
	pass

func export_category(directory : String = CurrentEnvironment.current_directory+"/dialogs/",category_name : String = CurrentEnvironment.current_category_name,export_version:int = 2):
	var exported_category_dir := DirAccess.open(CurrentEnvironment.current_directory+"/dialogs")
	var save_nodes := get_tree().get_nodes_in_group("Save")
	
	
	if !exported_category_dir.dir_exists(directory+category_name):
		exported_category_dir.make_dir(directory+category_name)
	empty_category_jsons(category_name)
	for i in save_nodes:
		if i.node_type != "Dialog Node":
			continue
		var dialog_file := FileAccess.open(directory+category_name+"/"+str(i.dialog_id)+".json",FileAccess.WRITE)
		var new_dict : Array[String] = create_dialog_dict(i,export_version)
		#var jsonprint = JSON.print(new_dict,"\r\n")
		for line in new_dict:
			dialog_file.store_line(line)
		dialog_file.close()
		
func empty_category_jsons(category_name : String):
	
	var dir := DirAccess.open(CurrentEnvironment.current_directory+"/dialogs/"+category_name)
	dir.remove(CurrentEnvironment.current_directory+"/dialogs/highest_index.json")
	if DirAccess.get_open_error() == OK:
		dir.list_dir_begin() # TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var file_name : String = dir.get_next()
		while file_name != "":
			if file_name == "autosave":
				dir.get_next()
			if dir.current_is_dir():
				empty_category_jsons(CurrentEnvironment.current_directory+"/dialogs/"+category_name+"/"+file_name)
			else:
				if file_name.get_extension() == "json":
					dir.remove(file_name)
			file_name = dir.get_next()
		

func create_dialog_dict(dialog : DialogNode, version):
	match version :
		0:
			var dialog_json_array : Array[String] =  [
			'{',
			'	DialogShowWheel: '+str(int(dialog.show_wheel))+'b,',
			'	AvailabilityQuestId: '+str(dialog.quest_availabilities[0].quest_id)+',',
			'	Options:['
			]
			for i in dialog.response_options.size():
				var new_option_dict : Array[String]= create_option_dict(dialog.response_options[i],i==dialog.response_options.size()-1,true)
				for line in new_option_dict:
					dialog_json_array.append(line)
			var rest_of_dialog_json_array :Array[String]= [
			'	],',
			'	DialogHideNPC: '+str(int(dialog.hide_npc))+'b,',
			'	AvailabilityFactionStance: '+str(dialog.faction_availabilities[0].stance_type)+',',
			'	DialogId: '+str(dialog.dialog_id)+',',
			'	AvailabilityQuest: '+str(dialog.quest_availabilities[0].availability_type)+',',
			'	AvailabilityDialog4: '+str(dialog.dialog_availabilities[3].availability_type)+',',
			'	AvailabilityDialog3: '+str(dialog.dialog_availabilities[2].availability_type)+',',
			'	AvailabilityQuest2: '+str(dialog.quest_availabilities[1].availability_type)+',',
			'	AvailabilityQuest3: '+str(dialog.quest_availabilities[2].availability_type)+',',
			'	AvailabilityQuest4: '+str(dialog.quest_availabilities[3].availability_type)+',',
			'	ModRev: '+str(16)+',',
			'	DecreaseFaction1Points: '+str(dialog.faction_changes[0].operator)+'b,',
			'	DialogQuest: '+str(dialog.start_quest)+',',
			'	AvailabilityDialog2: '+str(dialog.dialog_availabilities[1].availability_type)+',',
			'	OptionFactions1: '+str(dialog.faction_changes[0].faction_id)+',',
			'	AvailabilityDayTime: '+str(dialog.time_availability)+',',
			'	OptionFactions2: '+str(dialog.faction_changes[1].faction_id)+',',
			'	AvailabilityFaction2Id: '+str(dialog.faction_availabilities[1].faction_id)+',',
			'	OptionFaction1Points: '+str(abs(dialog.faction_changes[0].points))+',',
			'	DialogDisableEsc: '+str(int(dialog.disable_esc))+'b,',
			'	AvailabilityFaction: '+str(dialog.faction_availabilities[0].availability_operator)+',',
			'	DialogTitle : "'+str(dialog.dialog_title).c_unescape().replace("\\'","'")+'",',
			'	AvailabilityDialog: '+str(dialog.dialog_availabilities[0].availability_type)+',',
			'	AvailabilityFaction2: '+str(dialog.faction_availabilities[1].availability_operator)+',',
			'	AvailabilityFactionId: '+str(dialog.faction_availabilities[0].faction_id)+',',
			'	AvailabilityFaction2Stance: '+str(dialog.faction_availabilities[1].stance_type)+',',
			'	DialogCommand: "'+ str(dialog.command).c_unescape().replace("\\'","'")+'",',
			'	AvailabilityDialogId: '+str(dialog.dialog_availabilities[0].dialog_id)+',',
			'	OptionFaction2Points: '+str(abs(dialog.faction_changes[1].points))+',',
			'	DialogText: "'+str(dialog.text).c_unescape().replace("\\'","'").replace("\\n","\n")+'",',
			'	AvailabilityQuest4Id: '+str(dialog.quest_availabilities[3].quest_id)+',',
			'	AvailabilityQuest3Id: '+str(dialog.quest_availabilities[2].quest_id)+',',
			'	AvailabilityQuest2Id: '+str(dialog.quest_availabilities[1].quest_id)+',',
			'	AvailabilityDialog2Id: '+str(dialog.dialog_availabilities[1].dialog_id)+',',
			'	AvailabilityDialog3Id: '+str(dialog.dialog_availabilities[2].dialog_id)+',',
			'	AvailabilityDialog4Id: '+str(dialog.dialog_availabilities[3].dialog_id)+',',
			'	AvailabilityMinPlayerLevel: '+str(dialog.min_level_availability)+',',
			'	DecreaseFaction2Points: '+str(dialog.faction_changes[0].operator)+'b,',
				'	DialogMail: {',
				'		Sender: "'+dialog.mail.sender+'",',
				'		BeenRead: 0,',
				'		Message: {',
						dialog.mail.compose_pages_string(),
				'		},',
				'		MailItems: [',
						dialog.mail.compose_items_string(),
				'		],',
				'		MailQuest: '+dialog.mail.quest_id+',',
				'		TimePast: 1669491043541L,',
				'		Time: 0L,',
				'		Subject: "'+dialog.mail.subject+'"',
				'	}',
			'}'
			]
			dialog_json_array.append_array(rest_of_dialog_json_array)
			return dialog_json_array
		1:
			var dialog_json_array : Array[String] =  [
			'{',
			'	"DialogShowWheel": '+str(int(dialog.show_wheel))+'b,',
			'	"AvailabilityQuestId": '+str(dialog.quest_availabilities[0].quest_id)+',',
			'	"Options":['
			]
			for i in dialog.response_options.size():
				var new_option_dict : Array[String]= create_option_dict(dialog.response_options[i],i==dialog.response_options.size()-1)
				for line in new_option_dict:
					dialog_json_array.append(line)
			var rest_of_dialog_json_array :Array[String]= [
			'	],',
			'	"DialogHideNPC": '+str(int(dialog.hide_npc))+'b,',
			'	"AvailabilityFactionStance": '+str(dialog.faction_availabilities[0].stance_type)+',',
			'	"DialogId": '+str(dialog.dialog_id)+',',
			'	"AvailabilityQuest": '+str(dialog.quest_availabilities[0].availability_type)+',',
			'	"AvailabilityDialog4": '+str(dialog.dialog_availabilities[3].availability_type)+',',
			'	"AvailabilityDialog3": '+str(dialog.dialog_availabilities[2].availability_type)+',',
			'	"AvailabilityQuest2": '+str(dialog.quest_availabilities[1].availability_type)+',',
			'	"AvailabilityQuest3": '+str(dialog.quest_availabilities[2].availability_type)+',',
			'	"AvailabilityQuest4": '+str(dialog.quest_availabilities[3].availability_type)+',',
			'	"ModRev": '+str(18)+',',
			'	"DecreaseFaction1Points": '+str(dialog.faction_changes[0].operator)+'b,',
			'	"DialogQuest": '+str(dialog.start_quest)+',',
			'	"AvailabilityDialog2": '+str(dialog.dialog_availabilities[1].availability_type)+',',
			'	"OptionFactions1": '+str(dialog.faction_changes[0].faction_id)+',',
			'	"AvailabilityDayTime": '+str(dialog.time_availability)+',',
			'	"OptionFactions2": '+str(dialog.faction_changes[1].faction_id)+',',
			'	"AvailabilityFaction2Id": '+str(dialog.faction_availabilities[1].faction_id)+',',
			'	"OptionFaction1Points": '+str(abs(dialog.faction_changes[0].points))+',',
			'	"DialogDisableEsc": '+str(int(dialog.disable_esc))+'b,',
			'	"AvailabilityFaction": '+str(dialog.faction_availabilities[0].availability_operator)+',',
			'	"DialogTitle": "'+str(dialog.dialog_title).c_unescape().replace("\\'","'")+'",',
			'	"AvailabilityDialog": '+str(dialog.dialog_availabilities[0].availability_type)+',',
			'	"AvailabilityFaction2": '+str(dialog.faction_availabilities[1].availability_operator)+',',
			'	"AvailabilityFactionId": '+str(dialog.faction_availabilities[0].faction_id)+',',
			'	"AvailabilityFaction2Stance": '+str(dialog.faction_availabilities[1].stance_type)+',',
			'	"DialogCommand": "'+ str(dialog.command).c_unescape().replace("\\'","'")+'",',
			'	"AvailabilityDialogId": '+str(dialog.dialog_availabilities[0].dialog_id)+',',
			'	"OptionFaction2Points": '+str(abs(dialog.faction_changes[1].points))+',',
			'	"DialogText": "'+str(dialog.text).c_unescape().replace("\\'","'").replace("\\n","\n")+'",',
			'	"AvailabilityQuest4Id": '+str(dialog.quest_availabilities[3].quest_id)+',',
			'	"AvailabilityQuest3Id": '+str(dialog.quest_availabilities[2].quest_id)+',',
			'	"AvailabilityQuest2Id": '+str(dialog.quest_availabilities[1].quest_id)+',',
			'	"AvailabilityDialog2Id": '+str(dialog.dialog_availabilities[1].dialog_id)+',',
			'	"AvailabilityDialog3Id": '+str(dialog.dialog_availabilities[2].dialog_id)+',',
			'	"AvailabilityDialog4Id": '+str(dialog.dialog_availabilities[3].dialog_id)+',',
			'	"AvailabilityMinPlayerLevel": '+str(dialog.min_level_availability)+',',
			'	"DecreaseFaction2Points": '+str(dialog.faction_changes[0].operator)+'b,',
				'"DialogMail": {',
				'		"Sender": "'+dialog.mail.sender+'",',
				'		"BeenRead": 0,',
				'		"Message": {',
						dialog.mail.compose_pages_string(),
				'		},',
				'		"MailItems": [',
						dialog.mail.compose_items_string(),
				'		],',
				'		"MailQuest": '+str(dialog.mail.quest_id)+',',
				'		"TimePast": 1669491043541L,',
				'		"Time": 0L,',
				'		"Subject": "'+dialog.mail.subject+'"',
				'	}',
			'}'
			]
			dialog_json_array.append_array(rest_of_dialog_json_array)
			return dialog_json_array
		
		2:  
			var dialog_json_array : Array[String] =  [
			'{',
			'	"DialogShowWheel": '+str(int(dialog.show_wheel))+'b,',
			'	"AvailabilityQuestId": '+str(dialog.quest_availabilities[0].quest_id)+',',
			'	"Options":['
			]
			for i in dialog.response_options.size():
				var new_option_dict : Array[String]= create_option_dict(dialog.response_options[i],i==dialog.response_options.size()-1)
				for line in new_option_dict:
					dialog_json_array.append(line)
			var rest_of_dialog_json_array :Array[String]= [
			'	],',
			'	"AvailabilityScoreboardType": '+str(dialog.scoreboard_availabilities[0].comparison_type)+',',
			'	"DialogHideNPC": '+str(int(dialog.hide_npc))+'b,',
			'	"AvailabilityFactionStance": '+str(dialog.faction_availabilities[0].stance_type)+',',
			'	"AvailabilityScoreboard2Value": '+str(dialog.scoreboard_availabilities[1].value)+',',
			'	"DialogId": '+str(dialog.dialog_id)+',',
			'	"AvailabilityQuest": '+str(dialog.quest_availabilities[0].availability_type)+',',
			'	"AvailabilityDialog4": '+str(dialog.dialog_availabilities[3].availability_type)+',',
			'	"AvailabilityScoreboardObjective": "'+str(dialog.scoreboard_availabilities[0].objective_name)+'",',
			'	"AvailabilityDialog3": '+str(dialog.dialog_availabilities[2].availability_type)+',',
			'	"AvailabilityQuest2": '+str(dialog.quest_availabilities[1].availability_type)+',',
			'	"AvailabilityQuest3": '+str(dialog.quest_availabilities[2].availability_type)+',',
			'	"AvailabilityScoreboard2Objective": "'+str(dialog.scoreboard_availabilities[1].objective_name)+'",',
			'	"AvailabilityQuest4": '+str(dialog.quest_availabilities[3].availability_type)+',',
			'	"ModRev": '+str(18)+',',
			'	"DecreaseFaction1Points": '+str(dialog.faction_changes[0].operator)+'b,',
			'	"DialogQuest": '+str(dialog.start_quest)+',',
			'	"AvailabilityDialog2": '+str(dialog.dialog_availabilities[1].availability_type)+',',
			'	"OptionFactions1": '+str(dialog.faction_changes[0].faction_id)+',',
			'	"AvailabilityDayTime": '+str(dialog.time_availability)+',',
			'	"OptionFactions2": '+str(dialog.faction_changes[1].faction_id)+',',
			'	"AvailabilityFaction2Id": '+str(dialog.faction_availabilities[1].faction_id)+',',
			'	"OptionFaction1Points": '+str(abs(dialog.faction_changes[0].points))+',',
			'	"AvailabilityScoreboardValue": '+str(dialog.scoreboard_availabilities[1].value)+',',
			'	"DialogDisableEsc": '+str(int(dialog.disable_esc))+'b,',
			'	"AvailabilityFaction": '+str(dialog.faction_availabilities[0].availability_operator)+',',
			'	"DialogTitle": "'+str(dialog.dialog_title).c_escape().replace("\\'","'")+'",',
			'	"AvailabilityDialog": '+str(dialog.dialog_availabilities[0].availability_type)+',',
			'	"AvailabilityScoreboard2Type": '+str(dialog.scoreboard_availabilities[1].comparison_type)+',',
			'	"AvailabilityFaction2": '+str(dialog.faction_availabilities[1].availability_operator)+',',
			'	"AvailabilityFactionId": '+str(dialog.faction_availabilities[0].faction_id)+',',
			'	"AvailabilityFaction2Stance": '+str(dialog.faction_availabilities[1].stance_type)+',',
			'	"DialogCommand": "'+str(dialog.command).c_escape().replace("\\'","'")+'",',
			'	"AvailabilityDialogId": '+str(dialog.dialog_availabilities[0].dialog_id)+',',
			'	"OptionFaction2Points": '+str(abs(dialog.faction_changes[1].points))+',',
			'	"DialogText": "'+str(dialog.text).c_escape().replace("\\'","'").replace("\\n","\n")+'",',
			'	"AvailabilityQuest4Id": '+str(dialog.quest_availabilities[3].quest_id)+',',
			'	"AvailabilityQuest3Id": '+str(dialog.quest_availabilities[2].quest_id)+',',
			'	"AvailabilityQuest2Id": '+str(dialog.quest_availabilities[1].quest_id)+',',
			'	"AvailabilityDialog2Id": '+str(dialog.dialog_availabilities[1].dialog_id)+',',
			'	"AvailabilityDialog3Id": '+str(dialog.dialog_availabilities[2].dialog_id)+',',
			'	"AvailabilityDialog4Id": '+str(dialog.dialog_availabilities[3].dialog_id)+',',
			'	"AvailabilityMinPlayerLevel": '+str(dialog.min_level_availability)+',',
			'	"DecreaseFaction2Points": '+str(dialog.faction_changes[0].operator)+'b,',
				'	"DialogMail": {',
				'		"Sender": "'+dialog.mail.sender.c_escape()+'",',
				'		"BeenRead": 0,',
				'		"Message": {',
						dialog.mail.compose_pages_string(),
				'		},',
				'		"MailItems": [',
						dialog.mail.compose_items_string(),
				'		],',
				'		"MailQuest": '+str(dialog.mail.quest_id)+',',
				'		"TimePast": 1669491043541L,',
				'		"Time": 0L,',
				'		"Subject": "'+dialog.mail.subject.c_escape()+'"',
				'	}',
			'}'
			]
			dialog_json_array.append_array(rest_of_dialog_json_array)
			return dialog_json_array
	
func create_option_dict(response: ResponseNode,islast:bool,withoutQuotes : bool = false):
	var response_dict :Array[String]= []
	if withoutQuotes:
		if islast == false:
			response_dict = [
						'		{',
						'				OptionSlot: '+str(response.slot)+',',
						'				Option: {',
						'				DialogCommand: "'+str(response.command).c_escape().replace("\\'","'")+'",',
						'				Dialog: '+str(response.to_dialog_id)+',',
						'				Title: "'+str(response.response_title).c_escape().replace("\\'","'")+'",',
						'				DialogColor: '+str(response.color_decimal)+',',
						'				OptionType: '+str(response.get_option_id_from_index(response.option_type)),
						'			}',
						'		},'
				]
		else:
			response_dict = [
				'		{',
					'			OptionSlot: '+str(response.slot)+',',
					'			Option: {',
						'				DialogCommand: "'+str(response.command).c_escape().replace("\\'","'")+'",',
						'				Dialog: '+str(response.to_dialog_id)+',',
						'				Title: "'+str(response.response_title).c_escape().replace("\\'","'")+'",',
						'				DialogColor: '+str(response.color_decimal)+',',
						'				OptionType: '+str(response.get_option_id_from_index(response.option_type)),
						"			}",
						'		}'
				]
		return response_dict	
	if islast == false:
		response_dict = [
					'		{',
					'				"OptionSlot": '+str(response.slot)+',',
					'				"Option": {',
					'				"DialogCommand": "'+str(response.command).c_escape().replace("\\'","'")+'",',
					'				"Dialog": '+str(response.to_dialog_id)+',',
					'				"Title": "'+str(response.response_title).c_escape().replace("\\'","'")+'",',
					'				"DialogColor": '+str(response.color_decimal)+',',
					'				"OptionType": '+str(response.get_option_id_from_index(response.option_type)),
					'			}',
					'		},'
			]
	else:
		response_dict = [
			'		{',
				'			"OptionSlot": '+str(response.slot)+',',
				'			"Option": {',
					'				"DialogCommand": "'+str(response.command).c_escape().replace("\\'","'")+'",',
					'				"Dialog": '+str(response.to_dialog_id)+',',
					'				"Title": "'+str(response.response_title).c_escape().replace("\\'","'")+'",',
					'				"DialogColor": '+str(response.color_decimal)+',',
					'				"OptionType": '+str(response.get_option_id_from_index(response.option_type)),
					"			}",
					'		}'
			]
	return response_dict	
