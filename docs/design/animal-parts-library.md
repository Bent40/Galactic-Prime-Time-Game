# Animal Parts Library — design research

**Status:** RESEARCH / DRAFT — a premade parts catalog to draw from when animal
contestants and enemies get authored. Sourced by owner request (2026-07-18): "the body
parts unique to animals — tails, pincers, pockets, things like that."

**Feeds:** `docs/rules-addendum.md` **R21 (animal parts)** will be authored *from* this
catalog. Ties into **R20** (stealth/detection — sensory parts set vision cones) and
**R14** (the numbers rework — every HP/lethal figure here is a PLACEHOLDER pending that
pass and the owner's animal-layout sitting).

---

## How to read this catalog (alignment to the sim model)

Grounded in the real part record (`simulation/combatant.gd`) and condition system
(`simulation/condition_engine.gd`), not invented shapes. A body part is:

```
{ key, name, hp, base_max_hp, lethal, disabled, destroyed, hidden }
```

- **Human baseline** (the yardstick every sketch below is calibrated against):
  Head **2 (lethal)**, Torso **5 (lethal)**, each Arm **2 (non-lethal)**, each Leg
  **3 (non-lethal)**.
- **`lethal: true`** → destroying the part kills the combatant (or, for a delayable
  condition — bleeding/poison/infected/burn — starts bleed-out per R5). **`lethal:
  false`** → destroying it only **disables** the part (`part_usable()` returns false).
  So the vital/limb split *is* the small/large-consequence lever.
- **Only the 9 rulebook conditions exist:** bleeding, crushed, suffocation, chilled,
  exhausted, infected, burn, poison, dissolution. "Condition affinities" below is drawn
  strictly from this list — no new conditions are proposed.
- **Two load-bearing engine facts to respect when authoring R21 part keys:**
  1. **"Hands" are detected by substring** — `usable_hands()` / `acting_part()` count
     any part whose **key contains `arm` or `hand`**. A manipulation part that should be
     able to *act* (attack, grapple, hold an item) must key on `arm`/`hand`
     (e.g. `pincer_left_hand`), **or** R21 must generalize the hand test to a
     `can_manipulate` flag. Flagged for the R21 pass — see "How these plug in".
  2. **Some conditions route to a fixed part** (`target_body_parts`): suffocation /
     exhausted / infected → **torso**; dissolution → **head**. If a creature lacks that
     exact key, `_equivalent_part()` remaps (legal list → `torso` → first lethal part →
     first part). **Every animal layout therefore needs a torso-equivalent and a
     head-equivalent** so whole-body conditions have somewhere to land.
- **Grapple (R9/R197):** needs a free hand and a target **no more than one size larger**.
  Any part catalogued as "a second grapple limb" assumes it registers as a hand (fact 1).

All numbers below are **PLACEHOLDER (R14)**. They exist to show *relative* size/lethality
against the human baseline, not to be shipped.

---

## 1. Manipulation

*Parts that let a creature grab, hold, carry, wield, or fine-manipulate — the "arms"
slot's non-human variants.*

### Pincers / chelae
- **Who:** crabs, lobsters, scorpions, some shrimp.
- **Function:** grab + crush; a hand-equivalent that also deals damage on grip. Doubles as
  the creature's melee weapon.
- **HP / lethal:** ~2, **non-lethal** (a limb — losable, like an arm). Larger "crusher"
  claw ~3.
- **Conditions:** *inflicts* **crushed** (its whole point) and can open **bleeding**;
  *vulnerable to* being **chilled** (stiff, slowed grip) and **crushed** itself.
- **Hooks:** a grapple limb that adds crush damage while held → enables a "pin-and-crush"
  loop; counters fragile targets, countered by armor/shell that resists crushed.

### Prehensile tail
- **Who:** spider & howler monkeys, opossums, seahorses, chameleons, some pangolins.
- **Function:** a **fifth manipulator** — anchors, carries, and grips independently of the
  hands. A creature with one effectively has an extra hand for grappling/holding.
- **HP / lethal:** ~3, **non-lethal** (long, exposed limb).
- **Conditions:** *vulnerable to* **bleeding** (long, thin, exposed) and **crushed**;
  *inflicts* nothing directly (grip, not strike).
- **Hooks:** **a second grapple limb** — can grapple while both hands stay free to attack,
  or hold an ally/item mid-combat. One of the richest cheap upgrades in the catalog
  (see standouts).

### Trunk / proboscis
- **Who:** elephants (a boneless muscular hydrostat — ~40,000 muscles, no bone),
  tapirs, elephant seals (display only).
- **Function:** long-reach grab + precise manipulation + a water/dust sprayer; also a
  reach weapon (a strike/shove at range 1–2).
- **HP / lethal:** ~3, **non-lethal**, but a **high-value disable target** — losing it
  costs the creature its manipulation *and* its long-reach attack at once.
- **Conditions:** *vulnerable to* **bleeding**, **crushed**, **burn** (soft, exposed, no
  bone to protect it); *hosts* **poison** readily (soft tissue = easy entry).
- **Hooks:** reach-1-beyond-normal grab/shove; disabling it is a tactical objective
  (strips a boss's grab). No bone → good target for crush/burn setups.

### Tentacles / muscular arms
- **Who:** octopus (8), squid, cuttlefish, jellyfish (stinging), anemones.
- **Function:** **many** independent grippers (suckers) — multi-target grappling, hold +
  strike simultaneously; some carry stingers (see Stinger). An octopus is the extreme
  case of "all arms, no skeleton."
- **HP / lethal:** ~2 each, **non-lethal**; a creature may field 4–8, so it degrades
  gracefully rather than being disabled by one hit.
- **Conditions:** *vulnerable to* **bleeding**, **crushed**; boneless → also **burn** and
  **chilled** (chilled stiffens the hydrostat badly). Stinging tentacles *inflict*
  **poison** on contact.
- **Hooks:** grapple *several* targets at once; redundancy means you must destroy many to
  neutralize it (an attrition target). Pairs with ink sac + chromatophores (see §6) for
  the full cephalopod kit.

### Beak
- **Who:** birds, cephalopods (a hidden hard beak inside soft arms), turtles.
- **Function:** a fixed **head-mounted weapon** — puncture/tear; also fine manipulation
  (preening, shelling). Replaces "unarmed head strike" with a real weapon.
- **HP / lethal:** part of the **head** (lethal) rather than a separate part in most
  layouts — treat as a *weapon property of the head*, not its own HP pool, unless a giant
  raptor beak warrants its own ~2 non-lethal entry.
- **Conditions:** *inflicts* **bleeding** (raptor) or **crushed** (parrot/turtle crushing
  beak); hard keratin → *resists* being **chilled** into uselessness.
- **Hooks:** gives a headshot creature a native ranged-melee attack; a "disarm" tactic
  can't remove it (it's anatomy, not a held weapon).

### Raptor talons / grasping feet
- **Who:** eagles, owls, hawks; also parrots (feet as hands).
- **Function:** feet that double as **weapon + grapple** — seize and puncture. Blurs the
  leg/hand line: locomotion *and* manipulation.
- **HP / lethal:** ~2–3 per foot, **non-lethal**.
- **Conditions:** *inflicts* **bleeding** (piercing) and can **crush** (owl grip
  strength); *vulnerable to* **crushed**.
- **Hooks:** a leg that also grapples — an aerial creature can grab and carry (see Wings);
  disabling one foot cuts both a move option and a grab.

---

## 2. Locomotion

*Parts that determine how a creature moves — the "legs" slot's variants, plus movement
modes the human layout can't do.*

### Wings
- **Who:** birds, bats, insects, pterosaurs.
- **Function:** **flight** — a movement mode (over cover, out of melee reach, vertical
  positioning). Also a gust/buffet attack in big fliers.
- **HP / lethal:** ~3 each (large membrane/feather surface), **non-lethal** — but a
  **prime disable target**: destroy a wing → grounded (loses the flight mode, may fall =
  crushed/prone).
- **Conditions:** *vulnerable to* **bleeding** (membrane tears), **burn** (bat membrane,
  insect wing), **chilled** (insect flight fails when cold — real thermoregulation limit);
  *inflicts* nothing.
- **Hooks:** flight rewrites positioning and R20 vision cones (attack from above/behind);
  the counter is grounding it — a designed "clip the wing" objective. Pairs with talons
  for grab-and-lift.

### Extra legs (more than one pair)
- **Who:** insects (6), arachnids (8), myriapods (dozens), horses/quadrupeds (4).
- **Function:** stability + redundancy — a creature stays mobile after losing legs a biped
  couldn't. Many legs = hard to knock prone, hard to fully immobilize.
- **HP / lethal:** ~2–3 each, **non-lethal**; the point is the *count*.
- **Conditions:** *vulnerable to* **crushed**, **bleeding** per leg; *resists* being made
  **prone**/immobile (needs many disables to matter). **Chilled** slows the whole set.
- **Hooks:** an attrition target — one leg down barely matters; forces AoE or repeated
  hits to slow. Counters single-target "cripple the leg" tactics.

### Fins / flippers
- **Who:** fish, cetaceans, seals/sea lions (the live-campaign example animal), sea
  turtles, penguins.
- **Function:** aquatic propulsion + steering; on land, clumsy (a sea lion "walks" poorly).
  A movement-mode part that's terrain-gated (great in water, penalized on land).
- **HP / lethal:** ~3, **non-lethal**.
- **Conditions:** *vulnerable to* **bleeding**, **crushed**; pairs conceptually with Gills
  (§7) for the aquatic package.
- **Hooks:** terrain-dependent mobility — advantages flip by map (water tiles vs dry);
  the sea-lion contestant is the canonical test case for "authored animal layout."

### Hooves
- **Who:** horses, deer, cattle, goats.
- **Function:** fast straight-line movement + a **kick** (a rear-leg strike, often the
  creature's best attack). Hard keratin.
- **HP / lethal:** ~3 per leg, **non-lethal**.
- **Conditions:** *inflicts* **crushed** (kick); hard keratin *resists* **bleeding** on
  the hoof itself; *vulnerable to* **crushed**.
- **Hooks:** a leg that's also a heavy melee attack (kick = crush); enables a "kick on
  disengage" reaction; countered by staying in its blind spot (R20 — ungulate eyes are
  side-mounted, wide cone but a front/rear gap).

### Prehensile feet
- **Who:** primates, parrots, opossums, tree frogs, geckos (adhesive toes).
- **Function:** feet that grip like hands — climbing, perching, holding while both hands
  work. Gecko/tree-frog adhesion adds wall/ceiling movement.
- **HP / lethal:** ~2–3, **non-lethal**.
- **Conditions:** *vulnerable to* **bleeding**, **crushed**; adhesive pads lose grip when
  **chilled**.
- **Hooks:** climb/cling movement (vertical cover in R20 geometry); a third/fourth
  effective "hand" for hold-and-act. Overlaps talons and prehensile tail.

### Balancing / rudder tail
- **Who:** cheetahs, cats, kangaroos (a fifth-limb prop), crocodiles (swim rudder),
  squirrels.
- **Function:** agility — sharp turns, balance while sprinting, a swim rudder. Not a
  weapon or a gripper; a **mobility-quality** part.
- **HP / lethal:** ~3, **non-lethal**.
- **Conditions:** *vulnerable to* **bleeding**, **crushed**, **chilled**.
- **Hooks:** enables high-agility movement skills (turn-in-place, no-penalty direction
  change); disabling it degrades mobility but doesn't immobilize — a "soft cripple."
  (Contrast the *club/thagomizer* tail in §3, which is a weapon.)

---

## 3. Offense

*Parts whose primary job is dealing harm — dedicated weapons the human layout lacks.*

### Stinger (venom telson)
- **Who:** scorpions (metasoma tip), bees/wasps (modified ovipositor), stingrays,
  some caterpillars.
- **Function:** an **injecting** strike — delivers venom past the skin. This is the clean
  "attack that seeds poison" part because it satisfies poison's **entry requirement**
  (`_poison_gate_and_soup`: attack-sourced poison needs bleeding/head/injection/helpless;
  a stinger *is* the injection).
- **HP / lethal:** tail-tip part ~2, **non-lethal**; scorpion stinger sits on a "tail"
  segment chain.
- **Conditions:** *inflicts* **poison** (with `injection: true`) and **bleeding** (the
  puncture); bee stinger is single-use (models as a cooldown/consumable).
- **Hooks:** the premier **poison-application** tool — bypasses the entry gate. Carries a
  `poison_type`, so two differently-typed stingers on the field trigger **Poison Soup**
  (R10). Disabling the stinger shuts off the creature's affliction plan.

### Fangs / venom glands
- **Who:** snakes, spiders (chelicerae), gila monsters, some shrews.
- **Function:** a **head-mounted bite** that injects venom — like the stinger, satisfies
  poison's entry requirement, but head-slotted.
- **HP / lethal:** treat as a **head** weapon property (lethal head) rather than a separate
  pool; a spider's chelicerae could be their own ~1 non-lethal part.
- **Conditions:** *inflicts* **poison** (injection) + **bleeding**; hemotoxic vs
  neurotoxic maps to different `poison_type` values (→ Poison Soup interactions).
- **Hooks:** bite-to-envenom on the head slot; because poison on the **head** part needs
  no separate bleeding entry (head is itself an entry condition), a fanged head is the
  most reliable poison delivery in the catalog.

### Horns / antlers
- **Who:** cattle, rhinos, deer/elk (antlers, shed annually), beetles.
- **Function:** a **charge/gore** weapon and a shove; antlers also lock for grappling
  (deer wrestling).
- **HP / lethal:** ~2–3, **non-lethal** (a rhino horn is keratin, regrows; antlers shed).
- **Conditions:** *inflicts* **bleeding** (gore) and **crushed** (charge impact);
  keratin/bone *resists* **chilled**.
- **Hooks:** a movement-linked attack (charge = move + gore) — rewards line-of-sight
  approach lanes; antler-lock enables a grapple variant. Countered by not standing in the
  charge lane.

### Tusks
- **Who:** elephants, walruses, warthogs, boars, narwhals (a single tooth).
- **Function:** oversized always-present **piercing/prying** weapon; also a tool (digging,
  ice-hauling). Permanent, unlike a held weapon.
- **HP / lethal:** ~3, **non-lethal**.
- **Conditions:** *inflicts* **bleeding**, **crushed**; hard.
- **Hooks:** an un-disarmable heavy melee; a boss with tusks always has a weapon even
  "unarmed." Pairs with a heavy body for shove/impale combos.

### Spines (fixed, sharp)
- **Who:** lionfish, sea urchins, stingrays, spiny caterpillars, thorny devil lizard.
- **Function:** **contact damage** — anything that strikes or grapples the creature takes
  harm. A *reactive* offense/defense hybrid (distinct from detachable quills, §4).
- **HP / lethal:** an integument property of a body part (torso/limbs), not its own pool.
- **Conditions:** *inflicts* **bleeding** and often **poison** (lionfish/urchin spines are
  venom-tipped — a **passive** poison source on contact, no active injection needed);
  *resists* being grappled cleanly.
- **Hooks:** punishes melee and grapples against it — a "don't touch me" body; counters
  the pin-and-crush loop. Venom-tipped spines are the passive counterpart to the stinger.

### Club / thagomizer tail (tail weapon)
- **Who:** ankylosaurs (bony club), stegosaurs (the four-spike *thagomizer*), glyptodonts,
  some monitor lizards (tail-whip), crocodiles.
- **Function:** the tail as a **heavy weapon** — a wide-arc rear strike, often the
  creature's hardest hit (fossil thagomizers punched through *Allosaurus* bone).
- **HP / lethal:** ~3–4, **non-lethal**, but a **priority disable** — it's the main threat.
- **Conditions:** *inflicts* **crushed** (club) or **bleeding** (spiked thagomizer);
  bony/armored → *resists* **crushed** on itself.
- **Hooks:** a rear-arc attack that punishes flanking/backstab positioning (R20) — you
  can't safely stand behind it; discoverable "stay off the tail arc" is exactly the kind
  of **win-condition telegraph** bosses need (no raw damage race). The offensive twin of
  the §2 balance tail.

---

## 4. Defense

*Parts whose job is to reduce or refuse incoming harm — the armor slot.*

### Shell / carapace
- **Who:** turtles/tortoises (carapace + plastron), crabs/lobsters (exoskeleton),
  armadillos (banded bony plates), beetles (elytra).
- **Function:** **damage refusal / hiding** — a hard cover the creature can retreat into
  (turtle withdraws head+limbs; armadillo rolls up). Models well as the creature's
  **torso** with high HP + Physical resistance, and as a stance that *hides* limbs
  (`hidden`/withdrawn → not targetable).
- **HP / lethal:** as the **torso-equivalent (lethal)**, elevated — ~7–8 vs the human 5;
  high Physical resistance. Cracking it is the fight.
- **Conditions:** *resists* **crushed**, **bleeding** (nothing to bleed through the
  plate); a withdrawn shell also blocks **poison/infected** entry. *Vulnerable* — the seam
  is heat: prolonged **burn** cooks the animal inside; a cracked shell loses all of the
  above at once.
- **Hooks:** a "find the opening" boss — attack when it's out of the shell, or force it
  out (this is the discoverable win condition, not HP grind). "Withdraw" is a defensive
  stance that hides limb parts. Big synergy with the "no raw damage race" rule.

### Scale / plate armor (osteoderms)
- **Who:** crocodiles (keratin scales *over* bony osteoderms), pangolins (overlapping
  keratin scales), snakes/lizards, fish scales, ankylosaur body armor.
- **Function:** **flat damage reduction** across the whole body — Physical resistance
  without the retreat-and-hide behavior of a shell. Pangolin also rolls into a ball
  (scale ball = temporary shell).
- **HP / lethal:** an integument property → **Physical resistance** on parts, not its own
  HP pool. Model as `resistances.Physical` + `racial_traits.physical_resistance` (the sim
  already reads a racial `physical_resistance`).
- **Conditions:** *resists* **bleeding**, **crushed** (blunts both); osteoderms also store
  calcium (flavor). *Vulnerable to* **burn**/**chilled** at the soft seams; **poison**
  still lands if injected past the scales.
- **Hooks:** raises the R14 force-vs-robustness bar — weak single hits deal 0; rewards
  combined attacks (R15 merged force) or attacking the unarmored belly/seam. The reason a
  creature needs a **breach** to be hurt.

### Quills (detachable, barbed)
- **Who:** porcupines, hedgehogs, echidnas.
- **Function:** **defensive contact damage that detaches** — an attacker takes a barbed
  quill that stays embedded (lingering harm). Distinct from fixed spines (§3): quills come
  off *into* the attacker. (Porcupines don't shoot them — contact only.)
- **HP / lethal:** an integument property; models as a **reactive** effect on being struck
  in melee.
- **Conditions:** *inflicts* **bleeding** (embedded barb) and lingering **infected** risk
  (dirty barb — a clean fit for the infection condition); the curl-into-a-ball posture
  *hides* soft parts like a shell.
- **Hooks:** a melee-attacker punisher that leaves a **persisting condition** on the
  attacker (bleeding/infected) rather than instant damage — the "you'll regret touching
  me" body. Counter it with reach/ranged. Hedgehog/echidna ball = a shell-lite stance.

---

## 5. Sensory (ties directly to R20 stealth/detection)

*Parts that set what a creature can perceive — and therefore its **vision cone**, its
hearing, and how hard it is to stealth past. R20 says eye positioning and part-layout give
different creatures different cones; this section is the raw material for that.*

### Compound eyes
- **Who:** insects, crustaceans, mantis shrimp (extreme).
- **Function:** an **extremely wide, near-panoramic vision cone** with great motion
  detection but poor fine detail. In R20 terms: a huge cone angle, motion-triggered.
- **HP / lethal:** head-mounted; part of the **head** (lethal). Destroying/blinding →
  collapses the cone (a stealth enabler for the attacker).
- **Conditions:** *vulnerable to* **bleeding**, **dissolution** (head-routed — blinding a
  head), **burn**; blinding is a **disable** of the sensory function.
- **Hooks:** near-360° cone makes sneaking past *frontally* futile — but they detect
  **motion**, so "stay still" tactics and slow approaches beat them (R20 design space).
  Blinding one is a hard counter.

### Large forward eyes (predator binocular)
- **Who:** owls, cats, eagles, primates.
- **Function:** a **narrow but long** vision cone — excellent range and depth (owl/eagle),
  night vision (cats/owls). Extends detection range (R20 sight ≈ 2× Mind; big predatory
  eyes read as high effective sight/Mind).
- **HP / lethal:** head part (lethal).
- **Conditions:** *vulnerable to* **dissolution** (head), **bleeding**, **burn** (glare/
  flash → temporary blind = disable).
- **Hooks:** long, narrow cone → flanking works (get out of the forward arc); night-active
  eyes negate darkness-based stealth. The direct counter to a stealth build is a big-eyed
  hunter — one of R20's intended predator/prey dynamics.

### Antennae / whiskers (vibrissae)
- **Who:** insects/crustaceans (antennae), cats/rodents/seals (whiskers), catfish (barbels
  with taste buds).
- **Function:** **tremor / air-current / touch sense** — detects nearby movement without
  sight, including in the dark or behind cover. A short-range "you can't sneak up in melee
  range" sense that partially defeats visual stealth.
- **HP / lethal:** ~1, **non-lethal** (thin appendages); easily lost.
- **Conditions:** *vulnerable to* **bleeding**, **chilled**, **burn**; losing them
  **disables** the tremor sense (opens a stealth window).
- **Hooks:** a close-range detection net that fills the vision cone's blind spots — a
  reason stealth alone doesn't guarantee a backstab. Trimming/disabling them is a setup
  move for an assassin build.

### Echolocation (biosonar)
- **Who:** bats, dolphins/toothed whales, some shrews and swiftlets.
- **Function:** **active sonar** — full spatial awareness in total darkness; ignores light
  and visual cover, but is **acoustic**, so it keys off the *hearing* branch of R20 and
  can be **jammed by noise** or countered by sound-absorbing terrain (as real moths do).
- **HP / lethal:** paired ear/emitter organs on the **head** (lethal).
- **Conditions:** *vulnerable to* **dissolution** (head), deafening = **disable**.
- **Hooks:** negates darkness and light-based camouflage entirely — but a **loud
  environment or a decoy sound** (R20 hearing plays: scapegoat/decoy/misdirection) beats
  it. Deafening it is the hard counter. A rich stealth counter-play axis.

### Keen nose (macrosmatic olfaction)
- **Who:** dogs, bears, sharks, snakes (Jacobson's organ), moths (pheromones at km range).
- **Function:** **scent tracking** — detects a target's presence/trail regardless of sight
  or cover; a persistence sense (follows where you *were*). In R20 this is a third
  detection channel beyond sight and hearing.
- **HP / lethal:** head part (lethal).
- **Conditions:** *vulnerable to* **dissolution**, **burn** (smoke/irritant → temporary
  anosmia = disable).
- **Hooks:** defeats visual stealth by *trail* — you must mask scent or cross scent-breaking
  terrain (water) to lose a nose-tracker. Enables a "bloodhound" enemy that finds a hidden
  contestant. Countered by masking/environmental scent-break.

### Pit organ / lateral line (special contact senses)
- **Who:** pit vipers & pythons/boas (infrared pits, sense heat to 0.003°C),
  fish (lateral line — water-movement/pressure), sharks (electroreception).
- **Function:** **exotic detection** — the pit organ *sees heat*, so it detects a
  warm-bodied contestant **through visual camouflage and darkness**; the lateral line
  detects any movement in water. Hard counters to conventional stealth.
- **HP / lethal:** head/flank-mounted; head pits are a **head** property, the lateral line
  a **torso/flank** property.
- **Conditions:** *vulnerable to* **dissolution** (head pits), **chilled** (a chilled
  contestant is *colder* → harder for an IR pit to see = a stealth interaction!).
- **Hooks:** the anti-camouflage sense — an IR-pit hunter **ignores** the Camouflage
  skill (R20 sight seed) unless the target masks heat (e.g. is chilled/cold). A designed
  "this enemy sees through your hiding" — pushes players to a different stealth tool.

---

## 6. Utility / storage ("pockets" and tricks)

*Parts that store, conceal, illuminate, or otherwise do something other than fight/move/
sense — the owner's "pockets" request lives here.*

### Pouch (marsupial)
- **Who:** kangaroos, opossums, wombats, koalas.
- **Function:** the literal **"pocket"** — an on-body storage/carry compartment. In combat:
  **stash/retrieve an item as part of the body**, potentially outside the normal inventory
  economy (R3), or carry a small ally/young.
- **HP / lethal:** a **torso** property, not its own HP; a "container slot."
- **Conditions:** contents shielded from some AoE while pouched; a **burn**/**crushed**
  torso hit can damage stored items (flavor risk).
- **Hooks:** **in-combat storage** — draw a stashed item without the usual pick-up action,
  or protect a fragile item/ally inside. A native inventory-extension part; interacts with
  the R3 inventory-interaction economy. Rich because it's a *non-combat* mechanic that
  still shapes tactics (see standouts).

### Cheek pouches
- **Who:** hamsters, chipmunks, some monkeys, platypus (food storage while diving).
- **Function:** temporary bulk **carry in the head** — hoard/transport items or food;
  smaller, head-slotted version of the pouch.
- **HP / lethal:** a **head** property.
- **Conditions:** overfull → mild penalty (flavor); vulnerable with the head.
- **Hooks:** a smaller storage slot with a risk (it's on the lethal head); a "carry the
  objective in your cheeks" caper option.

### Crop / gizzard (specialized gut)
- **Who:** birds (crop = storage, gizzard = grinding mill with swallowed stones),
  crocodiles, earthworms.
- **Function:** **swallow-and-store / swallow-and-process** — engulf an item or small
  target; the gizzard grinds. A "swallow whole" attack + internal storage.
- **HP / lethal:** a **torso** property.
- **Conditions:** a swallowed target is subjected to **crushed** (gizzard) or **suffocation**
  (torso-routed — trapped inside); the creature is *vulnerable* to being cut open from
  inside.
- **Hooks:** a **swallow** finisher/grapple-terminal — target inside takes crushed/
  suffocation each clock, but can attack the gut from within (a "cut your way out" counter).
  Boss-scale "eaten, now escape" set-piece.

### Bioluminescence / photophores
- **Who:** anglerfish (lure), fireflies, lanternfish, some squid/octopus, glow-worms.
- **Function:** **produce light** — a lure (anglerfish esca), a signal, a counter-
  illumination camouflage, or a sudden flash. Directly manipulates the R20 sight system by
  *adding* light.
- **HP / lethal:** a small **head/torso** appendage property (an anglerfish lure could be a
  ~1 non-lethal part).
- **Conditions:** *vulnerable to* **bleeding** (lure organ); doused by nothing in the
  9-condition set — mostly a utility/positioning tool.
- **Hooks:** a **lure** that draws a target into position (anglerfish); a **flash** that
  briefly reveals or blinds (R20 sight); counter-illumination that *hides* the creature
  from below. Manipulates detection rather than dealing damage.

### Ink sac
- **Who:** octopus, squid, cuttlefish, sea hares.
- **Function:** eject a **body-sized dark cloud** (+ a decoy "pseudomorph" of ink and mucus)
  that blocks vision *and* disrupts chemoreception (scent). A one-button **break line-of-
  sight + escape** — and a decoy that fools the R20 hearing/scapegoat plays.
- **HP / lethal:** an internal **torso** property (consumable/cooldown resource).
- **Conditions:** the cloud imposes an **exposed/blinded**-style vision block on anything
  inside (models via R20 line-of-sight, not a new condition); the creature *stealths* or
  disengages under it.
- **Hooks:** an active **destealth-of-self / re-stealth** tool that ties straight into R20:
  breaks vision cones in an area, drops a decoy for the "something's there but where"
  alerted state, and blanks scent-trackers. One of the richest R20-interacting parts (see
  standouts).

### Chromatophore skin (active camouflage)
- **Who:** cephalopods (octopus/cuttlefish — plus texture-changing papillae), chameleons,
  some fish and frogs.
- **Function:** **active, on-demand camouflage** — match the background (color *and*, for
  cephalopods, texture). A built-in Camouflage skill (R20 sight seed, data id 44) as
  anatomy rather than a granted skill.
- **HP / lethal:** a whole-body **integument** property.
- **Conditions:** unaffected by most; a **burn**/**dissolution** could disable the
  color-control (flavor); works only while stationary-ish (R20: camouflage breaks on move).
- **Hooks:** native stealth that doesn't consume a skill slot — but obeys R20's rules
  (breaks on move, revealed within range, defeated by IR pits / echolocation / scent). The
  "why the octopus enemy vanishes" part; the direct interplay with §5 anti-camouflage
  senses is a whole design axis.

### Regenerating / droppable limb (autotomy)
- **Who:** lizards & geckos (drop the tail, regrow it), starfish (regrow arms; some regrow
  a whole body from one arm), crabs (regrow claws), axolotls (regrow limbs, even organs),
  octopuses (regrow arms).
- **Function:** **voluntary self-disable to escape** (autotomy) + **slow regrowth** of a
  lost part. The dropped tail may **wriggle as a distraction**. Turns "part destroyed" from
  purely bad into a tactical option.
- **HP / lethal:** applies to a **non-lethal** limb/tail; regrowth is a multi-clock/rest
  process.
- **Conditions:** dropping the part can **break a grapple** (the grappler is left holding a
  detached tail — clean interaction with the R9 grapple state); the stump may risk
  **bleeding**/**infected** until healed.
- **Hooks:** an **escape-from-grapple** tool (voluntarily lose the held limb → free) plus a
  decoy (the wriggling tail draws attention — an R20 scapegoat play), and **over-time
  self-repair** of disabled parts. Uniquely lets a creature *choose* to disable its own
  part for advantage (see standouts).

---

## 7. Vital / torso variants

*Non-human takes on the lethal core — the parts that change what "kill" and "breathe"
mean for a creature.*

### Multiple hearts
- **Who:** octopus/squid (3 hearts), earthworms (5 "hearts"/aortic arches), hagfish,
  cockroaches (a segmented multi-chambered heart).
- **Function:** **distributed vitality** — no single lethal organ; you must knock out
  redundancy before the torso is truly dead. A built-in "phase/breach" structure.
- **HP / lethal:** model as **multiple lethal sub-parts** (e.g. `heart_gill_left`,
  `heart_gill_right`, `heart_systemic`) or as an elevated-HP torso that only becomes
  killable after a **breach** — the sim already supports `hidden_until_breach` parts and a
  `breached` flag, and boss layouts already do this (see the `incinedile`/`network` enemy).
- **Conditions:** each heart *vulnerable to* **crushed** (instant, no bleed-out) and
  **bleeding**/**poison** (delayable → bleed-out per R5).
- **Hooks:** a **discoverable win condition** — find and destroy the pumping cores in
  order, not a single HP bar (exactly the boss design rule: no raw damage race). Natural
  fit for the existing breach/phase machinery.

### Long neck
- **Who:** giraffes, swans, ostriches, plesiosaurs, sauropods.
- **Function:** extends the **head's** reach and raises its vantage (a taller R20 vision
  cone, sees over cover); a reach bite/strike. Also a long, exposed **lethal** conduit.
- **HP / lethal:** a **lethal** segment linking head↔torso (~3), or fold the reach into the
  head. A prime target — cutting the neck reaches a vital.
- **Conditions:** *vulnerable to* **bleeding**, **crushed**, **suffocation** (a
  throat/airway on the neck — torso-routed condition could target here); **chilled**.
- **Hooks:** reach + high vantage (see over cover in R20) at the cost of a big, exposed
  vital target; "go for the neck" is a telegraphed vulnerability.

### Segmented body
- **Who:** worms, centipedes/millipedes, insects (head/thorax/abdomen), some snakes
  (functionally).
- **Function:** the torso as **repeated segments** — the creature keeps functioning after
  losing segments; conditions localize per segment. Distributed body plan.
- **HP / lethal:** several **torso-like** parts; make **one** the true vital (the head-
  bearing segment) and the rest non-lethal, or spread lethality so it takes several to
  kill.
- **Conditions:** conditions attach **per segment** (the engine already does per-part
  conditions) — a burn on one segment doesn't cook the others; **crushed** severs a segment.
- **Hooks:** graceful degradation like extra legs, but for the *core* — forces AoE or
  finding the one vital segment. Another "no single damage bar" body.

### Gills (aquatic breathing)
- **Who:** fish, larval amphibians/axolotls, crustaceans, mollusks.
- **Function:** breathe **in water** — but suffocate **out** of it. A terrain-gated vital:
  fine in water, a ticking clock on land (and vice-versa for air-breathers underwater).
- **HP / lethal:** a **torso/head** property; the gill itself ~2 non-lethal, but its
  *failure* is a **suffocation** timer (a lethal timer per R5).
- **Conditions:** **suffocation** out of water (torso-routed suffocation timer — directly
  reuses the existing suffocation machinery); *vulnerable to* **crushed**, **infected**;
  **poison** in the water enters through the gills readily.
- **Hooks:** a **terrain win/lose condition** — beach the fish-creature (or flood the room)
  to flip who's suffocating; the aquatic package with fins/flippers + lateral line. The
  environment becomes a weapon, which suits the dungeon-crawler frame.

---

## How these plug in

An animal contestant/enemy is authored as a **part-set that replaces or augments** the
human `head / torso / left_arm / right_arm / left_leg / right_leg`. Same record shape
(`{key, name, hp, base_max_hp, lethal, ...}`), same per-part condition system — only the
*roster of keys* changes. The default `animal` race in `data/races.json` already ships the
human 6-part template as a placeholder; R21 authors the real layouts from this catalog.

**Two invariants every layout must keep** (from the engine facts up top):
1. **A torso-equivalent and a head-equivalent must exist** (any keys), so torso-routed
   conditions (suffocation/exhausted/infected) and head-routed dissolution have a landing
   spot — `_equivalent_part()` remaps to `torso`, then to the first lethal part, so at
   minimum give the creature one lethal "core" part and one "head" part.
2. **Manipulation parts that must *act* (attack/grapple/hold) need `arm`/`hand` in the
   key** — today `usable_hands()`/`acting_part()` test that substring. Either name them
   `pincer_right_hand` etc., **or** R21 adds a `can_manipulate: true` part flag and the sim
   reads that instead of the substring. **Recommend the flag** — cleaner than key-string
   games. (This is the one small sim change R21 implies; flag it for the owner.)

**Worked example layouts** (all HP PLACEHOLDER, R14):

| Creature | Layout sketch |
|---|---|
| **Sea lion** (live-campaign animal) | `head`(2,L) · `torso`(5,L) · 2 `fore_flipper`(3) · 2 `hind_flipper`(3) · `rudder_tail`(3). Aquatic mobility; clumsy on land. |
| **Crab** | `carapace`=torso(7,L, high Physical res) · `head`(2,L) · 8 `leg`(2) · 2 `pincer_*_hand`(2, inflict crushed). No arms slot — pincers are the hands. |
| **Scorpion** | `head`(2,L) · `torso`(5,L) · 8 `leg`(2) · 2 `pincer_*_hand`(2) · `metasoma`(segmented tail) ending in `stinger`(2, injects poison). |
| **Snake** | `head`(2,L, venom fangs + IR pit) · several `body_segment`(one lethal) · no limbs. Grapple = constrict (torso), envenom = head bite. |
| **Bird of prey** | `head`(2,L, beak) · `torso`(5,L) · 2 `wing`(3, flight, disable→grounded) · 2 `talon_*_foot`(2, grapple+bleed). |
| **Octopus** | `head`(2,L, hidden beak) · `mantle`=torso with **3 lethal hearts** (breach layout) · 8 `arm_*`(2, grapple) · `ink_sac` · chromatophore skin. |
| **Ankylosaur-type boss** | armored `torso`(8,L, high res) · `head`(2,L) · 4 `leg`(3) · `club_tail`(4, rear-arc crushed) — discoverable "stay off the tail, hit the soft belly" win condition. |

**Everything here is PLACEHOLDER.** HP values, lethal flags, resistances, and which of the
9 conditions each part inflicts/resists all await **(a)** the R14 numbers rework
(force-vs-robustness, part HP, resistances) and **(b)** the owner's animal-layout sitting
that authors R21 from this catalog. Do not treat any figure as canon; treat the *shapes*
(which parts exist, what they do, which conditions they touch) as the reusable library.

---

### Sources

- [Prehensile tail — Britannica](https://www.britannica.com/science/prehensile-tail) · [Animals with prehensile tails — Animal Sake](https://animalsake.com/animals-with-prehensile-tails)
- [Octopus anatomy (3 hearts, ink, chromatophores) — OctoNation](https://octonation.com/octopus-anatomy/) · [Cephalopod ink: production, chemistry, functions — NCBI](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4052311/) · [Cephalopod color change — thecephalopodpage](https://thecephalopodpage.org/cephschool/HowCephalopodsChangeColor.pdf)
- [Thagomizer — Wikipedia](https://en.wikipedia.org/wiki/Thagomizer) · [Tail club — Wikipedia](https://en.wikipedia.org/wiki/Tail_club)
- [Infrared sensing in snakes — Wikipedia](https://en.wikipedia.org/wiki/Infrared_sensing_in_snakes) · [Pit vipers detect prey via heat — AMNH](https://www.amnh.org/explore/news-blogs/pit-viper-thermal-detection)
- [Venom: fangs, stingers, spines — Cal Academy](https://www.calacademy.org/exhibits/venom-fangs-stingers-and-spines) · [Venom — Wikipedia](https://en.wikipedia.org/wiki/Venom) · [Scorpion metasoma/telson — San Diego Zoo](https://animals.sandiegozoo.org/animals/scorpion)
- [Armour (zoology) — Wikipedia](https://en.wikipedia.org/wiki/Armour_(zoology)) · [Osteoderm development — Wikipedia](https://en.wikipedia.org/wiki/Osteoderm_development) · [Armored animals — GreaterGood](https://greatergood.com/blogs/news/armored-animals)
- [Weird animal body parts — Discover Wildlife](https://www.discoverwildlife.com/animal-facts/weirdest-animal-body-parts) · [Tail — Wikipedia](https://en.wikipedia.org/wiki/Tail)
