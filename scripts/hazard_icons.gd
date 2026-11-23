class_name HazardIcons
## Pictures of hazards for the info cards and the Field Guide, in each zone's
## look (the same art and tints Course and Terrain use there).
##
## icon(key, zid) -> Texture2D. zid "" means the hazard's own icon from
## Codex (HAZARDS / TERRAIN), as before. A key listed in ZONE_ICONS uses its
## zone's spec instead; a missing zone falls back to the first one listed.
##
## A spec is one of:
##   "<Prop>"                  assets/props/<Prop>.png
##   "res://…png"              any texture
##   "trap:<anim>:<frame>"     one frame of a trap sheet, cropped to its art
##   "liquid:<anim>"           a trap's left/mid/right strip (water, lava, quicksand)
##   "gap:<zone>[:<liquid>]"   a pit cut into that zone's ground, optionally filled
##   "critter:<kind>"          that zone's wild dinosaur of this kind (its portrait)
## and may end in "@stone", "@wood" or "@thorn" for Course's zone tints.

const P := "res://assets/props/%s.png"

const ZONE_ICONS := {
	"small": {"forest": "Stones_03", "desert": "Stones_03@stone", "canyon": "res://assets/canyon/stone_scatter.png", "volcanic": "Stones_03@stone"},
	"log": {"forest": "Logs_03", "desert": "Logs_03@wood", "canyon": "res://assets/canyon/sandstone_spikes.png", "volcanic": "Logs_03@wood"},
	"fence": {"forest": "Fences_01", "desert": "Fences_01@wood", "canyon": "res://assets/canyon/wooden_barricade.png", "volcanic": "Fences_01@wood"},
	"tall_fence": {"forest": "Fences_03", "desert": "Fences_03@wood", "canyon": "res://assets/canyon/tall_rock_pillar.png", "volcanic": "Fences_03@wood"},
	"thorn_bush": {"forest": "Grasses_16", "desert": "Grasses_16@thorn", "canyon": "res://assets/canyon/tumble_thorn.png", "volcanic": "Stones_03@stone"},
	"boulder": {"forest": "Stones_04", "desert": "trap:desert_wall_break:0", "canyon": "res://assets/canyon/sandstone_boulder.png", "volcanic": "trap:volcanic_wall_break:0"},
	"wall": {"forest": "Tile-3_08", "desert": "trap:desert_wall_break:0", "canyon": "res://assets/canyon/cracked_sandstone_wall.png", "volcanic": "trap:volcanic_wall_break:0"},
	"ledge": {"forest": "res://assets/traps/forest_overhead.png", "desert": "res://assets/traps/desert_fossil_arch.png", "canyon": "res://assets/canyon/rock_arch.png",
			"volcanic": "res://assets/props/Terrain-variation_03_volcanic.png"},
	"gate_tri": {"forest": "trap:forest_log_break:0", "desert": "trap:desert_wall_break:0", "canyon": "trap:desert_wall_break:0", "volcanic": "trap:volcanic_wall_break:0"},
	"gate_raptor": {"desert": "trap:desert_bridge_collapse:0", "forest": "Logs_05", "canyon": "trap:desert_bridge_collapse:0", "volcanic": "Logs_05"},
	"pit": {"forest": "gap:forest", "desert": "gap:desert", "canyon": "gap:canyon", "volcanic": "gap:volcanic"},
	"gate_ptera": {"forest": "gap:forest", "desert": "gap:desert", "canyon": "gap:canyon", "volcanic": "gap:volcanic:lava"},
	"gate_water": {"forest": "gap:forest:water"},
	"gate_lava": {"volcanic": "gap:volcanic:lava"},
	"quicksand": {"desert": "liquid:desert_quicksand"},
	"steam": {"volcanic": "trap:volcanic_steam:4"},
	"rolling_boulder": {"volcanic": "trap:volcanic_boulder:0"},
	"stampede": {"forest": "critter:stampede", "desert": "critter:stampede", "canyon": "critter:stampede", "volcanic": "critter:stampede"},
	"swooper": {"forest": "critter:swooper", "desert": "critter:swooper", "canyon": "critter:swooper", "volcanic": "critter:swooper"},
	"diver": {"forest": "critter:swooper", "desert": "critter:swooper", "canyon": "critter:swooper", "volcanic": "critter:swooper"},
}

static var _cache := {}


## The picture for a hazard (or terrain feature) in a zone ("" = its own icon).
static func icon(key: String, zid := "") -> Texture2D:
	if ZONE_ICONS.has(key):
		var by_zone: Dictionary = ZONE_ICONS[key]
		var z := zid if by_zone.has(zid) else String(by_zone.keys()[0])
		return from_spec(by_zone[z], z)
	for h in Codex.HAZARDS + Codex.TERRAIN:
		if h.key == key:
			return from_spec(h.icon, zid)
	if key == "egg":
		return load(P % "Other_04")
	return null


## The zones a hazard looks different in (for the Field Guide's row), in zone order.
static func variant_zones(key: String) -> Array:
	if not ZONE_ICONS.has(key):
		return []
	var out := []
	for z in Zones.ZONES:
		if ZONE_ICONS[key].has(z.id):
			out.append(z.id)
	return out


static func from_spec(spec: String, zid := "") -> Texture2D:
	var key := spec + "#" + zid
	if _cache.has(key):
		return _cache[key]
	var tint := Color.WHITE
	var s := spec
	if "@" in s:
		var parts := s.split("@")
		s = parts[0]
		var table: Dictionary = {"stone": Course.STONE_TINT, "wood": Course.WOOD_TINT, "thorn": Course.THORN_TINT}[parts[1]]
		tint = table.get(zid, Color.WHITE)
	var tex: Texture2D
	if s.begins_with("trap:"):
		var p := s.split(":")
		tex = _cropped(SpriteLib.trap(p[1]).get_frame_texture("a", int(p[2])))
	elif s.begins_with("liquid:"):
		tex = ImageTexture.create_from_image(_liquid_strip(s.split(":")[1], 2))
	elif s.begins_with("gap:"):
		var p := s.split(":")
		tex = _gap(p[1], p[2] if p.size() > 2 else "")
	elif s.begins_with("critter:"):
		var id := Critters.for_zone(zid if zid != "" else "forest", s.split(":")[1])
		tex = load("res://assets/portraits/%s.png" % id)
	else:
		tex = load(s if s.begins_with("res://") else P % s)
	if tex != null and tint != Color.WHITE:
		var img := _rgba(tex)
		for y in img.get_height():
			for x in img.get_width():
				img.set_pixel(x, y, img.get_pixel(x, y) * tint)
		tex = ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


static func _rgba(tex: Texture2D) -> Image:
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	return img


## A texture trimmed to its opaque pixels (trap frames have a lot of room).
static func _cropped(tex: Texture2D) -> Texture2D:
	var img := _rgba(tex)
	var r := img.get_used_rect()
	if r.size.x <= 0:
		return tex
	return ImageTexture.create_from_image(img.get_region(r))


## Frame 0 of a liquid's left, mid (n times) and right pieces side by side,
## from the surface down (so it reads as a pool).
static func _liquid_strip(anim: String, n: int) -> Image:
	var m: Dictionary = SpriteLib.trap_meta()[anim]
	var top := int(m.surface_y) - 14
	var pieces := ["left"]
	for i in n:
		pieces.append("mid")
	pieces.append("right")
	var imgs := []
	var w := 0
	for part in pieces:
		var img := _rgba(SpriteLib.trap(anim, part).get_frame_texture("a", 0))
		imgs.append(img)
		w += img.get_width()
	var h: int = imgs[0].get_height() - top
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var x := 0
	for img in imgs:
		out.blend_rect(img, Rect2i(0, top, img.get_width(), h), Vector2i(x, 0))
		x += img.get_width()
	return out.get_region(out.get_used_rect())


## A pit in a zone's ground: two cliff edges with a gap (or a liquid) between.
static func _gap(zid: String, liquid: String) -> Texture2D:
	const EDGE := 84
	const H := 130
	const GAP := 84
	var left: Image
	var right: Image
	if zid == "forest":
		left = _rgba(load("res://assets/terrain/cap_right.png"))   # the ground ending
		right = _rgba(load("res://assets/terrain/cap_left.png"))   # ...and starting again
	else:
		var strip := _rgba(load("res://assets/terrain/%s_ground.png" % zid))
		left = strip.get_region(Rect2i(0, 0, EDGE, H))
		right = strip.get_region(Rect2i(strip.get_width() / 2, 0, EDGE, H))
	var h := maxi(left.get_height(), right.get_height())
	var out := Image.create(left.get_width() + GAP + right.get_width(), h, false, Image.FORMAT_RGBA8)
	if liquid != "":
		var anim: String = {"water": "forest_water", "lava": "volcanic_lava"}[liquid]
		var pool := _liquid_strip(anim, 1)
		pool.resize(GAP + 24, h - 22)
		out.blend_rect(pool, Rect2i(Vector2i.ZERO, pool.get_size()), Vector2i(left.get_width() - 12, 22))
	out.blend_rect(left, Rect2i(Vector2i.ZERO, left.get_size()), Vector2i(0, 0))
	out.blend_rect(right, Rect2i(Vector2i.ZERO, right.get_size()), Vector2i(left.get_width() + GAP, 0))
	return ImageTexture.create_from_image(out.get_region(out.get_used_rect()))
