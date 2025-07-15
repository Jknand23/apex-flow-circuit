# scripts/cadence_manager.gd
# Manages the Velocity Cadence bar: decay, updates, and future build-up logic.
# Attach to ProgressBar node in UI. Decays over time to force player action.

extends ProgressBar

# Tunable constants (tweak for game feel).
const MAX_CADENCE: float = 100.0  # Full bar value.
const DECAY_RATE: float = 10.0    # Points lost per second (e.g., 10% of max).

# Descriptive state vars.
var current_cadence: float = MAX_CADENCE / 2  # Start at 50% for testing.

# Function to update the bar visually.
# Called every frame or on changes.
func update_bar() -> void:
	value = current_cadence

# Function to apply decay.
# @param delta: float - Time since last frame (for frame-independent decay).
func apply_decay(delta: float) -> void:
	current_cadence = max(current_cadence - DECAY_RATE * delta, 0.0)
	update_bar()

func _ready() -> void:
	max_value = MAX_CADENCE
	min_value = 0
	update_bar()  # Initial sync.

func _process(delta: float) -> void:
	apply_decay(delta)  # Constant decay – vibe test the rate!
