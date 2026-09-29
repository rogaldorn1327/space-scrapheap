extends "res://tests/scene_check.gd"

## R вызывает тот же GameMenu.restart, что пауза и экран смерти, через _input.


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
	GameMenu.reload_on_restart = false
	if not _check_start_screen_ignores_r(menu):
		return
	if not _check_play_and_pause_via_input(menu):
		return
	if not await _check_text_focus_ignores_r(scene, menu):
		return
	if not _check_button_focus_does_not_block(menu):
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
	event.key_label = code
	return event


func _physical_only(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = KEY_NONE
	event.physical_keycode = code
	event.key_label = KEY_NONE
	event.unicode = 0
	return event


func _unicode_only(codepoint: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = KEY_NONE
	event.physical_keycode = KEY_NONE
	event.key_label = KEY_NONE
	event.unicode = codepoint
	return event


func _check_key_filter() -> bool:
	if not GameMenu.is_restart_key(_key(KEY_R)):
		fail("Нажатие R должно быть клавишей рестарта")
		return false
	if not GameMenu.is_restart_key(_physical_only(KEY_R)):
		fail("Физическая R без keycode должна рестартить")
		return false
	if not GameMenu.is_restart_key(_unicode_only(0x043A)):
		fail("ЙЦУКЕН «к» на месте R должна рестартить")
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
	if GameMenu.is_restart_key(_unicode_only(0)):
		fail("Пустой unicode не должен рестартить")
		return false
	return true


func _check_start_screen_ignores_r(menu: GameMenu) -> bool:
	GameMenu.start_immediately = false
	if menu.wants_restart(_key(KEY_R)):
		fail("На стартовом экране R не должен рестартить")
		return false
	menu._input(_key(KEY_R))
	if GameMenu.start_immediately:
		fail("_input(R) на старте не должен вызывать restart")
		return false
	return true


func _check_play_and_pause_via_input(menu: GameMenu) -> bool:
	menu._close()
	if not menu.wants_restart(_key(KEY_R)):
		fail("В игре R должен рестартить")
		return false
	GameMenu.start_immediately = false
	menu._input(_physical_only(KEY_R))
	if not GameMenu.start_immediately:
		fail("_input(R) в игре должен вызывать GameMenu.restart")
		return false
	menu._show_pause()
	if not menu.wants_restart(_key(KEY_R)):
		fail("В паузе R должен рестартить как «Начать заново»")
		return false
	GameMenu.start_immediately = false
	menu._input(_unicode_only(0x043A))
	if not GameMenu.start_immediately:
		fail("_input(R) в паузе должен вызывать тот же restart")
		return false
	menu._close()
	return true


func _check_text_focus_ignores_r(scene: Node, menu: GameMenu) -> bool:
	menu._close()
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
	GameMenu.start_immediately = false
	menu._input(_key(KEY_R))
	if GameMenu.start_immediately:
		fail("_input(R) в LineEdit не должен вызывать restart")
		field.queue_free()
		return false
	field.queue_free()
	return true


func _check_button_focus_does_not_block(menu: GameMenu) -> bool:
	menu._show_pause()
	menu._primary.grab_focus()
	if GameMenu.focus_blocks_hotkeys(menu.get_viewport()):
		fail("Кнопка паузы не должна глушить R как LineEdit")
		return false
	GameMenu.start_immediately = false
	menu._input(_key(KEY_R))
	if not GameMenu.start_immediately:
		fail("R при фокусе кнопки паузы должен вызывать restart из _input")
		return false
	menu._close()
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
	var input_fn := menu_src.find("func _input")
	if input_fn < 0 or menu_src.find("wants_restart", input_fn) < 0:
		fail("R должен обрабатываться в _input, иначе фокус кнопки и пауза дерева его едят")
		return false
	if menu_src.find("func _unhandled_input") >= 0:
		fail("Рестарт не должен висеть только на _unhandled_input")
		return false
	return true
