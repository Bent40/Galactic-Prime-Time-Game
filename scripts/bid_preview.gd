extends SceneTree
## BID SCREEN PREVIEW / VISUAL-REGRESSION DRIVER (KAN-6) — renders bid_screen.tscn
## and saves a PNG for comparison with the approved mockup
## (docs/ux-designs/demo-slice-2026-07-19/renders/bid-screen.png).
##
## Run:  bash scripts/render_bid.sh          (xvfb gives a real GL renderer)
##  or:  xvfb-run -s "-screen 0 1920x1200x24" -a godot --path . -s scripts/bid_preview.gd
##
## The bid screen is presentation-only and reads pre-run data ONLY through the
## GameController view API (view_bid), which itself reads STATIC data via the DAL —
## no live combat is needed. This driver stands up a real GameController, then binds
## the scene straight off view_bid, exactly as the game would when opening the screen.

const GameControllerScript := preload("res://controller/game_controller.gd")
const BID_SCENE := preload("res://ui/screens/bid_screen.tscn")


func _initialize() -> void:
	var out := OS.get_environment("BID_OUT")
	if out == "":
		out = "res://bid_render.png"

	var root := get_root()
	DisplayServer.window_set_size(Vector2i(1600, 1000))
	root.size = Vector2i(1600, 1000)

	var gc = GameControllerScript.new()
	gc.name = "PreviewController"
	root.add_child(gc)

	var scene := BID_SCENE.instantiate()
	root.add_child(scene)
	scene.bind(gc)

	# let layout settle + the GL frame render before we grab the framebuffer
	await process_frame
	await process_frame
	await process_frame
	await process_frame

	var img := root.get_texture().get_image()
	var err := img.save_png(out)
	if err != OK:
		push_error("save_png failed (%d) -> %s" % [err, out])
	print("Bid render saved -> %s  %s" % [out, str(img.get_size())])
	quit()
