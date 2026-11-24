# 17: Torches

**What to build:** Torches work like lives: a failed or quit stage costs one (not within the first 5 seconds); clears are free; up to 5, one relights every 30 minutes on the real clock, also while closed; reward torches go up to 10; a full refill for about 150 meat in the Market and on the campaign screen; out of torches shows the countdown with Refill and Play an Endless Run.

**Blocked by:** [15: Campaign opens and a first stage plays](15-campaign-opens-first-stage.md)

**Status:** ready-for-agent

Spec: [docs/systems/campaign.md](../../systems/campaign.md).

- [ ] The torch clock is a pure rule with a fakeable now (direct-call tests: relight, cap 5, reward cap 10, refill)
- [ ] Failing or quitting spends one; clearing and a quit in the first 5 s don't
- [ ] The out-of-torches screen shows the countdown and both choices
- [ ] Numbers come from config
- [ ] Torch Totem (ticket 12) now works
- [ ] The affected system docs (and tests/CLAUDE.md for new checks) are updated in the same change; `ALL TESTS PASSED`
