# B — The Audience (§17) & Tags (§18): v1→v2 change inventory

**Slice owner:** B. **Date:** 2026-08-10. **Scope:** rulebook §17.1–§17.7 + §18.1–§18.3 (all
100 tags), plus the two-information-planes wherever it touches audience machinery.
**Read-only research.** Every row is cited to `file:line` or `§section`; unsupported claims are
marked **INFERRED**.

**Sources of truth used**
- v1: `/home/user/Galactic-Prime-Time/rulebook/gpt-system-v1.0.md` (§17 = L868–959, §18 = L963–1119)
  + `rulebook/tags-passover.md`, `rulebook/economy-passover.md`, `rulebook/lounge-passover.md`,
  `rulebook/item-drafting-passover.md`.
- v2 canon: `/home/user/Galactic-Prime-Time-Game/docs/` — `cosmic-casino-canon.md`,
  `setting-rebrand-options.md`, `DIRECTION.md`, `design/patron-gods.md`,
  `design/mythology-research-spec.md`, `design/slice-tags-proposal.md`,
  `design/tag-reconciliation-2026-07-18.md`, `audits/campaign-residuals-audit.md`,
  `rules-addendum.md`, `gdd/gdd.md`, `narrative/narrative-design.md`, `story-canon.md`,
  `review/review-1-ttrpg.md`, `review/review-2-conversion.md`.
- v2 **live state**: `data/tags.json`, `data/tag_effects.json`, `data/crowd_goals.json`,
  `data/patron_gods.json`, `simulation/hype_engine.gd`, `simulation/tag_engine.gd`,
  `simulation/exposure_engine.gd`.

**Headline:** §17 does **not** survive as a reskin. §17.2–§17.6 (Patron Tokens, Camera Call,
Goals, Directives, Achievements) port with a re-voice; **§17.1 Exposure and §17.7 Narrative
Tokens need genuine redesign**, because v1's audience is a statistical mass and v2's is a
finite roster of named creditors. §18 is the opposite: the *machinery* survives almost intact
(v2 has already built it), and the cost is concentrated in **names** — 62 of 100 tags are
media-artifact-coded, which is survivable only because v2 canon deliberately kept a diegetic
TV skin.

---

## Summary table

| ID | Element | §/file:line | Verdict | Effort | One-line change |
|---|---|---|---|---|---|
| B-01 | **Viewers** — the mass anonymous pool | §17.1, L874–876 | **FORK** | L | Mass hype counter survives as the *broadcast plane's* number; the *economy* moves to per-god attention — two quantities, not one |
| B-02 | **Followers** — paying watchers, phone-vote money | §17.1, L877–881 | **MECHANICAL** | M | "Paying watchers" has no god analogue at that scale; re-found as devotee/standing-bet tier or fold into Viewers |
| B-03 | **Patrons** — one-time large donors, permanent roster | §17.1, L882–885 | **KEEP** (already decided) | S | Becomes donator **gods**; the mechanic already had the right name (`setting-rebrand-options.md:30-31`) |
| B-04 | **THE patron god** — singular escort above the Patrons tier | *(new)* `patron-gods.md:14-23`; `DIRECTION.md:179-183` | **NEW** | L | v1 has no singular-sponsor slot; v2 adds contract, deal sheet, buy-outs, abandonment |
| B-05 | **Decay asymmetry** (Viewers/Followers decay, Patron roster permanent) | §17.1, L876, L881, L883-885 | **KEEP** | S | Permanence rationale ("the donation already happened") maps to divinity already staked |
| B-06 | **The word "Exposure"** collides with the combat state *Exposed* | §17.1 heading; `review-1-ttrpg.md:137` (B13); `simulation/exposure_engine.gd:1-8` | **RESKIN** | S | The name is already taken *in code* by the combat state — rename the metagame term (e.g. "Standing"/"The Board") |
| B-07 | **Scale units** — "counts run in the billions" | §17.1, L874 | **MECHANICAL** | M | Billions is a broadcast-plane prop; the wager plane counts a gallery. Decide which number the player's sheet shows |
| B-08 | **Patron Tokens** — skill-cap currency + earn channels | §17.2, L890–893; §19.2 L1145–1148 | **FORK** (already forked) | S | TTRPG keeps 25 UT → 1 PT; digital cut the exchange (`rules-addendum.md:234-236`). Under gods the token is *divinity*, not fandom |
| B-09 | **Camera Call — fiction** ("the odds board turns to you") | §17.3, L895–906; `setting-rebrand-options.md:33` | **RESKIN** | S | Already proposed and recorded "unchanged mechanically" (`patron-gods.md:82`) |
| B-10 | **Camera Call — the doubling** of gains AND losses | §17.3, L900–906; `rules-addendum.md:281-289` (R11 #13) | **MECHANICAL** | M | Under named gods, "doubled" must say *whose* stake doubles: spectacle points, per-god affection, or the wager pot |
| B-11 | **Camera Call — self-call legality + the D8 exploit** | §17.3, L903–906; `review-1-ttrpg.md:164` (D8) | **MECHANICAL** | M | The odds-board reskin makes self-calling *thematically correct* (betting on yourself) — but the Patron-Token-farm exploit needs re-checking against god-affection income |
| B-12 | **Camera Call on an ALLY/ENEMY** (doubling their losses) | §17.3, L900–906 | **MECHANICAL** | S | As a camera it's spite; as an odds board it's a **hostile bet** — a different, better fiction that implies who may be targeted |
| B-13 | **"Session" = one deployment** gates Camera Call stacks | §17.3, L897–899; `rules-addendum.md:242-243` (R10/B9) | **KEEP** | S | Settled; no frame dependency |
| B-14 | **Goals** as crowd challenges → gallery **side bets** | §17.4, L908–915; `setting-rebrand-options.md:32` | **RESKIN** | S | "Unchanged mechanically" already recorded (`patron-gods.md:81`) |
| B-15 | **Paid Goals set by Patrons** | §17.4, L910; §17.1 L883 | **MECHANICAL** | M | v2 gives every paid Goal a *named issuer* with declared `favor_conditions`/`taboos` (`patron-gods.md:169-171`) — completion now also moves affection |
| B-16 | **Goal→new-Patron conversion** (the Patron-Token trigger) | §17.4, L914–915 | **MECHANICAL** | L | Converting an anonymous viewer becomes **winning a specific god off the roster** — a discrete, named, state-bearing event (bid interest, `patron-gods.md:122-124`) |
| B-17 | **Goal taxonomy** (Spectacle/Performance/Risk/Subversion) | §17.4, L910–913 | **KEEP** | S | Add a divine-taste axis; `data/crowd_goals.json` already ships 7 rows in this shape |
| B-18 | **Directives — issuer**: The Corporation™ → the house | §17.5, L917–925 | **RESKIN** | M | Ruled: "the house/dealer speaks — the fallen god running the table" (`patron-gods.md:80`; `cosmic-casino-canon.md:58-62`) |
| B-19 | **One issuer vs many competing gods** (the slice's key question) | §17.5, L917–921; `cosmic-casino-canon.md:33-34`; `patron-gods.md:222-225` | **FORK** | L | v2 splits it: **house Directives** (one issuer, table rules) vs **tips to the dealer** (many issuers, boons *and* trials, incl. rivals) — a second, adversarial quest channel v1 has no analogue for |
| B-20 | **Directive reward contract** ("Corporation pays in stuff; audience pays in belief") | §17.5, L922–923; `rules-addendum.md:237-239` (A6/R10) | **KEEP + re-voice** | S | Contract stands; the sentence needs casino vocabulary ("the house pays in comps; the gallery pays in divinity") |
| B-21 | **Refusing a Directive** is playable (SAG Dispute) | §17.5, L924–925 | **MECHANICAL** | M | Consequence author changes from corporate discipline to house displeasure + patron `trial_table` (`patron-gods.md:173`) |
| B-22 | **Followers drive Directive volume** | §17.1, L879–880 | **MECHANICAL** | M | If B-02 rewrites Followers, this driver must be re-pointed (candidate: table tier + patron `generosity`) |
| B-23 | **Achievements** as the recognition/reward channel | §17.6, L927–930 | **KEEP** | S | Frame-independent plumbing (`review-2-conversion.md:41`) |
| B-24 | **Loot-box tier named "Godly"** | §17.6, L933; `economy-passover.md:61-68` | **RESKIN** | S | Name collision: in v2 "Godly" stops being hyperbole. Either lean in (a god authored it) or rename the ladder's top |
| B-25 | **"The box knows who opened it"** (Godly) | §17.6, L950 | **KEEP** (upgraded) | S | Becomes literal under gods — free thematic win, zero mechanical change |
| B-26 | **Achievement categories** include "class/race usage" | §17.6, L929–930 | **MECHANICAL** | S | No class system exists in the book, and races were re-ruled (`rules-addendum.md` R16). v2 axis: pantheon/patron usage + myth-template progress |
| B-27 | **Achievement rewards can unlock "Tags/Tropes"** | `GPT_Master_Compendium.md:200` | **RESKIN** | S | "Tropes" carries the dead TVTropes dependency; the unlock channel itself is exactly v2's detector model |
| B-28 | **Narrative Tokens** — player interferes with the script | §17.7, L952–957 | **FORK** | L | Table: re-flavor as a **divine favor spend**. Digital: already slated for redesign/cut (`review-2-conversion.md:65`), and v2 has a ready replacement in `patron_tip` (`patron-gods.md:196-198`) |
| B-29 | **Narrative-Token hard limits** ("cannot raise the dead / change how someone feels") | §17.7, L958–959 | **MECHANICAL** | M | Under gods these are precisely the things the audience CAN do (revival is novel canon, `cosmic-casino-canon.md:118-122`) — the limits need a diegetic price, not a flat prohibition |
| B-30 | **Ascension — winning promotes you into the audience** | *(absent from §17)*; `setting-rebrand-options.md:40,44-48`; `cosmic-casino-canon.md:41-43` | **NEW** | L | The audience chapter must gain the exit door: retire → become a Patron who funds others |
| B-31 | **Rival gods bless/curse you** (a hostile audience) | *(absent from §17)*; `patron-gods.md:222-225` (Q5) | **NEW** | M | v1's audience only moves counters; v2's audience intervenes in the fight |
| B-32 | **The announcer** (Momus) | *(absent from §17)*; `cosmic-casino-canon.md:73-75`; `setting-rebrand-options.md:157` | **NEW** | M | v1's audience chapter has no host at all (production cast MISSING, `narrative-design.md:108-110`) |
| B-33 | **Cross-party wagering** (Stage 2) | `setting-rebrand-options.md:41`; `DIRECTION.md:43-51` | **NEW** | L | Other players' patrons bet on your run — the shared-world payoff of the Patrons tier |
| B-34 | **Two information planes** vs the whole of §17 | `DIRECTION.md:149-163`; `patron-gods.md:199-203` | **MECHANICAL** | M | §17 as written addresses the audience openly; v2 requires every audience effect to arrive on the diegetic plane as a System message / world manifestation |
| B-35 | **Tags → EPITHETS**: pure rename? | `setting-rebrand-options.md:38` vs `patron-gods.md:126-150` (Q2 RULED) | **FORK** (already decided) | — | **Not a rename — a fork.** Tags stay crowd labels; epithets become a separate trait/myth-recreation track. The rebrand doc's row 38 is superseded by the same-day ruling |
| B-36 | **Where a tag comes from** (table consensus / hidden conditions / TVTropes) | §18, L967–969 | **MECHANICAL** (already decided) | M | Detectors over the event log + director/audience grant (`campaign-residuals-audit.md:204-206`); TVTropes dependency killed (`gdd.md` "Tags vs epithets") |
| B-37 | **Tag lifecycle** acquired→Reinforced→Faded→Lost | §18, L970–971; §18.1 pattern 4, L982–984 | **KEEP** | S | Becomes the 0–3 `weight` dial; brand-contract drift rides it free (`story-canon.md:31-35`) |
| B-38 | **Pattern 1 — On-brand spotlight** | §18.1, L975–977 | **KEEP** | S | Shipped as resonance in `simulation/hype_engine.gd` + `data/tag_effects.json` |
| B-39 | **Pattern 2 — The Show writes for you** (goal/directive bias) | §18.1, L978–979 | **KEEP** | M | Under many gods this becomes "whose side bets you attract"; weighted draw still deferred (`rules-addendum.md:297-298`) |
| B-40 | **Pattern 3 — Patron draw** | §18.1, L980–981 | **MECHANICAL** (upgraded) | M | The pattern that gains the most: v1's "Patrons adopt contestants whose tags match their taste" *is* v2's bidding + affection ledger, already designed |
| B-41 | **Pattern 5 — the ten flagship riders** | §18.2, L997–1011 | **MECHANICAL** | M | Two of the ten (Nine Lives, Unkillable) belong to tags the owner moved to the **epithet** track — those riders are orphaned; Munchkin's rider assumes a GM |
| B-42 | **Pattern 6 — Tag gates** | §18.1, L987–988 | **KEEP** | S | Ruled in (`rules-addendum.md:709-711`); two dead requirements remain (Flashy, Catchphrase — `campaign-residuals-audit.md:169-171`) |
| B-43 | **The twelve tag domains** vs the 26-word mythology domain vocabulary | §18.1, L990–995 vs `mythology-research-spec.md:274-288` | **MECHANICAL** | M | **Two live vocabularies.** `data/tag_effects.json` uses the *mythology* words (`war`, `chaos`, `luck_gambling`), not the book's twelve. One must win, or an explicit join table must exist |
| B-44 | **The 100-tag compendium** (§18.3) | §18.3, L1014–1118 | **RESKIN** (62 names) | L | See classification below: 62 media-coded · 32 neutral · 6 already myth-friendly |
| B-45 | **Live data contradiction** — 84-tag ruling vs 100-row seed | `rules-addendum.md:708-711` vs `tag-reconciliation-2026-07-18.md:16-22`; verified in `data/tags.json` (100 rows) | **MECHANICAL** | S | The 2026-07-17 ruling (K-pop cluster removed, 5 migrated, 7 cut) was **reverted in data** by the 2026-07-18 port; only the 7 renames survive |
| B-46 | **Fourth Wall / Fan Service / Parasocial** vs the two planes | §18.3 L1057, L1100, L1097; `DIRECTION.md:149-159` | **MECHANICAL** | M | These tags require a contestant who *knows* there is an audience — the two-planes rule says they can't hear it. Needs a ruling on what contestants know |

**46 findings. Verdict counts:** KEEP 11 (incl. 1 KEEP+re-voice) · RESKIN 7 · MECHANICAL 18 ·
FORK 5 · NEW 5 · CUT 0.
**Effort:** S 19 · M 18 · L 8 (one row, B-35, is a settled-decision record with no effort).

---

## Findings

### B-01 — Viewers, the mass anonymous pool (§17.1, gpt-system-v1.0.md:874–876)

- **v1 (alien):** "Entire galaxies are watching." Viewers are **active watchers, counts in the
  billions**, correlating with reward potential and session chaos; they are the **conversion
  pool for Followers** and they **decay when you're boring**. The compendium reads them as
  momentum: "Viewers = hype momentum via a rolling performance curve"
  (`GPT_Master_Compendium.md:342`).
- **v2 (gods):** The audience is a **finite roster of named gods** with declared domains,
  personality axes, `favor_conditions` and `taboos` (`patron-gods.md:152-182`;
  `mythology-research-spec.md:91-103`), whose numbers are bounded by design — **MVP patron
  roster: 24 gods** (`mythology-research-spec.md:366-368`). "Billions of anonymous watchers"
  has no referent; the fiction that *does* survive is the **odds board** — an aggregate of
  bets, not of eyeballs.
- **Verdict:** **FORK.** **Effort:** L.
- **Why:** A hype curve is a *crowd-psychology* instrument: it works because no individual
  matters, momentum is continuous, and the number can move without anyone deciding anything.
  A god gallery is the opposite on all three counts — each member is individually modelled,
  their attention is allocated not accumulated, and every movement is a decision by a named
  agent. Keeping one number for both jobs would either (a) make gods behave like a fluid, or
  (b) make the meter jerk discretely 24 times per run. The clean fork: **Viewers stay the
  broadcast plane's spectacle meter** (already built, deterministic, inside `state_hash` —
  `gdd.md:277-281`), and the **economy** moves to per-god affection ledgers
  (`patron-gods.md:177-182`). The hype meter feeds affection; it stops *being* the currency.
- **Already decided?** Partly. The hype meter is shipped v1 (`gdd.md:277-281`); per-god
  affection ledgers are RULED (`patron-gods.md:227-248` Q8). The **relationship between them**
  — hype as the input to affection — is **INFERRED**, not written anywhere I could find.
- **Open question for the owner:** does the player's sheet still show a viewer count, or does
  the god gallery replace it entirely on the contestant's HUD?

### B-02 — Followers, the paying watchers (§17.1, gpt-system-v1.0.md:877–881)

- **v1:** "**paying watchers**, at phone-vote money: they pay a little to follow you… follower
  counts track the percentage of watchers who'd actually pay to vote." They affect **TV rating
  and Directive volume**, are potential allies and enemies, and **decay**.
- **v2:** There is no phone-vote tier in the casino. The canon monetary layer is **tipping the
  dealer** (`cosmic-casino-canon.md:33-34`) — boons, buffs, items, or hindering rivals with
  trials, monsters, curses. That is Patron behaviour, not Follower behaviour. The one v2 group
  that resembles a mid-tier paying public is **followers of gods** — the monsters, in three
  states (Insane / Sane / Worshipped, `cosmic-casino-canon.md:150-155`) — but those are
  *enemies and NPCs*, not spectators. **The Follower tier is the single most orphaned piece of
  §17.**
- **Verdict:** **MECHANICAL.** **Effort:** M.
- **Why:** The tier's mechanical job is a **stabilised reward floor** ("Followers = stabilized
  reward floor", `GPT_Master_Compendium.md:342`) and a **Directive-volume driver** (L879-880).
  Both jobs are real and worth keeping; the *fiction* is what dies. Three candidate re-foundings,
  in decreasing fidelity: (1) **standing bets** — gods who have money on you across runs, so
  they keep paying attention (keeps "paying," keeps decay, keeps the floor); (2) **devotees** —
  mortal worshippers of your patron, a downstream audience your patron farms (keeps the
  conversion ladder, adds a reason the patron cares); (3) **cut the tier** and let the ladder
  read Viewers → Patrons, folding the reward floor into patron `generosity`.
- **Already decided?** No. The GDD still prints the three-tier ladder verbatim
  (`gdd.md:268-269`) and `narrative-design.md:140` repeats it — but neither says what a god
  Follower *is*. Recommendation (1) is **INFERRED**.
- **Open question for the owner:** does the middle tier survive at all, and if so, is a
  "Follower" a small god or a mortal worshipper?

### B-03 — Patrons, the permanent donor roster (§17.1, gpt-system-v1.0.md:882–885)

- **v1:** "**one-time large donors** (the streamer-gets-$5,000 tier of the galaxy). Can set
  paid Goals… Because the donation already happened, **the Patron roster is permanent**."
- **v2:** RULED — the Patrons tier **is** the donator gods: "gods who buy you things —
  donators. Any number of them; they tip the dealer on your behalf, gift comps, place side
  bets. This IS the existing Viewers → Followers → Patrons ladder with gods at the top"
  (`patron-gods.md:16-20`). The rebrand doc calls the mapping word-for-word: "the mechanic
  already has the right name" (`setting-rebrand-options.md:30-31`).
- **Verdict:** **KEEP.** **Effort:** S.
- **Why:** Permanence has a *better* justification under gods than under streamers: divinity
  staked at the table is committed, and canon says a god's standing rides on its bets
  (`cosmic-casino-canon.md:38-46`). The one nuance: v1 permanence means "never lose a Patron,"
  while v2 adds **abandonment modes** — extraction or neglect (`patron-gods.md:52-56`) — which
  is *not* removal from the roster but is functionally a dead patron. The book's flat
  "permanent" should be re-worded to "permanent on the roster; not permanently generous."
- **Already decided?** Yes — `patron-gods.md:14-23`, `DIRECTION.md:179-183` (D5), `gdd.md:268`.
- **Open question for the owner:** none blocking; only the wording nuance above.

### B-04 — THE patron god: a new singular tier above Patrons (patron-gods.md:14-23)

- **v1:** No such slot. §17.1's ladder tops out at a plural donor list.
- **v2:** A **singular escort** — "the one god who escorts you through the campaign — directs
  the *types of bets* running on you, shapes your run's wager profile, and is usually your
  **biggest donator**" (`patron-gods.md:20-23`). Around it: background-driven bidding with deal
  sheets, the ORV "only the patron-less may choose" rule, buy-outs with a notice of
  replacement, abandonment as extraction-or-neglect, Forsaken as god-initiated all-in
  (`patron-gods.md:25-56, 204-221`).
- **Verdict:** **NEW.** **Effort:** L.
- **Why:** This is the largest single addition to the audience chapter and it is *not* a
  reskin of anything in §17 — v1's audience has no member who is contractually yours. It also
  changes the reading of every other §17 mechanic: a Goal is now issued by *someone*, a
  Directive competes with *your* god's preferences, and Camera Call raises the stakes on a
  relationship rather than on a statistic.
- **Already decided?** Yes, thoroughly — Q1–Q8 all RULED 2026-07-16 (`patron-gods.md:227-248`),
  recorded in `DIRECTION.md:179-196` (D5). Do not re-litigate.
- **Open question for the owner:** where does the patron contract live in the *book*? §17 has
  no home for it; it either becomes §17.0 (the new top of the chapter) or a new §17.8.

### B-05 — Decay asymmetry (§17.1, gpt-system-v1.0.md:876, 881, 883–885)

- **v1:** Viewers decay when you're boring; Followers decay (they stop paying); the Patron
  roster never decays.
- **v2:** RULED at the questionnaire level and unchanged: "decay hits Viewers/Followers (they
  stop paying), never the Patron list" (`rules-questionnaire.md:458-461`, Q34–Q36 RULED).
- **Verdict:** **KEEP.** **Effort:** S.
- **Why:** The asymmetry is the design's spine — attention is rented, commitment is owned —
  and it survives the frame swap unchanged. The only edit is B-03's wording nuance.
- **Already decided?** Yes (`rules-questionnaire.md:458-461`).
- **Open question for the owner:** none.

### B-06 — "Exposure" is a name collision (§17.1 heading; review-1-ttrpg.md:137; simulation/exposure_engine.gd:1-8)

- **v1:** The chapter's metagame term is **Exposure**; the combat state is **Exposed**. Review-1
  flagged the collision explicitly (B13: "its text collides the *Exposure* metagame term with
  the *Exposed* combat state").
- **v2:** The collision is now **load-bearing in code**: `simulation/exposure_engine.gd` is the
  **combat** Exposed-state helper (`exposure_engine.gd:1-8`), so the audience system can never
  claim that name in this codebase.
- **Verdict:** **RESKIN.** **Effort:** S.
- **Why:** The rebrand is the free moment to fix it — the casino supplies better words that
  are already in use elsewhere in the canon: **the Board** / **Standing** / **the Line**
  (`setting-rebrand-options.md:33` already uses "odds board"). Renaming costs one heading and
  a handful of cross-references (§3.2 L129, §17.3, §18.1 L977) and permanently unblocks a
  code-vs-book vocabulary conflict.
- **Already decided?** No. The collision is *recorded* (review-1 B13) but never ruled.
- **Open question for the owner:** rename §17.1 to "Standing" (or similar), or keep "Exposure"
  and accept that the engine class name means something else?

### B-07 — Scale units: billions vs a gallery (§17.1, gpt-system-v1.0.md:874)

- **v1:** "Counts run in the billions, easily." The number is a *prop* — it exists to make the
  stakes feel cosmic, and the GM keeps the actual numbers ("Session-to-session numbers stay in
  the GM's hands; the structure above is the contract", L887-888).
- **v2:** Two audiences now exist at different scales. Canon: **VIP tables host 1 to a billion
  contestants** (`cosmic-casino-canon.md:24`) and the *watching* layer is gods plus whatever
  mortal spectacle the framework produces. The wager plane is small and named; the broadcast
  plane can still be vast.
- **Verdict:** **MECHANICAL.** **Effort:** M.
- **Why:** This is the concrete form of B-01. The honest resolution is that **§17.1's numbers
  are broadcast-plane set dressing** and the *economy* is the god ledger — which is exactly
  what the two-information-planes rule would predict (`DIRECTION.md:149-159`).
- **Already decided?** No. **INFERRED** from B-01 + the planes rule.
- **Open question for the owner:** see B-01.

### B-08 — Patron Tokens (§17.2, gpt-system-v1.0.md:890–893; §19.2 L1145–1148)

- **v1:** Earned when a **Goal converts a new Patron**, and from the exchange; spent to raise a
  skill cap past 5, +1 max level per token, ceiling 10 (§4.2 / §3.2 L173). The exchange is
  **25 Upgrade Tokens → 1 Patron Token, one-way** (§19.2 L1147), post-`economy-passover.md`
  GC0 which retired Boss Tokens (`economy-passover.md:11-19`).
- **v2:** The digital game **cut the exchange** — "Patron Tokens come only from the audience
  loop… the exchange bypassed the flagship system and ignored token tiers"
  (`rules-addendum.md:234-236`, R10/D7). Under gods, the token stops being fandom currency and
  becomes **divinity**: canon says winners take wagered currency, gain divinity, and join the
  table (`cosmic-casino-canon.md:41-43`).
- **Verdict:** **FORK** (already forked, deliberately). **Effort:** S.
- **Why:** The two products have different economies on purpose — the TTRPG keeps an overflow
  valve because a GM can price it; the digital game protects the flagship loop. Nothing about
  the god frame changes that split. What *does* change is naming: "Patron Token" is a
  fandom-shaped word for what is now a shard of divinity. Renaming it (e.g. **Divinity**,
  **Marker**) is free and would also fix the mild oddity of Patron Tokens buying *skill caps*
  rather than patron favour.
- **Already decided?** The fork: yes (`rules-addendum.md:234-236` vs `rulebook §19.2`; the
  digital cut is confirmed still standing at `rules-questionnaire.md:479-481`). The rename:
  no — **INFERRED**.
- **Open question for the owner:** rename Patron Tokens under the casino frame, or keep the
  word because the Patrons tier keeps its name?

### B-09 — Camera Call, the fiction (§17.3, gpt-system-v1.0.md:895–906)

- **v1:** Charm past 10 earns Camera Call stacks; each stack is one use per session (= one
  dungeon deployment). "The camera focuses a target."
- **v2:** RULED reskin — "**The odds board turns to you** — all stakes on you double"
  (`setting-rebrand-options.md:33`), and the patron design records it as "**unchanged
  mechanically**" (`patron-gods.md:82`). GDD repeats it (`gdd.md:282-283`).
- **Verdict:** **RESKIN.** **Effort:** S.
- **Why:** The mechanic is a *stake multiplier with two-sided risk*; nothing in it depends on
  a literal camera. The odds board is a strictly better metaphor for a mechanic whose defining
  property is that losses double too.
- **Already decided?** Yes — `setting-rebrand-options.md:33`, `patron-gods.md:82`,
  `gdd.md:282-283`.
- **Open question for the owner:** does the *name* change with the fiction ("Call the Board"),
  or does "Camera Call" survive as show-diegetic vocabulary (which the VIP-table ruling
  permits, `setting-rebrand-options.md:114-119`)?

### B-10 — Camera Call, what "doubled" means under named gods (§17.3, L900–906; rules-addendum.md:281-289)

- **v1:** "**Viewership, Follower, and Patron gains AND losses from that target are doubled**"
  until the end of that target's current or next action. Q37 RULED identically
  (`rules-questionnaire.md:462-464`).
- **v2:** The digital engine already had to narrow this: R11 #13 reads it as "*spectacle points
  attributed to the spotlit combatant are doubled*", with cross-referencing who **caused** the
  spotlit combatant's drama deferred to v2 (`rules-addendum.md:281-289`). Under gods there is a
  third quantity in play that v1 never had: **per-god affection** (`patron-gods.md:177-182`),
  and a fourth: the size of the pot riding on you.
- **Verdict:** **MECHANICAL.** **Effort:** M.
- **Why:** "Doubled" now has three plausible referents and they behave differently. Doubling
  *spectacle points* is a broadcast effect (safe, shipped). Doubling *affection swings* makes
  the spotlight a relationship accelerant — and, given taboos, a relationship **destroyer**
  when you fail on the board. Doubling *the pot* is the most faithful to "all stakes on you
  double" but implies a wager-size model the game does not have yet. The mechanic survives the
  reskin intact only if the answer is "spectacle points"; the odds-board fiction pulls toward
  "the pot," and that is a genuine mechanical change, not a reskin.
- **Already decided?** Partly — the sim's reading is recorded as PROVISIONAL
  (`rules-addendum.md:251`, R11 header). The affection/pot readings are **INFERRED**.
- **Open question for the owner:** **the load-bearing one for §17.3** — when the board turns to
  you, what exactly doubles: the spectacle points, the affection you gain/lose with every
  watching god, or the wager itself?

### B-11 — Camera Call self-targeting and the D8 exploit (§17.3, L903–906; review-1-ttrpg.md:164)

- **v1:** "**Self-calls are legal** — spotlighting yourself is the Charm build's play."
  Review-1 flagged D8: self-targeting "plausibly doubles Patron-Token income timed to Goal
  completions; currently unreachable only because Charm 20 is unreachable — two defects
  cancelling is its own smell."
- **v2:** Charm 20 is now reachable — traits have **no cap** (`rules-questionnaire.md:482-483`,
  Q5 RULED 2026-07-23: the 10/12/15/20 marks are repeating milestones, not ceilings). So the
  defect that was cancelling D8 is **gone**, and D8 is live.
- **Verdict:** **MECHANICAL.** **Effort:** M.
- **Why:** Two things changed at once. (a) The cancelling defect was removed by an unrelated
  ruling, so the exploit is now reachable in both products. (b) The exploit's *shape* changes
  under gods: if B-16 is right that Patron conversion is a discrete roster event, you cannot
  farm it by repetition — the god either joins your list or does not, and there is a finite
  supply. That may fix D8 for free, which is a genuinely good argument for the god frame.
- **Already decided?** No. D8 remains open (marked ⬜ in `review-1-ttrpg.md:164`; not addressed
  in R10 or R11 #13).
- **Open question for the owner:** with Charm uncapped, does a Charm-stacked self-caller
  double-dip on Patron acquisition — and does the finite god roster fix it, or does it need a
  per-session cap?

### B-12 — Calling the board on someone else (§17.3, L900–906)

- **v1:** The spotlight can be placed on any target; the doubling covers that target's gains
  **and losses**. As a camera, calling it on an ally to amplify their humiliation is spite;
  calling it on an enemy is showmanship.
- **v2:** As an **odds board**, the same act reads as raising the stakes on someone else's
  performance — a **bet placed by a contestant**, which is a fictionally richer object.
  Canon supports contestants being bet-adjacent (Marcus's HUD has a "**Current Bet** (live
  wagers affecting you)" tab, `cosmic-casino-canon.md:165`).
- **Verdict:** **MECHANICAL.** **Effort:** S.
- **Why:** The target-selection rule doesn't change, but the *reason* to use it does, and that
  changes tuning. Under the camera reading, hostile calls are a griefing corner case. Under the
  board reading, hostile calls are a core play — you are shorting a rival — which argues for
  authored consequences (does the target know? does their patron notice?).
- **Already decided?** No. **INFERRED** from `setting-rebrand-options.md:33` +
  `cosmic-casino-canon.md:165`.
- **Open question for the owner:** is a contestant-placed hostile call a supported strategy or
  an edge case?

### B-13 — "Session" = one deployment (§17.3, L897–899; rules-addendum.md:242-243)

- **v1:** Ambiguity flagged as B9 (`review-1-ttrpg.md:133`) — real-world session vs broadcast
  episode never stated; §17.3 resolves it in-book: "a session = **one dungeon deployment**
  (leave the Lounge → return, extract, or die)."
- **v2:** R10 settles the same shape (`rules-addendum.md:242-243`).
- **Verdict:** **KEEP.** **Effort:** S. **Why:** No frame dependency.
- **Already decided?** Yes, both sides. **Open question:** none.

### B-14 — Goals become side bets from the gallery (§17.4, L908–915)

- **v1:** "Issued by the audience for rewards + crowd favor," in four families
  (Spectacle / Performance / Risk / Subversion), rewards flowing through the Achievement system.
- **v2:** RULED mapping — "Goals (crowd challenges) → **Side bets from the gallery**"
  (`setting-rebrand-options.md:32`), recorded as "unchanged mechanically"
  (`patron-gods.md:81`). The engine already ships them: one active goal, offered at Clock
  resets, seven rows in `data/crowd_goals.json`, deterministic RNG stream
  (`rules-addendum.md:290-296`, R11 #14).
- **Verdict:** **RESKIN.** **Effort:** S.
- **Why:** A goal is a conditional payout on a described behaviour. That is *literally* a side
  bet; the reskin costs the flavour text and nothing else.
- **Already decided?** Yes. **Open question:** none.

### B-15 — Paid Goals get a named issuer (§17.4, L910; §17.1, L883)

- **v1:** "Patrons… can set paid Goals (direct story intervention + rewards)." The Patron is a
  faceless whale; the Goal is a bought moment.
- **v2:** Every god carries a declared taste profile — `domains`, `favor_conditions` (the DOs),
  `taboos` (the DON'Ts), `temperament`, `boon_table`, `trial_table`
  (`patron-gods.md:158-174`), plus five personality axes that are explicitly **generator
  inputs** for deal sheets (`mythology-research-spec.md:290-301`). The SQLite schema already
  anticipates the join: a `patron_goals.tag_id` FK (`campaign-residuals-audit.md:33`).
- **Verdict:** **MECHANICAL.** **Effort:** M.
- **Why:** The mechanic gains a second output. In v1 a paid Goal pays *you*. In v2 it also
  **moves affection** — completing Ares's paid Goal is a deed in Ares's ledger, and refusing or
  failing it can trip a taboo. That is not a reskin; it is a new edge in the graph, and it is
  the mechanism by which the audience stops being a vending machine (`narrative-design.md:139`
  makes exactly this point about factions).
- **Already decided?** The affection machinery: yes (`patron-gods.md:185-198` rules 1–3). That
  *Goals* feed it: **INFERRED** (the design says "domain-tagged impressions… derived from sim
  events", which a goal completion is, but no document says "goal completion is an impression").
- **Open question for the owner:** does completing a god's paid Goal grant affection with that
  god specifically, or only the generic payout?

### B-16 — Goal→Patron conversion, the Patron-Token trigger (§17.4, L914–915)

- **v1:** "**A Goal that converts a viewer into a new Patron awards a Patron Token.**" A
  statistical event: somewhere in the billions, one whale opened their wallet.
- **v2:** Conversion is now **acquiring a named god from a finite roster** — which the design
  already models as **buy-out interest**: "What non-patron affection buys: a higher chance those
  gods give you things (donator tips), and it **raises buy-out interest**"
  (`patron-gods.md:122-124`).
- **Verdict:** **MECHANICAL.** **Effort:** L.
- **Why:** This is the sharpest place the mass→named change bites. Four consequences:
  (1) **Supply is finite.** You cannot farm conversions; there are 24 gods in the MVP roster
  (`mythology-research-spec.md:366-368`). Patron Tokens therefore stop being an income stream
  and become **milestones** — which may be *good* (it kills D8, B-11) or may starve the skill-cap
  economy (§4.2's caps past 5 are gated on them).
  (2) **Conversion becomes stateful.** A god you nearly converted is a relationship, not a
  rounding error — which is exactly `affection` (`patron-gods.md:177-182`).
  (3) **Conversion becomes reversible-ish.** v1 says the roster is permanent; v2 adds
  abandonment (`patron-gods.md:52-56`).
  (4) **It collides with the patron-god layer.** If Goals convert gods to your Patron list, and
  bidding/buy-outs also move gods onto your list, the two systems need one door, not two.
- **Already decided?** The buy-out/affection machinery: yes. **That Goals are a conversion
  channel into it: not decided** — the digital game explicitly deferred it ("Goals pay HYPE
  only — the Patron conversion + Patron-Token reward channel (R10) is KAN-7 scope",
  `rules-addendum.md:295-296`).
- **Open question for the owner:** **the load-bearing one for §17.4** — with a finite god
  roster, does a Goal still *convert* a Patron (and thus mint Patron Tokens), or does it only
  raise affection, with Patron Tokens minted some other way?

### B-17 — Goal taxonomy (§17.4, L910–913)

- **v1:** Spectacle (Finish Fast, Overkill, Environmental Kill) · Performance (Play into a Tag,
  Say the Line) · Risk (While Exposed, Without Healing, Solo) · Subversion (Spare the Enemy,
  Betray Expectations). Fuller list at `GPT_Master_Compendium.md:190-192`.
- **v2:** Ported and shipped: `data/crowd_goals.json` carries seven rows across four kinds
  plus the three approved additions (Pratfall! / Body Block! / Zoomies! —
  `slice-tags-proposal.md:375`).
- **Verdict:** **KEEP.** **Effort:** S.
- **Why:** The four families are frame-neutral descriptions of contestant behaviour. What v2
  *adds* is a fifth axis the taxonomy doesn't have: **divine taste** — a war god's side bet and
  a trickster's side bet want different rows. That is content authoring on top of a stable
  taxonomy, not a taxonomy change.
- **Already decided?** Taxonomy: yes. Divine-taste axis: **INFERRED** (implied by
  `patron-gods.md:81` + `mythology-research-spec.md:274-288`).
- **Open question for the owner:** should goal rows carry a `domains` field so a god's side
  bets can be drawn from its own domains?

### B-18 — Directives: the issuer changes (§17.5, L917–925)

- **v1:** "Issued by **The Corporation and its subsidiaries**." Refusal is playable;
  "Consequences are the Corporation's to write."
- **v2:** RULED — "Directives (quests from the power that runs the show) → **The house/dealer
  speaks** — the fallen god running the table" (`patron-gods.md:80`). Who runs games is canon:
  **fallen, bankrupt gods of forgotten religions**, with explicit "anything goes" licence
  (`cosmic-casino-canon.md:58-62`), and the narrative doc names the house as the faction that
  "speaks only through Directives and System messages (the one legitimate in-fiction HUD
  channel)" (`narrative-design.md:137-138`).
- **Verdict:** **RESKIN.** **Effort:** M (M not S because the *word* "corporate" is load-bearing
  in the §17.5 heading, in tag names, and in the reward-contract sentence).
- **Why:** The mechanic — an optional, risky, unguaranteed quest from the power that runs the
  show — is unchanged. Only the letterhead changes. Note the deep irony the canon supplies for
  free: the biggest investors *are* corporations (modern religions as investor institutions,
  `cosmic-casino-canon.md:47-56`), so "corporate quest" can survive as a *joke that is now
  true* rather than a frame residue.
- **Already decided?** Yes (`patron-gods.md:80`, `narrative-design.md:137-138`).
- **Open question for the owner:** does the §17.5 heading become "Directives (house quests)",
  or does "corporate" survive because the holding-company canon makes it literal?

### B-19 — One issuer vs many competing gods (§17.5, L917–921; cosmic-casino-canon.md:33-34)

- **v1:** **One issuer.** The Corporation and its subsidiaries hand down Directives; the
  audience separately offers Goals. Two channels, two voices, no conflict between issuers is
  ever modelled.
- **v2:** **Two structurally different issuer classes.** (a) The **house** — one fallen god
  running the table, whose Directives are the table's script (`patron-gods.md:80`). (b) **Tips
  to the dealer** — canon's actual patron-influence mechanism: "at every non-Forsaken table,
  gods can tip the dealer to help their luck — **boons, buffs, items**, or hindering others with
  **trials, monsters, curses**" (`cosmic-casino-canon.md:33-34`). Rival gods can bless or curse
  your party, gated on affection (`patron-gods.md:222-225`, Q5 RULED). And the rebrand doc maps
  Directives to "**Wagers & divine challenges**" (`setting-rebrand-options.md:31`) while a later
  note maps *both* Directives and Goals to "tips to the dealer"
  (`setting-rebrand-options.md:131-132`) — those two mappings are not the same claim.
- **Verdict:** **FORK.** **Effort:** L.
- **Why:** This is my slice's second load-bearing answer. **Yes — the issuer change changes the
  mechanic's shape.** A single-issuer quest channel is a *script*: it can be balanced, it can be
  refused at a known cost, and its consequences are authored by one author. A many-issuer
  channel is a *market*: challenges arrive from parties with conflicting interests, the same
  action can please one issuer and trip another's taboo, and "refusing" is no longer a binary
  because someone else is always offering. Concretely, v2 gains three things v1's §17.5 has no
  rules for:
  1. **Conflicting simultaneous demands** — your patron's `favor_conditions` vs the house's
     Directive vs a rival's curse-bait. v1 never has two authorities wanting opposite things.
  2. **Hostile quests.** A rival's tip is a *trial* aimed at you (`patron-gods.md:173`
     `trial_table`). v1's Directives are indifferent, never adversarial-by-author.
  3. **Refusal becomes cheap.** With many issuers, refusing one is a routing decision, not a
     defiance. v1's SAG-Dispute drama depends on there being nowhere else to go.
  The honest design: keep §17.5 as the **house channel** (one issuer, scripted, refusable at a
  known cost — the v1 mechanic intact) and add a **separate patron-tip channel** with its own
  rules, rather than letting many gods issue Directives. That preserves what §17.5 is good at
  and gives the market behaviour its own home.
- **Already decided?** The pieces are (`cosmic-casino-canon.md:33-34`; `patron-gods.md:80,
  196-198, 222-225`); the **two-channel split itself is INFERRED** — no document states that
  house Directives and patron tips are distinct systems, and `setting-rebrand-options.md:131-132`
  arguably merges them.
- **Open question for the owner:** **the load-bearing one for §17.5** — is a patron's tip a
  *Directive* (same system, many issuers) or a separate channel alongside Directives?

### B-20 — The Directive reward contract (§17.5, L922–923; rules-addendum.md:237-239)

- **v1:** "**Rewards: tiered loot via the Achievement system** — one reward contract per system:
  the Corporation pays in stuff; the audience pays in belief." This sentence is the fix for
  review-1's A6 (three contradictory Directive reward contracts, `review-1-ttrpg.md:122`), and
  it matches R10's ruling: "Directives award tiered loot (achievement channel); **Goals** that
  convert a Patron award Patron Tokens" (`rules-addendum.md:237-239`).
- **v2:** The contract holds; the sentence needs casino vocabulary. Canon supplies it directly —
  the house comps (`setting-rebrand-options.md:36`, the Lounge as the comp suite) and the gallery
  pays in divinity (`cosmic-casino-canon.md:38-43`).
- **Verdict:** **KEEP + re-voice.** **Effort:** S.
- **Why:** "Belief" is *already* the right word under gods — more right than it was under
  aliens. The only edit is "Corporation"→"house."
- **Already decided?** Yes (`rules-addendum.md:237-239`). **Open question:** none.

### B-21 — Refusing a Directive (§17.5, L924–925)

- **v1:** "Refusing a Directive is playable (see the SAG Dispute tag). Consequences are the
  Corporation's to write." Q39 asked the table what actually happens on refusal
  (`rules-questionnaire.md:220-223`) — still unanswered.
- **v2:** The consequence author changes: the displeased party is the **house** (a fallen god
  with "anything goes" licence, `cosmic-casino-canon.md:60-62`) and, indirectly, your **patron**,
  whose displeasure has *ruled shapes*: extractive mode ("trials to max out on you even if you
  break") or total neglect (`patron-gods.md:52-56`), plus a `trial_table` of authored
  punishments (`patron-gods.md:173`).
- **Verdict:** **MECHANICAL.** **Effort:** M.
- **Why:** v2 turns "the GM writes something" into a bounded generator: refusal → displeasure →
  a draw from a declared trial table, scaled by `wrath` and `strictness`
  (`mythology-research-spec.md:294-299`). That is a real improvement and a real change: the
  consequence stops being fiat and starts being data. It also interacts with B-19 — with many
  issuers, refusing the house may *please* a rival.
- **Already decided?** The patron side: yes. The house side: no — no document says what
  refusing a *house* Directive costs.
- **Open question for the owner:** what does the house do when you refuse it — and can a rival
  god reward you for it?

### B-22 — Followers drive Directive volume (§17.1, L879–880)

- **v1:** Follower counts "affect TV rating and **Directive volume**."
- **v2:** If the Follower tier is re-founded or cut (B-02), this driver loses its input.
  Candidate replacements that already exist as data: **table tier** (Normal/VIP/VVIP —
  `cosmic-casino-canon.md:21-25`), patron **`generosity`** and **`power`**
  (`patron-gods.md:158-161`), and the hype band (`gdd.md:277-281`).
- **Verdict:** **MECHANICAL.** **Effort:** M.
- **Why:** It is a small rule with a dependency on the one tier that doesn't survive cleanly.
  Worth listing separately so the Follower decision doesn't silently orphan it.
- **Already decided?** No. **INFERRED.**
- **Open question for the owner:** what sets how often the house gives you work?

### B-23 — Achievements as the reward channel (§17.6, L927–930)

- **v1:** "The GM's recognition system: Scenario/Quest completion, class/race usage, Directives,
  Goals." Rewards: Buffs, Unlocks, Items, Abilities (`GPT_Master_Compendium.md:199`).
- **v2:** Unchanged in kind; review-2 rates "loot tiers, achievements, directives/goals *as
  reward plumbing*" as low-difficulty direct conversion (`review-2-conversion.md:41`). The
  canon HUD even keeps mocking achievements as a voice feature
  (`cosmic-casino-canon.md:160-163`).
- **Verdict:** **KEEP.** **Effort:** S. **Why:** Frame-independent plumbing.
- **Already decided?** Effectively yes. **Open question:** none.

### B-24 — The "Godly" box tier collides with actual gods (§17.6, L933, L950)

- **v1:** Six tiers — Bronze · Silver · Gold · Legendary · Mythic · **Godly** ("defying fate,
  almost never given"). Ruled content shapes at `economy-passover.md:61-68` and reprinted in
  the book at L943–950.
- **v2:** The rebrand maps boxes to "**Jackpots & comps**; Lounge box-opening = the prize floor"
  (`setting-rebrand-options.md:35`). But two tier names now mean something specific in the
  fiction: **Mythic** (myth is the epithet track's raw material —
  `mythology-research-spec.md:260-269`) and **Godly** (gods are the audience). Canon also
  constrains loot's *feel*: "loot must feel like remnants of belief, never generic stat sticks"
  (`cosmic-casino-canon.md:156-159`), with God Relics vs Follower Relics as the two classes.
- **Verdict:** **RESKIN.** **Effort:** S.
- **Why:** Two clean options, and one is nearly free. (a) **Lean in:** a Godly box is a **God
  Relic** and a Mythic box is a **Follower Relic** — the canon loot taxonomy maps onto the top
  two tiers with no mechanical change. (b) **Rename** the ladder's top to avoid the collision.
  (a) is strictly better: it converts a naming problem into canon alignment.
- **Already decided?** The loot-feel rule: yes (`cosmic-casino-canon.md:156-159`). The tier
  mapping: **INFERRED**.
- **Open question for the owner:** map Godly→God Relic and Mythic→Follower Relic, or keep the
  tiers as abstract rarity and let relics be a cross-cutting flavour?

### B-25 — "The box knows who opened it" (§17.6, L950)

- **v1:** Godly boxes are "Never random. One-of-a-kind, authored, fate-defying. **The box knows
  who opened it.**" A nice piece of menace with no explanation.
- **v2:** It becomes literal: a god chose you. Canon has the exact machinery — patron tips
  arrive diegetically as "a comp package in the loot drop, an inexplicable kindness of the
  dungeon" (`patron-gods.md:199-203`).
- **Verdict:** **KEEP** (upgraded). **Effort:** S.
- **Why:** Zero mechanical change; the frame swap retroactively explains an existing line. Worth
  recording because it is evidence for how well §17.6 survives.
- **Already decided?** Yes, implicitly (`patron-gods.md:199-203`). **Open question:** none.

### B-26 — Achievement categories reference classes and races (§17.6, L929–930)

- **v1:** Categories include "**class/race usage**." There is no class chapter anywhere in the
  book (verified: no `## Class` heading in `gpt-system-v1.0.md`), and races are a §2-era concept.
- **v2:** Races were re-ruled — **Earth-life only**, with background-granted skills
  (`rules-addendum.md` R16, heading at :574). The natural v2 axes for "usage" achievements are
  **pantheon/patron usage** (play under Ares; win with a trickster patron) and **myth-template
  progress** (`patron-gods.md:130-139`).
- **Verdict:** **MECHANICAL.** **Effort:** S.
- **Why:** A pre-existing v1 defect (dangling "class") that the frame swap gives a better answer
  to rather than inheriting.
- **Already decided?** R16 yes; the replacement axes **INFERRED**.
- **Open question for the owner:** replace "class/race usage" with "patron/pantheon usage +
  myth-template progress"?

### B-27 — Achievements can unlock "Tags/Tropes" (GPT_Master_Compendium.md:200)

- **v1:** Reward category "Unlocks (loot types, Directives, **Tags/Tropes**, Goals,
  opportunities)."
- **v2:** "Tropes" is the TVTropes dependency by another name, and it is dead canon —
  "TVTropes is not an authority" (`campaign-residuals-audit.md:357`). But *achievement-unlocks-a-tag*
  is precisely v2's shipped model: `unlock_conditions` = event predicates, achievement-style
  detection (`campaign-residuals-audit.md:204-206`), implemented in
  `simulation/tag_engine.gd` with per-tag detectors in `data/tag_effects.json`.
- **Verdict:** **RESKIN.** **Effort:** S.
- **Why:** Drop the word "Tropes," keep the channel — the channel is the v2 answer to §18's
  acquisition problem.
- **Already decided?** Yes (`campaign-residuals-audit.md:204-206`; `slice-tags-proposal.md:367-386`
  RULED). **Open question:** none.

### B-28 — Narrative Tokens (§17.7, L952–959)

- **v1:** "Let players interfere with the script. Earned via crowd donations, corporate rewards,
  rare drops. One token = one significant narrative shift within a scene; **scope by GM
  discretion.**"
- **v2:** Flagged for total redesign long before the frame swap — review-2 rates GM-dependence
  "**Total**" and says "Redesign or cut for v1" (`review-2-conversion.md:65`); the compendium
  carries the same flag (`GPT_Master_Compendium.md:182`); `rules-questionnaire.md:230-233` (Q41)
  is still unanswered. **The casino frame supplies the replacement for free:** interfering with
  the script is literally what a god does when it **tips the dealer**
  (`cosmic-casino-canon.md:33-34`), and the digital game already has the command shape —
  `patron_tip(boon|trial, magnitude, target)` emitted through the director interface, never
  direct state mutation (`patron-gods.md:196-198`).
- **Verdict:** **FORK.** **Effort:** L.
- **Why:** The two products want different answers and the frame swap changes both.
  **Table:** keep the token, but re-found it as *purchased divine intervention* — you spend a
  marker and a god acts. That converts "GM discretion" from a licence into a **fiction with
  rules**: a god will only do what its domains and temperament permit, which is a far better
  constraint than a bullet list of prohibitions.
  **Digital:** the token is redundant. `patron_tip` already does the job, schema-bound and
  deterministic, and it is a *god* acting rather than a player rewriting the script — which is
  more on-spine ("the audience is an active mechanic", §1 L28) than a player-side undo button.
- **Already decided?** The redesign/cut flag: yes. The **patron-tip-as-replacement: INFERRED** —
  no document connects Narrative Tokens to `patron_tip`.
- **Open question for the owner:** **the load-bearing one for §17.7** — does the Narrative Token
  survive at the table as a "buy a divine intervention" spend, or is it retired in favour of
  patron tips in both products?

### B-29 — The Narrative-Token hard limits become theme conflicts (§17.7, L958–959)

- **v1:** "**Hard limits:** cannot raise the dead, change how someone feels about you, instantly
  kill, or mint more tokens. Alter events — never override core rules."
- **v2:** Every one of those prohibitions is something the casino's gods demonstrably **can** do.
  Revival is canon and is a *purchase*: Viola buys a revival potion priced in lives
  (`cosmic-casino-canon.md:115-122`). Changing how someone feels is what the demonic brand does
  by dulling emotion (`story-canon.md:15-19`), and what a curse does. Instant death is what a
  losing god's erasure looks like (`cosmic-casino-canon.md:69-72`).
- **Verdict:** **MECHANICAL.** **Effort:** M.
- **Why:** The limits were *arbitrary* under aliens (a corporation's terms of service) and are
  now **fictionally false** under gods. They need re-founding as **prices, not prohibitions**:
  the thing is possible, and it costs more than you have. That preserves every balance intent
  ("no free resurrections") while removing a rule the fiction contradicts — and it opens
  authored content (a resurrection you *can* afford, once, at a stated cost, is a whole story).
- **Already decided?** No. The canon facts are decided; the implication for §17.7 is **INFERRED**.
- **Open question for the owner:** re-found the hard limits as prices, or keep them as house
  rules the table enforces ("the house does not permit resurrections at this table")?

### B-30 — Ascension: the audience chapter needs an exit door (setting-rebrand-options.md:40, 44-48; cosmic-casino-canon.md:41-43)

- **v1:** §17 has **no ascension mechanic at all.** The rebrand doc lists "Permadeath +
  Ascension (the retired become patrons)" among what the frame must preserve
  (`setting-rebrand-options.md:18`) — but that is a GDD/campaign concept, not a §17 rule; the
  audience chapter never mentions retiring into the audience.
- **v2:** Canon, near-verbatim: "**Winners of games can take some of the currency being bet
  around → gain divinity → join the table as gamblers**" (`cosmic-casino-canon.md:41-43`), and
  the rebrand calls it the pitch line: "winning doesn't free you; it **promotes you into the
  audience**… The verdict decides what kind of god you become" (`setting-rebrand-options.md:44-48`).
  D1 makes it a product requirement: "retired characters patron strangers' runs"
  (`DIRECTION.md:10-12`).
- **Verdict:** **NEW.** **Effort:** L.
- **Why:** This is the frame's headline feature and §17 is where it belongs — it is the terminal
  state of the Exposure ladder. Mechanically it needs: a conversion rate from run winnings to
  divinity, a rule for what an ascended contestant *becomes* on someone else's roster (a Patron?
  a full patron god with a deal sheet?), and the verdict's role in deciding which
  (`story-canon.md:74-76`).
- **Already decided?** The canon and the direction: yes. The **§17 rules: nothing exists.**
- **Open question for the owner:** does an ascended contestant join the standard patron-god
  schema (`patron-gods.md:152-182`) — domains, generosity, taboos and all — or a lighter
  "junior patron" record?

### B-31 — Rival gods bless or curse you: a hostile audience (patron-gods.md:222-225)

- **v1:** The audience never acts *on* the fight. It watches, it pays, it sets challenges. Its
  only lever is the number it moves.
- **v2:** RULED (Q5): "**Rival gods can bless or curse your party** — cross-party tips are gated
  on affection: **blessings require higher affection** with that god, **curses require lower**.
  Co-op griefing self-balances: a god that hates your party enough to curse it is a god your
  party starved." R20 gives a worked example: the diegetic destealth lever is a rival patron who
  can "**curse you unstealthy / out you**" (`rules-addendum.md:658-660`), replacing an earlier
  proposal that production interferes — with the explicit correction that "**Production NEVER
  interferes directly in the show**" (`rules-addendum.md:658`).
- **Verdict:** **NEW.** **Effort:** M.
- **Why:** §17 as written cannot express this: it has no rule where an audience member changes
  the game state. The affection gate is elegant (hostility is earned by neglect, so it can't be
  weaponised arbitrarily), and R20 shows it already doing load-bearing work in another chapter.
  §17 needs a subsection for it or the rule lives homeless.
- **Already decided?** Yes, twice (`patron-gods.md:222-225` Q5; `rules-addendum.md:658-660` R20).
- **Open question for the owner:** does this get its own §17 subsection, or live entirely in the
  patron chapter?

### B-32 — The announcer (cosmic-casino-canon.md:73-75; setting-rebrand-options.md:34, 157)

- **v1:** §17 has **no host**. Review-6 flagged the gap and `narrative-design.md:108-110` records
  it: "**Production cast: MISSING (rev-6 finding, OPEN)** — the announcer/host, the demographics
  department, recurring patron-god personalities."
- **v2:** RULED — "**Momus, shared with the novel**" (`setting-rebrand-options.md:157`;
  `narrative-design.md:176-178`), with a fixed voice: pink tuxedo, never breathes between
  sentences, unseen laughing audience, sign-off "This is Momus. Stay tuned!"
  (`cosmic-casino-canon.md:73-75`). The rebrand table lists him as filling exactly this gap:
  "The announcer we needed (rev-6 gap) → **Momus already exists**"
  (`setting-rebrand-options.md:34`).
- **Verdict:** **NEW.** **Effort:** M.
- **Why:** The announcer is not decoration — he is the **broadcast plane's only voice**
  (`DIRECTION.md:151-154`), so every audience mechanic that must be *legible to spectators but
  not to contestants* routes through him. §17 currently has no channel for that.
- **Already decided?** Yes. **Open question:** does §17 gain a "the announcer" subsection
  specifying what he does and does not reveal?

### B-33 — Cross-party wagering (setting-rebrand-options.md:41; DIRECTION.md:43-51)

- **v1:** Nothing. The audience is per-contestant.
- **v2:** "Cross-party patronage (Stage 2 async) → Cross-party **wagering** — other players'
  patrons bet on your run" (`setting-rebrand-options.md:41`); Stage 2 in the ladder enables
  "**cross-player patronage** (Ascended characters sponsor other players' runs)"
  (`DIRECTION.md:47-49`).
- **Verdict:** **NEW.** **Effort:** L (and out of near-term scope — Stage 2).
- **Why:** Listed for completeness because it is the shared-world payoff of the Patrons tier and
  therefore constrains how B-03/B-30 are designed *now* (a patron record must be able to belong
  to another player's ascended character).
- **Already decided?** Direction yes; rules no.
- **Open question for the owner:** none near-term; flag only that the patron schema should not
  assume patrons are NPCs.

### B-34 — The two information planes vs the whole of §17 (DIRECTION.md:149-163; patron-gods.md:199-203)

- **v1:** The audience is **openly addressed**. Contestants play to camera (Fourth Wall,
  §18.3 L1057), "Say the Line" is a Goal type (§17.4 L911), and the fiction assumes contestants
  know the ratings are the way out (§ front matter L11-13: "the only way out is through the
  ratings").
- **v2:** RULED — contestants are INSIDE the show and **never hear the announcer**
  (`DIRECTION.md:149-159`). Audience effects reach them only as world manifestations, sudden
  quests, or System messages — "the one legitimate in-fiction 'HUD' channel." Patron design
  restates it as a binding rule: "**Two information planes hold.** Contestants never hear the
  casino. Boons arrive diegetically… Spectators/replays get the announcer naming the god and the
  size of the tip — the dramatic irony is the product" (`patron-gods.md:199-203`).
- **Verdict:** **MECHANICAL.** **Effort:** M.
- **Why:** This is a genuine constraint on §17, not flavour. Three concrete consequences:
  1. **Goals and Directives must arrive as System messages** — which the canon already permits
     (`DIRECTION.md:157-159`), so §17.4/§17.5 survive.
  2. **The wager layer is broadcast-only.** Odds, tip sizes, which god bet what — none of it may
     appear on the contestant's sheet. That directly constrains B-10: if Camera Call doubles
     "the pot," the contestant cannot be shown the pot.
  3. **Exposure numbers become suspect.** If contestants can read their own Viewer count, they
     are reading the broadcast plane. Either the count is a System-provided figure the house
     chooses to share (fine, and characterful) or it is spectator-only.
- **Already decided?** The rule: yes, firmly. Its application to §17's *numbers*: **INFERRED**.
- **Open question for the owner:** may a contestant see their own standing, and if so, who is
  telling them — the house?

### B-35 — Tags → EPITHETS: a fork, not a rename (setting-rebrand-options.md:38 vs patron-gods.md:126-150)

- **v1:** Tags are "your **public identity as the Show sees you**" (§18 L965), gained by table
  consensus, hidden conditions, Goals/Directives, corporate narrative shaping — and
  "**Player-proposed tags must appear on TVTropes.org**" (§18 L969). That last clause is the
  flagged dependency.
- **v2 — the proposal:** the rebrand doc's mapping table proposes a rename: "Tags (TVTropes
  dependency — flagged debt) → **EPITHETS** — gods grant epithets ('Sasha the Nine-Lived');
  mythology-native, self-owned, kills the TVTropes debt" (`setting-rebrand-options.md:38`).
- **v2 — what was actually RULED, the same day:** **not a rename — a fork into two tracks.**
  "Epithets are not crowd tags; they run on a **traits** track — the champions are compared to
  previous legends… Crowd **tags** stay the audience's labels; **epithets** are the pantheon's
  comparisons. **Two tracks, deliberately separate** — the label/essence tension the spine
  wants" (`patron-gods.md:126-150`, Q2 RULED 2026-07-16). The mapping table in the same document
  says it flatly: "Tags | Crowd labels (**unchanged**); **epithets** are a separate
  traits/myth-recreation track" (`patron-gods.md:83`). Confirmed downstream in
  `gdd.md:284-296`, `narrative-design.md:151-153`, and used as the audit's framing device
  (`campaign-residuals-audit.md:20-28`).
- **Verdict:** **FORK** — and it is **already decided**. **Effort:** —
- **Why the fork is the better answer (and why the source question matters):** the *source* of a
  tag and the *source* of an epithet are different, and that is the whole point.
  - A **tag** is assigned by watchers, is **performable and fakeable**, and can be worn without
    being true — "pop-culture noise from a god-audience that binge-watched humanity"
    (`campaign-residuals-audit.md:21-22`).
  - An **epithet** is *earned* by recreating a myth: you accumulate trait-words from your
    background and deeds, and when your pattern matches a legend's, you are granted that
    legend's epithet (`patron-gods.md:130-139`). It cannot be performed, because the pattern is
    computed from what you actually did.
  Renaming Tags→Epithets would have collapsed that distinction and destroyed the spine's central
  mechanic: "Tags = how the AUDIENCE labels you (public identity, performable, fakeable). The
  question axes = what your choices reveal you to BE… The show breaks essence down while the
  audience applauds the label — that tension IS the spine made mechanical"
  (`story-canon.md:83-88`). So the answer to (a) is: **the source does change, and precisely
  because it changes, the rename is wrong** — the two sources need two systems.
- **Already decided?** Yes — `patron-gods.md:126-150` (Q2), `DIRECTION.md:191-192`,
  `gdd.md:284-296`. The rebrand doc's row 38 is a superseded proposal; it should be annotated so
  future sessions don't read it as canon.
- **Open question for the owner:** should `setting-rebrand-options.md:38` be marked SUPERSEDED
  in place, given it still reads as the decision?

### B-36 — Where a tag comes from (§18, L967–969)

- **v1:** Four channels: table consensus ("it's their thing"), hidden condition fulfilment,
  Goals/Directives, corporate narrative shaping — plus the TVTropes gate on player proposals.
- **v2:** Two channels, both frame-native: **detectors** (event predicates over the sim log —
  "achievement-style detection", `campaign-residuals-audit.md:204-206`) and
  **director/audience grant** for the rest. Shipped: `data/tag_effects.json` carries a
  `detector` block per tag (events + predicate + attribution) and `simulation/tag_engine.gd`
  evaluates them; the slice ruled "**Demo loadouts start with NO tags — everything is earned on
  camera**" (`slice-tags-proposal.md:372-373`). The TVTropes gate is explicitly dead
  (`campaign-residuals-audit.md:357`).
- **Verdict:** **MECHANICAL** (already decided). **Effort:** M — for the *book*, which still
  prints the TVTropes clause at L969.
- **Why:** The book's §18 has not been updated to match; a player reading the current rulebook
  is told to go to TVTropes. Under the god frame the sentence is also fictionally wrong — the
  crowd is not browsing a human wiki (except it *is*, deliciously: the gallery binged human pop
  culture, `cosmic-casino-canon.md:24`, so "the crowd names you after something it watched" is
  now *canon-supported flavour* even though the out-of-game dependency must die).
- **Already decided?** Yes. **Open question:** what replaces L969's sentence in the book — a
  "the crowd names you" line, or an explicit "the Show recognises patterns" line?

### B-37 — Tag lifecycle (§18 L970–971; §18.1 pattern 4, L982–984)

- **v1:** acquired → **Reinforced** (play into it, stack gear/skills) → **Faded** (neglected) →
  **Lost** → reacquirable. Pattern 4 makes it the universal dial: "Active = normal effect ·
  **Reinforced = doubled pull, and the tag can only be lost by dramatically betraying it** ·
  Faded = no effect until played back into."
- **v2:** Ported as a 0–3 `weight` (`character_tags.weight` already in the schema,
  `campaign-residuals-audit.md:194-198`), with the brand contract's drift riding it for free
  (empathy tags fade, cold-read tags come easier — `story-canon.md:31-35`). The slice
  deliberately shipped **binary held/not-held** and deferred the ladder
  (`slice-tags-proposal.md:372-374`, `data/tag_effects.json` `_meta.held`).
- **Verdict:** **KEEP.** **Effort:** S.
- **Why:** Frame-independent; one dial scaling every pattern is the reason 100 tags are
  affordable.
- **Already decided?** Yes (deferred, not changed). **Open question:** none — the ladder's
  return is a scheduling question, not a frame question.

### B-38 — Pattern 1, on-brand spotlight (§18.1, L975–977)

- **v1:** Each tag carries 1–3 domains; on-brand plays are "the reliable way to move Viewers
  (and, when Reinforced, Followers)."
- **v2:** Shipped as **resonance** — a multiplier on the spectacle points of matching events
  attributed to the holder, applied by the hype engine, never touching combat state
  (`data/tag_effects.json` `_meta.resonance`; `simulation/hype_engine.gd:91-95`). The slice
  constrained it hard: "**all effects are audience-side** (hype/goal/broadcast), never
  combat-stat buffs" (`slice-tags-proposal.md:40-42`).
- **Verdict:** **KEEP.** **Effort:** S.
- **Why:** The pattern's output is spectacle, which survives the frame swap untouched (B-01
  keeps the meter). The only knock-on: if Viewers/Followers are re-founded, the sentence at
  L977 needs re-pointing.
- **Already decided?** Yes. **Open question:** none.

### B-39 — Pattern 2, the Show writes for you (§18.1, L978–979)

- **v1:** "Goals and Directives are drawn toward your tags — your identity shapes your quest
  feed."
- **v2:** The field exists (`goal_modifier_weights`, empty on all 100 rows) and the FK exists
  (`patron_goals.tag_id`) — `campaign-residuals-audit.md:31-34`. But **weighted goal selection
  is deferred**: v1 draws uniformly (`rules-addendum.md:297-298`), and the slice ruled the
  deferral stands (`slice-tags-proposal.md:371`).
- **Verdict:** **KEEP.** **Effort:** M.
- **Why:** Under many gods the pattern gains a second reading it did not have: not just *which
  goals* you get, but *whose* side bets you attract — i.e. pattern 2 and pattern 3 (B-40)
  partially merge. That is an argument for making the tag's `domains` list serve both, which the
  audit already recommends ("one `domains` list serves both",
  `campaign-residuals-audit.md:192-193`).
- **Already decided?** Deferral yes; the merge **INFERRED**.
- **Open question for the owner:** when weighted draw lands, does a tag bias *which* goals
  appear, *which god* offers them, or both?

### B-40 — Pattern 3, Patron draw: the pattern that gains the most (§18.1, L980–981)

- **v1:** "**Patron draw.** Patrons adopt contestants whose tags match their taste; your domains
  steer who takes interest in you and what paid Goals they set." Note the tags-passover had to
  *de-mythologise* this for the table: "pattern 3's 'patron gods' become your audience
  Patrons — big donors… (The audience-economy version of the game's god-lens; **no gods here**)"
  (`tags-passover.md:9-11, 30-32`).
- **v2:** The god-lens comes back, fully specified: affinity-matched bidding
  (`patron-gods.md:25-40`), per-god affection ledgers, faction spill-over to "related lesser
  gods," and buy-out interest driven by the affection your deeds accumulate
  (`patron-gods.md:87-124`). Tags amplify matching domain impressions —
  "butcher-ish play under a gore tag draws war-domain god attention faster; empathy tags
  (Mascot, Crowd's Baby) draw hearth-domain gods; ties into buy-out interest"
  (`campaign-residuals-audit.md:189-193`). Each slice tag already ships a `domains` list drawn
  from the mythology vocabulary (`data/tag_effects.json`).
- **Verdict:** **MECHANICAL** (upgraded, already designed). **Effort:** M.
- **Why:** This is the single clearest case of the god frame *improving* an existing mechanic
  rather than costing it. In v1, "Patrons adopt contestants whose tags match their taste" is
  unfalsifiable GM flavour — a taste with no data behind it. In v2 the taste is a record with
  domains, favor conditions, taboos and personality axes, so the pattern becomes computable.
  The tags-passover's own parenthetical admits the table version is the *lesser* one.
- **Already decided?** Yes (`patron-gods.md:87-124`; `campaign-residuals-audit.md:189-193`;
  `gdd.md:284-288`).
- **Open question for the owner:** none blocking — but see B-43 (which domain vocabulary).

### B-41 — Pattern 5: two of the ten flagship riders are orphaned (§18.2, L997–1011)

- **v1:** Ten hand-picked tags carry one bespoke trigger each: The Monologue, Comeback Stage,
  Fan Favorite, Scene Stealer, The Bit, **Nine Lives**, **Unkillable**, Method Actor, Munchkin,
  LEEROY JENKINS. Approved at the table as GT4 (`tags-passover.md:66-79`).
- **v2:** Three problems.
  1. **Nine Lives and Unkillable were moved to the epithet track** (`rules-addendum.md:708-709`:
     "5 words moved to the epithet track"; the five are Unkillable, Vengeful, Incorrigible,
     Butcher, Nine Lives — `campaign-residuals-audit.md:163-167`). Their riders therefore belong
     to objects that are no longer tags. Either the riders migrate to the epithet system (which
     has no rider concept — it grants epithets, `patron-gods.md:130-139`) or they are re-homed
     on surviving tags.
  2. **Munchkin's rider assumes a GM**: "an exploit you found is grandfathered for you **even
     after the GM patches it**" (L1009). There is no GM in the digital game, and under the god
     frame the patcher is the house — which is a *better* joke ("the fallen god running the table
     lets your exploit stand") but a different mechanic.
  3. **LEEROY JENKINS was renamed to Reckless** by the owner on 2026-07-17 (verified in
     `data/tags.json`: `{"id": 6, "key": "reckless", "notes": "[renamed from leeroy_jenkins]"}`),
     so the rider table's row label is stale.
  Meanwhile the digital slice shipped exactly **one** rider — The Bit, with a hard constraint
  that the signature action be mechanically null (`slice-tags-proposal.md:379-383`).
- **Verdict:** **MECHANICAL.** **Effort:** M.
- **Why:** The riders are the only bespoke content in a 100-row table, so orphaning two of ten
  is a 20% loss of the scarce, hand-authored layer — and the loss is invisible unless someone
  cross-checks the epithet migration against the rider list, which is what this finding is.
- **Already decided?** The migration: yes (`rules-addendum.md:708-709`). The **rider
  consequence: not addressed anywhere.**
- **Open question for the owner:** do the Nine Lives and Unkillable riders move to the epithet
  system (giving epithets a mechanical payload they currently lack), or do two new tags take
  those rider slots?

### B-42 — Pattern 6, tag gates (§18.1, L987–988)

- **v1:** "Items, skills, Directives, and unlocks may REQUIRE a tag — authored per content
  piece." Approved as GT1 pattern 6 at the table (`tags-passover.md:38-40`, with the
  chainsaw-guitar example).
- **v2:** RULED in for the game: "**Effect model = the 5 audit patterns PLUS pattern 6: tags
  GATE unlocks** — items, actions, and skills may require tags as obtain/use conditions"
  (`rules-addendum.md:709-711`); out of slice scope (`slice-tags-proposal.md:38-39`).
- **Verdict:** **KEEP.** **Effort:** S.
- **Why:** Frame-independent. One inherited defect to carry: the Spark-volver requires tags
  **Flashy** and **Catchphrase**, neither of which exists in the 100
  (`campaign-residuals-audit.md:169-171`).
- **Already decided?** Yes. **Open question:** are Flashy/Catchphrase dead requirements or two
  missing tags?

### B-43 — Two live domain vocabularies (§18.1 L990–995 vs mythology-research-spec.md:274-288)

- **v1:** Twelve domains, authored for a crowd: **carnage · daring · showmanship · comedy ·
  heart · menace · cunning · grit · teamwork · chaos · craft · meta** (§18.1 L990-995; approved
  as GT2, `tags-passover.md:42-57`). These are *what the crowd is paying for*.
- **v2:** A **26-word controlled vocabulary** exists for gods: `war · hunt · sea · sky_storm ·
  sun_fire · moon_night · earth_harvest · death_underworld · wisdom · magic · trickery ·
  craft_forge · healing · love_beauty · music_performance · luck_gambling · wealth_commerce ·
  travel_speed · justice_oaths · chaos · beasts_wild · disease_poison · protection_home ·
  poetry_story · madness_dream · time_fate` — with an explicit "Researchers may ONLY use this
  list… the boon economy multiplies *action tags*, so domains must stay joinable"
  (`mythology-research-spec.md:274-288`). **The shipped tag data uses the mythology
  vocabulary, not the book's twelve** — e.g. Reckless is `["war","chaos","luck_gambling"]`,
  Craft Services is `["protection_home","healing","earth_harvest"]` (`data/tag_effects.json`).
- **Verdict:** **MECHANICAL.** **Effort:** M.
- **Why:** This is a live, unflagged divergence between the book and the game data, and it is
  not cosmetic — the two vocabularies answer different questions. The book's twelve describe
  **audience appetite** (what makes good TV: comedy, grit, meta). The mythology twenty-six
  describe **divine jurisdiction** (what a god owns: sea, oaths, plague). Only two words
  overlap (`chaos`; `craft`/`craft_forge` partially). A tag needs *both*: "showmanship" is what
  the crowd pays for and `music_performance` is which god notices. Three options: (1) keep both
  lists and author a join table (tag → crowd domains + god domains) — most honest, most
  authoring; (2) collapse to the mythology list and lose the crowd-appetite reading — cheapest,
  and is the de-facto current state in `tag_effects.json`; (3) collapse to the twelve and map
  them onto god domains at the patron layer — keeps the book intact, pushes the join into the
  patron system. Note `data/domain_condition_map.json` exists in the repo, suggesting the
  mythology vocabulary is already being wired to conditions.
- **Already decided?** Neither list was ever ruled *against* the other. The mythology list is
  "RULED — executable" for research (`mythology-research-spec.md:3-5`); the twelve are approved
  as GT2 for the table. **The conflict is unrecorded.**
- **Open question for the owner:** **the load-bearing one for §18.1** — do tags carry crowd
  domains, god domains, or both?

### B-44 — The Tag Compendium: 100 names under gods (§18.3, L1014–1118)

See the classification section below. Summary: **62 media-artifact-coded · 32 mythology-neutral
· 6 already myth-friendly.** The 62 survive because v2 deliberately kept a diegetic TV skin —
"**GPT becomes a VIP table whose in-fiction skin is a human reality show.** Every broadcast
mechanic (announcer, tags, camera calls, ratings) survives untouched"
(`setting-rebrand-options.md:114-119`) — grounded in canon: VIP games are "**special games
designed around what the gods found interesting during the quarter-millennium — mostly human
pop culture**" (`cosmic-casino-canon.md:24`). Without that ruling, 62% of the tag table would
need re-authoring. **Verdict: RESKIN. Effort: L** (voice pass, not a rewrite).

### B-45 — The live data contradicts the tag rulings (rules-addendum.md:708-711 vs data/tags.json)

- **The ruling (2026-07-17):** "**Tags:** renames/cuts/migrations applied per owner list (**84
  live tags**; 5 words moved to the epithet track; **K-pop cluster removed**)"
  (`rules-addendum.md:708-709`). The audit that fed it proposed KEEP 79 · RENAME 9 ·
  MIGRATE-TO-EPITHET 5 · CUT 7 (`campaign-residuals-audit.md:36`).
- **The data (2026-07-18 → today):** the reconciliation ported the authoritative 100-tag list
  back in — "84 rows, now **100**"; the 16 added include `unkillable`, `vengeful`, `butcher`,
  `nine_lives`, `incorrigible` (the five epithet migrations) and `main_vocalist`, `maknae`,
  `rap_line`, `comeback_stage` (K-pop) — `tag-reconciliation-2026-07-18.md:16-22, 57-74`.
  **Verified in the live file:** `data/tags.json` has **100 rows**, and every one of those nine
  is present. Also present: `Legacy Code`, `Null Pointer`, `Peer Review`, `Coconut Superpowers`,
  `Bolivian Army Ending` — all CUT candidates. Absent: `Corporate Asset`, `LEEROY JENKINS` —
  the only changes that stuck are the **7 owner renames** (Reckless, What a Beaut, Shill,
  Gorefest, Heart Melter, Not My Job, Winter Sheep), each carrying a `[renamed from …]` note.
- **Verdict:** **MECHANICAL.** **Effort:** S.
- **Why:** Two documents currently describe the tag set and they disagree by 16 rows. The
  reconciliation flagged its own divergence honestly ("the **names still disagree**",
  `tag-reconciliation-2026-07-18.md:95-103`) but the *count* discrepancy — 84 ruled vs 100
  shipped — was not flagged. Anyone doing the §18 content pass will hit this immediately.
- **Already decided?** Contradictorily. **The ruling and the data cannot both be right.**
- **Open question for the owner:** does the 84-tag ruling stand (re-apply the cuts, migrations
  and K-pop removal to `tags.json`), or did the 2026-07-18 port supersede it?

### B-46 — Fourth Wall, Fan Service, Parasocial vs the two planes (§18.3 L1057, L1100, L1097)

- **v1:** Three tags require a contestant who knows there is an audience and plays to it:
  **Fourth Wall** ("Hey. You watching? Good. **Address the audience directly**, in-character",
  L1057); **Fan Service** ("Do something with no tactical value, **purely for audience
  response**", L1100); **Parasocial** ("They don't know you. They feel like they do", L1097).
  Add the Goal type "Say the Line" (§17.4 L911) and the Camera Call fiction itself.
- **v2:** The two-planes rule says contestants "never hear the announcer" and "**never hear the
  casino**" (`DIRECTION.md:151-159`; `patron-gods.md:199-203`). It does *not* say contestants
  don't know they are being watched — and they must, or half the system is unmotivated. But
  under gods, "address the audience" means addressing **beings you cannot perceive who are
  betting on your death**, which is a much stranger act than mugging for a camera. **Parasocial
  becomes literal**: a god developing an attachment to a mortal is the canon patron
  relationship (`patron-gods.md:14-23`).
- **Verdict:** **MECHANICAL.** **Effort:** M.
- **Why:** These tags are where the plane rule and the tag catalogue actually touch, and the
  answer is a *ruling*, not a rename. If contestants know gods are watching, the show's horror
  changes register (you are performing for something that can kill you on a whim). If they only
  know "the audience" abstractly, Fourth Wall stays a TV joke. Both are playable; they are not
  the same game.
- **Already decided?** No. The planes rule is decided; **what a contestant believes about the
  audience is not stated anywhere I found.**
- **Open question for the owner:** **the load-bearing one for §18/§17 overlap** — do contestants
  know the audience is gods, know it's an audience but not who, or believe the show's own cover
  story?

---

## Tag Compendium classification

**Method.** Every one of the 100 names in §18.3 (`gpt-system-v1.0.md:1019-1118`) placed in
exactly one class, using a single discriminator: *does the NAME name a piece of human media /
the production apparatus (so the frame must supply a show for it to mean anything), is it a
frame-neutral behaviour label, or does it already read as a legend-word?*

| Class | What it means | Count |
|---|---|---|
| **T — media/production-coded** | The name names a human media artifact, format, role, credit, network, award, union, chart, or software artifact. Meaningless without a show or without human pop culture. | **62** |
| **N — mythology-neutral** | A behaviour, moral, or character label. Reads identically whether the watchers are aliens, gods, or nobody. | **32** |
| **M — already myth-friendly** | Reads natively as a divine epithet / legend-word ("X the ___"). | **6** |

**M (6, complete list):** Unkillable (10) · Vengeful (12) · Incorrigible (24) · Butcher (29) ·
Nine Lives (60) · Witnessed (63).
*Note the overlap: five of these six are exactly the owner's MIGRATE-TO-EPITHET set
(`campaign-residuals-audit.md:51,53,65,70,106`). Independent classification landing on the same
five is strong evidence the migration call was right. **Witnessed** is my one addition — "I was
there. I watched. I made my choice" is witness-language, which is religious register, and the
audit KEEPs it explicitly as "the audience's act of witnessing — tag-native"
(`campaign-residuals-audit.md:109`). Borderline; the audit's reading is defensible.*

**Sub-splits inside T (62)** — these matter more than the headline number:

| Sub-class | Count | What happens under gods |
|---|---|---|
| **T-break** — the referent is the alien Corporation (dead canon per D3) | **1** | Corporate Asset (16). Owner already renamed it → **Shill** (`data/tags.json`) |
| **T-IP** — real trademark or named third-party IP (breaks for *shipping*, not fiction) | **6** | LEEROY JENKINS (6), Animal Planet (14), Certified Fresh (42), SAG Dispute (43), Sea World Reject (57), Little Dead Rising Hood (27). All six already renamed or cut by the owner/audit |
| **T-insider** — TVTropes / TTRPG / K-pop jargon; opaque without the wiki | **5** | Bolivian Army Ending (18), Chunky Salsa Rule (19), Coconut Superpowers (20), Maknae (73), Rap Line (74) |
| **T-diegetic** — survives untouched because the VIP table *is* a pop-culture show | **50** | Voice check only. `cosmic-casino-canon.md:24` + `setting-rebrand-options.md:114-119` |

**Cluster notes.**
- **Software cluster (83–93, 11 tags)** is entirely T, and doubly contingent — authored for the
  removed Robot race (`rules-addendum.md` R16) *and* software-coded. Under gods they survive
  fine (the gallery binged human tech culture too), but the audit already CUT four of them for
  weak behavioural reads (`campaign-residuals-audit.md:140-148`).
- **K-pop cluster (71–82, 12 tags)** is 10× T, 2× N (Formation 75, Internal Dispute 77). Ruled
  removed 2026-07-17, present in the data (B-45).
- **Animal cluster (52–70, 19 tags)** is the most frame-robust block: 16 N, 2 M-adjacent, 1 T
  (Sea World Reject). Animals are playable (R16) and Sasha is in-game, so it carries.

### Representative table — 20 tags: v1 name → class → v2 disposition

**Read the last column carefully.** Because tags and epithets are **separate tracks** (B-35), an
"epithet form" is the correct output *only* for the M class. For T and N the right move is a
**crowd-voice re-check**, not epithet-ification — proposing "the Documentary" would be a
category error.

| # | v1 name (§18.3) | Class | v2 disposition |
|---|---|---|---|
| 10 | Unkillable | **M** | → **EPITHET** "the Unkillable" (migrated, `campaign-residuals-audit.md:51`). Its §18.2 rider is orphaned (B-41) |
| 60 | Nine Lives | **M** | → **EPITHET** "the Nine-Lived" — the canonical example, "Sasha the Nine-Lived" (`setting-rebrand-options.md:38`). Rider orphaned |
| 29 | Butcher | **M** | → **EPITHET** "the Butcher" — classic historical epithet shape |
| 12 | Vengeful | **M** | → **EPITHET** "the Avenger" — "avenger" is literally in the epithet trait vocabulary (`patron-gods.md:130-132`) |
| 63 | Witnessed | **M** | Stays a TAG (audit KEEP) — but note it is the one tag whose register is religious rather than televisual |
| 16 | Corporate Asset | **T-break** | **Renamed → Shill** (live). Under gods the equivalent joke is "House Asset" (`campaign-residuals-audit.md:57`) — the holding-company canon (`cosmic-casino-canon.md:47-56`) makes "corporate" survivable if wanted |
| 6 | LEEROY JENKINS | **T-IP** | **Renamed → Reckless** (live, `data/tags.json` id 6) |
| 14 | Animal Planet | **T-IP** | **Renamed → What a Beaut** (live); audit proposed "Nature Special" |
| 43 | SAG Dispute | **T-IP** | **Renamed → Not My Job** (live). The Directive-refusal joke survives; under gods it's refusing the *house's* script (B-21) |
| 42 | Certified Fresh | **T-IP** | **Renamed → Heart Melter** (live); audit proposed "Critics' Darling" |
| 19 | Chunky Salsa Rule | **T-insider** | **Renamed → Gorefest** (live) — a rules-lawyer name replaced with a crowd-voice one |
| 18 | Bolivian Army Ending | **T-insider** | **Rename pending** → "Last Stand" (`campaign-residuals-audit.md:59`) — not applied in data |
| 73 | Maknae | **T-insider** | **Rename pending** → "The Rookie" — not applied; still in `data/tags.json` |
| 1 | Documentary | **T-diegetic** | KEEP. Under gods: the gallery framing your mundane act as meaningful — arguably *better*, since gods narrating mortals is the whole genre |
| 39 | Fourth Wall | **T-diegetic** | KEEP, but needs the ruling in B-46 — addressing an audience you cannot perceive is a different act |
| 79 | Parasocial | **T-diegetic** | KEEP — becomes **literal**: a god forming an attachment to a mortal is the canon patron relationship |
| 98 | The Recast | **T-diegetic** | KEEP — already flagged as candidate diegesis for softcore respawn (`campaign-residuals-audit.md:159`); under gods, "the house recasts the role" |
| 89 | Safe Mode | **T-diegetic** | KEEP — the anti-spectacle label; hooks "spectacle over safety" as a *negative* crowd read |
| 13 | Menace | **N** | KEEP unchanged — behaviour label, frame-independent. (Borderline M: "the Menace" is epithet-shaped) |
| 30 | Survivor | **N** | KEEP unchanged — the reality-TV pun is a bonus, not a dependency |

---

## The mass-audience vs named-gods analysis

**The question:** v1's audience is a mass anonymous public; v2's is a small set of named,
individually-motivated gods with money on the table. What does that do to every Exposure
mechanic?

**The short answer:** it changes what *kind of object* the audience is, and mechanics divide
cleanly by whether they depend on that. A mass audience is a **fluid** — continuous, statistical,
momentum-bearing, individually meaningless. A god gallery is a **graph** — discrete, named,
stateful, individually decisive. Mechanics that only need "a number that goes up when you're
exciting" survive untouched. Mechanics that need *anonymity, scale, or continuity* break.

**Survives untouched (the fluid isn't load-bearing):**
- **Camera Call's structure** (§17.3) — a stake multiplier with symmetric risk. Doesn't care who
  is watching. *Caveat:* what exactly doubles becomes a real question (B-10).
- **Goals' structure** (§17.4) — a conditional payout on described behaviour is a side bet by
  another name. The four families, the one-active-goal rule, the Clock-reset offer cadence, all
  frame-independent.
- **Directives' structure** (§17.5) — an optional risky quest from the power that runs the show.
  The letterhead changes; the mechanic doesn't.
- **Achievements and box tiers** (§17.6) — reward plumbing, rated low-difficulty conversion
  (`review-2-conversion.md:41`).
- **All six tag patterns** (§18.1) and the whole lifecycle. Tags describe *the contestant*, and
  the contestant didn't change.
- **The hype meter itself** — it measures spectacle production, not audience composition.

**Needs genuine redesign (the fluid was doing the work):**
1. **Viewers (§17.1).** "Billions" is the load-bearing property: it is what makes the number
   continuous, decayable, and impersonal. Twenty-four gods cannot approximate a fluid. **This is
   the one mechanic that cannot be reskinned.** (B-01)
2. **Followers (§17.1).** The tier is defined by *micro-payment at scale* — "phone-vote money,"
   "the percentage of watchers who'd actually pay." Gods do not micro-pay; canon has them
   **tipping the dealer** in boons, buffs, items, trials, monsters, curses
   (`cosmic-casino-canon.md:33-34`) — a large, discrete, *targeted* act. The tier has no god
   analogue and must be re-founded or cut. (B-02)
3. **Goal→Patron conversion (§17.4).** v1 converts *one of billions*; v2 must convert *one of
   twenty-four*. Supply becomes finite, conversion becomes stateful, and Patron Tokens stop
   being income. This ripples into §4.2's skill caps, which are denominated in them. (B-16)
4. **Narrative Tokens (§17.7).** Already condemned for GM-dependence; the god frame both
   supplies a replacement (`patron_tip`) and falsifies the hard limits. (B-28, B-29)

**Gains machinery v1 has no slot for (the graph does things a fluid can't):**
- **A contractual audience member** — THE patron god, with a deal sheet, taboos, buy-outs and
  abandonment modes (B-04). A fluid cannot sign a contract.
- **A hostile audience** — rival gods bless or curse, gated on affection (B-31). A fluid cannot
  hold a grudge.
- **Competing issuers** — many gods with conflicting demands, which turns the quest feed from a
  script into a market (B-19). A fluid has one opinion at a time.
- **An exit door** — ascension, mortal→god, the winner joins the gallery (B-30). A fluid has no
  membership to join.
- **Named memory** — affection ledgers make the audience a set of long-term relationships,
  "not vending machines" (`narrative-design.md:139`). A fluid forgets you the moment you're
  boring; that *is* v1's decay rule.

**The structural trade, stated plainly.** v1's audience is **wide and shallow**: enormous,
instantly responsive, and it costs nothing to author because nobody in it is anybody. v2's is
**narrow and deep**: each member is a designed character with data, so the audience can *act*,
*remember*, *compete*, and *be lost* — at the cost of authoring 24+ of them
(`mythology-research-spec.md:366-368`) and of losing the statistical smoothness the hype curve
was built on. The frame swap is therefore not neutral for §17: it **upgrades everything about
the audience except its physics.**

**The clean resolution (recommendation, INFERRED):** keep both objects and make one feed the
other. The **hype meter stays the fluid** — it lives on the broadcast plane, it is what Momus
narrates, it decays, it is already built and inside `state_hash`. The **god gallery is the
graph** — affection ledgers, contracts, tips, buy-outs. Spectacle (fluid) is the *input* that
moves affection (graph); affection is what pays. That preserves every shipped v1 mechanic,
gives the gods somewhere to be, and is consistent with the two-planes rule: the crowd number is
broadcast-plane, the relationships are the game.

---

## Cross-cutting observations

1. **§17 has no home for its own biggest v2 additions.** Four ruled systems — the patron
   contract (B-04), rival intervention (B-31), the announcer (B-32), ascension (B-30) — belong
   structurally to "The Audience" and currently live only in `docs/design/patron-gods.md`. If the
   TTRPG book is re-skinned (RULED: it is — `setting-rebrand-options.md:155-156`), §17 roughly
   doubles in size.

2. **The frame swap is *net positive* for §18 and net cost for §17.1.** Every tag pattern either
   survives or improves (pattern 3 dramatically — B-40), and the TVTropes debt dies. The only
   real §18 costs are naming (62 media-coded tags, mitigated by the diegetic-show ruling) and
   the domain-vocabulary conflict (B-43). §17's cost is concentrated almost entirely in the
   Viewers/Followers tiers.

3. **Three defects the frame swap fixes for free.** (a) The Corporation's motive problem —
   "morally alien, not evil… nothing to twirl a mustache" (`setting-rebrand-options.md:50-52`).
   (b) The missing production cast — Momus already exists (`setting-rebrand-options.md:34`).
   (c) "The box knows who opened it" gets an explanation (B-25). And a possible fourth: the D8
   Camera-Call farm may die of finite god supply (B-11).

4. **One defect the frame swap *creates*: the tags/epithets boundary needs constant policing.**
   Five tags migrated, two flagship riders orphaned (B-41), one document still says the systems
   are the same thing (`setting-rebrand-options.md:38`), and the live data has all five migrated
   tags back in place (B-45). This is the highest-entropy area in my slice.

5. **The word "Exposure" is unusable in this codebase.** `simulation/exposure_engine.gd` is the
   *combat* Exposed-state helper. Any future audience-engine file cannot take the obvious name.
   Review-1 flagged the collision (B13) 3+ weeks before the code landed and it happened anyway —
   worth a rename now rather than later (B-06).

6. **Vocabulary drift is already shipping.** The book says tags carry twelve crowd domains;
   `data/tag_effects.json` gives them mythology domains. Nobody ruled that; it happened because
   the slice proposal needed "a clean join to the mythology pipeline's domain vocabulary"
   (`slice-tags-proposal.md:8-9`) and nobody checked the book. (B-43)

7. **The table version was deliberately de-mythologised, and that decision is now backwards.**
   `tags-passover.md:9-11` records the table's six patterns as "re-phrased for a GM'd table and
   **de-mythologized** (pattern 3's 'patron gods' become your audience Patrons — big donors)."
   Since the live campaign is RULED to re-skin to the casino
   (`setting-rebrand-options.md:155-156`), that de-mythologisation should be **reverted** — the
   table can now say "patron gods" and mean it.

8. **"Belief" was the right word all along.** §17.5's reward contract — "the Corporation pays in
   stuff; **the audience pays in belief**" (L923) — is a line written for aliens that reads as if
   it were written for a divinity economy. It should survive the re-voice verbatim.

---

## Open questions for the owner

Ordered by how much downstream design they unblock.

1. **(B-01/B-02/B-07) What is the Exposure ladder under gods?** Do Viewers stay a broadcast-plane
   spectacle meter with the *economy* moving to per-god affection — and does the Follower tier
   survive at all (standing bets? mortal devotees? cut)? This is the single biggest §17 decision;
   B-22 and the compendium's "rolling performance curve" both hang off it.
2. **(B-16) With a finite god roster, does a Goal still convert a Patron?** If yes, Patron Tokens
   are milestones with a hard supply cap and §4.2's skill caps need re-pricing. If no, where do
   Patron Tokens come from in the digital game (the exchange is cut)?
3. **(B-19) Is a patron's tip a Directive, or a separate channel?** One issuer (script) vs many
   competing issuers (market) is a genuine shape change, and `setting-rebrand-options.md:131-132`
   currently merges them while `patron-gods.md:80-81` separates them.
4. **(B-10) When the odds board turns to you, what doubles?** Spectacle points (safe, shipped),
   per-god affection swings (relationship accelerant *and* destroyer), or the wager itself
   (most faithful to the fiction, needs a pot model, and collides with the two-planes rule).
5. **(B-43) Do tags carry crowd domains, god domains, or both?** The book says twelve; the
   shipped data says the mythology twenty-six. Blocks the §18 content pass.
6. **(B-45) Does the 84-tag ruling stand, or did the 100-row port supersede it?** The K-pop
   cluster, the 5 epithet migrations and the 7 cuts are ruled out and shipped in.
7. **(B-46) What do contestants believe about the audience?** Know it's gods · know it's an
   audience but not who · believe the show's cover story. Changes Fourth Wall, Fan Service,
   Parasocial, "Say the Line," and the register of the whole broadcast layer.
8. **(B-28/B-29) Do Narrative Tokens survive as "buy a divine intervention"?** And do the hard
   limits become prices rather than prohibitions, given that revival is canon and purchasable?
9. **(B-41) Where do the Nine Lives and Unkillable flagship riders go** now that both tags are
   epithets — migrate to the epithet system (which currently has no rider concept), or re-home on
   two surviving tags?
10. **(B-30) What does an ascended contestant become?** A full patron god record (domains,
    generosity, taboos) or a lighter junior-patron record — and does the verdict pick which?
11. **(B-06) Rename §17.1 "Exposure"?** The word is taken by the combat state and by a sim class.
12. **(B-24) Map the top box tiers onto the canon relic taxonomy** (Godly → God Relic, Mythic →
    Follower Relic), or keep tiers abstract?
13. **(B-35, housekeeping) Mark `setting-rebrand-options.md:38` SUPERSEDED** — it still reads as
    the decision that tags become epithets, which the same day's Q2 ruling overturned.
