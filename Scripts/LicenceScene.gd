extends Control

onready var start_time = OS.get_ticks_msec()

func _input(event):
	if event.is_action_pressed("ui_accept") || event.is_action_pressed("mouse_click"):
		get_tree().change_scene("res://Scenes/TitleScene.tscn")

func _process(delta):
	if OS.get_ticks_msec() - start_time> 2000:
		get_tree().change_scene("res://Scenes/TitleScene.tscn")