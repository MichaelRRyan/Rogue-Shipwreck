extends Control

signal unpaused
signal restarted

func appear():
	visible = true
	$Resume.grab_focus()

func _on_Resume_pressed():
	visible = false
	emit_signal("unpaused")

func _on_Restart_pressed():
	visible = false
	emit_signal("restarted")
	
func _on_Exit_pressed():
	if get_tree().change_scene("res://Scenes/TitleScene.tscn") != OK:
		print ("An unexpected error occured when trying to switch to the TitleScene scene")
