# Campaign build tickets

The [Campaign spec](../../systems/campaign.md) split into 29 vertical slices, numbered with blockers first. Work the frontier: any ticket whose blockers are all done (each file's **Status** goes from `ready-for-agent` to `in-progress` to `done`). Tickets with no blockers: 01, 03, 10, 13 (they don't touch the same files).

| # | Ticket | Blocked by |
|---|---|---|
| 01 | [Memory budget](01-memory-budget.md) | - |
| 02 | [Lean launch and zone streaming](02-lean-launch-zone-streaming.md) | 01 |
| 03 | [Automatic levels](03-automatic-levels.md) | - |
| 04 | [Milestones, Evolution and the Raptor's six](04-milestones-evolution-raptor.md) | 03 |
| 05 | [Triceratops and Spinosaurus milestones](05-triceratops-spinosaurus-milestones.md) | 04 |
| 06 | [Pteranodon milestones and the expansion dinosaurs](06-pteranodon-expansion-milestones.md) | 04 |
| 07 | [Dinosaur level path screen](07-dino-level-path-screen.md) | 04 |
| 08 | [Rok's Skill Tree and its screen](08-rok-skill-tree.md) | 03 |
| 09 | [Nira's and Boro's Skill Trees](09-nira-boro-skill-trees.md) | 08 |
| 10 | [Gear wear rework](10-gear-wear-rework.md) | - |
| 11 | [Upgrades +1 to +10 and Kora's Blessing](11-upgrades-blessing.md) | 10 |
| 12 | [Accessory slot and six accessories](12-accessories.md) | 10 |
| 13 | [Market deals shelf](13-market-deals.md) | - |
| 14 | [Strength](14-strength.md) | 04, 08, 11, 12 |
| 15 | [Campaign opens and a first stage plays](15-campaign-opens-first-stage.md) | 03 |
| 16 | [Trail map and briefing](16-trail-map-briefing.md) | 14, 15 |
| 17 | [Torches](17-torches.md) | 15 |
| 18 | [Stars](18-stars.md) | 15 |
| 19 | [Results, rewards and failing](19-results-rewards-failing.md) | 16, 17, 18 |
| 20 | [Stage loading and instant retry](20-stage-loading-retry.md) | 02, 15 |
| 21 | [Time, weather and shared introductions](21-time-weather-shared-intros.md) | 15 |
| 22 | [First Boss stage (T-rex)](22-first-boss-trex.md) | 19 |
| 23 | [The other three bosses and Boss Sets](23-bosses-boss-sets.md) | 12, 22 |
| 24 | [Puzzle stages](24-puzzle-stages.md) | 19 |
| 25 | [Trails and eggs](25-trails-eggs.md) | 22 |
| 26 | [Endless runs point at the campaign](26-endless-points-at-campaign.md) | 14, 17, 18 |
| 27 | [Balance Bot](27-balance-bot.md) | 14, 22, 24 |
| 28 | [Balance tool and quick check](28-balance-tool.md) | 27 |
| 29 | [Write and tune all four chapters](29-write-tune-chapters.md) | 23, 24, 28 |
