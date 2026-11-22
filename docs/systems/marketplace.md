# Marketplace

The shop where the player spends **meat** (earned in runs) on power-ups, gear,
dinosaurs, heroes, the third booster slot and Heart Containers. It's a full
screen "place": Rok stands in Ugo's cave on the left, the shop panel is on the
right.

Part of the [system docs](README.md).

## At a glance

| | |
|---|---|
| Opened from | the **Marketplace** side button on the main menu (`main.open_market()`); key M/K on desktop |
| Currency | meat, banked when a run ends (`main.meat_bank`, saved) |
| Prices | `config/progression.cfg` `[market]` |
| When items go on sale | `[market_unlocks]` (best distance), `[market_badges]` (badge tier), `[market_score]` (Heart Containers, best score) |
| Code | `scripts/market.gd` (shop UI and rules), `scripts/market_scene.gd` (the cave scene behind it) |
| Art | `assets/market/` (cave room and merchant, `tools/prepare_market.py`), `assets/market/ui/` (UI pack, `tools/prepare_market_ui.py`) |
| Tests | Market checks in `tests/run_tests.gd` (search "Market") |

## What's sold

The shop has five tabs (`Market.TABS`, `Market.category(id)`). Each tab lists
only its own items, in order of unlock distance.

| Tab | Items | Notes |
|---|---|---|
| Power-Ups | every non-starter power-up (Primal Amber, Fossil Magnet, Time Crystal, Primal Berry, Golden Fossil) | once bought they start spawning in runs; see [power-ups](power-ups.md) |
| Gear | weapons and armor (`Gear.ITEMS`) | equipped at the Camp; see [weapons-and-armor](weapons-and-armor.md) |
| Dinosaurs | the 28 expansion dinosaurs | tiered per category; see [dinosaurs](dinosaurs.md) |
| Heroes | Nira, Boro | see [heroes](heroes.md) |
| Other | third booster slot (`SLOT_ID`), Heart Containers | hearts unlock by best **score**, one after another |

Dinosaur cards are **not** sold: wild dinosaurs drop them (the Card Pack was
retired; its code path is left in `category`/`price`).

## Rules

**Going on sale**
- An item is on sale once the best distance reaches its `[market_unlocks]`
  distance, plus its `[market_badges]` tier if it has one (`Market.on_sale(id, best_m)`).
- Each power-up arrives before the stretch of the run it helps with; badge-gated
  items match their badge.
- Heart Containers go on sale by best score, each only after the one before it.
- Not on sale: shown as a dark silhouette with LOCKED; the details strip lists
  what's still needed, one requirement per line ("✓" when met,
  `Market.lock_text`); Ugo says it in his own words (`unlock_hint`).

**Buying**
- Two taps: BUY, then SURE? (`press_buy`), so a stray touch can't spend.
- Not enough meat: the button reads NEED N (and Ugo teases).
- `main.buy(id)` checks and saves the purchase. Items are permanent and can't
  be bought twice; owned ones say OWNED and point to the Camp.

**New items and the badge**
- Crossing an item's unlock distance in a run adds it to that run's summary news.
- It's tagged NEW in the Market until seen; a tab label gets a dot for new items.
- The Market opens on the first tab with something new, else Power-Ups.
- The Marketplace button shows a red dot when something on sale is new or
  affordable (`main.market_badge()`); locked items don't count.

**Meat**
- A pickup of its own in reward spots (see [pickups-and-loot](pickups-and-loot.md)).
- Counted per run (`main.run_meat`, the HUD's meat pill), banked when the run
  ends (`main._bank_meat`), boosted by the run's rank.
- About 4–5 meat appear per 1000 m (`tests/amber_probe.gd`); use it for pricing.

## The screen

```
┌──────────────────────────────────────────────────────────────┐
│ [←] MARKETPLACE                                  [meat 1450] │
│                              ┌──────────────────────────────┐│
│   speech bubble              │ tabs                         ││
│   (Ugo's line)               │ cards: 3 across, scrolls     ││
│ Rok   item   Ugo             │                              ││
│ (hero) ↑    behind counter   ├──────────────────────────────┤│
│     cave room                │ details strip: pic|text|BUY  ││
└──────────────────────────────┴──────────────────────────────┘┘
```

**Backdrop** (`Market.outdoor_backdrop()`): the game's daytime sky gradient,
mountains (bg_2) and jungle (bg_1) at full strength, lightly shaded, so the
area above the cave and the gap beside it on wide phones read as the outdoors.
(The Field Guide and Camp still use the older tinted `backdrop()`.)

**Left: the cave scene** (`market_scene.gd`)
- The user's cave room (`MarketScene.room()`, laid out from `market.json`),
  drawn at 0.54 × screen height / 720 (the size the user picked).
- The hero you play stands on the left, idle, wearing their gear.
- Ugo stands behind the counter; the chosen item floats over his hand
  (`on_counter`, `counter_top()`).
- After a sale: Ugo plays his buy clip, the item flies to the hero, and the
  hero does the celebration jump (`_sold`).
- Back: Ugo waves goodbye (`leave()`), then the screen fades out.

**Right: the shop panel** (`Market._layout`)
- About 52% of the screen width (600–820 px), right-aligned.
- Cards fill three columns with 12 px gaps, sized so two full rows fit above
  the details strip (`FOOT_H` 164). Card width comes from the frame's real
  content margins and the scrollbar's width.
- Card contents sit `CARD_INSET` (16, 14) inside the frame; names over 12
  letters use a smaller font.
- **Empty spots** (`_empty_spot`, meta `empty`): a tab with few goods is padded
  with faint recessed frames to fill the two visible rows (`GRID_ROWS`) and
  complete the last row, so the board is never bare. They can't be tapped;
  code and tests that walk the grid skip them.
- **Details strip**: picture | name (+ NEW, category, tier) and what it does |
  BUY. The name row and the attribute row **wrap** (HFlowContainer) instead of
  widening the strip; a single unbreakable line once pushed the panel off the
  right edge. Long text scrolls inside the strip.
- A test checks every item: its details never make the panel wider than its
  place.

See the root `CLAUDE.md` UI rules (nothing overlaps or spills; check 1280×720
and 1560×720).

## Ugo, the merchant

- An old cave trader: a big-hearted showman who loves meat, tells tall tales
  about the T-rex, grumbles about his back and trusts his lucky rock.
- `Market.LINES`: a pool per situation (greet, one per tab, owned, short of
  meat, confirm, locked, sold, bye), 5–14 lines each (a test keeps ≥ 5).
- `say(key, args, stable)` picks at random without repeating the last line, and
  keeps the same line while you look at the same thing.
- Each new line plays one of his gibberish mumbles (`mumble_1..6`, longer
  lines longer; made by `tools/make_sounds.py mumble`).
- Clips (`merchant_frames()`): idle 5 fps, buy 8 fps after a sale, goodbye
  7 fps on Back.

## Art

- **UI pack** (`assets/market/ui/`, `ui.json`): panel frame, tabs, cards
  (incl. stone locked card), price pills (incl. red can't-afford), details
  strip, BUY states, meat counter, back tablet, MARKETPLACE plaque, check,
  padlock, heart icon. Drawn as 9-slices with the pack's margins, cropped to
  each piece's visible region; each falls back to a drawn stand-in if missing
  (`_ui_box`, `_ui_tex`, `has_ui`).
- **Cave room and merchant** (`assets/market/`): without them, a drawn cave and
  a hooded shadow merchant stand in.
- The meat counter is a fixed 300×84 9-slice with the icon inside its border.

## Code map

| Function | What it does |
|---|---|
| `Market.items()` | everything sold, in order |
| `Market.category(id)` | which tab an item is in |
| `Market.price(id)` / `unlock_m(id)` / `on_sale(id, best_m)` | price and sale rules |
| `Market.lock_text(id, best_m)` | what still keeps it off sale |
| `open_market()` / `show_tab(t)` / `select(id)` | open, switch tab, pick an item |
| `press_buy(id)` → `main.buy(id)` | the two-tap purchase |
| `_layout()` | sizes the panel, cards and scene from the screen |
| `_stats_row(id)` | the five attributes (wrapping row) |
| `_empty_spot(k)` | a padding spot on a short tab |
| `outdoor_backdrop()` | the sky, mountains and jungle behind the scene |
| `say(key, …)` / `_speak(text)` / `unlock_hint(id)` | Ugo's lines |
| `main.market_badge()` | the red dot on the Marketplace button |

## Leftovers and open items

- The retired Card Pack still has code paths (`Gear.CARD_PACK`).
- Hide Vest, Scale Mail and Bone Guards don't show on the hero yet (no fitted
  art; see [weapons-and-armor](weapons-and-armor.md)).
