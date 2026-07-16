extends SceneTree
## Headless sim test runner — zero addon dependencies.
##
## Run:  godot --headless --path . -s tests/test_runner.gd
## Discovers tests/test_*.gd (except this file), instantiates each script
## (they extend SimTestBase), runs every method starting with "test_" in
## sorted order, prints per-test PASS/FAIL plus a summary, and quits 0/1.

const TESTS_DIR: String = "res://tests"


func _initialize() -> void:
	var total_pass: int = 0
	var total_fail: int = 0
	var files: Array[String] = _find_test_files()
	if files.is_empty():
		printerr("No test files found in " + TESTS_DIR)
		quit(1)
		return
	for file_path: String in files:
		var script: GDScript = load(file_path) as GDScript
		if script == null:
			printerr("FAIL  %s (script failed to load/parse)" % file_path)
			total_fail += 1
			continue
		var instance: Object = script.new()
		if not (instance is SimTestBase):
			print("SKIP  %s (does not extend SimTestBase)" % file_path)
			continue
		var test: SimTestBase = instance
		for method_name: String in _test_methods(script):
			test.begin_test(method_name)
			test.call(method_name)
			if test.failures.is_empty():
				total_pass += 1
				print("PASS  %s :: %s  (%d checks)" % [file_path.get_file(), method_name, test.checks])
			else:
				total_fail += 1
				print("FAIL  %s :: %s" % [file_path.get_file(), method_name])
				for failure: String in test.failures:
					print("      - " + failure)
	print("")
	print("==== sim tests: %d passed, %d failed ====" % [total_pass, total_fail])
	quit(0 if total_fail == 0 else 1)


func _find_test_files() -> Array[String]:
	var files: Array[String] = []
	var dir: DirAccess = DirAccess.open(TESTS_DIR)
	if dir == null:
		return files
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.begins_with("test_") and file_name.ends_with(".gd") and file_name != "test_runner.gd":
			files.append(TESTS_DIR + "/" + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	files.sort()
	return files


func _test_methods(script: GDScript) -> Array[String]:
	var methods: Array[String] = []
	for method_info: Dictionary in script.get_script_method_list():
		var method_name: String = String(method_info.get("name", ""))
		if method_name.begins_with("test_") and not methods.has(method_name):
			methods.append(method_name)
	methods.sort()
	return methods
