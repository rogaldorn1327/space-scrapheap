extends "res://tests/scene_check.gd"

## R вызывает тот же GameMenu.restart, что пауза и экран смерти.


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not _check_key_filter():
		return
	var scene := await boot(3)
	if scene == null:
		return
	var menu := scene.get_node_or_null("Menu") as GameMenu
	if menu == null:
		fail("Нет узла Menu")
		return
	if not _check_start_screen_ignores_r(menu):
		return
	if not _check_play_and_pause_accept_r(menu):
		return
	if not await _check_text_focus_ignores_r(scene, menu):
		return
	if not _check_same_restart_path():
		return
	print("RESTART_OK")
	quit(0)


func _key(code: Key, pressed: bool = true, echo: bool = false) -> InputEventKey:
	var event := InputEventKey.new()
	event.pressed = pressed
	event.echo = echo
	event.keycode = code
	event.physical_keycode = code
	return event


func _check_key_filter() -> bool:
	if not GameMenu.is_restart_key(_key(KEY_R)):
		fail("Нажатие R должно быть клавишей рестарта")
		return false
	if GameMenu.is_restart_key(_key(KEY_R, false)):
		fail("Отпускание R не должно рестартить")
		return false
	if GameMenu.is_restart_key(_key(KEY_R, true, true)):
		fail("Echo R не должен рестартить")
		return false
	if GameMenu.is_restart_key(_key(KEY_W)):
		fail("W не должен рестартить")
		return false
	return true


func _check_start_screen_ignores_r(menu: GameMenu) -> bool:
	if menu.wants_restart(_key(KEY_R)):
		fail("На стартовом экране R не должен рестартить")
		return false
	return true


func _check_play_and_pause_accept_r(menu: GameMenu) -> bool:
	menu._close()
	if not menu.wants_restart(_key(KEY_R)):
		fail("В игре R должен рестартить")
		return false
	menu._show_pause()
	if not menu.wants_restart(_key(KEY_R)):
		fail("В паузе R должен рестартить как «Начать заново»")
		return false
	menu._close()
	return true


func _check_text_focus_ignores_r(scene: Node, menu: GameMenu) -> bool:
	var field := LineEdit.new()
	scene.add_child(field)
	field.grab_focus()
	await process_frame
	if not GameMenu.focus_blocks_restart(scene.get_viewport()):
		fail("LineEdit с фокусом должен глушить R")
		field.queue_free()
		return false
	if menu.wants_restart(_key(KEY_R)):
		fail("R в поле ввода не должен рестартить")
		field.queue_free()
		return false
	field.queue_free()
	return true


func _check_same_restart_path() -> bool:
	var wanderer_src := FileAccess.get_file_as_string("res://scripts/wanderer.gd")
	if wanderer_src.find("GameMenu.restart") < 0:
		fail("Экран смерти должен вызывать GameMenu.restart")
		return false
	var menu_src := FileAccess.get_file_as_string("res://scripts/menu.gd")
	if menu_src.find("reload_current_scene") < 0:
		fail("Рестарт должен перезагружать сцену")
		return false
	if menu_src.find("wants_restart") < 0:
		fail("Меню должно решать, когда R рестартит")
		return false
	return true
