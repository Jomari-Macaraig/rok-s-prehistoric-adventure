# Campaign (spec, not built yet)

**Status: ready-for-agent.** Nothing here is built yet; build it in the order under Further Notes.

The build-ready spec of the Campaign mode and the progression it runs on.
Every decision comes from the wayfinder map
[docs/wayfinder/campaign/MAP.md](../wayfinder/campaign/MAP.md); each question
file there holds the detail and the reasoning. Words follow
[GLOSSARY.md](../../GLOSSARY.md) (Campaign, Chapter, Stage, Trail, Home Zone,
Puzzle Stage, Checkpoint, Switch, Gem, Door, Torch, Star, Boss, Strength,
Recommended Strength, Journey, Breather, Balance Bot, Level, Milestone, Trick,
Trait, Evolution, Skill Tree, Accessory, Upgrade, Boss Material, Boss Set,
Set Bonus, Protection Charm, Worn Out, Mission). All numbers below are
starting values: they live in config and the Balance Bot tunes them.

## Problem Statement

Endless runs are the whole game today. They're good at teaching hazards and
growing the team, but past the first few thousand metres a player has no clear
next goal, no place to prove their team, and nothing that meat can't buy.
Growth is fiddly too: levels cost meat and a trip to the Camp, gear breaks and
then does nothing, and dinosaurs gain points rather than new things to do.
The player wants hand-made challenges with a finish line, bosses to beat,
puzzles to think through, and rewards worth chasing, while endless runs stay
the free, relaxing way to grow.

## Solution

A **Campaign** next to the **Endless Run** on the main menu. It opens at a
best distance of 1,000 m with the played hero at level 3.

- **Four Chapters**, one per zone (Forest, Desert, Canyon, Volcanic), of about
  10 **Stages** each on a winding trail map. A Stage is a run with a finish
  line built the same way every try. Some are **Boss** stages (a boss runs
  ahead and Rok wears its health down with ATTACK) and some are **Puzzle
  Stages** (the right dinosaur at the right moment, Switches and forks,
  coloured Gems for Doors, with Checkpoints).
- Each stage shows a **Recommended Strength** against the player's own
  **Strength** (one number for the hero plus the four equipped dinosaurs),
  coloured green, yellow or red. It never locks anything, except that puzzle
  stages wait for the dinosaurs they need.
- **Torches** work like lives: only a failed or quit stage costs one, and
  clears are free. You hold up to 5, and one relights every 30 minutes.
- **Three Stars** per stage: clear it, plus two goals from a set list. Star
  totals open chapter chests.
- **Rewards** pay what meat can't buy: XP, zone materials, cards, torches,
  **Boss Materials** for **Boss Sets**, Kora's Blessing and eggs. Endless runs
  stay the main source of meat.
- Each species gets a 3-stage **Trail** in its **Home Zone** once that chapter
  is cleared.
- **Progression redesign**:
  - Levels come automatically, up to 20, with no meat. Dinosaurs gain
    **Tricks** and **Traits** at **Milestones** and **evolve** at 10 and 20.
    Heroes spend skill points in a three-branch **Skill Tree**.
  - Gear has three slots: weapon, armor and the new **Accessory**. It can be
    upgraded +1 to +10, with a risk from +7.
  - Gear is **Worn Out** at half strength instead of broken, and repairs cost
    meat.
- **Loading**: each stage loads only what it needs, endless runs stream
  zones, and a stage loading screen ends on "Tap to start".
- **Balance**: a **Journey** table says how a typical player's Strength
  grows, and stages are set against it. A **Balance Bot** plays each stage
  like an average player to check that its Recommended Strength is fair.

## User Stories

### Opening the campaign
1. As a new player, I want the Campaign button locked with what's still needed ("Reach 1,000 m ✓ · Rok level 3 (now 2)"), so that I know how to open it.
2. As a player who just reached 1,000 m and hero level 3, I want a one-time tour pointing at the Campaign button and explaining torches and stars, so that I understand the new mode.
3. As a player, I want the main menu to show two big buttons, Endless Run and Campaign, so that I can pick a mode at a glance.
4. As a player, I want the Campaign button to show my current chapter, progress and torches, so that I know where I stand before tapping in.
5. As a player with Nira or Boro, I want my played hero's level to count toward the unlock, so that I'm not forced back to Rok.

### The chapter map
6. As a player, I want each chapter drawn as a winding path of stage circles on its zone's backdrop, so that progress feels like a journey.
7. As a player, I want cleared stages to show their number and stars, the next one glowing with "NEXT", and locked ones dim with a lock, so that I see what's done and what's next.
8. As a player, I want boss and puzzle stages to have their own icons (the boss circle standing out), so that I know what's coming.
9. As a player, I want Trails to branch off the path as side signs, locked until the chapter boss is beaten, so that side content is visible but not in the way.
10. As a player, I want chapter buttons along the bottom, so that I can switch between chapters I've reached.
11. As a player, I want the chapter's star total and star chests bottom-right, so that I know how close the next chest is.
12. As a player, I want the torch row with its relight timer and my Strength in the top bar, so that I can see both without opening anything.
13. As a player, I want each stage to open only after the one before is cleared, and each chapter only after the previous boss is beaten, so that the path stays clear.

### The briefing
14. As a player, I want tapping a stage to open a briefing popup with its kind, chapter and stage number, time and weather, so that I know what I'm walking into.
15. As a player, I want the briefing to list the 3 star goals with the ones I've earned, so that I can aim for the missing ones.
16. As a player, I want "Recommended: 40 · You: 32" with my number green (at or above), yellow (within about 15% below) or red (well below), so that I can judge if I'm ready.
17. As a player, I want to still be able to try a red stage, so that skill can beat numbers.
18. As a player, I want the briefing to show suggested and needed dinosaurs and first-clear rewards, so that I can prepare my team and see what's worth it.
19. As a player, I want a note that a failed try costs a torch, so that the cost is never a surprise.
20. As a player, I want a locked puzzle stage to say which dinosaurs it needs, so that I know what to unlock in endless runs.

### Loading a stage
21. As a player, I want a stage loading screen in the main loading screen's style showing the stage name, its 3 goals, recommended vs my Strength, a progress bar and a tip, so that the wait is useful.
22. As a player, I want the loading screen to end on "Tap to start", so that I begin when I'm ready.
23. As a player, I want Retry to restart instantly without loading again, so that retries feel snappy.
24. As a phone player, I want only the stage's zone, boss, puzzle pieces, wild species and my four dinosaurs loaded, so that the game doesn't run out of memory.

### Playing a normal stage
25. As a player, I want a stage to be the same course every try, so that I can learn it.
26. As a player, I want a finish line after a set distance and the distance to it on the HUD, so that I know how far is left.
27. As a player, I want a small star-goal tracker in the run, with a star popping and a sound when a goal is met, so that I know mid-run how I'm doing.
28. As a player, I want hazards, wild dinosaurs, the hunter, weather and pickups to work exactly as in endless runs, so that what I learned carries over.
29. As a player, I want a stage to be able to introduce a hazard I haven't met yet (NEW banner, alone first), so that the campaign can teach too.
30. As a player, I want a hazard first met in a stage to count as met in endless runs too (Field Guide entry, no repeat banner), so that I'm not taught twice.
31. As a player, I want each stage's time (day, dusk, night) and weather (sunny, cloudy, rain, storm, fog, eclipse) to matter a little (night is darker, rain makes slides go further), so that stages feel different.

### Boss stages
32. As a player, I want a boss stage to start with a normal approach run (about 600–800 m) before the boss jumps in ahead, so that there's a build-up.
33. As a player, I want the boss's health bar at the top of the screen, so that I can see my progress.
34. As a player, I want only ATTACK to hurt the boss, more with higher Power and better weapons, so that my weapon and dinosaur forms matter.
35. As a player, I want every boss attack warned a moment before (a flash, a roar) and answered with a move I know (jump a kicked rock, slide under a tail sweep, jump a roar shockwave, dodge or shapeshift away from a charge), so that the fight is fair.
36. As a player, I want the boss to enrage at half health, attacking more often with one extra move, so that the fight climbs.
37. As a player, I want no hunter chasing during the fight, so that I can focus on the boss.
38. As a player, I want to lose if I run out of hearts or the boss escapes after its fighting distance (for example 800 m), so that there's pressure.
39. As a player, I want beating the boss to clear the stage, so that there's no extra run after it.
40. As a player, I want the chapter bosses to be the T-rex (Forest), Carnotaurus (Desert), Utahraptor (Canyon) and Allosaurus (Volcanic), so that each zone has a signature fight.
41. As a player, I want bosses shown with existing clips plus a flash and shake on hits until their own art exists, so that the mode isn't held up by art.

### Puzzle stages
42. As a player, I want puzzle stages to run slower and have no hunter, so that I can think.
43. As a player, I want chains of dino gates, water, crumbling bridges and quicksand that each need a certain dinosaur, with limited PRIMAL energy, so that choosing the right form is the puzzle.
44. As a player, I want stone Switches hit with ATTACK to lower a bridge or open a gate, staying on until I'm sent back before them, so that order matters.
45. As a player, I want forks where I choose the upper or lower path, one a dead end, so that I have to read the course.
46. As a player, I want coloured Gems that open matching stone Doors later, some off the main path, so that exploring pays.
47. As a player, I want Checkpoints (totems) where a mistake costs a heart and sends me back, so that mistakes hurt without ending the try.
48. As a player, I want a hint for the next piece after 3 returns to the same checkpoint, so that I'm never stuck for good.
49. As a player, I want running out of hearts to fail a puzzle stage, and the finish line after the last puzzle to clear it, so that the rules match other stages.

### Stars
50. As a player, I want star 1 to always be "Clear the stage", so that every clear is rewarded.
51. As a player, I want two more goals per stage from a set list (collect amber or meat, find the hidden fossil, take no damage, finish with N hearts, reach a ×N combo, never stumble, smash N obstacles, bonk N wild dinosaurs, finish without shapeshifting, run N m as a dinosaur), so that stages ask different things.
52. As a player, I want boss-only goals (beat it with N hearts, beat it before half its escape distance) and puzzle-only goals (no checkpoint returns, every gem, no hints), so that special stages have fitting goals.
53. As a player, I want no time limits, so that Rok sets his own pace.
54. As a player, I want stars to add up across tries and stay earned for good, so that I can chase one goal at a time.
55. As a player, I want stars only on a clear, so that a star means I actually finished.
56. As a player, I want stars never to lock anything, and chapter star totals (for example 10, 20, 30) to open bonus chests, so that stars are a reward, not a gate.

### Torches
57. As a player, I want clearing a stage to cost nothing and only a failed or quit stage to cost a torch, so that I'm charged for failing, not for winning.
58. As a player, I want quitting within the first 5 seconds not to cost a torch, so that a mis-tap is forgiven.
59. As a player, I want up to 5 torches with one relighting every 30 minutes on the real clock (also while the game is closed), so that the campaign paces itself.
60. As a player, I want a full refill for about 150 meat in the Market or on the campaign screen, so that I can keep going.
61. As a player, I want reward torches (missions, chests, first clears, star chests) to go over the cap up to 10, so that rewards are never wasted.
62. As a player who's out of torches, I want "Out of torches · next one in mm:ss" with Refill for 150 meat and Play an Endless Run, so that I always have something to do.
63. As a player, I want endless runs to stay free, so that the main game never waits on a timer.
64. As a player, I want a checkpoint return in a puzzle stage to cost a heart, not a torch, so that puzzles aren't punishing.

### Results and failing
65. As a player who cleared a stage, I want the results popup to show stars, XP bars filling and rewards dropping in one by one with NEW tags, so that the win feels good.
66. As a player who failed, I want to see what happened ("Caught by the T-rex", "Out of hearts", "The Allosaurus escaped", "You left the stage"), how far I got ("820 / 1,200 m" or "Boss health left: 35%") and the torch spent ("🔥 1 spent (2 left)"), so that I understand the loss.
67. As a player who failed, I want to keep the XP from metres run and the meat and materials I picked up, so that no try is wasted.
68. As a player who failed, I want Retry (instant), Back to the chapter and Endless Run, so that I can choose what's next.
69. As a player out of torches after a failure, I want Retry to become "Refill for 150 meat" with the next-torch countdown, so that I know my options.
70. As a player who failed the same stage 3 times in a row, I want a tip based on my weakest part of Strength (level a dinosaur in an Endless Run, upgrade a weapon at Kora's, bring the suggested dinosaur), so that I know how to get past it.

### Rewards
71. As a player, I want a first clear to pay XP for the hero and every dinosaur used, a handful of the zone's materials, a little meat and a chance of a card, so that progress feels earned.
72. As a player, I want every few stages (for example every 3rd) to give a torch on first clear, so that the campaign feeds itself.
73. As a player, I want replays to pay about a fifth of the first clear's XP and meat and a smaller materials chance (no cards or torches), so that replaying has some point but isn't the best farm.
74. As a player, I want each star's first earning to pay a small bonus (XP or materials), so that every star matters.
75. As a player, I want a boss's first clear to pay 3 Boss Materials and big XP, and replays a 40% chance of 1, so that a Boss Set takes real effort.
76. As a player, I want a puzzle stage's first clear to pay a rare material and a good chance of Kora's Blessing, so that puzzles are worth the thinking.
77. As a player, I want star chests to hold rare materials, Kora's Blessings and torches, so that collecting stars pays well.
78. As a player, I want rewards to grow with each chapter, so that later stages feel worth more.

### Trails and home zones
79. As a player, I want every species to have a Home Zone where it runs wild, so that the world feels inhabited.
80. As a player, I want a 3-stage Trail per species (meet it running wild, a stage built around its category's strength, beat it as a boss) opening once its home chapter's boss is beaten, so that each dinosaur has its story.
81. As a player, I want a Trail's last stage to give one random reward from its pool (its card, a chunk of its XP if owned, a Market discount of about 30% if not, an egg), each won only once, so that retries work through the pool.
82. As a player, I want an emptied Trail pool to give the small normal replay reward, so that the rules stay simple.
83. As a player, I want eggs to wait in my items until the pet system arrives, so that early rewards aren't lost.

### Strength
84. As a player, I want one Strength number made from my hero (level, skill points, gear by rarity and upgrade, worn-out pieces at half) and my four equipped dinosaurs (level and evolution), so that I know my team's power at a glance.
85. As a player, I want my Strength at the Camp and next to the Campaign button, ticking up with a small animation when it grows, so that I notice growth.
86. As a player, once the campaign is open I want the endless-run summary to show "Strength 38 (+2 this run). Next stage: Desert 4 needs 40", with a tap opening that briefing, so that endless runs point at the campaign.

### Levels, milestones and evolution
87. As a player, I want characters to level up the moment they have the XP, mid-run, with a "LEVEL UP!" burst, sound and glow, without stopping play, so that growth feels instant.
88. As a player, I want no meat and no Camp trip for levels, so that levelling is never a chore.
89. As a player, I want quick early levels (level 2 within a first good run, about 300 m) slowing gently up to a cap of 20, so that growth starts fast and lasts.
90. As a player, I want XP from metres run as that character, stage clears and stars, bosses, chests and a small team share for the other equipped dinosaurs, so that every activity grows the team.
91. As a player, I want dinosaurs to grow their attributes automatically, mostly their best ones, so that each keeps its character.
92. As a player, I want each original dinosaur's Milestones at 3, 5, 8, 13, 15 and 18 to give a Trick or a Trait (for example the Raptor's Quick Start, Double Dash, Light Step, Pounce, Pack Instinct, Triple Jump), so that levels change how a form plays.
93. As a player, I want expansion dinosaurs to follow their category's Milestones with a Signature Trick at level 8, so that each one still feels unique.
94. As a player, I want dinosaurs to evolve at 10 (+1 every attribute) and 20 (+1 again, the best attribute 1 past its cap), with a glow until the evolved art exists, so that big moments look and feel big.
95. As a player, I want the summary to fill each character's XP bar and show a card for a new Milestone ("NEW: Raptor learned Double Dash!"), so that I see what I gained.
96. As a player, I want a dinosaur's level path at the Camp drawn as a road from 1 to 20 (plain dots, gold Milestones, purple Evolutions, the next level glowing, a "Next: Lv 8 · …" chip, tap for the reward card), so that I can see what's coming.

### Hero skill trees
97. As a player, I want each hero level from 2 to 20 to give one skill point (19 in all), so that the hero grows with me.
98. As a player, I want three branches per hero of 5 skills costing 1, 1, 2, 2, 3 (9 per branch, 27 for all), each needing the one below, so that I can fill two branches but not three and must choose.
99. As a player, I want Rok (Runner, Brawler, Survivor), Nira (Pathfinder, Acrobat, Tracker) and Boro (Bulwark, Crusher, Protector) each to have their own tree, so that heroes play differently.
100. As a player, I want a free reset, so that I can try builds without fear.
101. As a player, I want the skill tree screen to show the hero bottom-left, a panel with level, XP, skill points and Reset (free), and three branches growing upward as skill cards (learned filled, learnable gold-rimmed, locked dim), with a tap learning a learnable skill, so that choosing is clear.

### Gear
102. As a player, I want three gear slots per hero, weapon (attack), armor (defence and bonus hearts) and accessory (one special effect), so that each slot has one clear job.
103. As a player, I want dinosaurs to wear no gear and grow through levels instead, so that the two kinds of growth stay separate.
104. As a player, I want six accessories crafted from each zone's materials (Amber Pendant, Meat Hook, Lodestone, Sun Bead, Torch Totem, Lucky Fossil), their effect sized by rarity (about +10% to +30%) and upgrades (about +2% each), so that accessories reward crafting.
105. As a player, I want to upgrade gear +1 to +10 at Kora's bench for materials, with +1 to +6 always succeeding and +7 to +10 able to fail (for example 75%, 55%, 40%, 25%), so that top gear is a gamble.
106. As a player, I want a failed upgrade to cost the materials and drop the item one level, and from +8 up carry a small chance (about 10%) to break it for good, so that risk is real.
107. As a player, I want Kora's Blessing to stop an upgrade from dropping or breaking, so that I can protect my best piece.
108. As a player, I want each chapter boss's 3-piece Boss Set (weapon, armor, accessory, each the best of its slot) made from its Boss Material, with one Set Bonus for the full set (Tyrant's Roar, Bull Rush, Killing Claw, Molten Hide), so that bosses are worth beating again.
109. As a player, I want no gear sold in the Market, so that crafting and bosses stay the way to get it.

### Durability and repair
110. As a player, I want gear never to stop working: at 0 durability it's Worn Out and gives half its bonus until repaired, so that a run is never ruined by broken gear.
111. As a player, I want each run or stage to use 1 durability per piece worn, shown as "12 runs left", so that wear is easy to understand.
112. As a player, I want repairs to cost meat (more for rarer and higher-upgraded pieces) at the Camp and on Kora's Items screen, so that meat has a steady use.
113. As a player, I want a successful upgrade to restore full durability, so that upgrading also refreshes the piece.
114. As a player, I want selling to scale with durability left and the upgrade level to raise value, so that good gear sells well.

### Market
115. As a player, I want the Market to keep power-ups, the 3rd booster slot, heart containers, expansion dinosaurs, heroes and basic material bundles, so that what I know stays.
116. As a player, I want a torch refill (about 150 meat) and Kora's Blessing (pricey, a few a week) for sale, so that meat helps the campaign.
117. As a player, I want a daily deals shelf of 2–3 offers (a discounted dinosaur, a rare material bundle, a cheap Blessing), so that the Market is worth checking each day.
118. As a player, I want to sell Boss Materials at 80% but never eggs, so that spares have value but eggs stay special.
119. As a player, I want no XP boosts, eggs, gear or Boss Materials for sale, so that the campaign keeps its own rewards.

### Endless runs alongside the campaign
120. As a player, I want gear, Tricks, Traits, skills, accessories and Set Bonuses to work identically in both modes, so that one team means one set of rules.
121. As a player, I want the endless-run introduction order and distances to stay exactly as they are, so that the teaching curve isn't broken.
122. As a player, I want Bosses, puzzle pieces, Stars and Torches to stay campaign-only, so that endless runs stay simple.
123. As a player, I want endless runs never to drop Boss Materials or eggs, so that the campaign stays their only source.
124. As a player, once the campaign is open I want about 1 in 3 daily or weekly missions to be campaign goals ("Clear 2 stages", "Earn 3 stars", "Beat a boss"), never needing a stage I can't reach, so that missions mix both modes.
125. As a player, I want badges to gain tracks for stars earned, bosses beaten and Trails finished, so that long-term goals include the campaign.
126. As a player, once the campaign is open I want rare and better milestone chests to have a small chance of 1 torch, so that long runs help the campaign.
127. As a player, I want rain and clouds to come and go at random in endless runs with the same effects as in stages, so that weather is shared.

### Loading in endless runs
128. As a player, I want the game to launch loading only the core and the first zone, so that it starts faster.
129. As a player, I want endless runs to prepare the next zone in the background and free the one behind, so that long runs don't run out of memory.

### Old saves
130. As a returning player, I want my levels kept, attributes recalculated with the new growth and the meat I spent on levels refunded, so that the redesign doesn't cost me.
131. As a returning player, I want my broken gear to become Worn Out, so that it works again.

### Balance (the designer)
132. As the designer, I want a Journey table in config (typical Strength and typical team after N endless runs), so that every stage's number means "about run N".
133. As the designer, I want pace targets (Forest boss around run 20, Desert boss around 45, Canyon around 75, Volcanic around 110), so that the campaign lasts about 3 weeks of casual play.
134. As the designer, I want Forest 1 to recommend 10, about +2 per stage in a sawtooth with a Breather every 3rd or 4th stage, bosses at 26 / 44 / 64 / 90, and each chapter opening about 4 below the previous boss, so that difficulty climbs smoothly.
135. As the designer, I want no stage to need more than about 3 endless runs of growth beyond the one before (about 5 before a boss), so that there are no walls.
136. As the designer, I want a Balance Bot with a skill setting ("average" presses about 0.2 s late now and then and gets about 1 press in 20 wrong; "perfect" is today's autopilot), so that checks reflect real players.
137. As the designer, I want the Balance Bot to use ATTACK, answer boss attacks after their warning and play puzzles from the piece list, so that it can play every stage kind.
138. As the designer, I want a team builder that turns any Strength into the Journey's typical team with the stage's suggested dinosaurs equipped, so that "Strength 40" is always believable.
139. As the designer, I want 20 tries per stage to rate it: fair if at least 17 clear at the recommended Strength, too hard under 16, too easy if 19–20 clear at 15% below, and under half at 30% below, so that "fair" has a number.
140. As the designer, I want puzzle stages checked as solvable with their starting energy and needed dinosaurs, with hearts to spare, so that puzzles are judged on fairness, not Strength.
141. As the designer, I want a report per chapter (clear rates at three Strengths, hearts left, where failures happen, boss health left and fight length, star-goal hit rates with goals under 1 in 5 flagged, walls, Journey drift over 15%, and a suggested Recommended Strength), so that I know exactly what to change.
142. As the designer, I want the balance tool run by hand per chapter and only ever suggesting numbers, so that config changes stay deliberate.
143. As the designer, I want the normal tests to check that every stage builds and the average bot clears Forest 1 at its recommended Strength, so that a broken config is caught every time.

### Configuration and growth (the designer)
144. As the designer, I want general campaign settings (unlock, torches, refill price, bosses, Journey table) in `config/campaign.cfg` and one file per chapter with one section per stage, so that adding a chapter means adding a file.
145. As the designer, I want each stage to set its name, kind, zone, length, difficulty, hazards, wild dinosaurs and hunter (with charges), suggested dinosaurs, time and weather, two star goals with numbers, rewards and Recommended Strength, so that stages are made from config, not code.
146. As the designer, I want bosses described once (health, speed, attacks, how often, what changes on enrage) and a boss stage to name its boss, approach length and escape distance, and optionally override numbers, so that a tougher T-rex later is one line.
147. As the designer, I want puzzle stages to list their pieces in order, starting energy, amber spots, needed dinosaurs and a hint per piece, so that puzzles are authored as lists.
148. As the designer, I want new zones to become new chapters and join the endless-run zone cycle, so that the campaign grows with the world.
149. As the designer, I want a memory budget in config (a first guess of about 400 MB of images) checked by a test that loads each stage and endless zone, so that phones never run out of memory.
150. As the designer, I want stage settings to leave room for pets joining stages and for ads refilling torches later, so that neither needs a redesign.

## Implementation Decisions

### New modules
- **Campaign rules** (a deep module with a small interface): loads the
  campaign config and chapter files, answers "is this stage reachable/locked
  and why", builds a stage definition (seed, length, kind, hazards, boss,
  pieces, time, weather), records clears, stars and Trail pool draws in the
  save, and computes rewards for a result. The game scene asks it questions;
  it never touches nodes.
- **Strength**: a pure function from a team (hero level, skills, gear pieces
  with rarity, upgrade and wear; four dinosaurs with level and evolution) to
  one integer. Weights live in config. It also answers "weakest part" for
  the 3-failures tip and the colour against a Recommended Strength (green at
  or above, yellow within about 15% below, red below that).
- **Torches**: a pure clock module. Its inputs are the count, the last relight
  time and "now", and it returns the current count and time to next. It
  handles cap 5, relight every 30 minutes, reward torches up to 10, refill for
  meat, and the 5-second quit grace. "Now" is passed in so tests can fake it.
- **Stage course builder**: an extension of today's course and terrain
  generation that takes a stage definition (fixed seed, length, allowed
  hazards, difficulty) instead of endless-run distance. It places a finish
  line, and it builds puzzle stages from their ordered piece list.
- **Boss**: a runner-ahead actor with a health bar, an attack list (each with
  a warning, the move that answers it, and a damage tier like an obstacle),
  an enrage at half health that raises the rate and adds a move, and an
  escape distance. ATTACK damage uses the attack's Power and weapon. Smashing
  obstacles and Primal Frenzy don't hurt it.
- **Puzzle pieces**: Switch (off/on, hit by ATTACK, resets on a return before
  it), Fork (upper/lower path, one a dead end), Gem and Door (colour-keyed),
  Checkpoint (a totem; a mistake costs a heart and sends Rok back; it counts
  returns for the hint after 3, or 2 with Nira's Scout's Hint). Code-drawn
  stand-ins until art arrives.
- **Star goals**: a tracker fed by run events (amber, meat, fossil, damage,
  hearts, combo, stumbles, smashes, bonks, shapeshifts, metres per form, boss
  hearts and timing, checkpoint returns, gems, hints). It shows the in-run
  tracker and reports which goals were met on a clear.
- **Campaign screens**: the chapter trail map, the briefing popup, the stage
  loading screen, the in-run additions (finish distance, goal tracker, boss
  health bar, checkpoint and gem counter), and the results and fail popups,
  laid out as variant A of the throwaway prototypes.
- **Balance Bot and balance tool**: the existing autopilot gains a skill
  setting (perfect / average), ATTACK use, boss-attack answers and puzzle
  play from the piece list. A team builder turns a Strength into the
  Journey's typical team. A headless tool plays a chapter's stages 20 times
  at the recommended Strength, 15% below and 30% below, plays endless runs
  from a fresh save for the Journey check, and writes the report file. It
  never edits config.

### Changed modules
- **Run loop / main scene**: gains a stage mode next to the endless mode
  (an entry point to start a given stage, a finish line, boss and puzzle
  phases, no hunter in boss and puzzle phases, stage results and fail
  states, instant retry), and the summary's Strength line once the campaign
  is open. New states for the briefing and loading are allowed but the
  existing states stay.
- **Main menu**: Endless Run and Campaign buttons, the locked Campaign
  state with ticks, and the one-time campaign tour.
- **Progression**: a shared "met" list for hazards across both modes; stages
  can introduce a hazard with the same NEW banner and solo-first teaching.
  The endless-run order and distances don't change.
- **Levelling**: automatic level-ups mid-run up to 20 with no meat; an XP
  curve (level 2 at about 300 m) in config; team share; dinosaur Milestones
  (Tricks and Traits per species in config) and Evolution at 10 and 20;
  hero skill points and Skill Trees with free reset. The per-attribute "+"
  buttons and the meat cost of levels are removed.
- **Camp**: the dinosaur level path (road) and the hero skill tree screens,
  Strength shown, and repair for meat.
- **Gear**: an Accessory slot; upgrades +1 to +10 with failure odds, drop and
  break rules and Kora's Blessing; Boss Sets and Set Bonuses; wear of 1 per
  run or stage, Worn Out at half instead of broken; repair costs meat by
  rarity and upgrade; a successful upgrade restores durability.
- **Crafting**: accessory recipes per zone, boss-material recipes for Boss
  Sets, upgrade costs.
- **Market**: torch refill, Kora's Blessing (limited a week), the daily deals
  shelf, Boss Materials sellable, eggs not; no gear, XP boosts, eggs or Boss
  Materials for sale.
- **Missions and badges**: about 1 in 3 missions are campaign goals once it's
  open (only reachable stages); new badge tracks for stars, bosses and
  Trails.
- **Loot**: chest torch chance once the campaign is open (cap 10); endless
  runs never drop Boss Materials or eggs.
- **Weather**: random rain and clouds in endless runs; per-stage time and
  weather; night darker, rain makes slides go further.
- **Preloader and loading**: a small always-loaded core (hero, HUD, menus,
  pickups, effects, sounds, music); per-stage loading of only its zone, boss,
  pieces, wild species and four equipped dinosaurs; endless runs stream the
  current and next zone; launch loads only the core and the first zone;
  leaving the chapter map or the campaign frees what's no longer needed.
- **Save data**: campaign progress (clears, stars, chest claims, Trail pool
  draws, failures-in-a-row per stage), torches and last relight time, skill
  points and learned skills, gear upgrade levels and wear, accessories,
  eggs, the shared met list. A migration keeps levels, recalculates
  attributes, refunds meat spent on levels and turns broken gear into Worn
  Out.

### Config
- `config/campaign.cfg`: `[unlock]` (best distance 1,000 m, hero level 3),
  torches (cap 5, reward cap 10, relight 30 min, refill 150 meat, quit grace
  5 s), bosses (health, speed, attacks, rate, enrage), Strength weights, the
  Journey table with typical teams, the memory budget.
- `config/campaign/<chapter>.cfg`: one section per stage with every per-stage
  setting from the Solution, including Recommended Strength. Boss stages add
  boss, approach length, escape distance and optional overrides. Puzzle
  stages add pieces in order, starting energy, amber spots, needed dinosaurs
  and a hint per piece.
- Species Home Zones and Trail reward pools; Milestones per species; Skill
  Trees per hero; accessory effects; upgrade odds; repair costs; reward
  amounts per chapter. Each goes into the config file that owns its system
  (levelling, crafting, economy, pickups, missions).

### Starting numbers (all config, Balance Bot tuned)
- Recommended Strength: Forest 1 = 10, about +2 a stage, Breathers every 3rd
  or 4th, boss about +4; bosses 26 / 44 / 64 / 90; Stage 1 of each later
  chapter about 4 below the previous boss (Desert about 22, Canyon about 40,
  Volcanic about 60).
- Journey: about 12 after 5 runs, 20 after 15, 30 after 30; bosses around
  runs 20 / 45 / 75 / 110.
- Boss approach 600–800 m, escape distance about 800 m.
- Rewards: torch every 3rd first clear, replays a fifth, boss 3 materials
  then 40% for 1, star chests at 10 / 20 / 30 stars.

## Testing Decisions

- **Good tests check what the player sees or what's saved**, never internal
  fields. They go through the same doors the player does (start a stage,
  press buttons) and read the HUD, the screens' text, the results and the
  save file. Numbers come from config, not literals, so tuning never breaks a
  test (the way the progression checks already read `Progression`).
- **Seam 1 (the main one): the game scene driven frame by frame**, as
  `run_tests.gd` does today. A new "start this stage" entry point; the bot
  presses buttons. Through it: the campaign unlock and tour, the map's
  reachable and locked stages, the briefing's numbers and colours, a stage
  building the same course from its seed every try, finish line and clear,
  star goals met and kept across tries, stars only on a clear, a boss fight
  (warnings, ATTACK damage, enrage at half, escape, out of hearts), a puzzle
  (switches, forks, gems and doors, checkpoint returns costing a heart, hint
  after 3), torches spent on fail and quit but not on clear or within 5 s,
  the fail screen's text and choices, the 3-failures tip, rewards (first
  clear vs replay, boss materials, Trail pool each once), the endless
  summary's Strength line, a hazard met in a stage counting in endless runs,
  automatic level-ups mid-run, Milestone cards, Worn Out gear at half, the
  memory budget per stage and endless zone, and the UI layout rules at
  1280×720 and 1560×720 (nothing overlaps or spills out). The balance tool
  reuses this seam.
- **Seam 2: direct calls for the pure number rules only**: Strength from a
  given team (and worn-out pieces at half, the weakest part, the colour), the
  torch clock with a faked "now" (relight, cap, reward cap, refill, quit
  grace), the Journey table and team builder, and loading every chapter file
  (every stage has every required key and valid references to bosses,
  hazards, dinosaurs and goals).
- **Quick balance check in the normal tests**: every stage builds, and the
  average bot clears Forest 1 at its Recommended Strength. The full balance
  tool is run by hand per chapter, because 20 tries × 3 Strengths × about 40
  stages is slow.
- **Save migration**: an old-format save loads with levels kept, meat for
  levels refunded and broken gear Worn Out.
- **Prior art**: `run_tests.gd`'s frame-driven checks and its own save file
  (`_training_run_checks`, `_progression_checks`, `_market_checks`,
  `_unit_checks`, `_config_checks`, the "no control overlaps another"
  layout check); `tests/autopilot.gd` (the bot to extend);
  `tests/timeline_probe.gd` (a headless tool that reads config and reports,
  the model for the balance tool); the screenshot scripts for the layout
  checks at both resolutions.

## Out of Scope

- **Pets** in stages (stage settings just leave room), pet care, breeding
  and card battles; eggs are stored only.
- **Ads** (they'll refill torches later; the screens leave room for the
  button).
- **PVP** and pet battles.
- **Real money**: a premium currency and purchases.
- **Art**: boss clips, puzzle pieces, path and stage circles, Trail signs,
  torch icon, level path and skill card art, milestone and accessory icons,
  Boss Set art and evolved looks are asked of the user with a short spec in
  `docs/TODO.md` when built. Until then the game draws stand-ins in code.
  Art is never generated.
- **Trail stages for all 32 species**: the Trail system is in scope; writing
  each species' Trail (and its Signature Trick) happens when that dinosaur
  gets its Trail.
- **Boss variants** (a boss chasing from behind, the Quetzalcoatlus boss).

## Further Notes

- **Order to build** (suggested): measure today's launch memory, then the
  loading core and zone streaming; the progression redesign (levels, gear,
  durability, Market) because the game must work in endless runs on its
  own; Strength and the Journey; the campaign rules and config; normal
  stages and the trail map; stars, torches, results; bosses; puzzles;
  Trails; the Balance Bot and tool; then tune every chapter.
- **Several decisions change systems already built**: levels become
  automatic with no meat, durability becomes per-run wear with Worn Out at
  half, and repairs cost meat. Each of those systems' docs needs updating
  when built: [leveling](leveling.md), [weapons-and-armor](weapons-and-armor.md),
  [crafting](crafting.md), [marketplace](marketplace.md),
  [run-loop](run-loop.md) (loading and the summary line), [camp](camp.md),
  [goals](goals.md), [progression](progression.md) and
  [pickups-and-loot](pickups-and-loot.md).
- **Prototypes** (throwaway, never merge): `prototype/campaign-screens`
  (variant A, the trail map) and `prototype/level-path-screens` (variant A,
  road and growing tree).
- **Rule for balance**: re-run the balance tool after changing a chapter
  file, Strength weights, XP rates, form stats or gear numbers.
- **Revisit**: "When the campaign opens" asked for hero level 3; with faster
  early levels it may become a higher level. Check it with the Journey once
  levelling is built.
