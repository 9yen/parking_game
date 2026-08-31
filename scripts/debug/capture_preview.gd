extends SceneTree

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var instance := scene.instantiate()
	root.add_child(instance)
	for _frame in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var output_name := "compact-direct.png" if OS.get_cmdline_user_args().has("--compact-preview") else "normal-direct.png"
	var error := image.save_png("res://artifacts/%s" % output_name)
	quit(0 if error == OK else 1)
