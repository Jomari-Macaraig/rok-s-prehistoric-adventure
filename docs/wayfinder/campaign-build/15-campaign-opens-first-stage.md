# 15: Campaign opens and a first stage plays

**What to build:** The campaign exists end to end in its simplest form. Campaign config and a Forest chapter file with a few stages; the main menu shows Endless Run and Campaign buttons; the Campaign button is locked with ticks until best distance 1,000 m and the played hero at level 3, then a one-time tour points at it; picking a stage starts a run built from its fixed seed that ends at a finish line; the clear is saved and the next stage opens.

**Blocked by:** [03: Automatic levels](03-automatic-levels.md)

**Status:** ready-for-agent

Spec: [docs/systems/campaign.md](../../systems/campaign.md).

- [ ] Chapter files load with every required key (direct-call test of config loading)
- [ ] The locked button lists what's needed with ticks; the tour shows once
- [ ] A stage builds the same course every try and shows distance to the finish
- [ ] Reaching the finish clears the stage, saves it and opens the next
- [ ] Game-scene test: start a stage, the bot reaches the finish, the next stage opens
- [ ] The affected system docs (and tests/CLAUDE.md for new checks) are updated in the same change; `ALL TESTS PASSED`
