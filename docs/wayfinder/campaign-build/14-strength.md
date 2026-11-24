# 14: Strength

**What to build:** One number for how strong the team is: the hero (level, skill points, gear by rarity and upgrade, Worn Out pieces at half) plus the four equipped dinosaurs (level and evolution), weights in config. Shown at the Camp and next to the Campaign button, ticking up with a small animation when it grows.

**Blocked by:** [04: Milestones, Evolution and the Raptor's six](04-milestones-evolution-raptor.md), [08: Rok's Skill Tree and its screen](08-rok-skill-tree.md), [11: Upgrades +1 to +10 and Kora's Blessing](11-upgrades-blessing.md), [12: Accessory slot and six accessories](12-accessories.md)

**Status:** ready-for-agent

Spec: [docs/systems/campaign.md](../../systems/campaign.md).

- [ ] Strength is computed from a team by a pure rule with config weights (direct-call test)
- [ ] Worn Out gear counts half
- [ ] It can name the team's weakest part (for the tip in ticket 19)
- [ ] It colours against a recommended number: green at or above, yellow within about 15% below, red below
- [ ] The Camp and the menu show it and animate a rise
- [ ] The affected system docs (and tests/CLAUDE.md for new checks) are updated in the same change; `ALL TESTS PASSED`
