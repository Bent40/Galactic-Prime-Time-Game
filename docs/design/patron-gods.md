# Patron Gods — system design sketch

*Status: **DESIGNED** — all core questions (Q1–Q8) RULED by the owner 2026-07-16; numbers
remain placeholders (R14 discipline); bidding-flow details and marked ⟨PROPOSED⟩ items
still open for shaping.
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
   each shown as a deal sheet: domains, generosity, temperament — and the god's
   **EXPECTATIONS: the explicit dos and don'ts of this god** (RULED 2026-07-16). Dos =
   favor conditions; don'ts = taboos that cost affection (or worse) when crossed. You
   sign knowing exactly what pleases and what offends.
3. **The player chooses — because only the patron-less can choose** (the ORV rule). Once
   bound, the player cannot swap; the relationship changes only from the god side.
4. **Refusing every offer is allowed (RULED 2026-07-16, Q6):** it is simply a
   **patron-less run** — nothing else. Baseline diffuse gains, no escort, no directed
   bets, no special multipliers. Explicitly NOT Forsaken.
5. **Buy-outs (RULED 2026-07-16, Q4):** a buy-out means a god is willing to **overrule
   another god's divinity** — paying your patron god to take you, driven by the affection
   the rival has accumulated in you (boon economy, below). The champion receives a
   **notice of replacement** — showing **whether the current god agrees or not** — and
   may **accept or decline the new contract**. Diegetically: new bet types, a changed
   comp style; the player *feels traded*, which is exactly the spine.
6. **Abandonment (RULED 2026-07-16, Q4) — not a contract exit.** A displeased patron god
   doesn't release you; they change what you're *for*: either **extractive mode** —
   "I'll give you trials to max out on you even if you break, because you have no other
   use" (the god monetizes your breaking) — or **total neglect** (nothing, ever). The
   contract remains; the escort stops escorting.

## Divine influence hierarchy (owner, 2026-07-16 — RULED)

- **Influence follows modern belief and attention.** The gods of **modern religions hold
  the most influence — the biggest investors** at the tables. **Story-pantheons** (Zeus,
  Ares, the Greek roster and kin) come next: beloved as *characters humanity builds
  stories on*, not as living belief systems. Lower and forgotten deities trail down the
  curve.
- **Casting consequence (the production-cast ruling):** the big investors and the
  story-pantheons form the **recurring patron cast** — the gods players see again and
  again across runs, with shuffling among them. **Lower deities appear at higher rarity,
  or at lower tables.** The patron roster IS the show's recurring ensemble; authoring a
  god's temperament, dos/don'ts, and voice is casting an episode regular.
- **Data:** `influence` (1–5) on each god — drives bid frequency, table assignment, and
  appearance rarity. PLACEHOLDER values until the roster pass.
- ⟨Shipping note: depictions of modern religions carry rating/controversy weight — a
  deliberate handling decision for the roster pass, owner's IP call.⟩

## Where it sits in the existing machine

| Existing GPT system | Patron-god layer |
|---|---|
| Exposure tiers Viewers → Followers → **Patrons** | Viewers/Followers stay the mortal-ish crowd; the **Patrons tier = donator gods**; THE patron god is a singular slot above it |
| Directives (quests from the power that runs the show) | **The house/dealer speaks** — the fallen god running the table |
| Goals (crowd challenges) | Side bets from the gallery (unchanged mechanically) |
| Camera Call | The odds board turns to you (unchanged mechanically) |
| Tags | Crowd labels (unchanged); **epithets** are a separate traits/myth-recreation track (see Epithets section) |
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

## Epithets — traits and myth recreation (owner, 2026-07-16 — Q2 resolved)

Epithets are not crowd tags; they run on a **traits** track — **the champions are
compared to previous legends.**

- **Traits are the vocabulary:** you start with trait-words (*courageous, strong,
  hateful, avenger, …*) — seeded from the background picks — and earn more through deeds.
- **Myth templates are the goal state:** a legend's pattern, expressed as traits +
  signature deeds. When your accumulated pattern **recreates someone's myth, you gain an
  epithet from it.**
- **The myth catalog is REAL mythology, graded by level of myth (RULED 2026-07-16 —
  ORV-style):** folk tale < local legend < heroic epic < world myth — higher-grade myths
  demand rarer patterns and grant stronger epithets. Ascended players' runs compile into
  new templates at Stage 2 (they enter the catalog at an earned grade).
- **Canon synergy:** legends are literally artifacts of previous games (canon §3 — the
  winner decides how the apocalypse is remembered). Recreating a myth is re-walking a
  past champion's shape.
- **Stage-2 hook ⟨PROPOSED, later⟩:** an ascended player character's run compiles into a
  myth template — other players can then recreate *their* myth and wear their epithet.
  Cross-player content at zero authoring cost.
- Crowd **tags** stay the audience's labels; **epithets** are the pantheon's comparisons.
  Two tracks, deliberately separate — the label/essence tension the spine wants.
- **Epithet backlog (migrated from tags, owner 2026-07-17):** `nine_lives` ("Sasha the
  Nine-Lived" — the canonical example), `unkillable`, `vengeful`, `butcher`,
  `incorrigible` — first five entries for the myth-template/epithet vocabulary pass.

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
  favor_conditions: [..],      # the DOS — what wins favor, e.g.
                               #   "finish fights with their domain", "show mercy",
                               #   "never retreat", "make the crowd laugh", "hoard nothing"
  taboos: [..],                # the DON'TS — what costs affection when crossed (RULED:
                               #   shown on the deal sheet at bidding)
  boon_table: [..],            # domain-aligned buffs/items/heals (tip outcomes)
  trial_table: [..],           # what displeasure/rival-tips look like (trials, curses, spawns)
}
```

Contestant-side state: `patron_id`, **`affection` per god (or per faction)** — not a
single favor score — plus running buff-chance/tier-odds accumulators per domain, a
**`traits` list** (starting traits from background picks + deed-earned), earned epithets,
and tip history. Additional seed tables: **`traits`** (vocabulary) and
**`myth_templates`** (trait/deed patterns → epithet grants). Baseline (patron-less) rates
live in one global config block, so the patron layer is strictly a modifier on top.
Per-run god stats: **fixed cores + small seeded jitter** (RULED, Q3).

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
   Game translation (RULED 2026-07-16, Q7): **opting into hardcore** — the god offers
   you the chance **randomly, for higher stakes**. **Never on a first run; possible from
   the 2nd run onwards.** Can also be **triggered manually after winning with a character
   once** (CONFIRMED 2026-07-16). **No switching into Forsaken mid-campaign.**
   (Marcus is the template: Plutus went all-in — consent not included.)
   **Amendment (owner ruling, 2026-07-18): all-in is not reserved for the
   influential.** Any god can initiate a Forsaken game — including a god with
   nothing left, staking its own **existence** on the outcome. A god that loses
   its all-in can be erased/bankrupted, and that loss can **unlock new stages**
   (the erasure opens content). Desperate low-table gods are Forsaken hosts as
   much as the high-rollers.
6. **Rival gods can bless or curse your party (RULED 2026-07-16, Q5):** cross-party tips
   are gated on affection — **blessings require higher affection** with that god,
   **curses require lower**. Co-op griefing self-balances: a god that hates your party
   enough to curse it is a god your party starved.

## Question resolutions (all closed 2026-07-16)

- **Q1** — Two-tier structure: Patrons tier = donator gods; THE patron god = singular
  escort slot above it.
- **Q2** — Epithets run on the **traits track**: champions compared to previous legends;
  recreating a myth grants its epithet (see Epithets section).
- **Q3** — God stats: **fixed cores + small seeded jitter.**
- **Q4** — **Buy-outs adopted**: overruling another god's divinity; notice of replacement;
  player accepts/declines; shows whether the current god agrees. **Abandonment** is not a
  contract exit: extractive mode ("trials to max out on you even if you break") or total
  neglect.
- **Q5** — Rival gods **can bless or curse the party**, gated on higher/lower affection
  respectively.
- **Q6** — Refusing all offers is allowed: **simply a patron-less run, nothing else.**
  (Bidding flow details — structured picks, 2–3 offers, deal sheets — remain PROPOSED
  shaping.)
- **Q7** — Forsaken = **hardcore opt-in**: the god offers it randomly for higher stakes,
  never on a first run, from the 2nd run onwards; manual trigger after winning with a
  character once ⟨PROVISIONAL⟩; never mid-campaign.
- **Q8** — Buffs = conditional blessings AND loot/affix roll quality; temporary /
  continuous-on-a-condition / sometimes permanent. Non-patron affection → gift chance +
  buy-out interest.
