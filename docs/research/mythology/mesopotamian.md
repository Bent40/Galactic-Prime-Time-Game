# Mesopotamian mythology — Wave-2 extraction dossier

*Galactic Prime Time · mythology sweep Wave 2 · 2026-07-18 · tradition `mesopotamian`*
*Inputs: mythology-research-spec (RULED, incl. §3.3 depiction-policy v2), traditions.json census record (source_quality 5, influence_ceiling 2), census_candidates.jsonl (41-candidate pool), frozen Wave-0 calibration (Zababa 1/1), cosmic-casino-canon §4.*

## 1. Tradition overview — and the casino angle

Mesopotamian mythology (Sumerian → Akkadian → Babylonian → Assyrian, c. 3000–300 BCE) is
the oldest written mythology on Earth: cuneiform gave it primary texts a millennium
before Homer. Its cosmos is run like an administration — fates are DECREED, written,
filed, stolen, and reassigned; the gods divide the universe by **casting lots**
(Atrahasis I: Anu draws the sky, Enlil the earth, Enki the waters), and supreme power is
a portable clay object (the Tablet of Destinies) that betrays every holder. There is no
native luck/gambling deity — fate is a government office, not a wheel — and the census
correctly hangs the `luck_gambling` flag on the office-holders: **Namtar** (fate's
process-server) and the **Tablet** itself.

**Modern-life attribution (canon §4 register, offered for the roster pass):** the
Mesopotamians are the casino's **founding dynasty** — the family that built the first
tables, invented writing, contracts, ledgers, and the deed itself, then lost the
business generations ago. They haunt the floor as management emeriti: old-money
bureaucrats in dated finery who stamp everything with cylinder seals, insist every bet
be recorded in triplicate, and never let the new owners forget who poured the
foundations. This lands on canon already in place: **Enki is canonically the runner of
Marcus's Forsaken table** (cosmic-casino-canon §5), and the spec names the
fallen-god-as-table-runner pattern after him (§1 'the Enki pattern').

**Forsaken density is exceptional here.** The corpus is full of gods staking existence
and losing: Tiamat (unmade; her body became the world), Apsu (the first god ever
unmade), Inanna (died on the hook, ransomed by a substitute), Anzu (the all-in heist),
Erra (talked the king of gods off his throne for the thrill), Qingu (executed, drained
into humanity). Per the §5 amendment (any god can go all-in; erasure can unlock stages),
this tradition is the Forsaken table's home turf.

## 2. Source base & verification method

Source_quality 5 (census): rich public-domain primary translations.

- **ETCSL** (Oxford, Electronic Text Corpus of Sumerian Literature): Inana's Descent
  (t.1.4.1, tr141), Inana and Enki (t.1.3.1), Gilgamesh and Huwawa A (t.1.8.1.5,
  tr1815), Gilgamesh and the Bull of Heaven (t.1.8.1.2), Ninurta's Exploits / Lugal-e
  (t.1.6.2), Ninurta and the Turtle (t.1.6.3, tr163), Dumuzid's Dream (t.1.4.3).
- **L. W. King, The Seven Tablets of Creation (1902, PD)** — Enuma Elish
  (sacred-texts.com/ane/stc).
- **R. Campbell Thompson, The Epic of Gilgamish (1928, PD)**; A. George, The Epic of
  Gilgamesh (Penguin) as academic reference for the Standard Babylonian text.
- **Stephanie Dalley, Myths from Mesopotamia (Oxford World's Classics)** — Atrahasis,
  Anzu, Erra and Ishum, Nergal and Ereshkigal, Descent of Ishtar, Adapa.
- **Jeremy Black & Anthony Green, Gods, Demons and Symbols of Ancient Mesopotamia** —
  iconography claims (symbols, animals, attested depictions).
- **ORACC AMGG** (oracc.museum.upenn.edu/amgg) — deity profiles (via search surface;
  direct fetch blocked, see below).
- Wikipedia / Britannica / World History Encyclopedia / EBSCO Research Starters as
  index, claims verified one level down per the source ladder.

**Verification note (honesty):** in this container, direct fetches of ETCSL, ORACC, and
Wikipedia returned proxy 403s; verification therefore ran through web-search result
surfaces, which quoted the relevant ETCSL translation lines and reference-work passages
directly. Every load-bearing claim below was confirmed this way in-session
(2026-07-18): Huwawa's auras traded one by one (ETCSL tr1815 quoted in results);
Zababa's Kish/war/eagle-staff/Bau profile (Wikipedia/ORACC surfaces); Marduk's
wind-into-maw arrow kill, Qingu's blood → mankind (sacred-texts/WHE/Britannica
surfaces); the Namtar snub, fourteen demons at the gates, seizure of Ereshkigal from
her throne, raise-the-dead threat (multiple surfaces incl. Temple of Sumer's text
page); Erra persuading Marduk off his throne + Sibitti rampage + amulet use (Wikipedia
'Erra (god)' surface); the me drinking-bout heist and Boat of Heaven pursuit (WHE
surface); Atrahasis lot-casting division of the cosmos (New World Encyclopedia/livius
surfaces); the sixty diseases and water-of-life sprinkle, kurgarra and galatur rescue
(HistoryWiz primary-source page + ETCSL tr141 surfaces); Enki's turtle pit humbling
Ninurta (ETCSL tr163 + EBSCO surfaces); Anzu's decree-reversion of arrows and the
wing/feather stratagem (EBSCO 'Theft of Destiny' + Wikipedia Ninurta surfaces).

## 3. Myth leads forward-declared (Wave 3 to write full records)

| id | story | primary source | verified via |
|---|---|---|---|
| `myth_mesopotamian_descent_of_inanna` | Inanna/Ishtar descends, is stripped at seven gates, killed, hung on hook; revived (kurgarra & galatur / water of life); substitute demanded — Dumuzid taken | ETCSL t.1.4.1; Akkadian Descent of Ishtar (Dalley) | search: ETCSL tr141 + HistoryWiz surfaces |
| `myth_mesopotamian_inanna_and_enki_me` | Inanna drinks Enki under the table, sails off with the me; pursuit fails; Uruk keeps them | ETCSL t.1.3.1 | search: WHE/mesopotamiangods surfaces |
| `myth_mesopotamian_bull_of_heaven` | Spurned Ishtar borrows the Bull; drought-beast tramples Uruk; Enkidu hurls its haunch at her | SB Gilgamesh VI; ETCSL t.1.8.1.2 | standard text; multiple surfaces |
| `myth_mesopotamian_enuma_elish` | Apsu slain by Ea; Tiamat's monster army; Marduk's price (supreme decree); wind-wedged maw, arrow, world built from her body; mankind from Qingu's blood | King 1902 (PD), Tablets I–VI | search: sacred-texts/WHE/Britannica surfaces |
| `myth_mesopotamian_nergal_and_ereshkigal` | Nergal's snub of Namtar; descent with fourteen demons; throne seized; marriage; raise-the-dead threat | Amarna + Sultantepe versions (Dalley) | search: multiple surfaces incl. Temple of Sumer |
| `myth_mesopotamian_erra_epic` | Restless Erra lures Marduk off his throne; Sibitti rampage; Ishum talks him down; text worn as amulet | Erra and Ishum (Dalley/Foster) | search: Wikipedia 'Erra (god)' surface |
| `myth_mesopotamian_anzu_tablet_theft` | Anzu steals the Tablet from Enlil's bath-door watch; arrows revert to reed; Ninurta wins via the feather/wind stratagem | SB Anzu (Dalley) | search: EBSCO/Wikipedia surfaces |
| `myth_mesopotamian_lugale_asag` | Ninurta vs Asag and the stone army; Sharur the talking mace scouts; the stones judged — blessed and cursed | Lugal-e, ETCSL t.1.6.2 | standard text; game bible already uses Asag |
| `myth_mesopotamian_ninurta_and_the_turtle` | Ninurta covets the recovered Tablet; Enki's clay turtle digs a pit; the hero humbled | ETCSL t.1.6.3 | search: ETCSL tr163 + EBSCO surfaces |
| `myth_mesopotamian_gilgamesh_humbaba` | Cedar Forest raid; Shamash's thirteen winds; auras traded for gifts; Humbaba begs, dies; Enlil's anger | SB Gilgamesh III–V; ETCSL t.1.8.1.5 | search: ETCSL tr1815 quoted in results |
| `myth_mesopotamian_death_of_enkidu` | The gods' invoice: one of the pair must die for Bull + Humbaba; Enkidu dreams, sickens, dies | SB Gilgamesh VII | standard text |
| `myth_mesopotamian_gilgamesh_immortality_quest` | Scorpion-men gate, Siduri, Urshanabi, Utnapishtim's test, Plant of Heartbeat won and lost to the snake | SB Gilgamesh IX–XI | standard text |
| `myth_mesopotamian_atrahasis_flood` | Lots cast to divide the cosmos; plagues (Namtar shamed by directed offerings); Enki's reed-wall warning; the flood and the boat | Atrahasis (Dalley); SB Gilgamesh XI | search: NWE/livius surfaces |
| `myth_mesopotamian_adapa_south_wind` | Adapa breaks the south wind's wing; coached by Enki to refuse the bread of life; loses immortality | Adapa (Dalley/Foster) | census one-liner + standard text |
| `myth_mesopotamian_dumuzids_dream` | Dumuzid's death-dream; Utu turns his hands to gazelle's to slip the galla; caught at last | ETCSL t.1.4.3 | standard text |

## 4. Entities

### §Inanna / Ishtar — god, patron, VIP
The Queen of Heaven: love, war, and ambition fused. Texts: Descent (ETCSL t.1.4.1 /
Dalley), Inana and Enki (t.1.3.1), Gilgamesh VI. Ratings: influence 2 (tradition
ceiling; named revival target per census — Temple of Sumer; the family's strongest
cultural continuity), recognition 4 (census provisional 4; SMT/Fate-class game
presence). Depiction low (revival, data-only per policy v2). **Axes:** generosity 4
(lavishes favorites — the me handed to Uruk, Dumuzid showered); strictness 3; pettiness
5 (the Bull of Heaven — thousands dead over one rejection; Dumuzid condemned for
insufficient mourning); wrath 5 (Mount Ebih flattened for failing to bow — Exaltation
of Inanna corpus); fidelity 2 (Gilgamesh VI's catalog of discarded lovers is a primary
source ON her fidelity); risk_appetite 5 (walked into the land of no return with only a
contingency plan; drank a senior god under the table for civilization's source code).
Forsaken lens: died on the hook and paid her way out with a substitute — as host, her
fine print says someone else can cover her losses.

### §Enki / Ea — god, patron, VIP — GAME CANON
Lord of the abzu, trickster-engineer, maker of humanity, **already canon as Marcus's
Forsaken table runner** (cosmic-casino-canon §5; spec §1 'the Enki pattern'). Texts:
Inana and Enki, Atrahasis (reed-wall flood warning — kept the letter of his oath by
telling the wall, not the man), Adapa, Descent (fashions kurgarra and galatur from
fingernail dirt to retrieve Inanna), Ninurta and the Turtle. Ratings: influence 2
(revival target), recognition 3 (the rubric's own named anchor). **Axes:** generosity 4
(saved humanity twice, gave the me away drunk and let Uruk keep them); strictness 2
(letter-of-the-law only); pettiness 1 and wrath 1 (the corpus's least vindictive great
god — he punishes by教 lesson, cf. the turtle pit, not by plague); fidelity 4 (reliably
protects his creations and protégés); risk_appetite 3 (a hedger — schemes with exits).
His patron sheet is information-first, matching his canon role of teaching while
impartial.

### §Marduk — god, patron, VIP
Babylon's champion. Texts: Enuma Elish (King 1902), Erra and Ishum. The load-bearing
character beat: he accepted the Tiamat contract ONLY after the assembly convened and
wagered him supreme decree — the price negotiated before the fight (Tablets II–III) —
then killed her by wedging her maw open with the winds and shooting inside (IV), built
the world from the corpse (IV–V), and made mankind from Qingu's blood (VI). Ratings:
influence 2 (revival target), recognition 3 (census 3). **Axes:** generosity 3
(assigned the gods their stations, built them Babylon); strictness 4 (order incarnate;
fifty names of bureaucratic completeness); pettiness 2; wrath 3 (Qingu executed
judicially, not rabidly); fidelity 4 (holds the assembly bargain; the Erra lapse is him
being conned, not defecting); risk_appetite 4 (staked his claim on single combat
against the unbeatable; left his throne on a dare — and the world burned).

### §Ereshkigal — god, patron, Normal
Queen of the Great Below. Texts: Descent (both versions — she orders the sixty
diseases, later orders the water of life), Nergal and Ereshkigal (the snub, the
fourteen demons, seized by the hair from her own throne, the raise-the-dead threat, the
marriage). Ratings: influence 1, recognition 3 (census 3; steady game presence).
**Axes:** generosity 1 (her house gives nothing back; rations of dust); strictness 5
(the seven-gate protocol admits no exceptions, not even for her sister); pettiness 3
(the feast snub became an interstate incident); wrath 4 (killed Inanna; threatened to
empty the underworld); fidelity 5 (nothing leaves her; and once Nergal is hers, he is
hers forever); risk_appetite 2 (plays only home games — but her one recorded bet, the
hostage ultimatum, was table-flipping). Patron of hardcore/attrition play; her deal
sheet is deliberately the roster's cruelest.

### §Nergal / Erra — god, patron, Normal — MERGED
War, plague, the scorching season; king of the underworld by hostile takeover turned
marriage. MERGE NOTE: census listed Nergal and Erra separately; first-millennium
sources treat Erra as Nergal's name (the Erra epic's protagonist), so one entity with
`syncretic_group: nergal_erra`, Wave 4 to ratify or split. Texts: Nergal and
Ereshkigal; Erra and Ishum. Ratings: influence 1, recognition 3 (census 3). **Axes:**
generosity 2; strictness 3; pettiness 4 (the entire descent-war began with a chair he
didn't rise from); wrath 5 (the Erra epic is the corpus's anatomy of divine rampage);
fidelity 3 (fled Ereshkigal, returned, stayed); risk_appetite 5 (stormed death's house
with fourteen demons; talked the king of gods off his throne to feel alive — the
census's phrase, 'the pantheon's all-in gambler temperament,' is earned). Prime
Forsaken host.

### §Shamash / Utu — god, patron, Normal
The all-seeing sun, judge of heaven and earth, patron of travelers and the wronged.
Texts: Gilgamesh III–V (raises the thirteen winds that pin Humbaba at the crucial
moment), Dumuzid's Dream (turns the fugitive's hands to gazelle's — the pardon side),
plus the (non-narrative, so not myth-declared) Great Hymn to Shamash for his
merchant-scales ethics. Ratings: influence 1, recognition 2 (census 2 — famous office,
obscure name). **Axes:** generosity 3 (aids petitioners reliably); strictness 5 (oaths
are absolute; crooked scales cursed); pettiness 1 (the pantheon's only genuinely
impartial great god); wrath 3 (heavy but lawful); fidelity 5 (the daily circuit never
missed once in five thousand years of texts); risk_appetite 1 (bets on verdicts, which
are sure things). The casino's compliance office.

### §Ninurta — god, patron, Normal
Enlil's champion: war, the hunt, and — unusual pairing — agriculture. Texts: Anzu epic
(recovers the Tablet via Ea's feather stratagem), Lugal-e (slays Asag, judges the
stones — **the game's 'Offspring of Asag' monsters come from HIS myth**), Ninurta and
the Turtle (his ambition to keep the Tablet punished by Enki's pit). Ratings: influence
1, recognition 2 (census 2). **Axes:** generosity 3 (returned fate to the commons;
blessed the useful stones); strictness 4 (soldierly); pettiness 2 (trophy vanity, not
spite); wrath 4 (Asag and the stone army annihilated); fidelity 4 (Enlil's reliable
arm — the turtle episode is the one wobble); risk_appetite 4 (took the Anzu bounty
after senior gods refused it, against a foe holding fate itself).

### §Zababa — god (non-patron), Normal — FROZEN CALIBRATION ANCHOR
City god of Kish, pure war-god profile; spouse Bau (OB period); symbol the eagle-headed
staff (kudurru-attested); prominent as Hammurabi-era war god; equated with
Ninurta/Ningirsu in character. NO narrative myths survive — therefore NOT
patron_capable (a deal sheet would be invention; spec §7 forbids it), and his axes are
inferred from role attestations (war epithets, curse formulas, tutelary loyalty across
three dynasties of Kish) — flagged low-confidence. Scores are the frozen 1/1 EXACTLY
(calibration.json `mesopotamian_zababa`). Substitution note: not in the census pool;
included as the calibration anchor and the canon's beloved mythic-tier collector piece.
Casino use: Normal-table dealer; the desperate-god Forsaken seed (§5 amendment — a god
with nothing left staking residual existence; erasure-on-loss unlocks content).

### §Namtar — god (messenger), Normal — luck_gambling office
Fate personified; Ereshkigal's vizier and herald; plague-bringer. Texts: Nergal and
Ereshkigal (his snub starts the plot; he administers the gates), Descent of Ishtar
(strikes her with sixty diseases on order; sprinkles the water of life on order),
Atrahasis (as plague he WITHDRAWS when humanity, coached by Enki, directs all offerings
to him alone — shame as an exploit). Ratings: 1/1 (census 1; specialists only — the
Zababa shelf). Carries the census `luck_gambling` flag as fate-office holder, per the
tradition record's own note (no native gambling deity exists; the fate bureaucracy is
the nearest office). **Axes:** generosity 1; strictness 5 (protocol embodied);
pettiness 4 (a chair-snub became a war); wrath 3; fidelity 5 (the perfect servant);
risk_appetite 1 (fate doesn't gamble — it serves papers). Casino: messenger/dealer; the
Notice of Allotment event NPC.

### §Tiamat — god (primordial, non-patron), Normal
Saltwater mother of everything, roused to war by her consort's murder; made eleven
venom-blooded monsters; unmade by Marduk and split into sky and earth. Texts: Enuma
Elish I–V. Ratings: influence 1 (primordial, no cult); **recognition 3, deliberately
below the census's provisional 4** — the spec's §3.2 rubric itself names Tiamat at the
3-anchor, and the extra fame belongs to D&D's five-headed dragon, a WotC design we
cannot draw from (census closed-material note: caution, not closure — ip_status stays
`traditional`, art derives from primary text only). **Axes:** generosity 2 (initially
indulgent of her noisy children); strictness 2; pettiness 2; wrath 4 (slow to rouse,
apocalyptic once roused); fidelity 3 (avenged Apsu late; elevated Qingu); risk_appetite
5 (staked her body — the first all-in in history). Forsaken lens: the primal erasure
that BUILT the playing field — canon's 'loss unlocks stages' has its precedent here.

### §Gilgamesh — hero, contestant_legend
Two-thirds divine king of Uruk. Texts: SB Epic (George; Thompson 1928 PD), Sumerian
poems (ETCSL). Ratings: influence 1 — the Väinämöinen calibration lesson verbatim
(epic-literary fame without living worship); recognition 4 (census 4; Fate-class
presence, school-canon epic). ip `public_domain_literary` per census flag. **Axes:**
generosity 3; strictness 2; pettiness 3 (recited a goddess's dating history to her
face); wrath 3; fidelity 4 (the whole second half of the epic is grief-loyalty);
risk_appetite 5 (fame-raid on the Cedar Forest; the abyss dive). His arc — beat every
table, lose the immortality table, come home wise — is the myth-recreation economy's
founding template; epithet seed 'He Who Saw the Deep'.

### §Enkidu — hero, contestant_legend
Made from clay BY THE HOUSE to balance an overpowered contestant; civilized by
Shamhat; chose friendship over spec; killed by the gods' invoice. Texts: SB Epic I–VIII.
Ratings: influence 1, recognition 3 (census 3). ip `public_domain_literary`. **Axes:**
generosity 4 (guarded the shepherds; gave everything to the friendship); strictness 2;
pettiness 3 (threw the Bull's haunch in Ishtar's face — magnificent, doomed, extremely
on-camera); wrath 3; fidelity 5 (died for his partner's shared deeds without naming it
unfair until the fever-dreams); risk_appetite 4. Game: recruitable-rival archetype and
the 'gods' invoice' co-op event (a shared kill generates a debt exactly one member
pays).

### §Humbaba — beast, table_boss
Guardian of the Cedar Forest, appointed by Enlil; face of coiled entrails (attested
apotropaic mask plaques — Black & Green); seven auras of terror. Texts: ETCSL
'Gilgamesh and Huwawa A' (auras handed over one by one for offered gifts — quoted in
verification: 'when Huwawa had finally handed over to him his seventh aura, Gilgamesh
found himself beside Huwawa'), SB Gilgamesh V (the thirteen winds; the plea; the
beheading; Enlil's anger). Ratings: influence 1, recognition 3 (census 3). **Axes:**
generosity 1; strictness 4 (duty); pettiness 2; wrath 4; fidelity 5 (never left his
post); risk_appetite 1 (defensive; negotiates). Boss design in entity record: Large;
exhausted/crushed/bleeding affinities; tribute-baiting aura-shed win condition; the
on-camera mercy fork after he begs.

### §Anzu — beast, table_boss
The lion-headed thunderbird (Imdugud), trusted at the door of Enlil's bath, who grabbed
the Tablet of Destinies and went all-in on uncatchable. Texts: SB Anzu (Dalley):
holding the Tablet he decrees arrows back into reed, feather, and stone; Ea's stratagem
— strip his feathers on the gale and strike during the 'wing to wing' recall — wins.
Ratings: influence 1, recognition 2 (census 2). **Axes:** generosity 1; strictness 1;
pettiness 3; wrath 3; fidelity 1 (betrayed the master who trusted him at his most
vulnerable); risk_appetite 5 (the heist archetype). Census forsaken_candidate: the
all-in that ended with clipped wings. Boss design in entity record (decree-reversion
invulnerability; recall-window kill).

### §Tablet of Destinies — artifact, God Relic seed
The clay deed to the universe: whoever wears it decrees fate. Held by Enlil, stolen by
Anzu, worn by Qingu at Tiamat's grant, taken by Marduk, coveted by Ninurta and denied
him via turtle. Texts: Anzu epic, Enuma Elish, Ninurta and the Turtle. Ratings:
influence 1, recognition 2 (census 2). Carries the census `luck_gambling` flag (fate
office). **Axes (item-temperament):** strictness 5 (what it decrees, IS), fidelity 1
(serves any wearer, betrays every holder in sequence — four holders, four losses),
risk_appetite 3 (it IS the stake), generosity/pettiness/wrath 1 (it does not care).
Item design in entity record: requirement-relaxing God Relic that broadcasts the wearer
and magnetizes theft events — wearing the deed makes you the house, and everyone knows.

## 5. Candidates skipped, and why (honesty ledger)

- **Dumuzid/Tammuz & Geshtinanna** (both forsaken_candidates): strongest skips. Slot
  economy — their whole story is carried inside `myth_mesopotamian_descent_of_inanna`
  and `myth_mesopotamian_dumuzids_dream`, both declared. If the roster later wants a
  dying-god patron (half-year absence mechanic), extract Dumuzid in a Wave-2b pass.
- **Apsu, Qingu** (forsaken_candidates): fully narrated inside Enuma Elish; their
  unmaking survives in Tiamat's and Marduk's records and the myth lead. No standalone
  myth corpus beyond it.
- **Anu, Enlil, Nanna/Sin, Ninhursag, Nabu, Ashur, Adad**: real gods with real texts,
  cut purely by the 15-slot cap in favor of the forsaken/luck-flag priorities; Enlil
  especially recurs as off-screen authority in five declared myths. All remain in the
  census pool for expansion.
- **Pazuzu (rec 3, ip-flagged), Lamashtu, Galla, Lamassu (rec 3), Lilitu, Apkallu,
  Mushussu, Girtablullu, Bull of Heaven**: good enemy/spirit material; slot economy.
  Note the census's Pazuzu ip flag mirrors Tiamat's (Exorcist design is modern IP; the
  ancient amulet demon is traditional). Lilitu is deliberately deferred to the
  abrahamic_folk census per the census's own closed-material note.
- **The Me, Plant of Heartbeat** (artifacts): the me survive inside
  `myth_mesopotamian_inanna_and_enki_me`; the Plant inside the immortality quest (and
  as a scripted heartbreak event in Gilgamesh's hooks). Tablet of Destinies took the
  artifact slot on its luck_gambling flag.
- **Etana and Lugalbanda** were already OMITTED by the census (deified-king line, D-4);
  nothing to add.

## 6. Calibration statement

Frozen-set consistency: Zababa extracted at exactly 1/1/none/mythic/normal (frozen
values). All other scores sit on the anchor lattice: influence 2 only for the census's
named revival targets at the tradition ceiling (Inanna, Enki, Marduk — Zeus-logic one
scale down), influence 1 everywhere else (rubric: 'most Mesopotamian'); recognition
uses the rubric's own named anchors (Enki=3, Tiamat=3, Väinämöinen-lesson for
Gilgamesh's influence, Baba-Yaga-tier 4 for Gilgamesh/Inanna recognition). One
deliberate census deviation, argued in place: Tiamat recognition 3 vs provisional 4
(within ±1; rubric anchor wins over D&D-brand fame we cannot legally draw on).
