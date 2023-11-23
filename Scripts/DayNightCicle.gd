extends DirectionalLight3D

static var full_day_length_in_seconds = 300

func _ready() -> void:
	pass # Replace with function body.


var time = 0
func _process(delta: float) -> void:
	time += delta
	@warning_ignore('integer_division')
	rotate_x(deg_to_rad(360 / full_day_length_in_seconds * delta))
