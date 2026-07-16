# Patron Gods — system design sketch

*Status: **PROPOSED** (drafted 2026-07-16 from the owner's ruling; awaiting owner shaping).
Frame source: `../cosmic-casino-canon.md` · ruling record: `../story-canon.md` "The Setting".
Build epic: **KAN-7** (progression/audience) — nothing here is implemented early; only the
seed-data schema stub may land with the W2 schema pass.*

**Owner's ruling (verbatim intent):** implement a bunch of patron gods you can get
randomly, with random stats on how generous they are, how powerful they are, what type of
buffs they give, and what you need to do to win more favor with them.

## Where it sits in the existing machine

| Existing GPT system | Patron-god layer |
|---|---|
| Exposure tiers Viewers → Followers → **Patrons** | Viewers/Followers stay the mortal-ish crowd; the **Patron tier becomes gods at the table** ⟨open Q1⟩ |
| Directives (quests from the power that runs the show) | **The house/dealer speaks** — the fallen god running the table |
| Goals (crowd challenges) | Side bets from the gallery (unchanged mechanically) |
| Camera Call | The odds board turns to you (unchanged mechanically) |
| Tags | Crowd labels; **epithets** are the patron-granted subset at favor milestones ⟨open Q2⟩ |
| Ascension (retire → patron) | Canon: winners take winnings → divinity → join the table as gamblers |
| Loot boxes / comps | The vehicle patron boons arrive in (see diegesis, below) |

## The data model (seed data, JSON — schema stub only until KAN-7)

```
patron_god {
  id, name, origin,            # forgotten religion or invented — "anything goes" (canon §4)
  domains: [..],               # e.g. fire, fortune, hearth, war, storms, vermin, debt
  generosity: 1-5,             # how often/much they tip the dealer for you
  power: 1-5,                  # magnitude of boons (their bankroll/divinity)
  temperament,                 # flavor + curse/trial style when displeased
  favor_conditions: [..],      # what wins favor — behavioral demands, e.g.
                               #   "finish fights with their domain", "show mercy",
                               #   "never retreat", "make the crowd laugh", "hoard nothing"
  boon_table: [..],            # domain-aligned buffs/items/heals (tip outcomes)
  trial_table: [..],           # what displeasure/rival-tips look like (trials, curses, spawns)
}
```

Contestant-side state: `patron_id`, `favor` (a score the favor rules move), tip history.

## Rules of the layer (v1, deterministic — no LLM required)

1. **Assignment is random but seeded.** Roster in seed data; the run seed draws the patron
   (and any per-run stat jitter) → replay/determinism preserved. Random stats can be
   per-god fixed values, per-run jitter, or both — owner's call ⟨open Q3⟩.
2. **Favor is a pure function of the event log.** Favor conditions are declarative
   predicates over sim events (kills by damage type, mercy events, retreat events, hype
   beats…). No hidden state; the same run always earns the same favor.
3. **Patron actions are dealer tips, entering the sim as schema-bound commands** — exactly
   the social-director discipline (DIRECTION.md contract §4): `patron_tip(boon|trial,
   magnitude, target)` emitted by the director interface, never direct state mutation.
   Favor thresholds trigger generosity rolls; magnitude caps scale with `power`.
4. **Two information planes hold.** Contestants never hear the casino. Boons arrive
   diegetically — a comp package in the loot drop, an inexplicable kindness of the dungeon,
   a System message the house would plausibly send ("a benefactor smiles on you").
   Spectators/replays get the announcer naming the god and the size of the tip — the
   dramatic irony is the product.
5. **Forsaken hook (later, free):** a run with `patron_id = null` — no tips either way,
   higher payout multipliers. A hardcore mode the fiction already names.

## Open questions (owner)

- **Q1** — Do patron gods *replace* the Patrons exposure tier (recommended: simplest, and
  the name already matches) or sit above it as a separate layer?
- **Q2** — Are epithets (patron-granted titles) a subset of the existing tag system or a
  new parallel track?
- **Q3** — Random stats: fixed-per-god roster (gods feel like characters), per-run jitter
  (roguelike variance), or fixed cores + small jitter (recommended)?
- **Q4** — Can a contestant lose/anger a patron into abandonment mid-run (and does a rival
  god poach)? Adds drama; adds state.
- **Q5** — Do rival patrons tip *against* the player's party in co-op (trials targeting a
  teammate), or only against enemies/the environment in Stages 1–2?
