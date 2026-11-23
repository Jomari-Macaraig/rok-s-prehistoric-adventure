# Game design: the core loop

**Status: notes only.** The user will discuss these later; nothing here is
designed or built yet. Don't start on it without them.

The user's vision for Rok Runner (2026-11-23). This is the big picture; each
system's doc in [systems/](systems/README.md) says how what's built works, and
[TODO.md](TODO.md) tracks what's left.

## The loop

1. **Endless runs** (built): the player runs to earn meat, materials, cards
   and XP, levels up heroes and dinosaurs, and crafts and upgrades gear,
   until they're strong enough for the campaign.
2. **Campaigns** (to design): set levels to beat. Once the player hits a
   wall there, they go back to endless runs to get stronger.
3. **The cycle**: endless runs and campaigns feed each other. Endless runs
   are where you grow; the campaign is where you prove it, and its later
   levels ask for more growth.
4. **Pets** (to design): a second game alongside the runs, using the eggs.

## Pets

- **Hatching**: pets come from eggs (the Dino Egg art is kept for it).
- **Care**: the player tends their pets (feeding, playing, keeping them
  happy). Neglect should matter.
- **Age**: a pet ages through stages (baby, young, adult, old). It can
  battle from a certain age, and one day it dies.
- **Breeding**: two pets can breed. Each pet has **traits** (body parts,
  colours, attributes, attack cards), and an offspring inherits traits from
  both parents, with a chance of something new.
  - **Only the same type** can breed together (decided 2026-11-23): a
    Raptor with a Raptor, never two different species.
  - **Each dinosaur can be bred at most 8 times** (decided 2026-11-23).
- **More dinosaurs** will be added later, so pets and breeding must not
  assume a fixed species list.
- **Battles**: turn-based, card-based battles between teams of dinosaurs.
  Each dinosaur brings its own set of attack cards, decided by its traits.
  Each turn the player plays cards from their hand. For now the opponent is
  a bot; **PVP** comes later.

## Open questions (for the design session)

- **Campaign**: How is it laid out (zones, chapters, levels)? What does a
  level ask for (reach a distance, collect, survive a boss hunter, no
  stumbles)? What do levels pay? Does it gate anything in endless runs?
- **Pets and the runner**: Are pets the same dinosaurs as the run's (the 32
  species), or their own creatures? Does a pet do anything in a run?
- **Battles**: How big is a team? How many cards in a dinosaur's deck, and
  in a hand? What resource pays for cards (energy per turn)? What are the
  win conditions? What are the rewards?
- **Care and age**: How many real hours or days per age stage? What happens
  when a pet is neglected? Can a pet be saved from dying (and should it)?
- **Breeding**: What does breeding cost? Does the cost rise with each of
  the 8 breedings? How rare are new traits? Can offspring of two different
  colour variants of one species mix them?
- **Economy**: How do pets, eggs and battle rewards tie into meat and
  materials? Can pets be sold?
- **PVP later**: This needs online accounts and a server. Design the battle
  rules so they can run on a server later (no hidden client-side
  randomness).
