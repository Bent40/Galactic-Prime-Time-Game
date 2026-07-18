# Mythology Research Spec — criteria, schema, and conduct plan

Status: **RULED — executable** (owner, 2026-07-18: "all four approved, with
caveats"; amendments folded in below, see §8). A research session can execute
this spec as written.

## 1. Purpose — what the data must feed

This research exists to power four in-game systems (all already canon):

1. **The patron-god roster** — background-driven bidding, deal sheets
   (favor_conditions + taboos), the multiplier boon economy, faction spill-over,
   buy-outs, rival bless/curse (`docs/design/patron-gods.md`,
   `data/patron_gods.json` stubs).
2. **The divine influence hierarchy** — modern religions are the biggest
   investors > story pantheons > lower deities on rarer/lower tables
   (`influence` 1–5; table tiers Normal / VIP / VVIP-Forsaken).
3. **The epithet/myth catalog** — trait-based myth *recreation* earns epithets;
   catalog is real mythology graded ORV-style
   (folk tale < local legend < heroic epic < world myth).
4. **Content seeds** — beasts/fiends → enemy blocks and boss concepts; heroes →
   epithet templates and legendary NPC contestants; folk entities → events,
   minor NPCs, loot flavor; artifacts → item seeds; fallen/bankrupt gods →
   dealers and game hosts; specific gods → Forsaken table runners (the Enki
   pattern).

**Design principle: research output is seed-data-shaped, not essay-shaped.**
Every finding lands in a validated JSON record plus a short cited dossier. Prose
that doesn't fill a schema field is wasted effort.

## 2. Output contract — files and schemas

All research output lands in `data/mythology/`:

```
data/mythology/traditions.json    — one record per tradition (the census)
data/mythology/entities.jsonl     — one record per entity (gods, heroes, beasts…)
data/mythology/myths.jsonl        — one record per story
docs/research/mythology/<tradition>.md — per-tradition dossier (citations live here)
```

`scripts/validate_seeds.py` gets extended to validate all three (Wave 5).
The existing `data/patron_gods.json` stubs are superseded by a generator that
reads `entities.jsonl` (migration in Wave 5 — the three Greek stubs become
regular entity records).

### 2.1 `traditions.json` record

```json
{
  "id": "norse",
  "name": "Norse mythology",
  "family": "germanic",
  "region": "Scandinavia / North Germanic",
  "living_worship": "revival",         // none | revival | minority | major
  "influence_ceiling": 3,               // max influence any entity here can have
  "recognition_ceiling": 5,             // max pop-culture recognition here
  "source_quality": 4,                  // 1–5, see rubric §3.4
  "sensitivity_notes": "modern revival (Ásatrú); also co-opted symbols to avoid",
  "priority_wave": 1,                   // 1 = MVP, 2 = expansion, 3 = long tail
  "candidate_counts": {"god": 40, "hero": 12, "beast": 15, "folk": 20},
  "sources": ["Poetic Edda (Bellows tr., PD)", "Prose Edda", "..."]
}
```

### 2.2 `entities.jsonl` record

```json
{
  "id": "norse_odin",
  "entity_class": "god",        // god | fiend | hero | villain | beast | folk | spirit | artifact
                                 // spirit = angels, jinn, divine servitors, messengers
  "names": {
    "primary": "Odin",
    "variants": ["Óðinn", "Wotan", "Woden"],
    "epithets_traditional": ["Allfather", "Wanderer", "Raven God"]
  },
  "tradition": "norse",
  "pantheon": "aesir",
  "syncretic_group": "odin_wotan",  // one group per cross-tradition identity; null if unique

  "influence": 3,                // 1–5 worship-based (rubric §3.1) — divinity wealth
  "recognition": 5,              // 1–5 pop-culture recognition (rubric §3.2) — audience draw
  "obscurity_tier": "common",    // derived from recognition: common|uncommon|rare|mythic
  "depiction_risk": "low",       // none | low | living | restricted (rubric §3.3)
  "ip_status": "traditional",    // traditional | public_domain_literary | modern_ip_excluded

  "domains": ["wisdom", "war", "death", "magic", "poetry"],   // controlled vocab §4
  "iconography": {"symbols": ["spear", "one eye", "ravens"], "animals": ["raven", "wolf", "eight-legged horse"], "colors": ["grey", "midnight blue"]},

  "personality": {               // all 1–5; drives deal-sheet generation §5
    "generosity": 3, "strictness": 4, "pettiness": 2,
    "wrath": 3, "fidelity": 2, "risk_appetite": 5
  },
  "temperament": "one-line characterization in the casino frame",

  "patron_capable": true,
  "patron_block": {              // required iff patron_capable
    "favor_conditions": ["win by sacrificing something valuable mid-run", "learn a boss's win condition before engaging", "fight on despite a disabled body part"],
    "taboos": ["break an oath sworn on camera", "waste knowledge freely given"],
    "boon_domains": ["wisdom", "war"],   // which action tags the multipliers touch
    "blessing_style": "cryptic pre-run intelligence; boons front-loaded as information, not stats"
  },
  "casino_roles": ["patron", "investor", "forsaken_host"],
  // patron | investor | dealer | forsaken_host | table_boss | vip_audience |
  // contestant_legend | messenger (corporate agent of an investor institution, §3.3)
  "ship_status": "greenlit",     // greenlit | deferred (researched now, added later) | excluded
  "table_tier_hint": "vip",      // normal | vip | vvip — from influence + recognition, §3.5

  "relations": [
    {"id": "norse_loki", "type": "blood_brother"},
    {"id": "norse_thor", "type": "parent_of"},
    {"id": "norse_fenrir", "type": "slain_by"}
  ],
  "myth_refs": ["myth_odin_mimir_eye", "myth_ragnarok"],
  "game_hooks": "free text: enemy/boss/item/event ideas this entity suggests",
  "rating_notes": "one line justifying influence + recognition scores",
  "sources": ["dossier §Odin"]
}
```

Non-god classes use the same record; `patron_capable` is false and
`patron_block` absent. Beasts should fill `game_hooks` with an enemy-block
sketch (size class, obvious condition affinities, discoverable-win-condition
idea — bosses are never damage races). Artifacts sketch an item seed.

### 2.3 `myths.jsonl` record

```json
{
  "id": "myth_odin_mimir_eye",
  "title": "Odin trades his eye for wisdom",
  "tradition": "norse",
  "grade": "world_myth",         // folk_tale | local_legend | heroic_epic | world_myth (§3.6)
  "participants": ["norse_odin", "norse_mimir"],
  "summary": "2–4 sentences, plain retelling.",
  "deed_profile": {"physique": 0, "reflexes": 0, "mind": 5, "charm": 1},
  // which traits the deed showcases — this is what myth RECREATION checks against
  "reenactment_hook": "permanently sacrifice a stat/skill/item of real value in exchange for hidden information, and win the run using it",
  "epithet_grants": [{"epithet": "the One-Eyed Seer", "trigger": "complete the reenactment on a VIP table or higher"}],
  "spectacle": 4,                // 1–5: how good TV the recreation is
  "sources": ["dossier §Odin"]
}
```

## 3. Rating rubrics — anchored so parallel researchers score alike

Every fan-out batch includes the **calibration set** (§6, Wave 0 output): the
same 6 pre-scored reference entities, so scores stay comparable across agents.
Every score gets a one-line `rating_notes` justification.

### 3.1 `influence` (1–5) — worship-based divine wealth

Measures **present-day real-world adherence/practice** — this is the god's
bankroll in the casino.

- **5** — figure of a living major religion (>100M adherents): Hinduism's
  principal deities; the Abrahamic institutions (see §3.3 — depiction gate).
- **4** — living significant practice (1–100M): Shinto kami, Yoruba orishas,
  Vodou lwa, major Buddhist cosmology figures, Chinese folk religion deities.
- **3** — organized revival or continuous folk practice (Ásatrú-scale;
  saints/folk figures with active local cults).
- **2** — extinct organized worship, strong cultural continuity (Greek,
  Egyptian, Norse core figures).
- **1** — extinct and locally remembered only (most Mesopotamian, Baltic,
  minor local deities).

### 3.2 `recognition` (1–5) — pop-culture audience draw

Measures what the **casino audience** (VIP table themed on human pop culture)
cheers for. Independent of influence — Zeus is recognition 5, influence 2.

- **5** — global household name (Zeus, Thor, Anubis, Medusa, dragons).
- **4** — known to anyone who's touched games/comics/movies (Loki's children,
  Susanoo, Quetzalcoatl, Baba Yaga).
- **3** — known to mythology-curious audiences (Enki, Tiamat, Väinämöinen).
- **2** — encyclopedia-depth (minor Olympians, most city gods).
- **1** — specialists only.

`obscurity_tier` derives mechanically: 5→common, 4→uncommon, 3→uncommon,
2→rare, 1→mythic. Obscure ≠ weak: a mythic-tier entity is *rare on the boards*,
which per canon means lower tables and rarer appearances — and a collector's
thrill when one bids on you.

### 3.3 `depiction_risk` — the sensitivity gate

- **none** — no living worship, no depiction norms (most Greek/Norse/Egyptian).
- **low** — revival worship exists; depict respectfully, no gate needed.
- **living** — actively worshipped today (Hindu deities, orishas, kami,
  bodhisattvas). **Each individual appearance as an on-screen patron NPC is
  owner-gated** — precedent: real controversies over Hindu deities in games.
  Safe default: present as off-screen investors whose boons arrive through
  intermediaries.
- **restricted** — the tradition itself restricts depiction or the material is
  culturally closed: Islamic prophets and God (never depicted, full stop),
  founders of living majors (Jesus, Muhammad, Buddha as *persons*), specific
  closed ceremonial content (much Aboriginal Australian sacred lore, many
  Native American nations' ceremonial stories). **Never rendered as characters.
  Institutions may exist as abstract investor entities; closed stories are
  simply not collected.** Public folk material from those cultures (e.g.
  widely-published trickster tale variants already in the public sphere) may
  be collected with `depiction_risk: restricted` noted for owner review.

**RULED (owner, 2026-07-18) — policy approved with the messenger carve-out:**
modern majors participate as *investor institutions* (large corporations whose
influence-5 money moves markets, buys out champions, funds tables); their
sacred core (God, prophets, founders) never appears as characters; `living`
figures owner-gated one by one; `restricted` material never depicted.
**Carve-out: messenger-tier figures (Metatron, Gabriel, beings of that level)
ARE depictable — as people inside the corporation, staff acting on the boss's
requests.** Corporate presentation (suits, badges, org-chart rank), never
religious iconography — the office is the protective abstraction layer.
Research these as `entity_class: spirit`, `casino_roles: ["messenger"]`.
**Canon lore (owner-approved, same ruling):** the three Abrahamic brands are
fronts of ONE holding company — a market-segmentation play to sell more product
and multiply gambling opportunities (recorded in
`docs/cosmic-casino-canon.md` §3).

### 3.4 `source_quality` (1–5) — per tradition

5 = rich primary texts in public-domain translation (Greek, Norse, Sanskrit
epics); 3 = solid academic secondary sources, thin primary; 1 = fragmentary or
orally-held (score caps how many entities we extract — thin sources mean small,
honest entries, not padded ones).

### 3.5 `table_tier_hint`

- **vvip / Forsaken-adjacent**: influence ≥4 OR (influence 3 + recognition 5).
- **vip**: influence 2–3 with recognition ≥3.
- **normal**: everything else. Lower deities appearing here at higher rarity is
  the canon rule — the hint is a default, the table system owns final placement.

### 3.6 Myth `grade` anchors (ORV-style)

- **world_myth** — creation, apocalypse, or pan-tradition pivots: Ragnarök, the
  Flood, Izanagi in Yomi, the churning of the ocean.
- **heroic_epic** — named-hero cycles: the Twelve Labors, Gilgamesh & Enkidu,
  Beowulf, Sun Wukong's rebellion.
- **local_legend** — bound to a place or single community: city founders,
  a spring's naming, a mountain's giant.
- **folk_tale** — domestic, anonymous, variant-rich: clever-fox stories,
  kitchen-spirit bargains.

Higher grade = higher-stakes recreation = stronger epithet. Stage-2 player-made
myths join the catalog later at grades earned, not claimed.

## 4. Controlled domain vocabulary

Researchers may ONLY use this list (extend via Wave-4 review, never ad hoc —
the boon economy multiplies *action tags*, so domains must stay joinable):

`war` · `hunt` · `sea` · `sky_storm` · `sun_fire` · `moon_night` · `earth_harvest`
· `death_underworld` · `wisdom` · `magic` · `trickery` · `craft_forge` · `healing`
· `love_beauty` · `music_performance` · `luck_gambling` · `wealth_commerce`
· `travel_speed` · `justice_oaths` · `chaos` · `beasts_wild` · `disease_poison`
· `protection_home` · `poetry_story` · `madness_dream` · `time_fate`

Wave 5 maps each domain to: boosted action kinds/tags (e.g. `war`→melee
declares, `travel_speed`→movement, `music_performance`→hype gain), condition
affinities (`sun_fire`→burn, `disease_poison`→poison/infected), and loot-affix
families. `luck_gambling` deities are casino nobility — flag every one found.

## 5. Personality axes → deal-sheet generation

The five personality numbers are *generator inputs*, not flavor:

| axis | drives |
|---|---|
| generosity | boon frequency/magnitude; gift chance at affection thresholds |
| strictness | taboo count + penalty severity on the deal sheet |
| pettiness | rival-curse chance when you court other gods |
| wrath | punishment escalation speed after a taboo breach |
| fidelity | buy-out resistance; low fidelity = abandons/sells your contract sooner |
| risk_appetite | bet exoticness; ≥4 = eager Forsaken host |

**Forsaken hosting is NOT influence-gated (owner ruling, 2026-07-18):** any god
can go all-in — including a god with nothing left, staking its own existence on
the table. A god that loses its all-in can be erased/bankrupted, and that loss
can **unlock new stages** (content the erasure opens). Research implication:
flag desperate, declining, or nothing-to-lose deities as Forsaken-host
candidates *alongside* the high-rollers; note any myth where a god wagers its
existence or is unmade (`game_hooks`).

## 6. Conduct — the wave plan

Fan-out subagents per tradition, same rules as prior audits: flat fan-out, no
nested subagents, every agent gets the schema + vocab + rubric + calibration
set verbatim, output is validated JSON not prose.

- **Wave 0 — calibration (in-session, cheap).** Hand-score 6 reference
  entities spanning the rubric (proposal: Zeus, Ganesha*, a Shinto kami*,
  Väinämöinen, Baba Yaga, a minor Mesopotamian city god). Freeze as the
  calibration set shipped with every later prompt. (*living-risk examples on
  purpose — calibrates §3.3.)
- **Wave 1 — census (one agent per tradition family).** No deep entries: each
  returns a `traditions.json` record + candidate list (name, class, one line,
  provisional recognition). Output: the full tradition map with counts →
  owner + I pick the Wave-2 shortlist.
- **Wave 2 — extraction (one agent per priority tradition).** Full
  `entities.jsonl` records for the shortlist + the tradition dossier with
  citations. Patron-capable entities must ship a complete `patron_block`.
- **Wave 3 — myth catalog.** For every patron-capable or epithet-worthy
  entity: `myths.jsonl` records with deed profiles + reenactment hooks. Target
  ≥2 myths per patron-capable god, ≥1 per hero.
- **Wave 4 — cross-linking + dedup (single agent + my review).** Build
  `syncretic_group`s (Zeus/Jupiter, Odin/Wotan, Inanna/Ishtar/Astarte — one
  playable identity each, variants as skins/aliases); verify relations are
  reciprocal; normalize any vocabulary drift; flag rubric outliers vs the
  calibration set.
- **Wave 5 — game mapping (me, in the dev session).** Extend
  `validate_seeds.py`; build domain→tag/condition/affix mapping table; write
  the patron-roster generator that emits `patron_gods.json`-shaped records
  from `entities.jsonl` (numbers stay PLACEHOLDER per R14); migrate the three
  Greek stubs; wire table-tier placement.

### Tradition census list (Wave 1 input — ~24 families)

Greek/Roman · Norse/Germanic · Egyptian · Mesopotamian · Hindu† · Buddhist
cosmology† · Chinese (folk/Taoist)† · Japanese/Shinto† · Korean · Mesoamerican
· Andean · Yoruba/West African† · Vodou† · Slavic · Celtic · Finnish/Baltic ·
Polynesian/Māori‡ · Aboriginal Australian‡ · Inuit‡ · Native North American‡ ·
Abrahamic folk corpus† (angels/messengers, demons, saints, golem — figures,
not the sacred core; messenger tier depictable per §3.3) · Zoroastrian ·
Arthurian/medieval legend · global folklore corpus (fairy-tale types,
widely-known cryptids) · **cosmic horror**◊ (Lovecraft circle + public-domain
mythos: outer gods, great old ones; per-entity `ip_status` — Derleth-era and
later additions flagged) · **internet folklore**◊ (creepypasta, SCP-class,
Slenderman-class; per-entity license/IP flags — SCP is CC BY-SA, Slenderman is
claimed IP).

† = expect many `living` entries · ‡ = expect `restricted` screening; census
still runs — it *reports* what's closed rather than assuming ·
◊ = **researched now, `ship_status: deferred`** (owner ruling 2026-07-18: in
scope for research, not necessarily added immediately).

### Volume targets (Wave-1 census may revise)

Census: all ~26 (incl. the two ◊ deferred families) · Extraction: ~150
entities (≈60 patron-capable gods, 30 heroes, 30 beasts/fiends, 30
folk/spirits/artifacts) · Myths: ~120 · **MVP patron roster: 24 gods** spread
across influence tiers and ≥8 traditions. **APPROVED (owner, 2026-07-18).**

## 7. Source rules & honesty bars

- **Source ladder:** public-domain primary translations > academic reference
  works > Wikipedia as an *index* (claims verified one level down) > fan wikis
  never as sole source.
- **No invention.** Unknown = `null` + a note, never a plausible guess. A myth
  that can't be sourced doesn't exist. Small honest entries beat padded ones.
- **IP boundary (RULED 2026-07-18):** traditional material and public-domain
  literature ship freely. Cosmic horror and internet-era folklore ARE
  researched (census + extraction) but land as `ship_status: deferred` — the
  owner decides per entity/wave when they enter the game. Every non-traditional
  entity carries an honest `ip_status`:
  `traditional | public_domain_literary | cc_licensed | modern_ip_flagged` —
  `cc_licensed` records the exact license (SCP = CC BY-SA 3.0, share-alike
  obligations noted), `modern_ip_flagged` records who claims it
  (Slenderman-class). Nothing `modern_ip_flagged` ships without a separate
  clearance decision; researching it is legal, shipping it is the gate.
  Traditional cryptids (Mothman-class reported legends) are ordinary folklore:
  `greenlit`.
- **Acceptance criteria (gate for each Wave-2/3 batch):** every record
  validates against schema; every patron-capable god has ≥3 favor_conditions,
  ≥2 taboos, ≥1 myth ref, complete personality axes; every rating has
  `rating_notes`; every entity resolves to a dossier citation; calibration-set
  scores within ±1 of frozen values, else the batch is re-run, not hand-patched.

## 8. Decision points — ALL RULED (owner, 2026-07-18)

- **D-1 APPROVED + amended** (§3.3): investor-institution frame for modern
  majors; per-figure gate for `living`; never depict `restricted` —
  **carve-out: messenger-tier figures (Metatron, Gabriel, that level) are
  depictable as corporate staff acting on the boss's requests.** Plus the
  approved lore: the three Abrahamic brands = one holding company running
  segmented fronts for sales and gambling volume.
- **D-2 APPROVED** (§6): volume targets as written.
- **D-3 AMENDED** (§6/§7): internet-era folklore AND cosmic horror
  (Cthulhu mythos, outer gods and the like) are IN for research, shipped
  `deferred` — researched now, added when the owner says so.
- **D-4 APPROVED as exclusion:** real historical humans are OUT — including
  the deified ones (Guan Yu-class) for now. Their *legend cycles* may still be
  censused as stories under their tradition; the person doesn't become an
  entity. (Interpretation note: the owner's "historical figures can be out"
  is recorded as a full exclusion; cheap to revisit if Guan Yu-class deities
  were meant to survive.)
- **Forsaken amendment** (§5): all-in hosting is open to ANY god, existence
  can be the stake, and a god's loss can unlock new stages.
