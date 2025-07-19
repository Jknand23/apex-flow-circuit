## Lap UI Display Script
## Manages the display of lap progress, race time, and countdown
## Attach to a Control node in the UI layer

extends Control

# UI element references
@onready var lap_label: Label = $LapLabel
@onready var countdown_label: Label = $CountdownLabel
@onready var race_time_label: Label = $RaceTimeLabel
@onready var best_lap_label: Label = $BestLapLabel

# Display state
var local_player_id: int = 1
var race_start_time: float = 0.0

func _ready() -> void:
	# Connect to RaceManager signals
	if RaceManager:
		RaceManager.lap_completed.connect(_on_lap_completed)
		RaceManager.race_started.connect(_on_race_started)
		RaceManager.race_finished.connect(_on_race_finished)
		RaceManager.countdown_updated.connect(_on_countdown_updated)
	
	# Initialize display
	_update_lap_display()
	countdown_label.visible = false
	race_time_label.visible = false
	best_lap_label.visible = false

func _process(_delta: float) -> void:
	# Update race timer if race is active
	if RaceManager and RaceManager.is_race_active:
		_update_race_time()

## Updates the main lap display (e.g., "LAP 2/3")
func _update_lap_display() -> void:
	if not RaceManager:
		lap_label.text = "LAP 1/3"
		return
	
	var progress = RaceManager.get_race_progress(local_player_id)
	if progress["race_finished"]:
		lap_label.text = "FINISHED!"
		lap_label.modulate = Color.GREEN
	else:
		lap_label.text = "LAP %d/%d" % [progress["current_lap"], progress["total_laps"]]
		lap_label.modulate = Color.WHITE

## Updates the current race time display
func _update_race_time() -> void:
	if not race_time_label.visible:
		race_time_label.visible = true
	
	var current_time = Time.get_ticks_msec() / 1000.0
	var race_time = current_time - race_start_time
	race_time_label.text = "TIME: %s" % _format_time(race_time)

## Updates the best lap time display
func _update_best_lap_display() -> void:
	if not RaceManager:
		return
	
	var progress = RaceManager.get_race_progress(local_player_id)
	if progress["best_lap"] > 0.0:
		best_lap_label.text = "BEST: %s" % _format_time(progress["best_lap"])
		best_lap_label.visible = true

## Formats time in MM:SS.sss format
## @param time_seconds Time in seconds to format
## @return Formatted time string
func _format_time(time_seconds: float) -> String:
	var minutes = int(time_seconds) / 60
	var seconds = int(time_seconds) % 60
	var milliseconds = int((time_seconds - int(time_seconds)) * 1000)
	return "%02d:%02d.%03d" % [minutes, seconds, milliseconds]

## Sets the local player ID for display tracking
## @param player_id The ID of the local player
func set_local_player_id(player_id: int) -> void:
	local_player_id = player_id
	_update_lap_display()

# Signal handlers

## Called when a lap is completed
## @param player_id The player who completed the lap
## @param lap_number The lap that was completed
## @param lap_time The time taken for the lap
func _on_lap_completed(player_id: int, lap_number: int, lap_time: float) -> void:
	# Only update display for local player
	if player_id == local_player_id:
		_update_lap_display()
		_update_best_lap_display()
		
		# Show lap time notification
		_show_lap_time_notification(lap_number, lap_time)

## Called when the race starts
func _on_race_started() -> void:
	race_start_time = Time.get_ticks_msec() / 1000.0
	countdown_label.visible = false
	race_time_label.visible = true
	
	# Reset lap display to show current state
	_update_lap_display()

## Called when a player finishes the race
## @param player_id The player who finished
## @param total_time The total race time
func _on_race_finished(player_id: int, total_time: float) -> void:
	# Only show for local player
	if player_id == local_player_id:
		_update_lap_display()
		_show_race_finish_notification(total_time)

## Called during countdown updates
## @param seconds Countdown seconds remaining
func _on_countdown_updated(seconds: int) -> void:
	countdown_label.visible = true
	if seconds > 0:
		countdown_label.text = str(seconds)
		countdown_label.modulate = Color.YELLOW
	else:
		countdown_label.text = "GO!"
		countdown_label.modulate = Color.GREEN

## Shows a temporary notification for lap completion
## @param lap_number The completed lap number
## @param lap_time The lap time
func _show_lap_time_notification(lap_number: int, lap_time: float) -> void:
	# Create temporary label for lap time
	var notification = Label.new()
	notification.text = "LAP %d: %s" % [lap_number, _format_time(lap_time)]
	notification.position = Vector2(get_viewport().get_visible_rect().size.x / 2 - 100, 200)
	notification.add_theme_font_size_override("font_size", 24)
	notification.modulate = Color.CYAN
	add_child(notification)
	
	# Animate notification
	var tween = create_tween()
	tween.parallel().tween_property(notification, "position:y", 150, 1.0)
	tween.parallel().tween_property(notification, "modulate:a", 0.0, 1.0)
	tween.tween_callback(notification.queue_free)

## Shows race finish notification
## @param total_time The total race time
func _show_race_finish_notification(total_time: float) -> void:
	# Create finish notification
	var notification = Label.new()
	notification.text = "RACE COMPLETE!\nTIME: %s" % _format_time(total_time)
	notification.position = Vector2(get_viewport().get_visible_rect().size.x / 2 - 150, 250)
	notification.add_theme_font_size_override("font_size", 32)
	notification.modulate = Color.GOLD
	notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(notification)
	
	# Keep notification visible longer
	var tween = create_tween()
	tween.tween_interval(3.0)
	tween.tween_property(notification, "modulate:a", 0.0, 1.0)
	tween.tween_callback(notification.queue_free) 
