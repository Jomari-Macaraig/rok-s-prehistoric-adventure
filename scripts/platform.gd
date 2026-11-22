class_name FloatingPlatform
extends Node2D
## One-way floating island (land from above, run underneath).

const TOP_INSET := 14.0   # grass top sits a little below the sprite's top edge
var width := 0.0


## The floating-island art for a zone: Terrain-variation_03_<zone>.png
## (sandstone for the desert, basalt for the volcanic zone) once the user's
## art is imported, else the forest island. Same size and silhouette, so
## TOP_INSET and the hitboxes hold for every zone.
static func island_texture(zone_id: String) -> Texture2D:
	var path := "res://assets/props/Terrain-variation_03_%s.png" % zone_id
	if zone_id != "forest" and ResourceLoader.exists(path):
		return load(path)
	return load("res://assets/props/Terrain-variation_03.png")


func setup(scale_factor: float, zone_id := "forest") -> FloatingPlatform:
	var s := Sprite2D.new()
	s.texture = island_texture(zone_id)
	s.centered = false
	s.scale = Vector2.ONE * scale_factor
	var sz := s.texture.get_size() * scale_factor
	s.position = Vector2(-sz.x * 0.5, -TOP_INSET * scale_factor)
	width = sz.x * 0.86
	add_child(s)
	return self


## Walkable top with no sprite (used on top of ledges).
func setup_invisible(w: float) -> FloatingPlatform:
	width = w
	return self


## position.y is the walkable top.
func top() -> float:
	return position.y


func covers(x: float, half_w: float) -> bool:
	return absf(x - position.x) < width * 0.5 + half_w * 0.4
