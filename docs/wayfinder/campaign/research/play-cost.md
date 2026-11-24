# How other mobile games charge for levels

Research for [07-runner-energy-research](../07-runner-energy-research.md), feeding [03-play-cost](../03-play-cost.md) ("What a stage costs to play"). Gathered November 2026. Official help pages were often unreachable (403/404), so where a number comes only from press or fan wikis it is marked as such, and each source's date is given. Numbers from launch-era reviews may have changed since.

## Summary

- **Three common models.** (1) **Lives** (casual puzzle): a small pool, typically **5**, one lost per *failed* attempt, a win costs nothing (Candy Crush, Angry Birds 2, Royal Match). (2) **Stamina / energy** (RPG, gacha): a large pool spent per stage, with a fixed cost per stage and different stages costing different amounts (Genshin Resin, Honkai: Star Rail Trailblaze Power, Arknights Sanity, Puzzle & Dragons). (3) **Soft gating**: play is free and unlimited, only *rewards* are gated (Clash Royale chest slots, Hearthstone daily quests). Endless runners traditionally have **no entry cost at all**; they monetise continues/revives, upgrades and ads (Temple Run, Subway Surfers, Jetpack Joyride).
- **Typical lives numbers:** cap 5, **1 life per 30 minutes**, full refill from empty about **2.5 hours** (Candy Crush, Angry Birds 2 at launch, Royal Match). Paid refill of the whole bar is the usual instant option (Angry Birds 2: 60 gems; Candy Crush: about $0.99). Paid perks raise the cap (Candy Crush's Charm of Life 5 to 8; Royal Match up to 8 via its pass).
- **Typical stamina numbers:** Genshin Resin cap 160 raised to **200** in v4.7 (June 2024), **1 per 8 min** (about 26 h to fill), stages cost **20** (weekly bosses 30, then 60). Star Rail: 1 per **6 min**, cap 240 (later reported 300), plus an overflow store ("Reserved") of up to **2,400** at 1 per 18 min. Rule of thumb: a full bar is roughly one day's worth of play and fills in about a day.
- **Refund-on-fail convention:** lives games charge **only on failure** (a win is free). Stamina games increasingly charge **only on success**: Genshin and Star Rail spend the resource when you *claim the reward*, so a failed or abandoned attempt costs nothing; Arknights moved from refunding half on a failure, to all-but-1, to a **full refund** for normal operations. Quitting mid-level is the grey zone: Candy Crush-style games count a quit *after moves* as a loss; quitting before moving is inconsistent.
- **Ads for refills:** a rewarded video for **one life** (Angry Birds 2 at launch) or energy when the player runs out is the standard placement (Unity, AppLovin, Adjust, Chartboost guidance). Recommended daily caps vary widely by network: **1-2 per day** (AppLovin), 3-5 (InMobi), 5-8 per 20-50 min of play for casual (Pangle). Unity's advice: offer it at the moment of need, one tap away, and count ad rewards into the economy as if every ad is watched.
- **What players complain about:** being stopped mid-engagement ("I could not replay the level because of the lives system"); refills that cost more premium currency than normal play earns (Angry Birds 2 review, 2015); energy draining fast with slow regen and no free way to earn it (Hogwarts Mystery, 2018: 1 energy per 4 min, a widely mocked "wait or pay while your character is being strangled" moment, which led Jam City to cut prices); energy that doesn't fit the game's fiction; losing stamina on a failure; a cap that wastes regen while you sleep (Genshin players asked for years before the cap was raised).
- **What's considered fair:** charge on success or reward, not on failure (Clash Royale analysis; Adrian Crook; Arknights' refund changes); soft gating (keep playing, rewards slow down) over hard stops; an overflow/reserve so regen isn't wasted (Star Rail); a cap big enough for a sitting and a refill that fits the daily-return rhythm; multiple free ways to refill (friends/team gifts, ads, daily rewards); and alternative things to do when out of energy.
- **Industry view:** energy is mainly a retention and pacing tool (players come back daily), with refill sales a modest share of spending; experts warn against copying Candy Crush lives into games where they don't fit (PocketGamer.biz Mavens, 2014). For runners specifically, Deconstructor of Fun (2013) noted the genre had "no energy mechanics, no timers" and argued pacing should come from slowing progression instead.

## Detail per game

### Candy Crush Saga (King) — lives, hard gate
- Up to 5 lives outside events and perks; lose one when you fail a level's objective; one life returns every 30 minutes while below the cap, so about 2.5 h from empty. King's own community KB says a new life is added "in 30 minutes" if you don't buy more (search excerpt of the KB article; the page itself returned 404 when fetched).
- Ways to refill: friends send lives, buy a full set, Charm of Life raises the cap from 5 to 8 (Adrian Crook: refill about $0.99, Charm about $16.99).
- Quitting: fan wikis say quitting after making a move costs a life; quitting before moving is reported inconsistently across versions. Closing the app mid-level costs a life. No official King statement found.
- Clash Royale analysis (Pellerano, 2016) modelled it as a pool of 5 energy where a loss costs one and a win returns it: "hard waiting", since without lives you cannot replay at all. Energy priced about $0.14-0.16 per unit at typical bundle tiers.

### Angry Birds 2 (Rovio) — lives (launch, 2015)
- 5 lives, 30 minutes each; 60 gems refills all five; a video ad restores one life immediately (Macworld, Aug 2015).
- Complaints: couldn't replay levels for better scores because of lives; gems from missions and daily play too slow to afford refills; constant offers to pay to continue a stage or refill. Its move to Candy Crush-style lives was itself a review talking point (Business Insider: "Angry Birds meets Candy Crush"). No current official Rovio help page found.

### Royal Match (Dream Games) — lives
- Lose a life per failed level; one life refills every 30 minutes (about 2.5 h from empty); cap 5, up to 8 with the Royal Pass (guides; conflicting). Team members can gift lives (request once per 24 h); lives also buyable with coins; occasional ads for lives (guides, low trust). Some players complain of being pushed to ads for lives (a consumer complaint site). No official help page found.

### Puzzle & Dragons (GungHo) — stamina scaling with level
- Stamina gates dungeon entry; the cap rises and refill slows as the player levels (so early play is fast, later play paced). A failed run can be continued for one Magic Stone (about $1) within 10 seconds (Adrian Crook). Ed Biden (2015) cites P&D and Brave Frontier varying energy cost per dungeon as a way to give players strategy over it.

### Genshin Impact (HoYoverse) — Original Resin, pay on reward
- Regenerates 1 per 8 minutes. Cap 160 until v4.7, then 200 (announced in the May 22, 2024 Developers Discussion, live June 5, 2024): full in about 26 h instead of 21. Regen speed unchanged.
- Costs: domains and Ley Line outcrops 20; weekly bosses 30 for the first three each week, then 60.
- **Resin is spent when claiming the reward, not on entry**: you can fight a domain or boss without Resin. Failure therefore costs nothing.
- Primogems can buy 60 Resin (escalating cost; a daily limit is widely reported but not confirmed in what we could read). Condensed Resin lets players bank some.
- Complaint: the cap wasted regen overnight; players asked for an increase for years, and some still wanted a reserve like Star Rail's.

### Honkai: Star Rail (HoYoverse) — Trailblaze Power with reserve
- Regenerates 1 per 6 minutes; cap 240 at v1.3 coverage (later guides say 300). Once full, Reserved Trailblaze Power accumulates at 1 per 18 minutes up to 2,400 and can be moved back into the main pool. Introduced in v1.3 (2023) as an answer to wasted overflow; press framed it as more generous than Genshin.

### Arknights (Hypergryph) — Sanity, refunds on failure
- Wiki change log: one update standardised the failure penalty so a failed Challenge Mode stage refunds all Sanity but one point (previously half, rounded down), across all stages including events; a later update ("Ato" operations QoL) refunds the full amount on failure in Normal and Challenge Mode, except Annihilation. Exact dates not given on the page.

### Clash Royale (Supercell) — implicit energy via chest slots (2016)
- Winning a battle awards a locked chest; 4 slots; chests open one at a time (silver about 3 h, gold 8 h). Full slots mean "zero energy": you can keep playing but wins earn nothing. A loss costs nothing. "Soft waiting" versus Candy Crush's "hard waiting". Weighted cost per "energy" $0.19-0.33 (Pellerano, Game Developer, March 2016). The chest system has since been reworked; these numbers are the 2016 design.

### Super Mario Run (Nintendo) — tickets for a mode
- The main World Tour levels are free to replay (paid once to unlock). The competitive Toad Rally mode costs 1 Rally Ticket per play; tickets come from Pink Coin challenges, finishing worlds, Bonus Houses and My Nintendo rewards; you can hold at most 99 (My Nintendo reward page). A ticket-per-mode model rather than per-level energy.

### Endless runners: Temple Run 2, Subway Surfers, Jetpack Joyride — no entry cost
- No energy or timers (Deconstructor of Fun, 2013). Monetisation is soft currency from runs, upgrades, characters, ads (Subway Surfers about one ad per session in 2013) and paid continues. Under 1% of players pay.
- Revives: Temple Run let you resume after a crash for gems; Subway Surfers spends Keys to continue, and fan guides say the key cost doubles with each revive in the same run (not confirmed officially). Later both pivoted towards ad-driven monetisation (Naavik). One 2026 review claims Subway Surfers has an energy system that is slow to recharge; not verified, possibly a side mode.

### Harry Potter: Hogwarts Mystery (Jam City, 2018) — the cautionary tale
- Story actions cost energy; reported regen 1 per 4 minutes with no free way to earn more. A scene where the player's character is being choked by Devil's Snare demanded waiting or paying. Backlash on social media and the subreddit; Jam City cut IAP prices within weeks. It still grossed in the top 10.

### Industry commentary
- **Mobile Free To Play (Ed Biden, June/July 2015):** energy exists for habituation, content pacing, monetisation and strategic choice; disliked by players because it feels arbitrary and rarely fits the fiction. Alternatives: pace *rewards* not play (Hearthstone daily quests), framing (call it a bonus, not a penalty), let players choose what to spend on.
- **PocketGamer.biz Mobile Mavens (June 2014):** energy fits short mobile sessions ("5-10 three-minute sessions a day") and retention; refill sales a small share of hard-currency spend; copying Candy Crush lives without fitting them is a mistake; give alternative routes when blocked (Trials Frontier: unlimited retries); tune regen and bar size by A/B test, but decide whether to have energy at all in pre-production.
- **Zoya Street, PocketGamer.biz (July 2014):** the resentment is about some players waiting for what others buy; most players simply wait (cites 70% of players who reached Candy Crush's last level never having paid).
- **Adrian Crook (republished 2026, originally older):** reward success rather than punish failure; prefer soft waits to hard stops, which can strand players on a hard level.
- **Ads (Unity/ironSource Dec 2021; AppLovin MAX docs; Adjust; Chartboost; InMobi; Pangle):** offer rewarded video at the moment of need (out of lives/energy, after failing for an extra life, doubling end-of-level rewards); keep it one tap away; cap per day (1-2 AppLovin; 3-5 InMobi; 5-8 per 20-50 min Pangle) and A/B test; count every available ad in the economy maths; give paying/subscribed players the reward without watching.

## Sources

- King community KB, Candy Crush Saga "Lives" (search excerpt only; 404 when fetched): https://community.king.com/en/candy-crush-saga/kb/articles/484-lives
- Candy Crush Saga Wiki (fan), Lives: https://candycrush.fandom.com/wiki/Lives
- Andrew Pellerano, "Energy Systems Are Back! Clash Royale", Game Developer, 21 Mar 2016: https://gamedeveloper.com/design/energy-systems-are-back-clash-royale
- Adrian Crook, "Energy Systems: Lessons from Top Freemium Games" (page dated 15 Jun 2026): https://adriancrook.com/?p=8174
- Macworld, "Freemium Field Test: Angry Birds 2", 11 Aug 2015: https://www.macworld.com/article/226106/freemium-field-test-angry-birds-2-is-a-somewhat-muddled-return-to-form.html
- Business Insider, Angry Birds 2 review (2015): https://www.businessinsider.in/angry-birds-2-review-angry-birds-meets-candy-crush/articleshow/48308107.cms
- Royal Match lives guides (low trust): https://simplegameguide.co.uk/royal-match-lives-things-to-know , https://twinfinite.net/guides/how-to-get-more-lives-in-royal-match
- Genshin Impact v4.7 Resin cap (press on the 22 May 2024 Developers Discussion): https://www.destructoid.com/genshin-impact-will-increase-its-resin-cap-in-version-4-7/ , https://beebom.com/genshin-impact-increases-resin-cap
- Genshin Resin costs and claim-on-reward: https://game8.co/games/Genshin-Impact/archives/301612 , https://genshinimpact.wiki.fextralife.com/Domains
- Honkai: Star Rail Reserved Trailblaze Power (v1.3, 2023): https://primagames.com/tips/how-to-get-reserved-trailblaze-power-in-honkai-star-rail , https://www.rpgsite.net/news/14699-honkai-star-rail-update-13-will-revamp-the-games-energy-system , https://www.icy-veins.com/honkai-star-rail/trailblaze-power
- Arknights wiki, Gameplay and Base Changes: https://arknights.wiki.gg/wiki/Gameplay_and_Base_Changes
- Super Mario Run: My Nintendo reward "5 Toad Rally Tickets": https://my.nintendo.com/rewards/0d341e60008d67e6?lang=en-GB ; iMore guide: https://www.imore.com/how-get-more-toad-rally-tickets-super-mario-run
- Michail Katkoff, "Monetizing an Infinite Runner", Deconstructor of Fun, Feb 2013: https://www.deconstructoroffun.com/blog//2013/02/monetizing-infinite-runner.html
- Subway Surfers gameplay analysis, Game World Observer, Jun 2016: https://gameworldobserver.com/2016/06/24/subway-surfers-gameplay-analysis
- Naavik, "Evolution of Hybridcasual": https://naavik.co/deep-dives/evolution-of-hybridcasual-deepdive/
- Subway Surfers key revives (fan guide, low trust): https://theriagames.com/?p=125905
- Hogwarts Mystery backlash, 2018: https://www.pocketgamer.biz/news/68052/jam-city-slashes-harry-potter-hogwarts-mystery-iaps/ , https://thenextweb.com/news/new-harry-potter-game-sucks-magic-hogwarts , https://www.pocketgamer.com/harry-potter-hogwarts-mystery/making-the-case-for-harry-potter-hogwarts-mysterys-energy-system/
- Ed Biden, "Eliminating Energy", Mobile Free To Play, 2 Jul 2015: https://mobilefreetoplay.com/eliminating-energy/ (and "Understanding Energy Systems", 18 Jun 2015)
- Jon Jordan (ed.), "Is there any place in the F2P designer's toolbox for energy-based systems?", PocketGamer.biz, 6 Jun 2014: https://www.pocketgamer.biz/is-there-any-place-in-the-f2p-designers-toolbox-for-energy-based-systems/
- Zoya Street, "Should you hate energy mechanics?", PocketGamer.biz, 8 Jul 2014: https://www.pocketgamer.biz/should-you-hate-energy-mechanics/
- Anna Popereko, "The fundamentals of rewarded video ad placements", Unity, 23 Dec 2021: https://unity.com/blog/the-fundamentals-of-rewarded-video-ad-placements
- AppLovin MAX, "Using rewarded videos more effectively": https://support.applovin.com/en/max/best-practices/tips-for-using-rewarded-videos-more-effectively
- Adjust, "Understanding rewarded video ads": https://www.adjust.com/blog/understanding-rewarded-video-ads
- InMobi, "Succeeding with rewarded ads: the three commandments": https://www.inmobi.com/blog/succeeding-with-rewarded-ads-the-three-commandments
- Pangle, rewarded video ads guideline: https://www.pangleglobal.com/knowledge/rewarded-video-ads-guideline
