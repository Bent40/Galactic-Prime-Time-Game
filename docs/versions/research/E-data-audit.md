# E — Live campaign content audit: how much authored content is v1-locked

**Date:** 2026-08-10 · **Scope:** every authored record in the live campaign's data
stores (char-sheet Mongo exports + `server/seeds/` batches) plus the game repo's ports,
plus the app's own UI chrome. **461 records classified, 0 sampled.**
**Read-only pass** — nothing in either repo was edited.

> ## ⚠️ Read this before the numbers — what "needs work" means under D-V2
>
> **Owner ruling D-V2 (2026-08-10, this session): v1 is FROZEN; v2 bends.** The live
> TTRPG campaign does **not** re-skin. `gpt-system-v1.0.md` stays the v1 master; v2 needs
> its own artifact (delta layer or forked book). Every FORK resolves one way only: **v1
> keeps its form, v2 authors a new one.**
>
> **Therefore this document is a v2 BUILD BUDGET, not a migration plan.** Read every
> column labelled *"% needing work"* as **"% of records v2 must author differently"**, and
> every *"proposed v2 form"* as **what the v2 catalog would carry** — never as an edit to
> a live file. **Nothing here proposes touching the live campaign.** (D-V2 §2 explicitly
> forbids renaming Camera Call / Directives / Viewers *in v1*.)
>
> D-V2 supersedes `setting-rebrand-options.md:155-156` ("RULED: RE-SKIN TO CASINO") in
> favour of `ttrpg-update-plan.md:6-9`. The whole "cost of re-voicing the live app and
> rulebook" question is therefore **moot** — that cost is now **zero**, because nothing
> live changes. What remains is: *how much of the live content can v2 copy for free?*
>
> **The answer: 449 of 461 records (97.4%) copy verbatim.** The v2-authoring surface is
> **12 records** plus the rulebook's v1-power prose (21 lines, 11 sections) — which under
> D-V2 is not an edit list but the **minimum delta surface a v2 rules artifact must
> cover**.

> **Why so little is v1-locked (the mechanism).** The v2 frame does **not** delete the
> broadcast. `setting-rebrand-options.md:113–119` (RULED 2026-07-16) makes GPT a **VIP
> table whose in-fiction skin is a human reality show** — *"Every broadcast mechanic
> (announcer, tags, camera calls, ratings) survives untouched — the DCC separation comes
> from who runs it and why."* `docs/design/patron-gods.md:79` confirms the vocabulary:
> *"Viewers/Followers stay the mortal-ish crowd; the **Patrons** tier = donator gods."*
> Only **the Corporation / alien-abduction POWER** is dead canon in v2 (DIRECTION.md D3,
> `campaign-residuals-audit.md:483`). So v2 inherits nearly the whole catalog.

---

## Headline numbers

**FRAME-A** = the ruled frame (broadcast survives; only the Corporation/alien power forks).
NEUTRAL = **v2 copies the record verbatim, at zero cost.**

| collection | total | NEUTRAL | RESKIN-NAME | RESKIN-TEXT | FORK | % v2 must re-author |
|---|---:|---:|---:|---:|---:|---:|
| Skills — live templates | 44 | 44 | 0 | 0 | 0 | **0.0%** |
| Skills — passover adds (not in export) | 5 | 5 | 0 | 0 | 0 | **0.0%** |
| Items — legacy templates | 28 | 25 | 0 | 3 | 0 | **10.7%** |
| Items — drafted batches (A/B/C/mat-F1) | 128 | 125 | 0 | 3 | 0 | **2.3%** |
| Tags | 100 | 97 | 1 | 2 | 0 | **3.0%** |
| Affixes — live catalog | 27 | 27 | 0 | 0 | 0 | **0.0%** |
| Affixes — Higher tier (proposed) | 15 | 15 | 0 | 0 | 0 | **0.0%** |
| Enemies — statted | 3 | 2 | 0 | 1 | 0 | **33.3%** |
| Messages | 49 | 48 | 0 | 0 | 1 | **2.0%** |
| Characters — identity | 5 | 5 | 0 | 0 | 0 | **0.0%** |
| Characters — background | 5 | 5 | 0 | 0 | 0 | **0.0%** |
| Characters — notes | 4 | 3 | 0 | 0 | 1 | **25.0%** |
| Characters — achievements | 33 | 33 | 0 | 0 | 0 | **0.0%** |
| Characters — objectives | 12 | 12 | 0 | 0 | 0 | **0.0%** |
| Characters — tag instances | 3 | 3 | 0 | 0 | 0 | **0.0%** |
| **TOTAL** | **461** | **449** | **1** | **9** | **2** | **2.6%** |

**FRAME-B** = the *un-ruled alternative* buried in `setting-rebrand-options.md:30–42`'s
mapping table, where the audience-economy nouns also get divine names (Viewers →
spectator gods, Followers → devotees, Camera Call → the odds board). This is the real
cost fork and **the owner has not decided it** — the mapping table and the 2026-07-16
update say different things.

| | records touched | % of 461 |
|---|---:|---:|
| Frame-A (ruled): Corporation/alien only | **12** | **2.6%** |
| Frame-B additional (audience nouns renamed) | **+89** | +19.3% |
| **Frame-B total** | **101** | **21.9%** |

Frame-B's 89 is a mechanical keyword count and carries an eyeballed **~10% false-positive
rate** (verified cases: `Grapnel Rig` "fire-and-**reel**", affix `Penetrating` contains
"**rating**", affix `Spiked`, skill `Swim` "in a single **scene**"). Corrected estimate:
**~80 genuinely audience-voiced records** — label this ESTIMATE.

---

## Method

Every number above comes from one of these commands. `jq` and `python3` are both present.

```bash
# record counts
jq 'length' /home/user/Galactic-Prime-Time/galactic-prime-time.{skilltemplates,itemtemplates,messages,characters,users}.json
node -e 'for (const f of ["items-batch-a.js","items-batch-b.js","items-batch-c.js",
  "items-batch-d-repairs.js","items-materials-f1.js","affixes-higher.js"])
  console.log(f, require("./"+f).length)'      # from server/seeds/
python3 -c "import json; [print(f, len(json.load(open(f)))) for f in
  ['tags.json','modifiers.json','enemies.json','items.json','skills.json']]"  # from GAME data/

# the classifier (writes classified.json; every override carries its reason)
python3 /tmp/.../scratchpad/v2-research/classify.py
```

**Classification rules** (mutually exclusive; heaviest class wins
FORK > RESKIN-TEXT > RESKIN-NAME > NEUTRAL). Under D-V2 each class states what **v2**
does; **v1 is untouched in all four cases**:

- **FORK** — the record's premise only works in v1; v2 authors a genuinely different record.
- **RESKIN-TEXT** — description/flavour names v1-specific fiction, **or** uses the
  retail-corporate register the casino replaces (the items-audit's own RE-VOICE bar).
  v2 copies the mechanics and writes new copy.
- **RESKIN-NAME** — only the name is v1-coded; v2 copies the behaviour text verbatim
  under a new name.
- **NEUTRAL** — v2 copies the record unchanged. **Includes all broadcast/TV/crowd/
  Viewer/Camera-Call language**, per the ruling quoted at the top.

**Band-C regex** (the dead power): `corporat|myceli|mycilius|\balien\b|abduct|the company\b`
**Band-B regex** (broadcast furniture, Frame-B only): `\bviewer|\bfollower|camera|\bcrowd|audience|face screen|\bspike|\bshow\b|spotlight|\bhype\b|broadcast|\bfans?\b|gallery|odds board|circus|viral|popular|\bscene\b|\bactor|\bstage\b|episode|\bseason\b|ratings?\b|\bdirector\b|\bscreen|\breel\b|\bfilm|\bchannel\b|\bpop\b`

**Data-freshness caveat (honesty line).** The JSON exports in
`/home/user/Galactic-Prime-Time/` are dated 2026-08-04 and **do not contain the 5 skills
the 2026-07-25 passover added** (`Intercept`, `Death Grip Jaws`, `Field Triage`,
`Iron Stance`, `Play to the Camera` — verified: `jq -r '.[].name' …skilltemplates.json`
returns 44 names, none of them these). CLAUDE.md notes the campaign DB lives with the
`ClaudeCodeTest` checkout and this repo's copy is "a sparse dev copy". I audited the 5
directly from `server/apply-skill-passover.js` and listed them as a separate row. **The
live DB may hold a few more records than 461** — the percentages are robust, the absolute
totals are a floor.

---

## Per-collection findings

### Skills (n=44 live + 5 passover adds = 49)

**FRAME-A: 0 records need any work. 100% NEUTRAL.** Zero hits for
`corporat|alien|abduct` across every field of all 44
(`grep`-equivalent verified in `classify.py`; also confirmed independently — the scan
over `name+description+effect+achievementUnlock+requirements+target+range+levelEffects`
returned `skills with corp/alien language: 0`).

Six records touch the audience economy (Frame-B only):

| skill | class (A) | why | proposed v2 form |
|---|---|---|---|
| Controlled Sweep | NEUTRAL | pure combat | — |
| Strong Strike | NEUTRAL | "The crowd holds its breath" — crowd survives | — (Frame-B: "the gallery holds its breath") |
| Decapitate | NEUTRAL | "Cinematic Kill — gain 1 **Viewer spike**" | — (Frame-B: "1 odds spike") |
| Heroic Punch | NEUTRAL | "cosmetic crowd effect… POW graphic… **Viewer spike** on a Head hit" | — (Frame-B: same noun swap) |
| Generate Visual Media | NEUTRAL | densest broadcast skill: **Face Screen**, images, "Viewer spike at GM discretion" | — (Frame-B: Face Screen → the contestant's odds-board panel) |
| Dance | NEUTRAL | "Every step is a sentence. **The crowd is reading**." | — |
| Swim | NEUTRAL | FALSE POSITIVE — matched "in a single **scene**" | — |
| Play to the Camera *(passover add)* | NEUTRAL | "spend a **Camera Call** stack… the camera pans across the team" | — (Frame-B: the only skill whose *name* would change) |
| Ignore All Previous Commands | NEUTRAL *(v1-clean)* | LLM-prompt joke; not v1 fiction — but see note | — |
| Telepathy / Telekinesis / Mind Burst | NEUTRAL | psychic kit, setting-agnostic | — |
| Poison/Frost/Fire Ball + Wall, Elemental Confluence | NEUTRAL | elemental kit, setting-agnostic | — |
| Pounce → Slip Through → Decapitate (chain) | NEUTRAL | pure combat chain | — |
| Lockpicking / Acrobatics / Nightlurking / Camouflage | NEUTRAL | utility kit | — |
| Voicebox / Vibe Control / Aura Reading / Juggling | NEUTRAL | social/utility kit | — |

**Notes.**
1. `skills-audit.md:190-196` already audited all 44 on *mechanical* grounds
   (KEEP-AS-IS 5 · FIX 34 · REWORK 3 · OWNER-CALL 2 · **CUT 0**) and issued **no setting
   verdict at all** — because there was nothing to issue. My pass confirms that from the
   other direction: the setting cost of the skill catalog is **zero**.
2. Adjacent, already-ruled, *not* a v1→v2 cost: `Generate Visual Media` and
   `Ignore All Previous Commands` are R16 robot-orphans tied to XQUEZ/T, which
   `campaign-residuals-audit.md:485-487` rules dead canon for the **game** on IP grounds.
   That is a different axis and belongs to whoever owns the IP slice.

### Items (n=28 legacy + 128 drafted = 156)

**FRAME-A: 6 records (3.8%) need work.** Zero FORKs.

| item | src | class | why | proposed v2 form |
|---|---|---|---|---|
| Generic Outfit Coupon | legacy | **RESKIN-TEXT** | "Coupon" is retail-corporate register; the casino *comps*, it doesn't issue coupons | **Wardrobe Comp** — copy already written at `items-audit.md:54` |
| Silver Modifier Coupon | legacy | **RESKIN-TEXT** | same, + a tier-word collision (Silver=box tier vs Lesser=affix tier) | **Altar Marker — Lesser** (`items-audit.md:55`) |
| Basic Weapon Coupon | legacy | **RESKIN-TEXT** | same retail register | **Forge Marker — Basic** (`items-audit.md:75`) |
| Bandage | batch-a | **RESKIN-TEXT** | *"**Corporation-brand** gauze. Smells like victory and antiseptic."* — the only literal Corporation string in 156 item records | *"House-brand gauze."* — one word |
| Mycelium Core | batch-a | **RESKIN-TEXT** | MYCELIUM CLUSTER (see below) — owner ruling, not a rewrite | unchanged if the mycelium theme is kept |
| Mycelium-Threaded Hide | mat-F1 | **RESKIN-TEXT** | MYCELIUM CLUSTER — F1 boss-carve material | unchanged if the mycelium theme is kept |
| Duct-Tape Machete | batch-a | NEUTRAL *(borderline)* | *"**Sponsor logo** on the grip"* — sponsors survive; under the casino a sponsor **is** a patron god | none; arguably *strengthened* by v2 |
| Show-Brand Buckler | batch-a | NEUTRAL | the show survives diegetically | — (Frame-B: "House-Brand Buckler") |
| Personal Camera Drone | batch-b | NEUTRAL | *"Your own camera: +1 Exposure gain"* | — (Frame-B only) |
| Fan Mail | batch-c | NEUTRAL | *"Read the crowd at will… the audience issues a Goal you wrote"* | — (Frame-B only) |
| The Body Double | batch-c | NEUTRAL | *"The crowd saw it live. It trended."* | — (Frame-B only) |
| Patron's Favor Ring | batch-c | NEUTRAL | *"A patron's thumb on the scale"* — **already v2-native** | none; this is the v2 voice already |
| Fedora Hat | legacy | NEUTRAL | campaign provenance ("killing Big Brother Roach"), not v1 fiction | — |
| Pointed Clown Hat / Ruffled Clown Collar | legacy | NEUTRAL | *"entertain the mindless mass"* — `items-audit.md:56` explicitly rules this "reads fine under the casino gallery" | — |
| Bag Of Trail Mix | legacy | NEUTRAL | the `™` joke is human-brand skin, diegetic under the VIP-table premise (`items-audit.md:68`) | — |
| Beachy / Middle Brother's Doll | legacy | NEUTRAL | campaign memorabilia, setting-agnostic | — |

**Note.** The three coupon rows are the *only* rows the existing `items-audit.md` marked
RE-VOICE (28 items → KEEP-AS-IS 5 · FIX 19 · REWORK 1 · **RE-VOICE 3** · CUT 0,
`items-audit.md:186-194`). That audit **predates the 128 drafted batch records**
(blessed 2026-08-04), so the Bandage and mycelium findings are new here.

### Tags (n=100)

Source of truth is the char-sheet DB, seeded from the rulebook's Tag Compendium
(`server/seedTagDescriptions.js` parses `rulebook/gpt-system-v1.0.md` §18.3). I audited
the game repo's port, `data/tags.json`, which is the same 100 rows with descriptions filled.

**FRAME-A: 3 records (3.0%).**

| tag | class | why | proposed v2 form |
|---|---|---|---|
| Corporate Asset | **RESKIN-NAME** | names the dead power; behaviour ("Complete a **Directive** without deviation") survives verbatim | **House Asset** — already applied in the v2 port (`data/tags.json:129` carries `[renamed from corporate_asset — owner 2026-07-17]`); the live char-sheet DB still says `Corporate Asset`, which under D-V2 is **correct and stays that way** |
| Antagonist | **RESKIN-TEXT** | *"position yourself against the interests of an ally, an NPC, or **the Corporation**"* (`data/tags.json:163`) | swap the noun → "the house" |
| Crowd's Baby | **RESKIN-TEXT** | *"loud enough that **the Corporation** has to acknowledge it"* (`data/tags.json:472`) | swap the noun → "the house" |
| Fan Favorite | NEUTRAL | *"Take a bow, little actor! Receive an unsolicited positive crowd reaction"* | — (Frame-B) |
| Fourth Wall | NEUTRAL | *"Address the audience directly, in-character"* — two-information-planes hook | — |
| Director's Cut | NEUTRAL | *"Redo a failed action in the same scene… The crowd…"* | — |
| Scene Stealer | NEUTRAL | *"Redirect the crowd's attention"* | — |
| Fan Service | NEUTRAL | *"This one's for the **viewers** at home"* | — (Frame-B) |
| All-Kill | NEUTRAL | *"In a single Clock, generate a **Viewer** spike…"* | — (Frame-B) |
| Technical Difficulties | NEUTRAL | *"Two different failures. Same moment. Live **broadcast**."* | — |
| Blooper Reel | NEUTRAL | *"Fail at least three times in sequence in the same scene"* | — |
| Not My Job | NEUTRAL | *"Refuse a **Directive** on stated principle"* — Directives survive as the dealer speaking | — |
| Post-Credits Scene / Comeback Stage / Off Script | NEUTRAL | show-native, survives | — |
| Documentary / Anime / Gorefest / Munchkin (+83 more) | NEUTRAL | crowd slang / generic | — |

**41 of 100 tags carry broadcast language** (Frame-B exposure), of which ~4 are
false positives (`Gorefest` matched "**Pop** goes", `Blue Screen` matched "**screen**"
in a BSOD joke, `Main Vocalist`/`Knock It Off The Table` matched generic "**scene**").
**~37 genuinely broadcast-voiced** — ESTIMATE from manual review of all 41.

**Do not conflate with the residuals audit's tag verdicts.**
`campaign-residuals-audit.md:36` issued **KEEP 79 · RENAME 9 · MIGRATE-TO-EPITHET 5 ·
CUT 7** — but only **1** of those 21 non-KEEP verdicts (`Corporate Asset`) is a v1→v2
setting cost. The other 20 are **TVTropes / real-world-IP / epithet-track** debt
(`LEEROY JENKINS`, `Animal Planet`, `Bolivian Army Ending`, `Little Dead Rising Hood`…),
which is owed in v1 too. Charging them to the v2 build would triple the estimate
dishonestly.

### Affixes (n=27 live + 15 proposed Higher tier = 42)

**FRAME-A: 0 records. 0.0%.** The live catalog is the game repo's `data/modifiers.json`
(27 rows — the char-sheet DB's `affixes` collection is not exported to this checkout;
`server/repair-affixes.js` and `server/seeds/affixes-higher.js` are the only on-disk
affix sources).

`items-audit.md:116` reached the same conclusion independently:
> *"**Modifiers: KEEP-AS-IS 12 · FIX 14 · REWORK 1 · CUT 0 · RE-VOICE 0** — no modifier
> has any flavor copy to re-voice: `description` is repurposed as an applicability field
> ('Applicable to: X') and no casino voice exists anywhere in the file."*

| affix | class | why |
|---|---|---|
| Serrated / Serrated II / Weighted / Weighted II | NEUTRAL | pure stat riders |
| Chilling / Burning / Poisoned / Venomous / Infectious | NEUTRAL | condition riders |
| Grip Wrap / Sure Grip / Balanced / Steady / Reactive | NEUTRAL | handling riders |
| Extended / Reaching / Returning / Swift / Lightweight | NEUTRAL | range/tempo riders |
| Spiked / Sundering / Volatile / Draining / Penetrating | NEUTRAL | `Spiked`+`Penetrating` are Frame-B **false positives** ("Spike", "**rating**") |
| Sharpened / Sharpened II / Barbed | NEUTRAL | — |
| Serrated III / Weighted III / Searing / Rending / Thornguard / Concussive (+9) | NEUTRAL | Higher tier, proposed — same register |

The affix catalog is the single cleanest collection in the project: **zero flavour text
exists at all**, which is a content gap in every other respect but makes v2's
inheritance of it free.

### Enemies (n=3 statted; ~23 unwritten)

**FRAME-A: 1 of 3 (33.3%)** — the highest per-collection rate, on the smallest collection.

| enemy | class | why | proposed v2 form |
|---|---|---|---|
| Roach-dog | NEUTRAL | tutorial vermin | — |
| Little Brother Roach | NEUTRAL | elite brood-tender; the Brothers arc is campaign story, not v1 cosmology | — |
| **Incinedile** | **RESKIN-TEXT** | **MYCELIUM CLUSTER ANCHOR.** Its premise is *"actually a **mycelium puppet**: a network inside controls the body"* (`data/enemies.json:165`). In v1 the Corporation **is** mycelium — the campaign's shopkeep is **"Mycelius Chrom Production Co"** (`messages.json`, `characters.json` Filipe notes) and the owner's own rebrand complaint names *"a **mycelium-Corporation** with a clear evil motive"* as the thing that is too on the nose (`setting-rebrand-options.md:4-5`) | keep every mechanic (breach paths, 6 phases, fire-heal, network-as-body-part, 50 HP); re-author only the **why**: a fallen-god construct, or a Follower-Relic parasite per casino canon §6 |

> **This contradicts the existing audit and I am flagging it deliberately.**
> `campaign-residuals-audit.md:221` states *"**No Corporation-flavored text exists in
> `enemies.json`** — the anticipated re-voice burden is (pleasantly) zero here."* That is
> true of the literal *word* and false of the *fiction*. The audit grepped for
> "Corporation"; the Corporation's body-horror signature in this campaign is the
> mycelium, and it is present in 5 fields of `enemies.json` (lines 165, 176, 187, 249)
> plus 2 item records. **Confidence: moderate-high** — the mycelium↔Corporation link is
> stated in the owner's own words in `setting-rebrand-options.md`, but no doc says
> explicitly "the mycelium theme is retired". It needs an owner ruling (see Open Questions Q1).

The ~23 missing stat blocks (`campaign-residuals-audit.md:250-274`) are **not a migration
cost** — they are unwritten either way, and get authored in the v2 voice from birth.

### Messages / in-fiction comms (n=49)

**FRAME-A: 1 FORK (2.0%). The collection is worth almost nothing.**

The brief anticipated this would be "rich in v1 voice". It is not. **48 of 49 messages
are out-of-character player↔GM chat** — feature requests, session feedback, test spam,
and Hebrew rules questions. **19 of the 49 are the literal duplicate string
`"achievement for getting to skill lvl 6?"`** (sasha → Ben). Senders:
`sasha 26 · Filipe 9 · Mario Marcus 8 · XQUEZ/T 5 · System 1`
(`jq '[.[].senderName] | group_by(.) …'`).

| message | class | why | proposed v2 form |
|---|---|---|---|
| *"The sign reads **Mycelius Chrom Production Co**"* (System) | **FORK** | the **only in-fiction message in the collection**, and it is the Corporation's brand sign | a house/table sign; no v1 carry-over — write fresh |
| *"did we get extra followers\viewers for beating 2 eliets?"* | NEUTRAL | OOC player question | — (Frame-B noun only) |
| *"i want an achievement and follower update…"* | NEUTRAL | OOC feature request | — |
| *"dogroach - back of head is tough, rest of body squishy"* | NEUTRAL | GM tactical note | — |
| *"crossbow - big brother's spare part (write desc)"* | NEUTRAL | GM TODO | — |
| the other 44 | NEUTRAL | OOC chatter, test spam, Hebrew rules Q&A | — |

**Recommendation: do not port this collection to v2.** Extract the one System line as a
design reference, keep the 4 GM notes as dev notes, drop the rest. (v1 keeps all 49 —
they are its chat history, not content.)

### Characters (n=5 PCs / 62 authored sub-records)

**FRAME-A: 1 FORK (1.6%).** These are **real campaign PCs** — treat destructively at your peril.

Sub-record inventory (`python3` over `state`): 5 identity blobs · 5 backgrounds ·
4 notes · **33 achievements** · 12 objectives (8 main + 4 goals, **0 directives** —
the Directives array is empty on every PC) · 3 tag instances.

| record | class | why | proposed v2 form |
|---|---|---|---|
| Filipe / notes | **FORK** | *"28 march 2026 / shopkeep - **mycilius chrom**"* — the Corporation NPC by name | recast the shopkeep as a house vendor or a Sane Follower trader (casino canon §6) |
| Filipe, sasha, Mario, XQUEZ/T, Frod / backgrounds | NEUTRAL | sea lion from an aquarium; tuxedo cat; hero OC; AI K-pop group; all setting-agnostic | — |
| identity.contestantNumber (#1652, #2,482,123-125) | NEUTRAL | **"contestants" is verbatim casino canon** (`cosmic-casino-canon.md:24`: *"1 to a billion contestants"*) | — |
| Achv "Baby Steps" — *"Get your first 100 viewers"* (×4) | NEUTRAL | Viewers survive | — (Frame-B: "first 100 watchers") |
| Achv "Mr Popular" — *"Reach 5000 Followers!"* (×4) | NEUTRAL | Followers survive | — (Frame-B: "devotees") |
| Achv "Viral" — *"Trigger a Viewer Spike!"* (×4) | NEUTRAL | — | — (Frame-B: "odds spike") |
| Achv "First steps to recognition" — *"Reach 500K Viewers!"* (×4) | NEUTRAL | — | — (Frame-B) |
| Achv "Joined The Circus" — *"at least you're in the show"* (×3) | NEUTRAL | the show survives diegetically | — |
| Achv "Big Shot" — *"Gain more viewers than there were people originally on your system"* (×4) | NEUTRAL | *"your system"* = star system; survives | — (Frame-B) |
| Achv "Early Adopter" / "Animal Planet" / "Unkillable" / "Mascot" / "One Punch Nerd" / "Hit a motherfucker" | NEUTRAL | ("Animal Planet" is the *tag*-side trademark issue, not a setting issue) | — |
| Obj "Clear The Tutorial!" → reward *"unlock The Lounge"* (×4) | NEUTRAL | the Lounge maps to **the comp suite** (`setting-rebrand-options.md:36`) — name may even survive | — |
| Obj "The Brotherly Elites" / "Butcher them!" → *"1 patron coin"* | NEUTRAL | **patron coin is already v2-native vocabulary** | — |
| Tag instances: Mascot, Animal Planet, Unkillable | NEUTRAL | inherit whatever the tag catalog decides | — |

**27 of 33 achievement instances (8 of 14 unique titles) carry audience-economy
language** — 81.8%, the highest Frame-B density anywhere in the project. Under Frame-B
**the achievement ladder is v2's single biggest authoring job**. Under D-V2 this is
strictly cheaper than it looks: these instances live inside **5 live PC documents that
are frozen**, so v2 authors a fresh ladder rather than migrating persisted player data.
Had the freeze not been ruled, this would have been the one place a setting change could
have destroyed earned player progress.

---

## App UI strings

> **D-V2 reframe.** The live char-sheet app is **frozen** — none of these strings changes.
> This table is a **specification input for v2's own UI** (which strings v2 can copy
> verbatim, which it must re-author) and a **completeness check** on the claim that the
> Corporation never reached the chrome. The "proposed v2 form" column describes v2's UI,
> never an edit to `client/src`.

The app's chrome is where v1 voice is *densest per line*. 240 keyword occurrences across
23 files (`grep -rc` over `client/src`). The load-bearing ones:

| string | file:line | class | proposed v2 form |
|---|---|---|---|
| `<title>GALACTIC PRIME TIME</title>` | `client/index.html:7` | NEUTRAL | ruled to survive as the show's in-world name (`setting-rebrand-options.md:158`, Open Decision 5) |
| `'Register Contestant'` / `'Contestant Login'` | `components/shared/LoginOverlay.jsx:44` | NEUTRAL | "contestants" is casino canon |
| `Contestant Identity` (panel title) | `components/character/BodyTab.jsx:121` | NEUTRAL | — |
| `Contestant #` (field label) | `components/character/BodyTab.jsx:163` | NEUTRAL | — |
| `Camera Call` (panel title) | `components/character/ExposureTab.jsx:61` | NEUTRAL (A) / **RESKIN-NAME** (B) | Frame-B: "Odds Board" |
| `Exposure Metrics` (panel title) | `components/character/ExposureTab.jsx:102` | NEUTRAL | — |
| `Viewers` / `Followers` (counter labels) | `components/character/ExposureTab.jsx:106` | NEUTRAL (A) / **RESKIN-NAME** (B) | Frame-B: "Watchers"/"Devotees" |
| `Top Patrons`, `🥇 Top Patron` / `🥈 2nd` / `🥉 3rd` | `ExposureTab.jsx:181, :49` | NEUTRAL | **already v2-native** — patrons *are* the gods |
| `Contribution` (patron amount placeholder) | `ExposureTab.jsx:198` | NEUTRAL | Frame-B nicety: "Stake" |
| `Exposure` (tab label + admin panel title) | `constants.js:6`, `admin/PlayerPanel.jsx:454` | NEUTRAL | — |
| `Followers` / `Viewers` (admin input labels) | `admin/PlayerPanel.jsx:457-458` | NEUTRAL (A) / RESKIN-NAME (B) | — |
| `Set Followers` + placeholder `"e.g. 1.5B, 200.6T"` | `pages/AdminPanel.jsx:134-135` | NEUTRAL | — |
| `LABELS = { main:…, directives: 'Directives', goals: 'Goals' }` | `components/character/ObjectivesTab.jsx:2` | NEUTRAL | Directives survive as **the house/dealer speaking** (`patron-gods.md:80`) |
| `<option value="directives">Directives</option>` | `pages/AdminPanel.jsx:117` | NEUTRAL label / **enum value** — see schema section | — |
| `'📢 Broadcast'`, `'Broadcast message...'` | `character/CommsTab.jsx:97,107`; `admin/CommsSection.jsx:94,102` | NEUTRAL | — |
| `1 Patron Token` / `Raise cap … costs 1 Patron Token` | `character/SkillsTab.jsx:219,222` | NEUTRAL | already v2-native |
| `House rule (§20): boxes only open at the Lounge` | `character/LootBoxes.jsx:163` | NEUTRAL | **already reads casino-native** ("house rule" is a free pun) |
| `SHOW = ['Primetime','Encore','Fan-Favorite','Sweeps-Week','Golden-Hour','Season-Finale','Commercial-Break','Ratings-Spike','Cliffhanger','Cold-Open']` | `admin/BoxBuilder.jsx:29` | NEUTRAL (A) / **RESKIN-TEXT** (B) | 10 words; Frame-B needs a full casino wordlist (Jackpot, Comp, All-In, House-Edge, Last-Call…) |
| `DEED_LEX` TV words: Primetime, Stagecraft, Typecast, Catchphrase, One-Man-Show, Plot-Twist, Swerve | `admin/BoxBuilder.jsx:11-21` | NEUTRAL (A) | — |
| `CONTENT_FLAVOR`: Stagehand, Variety-Hour, Fine-Print, MacGuffin, Wardrobe | `admin/BoxBuilder.jsx:23-27` | NEUTRAL (A) | — |
| CSS classes `.exposure-counters`, `.exp-counter*`, `.patron-*` (10 classes) | `styles/index.css:309-334` | NEUTRAL | cosmetic; rename only if the state keys rename |
| `📖 GPT RULEBOOK v1.0` | `pages/Wiki.jsx:50` | NEUTRAL | version bump only |

**Total UI-string cost: under D-V2, zero — the live app is frozen.** As a v2 spec input:
**Frame-A ≈ 0 strings v2 would write differently. Frame-B ≈ 15 labels + 2 wordlists (~80
words) + 10 CSS classes.** The app's chrome is remarkably v2-portable because the show
survives; the only thing v1 gave it that v2 kills — the Corporation — **never made it
into a single UI string** (`grep -riE "corporat" client/src` → **0 hits**).

**One live-app fact worth carrying forward:** the player-facing Wiki (`pages/Wiki.jsx`)
renders `rulebook/gpt-system-v1.0.md` via a `?raw` import — **one committed copy, no
drift**. That is why D-V2's "v2 needs its own artifact" matters concretely: a v2 delta
layer cannot ride this import without changing what the live table's players read.
**v2 needs a second rules file and a second render target, or an explicitly versioned
route.** That is a v2 build item, not a v1 edit.

---

## Schema-level v1 coupling

The distinction that matters: **a word in a label** is a string edit. **A word that is a
DB key or a CHECK-constrained enum value** is a migration + every read/write site + any
persisted row already carrying it.

> **D-V2 reframe — where the cost actually lands.** With v1 frozen, the **live app's**
> couplings (rows 2–9 below) cost **nothing to change, because they don't change**. They
> matter for exactly one reason: **v2 must not blindly inherit them.** The only row that
> is a real v2 build cost is row 1 — and it sits in the **game repo**, which is v2.

### Enum values and DB keys

| coupling | kind | location | cost |
|---|---|---|---|
| `source_type TEXT NOT NULL DEFAULT 'Patron' CHECK (source_type IN ('Patron', **'Corporate'**, 'Crowd'))` | **SQL CHECK-constrained enum value** — the single most expensive v1 coupling found | `Galactic-Prime-Time-Game/data/migrations/001_initial_schema.sql:212` | **HIGH.** DDL migration (SQLite CHECK requires table rebuild), plus 2 indexes (`:223`), plus every write site. Already on the residuals audit's top-10 (`campaign-residuals-audit.md:328-331` calls it *"the one true **Corporation residue in the data layer**"*; also its top-10 at `:478`). **This is the only place in either repo where v1 fiction is enforced by a constraint.** |
| `state.exposure.{viewers, followers}` | Mongo blob key (v1 app) | `client/src/constants.js:78`; `server/routes/admin.js:92-93, 113-114`; `ExposureTab.jsx:16, 106` | **ZERO (frozen).** Recorded so v2's data layer makes its naming choice deliberately. Had this been a migration: ~8 code sites + 2 REST paths + a backfill over 5 live PC docs. |
| `state.cameraCallUsed` | Mongo blob key (v1 app) | `constants.js:102`; `ExposureTab.jsx:53, 84, 88, 91`; `pages/CharacterSheet.jsx:49` | **ZERO (frozen).** 6 sites if it ever moved. |
| `state.statCapBonuses.cameraCall` | Mongo blob key, rules-derived (v1 app) | `constants.js:72`; CLAUDE.md's Stat Cap Bonuses block; rulebook Charm milestone | **ZERO (frozen).** Note: this key is *rules-derived* — if v2 keeps the Charm/20 → +1 Camera Call milestone under a different noun, v2's own key differs. |
| `state.objectives.directives` | Mongo blob key **+ a route-level string whitelist** (v1 app) | `constants.js:98`; `server/routes/admin.js:185` (`['main','directives','goals'].includes(section)`), `:205`; `ObjectivesTab.jsx:2`; `AdminPanel.jsx:117` (`<option value="directives">`) | **ZERO (frozen).** The `admin.js:185` whitelist is a de-facto enum on a public route — flagged because **v2 should not copy this pattern**; make it a real enum. |
| `PATCH /api/admin/players/:userId/exposure` · `/bulk/followers` | **URL path segments** (v1 public API) | `server/routes/admin.js:80, 108`; called from `AdminPanel.jsx:69`, `PlayerPanel.jsx:161, 169` | **ZERO (frozen).** v1 fiction reached the **public API surface** — the single strongest argument for D-V2's freeze; renaming these would have been the most breakage-prone edit in the project. |
| `state.tokens.patronTokens` | Mongo blob key (v1 app) | `constants.js:84`; `PlayerPanel.jsx:353, 361`; `ExposureTab.jsx:210`; `SkillsTab.jsx:219-222` | **ZERO.** v2-safe anyway — patrons survive verbatim. |
| `state.identity.contestantNumber` | Mongo blob key (v1 app) | `constants.js:45`; `BodyTab.jsx:163-164` | **ZERO.** v2-safe — contestants survive verbatim (`cosmic-casino-canon.md:24`). |
| TAB id `'exposure'` | tab/route id (v1 app) | `constants.js:6`; `CharacterSheet.jsx:119` | **ZERO.** |

### Mere labels

Everything in the UI-strings table whose class is NEUTRAL or RESKIN-NAME: panel titles,
button text, placeholders, the BoxBuilder wordlists, the 10 CSS class names. Under D-V2
none of them is edited; each is simply a string v2 either copies or re-writes.

### The two findings that most change the estimate

1. **The Mongoose layer is 100% v1-clean.** `grep -rniE "camera|viewer|follower|patron|
   directive|corporat|broadcast|contestant|exposure|spike|show" server/models/` returns
   **zero hits across all 11 models**. `Character.js` stores everything as
   `state: { type: mongoose.Schema.Types.Mixed }` — so **none of the v1-named state keys
   above is schema-enforced**. Under D-V2 that is now a *retrospective relief* rather than
   a saving: it means the freeze costs nothing to hold, and it means **v2 is free to pick
   its own key names without inheriting a schema**.
2. **The one genuinely expensive coupling is in the *v2* repo.** The only
   CHECK-constrained v1 enum value in either codebase is `'Corporate'` in the Godot
   project's SQLite schema (`001_initial_schema.sql:212`) — v2's own data layer, carrying
   a v1 noun. It has **no production data yet**. Under D-V2 this is the **single concrete
   schema action item in this whole audit**: change `'Corporate'` → `'House'` now, while
   it is a one-line edit, not after Stage-1 saves exist.

---

## What the existing audits already cover

| audit | what it already settled | what I add |
|---|---|---|
| `docs/audits/items-audit.md` (2026-07-17) | All 28 legacy items + all 27 modifiers, full pass. **RE-VOICE 3** (the coupon family) with replacement copy already written (`:54, :55, :75`). **Modifiers RE-VOICE 0** with the reason (`:116`). Owner already ruled `kunai`'s dev-chat copy KEPT deliberately (`:1-3`). | The **128 drafted batch records** (blessed 2026-08-04, *after* this audit) — finds the Bandage's literal "Corporation-brand" string and the 2 mycelium materials. |
| `docs/audits/skills-audit.md` (2026-07-17) | All 44 skills: KEEP-AS-IS 5 · FIX 34 · REWORK 3 · OWNER-CALL 2 · **CUT 0**. Every finding is mechanical (stat_requirements, growth model, cooldown language). Flags the R16 robot-orphans. | Confirms the **setting** cost is zero, and covers the **5 passover-added skills** the export doesn't contain. |
| `docs/audits/campaign-residuals-audit.md` (2026-07-17) | All 100 tags with verdicts (KEEP 79 · RENAME 9 · MIGRATE-TO-EPITHET 5 · CUT 7); enemies; conditions; skill_thresholds; a compendium dead-canon list (`:481-495`) that names the Corporation first; the `'Corporate'` enum in its top-10 (`:478`). | (a) Separates the **1** genuinely-v1 tag verdict from the **20** IP/TVTropes verdicts, which is what makes the headline 3% and not 21%. (b) **Contradicts** its "0 Corporation text in enemies.json" (`:222`) with the mycelium finding. (c) Covers the **characters and messages collections**, which it explicitly excluded. |

Nothing here re-does those audits' mechanical work; where they already ruled, I cite and move on.

---

## Cost estimate for a full v2 content pass

Sizing: **S** ≤ half a day · **M** = 1–3 days · **L** = a week+.

> **Under D-V2 the v1 side of every line below is ZERO** — nothing in the live campaign
> is edited. These are **v2 authoring costs**: what it takes to stand up a v2 catalog that
> is content-complete against the live one.

### Frame-A (the ruled frame) — v2 build budget: **S**, ~1 day end to end

| collection | size | reasoning |
|---|---|---|
| Skills (49) | **S — zero** | v2 copies all 49 verbatim. No authoring exists. |
| Items — legacy (28) | **S** | v2 carries 25 verbatim + 3 re-voiced rows; the replacement copy is **already written** in `items-audit.md:54,55,75`. Pure transcription. |
| Items — drafted (128) | **S** | 125 verbatim; 1 one-word change (Bandage); 2 gated on the mycelium ruling. |
| Tags (100) | **S** | 97 verbatim; 1 renamed (**already done in the v2 port** — `data/tags.json:129`); 2 noun swaps. v1's `server/seedTags.js:11`, `seedTagEffects.js:34` and rulebook §18.3 **stay as they are**. |
| Affixes (42) | **S — zero** | No flavour text exists to fork. |
| Enemies (3) | **S–M** | v2 re-authors 1 boss's *fiction*, keeping every mechanic. M only if the mycelium theme is retired (then 3 records + the F1 carve table move together). |
| Messages (49) | **S — do not port** | Extract 1 System line + 4 GM notes as dev references; the other 44 are OOC chat with no v2 value. |
| Characters (62) | **S — zero for v2** | These are v1 PCs and stay v1 PCs. v2's contestants are new. The only carry-over item is the shopkeep NPC concept. |
| **v2 rules artifact** | **M — the real cost, and it is a NEW deliverable** | D-V2 §4: *"v2 needs its own artifact — a delta layer or a forked book."* The **minimum delta surface** is the v1 book's own v1-power prose: **21 lines across 11 sections** (`gpt-system-v1.0.md`, verified by section-scan) — premise `:9`, §1 The Show `:25-26`, §2.2 Creation `:69`, §16 `:863`, **§17.5 "Directives (corporate quests)" `:917-925` — the section title itself**, §17.7 `:954`, §18 `:968`, §18.3 Tag Compendium `:1034,1040,1077`, §19.1 `:1130`, §19.3 Retail `:1156-1163`, §20 The Lounge `:1178-1185`. Two sections (§19.3, §20) need genuine re-conception, not word-swaps: *"the Lounge is where the Corporation recoups"* / *"Corporation profits either way"* is a **motive**, and v2's house has a different one. **Delta-layer vs forked-book is itself an open question (Q3).** |
| Schema: `'Corporate'` enum in the v2 repo | **S now / M later** | One CHECK constraint + 2 indexes, no production data yet. |
| v2 UI | **S** | v2 can copy the entire v1 chrome; the Corporation reached **0 UI strings**. Only new build is v2's own rules-render target (the `?raw` Wiki import is v1's). |

**Frame-A v2 build total: S (~1 day of content work), of which the v2 rules artifact is
~70%.** The 449 NEUTRAL records are the reason this is a day and not a month.

### Frame-B (v2 also renames the audience nouns) — v2 build budget: **L**, ~1 week

| collection | size | reasoning |
|---|---|---|
| v2 achievement ladder | **M** | 27 of 33 v1 instances / 8 of 14 unique titles are audience-voiced. **Note the D-V2 relief:** these live in v1 PC documents that are never touched — v2 simply authors its own ladder instead of migrating one. That is the difference between "M" and "M plus a scripted DB migration with a `backup-db.js` run". |
| Tags | **M** | ~37 descriptions re-voiced; each is a joke that has to survive translation |
| v2 UI + wordlists | **M** | ~15 labels + 2 wordlists (~80 words) + 10 CSS classes; v2 picks its own state-key names from scratch (no rename, no backfill) |
| Skills / items / affixes | **S** | ~13 records between them |
| v2 rules artifact | **L** | every Viewer/Follower/Camera-Call mention, plus the whole Exposure chapter's vocabulary |
| **Frame-B v2 total** | **L** | ~8× Frame-A, and **not currently authorized by any ruling** |

**The decision that sets the budget is Q2 below.** Everything else is rounding.

**What D-V2 changed about this estimate.** Before the freeze, the plan would have been a
*migration*: rewrite the rulebook in place, `--force`-reseed the item templates, `updateMany`
the 5 live PC docs, rename 2 REST paths, and re-voice a live app mid-campaign — roughly
**M→L with real breakage risk on a running table**. The freeze converts every one of those
into "v2 writes its own", which is both cheaper and non-destructive. **D-V2 is the single
biggest cost reduction in this audit.**

---

## Open questions for the owner

*Reframed under D-V2 — none of these proposes changing the live campaign.*

1. **Does the mycelium theme survive INTO v2?** Your own rebrand note calls out *"a
   mycelium-Corporation with a clear evil motive"* as too on the nose
   (`setting-rebrand-options.md:4-5`), but the mycelium is also the Incinedile's whole
   discoverable-win-condition design — 6 phases, breach paths, network-as-body-part, all
   play-tested at the live table. v1 keeps it either way. **Ruling needed for v2:**
   (a) v2 keeps the mycelium and drops only the Corporation's *ownership* of it; (b) v2
   retires the theme and re-authors 3 records (Incinedile + Mycelium Core +
   Mycelium-Threaded Hide) plus the shopkeep NPC. **Recommendation: (a)** — a fungal
   puppet-god reads *more* casino-canon than corporate, and (b) costs a play-tested boss
   its identity for no gain. This is the **single highest-leverage ruling in this slice**:
   it moves 3 of the 12 v2-authoring records.

2. **Frame-A or Frame-B — does v2 keep the audience nouns?** The canon says both things.
   `setting-rebrand-options.md:30-42`'s mapping table renames them (Viewers → spectator
   gods, Camera Call → the odds board); the 2026-07-16 update at `:115-116` says *"Every
   broadcast mechanic… survives untouched"* and `patron-gods.md:79` says *"Viewers/
   Followers stay the mortal-ish crowd."* **This one decision is 2.6% vs 21.9% of the
   content, S vs L.** **Recommendation: Frame-A** — the diegetic-show reading is the later
   ruling, it is stronger fiction (gods *built* a reality show because they binge-watched
   us), and it is nearly free. *(D-V2 note: under the freeze this decision now only binds
   v2's own catalog, which makes Frame-B cheaper than it was — no live migration — but
   still 8× Frame-A.)*

3. **v2 rules artifact: delta layer or forked book?** D-V2 §4 names this as a finding to
   put to you and does not decide it. The data says a **delta layer suffices**: the v1
   book's v1-power surface is only **21 lines across 11 sections**, and two of them
   (§19.3 Retail, §20 The Lounge) are the only ones needing re-conception rather than
   noun-swaps. **Recommendation: delta layer** — a forked 1,315-line book creates a
   permanent two-copy drift problem for a 21-line difference. **Caveat that must be
   priced:** the live Wiki renders the v1 book via a `?raw` import (`pages/Wiki.jsx`), so
   a delta layer needs its **own** render target or an explicitly versioned route — v2
   cannot ride v1's.

4. **Does v2 keep the name "The Lounge"?** `setting-rebrand-options.md:36` maps it to
   *"the comp suite"*. It reads casino-native already, and it appears in 4 v1 PC objective
   rewards that are now frozen anyway. **Recommendation: v2 keeps the name and re-voices
   only the §20 motive text** (the *"Corporation recoups"* / *"profits either way"* lines).

5. **Who is v2's Directive-issuer, by name?** `patron-gods.md:80` says *"the house/dealer
   speaks — the fallen god running the table"*, but neither the fallen god nor the house
   has a **name** yet. `objectives.directives` is empty on all 5 v1 PCs, so nothing is
   blocked today — but the v2 delta layer's §17.5 equivalent cannot be written without
   the noun. **This blocks the largest single line of the v2 build budget.**

6. **Should the `messages` collection be preserved at all?** 48/49 rows are OOC chat and
   19 are duplicate spam. **Recommendation: archive it; port nothing.**

7. **Is the `'Corporate'` SQL enum fixed now or at KAN-7?** This is the one schema action
   item and it sits in the **v2** repo, so the freeze does not protect it. ~10 minutes
   today; a real migration once Stage-1 saves exist. **Recommendation: now.**

8. **Which DB is canonical for this audit's numbers?** This checkout's exports lack the 5
   passover skills that CLAUDE.md says were applied 2026-07-25. If the campaign DB (the
   `ClaudeCodeTest` checkout) holds more records, the absolute totals rise — the
   percentages should not.

9. **Should D-V2 be written back into the docs?** The session-decisions file flags that
   D-V2 reverses `setting-rebrand-options.md:155-156`'s *"RULED: RE-SKIN TO CASINO"* in
   favour of the never-approved `ttrpg-update-plan.md:6-9`. From this slice's evidence the
   freeze is clearly the right call — the v1 fiction reached the **public REST API**
   (`/players/:userId/exposure`, `/bulk/followers`) and 5 live mid-campaign PC documents,
   so a live re-skin was the highest-breakage option available. **Recommendation: write
   D-V2 back into `setting-rebrand-options.md:155-156` and mark `ttrpg-update-plan.md`
   APPROVED**, so a future reader cannot resurrect the July-16 ruling.
