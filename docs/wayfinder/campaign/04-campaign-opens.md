---
title: When the campaign opens
label: wayfinder:grilling
status: closed
assignee: claude
blocked_by: []
---

# When the campaign opens

## Question

The campaign opens at a certain best distance and level. Which distance, and whose level (Rok's, any dinosaur's, the total)? What does the main menu show before it opens (a locked Campaign button saying what's needed)?

## Resolution

Decided with the user (2026-11-24):
- **Opens at** a best distance of **1,000 m** **and** the played hero (Rok,
  or Nira or Boro if bought) at **level 3**. Dinosaur levels don't count.
- **Before it opens**, the main menu shows the **Campaign** button locked,
  with what's still needed and ticks (for example "Reach 1,000 m ✓ · Rok
  level 3 (now 2)").
- **When it opens** (after the run or level-up that does it), a one-time
  **tour** points at the Campaign button and explains torches and stars,
  like the Crafting tour.
- **Config**: both numbers in `config/campaign.cfg` `[unlock]`.

Feeds: the main menu (Endless Run and Campaign buttons; the locked state),
the tutorial (the campaign tour), and "What settings define a stage" (the
first stages must be playable at about 1,000 m and hero level 3).
