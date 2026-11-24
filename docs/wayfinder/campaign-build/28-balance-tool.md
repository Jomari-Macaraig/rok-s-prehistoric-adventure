# 28: Balance tool and quick check

**What to build:** A headless tool, run by hand per chapter, plays each stage 20 times at the Recommended Strength, 15% below and 30% below, and writes a report: clear rates, hearts left, where failures happen, boss health and fight length, star-goal hit rates, walls, Journey drift, and a suggested Recommended Strength. It never edits config. The normal tests add a quick check that every stage builds and the average bot clears Forest 1.

**Blocked by:** [27: Balance Bot](27-balance-bot.md)

**Status:** ready-for-agent

Spec: [docs/systems/campaign.md](../../systems/campaign.md).

- [ ] The tool runs per chapter and writes the report file
- [ ] It flags too hard (<16/20), too easy (19+/20 at -15%), red not red (half or more at -30%), star goals under 1 in 5, walls over ~3 runs (5 before a boss) and drift over 15%
- [ ] It suggests the lowest Strength that clears 17/20
- [ ] run_tests.gd checks every stage builds and Forest 1 clears
- [ ] tests/CLAUDE.md documents it and the re-run rule
- [ ] The affected system docs (and tests/CLAUDE.md for new checks) are updated in the same change; `ALL TESTS PASSED`
