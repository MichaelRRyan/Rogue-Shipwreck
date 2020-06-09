extends RichTextLabel

signal finished

export var message = "Example Text"
export var character_delay = 0.2

var letter_index = 0
var timer = 0

func _ready():
	message = text
	text = ""

func _physics_process(delta):
	
	if letter_index < message.length():
	
		timer += delta
	
		if timer > character_delay:
			timer -= character_delay
			text += message[letter_index]
			letter_index += 1
	else:
		set_physics_process(false)
		emit_signal("finished")

func skip():
	text = message
	set_physics_process(false)
	emit_signal("finished")