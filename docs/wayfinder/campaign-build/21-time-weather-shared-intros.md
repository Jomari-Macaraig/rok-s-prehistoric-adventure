# 21: Time, weather and shared introductions

**What to build:** Each stage sets its time (day, dusk, night) and weather (sunny, cloudy, rain, storm, fog, eclipse): night is darker, rain adds puddles and slides go further. Endless runs get random rain and clouds with the same effects. A stage can introduce a hazard the player hasn't met, taught the same way, and meeting it counts in both modes.

**Blocked by:** [15: Campaign opens and a first stage plays](15-campaign-opens-first-stage.md)

**Status:** ready-for-agent

Spec: [docs/systems/campaign.md](../../systems/campaign.md).

- [ ] A stage's time and weather come from its config and look and play as described
- [ ] Endless runs get random weather
- [ ] A hazard met in a stage shows no NEW banner later in an endless run, and vice versa
- [ ] The endless-run introduction order and distances are unchanged (timeline probe)
- [ ] The affected system docs (and tests/CLAUDE.md for new checks) are updated in the same change; `ALL TESTS PASSED`
