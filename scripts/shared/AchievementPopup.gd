extends Control
# ═══════════════════════════════════════════════════
# AchievementPopup.gd
# Slides in from top-right, auto-dismisses after 3s.
# ═══════════════════════════════════════════════════

func show_achievement(id: String) -> void:
	var info: Dictionary = ProgressTracker.ACHIEVEMENTS.get(id, {}) as Dictionary
	if info.is_empty(): return

	AudioManager.play_sfx("achieve")

	var panel := ColorRect.new()
	panel.color = Color("#1a1a2e")
	panel.set_size(Vector2(320, 70))
	panel.set_position(Vector2(1280, 20))  # starts off-screen
	add_child(panel)

	var accent := ColorRect.new()
	accent.color = Color("#FFD93D")
	accent.set_position(Vector2(0, 0))
	accent.set_size(Vector2(4, 70))
	panel.add_child(accent)

	var tag := Label.new()
	tag.text = "Achievement Unlocked!"
	tag.set_position(Vector2(14, 6))
	tag.add_theme_font_size_override("font_size", 10)
	tag.add_theme_color_override("font_color", Color("#FFD93D"))
	panel.add_child(tag)

	var name_lbl := Label.new()
	name_lbl.text = info.get("name","") as String
	name_lbl.set_position(Vector2(14, 22))
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color("#e8e8f0"))
	panel.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = info.get("desc","") as String
	desc_lbl.set_position(Vector2(14, 44))
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color("#888899"))
	panel.add_child(desc_lbl)

	# Slide in
	var tw := create_tween()
	tw.tween_property(panel, "position", Vector2(948, 20), 0.4)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Auto-dismiss after 3s
	await get_tree().create_timer(3.2).timeout
	var tw2 := create_tween()
	tw2.tween_property(panel, "position", Vector2(1280, 20), 0.3)
	tw2.tween_callback(queue_free)
