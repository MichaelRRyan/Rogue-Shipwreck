extends Control

onready var start_time = OS.get_ticks_msec()

func _input(event):
	if event.is_action_pressed("ui_accept") || event.is_action_pressed("mouse_click"):
		if get_tree().change_scene("res://Scenes/TitleScene.tscn") != OK:
			print ("An unexpected error occured when trying to switch to the TitleScene scene")

func _process(_delta):
	if OS.get_ticks_msec() - start_time> 2000:
		if  get_tree().change_scene("res://Scenes/TitleScene.tscn") != OK:
			print ("An unexpected error occured when trying to switch to the TitleScene scene")