extends Control

var text_displayed = false

func _input(event):
	if event.is_action_pressed("ui_accept") || event.is_action_pressed("mouse_click"):
		if text_displayed:
			if get_tree().change_scene("res://Scenes/Game.tscn") != OK:
				print ("An unexpected error occured when trying to switch to the TitleScene scene")
		else:
			$DialogBox.skip()

func _on_DialogBox_finished():
	text_displayed = true
	$Instruction.text = "Press space to continue"
