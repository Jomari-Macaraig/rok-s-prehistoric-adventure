# 24: Puzzle stages

**What to build:** Slower stages with no hunter, built from an ordered piece list in config: right-dinosaur chains with limited PRIMAL energy, stone Switches hit by ATTACK, forks with a dead end, coloured Gems that open matching Doors, and Checkpoints where a mistake costs a heart and sends Rok back (resetting later Switches). A hint appears after 3 returns. A puzzle stage is locked until its needed dinosaurs are unlocked.

**Blocked by:** [19: Results, rewards and failing](19-results-rewards-failing.md)

**Art:** the user's puzzle pieces are in `../Assets/Rok_Puzzle_Pieces` (README, `manifest.json`: switch, four coloured doors and gems, checkpoint totem, fork sign, with animation frames). Import them instead of code-drawn stand-ins.

**Skills to wire here:** Nira's Scout's Hint (hints after 2 tries) and Shortcut Sense (forks show the safer path).

**Status:** ready-for-agent

Spec: [docs/systems/campaign.md](../../systems/campaign.md).

- [ ] A puzzle stage builds from its piece list, energy and amber spots
- [ ] Each piece works as the spec describes; Switches reset on a return before them
- [ ] A mistake costs a heart, not a torch; out of hearts fails
- [ ] The hint shows after 3 returns to the same checkpoint (2 with Nira's Scout's Hint)
- [ ] Locked puzzle stages say which dinosaurs they need
- [ ] Puzzle-only star goals work; puzzles pay a rare material and a Blessing chance
- [ ] Stand-in drawing for the pieces until the user's art
- [ ] The affected system docs (and tests/CLAUDE.md for new checks) are updated in the same change; `ALL TESTS PASSED`
