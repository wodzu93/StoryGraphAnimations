extends Label
class_name EventLog 

export var log_fade_after := 3.0

func _ready():
	self.set_process(false)

func _process(delta):
	if !$"../CheckButton".pressed:
		modulate.a = min(1, $Timer.time_left)

func clear():
	self.text = ""

func add_text(value):
	self.text += value+"\n"
	$Timer.start(log_fade_after)
	self.set_process(true)

func _on_Timer_timeout():
	self.set_process(false)

func _on_CheckButton_toggled(button_pressed):
	modulate.a = 1.0 * float(button_pressed)
