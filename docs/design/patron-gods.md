# Patron Gods — system design sketch

*Status: **PROPOSED** (drafted 2026-07-16 from the owner's ruling; awaiting owner shaping).
Frame source: `../cosmic-casino-canon.md` · ruling record: `../story-canon.md` "The Setting".
Build epic: **KAN-7** (progression/audience) — nothing here is implemented early; only the
seed-data schema stub may land with the W2 schema pass.*

**Owner's ruling (verbatim intent):** implement a bunch of patron gods, with stats on how
generous they are, how powerful they are, what type of buffs they give, and what you need
to do to win more favor with them.

## The two-tier structure (owner, 2026-07-16 — adopted)

- **patrons** (plural, the exposure tier's top rung): **gods who buy you things** —
  donators. Any number of them; they tip the dealer on your behalf, gift comps, place side
  bets. This IS the existing Viewers → Followers → Patrons ladder with gods at the top.
  *(Resolves former Q1.)*
- **THE patron god** (singular slot): the one god who **escorts you through the
  campaign** — directs the *types of bets* running on you, shapes your run's wager
  profile, and is usually your **biggest donator**. One per contestant (or none — see
  Forsaken, below).

## Assignment — background-driven bidding (owner-proposed 2026-07-16, PROPOSED synthesis)

Owner: *maybe not random — matched by **keywords in the player-written character
background**; gods can maybe **buy out** champions; or ORV-style, **only those without a
patron can choose a patron**.* Proposed synthesis of all three:

1. **The background is the audition tape.** OC creation includes a short background —
   freeform text plus a few structured picks (origin, vice, virtue, what you want back
   home). The structured picks map deterministically to god affinities in v1; the freeform
   text is LLM-read for keywords later (same staging as the social director — deterministic
   first, model-augmented behind the same interface).
2. **Interested gods bid.** Affinity match + seeded variance produces 2–3 suitor offers,
   each shown as a deal sheet: domains, generosity, temperament, favor demands.
3. **The player chooses — because only the patron-less can choose** (the ORV rule). Once
   bound, the player cannot swap; the relationship changes only from the god side.
4. **Refusing every offer = the Forsaken run.** No escort, no tips, higher payout
   multipliers — the hardcore mode stops being a menu toggle and becomes a *roleplay
   decision at creation*.
5. **Buy-outs are god-side drama (⟨open⟩):** a richer god can buy your contract from your
   patron god mid-campaign — triggered by performance (hype/favor thresholds), arriving
   diegetically as new bet types and a changed comp style. Rare, event-worthy, and it
   makes the player *feel traded*, which is exactly the spine.

## Where it sits in the existing machine

| Existing GPT system | Patron-god layer |
|---|---|
| Exposure tiers Viewers → Followers → **Patrons** | Viewers/Followers stay the mortal-ish crowd; the **Patrons tier = donator gods**; THE patron god is a singular slot above it |
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

1. **Assignment is background-driven bidding** (section above), seeded where variance
   enters → replay/determinism preserved. Stat randomness shape still open ⟨Q3⟩: fixed
   roster / per-run jitter / fixed cores + small jitter (recommended).
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

- ~~**Q1**~~ — RESOLVED 2026-07-16: Patrons tier = donator gods; THE patron god = singular
  escort slot above it (two-tier structure).
- **Q2** — Are epithets (patron-granted titles) a subset of the existing tag system or a
  new parallel track?
- **Q3** — Random stats: fixed-per-god roster (gods feel like characters), per-run jitter
  (roguelike variance), or fixed cores + small jitter (recommended)?
- **Q4** *(reshaped)* — Adopt the **buy-out** mechanic (god-side contract transfer,
  performance-triggered)? And can a displeased patron god *abandon* a contestant, leaving
  them patron-less (able to choose again, per the ORV rule) or Forsaken-locked?
- **Q5** — Do rival patrons tip *against* the player's party in co-op (trials targeting a
  teammate), or only against enemies/the environment in Stages 1–2?
- **Q6** — Confirm the bidding synthesis: structured background picks (v1, deterministic)
  + freeform text (LLM-read later); 2–3 suitor offers; refusal of all = Forsaken run.
