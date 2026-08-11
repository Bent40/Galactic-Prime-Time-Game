# Floors 4–6 — The Crowned (proposal)

**Status:** ⟨PROPOSAL⟩ — owner's shape, my assessment and additions. Nothing here is ruled.
**Owner's brief (2026-08-10):** *faction wars worldwide · control and large-scale fighting ·
kingdom-based · champions build alliances and empires and conquer rival kingdoms · relic
pieces gate the stairs · F4 establish your kingdom and make your relic part · F5 explore
rival kingdoms and their dungeons for pieces · F6 conquer, take their relics, X relics
opens the passage · citizens and alliances carry over from the previous set.*

---

## 1. Assessment — what's already right

| | Why it works |
|---|---|
| **It matches the compendium's F4–6** | `../GPT_Master_Compendium.md:268` already has floors 4–6 as the **continent merge**, players consolidated as competition narrows. Kingdom war *is* the continent merge |
| **The scale escalates correctly** | The compendium's rule is each floor grows geographically — city → country → continent. F1–3 was one buried god under one capital; empires are the right next rung |
| **The gate is countable** | "X relics opens the passage" is legible at a table and trivially implementable in the sim |
| **Carry-over is canon** | *"unlocks are path-dependent"* (`../story-canon.md:72-73`). This is the **first concrete instance** of the convergence matrix, which is the largest unwritten artifact in the project (I-20) |

---

## 2. The thing it's missing — the war IS the economy

The proposal reads as a good 4X layer. Under the rules already ruled, it can be something
almost nobody else can do.

> **Under Q-14, divinity is named, living beings who revere you. A kingdom is a population.**
>
> **So conquering a kingdom is not taking territory. It is taking a congregation.**

That single sentence reframes the whole set at no design cost:

- Every citizen under your rule is **potential divinity** — but only if they revere **you**.
  Q-64 already established the trap: Vermilia rules a capital and is **poor**, because the
  city worships a name that isn't hers. **An empire can be enormous and worthless.**
- **Q-63's running thread is the same mechanic, inverted.** Hunting Beelzebub's believers
  is *subtraction* from a god's ledger. Kingdom-building is *addition* to yours. F4–6 is
  the same system pointed the other way, so the set needs no new economy — it needs the
  existing one at scale.
- Conquest now has a **cost the players can feel**: a conquered population that fears you
  is not a congregation. Slaughter your way through and you inherit an empty ledger.

**This is what stops F4–6 being a strategy minigame bolted onto a dungeon crawler.**

---

## 3. The set's question is already chosen for it

Canon lists the question shapes at `../story-canon.md:69-71`: *necessary vs right · safety
vs justice · **power for yourself vs power for many***.

**The third one is this set, exactly.** And **Q-53 makes it mechanical rather than moral
flavour**:

> Stability flowing down the vassalage is a **grant, not a pipe** — the god chooses whether
> to route it.

So as a champion accumulating reverence from a growing empire, you make one recurring
decision, every floor:

```
   Your citizens revere you  ──▶  divinity accrues to YOU
                                        │
                        ┌───────────────┴───────────────┐
                  HOARD IT                        ROUTE IT DOWN
          power for yourself                   power for many
          you grow fast                        they prosper, stay,
          they weaken, starve,                 and keep revering you
          and eventually stop                  you grow slower
          naming you                           and hold what you built
```

**The floor-set's question, the verdict axis, and the resource loop are the same action.**
That is what F1–3 achieved with the pray-or-ransack choice, at empire scale, and it uses a
rule the owner already ruled for a different reason entirely.

---

## 4. The weakest part, and the fix

**"Collect X relic pieces to open the door" is a lock, not a question.** It is the one part
of the brief that doesn't carry the set's meaning.

**The fix is already in the system: Q-33.** Every floor-set hides its god's **myth-source**.
Apply that at kingdom scale:

> **Each kingdom's relic IS its god's myth-source.**
>
> Taking it does to that god exactly what **Beelzebub did to Cinnabrus** — silences them,
> forecloses them, ends their ability to be named.

Which produces the best thing in this proposal:

> **F4–6 asks the party to commit Beelzebub's crime, six times, to advance — immediately
> after F1–3 spent three floors teaching them what it costs.**

They will *know*. And they can look for another way: negotiate for a relic, restore a
bankrupt god in exchange for it, or take it and live with having become the thing they
buried. That converts a fetch quest into the set's moral engine, with no new machinery.

**It also explains why the relics grant buffs** — you are wearing another god's voice.

---

## 5. The set needs its own bankrupt god (§11.2 requires one)

Every 3-floor set has one bankrupt runner working off a debt to the house (Q-29). F1–3 has
Cinnabrus. F4–6 needs one, and F1–3 established the pattern to follow:

> **The floor's host is a cautionary answer to the floor's question.**
> Cinnabrus asks *"will you cure what's corrupted, and at what cost?"* — and he is the god
> who cured too eagerly, killed everyone, and lost everything.

So F4–6's host should be **a sovereignty god who answered "power for yourself" and was
proved right, then bankrupt**:

⟨PROPOSAL⟩ A god of crowns whose empire was the largest ever worshipped — who **hoarded**,
never routed stability down, watched his people starve, and was **stopped being named** one
province at a time. He did not fall to a rival. **His congregation simply stopped.** He now
runs a floor where champions build empires, watching to see whether anyone does it better,
and taking a cut either way.

His myth-source would be the **crown** — and it is the one relic in the set that no kingdom
holds, because it is his own, and the house took it against the debt.

---

## 6. Carry-over from F1–3 — concrete, and it forks hard

Q-57 already ruled the mechanism. This is what it means at the start of F4:

| F1–3 outcome | What you bring into F4 |
|---|---|
| **Revived Cinnabrus** | Vermilia and her demon soldiers as a **standing army**; the capital as a Lounge-attached base; Cinnabrus as a vassal god (whose divinity flows up to you — Q-52); the war on Beelzebub's believers already running (Q-63) |
| **Ransacked the grave** | **No army.** Every demon in the world hostile. You start F4 with plague-speech, a hostile continent, and no allies — a genuinely harder, lonelier campaign |
| **Never found the tongue** | Neither. You arrive at F4 as a stranger with no faction — the "clean" start, and the poorest one |

**That is three materially different openings to the same floor**, driven by one earlier
choice, which is exactly what path-dependent unlocks were supposed to deliver.

---

## 7. Risks

| Risk | Mitigation |
|---|---|
| **Scope — kingdom management is a second game.** In a TTRPG it's GM narration; in the Godot sim it's a 4X system, and KAN-2 (combat) isn't finished | Keep a kingdom to **four tracked numbers**: reverent population, army, relics held, alliances. No builder, no tile map. The dungeon crawl stays the game |
| **Rival champions need definition** | Make them **NPC champions with their own patron gods** — it makes the patron system visible from the outside for the first time, and every rival kingdom comes with a god who has money on it |
| **F5 "explore other kingdoms' dungeons" could become filler** | Tie each dungeon to its kingdom's god and relic (§4). Then exploration is reconnaissance on a *person*, not a level |
| **Six floors of war may crowd out the show** | The broadcast is the frame — Camera Call, Directives and the audience still run. An empire is *better* television than a dungeon; lean on it |

---

## 8. Open questions

| # | Question |
|---|---|
| **F-01** | Adopt "conquest = taking a congregation" as the set's spine? (§2) |
| **F-02** | Confirm **power for yourself vs power for many** as the set's question, with Q-53's hoard-or-route as its mechanic? (§3) |
| **F-03** | Adopt "each kingdom's relic is its god's myth-source", so taking it repeats Beelzebub's crime? (§4) |
| **F-04** | Approve the **god of crowns** as the F4–6 bankrupt runner, and the crown as the missing relic? (§5) |
| **F-05** | Are rival kingdom-builders **NPC champions with their own patrons**? (§7) |
| **F-06** | How deep does kingdom management go — four numbers, or more? (§7) |
| **F-07** | How many relics does the passage require, and out of how many kingdoms? |
| **F-08** | Does the **Loong** survive into F4–6, and does Vermilia's war on Beelzebub start here or at F7? |
