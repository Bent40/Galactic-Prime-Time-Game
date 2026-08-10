# v2 Decisions — Round 2 (owner, 2026-08-10)

Answers to the Tier-1 docket in [`v1-v2-fork-spec.md`](v1-v2-fork-spec.md) §8, the
design that falls out of them, and the remaining open questions.

**Status:** D-01, D-03, D-04, D-06 RULED · D-02 expanded, awaiting choice · D-05 resolved
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

**Not a contradiction — it is the central dilemma, and it is the best thing D-01 produces.**

One pool. **Spend it during the run to survive; whatever you carry to the end is what you
ascend with.** Survival and apotheosis compete for the same resource, every session.

That makes "your place in the world" *literally your closing divinity balance* — the stake
is a number the player watches all campaign. Buddhist canon already frames divinity as
"spendable **and losable**," so spending down is doctrinally correct, not a fudge.

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

### New questions raised by round 2

| # | Question | Why it matters | Rec |
|---|---|---|---|
| **Q-01** | **Frame-A, Frame-B, or Frame-C?** | Decides what a contestant thinks is happening; 8× cost swing between A and B | **Frame-C** |
| **Q-02** | **In a group game, is there one winner or a collective one?** (C5) | Decides the finale's shape — collective triumph vs a party that turns | Needed before any floor-9+ authoring |
| **Q-03** | **What does a non-winning survivor get?** (residue) | Makes every divinity spend cost something | Station-without-memory |
| **Q-04** | **Is the patron's cut fixed, or negotiated per contract?** | If negotiated it becomes the **deal sheet's headline term** — a god who wants more takes more | Negotiated — it makes bidding a real scene |
| **Q-05** | **Can you fire a patron mid-run to stop the cut?** `patron-gods.md:50` already lets you decline a *new* contract at level-up | Decides whether patronage is a lock or a lease | Lease, with a cost |
| **Q-06** | **Champion vs civilian — what does the champion's "advantage" concretely buy?** Starting skills, items, a free patron tier, foreknowledge of floor 1? | It is a creation path, and it must not simply be "better" | Preparation, not power |
| **Q-07** | **Do the dead exist in the reset world?** | Permadeath's meaning under a universal reset | — |
| **Q-08** | **Is the winner's event-authorship played on screen** (an epilogue the group plays) **or narrated?** | The finale's staging (I-18) | Played — it is the verdict made literal |
| **Q-09** | **Is the current world the product of a previous cycle's winner?** (from D-03) | Follows logically from D-03; decides whether real history is diegetically authored, and how close the camera may get | Yes, but never narrated over a real atrocity |
| **Q-10** | **Two rendered books from one source, or a hand-forked second file?** (from D-06) | Decides whether v1/v2 drift again | Two renders |

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

## Part 5 — What D-01 unblocks immediately

1. **The floor-set question bank** (fork spec §7) — a question only classifies you if there
   is something you want. There now is: *survive, and what you are worth after the reset.*
2. **Creation** — the champion/civilian fork and the patron trade are both creation-facing,
   which fills A-16's background system with real decisions instead of flavour.
3. **The finale** — pending **Q-02**.
4. **The divinity shop** — pending the currency layering in §1.1 above.
