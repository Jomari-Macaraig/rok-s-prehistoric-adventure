# 06: Pteranodon milestones and the expansion dinosaurs

**What to build:** The Pteranodon gains Updraft, Dive, Soft Landing, Wing Buffet, Thermal Rider and Barrel Roll, and the 28 expansion dinosaurs follow their category's milestone list, with the level 8 slot reserved for a Signature Trick written when that dinosaur gets its Trail.

**Blocked by:** [04: Milestones, Evolution and the Raptor's six](04-milestones-evolution-raptor.md)

**Status:** done

Spec: [docs/systems/campaign.md](../../systems/campaign.md).

- [x] Each of the Pteranodon's six works in a run
- [x] An equipped expansion dinosaur gains its category's milestones
- [x] The level 8 Signature Trick slot is empty (no effect) until configured
- [x] The affected system docs (and tests/CLAUDE.md for new checks) are updated in the same change; `ALL TESTS PASSED`

## Done (2026-11-24)

Built per [dinosaurs.md#milestones](../../systems/dinosaurs.md#milestones). Dive adds a steeper dive and a chase gain (SLIDE in the air already slammed down for every form); Soft Landing is a short invulnerability after a dive landing. Thermal Rider has no automated check.
