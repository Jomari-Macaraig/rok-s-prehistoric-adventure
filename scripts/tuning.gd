class_name Tuning
## Every gameplay number lives here.

const VIEW_W := 1280.0
const VIEW_H := 720.0
const GROUND_Y := 560.0          # base feet line (raised so buttons fit on the dirt below)
const GROUND_STRIP_TOP := 550.0  # base ground level, top of the grass texture
const FEET_BELOW_GRASS := 8.0    # feet sit this far below the tiles' grass tips

# Terrain shape
# One level = the slope tile's rise (47 px, from assets/terrain/terrain.json)
const FLAT_MIN := 650.0
const FLAT_MAX := 1500.0
const PIT_MIN := 150.0
const PIT_MAX := 260.0
const HILL_CHANCE := 0.35        # per terrain section
const QUICKSAND_CHANCE := 0.22   # per terrain section in the Desert
const QUICKSAND_MIN := 520.0
const QUICKSAND_MAX := 720.0
const SINK_RATE := 1.4           # quicksand: full sink after ~0.7 s standing as Rok
const SINK_RATE_FAST := 0.35     # the Raptor skims across
const SINK_RATE_HEAVY := 1.9     # Triceratops / Spinosaurus sink faster
const SINK_RECOVER := 3.0        # per second once clear of the sand (not while airborne over it)
# Deep quicksand: once the Raptor is unlocked, quicksand grows with the world
# speed so Rok can't bound across it (see Terrain.quicksand_width).
const QUICKSAND_SAFE := 0.85     # before the Raptor: at most this share of Rok's longest bound
const QUICKSAND_DEEP := 1.08     # after: this much wider than Rok's bound + one escape hop
const QUICKSAND_PLUNGE := 0.55   # landing on the sand from the air adds this much sink (Rok)
const CELEBRATE_WINDOW := 4.0   # s after passing the best flag in which a jump celebrates
const QUICKSAND_GRIP := 0.6      # jump strength off the sand; such a jump gets no air jump
const STUMBLE_STEAM := 90.0      # an active steam vent staggers Rok
const ROLL_SPEED := 170.0        # rolling boulders come at you this much faster
const LARGE_HILL_CHANCE := 0.16  # per terrain section, from ground level
const LARGE_HILL_STEPS := 3      # levels a large hill climbs
const HILL_TOP_TILES_MIN := 1     # a hill = slope up, 1-3 blocks, slope down
const HILL_TOP_TILES_MAX := 3
const PIT_CHANCE := 0.22         # per terrain section, rises with difficulty
const GROUND_SNAP := 24.0        # max drop per frame that still counts as running downhill
const PLAYER_X := 335.0          # leaves room for the left thumb cluster

# Touch UI
const UI_MARGIN := 36.0          # keeps buttons clear of phone notches / rounded corners
const FORM_BUTTON_SIZE := 96.0
const JUMP_BUTTON_SIZE := 132.0
const SLIDE_BUTTON_SIZE := 108.0
# Thumb clusters (angles in degrees: 0 = right, 90 = up)
const MAIN_FORM_SIZE := 104.0    # Rok, bottom-left corner
const ARC_FORM_SIZE := 78.0      # the four dinosaurs arcing around Rok
const LEFT_ARC_R := 152.0   # wide enough that the dino rings (TouchButton.FRAME_OUT) never touch
const LEFT_ARC_DEG := [-6.0, 34.0, 70.0, 106.0]
const SLOT_BUTTON_SIZE := 78.0   # booster slots
const RIGHT_ARC_R := [150.0, 164.0, 166.0, 164.0]   # SLIDE, slots 1-3 (a test checks no control overlaps another)
const RIGHT_ARC_DEG := [186.0, 146.0, 113.0, 80.0]

# World speed (px/s)
const START_SPEED := 380.0
const MAX_SPEED := 900.0
const SPEED_RAMP := 3.0          # px/s gained per second (≈ +180 px/s per minute)
const PX_PER_M := 40.0           # world pixels per displayed metre
const GRAVITY := 2700.0
const JUMP_CUT := 0.75            # velocity kept when jump is released early (a tap still clears a small rock)
const JUMP_TAP_TIME := 0.08      # a tap that ends before the jump starts is cut this long after takeoff
const COYOTE_TIME := 0.09
const FAST_FALL_SPEED := 1500.0  # pressing slide in the air slams down
const SLIDE_MIN := 0.62          # a tapped slide lasts at least this long (s)
const SLIDE_MAX := 1.3           # (unused: holding SLIDE no longer turns into a duck, the user's rule)
const SLIDE_BUFFER := 0.2        # a SLIDE press this close to the end of its cooldown still slides when ready
# Pteranodon flight
const FLY_RISE := 430.0          # climb speed while JUMP is held
const FLY_ACCEL := 2600.0
const GLIDE_FALL := 150.0        # max sink speed while gliding
const FLY_CEILING := 210.0       # highest feet line in flight (keeps clear of the HUD)
const SKY_TRAIL_CHANCE := 0.12   # high amber trails worth flying for
const LEDGE_CLEARANCE := 110.0   # gap under a low ledge: Rok/Spinosaurus must slide
const JUMP_BUFFER := 0.12

# Primal energy (powers dinosaur forms)
const ENERGY_MAX := 100.0
const ENERGY_START := 60.0
const SHIFT_MIN_ENERGY := 15.0
const SHIFT_COOLDOWN := 0.35
# The user's shapeshift burst (assets/fx/transform_burst, Player.play_transform).
# Shapeshifting stays instant, so the burst starts on this frame (3 = its
# first covering frame: the swap happens hidden under the cloud); 0 would
# show the whole build-up after the change.
const TRANSFORM_FX_START := 3
const TRANSFORM_FX_COVER := 0.8
# The user's power-up effects (Player.powerup_fx / set_power_aura): the ring is this wide
# against the form's drawn frame (its bigger side).
const POWERUP_FX_SIZE := 0.75   # the solid cloud covers this share of the bigger form's frame
const AMBER_ENERGY := 15.0       # energy per amber as Rok
const AMBER_ENERGY_DINO := 7.0   # ...and while in a dino form (Rok is the form for recharging)
# Staying a dino gets more tiring: the drain grows with the time spent as a
# dino (summed across dino forms, reset only by going back to Rok):
# ×2 after DRAIN_DOUBLE_TIME seconds, ×3 after twice that, and so on.
const DRAIN_DOUBLE_TIME := 8.0
# T-rex chase: gap (px) between its snout and Rok
const CHASE_GAP_MAX := 250.0     # comfortable distance: only its head shows at the left edge
const CHASE_GAP_START := 250.0   # right after the intro roar (Rok can't win distance back on foot)
const CHASE_RECOVER := 0.0       # Rok runs at the T-rex's pace: the gap holds steady
const STUMBLE_THORN := 115.0     # brushing a thorn bush trips Rok up
# Mushrooms don't end the run: Rok squashes them and the spores make him dizzy
const STUMBLE_VINE := 90.0       # running into a Forest vine branch
const CRITTER_EAT_X := 30.0      # a critter is eaten once it's this close to the T-rex's snout
const STUMBLE_ROCK := 90.0       # tripping over a small rock
const STUMBLE_MUSHROOM := 50.0   # a small stumble (the T-rex gains a little)
const DIZZY_TIME := 3.0          # seconds of dizziness
# T-rex charges (distances in config [trex]): a warning, then it gains fast
const CHARGE_WARN := 1.5         # seconds of roaring before it charges
const CHARGE_ALARM_DELAY := 0.45  # seconds after the roar before Rok shouts to run
# (how long a charge lasts and how fast it gains depend on the hunter: Hunters.DATA)
const SNAG_HOLD := 0.35          # seconds the vine holds Rok (struggle loop) before he pushes through
const DIZZY_JUMP := 0.8          # jumps are this much lower while dizzy
const STUMBLE_SHIELD := 70.0     # a shield hit staggers him
const CHASE_DANGER := 110.0      # below this: red edge pulse
const CHASE_GAP_FAR := 480.0     # the biggest lead (downhill slides, the Raptor, peppers): kept until a stumble or charge
# Peppers: a short burst of speed
const PEPPER_BOOST_TIME := 2.5      # seconds
## Every run offers a pepper at Progression.intro_m("pepper") (config [introductions] pepper).
const PEPPER_BOOST_PACE := 1.3      # world speed during the boost
const PEPPER_CHASE_GAIN := 90.0     # px/s pulled away from the T-rex during the boost
const UPHILL_LOSS := 85.0        # px/s the hunter gains while Rok (or a slow dino) climbs; the Raptor doesn't lose ground
const SLIDE_DOWNHILL_GAIN := 170.0  # px/s gained sliding down a slope
const UPHILL_PACE := 0.86        # world speed while climbing
const DOWNHILL_SLIDE_PACE := 1.18   # world speed while sliding downhill
const TREX_ROAR_EVERY := Vector2(11.0, 19.0)   # seconds between chase roars (faster when close)
const DEATH_FREEZE := 0.5        # Rok freezes on the hit before the death hop
const DEATH_HOP := 900.0         # upward kick of the death hop
const INFO_MIN_TIME := 0.6       # an info card can't be tapped away sooner (so a jump tap doesn't skip it)
const INTRO_TIME := 1.7          # roar cutscene at the start of each run
const INTRO_PLAYER_X := 680.0    # Rok stands here during the roar so the whole T-rex fits
const INTRO_ROAR_GAP := 90.0     # snout-to-Rok distance while it roars

# Score
const SCORE_PER_PX := 0.02
const SMASH_SCORE := 50
const PEPPER_SCORE := 250
const AMBER_SCORE := 25
const MEAT_SCORE := 25
# Reward spots (amber arcs, floating islands, sky trails) hold one kind each:
# Pickups per amber/meat/mixed spot: chance of 1, 2, 3 or 4 (average about 2.2;
# it used to be always 3). Under a low ledge it's capped at 3.
const SPOT_COUNT_WEIGHTS := [0.35, 0.3, 0.2, 0.15]
const POWER_SPOT_CHANCE := 0.1   # a lone power-up
const HEART_SPOT_CHANCE := 0.025 # a lone heart: rare (about one per few km)
const MEAT_SPOT_CHANCE := 0.1    # all meat
const MIXED_SPOT_CHANCE := 0.06  # the rare spot with amber and meat together
# ...the rest are all amber.
const MEAT_DUE_M := 400.0        # a spot turns to meat if none came for this many metres

# Power-ups bought in the Market (Boosters)
const SHIELD_CHARGES := 1        # (unused: the Amber Shield became Primal Amber, an energy refill)
const MAGNET_TIME := 7.0         # Fossil Magnet
const MAGNET_RADIUS := 360.0     # px around Rok
const MAGNET_PULL := 1100.0      # px/s
const SLOW_TIME := 4.0           # Time Crystal
const SLOW_PACE := 0.65          # world speed while slowed
const SLOW_CHASE_GAIN := 35.0    # gap/s won from the slowed T-rex
const BERRY_TIME := 8.0          # Primal Berry: free, instant shapeshifting
const GOLD_TIME := 10.0          # Golden Fossil
## Pitch of the shared activation sound (powerup_activate) per power-up, so
## each one sounds a little different (missing = 1.0).
const POWERUP_SOUND_PITCH := {"pepper": 1.0, "amber_shield": 0.9, "fossil_magnet": 1.15,
		"time_crystal": 0.75, "primal_berry": 1.25, "golden_fossil": 1.05}
const GOLD_MULT := 2.0           # points multiplier

# Combo streak and Primal Frenzy (combo.gd)
# [feats needed, points multiplier]: x1.5 after 5 clean feats .. x5 after 60
const COMBO_TIERS := [[0, 1.0], [5, 1.5], [12, 2.0], [24, 3.0], [40, 4.0], [60, 5.0]]
const COMBO_WINDOW := 6.0        # s without a feat before the streak lapses
const COMBO_GATE_WEIGHT := 3     # a dino gate counts as this many feats
const COMBO_SNACK_WEIGHT := 2    # a wild dinosaur led to the hunter
const FRENZY_FILL := 0.03        # meter per feat (about 33 feats to Primal Frenzy)
const FRENZY_HIT_LOSS := 0.35    # a stumble knocks this much off the meter
const FRENZY_TIME := 8.0         # s of Primal Frenzy
const FRENZY_CHASE_GAIN := 90.0  # px/s of lead on the hunter during a frenzy
const FRENZY_MEAT_EVERY := 0.7   # s between meat drops ahead of Rok during a frenzy
const FRENZY_END_INVULN := 1.2   # grace after a frenzy so it can't end in a crash

const ZONE_WALL_PIECE_H := 87.0  # px per sandstone/basalt wall piece (matches Forest wall heights)
# Attack (main._attack): the ATTACK button lunges at the nearest thing ahead
const TUTORIAL_GAP := 34.0        # px between the Tutorial button and the Marketplace below it (its name sits there)
const TUTORIAL_BUTTON_SIZE := 92.0  # the main menu's Tutorial button (right edge, above the Marketplace)
## Elder Numa's murmur when she speaks: Ugo's mumbles, pitched up and softer.
const NUMA_PITCH := 1.35
const NUMA_DB := -4.0
const KORA_PITCH := 1.2    # Kora the Craftkeeper's murmur (Workshop.kora_say): brighter than Ugo, lower than Numa
const KORA_DB := -3.0
## The Camp's staged dinosaur or hero idles and now and then attacks, jumps or slides:
## seconds before the first attack and between attacks (random in the range).
const CAMP_ATTACK_FIRST := Vector2(1.2, 2.5)
const CAMP_ATTACK_EVERY := Vector2(3.5, 7.0)
const SIDE_BUTTON_SIZE := 104.0  # Encyclopedia / Dinosaurs (left edge) and Marketplace (right edge) square buttons
const TITLE_BANNER_H := 62.0     # the user's banners (ENCYCLOPEDIA, MARKETPLACE, DINOSAURS) as screen titles
const STOP_CONFIRM_TIME := 3.0   # s the Stop button waits for its second tap
const ATTACK_BUTTON_SIZE := 92.0
const ATTACK_R := 262.0          # from the JUMP button's centre ...
const ATTACK_DEG := 172.0        # ... at this angle (left of SLIDE, on the dirt)
const ATTACK_COOLDOWN := 1.8     # s between attacks, from the press (shortened by Power: Dinos.cooldown_mult)
const SLIDE_COOLDOWN := 2.2      # s from a slide's press to the next (the slide itself takes ~1 s; shortened by Speed)
const JUMP_COOLDOWN := 0.0       # no jump cooldown (the user's call); >0 would make ground jumps wait after landing, shortened by Jump
const LOOT_CHANCE := 0.12         # a broken obstacle drops loot (main._break_loot; the user's rule)
const LOOT_HEART_SHARE := 0.15    # ...of which a heart (amber at full health)
const LOOT_POWER_SHARE := 0.2     # ...a power-up the player owns; the rest is amber
const LOOT_AMBER := 3             # amber pieces in an amber drop
const CARD_DROP_CHANCE := 0.25   # a bonked wild dinosaur drops its own card (always the first time per species)
const COOLDOWN_CUT_PER_POINT := 0.04   # each attribute point cuts a cooldown by 4% (40% at 10)
const ATTACK_REACH_HAND := 150.0 # px ahead a hero reaches bare-handed (weapons reach further)
const ATTACK_REACH_DINO := 190.0 # px ahead a dinosaur reaches
const ATTACK_METEOR_REACH := 140.0  # extra reach for a falling meteor rock (any height)
const ATTACK_POWER_WOOD := 4.0   # Power needed to break logs and thorn bushes
const ATTACK_POWER_FENCE := 6.0  # ... fences
const ATTACK_POWER_ROCK := 7.0   # ... boulders and walls (dino gates never break)
const CRITTER_WEIGHT := 2.2      # wild dinosaurs (stampede, swooper) come up this much more often
# Diving flyers: a swooper that comes in high and dives at Rok (introduction "diver";
# its distance is in config/progression.cfg). The dive follows the flyer's distance
# ahead of Rok, so it lines up at any speed.
const DIVE_CHANCE := 0.4         # once its lesson is over, a swooper dives this often
const DIVE_START_H := 300.0      # px its underside starts above the ground (out of reach)
const DIVE_FROM_X := 620.0       # px ahead of Rok where the dive starts (it screeches)
const DIVE_TO_X := 140.0         # px ahead of Rok where it bottoms out
const DIVE_DIP := 0.0            # px below its species' normal flying height at the bottom (0: slide under it, the Raptor fits standing)
const DIVE_SPEED_MULT := 1.25    # a diver closes in this much faster than a level swooper
const DIVE_TILT := 0.4           # radians it tips nose-down mid-dive

# Mid-run events (run_events.gd)
const EVENT_FROM_M := 1200.0     # no events before this far into a run
const EVENT_GAP_MIN := 700.0     # metres between events
const EVENT_GAP_MAX := 1100.0
const METEOR_EVERY := 2.2        # s between falling rocks in a meteor shower (gentler: the user found it hard)
const METEOR_FALL := 1.1         # s a rock takes to fall (the shadow warns that long)
const AMBER_STORM_EVERY := 0.45  # s between amber drops in an amber storm
const STAMPEDE_RUSH_EVERY := 2.4 # s between wild dinosaurs in a stampede
const GOLDEN_HOUR_MEAT := 2      # meat multiplier during a golden hour

# Bonus zones (main._bonus_step, bonus_portal.gd)
# coach hints (the tutorial, tutorial.gd / main._coach_step)
const COACH_NEAR := 40.0          # px ahead of Rok an obstacle's hint starts...
const COACH_FAR := 420.0          # ...and the furthest it looks
const COACH_TALL := 60.0          # a "hold to jump higher" obstacle is at least this tall (px)
const COACH_WALL := 110.0         # a "double jump" obstacle is at least this tall
const COACH_HOLD_JUMP := 0.25     # s JUMP held after a ground jump counts as a high jump
const COACH_SLOT_WAIT := 3.0      # s a ready power-up sits unused before its hint
const COACH_LOW_ENERGY := 22.0    # energy as a dino that brings the "back to Rok" hint
const COACH_SKIP_BASICS_M := 1500.0   # an old save past this best distance skips the basic move lessons
const TIPS_BUTTON_SIZE := 112.0   # the pause screen's Tips on/off button
const MENU_GRACE := 0.35         # s after the summary card before a tap on the main menu starts a run
const BONUS_ENABLED := false     # bonus zones (portals) are off for now (the user's call); true brings them back
const BONUS_FROM_M := 700.0      # the first portal can come after this far
const BONUS_GAP_MIN := 1000.0    # metres between portals
const BONUS_GAP_MAX := 1600.0
const BONUS_TIME := 9.0          # s inside the bonus zone
const BONUS_DROP_EVERY := 0.28   # s between treasures inside it
const BONUS_CLEAR := 900.0       # px of empty, flat ground after the portal before it opens

# Lap twists (weather.gd): every lap past the first adds this to points
const LAP_BONUS := 0.25
const LAP_BANNER_DELAY := 2.8    # s after the lap starts (the zone banner goes first)

# Daily missions (missions.gd)
const MISSION_MEAT := 25         # meat for each mission done
const MISSION_ALL_MEAT := 50     # bonus for all three in a day ...
const MISSION_STREAK_MEAT := 15  # ... + this per day of the streak after the first
const MISSION_STREAK_MAX := 6    # (capped)

# Milestone chests (chest.gd): one on the ground every CHEST_EVERY_M of a run
const CHEST_EVERY_M := 1000.0
# Defaults only: config/pickups.cfg [chests] sets these (Chest reads it).
# Chance of each rarity: [at the first milestone, + per milestone after, cap]
const CHEST_ODDS := {"rare": [0.22, 0.03, 0.45], "ultra_rare": [0.04, 0.04, 0.30], "legendary": [0.01, 0.015, 0.12]}
const CHEST_MEAT := [4, 8, 15, 30]   # common / rare / ultra rare / legendary meat (+1 per milestone)
const CHEST_XP := [150, 400, 1000, 2500]   # ... XP for the form Rok is in
const CHEST_SCORE := 500         # points for opening any chest (default; pickups.cfg [chests] score)
const CHEST_COMBO_WEIGHT := 2    # a chest counts as this many combo feats

# Escalating pickups: the further a run goes, the richer its pickups
const BIG_MEAT_FROM_M := 2000.0 # big meat (worth BIG_MEAT_VALUE) starts here ...
const BIG_MEAT_FULL_M := 6000.0 # ... and reaches BIG_MEAT_MAX_CHANCE of meat here
const BIG_MEAT_MAX_CHANCE := 0.4
const BIG_MEAT_VALUE := 3       # meat per big meat
const BIG_MEAT_SCALE := 0.8     # big meat is the meat art drawn this big (meat is 0.47)
const FOSSIL_FROM_M := 4000.0    # rare fossils start appearing here ...
const FOSSIL_FULL_M := 9000.0    # ... becoming as common as FOSSIL_MAX_CHANCE here
const FOSSIL_MIN_CHANCE := 0.03  # share of reward spots holding a fossil
const FOSSIL_MAX_CHANCE := 0.08
const FOSSIL_MEAT := 8
const FOSSIL_SCORE := 1500

# Spawning: gap between obstacles is measured in seconds of travel.
# gap between hazards, in seconds of travel: generous while learning,
# tightening with Progression.pressure()
const GAP_EARLY := Vector2(1.6, 2.6)
const GAP_LATE := Vector2(0.9, 1.5)
const INTRO_GAP_MULT := 1.6      # extra space around a newly introduced hazard
const PLATFORM_CHANCE := 0.22
const PICKUP_CHANCE := 0.45

# Parallax factors (fraction of world speed)
const PARALLAX_MOUNTAINS := 0.08
const PARALLAX_FAR_TREES := 0.16
const PARALLAX_TREES := 0.28
const PARALLAX_BACK_DECOR := 0.55
const PARALLAX_FOREGROUND := 1.35

# Health (scripts/hearts.gd): Rok's hearts, counted in quarters. Crashing into a
# solid obstacle costs hearts instead of ending the run; pits, water, lava,
# quicksand, dino gates and being caught are still instant.
const MAX_HEARTS := 3            # at the start; Heart Containers from the Market add more
const HEART_CONTAINERS := 3      # the most you can buy (so up to 6 hearts)
const CRASH_INVULN := 1.2        # seconds of invulnerability after a crash
const STUMBLE_CRASH := 70.0      # the hunter gains this much on a crash
const HEART_SCORE := 50          # a heart picked up at full health is just points

# Run ranks (the summary card): a run's score sets its rank, and the rank's
# multiplier boosts that run's meat and dinosaur XP. Very steep on purpose:
# each rank needs about 2.5x the score of the last. [min score, rank, multiplier]
const RUN_RANKS := [[0, "C", 1.0], [3000, "B", 1.25], [8000, "A", 1.5], [20000, "S", 2.0], [50000, "SS", 3.0]]
