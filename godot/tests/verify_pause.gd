extends "res://tests/scene_check.gd"

## P и Esc открывают и закрывают паузу одним путём.


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
	if not _check_start_screen_ignores_p(menu):
		return
	if not _check_play_and_pause_accept_p(menu):
		return
	if not await _check_text_focus_ignores_p(scene, menu):
		return
	if not _check_same_pause_path():
		return
	print("PAUSE_OK")
	quit(0)


func _key(code: Key, pressed: bool = true, echo: bool = false) -> InputEventKey:
	var event := InputEventKey.new()
	event.pressed = pressed
	event.echo = echo
	event.keycode = code
	event.physical_keycode = code
	return event


func _check_key_filter() -> bool:
	if not GameMenu.is_pause_key(_key(KEY_P)):
		fail("Нажатие P должно быть клавишей паузы")
		return false
	if GameMenu.is_pause_key(_key(KEY_P, false)):
		fail("Отпускание P не должно переключать паузу")
		return false
	if GameMenu.is_pause_key(_key(KEY_P, true, true)):
		fail("Echo P не должен переключать паузу")
		return false
	if GameMenu.is_pause_key(_key(KEY_W)):
		fail("W не должен быть клавишей паузы")
		return false
	if GameMenu.is_pause_key(_key(KEY_ESCAPE)):
		fail("Esc обрабатывается как ui_cancel, не как is_pause_key")
		return false
	return true


func _check_start_screen_ignores_p(menu: GameMenu) -> bool:
	if menu.wants_pause_toggle(_key(KEY_P)):
		fail("На стартовом экране P не должен ставить паузу")
		return false
	if not menu.wants_pause_toggle(_key(KEY_ESCAPE)):
		fail("На стартовом экране Esc по-прежнему ловится (но не закрывает старт)")
		return false
	return true


func _check_play_and_pause_accept_p(menu: GameMenu) -> bool:
	menu._close()
	if not menu.wants_pause_toggle(_key(KEY_P)):
		fail("В игре P должен открывать паузу")
		return false
	if not menu.wants_pause_toggle(_key(KEY_ESCAPE)):
		fail("В игре Esc должен открывать паузу")
		return false
	menu._apply_pause_toggle()
	if not menu._open or not menu._pause_mode:
		fail("P/Esc в игре должны открывать тот же экран паузы")
		return false
	if not menu.wants_pause_toggle(_key(KEY_P)):
		fail("В паузе P должен продолжать игру")
		return false
	menu._apply_pause_toggle()
	if menu._open:
		fail("P в паузе должен закрывать паузу")
		return false
	return true


func _check_text_focus_ignores_p(scene: Node, menu: GameMenu) -> bool:
	menu._close()
	var field := LineEdit.new()
	scene.add_child(field)
	field.grab_focus()
	await process_frame
	if not GameMenu.focus_blocks_hotkeys(scene.get_viewport()):
		fail("LineEdit с фокусом должен глушить P")
		field.queue_free()
		return false
	if menu.wants_pause_toggle(_key(KEY_P)):
		fail("P в поле ввода не должен ставить паузу")
		field.queue_free()
		return false
	if not menu.wants_pause_toggle(_key(KEY_ESCAPE)):
		fail("Esc в поле ввода по-прежнему ставит паузу")
		field.queue_free()
		return false
	field.queue_free()
	return true


func _check_same_pause_path() -> bool:
	var menu_src := FileAccess.get_file_as_string("res://scripts/menu.gd")
	if menu_src.find("wants_pause_toggle") < 0:
		fail("Меню должно решать, когда P/Esc переключают паузу")
		return false
	if menu_src.find("_apply_pause_toggle") < 0:
		fail("P и Esc должны вызывать один _apply_pause_toggle")
		return false
	if menu_src.find("is_pause_key") < 0:
		fail("P должен распознаваться через is_pause_key")
		return false
	return true
