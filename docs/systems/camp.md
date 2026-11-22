# Camp (levelling and gear screen)

Where the player chooses the hero and the dinosaur on each button, compares
them, levels them up, and equips gear. The code still calls it the Herd.

Part of the [system docs](README.md).

## At a glance

| | |
|---|---|
| Opened from | the **Dinosaurs** side button on the main menu (`main.open_herd(cat)`, `Hud.herd_button`); key H on desktop |
| Code | `scripts/herd.gd` (`Herd`) |
| Related | [leveling](leveling.md), [attributes](attributes.md), [weapons-and-armor](weapons-and-armor.md), [dinosaurs](dinosaurs.md), [heroes](heroes.md) |
| Art | drawn in code until `assets/camp/hut.png` exists |

## The screen

- **Scene** (`_draw_camp`): a hide hut, a campfire and a log; title banner DINOSAURS, sign CAMP. Your hero stands at the left; the chosen dinosaur (or another hero) stands by the hut (`stage`, its idle loop; a silhouette if not owned).
- **Tabs** (`Herd.tabs()`): Heroes first (Rok, Nira, Boro), then one per category with how many of its 8 you own ("Runner 4/8").
- **Shelf** (`list`): a sideways row of tiles (`_row`): picture, name, tier and level, a tag (EQUIPPED / OWNED / MARKET / LOCKED), and `LevelReady`. Members: the button's original first, then the Market dinosaurs in on-sale order (`Herd.members(cat)`).
- **Board** (`board`, `detail` inside the scrolling `dscroll`): the level-up, compare and gear panel.
- Drags scroll whichever panel they start on; a drag isn't taken as a tap. While it's open `main._input` leaves touches to its GUI.

## Comparing

Tap a tile (`select(id)`) to show it on the board:
- its category, tier and trade-off;
- the five attributes as 10-segment bars **against the equipped one**: shared points brown, gains bright green, points you'd give up light red, the difference beside each (`Delta_<attr>`); part-segments for decimals;
- what its attributes add in play (`Dinos.perks`).

Ones you don't own are silhouettes but can still be compared, with how to get them (Market price or `Market.lock_text`). A note says when the category's button is still locked.

## Equipping

- **Equip** (`press_equip`) puts an owned one on the button; on the original it reads "Use the original" (`main.unequip`).
- Heroes: "Play as …" (see [heroes](heroes.md)).

## Levelling

- A button beside each attribute shows what a level-up adds ("+0.4", "max" at the cap).
- `press_level`: the first tap asks "Confirm?", the second calls `main.level_up`.
- Disabled at the cap, without the meat, or without the XP (the note says how many metres to run as it).
- An XP bar under the level shows progress; a note shows the next level's price; the header shows the meat bank.

## Gear (Heroes tab)

- EQUIPMENT rows (`_gear_rows`): weapon and armor with their bonuses and attack reach, and "Durability n/max" (or BROKEN) with a **Repair** button (two taps, `press_repair`).
- **Change** (`press_slot`) turns the shelf into that slot's choices (`_gear_list`: Nothing, owned gear, cards); a tap equips (`press_gear`).

## Red dots

Where something can be done: `main.level_ready()` (owned characters with the XP and meat for a level) and `gear_ready()` light the Camp button (`Hud.set_herd`), its tabs ("●") and rows ("● LEVEL UP!").
