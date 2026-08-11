# A — Framing, premise & contestant layer: v1→v2 change inventory

**Scope:** rulebook §1 (The Show), §2 (Making a Contestant), §3 (Advancement),
§9 (Shock), §11 (States Glossary), §16 (Healing & Downtime), the book's voice/register,
and every in-fiction proper noun in those sections. Whole-book vocabulary sweep included,
with out-of-slice instances flagged to B/C/D.

**Citation shorthands used below**

| shorthand | file |
|---|---|
| `book:N` | `/home/user/Galactic-Prime-Time/rulebook/gpt-system-v1.0.md` line N |
| `canon:§N` | `/home/user/Galactic-Prime-Time-Game/docs/cosmic-casino-canon.md` §N |
| `rebrand:N` | `/home/user/Galactic-Prime-Time-Game/docs/setting-rebrand-options.md` line N |
| `dir:N` | `/home/user/Galactic-Prime-Time-Game/docs/DIRECTION.md` line N |
| `add:N` | `/home/user/Galactic-Prime-Time-Game/docs/rules-addendum.md` line N |
| `patron:N` | `/home/user/Galactic-Prime-Time-Game/docs/design/patron-gods.md` line N |
| `narr:N` | `/home/user/Galactic-Prime-Time-Game/docs/narrative/narrative-design.md` line N |
| `story:N` | `/home/user/Galactic-Prime-Time-Game/docs/story-canon.md` line N |
| `audit:N` | `/home/user/Galactic-Prime-Time-Game/docs/audits/campaign-residuals-audit.md` line N |
| `plan:N` | `/home/user/Galactic-Prime-Time-Game/docs/ttrpg-update-plan.md` line N |
| `myth:N` | `/home/user/Galactic-Prime-Time-Game/docs/design/mythology-research-spec.md` line N |
| `gdd:N` | `/home/user/Galactic-Prime-Time-Game/docs/gdd/gdd.md` line N |
| `brief:N` | `/home/user/Galactic-Prime-Time-Game/docs/brief/brief.md` line N |
| `rev1:N` / `rev6:N` | `…/docs/review/review-1-ttrpg.md` / `review-6-story.md` line N |

> **⚠️ READ A-00 FIRST.** The single most load-bearing fact in this slice is that the
> newest written position **already forks v1 and v2 by policy** — and it contradicts an
> older ruling that said they merge. Every verdict below is conditional on that.

---

## Summary table

| ID | Element | §/file:line | Verdict | Effort | One-line change |
|---|---|---|---|---|---|
| **A-00** | **The v1/v2 relationship itself (fork vs re-skin)** | `plan:6-9`, `plan:12-45` vs `rebrand:155-156` | **FORK** (per newest doc) — **CONTESTED** | — | Two docs disagree; the 2026-07-23 plan says the book NEVER takes the casino, the 2026-07-16 rebrand says the live table re-skins. Owner must pick before any of A-01…A-30 is actioned. |
| A-01 | Abduction as the entry mechanism | `book:9`, `book:25`, `book:69` | CUT | S | Nobody is abducted; the realm's bindings weaken and the world drops into the games. |
| A-02 | The Corporation™ as the power running the show | `book:9-11`, `book:863` (+ 11 out-of-slice) | RESKIN | S (my §§) / M (book-wide) | "The Corporation" → **the house** — the fallen (bankrupt) god running the table. |
| A-03 | The colonization-propaganda motive | `book:10-11` | CUT | S | Dead canon; there is no colonization argument and no "citizens" to persuade. |
| A-04 | The show's actual motive + endgame (divinity economy, ascension, the verdict) | absent from book; `canon:§3`, `rebrand:44-48` | NEW | M | §1 must state *why* the games exist and what winning does (you join the audience). |
| A-05 | "Refusing to join the show?" coercion threat | `book:12-13` | CUT | S | No one is asked, so no one can refuse; v2's refusal analogue is refusing a **patron**. |
| A-06 | "Contestant" as the player-character noun | `book:25` (+13 more) | KEEP | S | Keep "contestant"; note the two-plane register split with canon's "champion". |
| A-07 | "alien-broadcast dungeon runs" | `book:26` | RESKIN | S | Drop "alien"; the broadcast survives as the VIP table's diegetic skin. |
| A-08 | Core pillars — "Spectacle over safety" / "The crowd is watching" | `book:27`, `book:32` | KEEP | S | Zero change; gods are canonically "starving for spectacle". |
| A-09 | Timescale flavour ("the table's deliberation is the broadcast's slow-motion replay") | `book:34-36` | RESKIN | S | 5-second Clock is theme-neutral; the tabletop simile needs a digital analogue. |
| A-10 | The book's whole VOICE and register | front matter + `book:860-864` etc. | RESKIN | **L** | Corporate-sardonic survives — **re-pointed** from the Corporation to the investor-religions; add the pop-culture-mythology register on top. |
| A-11 | The two information planes | absent from book; `dir:149-163` | NEW | S | §1 must say contestants never hear the announcer. |
| A-12 | Charm = "camera-ready / photogenic" | `book:52-56`, `add:594-601` | RESKIN | S | R18 survives verbatim; only the flavour gains the odds-board/divine-eye reading. |
| A-13 | Charm's off-stat pointer ("warmth lives in the audience's reaction") | `book:54-56` | RESKIN | S | v2 has **three** off-Charm tracks (crowd tags · patron affection · epithets), not one. |
| A-14 | §2.3 Command / Persuade / Intimidate keyed to Charm | `book:99-101` vs `add:596-598` | **MECHANICAL** | M | Under R18 ("Charm is NOT charisma") these three rows are incoherent and were never re-audited. |
| A-15 | Body/Core pillars, 7+7 point-buy, 1–5 creation-only scale | `book:44-45`, `book:60-67` | KEEP | S | Theme-neutral; re-affirmed verbatim by R6. |
| A-16 | Background as the single creation surface (audition tape) | absent from book; `add:579-588` | NEW | **L** | Creation gains a background that grants skills, seeds epithet traits, and draws patron bids. |
| A-17 | Race list — Human / Animal / **Robot-AI** | `book:68-70` | **FORK** | S | R16 removes Robot/AI for v2 (Earth-life only); D-4 explicitly keeps it in the book. |
| A-18 | "Machines & conditions" sidebar | `book:74-85` | **FORK** | S | Same fork as A-17; v2 replaces it with R21 Lego part composition. |
| A-19 | Contestant-animals vs. god-followers (creature taxonomy) | `book:68-70`; `canon:§6` | NEW | M | v2 needs a line separating playable Earth animals from "followers dragged into the framework". |
| A-20 | "Levels are awarded by the GM at milestones" | `book:111`, `add:583-585` | **MECHANICAL** | S | No GM in v2 — progression issues `grant_level` automatically. |
| A-21 | What a level *is*, diegetically, under gods | absent from book | NEW | M | Unstated. Framework-grants-levels vs patron-grants-power is an unruled theme boundary. |
| A-22 | §3.2 milestone bonuses incl. Charm/20 → Camera Call stack | `book:118-132` | KEEP | S | Mechanically theme-neutral; carries a known unreachability defect (flag, don't fix here). |
| A-23 | §3.3 skill points, §3.4 respec, the XP-variant aside | `book:134-148` | KEEP | S | Theme-neutral; one stale sentence (XP is now approved in principle by R6). |
| A-24 | §9 Shock — tier names and model | `book:577-601` | KEEP | S | Zero TV-coded vocabulary. Shout/Stutter/Faint/Helpless all survive untouched. |
| A-25 | §11 States Glossary | `book:622-632` | KEEP | S | Zero TV-coded vocabulary; note the pre-existing **Exposed/Exposure** name collision. |
| A-26 | §16 Med Bay invoice + "costs the Corporation more than stabilizing them" | `book:856-863` | RESKIN | S | Corporate invoice → casino **comps and markers**; the joke gets better, not weaker. |
| A-27 | §16 downtime's diegetic identity (the Lounge) | `book:852-855` | RESKIN | S | The Lounge is the **comp suite**; the house comps your room and watches its assets. |
| A-28 | §16 "wounds are content, and the audience loves a limp" | `book:864` | KEEP | S | Reads *better* under morally-alien gods. Model line for the whole re-voice. |
| A-29 | The title "Galactic Prime Time" | `book:1`; `rebrand:158-159` vs 4 docs | KEEP (ruled) | S | Ruled KEEP 2026-07-16; four downstream docs still carry it OPEN. Reconcile, don't re-decide. |
| A-30 | The announcer / host | **zero occurrences in the book**; `rebrand:157` vs `dir:197` | NEW | M | Book has no announcer at all. Momus is ruled in one doc and listed OPEN in four. |

**Verdict counts:** KEEP 9 · RESKIN 8 · NEW 6 · MECHANICAL 3 · FORK 3 (+A-00, contested) · CUT 3.
**Effort:** S 22 · M 6 · L 2.

---

## Findings

### A-00 — The v1/v2 relationship itself: fork or re-skin? (`plan:6-9` + `plan:12-45` vs `rebrand:155-156`)

- **v1 (alien):** the book is the live campaign's rules master, running Corporation lore.
- **v2 (gods):** two documents give opposite answers about whether the book follows the game.
  - `rebrand:155-156` — *"~~Does the live TTRPG campaign re-skin too?~~ **RULED 2026-07-16:
    RE-SKIN TO CASINO** — the live table adopts the casino frame alongside the game."*
  - `plan:6-9` (dated **2026-07-23**, seven days later) — *"**Explicitly out of scope:** the
    video game's setting change. The TTRPG keeps its ORIGINAL setting — reality-TV dungeon
    crawler, The Corporation™, alien broadcast, Viewers/Followers/Patrons as the audience
    economy. Everything Cosmic-Casino-flavored is video-game-only and stays out of the book
    and the app."*
  - `plan:12-18` formalises this as **"The no-mix-ups guard — three canons, kept separate"**,
    with a "Video-game setting layer (**NEVER ported to TTRPG**)" row.
  - `plan:26-27` goes further: *"**'Patrons' in the TTRPG remain paying audience members**
    (System §Exposure), never gods. … Any sentence that needs the word 'god' does not belong
    in the book."*
- **Verdict:** **FORK** per the newest document — but **CONTESTED**. **Effort:** —
- **Why:** this decides whether my inventory is *an edit list for the existing book* or *a
  spec for a separate v2 rules text*. The fork position is already partly institutionalised
  and executed: D-4 keeps Robot/AI in the book while R16 removes it from the game
  (`plan:114`); D-6 keeps the full tag list in the book while the game runs a pruned 84
  (`plan:117`); the B-1/B-2/B-4 passes were executed on the live campaign DB under this
  plan's framing. So the fork is not hypothetical — three concrete divergences are live.
- **Already decided?** **Both ways, and that is the problem.** `rebrand:155-156` says merge;
  `plan:6-9` (newer, status *PROPOSED — awaiting owner approval*, but partly executed) says
  never merge; `dir:197-198` lists "TTRPG-table re-skin?" as *still open*, siding with the
  plan. `gdd:397-398`, `brief:143-144`, `narr:245` all carry it OPEN too. Four docs vs one.
- **Open question for the owner:** **Does the live TTRPG book adopt the Cosmic Casino, or
  does the casino stay video-game-only?** If fork: this inventory becomes the spec for a v2
  rules text (or the game's own rules doc) and the book is untouched. If merge: `plan:6-9`
  and its no-mix-ups guard must be retracted, and D-4/D-6 revisited.

---

### A-01 — Abduction as the entry mechanism (`book:9`, `book:25`, `book:69`)

- **v1 (alien):** *"You were abducted by an alien conglomerate"* (`book:9`); *"You are a
  **contestant**: an abducted human"* (`book:25`); *"Animals and machines are rarer
  **abductions**"* (`book:69`).
- **v2 (gods):** there is no abduction. *"Roughly **once a quarter-millennium**, the bindings
  of the realms weaken and the gods get the opportunity to **claim divine favor from that
  realm's subjects** … This cycle it is **the humans, in the human realm, on Earth** …
  When the world is thrown into the casino's games, **tables form**"* (`canon:§1`). Most of
  humanity is unaware anything is coming; the whole world drops in at once.
- **Verdict:** **CUT** **Effort:** S (three sentences) / M downstream
- **Why:** abduction is a *selection* event with an agent who chose you; the v2 cosmology is
  an *ambient* event with no selector. That inverts the contestant's opening emotional
  position from "taken" to "caught", and it removes the question "why me?" that v1's premise
  implicitly answers. Downstream data already leans on the v1 read: `characters/contestant-template.md:10`
  asks *"Why the Corporation picked them (what makes them good TV)"* and
  `characters/sasha.md:14` cites *"pre-abduction surveillance flagged an 'anomalous
  attachment pair'"* — both need a v2 replacement question (which table you landed on, which
  god noticed you).
- **Already decided?** Yes — `canon:§1`; `audit:483-484` lists the Corporation frame under
  "**Throw away entirely (dead canon — never re-import)**".
- **Open question for the owner:** none for the game. For the book, see A-00.

### A-02 — The Corporation™ as the power running the show (`book:9-11`, `book:863`; 11 more out of slice)

- **v1 (alien):** an alien conglomerate that films you, writes Directives, sells you gear,
  and eats the cost of stabilising you. 13 occurrences book-wide; **2 in my sections**
  (`book:9` front matter, `book:863` §16), the rest in §17.5 (slice B), §18 tag copy (B),
  §19 retail (C/D), §20 Lounge (C/D).
- **v2 (gods):** **"the house"** — the fallen (bankrupt) god running the table. *"The games
  are controlled **not by AI but by fallen gods** — gods who went **bankrupt**: **forgotten
  religions**"* (`canon:§4`); *"**The house** — the fallen god's production apparatus; speaks
  only through Directives and System messages"* (`narr:136-137`).
- **Verdict:** **RESKIN** **Effort:** S in my sections / M book-wide
- **Why:** this is the cleanest swap in the whole inventory — the Corporation is a *role*
  (issuer of directives, seller of goods, payer of invoices, owner of the cameras) and the
  house occupies it 1:1 with no mechanical consequence. Nothing in §16 or §1 changes except
  the noun.
- **Already decided?** Yes — `audit:351` (frame), `audit:358` (*"the house (fallen god) issues
  Directives; System messages are the house channel. Mechanics unchanged, voice re-skinned"*),
  `audit:359` (Lounge → comp suite). Seed-data follow-through already scheduled:
  `audit:478-479` migrates `patron_goals.source_type` `'Corporate'` → `'House'` and renames
  the `corporate_asset` tag → **"House Asset"** (`audit:57`).

### A-03 — The colonization-propaganda motive (`book:10-11`)

- **v1 (alien):** *"The Corporation™ films you running its dungeons **to prove to its
  citizens that colonizing Earth is beneficial — nay, *necessary***."*
- **v2 (gods):** nothing occupies this slot as a *justification*. The casino has no motive at
  all: *"the casino is a framework with no motive … Nothing to twirl a mustache"*
  (`rebrand:51-52`); the gods are *"powerful beings expanding their own influence **in their
  petty ways**"* (`canon:§4`).
- **Verdict:** **CUT** **Effort:** S
- **Why:** it is the load-bearing satire of v1 — the show exists to *argue* something, which
  is what makes every death propaganda. v2 deliberately removes the argument: the show exists
  because gods are bored and gambling. That is a *tonal downgrade in menace and an upgrade in
  alienness*, and it is exactly the trade `rebrand:50-52` was designed to make. The v1 line
  cannot be softened into v2 — it must go, and A-04 must replace it or §1 has no reason to
  exist.
- **Already decided?** Yes — `audit:483-484` ("Throw away entirely": *"colonization motive,
  'beneficial — nay, necessary', the refusal threat"*).

### A-04 — The show's actual motive and endgame: the divinity economy (absent from book; `canon:§3`)

- **v1 (alien):** the endgame is a single clause — *"the only way out is through the
  ratings"* (`book:12`). The book states no win condition, no exit, no meta-goal.
- **v2 (gods):** three canon statements the book must carry:
  1. *"The more **currency** a god wins, the higher their **divinity** — and the more
     **central their religion will be for the next 250 years**"* (`canon:§3`).
  2. *"**Winners of games can take some of the currency being bet around → gain divinity →
     join the table as gamblers.**"* — the mortal→god pipeline is canon (`canon:§3`).
  3. *"**The final winner of the tables decides how history is shaped for the next 250 years
     and how the apocalypse is remembered.**"* (`canon:§3`)
  `rebrand:44-48` names this the frame's biggest unlock: *"**winning doesn't free you; it
  promotes you into the audience.** The verdict decides what kind of god you become."*
- **Verdict:** **NEW** **Effort:** M
- **Why:** v1's §1 gets away with no stated endgame because "escape the show" is implicit.
  v2 *inverts* the endgame — there is no escape, only promotion — and that inversion is the
  product's pitch line. A v2 §1 that does not say it leaves the whole spine
  (*"how much can we break your essence down in the name of entertainment?"*, `story:63`)
  without its payoff. It also retro-justifies the existing Ascension→Patron loop
  (`rebrand:120-122`: *"GPT's retire-into-Patron loop maps 1:1 with zero invention"*).
- **Already decided?** Yes — `canon:§3`, `rebrand:44-48`, `rebrand:120-126`, `narr:36-37`
  (theme: *"Winning is joining"*), `narr:63-66` (the finale is a verdict).

### A-05 — "Refusing to join the show?" — the coercion threat (`book:12-13`)

- **v1 (alien):** *"Refusing to join the show? 'We can't guarantee what will happen to you
  afterwards.'"* — a named threat from a named agent. `rev6:32` calls it load-bearing:
  *"'No respawns' + 'we're not asking' sets stakes cleanly."*
- **v2 (gods):** there is no offer, therefore no refusal. But v2 *relocates* refusal one layer
  in, and has already ruled it: **refusing a patron** is legal and costless in itself —
  *"Refusing every offer is allowed (RULED 2026-07-16, Q6): it is simply a **patron-less
  run** — nothing else. Baseline diffuse gains, no escort, no directed bets, no special
  multipliers. Explicitly NOT Forsaken."* (`patron:43-45`). And the Forsaken run is
  explicitly **not** a refusal: *"story-wise the champion is **chosen by the gods to overcome
  a trial bigger than others** — it is *the gods' way of going all-in*, never the champion's
  refusal of patronage"* (`canon:§2`).
- **Verdict:** **CUT** (the v1 line) **Effort:** S
- **Why:** the v1 threat is what makes the Corporation a villain, and the v2 canon spent an
  explicit ruling making sure the gods are *not* villains. Cutting it is required, not
  optional. The replacement is strictly better designed: v1's refusal is a bluff you can
  never test; v2's refusal is a real, priced, playable choice.
- **Already decided?** Yes — `audit:484` (refusal threat = dead canon); `patron:43-45` and
  `canon:§2` for the replacement.

### A-06 — "Contestant" as the player-character noun (`book:25` + 13 more occurrences)

- **v1 (alien):** "contestant" throughout — 14 occurrences, 5 of them in my sections
  (`book:25, 75, 858, 862, 905`).
- **v2 (gods):** **both nouns are live in v2 canon, in different registers.** The casino
  canon says **champion**: *"Realm-tied deities prepare **hidden champions**"* (`canon:§1`),
  *"A lone champion"* (`canon:§2`), and `patron:41,50,124,206-215` uses "champion"
  consistently for the contract-holder. The narrative/product docs say **contestant**:
  `narr:22`, `narr:140`, `gdd:21`, `brief:12-13`.
- **Verdict:** **KEEP** ("contestant" survives) **Effort:** S
- **Why:** the VIP table's diegetic skin is a human reality show (`rebrand:111-119`), so the
  show calls you a contestant — and every mechanic in my sections that names you
  (`book:858` per-contestant med-bay pricing, `book:905` Camera Call) is show-side. The gods
  call you a *champion*: it's the wager-side noun. This is not drift, it is exactly the
  **two information planes** (A-11) expressed in vocabulary — but no document states it, so a
  future author will normalise one away by accident.
- **Already decided?** Partially. Both nouns are ruled *in their own documents*; nothing rules
  the relationship between them.
- **Open question for the owner:** confirm **contestant = broadcast plane, champion = wager
  plane**, so the two nouns are a deliberate register split rather than drift.

### A-07 — "alien-broadcast dungeon runs" (`book:26`)

- **v1 (alien):** *"competing in **alien-broadcast** dungeon runs."*
- **v2 (gods):** the broadcast survives; only "alien" dies. *"**The TV frame doesn't have to
  die — it becomes diegetic.** VIP tables are 'special games designed around what the gods
  have seen throughout the quarter-millennium and found interesting — mostly human pop
  culture.' A reality-TV dungeon crawler is exactly what gods who binge-watched humanity would
  build. **GPT becomes a VIP table whose in-fiction skin is a human reality show.** Every
  broadcast mechanic (announcer, tags, camera calls, ratings) survives untouched"*
  (`rebrand:111-119`).
- **Verdict:** **RESKIN** **Effort:** S
- **Why:** this is the ruling that saves ~80% of my slice from rework. Without it, every
  camera/broadcast/audience noun in the book would be a rewrite; with it, they are diegesis.
  Only the *provenance* word ("alien") is wrong.
- **Already decided?** Yes — `rebrand:111-119`, `canon:§2` (VIP table definition), and the
  repo CLAUDE.md front matter (*"The reality-show skin survives diegetically (a VIP table
  themed on human pop culture)"*).

### A-08 — Core pillars: "Spectacle over safety" / "The crowd is watching" (`book:27`, `book:32`)

- **v1 (alien):** *"**Core pillars:** Spectacle over safety. Identity through Tags. Timeline
  combat (Moments and Clocks). The Audience as an active mechanic."* (`book:27`);
  *"Safe, passive play is structurally discouraged. **The crowd is watching.**"* (`book:32`).
- **v2 (gods):** unchanged, and *better motivated*. Canon's hard rule on the gods:
  *"gods are **morally alien** throughout — addicted, bored, **starving for spectacle**"*
  (`canon:§4`). "Spectacle over safety" is a design pillar in v1 and a *cosmological fact* in
  v2.
- **Verdict:** **KEEP** **Effort:** S (zero edits)
- **Why:** worth an explicit row because it demonstrates the frame swap costs nothing at the
  design-principle layer. `rebrand:101-104` makes the same claim structurally:
  *"This is a FRAME swap, not a redesign — the engine doesn't know who's watching."*
  The word "crowd" also survives: the tags audit's discriminator is *"does the NAME read as
  something a watching crowd would chant about a contestant's on-camera behavior?"*
  (`audit:26`) and it kept 79/100 tags on that basis.
- **Already decided?** Yes — `canon:§4`, `rebrand:101-104`.

### A-09 — Timescale flavour (`book:34-36`)

- **v1 (alien):** *"**Timescale (flavor):** in the fiction, a full Clock is roughly **five
  seconds**. Everything happens *fast* — **the table's deliberation is the broadcast's
  slow-motion replay**."*
- **v2 (gods):** the 5-second Clock is theme-neutral and survives (`add:15-29` R0 puts the
  tick at ≈0.5s in-game). The *simile* is tabletop-only — a digital v2 has no table
  deliberating. Its digital analogue is already designed: *"treat Moments as **real-time
  ticks with a declare window**, not turns with timers — the clock advances on a wall-clock
  cadence inside a field (tunable, ~3–5s/Moment)"* (`dir:89-93`).
- **Verdict:** **RESKIN** **Effort:** S
- **Why:** the sentence teaches the reader *why the fiction is fast while play is slow* —
  that pedagogical job still needs doing in v2, with a different second half (the declare
  window is the replay; the broadcast still gets the slow-motion). Only the referent changes.
- **Already decided?** The clock-driver model is SKETCH-status (`dir:83`), not decided. The
  flavour line has no ruling.

### A-10 — The book's whole VOICE and register (front matter, `book:860-864`, and book-wide)

- **v1 (alien):** **corporate-sardonic broadcast TV.** Concrete lines from my sections that
  cannot survive as written:
  - `book:8` — *"**Lights. Camera. Action.**"*
  - `book:9-11` — *"You were abducted by an alien conglomerate. The Corporation™ films you
    running its dungeons to prove to its citizens that colonizing Earth is beneficial — nay,
    *necessary*."*
  - `book:12-13` — *"Refusing to join the show? 'We can't guarantee what will happen to you
    afterwards.'"*
  - `book:18` — *"…first-pass values that **the show tunes in play**."*
  - `book:860-861` — *"Premiums rise with every claim and every floor deeper — **hazard
    pricing, itemized, on camera**."*
  - `book:862-863` — *"**Bleed-out stabilization is always free.** Losing the contestant costs
    **the Corporation** more than stabilizing them. Almost always."*
  - (out of slice, flagged to **B**: `book:872` *"**Entire galaxies are watching.**"*;
    `book:877` *"at **phone-vote money**"*; `book:882-883` *"the **streamer-gets-$5,000 tier
    of the galaxy**"*; `book:879` *"affect **TV rating** and Directive volume"*.)
- **v2 (gods):** the register is **ruled**, and it is *not* "delete the corporate voice" — it
  is "re-point it".
  - **Base register:** *"pop-culture mythological fiction — owner-named precedents:
    **Helltaker, mythology manhwa, Shinto-themed anime**. Gods, angels, demons, and
    God-figures are depictable as characters, positively or negatively. The bar:
    **respectful, never racist**"* (`canon:§4 "Depiction register"`, `myth:219-233`).
  - **Hard tonal rule:** *"gods are **morally alien** throughout — addicted, bored, starving
    for spectacle. **No redemption, no hidden benevolence, nothing to twirl a mustache**"*
    (`canon:§4`).
  - **Where the corporate voice goes:** *"**Modern major religions = investor institutions**
    … present as **large corporations**: … **messenger-tier figures (Metatron, Gabriel …)
    appear as corporate staff** — suits and org-chart rank"*; *"**the three Abrahamic brands
    are fronts of ONE holding company** — a market-segmentation front to sell more product
    and multiply gambling opportunities. **Play it deadpan-corporate, diegetic satire in the
    casino's register**"* (`canon:§3`, `myth:204-217`).
  - **Two-register discipline:** *"**Showbiz over grief.** The broadcast plane is comedy —
    announcer patter, absurd loot, mocking achievements; the diegetic plane underneath
    carries the dread and the tenderness. The tension between the two planes IS the tone"*
    (`narr:41-45`); `rev6:43-48` names the same split the *tonal firewall*.
  - **Casino diegesis for economy language:** *"comps, markers, tips, the odds board"*
    (`narr:152-154`); *"Corporate-satire item copy gets re-voiced (house merchants, 'the
    house claims no responsibility…') — **modest rewrite, same joke engine**"* (`rebrand:61-62`).
- **Verdict:** **RESKIN** **Effort:** **L** (whole-book pass; ~40–60 lines in my sections)
- **Why:** this is the largest single work item in the slice and the one most likely to be
  under-estimated. The good news is structural: the corporate-satire *engine* is not deleted,
  it is handed to a new owner (the investor-religions and the house), so the writer's job is
  substitution rather than invention. The genuinely *new* register work is the mythology
  layer on top — and the "morally alien, not evil" rule is the constraint that most v1 lines
  violate: `book:9-13` gives the Corporation a *motive and a threat*, which is exactly the
  mustache-twirling v2 forbids.
- **Already decided?** Yes, comprehensively — `canon:§4`, `myth:204-238`, `narr:41-45`,
  `rebrand:61-62`.
- **Open question for the owner:** none on register. One on *rating*: `patron:73` flags
  *"depictions of modern religions carry rating/controversy weight — a deliberate handling
  decision for the roster pass, owner's IP call"*, and the register ruling
  (`myth:219-233`) drops the per-figure gate. That interacts with the book's voice, but it
  is a roster decision, not a framing one.

### A-11 — The two information planes (absent from the book; `dir:149-163`)

- **v1 (alien):** **not in the rulebook at all.** Grep-verified: zero occurrences of
  "announcer", "information plane", or any statement about what contestants can and cannot
  hear. The book has an audience mechanic (§17) with no epistemology.
- **v2 (gods):** ruled and load-bearing. *"**Contestants are INSIDE the show — they never hear
  the announcer.** … **Broadcast plane** (spectators, replays, dead-teammate spectating,
  Stage-2 viewers): the announcer explains everything. **Dramatic irony is the product** …
  **Diegetic plane** (contestants): consequences arrive as *world manifestations* … and
  **a sudden quest**"* (`dir:149-163`). `rebrand:19` lists it among the seven things the new
  frame **MUST preserve**. Patron boons obey it too: *"Contestants never hear the casino.
  Boons arrive diegetically — a comp package in the loot drop, an inexplicable kindness of
  the dungeon"* (`patron:199-203`).
- **Verdict:** **NEW** **Effort:** S (one §1 subsection)
- **Why:** it is the rule that makes every other v2 flavour decision resolvable — it tells an
  author which of the two registers a given line belongs to (A-10), it justifies the
  contestant/champion noun split (A-06), and it is the mechanism by which patron gods can
  exist without contestants knowing gods exist. The book currently implies the opposite by
  addressing the reader as someone who knows they're on television (`book:9-13`).
- **Already decided?** Yes — `dir:149-163`, `rebrand:19`, `patron:199-203`, `narr:196-198`.

### A-12 — Charm defined as "camera-ready / photogenic" (`book:52-56`; R18 `add:594-601`)

- **v1 (alien):** *"**Charm** — **presentability**: how objectively camera-ready you are —
  photogenics, striking looks, visual impressiveness. Charm 5 = 'cinematic gravity, the scene
  favors you.'"*
- **v2 (gods):** **survives verbatim.** R18 is a 2026-07-16 owner clarification made *after*
  the frame swap and it doubles down on the camera reading: *"**Charm is NOT charisma.** It
  measures **how PRESENTABLE you are — objectively aesthetic as compared to others.** The
  camera-facing stat … Existing formulas stay coherent under this reading (Charm /20 → Camera
  Call stacks: **the camera seeks the aesthetic**)"* (`add:596-601`). The camera is diegetic
  under v2 (A-07), so nothing breaks. The available *flavour* upgrade, which nothing rules:
  under gods, presentability is what makes the odds board turn to you — *"Camera Call → **The
  odds board turns to you** — all stakes on you double"* (`rebrand:34`) — and choosing
  champions for being *striking* is mythologically native (Ganymede/Helen shape). INFERRED,
  offered as flavour only.
- **Verdict:** **RESKIN** **Effort:** S
- **Why:** the deeply-TV-coded definition turns out to be the *least* endangered thing in my
  slice, precisely because R18 was ruled after the casino was adopted and the camera survived
  the swap. Nothing mechanical changes. Do not treat "camera-ready" as a v1 residue.
- **Already decided?** Yes — R18 (`add:594-601`), post-dating the frame ruling; `rebrand:116-119`
  keeps camera mechanics untouched.

### A-13 — Charm's off-stat pointer sentence (`book:54-56`)

- **v1 (alien):** *"Charm is not warmth or likability — those live in **the audience's
  reaction to you (Tags and crowd response)**, never in the number."* — a **two-way** split:
  the number, and the audience layer.
- **v2 (gods):** the audience layer has split into **three** tracks, all ruled:
  1. **Crowd tags** — *"the audience's labels"*, performable and fakeable (`patron:146`).
  2. **Patron/god affection** — a per-god ledger, a pure function of the event log
     (`patron:177-183`, `patron:190-194`).
  3. **Epithets** — *"the pantheon's comparisons"*, earned by trait accumulation + myth
     recreation, deliberately a separate track (`patron:126-147`).
  `story:82-88` makes the separation thematic: *"**Tags = how the AUDIENCE labels you**
  (public identity, performable, fakeable). **The question axes = what your choices reveal you
  to BE** … The two systems should be kept deliberately separate and occasionally
  contradictory."*
- **Verdict:** **RESKIN** **Effort:** S
- **Why:** it is a one-sentence edit with outsized effect: this sentence is the book's only
  statement of *where the social layer lives*, and a v2 reader who takes it at face value will
  conclude that god affection is a Charm function. It isn't — affection is a deed function.
  Getting this wrong makes players build Charm for patron favour, which is the wrong build.
- **Already decided?** Yes for each track (`patron:126-147`, `patron:177-194`, `story:82-88`);
  no ruling exists that *rewrites the book sentence*.

### A-14 — §2.3 Command / Persuade / Intimidate keyed to Charm (`book:99-101` vs `add:596-598`)

- **v1 (alien):** the action→stat table maps *Command → Charm*, *Persuade → Charm + Mind*,
  *Intimidate → Charm + Physique* (`book:99-101`).
- **v2 (gods):** R18 explicitly says **"Charm is NOT charisma … Warmth, likability, and
  parasocial pull live in the AUDIENCE systems … never in the Charm number"** (`add:596-599`).
  Under that reading, a Charm-gated *Persuade* is incoherent — presentability is not
  persuasion. The skills audit already applied R18 to skills and found exactly this class of
  break: `audits/skills-audit.md:95` calls `vibe_control` *"The R18 poster child: projecting
  FEAR/CHARM emotional states reads Charm as social charisma"*, and `:98` moves `voicebox`
  from Charm to Mind because *"mimicry is deception/technique, not being photogenic"*. **The
  §2.3 table was never given the same pass** (verified: the audit covers skills, items, tags,
  enemies, conditions and thresholds — not §2.3).
- **Verdict:** **MECHANICAL** **Effort:** M
- **Why:** it is the only *mechanic* in my slice that is actually broken rather than merely
  re-flavoured, and it is broken in **v1 as well as v2** — R18 is a rules clarification, not a
  setting change. The skills audit shows the fix shape is known (re-read presentability as
  *battlefield/social presence*, or move the primary stat to Mind), and that a stat move has a
  cost: *"owner sign-off since stat moves refund skill points"* (`audits/skills-audit.md:98`).
  In v2 the strain grows: under gods, "Command" and "Persuade" have to work on followers and
  NPC actors, and the social layer is being handed to a Charm-weighted LLM judge
  (`dir:134-148`, *"persuasiveness = Charm + LLM-judged quality of the actual words"*) — so
  §2.3's mapping is about to become load-bearing code, not just a table.
- **Already decided?** R18 is ruled; its application to §2.3 is **not**. The audit's R18 sweep
  was scoped to skills.
- **Open question for the owner:** **re-derive §2.3's three Charm rows under R18** — keep
  Charm as a *presence* term (you look like someone to be obeyed), or move Persuade to
  Mind-primary and leave Charm as a modifier? This is the same "R18 sweep" the skills audit
  flagged for `feint` (`audits/skills-audit.md:90`) and never got.

### A-15 — Body/Core pillars, 7+7 point-buy, 1–5 creation-only scale (`book:44-45`, `book:60-67`)

- **v1 (alien):** two pillars — Body (*"physical — changes more easily"*) and Core
  (*"mental/identity — harder to change"*); 7 points across Body traits + 7 across Core; no
  trait above 5 at creation; the 1–5 scale is creation-only.
- **v2 (gods):** unchanged. R6 re-affirms all of it verbatim as SETTLED (`add:166-180`):
  *"Creation rules unchanged (7+7 across pillars, max 5) … The 'rated 1–5' scale is
  **creation-only** (now stated explicitly)."* One v2-only amendment, already ruled:
  *"**NPC stats fit the CHARACTER, not creation budgets** … authored NPCs ignore both"*
  (`add:589-592`).
- **Verdict:** **KEEP** **Effort:** S
- **Why:** listed to close the question, not because it needs work. The pillar *names* have a
  quiet thematic bonus in v2 — "Core (mental/**identity** — harder to change)" is the exact
  substance the spine proposes to break down (*"how much can we break your essence down"*,
  `story:63`) — so the existing vocabulary supports the v2 theme with no edit.
- **Already decided?** Yes — R6 (`add:166-180`), R16's NPC amendment (`add:589-592`).

### A-16 — Background as the single creation surface (absent from book; `add:579-588`)

- **v1 (alien):** creation is point-buy + race + level 1, full stop (`book:58-72`). Skills are
  *"revealed and unlocked in play"* (`book:71-72`, §4.4). There is **no background step**.
- **v2 (gods):** ruled, and it becomes the *only* creation surface:
  *"**RULED: the background grants the starting skills.** Humans: the background gives **4
  skills**, and any of them may be given up for **+1 cap on another** … Animals work the same,
  with a higher bias toward race skills … Consequence: **the background is now the single
  creation surface** — skills (this ruling) + starting traits (epithet track) + patron-god
  bidding all flow from who you were before the show"* (`add:579-588`).
  The bidding side: *"**The background is the audition tape.** OC creation includes a short
  background — freeform text plus a few structured picks (origin, vice, virtue, what you want
  back home) … **Interested gods bid** … each shown as a deal sheet: domains, generosity,
  temperament — and the god's **EXPECTATIONS: the explicit dos and don'ts** … **The player
  chooses — because only the patron-less can choose** (the ORV rule)"* (`patron:25-42`).
  Epithets seed from it too: *"you start with trait-words (*courageous, strong, hateful,
  avenger, …*) — **seeded from the background picks**"* (`patron:129-131`).
- **Verdict:** **NEW** **Effort:** **L**
- **Why:** this is the biggest *addition* in the slice and it changes what "Making a
  Contestant" means. In v1 the chapter is arithmetic; in v2 it is the moment the game decides
  which god wants you, which epithets you can chase, and which four skills you own — i.e. it
  becomes the game's most consequential screen. It also silently kills v1's *"skills are
  revealed and unlocked in play"* as the *only* acquisition route (`book:71-72`).
  `narr:82-86` confirms the shape and marks the specific picks ⟨PROPOSED⟩.
- **Already decided?** The **ruling** is settled (R16, `add:579-588`; D5, `dir:179-196`). The
  **flow** is not: `patron:240-242` marks *"Bidding flow details — structured picks, 2–3
  offers, deal sheets — remain PROPOSED shaping"*, and `narr:83-85` marks the background picks
  ⟨PROPOSED⟩.
- **Open question for the owner:** nod the four structured picks (origin / vice / virtue /
  what you want back home) — everything downstream (god affinities, epithet trait seeds) keys
  off that list. *Note: "what you want back home" presumes a home to return to, which A-04's
  "winning promotes you into the audience" quietly forecloses — worth a sanity check.*

### A-17 — Race list: Human / Animal / **Robot-AI** (`book:68-70`)

- **v1 (alien):** *"Race: **Human**, **Animal**, or **Robot/AI**. Humans are the default;
  Animals and machines are **rarer abductions** with GM-shaped bodies (a sea lion does not get
  the standard two-arms-two-legs sheet)."*
- **v2 (gods):** **Earth-life only.** *"**RULED: the Robot race is REMOVED entirely.** Playable
  contestants are any living thing on Earth — **Humans and Animals**. Seed data updated; **the
  rulebook's Robot entry becomes TTRPG-only history**"* (`add:576-578`). Verified in seed data:
  `audit:352` — *"(verified: `data/races.json` = `human`, `animal`)"*.
- **Verdict:** **FORK** **Effort:** S (already done on the game side)
- **Why (and this answers the slice's roster question directly):** an alien-abduction roster
  is not merely unnecessary under v2 — **Earth-life-only is the premise-correct roster.**
  Canon says the cycle claims favour *"from **the humans, in the human realm, on Earth**"*
  (`canon:§1`), so the contestant pool is definitionally terrestrial. R16 is therefore
  frame-consistent, not a scope cut. Animals are fine (Earth life). Robots/AI are the casualty
  — and note the *sidebar's* mechanics (A-18) were never about robots specifically.
  The fork is explicit and on record on both sides:
  - book keeps it — *"D-4 | Robot/AI race entry | **RULED: as recommended** — race kept;
    'machines & conditions' sidebar added"* (`plan:114`);
  - game drops it — *"R16 races 'Earth-life only / Robot removed' — **game-only.** The ruling
    itself says the rulebook's Robot entry becomes TTRPG history; **XQUEZ/T (AI) is a live
    table character.** The book keeps Human / Animal / Robot-AI"* (`plan:31-34`).
- **Already decided?** Yes, both sides — R16 (`add:574-578`) and D-4 (`plan:114`, `plan:31-34`).
  The driver is a live-campaign character, not a design preference.

### A-18 — The "machines & conditions" sidebar (`book:74-85`)

- **v1 (alien):** a sidebar re-reading every condition for a Robot/AI body — *"Bleeding =
  structural leaks (hydraulics, coolant, power)"*, poison/infection immunity for pure
  machines, suffocation immunity with an overheating/vacuum substitute, and *"**Dissolution**:
  a mind is a mind. Machines are not exempt."*
- **v2 (gods):** deleted with the race (A-17). Its *job* — describing conditions on a
  non-standard body — is done generally by R21: *"**Body structure: Lego-style part
  composition**"* (`add:670`), plus the animal-parts library
  (`docs/design/animal-parts-library.md`).
- **Verdict:** **FORK** **Effort:** S
- **Why:** worth separating from A-17 because the sidebar is the *better-designed half* of the
  robot entry — it is a general "how do conditions read on a body that isn't a standard human"
  rubric that happens to be written for machines. v2 does not lose the capability (R21 covers
  it), but a v2 author reaching for a worked example of condition re-reading will find the
  robot sidebar and think it's dead. It's dead *as a race*; the pattern is live.
- **Already decided?** Yes — R16 + D-4 fork (as A-17); R21 (`add:670-694`) for the replacement
  mechanism. `plan:43-45` confirms the book keeps GM-statted animal bodies instead of R21.

### A-19 — Contestant-animals vs. god-followers: the creature taxonomy (`book:68-70`; `canon:§6`)

- **v1 (alien):** everything non-contestant is dungeon content. No taxonomy needed.
- **v2 (gods):** canon introduces a *third* category the book has no word for:
  *"**Monsters:** collateral **followers of gods** dragged into the framework. Three states:
  **Insane Followers** (hostile, XP), **Sane Followers** (aware — traders/allies/quest-givers),
  **Worshipped Creatures** (revered beings, moral dilemmas)"* (`canon:§6`). Meanwhile R16 makes
  ordinary Earth animals **playable contestants** (`add:576-578`).
- **Verdict:** **NEW** **Effort:** M
- **Why:** in v2 an animal on screen can now be any of four things — a contestant (Sasha), an
  insane follower (a mob), a sane follower (a trader), or a worshipped creature (a moral
  dilemma) — and the rules text gives a reader no way to tell them apart or to know which
  rules apply. Sasha sits exactly on the line: *"**Race:** Animal — cat"*
  (`characters/sasha.md:11`) and a recruitable NPC (`story:41-44`). This is a genuine gap
  created by the frame swap, not a v1 defect.
- **Already decided?** The follower taxonomy is canon (`canon:§6`); playable Earth-life is
  ruled (R16). Nothing rules the boundary between them.
- **Open question for the owner:** is a contestant-animal ever *also* a follower of a god (i.e.
  can the roster and the monster pool overlap), or are they disjoint populations?

### A-20 — "Levels are awarded by the GM at milestones" (`book:111`; `add:583-585`)

- **v1 (alien):** *"**Levels are awarded by the GM at milestones** — bosses, floors, major
  achievements. There is no XP curve."*
- **v2 (gods):** *"**RULED (same day): the system grants level/skill points automatically** —
  the TTRPG's admin role is automated in the video game; progression rules issue
  `grant_level`, **no human in the loop**"* (`add:583-585`). R6 codifies the trigger set:
  *"Levels are **awarded by the game** at authored milestones (bosses, floors, major
  achievements) — no XP curve"* (`add:165-168`).
- **Verdict:** **MECHANICAL** **Effort:** S
- **Why:** the *mechanic* is the same (milestone → 1 point into a pool) but the **grantor
  changes from a person to a system**, which is a real change in a book whose §3 is written as
  GM instructions. Book-wide this is one instance of a general v2 problem the compendium
  already logs: *"remove GM-discretion language"*
  (`GPT_Master_Compendium.md:417`, translation debts).
- **Already decided?** Yes — R16 (`add:583-585`), R6 (`add:165-168`).

### A-21 — What a level *is*, diegetically, under gods (absent from the book)

- **v1 (alien):** unstated — the show simply gives you one, and nobody asks why an alien
  broadcaster can make you stronger.
- **v2 (gods):** **still unstated, and it now matters.** The pieces that exist:
  - the house is *"the fallen god's production apparatus; speaks only through Directives and
    System messages (the one legitimate in-fiction HUD channel)"* (`narr:136-137`);
  - patron boons are *dealer tips* — *"`patron_tip(boon|trial, magnitude, target)` emitted by
    the director interface"* (`patron:195-198`) — and arrive diegetically as *"a comp package
    in the loot drop, an inexplicable kindness of the dungeon"* (`patron:199-203`);
  - epithets come from myth recreation, not from levels (`patron:126-147`).
  The clean reading — **the framework grants levels impersonally; gods grant boons
  personally** — is *not written anywhere*. INFERRED.
- **Verdict:** **NEW** **Effort:** M
- **Why:** in a divinity economy, "who made you stronger" is a theme question, not a
  bookkeeping one. If levels are divine gifts, the patron layer loses its exclusivity (why
  court a god for buffs you get for free?); if levels are framework mechanics, the game needs
  a diegetic story for why a gambling apparatus improves its own stakes. The answer also sets
  the register for every level-up message the player will ever read.
- **Already decided?** No.
- **Open question for the owner:** **is a level a divine grant or a framework function?**
  Recommended: framework (keeps patron boons scarce and personal), with level-ups delivered as
  house System messages — but this is a product-intent call.

### A-22 — §3.2 milestone bonuses incl. Charm/20 → Camera Call stack (`book:118-132`)

- **v1 (alien):** four over-10 repeating payouts — Physique /5 → +1 max HP per part;
  Reflexes /12 → +1 physical resistance; Mind /15 → +1 psychic tier;
  **Charm /20 → +1 Camera Call stack** (`book:129`).
- **v2 (gods):** unchanged mechanically. R6 adopts all four formulas verbatim
  (`add:171-175`). Only the *name* "Camera Call" is theme-loaded, and it survives per A-07 —
  `rebrand:34` gives the optional casino re-read: *"Camera Call → **The odds board turns to
  you** — all stakes on you double."* (§17.3 itself is **slice B**.)
- **Verdict:** **KEEP** **Effort:** S
- **Why:** listed to close it, plus one honest flag that is **not** a v2 issue: the Charm/20
  row is effectively unreachable. `rev1:164` — *"Camera Call self-targeting plausibly doubles
  Patron-Token income … currently **unreachable only because Charm 20 is unreachable**"*; the
  slice playtest confirms the engine needs **Charm 30** for one stack
  (`playtests/slice-playtest-2026-07-19.md:55-59`, `over_cap(charm,20)` at `combatant.gd:193`).
  That is a pre-existing balance defect inherited by v2, not created by it. Do not fix it in a
  framing pass.
- **Already decided?** Yes mechanically — R6 (`add:171-175`); D-3 finalises §17.3's self-call
  and doubling scope for the book (`plan:113`).

### A-23 — §3.3 skill points, §3.4 respec, and the XP-variant aside (`book:134-148`)

- **v1 (alien):** skill points = traitTotal − 1; multi-stat skills cost from each stat;
  *"**There is no free respec or refund, ever.** Unlearning and rebuilding is possible only
  through specific items or **Lounge upgrades**, and always at a cost"* (`book:144-145`); and
  the aside *"(An XP-based variant may arrive in a future edition.)"* (`book:111`).
- **v2 (gods):** skill points and refunds unchanged — R6 adopts the app formula verbatim
  (`add:176-179`). The respec rule survives; only "Lounge" is re-voiced (A-27, and the Lounge
  chapter is **slice C/D**). The XP aside is now stale: *"**AMENDED (owner, 2026-07-17):** an
  **XP system is approved in principle** ('just a matter of how much') — level points may flow
  from XP rules rather than pure grants; amounts are a tuning-pass concern"* (`add:162-164`).
- **Verdict:** **KEEP** (one stale line) **Effort:** S
- **Why:** the whole sub-chapter is theme-neutral arithmetic. The only edit is turning a
  "maybe someday" aside into a recorded ruling. Note the respec rule interacts with A-14: if
  §2.3's Charm rows are re-derived and any skill's primary stat moves, refunds are owed
  (`audits/skills-audit.md:98` flags exactly this).
- **Already decided?** Yes — R6 (`add:162-164`, `add:176-179`).

### A-24 — §9 Shock: tier names and model (`book:577-601`)

- **v1 (alien):** *"Shock is the body's pain response — momentary events, not an accumulating
  pool"*; tiers **T1 Shout · T2 Stutter · T3 Faint · T4 Helpless**; no decay in combat, full
  reset at combat end; Burn T1 inflicts Shock T1 (*"cauterization's price"*).
- **v2 (gods):** **no change required.** Grep-verified: zero TV-coded or alien-coded
  vocabulary in the whole section. Every tier name is a plain physiological word. The one
  adjacent thing that touches theme — the app's button label *"Reset (combat end)"* — is a UI
  string in the character-sheet repo, not the book.
- **Verdict:** **KEEP** **Effort:** S (zero edits)
- **Why:** reported as a clean negative so the v2 pass does not spend time here. The section's
  open item is a *mechanical* one with no theme content — R13's Shock model awaits an owner
  nod (`audit:427-428`, Q21), and `add:495` records R13 as approved 2026-07-17.
- **Already decided?** Mechanically yes (R13, `add:495-520`). Thematically: nothing to decide.

### A-25 — §11 States Glossary (`book:622-632`)

- **v1 (alien):** Exposed · Helpless · Prone · Slowed · Channeling · Overwhelmed · Alerted.
- **v2 (gods):** **no change required.** Grep-verified: zero TV-coded vocabulary. "Channeling"
  is the multi-Moment-action sense (*"= performing a multi-Moment action … the word adds no
  new state"*, `book:630`), not a TV channel — it is a spellcasting word and survives. R7
  re-affirms the whole glossary (`add:186-202`).
- **Verdict:** **KEEP** **Effort:** S (zero edits)
- **Why:** reported as a clean negative, with one naming observation worth carrying: **"Exposed"
  (a combat state, `book:626`) collides with "Exposure" (the audience-attention system,
  §17.1 `book:870`)** — two unrelated systems, one root word, already confusing in v1. Slice
  B's casino re-voice of §17.1 (odds / stakes / attention vocabulary) would **incidentally fix
  the collision at zero cost.** Flag it to B as a free win rather than fixing it here.
- **Already decided?** Yes mechanically — R7 (`add:186-202`). The collision is unaddressed
  anywhere.

### A-26 — §16 Med Bay invoice + "costs the Corporation more" (`book:856-863`)

- **v1 (alien):** *"The full medical restore is **INVOICED** at the **Med Bay** (§20.3):
  **`Floor × 2^(claims already made this floor)` Upgrade Tokens** per contestant … Premiums
  rise with every claim and every floor deeper — **hazard pricing, itemized, on camera.**"*
  and *"**Bleed-out stabilization is always free.** Losing the contestant costs **the
  Corporation** more than stabilizing them. **Almost always.**"*
- **v2 (gods):** the same joke in casino vocabulary. `rebrand:36` — *"The Lounge (corporate
  base) → **The comp suite** — the house always comps your room; surveillance = the house
  watching its assets"*; `narr:152-154` — *"casino diegesis for all economy language (**comps,
  markers, tips, the odds board**)"*; `rebrand:61-62` — *"Corporate-satire item copy gets
  re-voiced (house merchants, 'the house claims no responsibility…') — **modest rewrite, same
  joke engine**."*
- **Verdict:** **RESKIN** **Effort:** S
- **Why:** the escalating-invoice mechanic is untouched; only the biller changes. The casino
  reading is *tighter* than the corporate one: a house that comps your room but extends you a
  **marker** for the med bay, at rising vig the deeper you go, is a real casino behaviour and
  a sharper joke than an itemized invoice. The free-stabilisation line survives with one word
  swapped ("the house"), and its cynicism (*"Almost always"*) is exactly the morally-alien
  register (`canon:§4`).
- **Already decided?** Yes for the vocabulary (`rebrand:36`, `rebrand:61-62`, `narr:152-154`,
  `audit:359`). The specific comps-vs-marker framing is INFERRED.
- **Open question for the owner:** worth one line — is the med bay a **comp** (free, the house
  keeps its asset playing) or a **marker** (credit at rising vig)? The existing escalating
  price says marker; "the house always comps your room" says comp. Both are fine; pick one so
  the §16 and §20 copy agree.

### A-27 — §16 downtime's diegetic identity (`book:852-855`)

- **v1 (alien):** *"**At the Lounge:** **Free rest** (Dormitories): resolvable conditions
  resolve over a downtime — time heals sickness — but HP trickles back at only **+1 per part
  per downtime**."* Downtime = time in the Corporation's base between broadcasts.
- **v2 (gods):** the Lounge is the **comp suite** — *"the comp suite you physically enter, and
  the EXCLUSIVE place where you **open loot**, **review contract changes** (patron deal
  updates, buy-out notices), and **tinker your character and run**"* (`gdd:237-240`, RULED
  2026-07-16 — a walkable stage, not menus); *"the **Lounge** (comp suite — the house always
  comps your room; surveillance = the house watching its assets)"* (`narr:145-147`).
  Pacing is diegetic too: *"Time skips between floors (**the framework fast-forwards the host
  realm — gods skip the boring parts**)"* (`narr:75-77`, from `rebrand:39`).
- **Verdict:** **RESKIN** **Effort:** S (my §16 lines; §20 itself is **slice C/D**)
- **Why:** §16's rules are unchanged; what changes is *what downtime is*. The v2 reading adds a
  meaningful beat v1 lacks — the comp suite is where **contract changes** (buy-out notices,
  patron deal updates) are read (`gdd:238-239`), so downtime becomes a narrative station, not
  just a healing station. The "surveillance = the house watching its assets" reading also
  preserves the compendium's design note that *"Lounge downtime is a spectacle dead-zone —
  make surveillance bite"* (`GPT_Master_Compendium.md:351`).
- **Already decided?** Yes — `gdd:237-240` (RULED), `rebrand:36`, `narr:145-147`, `audit:359`.

### A-28 — §16 "wounds are content, and the audience loves a limp" (`book:864`)

- **v1 (alien):** *"Deliberately harsh: **wounds are content, and the audience loves a limp**."*
- **v2 (gods):** **survives unchanged and improves.** The audience is gods who are *"addicted,
  bored, **starving for spectacle**"* (`canon:§4`), and the tonal rule is *"the funniest
  moments are someone's worst day, on air"* (`narr:45`).
- **Verdict:** **KEEP** **Effort:** S (zero edits)
- **Why:** carried as a row because it is the **model line for the whole re-voice (A-10)**:
  it is corporate-sardonic *in structure* but names no corporation, so it transfers for free.
  When rewriting v1 copy, the test is "does this line name the Corporation, aliens, Earth, or
  colonization?" — if not, it almost certainly survives. `rebrand:96-97` makes the general
  claim: *"gods wagering on Nikita's song is **more** devastating than a corporation doing it."*
- **Already decided?** Yes by implication — `canon:§4`, `narr:41-45`.

### A-29 — The title "Galactic Prime Time" (`book:1`; `rebrand:158-159` vs four docs)

- **v1 (alien):** `book:1` — *"# GALACTIC PRIME TIME — System Rulebook"*. Fully TV-coded:
  "prime time" is a broadcast-scheduling term, "galactic" is the alien reach.
- **v2 (gods):** **ruled KEEP, then carried as OPEN by four downstream documents.** State,
  exactly as found:
  - **Ruled keep:** `rebrand:158-159` — *"~~**The title.**~~ **RULED 2026-07-16: keep
    'Galactic Prime Time' for now** (it survives diegetically as the show's in-world name;
    revisit only if a rename earns it)."* Reasoning at `rebrand:116-119`: the VIP table's skin
    IS a human reality show, so an in-world show title is *correct*, not residue.
  - **Still carried OPEN, all dated 2026-07-16 or later:**
    `dir:197-198` (*"Still open from the frame swap: TTRPG-table re-skin?, Momus shared vs
    sibling host, **title**, the timer"*) · `gdd:11` and `gdd:397-398` · `brief:8` and
    `brief:143-144` (*"title (this working title is TV-frame)"*) ·
    `brief/.decision-log.md:13` · `narr:3` (*"project: 'Galactic Prime Time ⟨working title —
    OPEN⟩'"*) and `narr:241-245`.
- **Verdict:** **KEEP** (per the ruling) **Effort:** S (reconcile five documents)
- **Why:** the title question is *already answered by the frame*, and the answer is
  counter-intuitive enough that it keeps getting re-opened: because the gods built a table
  themed on human pop culture, a show called "Galactic Prime Time" is precisely what they
  would name it. The word "Galactic" stops being a claim about who runs it and becomes
  show-branding — the kind of overreaching title a real broadcaster picks. **Do not re-decide
  this; reconcile the docs to the ruling or retract the ruling.**
- **Already decided?** **Yes — `rebrand:158-159`.** Four docs have not caught up.
- **Open question for the owner:** confirm the 2026-07-16 ruling stands, so the four OPEN
  listings can be closed in one edit.

### A-30 — The announcer / host (zero occurrences in the book; `rebrand:157` vs `dir:197`)

- **v1 (alien):** **the rulebook has no announcer.** Grep-verified across all 1315 lines: zero
  matches for "announcer"; zero standalone "host". The audience exists as counters (§17.1) with
  no voice. `rev6:34-41` names this the frame's biggest narrative hole: *"**Weak — the show has
  no faces.** For a reality-TV story, the missing cast is the *production*: there is no named
  announcer, no producer, no showrunner AI … Dungeon Crawler Carl works because the production
  is *personified*."*
- **v2 (gods):** the host exists and is named — with the same ruled-vs-open drift as A-29:
  - **Ruled:** `rebrand:157` — *"~~**Momus?**~~ **RULED 2026-07-16: MOMUS, shared host**
    across the novel and the game."* `narr:178` repeats it: *"Host: **Momus, shared with the
    novel (RULED)** — never breathes between sentences."* Character detail at `canon:§4`:
    *"**Momus** hosts/announces (bible): pink tuxedo 'as if a flamingo decided it wanted to be
    human,' never breathes between sentences, unseen laughing audience, sign-off *'This is
    Momus. Stay tuned!'*"*
  - **Still open:** `dir:197-198`, `gdd:397-398`, `brief:143`, `narr:92` (*"the house voice;
    host identity **OPEN** (Momus shared with the novel vs a sibling)"*), `narr:241-245`.
    `narr:108-110` also carries *"**Production cast: MISSING (rev-6 finding, OPEN)**"*.
    Note `narr` contradicts **itself** — RULED at line 178, OPEN at lines 92 and 244.
  - `rebrand:33` frames the win: *"The announcer we needed (rev-6 gap) → **Momus already
    exists**."*
  - `audit:370` warns against re-deriving the gap: *"(absence) no announcer anywhere in the
    compendium → **Momus RULED shared host** (rebrand decision 4) — don't re-derive 'the game
    lacks an announcer' from the compendium."*
- **Verdict:** **NEW** **Effort:** M
- **Why:** this is a *content* gap, not a reskin: even with Momus ruled, the rulebook needs an
  announcer to exist as a rules-relevant entity — he is the voice of the broadcast plane
  (A-11), the reason dramatic irony is deliverable, and the delivery vehicle for Directives
  and Camera Calls. The book currently makes the audience mechanically present and narratively
  mute, which `rev6:34-41` identifies as the frame's weakest point. Adding him also imports the
  register (A-10) in a single character.
- **Already decided?** **Momus: yes** (`rebrand:157`, `narr:178`, `canon:§4`) — with four docs
  and one self-contradiction still carrying it OPEN. **Production cast beyond the host: no**
  (`narr:108-110`, ⟨PROPOSED⟩ solution: grow it from the patron roster).
- **Open question for the owner:** confirm the Momus ruling stands (shared with the novel) vs
  a sibling host, so `dir`/`gdd`/`brief`/`narr` can be reconciled.

---

## Vocabulary sweep

Whole-book grep of `/home/user/Galactic-Prime-Time/rulebook/gpt-system-v1.0.md` (1315 lines),
case-insensitive counts. **"Mine"** = occurrences inside slice A's sections
(front matter, §1, §2, §3, §9, §11, §16).

| Term | Count | Mine | Chapters | Proposed v2 term |
|---|---|---|---|---|
| **Corporation** | 13 | **2** (`:9`, `:863`) | front matter, §16 · **B**: §17.5 (`:919,923,925`), §18 tags (`:1040,1077`) · **C/D**: §19 (`:1130,1156,1159,1163`), §20 (`:1181,1185`) | **the house** — the fallen god running the table (`narr:136-137`; `audit:358`) |
| **camera / Camera** | 16 | **2** (`:52` Charm, `:129` Camera Call) | §2.1, §3.2 · **B**: §17.3 (`:895,900,906`), §18 tags (`:976,1004,1027,1056,1061`) · **C/D**: §16 (`:861`), §20 (`:1183,1233`) | **keep** — the camera is diegetic (`rebrand:111-119`); optional casino re-read "the odds board turns to you" (`rebrand:34`) |
| **audience** | 17 | **5** (`:11,17,28,55,864`) | front matter, §1, §2.1, §16 · **B**: §15 (`:837`), §17 (`:868,904,910,923`), §18 (`:1057,1077,1093,1099-1100`) · **C/D**: §19 (`:1147`) | **keep** — the audience is gods; tiers become god-tiers (slice B owns §17.1) |
| **crowd** | 36 | **2** (`:32,55`) | §1, §2.1 · **B**: §15 (`:839`), §17 (`:908,910,954`), §18 tag copy (28×) · **C/D**: §19 (`:1127`), §20 (`:1224`), §21 (`:1267`) | **keep** — "crowd" is the audience's voice and survives the swap (`audit:26`, 79/100 tags kept) |
| **contestant** | 14 | **5** (`:25,75,858,862,905`) | §1, §2.2, §16 · **B**: §4.4 (`:198`), §8.3 (`:565`), §17.3 (`:905`), §18 (`:980`) · **C/D**: §19 (`:1155`), §20 (`:1181,1195,1214×2,1226`) | **keep "contestant"** (broadcast plane); **"champion"** is the wager-plane noun (`canon:§1-2`, `patron:41`) — see A-06 |
| **show** (noun) | 12 | **5** (`:12,15,18,23`, §1 heading) | front matter, §1 · **B**: §18 (`:965,978`) · **C/D**: §20 (`:1183`) | **keep** — the VIP table's diegetic skin is a show (`rebrand:111-119`) |
| **broadcast** | 4 | **2** (`:26,35`) | §1 · **B**: §18 tags (`:1111,1112`) | **keep** the noun; **cut "alien-"** (A-07) |
| **human** | 7 | **3** (`:25,63,68`) | §1, §2.2 · **C/D**: §7.1 (`:415`), §12.4 (`:722,724`) | **keep** — the cycle claims favour from the human realm (`canon:§1`); §7/§12 uses are anatomical |
| **abduct / abduction** | 3 | **3** (`:9,25,69`) | front matter, §1, §2.2 | **no v2 equivalent** — CUT (A-01); replaced by the quarter-millennial binding-weakening (`canon:§1`) |
| **alien** | 2 | **2** (`:9,26`) | front matter, §1 | **no v2 equivalent** — CUT. (NB: "morally alien" is v2's *register* term for gods, `canon:§4` — different sense, don't conflate) |
| **channel** | 5 | **2** (`:626,630` "Channeling") | §11, §4.5 (`:245`) · **B**: §18 tag (`:1117`) · **C/D**: §19 (`:1159`) | **keep** — §11/§4.5 are the spellcasting sense, theme-neutral (A-25); `:1117` and `:1159` are TV/retail senses → slice B/C-D |
| **episode** | 3 | 0 | **B**: §18 tag "Anime" (`:1023`, ×2) · **C/D**: §20 Kitchen (`:1214`) | **keep** — diegetic under the reality-show skin; flagged to B/C-D |
| **ratings / TV rating** | 2 | **1** (`:12`) | front matter · **B**: §17.1 (`:879`) | front-matter instance dies with A-03/A-04; §17.1's is **slice B** (casino: odds / stakes / divinity) |
| **galax- (galaxy/galactic)** | 2 | **1** (title `:1`) | title · **B**: §17.1 (`:872` *"Entire galaxies are watching"*) | **title: keep** (A-29 — show-branding); **`:872`: rewrite** → the gods are watching (slice B) |
| **coloniz-** | 1 | **1** (`:10`) | front matter | **no v2 equivalent** — CUT (A-03) |
| **Earth** | 1 | **1** (`:10`) | front matter | the *word* survives with an inverted role: Earth is the **host realm**, not the target (`canon:§1`) |
| **spectacle** | 4 | **1** (`:27`) | §1 · **B**: §15 (`:838`), §17.4 (`:910`) | **keep** — gods are "starving for spectacle" (`canon:§4`) |
| **screen** | 2 | 0 | **B**: §18 tags (`:1062` "Direct to DVD", `:1101` "Blue Screen") | slice B; both are crowd-voice tag names, likely KEEP |
| **prime time** | 1 | **1** (title `:1`) | title | **keep** (A-29) |
| **announcer** | **0** | 0 | — | **NEW** — the book has no announcer at all (A-30); v2 host = **Momus** (`rebrand:157`) |
| **host** (standalone) | **0** | 0 | — | as above |
| **producer / network / sponsor / studio / footage / airtime / advert / commercial / franchise / season** | **0** each | 0 | — | nothing to change — the book never used them |

**Sweep conclusions**

1. The alien/colonization layer is astonishingly **thin**: `abduct` ×3, `alien` ×2,
   `coloniz` ×1, `Earth` ×1 — **7 words, 6 of them inside the 6-line front-matter blurb.**
   Deleting `book:8-13` and `book:25-26`'s "alien-" removes essentially the entire
   alien premise from the rulebook.
2. The **TV layer is thick and mostly survives** (`camera` 16, `audience` 17, `crowd` 36,
   `contestant` 14, `show` 12) because `rebrand:111-119` made the broadcast diegetic. This is
   the single highest-leverage ruling in the whole slice.
3. The **Corporation layer is thin but structural** (13 occurrences), and a 1:1 noun swap to
   "the house" clears it. Only 2 of 13 are mine.
4. `producer`/`network`/`sponsor`/`studio` return **zero** — the book never personified the
   production, which is precisely `rev6:34-41`'s finding and A-30's gap.

---

## Cross-cutting observations

1. **The fork question (A-00) gates everything.** The newest document (`plan:6-9`, 2026-07-23)
   says the casino is *"NEVER ported to TTRPG"* and that *"any sentence that needs the word
   'god' does not belong in the book"* (`plan:27`); an older one (`rebrand:155-156`, 2026-07-16)
   says the live table re-skins. Three concrete divergences already exist under the fork
   position (races D-4, tags D-6, "Patrons remain paying audience members, never gods"), so
   the fork is *operationally in force* whether or not it was ever formally approved.
   **Recommendation: treat this inventory as a v2 spec, not a book edit list, until the owner
   says otherwise.**

2. **A ruled-vs-open drift runs through four documents and is not limited to my slice.**
   `rebrand:145-164` marks decisions 1–6 RULED on 2026-07-16; `dir:197-198`, `gdd:397-398`,
   `brief:143-144` and `narr:241-245` all still list **title · host · TTRPG re-skin · timer**
   as OPEN, and `narr` contradicts itself (Momus RULED at `:178`, OPEN at `:92` and `:244`).
   This is a documentation-hygiene problem with real cost: two of the four items are my
   slice's headline deliverables. **One reconciliation edit closes all four in every doc.**

3. **The frame swap is cheap where the mechanics live and expensive where the prose lives.**
   Every mechanic in §2, §3, §9, §11 and §16 is theme-neutral and survives — R6 and R7 already
   re-affirm them verbatim. The cost is concentrated in (a) the voice pass (A-10, effort L) and
   (b) one genuinely new system, background-driven creation (A-16, effort L). `rebrand:101-104`
   said this in advance: *"This is a FRAME swap, not a redesign — the engine doesn't know who's
   watching."* My sweep confirms it empirically.

4. **The corporate-satire voice does not die; it changes employer.** The most useful thing I
   found for the writing pass: v2 keeps a deadpan-corporate register, re-pointed at the
   *investor religions* (`canon:§3`, `myth:204-217`) — *"the three Abrahamic brands are fronts
   of ONE holding company"* — plus casino comps/markers vocabulary for the economy
   (`narr:152-154`). So `book:860-863`'s itemized hazard pricing does not become *less* funny;
   it becomes a casino marker. The joke engine is preserved; only its target moves.

5. **R18 (Charm = presentability) is the one place where v1 is *already* broken, independent
   of the frame.** §2.3's Command/Persuade/Intimidate rows contradict it (A-14), and the
   skills audit found the same class of break in three skills but never swept §2.3. In v2 this
   stops being cosmetic: Charm becomes an input to the social director's speech scoring
   (`dir:134-148`). This is my slice's only true MECHANICAL-and-urgent item.

6. **The v2 frame *fixes* two inherited problems for free.** (a) The Exposed/Exposure name
   collision (`book:626` vs `book:870`) disappears if slice B re-voices §17.1 into casino
   vocabulary. (b) The tag system's TVTropes-sourcing dependency is replaced by the epithet
   track (`rebrand:38`, `patron:126-147`). Neither needs work in slice A — flag both to B.

7. **The premise inversion changes the contestant's opening emotional position, and downstream
   content still assumes v1.** v1: you were *taken* by someone who chose you. v2: you were
   *caught* by a cosmological event that chose nobody. `characters/contestant-template.md:10`
   still asks *"Why the Corporation picked them (what makes them good TV)"* and
   `characters/sasha.md:14` cites *"pre-abduction surveillance"* — both need a v2 question
   (which table, which god noticed you, what your background made you worth bidding on).

8. **Two nouns, two planes — an unwritten but clean rule.** "Contestant" (the show's word) and
   "champion" (the gods' word) are both live in v2 canon and map exactly onto the two
   information planes. Writing this down once (A-06) prevents a future author from normalising
   one away and would give the register pass a mechanical test for which word to use in any
   given line.

---

## Open questions for the owner

Ordered by how much downstream work they unblock.

1. **[A-00 — blocks everything] Does the live TTRPG book adopt the Cosmic Casino, or does the
   casino stay video-game-only?** `rebrand:155-156` says re-skin; `plan:6-9` (newer, and
   partly executed) says never. Three divergences (races, tags, "Patrons are never gods") are
   already live under the fork reading. Everything in this inventory is either a book edit
   list or a v2 spec depending on this answer.

2. **[A-29 + A-30 — one edit, four docs] Confirm the 2026-07-16 rulings stand: keep the title
   "Galactic Prime Time", and Momus is the shared host.** Both are RULED in
   `rebrand:157-159` and both are still carried OPEN in `dir`/`gdd`/`brief`/`narr` (which also
   contradicts itself). This is reconciliation, not re-decision — unless the owner wants to
   re-open them.

3. **[A-14 — the only broken mechanic] Re-derive §2.3's Command / Persuade / Intimidate under
   R18.** "Charm is NOT charisma" makes Charm-gated Persuade incoherent; the skills audit
   applied R18 to skills and flagged an "R18 sweep" that never covered the action table. Note
   a stat move owes skill-point refunds (`audits/skills-audit.md:98`).

4. **[A-21] Is a level a divine grant or a framework function?** Unstated anywhere. It sets
   whether patron boons stay scarce and personal, and it sets the register of every level-up
   message. (My INFERRED recommendation: framework grants levels, gods grant boons.)

5. **[A-16] Nod the four background structured picks (origin / vice / virtue / what you want
   back home).** Still ⟨PROPOSED⟩ (`patron:240-242`, `narr:83-85`); god affinities and epithet
   trait seeds both key off the list. Minor snag worth checking: *"what you want back home"*
   presumes a home to return to, which A-04's "winning promotes you into the audience"
   forecloses.

6. **[A-06] Confirm the contestant/champion register split** — contestant on the broadcast
   plane, champion on the wager plane — so the two live nouns are deliberate, not drift.

7. **[A-19] Can a contestant-animal also be a follower of a god,** or are the playable Earth-life
   roster (R16) and the "followers dragged into the framework" monster pool (`canon:§6`)
   disjoint? Sasha sits exactly on this line.

8. **[A-26 — cosmetic but cheap] Is the Med Bay a comp or a marker?** The escalating price says
   marker; *"the house always comps your room"* (`rebrand:36`) says comp. Pick one so §16 and
   §20 copy agree.
