---
title: How other mobile games charge for levels
label: wayfinder:research
status: closed
assignee: claude
blocked_by: []
---

# How other mobile games charge for levels

## Question

How do popular mobile runners and level-based mobile games make the player pay to play levels (energy, lives, tickets, keys)? Typical cost per level, refill time, cap, refund rules for failing, how ads are offered for refills, and what players complain about. Facts to inform "What a stage costs to play".

## Resolution

Findings on the throwaway branch `research/play-cost` (never merged), file
`docs/wayfinder/campaign/research/play-cost.md` (view with
`git show origin/research/play-cost:docs/wayfinder/campaign/research/play-cost.md`). Gist:
- Three models: **lives** (about 5, only a failure costs one, 1 back per ~30 min; Candy Crush, Angry Birds 2),
  **stamina** (big pool, fixed cost per stage, refills in about a day; Genshin, Star Rail, Arknights),
  and **soft gating** (play free, rewards gated). Endless runners traditionally have **no** entry cost.
- Fairness trend: charge on **success/reward, not failure** (Genshin, Star Rail; Arknights moved to full refunds on failure).
- Ads: a rewarded video for one life or some energy, offered right when you run out; networks suggest daily caps (about 1-8 a day).
- Players hate: being blocked from replaying, fast drain and slow refill, losing stamina on failure, caps that waste overnight refill, refills costing more than play earns.
- Fair: charge on success, an overflow reserve, a cap sized for a sitting with a daily rhythm, several free ways to refill, other things to do when empty.
