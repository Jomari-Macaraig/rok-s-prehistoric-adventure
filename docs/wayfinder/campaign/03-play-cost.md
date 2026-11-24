---
title: What a stage costs to play
label: wayfinder:grilling
status: closed
assignee: claude
blocked_by: [07-runner-energy-research]
---

# What a stage costs to play

## Question

What does the player spend to play a stage: energy that refills over time, tickets, or something else? How much does a stage cost, how fast does it refill, what's the cap, can it be earned in endless runs or bought with meat, is a failed or quit stage refunded, and where will ads plug in later (watch an ad for energy)?

## Resolution

Decided with the user (2026-11-24), informed by
[How other mobile games charge for levels](07-runner-energy-research.md):
- **Model: lives, called Torches.** Only a **failed** stage costs one torch
  (out of hearts, the boss escapes, or quitting); **clearing is free**.
  Every stage kind follows the same rule. In a puzzle stage, being sent
  back to a checkpoint costs a heart, not a torch.
- **Quitting** (pause, Stop) counts as a failure, except within the first
  **5 seconds** (a mis-tap).
- **Numbers** (all in `config/campaign.cfg`): up to **5** torches, one
  relights every **30 minutes**, counted on the real clock (also while the
  game is closed).
- **Getting more**: a **full refill for meat** (for example 150) in the
  Market or on the campaign screen; **reward torches** from missions,
  chests or first clears can go **over the cap, up to 10**; **ads later**
  (1 torch per ad, a few a day; the screen leaves room for the button).
- **Out of torches**: the campaign screen shows "Out of torches · next one
  in mm:ss" with **Refill for 150 meat** and **Play an Endless Run**.
- **Endless runs stay free.**

Feeds: "What stages pay" (torches as a reward), "What settings define a
stage", the screens (torch row, timer, out-of-torches choices) and
"When the campaign opens".
