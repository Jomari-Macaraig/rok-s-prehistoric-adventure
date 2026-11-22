class_name Combo
extends RefCounted
## Combo streak and Primal Frenzy (the user's picks for keeping long runs
## exciting). main owns one (`main.combo`) and feeds it events; all numbers
## live in tuning.gd (COMBO_*, FRENZY_*).
##
## Streak: every clean feat (an obstacle passed or smashed, a pit or quicksand
## crossed, a dino gate, a wild dinosaur led to the hunter) adds to `count`.
## The count sets the tier (COMBO_TIERS: x1 .. x5), which multiplies points
## (main.points_mult) and meat per pickup. Pickups don't add to the count but
## keep the streak alive. COMBO_WINDOW seconds with no feat, or any stumble
## (main._stumble), ends the streak.
##
## Primal Frenzy: feats also fill `meter`. Full, it starts a frenzy of
## FRENZY_TIME seconds: Rok smashes through every obstacle (dino gate walls
## too), bowls wild dinosaurs over, pulls away from the hunter and meat rains
## down. Pits, liquids and quicksand still count. Feats during a frenzy still
## build the streak but not the meter, which drains as the frenzy runs.

signal tier_up(tier: int)
signal broken(count: int)
signal frenzy_started
signal frenzy_ended

var count := 0
var tier := 0            # index into Tuning.COMBO_TIERS
var window := 0.0        # seconds left before the streak lapses
var meter := 0.0         # 0..1 toward Primal Frenzy
var frenzy_t := 0.0      # seconds of frenzy left
var best := 0            # this run's longest streak


func reset() -> void:
	count = 0
	tier = 0
	window = 0.0
	meter = 0.0
	frenzy_t = 0.0
	best = 0


func in_frenzy() -> bool:
	return frenzy_t > 0.0


## The points multiplier for the current tier.
func mult() -> float:
	return float(Tuning.COMBO_TIERS[tier][1])


## Meat per meat pickup: the multiplier's whole part (x1.5 -> 1, x2 -> 2).
func meat_per_pickup() -> int:
	return maxi(int(floorf(mult())), 1)


## A clean feat worth `weight` (1 for most, more for big ones).
func feat(weight := 1) -> void:
	count += weight
	best = maxi(best, count)
	window = Tuning.COMBO_WINDOW
	var t := tier
	while t + 1 < Tuning.COMBO_TIERS.size() and count >= int(Tuning.COMBO_TIERS[t + 1][0]):
		t += 1
	if t > tier:
		tier = t
		tier_up.emit(tier)
	if not in_frenzy():
		meter = minf(meter + Tuning.FRENZY_FILL * weight, 1.0)
		if meter >= 1.0:
			frenzy_t = Tuning.FRENZY_TIME
			frenzy_started.emit()


## A pickup keeps the streak going without adding to it.
func keep_alive() -> void:
	if count > 0:
		window = maxf(window, Tuning.COMBO_WINDOW * 0.5)


## A stumble or hit: the streak ends and the meter loses FRENZY_HIT_LOSS.
## A frenzy can't be hit (main doesn't call this during one).
func hit() -> void:
	_end_streak()
	meter = maxf(meter - Tuning.FRENZY_HIT_LOSS, 0.0)


func step(delta: float) -> void:
	if in_frenzy():
		frenzy_t = maxf(frenzy_t - delta, 0.0)
		meter = frenzy_t / Tuning.FRENZY_TIME
		if frenzy_t <= 0.0:
			meter = 0.0
			frenzy_ended.emit()
		return
	if count > 0:
		window -= delta
		if window <= 0.0:
			_end_streak()


func _end_streak() -> void:
	if count > 0:
		broken.emit(count)
	count = 0
	tier = 0
	window = 0.0
