# C — Economy, Lounge & Equipment: v1→v2 change inventory

**Slice:** §19 (Tokens & Economy) · §20 (The Lounge) · §12 (Weapons & Equipment) · the ITEM
side of §17.6 (loot boxes / box tiers) · item-affix-material naming sweep.

**Sources read in full:** `rulebook/gpt-system-v1.0.md` §12, §16, §17.2–17.7, §19, §20 ·
`rulebook/economy-passover.md` · `rulebook/lounge-passover.md` ·
`rulebook/item-drafting-passover.md` · `-batch-a/b/c/d.md` · `-materials.md` ·
`-higher-affixes.md` · v2 canon: `docs/cosmic-casino-canon.md`,
`docs/setting-rebrand-options.md`, `docs/DIRECTION.md`, `docs/gdd/gdd.md`,
`docs/narrative/narrative-design.md`, `docs/design/patron-gods.md`,
`docs/design/mythology-research-spec.md`, `docs/rules-addendum.md`,
`docs/audits/items-audit.md`, `docs/audits/campaign-residuals-audit.md` ·
live app: `client/src/constants.js`, `client/src/components/admin/BoxBuilder.jsx`,
`server/seeds/*.js`.

**Path shorthand:** `BOOK:n` = `/home/user/Galactic-Prime-Time/rulebook/gpt-system-v1.0.md`
line n. `GAME/` = `/home/user/Galactic-Prime-Time-Game/`. `APP/` =
`/home/user/Galactic-Prime-Time/`.

**Headline:** this slice is far cheaper to convert than it looks. §12 (the whole weapons
chapter, 142 lines) contains **zero** Corporation/alien language — grep-verified. The
entire slice carries only **8 prose instances** of Corporation-coded voice, all in §16/§19/§20.
The materials system (§12.7) was already authored *from v2's own mythology research library*.
The real work is three things: one **NEW** subsystem (the mortal→god pipeline, which the
TTRPG book does not have at all), one **vocabulary collision** (Legendary/Mythic/Godly now
mean literal things), and one **owner confirmation** (the Advanced Fabricator's future-tech
ladder).

---

## Summary table

| ID | Element | §/file:line | Verdict | Effort | One-line change |
|---|---|---|---|---|---|
| C-01 | Upgrade Tokens — "the money" | §19.1 · BOOK:1126-1130 | RESKIN | S | UT become **house chips**; "where the Corporation recoups" → "where the house recoups" |
| C-02 | Boss payout ladder (Neighbourhood→Stage) | §19.1 · BOOK:1134-1143 | KEEP | S | Untouched; optionally re-voiced as pot size by table rank |
| C-03 | Patron Tokens (skill-cap currency) | §17.2 · BOOK:890-893 | RESKIN | S | Patrons are already **donator gods** in v2; the word survives, the issuer changes |
| C-04 | 25 UT → 1 Patron Token exchange | §19.2 · BOOK:1145-1148 | KEEP | S | Mechanically fine; **flag: the digital game CUT it** (R10) — TTRPG/game fork |
| C-05 | Narrative Tokens income ("corporate rewards") | §17.7 · BOOK:954-955 | RESKIN | S | "corporate rewards" → house comps / a tip from the box |
| C-06 | The general store ("Sup, nerds!") | §19.3 · BOOK:1152-1155 | RESKIN | S | Tutorial concession stand; the pop-culture NPC voice survives diegetically |
| C-07 | Coupons (Corporation vouchers) | §19.3 · BOOK:1156-1158 | RESKIN | S | → **markers** (a casino marker is literally house credit); 3 live items already re-voiced in the audit |
| C-08 | Bronze box shops (standing vendors) | §19.3 · BOOK:1159-1163 | RESKIN | S | "The Corporation understands surprise mechanics" → the house does; joke gets *better* |
| C-09 | Found boxes — the booster-pack rule | §19.3 · BOOK:1164-1170 | KEEP | S | Sealed box with a price tag on a shelf = a casino side-bet; no change |
| C-10 | Selling / the barter bench | §19.3 · BOOK:1171-1172 · §20.3 | RESKIN | S | The Goldsmith's bench **is the cage** (where chips cash out) — free upgrade |
| C-11 | Med Bay invoice `Floor × 2^claims` | §16 · BOOK:852-863 | RESKIN | S | "costs the Corporation more than stabilizing" → the house protects an asset it's still taking action on |
| C-12 | **The divinity economy / mortal→god pipeline** | canon §3 · `GAME/docs/cosmic-casino-canon.md:38-46` | **NEW** | **L** | The TTRPG has **no** Ascension/retirement mechanic (grep-verified: zero "Ascen" in BOOK) — this is a genuinely new subsystem |
| C-13 | Currency-stack layering decision | §19.1 + canon §3 | MECHANICAL | M | **Layer, don't replace**: relabel rungs 1–2, add divinity as a third, non-spendable, terminal rung |
| C-14 | New SOURCE: a cut of the wagers ("the handle") | §19.1 income list · BOOK:1126-1128 | NEW | M | No current income line is "a cut of what's bet on you" — canon requires one |
| C-15 | New SINK: the buy-in (retire → gambler) | canon §3 · `cosmic-casino-canon.md:42-43` | NEW | M | The terminal sink the book lacks; consumes the character, not the tokens |
| C-16 | Tipping the dealer = Directives/Goals | canon §2 · `cosmic-casino-canon.md:32-34` | RESKIN | S | **Already decided** (`setting-rebrand-options.md:135`) — no §19 change needed |
| C-17 | The Lounge → **the comp suite** | §20 · BOOK:1176-1178 | RESKIN | S | **Already decided** (`setting-rebrand-options.md:36`; `campaign-residuals-audit.md:359`) |
| C-18 | The Golden Cage design pillar | §20 · BOOK:1180-1186 | RESKIN | S | Gets *stronger*: comping the room to keep you at the table is real casino practice |
| C-19 | House rules (24/7 surveillance, overstay ejection) | §20 · BOOK:1188-1191 | RESKIN | S | "surveillance = the house watching its assets" — already canon-voiced |
| C-20 | Downtime economy (2 actions, +1 for 3 UT) | §20.1 · BOOK:1193-1198 | KEEP | S | No change |
| C-21 | Module level ladder (L1 / L2=5 UT / L3=15 UT) | §20.2 · BOOK:1200-1204 | KEEP | S | Numbers stand; one voice line |
| C-22 | Farm module | §20.3 · BOOK:1215 | RESKIN | M | Weakest fit — a farm inside a comped suite needs a new justification (augury pen / the house's livestock) |
| C-23 | **Advanced Fabricator** (3D printer → railguns, nukes) | §20.3 · BOOK:1224 | KEEP-w/-justification | M | The single biggest tonal risk; canon *permits* it but nothing rules it — **owner confirmation wanted** |
| C-24 | Wizard's Tower (name) | §20.3 · BOOK:1226 | RESKIN | S | "Wizard" is generic-fantasy; its own L3 already says "**the sanctum**" — promote that |
| C-25 | Surgeon's Table — the race-change service | §20.3 · BOOK:1234 | RESKIN | M | Metamorphosis is myth-native (upgrade); **fork flag:** the game removed the Robot/AI race (R16), the TTRPG kept it |
| C-26 | Garage: Bike Shop / Car Shop / Armory | §20.3 · BOOK:1241-1243 | KEEP | S | Rides the firearms verdict; the "tour bus mini-Lounge" is show-coded and survives diegetically |
| C-27 | Restrooms module (dropped from BOOK, live in passover/compendium) | `lounge-passover.md:97` | RESKIN | S | "The Corporation thanks you for your compliance" → the house does |
| C-28 | §12.1 weapon classes (incl. pistols/rifles/shotguns/cannons) | §12.1 · BOOK:643-650 | KEEP | S | Firearms survive — see the firearms verdict |
| C-29 | §12.2 RPM / magazines / reload | §12.2 · BOOK:659-668 | KEEP | S | Also already built & tested in the sim (R8) — changing it is a code change |
| C-30 | §12.3 tier ladder + modifier access | §12.3 · BOOK:670-689 | KEEP | S | Frame-neutral |
| C-31 | §12.3 affix catalog (27 live + 15 Higher proposed) | `items-audit.md:88-114`; `seeds/affixes-higher.js` | KEEP | S | **Zero** alien/corporate names; 2 firearms-coded *candidates* only |
| C-32 | §12.3 Polish Kits / Creation Kits / pre-affixed drops | §12.3 · BOOK:702-717 | KEEP | S | Frame-neutral |
| C-33 | §12.4 equipment slots (anatomy rule) | §12.4 · BOOK:719-728 | KEEP | S | Frame-neutral; the "20 rings" rule is myth-friendly |
| C-34 | §12.5 uses & charges (magazines, batteries, printed devices) | §12.5 · BOOK:730-740 | KEEP | S | Rides C-23 and the firearms verdict |
| C-35 | §12.6 armor & protection / nullification | §12.6 · BOOK:742-752 | KEEP | S | Frame-neutral |
| C-36 | **§12.7 Materials — the band ladder** | §12.7 · BOOK:754-774 + `item-drafting-materials.md` | KEEP | S | **Already mythology-sourced from v2's own research library** — the slice's biggest free win |
| C-37 | Modifier tier names (Lesser…Higher/Legendary/**Mythic/Godly**) | §12.3 · BOOK:682-683 | MECHANICAL | M | See C-38: three ladders, one loaded word |
| C-38 | **Box tiers Bronze→Godly** — divine-vocabulary collision | §17.6 · BOOK:931-933; `constants.js:34` | MECHANICAL | M | Bronze/Silver/Gold *upgrade* (club tiers); **Legendary/Mythic/Godly all become literal in v2** |
| C-39 | §17.6 box contents shape + generic-vs-specific | §17.6 · BOOK:935-950 | KEEP | S | Frame-neutral; "the box knows who opened it" is *more* true in v2 |
| C-40 | Box Namer / Box Builder flavour vocabulary | `APP/client/src/components/admin/BoxBuilder.jsx:10-33` | NEW (add lane) | S | Broadcast lane survives diegetically; **a casino lane is missing entirely** |
| C-41 | `ITEM_SUBTYPES` vocabulary | `constants.js:35` | KEEP | S | Frame-neutral (Bladed/Crush/Martial/Ranged/Thrown/Armor/…/Tome/Material) |
| C-42 | Naming economy / power-fantasy ceiling ruling | `item-drafting-passover.md:164-179`, ID-0.20/21 | KEEP | S | Owner already ruled show-pun naming OUT of the standing catalog — pre-paid v2 debt |
| C-43 | Item-name sweep result across all pools | see Naming sweep | KEEP (mostly) | S | **3 confirmed renames + ~2 borderline out of ~147 templates** |

**Verdict counts:** KEEP 20 · RESKIN 13 · MECHANICAL 3 · NEW 5 · FORK 0 · CUT 0
(2 entries carry a secondary fork *flag*: C-04, C-25.)
**Effort:** S 34 · M 8 · L 1.

---

## Findings

### C-01 — Upgrade Tokens, "the money" (§19.1 · BOOK:1126-1130)
- **v1 (alien):** UT are the single currency after GC0 retired Boss Tokens. Earned from boss
  kills, bartering, crowd donations, Directives, rare boxes; spent on Med Bay bills, module
  unlocks/levels, extra downtime, threshold dice, respec, the store. The line reads "the
  Lounge is where **the Corporation** recoups" (BOOK:1130).
- **v2 (gods):** house **chips**. Already directionally decided: "Boss/Upgrade tokens →
  **House markers & chips**" (`GAME/docs/setting-rebrand-options.md:37`); "casino diegesis for
  all economy language (comps, markers, tips, the odds board)"
  (`GAME/docs/narrative/narrative-design.md:152-153`).
- **Verdict:** RESKIN **Effort:** S
- **Why:** the mechanic is untouched. One prose line changes issuer.
- **Already decided?** Yes at direction level — but only as a *pair* of words. Which is which
  is unassigned. Recommendation ⚖ (INFERRED): **chips = the spendable unit (UT); marker = a
  credit/IOU instrument** — that is the real-world meaning and it gives the Med Bay's
  escalating invoice (C-11) and the coupons (C-07) a natural home.
- **Open question for the owner:** chips vs markers — one word or two instruments?

### C-02 — Boss payout ladder (§19.1 · BOOK:1134-1143)
- **v1:** Neighbourhood 5 · District 10 · City 25 · Precinct 50 · Country 100 · Stage 250 UT.
- **v2:** unchanged. The rank names are civic-scale, not alien-coded.
- **Verdict:** KEEP **Effort:** S
- **Why:** nothing in the ladder references the Corporation. Optional flavour: the payout is
  the pot the gallery had riding on that boss.
- **Already decided?** The ladder itself is RULED (`economy-passover.md:11-19`, GC0).
- **Open question:** none.

### C-03 — Patron Tokens (§17.2 · BOOK:890-893; §19.1 · BOOK:1131)
- **v1:** the skill-cap currency; earned when a Goal converts a new Patron, and from the
  exchange. Patrons are "one-time large donors (the streamer-gets-$5,000 tier of the galaxy)"
  (BOOK:882-883).
- **v2:** **Patrons = donator gods** — RULED (`GAME/docs/DIRECTION.md:179-181`, D5;
  `GAME/docs/design/patron-gods.md:78-84`; `campaign-residuals-audit.md` §4.1 #5). The rebrand
  doc's own note: "the mechanic already has the right name"
  (`setting-rebrand-options.md:31`).
- **Verdict:** RESKIN **Effort:** S
- **Why:** the word survives verbatim; only the issuer's nature changes (a god's attention,
  not a whale's wallet). Raising a skill cap with a god's favor is *better* fiction than
  raising it with donor money.
- **Already decided?** Yes, RULED.
- **Open question:** none for §19; the boon-multiplier layer is slice-adjacent (patron-gods).

### C-04 — The 25 UT → 1 Patron Token exchange (§19.2 · BOOK:1145-1148)
- **v1:** flat 25:1, one-way, the "overflow valve." History: D-2 originally ruled a
  tier-aware exchange (`GAME/docs/ttrpg-update-plan.md:112`), amended flat by GC0
  (`economy-passover.md:18`).
- **v2:** reads perfectly — buying divine favor with house chips is a casino cage transaction.
  It is also the *only* place in v1 where the mortal ledger touches the divine one, which makes
  it the natural anchor for C-13's layering.
- **Verdict:** KEEP **Effort:** S
- **Why:** no frame conflict.
- **Already decided?** ⚠️ **Divergence, not a decision.** The **digital game CUT this exchange**
  — `GAME/docs/rules-addendum.md:235-237` (R10/D7, PROVISIONAL): "**cut from the digital game.**
  Patron Tokens come only from the audience loop… the exchange bypassed the flagship system";
  restated as dead compendium canon at `campaign-residuals-audit.md` §4.1 #6. The TTRPG kept
  and re-priced it.
- **Open question for the owner:** is the TTRPG/game split on this exchange intentional? If v2
  layers a divinity rung (C-13), the exchange becomes rung-1→rung-2 plumbing and the game's
  cut may want revisiting.

### C-05 — Narrative Tokens' income line (§17.7 · BOOK:952-955)
- **v1:** "Earned via crowd donations, **corporate rewards**, rare drops."
- **v2:** the house's comps. One word.
- **Verdict:** RESKIN **Effort:** S
- **Why:** Narrative Tokens ("interfere with the script") get *sharper* under a frame where
  the script is a god's staged trial — but the mechanic and its hard limits (BOOK:958-959) are
  frame-neutral.
- **Already decided?** No, but it rides the blanket "the house speaks where the Corporation
  spoke" ruling (`campaign-residuals-audit.md` §4.1 #1, #8).
- **Open question:** none.

### C-06 — The general store, "Sup, nerds!" (§19.3 · BOOK:1152-1155)
- **v1:** tutorial-only fixture; consumables 1–2 UT, Crude 1, Basic 3; **closes when the
  Lounge unlocks** (RULED, `economy-passover.md:37-47`, GC2).
- **v2:** a concession stand on the casino floor before you're comped into the suite. The
  vendor's meme voice ("Sup, nerds!") is exactly the pop-culture texture the VIP table is
  *made of* — `cosmic-casino-canon.md:24`.
- **Verdict:** RESKIN **Effort:** S
- **Why:** structure and prices untouched; only the vendor's employer changes.
- **Already decided?** Frame-level yes; the store is not named in any v2 doc.
- **Open question:** does the store close at the Lounge (v1 rule) or become the casino floor's
  standing kiosk? Recommend keeping the v1 close — it is the Golden Cage's first tooth.

### C-07 — Coupons (§19.3 · BOOK:1156-1158)
- **v1:** "**Corporation vouchers** that skip payment on one store purchase. They retire with
  the store." Three live templates: Generic Outfit Coupon, Silver Modifier Coupon, Basic
  Weapon Coupon.
- **v2:** a casino **marker** is literally a house credit line — the vocabulary already exists
  and is already assigned to this family. The items audit proposed exact replacements:
  Generic Outfit Coupon → **"Wardrobe Comp"** (`GAME/docs/audits/items-audit.md:54`); Silver
  Modifier Coupon → **"Altar Marker — Lesser"** (:55, also fixing a tier-vocabulary collision:
  the name says *Silver* — a box tier — while the effect is *Lesser*, a modifier tier); Basic
  Weapon Coupon → **"Forge Marker — Basic"** (:75).
- **Verdict:** RESKIN **Effort:** S
- **Why:** "coupon" is the single most retail-corporate word in the item corpus and the audit
  already did the work.
- **Already decided?** **Proposed, not ruled.** The audit is an analysis doc; the only owner
  ruling recorded on it is the `kunai` KEEP-AS-IS (items-audit.md:1-3). Also note GC6 unified
  the two weapon/modifier coupons into one Basic Weapon Creation Kit
  (`item-drafting-passover.md:245-246`) — any rename must not fork that unification.
- **Open question for the owner:** adopt the three audit renames as-is?

### C-08 — Bronze box shops (§19.3 · BOOK:1159-1163)
- **v1:** "Standing **Corporation** vendors… Bronze boxes at 5 UT, repeatedly. Pity rule: every
  5th Bronze box from the same shop guarantees a gear item. **The Corporation understands
  surprise mechanics.**"
- **v2:** the house's slot bank. The gacha joke is *strictly better* under a casino: a pity
  counter is a real slot-machine mechanic, and "the house understands surprise mechanics" is
  a sharper line than the corporate version.
- **Verdict:** RESKIN **Effort:** S
- **Why:** two words, one punchline improved.
- **Already decided?** Frame-level.
- **Open question:** none.

### C-09 — Found boxes, the booster-pack rule (§19.3 · BOOK:1164-1170)
- **v1:** sealed Silver/Gold/Legendary boxes randomly placed in the dungeon with a price tag
  (15/40/100 UT); buy on the spot or lose it forever; never restocked. Mythic/Godly never sold.
  Boxes only open at the Lounge.
- **v2:** unchanged — a one-time offer at a fixed price you can decline is a side bet, and
  "carry it home sealed, open it in the cage" is already casino-shaped language in v1.
- **Verdict:** KEEP **Effort:** S
- **Why:** zero frame dependency.
- **Already decided?** RULED as v1 mechanics (`economy-passover.md:44-47`, GC2 amended).
- **Open question:** none.

### C-10 — Selling / the Goldsmith's barter bench (§19.3 · BOOK:1171-1172; §20.3 · BOOK:1222)
- **v1:** the L2 Goldsmith bench buys surplus at about half value.
- **v2:** this **is the cage** — the casino counter where chips are exchanged for value and
  value for chips. The half-value spread is the house edge, stated out loud.
- **Verdict:** RESKIN **Effort:** S
- **Why:** a free thematic upgrade: v1's arbitrary 50% haircut acquires a diegetic reason.
- **Already decided?** No — "the cage" is not named in v2 docs; the casino-diegesis blanket
  (`narrative-design.md:152-153`) covers it. **INFERRED.**
- **Open question:** name the bench "the cage"?

### C-11 — Med Bay invoicing (§16 · BOOK:852-863; §20.3 · BOOK:1213)
- **v1:** full medical restore invoiced at `Floor × 2^(claims this floor)` UT; free rest
  trickles +1 HP/part/downtime; **bleed-out stabilization always free** because "losing the
  contestant costs **the Corporation** more than stabilizing them. Almost always."
  (RULED, `lounge-passover.md:61-87`, GL6.)
- **v2:** the house keeps an asset alive while action is still riding on it — and the
  "Almost always" gets teeth, because in v2 the house is a *bankrupt* god
  (`cosmic-casino-canon.md:60-68`) that can genuinely decide you're not worth the stake.
- **Verdict:** RESKIN **Effort:** S
- **Why:** one clause; the escalating-premium formula is untouched. Note the *game* diverges
  here too: `rules-addendum.md:245-247` (R10/B11) still says "At the Lounge, HP restores fully"
  — pre-GL6. Slice-adjacent, but worth flagging to whoever reconciles the addendum.
- **Already decided?** Frame-level only.
- **Open question:** should the free stabilization become conditional on your current odds?
  (A very v2 idea; a real cruelty escalation. Owner's call.)

### C-12 — The divinity economy / mortal→god pipeline (**NEW**)
- **v1 (alien):** **does not exist.** Grep-verified: `gpt-system-v1.0.md` contains zero
  instances of "Ascen*", "retire" (except the store retiring), or any exit-from-play mechanic.
  A contestant's only terminal states are death (§7.5) and, implicitly, the campaign ending.
- **v2 (gods):** canon and central. "The more **currency** a god wins, the higher their
  **divinity** — and the more **central their religion will be for the next 250 years**."
  "**Winners of games can take some of the currency being bet around → gain divinity → join
  the table as gamblers.** (Mortal→god pipeline is canon.)"
  (`cosmic-casino-canon.md:38-43`). The rebrand doc lists "Permadeath + **Ascension** (the
  retired become patrons)" as mechanically load-bearing and must-preserve
  (`setting-rebrand-options.md:17`), and calls the ending the pitch line:
  "survive the casino and the house makes you one of them — the verdict decides what kind"
  (:96-99). `gdd.md:108`: "Ascension = buying into the table with divinity."
- **Verdict:** **NEW** **Effort:** **L**
- **Why:** this is the one place in my slice where v2 asks for a system that v1 simply does not
  have. Everything else is voice. Ascension exists in the *video game's* lineage (the GDD PDF,
  `review-3-game-repo.md:52`) — it never made it into the TTRPG book.
- **Already decided?** The *fiction* is ruled canon. The *TTRPG mechanic* does not exist and
  has never been designed. Two sub-pieces are needed (C-14, C-15).
- **Open question for the owner:** does the live TTRPG table want an Ascension exit at all?
  It only matters if a campaign runs long enough for a character to retire — and the campaign
  frame is now explicitly ten floors ending in a Floor-10 free-for-all
  (`item-drafting-passover.md:135-142`, ID-0.29), which is an *ending*, not a retirement.
  A cheap first version: Ascension is the **Floor-10 victory condition**, not a mid-campaign
  option.

### C-13 — The currency-stack layering decision (MECHANICAL)
Full reasoning in **"The divinity-economy layering question"** below. Verdict in one line:
**layer** — relabel rung 1 (UT → chips) and rung 2 (Patron Tokens), and add divinity as a
**third rung the contestant accumulates but cannot spend on goods**. Effort M (the design
call; C-14/C-15 carry the build).

### C-14 — New SOURCE: a cut of the wagers ("the handle") (**NEW**)
- **v1:** UT income = boss kills, bartering, crowd donations, Directives, rare loot boxes
  (BOOK:1126-1128). None of these is *a share of what is being bet on you*.
- **v2:** canon specifies exactly that: winners "take some of **the currency being bet
  around**" (`cosmic-casino-canon.md:42`). There is no such quantity in the TTRPG.
- **Verdict:** NEW **Effort:** M
- **Why:** without it, C-12's pipeline has no input and the divinity rung is unearnable.
  Proposal ⚖ (**INFERRED**, not canon): a **Handle** track — the gallery's total stake on the
  party this run, driven by the Exposure numbers §17.1 already asks the GM to hold. A
  percentage settles to the party on run completion. Two free consequences: (a) **Camera Call
  becomes literally an odds mechanic** — §17.3's "gains AND losses from that target are
  doubled" (BOOK:900-906) is a doubled *bet*, and the rebrand doc already framed it as "the
  odds board turns to you — all stakes on you double"
  (`setting-rebrand-options.md:33`); (b) Exposure finally has a cash face, closing review-1's
  standing complaint that the audience economy pays only in belief.
- **Already decided?** No. The Camera-Call→odds-board mapping is decided; the Handle is my
  proposal.
- **Open question for the owner:** does the GM want to track a wager number, or should the
  handle stay abstract (a GM dial that sets payout size, never a written figure)?

### C-15 — New SINK: the buy-in (retire → gambler) (**NEW**)
- **v1:** no exit-from-play mechanic exists.
- **v2:** "join the table as gamblers" (`cosmic-casino-canon.md:43`); "winning doesn't free
  you; it **promotes you into the audience**… the verdict decides what kind of god you become"
  (`setting-rebrand-options.md:45-48`).
- **Verdict:** NEW **Effort:** M
- **Why:** the terminal sink the book lacks. Crucially it must **not** be priced in Upgrade
  Tokens — the whole point of the Golden Cage (§20's design pillar) is that UT are consumed by
  comfort. Proposal ⚖ (**INFERRED**): the buy-in consumes **the character**, plus their
  accumulated handle/divinity, and converts them into a Patron on the party's roster — which
  §17.1 already makes permanent ("once on your list, always on your list", BOOK:884-885). The
  retired character's Patron Tokens then flow to the party. That is a complete loop using two
  systems that already exist.
- **Already decided?** Fiction ruled; mechanic undesigned.
- **Open question:** see C-12's — is this a mid-campaign door or the Floor-10 ending?

### C-16 — Tipping the dealer = Directives + Goals
- **v1:** Directives are "corporate quests" issued by The Corporation (§17.5, BOOK:917-925);
  Goals are crowd challenges (§17.4).
- **v2:** "at every non-Forsaken table, gods can **tip the dealer** to help their luck —
  **boons, buffs, items**, or hindering others with **trials, monsters, curses**"
  (`cosmic-casino-canon.md:32-34`). Mapped explicitly: "Directives/Goals = tips to the dealer…
  the patron-influence mechanic now has exact house vocabulary"
  (`setting-rebrand-options.md:135-136`).
- **Verdict:** RESKIN **Effort:** S
- **Why:** included here only because Directives are a §19 *income line* (BOOK:1127). No §19
  change is needed — the reward contract ("the Corporation pays in stuff; the audience pays in
  belief", BOOK:923) survives with "the house" substituted.
- **Already decided?** Yes.
- **Open question:** none. (Directive/Goal design proper belongs to another slice.)

### C-17 — The Lounge → the comp suite (§20 · BOOK:1176-1178)
- **v1:** "The party's **corporate-controlled** modular base; unlocks after the Tutorial Boss."
- **v2:** "**The comp suite** — the house always comps your room; surveillance = the house
  watching its assets" (`setting-rebrand-options.md:36`), restated in
  `narrative-design.md:145-146` and ruled in `campaign-residuals-audit.md` §4.1 #9 ("Casino
  re-voice… Module tree itself is live"). Also RULED as a *walkable stage, not menus*, and the
  exclusive place you open loot / review contract changes / tinker
  (`gdd.md:237-243`).
- **Verdict:** RESKIN **Effort:** S
- **Why:** two words.
- **Already decided?** **Yes — settled.** Do not re-litigate.
- **Open question:** none.

### C-18 — The Golden Cage design pillar (§20 · BOOK:1180-1186)
- **v1:** "The Lounge is essential AND a crutch. The **Corporation** builds it so good that
  contestants delay their own descent — every comfort is content, every upgrade is a reason to
  stay one more cycle… the **Corporation profits either way**." (Owner's THINK-BIGGER
  directive, `lounge-passover.md:5-9`.)
- **v2:** this is not a re-skin, it is a **thesis upgrade**. Comping a high-roller's room to
  keep them on the floor is the actual mechanism casinos use; v1 invented it and v2 supplies
  the real-world referent. "You're either content in the dungeon or content in the house"
  survives verbatim.
- **Verdict:** RESKIN **Effort:** S
- **Why:** the strongest single argument in this slice for the frame swap.
- **Already decided?** Frame-level; the pillar text itself is untouched v1 canon.
- **Open question:** none.

### C-19 — House rules (§20 · BOOK:1188-1191)
- **v1:** no entry during combat; all boxes open inside, all at once; a guide is available;
  overstaying past all pretense of content → ejection + 24h re-entry lock; **fully monitored
  24/7 — higher levels mean more surveillance.**
- **v2:** the phrase "**House rules**" is already in the book (BOOK:1188) and needs no change
  at all. Overstay-ejection is comp policy (comped rooms carry expected play). Escalating
  surveillance with module level = the house watching a bigger asset harder — already the
  ruled framing (`setting-rebrand-options.md:36`).
- **Verdict:** RESKIN **Effort:** S
- **Why:** near-zero; the section is accidentally already v2.
- **Already decided?** Yes, at the surveillance clause.
- **Open question:** none.

### C-20 — Downtime economy (§20.1 · BOOK:1193-1198)
- **v1:** 2 downtime actions per contestant between deployments; free sleeping/eating/rest;
  GM may grant a third; an extra costs 3 UT once per downtime (RULED, `lounge-passover.md:24-31`).
- **v2:** unchanged.
- **Verdict:** KEEP **Effort:** S
- **Why:** no frame dependency. "You have until the next episode" (the passover's diegetic
  justification) still works — the VIP table's skin is a show.
- **Open question:** none.

### C-21 — Module level ladder (§20.2 · BOOK:1200-1204)
- **v1:** L1 = unlock price · L2 = 5 UT · L3 = 15 UT. "The Lounge is where Upgrade Tokens go to
  die — happily."
- **v2:** unchanged. Optional line: the house sells you a better room.
- **Verdict:** KEEP **Effort:** S
- **Why:** structural, frame-neutral.
- **Open question:** none.

### C-22 — The Farm (§20.3 · BOOK:1215)
- **v1:** 10 UT. L1 ingredient supply + a companion animal; L2 mounts and livestock (bandage/
  antitoxin crafting stock); L3 the menagerie — battle-beast, exotic boss-livestock, and the
  **petting-zoo segment (standing Patron draw)**.
- **v2:** the weakest fit in the module tree. A working farm is not a comp-suite amenity; it is
  the one module whose v1 justification was purely "the Corporation supplies its show."
  Re-justification options (**INFERRED**, none canon): (a) the house's **livestock pen** — the
  casino's kitchen supply, which makes the Kitchen dependency literal; (b) an **augury pen** —
  sacrificial animals and haruspicy are mythology-native and would make the "Patron draw"
  clause diegetic (the gods watch the entrails, not the petting zoo); (c) leave it a petting
  zoo — gods who binge-watched human pop culture would absolutely stage one.
- **Verdict:** RESKIN (needs a new justification) **Effort:** M
- **Why:** the mechanics (crafting stock, mounts, companion) all survive; only the *reason*
  the house built it needs writing.
- **Already decided?** No. `campaign-residuals-audit.md:380` says the whole module tree "needs
  only casino re-voice" — that is true for every module except this one and C-23.
- **Open question for the owner:** which farm justification? (b) is the most v2 and costs
  nothing mechanically.

### C-23 — The Advanced Fabricator (§20.3 · BOOK:1224) — **the load-bearing one**
- **v1:** 10 UT. "**The giant 3D printer** — L1 prints ammo only (magazines, standard rounds;
  refills free)"; L2 gadget printing (element-tipped special ammo, grapnels, flash/smoke,
  one-shot drones); L3 "**The impossible catalog: futuristic weaponry** — plasma cutters,
  railguns, energy shields… and yes, **nuclear options** (a micro-nuke is a once-per-campaign
  purchase the GM prices in tokens AND consequences; the crowd goes insane)." Owner's own
  THINK-BIGGER amp (`lounge-passover.md:8-9`).
- **v2:** this is the highest-tech object in the entire system and the sharpest tonal collision
  with "gods, myth, faith." **Canon permits it, on three independent grounds:**
  1. The VIP table is "special games designed around what the gods found interesting…
     **mostly human pop culture**" (`cosmic-casino-canon.md:24`) — a pop-culture-themed table
     stages pop-culture kit.
  2. **Sci-fi tech is explicitly in-canon at other tables:** Viola's VIP game is a
     "large Star-Wars-like fleet game" with an imperial military
     (`cosmic-casino-canon.md:113-121`).
  3. **A machine-god already exists in canon:** Viola crashes on "a mechanical planet whose
     machine race believes in **Deus Ex Machina, the director god of her game**"
     (`cosmic-casino-canon.md:115-117`). A fallen tech-god as the Fabricator's patron is a
     zero-invention answer.
- **Verdict:** KEEP-with-justification **Effort:** M
- **Why:** cutting it would delete the owner's own THINK-BIGGER amp and the L1 ammo rule that
  §12.5 and the materials system (M-7) both depend on. But "modern kit a pop-culture table
  would stage" (a shotgun) and "future tech nobody on Earth has" (a railgun, a micro-nuke) are
  different claims, and only the first is comfortably covered by ground 1.
- **Already decided?** **No.** No v2 doc mentions the Fabricator. The canon grounds above are
  ruled; the *application to this module* is my **INFERENCE**.
- **Open question for the owner:** name the Fabricator's god. Recommendation: a bankrupt
  machine-/smith-god running the print shop — which also fills a gap the materials sweep
  already flagged, "the smith-god gap: no Hephaestus/Ptah/Wayland in the corpus"
  (`item-drafting-materials.md:174-176`). One name closes two open items.

### C-24 — Wizard's Tower (§20.3 · BOOK:1226)
- **v1:** 15 UT. "The magic source: reveals magic skills (level 0)… craft Lesser modifiers";
  L3 "**The sanctum**: commission GM-authored relics."
- **v2:** "Wizard" is generic high-fantasy furniture and the only module name that reads as
  borrowed genre rather than casino or myth. Its own L3 already supplies the replacement:
  **the Sanctum** (or the Oracle). Everything under it — magic revelation, modifier crafting,
  relic commissions — is myth-native and gets *better* (relics are canon loot:
  "**God Relics**… and **Follower Relics**", `cosmic-casino-canon.md:156-159`).
- **Verdict:** RESKIN **Effort:** S
- **Why:** one word, and the book already wrote the replacement.
- **Already decided?** No. **INFERRED.**
- **Open question:** rename to the Sanctum?

### C-25 — Surgeon's Table & the race-change service (§20.3 · BOOK:1234)
- **v1:** 20 UT. Reattach severed parts · prosthetic fitting · **the canonical race-change
  service**; L2 animal-part grafts; L3 boss-part grafts.
- **v2:** **metamorphosis is the single most myth-native module in the tree** — transformation
  into and out of animal form is core mythological grammar, and the L2/L3 graft ladder becomes
  theriomorphy rather than surgery. Big upgrade, near-free.
- **Verdict:** RESKIN **Effort:** M
- **Why:** M rather than S only because of a **fork flag**: the digital game **removed the
  Robot/AI race entirely** (R16 — `campaign-residuals-audit.md` §4.1 #2: "playable = Humans +
  Animals"), while the TTRPG's live `RACES` is Human/Animal/Robot / AI (`APP/CLAUDE.md`,
  migration executed 2026-07-25). What the race-change service can *sell* therefore differs
  between the two products.
- **Already decided?** The game's removal is ruled; the TTRPG's retention is live data.
- **Open question for the owner:** does the TTRPG table follow R16 and drop Robot/AI, or do
  the two products keep different race lists? (If the TTRPG keeps Robots, C-23's machine-god
  becomes load-bearing lore for *both* the Fabricator and the Surgeon.)

### C-26 — Garage: Bike Shop / Car Shop / Armory (§20.3 · BOOK:1241-1243)
- **v1:** 30/30/75 UT. Bikes, cars, an armored vehicle; L3s: televised race segments,
  **"the tour bus: a mobile mini-Lounge,"** and the war rig with a heavy-weapon mount.
- **v2:** rides the firearms verdict exactly — modern vehicles are the same class of
  anachronism as modern firearms and are covered by the same pop-culture-table clause. The
  tour bus and the televised race segment are *broadcast*-coded, and broadcast survives
  diegetically ("Every broadcast mechanic… survives untouched",
  `setting-rebrand-options.md:117-118`). Chariots are the myth-native fallback if the owner
  ever wants one.
- **Verdict:** KEEP **Effort:** S
- **Why:** no independent decision needed; it inherits.
- **Open question:** none beyond the firearms verdict.

### C-27 — Restrooms (dropped from the book; live in the passover & compendium)
- **v1:** auto-unlock module: "**Monitored. The Corporation thanks you for your compliance.**"
  (`lounge-passover.md:97`; compendium §2.15 via `GAME/docs/GPT_Master_Compendium.md:158`.)
  Note it is **absent from the final book §20.3 table** (BOOK:1206-1244) — a quiet drop.
- **v2:** the joke is the surveillance clause, which v2 makes *canon* rather than a gag.
- **Verdict:** RESKIN **Effort:** S
- **Why:** trivial if reinstated; ignorable if the drop was deliberate.
- **Open question:** was the Restrooms drop from §20.3 intentional?

### C-28 — §12.1 weapon classes (BOOK:643-650)
- **v1:** six classes. Light Small (daggers, knives, tools) · Light Large (rapiers, whips,
  spears) · Heavy Small (maces, hammers, axes) · Heavy Large (greatswords, mauls, halberds) ·
  **Light Ranged (pistols, bows, slings)** · **Heavy Ranged (rifles, shotguns, cannons)**.
  Requirements, hands, range, Moment cost, damage.
- **v2:** four of six classes are already pure myth-compatible. The two ranged classes each
  list a firearm *and* a pre-industrial weapon in the same row — the table is already
  frame-agnostic by construction.
- **Verdict:** KEEP **Effort:** S
- **Why:** see the firearms verdict. Note the classes are defined by *shape and requirement*,
  not by technology: "Heavy Ranged, 4 Reflexes, 2 hands, steady ground, ammo" describes a
  ballista as readily as a shotgun.
- **Already decided?** "This is a FRAME swap, not a redesign… all combat rules [stay
  untouched]" (`setting-rebrand-options.md:103-104`).
- **Open question:** none.

### C-29 — §12.2 RPM, magazines, reload (BOOK:659-668)
- **v1:** firing is a 1-Moment action delivering up to RPM rounds; magazine defaults light 6 /
  heavy 2; reload 2 Moments, both hands.
- **v2:** the most explicitly modern machinery in the book. It survives on the firearms
  verdict — and on a second, harder ground: **it is already implemented and tested in the
  simulation** (`GAME/docs/rules-addendum.md:203-209`, R8; acceptance test at :902-903).
  Removing firearms is not a lore edit, it is an engine change plus a content re-stat.
- **Verdict:** KEEP **Effort:** S
- **Why:** as above. §12.7/M-7 already reconciles it with myth: the ammo carries the material
  band, so a mythic round fired from a modern platform is *the designed case*, not a workaround
  (`item-drafting-materials.md:136-152`).
- **Open question:** none.

### C-30 — §12.3 tier ladder & modifier access (BOOK:670-689)
- **v1:** Crude 0/0 → Basic 1/0 (Lesser) → Quality 1/1 (≤Normal) → Superior 2/1 (≤Higher) →
  Exceptional 2/2 (≤Legendary). "Progression = **access**, not just slots." Tiers apply to ALL
  items.
- **v2:** untouched — craftsmanship quality is frame-neutral. (The *upper modifier tier names*
  are a separate problem: C-37.)
- **Verdict:** KEEP **Effort:** S
- **Open question:** none.

### C-31 — §12.3 the affix catalog (BOOK:691-704; live catalog is source of truth)
- **v1:** 27 live affixes (12 Lesser, 15 Normal — `items-audit.md:123-126`), plus 15 proposed
  Higher (`seeds/affixes-higher.js`; `item-drafting-higher-affixes.md`). Book §12.3's working
  list is explicitly historical; **the live catalog is truth** (ID-0.1/ID-0.14).
- **v2:** the audit's own sweep is decisive: "**no robot/Corporation/alien/broadcast strings
  anywhere in either file**" (`items-audit.md:142`, grep-verified). Names are mechanical
  (Serrated, Weighted, Chilling, Penetrating, Rending, Thornguard, Warded, Anchored…).
- **Verdict:** KEEP **Effort:** S
- **Why:** **zero renames required.** Two firearms-coded names exist only as *book-side
  candidates* not in the live catalog — **Hollow Point** and **Explosive Tip** (BOOK:693-694),
  which ID-0.14 demotes to candidate ADDs (`item-drafting-passover.md:51-52`). If the firearms
  verdict ever flips, those two are the only affix names affected.
- **Open question:** none.

### C-32 — §12.3 Polish Kits, Creation Kits, pre-affixed drops (BOOK:702-717)
- **v1:** Exceptional is polish-only (Crude/Normal/Superior kits, d6 odds; Superior kit never
  sold); Creation Kits let a player assemble base + modifiers within tier access; Quality+
  drops arrive pre-affixed ~1-in-3.
- **v2:** frame-neutral crafting. One free upgrade: "the only kit that completes →Exceptional,
  and it is **never sold**" reads as a house-restricted comp.
- **Verdict:** KEEP **Effort:** S
- **Open question:** none.

### C-33 — §12.4 equipment slots (BOOK:719-728)
- **v1:** one item per slot; anatomy-derived (1 head, 1 torso, 2 hands, 2 legs, accessories);
  **ring-class items fit fingers and toes, up to 20**; non-standard bodies derive slots from
  their parts ("a sea lion has flippers, not hands"); "think logically about the anatomy —
  that IS the rule."
- **v2:** untouched, and the 20-ring rule is quietly perfect for a divinity economy — rings
  are the canonical form of a god's favor made wearable, and Batch C's **Patron's Favor Ring**
  already uses exactly that (`item-drafting-batch-c.md:63`).
- **Verdict:** KEEP **Effort:** S
- **Open question:** none. (The sea-lion example ties to the animal race — see C-25's fork.)

### C-34 — §12.5 uses & charges (BOOK:730-740)
- **v1:** consumables die at 0 uses; charged gear (magazines, batteries, printed devices)
  refills at the Lounge — ammo free at the Fabricator, other charges 1 UT; nothing refills in
  the field except explicit items; **ammo carries a material** (§12.7).
- **v2:** rides C-23 and the firearms verdict. The "banded ammo has a running cost" rule is the
  economic spine of ranged play (M-7) and is *mythology-native by construction* — you burn
  Beastbone, Sky-Iron, Jade per shot.
- **Verdict:** KEEP **Effort:** S
- **Open question:** none independent.

### C-35 — §12.6 armor & protection (BOOK:742-752)
- **v1:** armor is flat resistance to the parts it covers; resists stack across worn pieces;
  flat resists are Bleed/Crush/Burn only; Superior may carry T1 nullification of its theme
  type, Exceptional T2 or full-type; shields occupy a hand.
- **v2:** untouched, and thematically ideal — "nullification of a type" is exactly how myth
  describes warded/invulnerable gear (and Batch C already ships **Cindershell Plate**,
  **Wyrmhide Cloak**, **Stoneframe Greaves** on that rule).
- **Verdict:** KEEP **Effort:** S
- **Open question:** none.

### C-36 — §12.7 Materials — the band ladder (BOOK:754-774; `item-drafting-materials.md`)
- **v1:** tier is craftsmanship, **material is scale**; each floor introduces a band that
  doubles damage/resist (F1 ×2 … F9 ×512, F10 adds none); part count = material capacity; the
  striking part sets the band; ranged/tech band by ammo or emitter core; carve, gather, reforge.
- **v2:** **this section is already v2.** The catalog was authored by scavenging the *game
  repo's own mythology research library*: "Scavenged from stories per ID-0.27d (primary source:
  the game repo's `docs/research/mythology/` library, **155 grounded entries swept across 14
  traditions**)" (`item-drafting-materials.md:5-8`; ruled at ID-0.27d,
  `item-drafting-passover.md:124-128`). Every named material is a myth object: Oak Heartwood
  (the oaks of the Fourth Branch), **Mistletoe** ("the one thing unsworn" — Norse), Sinew Cord
  (Gleipnir's bear sinew), Sky-Iron (Egyptian *bja*), Turquoise (Xiuhcoatl), Jade,
  Mirror-Bronze (Perseus's shield), Silver (Nuada's arm), Inscribed Clay (the Golem),
  Orichalcum, Cursed Gold (Andvari's hoard), Adamant (Kronos's sickle), Loong-Scale,
  **Gleipnir-Weave**, **Five-Colored Sky-Stone** (Nüwa's), Ichor.
- **Verdict:** KEEP **Effort:** S
- **Why:** **the single biggest free win in this slice.** The power axis of every item in the
  system already speaks v2's language, which also resolves the loot-tone tension flagged below
  (see "Cross-cutting"). Zero renames.
- **Already decided?** Yes — BLESSED by the owner 2026-08-04 (`item-drafting-materials.md:3-4`,
  ID-0.30).
- **Open question:** none. (M-9's flagged consultation notes for Māori/Hawaiian materials and
  the Kusanagi depiction restriction carry forward unchanged — they are v2 obligations already.)

### C-37 — Modifier tier names: Lesser · Normal · Higher · Legendary · **Mythic · Godly** (BOOK:682-683)
- **v1:** a six-rung ladder; only Lesser and Normal are designed, Higher is proposed, Legendary+
  deliberately undesigned (`item-drafting-higher-affixes.md:77-79`).
- **v2:** the top three rungs collide with literal v2 vocabulary — see C-38. "Godly modifier"
  in v2 means *a modification a god made*, which is a claim, not a rarity grade.
- **Verdict:** MECHANICAL **Effort:** M
- **Why:** the collision is real but the affected rungs are **all undesigned**, so a rename now
  is free. Renaming after Legendary affixes ship would not be.
- **Already decided?** No.
- **Open question:** see C-38.

### C-38 — Box tiers Bronze → Godly (§17.6 · BOOK:931-933; `APP/client/src/constants.js:34`)
- **v1:** `BOX_TIERS = ['Bronze','Silver','Gold','Legendary','Mythic','Godly']` — Bronze (bulk
  utility) · Silver (tools/armor/limited magic) · Gold (game-changers) · Legendary
  (campaign-carrying) · Mythic (meta-breaking) · **Godly** ("defying fate, almost never
  given… **the box knows who opened it**", BOOK:950). Box tier ≠ item tier (BOOK:936-937).
- **v2 — three findings:**
  1. **Bronze/Silver/Gold get a free upgrade.** Under a casino they read as **player-club
     tiers** (Bronze/Silver/Gold member) or chip denominations. Better than v1's neutral metals.
  2. **Godly stops being a superlative and becomes a provenance claim.** This is arguably an
     *improvement* — and Batch C already wrote it that way, unprompted: "**The divinity end is
     populated** — patron gods, fallen-god game-runners (Cosmic Casino canon). A Godly item is
     *somebody's* attention made solid; **author the somebody first, the stats last**"
     (`item-drafting-batch-c.md:151-154`). "The box knows who opened it" is *more* true in v2.
  3. **But "Legendary" and "Mythic" are now technical terms elsewhere in v2, and the ladder is
     used three times.** In v2: legends are the literal product of past games ("the source of
     **every legend, idea, and imagination humanity ever created**",
     `cosmic-casino-canon.md:44-46`); the epithet system runs on a **graded myth ladder** —
     "folk tale < local legend < heroic epic < **world myth**" (`patron-gods.md:139`); and
     `obscurity_tier` derives 5→common … **1→mythic** (`mythology-research-spec.md:181-184`).
     Meanwhile the same six words are the **box** ladder, and the top four are also the
     **modifier** ladder (C-37) — and neither is the **item** ladder (Crude→Exceptional). Under
     v1 that was mild jargon overload; under v2, "Mythic" means four different things across
     box tier, modifier tier, epithet grade, and entity obscurity.
- **Verdict:** MECHANICAL **Effort:** M
- **Why:** it is a naming-collision decision, not a mechanics change — but it has to be made
  *before* the epithet system ships, because that system is the one that gives "myth" a precise
  technical meaning.
- **Already decided?** No. No v2 doc addresses the box ladder's names.
- **Open questions for the owner:** (a) keep Godly and let it become literal (recommended —
  Batch C already does)? (b) rename the modifier ladder's top rungs so one word doesn't run
  three ladders? (c) does "Mythic" need to be freed for the epithet grade?

### C-39 — §17.6 box contents & generic-vs-specific boxes (BOOK:935-950)
- **v1:** boxes are generic or specific (boss-, quest-, floor-themed; a specific box carries its
  source's materials and flavor); a curated contents-shape table per tier; roll tables as
  fallback (RULED, `economy-passover.md:54-68`, GC3).
- **v2:** unchanged. "Themed to the floor that dropped them" composes cleanly with the
  arena-as-psyche rule (each arena shaped by the judge god's psyche —
  `cosmic-casino-canon.md:76-77`): a floor-themed box is a *god*-themed box for free.
- **Verdict:** KEEP **Effort:** S
- **Open question:** none.

### C-40 — Box Namer / Box Builder flavour vocabulary (`APP/client/src/components/admin/BoxBuilder.jsx:10-33`)
- **v1:** three suggestion lanes. `DEED_LEX` (10 regex→word groups: Massacre/Carnage/Overkill,
  Blitz/Speedrun/Primetime, Stagecraft/Hazard-Pay, Typecast/In-Character, Catchphrase/Quotable,
  Daredevil/High-Wire, Iron-Will/No-Sell, One-Man-Show/Solo-Act, Mercy/Clemency,
  Plot-Twist/Swerve) · `CONTENT_FLAVOR` (Arsenal, Armory, Care-Package, Supply-Drop, Triage,
  Stagehand, Toolbox, Grab-Bag, Variety-Hour, Fine-Print, MacGuffin) · **`SHOW`** (10 words,
  100% broadcast: Primetime, Encore, Fan-Favorite, Sweeps-Week, Golden-Hour, Season-Finale,
  Commercial-Break, Ratings-Spike, Cliffhanger, Cold-Open).
- **v2:** the broadcast lane **survives diegetically** — it is precisely the pop-culture skin
  the VIP table wears (`setting-rebrand-options.md:117-118`). The gap is that **no casino lane
  exists**, even though v2 has ruled "casino diegesis for all economy language (comps, markers,
  tips, the odds board)" (`narrative-design.md:152-153`).
- **Verdict:** NEW (add a lane) **Effort:** S
- **Why:** a ~10-word `HOUSE` array beside `SHOW`, and the tool speaks v2. Candidate vocabulary
  ⚖ (**INFERRED**): Jackpot · High-Roller · House-Edge · Comp · All-In · Double-Down ·
  Pit-Boss · Whale · Hot-Streak · Last-Call.
- **Already decided?** No. Purely additive; no ruling needed, but it is the one *code* change
  in this slice.
- **Open question:** should `SHOW` and `HOUSE` weight equally, or should HOUSE dominate?

### C-41 — `ITEM_SUBTYPES` (`APP/client/src/constants.js:35`)
- **v1:** Bladed · Crush · Martial · Ranged · Thrown · Armor · Shield · Trinket · Tool ·
  Consumable · Charged gear · Limited-magic · Kit · Growth · Tome · Material.
- **v2:** frame-neutral throughout. "Charged gear" is the only mildly tech-coded entry, and it
  covers gadget batteries *and* magic charges alike.
- **Verdict:** KEEP **Effort:** S
- **Open question:** none.

### C-42 — The naming-economy ruling (`item-drafting-passover.md:164-179`, ID-0.20/0.21)
- **v1:** **"Theme by FLOOR, not by Show"** (ID-0.20) — "the standing catalog stays neutral and
  generic; thematic personality lives in the floor/boss/quest pools… **Show-pun naming on
  ordinary gear is out.**" Plus ID-0.21's power-fantasy ceiling: Basic and Quality are
  commodity gear with plain names; nonsense starts at Superior; "the top of the ladder holds
  literal divinity — name inflation at the bottom devalues it."
- **v2:** this ruling is why the naming sweep below comes back almost empty. The owner
  pre-paid the v2 rebrand debt on 2026-08-04 without the rebrand being the reason — and
  ID-0.21's phrase "**the top of the ladder holds literal divinity**" is already v2's thesis.
- **Verdict:** KEEP **Effort:** S
- **Already decided?** Yes, RULED.
- **Open question:** none.

### C-43 — Sweep result across all item pools
See **"Naming sweep"** below. Verdict KEEP for the corpus; 3 confirmed renames + ~2 borderline
across ~147 templates. Effort S.

---

## The firearms question

**Verdict: firearms are PRESERVED. The gods/mythology premise tolerates them — because the
premise explicitly says the VIP table is themed on human pop culture.** §12.1's ranged classes,
§12.2's RPM/magazine/reload machinery, and every gun in the item pools stay.

**Cited chain (all four ruled canon):**

1. **The VIP table is a pop-culture theme table.** "**Special games designed around what the
   gods found interesting during the quarter-millennium — mostly human pop culture.**"
   — `GAME/docs/cosmic-casino-canon.md:24` (table taxonomy, owner-corrected 2026-07-16).
2. **The rebrand explicitly applied that to GPT.** "A reality-TV dungeon crawler is exactly
   what gods who binge-watched humanity would build. **GPT becomes a VIP table whose in-fiction
   skin is a human reality show.** Every broadcast mechanic (announcer, tags, camera calls,
   ratings) survives untouched — the DCC separation comes from *who runs it and why*… not from
   deleting the broadcast." — `GAME/docs/setting-rebrand-options.md:113-119`.
3. **The frame swap was scoped to exclude combat/kit.** "**What stays untouched:** the dungeon
   itself (floors, routes, time skips, demons, Loong, Incinedile), the Moment clock, **all
   combat rules**, per-part HP, the addendum, the engine and its 22 green tests… **This is a
   FRAME swap, not a redesign** — the engine doesn't know who's watching."
   — `setting-rebrand-options.md:103-104`.
4. **Sci-fi tech is in-canon at sibling tables.** Viola's VIP game is a "**large Star-Wars-like
   fleet game**" with an imperial military and a machine planet worshipping **Deus Ex
   Machina**, its director god — `cosmic-casino-canon.md:113-121`. Canon's own design takeaway:
   "VIP games span genres… the table structure is built to host *different games of different
   shapes inside one apocalypse*" (:129-132).
5. **Where casino canon and GPT differ on gameplay, GPT wins.** D3: "**where casino canon and
   GPT differ on *gameplay*, the dungeon/tables work closer to GPT's way**"
   — `GAME/docs/DIRECTION.md:173-175`.

**One existing item-level precedent** (an audit proposal, not an owner ruling): the
`superhero_outfit` row was kept with "copy itself is fine — **pop-culture skin is diegetic
under the VIP-table premise**" — `GAME/docs/audits/items-audit.md:58`.

**Two reinforcing practical grounds:**
- **RPM/magazine/reload is already implemented and unit-tested** in the sim
  (`GAME/docs/rules-addendum.md:203-209` R8; acceptance test :902-903). Deleting firearms is an
  engine change plus a full ranged re-stat, not a copy edit.
- **The material system already fuses guns with myth.** M-7's ruled shape is "**the AMMO is the
  blade**": rounds, shells, bolts and arrows are crafted from banded mythic materials —
  "Beastbone shot, Sky-Iron slugs, Jade-tipped bolts" — and the projectile's material sets the
  damage band, while the barrel caps it (`APP/rulebook/item-drafting-materials.md:136-152`;
  BOOK:767-770). A GPT firearm is therefore *a modern delivery platform firing mythic
  ammunition*, which is a stronger v2 object than either half alone.

**Settled canon vs my inference — stated precisely:**
- **SETTLED:** the VIP table is pop-culture-themed; the broadcast skin survives; combat rules
  and the engine are out of scope for the frame swap; sci-fi genres exist at other tables.
- **INFERRED (mine):** that the above adds up to "therefore firearms specifically stay." **No
  v2 document names guns, firearms, magazines, or RPM anywhere.** The inference is strong but
  it has never been put to the owner.
- **The one piece I would NOT bundle into it:** the Advanced Fabricator's L3 —
  plasma cutters, railguns, energy shields, micro-nukes (BOOK:1224). "Modern kit a pop-culture
  table would stage" and "future tech no human ever held" are different claims, and only the
  first is squarely covered by citation 1. See C-23 — recommend an explicit owner confirmation
  there, and there only.

**The counter-pressure worth naming:** the story bible's loot rule, still listed as standing
material, is "**loot must feel like remnants of belief**, never generic stat sticks"
(`cosmic-casino-canon.md:156-159`, God Relics / Follower Relics — Infinite Rice Sack, Ghost
Warding Torch, Rusted Legion Spear). A Basic Shotgun is a generic stat stick. **Resolution
(INFERRED):** that rule governs the *novel's* Normal/Forsaken tables, where the loot is
literally faith-residue; GPT's VIP table draws its identity from a different source — and
§12.7's material system supplies belief-residue as the *power axis* of every item, gun
included. Worth an owner sanity-check, but not a blocker.

---

## The divinity-economy layering question

**Verdict: LAYER — with the two existing rungs RE-LABELED and one genuinely NEW rung on top.
Not a replacement; not a pure re-label either.**

### Why not REPLACE
Canon is unambiguous that **divinity is what the gods win, not what contestants spend**: "The
more **currency** a god wins, the higher their **divinity**" (`cosmic-casino-canon.md:40-41`).
The two ledgers have different owners. Making contestants spend divinity on bandages and module
upgrades would invert the fiction and destroy the one number canon reserves as the *measure of
apotheosis*. It would also break the Golden Cage (§20's design pillar, BOOK:1180-1186), which
depends on the spendable currency being consumed by *comfort* — a pillar the owner personally
amped (`lounge-passover.md:5-9`).

### Why not pure RE-LABEL
A pure re-label leaves canon's central promise unmechanized. The TTRPG book has **no exit door
at all** — grep-verified: zero occurrences of "Ascen*" or any retirement mechanic in
`gpt-system-v1.0.md`. Meanwhile v2 canon states the pipeline as fact
(`cosmic-casino-canon.md:42-43`), the rebrand doc lists it as mechanically load-bearing
(`setting-rebrand-options.md:17` item 5), and the ending is the product's pitch line
(:96-99). Relabeling UT to "chips" and calling it done would ship a casino with no cash-out.

### The layering, concretely

| Rung | v1 | v2 | Owner of the ledger | Spendable on |
|---|---|---|---|---|
| 1 | **Upgrade Tokens** (§19.1) | **house chips** ⚖ | the contestant | everything in the Lounge, the store, the Med Bay — unchanged (C-01) |
| 2 | **Patron Tokens** (§17.2) | **a god's favor**, tokenized | the contestant, granted by gods | skill caps beyond 5 — unchanged (C-03) |
| 3 | — | **divinity** (**NEW**) | the *god*, mirrored on the contestant as accumulated stake | **nothing in the Lounge.** Only the buy-in (C-15) |

The rungs already touch at exactly one point: **§19.2's 25 UT → 1 Patron Token exchange**
(BOOK:1145-1148) is the mortal ledger buying into the divine one. That is the pipeline in
miniature, and it is already in the book — which is a strong argument that the layering is the
natural shape rather than an imposition. (Flag: the *digital game* cut this exchange —
`rules-addendum.md:235-237` — see C-04.)

### Does the TTRPG economy need a new sink/source for the mortal→god pipeline? **Yes — two.**

**A new SOURCE (C-14): a cut of the handle.** Canon says winners take "some of **the currency
being bet around**." §19.1's income list (BOOK:1126-1128) contains boss kills, bartering, crowd
donations, Directives and rare boxes — **none of which is a share of the wagers on you.** The
economy currently has no representation of the pot. Proposal ⚖ (INFERRED): a **Handle** track
driven off the Exposure numbers §17.1 already asks the GM to hold, with a percentage settling
to the party at run completion. Two free consequences: Camera Call becomes literally an odds
mechanic (§17.3's doubling of gains *and losses* is a doubled bet, exactly as the rebrand doc
framed it — "the odds board turns to you — all stakes on you double",
`setting-rebrand-options.md:33`), and the audience economy finally pays in something other than
belief.

**A new SINK (C-15): the buy-in.** "Join the table as gamblers." This must **not** be priced in
chips — the Golden Cage needs chips to die in the Lounge. Proposal ⚖ (INFERRED): the buy-in
consumes **the character**, converting them into a Patron on the party's roster, which §17.1
already makes permanent ("once on your list, always on your list", BOOK:884-885). Their Patron
Tokens then flow to the surviving party. That closes the loop using only systems the book
already has, and it makes the verdict ("what kind of ruler you'll be") mechanically load-bearing
— canon's literalization of exactly that (`setting-rebrand-options.md:122-126`).

**A third, already handled:** the dealer tip. Gods tipping the dealer for boons/buffs/items or
trials/monsters/curses (`cosmic-casino-canon.md:32-34`) is already mapped to Directives and
Goals (`setting-rebrand-options.md:135-136`) and needs no new §19 machinery (C-16).

**Scale note.** C-12 is the only **L**-effort item in this slice, and it may not be needed at
the table at all: the ruled campaign frame is ten floors ending in a Floor-10 free-for-all
(`item-drafting-passover.md:135-142`, ID-0.29) — an *ending*, not a retirement window. The
cheapest honest version of the pipeline is **Ascension as the Floor-10 victory condition**,
which needs C-14 only for flavour and C-15 only once.

---

## Lounge module walk

Every module in §20.3 (BOOK:1206-1244), plus the auto/dropped ones.

| Module (unlock) | v1 justification | v2 justification | Verdict |
|---|---|---|---|
| **Dormitories** (auto) | The Corporation houses its contestants; free rest trickles HP | **The comped room.** The house always comps your room — canon-voiced verbatim (`setting-rebrand-options.md:36`) | RESKIN — clean |
| **Med Bay** (auto) | Invoiced restore; free stabilization because losing you costs the Corporation more | The house keeps an asset alive while action still rides on it; "Almost always" gets teeth (the house is a *bankrupt* god) | RESKIN — clean, upgrade (C-11) |
| **Restrooms** (auto, dropped from BOOK) | "Monitored. The Corporation thanks you for your compliance." | Same joke, house-voiced; surveillance is now canon, not a gag | RESKIN — clean (C-27) |
| **Kitchen** (5 UT) | Meals fight Exhausted; feast episodes earn hype | **The comped buffet** — the most literally casino amenity in the tree. Feast episodes still earn hype (broadcast survives) | RESKIN — clean, upgrade |
| **Farm** (10 UT) | The Corporation supplies its own show: ingredients, mounts, livestock, the petting-zoo segment | ⚠ **Needs a new justification.** A working farm is not a comp-suite amenity. Best fit: an **augury pen** (sacrificial stock; entrails as the Patron draw) — myth-native, mechanically free | RESKIN — **needs justification** (C-22) |
| **Forging Station** (5 UT) | Crafts/repairs Crude→Superior; signature weapon commissions | Myth-native (smith gods). Also fills the flagged **smith-god gap** in the material corpus (`item-drafting-materials.md:174-176`) | RESKIN — clean, upgrade |
| **Goldsmith** (10 UT) | Trinkets (the 20 ring slots); barter bench; bling as a Patron draw | **The cage** — where chips cash out; the half-value spread is the house edge, stated. Bling attracting donors is *more* true when donors are gods | RESKIN — clean, upgrade (C-10) |
| **Melding Station** (10 UT) | Merge 2 same-type items; L3 chimera merges | Fusion/reforging is myth-native; "chimera merge" is already the right word | RESKIN — clean |
| **Advanced Fabricator** (10 UT) | The giant 3D printer: ammo → gadgets → plasma/railguns/**nukes** | ⚠ **The sharpest tonal risk in the tree.** Canon *permits* it (pop-culture table; Star-Wars-genre sibling table; **Deus Ex Machina** is a canon machine-god) but nothing rules it. Recommend naming a bankrupt machine-/smith-god as its patron | KEEP-w/-justification — **owner confirmation** (C-23) |
| **Enchantment Altar** (10 UT) | Extract/apply modifiers; L3 the modifier vault | **Already named "Altar."** Ritual extraction and the "master ritual" L3 are myth grammar as written | KEEP — accidentally already v2 |
| **Wizard's Tower** (15 UT) | The magic source; crafts modifiers; L3 "the sanctum," relic commissions | "Wizard" is borrowed high-fantasy — the only genre-mismatched *name* in the tree. **Its own L3 supplies the fix: the Sanctum.** Relics are canon loot (God/Follower Relics) | RESKIN — **rename candidate** (C-24) |
| **Skill Gemstone** (5 UT) | Merges/mutations + respec | Frame-neutral; "gemstone that reshapes what you know" is myth-friendly | KEEP — clean |
| **Tattoo Artist** (25 UT) | Permanent buff tattoos; threshold dice; L3 ink makes you recognizable | Ritual marking is deeply myth-native, and "the ink makes you recognizable (standing Patron draw)" is **the epithet system in miniature**. ⚠ Carry forward the same cultural-consultation care the materials sweep already flagged (M-9) | RESKIN — clean, upgrade |
| **Surgeon's Table** (20 UT) | Reattachment, prosthetics, **race change**, animal/boss grafts | **Metamorphosis** — the most myth-native module in the tree. ⚠ Fork flag: the game removed Robot/AI (R16); the TTRPG kept it | RESKIN — **fork flag** (C-25) |
| **Augmentation Hub** (20 UT) | Mechanical prosthetics, weaponized limbs, the exo-suite | Myth precedent already sits in the material catalog: **Silver — "Nuada's arm — the prosthetic metal"** (`item-drafting-materials.md:88`); Viola's machine-reforging is canon | KEEP — clean, upgrade |
| **Bike Shop** (30 UT) | Overworld travel; L3 televised race segments | Rides the firearms verdict (modern kit at a pop-culture table); race segments are broadcast, which survives | KEEP (C-26) |
| **Car Shop** (30 UT) | Party transport; L3 **the tour bus: a mobile mini-Lounge** | Same. The tour bus is show-coded and survives diegetically; "a mobile comp suite" is a fine v2 read | KEEP (C-26) |
| **Armory** (75 UT) | An armored vehicle; L3 the war rig with a heavy weapon mount | Same. Chariots are the myth-native fallback if ever wanted | KEEP (C-26) |
| **Universal Travel** (fixed) | "The door of descent. It doesn't level. It knows where you're going." | Unchanged — and *better*: a door that knows where you're going is a god's door | KEEP — accidentally already v2 |

**Walk summary:** 19 modules · **breaks: 0** · clean re-skins: 12 · already-v2: 3 ·
needs a new justification: 1 (Farm) · needs owner confirmation: 1 (Advanced Fabricator) ·
rename candidate: 1 (Wizard's Tower) · carries a product-fork flag: 1 (Surgeon's Table).

---

## Naming sweep

Scope: every item template across the live library and all authored batches, every affix in the
live catalog and the Higher proposal, every material in the catalog, the box tiers, and the Box
Builder wordlists.

### Corpus sizes
| Pool | Count | Source |
|---|---|---|
| Legacy live library | 28 | `GAME/data/items.json` (port of the char-sheet library) |
| Batch A (Lounge-unlock playables) | 41 | `APP/server/seeds/items-batch-a.js` |
| Batch B (standing catalog) | 51 seeded / 57 authored | `APP/server/seeds/items-batch-b.js` |
| Batch C (top shelf) | 21 | `APP/server/seeds/items-batch-c.js` |
| Materials F1 (seeded) | 10 | `APP/server/seeds/items-materials-f1.js` |
| **Item templates total** | **~147** | |
| Affixes (live catalog) | 27 | `items-audit.md:81-114`, R12 conformance :123-126 |
| Affixes (Higher, proposed) | 15 | `APP/server/seeds/affixes-higher.js` |
| Materials (named across all bands) | ~26 | `APP/rulebook/item-drafting-materials.md` M-0…M-5 |
| Box tiers | 6 | `APP/client/src/constants.js:34` |
| Box Namer flavour words | ~45 | `APP/client/src/components/admin/BoxBuilder.jsx:10-33` |

### Counts of alien/corporate-coded names

| Category | Needs rename | Borderline (survives diegetically) | Clean |
|---|---|---|---|
| **Item names — legacy 28** | **3** — Generic Outfit Coupon · Silver Modifier Coupon · Basic Weapon Coupon | 2 — Big Brother Roach's Suit, Superhero Outfit (show/pop-culture-coded; both explicitly kept: `items-audit.md:58,60`) | 23 |
| **Item names — Batch A (41)** | **0** | 1 — Show-Brand Buckler | 40 |
| **Item names — Batch B (57)** | **0** | 1 — Personal Camera Drone (cameras are v2 canon) | 56 |
| **Item names — Batch C (21)** | **0** | 3 — The Director's Cut, Fan Mail, The Body Double (all broadcast-coded; broadcast survives) | 18 |
| **Materials (~26)** | **0** | 0 | 26 — all mythology-sourced by construction |
| **Affixes — live 27** | **0** | 0 | 27 |
| **Affixes — Higher 15** | **0** | 0 | 15 |
| **Box tiers (6)** | **0** renames forced | **3** — Legendary, Mythic, Godly (now literal / collide with the epithet ladder; C-38) | 3 (Bronze/Silver/Gold — upgraded) |
| **Box Namer wordlists (~45)** | **0** | 18 broadcast-coded (10 in `SHOW`, 8 in `DEED_LEX`) — all survive; **a casino lane is missing** (C-40) | ~27 |

**Bottom line: 3 confirmed renames out of ~147 item templates (2.0%). Zero across 42 affixes
and ~26 materials.** All three are the coupon family, and the items audit already drafted their
replacements (`items-audit.md:54, 55, 75`).

### Item *description* copy (separate from names)
Grepping all authored seed batches for `corporation|corporate|sponsor|™|alien|broadcast|ratings`
returns **3 hits across 119 templates**:
- `items-batch-a.js:21` — Bandage: "**Corporation-brand** gauze. Smells like victory and antiseptic."
- `items-batch-a.js:80` — Duct-Tape Machete: "The tape is load-bearing. **Sponsor logo** on the grip."
- `items-batch-a.js:84` — the **Show-Brand Buckler** name itself.

Plus three prose framing lines in the batch doc (not shipped data): "Corporation-branded
necessities" (`item-drafting-batch-a.md:14`), "Sponsor-branded, proudly adequate" (:41), and
the Corporation "loyalty program" beat (:64).

The audit's own independent sweep agrees for the ported corpus: "**no robot/Corporation/alien/
broadcast strings anywhere in either file**" (`items-audit.md:142`, on items.json + modifiers.json).

### Rulebook prose in this slice
`Corporation|corporate` in §12–§20 (BOOK:636-1246): **8 instances**, all in §16/§19/§20 —
BOOK:863, 1130, 1156, 1159, 1163, 1178, 1181, 1185. **§12 (the entire 142-line weapons chapter)
contains zero.** The book also contains almost no casino vocabulary to build on: grepping
`bet|gambl|odds|casino|wager|jackpot|chip|marker` across all 1315 lines returns **2 hits**, and
one is coincidental ("odds improved by Lounge upgrades", BOOK:699). The other is a gift:
"**the camera is a gamble, not a buff**" (§17.3, BOOK:906).

### Why the sweep is this clean
Not luck. Owner ruling **ID-0.20** (2026-08-04) — "**Theme by FLOOR, not by Show**… the standing
catalog stays neutral and generic… **Show-pun naming on ordinary gear is out**"
(`item-drafting-passover.md:73-76`) — and **ID-0.21**'s power-fantasy ceiling ("the top of the
ladder holds **literal divinity**", :77-81) de-branded the entire standing catalog four months
before this research pass, for craft reasons. Batch B's status line records the pass explicitly:
"BLESSED… **after the de-theming + Skill-Tome naming passes**" (`item-drafting-batch-b.md:3-5`).

---

## Cross-cutting observations

1. **This slice is the cheapest of the conversion, and §12 is nearly free.** 8 prose lines,
   3 item renames, 3 description edits, 1 module needing a new justification, 1 needing owner
   confirmation, 1 rename candidate, 1 code-side wordlist addition — and exactly one genuinely
   new subsystem (C-12). The weapons chapter needs *nothing*.

2. **§12.7 Materials is the frame swap's best-kept secret.** The power axis of every item in the
   game was authored by mining the *game repo's own mythology research library*
   (`item-drafting-materials.md:5-8`, 155 entries / 14 traditions, ruled ID-0.27d). The TTRPG's
   scaling system is already speaking v2. This also quietly answers the bible's "loot must feel
   like remnants of belief" rule (`cosmic-casino-canon.md:157-159`): under v2, an item's power
   *is* a myth-object.

3. **Three v1 design decisions get materially better under v2, at zero cost.** (a) The Golden
   Cage pillar — comping the room to keep a player at the table is the real mechanism, not an
   invented one. (b) The Goldsmith's half-value barter bench — an arbitrary haircut becomes the
   house edge. (c) The Bronze-shop pity rule — a pity counter is a genuine slot-machine
   mechanic, and "the house understands surprise mechanics" is a better line than the corporate
   original.

4. **The economy's ONE structural hole is the pot.** v1 has an audience with billions of viewers
   whose attention drives everything and pays in nothing but belief (§17). v2 requires "the
   currency being bet around" to exist. C-14's Handle is the smallest object that closes that
   hole, and it makes Camera Call literally an odds mechanic for free.

5. **Vocabulary pressure is now the top naming risk, not branding.** The de-branding is
   effectively done (2% of templates). What is *not* done is disambiguating
   Legendary/Mythic/Godly, which under v2 run three ladders (box tier, modifier tier, epithet
   grade) plus `obscurity_tier`, while a fourth ladder (item tier: Crude→Exceptional) uses
   different words entirely. This should be settled before the epithet system ships, because
   that is what makes "myth" a technical term.

6. **Two live TTRPG/digital-game forks surfaced inside this slice** and are worth logging
   wherever product divergence is tracked: the **25 UT → 1 Patron Token exchange** (kept in the
   TTRPG, cut in the game — C-04) and the **Robot/AI race** (kept in the TTRPG, removed by R16
   in the game — C-25, which changes what the Surgeon's Table sells). Neither is caused by the
   v2 rebrand; both are pre-existing and both are now visible because v2 forces the economy and
   the Surgeon into the same conversation.

7. **The one *code* change in the slice is trivial and additive:** a `HOUSE` wordlist beside
   `SHOW` in `BoxBuilder.jsx` (C-40). Everything else is rulebook prose, three seed
   descriptions, and a rename script for three coupon templates.

8. **Scope note on which product this applies to.** The TTRPG table's re-skin is itself ruled:
   "Does the live TTRPG campaign re-skin too? **RULED 2026-07-16: RE-SKIN TO CASINO** — the live
   table adopts the casino frame alongside the game" (`setting-rebrand-options.md:155-157`).
   So the v2 rulings in the game repo bind this slice's TTRPG subject matter too.

---

## Open questions for the owner

**Blocking / design-shaped**

1. **(C-12/C-13/C-15) Does the TTRPG want an Ascension exit at all — and is it mid-campaign or
   the Floor-10 ending?** This is the only L-effort item in the slice, and the ruled ten-floor
   frame (ID-0.29) suggests the cheap answer: make Ascension the Floor-10 victory condition
   rather than a retirement door.
2. **(C-14) Does the GM track a wager number ("the handle"), or does the pot stay an abstract GM
   dial?** Canon requires "the currency being bet around" to exist; only the visibility is open.
3. **(C-23) Name the Advanced Fabricator's god.** Canon permits its future-tech ladder three
   ways over, but nothing *rules* it, and it is the sharpest tonal risk in the slice.
   Recommendation: a bankrupt machine-/smith-god — which also fills the material corpus's
   flagged smith-god gap.
4. **(C-38/C-37) Legendary / Mythic / Godly — keep, or free the words?** Godly becoming literal
   is an upgrade (Batch C already writes it that way). "Mythic" running four ladders at once is
   not. Cheapest moment to decide is now, before Legendary affixes and the epithet grades ship.

**Cheap / voice-shaped**

5. **(C-01) Chips or markers — one word or two instruments?** Recommend: chips = the spendable
   unit (UT); markers = house credit (the Med Bay invoice and the coupons).
6. **(C-07) Adopt the three audit coupon renames** (Wardrobe Comp · Altar Marker — Lesser ·
   Forge Marker — Basic)? They also fix a real tier-vocabulary collision.
7. **(C-22) Which Farm justification** — augury pen (recommended, myth-native, mechanically
   free) · house livestock · keep the petting zoo?
8. **(C-24) Rename Wizard's Tower → the Sanctum?** Its own L3 already uses the word.
9. **(C-10) Name the Goldsmith's barter bench "the cage"?**
10. **(C-40) Add a `HOUSE` casino lane to the Box Namer**, and does it outweigh `SHOW`?

**Reconciliation flags (not v2 decisions, but surfaced by this pass)**

11. **(C-04) Is the TTRPG/game split on the 25 UT → 1 Patron Token exchange intentional?**
12. **(C-25) Does the TTRPG follow R16 and drop the Robot/AI race**, or do the products keep
    different race lists? (Changes what the Surgeon's Table sells.)
13. **(C-11) The digital addendum's healing rule is pre-GL6** — `rules-addendum.md:245-247`
    still says the Lounge restores HP fully and free, which the TTRPG replaced with the invoiced
    Med Bay. Worth reconciling whenever the addendum is next touched.
14. **(C-27) Was dropping the Restrooms module from book §20.3 intentional?**
15. **(Firearms) Sanity-check the bible's "loot must feel like remnants of belief" rule against
    a Basic Shotgun.** I believe §12.7's materials resolve it (the *material* is the belief), but
    the tension deserves a line of owner canon rather than my inference.
