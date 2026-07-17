# Items & Modifiers Audit — full pass, no sampling

**Date:** 2026-07-17 · **Subjects:** `data/items.json` (28 rows) + `data/modifiers.json` (27 rows) —
every row audited. **Yardsticks:** `docs/rules-addendum.md` R3/R8/R10/R12/R14/R16,
`simulation/action_resolver.gd` + `simulation/resistance.gd` (what the engine actually consumes),
`scripts/validate_seeds.py` (what is actually checked), `docs/gdd/gdd.md` §Inventory & Equipment,
`docs/GPT_Master_Compendium.md` §3.2, `docs/setting-rebrand-options.md` + `docs/cosmic-casino-canon.md`
(casino voice).

**Honesty line:** this is a data/docs audit. `python3 scripts/validate_seeds.py` was run live: **OK, 171
rows** — but note it validates items only for `item_type`/`rpm`/`magazine` typing and validates
modifiers.json for *nothing beyond JSON parse* (`validate_seeds.py:88`). No Godot binary was run; no sim
test claims are made here.

---

## 0. The engine contract (what a row must carry to be playable)

`action_resolver.gd` consumes from an item dict: `damage_type` + `damage_amount` (typed condition
damage, R4), `rpm` + `magazine`/`magazine_loaded` (R8), `stat_requirements` as a dict over
`physique/reflexes/mind/charm/hands` (R10 gate), `base_moment_cost` (R3 costs), `attack_range` or
`range_pattern` (numeric reach; fallback 1), `dropped`. `resistance.gd` reads resistances **only from
the combatant** (`{"Physical": n, "Affliction": n, "Psychic": n}`) — there is **no item-resistance
model at all**. There is **zero modifier/affix support anywhere in `simulation/`** (verified: no match
for modifier/affix/prefix/suffix).

Against that contract, the seeded 28 items carry: freeform `requirements` strings (never
`stat_requirements`), freeform `range` strings ("Adjacent", "Physique", "Adj / 2 * Physique", "0", ""),
freeform `resistance` strings ("Crush 1", "Bleed 1"), **no** `base_moment_cost`, **no** `rpm`/`magazine`
on any row (matches R11 note 11: content pass open), and a dead `type` column (populated once, on
`bandage`). The set is display-shaped (ported from the char-sheet app, where a human GM parsed the
text), not sim-shaped.

**No CUT verdicts were issued:** all 28 items are live-campaign canon (CLAUDE.md: the char-sheet app's
28 items are canonical content); cutting rows here would desync the port from live play. Robot-gear
orphan check (R16): **clean** — no robot-only item or modifier exists (grep-verified).

---

## 1. Items — verdict table (28/28)

| key | verdict | issues | proposed action |
|---|---|---|---|
| `bandage` | FIX | `requirements: "Have Bleed or Crush."` freeform; `effect` ("Delay bleeding for 1 clock") and `special_effects` overlap/extend each other; only row using the `type` column ("Healing") | Structure requirement as `{"has_condition": ["bleeding","crushed"]}`; merge effect text into one statement ("Delay Bleeding 1 Clock; prevents Infected/Poison entry; stabilizes Crushed T1"); decide the `type` column's fate file-wide |
| `stun_net` | FIX | Empty description; the Moment cost ("2 Moment Cost") is trapped in `requirements`; `range: "Physique"` needs formula grammar; effect lives in `special_effects`; "disable target Leg" needs a part-disable vocabulary | Add `base_moment_cost: 2`, clear requirements; range → `{"thrown": "physique"}`; write copy ("House crowd-control surplus. The net remembers its job.") |
| `pointed_clown_hat` | KEEP-AS-IS | "entertain the mindless mass" reads fine under the casino gallery; crude tier ✓ (0/0 slots); no effect is legitimate for cosmetics | None now; candidate for a Charm/hype hook when KAN-7 lands |
| `ruffled_clown_collar` | FIX | Trailing `\n` in description; otherwise identical situation to the hat | Strip whitespace |
| `fedora_hat` | FIX | `damage_type_raw: "Psy"` is char-sheet-app DMG_TYPES drift — the exact vocabulary CLAUDE.md forbids importing; `resistance: "Crush 1"` freeform with no engine model; description hardwires campaign provenance (acceptable flavor for a memento) | Null out `damage_type_raw`; migrate resistance to a structured per-part item-resistance field once one exists (see systemic pattern 1) |
| `scalpel_used` | FIX | `requirements: "1 Physique, 1 Reflexes"` freeform; `attack_types: []` though it's a weapon; `range: ""` (engine defaults to 1 — accidentally correct) | `stat_requirements: {"physique":1,"reflexes":1}`; `attack_types: ["Single Target"]`; `attack_range: 1` |
| `generic_outfit_coupon` | RE-VOICE | "Coupon" is retail-corporate language; grant-vehicle from the live app's admin flow | Rename **"Wardrobe Comp"** — *"A comp slip for the house wardrobe. Dress for the table you want; the odds board notices."* Redemption flow = Lounge |
| `silver_modifier_coupon` | RE-VOICE | "Coupon" + tier-vocabulary collision: name says **Silver** (a Boss-Token tier: Bronze/Silver/Gold…), effect says **Lesser** (the modifier tier) | Rename **"Altar Marker — Lesser"** — *"Redeemable at the Enchantment Altar for one Lesser engraving on an item you hold. The house claims no responsibility for extraction accidents."* |
| `beachy_the_beach_ball` | KEEP-AS-IS | Campaign memorabilia (Filipe's soul-object); `misc` is right; copy is the joke | Consider an `exclusive_to` field when the skills schema gets one (R12 notes the lock field) |
| `middle_brother_s_doll` | KEEP-AS-IS | Clean `key_item`; story artifact; copy good | None |
| `superhero_outfit` | FIX | `requirements: "Humanoid body"` has no data binding (races.json defines only human/animal, no body-plan flags); copy itself is fine — pop-culture skin is diegetic under the VIP-table premise | Requirement → structured race/part predicate (`{"body_plan":"humanoid"}`) once the grammar exists |
| `metal_gauntlets` | FIX | `requirements: "2 Hands. Physique 3."` freeform; semantics contradiction: `damage_amount: 2` **and** "Damage is added to unarmed attacks" — is it a 2-crush weapon or a +2 unarmed augment? Engine has no natural-attack-augment model | `stat_requirements: {"physique":3,"hands":2}`, `attack_range: 1`; rule the augment semantics (recommend: weapon row, 2 crushed, drop the augment line) |
| `big_brother_roach_s_suit` | FIX | `resistance: "Bleed 1"` freeform, no engine model; "Didnt" typo | Structured item resistance (pattern 1); fix typo. Copy (4 sleeves, the stains) is keepable flavor |
| `arrow` | REWORK | Ammo with no launcher anywhere in the pool ("Shooting mechanism." binds to nothing — no bow/crossbow seeded, though the campaign's Mario carries 25 arrows + a crossbow); engine's R8 model is magazine-based with no ammo-item linkage; `qty: 1` with no stacking model; carries its own damage (2 bleeding) plus a melee special | Decide the ammo model: (a) arrows become the magazine-refill resource for bow-class weapons, or (b) launcher carries damage and arrow becomes count-only. Add a stack/qty convention. Seed a launcher (GAPS #9) |
| `bag_of_trail_mix` | FIX | A consumable with **zero effect** — nothing happens when eaten; the ™ joke is fine diegetically (human-brand skin) | Give it one: out-of-combat, recover 1 Exhausted tier (pairs with R4 Exhausted recovery); optional casino garnish ("concession-stand grade") |
| `tome_of_submission` | FIX | Grants skill "Submission" which **does not exist in `data/skills.json`** (grep-verified) — dangling grant; `requirements: "Animal Planet, have a pet."` — "Animal Planet" is a real tag (`tags.json:122`; tags→epithet migration pending) but "have a pet" binds to no system | Seed the Submission skill (or retarget to an existing animal skill); requirement → structured `{"tag":"animal_planet","companion":true}` once companions exist; hold until then |
| `medical_suture_kit` | FIX | `requirements: "Reflexes 4, Mind 4, 2 Hands."` freeform; effect ambiguity: "Remove 1 Bleed effect" — one Bleeding *tier* or the whole condition? (R4 is tiered) | `stat_requirements: {"reflexes":4,"mind":4,"hands":2}`; respecify: "per Moment spent, reduce Bleeding one tier on the treated part" |
| `sewing_kit` | FIX | `special_effects` is a contents inventory, not an effect; `requirements: "Reflexes 4"` freeform; quality tier on a tool is fine | Move contents to `notes`; `stat_requirements: {"reflexes":4}` |
| `garden_gloves` | FIX | `requirements: "Humanoid hands"` unbindable (same as superhero_outfit); otherwise a clean cosmetic with good copy | Structured predicate when grammar lands; nothing else |
| `wood_scraps` | KEEP-AS-IS | Crafting material for the planned Forging Station (compendium Lounge module); inert until KAN-7 — harmless | None |
| `fabric_scraps` | FIX | Typo: "Fiber **Scarps**" | "Fiber Scraps" |
| `metal_claw_coverings` | FIX | **Engine-broken damage row:** `damage_type: null` while `damage_raw: "2 Bleed"` — resolver reads `damage_type`, so this weapon deals 2 *typeless* damage and applies no condition; "Have claws" binds to nothing (no claw part concept — animal part layouts are authored at creation); same augment contradiction as gauntlets ("+1 damage to claw attacks" vs `damage_amount: 2`) | Set `damage_type: "bleeding"`, null `damage_raw`; requirement → part-tag predicate; rule augment semantics |
| `kunai` | FIX | **Dev-chat leakage shipped in player-facing copy:** "Idk ben edit it\nI swear its not a weeb thing…"; `range: "Adj / 2 * Physique"` is the poster child for the missing formula grammar; quality tier ✓ (1/1 slots) | Rewrite: *"A stubby round-gripped blade, balanced for the throw. The gallery loves a clean arc."* Range → `{"melee":1,"thrown":"2*physique"}` |
| `short_sword` | KEEP-AS-IS | Cleanest weapon row in the file: typed damage, tier, meme copy that survives any frame; `range: "Adjacent"` rides the engine's default reach 1 correctly | Only the systemic range-grammar migration touches it |
| `musketeer_hat` | FIX | Empty description; `tier: null` on equipment (R12 slots/tier undefined for it) | Assign tier (crude) + one line of copy |
| `soft_boots` | FIX | Empty description; `tier: null`; a "soft boots" item with no effect begs the missing mobility hook | Tier + copy; candidate effect: silent movement (noise/absorption economy, GDD Fields) |
| `blue_cape` | FIX | Empty description; `tier: null` | Tier + copy |
| `basic_weapon_coupon` | RE-VOICE | "Coupon" retail language; this is the compendium's Fantasy Item Coupon (self-designed Basic weapon, distribution `[OPEN]`) | Rename **"Forge Marker — Basic"** — *"Stakes you one commission at the Forging Station, up to Basic make. The house always lets you arm yourself; it's better television."* |

**Items: KEEP-AS-IS 5 · FIX 19 · REWORK 1 · RE-VOICE 3 · CUT 0.**

---

## 2. Modifiers — verdict table (27/27)

R12 recap: tier ladder Lesser → Normal → Higher → Legendary; weapon tier gates access (Basic → Lesser
only … Exceptional → Legendary); slots Crude 0/0 → Exceptional 2/2.

| key | verdict | issues | proposed action |
|---|---|---|---|
| `serrated` | KEEP-AS-IS | Working-list canon (compendium §3.2); numbers are R14 placeholders like everything | Structured effect when the effects schema lands |
| `weighted` | KEEP-AS-IS | "Applicable to: Any" is loose (+1 Crush on a hat?) but matches the app; working-list canon | Tighten applicability in the taxonomy pass |
| `barbed` | KEEP-AS-IS | Seeded effect (retaliation when the item is hit) **diverges from compendium** ("removal deals +1 Bleed"); applicability "Armors, Shields" is an **orphan class — zero armor/shield items exist** | Keep the retaliation version (better design); seed a shield/armor (GAPS #7–8); log the compendium delta |
| `spiked` | FIX | Effect ambiguous: "Split original damage between crush and bleed and add 1 damage to 1 of them" — who chooses, what rounding? Diverges from compendium's simpler "secondary 1 Bleed on Crush hits"; gate "Crush Weapons of 2+ damage" is freeform | Adopt the compendium's simpler version, or fully specify the split (attacker chooses, round up on crush) |
| `chilling` | KEEP-AS-IS | Clean: Tier 1 Chill on hit; vocabulary ✓ (`chilled`) | None |
| `poisoned` | FIX | R10 poisons are **typed** (neuro/hemo/myo/pneumo/cyto) and the engine's `apply()` takes `poison_type` — "Tier 1 Poison on hit" is untyped; overlaps `venomous` | Add a default type (recommend hemotoxin) or a type field per instance |
| `grip_wrap` | KEEP-AS-IS | The adopted "Wrapped" candidate; "undroppable" binds cleanly to the engine's `dropped` flag + Forced-Tool drop consequences | Differentiate from `sure_grip` in one sentence of rules text |
| `sharpened` | FIX | "Reduces moment use cost of weapon attack by 1, up to a minimum of 1" — every seeded weapon already costs 1 (`base_moment_cost` default), so the effect is **dead on all current content**; compendium flags the Balanced+Sharpened-II cost-elimination combo | Respecify to target 2+-cost attack actions; add the incompatibility note |
| `extended` | KEEP-AS-IS | +1 Range — cleanly consumable once ranges are numeric | None |
| `lightweight` | FIX | "Requires three fourths of the Physique to use" — three fourths of *what* (the item's listed Physique requirement, presumably); rounding unspecified | Respecify: "Physique requirements become ceil(0.75 × listed)" |
| `steady` | FIX | Trigger "took a hit last moment" — the engine tracks no per-tick hit history; window (tick vs Moment vs Clock) undefined; no floor on the reduction | Define: "if you took damage since your last action, your next scheduled action costs −1 Moment (min 1)"; needs a `last_hit_tick` field |
| `sure_grip` | FIX | "Stolen by enemy mobs or elites" — **no theft mechanic exists** in engine or enemies.json; overlaps `grip_wrap` | Scope: grip_wrap = never dropped (Forced Actions), sure_grip = never disarmed/stolen by enemy effects; implement when an enemy steal ability exists |
| `serrated_ii` | KEEP-AS-IS | Linear +2 Bleed upgrade; R14 placeholder | None |
| `weighted_ii` | KEEP-AS-IS | Linear +2 Crush | None |
| `venomous` | FIX | Weak for Normal: identical to `poisoned` (T1 Poison) with only a type attached — one tier up should buy more | Differentiate (e.g., T1 neurotoxin that advances on hit while active) or swap tiers with a typed `poisoned` |
| `burning` | KEEP-AS-IS | T1 Burn on hit; note R4: Burn T1 also applies Shock T1 — strong; watch in the R14 numbers pass | None now |
| `infectious` | FIX | "Applies Infected on open wounds" — "open wounds" undefined | Define: applies Infected T1 to parts with active Bleeding |
| `sundering` | FIX | **Vocabulary violation:** "stunning" is not in the condition set (bleeding/crushed/…/dissolution) — the pain system is Shock (R13); 1/6 chance is fine as a logged seeded roll (R2) | Respecify: "Crush hits: 1/6 (logged roll) to apply Shock T2 (Stutter)" |
| `volatile` | FIX | Compendium explicitly flags it: "synergizes strongly with Sasha — consider reserving for higher tier"; with no Higher tier seeded it sits at Normal; blast target part unspecified | Hold for the Higher list when authored, or accept at Normal deliberately; specify torso-default (matches R11.10 collateral convention) |
| `draining` | FIX | **Missing the R12-canon cap:** "Draining capped once per Clock per target" (condition-fishing abuse, compendium's own note) — seeded text is uncapped | Append: "at most once per Clock per target" |
| `sharpened_ii` | FIX | Family naming implies an upgrade of `sharpened` but the mechanic differs (skill Moment costs vs weapon attack cost) and applicability differs (Bladed → Any); compendium flags Balanced+Sharpened-II incompatibility | Rename (e.g., "Fluid") or align the family; add the incompatibility |
| `reaching` | KEEP-AS-IS | +2 Range, clean ladder above `extended` | None |
| `returning` | KEEP-AS-IS | Throwing weapons exist (kunai, stun_net); "end of action" timing is fine under R1 | None |
| `balanced` | FIX | **Tier mismatch vs canon:** R12/compendium lists Balanced as a *Lesser* candidate (Padded/Reinforced replacement); seeded at Normal; "exposing skill" needs a definition (= multi-Moment windup, R2) | Owner call on tier; define "exposing"; add Sharpened-II incompatibility |
| `reactive` | FIX | Text garbled: "First Forced action - Tool per clock is ignored" | Rewrite: "Once per Clock, ignore the first Forced Action – Tool rolled against the wielder" |
| `swift` | REWORK | Effect incoherent as written: "Can do an action as if done 1 moment sooner. The user still has to wait until the moments end" — unschedulable against the R0/R1 tick model | Direction: once per Clock, declare a scheduled action 1 tick before `next_action_tick` without changing subsequent scheduling — spec it against the tick counter, then reword |
| `penetrating` | KEEP-AS-IS | Binds perfectly to the engine's flat Physical reduction; note: this is compendium's "Hollow Point" concept renamed and moved Lesser→Normal — a deliberate-looking delta worth logging | Log the delta; none otherwise |

**Modifiers: KEEP-AS-IS 12 · FIX 14 · REWORK 1 · CUT 0 · RE-VOICE 0** — no modifier has any flavor
copy to re-voice: `description` is repurposed as an applicability field ("Applicable to: X") and no
casino voice exists anywhere in the file. Flavor authoring + a structured `applies_to` field is a gap,
not a per-row re-voice.

### R12 conformance summary (modifiers)

- **Typing:** all 27 carry `modifier_type` prefix/suffix ✓ (6/6 lesser, 8/7 normal).
- **Tier ladder:** only **lesser (12)** and **normal (15)** exist. **Higher and Legendary are empty** —
  Superior (2/1) and Exceptional (2/2) weapons currently unlock slots and tier-access to *nothing*.
  Compendium §3.2 confirms only Lesser was designed by May 5; the Normal rows are live-app additions.
- **Working-list conformance:** Poisoned/Serrated/Weighted/Spiked/Chilling/Barbed ✓ seeded lesser;
  **Hollow Point** → became `penetrating` at normal (delta); **Explosive Tip is missing entirely**;
  Padded/Reinforced correctly absent; candidates Wrapped (→`grip_wrap` ✓) and Sure-grip ✓ at lesser,
  **Balanced seeded at the wrong tier** (normal vs the list's lesser).
- **Draining cap** (explicit in R12): missing from the seeded text.
- **Attachment model:** items carry **no slot/modifier fields**, and the engine has **zero modifier
  support** — R12's economy is paper-only today. Extraction friction is legitimately deferred to the
  Lounge epic (KAN-7).
- **Validation:** `validate_seeds.py` parse-checks modifiers.json and nothing else — no key uniqueness,
  no tier/type enums. Cheap win: add `check_unique` + enum checks mirroring the items block.

---

## 3. Orphans (R16 + cross-reference sweep)

- **Robot gear: none** — items and modifiers are clean under R16 (grep-verified; no robot/Corporation/
  alien/broadcast strings anywhere in either file).
- `tome_of_submission` → skill **"Submission" absent from skills.json** (dangling grant).
- `arrow` → no launcher item exists ("Shooting mechanism." binds to nothing).
- `barbed`, `steady` → applicability class "Armors, Shields" has **zero members** (armor exists only as
  two resistance-bearing equipment pieces; no shield at all).
- `returning` ("Throwing weapons"), `balanced` ("Martial Weapons"), `sharpened` ("Bladed weapons") →
  no item-class taxonomy field exists to bind applicability to; today it's prose.
- Coupons reference the live app's **admin-grant flow**; in-game they need redemption stations — the
  compendium already maps them (Forging Station, Enchantment Altar), the RE-VOICE rows adopt that.
- `requirements` referencing unbound concepts: "Humanoid body/hands", "Have claws", "have a pet",
  "Shooting mechanism", tag "Animal Planet" (tag exists, but tags→epithets migration is pending).

---

## 4. GAPS — missing basics for a party-RPG slice (proposed, ~15)

The pool today: 1 healing item (Bleeding/Crush only), 5 weapons (all melee, all 2-damage), 0 ranged,
0 shields, 0 mobility, 1 throwable-CC, 0 light sources, no counter-item for Poison/Burn/Chill/Infected/
Exhausted — despite all nine conditions being live in the engine. Proposals (casino-voiced; all
numbers R14 placeholders):

| # | name | concept | tier |
|---|---|---|---|
| 1 | Splint | Stabilize Crushed T1–T2 on a limb (the crush-twin of the bandage) | crude |
| 2 | Antitoxin | Delay/resolve Poison of a matching type; typed variants per R10 (neuro/hemo/…) — the addendum already presumes antitoxins exist (D3 closure) | basic |
| 3 | Burn Salve | Delay Burn advancement 1 Clock | basic |
| 4 | Cold Compress ("house spa grade") | Remove Chilled T1 | crude |
| 5 | Clinic Ampoule | Delay Infected 1 Clock (rare — Infected T1 blocks healing, R4) | quality |
| 6 | Pit-Boss Espresso | Remove 1 Exhausted tier in the field (rare stim) | quality |
| 7 | Buckler | 1-hand shield: +1 Physical resist to holding-arm parts — gives `barbed`/`steady` their class | basic |
| 8 | Comp Jacket | Torso armor: Physical resist 1 — armor baseline for the per-part HP game | basic |
| 9 | Hand Crossbow | Light ranged: range 5, rpm 1, magazine 1, 2 bleeding — exercises the engine's dormant R8 path and gives `arrow` a launcher | basic |
| 10 | Chunk of Debris | Thrown: range = Physique, 1 crushed — the 1-damage baseline item R14 defines | crude |
| 11 | House Curtain (smoke vial) | Thrown: 1-space sight-blocking cloud for 1 Clock — the disengage tool | basic |
| 12 | Grappling Hook | Traversal tool (2 Moments): climb/gap-cross — KAN-5 exploration | quality |
| 13 | Torch | Light + 1 burn on melee poke — dungeon basic; light is load-bearing in casino canon (shadow-people) | crude |
| 14 | Marker Loan (doping vial) | +2 one trait for 1 Clock, then Exhausted T1 — the house lends, with interest | quality |
| 15 | Whetstone | Field maintenance for the scraps/crafting family | basic |

---

## 5. Summary block

**Counts per verdict**

| verdict | items (28) | modifiers (27) |
|---|---|---|
| KEEP-AS-IS | 5 | 12 |
| FIX | 19 | 14 |
| REWORK | 1 (`arrow`) | 1 (`swift`) |
| RE-VOICE | 3 (the coupon family) | 0 (no copy exists to re-voice) |
| CUT | 0 | 0 |

**Top-5 urgent fixes**

1. **`kunai` description ships author dev-chat** ("Idk ben edit it… I swear its not a weeb thing") —
   player-facing copy; one-line rewrite proposed above.
2. **`metal_claw_coverings` is the one engine-broken combat row**: `damage_type: null` + text-only
   `damage_raw: "2 Bleed"` — deals typeless damage, applies no condition. Set `damage_type: "bleeding"`.
3. **Structure the requirements** — 10 items carry freeform `requirements` strings while the engine's
   R10 gate reads `stat_requirements` dicts; the gate is dead data for 100% of seeded items (and
   `stun_net`'s Moment cost is trapped in the requirements text — add `base_moment_cost`).
4. **`draining` is missing its R12-canon cap** ("once per Clock per target") — the seeded text is the
   exact condition-fishing exploit the compendium note exists to prevent.
5. **Vocabulary sweep:** `fedora_hat`'s `damage_type_raw: "Psy"` is the forbidden char-sheet-app
   DMG_TYPES drift (CLAUDE.md hard rule), and `sundering`'s "stunning" is not a condition — respecify
   as Shock (R13).

**Three systemic patterns**

1. **Display-shaped data, sim-shaped engine.** Every gate the resolver consumes structurally
   (`stat_requirements`, `attack_range`, `base_moment_cost`, `rpm`/`magazine`, item resistance,
   modifier effects/applicability) is seeded as freeform prose — a legacy of porting from the
   char-sheet app where a human GM was the parser. One migration (requirement/formula grammar +
   structured `applies_to`/`effects` on modifiers + item-resistance model) converts ~30 of the 33 FIX
   verdicts above; the validator should then enforce the shapes (today modifiers.json is parse-checked
   only).
2. **The R12 economy exists on paper only, and its ladders are bottom-heavy half-orphans.** No Higher/
   Legendary modifiers (Superior/Exceptional weapons buy access to nothing), no items above quality
   tier, 12 items with `tier: null` (including 3 equipment rows), no slot/attachment fields on items,
   zero engine modifier support, and applicability classes (shields, armor, martial) with no members.
   Progression-as-access needs both ends of the ladder to exist.
3. **The casino voice pass hasn't started, and copy hygiene is uneven.** The coupon family still
   speaks retail-corporate; four items have empty descriptions (`stun_net`, `musketeer_hat`,
   `soft_boots`, `blue_cape`); one leaks dev chat (`kunai`); one has a typo ("Scarps"); and all 27
   modifiers have no flavor text at all. This is a single writing pass — house/comps/markers language
   per `setting-rebrand-options.md` — best done together with the R14 numbers pass so copy is only
   touched once.
