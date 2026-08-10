# G — Story, encounters & campaign structure: v1→v2 change inventory

**Slice G of the v2 research session.** Read-only research pass, 2026-08-10. Nothing in the
repos was edited.

**Citation legend** — all `file:line` refs below are relative to one of two roots:

| prefix | absolute root |
|---|---|
| `docs/…` | `/home/user/Galactic-Prime-Time-Game/docs/` |
| `rulebook/…` | `/home/user/Galactic-Prime-Time/rulebook/` |

`INFERRED` marks my reasoning; everything else is cited canon. Where v2 canon has already
ruled something I cite the ruling rather than re-deciding it.

**Verdict vocabulary:** KEEP (unchanged) · RESKIN (same structure, new vocabulary) ·
MECHANICAL (the rules change, not just the words) · FORK (v1 and v2 genuinely diverge —
both need separate content) · CUT (dies in v2) · NEW (does not exist in v1).
**Effort:** S = a paragraph rewrite · M = a design decision plus a few scenes · L = a system
or arc needing owner design sessions.

---

## Summary table

| ID | Element | file:line | Verdict | Effort | One-line change |
|---|---|---|---|---|---|
| G-01 | Abduction by aliens | `rulebook/gpt-system-v1.0.md:9`, `docs/GPT_Master_Compendium.md:20` | RESKIN | S | Not abducted — **conscripted in place** when the realm bindings weaken and the world drops into the tables (`docs/cosmic-casino-canon.md:11-18`); the VIP table is a constructed set you're seated at. |
| G-02 | The Corporation™ as the power running the show | `rulebook/gpt-system-v1.0.md:9-13`, `docs/GPT_Master_Compendium.md:20` | RESKIN | S | Already dead canon: replaced by **"the house" — a fallen (bankrupt) god of a forgotten religion** (`docs/audits/campaign-residuals-audit.md:351`, `docs/cosmic-casino-canon.md:59-62`). |
| G-03 | Colonization-justification motive | `rulebook/gpt-system-v1.0.md:10-11`, `docs/GPT_Master_Compendium.md:462` | CUT | S | Explicitly on the never-re-import list (`docs/audits/campaign-residuals-audit.md:483-484`). Replaced by **no motive at all** — the divinity economy is a framework, gods are morally alien (`docs/cosmic-casino-canon.md:78-79`). |
| G-04 | "The only way out is through the ratings" (the exit) | `rulebook/gpt-system-v1.0.md:11-12` | **FORK** | **L** | **v2 has no way out.** Winning is joining (`docs/setting-rebrand-options.md:45-47`). This is the conversion's central hole — see §2. |
| G-05 | The refusal threat ("we can't guarantee what happens to you") | `rulebook/gpt-system-v1.0.md:12-13`, `docs/GPT_Master_Compendium.md:463` | CUT | S | Dead canon (`docs/audits/campaign-residuals-audit.md:484`). v2 needs a replacement pressure — the patron is the candidate (§2, Proposal B). |
| G-06 | The contestant's personal stake | *(v1: implicit in G-04)* | **NEW** | **L** | **Unwritten in v2.** Three proposals in §2; canon supports two of them today. |
| G-07 | Dungeon floors + route exclusivity | `docs/GPT_Master_Compendium.md:263-269`, `docs/setting-rebrand-options.md:15` | KEEP | — | Survives untouched; gains a diegetic reason (routes = separate side-bet books). INFERRED. |
| G-08 | Time skips between floors | `docs/GPT_Master_Compendium.md:266-267`, `docs/setting-rebrand-options.md:42` | RESKIN | S–M | Gets a *better* excuse (the framework fast-forwards between acts) but opens a real hole: what happens to Earth outside during 170 years? See §3.2/§3.3 and Open Q3. |
| G-09 | Permadeath | `docs/setting-rebrand-options.md:17`, `docs/rules-addendum.md:603` | MECHANICAL | M | Game-side already ruled into **run types** (R17: softcore/hardcore/Forsaken). TTRPG side: book death rules stay R5's (`docs/ttrpg-update-plan.md:34-35`). |
| G-10 | Ascension (retire → patron) | `docs/setting-rebrand-options.md:17,40`, `docs/GPT_Master_Compendium.md` §Winner's Arc via `docs/review/review-6-story.md:206` | RESKIN + **unreconciled** | M | Canon near-verbatim: winners take winnings → divinity → join the table (`docs/cosmic-casino-canon.md:43-44`). **But the two doors out are not reconciled** (`docs/cosmic-casino-canon.md:190-193`) — divinity buy-in vs. "unwagerable" exit. Blocks the ending. |
| G-11 | The verdict / "what kind of ruler" ending | `docs/story-canon.md:73-76` | RESKIN → literalised | M | Canon literalises it: the final winner decides how history is shaped and the apocalypse remembered for 250 years (`docs/cosmic-casino-canon.md:45-46`). See §5. |
| G-12 | The spine question | `docs/story-canon.md:62-63` | KEEP | — | 100% theme-neutral. Carries both versions verbatim. |
| G-13 | Question architecture (each floor-set asks one question) | `docs/story-canon.md:65-72` | KEEP | — | A scoring architecture, not a fiction. Carries both versions. See §6. |
| G-14 | Audience economy (Viewers→Followers→Patrons) | `rulebook/gpt-system-v1.0.md:870-886` | RESKIN | S | Spectator gods / devotees / **donator gods**, with THE patron god above them (`docs/DIRECTION.md:180-186`). Mechanic already has the right name. |
| G-15 | Directives (corporate quests) | `rulebook/gpt-system-v1.0.md:917-925` | RESKIN | S | The house issues them; **tips to the dealer** is the exact house vocabulary (`docs/setting-rebrand-options.md:132-133`). Mechanics unchanged (`docs/audits/campaign-residuals-audit.md:358`). |
| G-16 | Goals (crowd challenges) | `rulebook/gpt-system-v1.0.md:908-915` | RESKIN | S | Side bets from the gallery (`docs/setting-rebrand-options.md:33`). |
| G-17 | Camera Call | `rulebook/gpt-system-v1.0.md:895-906` | RESKIN | S | The odds board turns to you — all stakes on you double (`docs/setting-rebrand-options.md:34`). The gains-AND-losses gamble reads *better* at a casino. |
| G-18 | Tags = identity assigned by watchers | `rulebook/gpt-system-v1.0.md:963-1013` | KEEP | S | Survives; the TVTropes dependency is already internalised (`docs/audits/campaign-residuals-audit.md:357`). 9 renames / 7 cuts already catalogued (`docs/audits/campaign-residuals-audit.md:36`). |
| G-19 | Epithets (pantheon comparisons) | `docs/design/patron-gods.md:126-150` | **NEW** | L | v2-only track: trait-words + deeds recreate a real myth's pattern → you earn its epithet, graded ORV-style. Kills the TVTropes debt and gives §2's Proposal C its machinery. |
| G-20 | Two information planes | `docs/setting-rebrand-options.md:19`, `docs/DIRECTION.md:149-163` | KEEP | — | Survives untouched, and becomes *more* load-bearing as the tonal firewall (§4, cross-cutting #6). |
| G-21 | The Lounge / the Golden Cage | `rulebook/gpt-system-v1.0.md:1176-1191` | RESKIN | S | **The comp suite** — the house always comps your room; surveillance = the house watching its assets (`docs/setting-rebrand-options.md:36`). Golden-Cage pillar survives verbatim. |
| G-22 | Loot boxes / achievements | `rulebook/gpt-system-v1.0.md:927-951` | RESKIN | M | Jackpots & comps; the Lounge box-opening is the prize floor. Plus a v2 hard rule worth adopting: **loot must feel like remnants of belief** — God Relics / Follower Relics (`docs/cosmic-casino-canon.md:156-159`). |
| G-23 | Narrative Tokens | `rulebook/gpt-system-v1.0.md:952-962`, `docs/GPT_Master_Compendium.md:178-182` | KEEP (TTRPG) / already flagged (digital) | S | Frame-independent. The "DM discretion" digital rebuild flag is unchanged by v2. |
| G-24 | Production cast (announcer, producer) | `docs/review/review-6-story.md:34-41`, `docs/ISSUES.md:28` | RESKIN → **fixed for free** | S | v1's biggest cast gap. v2 hands over **Momus** (pink tuxedo, never breathes, "Stay tuned!") pre-built (`docs/cosmic-casino-canon.md:73-75`), RULED shared host (`docs/setting-rebrand-options.md:157`). |
| G-25 | F1 — green forest, three labelled routes | `docs/GPT_Master_Compendium.md:265` | RESKIN | S | Set-dressing only; and it gains the **arena-as-psyche** rule (each arena shaped by the judge god's mind — `docs/cosmic-casino-canon.md:76-77`), already ruled in from floor-set 3+ (`docs/gdd/decision-log.md:37`). |
| G-26 | F2 — great desert, +70 years | `docs/GPT_Master_Compendium.md:266` | RESKIN + **hole** | M | Better excuse (gods skip the boring parts), worse cosmology: see G-08 and Open Q3. |
| G-27 | F3 — grand capital, +100 years | `docs/GPT_Master_Compendium.md:267` | RESKIN | S | Unchanged in shape. Its convergence-matrix debt (`docs/review/review-6-story.md:59-64`) is frame-independent. |
| G-28 | The capital attaches to the Lounge | `docs/GPT_Master_Compendium.md:267` | RESKIN → **improves** | S | "Your conquered city gets annexed into the house's hotel" is a better joke and a darker one at a casino than at a corporation. INFERRED. |
| G-29 | F4–6 — continent merge | `docs/GPT_Master_Compendium.md:268` | RESKIN → **improves most** | M | v1: a TV-production convenience. v2: **the casino closing tables and moving survivors to the main floor as stakes concentrate** — literally how a tournament ends. INFERRED, but it's the frame's single best structural gift. |
| G-30 | Easy route — mask / chained man / Nullrot | `docs/GPT_Master_Compendium.md:271-274` | RESKIN → **fixes 2 known holes** | M | The mask's missing origin and Nullrot's missing motive (`docs/review/review-6-story.md:86-89`) are both filled by v2's relic canon (`docs/cosmic-casino-canon.md:156-159`). Closes part of I-17. |
| G-31 | Medium route — demon girl → queen → human farm | `docs/GPT_Master_Compendium.md:276-279` | **FORK** | **L** | Survives only after the demon-cosmology ruling (G-32). Its 170-year continuity bug (`docs/review/review-6-story.md:108-112`) is fixed for free by v2. |
| G-32 | Demonic-nobility cosmology | `docs/GPT_Master_Compendium.md:428` | **FORK** | **L** | v2 offers three incompatible homes for "demons" and none is ruled — see §3.6. **The only genuine FORK among the set pieces.** |
| G-33 | The demonic brand contract | `docs/story-canon.md:6-38` | RESKIN → **improves** | M | Under gods it becomes an **unauthorised second patronage**; brand-breach (I-23) gets a native mechanism — your actual patron finds out. INFERRED. |
| G-34 | Dissolution-songs encounter (Medium F2) | `docs/GPT_Master_Compendium.md:251-256`, `docs/review/review-6-story.md:133-145` | KEEP (mech.) / RESKIN (frame) | M | Mechanically untouched (adopted R12). Under v2 the *personalisation* gets a diegetic author: a god picks your song. Licensed tracks remain unshippable either way (`docs/audits/campaign-residuals-audit.md:493`). |
| G-35 | Hard route — the Loong | `docs/GPT_Master_Compendium.md:281-284` | RESKIN → **improves** | M | v2 has the exact category pre-built: **Worshipped Creatures** — revered beings, moral dilemmas (`docs/cosmic-casino-canon.md:152-153`). The escort-quest weakness (`docs/review/review-6-story.md:123-126`) is a design problem, unchanged by frame. |
| G-36 | Sasha's F1 demon encounter (the maze) | `docs/GPT_Master_Compendium.md:296-303` | KEEP | S | Frame-independent: it needs a Dissolution source and a maze. The reveal (the fear is Nikita's) is untouched. Best evidence that the character content is theme-portable. |
| G-37 | The Incinedile | `docs/GPT_Master_Compendium.md:204-220` | KEEP | S | Zero Corporation text in the data (`docs/audits/campaign-residuals-audit.md:221-223`); its thesis ("the spectacle is a skin over the real organism", `docs/review/review-6-story.md:155-158`) is *sharper* under a bankrupt god. Licensed boss music still unshippable. |
| G-38 | Nikita (the character) | `docs/GPT_Master_Compendium.md:286-294`, `docs/characters/nikita.md` | KEEP + **guardrail** | M | Parses and gets more resonant — but only under a narrow reading of "shapes history". See §4. |
| G-39 | Nikita's F4–6 appearance | `docs/GPT_Master_Compendium.md:293` | RESKIN → **improves** | M | v2 adds war-gods bidding on the song and hearth-gods bidding on the old man (`docs/characters/nikita.md:79-80`, APPROVED) — the spine expressed as an economic fight over which version of him is worth more. |
| G-40 | Sasha | `docs/characters/sasha.md` | KEEP | — | Nothing in her sheet touches the frame. Her "chat function" speech rule (`docs/characters/sasha.md:35-40`) works identically under a System run by a god. |
| G-41 | Route exclusivity + path-dependent unlocks | `docs/story-canon.md:70-72`, `docs/GPT_Master_Compendium.md:265` | KEEP | — | Canon; theme-neutral. |
| G-42 | Live party as content (Filipe / XQUEZ-T / Mario / Frod) | `docs/GPT_Master_Compendium.md:307-322` | CUT (game) / KEEP (v1 table) | — | Already ruled out of the game by the IP split (`docs/story-canon.md:39-45`). If v2 is *also* a TTRPG, the live party's fate at a v2 table is an unasked question. |
| G-43 | Races: Human / Animal / Robot-AI | `rulebook/gpt-system-v1.0.md:25-26`, `docs/rules-addendum.md:574` | FORK | M | R16 removed Robot/AI game-side; the book keeps all three (`docs/ttrpg-update-plan.md:31-33`). A v2 *table* inherits the game's ruling or the book's — unasked. |
| G-44 | Whether the live TTRPG re-skins at all | `docs/setting-rebrand-options.md:155-157` **vs** `docs/ttrpg-update-plan.md:6-9` | **contradiction in the record** | S | RULED "re-skin to casino" 2026-07-16, explicitly scoped OUT 2026-07-23, still carried OPEN in two decision logs. See cross-cutting #2. |
| G-45 | Licensed music as content | `docs/audits/campaign-residuals-audit.md:228-232,493` | CUT | S | Frame-independent debt; unchanged by v2. |

**Counts:** KEEP 11 · RESKIN 19 · MECHANICAL 2 · FORK 5 · CUT 5 · NEW 2 · record-contradiction 1.
(G-10 and G-31 are counted once each under their primary verdict.)

---

## 1. Premise-level story deltas

### 1.1 Element-by-element

**Abduction (G-01) — RESKIN, cheap.** v1: "You were abducted by an alien conglomerate"
(`rulebook/gpt-system-v1.0.md:9`). v2 has a stronger and cheaper substitute already written:
roughly once a quarter-millennium the realm bindings weaken, the gods claim divine favour
from a realm's subjects, and **the whole world drops into the games at many tables at once**
(`docs/cosmic-casino-canon.md:11-18`). You are not taken away from Earth; Earth is taken.
What survives intact is the load-bearing *feeling* — sudden, non-consensual, no appeal —
and the VIP table's constructed-arena nature preserves "you are somewhere purpose-built"
(`docs/cosmic-casino-canon.md:24`: VIP games are special games designed around what the gods
found interesting, 1 to a billion contestants). **INFERRED but tightly grounded:** the
Normal table is the "your hometown becomes the arena" shape
(`docs/cosmic-casino-canon.md:143-147`); GPT is a VIP table, so the removal-to-a-set reading
is the natural one and no canon contradicts it.

**The Corporation and its motive (G-02, G-03) — already dead canon.** The residuals audit
has this on the never-re-import list explicitly: "The Corporation as the power running the
show: colonization motive, 'beneficial — nay, necessary', the refusal threat"
(`docs/audits/campaign-residuals-audit.md:483-484`), superseded by the house = a bankrupt
god of a forgotten religion (`docs/cosmic-casino-canon.md:59-62`). The *replacement* is not
a different villain — it is **the deliberate absence of one**: gods are morally alien,
addicted, bored, no redemption, nothing to twirl a mustache
(`docs/cosmic-casino-canon.md:78-79`). This directly answers the owner's "too on the nose"
complaint (`docs/setting-rebrand-options.md:50-53`) — and it is also, precisely, what
creates the stakes problem in §2. **The owner bought one with the other.**

**"The only way out is through the ratings" (G-04) — FORK, and the biggest single delta.**
This one sentence carries v1's entire motivational structure. v2 replaces it with
"winning doesn't free you; it promotes you into the audience"
(`docs/setting-rebrand-options.md:45-47`). That is not a reskin of the same idea — it
inverts the vector. Full treatment in §2.

**Floors + time skips (G-07, G-08) — RESKIN with one real hole.** Route exclusivity and time
skips are on the MUST-PRESERVE list and survive (see §1.2). The time skip *gains* an excuse
("the framework fast-forwards the host realm between acts — gods skip the boring parts",
`docs/setting-rebrand-options.md:42`), but it also acquires a question v1 never had to
answer: **v1's contestants were off Earth, so 170 years passing was nobody's problem. In v2,
Earth is the thing being played for, and the season is a run, not a cosmology**
(`docs/setting-rebrand-options.md:164`). Either the fast-forward applies only inside the
table's constructed set, or the host realm really ages 170 years while the special is on.
The current phrasing says the latter. Open Q3.

**Permadeath (G-09) — MECHANICAL, already handled.** Game-side R17 splits it into softcore /
hardcore / Forsaken (`docs/rules-addendum.md:603`, `docs/gdd/gdd.md:104-106`), with
"no respawns" as an absolute explicitly retired
(`docs/audits/campaign-residuals-audit.md:491`). Table-side, the book keeps R5's death rules
(`docs/ttrpg-update-plan.md:34-35`). One genuinely v2-native addition already exists and is
excellent: **Dissolution completion removes you permanently and you become forever a puppet
of whatever collapsed you — no Ascension, no body** (`docs/gdd/gdd.md:100-102`,
`docs/rules-addendum.md:146-147`). Under v2 that reads as a *failed* apotheosis: the ending
where you got taken up by the wrong thing.

**Ascension (G-10) — RESKIN, but with an unreconciled fork underneath.** Canon maps it
near-verbatim: "winners of games can get some of the currency being bet around, allowing them
to gain divinity, and join the table as gamblers"
(`docs/cosmic-casino-canon.md:43-44`, `docs/setting-rebrand-options.md:120-122`). But
`docs/cosmic-casino-canon.md:190-193` flags the tension honestly: the bible's "becomes
unwagerable" exit and the divinity buy-in "are different doors out", owner to reconcile.
**The ending (§5) cannot be designed until that's ruled**, because whether a refusal door
exists decides whether the verdict is a mirror or a sentence.

**The verdict / "what kind of ruler" (G-11) — RESKIN into literal.** In v1 it was a
metaphor: the show tells you what kind of person you were and what kind of ruler you'd be
(`docs/story-canon.md:73-76`). In v2 it is the tables' actual prize — the final winner
decides how history is shaped for 250 years and how the apocalypse is remembered, the source
of every legend humanity created (`docs/cosmic-casino-canon.md:45-46`,
`docs/setting-rebrand-options.md:123-126`). This is the frame's strongest single upgrade and
its most dangerous sentence (§4).

### 1.2 The 7 MUST-PRESERVE checklist, each verified

Source list: `docs/setting-rebrand-options.md:10-20`.

| # | Must preserve | Survives? | Evidence / caveat |
|---|---|---|---|
| 1 | An audience whose attention is an economy (Viewers→Followers→Patrons, Camera Call, Goals) | ✅ **YES — improved** | Direct mapping, and "Patrons" already had the right name (`docs/setting-rebrand-options.md:30-33`); D5 formalises donator gods + THE patron god (`docs/DIRECTION.md:180-186`). |
| 2 | A power that issues Directives and runs the game | ✅ **YES** | The house = the fallen god's production apparatus, speaking through Directives and System messages (`docs/narrative/narrative-design.md:136-138`); mechanics unchanged, voice re-skinned (`docs/audits/campaign-residuals-audit.md:358`). |
| 3 | Dungeon floors with route exclusivity **and time skips** | ⚠️ **YES, with a new hole** | Exclusivity: clean (`docs/gdd/gdd.md:229-231`). Time skips: preserved and better-motivated (`docs/setting-rebrand-options.md:42`) **but** now interacts with the host realm's own clock — Open Q3. |
| 4 | The spine + the verdict/"what kind of ruler" ending | ✅ **YES — sharpened** | Spine is theme-neutral (`docs/story-canon.md:62-63`); the verdict becomes literal (`docs/cosmic-casino-canon.md:45-46`). |
| 5 | Permadeath **+ Ascension (the retired become patrons)** | ⚠️ **HALF — flag this one** | Permadeath: fine (R17). **Ascension does NOT survive in the same shape.** v1's Ascension is a *retirement*: finish the show, **go home**, become a Patron (`docs/review/review-6-story.md:206`). v2's is a *buy-in*: you gain divinity and join the table (`docs/cosmic-casino-canon.md:43-44`). The mechanism transposes 1:1; **the meaning inverts** — v1's Ascension is an exit that also makes you a sponsor; v2's is an entry with no exit. The canon itself flags the unreconciled residue (`docs/cosmic-casino-canon.md:190-193`). |
| 6 | Tags = identity assigned by watchers | ✅ **YES** | Kept as the crowd's labels; epithets added as a *separate* pantheon track, deliberately divergent (`docs/design/patron-gods.md:146-147`). 79 KEEP / 9 RENAME / 5 MIGRATE / 7 CUT already audited (`docs/audits/campaign-residuals-audit.md:36`). |
| 7 | The two information planes | ✅ **YES — more necessary** | Preserved verbatim (`docs/DIRECTION.md:149-163`, `docs/gdd/gdd.md:299-301`), and load-bearing as the tonal firewall now that the comedy register got sharper (cross-cutting #6). |

**Verdict on the checklist: 5 clean, 2 flagged.** Item 3's flag is a cosmology question
(cheap to rule, cheap to fix). **Item 5's flag is the real one** — and it is the same finding
as §2: v2 preserves the *mechanism* of Ascension while deleting the *exit* it used to
represent. Nobody has written that down as a delta yet; the rebrand doc scores it as a clean
1:1 map (`docs/setting-rebrand-options.md:40`), which is true mechanically and misleading
narratively.

---

## 2. The stakes problem — what does a v2 contestant actually want?

### 2.1 Statement of the problem (sharper than "the stake changed")

v1's stake is a three-layer stack and every layer works:

| layer | v1 | source |
|---|---|---|
| **the want** | go home; the only way out is through the ratings | `rulebook/gpt-system-v1.0.md:11-12` |
| **the pressure** | be entertaining or lose the audience economy; refuse and "we can't guarantee what will happen to you" | `rulebook/gpt-system-v1.0.md:12-13`, `:874-877` (viewers decay when you're boring) |
| **the record** | tags — who the show says you are | `rulebook/gpt-system-v1.0.md:963-972` |

v2 as currently written **keeps the pressure and the record and deletes the want**, and
replaces it with a want that has three defects:

1. **The prize is the antagonist.** The canon hard rule is that gods are morally alien —
   addicted, bored, petty, expanding influence in petty ways, ruin self-inflicted
   (`docs/cosmic-casino-canon.md:64-68`, `:78-79`). The pitch line is "whatever survives the
   breaking-down is what gets deified" (`docs/setting-rebrand-options.md:47-48`). A player
   who *understands the frame* should not want to become one of them. That is superb theme
   and dangerous motivation.
2. **The stake is cosmological, not personal.** "250 years of myth" is the *gods'* stake
   (`docs/cosmic-casino-canon.md:38-46`). A contestant cares about the divinity economy
   roughly as much as a racehorse cares about the tote board. INFERRED, but this is exactly
   the gap the task names.
3. **v2 deletes the antagonist and the exit at the same time.** In v1 you could want to beat
   the Corporation *and* want to leave. v2's "no motive at all"
   (`docs/setting-rebrand-options.md:50-53`) removes the thing to beat; "winning is joining"
   removes the door. What's left, unaided, is "don't die" — which is a floor, not a drive.

The residual motivation v2 *does* supply — "everyone is in the games; the alternative is the
Normal table's apocalypse" (`docs/cosmic-casino-canon.md:23`) — is real but undifferentiated:
it explains why humanity is fighting, not why **this** contestant, **this** floor, **this**
Moment.

### 2.2 Three concrete proposals

#### Proposal A — **Divinity is a lifeboat with a seat count** *(the want)*

The currency won at the table isn't only self-improvement — it is **transferable**. Every
chip is a name you can pull out of the erasure: a person resurrected, a patron seat bought
for someone else, a name written into the next 250 years so it isn't rewritten away. The
contestant plays not to become a god but to **decide who gets remembered**, and the show's
cruelty is that the price is always paid in pieces of yourself.

- **Why it fits the spine:** the show breaks your essence down by making the price of saving
  someone *be* the pieces of you (`docs/story-canon.md:62-63`).
- **Slot it already occupies:** character creation already has this field — the background's
  "**what you want back home**" pick (`docs/narrative/narrative-design.md:82-85`), and both
  built demo loadouts already fill it: Imani, "nothing for herself — everyone else out"
  (`docs/design/slice-contestants-proposal.md:64-65`); Dario, "the Ledger burned"
  (`:143-144`). The stake slot exists and is empty of consequences.
- **Canon support:** *partial and permissive*. Canon says winners take **some of the
  currency being bet around** (`docs/cosmic-casino-canon.md:43`) — an amount, not a binary —
  and religions are corporate bankrolls with transferable standing (`:47-52`). Nothing
  contradicts spendability. **Nothing asserts it either.** Requires one owner ruling.
- **Cost:** an economy rule + an epilogue procedure. M–L.

#### Proposal B — **The patron is the stake** *(the pressure)*

The contestant doesn't play for godhood; they play against their own sponsor's boredom. A god
paid for you; the bet is on you; displeasure has two named modes — **extraction** ("trials to
max out on you even if you break") and **total neglect** — and there is deliberately **no
contract exit**; you can be **bought out** and handed to something worse, with a notice of
replacement (`docs/narrative/narrative-design.md:93-95`, `docs/DIRECTION.md:180-196`). Moment
to moment the question is never "will I become a god?" but "**will the thing that owns me
stay interested?**" — which is *exactly* v1's "the only way out is through the ratings",
except the ratings now have a name, a face, a temperament and a taboo list.

- **Canon support: STRONGEST — this is already RULED.** Q1–Q8 all closed 2026-07-16
  (`docs/DIRECTION.md:191-196`); deal sheets show dos and taboos at bidding
  (`docs/design/patron-gods.md:167-171`); the abandonment modes are named. **Zero invention
  required.**
- **Honest weakness:** it is a pressure, not a want. It answers "why do I act this way in
  this scene" perfectly and "why am I still here in session 40" not at all. **Best used as
  the moment-to-moment layer underneath A or C, not as the whole answer.**
- **Cost:** S. It's built; it just needs to be *named* as the stake in the fiction.

#### Proposal C — **Play for the record, not the prize** *(the record, promoted to a want)*

What you compete for is **how you get remembered**, because in this cosmology that is not a
metaphor but the literal product (`docs/cosmic-casino-canon.md:45-46`). The epithet track is
already the machine for it: you start with trait-words from your background, earn more
through deeds, and when your accumulated pattern **recreates a real legend's pattern you
inherit its epithet**, graded folk-tale < local legend < heroic epic < world myth
(`docs/design/patron-gods.md:126-142`, `docs/design/mythology-research-spec.md:260-273`) —
and legends are explicitly artifacts of previous games
(`docs/design/patron-gods.md:140-142`). The verdict ending then stops being a surprise report
card and becomes the tally of a thing the player has been consciously writing all campaign.

- **Canon support: STRONG — ruled, but never framed as the stake.** The system exists; nobody
  has said "this is what you want."
- **Honest weakness:** it is a *vanity* stake. It can degrade into achievement-hunting, and
  it does not answer "why not just stop playing." Pair it with A and it stops being vanity:
  **a myth is the thing that protects a name from the 250-year rewrite.**
- **Cost:** S–M (framing + the myth catalog work already scheduled).

### 2.3 Which the existing canon supports — my read

- **B is supported outright** (ruled, zero invention) and should be adopted immediately as
  the moment-to-moment answer. It is the direct structural heir to "the only way out is
  through the ratings."
- **C is supported** (ruled) but needs *promoting from a system to a motive* — a framing pass,
  not a design pass.
- **A is the only one that needs a new ruling — and it is the only one that replaces what
  v1 actually lost.**

**The honest read: canon today gives v2 a pressure and a record and no want.** B and C are
both answers to *how* you play; neither answers *what you are playing for*. v1 had all three
layers. The cheapest complete fix is **B + C + a ruling on A** — and if the owner rejects A,
something structurally equivalent has to take its place, because the hole is real and it is
not a reskin problem, it is the conversion's one genuine design debt.

One more observation worth the owner's time, **INFERRED**: Proposal A also solves a second
problem for free. It restores an *exit* (you can spend your winnings and walk out having
bought what you came for) without contradicting "winning is joining" — the two doors become
a choice rather than a contradiction, which is precisely the unreconciled item at
`docs/cosmic-casino-canon.md:190-193` and precisely what §5 needs to make the ending land.

---

## 3. Existing campaign content under v2 — floors 1–6 and the set pieces

### 3.1 F1 — green forest, three labelled routes — **survives, gets better**
`docs/GPT_Master_Compendium.md:265`. Nothing about a forest and three doors is
alien-dependent. Two upgrades: (a) the **arena-as-psyche** rule — each arena shaped by the
judge/director god's mind, symbolic and surreal, never merely physical
(`docs/cosmic-casino-canon.md:76-77`), already ruled in from floor-set 3+
(`docs/gdd/decision-log.md:37`) — gives every future floor a reason to be shaped the way it
is, which v1 never had; (b) review-6's best joke gets a better owner: the routes are rated by
**survival odds only**, because the house cannot price moral damage
(`docs/review/review-6-story.md:71-74`) — at a casino that's an odds board, which is literally
what it is.

### 3.2 F2 — great desert, +70 years — **survives; one cosmology hole opens**
`docs/GPT_Master_Compendium.md:266`. Review-6 rightly calls the time skips the campaign's best
structural idea — choice becomes archaeology (`docs/review/review-6-story.md:52-55`). v2
motivates them properly for the first time (`docs/setting-rebrand-options.md:42`). **The
break:** in v1 the contestants were off-world, so nothing outside had to be tracked. In v2 the
host realm is the prize; if the framework fast-forwards *the realm*, then 170 years of Earth
elapse while the special runs — which is a season, not a cosmology
(`docs/setting-rebrand-options.md:164`). Cheapest fix (**INFERRED**): the fast-forward applies
to **the set**, not the realm — a VIP table is a constructed game space
(`docs/cosmic-casino-canon.md:24`) and its internal clock is the director god's to set.
Needs one sentence of ruling; blocks F2 and F3 content locking.

### 3.3 F3 — grand capital, +100 years — **survives unchanged**
`docs/GPT_Master_Compendium.md:267`. The route-convergence debt (all three routes converge on
one ecology and it currently reads as coincidence — `docs/review/review-6-story.md:59-64`,
tracked as I-20) is entirely frame-independent: it is the highest-value story item in *either*
version.

### 3.4 The capital attaches to the Lounge — **survives, gets better**
Under the Corporation this was a base upgrade. Under the house it is the **comp suite
annexing your conquest** — the casino absorbing the attraction next door
(`docs/setting-rebrand-options.md:36`, `rulebook/gpt-system-v1.0.md:1180-1186` Golden Cage
pillar). The Golden Cage design pillar — the Lounge is *so good* that contestants delay their
own descent, and the house profits either way — is one of the strongest paragraphs in the v1
book and it needs **zero** edits beyond swapping the noun. INFERRED, high confidence.

### 3.5 F4–6 — continent merge — **the frame's biggest structural win**
`docs/GPT_Master_Compendium.md:268`. Review-6 flags it as "a premise, not a design", holding
the project's best character (`docs/review/review-6-story.md:66-69`). v1's stated reason
("players consolidated into shared floors as competition narrows") is TV-production
hand-waving. v2 hands over a native mechanism: **the casino closes tables and moves survivors
to the main floor as the wagering concentrates.** That is literally how a tournament ends, it
explains merge pacing, it explains why other contestants suddenly exist, and it explains why
the stakes visibly rise. INFERRED, but it costs nothing and it converts the least-designed
region into the most obviously-shaped one.

### 3.6 Medium route — the demon girl, the queen, the human farm — **the one real FORK**
`docs/GPT_Master_Compendium.md:276-279`. Three findings.

**(a) The demon cosmology has three incompatible homes in v2 and none is ruled.** v1's rule is
categorical and clean: normal demons are fallen, comprehensible humans; **nobility corrupts by
existing** (`docs/GPT_Master_Compendium.md:428`). v2 offers:
1. **Followers of gods dragged into the framework** — the canon monster taxonomy: Insane
   Followers (hostile), Sane Followers (traders/allies), Worshipped Creatures (revered,
   moral dilemmas) (`docs/cosmic-casino-canon.md:150-155`);
2. **Abrahamic corporate staff** — messenger-tier figures as suits in an investor institution,
   the three brands as fronts of one holding company (`docs/cosmic-casino-canon.md:47-56`) —
   and Beelzebub, Lucifer and Mammon are already on the proposed patron roster as *gods*
   (`docs/design/wave5-roster-shortlist.md:31-34`);
3. **The house's own court** — the fallen god's dealers and nobility.

These cannot all be true at once, and the route's whole moral engine depends on which. **My
recommendation (INFERRED): option 3.** Noble demons as the management's court makes "corrupts
by existing" mean *proximity to a divine thing you are not built to stand near* — which is
exactly what Dissolution already models mechanically
(`docs/GPT_Master_Compendium.md:429`). It makes the Medium route "the route where you get
close to the people running the game", which is thematically the best version of a complicity
route, and it keeps the Abrahamic satire (option 2) safely away from this content.

**(b) The brand contract gets BETTER.** The brand is a contract that works by *dulling you* —
massive EQ loss, drier perception, less of you to reach
(`docs/story-canon.md:12-19`). Under v2 that reads as an **unauthorised second patronage**:
you signed with something that isn't your god. This gives I-23's brand-breach rules a native
mechanism for free — breach isn't "the demons get angry", it's "your actual patron finds
out", and D5 already rules that abandonment is never a contract exit
(`docs/DIRECTION.md:184-190`). INFERRED, but it fits the ruled machinery exactly.

**(c) The 170-year continuity bug is fixed for free.** Review-6's item: the F3 human-farm
leader is "the surviving F1 NPC", a mortal, ~170 years later
(`docs/review/review-6-story.md:108-112`). v2 supplies three ready mechanisms (divine favour,
a relic, or the queen keeping him alive as a pet cruelty) where v1 had none. Part of I-17
closes on the frame swap alone.

**(d) What does NOT get fixed:** the route's compliance assumption — every beat assumes the
players do the monstrous thing, and refusal forks don't exist
(`docs/review/review-6-story.md:102-103`, I-23). Frame-independent design debt.

### 3.7 Easy route — the mask, the chained man, Nullrot — **survives and closes two known holes**
`docs/GPT_Master_Compendium.md:271-274`. Review-6 grades it the best route as written but
names two gaps: the mask has no origin, wants or rules; **Nullrot's spread-AND-cure behaviour
has no motive and "runs on vibes"** (`docs/review/review-6-story.md:86-89`). v2's loot doctrine
answers both in one stroke: **God Relics and Follower Relics — loot must feel like remnants of
belief, never generic stat sticks** (`docs/cosmic-casino-canon.md:156-159`). The mask becomes a
relic of a forgotten god, and possession is that god trying to get back on the board; Nullrot
balancing every mercy with a cruelty becomes the shape of a bankrupt god's bargain rather than
a writer's coin-flip. INFERRED, but it is the cleanest example in this whole audit of the
frame paying for itself.

### 3.8 Hard route — the Loong — **survives, gets better; its weakness is untouched**
`docs/GPT_Master_Compendium.md:281-284`. v2 has the category pre-built: **Worshipped
Creatures — revered beings, moral dilemmas** (`docs/cosmic-casino-canon.md:152-153`). The
Loong is one by construction. And its premise gains a native tragedy: it guards a city whose
god went bankrupt, and its worshippers are gone because a previous cycle's winner rewrote the
myth that held them — which ties the route directly to the campaign's own thesis about who
authors memory. INFERRED. **Unchanged:** it is still structurally an escort quest three times
over (`docs/review/review-6-story.md:123-126`), and the moving-arena reinvention (I-29) is
still the fix. A frame cannot repair a quest shape.

### 3.9 The Dissolution-songs encounter — **mechanically untouched; framing improves**
`docs/GPT_Master_Compendium.md:251-256`. Review-6 calls it the campaign's crown jewel and its
key insight — Dissolution amplifies *an* emotion, not necessarily yours — the thing that
elevates the mechanic to theme (`docs/review/review-6-story.md:133-138`). Nothing in it touches
the frame. Two notes: the digital *personalisation* problem (the game must infer each
character's fear from observed play — `docs/review/review-6-story.md:141-145`) now has a
diegetic author under v2 (a god picks your song, and paying to pick it is a *tip to the
dealer* — `docs/cosmic-casino-canon.md:32-34`), which turns an engineering feature into a
story beat; and the licensed tracks remain unshippable in both versions
(`docs/audits/campaign-residuals-audit.md:493`).

### 3.10 Sasha's F1 demon encounter — **survives untouched; the portability proof**
`docs/GPT_Master_Compendium.md:296-303`. The funnel-to-the-door maze, the two valid paths
(fight = shown revelation, flee = lonelier deduction), and the reveal that the fear is
Nikita's — none of it references the power running the show. Review-6 calls it the
best-designed single encounter and extracts its principle (both paths reach the truth; they
differ in cost and loneliness — `docs/review/review-6-story.md:147-153`). **This encounter is
the single strongest evidence that the character-level content is theme-portable**, which is
the finding §6 generalises. One caveat: its power depends on the Polish / Eastern-Front detail
landing as *atmosphere, never explanation*
(`docs/GPT_Master_Compendium.md:302`, `:430`) — see §4.

### 3.11 The Incinedile — **survives; thesis sharpens**
`docs/GPT_Master_Compendium.md:204-220`. The audit confirms **zero Corporation-flavoured text
in `enemies.json`** — the anticipated re-voice burden here is zero
(`docs/audits/campaign-residuals-audit.md:220-223`). Thematically the mycelium-puppet reveal
teaches "nothing on this show is what it appears to be; the spectacle is a skin over the real
organism" (`docs/review/review-6-story.md:155-158`) — which under v2 also describes the
bankrupt god running the table, so the tutorial's thesis now rhymes one layer higher. Its
reality-TV pun name survives because the show's TV skin is diegetic
(`docs/setting-rebrand-options.md:116-119`). Unshippable boss music unchanged.

### 3.12 Nikita's continent-merge appearance — **survives, gains a mechanism**
`docs/GPT_Master_Compendium.md:293`. Structurally the risk is unchanged: the project's best
character's payoff sits in its least-designed region
(`docs/review/review-6-story.md:66-69`); the mitigation (echo the thread every floor — a scarf
glimpsed, a bar of the song) applies to both versions. What v2 adds: **war-domain gods bid hard
the first time the song lands; Hestia-shaped gods bid on the old man, not the weapon** — already
APPROVED on the sheet (`docs/characters/nikita.md:79-80`). That is the Old/War duality rendered
as an economic contest between two gods over which version of him is worth more, on air. v1
could not do that. It is, mechanically, the best expression of the spine anywhere in the project.

### 3.13 Route exclusivity — **untouched**
`docs/story-canon.md:70-72`, `docs/gdd/gdd.md:229-231`. One free diegetic upgrade: routes are
separate side-bet books, and you can only be wagered on one line. INFERRED.

---

## 4. Nikita

**Short answer: he still parses, and under v2 he becomes *more* resonant — but only under a
narrow reading of one canon sentence, and that narrow reading is not yet written down. The
risk is not Nikita. The risk is the sentence.**

### 4.1 What changes about his position

Under v1, the frame is morally neutral toward him. The Corporation is a stupid, greedy alien
company that does not know what it grabbed; his history is his own, and the show exploits it
out of ignorance and appetite. The two-planes rule is the tonal firewall — comedy on the
broadcast plane, grief on the diegetic plane — and review-6 already names this as the thing
that keeps corporate comedy ("Sup, nerds!") in the same product as Holocaust-adjacent grief
(`docs/review/review-6-story.md:43-48`).

Under v2, the frame makes a much stronger claim: the outcomes of these games are **the source
of every legend, idea, and imagination humanity ever created — it all stems from these games**
(`docs/cosmic-casino-canon.md:45-46`, restated `docs/narrative/narrative-design.md:130-133`).
That sentence admits two readings, and the whole question turns on which one is canon:

- **Reading 1 (narrow):** the winner authors the **myth-layer and the memory** — gods,
  legends, religions, how the apocalypse is remembered. Human history still happened to
  humans; what the games write is the mythology laid over it.
- **Reading 2 (broad):** the games *authored* human history, atrocities included.

**Under Reading 1, Nikita gets meaningfully better.** The machine that converts human
suffering into story becomes literal, on stage, and staffed by beings who find it delicious.
His scarf — a promise to a dead woman he can't return
(`docs/GPT_Master_Compendium.md:292`, ruled **pure story weight, no mechanics**,
`docs/characters/nikita.md:49-50`) — becomes the one object in the game that refuses to be
content. That is a stronger Nikita than v1's, not a compromised one. And the show's incentive
gets uglier and truer: the show will play the song *because it rates*
(`docs/characters/nikita.md:67-69`) — now with named gods paying for it.

**Under Reading 2, it breaks.** Making a real genocide downstream of a divine card game
converts it into cosmological set dressing and takes its authorship away from the humans who
committed it. It also violates the project's own guardrail, recorded in the compendium's
design principles: **historical/cultural context in narrative = atmosphere, not explanation**
(`docs/GPT_Master_Compendium.md:430`, echoed in his own entry at `:294`). Reading 2 makes
history *explanation*. That is the failure mode, and the canon text as written sits closer to
Reading 2 than to Reading 1.

**Recommendation:** rule the scope explicitly, and rule it narrow — *the games author the
myth-layer and the memory; never the events.* One sentence. It protects Nikita, it protects
the ending (§5), and it costs nothing.

### 4.2 The second consideration — a specific new adjacency

v1's aliens have no opinion about Jews, Poles or the Eastern Front; they are an appetite.
v2's pantheon does have opinions, because it contains real religious figures played as
comedy: modern major religions as investor institutions present as **large corporations**,
messenger-tier figures (Metatron, Gabriel) as corporate staff, and — approved lore — **the
three Abrahamic brands as fronts of one holding company**, played deadpan-corporate
(`docs/cosmic-casino-canon.md:47-56`).

Putting a Jewish Holocaust survivor on a stage where a satirical Judaism-Christianity-Islam
holding company is a running joke is a materially different proposition from putting him on a
stage run by aliens. It is not disqualifying — the owner is already running a deliberate
sensitivity policy with real carve-outs (named Islamic prophets out; the
closed-ceremonial-material exclusion stands — `docs/cosmic-casino-canon.md:96-98`) and a stated
bar ("respectful, never racist" — `:84-86`). But it will read as a statement whether or not one
is intended, so it should be a decision rather than a side-effect.

**Recommended addition to the existing policy — a separation rule, not a ban:** *Nikita's
material and the Abrahamic-corporate satire never share a scene, a floor, or an episode.*
Cheap to honour, removes the worst possible juxtaposition, costs neither piece of content.

### 4.3 What v2 gives him for free

1. **The patron fight over his two selves** — war gods bid on the weapon, hearth gods bid on
   the old man (`docs/characters/nikita.md:79-80`, APPROVED). The spine as an auction.
2. **The rhyme.** Reversion is a mortal made briefly god-shaped by a song
   (`docs/characters/nikita.md:31-40`: full reversion, young again, body and mind), in a
   setting about mortals becoming gods. Free thematic interest.
3. **The epithet track.** The show will try to name him
   (`docs/design/patron-gods.md:126-147`), and the name it lands on *is* the episode's thesis.

### 4.4 What gets harder

v1's Nikita has an implicit possible mercy: the war ended, there is a home, the scarf could in
principle be returned. v2 has no home to return to. The promise becomes unreturnable in a
stronger sense. That is arguably better tragedy — but it removes a mercy ending the owner may
want available. Flag it as a choice, not a bug.

### 4.5 Clear read, stated plainly

**KEEP Nikita, unchanged in shape.** He is the deepest thing in the project
(`docs/review/review-6-story.md:167-177`) and none of his machinery is frame-dependent. Add:
(1) the Reading-1 ruling on the scope of "shapes history"; (2) the adjacency separation rule;
(3) continue honouring the existing guardrails — history as atmosphere, and **the wife gets
full individual personhood before any historical framing**
(`docs/GPT_Master_Compendium.md:294`). Do not dodge the character, and do not soften him;
the thing that needs handling is one sentence of cosmology, not the man.

---

## 5. The ending

### 5.1 Is "nobody has this ending" true? — mostly, but claim the right thing

The canon pitch: winning promotes you into the audience, the verdict decides what kind of god
you become, and "nobody in the DCC lane — or anywhere adjacent — has that ending"
(`docs/setting-rebrand-options.md:44-48`).

Honest assessment: **apotheosis endings are not rare.** Ascension-to-the-system endings are
common in the LitRPG/progression lane, and the project's own canon cites ORV as a design
reference for myth grading (`docs/design/patron-gods.md:136`). What *is* rare is the
**conditional** form already written into the GDD: the ending varies **by essence axes and
path history, not by a last-minute choice** (`docs/gdd/gdd.md:295-298`). "You ascend" is
common; "**you ascend as the specific thing the game has been quietly measuring you into, and
you cannot renegotiate it in the last scene**" is genuinely uncommon and is the defensible
claim. Recommend the owner market *that*, because it is true and it is also the thing that is
hard to copy.

### 5.2 What the TTRPG needs for it to land **at a table**

A video game can compute a verdict function over a logged command stream. A table cannot.
Six concrete requirements, in order of importance:

1. **A visible ledger with invisible totals.** The verdict must never be the GM's end-of-
   campaign opinion; it must be an accumulation the players *felt being taken*. Practical
   shape: one index card per axis, on the table all campaign; at each floor-set's question the
   GM visibly writes a mark and the card goes back in the envelope. Players see the ritual,
   never the tally. This is the tabletop analogue of the convergence matrix (I-20,
   `docs/ISSUES.md:36`), and it is 90% of the work.
2. **The axes are declared up front, in the book, as the campaign's structure.** The
   architecture is already canon — each floor-set asks one question that determines who you
   are (`docs/story-canon.md:65-72`), with three shapes ruled: necessary vs right, safety vs
   justice, power for yourself vs power for many (`:69-71`). A table needs to *know* it is
   being asked, or the choices are just choices. The dramatic irony — they know they're being
   scored and still can't game it — is the point.
3. **The verdict is a scene, not a score.** "You scored 4 on self/many" is dead at a table.
   What lands is the machinery the game already owns: the house cuts your season into a
   **highlight reel**, and the reel is accurate and unkind. **Recommendation: the last episode
   IS your own highlight reel, narrated by the house, and the godhood you are offered is the
   shape of the person in the reel.** That uses the two information planes
   (`docs/gdd/gdd.md:299-301`), the announcer, and the tags — all built — and it is a scene a
   GM can actually run.
4. **A final choice that is real but does not move the verdict.** The verdict names what you
   are; the last decision is only whether you take the seat. This requires resolving the
   unreconciled two-doors item (`docs/cosmic-casino-canon.md:190-193`): divinity buy-in vs the
   "unwagerable" exit. **Both doors must exist**, or the verdict is a sentence rather than a
   mirror — and §2's Proposal A is the cleanest way to make the refusal door mean something
   (you spent your winnings on other people instead of on yourself).
5. **The campaign must have cost something by then.** Permadeath is what makes the verdict
   heavy; at a table that is simply R5's death rules (`docs/ttrpg-update-plan.md:34-35`) plus
   the rule that recruited companions are permanently losable (`docs/story-canon.md:45`).
6. **A 250-year epilogue procedure.** The cheapest high-impact artifact in this entire
   document: after the verdict, **each player writes, in one paragraph, the myth their
   character became** — in the register of a legend — and the GM reads them aloud as the next
   cycle's scripture. Ten minutes, zero system, and it lands the frame's whole thesis
   (`docs/cosmic-casino-canon.md:45-46`). Bonus: those paragraphs *are* the epithet/myth
   catalog for the next campaign (`docs/design/patron-gods.md:143-145` already proposes exactly
   this loop for Stage 2).

### 5.3 What happens to v1's ending if v2 takes this one

**Nothing is taken away, because v1 does not currently have one.** Review-6 is explicit: "The
campaign has no designed finale" — mechanically a Stage boss you're not expected to beat
exists, and the Winner's Arc (finish the show, go home, become a Patron) exists as NG+
machinery, but narratively the last episode is undesigned
(`docs/review/review-6-story.md:203-212`).

But if v2 owns apotheosis, v1 should deliberately take the **opposite** door, and its own
material already names the candidates: the winner becomes the next product; the audience
revolts; the show is renewed forever; **the colonization vote actually happens**
(`docs/review/review-6-story.md:209-210`).

**My recommendation: v1 takes the colonization vote.** It is the only candidate the v1 premise
actually *earns* — the show exists to prove a thesis to an electorate
(`rulebook/gpt-system-v1.0.md:10-11`), so the finale is the electorate voting, and the verdict
on you is the argument they vote on. That gives the two versions a clean, non-competing split:

- **v1's ending is political** — you are evidence in someone else's referendum, and the
  question is what you proved about your species.
- **v2's ending is theological** — you are the next 250 years of scripture, and the question
  is what you proved about yourself.

Same verdict instrument, opposite meanings; neither is a lesser copy of the other. And v1 keeps
one asset v2 structurally cannot have: **a real exit** — go home, and become the thing that
sponsors the next contestant. Protect that as v1's.

---

## 6. Floors as a shared spine

### 6.1 What is theme-neutral (and it is more than expected)

| layer | theme-neutral? | evidence |
|---|---|---|
| **The spine question** — "how much can we break your essence down in the name of entertainment?" | **100%** | `docs/story-canon.md:62-63`. "Entertainment" is the operative word and both frames are entertainment economies. Carries both versions verbatim. |
| **The question architecture** — each set asks one question; answers gate path-dependent unlocks; ending is a verdict | **100%** | `docs/story-canon.md:65-76`. It is a scoring architecture, not a fiction. |
| **The essence-vs-label duality** — tags are what the audience calls you; the axes are what you are; keep them separate and occasionally contradictory | **100%** | `docs/story-canon.md:84-88`. Works identically for a crowd of humans and a crowd of gods. |
| **The three ruled axes** — necessary/right · safety/justice · self/many | **100%** | `docs/story-canon.md:69-71`, `docs/narrative/narrative-design.md:62-64`. None references aliens or gods. |
| **The F1–F3 sub-theme** — "will you cure what's corrupted, and at what cost?" | **wording yes, content no** | `docs/story-canon.md:91-93`. The question travels; its content (Nullrot, demon cures, the Loong-as-cure) rides the demon cosmology, which is the one FORK (§3.6). |

### 6.2 Where the two versions must split

The fork is **not in the questions. It is in the referents of the answers** — three of them:

1. **What the power wants.** v1's power has a motive and therefore a preference (prove
   colonization is beneficial, `rulebook/gpt-system-v1.0.md:10-11`); v2's has none by hard rule
   (`docs/cosmic-casino-canon.md:78-79`). So a complicity question plays differently: in v1
   serving the house means endorsing a colonization argument — a political act with a
   real-world referent; in v2 it means amusing a bored immortal — a moral act with no referent.
   **Same question shape, different meaning.** The Medium route's complicity engine
   (`docs/review/review-6-story.md:94-99`) sits exactly here.
2. **Whether an exit exists.** v1 has one; v2 does not (§2). Any floor-set built on "what would
   you give up to go home" is v1-exclusive.
3. **Whether being remembered is a stake.** v2-native (`docs/cosmic-casino-canon.md:45-46`);
   in v1 nobody on Earth is watching, so "what will they say you were" lands weakly.

### 6.3 Concrete read — which floor-set questions carry both

| # | Floor-set question | v1 | v2 | verdict |
|---|---|---|---|---|
| 1 | **Necessary vs. right** | ✅ | ✅ | **BOTH — verbatim** (ruled shape, `docs/story-canon.md:69-71`) |
| 2 | **Safety vs. justice** | ✅ | ✅ | **BOTH — verbatim** |
| 3 | **Power for yourself vs. power for many** | ✅ | ✅ | **BOTH** — but the *prize* differs (v1: leverage with the Corporation; v2: divinity). Same question, re-costumed reward. |
| 4 | **Will you cure what's corrupted, and at what cost?** (F1–3) | ✅ | ✅ | **BOTH** at question level; **content forks** on the demon ruling (§3.6). |
| 5 | **Is a life worth an audience's attention?** (the spectacle price) | ✅ | ✅ | **BOTH** — this is the spine's most direct restatement. |
| 6 | **Complicity: do you serve the house, or not?** | ✅ political | ✅ moral | **SHARED SHAPE, SPLIT MEANING** — author once, write two sets of consequences. |
| 7 | **Would you leave without them?** (the exit) | ✅ | ❌ | **v1-ONLY** |
| 8 | **What will they say you were?** (memory / myth) | ⚠️ weak | ✅ | **v2-ONLY** |
| 9 | **What do you owe the thing that made you?** (patron / creator) | ⚠️ weak | ✅ | **v2-ONLY** — the patron system is the machinery (`docs/DIRECTION.md:180-196`). |

**Headline: 5 of 9 carry both versions unchanged, 1 more shares its shape and forks only in
consequence, and 3 are version-exclusive.** The practical consequence for floors 7–20 (paused
by design, `docs/story-canon.md:66-67`) is significant: **they can be designed ONCE at the
question level and forked only at the content level.** Two versions of the campaign do not
require two campaign architectures — they require one architecture, one shared bank of ~6
questions, and two sets of set pieces. That is the cheap way to run both, and it is available
because the owner already made the architecture theme-neutral before the frame swap was on the
table.

---

## Cross-cutting observations

1. **The frame swap pays for itself in story debt.** Three of review-6's open items close on
   the reskin alone: the mask's missing origin and Nullrot's missing motive
   (`docs/review/review-6-story.md:86-89` → relic canon,
   `docs/cosmic-casino-canon.md:156-159`), and the Medium route's 170-year continuity bug
   (`docs/review/review-6-story.md:108-112`). A fourth — the missing production cast, I-12
   (`docs/ISSUES.md:28`) — closes because Momus already exists
   (`docs/cosmic-casino-canon.md:73-75`, RULED shared host,
   `docs/setting-rebrand-options.md:157`). **I-17 and I-12 both shrink materially under v2.**

2. **The TTRPG re-skin decision is contradicted in the record — three states, four documents.**
   (a) RULED "RE-SKIN TO CASINO — the live table adopts the casino frame alongside the game",
   2026-07-16 (`docs/setting-rebrand-options.md:155-157`, echoed
   `docs/gdd/decision-log.md:39`). (b) Explicitly scoped OUT eight days later: "Explicitly out
   of scope: the video game's setting change. The TTRPG keeps its ORIGINAL setting… Everything
   Cosmic-Casino-flavored is video-game-only and stays out of the book and the app"
   (`docs/ttrpg-update-plan.md:6-9`), formalised as a three-canon guard
   (`:13-19`) with a hard-exclusion list (`:21-45`). (c) Still carried as **OPEN** in two
   decision logs (`docs/narrative/decision-log.md:23-25`, `docs/gdd/decision-log.md:13`).
   (d) The live rulebook, updated to v1.1 on 2026-08-04 — *after* all of the above — still opens
   with the abduction/Corporation premise (`rulebook/gpt-system-v1.0.md:9-13`).
   **The v1/v2 two-version framing resolves this cleanly, but it must be written down as a
   superseding decision or the contradiction will resurface in a future session.**

3. **The three-canon guard is the right tool and already exists.** `docs/ttrpg-update-plan.md:13-19`
   separates TTRPG book / digital rules / video-game setting layer. v2 needs that table amended
   to four rows — or better, its third row renamed from "video-game setting layer" to
   "**v2 setting layer**", shared by the v2 TTRPG and the game. Its hard-exclusion list
   (`:21-45`) doubles, read in reverse, as **a ready-made import manifest for a v2 TTRPG fork**:
   casino frame, patron gods, bidding, boons, buy-outs, Forsaken runs, epithets, rival-god
   interventions, the mythology roster, R16 races, R17 run types, R5's puppet epilogue.

4. **v2 deletes the antagonist and the exit at the same time** (§2). This is the conversion's
   single largest narrative risk and it is *not* the abduction reskin, which is a paragraph.

5. **Content cost is concentrated in cosmology, not scenes.** Of the fourteen set pieces walked
   in §3, exactly one — the demonic-nobility cosmology (G-32) — requires a genuine FORK
   decision. Everything else is RESKIN or KEEP, and four items actively improve.

6. **The two-planes rule is the tonal firewall in BOTH versions, and v2 needs it more.**
   Review-6 identified it as the mechanism that lets corporate comedy sit beside
   Holocaust-adjacent grief (`docs/review/review-6-story.md:43-48`). v2 sharpens the comedy
   register considerably — Greek gods in Hawaii-vacation mode, Romans food-obsessed, Abrahamic
   brand managers (`docs/cosmic-casino-canon.md:90-93`) — while leaving the grief plane
   untouched. The firewall does more work, not less.

7. **Licensed-content debt is frame-independent and unchanged**
   (`docs/audits/campaign-residuals-audit.md:493`): the boss music and every Dissolution song
   are dev vibe references in both versions.

8. **One asymmetry worth stating plainly:** v1 is the version with a *reason to fight* and no
   designed ending; v2 is the version with a designed ending and no reason to fight. Fixing
   each version's hole is roughly one owner decision apiece — §2 for v2, §5.3 for v1.

---

## Open questions for the owner

Ranked by how much else they block.

1. **What is the contestant's personal stake in v2?** (§2) Adopt B + C and rule on A, or supply
   an equivalent. **Blocks: every floor-set question, the ending, character creation's "what
   you want back home" field, and the pitch.** Highest-leverage item in this document.
2. **Scope of "shapes history for 250 years": the myth-layer and the memory, or the events?**
   (`docs/cosmic-casino-canon.md:45-46`) Recommend **narrow — myth-layer only**. Blocks Nikita
   (§4), the ending's meaning (§5), and the epithet catalog's premise.
3. **Where do demons live in v2's cosmology?** Fallen humans (v1's rule,
   `docs/GPT_Master_Compendium.md:428`) / followers-of-gods
   (`docs/cosmic-casino-canon.md:150-155`) / the house's own court / Abrahamic corporate staff
   (`:47-56`)? Recommend **the house's court**. Blocks the entire Medium route, the brand
   contract, and the Dissolution-songs framing.
4. **Is v2 a TTRPG fork, a game-only frame, or both** — and does that supersede
   `docs/setting-rebrand-options.md:155-157` and `docs/ttrpg-update-plan.md:6-9`? (cross-cutting
   #2). Cheap to answer, expensive to leave ambiguous.
5. **Time skips vs. the season clock:** does the fast-forward move the host realm or only the
   table's set? (§3.2) Blocks F2/F3 content locking and the meaning of the prize.
6. **Ascension's two doors** — divinity buy-in vs. the "unwagerable" exit
   (`docs/cosmic-casino-canon.md:190-193`). The ending cannot be staged until this is ruled.
7. **Does v1 take the colonization-vote finale and keep the "go home" winner's arc
   exclusively?** (§5.3)
8. **Adopt the Nikita adjacency separation rule** (no shared scene/floor/episode with the
   Abrahamic-corporate satire)? (§4.2)
9. **Are floors 7–20 authored once at the question level and forked at content level?** (§6.3)
   If yes, the shared question bank should be written before any floor-7 content.
10. **Nikita's two key scenes** — what "winning" a War-Nikita fight means, and the recognition
    scene (I-24, `docs/ISSUES.md:40`; OPEN on his sheet,
    `docs/characters/nikita.md:85-87`). Frame-independent, still owner-gated, and §3.12 argues
    it gets *more* valuable under v2, not less.
11. **Does "Galactic Prime Time" remain the title for a v2 *table*?** Kept for the game
    (`docs/setting-rebrand-options.md:158-159`); unasked for a v2 TTRPG.
12. **Races and the live party at a v2 table** — the book keeps Human/Animal/Robot-AI
    (`docs/ttrpg-update-plan.md:31-33`) while the game removed Robot/AI (R16); and the live
    party's status at a v2 table is unasked (G-42, G-43).
