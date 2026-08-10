# F — v2 canon ledger, open residuals & divergence register

**Compiled:** 2026-08-10 · **Method:** read-only sweep of the game repo's decision record.
**Scope:** what v2 (the Cosmic Casino / mythology version) has ALREADY DECIDED, what it
itself flags as still open, and where the game has already diverged from the TTRPG book.

### Citation roots (all paths below are relative to one of these)

| prefix | absolute root |
|---|---|
| `GAME:` | `/home/user/Galactic-Prime-Time-Game/` |
| `BOOK:` | `/home/user/Galactic-Prime-Time/` (char-sheet repo; the v1 rules master is `rulebook/gpt-system-v1.0.md`) |

### Status vocabulary used here

- **DECIDED** — an owner ruling exists, dated, in a decision record.
- **PROVISIONAL** — implemented/recorded but explicitly awaiting owner sign-off.
- **PROPOSED / ⟨PROPOSED⟩** — a drafting-agent proposal the docs mark as un-ruled.
- **SKETCH** — the doc itself says "not yet DECIDED".
- **OPEN** — named in a doc's own open list.
- **INFERRED** — *my* reading, not a recorded ruling (marked explicitly, used sparingly).

### Three structural facts that frame everything below

1. **The precedence chain is written down**: `GAME:docs/DIRECTION.md:200-207` — DIRECTION >
   `rules-addendum.md` > `GPT_Master_Compendium.md` > the GDD/architecture PDFs > the
   rulebook docx. v2 canon therefore *outranks* the book inside the game repo by design.
2. **The v1/v2 firewall is written down**: `GAME:docs/ttrpg-update-plan.md:13-45` — three
   canons kept deliberately separate (TTRPG book · digital rules addendum · video-game
   setting layer), with an explicit "hard exclusions" list of what never ports to the book.
   That table is the single most load-bearing artifact for this whole research task.
3. **The frame swap was scoped as a FRAME swap, not a redesign**:
   `GAME:docs/setting-rebrand-options.md:102-104` — dungeon, Moment clock, all combat
   rules, per-part HP, the addendum, the engine and its tests, Sasha & Nikita, the brand
   contract, the question architecture and the verdict were all declared untouched.

---

## 1. The v2 canon ledger (already decided — do not re-litigate)

### 1.1 Cosmology & the frame

| ID | Decision | Status | file:line |
|---|---|---|---|
| **D3** | The show is a table in the **Cosmic Casino**, adopted **game-first**: world rules yes, the novel's story no; where casino canon and GPT differ on *gameplay*, the dungeon/tables work closer to GPT's way ("mix and match") | DECIDED (2026-07-16) | `GAME:docs/DIRECTION.md:169-175`; `GAME:docs/story-canon.md:95-105` |
| REB-OD1 | Option A (the Cosmic Casino merge) adopted; options B/C/D rejected | DECIDED | `GAME:docs/setting-rebrand-options.md:1`, `:145-150` |
| REB-OD2 | **Hard decoupling from the novel** — "we only take the game, not the full story"; Marcus/Viola/#3 are examples only. Same-Earth-special-different-table is the default flavor, not a coupling risk | DECIDED | `GAME:docs/setting-rebrand-options.md:151-154`, `:133-138` |
| REB-OD5 | **Title "Galactic Prime Time" kept for now** — survives diegetically as the show's in-world name | DECIDED | `GAME:docs/setting-rebrand-options.md:158-159` |
| REB-OD6 | **Option E (starving pantheon) REJECTED** — the gods are NOT running out. Replacement lore: debaucherous casino spending bankrupts certain gods; ruin is self-inflicted status-loss. The campaign timer, where used, is a *season* mechanic, not cosmology | DECIDED | `GAME:docs/setting-rebrand-options.md:160-164`; `GAME:docs/cosmic-casino-canon.md:64-68` |
| COS-1 | **The ~250-year cycle**: realm bindings weaken, gods claim divine favor from a host realm; this cycle it's humanity/Earth; realm-tied deities prepare hidden champions | DECIDED (owner-corrected) | `GAME:docs/cosmic-casino-canon.md:10-17` |
| COS-2 | **Table taxonomy: Normal / VIP / VVIP-Forsaken** (supersedes the bible's Mass/VIP/War framing; war games are a *genre* of VIP game) | DECIDED | `GAME:docs/cosmic-casino-canon.md:19-25`, `:182` |
| COS-3 | **GPT is a VIP table whose in-fiction skin is a human reality show** — VIP games are built from what fascinated the gods about humanity (mostly pop culture). Every broadcast mechanic survives untouched | DECIDED | `GAME:docs/setting-rebrand-options.md:111-119` |
| COS-4 | **The games are run by fallen (bankrupt) gods of forgotten religions**, with explicit "anything goes" design license (relics, shapes, ideas, names) | DECIDED | `GAME:docs/cosmic-casino-canon.md:58-63`; `GAME:docs/setting-rebrand-options.md:127-130` |
| COS-5 | **Gods are morally alien throughout** — addicted, bored, spectacle-starved; no redemption, no hidden benevolence, nothing to twirl a mustache (hard rule) | DECIDED | `GAME:docs/cosmic-casino-canon.md:78-79`; `GAME:docs/narrative/narrative-design.md:44-45` |
| COS-6 | **Any god can go all-in** — Forsaken hosting is not influence-gated; a god may stake its **existence**, and its erasure can **unlock new stages** | DECIDED (2026-07-18) | `GAME:docs/cosmic-casino-canon.md:69-72`; `GAME:docs/design/patron-gods.md:216-221`; `GAME:docs/design/mythology-research-spec.md:303-309` |
| COS-7 | **Arena design rule:** each arena is shaped by the judge/director god's psyche — symbolic/psychological, never merely physical. Adopted for floor-set 3+ | DECIDED (canon) / adopted ✓ | `GAME:docs/cosmic-casino-canon.md:76-77`; `GAME:docs/gdd/decision-log.md:37` |
| COS-8 | **Momus hosts/announces** — pink tuxedo, never breathes between sentences, "This is Momus. Stay tuned!" — **shared host across novel and game** | DECIDED (2026-07-16) — *but see residual R-2* | `GAME:docs/cosmic-casino-canon.md:73-75`; `GAME:docs/setting-rebrand-options.md:157`; `GAME:docs/gdd/decision-log.md:39` |

### 1.2 Depiction policy & mythology sourcing

| ID | Decision | Status | file:line |
|---|---|---|---|
| MYT-D1 | **Modern majors participate as investor institutions** — living religions are the biggest bankrolls, present as large corporations; sacred core (God, prophets, founders) never depicted | DECIDED (2026-07-18) | `GAME:docs/cosmic-casino-canon.md:47-52`; `GAME:docs/design/mythology-research-spec.md:204-217` |
| MYT-D1b | **Messenger carve-out:** messenger-tier figures (Metatron, Gabriel, that level) ARE depictable — as corporate staff acting on the boss's requests; suits and org-chart rank, never religious iconography (`entity_class: spirit`, `casino_roles:["messenger"]`) | DECIDED | `GAME:docs/design/mythology-research-spec.md:204-213` |
| MYT-LORE | **The three Abrahamic brands are fronts of ONE holding company** — market segmentation to sell more product and multiply gambling volume; deadpan-corporate register | DECIDED (owner-approved) | `GAME:docs/cosmic-casino-canon.md:53-56`; `GAME:docs/design/mythology-research-spec.md:214-217` |
| MYT-v2 | **Depiction policy v2 (supersedes the gate structure):** register = pop-culture mythological fiction (Helltaker / mythology manhwa / Shinto anime). Gods, angels, demons and God-figures ARE depictable, positively or negatively; the per-figure `living` gate is **DROPPED**; `depiction_risk` stays as data only. Bar: respectful, never racist | DECIDED (2026-07-18, second ruling) | `GAME:docs/design/mythology-research-spec.md:219-233`; `GAME:docs/cosmic-casino-canon.md:81-89`; `GAME:docs/gdd/decision-log.md:58-69` |
| MYT-CO1 | **Named Islamic prophets (Muhammad above all) stay OUT** | DECIDED (confirmed) | `GAME:docs/design/mythology-research-spec.md:236-239`; `GAME:docs/cosmic-casino-canon.md:96-98` |
| MYT-CO2 | **Culturally closed ceremonial material** (Aboriginal sacred lore, Native nations' ceremonial stories) — **collection exclusion stands**; public-sphere folk material still screened in | DECIDED | `GAME:docs/design/mythology-research-spec.md:240-244` |
| MYT-FLAV | **Modern-life pantheon attributions are wanted flavor** (Greek = Hawaii-vacation, Roman = food-obsessed, Abrahamic = three managers fighting over one company); FSM-class parody figures eligible in principle, IP-check per figure | DECIDED | `GAME:docs/cosmic-casino-canon.md:90-95` |
| MYT-D2 | **Volume targets approved:** ~26-family census · ~150→**210** entities (14 traditions × up to 15) · ~120 myths · **MVP patron roster = 24 gods** | DECIDED (2026-07-18) | `GAME:docs/design/mythology-research-spec.md:363-377` |
| MYT-D3 | **Cosmic horror + internet folklore are researched now, shipped `deferred`** (`ship_status`); every non-traditional entity carries an honest `ip_status` | DECIDED (amended) | `GAME:docs/design/mythology-research-spec.md:386-395`, `:413-415` |
| MYT-D4 | **Real historical humans are OUT** — including deified ones (Guan Yu-class); their legend *cycles* may still be censused as stories | DECIDED (as exclusion) | `GAME:docs/design/mythology-research-spec.md:417-421` |
| MYT-RUB | **Dual-axis rating**: `influence` 1–5 = present-day worship (the god's bankroll) · `recognition` 1–5 = pop-culture audience draw; `obscurity_tier` derives mechanically; `table_tier_hint` from influence+recognition | DECIDED (spec executable) | `GAME:docs/design/mythology-research-spec.md:146-185`, `:253-258` |
| MYT-VOCAB | **26 controlled boon domains** — researchers may not extend ad hoc; Wave 5 maps domain → action tags / conditions / affix families | DECIDED | `GAME:docs/design/mythology-research-spec.md:274-288`; realized in `GAME:data/domain_condition_map.json` |
| MYT-EXEC | The research **executed**: 224 entity records, 294 myth records, 14 tradition dossiers, 24-god roster generated | DONE (data landed) | `GAME:data/mythology/entities.jsonl`, `GAME:data/mythology/myths.jsonl`, `GAME:docs/research/mythology/`, `GAME:data/patron_roster.json` |
| MYT-ROSTER | **Wave-5 24-god MVP roster APPROVED** (greenlit → build the roster generator + domain maps) | DECIDED (2026-07-18) | `GAME:docs/gdd/decision-log.md:130-132`; `GAME:docs/design/wave5-roster-shortlist.md:1-9` |
| MYT-FIX | **Caishen influence restored to 5** (not a rubric error — he's simply a better/more popular casino player); **Anansi→Ra swap** (Anansi is `folk`, not patron-capable — recorded as an error, not quietly patched) | DECIDED | `GAME:docs/gdd/decision-log.md:120-122`, `:149-153`; `GAME:docs/design/wave5-roster-shortlist.md:39-44` |

### 1.3 Audience, patrons & the divinity economy

| ID | Decision | Status | file:line |
|---|---|---|---|
| **D5 / Q1** | **Two tiers:** the **Patrons tier = donator gods** (they buy you things — the existing Viewers→Followers→Patrons ladder with gods on top); **THE patron god** = one singular escort who directs the *types of bets* on you and is usually your biggest donator | DECIDED (2026-07-16) | `GAME:docs/DIRECTION.md:179-182`; `GAME:docs/design/patron-gods.md:14-23`, `:229-230`; `GAME:docs/gdd/gdd.md:268-270` |
| PAT-ASSIGN | **Assignment is background-driven bidding**, not random: the OC background is the audition tape; structured picks map deterministically to god affinities (freeform LLM-read later); interested gods bid; **only the patron-less may choose** (the ORV rule); once bound the player cannot swap | DECIDED | `GAME:docs/design/patron-gods.md:25-42`; `GAME:docs/DIRECTION.md:182-184` |
| PAT-DEAL | **Deal sheets carry the god's explicit DOS and DON'TS** — `favor_conditions` + `taboos`, shown at bidding | DECIDED (2026-07-16) | `GAME:docs/design/patron-gods.md:36-40`; `GAME:docs/gdd/decision-log.md:31` |
| **Q4a** | **Buy-outs adopted:** a rival god overrules your patron's divinity, driven by accumulated affection; the champion gets a **notice of replacement** showing whether the current god agrees, and may accept or decline | DECIDED | `GAME:docs/design/patron-gods.md:46-51`, `:234-237` |
| **Q4b** | **Abandonment is NOT a contract exit:** a displeased patron switches to **extractive mode** ("trials to max out on you even if you break") or **total neglect**; the contract remains, the escort stops escorting | DECIDED | `GAME:docs/design/patron-gods.md:52-56` |
| **Q5** | **Rival gods can bless or curse your party**, gated on affection — blessings need higher affection, curses need lower (co-op griefing self-balances) | DECIDED | `GAME:docs/design/patron-gods.md:222-225`, `:238-239` |
| **Q6** | **Refusing every offer is allowed** — it is simply a **patron-less run**, nothing else. Explicitly NOT Forsaken | DECIDED | `GAME:docs/design/patron-gods.md:43-45`, `:240-242` |
| **Q7** | **Forsaken = god-initiated all-in**, never a refusal: the champion is *chosen* for a trial bigger than others; patron intact, tip channel sealed for every god, higher divinity/payout. Game translation: **hardcore opt-in** offered randomly from run 2 onward, never on a first run, **never mid-campaign** | DECIDED | `GAME:docs/design/patron-gods.md:204-215`, `:243-245`; `GAME:docs/cosmic-casino-canon.md:27-30` |
| **Q8** | **Buffs = conditional blessings AND loot/affix roll quality**; durations temporary / continuous-on-a-condition / sometimes permanent. **Non-patron affection buys** gift chance + **buy-out interest** | DECIDED | `GAME:docs/design/patron-gods.md:114-124`, `:246-248` |
| **Q3** | **God stats = fixed cores + small seeded jitter** per run | DECIDED | `GAME:docs/design/patron-gods.md:183`, `:233` |
| PAT-BOON | **The boon economy is the MULTIPLIER model:** actions emit domain-tagged impressions; patron-less = diffuse spread across related gods; with a patron = top multiplier on their domains, middle multiplier on faction ("related lesser gods"), affection amplified and directed | DECIDED (direction; numbers PLACEHOLDER) | `GAME:docs/design/patron-gods.md:87-113` |
| PAT-INFL | **Divine influence hierarchy:** modern religions = biggest investors > story-pantheons (Zeus/Ares kin, beloved as characters) > lower/forgotten deities. **Casting consequence:** that ordering IS the show's recurring ensemble; lower deities appear at higher rarity or lower tables. Data field `influence` 1–5 | DECIDED | `GAME:docs/design/patron-gods.md:58-71` |
| PAT-DET | **Affection is a pure function of the event log** (declarative predicates over sim events); **patron actions are dealer tips entering the sim as schema-bound commands** (`patron_tip(...)`), never direct state mutation | DECIDED | `GAME:docs/design/patron-gods.md:189-198` |
| PAT-PLANE | **Two information planes hold for boons:** contestants get diegetic manifestations (a comp in the loot drop, a System message); spectators/replays get the announcer naming the god and the size of the tip — the dramatic irony is the product | DECIDED | `GAME:docs/design/patron-gods.md:199-203`; `GAME:docs/DIRECTION.md:149-163` |
| ECON-1 | **Ascension is canon near-verbatim:** winners take some of the currency wagered → gain divinity → **join the table as gamblers**. Winning doesn't free you, it promotes you into the audience | DECIDED | `GAME:docs/cosmic-casino-canon.md:41-43`; `GAME:docs/setting-rebrand-options.md:44-48`, `:120-121` |
| ECON-2 | **The final winner decides how history is shaped for 250 years and how the apocalypse is remembered** — the source of every legend humanity created. The verdict ending is literalized, not metaphorical | DECIDED | `GAME:docs/cosmic-casino-canon.md:44-46`; `GAME:docs/setting-rebrand-options.md:122-126` |
| ECON-3 | **Directives/Goals = tips to the dealer / side bets from the gallery**; Camera Call = the odds board turning to you; Lounge = **the comp suite**; Boss/Upgrade tokens = house markers & chips. Mechanics unchanged, voice re-skinned | DECIDED (mapping) | `GAME:docs/setting-rebrand-options.md:29-42`, `:131-132`; `GAME:docs/design/patron-gods.md:77-85` |
| ECON-4 | **Tipping the dealer** is the wager/patron-influence mechanism at every non-Forsaken table (boons, buffs, items — or trials, monsters, curses against others) | DECIDED | `GAME:docs/cosmic-casino-canon.md:32-34` |
| ECON-5 | **Cross-party wagering** is the Stage-2 shape of patronage (other players' patrons bet on your run) | DECIDED (direction) | `GAME:docs/setting-rebrand-options.md:41`; `GAME:docs/DIRECTION.md:46-47` |

### 1.4 Epithets, tags & identity

| ID | Decision | Status | file:line |
|---|---|---|---|
| **Q2** | **Epithets run on a TRAITS track, not the tag track** — you accumulate trait-words (from background picks + deeds); when your pattern **recreates a legend's myth you gain its epithet**. Champions are compared to previous legends | DECIDED | `GAME:docs/design/patron-gods.md:126-135` |
| EPI-CAT | **The myth catalog is REAL mythology, graded ORV-style:** folk tale < local legend < heroic epic < world myth; higher grade = rarer pattern = stronger epithet | DECIDED (2026-07-16) | `GAME:docs/design/patron-gods.md:136-139`; `GAME:docs/design/mythology-research-spec.md:260-272`; `GAME:docs/gdd/decision-log.md:38` |
| EPI-CANON | **Canon synergy:** legends are literally artifacts of previous games — recreating a myth is re-walking a past champion's shape | DECIDED | `GAME:docs/design/patron-gods.md:140-142`; `GAME:docs/narrative/narrative-design.md:129-134` |
| EPI-SEED | **Epithet backlog (migrated from tags):** `nine_lives` ("Sasha the Nine-Lived" — the canonical example), `unkillable`, `vengeful`, `butcher`, `incorrigible` | DECIDED (2026-07-17) | `GAME:docs/design/patron-gods.md:148-150` |
| TAG-SPLIT | **Tags = the audience's labels (performable, fakeable); epithets = the pantheon's comparisons.** Two tracks, deliberately separate and occasionally contradictory — that tension IS the spine made mechanical | DECIDED | `GAME:docs/design/patron-gods.md:146-147`; `GAME:docs/story-canon.md:84-88`; `GAME:docs/gdd/gdd.md:284-294` |
| TAG-FX | **Tag effect model RULED: the 5 declarative patterns PLUS a 6th — tags GATE unlocks** (items, actions and skills may require tags as obtain/use conditions) | DECIDED (2026-07-17) | `GAME:docs/rules-addendum.md:708-711`; model detail `GAME:docs/audits/campaign-residuals-audit.md:173-206` |
| TAG-PRUNE | Game tag list pruned per owner list: **84 live tags**, 5 words moved to the epithet track, K-pop cluster removed; the 2026-07-17 **renames stand** (Reckless, Gorefest, What a Beaut, Shill, Heart Melter, Not My Job, Winter Sheep) | DECIDED — *data now contradicts, see residual R-19* | `GAME:docs/rules-addendum.md:708-711`; `GAME:docs/gdd/decision-log.md:93-97` |
| TAG-TVT | **TVTropes.org is no longer a tag-sourcing authority** — the dependency is internalized; epithets absorb the "essence word" cases | DECIDED | `GAME:docs/audits/campaign-residuals-audit.md:357`; `GAME:docs/setting-rebrand-options.md:38` |
| TAG-SLICE | **Slice tag set APPROVED** (10 detectable tags in `data/tag_effects.json`; loadouts start tagless — everything earned on camera; non-contestants hold no tags; **The Bit must be mechanically NULL**) | DECIDED (2026-07-18) | `GAME:docs/design/slice-tags-proposal.md:367-388`; `GAME:docs/gdd/decision-log.md:160-166` |
| TAG-BIT | **The Bit is AUTHORED, per-character content** — not everyone has one; the sim rejects `the_bit` from an actor with no authored bit (Dario: The Bow; Imani: none) | DECIDED (2026-07-22) | `GAME:docs/gdd/decision-log.md:276-284` |

### 1.5 Enemies & content pools

| ID | Decision | Status | file:line |
|---|---|---|---|
| ENE-MYT | **Mythology-sourced monsters** are the licence-free content pool (the Asag-offspring template); monsters are collateral **followers of gods** in three states (Insane / Sane / Worshipped) | DECIDED (frame) | `GAME:docs/setting-rebrand-options.md:42`; `GAME:docs/cosmic-casino-canon.md:148-155` |
| ENE-KEEP | **The existing dungeon survives the frame swap untouched** — floors, routes, time skips, demons, Loong, Incinedile | DECIDED | `GAME:docs/setting-rebrand-options.md:102-104`; `GAME:docs/audits/campaign-residuals-audit.md:386` |
| ENE-LOOT | **Loot must feel like remnants of belief** — God Relics (jackpot-rare) and Follower Relics (objects empowered by faith); never generic stat sticks | DECIDED (bible material that stands) | `GAME:docs/cosmic-casino-canon.md:156-159` |
| ENE-CHROM | **Mycelius Chrom is a SERVANT, not a god** — a fungal servitor tied to a decay/death myth (Osiris-type retinue) | DECIDED (owner correction 2026-07-18) | `GAME:docs/gdd/decision-log.md:98-100` |
| ENE-BOSS | **Bosses need discoverable win conditions, never damage races** — enforced in the engine as the F2 invariant: *death/removal routes ONLY through a lethal, EXPOSED part* | DECIDED + IMPLEMENTED | `GAME:CLAUDE.md` hard rules; `GAME:docs/gdd/decision-log.md:190-201`; `GAME:_workflow/learnings.jsonl:24` |
| ENE-INC | **Incinedile canon:** 6 phases; breach B = 7+ damage in a **single hit**; explosion beats are REAL (telegraph → escape window → blast → knockout = **Helpless 2 Clocks** → retreat → next Threshold); wounds persist across the valve | DECIDED (2026-07-14 / 2026-07-18 / 2026-07-23) | `GAME:docs/DIRECTION.md:126-127`; `GAME:docs/gdd/decision-log.md:297-308`; `GAME:docs/rules-addendum.md:386-404` |
| ENE-NET | **The mycelium network is just a body part with per-part resistances** — not a bespoke gate; immune to most conditions, no force resistance, **fire harms it**, neural poison bypasses. Generalized as the material/prosthetic system | DECIDED (2026-07-20) | `GAME:docs/gdd/decision-log.md:260-275`; `GAME:_workflow/learnings.jsonl:26` |

### 1.6 Narrative & story

| ID | Decision | Status | file:line |
|---|---|---|---|
| **D4** | **The player is an OC** (their own created contestant); **NPCs are predesigned characters with story arcs** — Sasha & Nikita are the first two, recruitable | DECIDED (2026-07-16) | `GAME:docs/DIRECTION.md:176-178`; `GAME:docs/story-canon.md:97-105` |
| D4b | **"OC" = made in character creation (KAN-4 S4.1).** Imani/Dario are **demo/quick-start loadouts + test fixtures, never canon characters** — build them, but everything demo-built is rewireable later | DECIDED (2026-07-18) | `GAME:docs/gdd/decision-log.md:74-77`, `:154-166`; `GAME:docs/design/slice-contestants-proposal.md:257-274` |
| IP-1 | **Players' own campaign characters stay OUT** (parked as concepts); **Sasha & Nikita enter as recruitable NPCs, names kept**, permanently losable; their story is **KEEPER content** (story shape protected, surface renameable) | DECIDED (2026-07-15/16) | `GAME:docs/story-canon.md:39-58` |
| SPINE | **The spine:** *"How much can we break your essence down in the name of entertainment?"* Floors reach ~20 (design paused at 6); each floor-SET asks one moral question; answers unlock path-dependent routes; **the ending is a verdict** naming what person you were and what **ruler** you'll be | DECIDED (2026-07-15) | `GAME:docs/story-canon.md:60-83` |
| VERD | **The verdict system is a data structure** — axes, per-floor-set scoring, an unlock graph keyed on prior answers, a final verdict function; the convergence matrix is its data feed | DECIDED (design consequence) | `GAME:docs/story-canon.md:77-83`; `GAME:docs/gdd/gdd.md:295-298` |
| BRAND | **The demonic brand paradox is intentional — mercy earns the songs.** The brand is a contract that works by **dulling the branded** (massive EQ loss); dual-prose presentation is canon **but post-MVP** | DECIDED (2026-07-15/16) | `GAME:docs/story-canon.md:6-37` |
| NAR-VOICE | Sasha **cannot speak human — she talks through the CHAT FUNCTION**; Old Nikita slow/warm, War Nikita clipped-imperative | DECIDED (2026-07-16) | `GAME:docs/narrative/narrative-design.md:174-178`; `GAME:docs/gdd/gdd.md:257-260` |
| NAR-DLG | Dialogue = broadcast lower-thirds + barks + short trees; **no VN layer, no cutscenes in v1** | DECIDED (2026-07-16) | `GAME:docs/gdd/gdd.md:257-259`; `GAME:docs/narrative/narrative-design.md:157-161` |
| NAR-BEAT | **Episode beats adopted provisionally** — try it during floor authoring, drop if it fights the dungeon | DECIDED-provisional | `GAME:docs/narrative/narrative-design.md:68-72`; `GAME:docs/gdd/decision-log.md:36` |
| NAR-PRIN | **Never moralize in text what the game scores in data**; **found documents** as environmental storytelling ✓ | DECIDED (both ✓ in the slate) | `GAME:docs/gdd/decision-log.md:37`; `GAME:docs/narrative/narrative-design.md:213`, `:187-189` |
| **R17** | **Death rules depend on RUN TYPE:** softcore = respawn (humane default) · hardcore = permadeath (owner-preferred) · **Forsaken = hardcore by nature**. Recruited NPCs permanently losable in every mode. **No difficulty menu** — run types + patron choice + route selection are the difficulty surface | DECIDED (2026-07-16) | `GAME:docs/rules-addendum.md:603-612`; `GAME:docs/gdd/decision-log.md:32`, `:35-36` |
| LOUNGE | **The Lounge is a walkable exclusive hub** (loot opening / contract review / tinkering), and entering it **resets roaming monsters** — overriding the earlier menus-over-scenes proposal | DECIDED (2026-07-16) | `GAME:docs/gdd/decision-log.md:34-35`; `GAME:docs/gdd/gdd.md:237-245` |

### 1.7 Presentation & production

| ID | Decision | Status | file:line |
|---|---|---|---|
| **D2** | **2.5D tactical presentation**; 3D reconsidered only at Stage 3, and only with team/funding | DECIDED (2026-07-13) | `GAME:docs/DIRECTION.md:15-17` |
| ART-1 | **Art route: GPT-generated stills + an asset-ification pipeline** (`spritify.py`); ComfyUI and Claude Design eliminated in the bake-off | DECIDED (2026-07-18) | `GAME:docs/gdd/gdd.md:330-333`; `GAME:memory/decisions.md:39-41` |
| ART-2 | **16-bit pixel accepted as the FLOOR**; the ceiling is set by **animation cost**, not still-frame beauty | DECIDED (with the ceiling itself OPEN) | `GAME:docs/gdd/gdd.md:335-343` |
| UI-1 | **Demo mockups APPROVED — KAN-6 mockup gate passed** (combat/broadcast HUD, patron bid screen, verdict card); keep the 3-column director rail; keep the band display names | DECIDED (2026-07-19) | `GAME:docs/gdd/decision-log.md:183-189` |
| UI-2 | **HUD v2 structural spec ADOPTED** as the rebuild target; **vocabulary RULED: engine terms stand** — Clock = the 10-tick lap, Moment = the tick | DECIDED (2026-07-22) | `GAME:docs/gdd/decision-log.md:285-296` |
| UI-3 | **Engine-first mandate; the front rework is owner-led** — the owner drafts the mockups; KAN-4 screen decisions deferred; engine work proceeds without UI approval | DECIDED (2026-07-25) | `GAME:docs/gdd/decision-log.md:345-356` |
| UI-4 | **"Rework Visuals Properly" is a named PARKED epic** (declutter the HUD, replace placeholder art/writing); the themed-game-pieces + visceral-injury art direction is a **candidate, NOT ruled** | PARKED / candidate | `GAME:docs/gdd/decision-log.md:202-220` |
| SLICE-BID | **The patron bid screen IS in the slice**, with one chosen patron seeded per demo loadout; stub archetype gods into `patron_gods.json` | DECIDED (2026-07-18) | `GAME:docs/design/slice-contestants-proposal.md:268-270` |

### 1.8 Technical & process (v2-shaped, already binding)

| ID | Decision | Status | file:line |
|---|---|---|---|
| **D1** | **North star = the shared-world ladder**: Stage 0 command-stream sim → Stage 1 slice + friends co-op → Stage 2 async global show → Stage 3 shared space. Literal-MMO pivot and single-player-only both rejected | DECIDED (2026-07-13) | `GAME:docs/DIRECTION.md:8-14`, `:30-60` |
| TECH-1 | **Command-stream contract:** state is a pure function of (seed, ordered command log); no wall-clock reads, no unlogged randomness; UUID ids at the JSON boundary; saves = snapshot + log offset | DECIDED | `GAME:docs/DIRECTION.md:62-79` |
| TECH-2 | **Director behind one interface** (goals, directives, audience reactions, beats): procedural v1, LLM-augmentable later, server-side from Stage 2 | DECIDED | `GAME:docs/DIRECTION.md:73-75` |
| TECH-3 | **The social director ("mother brain") constraints:** LLM interprets, **sim decides** — schema-bound commands only (`faction_shift`, `quest_spawn`, `world_manifest`, `system_message`); ONE brain over many NPCs; speech scoring = LLM-judge + deterministic combiner | DECIDED (feasibility assessment recorded) | `GAME:docs/DIRECTION.md:129-166` |
| TECH-4 | **Two information planes** (broadcast plane hears the announcer; contestants get world manifestations / sudden quests / System messages) — this is also the tonal firewall | DECIDED (owner refinement 2026-07-14) | `GAME:docs/DIRECTION.md:149-163`; `GAME:docs/review/review-6-story.md:43-48` |
| TECH-5 | **Combat fields + pluggable clock drivers** (paused solo / timed declare windows / wall-clock broadcast); noise/absorption at Clock resets | **SKETCH — explicitly not DECIDED** | `GAME:docs/DIRECTION.md:81-115` (status line `:83`) |
| PROC-1 | **Build with PLACEHOLDER numbers and tune by feel** — R14 is no longer a gate on building systems | DECIDED (2026-07-19) | `GAME:docs/gdd/decision-log.md:142-145` |
| PROC-2 | **Content freeze:** no new mythology / bosses / patrons beyond 6 / floors / recruitment / shared-world until the slice proves fun to a stranger | DECIDED (2026-07-20) | `GAME:memory/current-state.md:57-58` |
| PROC-3 | **Patron dataset ruling:** `data/patron_roster.json` (24 gods) is CANONICAL; `data/patron_gods.json` (5) is an explicit slice subset; the migration is DEFERRED | DECIDED (2026-07-20) | `GAME:docs/gdd/decision-log.md:252-259`; `GAME:data/patron_roster.json` `_meta.supersession_note` |

---

## 2. Open-residual register (the real open questions)

Ordered roughly by how much v2 design depends on them. "Doc conflict" = two records disagree about whether something is already ruled; those are cheap to close and dangerous to leave.

| # | Question | Where flagged (file:line) | Blocking what? |
|---|---|---|---|
| **R-1** | **Does the live TTRPG table actually re-skin to the casino?** `setting-rebrand-options.md` records it **RULED: RE-SKIN TO CASINO**; the TTRPG update plan's scope says the opposite in the strongest terms ("The TTRPG keeps its ORIGINAL setting… everything Cosmic-Casino-flavored is video-game-only"); DIRECTION and the GDD still list it as open | `GAME:docs/setting-rebrand-options.md:155-156` vs `GAME:docs/ttrpg-update-plan.md:5-9`, `:21-28`; still-open lists `GAME:docs/DIRECTION.md:197-198`, `GAME:docs/gdd/gdd.md:398`, `GAME:docs/narrative/narrative-design.md:244` | Everything in section 3. Whether the book/app ever adopt god vocabulary, and whether "Patrons" stay audience members at the table |
| **R-2** | **Momus: shared host with the novel, or a sibling host?** Ruled "shared" twice; three live docs still carry it as OPEN | ruled: `GAME:docs/setting-rebrand-options.md:157`, `GAME:docs/gdd/decision-log.md:39` · open: `GAME:docs/DIRECTION.md:197-198`, `GAME:docs/narrative/narrative-design.md:241-242`, `GAME:docs/gdd/gdd.md:398` | The production cast (R-10), announcer VO scope, novel–game coupling optics |
| **R-3** | **The title.** "Keep for now" was ruled; the GDD and narrative doc still title the project "⟨working title — OPEN⟩" | ruled: `GAME:docs/setting-rebrand-options.md:158-159` · open: `GAME:docs/gdd/gdd.md:11`, `GAME:docs/narrative/narrative-design.md:3` | Marketing, store page, nothing structural |
| **R-4** | **The timer.** Option E rejected and the timer demoted to a *season* mechanic; the GDD still lists "the timer (season mechanic vs starving-pantheon cosmology)" as OPEN | ruled: `GAME:docs/setting-rebrand-options.md:160-164` · open: `GAME:docs/gdd/gdd.md:399`, `GAME:docs/narrative/narrative-design.md:242` | Whether a run/season clock exists at all; cosmology consistency |
| **R-5** | **Forsaken manual trigger** (after a first win): recorded as **CONFIRMED** in the GDD decision log but still marked ⟨PROVISIONAL⟩ in three places | confirmed: `GAME:docs/gdd/decision-log.md:31-32` · provisional: `GAME:docs/design/patron-gods.md:245`, `GAME:docs/DIRECTION.md:194-195`, `GAME:docs/gdd/gdd.md:276`, `GAME:docs/gdd/decision-log.md:14` | KAN-7 Forsaken mode build |
| **R-6** | **Does the "patron never redeems" hard rule survive Plutus's softer characterization?** — explicitly "owner to confirm" | `GAME:docs/cosmic-casino-canon.md:186-187` | Patron-god temperament authoring; whether a patron arc can ever soften |
| **R-7** | **Unwagerable exit vs divinity buy-in** — the bible's "become unwagerable" north star was never restated against the winners→gamblers pipeline; "owner to reconcile" | `GAME:docs/cosmic-casino-canon.md:191-193` | The ending/Ascension design; what "winning" ultimately means |
| **R-8** | **Rating/controversy handling for depicted living religions** — flagged as "a deliberate handling decision for the roster pass, owner's IP call", and the risk register still demands a cultural review before any public build (even though the per-figure gate was dropped) | `GAME:docs/design/patron-gods.md:72-73`; `GAME:memory/open-risks.md:11-16`; `GAME:memory/next-actions.md:41-43` | Public release of anything containing the 24-god roster |
| **R-9** | **Player-OC death consequence** — OPEN; defaults to GDD v0.2's Ascension-NG+ until ruled (R17 gives run types, not the *diegetic* consequence; softcore's respawn framing is also TBD) | `GAME:docs/gdd/decision-log.md:13-16`; `GAME:docs/narrative/narrative-design.md:85-87`; `GAME:docs/gdd/gdd.md:104-106`, `:401` | Campaign loop, NG+, what Ascension means for a dead OC |
| **R-10** | **The production cast** — no named announcer/producer/showrunner beyond Momus; review-6 called this the frame's biggest narrative hole; the patron roster is proposed as the cheapest place to grow it ⟨PROPOSED⟩ | `GAME:docs/review/review-6-story.md:34-41`; `GAME:docs/narrative/narrative-design.md:108-110`; `GAME:docs/ISSUES.md:28` (I-12); still "pending explanation before ruling" as *production-cast-via-patrons* `GAME:docs/gdd/decision-log.md:40-41` | Slice win/lose framing, broadcast voice, KAN-7 cast |
| **R-11** | **The convergence matrix** (routes × offscreen resolutions → capital state → verdict axes) — the largest unwritten story artifact; needs owner walkthrough sessions | `GAME:docs/narrative/narrative-design.md:221-223`; `GAME:docs/ISSUES.md:36` (I-20); `GAME:docs/review/review-6-story.md:214-216` | Floor-3 content lock, the verdict instrument |
| **R-12** | **Finale staging + what "ruler" concretely means** | `GAME:docs/ISSUES.md:34` (I-18); `GAME:docs/story-canon.md:79-83` | Endgame content; the convergence matrix should point at it |
| **R-13** | **Medium-route refusal forks + brand-breach consequences** ("the contract cuts both ways — define breach consequences") | `GAME:docs/story-canon.md:36-37`; `GAME:docs/ISSUES.md:39` (I-23) | Floor 1–3 Medium route authoring |
| **R-14** | **Nikita's two key scenes** (what winning a War-Nikita fight means; the recognition scene) + war-state numbers + target-discrimination rule | `GAME:docs/characters/nikita.md:85-88`; `GAME:docs/ISSUES.md:40` (I-24) | Floors 4–6; the keeper thread's climax |
| **R-15** | **Sasha's part layout / the animal-parts sitting** — she isn't playable without an authored cat body plan (Q61 deferred) | `GAME:docs/characters/sasha.md:74-76`; `GAME:docs/rules-questionnaire.md:337-340`; `GAME:memory/next-actions.md:41-43` | Recruiting Sasha; R21 animal layouts generally |
| **R-16** | **Patron bidding-flow details remain PROPOSED shaping** — the structured background picks, the 2–3 offer count, deal-sheet presentation | `GAME:docs/design/patron-gods.md:25-31`, `:240-242`; picks marked ⟨PROPOSED⟩ `GAME:docs/narrative/narrative-design.md:82-85` | KAN-4 creation flow + KAN-7 bidding |
| **R-17** | **Stage-2 myth compilation** (an ascended player's run becomes a myth template others can recreate) — ⟨PROPOSED, later⟩ | `GAME:docs/design/patron-gods.md:143-145` | Stage-2 design only |
| **R-18** | **Patron slice→roster migration deferred** — the 5-god `patron_gods.json` still backs the bid screen because demo loadouts reference ids 2/3 | `GAME:docs/gdd/decision-log.md:252-259`; `GAME:data/patron_roster.json` `_meta` | Using the canonical 24 gods in-game |
| **R-19** | **Tag data contradicts the tag rulings.** `data/tags.json` is back to **100 rows**, including all 5 epithet-migration words (`unkillable`, `vengeful`, `butcher`, `incorrigible`, `nine_lives`) and the 7 tags the audit CUT — because the I-8 rulebook-description port re-added 16 authoritative rows. The 84-tag pruning + epithet migration is therefore *not* reflected in data | ruling: `GAME:docs/rules-addendum.md:708-711`, migration mechanics `GAME:docs/audits/campaign-residuals-audit.md:163-167` · port: `GAME:docs/design/tag-reconciliation-2026-07-18.md:1-27` · data: `GAME:data/tags.json` (100 rows) | The epithet vocabulary seed; any tag-count assertion; KAN-7 |
| **R-20** | **Tag effects for the remaining ~90 tags** + `goal_modifier_weights` (only 10 slice tags have effects) | `GAME:docs/ISSUES.md:43` (I-27); `GAME:docs/design/slice-tags-proposal.md:369-371` | KAN-7 audience systems |
| **R-21** | **R25 valve-counter consequence flagged for explicit owner sign-off** — a well-timed Tactical Roll always escapes the explosion KO from anywhere in the radius | `GAME:docs/rules-addendum.md:841-847` | Boss balance / the slice's win moment |
| **R-22** | **Incinedile dodge threshold retune 4→7 stays PROVISIONAL** (flagged with the rest of the R14 numbers) | `GAME:docs/rules-addendum.md:750-752` | Slice tuning |
| **R-23** | **F2 open nit:** is a lethal *condition* on the *exposed* network an acceptable finisher, or must "destroy the network" strictly mean HP→0? | `GAME:docs/gdd/decision-log.md:199-201` | Boss win-condition purity |
| **R-24** | **Run-engine PROVISIONAL defaults** awaiting the owner's front pass: recruits join AS-IS carrying encounter damage; a declined recruit is gone for the run | `GAME:docs/gdd/decision-log.md:349-356` | KAN-4 recruitment |
| **R-25** | **R14 magnitudes**: the *function* is decided (`damage = max(0, Force − Robustness)`) but every number is PLACEHOLDER and the engine implementation is still pending | `GAME:docs/rules-addendum.md:536-545`; `GAME:memory/current-state.md:38-43`; `GAME:STATUS.md:35-46` | All balance; the mutation/playtest tuning pass |
| **R-26** | **Questionnaire remainder**: as of the 2026-07-17 audit **70 of 79 questions were open**; the 2026-07-23 batch closed many, and the questionnaire itself still lists **Q42 (tag effects), Q49/Q50 (currency + loot boxes), Q65–Q67 (Lounge)** as open, plus **NQ6** (tank kit) and **NQ7** (affliction-resistance sourcing) | `GAME:docs/audits/campaign-residuals-audit.md:395-443`; `GAME:docs/rules-questionnaire.md:484-485`, `:423-429` | Economy + Lounge epics (note: the v1 book has since ruled its own economy/Lounge — see R-27) |
| **R-27** | **Game-side propagation of the 2026-07-23→07-25 book rulings is still pending** (the book reached v1.0 with a fully ruled economy, Lounge, tags chapter, Boss Tokens retired into Upgrade Tokens; the addendum has not absorbed those) | `GAME:_workflow/learnings.jsonl:32`; `GAME:docs/rules-questionnaire.md:435-441` | Keeping the two canons honestly diffed |
| **R-28** | **The divergence guard itself does not exist yet.** The update plan's Phase 4 requires a committed three-way consistency appendix (book ↔ app ↔ addendum) and states plainly that any difference not listed there is a bug. No such artifact was found in either repo, and the book never references the addendum | plan: `GAME:docs/ttrpg-update-plan.md:207-211`, `:219-221` · absence verified across `BOOK:rulebook/gpt-system-v1.0.md` (no "addendum"/"divergence" hits) and `BOOK:docs/` | Every future v1/v2 reconciliation; this is the artifact section 3 below is a stand-in for |
| **R-29** | **Art fidelity ceiling** (16-bit floor accepted; "maybe 16-bit is too little") — the ladder test never resolved; the themed-game-pieces art direction is a parked candidate | `GAME:docs/gdd/gdd.md:335-343`; `GAME:docs/gdd/decision-log.md:202-210` | The visual rework epic |
| **R-30** | **Legal/asset hygiene before any public build**: LICENSE holder name, 15 raw photo/screenshot placeholders, licensed music references (God Shattering Star; the Dissolution songs) are dev-vibe only, SCP/Slenderman `ship_status` clearance | `GAME:memory/next-actions.md:38-43`; `GAME:memory/open-risks.md:17-19`; `GAME:docs/audits/campaign-residuals-audit.md:228-232` | Public release |
| **R-31** | *(low)* **Stale open-item lists.** `memory/next-actions.md:41-43` still lists "telepathy manipulation-lane confirm" although it was RESOLVED + CONFIRMED; the GDD's OPEN block (`gdd.md:398-402`) predates the R13/R14 finalizations and the title/host/timer/re-skin rulings | `GAME:docs/gdd/decision-log.md:117-119` vs `GAME:memory/next-actions.md:41-43`; `GAME:docs/gdd/gdd.md:398-402` | Nothing — but they generate false "open" signals in exactly this kind of sweep |

---

## 3. Divergence register (game vs book)

**Book** = `BOOK:rulebook/gpt-system-v1.0.md` (v1.1 content, the TTRPG rules master).
**Split type:** **THEME** = the difference exists because v1 is alien-broadcast and v2 is
gods-casino · **IMPL** = digital-vs-tabletop implementation (an engine needs a number/rule
where a GM improvises) · **MIXED** where both drivers are recorded.

The authoritative *intent* list is `GAME:docs/ttrpg-update-plan.md:13-45` ("three canons,
kept separate" + hard exclusions). Everything below is either from that list or verified
directly against both texts.

| Topic | What the BOOK says (file:line) | What the GAME says (file:line) | Split | Notes |
|---|---|---|---|---|
| **Who runs the show** | "You are a contestant: an abducted human — or animal, or machine — competing in **alien-broadcast** dungeon runs" | The show is a **VIP table in the gods' Cosmic Casino**, run by a fallen/bankrupt god; the Corporation-as-power and its colonization motive are **dead canon** | **THEME** | `BOOK:rulebook/gpt-system-v1.0.md:25-26` vs `GAME:docs/DIRECTION.md:169-175` + `GAME:docs/audits/campaign-residuals-audit.md:351`. The single root divergence; almost everything else in this table descends from it |
| **"Patrons"** | **One-time large donors** ($5,000-tier watchers); the Patron roster is **permanent**; Patron Tokens are the skill-cap currency | The **Patrons tier = donator gods**, with **THE patron god** as a singular escort slot above it | **THEME** | `BOOK:...:882-886`, `:892-894` vs `GAME:docs/design/patron-gods.md:14-23`. The plan states it explicitly: "Patrons in the TTRPG remain paying audience members, never gods" (`GAME:docs/ttrpg-update-plan.md:25-28`) |
| **Patron-Token exchange** | Kept and priced: **25 Upgrade Tokens → 1 Patron Token**, one-way (Boss Tokens retired into Upgrade Tokens by v1.0; the earlier plan ruling D-2 had a tier-aware Bronze 5:1…Godly 1:2 ladder) | **CUT from the digital game** (R10, D7): Patron Tokens come only from the audience loop | **IMPL** | `BOOK:...:1145-1148` and `GAME:docs/ttrpg-update-plan.md:112` vs `GAME:docs/rules-addendum.md:234-236`. Note the book has moved twice since the plan was written — the recorded D-2 rates are already superseded book-side |
| **Damage model** | Attack deals its **listed damage** minus flat resistance | **`damage = max(0, Force − Robustness)`** — the force gate and the number are one subtraction; blocked hits can still land Shock but seed no conditions | **IMPL** (explicitly ruled) | `BOOK:...:429` vs `GAME:docs/rules-addendum.md:536-545`. Ruled as a deliberate split: D-1, "book keeps the listed-damage model; R14 stays digital-only" (`GAME:docs/ttrpg-update-plan.md:111`, rationale `:47-52`) |
| **Races** | **Human / Animal / Robot-AI**; machines get a conditions sidebar; non-standard bodies are GM-shaped | **Robot removed entirely** — playable = any living thing on Earth (Humans + Animals); background grants the 4 starting skills | **IMPL** (not required by the casino frame) | `BOOK:...:68`, `:75`, `:413` vs `GAME:docs/rules-addendum.md:575-587`, data `GAME:data/races.json` (2 rows). Book-side reason is campaign continuity (XQUEZ/T is a live table character) — D-4, `GAME:docs/ttrpg-update-plan.md:114`, exclusion `:31-33` |
| **Tags** | The **full original 100-tag list** with the owner's authoritative descriptions (ch.18) | **84 live tags**; 5 words migrated to the **epithet** track; K-pop cluster removed; renames applied; effects = 5 declarative patterns + tags-gate-unlocks | **THEME** (the epithet track is pantheon-native) | `BOOK:...:963+` and D-6 `GAME:docs/ttrpg-update-plan.md:116` vs `GAME:docs/rules-addendum.md:708-711`. ⚠ **Data does not match the game ruling** — see residual R-19 |
| **Epithets** | **Do not exist** (zero occurrences of "epithet" in the book) | A whole second identity track: traits → myth recreation → epithets, graded ORV-style | **THEME** (pure v2 addition) | `GAME:docs/design/patron-gods.md:126-150`; excluded from the book by `GAME:docs/ttrpg-update-plan.md:22-24` |
| **Divine intervention in stealth** | Stealth/detection/cover chapter with GM adjudication; **no god lever** | R20's diegetic destealth lever is **a rival patron cursing you unstealthy / outing you** | **THEME** | `BOOK:...:819+` (+ A-25 "the god-based destealth lever stays game-only", `GAME:docs/ttrpg-update-plan.md:103`) vs `GAME:docs/rules-addendum.md:658-660` |
| **Directives / the house voice** | Directives issued by the Corporation/production | Directives are the **house** (the fallen god running the table) speaking; System messages are the house channel; Goals = side bets from the gallery | **THEME** (mechanics identical, voice re-skinned) | `GAME:docs/audits/campaign-residuals-audit.md:358`; `GAME:docs/design/patron-gods.md:80-82` |
| **The Lounge** | The Golden Cage Lounge: GM chapter with priced healing (`Floor × 2^claims`), module tree, Upgrade-Token sinks | **The comp suite** — "the house always comps your room; surveillance = the house watching its assets" — and a **walkable hub** whose visit resets roaming monsters | **MIXED** (voice = THEME; walkable hub + roaming resets = IMPL) | `BOOK:...:1176+`, `:857` vs `GAME:docs/gdd/gdd.md:237-245`; re-voice `GAME:docs/audits/campaign-residuals-audit.md:359` |
| **Mind collapse epilogue** | Dissolution completion = permanently removed from play; the book "keeps the fiction open (brainwashing/ghoul/puppet per the campaign) — **no god framing**" | The collapsed character becomes, **forever, a puppet of the one who collapsed it** — an enemy asset the party may meet again | **MIXED** | `GAME:docs/ttrpg-update-plan.md:91` (A-13) + exclusion `:30` vs `GAME:docs/rules-addendum.md:144-149` |
| **Death & run types** | One campaign, one GM: death rules are R5's | **Run types** decide death: softcore respawn / hardcore permadeath / **Forsaken** (hardcore by nature, god-initiated) | **MIXED** (modes = IMPL; Forsaken = THEME) | exclusion `GAME:docs/ttrpg-update-plan.md:34-35` vs `GAME:docs/rules-addendum.md:603-612` |
| **Body composition** | Non-standard bodies get **GM-shaped part layouts** | **R21 Lego-style typed-part library** (base parts + 38-part animal library, each with a size range), plus a properties-filter creation UX | **IMPL** | `BOOK:...:413` vs `GAME:docs/rules-addendum.md:670-693`; exclusion `GAME:docs/ttrpg-update-plan.md:43-45` |
| **Enemy attention / targeting** | GM decides (optional sidebar suggested, not written) | **R23 Antagonism engine** — a serialized weighted-random draw per opponent, proximity base × grudge/mockery/mercy, 50/50 anchor, personality types per template | **IMPL** | `GAME:docs/rules-addendum.md:762-786`; exclusion `GAME:docs/ttrpg-update-plan.md:40-42` |
| **Feints** | Feint appears only as a CHAIN-prime example; **no read/counter rule** | **R24 feint-read**: smart mobs read feints by **Mind** through the R22 threshold machinery; a read feint is wasted and adds mock-grudge | **IMPL** | `BOOK:...:241` vs `GAME:docs/rules-addendum.md:788-809` |
| **Tactical Roll's cost** | §4.6 still gives STANCE's example shape as "**defensive footwork enabling Tactical Roll**" | **R25/G1: no stance, no charges, no cooldown** — the cost is the **movement forfeit**; it's a declared-hex dodge, with the AREA/center refinement | **IMPL** + ⚠ **book text appears stale vs its own repo's G1 ruling** | `BOOK:rulebook/gpt-system-v1.0.md:242` vs `BOOK:rulebook/skills-passover.md:7-18` and `GAME:docs/rules-addendum.md:811-869` |
| **Boss explosion beats / KO** | No such choreography (GM narrates) | Telegraph → escape window → blast → **caught = Helpless for 2 Clocks** → retreat → next Threshold; phase 6 stays data-only | **IMPL** | `GAME:docs/gdd/decision-log.md:297-308`; `GAME:docs/rules-addendum.md:386-404` |
| **Boss death routing** | Doctrine prose: "raw damage races are anti-design" | A hard engine invariant: **HP damage never touches a hidden part; death/removal routes ONLY through a lethal, exposed part** (nine bypasses closed) | **IMPL** | `BOOK:...:1278` vs `GAME:docs/gdd/decision-log.md:190-201`; `GAME:_workflow/learnings.jsonl:24` |
| **Hype / goals / camera attribution** | GM feel; the audience chapter gives structure, not rates | Deterministic hype engine with per-event weights, one active crowd goal offered at Clock resets from a salted RNG stream, `completed_by` attribution, takedown = a kill YOU caused | **IMPL** | `GAME:docs/rules-addendum.md:283-317`; exclusion `GAME:docs/ttrpg-update-plan.md:40-42` |
| **Char-sheet app vocabulary** | (the app models the book) `DMG_TYPES` migrated to the 7 resistance keys incl. Dissolution; races → Human/Animal/Robot-AI | The game repo uses the **rulebook condition taxonomy + its own seed enums**; CLAUDE.md forbids importing the app's `DMG_TYPES`/`RACES` | **IMPL** (tool drift — now largely reconciled) | drift catalogued `GAME:docs/review/review-1-ttrpg.md:91-101`; reconciliation executed `GAME:docs/ttrpg-update-plan.md:151-156` + `BOOK:CLAUDE.md` backlog §2. ⚠ The CLAUDE.md warning is now **stale in its specifics** — see §5 |
| **Compendium-era canon** | — | 20 catalogued supersessions (Corporation motive, TVTropes tag sourcing, Robot race, Boss→Patron exchange, "no respawns" absolute, 4-phase Incineradile, checkpoint-rewind as *the* death model, Patrons-as-audience, corporate Lounge…) | **MIXED** | The full table is `GAME:docs/audits/campaign-residuals-audit.md:347-370`; "never re-import" list `:481-495`; the May-era NQ1–NQ4 conflicts are all closed (`GAME:docs/review/review-5-compendium-delta.md:82-89`, rulings `GAME:docs/rules-questionnaire.md:399-415`) |
| **Data-layer residue** | — | `patron_goals.source_type` CHECK enum still reads `('Patron','Corporate','Crowd')` — the last Corporation residue in the data layer; casino re-voice `'Corporate' → 'House'` pending | **THEME** (unfinished re-skin) | `GAME:docs/audits/campaign-residuals-audit.md:329-332` |
| *(convergent, listed to prevent false alarms)* | Camera Call: self-calls legal, gains **and** losses doubled, one spotlight at a time, ends with the target's current-or-next action · Dodge thresholds ask Reflexes with a d4 fallback · Priming replaces cooldowns (5-type vocabulary) · Combined actions merge into one hit · Traits have no cap | Same rulings, same wording | **none** | `BOOK:...:903-905`, `:794+`, `:234-247`, `:338-345` vs `GAME:docs/rules-addendum.md:283-289`, `:724-760`, `:90-107`, `:547-572`; trait cap `GAME:docs/rules-questionnaire.md:482-483` |

---

## 4. Things v2 canon assumes that the TTRPG rulebook has no slot for

Verified by keyword sweep of `BOOK:rulebook/gpt-system-v1.0.md`: the words **god, gods,
casino, divinity, epithet, wager, patron god, myth** occur **nowhere** in the book except
as loot-tier names ("Mythic", "Godly" — `:683`, `:933`, `:949`, `:1168`). The book's only
"patron" is an audience donor. So every item below is machinery v2 needs and v1 never wrote:

1. **A god-side actor model.** v2 needs entities with `influence`, `power`, `generosity`,
   personality axes, domains, factions, favor conditions and taboos
   (`GAME:docs/design/patron-gods.md:152-183`). The book has no NPC-with-a-contract concept
   at all — its Patrons are a *number on a roster* (`BOOK:...:882-886`).
2. **A contract layer between a contestant and a sponsor.** Bidding, deal sheets, signing,
   buy-outs with a notice of replacement, abandonment modes, and "you cannot swap, only the
   god can" (`GAME:docs/design/patron-gods.md:25-56`). Nothing in the book binds a
   contestant to anyone; Directives are quests, not contracts.
3. **A per-god affection ledger + the multiplier boon economy.** Domain-tagged impressions
   from sim events, diffuse-vs-focused multipliers, faction spill-over, tier-odds bumps
   (`GAME:docs/design/patron-gods.md:87-124`, `:189-198`). The book's audience economy is
   three counters and a conversion story (`BOOK:...:872-890`) — there is no per-sponsor
   relationship state to hang this on.
4. **The epithet/myth-template system.** A trait vocabulary, a graded myth catalog with
   `deed_profile`s and reenactment hooks, and a matcher that fires an epithet when your
   pattern recreates a legend (`GAME:docs/design/patron-gods.md:126-150`;
   `GAME:docs/design/mythology-research-spec.md:128-144`). The book has Tags and nothing
   else identity-shaped.
5. **Table tiers as a mechanical structure.** Normal / VIP / VVIP-Forsaken with different
   stakes, different help rules and different payouts (`GAME:docs/cosmic-casino-canon.md:19-30`),
   plus `table_tier_hint` placement for entities
   (`GAME:docs/design/mythology-research-spec.md:253-258`). The book has one show, one
   broadcast, one set of rules.
6. **Forsaken as a run mode.** "All help sealed for every god" needs a *help channel* to
   seal — i.e. it only makes sense once tips/boons exist
   (`GAME:docs/design/patron-gods.md:204-221`). The book has no analogue, and the plan
   excludes it outright (`GAME:docs/ttrpg-update-plan.md:22-24`).
7. **The divinity economy and the mortal→god pipeline.** Winnings → divinity → a seat at
   the table; the winner writing 250 years of history
   (`GAME:docs/cosmic-casino-canon.md:38-46`). The book's Ascension analogue is a Lounge/NG+
   idea, not an economy with a currency the gods also spend.
8. **Rival-god intervention as a game verb.** Cross-party blessings/curses gated on
   affection (`GAME:docs/design/patron-gods.md:222-225`) and the destealth lever
   (`GAME:docs/rules-addendum.md:658-660`). The book's only third-party pressure is the GM.
9. **A depiction-policy layer.** Real living religions on screen require an
   `ip_status`/`depiction_risk`/`ship_status` discipline and named carve-outs
   (`GAME:docs/design/mythology-research-spec.md:184-244`, `:386-395`). The book never
   touches real-world belief systems and so needs none of it.
10. **Arena-as-psyche and myth-sourced bestiary provenance.** Arenas shaped by the judge
    god's mind (`GAME:docs/cosmic-casino-canon.md:76-77`) and monsters as *followers of
    gods* in three states (`:148-155`) — the book's enemy chapter is a statting guide with
    no cosmological provenance (`BOOK:...:1248+`).
11. **A second, god-facing information plane.** The book has one audience; v2 has spectators
    who hear the announcer name the god and the size of the tip, while contestants only ever
    see world manifestations (`GAME:docs/DIRECTION.md:149-163`;
    `GAME:docs/design/patron-gods.md:199-203`).
12. **Cross-party/shared-world hooks.** Cross-player patronage and wagering, ascended players
    becoming other players' patrons or myth templates
    (`GAME:docs/DIRECTION.md:43-52`; `GAME:docs/design/patron-gods.md:143-145`). The book is
    a single-table document by construction.

**INFERRED (not a ruling):** items 1–4 are also the reason KAN-7 "grew 3× with the frame
adoption" (`GAME:docs/gdd/gdd.md:376`) — the epic sizing is recorded, the causal attribution
to these four gaps is my reading.

---

## 5. Confidence notes

**High confidence.** The v2 canon ledger (§1) — every row is a dated owner ruling with a
citation, and the same rulings are cross-recorded in at least two places (DIRECTION /
design doc / GDD decision-log / memory pack) in almost every case. The divergence *intent*
(§3) is unusually well documented: `GAME:docs/ttrpg-update-plan.md:13-45` is an explicit,
owner-ruled exclusion list, so most of §3 is quoting a decision rather than reconstructing one.

**What I could not verify.**

- **Nothing was executed or tested.** This is a documentation sweep; I did not run the sim,
  the seed validator, or any test (`STATUS.md` reports 393 tests discovered and a PASS from
  its own last generation, `GAME:STATUS.md:13-18` — I did not re-run it).
- **The v1 book was only spot-read.** I read its headings, ch.1, ch.17, §4.6, and grepped it
  for every v2 keyword and for each divergence topic in §3. I did **not** read all 1,315
  lines, so §3's book-side column is complete for the topics listed, not exhaustive for the
  book as a whole. The six sibling agents reading it chapter-by-chapter will beat this.
- **The novel (*A Day of Ruin*) itself was not available** — `cosmic-casino-canon.md` says so
  in its own §8 (`:195-201`): the Forgotten Religions reference doc was never uploaded, V0.1/V0.2
  exist only via the bible, and the owner says "there's more information". Any v2 lore question
  that bottoms out in the novel cannot be answered from this repo.
- **Numbers.** Every magnitude in v2 systems is PLACEHOLDER by standing ruling (R14 /
  `GAME:docs/gdd/decision-log.md:142-145`), so I recorded no numeric canon anywhere.

**Ambiguities I flagged rather than resolved.**

- **Four "ruled twice, still listed open" conflicts** (residuals R-1 to R-5). I did not pick a
  winner. R-1 (does the table re-skin?) is the important one: the rebrand doc and the update
  plan flatly contradict each other, and the update plan is the newer, more operational
  document — but it is also marked `Status: PROPOSED (awaiting owner approval)`
  (`GAME:docs/ttrpg-update-plan.md:3`) even though its workstreams B-1/B-2/B-4 are recorded
  DONE, so its authority is genuinely unclear.
- **`GAME:CLAUDE.md`'s drift warning is stale in its specifics.** It says "Do NOT import the
  character-sheet app's DMG_TYPES/RACES lists (known drift — see review-1)". Since 2026-07-25
  the app has been migrated to the book taxonomy (7 resistance keys incl. Dissolution; races
  Human/Animal/Robot-AI) — `BOOK:CLAUDE.md` backlog §2 and `GAME:docs/ttrpg-update-plan.md:151-156`.
  The *rule* (game uses its own seed enums; the game removed Robot) still stands; the *reason*
  quoted no longer describes reality.
- **Tags.** I verified the 100 rows and the presence of all five epithet-migration keys
  directly in `GAME:data/tags.json`. Whether that state is intentional (the port deliberately
  restoring the authoritative list) or an unnoticed regression of the 07-17 pruning is not
  recorded anywhere I could find — hence R-19 is written as a question, not a bug report.
- **The Forsaken manual trigger** is the cleanest example of the doc-state problem: one log
  says CONFIRMED, three docs say ⟨PROVISIONAL⟩, and both were written by the same process on
  the same day.
- **`review-6-story.md` and `review-1-ttrpg.md` predate the frame swap** (2026-07-13/15). Their
  findings about "the Corporation", the missing production cast and the TVTropes dependency are
  still live *as problems*, but their vocabulary is v1. I cited them only where a later doc
  carries the finding forward.
