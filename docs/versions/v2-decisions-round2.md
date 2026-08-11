# v2 Decisions — Round 2 (owner, 2026-08-10)

Answers to the Tier-1 docket in [`v1-v2-fork-spec.md`](v1-v2-fork-spec.md) §8, the
design that falls out of them, and the remaining open questions.

**Status:** Rounds 2 and 3 both ruled. D-01/D-03/D-04/D-06 RULED · D-02 → **Frame-C** · D-05 resolved
against D-01, two residues to confirm.

---

## Part 1 — Rulings

### D-01 — The contestant's stake ✅ RULED

> **The games decide the survival of the person playing them.** Normal humans are unaware
> the games exist until they are pulled in as a participant. **Champions of gods are aware
> ahead of time and have an advantage.** In both cases humans gain **a percentage of the
> divinity earned on them** as part of their advancement — so the divinity shop exists.
> **Humans without a patron god receive more divinity, since their share isn't cut.**
> The participant's personal stake is **their place in the world, and their survival**.
> After the games **everything resets**; only the **winner** remembers what happened, and
> **humanity's path is decided by the winner**.

This closes the hole v1's "go home" left. v1's three-layer stake is restored in full:

| Layer | v1 | v2 |
|---|---|---|
| **Want** | Go home | **Your place in the world after the reset** |
| **Pressure** | Ratings — the only way out | **Survival** — the games decide it |
| **Record** | Tags | Tags + epithets + **the winner's memory** |

**Why this is stronger than v1:** the want and the record fuse at the finale. The winner is
the only one who *remembers*, so memory itself becomes the prize. Everyone else plays for a
life they will not remember earning.

#### 1.1 The divinity economy — the shape this implies

Divinity is a **contestant-facing currency**, earned as a **cut of the wagering on you**.

**Canon support:** `docs/research/mythology/buddhist.md:9` — *"the casino's thesis —
divinity as a spendable, losable currency — is stated here as doctrine, 2,500 years early."*
This **supersedes** [`research/C-economy-lounge-items.md`](research/C-economy-lounge-items.md)
C-13's "divinity is what gods win, not what contestants spend."

**The patron trade — now a complete three-axis decision.** The buff axes already exist at
`design/patron-gods.md:88-101`; D-01 adds the third:

| | Buff focus | Tier odds | Affection | **Divinity income** |
|---|---|---|---|---|
| **With a patron** | Patron's domains get the top multiplier; faction gods a middle one | Better | Channelled to one god/faction | **Cut** — the patron takes their share |
| **Without a patron** | Diffuse — spread across *every* related god | Baseline | Rises neutrally | **Full** — no cut |

> **The trade reads cleanly at a table:** *a patron makes you stronger now; going it alone
> makes you greater later.* Patron-less is not a penalty setting — it is the greedy build.

This also confirms `patron-gods.md:43` (Q6, RULED 2026-07-16): refusing every offer is
allowed and is "simply a patron-less run." It now has a positive reason to exist.

#### 1.2 The two contestant classes

D-01 creates a real creation-time fork, grounded in `cosmic-casino-canon.md:15-16`
(*"Realm-tied deities prepare hidden champions ahead of time; most of humanity is unaware
anything is coming"*):

| | **Champion** | **Civilian** |
|---|---|---|
| Knows the games exist | **Before** being pulled in | Only on arrival |
| Patron | Enters with one | None at start; may be bid on later |
| Advantage | Preparation — the god's investment | None |
| Divinity | Cut | **Full** |

This answers **D-17** (what contestants believe about the audience) diegetically rather
than by fiat: **both knowledge states sit at the same table**, which is a gift for a group
game — the champion knows what the civilian is still working out.

---

### D-03 — Scope of "shapes history for 250 years" ✅ RULED — **THE EVENTS**

> *"Myths are born from events. **Gods get to mess with the religion, winner gets to mess
> with events.**"*

A clean split of authority: **gods author religion; the winner authors events.** This is
broader than my recommendation, and the split addresses part of what worried me — the gods
are not rewriting history, only its interpretation.

**One consequence to state plainly, because it is load-bearing and not reversible later:**
if the winner authors events and this cycle recurs every ~250 years, then **the world as it
stands is the product of a previous cycle's winner** — which places real historical
atrocity downstream of a game. That is exactly the reading `GPT_Master_Compendium.md:430`
guards against, and it is sharpest at Nikita, whose backstory is the Holocaust and the
Eastern Front.

**This is your call and it is made.** The mitigation that costs nothing and preserves the
ruling in full is **D-20's separation rule**: the winner's event-authorship is never
narrated *over* a real atrocity on screen, and Nikita never shares a scene, floor, or
episode with the Abrahamic-corporate satire. Recommend adopting D-20 alongside this.
See **Q-09** for the one question this leaves open.

---

### D-04 — Divine intervention in combat ✅ RULED — **YES, ASSIST + NUDGE only**

Never a to-hit. Preserves the "no to-hit rolls" spine while making the 11 of 24 MVP gods
carrying `luck_gambling` mechanically real. Precedent: §18.2 Nine Lives was already
migrated to the epithet/god track.

---

### D-06 — What artifact is v2 ✅ RULED — **a new edition of the book**

> *"Delta layer. Basically a new edition of the game book so I can run the game to a group
> with the new premise."*

**One distinction matters here, because these two things pull apart:**

- **Delta is the *authoring method*** — v2 inherits the shared spine (§4 of the fork spec:
  all of §5 The Clock, §6, §7, §8, §9, §10, §11, §13, §14, §15, §21.2, §21.5, and the §4
  skill architecture) **by reference, not by rewriting**. One source of truth per rule.
- **But the *artifact* must be standalone.** You cannot run a table from a diff. A GM needs
  one book, front to back.

**Recommendation: single-source authoring, two rendered books.** Keep the shared spine in
one place, mark v1-only and v2-only passages, and render `gpt-system-v1.0.md` and
`gpt-system-v2.0.md` from it. The Wiki's `?raw` import already proves the pattern — it just
needs a second output.

This keeps D-V2's freeze honest (v1's rendered book never changes) while giving you a
runnable v2 edition. It also means a spine fix lands in both books instead of drifting —
which is the exact failure mode that produced the July contradiction.

**Scope estimate for the v2 edition:** ~21 lines of v1-power prose across 11 sections are
genuinely v1-locked. Everything else is either shared spine or the §17 redesign. The large
job is not the delta — it is the **voice pass** (fork spec §5, Tier 3) and **§17**.

**→ Confirm the two-render approach, or say you want a hand-forked second file (Q-10).**

---

## Part 2 — D-02 expanded (your question)

### What the choice actually is

Not a naming preference — **it decides what a contestant experiences.**

| | **Frame-A** — the broadcast is real | **Frame-B** — the broadcast is a metaphor |
|---|---|---|
| Viewers / Followers / Patrons | Keep the names | → spectator gods / devotees / patron gods |
| Camera Call | Keeps the name | → **the odds board turns to you** |
| Directives | Keep the name | → **divine challenges / wagers** |
| The Lounge | Keeps the name | → **the comp suite** |
| Tags | Keep (epithets are separate) | Keep (epithets are separate) |
| **Records touched** | **12 (2.6%)** | **101 (21.9%)** |
| **Cost** | **S — ~1 day** | **L — ~1 week** |
| **What a contestant thinks is happening** | *"I am on a lethal reality show."* | *"I am a piece in a divine game."* |

### Why canon says both

- **Frame-A:** `setting-rebrand-options.md:113-119` (RULED 2026-07-16) — *"Every broadcast
  mechanic (announcer, tags, camera calls, ratings) survives untouched — the DCC separation
  comes from who runs it and why."* And `patron-gods.md:79` — *"Viewers/Followers stay the
  mortal-ish crowd; the Patrons tier = donator gods."*
- **Frame-B:** the mapping table at `setting-rebrand-options.md:30-42` renames all of them.

The mapping table is the *older brainstorm*; the update at `:113-119` is the *later ruling*.

### Frame-C — what D-01 just made available

**D-01 changes this question.** You ruled that **champions know beforehand and civilians
don't**. So the table now contains both knowledge states at once — which means picking one
global vocabulary is the wrong shape.

The system already has the mechanism: **the two information planes** (watchers hear the
announcer; contestants live the world), listed as must-preserve at
`setting-rebrand-options.md:26`.

> **Frame-C — split the vocabulary by plane, not by preference.**
>
> - **Broadcast plane** keeps the show nouns — Viewers, Followers, Camera Call, Directives.
>   This is what the production says out loud and what a **civilian** perceives.
> - **Wager plane** carries the divine nouns — the gallery, devotees, the odds board, the
>   bid. This is what a **champion** already knows and what the GM tracks.
>
> They are the same mechanics under two registers. A civilian who survives long enough
> *learns the second vocabulary* — and that learning is a story beat you get for free.

**Cost: Frame-A's 12 records** (the divine nouns are GM-facing additions, not content
rewrites) — so Frame-C buys Frame-B's fiction at Frame-A's price.

**Recommendation: Frame-C.** It is the only option that uses D-01 rather than ignoring it.
**→ Q-01.**

---

## Part 3 — D-05 resolved against D-01

You asked me to check answer 1 for contradictions. There are **five**. Four resolve; two
residues need you.

### ✅ C1 — "Divinity is spent on advancement" vs "winners accumulate divinity → become gods"

**Not a contradiction — it is the central dilemma.**

> **⚠️ CORRECTED by round 3 (Q-03 + Q-05).** My first resolution was *"spend to survive vs
> bank to ascend."* **That was wrong.** Q-03 rules there are **no non-winning survivors**, so
> a loser's banked divinity buys nothing — banking-to-ascend is strictly dominated by
> spending. The dilemma is real but differently shaped. See **Part 6 §6.2** for the correct
> form: **spend on advancement vs hold as leverage over your patron** (Q-05).

Buddhist canon frames divinity as "spendable **and losable**" (`research/mythology/buddhist.md:9`),
which holds under either reading.

### ✅ C2 — "Everything resets" vs "the retired become patrons" (Ascension as a retirement door)

**Resolved: v2 has no mid-campaign retirement door.** Ascension is a **terminal, graded
outcome** at the end of the games, not an exit you may take early. "The retired become
patrons" survives as an *outcome tier*, not a *door* — which is also why the rulebook never
implemented it (`Ascen*` appears 0 times).

### ✅ C3 — The bible's "become unwagerable" vs "winners join the table as gamblers"

**Same event, two viewpoints — record as reconciled.** You stop being the thing bet upon and
become the one betting. This closes `cosmic-casino-canon.md:191-193`, flagged *"owner to
reconcile"* since July.

### ✅ C4 — v1's Ascension "lets you leave" vs my earlier "v2 is a buy-in with no exit"

**My earlier read was wrong, and D-01 corrects it.** v2 *does* have an exit — the reset.
Everyone leaves. The inversion is not entry-vs-exit, it is **memory**: v1's winner leaves
and remembers; v2's winner is the *only* one who remembers. Everyone else exits into a life
they cannot trace.

That is a better ending than the one the fork spec described, and it needs no new machinery.

### ⚠️ C5 — "Only the winner remembers" vs **this being a group game** — UNRESOLVED

You want to run this for a group (D-06). D-01 says **one** winner remembers and authors
events. In a party campaign that means either the party wins **collectively**, or the
finale turns on the party.

This is the one place D-01 does not yet reach, and it decides the shape of your entire
finale. **→ Q-02.**

### ⚠️ Residue — what a non-winning survivor actually gets

D-01 says survivors keep a "place in the world" but not the memory. My reading: **they wake
into the reset world holding a station they cannot remember earning** — their divinity
balance cashed into a life. Haunting, and it makes every mid-run divinity spend cost
something real.

Marked INFERRED — it is not in canon. **→ Q-03.**

---

## Part 4 — The remaining docket

### New questions raised by round 2 — **ALL RULED 2026-08-10 (round 3)**

| # | Question | **Ruling** |
|---|---|---|
| **Q-01** | Frame-A, Frame-B, or Frame-C? | **Frame-C** — vocabulary splits by information plane |
| **Q-02** | One winner or a collective one? | **One winner** — and winning includes **deciding what to do with those who lose**. A winner *can* delete his enemies from reality, for any reason he likes |
| **Q-03** | What does a non-winning survivor get? | **There are no non-winning survivors.** Anyone who lost deals with the consequences of whoever won |
| **Q-04** | Is the patron's cut fixed or negotiated? | **Negotiated** — per contract |
| **Q-05** | Can you fire a patron mid-run? | **No — unless you hold more divinity than they do, or the contract specifically allows it** |
| **Q-06** | What does the champion's advantage buy? | **Preparation**: champion-specific skills (things not practised in modern daily life) + **guidance from the god — personal intervention** |
| **Q-07** | Do the dead exist in the reset world? | **All the dead are respawned, at the winner's mercy.** He decides who lives and who dies — bounded only by **leaving room for humanity to survive as a race** |
| **Q-08** | Is the winner's authorship played or narrated? | **Played** |
| **Q-09** | Is the current world a previous winner's work? | **Yes.** Atrocities need not be his *direct* influence — they can be a **side effect** of his choices *(e.g. wanting the German people defeated drags a world war behind it)* |
| **Q-10** | Two renders, or a hand-forked file? | **Two renders — and this applies to the character-sheet app as well** |

### Still open from round 1 — Tier 2

| # | Question | Note |
|---|---|---|
| **D-07** | The Exposure ladder under gods — does the **Follower tier survive at all**? | The single biggest §17 decision. *(D-01 helps: Followers can be the mortal crowd whose attention sets the betting line.)* |
| **D-08** | Is a patron's tip a Directive, or a separate channel? | Canon says both |
| **D-09** | With a finite god roster, does a Goal still convert a Patron? | If yes, Patron Tokens gain a hard supply cap and §4.2 skill caps need re-pricing |
| **D-10** | When the odds board turns to you, what doubles? | Spectacle / affection / **the wager itself** — D-01 makes the third option live, since the wager is now your income |
| **D-11** | Do tags carry crowd domains, god domains, or both? | 12 vs 26; only `chaos` overlaps |
| **D-12** | Where do demons live in v2's cosmology? | Three incompatible homes, none ruled. Blocks the whole Medium route. Rec: the house's court |
| **D-13** | **Name the house / the fallen god running the table** | §17.5's rewrite needs the noun; nothing in canon supplies it |
| **D-14** | Approve the **anti-prime** as the curse chassis? | Zero new machinery; unblocks every `trial_table` |
| **D-15** | Pick the Super Boss ladder | Shrine→Temple→Pantheon / Legend→Age-Ender→The House |
| **D-16** | Does the mycelium theme survive? | Rec: keep it, drop only the Corporation's ownership |
| **D-17** | What do contestants believe about the audience? | **Largely answered by D-01** — champions know, civilians don't. Confirm |
| **D-18** | Name the Advanced Fabricator's god | Sharpest tonal risk in the economy slice |
| **D-19** | Legendary / Mythic / Godly — keep, or free the words? | "Godly" becoming literal is an upgrade; "Mythic" running four ladders is not |
| **D-20** | Adopt the Nikita adjacency separation rule? | **Now strongly recommended** — it is D-03's mitigation |

### Still open from round 1 — Tier 3 (housekeeping)

| # | Item |
|---|---|
| **D-21** | Record D-V2 as superseding `setting-rebrand-options.md:155-156` |
| **D-22** | Four items "ruled twice but still listed OPEN" — Momus, title, timer, Forsaken trigger |
| **D-23** | `data/tags.json` is back to 100 rows — does 84 or 100 stand? |
| **D-24** | Mark `setting-rebrand-options.md:38` SUPERSEDED (tags→epithets rename) |
| **D-25** | §2.3 Command/Persuade/Intimidate contradict R18 — **a v1 bug**, fix in v1 |
| **D-26** | The Phase-4 three-way divergence guard was never written |
| **D-27** | **Firearms in v2** — confirm the inference; no v2 doc names guns anywhere |
| **D-28** | The `'Corporate'` SQL enum at `001_initial_schema.sql:212` — the one v1 fiction the freeze doesn't protect |
| **D-29** | Archive rather than migrate the `messages` collection |
| **D-30** | Confirm the contestant/champion register split — **D-01 makes this load-bearing**, not cosmetic |

### Slice-local, low stakes

Farm justification (augury pen?) · Wizard's Tower → Sanctum? · the Goldsmith's "cage"? ·
Box Namer HOUSE lane? · three coupon renames? · Med Bay comp-or-marker? · rename §17.1
"Exposure" (the word is taken twice)? · map top box tiers onto the relic taxonomy? · where
Nine Lives and Unkillable go now both are epithets? · do Skill Tomes split into God Relics
and Follower Relics? · enemy disposition template- or encounter-level? · rename the four
TV-coded skills? Full detail in [`research/`](research/).

---

## Part 6 — Round 3: what the Q-01…Q-10 rulings build

### 6.1 The endgame, as now ruled

```
The games run ──▶ ONE winner ──▶ everything resets
                      │
                      ├── remembers everything (only he does)
                      ├── authors EVENTS (gods author religion)      [D-03]
                      ├── respawns all the dead, and decides
                      │   who lives and who stays dead               [Q-07]
                      └── disposes of those who lost — up to and
                          including deleting them from reality       [Q-02]

  THE ONE LIMIT: he must leave room for humanity to survive as a race.
```

**That single limit is the only constraint on a winner's power, and it is load-bearing** —
it is what stops the ending being arbitrary, and it is the reason the cycle can repeat every
~250 years. Record it as canon.

**The spine now pays off literally.** The campaign's defining question is
*"how much can we break your essence down in the name of entertainment?"*, and the ending
names *what kind of ruler you'll be* (`story-canon.md:63`, `:74-75`). Under Q-02 + Q-07 +
Q-09, that verdict stops being a label and becomes **a test the player actually sits**: you
are handed the authorship that produced this world's atrocities, and what you do with the
people who lost to you *is* the answer. The verdict system no longer has to score the player
— **the epilogue makes him score himself, out loud, at the table** (Q-08: played).

### 6.2 The corrected divinity dilemma — the golden cage, made mechanical

Q-03 kills "bank it to ascend" (a loser's balance buys nothing). **Q-05 replaces it with
something better.** Divinity has exactly two uses:

| Use | Effect |
|---|---|
| **Spend** on the divinity shop | Advancement — you get stronger now |
| **Hold** | **Leverage.** You may break your patron's contract only if you hold **more divinity than the god does** (or the contract allows it) |

> **The trap:** you take a patron for power. The patron cuts your divinity income. That cut
> makes reaching the balance needed to *fire* them slower — **the longer you stay patroned,
> the harder leaving becomes.** Spend to survive the next floor and you never escape;
> hoard to escape and you may not reach the next floor.

This is the Golden Cage as a live, session-by-session decision, and it costs no new
machinery — it falls out of Q-04 + Q-05 alone. It also gives the **negotiated cut** (Q-04)
real teeth: the cut is not flavour on a deal sheet, it is *the interest rate on your
freedom*. A cheap god who takes 40% may be a worse deal than an expensive one who takes 10%.

**Patron-less is now fully coherent:** diffuse, weaker buffs — but the fastest route to a
divinity stock large enough to matter, and nobody to buy your way out from.

### 6.3 Champion skills — a new content pool (Q-06)

Q-06 creates something v1 has no equivalent of: **skills not practised in modern daily
life**, available only to champions, plus **personal divine guidance** as an ongoing
intervention channel.

- The live catalogue's 44 skills are modern-human-shaped (see
  [`research/D-combat-skills-enemies.md`](research/D-combat-skills-enemies.md)) — so this is
  **net-new authored content**, not a reskin. First real content cost v2 has incurred.
- It cleanly justifies the champion/civilian asymmetry as **preparation, not raw power** —
  a champion knows sword forms and rites; a civilian knows how to drive.
- **"Personal intervention" is distinct from D-04's ASSIST/NUDGE** — that was the *buff*
  stream every contestant gets; this is a champion-only *advisory* channel. Confirm they are
  two systems, not one (**Q-13**).

### 6.4 Q-09 — this closes the Nikita concern

Your refinement does the work: the winner sets **intentions**, and history carries the
**consequences** — *"he wanted the German people defeated… and that dragged a world war with
victims and atrocities."*

That is a **causal** relationship, not an **authorial** one. A previous winner did not write
the Holocaust; he wanted something, and the world paid for it in ways he did not specify.
That is recognisable tragic irony, it keeps `GPT_Master_Compendium.md:430`'s guardrail
intact in substance, and it makes Nikita *more* legible rather than less — he is a man
living inside someone else's careless wish.

**Adopt D-20 as the handling rule** (never narrate authorship over an atrocity in scene;
keep Nikita clear of the Abrahamic-corporate satire) and this is closed. **No further
flagging from me.**

### 6.5 Two renders — now including the app (Q-10)

**Frame-C makes this dramatically cheaper than it looks**, and the reason is worth stating:

Frame-C keeps the **broadcast-plane nouns** (Viewers, Followers, Camera Call, Directives).
The app's existing data keys — `exposure.viewers`, `cameraCallUsed`, `objectives.directives`
— **are broadcast-plane names, so they stay valid in v2 unchanged.** The audit already
confirmed all 11 Mongoose models are v1-clean and `grep -riE corporat client/src` returns 0
hits.

So the app's v2 work is **additive**, not a rename pass:

| Work | Shape |
|---|---|
| A `version` field on Character | v1 / v2 — drives everything below |
| A vocabulary map | One label set per version; the wager-plane register is *additional*, not a replacement |
| v2-only state | Divinity balance · patron contract (cut %, clauses) · champion-vs-civilian · epithets alongside tags |
| Wiki route | Renders the matching book |

**The freeze holds:** v1 renders exactly as it does today. Nothing about a v1 character
changes. This is the two-renders principle applied to the app, which is precisely what you
asked for.

**Estimate: M** — the schema additions and the version switch are small; the v2-only
subsystems (divinity, contracts) are the real work, and they cannot be built until the
Tier-2 economy questions land.

### 6.6 One design note on running this for a group

Q-02 + Q-03 + Q-08 together mean: **at the final session, one player decides the fate of the
other players' characters, in scene.** That is a strong, coherent ending — and it is the
kind of thing that must be **declared at session zero, not discovered at the finale.**

Three ways to run it, all compatible with your rulings:

1. **Declared competitive** — "only one of you walks out" is the pitch from session one.
   Strongest version of the premise; needs buy-in up front.
2. **Collectively winnable** — the party can arrive together and the winner is free to
   restore everyone. The choice still gets played (Q-08), the verdict still scores, but the
   table isn't structurally adversarial.
3. **Verdict-determined** — the winner is decided by the question axes rather than by force,
   so it is a moral outcome rather than a PvP one.

**Recommendation: 1 or 3 declared up front.** Not because 2 is weaker fiction — it is
because an unannounced competitive finale is the one failure mode that damages a real table.
**→ Q-11.**

### 6.7 New questions from round 3

| # | Question | Why | Rec |
|---|---|---|---|
| **Q-11** | **Which group-mode do you run** — declared competitive / collectively winnable / verdict-determined? (§6.6) | Must be set before session zero, and it shapes floors 4–9's route exclusivity | 1 or 3, declared |
| **Q-12** | **If you win, does unspent divinity matter?** Does it set what kind of god you become? | Restores an endgame reason to hold divinity beyond the Q-05 leverage | Yes — it grades your godhood |
| **Q-13** | **Is champion "guidance/personal intervention" a separate system from D-04's ASSIST/NUDGE?** (§6.3) | Two channels or one | Two |
| **Q-14** | **What is a god's divinity on the same scale as a contestant's?** Q-05 requires the two be comparable | Without a number, "more divinity than them" is unadjudicable at a table | Publish a rough god-tier ladder |
| **Q-15** | **How many champion-specific skills, and are they a separate pool or a tier of the existing catalogue?** | Sizes the first real v2 content job | Separate small pool (~10–15) |
| **Q-16** | **Can a civilian ever become a champion mid-run** (by accepting a patron), and does that unlock champion skills retroactively? | Decides whether the classes are a start-state or a live track | Yes, but skills stay locked |
| **Q-17** | **Is the "leave room for humanity to survive" limit enforced, or honour-system?** (§6.1) | It is the only bound on a winner's power | Enforced — it's why the cycle repeats |

---

## Part 7 — Round 4: the divinity scale, and what it unifies

**Rulings:** Q-11 … Q-17, 2026-08-10.

### 7.1 Floor 10 is already ruled — in *v1's* book

Q-11 sets Floor 10's reveal as **"only one lives,"** hinted throughout the campaign. That
structure **already exists and is already canon on the v1 side**:

> **RULED (owner, 2026-08-04, ID-0.29):** *"10 floors — three sets of three story floors,
> then **Floor 10: a free-for-all between everyone left**."*
> — `item-drafting-materials.md:10-11`, `item-drafting-passover.md:135-136`, and in the
> rulebook itself at `gpt-system-v1.0.md:759`

**Three consequences:**

1. **The finale's *shape* is shared between v1 and v2.** Only its *meaning* forks — v1's FFA
   decides who walks out; v2's decides who authors the next 250 years. **Add the finale to
   the shared spine** (fork spec §4).
2. **"Stages 4–9" now resolves exactly.** The campaign is `[1–3] [4–6] [7–9] [10]`. Floors
   4–9 are **sets two and three — the entire body of the campaign between the designed
   opening and the exam.** D-V1 was pointing at the whole remaining build.
3. **Floor 10 is "the exam, not a shop"** (`item-drafting-materials.md:42`) — no new
   materials, contested. The v2 reveal lands on a floor already designed to strip everything
   back to what you are.

### 7.2 The divinity scale (Q-14) — divinity is a pyramid, not a number

> **1 divinity = 1 being who reveres you.** Reverence need not be human. **Anyone bound
> under you contributes their divinity to yours** — and if they secede, you lose their
> followers with them, unless those followers revered *you* independently.
> *(Odin and the Valkyries.)*

This is a **vassalage graph**, and it gives Q-05 the scale it was missing:

| Patron | Their divinity | Can you ever out-hold them? |
|---|---|---|
| A major god (Odin-tier) | Their whole pyramid — millions | **Effectively never** |
| A mid god | Their own cult | Late campaign, at cost |
| A minor spirit / bankrupt god | Dozens | **Yes, plausibly** |

> **The bidding decision this creates is excellent, and it emerges rather than being
> designed:** *a big patron gives you the strongest buffs and you will never escape them; a
> small patron gives less and can be bought out.* Q-04's negotiated cut is the second axis.
> Every patron offer is now a genuine dilemma instead of a shopping list.

### 7.3 ⚠️ INFERENCE — Q-14 may close the biggest open question in §17

**This is my reading, not your ruling. It needs a yes/no (Q-18).**

Q-14 defines divinity as **reverence**. §17.1 already defines a tier as **paying watchers
who follow you** (`gpt-system-v1.0.md:874-878`). Those are the same thing at two scales.

| §17.1 tier | v1 meaning | **v2 under Q-14** |
|---|---|---|
| **Viewers** | Active watchers, billions, decay when boring | **Attention** — the transient spectacle meter |
| **Followers** | *Paying* watchers; **they decay** | **Reverence — your divinity itself** |
| **Patrons** | One-time large donors; **roster is permanent** | **Gods with a stake in you** |

If that holds, four problems close at once:

1. **D-07 answers itself.** The Follower tier doesn't just survive — it becomes **the
   divinity generator**. The "phone-vote money" that [`research/B`](research/B-audience-tags.md)
   called *"the most orphaned mechanic in §17"* was the divinity engine all along.
2. **The patron's cut becomes diegetic, not arithmetic.** The cut is the Valkyrie rule
   applied to mortals: **your Followers flow up to your patron unless they revere *you*
   independently.** The negotiated percentage (Q-04) is literally *whose name the crowd says*.
3. **The mortal→god pipeline needs no new machinery.** You ascend with the pyramid you
   built. Your Followers *are* your godhood.
4. **Follower decay is already in the book** — so reverence being losable is v1-native, and
   Buddhist canon's "spendable **and losable**" holds without a special case.

**→ Q-18: is Followers = reverence = divinity, one system at two scales?** If yes, §17's
redesign gets dramatically smaller and I'd fold it into the v2 edition directly.

### 7.4 Q-13 — the third intervention channel, and it answers D-08

> *"A god can also pay-to-win, lowering their winnings but raising chance of success via
> gifting its contractor specific things, with potential conditions on them."*

This is canon's **"tipping the dealer"** made concrete (`cosmic-casino-canon.md:33-34`:
*"gods can tip the dealer to help their luck — boons, buffs, items, or hindering others"*).
v2 now has **three distinct divine-influence channels**, which should be kept separate:

| Channel | Source | Cost to the god | Ruling |
|---|---|---|---|
| **ASSIST / NUDGE** | Ambient buff stream, every contestant | None — it's the domain multiplier | D-04 |
| **Guidance** | Champion-only personal advice | None | Q-06 |
| **Gifting (pay-to-win)** | Specific items/boons, **with conditions attached** | **Lowers their winnings** | Q-13 |

**This substantially answers D-08** ("is a patron's tip a Directive, or a separate
channel?"): the **gift is the carrot; the attached condition is the Directive.** They're
linked, not identical — which is exactly the shape both canon docs were reaching for.

It also gives the god a real economic decision — spend winnings to raise win probability —
and a feedback loop, since a winning contestant generates more reverence to cut. **That's
investment logic, which is the most casino-native thing in the design so far.**

### 7.5 Q-12 — vassal or founder

> *"Unspent divinity can be used to strengthen your hold within the pantheon you joined or
> created."*

**"Joined or created" maps exactly onto the Q-14 vassalage graph**, and makes the last
choice of the campaign a real one:

- **Join** — ascend as a vassal beneath your patron. Protected; your divinity flows upward.
- **Create** — secede and found your own pantheon. Free; exposed; and by the Valkyrie rule
  you take only the followers who revered *you*.

Unspent divinity is your standing in whichever you pick. **This is why Q-05's hoarding
matters after all** — not to ascend, but to arrive *powerful*.

### 7.6 Rulings recorded

| # | Ruling |
|---|---|
| **Q-11** | Floor 10's reveal is **"only one lives"** — hinted throughout, not declared |
| **Q-12** | Unspent divinity strengthens your hold in the pantheon you **joined or created** |
| **Q-13** | Gods may **pay to win** — gifting specific things with conditions, at the cost of their own winnings |
| **Q-14** | **1 divinity = 1 reverent being**; non-humans count; vassals' divinity flows upward and is lost on secession |
| **Q-15** | **10–15 champion skills** to start |
| **Q-16** | A civilian **can** become a champion mid-run |
| **Q-17** | The "leave room for humanity" limit is **enforced** |

### 7.7 New and outstanding

| # | Question | Note |
|---|---|---|
| **Q-18** | **Is Followers = reverence = divinity?** (§7.3) | Biggest open item. If yes, §17's redesign shrinks from L to S |
| **Q-19** | **Table-safety on Q-11.** The reveal stays a reveal — but do the *players* get an out-of-character heads-up at session zero that the campaign has a competitive endgame? | The characters can still be blindsided at Floor 10; the people shouldn't be. Costs the reveal nothing |
| **Q-20** | **Q-16 read as:** yes to becoming a champion mid-run, but **champion skills stay locked** (they're preparation you didn't do). Correct? | One-word confirm |
| **Q-21** | Does a **patron-less** contestant keep 100% of Followers-as-divinity, making patron-less the fastest ascent? | Falls out of §7.3; confirms the trade is balanced |
| **Q-22** | Can a contestant be **gifted followers** by a patron, or is reverence only earned? | Decides whether the cut can run backwards |

---

## Part 8 — Round 5: Followers become a named ledger

**Rulings:** Q-18 … Q-22, 2026-08-10.

| # | Ruling |
|---|---|
| **Q-18** | **Yes** — Followers = reverence = divinity. **But vastly different numbers, and followers are actual, *named* beings** — a village, a person, a god, anything living, but it must be named |
| **Q-19** | **Yes** — players get an out-of-character heads-up at session zero |
| **Q-20** | **Confirmed** — a civilian may become a champion mid-run; champion skills stay locked |
| **Q-21** | **Yes** — patron-less keeps 100%, and is the fastest ascent |
| **Q-22** | **Only earned** — a patron cannot gift you followers |

### 8.1 ⚠️ Sizing correction — §17 goes L → **M**, not L → S

I told you Q-18 would shrink §17's redesign from L to S. **The named-beings refinement makes
that wrong, and I'm correcting it before it becomes a plan.**

v1's Followers are an **abstract decaying count in the billions**
(`gpt-system-v1.0.md:874-878`). v2's are a **named roster of living beings**. That is a
mechanical fork, not a re-skin — the tier changes representation, not just meaning. §17 is
**M**: smaller than a ground-up redesign, larger than a relabel.

### 8.2 The two tiers finally became different things

This is the payoff, and it fixes a weakness v1 has always carried — Viewers and Followers
were two numbers doing similar work.

| | **Viewers** | **Followers** |
|---|---|---|
| Nature | **Mass, anonymous attention** | **Named, individual reverence** |
| Scale | Billions | Small — dozens, not millions |
| Gained by | Spectacle | **Story events** — you saved the village, it now reveres you |
| Lost by | Being boring | Losing what earned it |
| Is | The hype meter | **Your divinity** |

> **Every follower is a name a GM can say at the table.** That is what makes this workable
> in the book (D-06): no GM tracks billions, but any GM tracks *the village of Threshold, the
> smith who owes you, the minor god of doorways.* Reverence stops being a stat and becomes a
> cast list.

**The patron's cut (Q-04) becomes fully concrete:** it is **which named followers are listed
under you, and which under your patron.** The Valkyrie rule, applied at table scale.

**And Q-22 ("only earned") locks the loop honestly** — a patron can buy you power (Q-13's
gifting) but *cannot* buy you reverence. Divinity must be earned in play. The cut can only
ever run one way.

### 8.3 Proposal — this may answer D-09 too

D-09 asked: *with a finite 24-god roster, does a Goal still convert a Patron?* It couldn't
scale — you cannot convert 24 gods repeatedly.

**Under Q-18 it resolves cleanly by moving one rung down the pyramid:**

```
  Goals convert NAMED FOLLOWERS  (repeatable, story-shaped, unbounded)
              │
              ▼
  Your reverence base grows
              │
              ▼
  At thresholds, a GOD NOTICES  ──▶  Patron  (rare, finite, a real event)
```

That preserves §17.2's Patron Tokens as genuine milestones, keeps Goals repeatable, and is
exactly Q-14's vassalage running upward: mortals revere you, which makes you worth betting
on. **→ Q-24.**

### 8.4 New questions

| # | Question | Why it matters | Rec |
|---|---|---|---|
| **Q-23** | **Is a village one entry worth many divinity, or many entries?** Q-14 says *1 divinity = 1 revering being*; Q-18 says a *village* can be a follower | The arithmetic of the whole economy hangs on it | **One named entry, carrying a weight** — the name is the ledger row, the divinity is its value |
| **Q-24** | **Do Goals convert named Followers, with gods taking notice at thresholds?** (§8.3) | Answers D-09 and keeps Patron Tokens meaningful | Yes |
| **Q-25** | **Can a contestant, a defeated enemy, or an NPC become your follower?** "Anything living, but named" suggests yes | Turns mercy and rivalry into economy — a beaten enemy who reveres you is worth more than a dead one | Yes — it makes non-lethal play pay |
| **Q-26** | **Do Viewers stay abstract billions in v2** while Followers are named? (§8.2) | Confirms the two-tier contrast is deliberate | Yes |

---

## Part 9 — Round 6: the ledger closes, and the final batch

**Rulings:** Q-23 … Q-26, 2026-08-10. **The divinity economy is now fully specified.**

| # | Ruling |
|---|---|
| **Q-23** | A village is **one named entry carrying a weight** — the name is the ledger row, the divinity is its value |
| **Q-24** | **Yes** — Goals convert named Followers; at reverence thresholds a god notices and becomes a Patron. **Closes D-09** |
| **Q-25** | **Yes** — a defeated enemy or NPC can become your follower |
| **Q-26** | **Yes** — Viewers stay abstract billions; Followers are named |

### 9.1 Q-25 gives v2 something v1 never had: a reason to spare people

v1's audience economy rewards spectacle, and spectacle rewards violence. **Q-25 puts a
counterweight in the same currency**: a beaten enemy who reveres you is a permanent ledger
row; a dead one is a one-off spectacle spike.

That is not a soft rule bolted on — it is the divinity economy doing it. **Mercy is now the
greedy play in exactly the situations where v1 made cruelty the greedy play**, which is the
sharpest possible expression of the spine (*"how much can we break your essence down in the
name of entertainment?"*) — because now the show is *paying you to stay whole*, and you
still have to choose.

It also makes §21's non-lethal rules and the Forced-Action failure path economically live
rather than merely available.

### 9.2 The complete divinity economy

```
    SPECTACLE ──▶ Viewers        mass, anonymous, decays when boring
                     │            (the hype meter — unchanged from v1)
                     │
    STORY EVENTS ──▶ Followers   NAMED beings · one entry, one weight
       (Goals,          │        villages, people, gods, spared enemies
        mercy,          │        ═ YOUR DIVINITY
        rescue)         │
                        ├──▶ cut flows up to your PATRON
                        │     (Q-04 negotiated — literally whose name
                        │      the crowd says; Q-22 earned, never gifted)
                        │
                        ▼
              at thresholds, a GOD NOTICES ──▶ Patron
                        │
    SPEND ◀─────────────┴─────────────▶ HOLD
  advancement                      leverage — break the contract
  (divinity shop)                  only if you out-hold your patron
                                   (Q-05); and at the end, your
                                   standing in the pantheon you
                                   joined or created (Q-12)
```

**Every rung is now ruled.** No placeholders remain in the economy's *shape* — only its
numbers, which are tuning.

### 9.3 D-13 answers itself — the house has no name

D-13 asked us to name the house / the fallen god running the table. **Q-14 and Q-18 make
the answer structural rather than a naming exercise.**

Canon: the games are run by **gods who went bankrupt** (`cosmic-casino-canon.md` §4).
Q-14: divinity *is* reverence. Q-18: followers must be **named**.

> **Therefore a bankrupt god is, by the rules as written, a god nobody names any more.**
> The house cannot have a name — losing it is what bankruptcy *is*. It is addressed only by
> function: **the House. The Dealer. Management.**

That is mechanically true rather than merely atmospheric, it lands the deadpan-corporate
register canon asks for, and it gives §17.5 its noun without inventing a deity. It also
quietly explains why the house wants the games so badly: **it is trying to be named again.**

**→ Confirm (D-13).** If you'd rather it have a name recoverable late in the campaign, that
works too — and would be a strong Floor-10 reveal.

---

## Part 10 — The final batch

Everything still open, grouped by what it needs from you.

### A. Closed by your own rulings — confirm only

| # | Question | Closed by |
|---|---|---|
| **D-07** | Does the Follower tier survive? | **Q-18 / Q-26** — it survives as the divinity engine |
| **D-09** | Does a Goal still convert a Patron? | **Q-24** — Goals convert Followers; gods notice at thresholds |
| **D-17** | What do contestants believe about the audience? | **D-01 + Frame-C** — champions know, civilians learn |
| **D-08** | Is a patron's tip a Directive or a separate channel? | **Q-13** — the gift is the carrot, the condition is the Directive |
| **D-13** | Name the house | **§9.3** — it has no name; bankruptcy is namelessness |

### B. Need a decision from you

| # | Question | Recommendation |
|---|---|---|
| **D-10** | On a Camera Call, what doubles? | **The reverence swing — both ways.** Camera Call is the moment the crowd decides what you are, so it should double what you stand to gain *and* lose. Double-edged fits "spectacle over safety" and now has a currency to bite with |
| **D-11** | Tags: 12 crowd domains, or the shipped 26 god jurisdictions? | **Both — split by plane, per Frame-C.** Tags carry crowd-appetite domains (broadcast); epithets carry god jurisdictions (wager). Uses the existing data as-is, no reconciliation needed |
| **D-12** | Where do demons live in v2's cosmology? | **The house's court.** Blocks the entire Medium route and the brand contract until ruled |
| **D-19** | Legendary / Mythic / Godly — keep or free the words? | **Keep "Godly"** (now literally true); **free "Mythic"** from at least one of its four ladders before Legendary affixes and epithet grades ship |
| **D-23** | Tags: does **84** or **100** stand? | **100** — the data has been back at 100 since the rulebook-description port; the 84-pruning never landed. Cheaper to bless reality than re-prune |
| **D-27** | Firearms in v2 — confirm | **Yes.** The chain is strong (VIP table = human pop culture; §12.7 already fuses guns with myth) but **no v2 doc names guns anywhere**, so it stays an inference until you say it |
| **D-25** | §2.3's Command/Persuade/Intimidate contradict R18 | **A v1 bug.** v1 is frozen for *setting*, not for errata — but it's your table, so your call whether I fix it in v1, v2-only, or leave it |

### C. Recommend yes — batch-approve and I'll apply

| # | Item | Recommendation |
|---|---|---|
| **D-14** | The **anti-prime** as the curse chassis | Adopt — zero new machinery, unblocks every `trial_table` |
| **D-15** | Super Boss ladder | Bosses **Shrine → Temple → Pantheon**; supers **Legend → Age-Ender → The House** |
| **D-16** | The mycelium theme | Keep it; drop only the Corporation's *ownership* of it |
| **D-18** | The Advanced Fabricator's god | A bankrupt smith-god — also fills the materials corpus's flagged gap |
| **D-20** | The Nikita adjacency separation rule | Adopt — it is D-03's mitigation |

### D. Housekeeping — I can just do these

| # | Item |
|---|---|
| **D-21** | Record D-V2 as superseding `setting-rebrand-options.md:155-156` |
| **D-22** | Close the four "ruled twice, still listed OPEN" items (Momus · title · timer · Forsaken trigger) |
| **D-24** | Mark `setting-rebrand-options.md:38` SUPERSEDED |
| **D-26** | Write the Phase-4 three-way divergence guard that was never written |
| **D-28** | Fix the `'Corporate'` SQL enum at `001_initial_schema.sql:212` |
| **D-29** | Archive rather than migrate the `messages` collection |
| **D-30** | Record the contestant/champion register split |

### E. Slice-local flavour — batch-approve or ignore

Farm → augury pen · Wizard's Tower → the Sanctum · the Goldsmith's "cage" · a HOUSE lane in
the Box Namer · three coupon renames · Med Bay comp-or-marker · rename §17.1 "Exposure" (the
word is taken twice) · map top box tiers onto the relic taxonomy · re-home Nine Lives and
Unkillable now both are epithets · split Skill Tomes into God/Follower Relics · enemy
disposition template- or encounter-level · rename the four TV-coded skills.

---

## Part 11 — Round 7: demons, and who runs each floor

### 11.1 D-12 RULED — demons are a race that reveres demon gods

> *"Demons are a potential race. They can revere demon gods (the 72 demons of Solomon, for
> example)."*

**None of the three options I offered — this is better than all of them.** Demons don't need
a *home* in the cosmology; they slot straight into the structure Q-14 already built:

```
  the 72 goetic spirits  ──  demon GODS (patron-tier, wagering)
            ▲
            │ reverence = their divinity
            │
      demons ── a RACE, and their followers
```

**Three things this gets for free:**

1. **"Demonic nobility" was always literally true.** The Ars Goetia's 72 spirits carry noble
   ranks in the source — **King, Duke, Prince, Marquis, President, Earl, Knight**. The
   existing demonic-nobility fiction and the brand contract need no reinterpretation at all;
   they were Goetic-shaped from the start.
2. **It settles [`research/D`](research/D-combat-skills-enemies.md)'s D-37** (*"do demons get
   re-parented to the extracted goetic roster, or stay an original species?"*) — **re-parented.**
3. **The Medium route unblocks.** The demonic brand contract is a contract with a goetic
   power — an unauthorised second patronage, exactly as
   [`research/G`](research/G-story-encounters.md) predicted, now with a named source roster.

**One check needed:** "potential race" — playable, enemy, or both? R16 currently rules the
playable roster **Earth-life-only**, which demons are not. **→ Q-28.**

### 11.2 The table is run by a succession of gods, not one house

> *"The tutorial floor is 1 god, then every 3 floors are 1 god, then the last FFA floor is
> not a god, but the remains of Earth — the world from where everyone came."*

```
   Tutorial   ──  1 bankrupt god
   Floors 1–3 ──  1 bankrupt god
   Floors 4–6 ──  1 bankrupt god     ◀── D-V1's build target
   Floors 7–9 ──  1 bankrupt god     ◀── D-V1's build target
   Floor 10   ──  NO god. The remains of Earth.
```

**This matches canon better than a single house did.** `cosmic-casino-canon.md` §4 says the
games are run by *"fallen gods — gods who went **bankrupt**"* — **plural**, and never
reconciled to a single runner. It also gives every floor-set a built-in author: the set's
question (`story-canon.md:68`) is now *that god's* question, which is a free, structural
answer to "who is asking?" across floors 4–9.

**Refines §9.3.** The **House** (the institution) stays nameless; the **floor-runners** are
individual bankrupt gods. A bankrupt god has a name — it is just that nobody says it.

### 11.3 ⚠️ INFERENCE — naming a floor-god may be a player lever

**Mine, not yours. → Q-29.**

Q-14: divinity = named reverence. §11.2: each floor is run by a god who went bankrupt —
i.e. who lost their reverence.

> **Then speaking a floor-god's name with reverence *pays them*.** A contestant can choose to
> restore, withhold, or bargain with a floor-runner's divinity — and the floor-runner has an
> obvious motive for running the games at all: **being watched is income; being named is
> recovery.**

If you take it, every floor-set gains a native moral question in the same currency as
everything else, and it costs no new machinery.

### 11.4 Floor 10 on the remains of Earth

The strongest structural beat in the design so far, for three reasons:

1. **You compete *on* the thing you are competing *for*.** The winner authors Earth's next
   250 years — and the FFA is fought on Earth's corpse.
2. **It closes D-01's "no home to return to" honestly.** You don't go home; you face what's
   left of it, and then decide what it becomes.
3. **It completes the reset loop.** Floor 10 is Earth at its lowest; the winner's respawn and
   authorship (Q-07, Q-09) is what rebuilds it. The apocalypse and the restoration are the
   same event seen from either side of the finale.

Removing the god from the last floor also lands the fiction's own logic — **at the end there
is no house, no patron, no audience between you and the world.** Just what you did.

### 11.5 ⚠️ Conflict with a ruled item — the floor count

**§11.2 adds a tutorial floor. The ruled frame has no room for one.**

> **RULED (owner, 2026-08-04, ID-0.29):** *"**10 floors** — three sets of three story
> floors, then Floor 10: a free-for-all between everyone left."*
> — `item-drafting-materials.md:10-11`, `gpt-system-v1.0.md:759`

Tutorial + 3×3 + FFA = **11**. Three ways to reconcile — **→ Q-27**:

| | Reading | Cost |
|---|---|---|
| **a** | **Tutorial is Floor 0** — pre-campaign, outside the count. 10 floors stands | Cleanest. ID-0.29 survives untouched |
| **b** | **Tutorial *is* Floor 1**, and floors 1–3 share one god (the tutorial god) | No new floor; sets stay 1–3 / 4–6 / 7–9 |
| **c** | **The campaign is 11 floors** | Amends ID-0.29, which the item-drafting damage spread is calibrated against |

**Recommend (a)** — it preserves a ruling the item and material tiers are already tuned to,
and a Floor 0 tutorial is the natural home for the civilian's "what *is* this" beat anyway.

### 11.6 New questions

| # | Question | Rec |
|---|---|---|
| **Q-27** | **Floor count** — tutorial as Floor 0, as Floor 1, or an 11th floor? (§11.5) | **Floor 0** — preserves ID-0.29 |
| **Q-28** | **Demons: playable, enemy, or both?** Does this override R16's Earth-life-only roster? | Both — with demon PCs gated behind a story unlock |
| **Q-29** | **Is naming/revering a floor-god a player lever?** (§11.3) | Yes — free moral question per floor-set |
| **Q-30** | **Does the remains of Earth have agency at Floor 10, or is it purely the arena?** | Arena that *reacts* — no voice, no deals |
| **Q-31** | **Are the four floor-gods drawn from the 24-god roster, or are bankrupt gods a separate cast?** | Separate — the roster gods are *wagering*, the floor-runners are *broke* |

---

## Part 12 — Round 8: the batch clears

### 12.1 Rulings

| # | Ruling |
|---|---|
| **D-10** | **Camera Call = double or nothing.** It calls the table to gamble on your *specific declared action*: higher earnings on success, higher loss on failure |
| **D-11** | **Both** — tags carry crowd domains, epithets carry god jurisdictions (split by plane, per Frame-C) |
| **D-19** | Keep **"Godly"** (now literally true); free **"Mythic"** from at least one of its four ladders |
| **D-23** | **100 tags** — the data stands; the 84-pruning is retired |
| **D-27** | ✅ **Firearms are canon in v2** — *"we are in modern reality."* No longer an inference |
| **Q-27** | Tutorial is **Floor 0** — outside the count. ID-0.29's ten floors survives intact |
| **Q-28** | Demons are **NPCs and enemies — not playable, unless a character is *changed into* one** |
| **Q-29** | **Speaking a floor-god's name does not pay them — praying to them does.** A floor-god's goal is to collect enough reverence to **pay the casino back and earn its right of existence** |
| **Q-30** | Earth's remains have **no voice and no agency**. Simply the desolate remains |
| **Q-31** | The floor-runners are a **separate broke cast**, not drawn from the 24-god roster |

### 12.2 D-10 is better than what I proposed

I suggested Camera Call should double the reverence swing. **"Double or nothing on a declared
action" is a stronger mechanic**, for three reasons:

1. **It is a *declared* bet.** The player chooses the moment and names the action. That is
   agency, where a passive multiplier is just variance.
2. **It makes the two planes fire together** (Frame-C): the broadcast plane sees a Camera
   Call; the wager plane sees the table taking odds on one specific act.
3. **It restores "spectacle over safety" as a real decision** — declaring big when you are
   not sure is exactly the behaviour the show wants and the smart play punishes.

**Open detail:** does a failed double-or-nothing cost *only the stake*, or does it also
**burn earned reverence** (named followers walking away)? The second is harsher and more
faithful to reverence being losable. **→ Q-32.**

### 12.3 Q-29 gives every floor-god a motive and a clock

> *"A floor god's goal is to collect enough reverence to pay the casino back and earn its
> right of existence."*

This is the best single line of lore produced in this pass. It means:

- **Every floor-set has a host with a stake and a debt.** The set's question
  (`story-canon.md:68`) is now *that god's* question, asked by something that will cease to
  exist if the answer doesn't pay.
- **Prayer is a mechanic, not flavour.** A contestant can pay a floor-god in reverence —
  and since divinity is finite and earned (Q-22), **praying costs you what it gives them.**
  That is a genuine moral trade in the campaign's own currency.
- **The house has leverage over its own runners.** A bankrupt god running your floor is
  itself being squeezed, which makes it bargainable, desperate, and occasionally an ally.
- **It explains the whole institution.** The casino doesn't need to be evil; it holds the
  debt. `cosmic-casino-canon.md` §4's *"a framework with no motive at all"* now has teeth
  without a villain.

**Sharpest consequence:** a contestant can **save or condemn a god**. On a floor whose runner
is short of its debt, praying is charity that costs you the campaign's only real resource —
and refusing is an execution you commit by doing nothing. That is the spine
(*"how much can we break your essence down…"*) pointed at the *audience* for once.

**→ Q-33: is a floor-god's debt a visible number?** Recommend yes — a floor-set-long ledger
the party watches, which makes the choice concrete instead of abstract.

### 12.4 Approved and applied

**Group C — adopted** (mycelium dropped, see §12.5):

| # | Adopted |
|---|---|
| **D-14** | The **anti-prime** is the curse chassis — a curse adds or invalidates a §4.6 prime |
| **D-15** | Boss ladder: **Shrine → Temple → Pantheon**; supers **Legend → Age-Ender → The House** |
| **D-18** | The Advanced Fabricator is fronted by a **bankrupt smith-god** — also fills the materials corpus's flagged smith-god gap. *(Now doubly apt: a smith-god in debt to the house is a floor-runner in miniature.)* |
| **D-20** | The **Nikita adjacency separation rule** — no shared scene, floor, or episode with the Abrahamic-corporate satire |

**Group D — housekeeping, applied:** D-21, D-22, D-24 (doc reconciliation sweep) · D-26
(the three-way consistency guard, written) · **D-28 applied** — `data/migrations/001_initial_schema.sql:212`
now reads `CHECK (source_type IN ('Patron', 'House', 'Crowd'))`; verified the value was
referenced nowhere else in the codebase before changing it · D-29 (archive `messages`,
don't migrate — recorded) · D-30 (contestant/champion register split — recorded).

**Group E — flavour, adopted:** Farm → **augury pen** · Wizard's Tower → **the Sanctum** ·
the Goldsmith's bench → **"the cage"** · a **HOUSE** lane in the Box Namer · the three coupon
renames (Wardrobe Comp · Altar Marker — Lesser · Forge Marker — Basic) · Med Bay is a
**marker**, not a comp · §17.1 "Exposure" renamed (the word is taken twice — by the combat
state and a sim class) · top box tiers mapped onto the relic taxonomy (Godly → God Relic,
Mythic → Follower Relic) · Nine Lives and Unkillable re-homed to the epithet track · Skill
Tomes split into **God Relics** and **Follower Relics** · enemy disposition is
**encounter-level** · the four TV-coded skills renamed (Vibe Control, Heroic Punch, Slice n'
Dice, Play to the Camera) — *note: renames break name-matching in `apply-skill-passover.js`.*

### 12.5 The mycelium is dropped — one consequence to place

**Ruled: drop it.** Under D-V2 this is **v2-only** — v1 keeps the mycelium unchanged.

The cost the audit flagged is real: the Incinedile's discoverable win condition *is* the
mycelium — 6 phases, breach paths, network-as-body-part, all play-tested. **The mechanics
should survive the re-theme**; only the fiction changes. Three re-themes that preserve the
network structure exactly:

| | Re-theme | Fit |
|---|---|---|
| **a** | **The root-system of a bankrupt god's dead temple** — the boss is squatting in it | Ties straight into Q-29's floor-god debt; strongest option |
| **b** | **A dead god's nervous system**, still twitching | Myth-native; keeps the body-horror register |
| **c** | A creature with a genuinely distributed nervous system — no divine element | Cheapest; loses the thematic hook |

**→ Q-34.** Also affects the Mycelium Core item, the Mycelium-Threaded Hide, and the
"Mycelius Chrom Production Co" shopkeep — 3 records plus an NPC, v2 side only.

### 12.6 D-25 explained (you asked)

**The problem, in the book's own words.**

§2.1 defines Charm (`gpt-system-v1.0.md:55-57`):
> *"**Charm** — **presentability**: how objectively camera-ready you are — photogenics,
> striking looks, visual impressiveness… **Charm is not warmth or likability** — those live
> in the audience's reaction to you (Tags and crowd response), never in the number."*

R18 (`rules-addendum.md:594-601`) restates it as a hard ruling: **"Charm is NOT charisma."**

But §2.3's action table (`gpt-system-v1.0.md:98-100`) keys three social actions to it:

| Action | Stat(s) | Reads as |
|---|---|---|
| **Command** | Charm | *You lead because you are photogenic* |
| **Persuade** | Charm + Mind | *You talk people around by being attractive* |
| **Intimidate** | Charm + Physique | *You are frightening because you look striking* — **this one is arguably fine**; menace really is partly visual |

**So Command and Persuade are incoherent under the book's own definition of the stat.**
Intimidate survives, because presentability plausibly contributes to threat.

**Why it was missed:** `docs/audits/skills-audit.md` applied R18 across the *skills* and
flagged an "R18 sweep" — the sweep never reached the action table.

**Cost of fixing:** moving a stat owes **skill-point refunds** to anyone who invested under
the old mapping (`audits/skills-audit.md:98`). With 5 live PCs that is small but real.

**The likely fix** (not applied — awaiting your call): Persuade → **Mind** (+ Charm as a
secondary), Command → **Mind** or Mind + Charm, Intimidate → **unchanged**.

**Your three options:**

| | Option | Effect |
|---|---|---|
| **a** | **Fix in v1 as errata** | Corrects a live incoherence; costs refunds to 5 PCs. v1's freeze covers *setting*, not errata — but it is your table |
| **b** | **Fix in v2 only** | v1 keeps the quirk; the two books diverge on a rule for no thematic reason — the exact drift the consistency guard exists to prevent |
| **c** | **Leave it** | Zero cost; the book contradicts itself in a spot players rarely touch |

**Recommendation: (a).** It is a genuine defect rather than a fork, and fixing it in one
place keeps the shared spine honest.

### 12.7 Outstanding

| # | Question | Rec |
|---|---|---|
| **D-25** | Fix the Charm/action-table contradiction in **v1 as errata**, v2-only, or leave? (§12.6) | **v1 errata** |
| **Q-32** | Does a failed double-or-nothing cost only the stake, or **burn earned reverence**? (§12.2) | Burn — reverence is losable |
| **Q-33** | Is a floor-god's **debt a visible number** the party can watch? (§12.3) | Yes |
| **Q-34** | What replaces the mycelium in v2? (§12.5) | **(a)** the root-system of a bankrupt god's dead temple |

---

## Part 13 — Round 9: Charm widened, myth-sources, and strings

### 13.1 D-25 ✅ RULED — and the fix inverts

> *"v1 errata — but arguably, people listen better to someone who is attractive. Attractive
> can also mean having a nicer voice, a more striking look, better facial expressions and
> control of your face and body language. It's just not some cosmic attraction."*

**This turns the fix upside down, in the cheap direction.** I proposed moving Command and
Persuade *off* Charm. The owner's clarification says the mappings were right and **the
definition was too narrow**.

| | What I proposed | What was ruled |
|---|---|---|
| Change | §2.3's action table — move Persuade/Command to Mind | **§2.1's definition** — widen Charm |
| Refunds owed | Yes, to 5 live PCs (`audits/skills-audit.md:98`) | **None** — no stat moves |
| Result | Two books diverge, or a live campaign gets re-pointed | One wording fix, both versions |

**Applied to both canons:**

- `gpt-system-v1.0.md` §2.1 — Charm is now **presence**: *"how compelling you are to look at
  and to listen to — striking looks, bearing, voice, facial control, body language.
  Presentation used as an instrument… not a cosmic pull."* It now **states the §2.3 link
  inline** (*"People do listen better to someone who commands a room, which is why Command,
  Persuade and Intimidate key off it"*), so the contradiction cannot silently return.
- `rules-addendum.md` R18 — widened to match, with the errata's reasoning recorded.

**Shared-spine fix — it holds for v1 and v2 alike.** Everything downstream (Camera Call
stacks at Charm/20, the speech-scoring Charm term) stays coherent; R18 already implied Charm
belonged in speech scoring, which is why the narrow wording was the odd one out.

### 13.2 Q-32 ✅ **Burn.** A failed double-or-nothing costs earned reverence

Named followers walk away. Reverence is losable (Buddhist doctrine, `research/mythology/buddhist.md:9`),
Followers already decay in v1's own §17.1, and a bet that can only cost *unbanked* winnings
isn't a bet. **A failed Camera Call now removes rows from your ledger** — people who
believed in you, by name, no longer do.

### 13.3 Q-33 ✅ — the debt is visible, but only after you find the god's myth-source

> *"Yes, but they must find the source of the god's myth. A sword, a temple, something
> hidden away in the floor — and when they find it, that's when communications and
> understanding of the god's situation can be established."*

**This is the best structural device in the design after Floor 10.** The loop:

```
   Floor contains a hidden MYTH-SOURCE  (a sword, a temple, a relic)
                    │
        party finds it ──▶ communication opens
                    │      the god becomes legible
                    │      its DEBT becomes a visible number
                    ▼
        pray (pay reverence you cannot get back)  ──▶ save it
        or walk away                              ──▶ condemn it
                    │
   never found ──▶ the floor-god stays mute. The floor plays normal.
                  You never learn there was anyone to save.
```

**Why it works so well:**

1. **It explains bankruptcy mechanically.** Under Q-14 reverence needs a *locus* — a name
   attached to a thing. A god whose myth-source is buried has nothing for anyone to revere.
   **Finding the relic is the precondition for being named again**, so the device and the
   economy are the same idea.
2. **It makes the god-saving content optional and earned.** A party that doesn't explore
   never meets the floor's author. That is a real reward for exploration rather than a
   collectible.
3. **It extends the architecture's own doctrine.** The rule is *"bosses need discoverable win
   conditions, never raw damage races"* (`CLAUDE.md`). Now **floors have discoverable
   characters** — the same principle one level up.
4. **It gives floors 4–9 their authoring template.** Each set needs: a bankrupt god, its
   hidden myth-source, its debt, and the question it is asking. That is a repeatable content
   recipe, which is exactly what six floors of greenfield needed.

### 13.4 Q-34 ✅ — puppeteering replaces the mycelium

> *"Instead of mycelium, we can have the floor 0 god's power be puppeteering. The party can
> find strings in the boss."*

**Mechanically this is a drop-in.** The Incinedile's play-tested structure — a network that
*is* a body part, breach paths, sever points, 6 phases — maps onto **strings** one-for-one.
Nothing tuned is lost; only the fiction changes.

**Thematically it is a large upgrade, and not just for this boss.** Puppeteering is what the
entire premise *is*: gods move contestants, patrons pull on their champions, the house works
the whole floor. **A tutorial whose lesson is "there are strings on things, and you can find
them and cut them"** teaches the game's central literacy on Floor 0 and foreshadows every
patron contract that follows. The mycelium never did that — it was set dressing.

It also lands Floor 0's god cleanly: the tutorial's host is a puppeteer, so the tutorial boss
is *its puppet*, which is why it has strings at all.

**Records to re-author (v2 only — v1 keeps the mycelium):** the Incinedile · Mycelium Core ·
Mycelium-Threaded Hide · the "Mycelius Chrom Production Co" shopkeep. 3 records + 1 NPC, as
costed in [`research/E`](research/E-data-audit.md).

**→ Q-35: is the Incinedile the Floor-0 boss?** The re-theme assumes so. If it sits on Floor
1 instead, the puppeteer's reach extends one floor further and that should be deliberate.

### 13.5 Outstanding

| # | Question | Rec |
|---|---|---|
| **Q-35** | Is the Incinedile the **Floor-0** boss? (§13.4) | — |
| **Q-36** | Do the **renames** for the three mycelium records need owner wording, or shall I draft them? | I draft, you veto |
| **Q-37** | `narrative-design.md:89` still calls the casino *"a famine of attention"* — residual **Option-E** flavour, which was REJECTED (the gods are not starving) | Fix the line |

---

## Part 14 — Round 10: the puppet floor, and a brief for floors 1–3

### 14.1 Q-35 / Q-36 / Q-37 ✅

- **Q-35 — the Incinedile is the Floor-0 boss.** The puppeteering re-theme lands as designed:
  the tutorial's host is a puppeteer, so the tutorial's boss is its puppet.
- **Q-37 — applied.** `narrative-design.md:89` no longer calls the casino *"a famine of
  attention."* That was residual **Option-E** flavour, rejected 2026-07-16. It now reads
  *"an appetite with a house style, and a ledger that quietly ruins its own"* — which is the
  ruled lore (self-inflicted status-loss) and now also points at Q-29's floor-god debts.

### 14.2 Q-36 — the mycelium renames, drafted

The naming test: the puppet network must read as *strings you can find and cut*, and the
shopkeep's joke has to survive the swap.

| v1 (frozen — unchanged) | **v2** | Why |
|---|---|---|
| Mycelium Core | **Puppeteer's Cross** | The cross-bar a marionettist holds *is* the control point — so the boss's core is now a thing with an obvious use, which is exactly what a discoverable win condition wants |
| Mycelium-Threaded Hide | **String-Threaded Hide** | Same grammar, one word swapped. Nothing else about the item changes |
| Mycelius Chrom Production Co *(shopkeep NPC)* | **Cordelius Chrom Production Co** | `Myc-elius` → `Cord-elius` — identical rhythm, and *cord* is the string. The joke survives intact because the shape of the name does |
| Incinedile | **unchanged** | The name is good and premise-neutral; only its network re-themes |

**Veto any of these and I'll redraft.** The Incinedile's tuned structure — 6 phases, breach
paths, network-as-body-part, sever points — is untouched throughout.

### 14.3 Floors 1–3: brief and proposal

> **Owner's direction:** *"demon related and dragon opposed, with ties to disease and
> immortality."*

**Constraints this has to satisfy:**

| Source | Requirement |
|---|---|
| Q-31 | Floor-runners are a **separate broke cast** — **not** from the 24-god roster *(verified: the roster holds Amaterasu, Zeus, Odin, Beelzebub, Lucifer et al.; none of the figures below are in it)* |
| Q-29 | The god needs a **debt** and a reason it went bankrupt |
| Q-33 | The floor must hide its **myth-source** — a sword, a temple, a relic |
| `story-canon.md:91-93` | The F1–F3 set already asks: ***"will you cure what's corrupted, and at what cost?"*** |
| Existing content | The **Loong** (a dragon, already canon as a Worshipped Creature), the demonic brand contract, Sasha's demon encounter, Nullrot |

#### The proposal — the bankruptcy writes itself

**A plague god who made his name killing a dragon, and went bankrupt by curing too well.**

```
  He was a PLAGUE god ──────▶ people revered him to be spared. Reverence = income.
  He SLEW A DRAGON ─────────▶ the deed that made his name. The blade is his myth-source.
  He granted a CURE ────────▶ a lineage made permanently immune. His masterpiece.
                                        │
                    permanent immunity = nobody needs to pray any more
                                        │
                                        ▼
                          ZERO REVERENCE. He cured himself into bankruptcy.
                                        │
  His demons — the plague-carriers who revered HIM — are now unemployed and feral.
  That is why this floor-set is demon-infested.
```

**Why this is the right shape:**

1. **The bankruptcy is causal, not decorative.** Under Q-14 divinity *is* reverence, so a god
   whose cure was permanent has no income by construction. He is broke **because he
   succeeded** — no villainy required, exactly the morally-alien register canon asks for.
2. **It *is* the floor-set's question.** *"Will you cure what's corrupted, and at what
   cost?"* — the cost is on the table in front of you: the last god who cured something
   properly is the beggar asking you for prayers. The set's question and its host are the
   same argument.
3. **The demons are explained, not imported.** Q-28 makes demons NPCs and enemies who revere
   demon gods; here they are a *bankrupt* god's abandoned workforce. The demonic brand
   contract becomes a rival goetic power recruiting from his lapsed staff.
4. **The dragon is already on the board.** The Loong needs no new justification — either the
   dragon he killed, or its descendant with a grudge. `research/G` flagged the Loong's
   escort-quest weakness as unfixable by the frame; giving it a blood claim on the floor's
   host gives it a motive it currently lacks.
5. **The myth-source is obvious and findable.** **The blade that killed the dragon**, buried
   somewhere in F1–F3. Find it → he can speak → his debt becomes visible → pray or walk away.

**Sourcing note.** The corpus already carries this archetype — Susanoo (`disease_poison` +
the Orochi-slaying myth, `myth_japanese_shinto_orochi_slaying`), Nergal, Namtar (already cast
as a *dealer*, with `luck_gambling`), Whiro, Babalú-Ayé. But **Susanoo, Amaterasu, Benzaiten
and Xiwangmu are `depiction_risk: living`**, and casting a living-religion kami as a
debt-ridden beggar is a different proposition from casting Zeus that way.

| | Option | Trade |
|---|---|---|
| **a** | **An original bankrupt god built in the archetype's shape** — the wandering plague-warder who tests hospitality and rewards shelter with immunity | No depiction risk, full authorial freedom, and he can be tuned exactly to the floor-set's question. Costs one new entity |
| **b** | **Use a low-risk corpus figure** — **Nergal** (`risk: none`, war/disease/underworld/chaos) or **Whiro** (`risk: low`) | Free sourcing, already authored. Neither has the immortality thread; it would need adding |
| **c** | Use Susanoo | The tightest myth fit — dragon-slayer *and* disease — but `risk: living`, and the depiction policy would need an explicit carve-out |

**Recommend (a)**, with the corpus figures as his lapsed rivals and creditors. It keeps the
living-religion policy clean and lets the *cure-yourself-broke* mechanism be authored
precisely rather than retrofitted onto a god who already means other things.

**→ Q-38: pick a, b or c.** **→ Q-39: is the Loong the dragon he killed, or its descendant?**
(Descendant is stronger — it puts a living claimant on the floor.) **→ Q-40: does his cured
lineage still exist in F1–F3** — a village that cannot get sick and does not know why? *(That
would be a named Follower under Q-18 worth a great deal of divinity, sitting in plain sight,
already owed to someone.)*

---

## Part 5 — What D-01 unblocks immediately

1. **The floor-set question bank** (fork spec §7) — a question only classifies you if there
   is something you want. There now is: *survive, and what you are worth after the reset.*
2. **Creation** — the champion/civilian fork and the patron trade are both creation-facing,
   which fills A-16's background system with real decisions instead of flavour.
3. **The finale** — pending **Q-02**.
4. **The divinity shop** — pending the currency layering in §1.1 above.
