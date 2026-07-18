# Slice Contestants — Proposal: the two original premades (issue I-3)

*Status: **PROPOSAL — awaiting owner approval.** Nothing here is canon until ruled.
Context: the character-IP ruling (`../story-canon.md` "Character IP split", 2026-07-15)
parks the live players' characters — the game gets an **original cast**. Sasha & Nikita
enter separately as recruitable NPCs; this document covers the **two original premade
contestants** the vertical slice needs (review-4 §5; `../characters/contestant-template.md`:
"Slice needs two").*

***R14 discipline applies throughout:* every number below — trait spreads, skill levels,
damage references, Camera Call stacks — is **PLACEHOLDER (R14)** pending the numbers
rework. Shapes and identities are what is being proposed, not values.*

---

## Where these two fit (proposed reconciliation)

Review-4 §5 specifies the slice as *"2 premade contestants (player controls both)."*
Story-canon's later Q68 ruling reshapes the slice party to *player OC (default build or
60-second creation) + Sasha & Nikita recruits, party of 3.* Proposed reconciliation, for
owner confirmation (Open Question 1):

- These two premades are the **default-build options for the player's OC slot** — pick
  one and play immediately, or take the 60-second creator instead.
- Until the recruitment encounters exist in the build, they also serve as the review-4
  §5 two-hander (player controls both) so the arena + Incinedile Phase 1 + hype meter
  are testable **now**, before KAN-4 party work lands.
- They are deliberately designed as a **pair**: two breach paths, two speeds, two
  audience reads. Whatever roster shape wins, the pair coverage below holds.

Both premades are **Human** (`data/races.json` id 1). Rationale: animal part layouts are
deferred by owner ruling (Q61, 2026-07-17), so an animal premade would block on an
unauthored system. An animal-cast option is raised in Open Questions.

Both follow R16 creation rules: the background grants 4 skills; **each premade traded
their 4th background skill for +1 cap on a signature skill** — which is why they carry
exactly 3 skills and one raised cap. (This also demos the trade rule on screen.)

---

## Contestant 1 — Imani "The Door" Brandt

### Broadcast persona (the edit)
The immovable veteran. Heavy-rescue firefighter, mid-career, zero interest in the
camera — which the camera loves. The show cuts her as the wall between the monster and
everyone else: slow walk, held breath, doors opened, people carried out. Broadcast
handle: **"The Door"** — *when the Door opens, somebody's getting carried out.*
Momus-plane framing writes itself: the contestant who treats the deadliest game show on
television as *a shift*. Expected tag drift: `fan_favorite`, `protagonist`,
`method_actor` (she is not performing — that IS the method).

Per R18 (Charm = presentability, not charisma): her Charm is a strong, legible
silhouette — soot-dark turnout gear, scarred forearms, a stance the camera finds in any
crowd shot. She never plays to the lens; the lens plays to her.

### Background (the audition tape)
Eighteen years of heavy rescue — the breacher, the one who cuts into burning buildings
and collapsed stairwells and brings people out. Dismissed after she ignored a pull-out
order during a tenement collapse: she got the child out; two of her crew didn't come
back, and she has never once said she'd choose differently. She wants to go home with
nothing — she wants the people *around her* to go home.

**Structured picks (bidding keywords):** origin *burning stairwell* · virtue *nobody
left behind* · vice *cannot obey a pull-out order* · wants back home *nothing for
herself — everyone else out*.

**Which god archetypes bid, and why (≥2 required):**
1. **Hearth/protection archetype — `hestia` (`data/patron_gods.json` id 3), direct
   match.** Her natural play IS Hestia's seeded favor list (stabilize an ally's lethal
   part, share a consumable, protect the weak); her firing offense ("never left anyone")
   is the taboo list inverted. The obvious, comfortable offer.
2. **War archetype — `ares` (id 1).** "Finish a fight without retreating" is literally
   the thing she was fired for. Ares reads refusal-to-withdraw as glory; he is bidding
   on a misread — she doesn't fight for victory, she fights for extraction — and that
   misread is a story engine (displeasure, extractive-mode threat, buy-out drama).
3. **Forge/fire archetype (roster pass; domains list already includes `fire`).** The
   perverse bid: a fire god wagering on the woman who has spent her life robbing fire of
   its due. It doesn't want her to win — it wants to watch the rematch. Exactly the
   morally-alien register the canon demands.

The deal-sheet moment — a hearth god, a war god, and a fire god all bidding on the same
firefighter for three incompatible reasons — is the patron system's pitch in one screen.

### Race + traits — PLACEHOLDER (R14)
**Human** (`races.json` id 1). Creation-legal 7 Body / 7 Core, max 5:

| Physique | Reflexes | Mind | Charm |
|---|---|---|---|
| 5 — PLACEHOLDER (R14) | 2 — PLACEHOLDER (R14) | 4 — PLACEHOLDER (R14) | 3 — PLACEHOLDER (R14) |

### Skills (3; all real `data/skills.json` entries — no new skills needed)
| Skill (id) | Start Lv — PLACEHOLDER (R14) | How it plays in the slice |
|---|---|---|
| **Strong Strike** (id 4, `strong_strike`) | 2 | The held-breath button: a 2-Moment windup, +1 damage, Exposed while performing — teaches R2's dodge-the-windup rule from the *dealing* side, and is her half of the pair's 7+ single-hit breach (see pair section). |
| **Overhead Slam** (id 23, `overhead_slam`) | 1 — **cap 6 via the R16 skill-trade** | 3 Crush + knockdown with a Heavy Large weapon; the tool for advancing Crushed to Tier 2 on Incinedile's left hand — the flamethrower-disable discovery, her clip of the night. |
| **Brace** (id 8, `brace`) | 2 | 0-Moment reaction, reduce next Crush/Burn by 1: she steps into the flamethrower cone or the Dash line for someone else — the tank fantasy in one free action. |

*Gear note (content pass, not this doc): needs a Heavy Large breaching weapon
(fire-axe/breaching-maul pattern); no current `items.json` entry qualifies — flag for
the slice content pass. Plus 1× `bandage` (items id 1).*

### Camera-call / hype angle
- **Windup drama:** Strong Strike's Exposed channel is the hype meter's slow build —
  the crowd holds its breath *with* her (the skill's own flavor text).
- **Body-blocking is cinema:** the compendium notes the wide flamethrower cone makes
  body-blocking cinematic — Brace-into-the-cone for a stranger is the "No Safety Play" /
  protective-spectacle Goal served on a plate.
- **The disable clip:** Crushed T2 on the left hand permanently removes the
  flamethrower — a visible, permanent, crowd-detonating state change mid-boss.
- **Combined-action anchor:** R15 gives combined actions an explicit hype bonus
  (PLACEHOLDER weight) — she is the base of every choreographed merged hit.
- **Camera Call (1 stack — slice default, PLACEHOLDER R14):** best spent as the cameras
  find her mid-Brace or mid-windup — doubling audience gains on the save.

### Arc hook (spine: "how much can we break your essence down in the name of entertainment?")
The show will keep handing her people to save until saving them becomes the act that
breaks her — the first time she rescues someone *for the camera*, what's left of the
rescuer?

---

## Contestant 2 — Dario "Encore" Vekić

### Broadcast persona (the edit)
The heel you pay to boo. Boardwalk sleight-of-hand hustler turned show-off: he works
the crowd mid-fight, steals finishing blows, and **bows after every kill** — the bow is
the bit (`the_bit`), and the boo is the applause. Broadcast handle: **"Encore."** He is
the only contestant who acts like he read the format sheet: the audience is not a
danger, it's a *mark*. Expected tag drift: `scene_stealer`, `prima_donna`, `menace`,
`the_monologue` — heel tags he actively farms.

Per R18: Charm 5 because he is *objectively striking* — sequined jacket over dungeon
armor, stage face, knife-flourishes tuned for the wide shot. Presentability as armor.

### Background (the audition tape)
A three-card-monte and stage-knives act on the boardwalk, right up until he doubled
down with borrowed money one time too many — the debt he calls "the Ledger" belongs to
people who do not forgive. One private rule under all the grift: he never cons the
broke — marks are people who can afford to lose. He treats the abduction as his big
break: an audience that finally can't walk away.

**Structured picks (bidding keywords):** origin *boardwalk card table* · vice *doubles
down* · virtue *never cons the broke* · wants back home *the Ledger burned*.

**Which god archetypes bid, and why (≥2 required):**
1. **Fortune/wealth archetype (roster pass; domains list already includes `fortune` and
   `debt`).** The Plutus pattern is canon precedent (cosmic-casino canon §5: gods who
   buy low on desperate men). A debtor with showman's hands is an undervalued asset;
   this god isn't backing him — it's *acquiring* him.
2. **Carnage/chaos archetype — `enyo` (`data/patron_gods.json` id 2), direct match.**
   Her seeded favor condition "trigger three forced actions in one combat" is his kit's
   natural output — Feint mass-produces Forced Actions. Her taboo "end a fight in under
   one Clock" costs him nothing: he was always going to milk the encore.
3. **Trickster/showman archetype (roster pass — Hermes-grade: thieves, liars, stage
   patter).** Bids for the craft itself; favor conditions would read "win a fight
   without landing the first blow," "make the crowd laugh."

### Race + traits — PLACEHOLDER (R14)
**Human** (`races.json` id 1). Creation-legal 7 Body / 7 Core, max 5:

| Physique | Reflexes | Mind | Charm |
|---|---|---|---|
| 2 — PLACEHOLDER (R14) | 5 — PLACEHOLDER (R14) | 2 — PLACEHOLDER (R14) | 5 — PLACEHOLDER (R14) |

### Skills (3; all real `data/skills.json` entries — no new skills needed)
| Skill (id) | Start Lv — PLACEHOLDER (R14) | How it plays in the slice |
|---|---|---|
| **Feint** (id 26, `feint`) | 3 — **cap 6 via the R16 skill-trade** *(Lv 3 also satisfies Pressure Strike's chain requirement)* | The "made you flinch" button: no damage, target's next action becomes Forced Action — Tool, free 1-space reposition. He points the game's own failure path (the Forced Action d6) at the ENEMY — pratfall comedy as a combat verb. |
| **Pressure Strike** (id 27, `pressure_strike`) | 1 | Chained from Feint at reduced cost: 2 Bleeding to a limb + 2 free spaces of movement; re-applying to the same part advances Bleeding a tier — his engine toward the Tier-2 breach (see pair section). |
| **Dance** (id 33, `dance`) | 2 | 0-Moment declaration; movement generates +1 Charm crowd effect while it holds, and it drops the instant he's hit — showboating with a posted price, the hype meter made legible. |

*Gear note: 2× `kunai` (items id 23 — the dev-chat kunai stays canon comedy) as his
stage knives; `fedora_hat` (id 5) optional costume seed.*

### Camera-call / hype angle
- **Crowd-work as mechanics:** Dance ties his movement economy directly to Charm-read
  crowd reactions — when Encore is dancing, the hype meter visibly breathes with him.
- **Failure-path spectacle:** every Feint that lands turns an enemy action into a d6
  pratfall — he generates *other people's* blooper reel, the cheapest reliable
  spectacle events in the sim.
- **The bow:** kill → bow is his authored spectacle beat and Goal bait (Performance:
  "Act Stylish" / "Do the Bit"); interrupting the bow is the risk the crowd tunes in for.
- **Camera Call (1 stack — slice default, PLACEHOLDER R14) as a gamble:** Camera Call
  doubles gains AND losses — Encore calling the camera before a stunt is his
  doubling-down vice expressed mechanically. When it works: all-kill. When it doesn't:
  doubled, televised, deserved.

### Arc hook (spine)
The act was supposed to be armor — "they can't break what's fake" — but the show keeps
cutting to the frames where the mask slips, because the audience loves him most at
exactly the moments he can't stand being seen.

---

## How the pair covers the slice together

**The two breach paths ARE the two characters.** Incinedile Phase 1's discoverable win
condition (surface immunity until breach) has two authored doors, and each premade is
the key to one:

| Slice system | Imani ("The Door") | Dario ("Encore") |
|---|---|---|
| **Breach A — Bleeding T2 on a part** | — | Feint → Pressure Strike applies Bleeding, re-application advances the tier; his "why is nothing working" cosmetic-damage phase ends when a Tier-2 wound exposes the mycelium — the discovery beat belongs to his kit |
| **Breach B — 7+ damage in a single hit** | Strong Strike's windup is the raw-force half; solo numbers likely can't reach 7 (PLACEHOLDER R14) *by design* | The assist: R15 combined actions **merge linked same-tick hits into one hit for thresholds** — the pair discovering "swing together" is the designed 7+ breach, and it earns R15's choreography hype bonus |
| **Flamethrower disable (Crushed T2, left hand)** | Overhead Slam advances Crushed on the hand — the permanent mid-fight state change | Feint herds/holds the boss's attention so she gets the slam window |
| **Fire Heals (the trap rule)** | The diegetic hint carrier: a firefighter reads fuel — she's the character who says "stop feeding it" when burning trash cans heal the boss | His showboating near burning trash cans is how the party *finds out* fire heals it (the announcer plane milks the irony) |
| **Death Spin grab (5 damage to the hand releases)** | Her hits free a grabbed partner — co-dependence in both directions | Grabbed Encore is the crowd's favorite jeopardy |
| **Flamethrower cone / Dash pressure** | Brace + body-block: she reduces and absorbs | Dance + chain movement: he simply isn't there |
| **Clock literacy (R2's core lesson)** | Teaches windups: slow, Exposed, dodgeable — from the dealing side | Teaches instants: 0–1 Moment actions, free-move economy — the un-dodgeable side |
| **Hype meter** | Slow-build spectacle: held-breath windups, saves, the disable clip | Fast-twitch spectacle: crowd-work, forced-action pratfalls, the bow |
| **Audience read (contrast)** | `fan_favorite` / `protagonist` — the crowd loves her *despite* her ignoring them | `scene_stealer` / `menace` heel — the crowd loves booing him *because* he begs them to |
| **Verdict axes (spine instrumentation)** | Safety-vs-justice, necessary-vs-right — the rescuer axis | Label-vs-essence — the tag/essence tension made playable |

**On-camera relationship (the duo edit):** she keeps dragging him out of fires he
grandstands in; he keeps stealing her saves and bowing. The production cuts them as a
double act — *The Door & The Encore* — and neither can stand it, which is why it rates.

**Party-of-3 note:** Incinedile P1 is balanced for a party of 3 (story-canon slice
shape). Under the Q68 roster, whichever premade the player picks fills the OC slot
beside Sasha & Nikita; the breach-coverage analysis above degrades gracefully — Breach A
also reachable via Sasha's claws, Breach B via any R15 merged hit.

---

## Open questions for the owner

1. **Roster shape:** confirm the reconciliation — are these two the *default-build
   options for the OC slot* (Q68 shape: pick one, + Sasha & Nikita), the review-4 §5
   *two-hander* (player controls both, pre-recruitment build), or both in sequence as
   proposed? If pick-one: does the unpicked premade exist in the slice's world (rival
   contestant on the broadcast?) or simply not appear?
2. **Names/identities approval:** Imani "The Door" Brandt and Dario "Encore" Vekić —
   approve, rename, or redirect. Both are fully original (no player-character DNA);
   surface details are freely changeable, per the IP ruling's protected-asset logic.
3. **The 4-skill trade framing:** both premades use R16's trade rule (4th background
   skill → +1 cap) to land on exactly 3 skills. Keep — or should slice premades carry
   all 4 background skills? (If 4: proposed 4th picks would be `read_the_pattern`
   (id 6) for Imani and `juggling` (id 32) for Dario.)
4. **Starting skill levels:** premades starting above Lv 1 (Feint 3 to satisfy the
   chain requirement; others 1–2) — acceptable authoring, or should chain requirements
   get a slice-tuned pass instead? (All levels PLACEHOLDER R14 regardless.)
5. **Camera Call stacks in the slice:** Charm /20 grants zero stacks at creation-scale
   numbers; proposal gives each premade 1 stack as a slice default so the button (review-4
   §5) is usable. Confirm the override and its diegetic framing.
6. **Patron bidding in the slice:** is the deal-sheet/bidding screen IN the slice
   (patron-gods builds in KAN-7 — presumably not), or do the premades ship with a
   pre-signed patron each (proposal: Imani–Hestia, Dario–Enyo) as a static flavor line
   the announcer references? Or no patron surface in the slice at all?
7. **Human-only premades:** both are Human because animal part layouts are deferred
   (Q61). Acceptable for the slice, or does the owner want one animal premade badly
   enough to pull the part-layout sitting forward?
8. **Forge/fire god and fortune/trickster gods** cited in the bidding sections don't
   exist in `patron_gods.json` yet (only ares/enyo/hestia stubs do). Fine as archetype
   references for now, or should the roster pass stub them when this proposal is
   approved?
