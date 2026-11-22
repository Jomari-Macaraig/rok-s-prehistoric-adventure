class_name Weather
extends CanvasLayer
## Lap twists (the user's pick for long runs): from lap 2 (every
## Zones.ZONE_LEN_M x zones metres) each lap brings a twist, in turn
## (TWISTS): a storm in the zone's own style (Forest rain, Desert sandstorm,
## Volcanic ash), fog closing in from the right, or an eclipse (main darkens
## the lighting, `light_mult`). main calls `set_twist(twist, zone_id)` every
## frame; this layer sits under the HUD and draws the particles and fog.
## Every lap past the first also adds LAP_BONUS to points (main.points_mult).

const TWISTS := ["storm", "fog", "eclipse"]
const NAMES := {"storm": "STORM", "fog": "FOG", "eclipse": "ECLIPSE"}
const HINTS := {
	"storm": "The weather turns wild.",
	"fog": "Fog rolls in: hazards appear late, so stay sharp!",
	"eclipse": "The sun goes dark.",
}

var twist := ""
var zone := ""
var _rain: CPUParticles2D
var _fog: TextureRect
var _fog_a := 0.0


## The twist for lap n ("" for the first lap).
static func twist_for_lap(n: int) -> String:
	return "" if n < 2 else TWISTS[(n - 2) % TWISTS.size()]


func _init() -> void:
	layer = 1
	_rain = CPUParticles2D.new()
	_rain.emitting = false
	_rain.amount = 160
	_rain.lifetime = 1.2
	_rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_rain.emission_rect_extents = Vector2(900, 10)
	_rain.position = Vector2(760, -30)
	_rain.gravity = Vector2.ZERO
	add_child(_rain)
	var g := Gradient.new()
	g.set_color(0, Color(0.85, 0.88, 0.9, 0.0))
	g.set_color(1, Color(0.85, 0.88, 0.9, 1.0))
	g.add_point(0.55, Color(0.85, 0.88, 0.9, 0.35))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 256
	gt.height = 4
	_fog = TextureRect.new()
	_fog.texture = gt
	_fog.stretch_mode = TextureRect.STRETCH_SCALE
	_fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fog.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fog.modulate.a = 0.0
	add_child(_fog)


## How much main's lighting is multiplied by (an eclipse darkens the world).
func light_mult() -> float:
	return 0.55 if twist == "eclipse" else 1.0


func set_twist(t: String, zone_id: String) -> void:
	if t == twist and zone_id == zone:
		return
	twist = t
	zone = zone_id
	_rain.emitting = t == "storm"
	if t == "storm":
		match zone_id:
			"forest":   # rain: fast blue streaks
				_rain.direction = Vector2(-0.25, 1).normalized()
				_rain.initial_velocity_min = 900.0
				_rain.initial_velocity_max = 1100.0
				_rain.scale_amount_min = 3.0
				_rain.scale_amount_max = 5.0
				_rain.color = Color(0.75, 0.85, 1.0, 0.7)
				_rain.amount = 260
			"desert":   # sandstorm: sideways ochre grit
				_rain.direction = Vector2(-1, 0.25).normalized()
				_rain.initial_velocity_min = 700.0
				_rain.initial_velocity_max = 1000.0
				_rain.scale_amount_min = 4.0
				_rain.scale_amount_max = 9.0
				_rain.color = Color(0.95, 0.72, 0.4, 0.75)
				_rain.amount = 320
			_:          # volcanic ash: slow grey flakes
				_rain.direction = Vector2(-0.4, 1).normalized()
				_rain.initial_velocity_min = 120.0
				_rain.initial_velocity_max = 220.0
				_rain.scale_amount_min = 4.0
				_rain.scale_amount_max = 7.0
				_rain.color = Color(0.6, 0.55, 0.55, 0.8)
				_rain.amount = 200
		_rain.lifetime = 1.4 if zone_id != "volcanic" and zone_id != "" else 4.0


func _process(delta: float) -> void:
	var want := 0.85 if twist == "fog" else 0.0
	_fog_a = lerpf(_fog_a, want, minf(delta * 1.5, 1.0))
	_fog.modulate.a = _fog_a
	var vw := get_viewport().get_visible_rect().size.x
	_rain.position.x = vw * 0.6
	_rain.emission_rect_extents.x = vw * 0.7
