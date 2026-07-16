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
4. **Refusing every offer leaves you undrafted, NOT Forsaken** ⟨open, part of Q6⟩ — a
   patron-less run: no escort, no directed bets, at most stray donator tips. Whether
   refusal is even allowed, and what an undrafted run is worth, is open.
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

## The boon economy — the multiplier model (owner, 2026-07-16 — adopted direction)

**The patron decides how much, which type, and how strong.** Every domain-relevant action
you take generates buff *chances*; a patron god is a **multiplier profile** laid over that
stream — skewing which buff types you're offered, their tier odds, and where your rising
affection lands. *(All numbers below are the owner's illustrative placeholders — R14
discipline applies: seeded numbers are placeholders until tuning.)*

**Worked example (owner's, Ares — domain: melee weapons).** Action: you kill a boss with
a melee weapon.

| | melee-buff chance | tier-2 chance | related lesser gods | affection |
|---|---|---|---|---|
| **With Ares as patron god** | **+0.12x** | **+12%** | +0.08x to *their* buffs | rises with a god-specific modifier — gains channeled toward Ares/his faction |
| **Without a patron** | +0.10x | +5% | (same +0.10x spread across *every* related god) | rises neutrally — no relation to any god faction |

The shape this implies:

1. **Actions emit domain-tagged impressions** (melee boss kill → war/melee), derived from
   sim events — deterministic, replayable.
2. **Patron-less baseline:** the impression raises buff chance and tier odds *diffusely*
   across all gods related to that domain; affection rises unfocused.
3. **With a patron:** the patron's own domains get the top multiplier and better tier
   odds; the patron's **related lesser gods** (faction) get a middle multiplier; affection
   gains are amplified and directed toward the patron's faction. The patron is the
   pantheon's attention, *focused*.

**Buff taxonomy (owner, 2026-07-16 — Q8 resolved).** "Buffs" cover BOTH surfaces:
**conditional blessings** and **loot/affix roll quality**. Duration classes:

- **temporary** — expires on its own;
- **continuous on a condition** — active while a condition holds (same design language as
  R3 priming: power gated on conditions, never timers);
- **permanent** — sometimes, depending on the buff.

**What non-patron affection buys (owner, Q8 resolved):** a higher chance those gods give
you things (donator tips), and it **raises buy-out interest** — the god your deeds keep
feeding is the god most likely to bid for your contract.

## The data model (seed data, JSON — schema stub only until KAN-7)

```
patron_god {
  id, name, origin,            # forgotten religion or invented — "anything goes" (canon §4)
  faction,                     # pantheon/relatedness group (drives "related lesser gods")
  related: [god_id..],         # or derived from faction + shared domains
  domains: [..],               # e.g. melee, fire, fortune, hearth, war, storms, vermin, debt
  generosity: 1-5,             # how often/much they tip the dealer for you
  power: 1-5,                  # magnitude of boons (their bankroll/divinity)
  buff_multiplier,             # patron-domain buff-chance bonus        (ex: +0.12x)
  tier_up_bonus,               # chance bump for higher-tier buffs      (ex: +12% T2)
  related_multiplier,          # spill-over to faction gods' buffs      (ex: +0.08x)
  affection_modifier,          # how strongly deeds convert to affection, and toward whom
  temperament,                 # flavor + curse/trial style when displeased
  favor_conditions: [..],      # what wins favor — behavioral demands, e.g.
                               #   "finish fights with their domain", "show mercy",
                               #   "never retreat", "make the crowd laugh", "hoard nothing"
  boon_table: [..],            # domain-aligned buffs/items/heals (tip outcomes)
  trial_table: [..],           # what displeasure/rival-tips look like (trials, curses, spawns)
}
```

Contestant-side state: `patron_id`, **`affection` per god (or per faction)** — not a
single favor score — plus running buff-chance/tier-odds accumulators per domain, and tip
history. Baseline (patron-less) rates live in one global config block, so the patron
layer is strictly a modifier on top.

## Rules of the layer (v1, deterministic — no LLM required)

1. **Assignment is background-driven bidding** (section above), seeded where variance
   enters → replay/determinism preserved. Stat randomness shape still open ⟨Q3⟩: fixed
   roster / per-run jitter / fixed cores + small jitter (recommended).
2. **Affection is a pure function of the event log.** Favor conditions and domain
   impressions are declarative predicates over sim events (kills by damage type/weapon
   class, mercy events, retreat events, hype beats…), feeding the per-god affection
   ledger through the multiplier model above. No hidden state; the same run always earns
   the same affection.
3. **Patron actions are dealer tips, entering the sim as schema-bound commands** — exactly
   the social-director discipline (DIRECTION.md contract §4): `patron_tip(boon|trial,
   magnitude, target)` emitted by the director interface, never direct state mutation.
   Favor thresholds trigger generosity rolls; magnitude caps scale with `power`.
4. **Two information planes hold.** Contestants never hear the casino. Boons arrive
   diegetically — a comp package in the loot drop, an inexplicable kindness of the dungeon,
   a System message the house would plausibly send ("a benefactor smiles on you").
   Spectators/replays get the announcer naming the god and the size of the tip — the
   dramatic irony is the product.
5. **Forsaken runs are god-initiated — the gods' way of going ALL-IN (owner ruling,
   2026-07-16).** Not a refusal and not patron-less: a Forsaken champion is **chosen by
   the gods to overcome a trial bigger than others.** Your patron god sponsors the run,
   but **no help is permitted** (canon §2, VVIP): the tip channel is sealed for every
   god, everything is solved alone, the divinity involved is much higher, and the
   sponsoring god's payout is much larger. Mechanically: `forsaken = true` on the run;
   patron relationship intact, assistance disabled, payout/divinity multipliers up.
   Game translation ⟨PROPOSED⟩: the *player* opts into a Forsaken run at creation
   (hardcore mode) — but the *fiction* frames it as the god choosing them; diegetically
   nobody volunteers. (Marcus is the template: Plutus went all-in — consent not
   included.)

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
  + freeform text (LLM-read later); 2–3 suitor offers. And: can the player refuse all
  offers at all — and if so, what is an *undrafted* (patron-less, non-Forsaken) run worth?
- **Q7** — Forsaken designation: meta-level it's presumably the player opting into
  hardcore at creation — confirm the fiction frames it as *the god choosing them* (and
  whether a patron god can also trigger it mid-campaign as a true all-in, Marcus-style).
- ~~**Q8**~~ — RESOLVED 2026-07-16: buffs = conditional blessings AND loot/affix roll
  quality; duration classes temporary / continuous-on-a-condition / sometimes permanent.
  Non-patron affection → higher chance of gifts from those gods + raises buy-out
  interest. (See "Buff taxonomy" above.)
