# 22: First Boss stage (T-rex)

**What to build:** The Forest boss stage: an approach run (600-800 m), then the T-rex jumps in ahead with a health bar. Only ATTACK hurts it (more with Power and weapon); its attacks are warned and answered with known moves (kicked rock: jump; tail sweep: slide; roar shockwave: jump; backward charge: dodge or shapeshift). Enrages at half health. Escapes after its fighting distance. No hunter during the fight. Beating it clears the stage and pays 3 T-rex teeth (40% for 1 on replays) and big XP.

**Blocked by:** [19: Results, rewards and failing](19-results-rewards-failing.md)

**Status:** ready-for-agent

Spec: [docs/systems/campaign.md](../../systems/campaign.md).

- [ ] Bosses are described in config (health, speed, attacks, rate, enrage); a stage can override
- [ ] Each attack has a warning and the right answer avoids it
- [ ] Damage comes only from ATTACK
- [ ] Enrage at half raises the rate and adds a move
- [ ] Out of hearts or escaping fails; beating it clears
- [ ] Boss-only star goals work
- [ ] Game-scene test of a win and an escape; existing clips plus flash and shake as stand-in art
- [ ] The affected system docs (and tests/CLAUDE.md for new checks) are updated in the same change; `ALL TESTS PASSED`
