extends Control

func _ready():
	$PlayButton.grab_focus()

func _on_PlayButton_pressed():
	if get_tree().change_scene("res://Scenes/Game.tscn") != OK:
		print ("An unexpected error occured when trying to switch to the Game scene")

func _on_ExitButton_pressed():
	get_tree().quit()

