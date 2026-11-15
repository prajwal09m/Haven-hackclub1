class_name StoryData
extends RefCounted
## All story text and objective definitions. Edit here to change the writing.

## chapter: which chapter the objective belongs to. initial: registered when the chapter starts
## (otherwise GameState registers it when the story reaches it).
const OBJECTIVES: Array[Dictionary] = [
	{"id": "read_first_email", "title": "Read the first email", "chapter": 1, "initial": true},
	{"id": "investigate_woman", "title": "Investigate the woman's case", "chapter": 1, "initial": false},
	{"id": "find_coordinates", "title": "Discover the forest coordinates", "chapter": 1, "initial": false},
	{"id": "enter_forest", "title": "Enter the forest", "chapter": 2, "initial": true},
	{"id": "investigate_cult", "title": "Investigate the cult evidence", "chapter": 2, "initial": true},
	{"id": "find_note", "title": "Find the note", "chapter": 2, "initial": true},
	{"id": "return_hotel", "title": "Return to the hotel", "chapter": 2, "initial": false},
	{"id": "open_attachment", "title": "Open the attachment", "chapter": 3, "initial": true},
	{"id": "reach_ritual", "title": "Reach the ritual site", "chapter": 3, "initial": false},
]

const EMAILS: Dictionary = {
	"e1_welcome": {
		"from": "UNKNOWN <no-name@harrow.mb>",
		"subject": "You are in Room 6",
		"date": "Sep 17 1989  21:31",
		"body": "Detective M,\n\nYou checked in at 9:14 this evening. Room 6. The bed by the window, the lamp that doesn't work.\n\nYou were told this was a routine consultation. It isn't. Eleven people have walked into Harrow Forest since April and not one has walked out. The department stopped counting at six.\n\nI have been watching the road for someone who would keep counting.\n\nLook at what the last guest in this room left behind. The dresser drawer sticks. Pull harder.\n\n- a friend",
		"attachments": [],
	},
	"e2_whitlow": {
		"from": "UNKNOWN <no-name@harrow.mb>",
		"subject": "Clara Whitlow",
		"date": "Sep 17 1989  21:44",
		"body": "Her name was Clara Whitlow. She came to Melbrook to photograph the old city for a magazine. She found the forest instead.\n\nEleven days after she checked in, the maid found her on the floor of Room 6 with her fingers torn open from the inside of the door. The coroner wrote 'exposure'. Indoors. In August.\n\nThe police report is attached. Read the margins.\n\nThen read the rest of what she left. A newspaper clipping by the bed. A diary in the drawer. She was writing to me, in a way. I was the only one who answered.",
		"attachments": [{
			"name": "whitlow_report.txt",
			"kind": "text",
			"text": "MELBROOK CITY POLICE  -  CASE 89-0417\n\nDECEASED : WHITLOW, Clara (29), photographer\nLOCATION : Hotel Marlowe, Room 6\nFOUND    : 14 Aug 1989, 07:40, by housekeeping\nCAUSE    : EXPOSURE (see note)\n\nNOTE: Body frozen. Room temperature normal.\nFingernails broken; interior of door gouged. Door locked from the inside, chain on.\nTwo earlier complaints from neighbouring rooms: knocking at night (two knocks), then scratching.\nSubject had received messages from an unregistered address for three weeks. Sender never traced.\nCamera recovered. Film missing.\n\n[handwritten in the margin, then crossed out]\n  SAME SENDER. HARROW.",
		}],
	},
	"e3_coordinates": {
		"from": "UNKNOWN <no-name@harrow.mb>",
		"subject": "She was right",
		"date": "Sep 17 1989  22:05",
		"body": "You have read what she left. Now you know what I know.\n\nShe went into the forest to find where it starts. I am sending you the survey she copied onto the back of the clipping. I can't go myself. Only people who are invited can walk those trees, and I was never invited. Not the way you will be.\n\nTake your revolver. It won't kill what lives in there. It may buy you minutes.\n\nThe survey is attached.",
		"attachments": [{
			"name": "harrow_survey.dat",
			"kind": "text",
			"text": "HARROW FOREST SURVEY  //  GRID DATA\n\nTRAILHEAD (OLD LOGGING ROAD)  N 44 13' 07\"  W 71 42' 51\"\nENTRY POINT                   NORTH of the road, at the treeline\nGRID                          7-D\n\nSTAY ON THE PATH AFTER DARK.\nSOMETHING PATROLS THE MAIN TRAIL.\nTHE CAMP IS NORTH-WEST OF THE TRAILHEAD, ABOUT 60 PACES OFF THE TRAIL.\nTHE RITUAL GROUND IS FURTHER NORTH. I HAVE NOT SEEN IT.\n\n[end of file]",
		}],
	},
	"e4_invitation": {
		"from": "THE CONGREGATION <hollow@harrow.mb>",
		"subject": "YOU READ OUR RECORDS",
		"date": "Sep 18 1989  23:58",
		"body": "Detective M,\n\nYou found the camp. You found the note. You are more thorough than the last one.\n\nWe have prepared a place for you. Attached is a small program. It will explain. It will not hurt. Much.\n\nOpen it.",
		"attachments": [{
			"name": "INVITATION.EXE",
			"kind": "program",
			"text": "",
		}],
	},
}

const DOCS: Dictionary = {
	"diary": {
		"title": "CLARA WHITLOW - DIARY",
		"text": "AUG 3\nRoom 6 smells like wet pine. The manager says the last guest left in a hurry.\n\nAUG 6\nSomeone keeps writing to the hotel terminal. No name. It says it can show me where the pictures are. It is right about the pictures.\n\nAUG 9\nTwo knocks at night. Then scratching, low on the door, like something with a lot of patience. Nobody in the hall. I checked.\n\nAUG 11\nThe sender is not the thing in the forest. I think it is another prisoner. It wants someone to finish what it started.\n\nAUG 12\nThe cult is real. Hoods, lanterns, a circle in the ground. One of them looked straight at my lens. I ran. If I'm found in this room: it was not the cold.\n\nAUG 13\nTwo knocks. They know the room number.",
	},
	"clipping": {
		"title": "MELBROOK COURIER - AUG 15 1989",
		"text": "PHOTOGRAPHER FOUND DEAD IN HOTEL\n\nA 29-year-old visitor was found dead on Monday at the Hotel Marlowe. Police describe the death as 'unexplained'. The room's heating was on. The body was frozen.\n\nThe search of Harrow Forest, suspended again on Tuesday, has now cost the city eleven residents and the patience of the council.\n\n[on the back, in blue ink]\n7-D. Old logging road. Look for the camp. Don't take the main trail.",
	},
	"suitcase": {
		"title": "SUITCASE",
		"text": "Your service revolver, a .38. Four rounds. You were told not to bring it.\n\nYou take it anyway.",
	},
	"symbol": {
		"title": "PAINTED SYMBOL",
		"text": "A spiral painted in something that has dried brown. Eleven tally marks cut around the rim. A twelfth, fresher.\n\nA thirteenth space has been left blank, with a single letter above it:\n\nM",
	},
	"robe": {
		"title": "FOLDED ROBE",
		"text": "A coarse gray robe, left folded as if its owner will be back soon.\n\nStitched into the hem: a laundry tag from Hotel Marlowe.\n\nROOM 6.",
	},
	"ledger": {
		"title": "THE LEDGER",
		"text": "A ledger held down by a stone. Names in columns, eleven crossed out.\n\nWHITLOW, C.  -  received / unbound\n\nThe last line is not crossed out:\n\nM.  -  arrives the 18th. Will be sent the invitation. Will answer it.\n\nBelow, in a different hand:\n\n'Don't answer it. Look at what it is made of.'",
	},
	"note": {
		"title": "THE NOTE",
		"text": "M -\n\nGo back to the hotel. Check your computer. They have sent you something and you have to open it, whatever you decide to do after.\n\nI can't write more here. Look closely at the file. They are not as strong as they want you to think.\n\n- a friend",
	},
}


static func get_email(email_id: String, transformed: bool = false) -> Dictionary:
	var email: Dictionary = (EMAILS.get(email_id, {}) as Dictionary).duplicate(true)
	if email_id == "e1_welcome" and transformed:
		email["body"] = str(email["body"]) + "\n\nP.S. You have read this before, haven't you? You always say the same thing the next morning. 'Where is the door.'"
	return email
