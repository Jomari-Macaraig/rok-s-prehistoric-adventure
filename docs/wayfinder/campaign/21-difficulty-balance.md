---
title: Difficulty balance and the bot check
label: wayfinder:grilling
status: closed
assignee: claude
blocked_by: [20-campaign-and-endless-cycle]
---

# Difficulty balance and the bot check

## Question

How hard are the first stages, how fast does difficulty climb across a
chapter and from chapter to chapter, and how does each stage's recommended
Strength line up with where a typical player is (runs played, levels, gear)?
How is it checked: a bot like the endless-run autopilot that plays every
stage at a given Strength, what it reports (clear rate, hearts left, boss
time), what counts as "too hard" or "too easy", and whether it runs as a
test or a tool.

## Resolution

Decided with the user (2026-11-24). Every number below goes in config and is
a starting target the Balance Bot checks.

**The Journey** (how a typical player's Strength grows):
- A **journey table** in config: typical Strength after N endless runs
  (for example about 12 after 5 runs, 20 after 15, 30 after 30). It also
  holds the **typical team** at each point (hero level and skills, gear
  rarity and upgrade level, the four dinosaurs' levels).
- **Pace targets** for a casual player (about 5 endless runs a day; stage
  XP speeds it up): Forest boss around run **20** (day 4), Desert boss
  around run **45**, Canyon boss around run **75**, Volcanic boss around
  run **110** (about 3 weeks).
- The bot checks the table by playing endless runs from a fresh save with
  automatic levelling. It flags a **drift of more than 15%**; then the table
  is updated or the stages are re-checked.

**The scale and the climb**:
- **Forest 1 recommends 10**, so it's green the moment the campaign opens
  (1,000 m, hero level 3, Strength about 12).
- A **sawtooth**: each stage adds about **+2**, every 3rd or 4th stage is a
  **Breather** (easier, often a puzzle or a collecting stage), and the boss
  is the peak (about **+4**). "Harder" means the stage's difficulty setting
  (speed, how close hazards come), more hazard kinds, and stronger wild
  dinosaurs and hunter charges.
- Boss targets: **Forest 26, Desert 44, Canyon 64, Volcanic 90**. Each
  chapter's Stage 1 sits **about 4 below the previous boss** (Desert 1
  about 22, Canyon about 40, Volcanic about 60). A fully grown team is well
  above 90, which leaves room for future chapters.
- **No walls**: the next stage never needs more than about **3 endless
  runs of growth** beyond the one before it (about **5** before a boss),
  measured with the journey table.

**The Balance Bot**:
- One bot with a **skill setting**. **Average** (used for balance) presses
  about 0.2 s late now and then and gets about 1 press in 20 wrong or late.
  **Perfect** is today's autopilot, kept for the endless-run tests.
- It learns the campaign's moves: **ATTACK** (breakables, wild dinosaurs,
  bosses), answering **boss attacks** after their warning, and **puzzles**
  from the stage's piece list (it knows the answer, then makes the average
  bot's mistakes). Puzzles are checked as **solvable with the starting
  energy and needed dinosaurs, with hearts to spare**; Strength matters
  less there.
- A **team builder** turns any Strength into the journey table's typical
  team at that point, with the stage's suggested dinosaurs equipped, so
  "Strength 40" is always a believable team.

**Fair, too hard, too easy** (20 tries per stage, average bot):
- **Fair**: at least **17 of 20** clears at the recommended Strength
  ("Forest 1 cleared 19/20 at Strength 10").
- **Too hard**: under 16 of 20 at the recommended Strength.
- **Too easy**: 19 or 20 of 20 at **15% below** (the yellow edge); lower
  the number or make the stage harder.
- **Red means red**: under half at **30% below**.
- A **star goal** met under 1 in 5 times at the recommended Strength is
  flagged as too hard.

**The report**: a table per chapter, one row per stage: clear rate at
recommended, -15% and -30%; average hearts left; where failures happen
("12 of 20 failures at the double-log combo at 640 m"); for bosses, health
left on a fail and the average fight length against the escape distance;
how often each star goal is met; walls (Q12) and journey drift; and a
**suggested recommended Strength** (the lowest that clears 17 of 20).
Written to a file.

**Test or tool**:
- A **tool** run by hand per chapter (for example
  `godot --headless -s tests/balance_bot.gd -- desert`). It **only
  suggests**; you or a session copy the numbers into the config.
- A quick check in `run_tests.gd`: every stage builds, and the average bot
  clears Forest 1 at its recommended Strength.
- Rule for the docs: **re-run the tool after changing a chapter file,
  Strength weights, XP rates, form stats or gear numbers.**

Feeds: the spec (`docs/systems/campaign.md`: the journey table and pace
targets, the scale, the sawtooth, the fair/too-hard/too-easy rules),
`tests/CLAUDE.md` (the Balance Bot, its skill setting, the quick check),
`config/campaign.cfg` (journey table, typical teams), the chapter files
(recommended Strength per stage), and building (the autopilot gains ATTACK,
boss answers, puzzles and a skill setting).
