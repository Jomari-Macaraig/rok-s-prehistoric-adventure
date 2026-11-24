# 20: Stage loading and instant retry

**What to build:** A stage loads only its zone, wild species and the four equipped dinosaurs (bosses and puzzle pieces later) behind a stage loading screen in the main loading screen's style, with the stage name, its three goals, Recommended vs your Strength, a tip and "Tap to start". Retry reloads nothing; back to the map frees the stage's extras; leaving the campaign frees everything campaign-only.

**Blocked by:** [02: Lean launch and zone streaming](02-lean-launch-zone-streaming.md), [15: Campaign opens and a first stage plays](15-campaign-opens-first-stage.md)

**Status:** ready-for-agent

Spec: [docs/systems/campaign.md](../../systems/campaign.md).

- [ ] A stage loads nothing from other zones (memory test per stage, under budget)
- [ ] The loading screen shows name, goals and Strength and waits for a tap
- [ ] Retry restarts instantly
- [ ] Leaving frees what's no longer needed
- [ ] The affected system docs (and tests/CLAUDE.md for new checks) are updated in the same change; `ALL TESTS PASSED`
