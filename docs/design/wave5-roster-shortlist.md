# Wave 5 — proposed 24-god MVP patron roster (distinctness / edge-case / build-diversity pass)

Curated from the 114 patron-capable entities to be **maximally distinct** — so the slice/
Stage-2 systems get stressed at their edges and players get genuinely different builds to
chase. Spans **12 traditions**, **all 5 influence tiers**, **every personality extreme**,
**19 of 26 boon domains**, and the mechanical edge cases (off-screen investor, fidelity-1
buy-out magnet, pure-luck floor, Forsaken all-in, living-major gate). Owner picks/edits;
this is a proposal, not a lock.

| # | God | Tradition | inf/tier | Boon domains | What it TESTS (edge case / build it enables) |
|---|---|---|---|---|---|
| 1 | **Ganesha** | hindu | 5 vvip | wisdom, luck, wealth | Living-major **investor gate** (on-screen appearance is owner-gated); luck+wealth build |
| 2 | **Avalokiteshvara** | buddhist | 5 vvip | healing, protection, sea | Personality extreme: **generosity 5 / fidelity 5 / wrath 1** (the pure-generous loyal patron); defensive/healing build; covers `sea` |
| 3 | **Amaterasu** | japanese | 4 vvip | sun_fire, justice, protection | Living anchor; sun/leadership/oath build |
| 4 | **Yama** | buddhist | 4 vvip | death, justice, time_fate | Personality extreme: **strictness 5 / risk 1** (the strict, cautious death-judge); taboo-heavy deal sheet |
| 5 | **Palden Lhamo** | buddhist | 4 vvip | luck, war, time_fate | **risk_appetite 5** (eager Forsaken host at high influence); aggressive-gamble build |
| 6 | **Caishen** | chinese | 4 vvip | wealth, luck | The **wealth-god** greed build; the Caishen influence flag lives here |
| 7 | **Santa Muerte** | abrahamic | 4 vvip | death, protection, luck | **Nothing-to-lose Forsaken** at high influence; generosity 5 **but wrath 5** on a broken vow — the jealous-saint contract edge |
| 8 | **Eshu** | yoruba | 4 vvip | trickery, luck, travel | Messenger+dealer crossroads trickster; **movement/trickery** build; West-African flavor |
| 9 | **Odin** | norse | 3 vip | wisdom, war, magic | **Cryptic-intel/prep** build (boons as foreknowledge, not stats); Forsaken |
| 10 | **The Morrígan** | celtic | 3 vip | war, time_fate, magic | Personality extreme: **pettiness 5** (rival-curse mechanic tester); war/fate |
| 11 | **Morgan le Fay** | arthurian | 3 vip | magic, healing, death | Two-faced **heal-you / poison-your-rival** vengeance build |
| 12 | **Benzaiten** | japanese | 3 vip | music, luck, wealth | **Spectacle/Charm** build (Charm scales the crowd payoff per default #6); music + luck |
| 13 | **Zeus** | greek | 2 vip | sky_storm, justice, protection | The **on-camera oath-contract** build; **fidelity 1** buy-out magnet; calibration anchor |
| 14 | **Athena** | greek | 2 vip | wisdom, war, craft_forge | **Prep + flawless-execution** build (scout-first, no-damage clears, craft-and-win) |
| 15 | **Hades** | greek | 2 vip | death, wealth, justice | Personality extreme: **fidelity 5 / risk 1**; **attrition / no-cheating-death / hold-the-line** build |
| 16 | **Hermes** | greek | 2 vip | trickery, travel, luck | Dealer+messenger; **speed/luck** build; the knucklebone-dice casino angle |
| 17 | **Loki** | norse | 2 vip | trickery, chaos, magic | **fidelity 1** buy-out magnet + chaos/trickster build |
| 18 | **Tezcatlipoca** | mesoamerican | 2 vip | trickery, luck, moon_night | **fidelity 1** buy-out magnet + night/chaos; Mesoamerican flavor |
| 19 | **Inanna** | mesopotamian | 2 vip | love_beauty, war, chaos | The **descent** myth; love+war build; Mesopotamian flavor |
| 20 | **Beelzebub** | abrahamic | 1 normal | disease_poison, death, chaos | **Poison/attrition/swarm** build (the rare `disease_poison` lane); Forsaken |
| 21 | **Gad** | abrahamic | 1 normal | luck, wealth | **The honest-floor pure-luck patron** (inf 1 / rec 1 — rare-board collector's thrill); reweighted-dice build |
| 22 | **Lucifer** | abrahamic | 1 normal | chaos, sun_fire, luck | **The archetypal Forsaken all-in** (stakes existence); leverage-loan build; famous-but-poor (inf1/rec5) tier edge |
| 23 | **Mammon** | abrahamic | 1 normal | wealth, luck, trickery | **fidelity 1** — THE buy-out-magnet mechanic tester; treasure-greed build |
| 24 | **Ra** | egyptian | 2 vip | sun_fire, justice, wisdom | Adds the missing **Egyptian** pantheon; sun-king / cosmic-order / prophecy build |

> **Correction (2026-07-18):** slot #24 was originally **Anansi** — a mistaken pick: he's
> extracted as `folk` / `patron_capable: false` (no deal sheet), so he could not be a patron
> without fabricating one. Replaced with **Ra**, who is genuinely patron-capable AND fills the
> roster's only major-pantheon gap (there was no Egyptian god). Anansi remains a folk
> dealer/contestant-legend in the data, unchanged.

## Coverage checks
- **Influence tiers:** i5×2 · i4×6 · i3×4 · i2×9 · i1×3 — every tier, weighted toward the playable-VIP band. (13 traditions now, incl. Egyptian.)
- **Personality extremes:** generosity-hi (Avalokiteshvara) · strictness-hi (Yama) · pettiness-hi (Morrígan) · wrath-hi (Santa Muerte) · risk-hi (Palden Lhamo/Lucifer) · risk-lo (Yama/Hades) · **fidelity-1 buy-out magnets ×4** (Zeus, Loki, Tezcatlipoca, Mammon) to stress the contract-sale mechanic.
- **Casino roles:** investor (Ganesha), Forsaken hosts (Lucifer + 8 more), dealers (Hermes, Gad, Mammon, Eshu), messenger (Hermes, Eshu).
- **Build archetypes:** aggression, prep/defense, attrition/death, trickery, treasure-greed, spectacle/Charm, oath-keeping, speed/movement, underdog, healing/protection, poison/swarm, gamble/luck.
- **Domain gaps (deliberately deferred to expansion):** `hunt`, `beasts_wild`, `poetry_story`, `madness_dream`, `sea`-heavy — thin in the corpus; add when a build needs them.

## Next
On owner sign-off, Wave 5 builds the patron-roster generator that emits `patron_gods.json`
records for these 24 (numbers PLACEHOLDER per R14), plus the domain→tag/condition/affix
map and the `validate_seeds.py` extension for `data/mythology/`.
