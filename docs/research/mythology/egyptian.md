# Egyptian Mythology — Wave 2 Extraction Dossier

Status: extraction batch complete (15 entities) · researcher: Wave-2 fan-out agent · date: 2026-07-18
Spec: `docs/design/mythology-research-spec.md` (RULED, incl. §3.3 depiction-policy v2) · census: `data/mythology/census_candidates.jsonl` line "egyptian" · calibration: `data/mythology/calibration.json` (frozen)

## 1. Tradition overview — and the casino angle

Ancient Egyptian religion ran ~3,000 years as the state technology of a civilization
obsessed with **audit, verdict, and estate transfer**: every soul ends its run at a
weighing station, its heart counterweighed against a feather, with a recorder (Thoth),
an auditor (Anubis), a presiding judge (Osiris), fate officers in attendance (Shai,
Renenutet), and a repo-beast under the table (Ammit). No other pantheon maps this
cleanly onto a casino's back office — **proposed pantheon-level modern-life
attribution (owner review): the Egyptian gods play the Cosmic Casino as a dynastic
estate-and-probate firm** — funeral directors, notaries, actuaries, and one disgraced
ex-heir — who handle the house's death paperwork and audits. (Fits the canon register:
petty, procedural, morally alien; extends the owner's Greek-Hawaii / Roman-food seeds.)

The tradition is also unusually rich in **casino-native myth**: an attested divine
gamble that restructured the calendar (the moonlight wager), a murder committed via a
**rigged party game** (Set's chest), an 80-year litigation over the throne, a god who
was unmade and returned (Osiris), a god who lost his cult entirely (Set), and a creator
whose **existence-stake all-in is already scheduled** (Atum, BD 175). All five census
`luck_gambling` flags and all five `forsaken_candidate` flags are extracted below.

Worship status: ancient cult extinct; small open-practice Kemetic revival (Kemetic
Orthodoxy/House of Netjer, founded 1988; low thousands). Per the tradition record, god-class
entries carry `depiction_risk: low` (data only under depiction-policy v2); nothing is
culturally closed. Source quality 5 — rich public-domain primary translations.

## 2. Source base and method

Ladder used: PD primary translations → academic reference (Wilkinson 2003, *The Complete
Gods and Goddesses of Ancient Egypt*; Pinch 2002, *Egyptian Mythology: A Guide*) →
Wikipedia as index with claims verified one level down (museum glossaries, university
course texts, journal material). Web verification performed 2026-07-18 through the session
proxy; sacred-texts.com and penelope.uchicago.edu returned 403 through the proxy, so
Plutarch passages were verified via the Cornell teaching text
(courses.cit.cornell.edu/hist1510/Plutarch_Isis&Osiris.pdf) and the Maricopa open-education
World Mythology chapter (open.maricopa.edu), with sacred-texts page identities confirmed
via search index. Primary texts relied on:

- **Plutarch, De Iside et Osiride** §12 (Hermes wins the seventieth part of the Moon's light
  at draughts → the five epagomenal days; children of Nut born on them), §13 (the chest:
  measured to Osiris, promised at the banquet "to whoever fits it", 72 conspirators seal it),
  §18 (dismemberment into parts; the fish-taboo aetiology). Verified via Cornell/Maricopa texts.
- **The Contendings of Horus and Seth**, P. Chester Beatty I (20th Dyn.): "it is eighty years
  now that we have been in the tribunal"; Neith's arbitration letter; hippopotamus duel; Set's
  stone boat; Thoth as counsel/recorder. Verified via Wikipedia → journals.uchicago.edu
  (Oden, *History of Religions* 18.4) and TheCollector summary.
- **Book of the Heavenly Cow** (royal tombs, NK): Destruction of Mankind — Ra sends his Eye as
  Sekhmet; 7,000 jars of beer dyed with red ochre flood the fields; she drinks, sleeps, and
  humanity survives. Verified via worldhistory.org, the-past.com, brewminate.
- **Turin papyrus, Legend of Ra and Isis** (Pleyte & Rossi; PD tr. in Budge, *Legends of the
  Gods*, 1912): Isis crafts the serpent from Ra's spittle, extracts the secret name. Verified
  via sacred-texts leg06/ebod07 index + wisdomlib. (Myth lead for the Isis/Ra follow-up batch.)
- **Book of the Dead**: BD 125 (weighing, 42 declarations, Ammit and the second death — ROM
  collections, egypt-museum Papyrus-of-Ani commentary); BD 175 (Atum: "I shall destroy all I
  have made; the land will return into the Nun... I shall remain with Osiris", both as
  serpents — Global Egyptian Museum glossary, Fitzwilliam Museum); BD 17b (Medjed: "who
  smites/shoots with his eye, yet is unseen", House of Osiris — Wikipedia → Salvador 2017,
  *Journal of Geek Studies*; Greenfield Papyrus sheet 76; 2012 Mori Art Museum exhibition →
  Japanese meme career).
- **Book of Overthrowing Apep**, P. Bremner-Rhind (BM EA 10188, Ptolemaic): execration
  program — speared, bound, cut, burned daily; Set spears Apep from the barque prow (Amduat
  tradition). Verified via Wikipedia (Apophis) + worldhistory.org.
- **Tale of Two Brothers**, P. D'Orbiney (BM EA 10183, reign of Seti II; PD ed. Moldenke,
  archive.org): brothers named Anubis and Bata; heart hidden in the cedar; deaths and returns
  as bull → persea trees → splinter → crown prince → king. Verified via Wikipedia + BM
  collection record.
- **Setne I (Setne Khamwas and Naneferkaptah)**, demotic (P. Cairo 30646; PD tr. Griffith,
  *Stories of the High Priests of Memphis*, 1900): the Book of Thoth in nested chests at
  Coptos guarded by the deathless serpent; Thoth's punishment of Naneferkaptah's family; the
  tomb board game with sinking stakes (game unnamed in text — senet per scholarly comparison,
  noted on Wikipedia's Senet article); Setne's escape and forced restitution. Verified via
  attalus.org index + worldhistory.org Setna I summary.
- **Bentresh Stela** (Louvre C 284, Ptolemaic pseudo-Ramesside): statue of
  Khonsu-the-Provider sent to Bakhtan; the possessing spirit concedes and departs; Khonsu
  demands his own return in a dream. Verified via Wikipedia + egypt-museum.
- **Pyramid Texts, Cannibal Hymn** (PT 273–274, Unas): Khonsu the butcher "who slays the
  lords, strangles them for the King" — his oldest attested face. Verified via
  ancientegyptonline.co.uk/khonsu + hymn translations online.
- **Philae, Temple of Hathor reliefs** (Ptolemaic): Bes as musician-dancer in the festival
  program for the return of the raging goddess ("Bes succeeded in flattering Hathor with his
  dancing and music, resulting in her return"). Verified via uncoveringsound.com + ASOR photo
  collection (pid000668, pid000672) + ancient-egypt-online Philae pages.
- **Set demonization arc**: Ramesside royal names (Seti = "man of Set") → post-Dyn. XX
  eradication, Late Period execration rituals, association with foreign oppressors; cult
  persistence only in the oases (Kharga, Dakhla). Verified via Wikipedia (Set) + U. Penn
  Discentes essay + Charles University thesis (dspace.cuni.cz).

## 3. Calibration cross-check (frozen set, ±1 rule)

- **Anubis (2/5, vip, common)** mirrors calibration **Zeus (2/5, vip, common)** exactly — the
  rubric's §3.2 anchor list itself names Anubis at recognition 5; §3.1's influence-2 anchor
  names "Egyptian core figures". All core gods here (Thoth, Set, Osiris, Sekhmet, Khonsu,
  Atum, Bes) sit at influence 2 on the same anchor.
- **Shai and Renenutet (1/1, normal, mythic)** mirror **Zababa (1/1)** — minor extinct cult,
  specialists only, deliberately not padded; canon makes mythic tier a collector feature.
- **Bata (hero, 1/1)** calibrates against **Väinämöinen (hero, 1/3)**: same no-worship
  influence floor; recognition 1 not 3 because he has no national-epic living fame.
- **Medjed (1/2)** sits well below **Baba Yaga (1/4)**: a real niche celebrity, not a
  global folk image. No entity in this batch exceeds the tradition's influence ceiling (3);
  none of the calibration entities themselves were re-scored.

## 4. Entities

### Thoth (egyptian_thoth) — god, patron
The scribe, reckoner, and referee of the gods; Hermopolitan moon-linked intellect. **The
casino-founding myth**: Plutarch (De Iside 12) — playing draughts against the Moon, he won
the seventieth part of her light and built the five epagomenal days from the winnings, the
loophole-days on which Nut's cursed children could be born. He referees the 80-year
Contendings, restores what is broken (the wedjat), and wrote the one book so dangerous it
gets its own record below. **Axes**: generosity 3 (knowledge given, but priced in exactness);
strictness 4 (the 42-declaration recorder); pettiness 2 and wrath 2 (the tribunal's calm
hand — but the Setne cycle shows procedural punishment when his book is stolen); fidelity 4
(steady counsel across every myth); risk_appetite 3 (gambles famously, but only after
computing the odds — a card-counter, not a plunger). Syncretism lead for Wave 4:
Thoth→Hermes (Hermes Trismegistus) once the Greek batch lands. Citations: Plutarch §12
(Cornell/Maricopa texts); Contendings (Oden 1979 via journals.uchicago.edu); Wilkinson 2003.

### Khonsu (egyptian_khonsu) — god, patron, Forsaken lens
Theban moon god, son of Amun and Mut, "the Traveller". Three attested faces: the Cannibal
Hymn's divine butcher (PT 273–274, his OLDEST layer); the New Kingdom's gentle healer
(Bentresh Stela — his statue exorcises the princess of Bakhtan, then demands to be returned
home in a dream); and the moon whose waning the moonlight-wager aetiology explains.
**Honesty note**: the primary attestation of the wager is Plutarch, whose players are Hermes
and *Selene*; naming the Egyptian moon god Khonsu as the loser is the standard modern
retelling of the Egyptian role, not an ancient text — recorded as such in
myth_egyptian_moonlight_wager. **Axes**: wrath 4 (the butcher under the healer's skin);
pettiness 3 (still sore about the light); risk_appetite 5 (the one god with an attested
divine-asset gambling loss — eager Forsaken host, per the §5 amendment); fidelity 3,
generosity 3, strictness 3 (middle of the deck — he lends, he collects). IP caution:
Marvel's "Khonshu" (Moon Knight) is a protected design; the god is traditional. Citations:
ancientegyptonline.co.uk/khonsu; Wikipedia Bentresh stela; Plutarch §12 as above.

### Set (egyptian_set) — god, patron, Forsaken lens
Storm, desert, chaos, and foreign lands; murderer of Osiris **by rigged party game**
(Plutarch §13: the chest measured to Osiris's body, promised at a banquet to whoever fit
it, slammed shut by 72 conspirators — the first crooked table in recorded myth); loser of
the 80-year succession tribunal (Chester Beatty I); then loser of everything else — after
Dynasty XX his cult was eradicated, his image execrated, his name attached to foreign
oppressors, worship surviving only in remote oases. **And yet**: the Amduat/Bremner-Rhind
tradition keeps him on the sun barque's prow, the only god strong enough to spear Apep
nightly. That triangle — cheat, bankrupt, indispensable — is the Forsaken arc in one god.
**Axes**: pettiness 5 and wrath 5 (fratricide + eight decades of spite litigation);
strictness 2, generosity 2 (few rules, fewer gifts); fidelity 2 (kin-betrayer — sells
contracts); risk_appetite 5 (bet the throne on contest after contest; would absolutely go
all-in). Citations: Plutarch §13; Contendings; Wikipedia Set + Discentes (UPenn) + Charles
Univ. thesis on the demonization; Bremner-Rhind via Wikipedia Apophis.

### Osiris (egyptian_osiris) — god, patron, Forsaken table host
Murdered, dismembered into pieces, reassembled by Isis/Nephthys/Anubis, and enthroned as
First of the Dead — the god who **already lost an existence stake once and came back
holding the house**. Green-skinned lord of grain and resurrection; presiding judge of the
weighing. BD 175 names him one of two survivors of Atum's end of creation. His cult taboo
(Plutarch §18: the fish that ate his member) gives the deal sheet its one comedy taboo.
**Axes**: wrath 1, pettiness 1 (his side of the feud is prosecuted entirely by Isis and
Horus — he never retaliates); generosity 4 (grain and afterlife for all who pass);
strictness 3 (a judge, but the fair kind); fidelity 5 (the loyal king/husband, keeps his
office eternally); risk_appetite 2 (took exactly one party wager in his existence and it
killed him — he has learned; hence host, not gambler, at the Forsaken table). Citations:
Plutarch §§13–19; Pyramid Texts resurrection complex (Faulkner); BD 125/175 as above.

### Anubis (egyptian_anubis) — god, patron, dealer
Jackal-headed lord of embalming and the necropolis; inventor of mummification (first
performed on Osiris — the Imiut epithet); psychopomp; **Guardian of the Scales** who
performs the weighing in BD 125 while Thoth records and Ammit waits. In the Tale of Two
Brothers the elder brother bears his name (recorded as a namesake/aspect relation, not an
identity claim). protection_home in his domain list encodes tomb-guardianship — the closest
controlled-vocabulary term; flagged for the Wave-4 vocab review rather than ad-hoc extension.
**Axes**: strictness 5 (the 42-point auditor); pettiness 1, wrath 2 (punishes desecration,
nothing else); generosity 3; fidelity 5 (defected from nothing — the eternally reliable
officiant); risk_appetite 2 (auditors don't gamble). Citations: Wikipedia Anubis +
worldhistory.org (imiut, Opening of the Mouth, Guardian of Scales); BD 125 sources above.

### Sekhmet (egyptian_sekhmet) — god, patron, table boss
The Powerful One — lioness Eye of Ra, plague-bearer ("seven arrows" tradition; Pinch 2002),
whose one deployment nearly ended the species: the Destruction of Mankind (Book of the
Heavenly Cow) — stopped not by force but by 7,000 jars of beer dyed with red ochre, drunk
as blood. Her priesthood doubled as physicians: burn and cure are the same hand. The
appeasement shape of her cult (festivals of drunkenness) becomes her taboo/favor logic and
her Red Flood boss design (win by feeding the rage, never by out-damaging it). **Axes**:
wrath 5 (the rubric's own extinction-event anchor); strictness 4 (a sent weapon follows its
order past its recall); generosity 2; pettiness 2 (nothing personal — that's the horror);
fidelity 3; risk_appetite 4 (all-out is her only speed). Citations: worldhistory.org +
the-past.com + brewminate on the Heavenly Cow; Wilkinson 2003.

### Bes (egyptian_bes) — god, patron, dealer
Grimacing dwarf protector of the household, mothers, and children — apotropaic "wards off
evil and bad luck" (worldhistory.org), the god of every class's kitchen wall, knife handle,
and mirror. He guards by being louder and uglier than the demons: dancing, drumming,
tongue out. **Myth base (honest)**: no narrative myth survives; his one attested story-role
is in the temple program of the Return of the Distant Goddess at Philae's Hathor temple,
where his music and dancing flatter the raging goddess home (reliefs of Bes with tambourine
and harp; ASOR photo collection). The census luck_gambling flag rests on the apotropaic
good-luck function, not on any dice myth — recorded as data, not invented narrative.
**Axes**: generosity 5 and fidelity 5 (the unpaid full-time bodyguard of every family);
strictness 1, pettiness 1; wrath 2 (scares, rarely destroys); risk_appetite 3 (scrappy
tavern gambler). Citations: Wikipedia Bes; worldhistory.org/Bes/; uncoveringsound + ASOR
(Philae); egyptianmuseum.org deities-bes.

### Shai (egyptian_shai) — god, patron, house odds-setter
Fate personified — from šꜣ, "to ordain": born beside each person, allotting lifespan and
fortune, present again at the weighing (Papyrus of Ani vignette: Shai stands by the balance
with Renenutet and Meskhenet). Depicted as a man, sometimes a cobra or a human-headed birth
brick. The Instruction of Amenemope's fatalism ("none can ignore Shai") frames him as the
one authority even gods route around rather than overrule. Minor cult, major office —
influence 1 with a straight face, per the Zababa anchor. **Axes**: strictness 5, fidelity 5
(fate is absolute and never leaves you); pettiness 1, wrath 1 (the ledger balances without
anger); generosity 3 (allotments are sometimes kind); risk_appetite 2 (never gambles — he
already knows; his table appearances are settlements, which the deal-sheet generator should
read as maximally boring bets). Citations: egypt-museum.com Papyrus of Ani weighing;
ancientegyptonline.co.uk/shai; Global Egyptian Museum glossary §346.

### Renenutet (egyptian_renenutet) — god, patron, quiet investor
Cobra goddess of the harvest and of nursing — "Lady of the Granary" with a real temple cult
at Medinet Madi (Faiyum) — and **the namer**: she gives each newborn its secret true name
and with it its fortune; Shai's consort in the economy of luck; attends the weighing in the
Ani vignette. She is the diegetic owner of the game's epithet system — the goddess whose
office stamps names onto contestants. A cobra remains a cobra: her protective glare was
held to subdue enemies (Wilkinson 2003), hence wrath 3. **Axes**: generosity 4 (the
nourisher); strictness 3; pettiness 2; fidelity 4; risk_appetite 2 (granary keepers bank,
not bet). Citations: ancientegyptonline (Shai/Renenutet pair); egypt-museum Ani vignette;
Wilkinson 2003 (Medinet Madi, naming role).

### Atum (egyptian_atum) — god, patron, the scheduled Forsaken host
The self-created first god of Heliopolis, "Lord of Totality", the evening sun — and the
author of Egyptian eschatology's single most casino-shaped text, **BD 175**: he announces
he will one day destroy all he has made and return creation to the primeval flood,
surviving as a serpent with Osiris beside him. A god whose existence-stake all-in is
**already on the books** — the §5 amendment's stage-unlock hook, ready-made. Domain note:
`chaos` records the Nun-return and serpent form only; he is otherwise order's origin.
**Axes**: risk_appetite 5 (the pre-declared total wager); strictness 4 (completion is his
nature — he "completes himself"); pettiness 1 (the end of all things has no time for
squabbles); wrath 3; generosity 2 (aloof and total — gives rarely); fidelity 4 (keeps
exactly one companion into the end). Citations: Global Egyptian Museum glossary §79;
Fitzwilliam Museum BD pages; Faulkner BD 175.

### Bata (egyptian_bata) — hero, contestant legend
Protagonist of the Tale of Two Brothers (P. D'Orbiney, BM EA 10183 — one of the world's
oldest complete prose tales, PD in Moldenke's edition): the wronged herdsman who hides his
heart in the cedar blossom, is betrayed, dies, and returns through serial transformations —
bull, persea trees, splinter-conception, crown prince — until he is king and his betrayer
is judged. External-heart phylactery, comeback chain, false-accusation courtroom: three
game systems in one PD text. **Axes**: fidelity 5 (keeps innocence and oath through every
death); risk_appetite 4 (bets his life on each transformation); wrath 3 (methodical, not
hot, revenge); strictness 3, generosity 3, pettiness 2. Citations: Wikipedia Tale of Two
Brothers; British Museum EA 10183 record; Moldenke 1898 (archive.org).

### Apep (egyptian_apep) — fiend, table boss
The world-ending serpent who ambushes the solar barque nightly and is speared, bound, cut,
and burned nightly (Book of Overthrowing Apep, P. Bremner-Rhind BM EA 10188 — an execration
liturgy performed daily), only to reform. Never worshipped — the only major Egyptian power
whose entire cult is his destruction. Set spears him from the prow; Selket binds him. His
census forsaken_candidate flag is honored in the casino frame as the dark mirror of the
existence stake: the thing that is unmade daily and returns, and therefore the escrow that
swallows gods who lose theirs. Full boss sketch in the record (colossal; suffocation /
poison / dissolution; ritual-execration win condition, never a damage race). **Axes**: an
honest cartoon — wrath 5, risk_appetite 5, everything relational at 1, pettiness 3 (he
only ever attacks the same boat). Citations: Wikipedia Apophis; worldhistory.org/Apophis/.

### Ammit (egyptian_ammit) — fiend, table boss / repo-agent
"Devourer of the Dead": crocodile head, lion forequarters, hippo hindquarters — the three
biggest man-killers the Egyptians knew, composited into a consequence. She waits beneath
the scales in BD 125; hearts heavier than the feather go to her, and that is the second,
final death. She has no cult, no temple, no appetite beyond the verdict — which makes her
the casino's one perfectly honest operator: she cannot take what the ledger doesn't
condemn. Boss design in the record (sin-weight targeting; courtroom rebalancing win).
**Axes**: strictness 5, fidelity 5, wrath 2 (nothing personal), generosity 1, pettiness 1,
risk_appetite 1. Citations: Wikipedia Ammit; ROM BD 125 fragment; egypt-museum Ani pages.

### Medjed (egyptian_medjed) — spirit, masked VIP
Attestation, complete: BD 17b names among the House of Osiris "Medjed — the Smiter — who
shoots with his eye, yet is unseen"; the Greenfield Papyrus (sheet 76) draws a conical
covered figure with only eyes and feet. That's all antiquity left us — and the 2012 Mori
Art Museum / Fukuoka exhibitions turned that sheet-ghost into a Japanese internet icon,
games character, and plush (Salvador 2017, Journal of Geek Studies). Personality axes are
therefore thin-evidence defaults (flagged); the design content is the mystery itself plus
the diegetically-imported merch career. No myth_refs — no narrative exists to declare;
requirement binds patron gods and heroes only. Citations: Wikipedia Medjed; Salvador 2017
(jgeekstudies.org); historicmysteries.com.

### Book of Thoth (egyptian_book_of_thoth) — artifact, cursed item seed
From Setne I (P. Cairo 30646, demotic; PD tr. Griffith 1900, *Stories of the High Priests
of Memphis*): Thoth's own book — two spells, one to understand the speech of animals and
one to see the gods — locked at Coptos in nested chests (iron → bronze → wood →
ivory-and-ebony → silver → gold) wrapped by a deathless serpent. Naneferkaptah takes it and
Thoth's audit takes his family; Setne steals it from the tomb and the dead owner challenges
him to a board game (unnamed in text; senet by scholarly comparison) where each loss
hammers Setne into the ground — he escapes only by amulet, and is finally made to return
the book in penitence. The record's item seed reproduces this loop verbatim. Personality
axes encode the curse's behavior (its lure, its audit, its homing fidelity) as generator
input — noted so Wave 5 doesn't read them as characterization of a person. ip_status:
public_domain_literary per census flag (ancient literary papyrus, PD translation).
Citations: attalus.org/egypt/setne.html; worldhistory.org Setna I; Griffith 1900.

## 5. Forward-declared myth records (all verified this session; Wave 3 writes them)

- **myth_egyptian_moonlight_wager** — Thoth wins 1/70 of the moon's light at draughts;
  five days built from the pot (Plutarch §12; Khonsu-as-loser = modern standard gloss,
  Selene in the primary — Wave 3 must carry this note). Participants: thoth, khonsu.
- **myth_egyptian_chest_of_set** — the rigged party game that killed a god (Plutarch §13).
  Participants: set, osiris.
- **myth_egyptian_contendings_of_horus_and_set** — the 80-year tribunal; Neith's letter;
  hippo duel; stone boat (P. Chester Beatty I). Participants: set, thoth (+ horus, neith — follow-up batch).
- **myth_egyptian_rising_of_osiris** — dismemberment, reassembly, first embalming,
  enthronement below (Plutarch §§13–19; Pyramid Texts). Participants: osiris, set, anubis.
- **myth_egyptian_weighing_of_the_heart** — BD 125: scales, feather, 42 declarations,
  Ammit's second death; Shai and Renenutet in the Ani vignette. Participants: anubis,
  ammit, thoth, osiris, shai, renenutet.
- **myth_egyptian_destruction_of_mankind** — the Eye unleashed; the red-beer flood (Book
  of the Heavenly Cow). Participants: sekhmet (+ ra, hathor — follow-up).
- **myth_egyptian_nightly_execration_of_apep** — the barque ambush and the daily ritual
  unmaking (Bremner-Rhind; Amduat). Participants: apep, set (+ ra).
- **myth_egyptian_bentresh_healing** — Khonsu's statue exorcises the princess of Bakhtan
  and dreams its way home (Bentresh Stela). Participants: khonsu.
- **myth_egyptian_cannibal_hymn** — Khonsu the butcher of lords (PT 273–274).
  Participants: khonsu.
- **myth_egyptian_end_of_creation** — Atum's scheduled unmaking; two serpents in the flood
  (BD 175). Participants: atum, osiris.
- **myth_egyptian_two_brothers** — heart in the cedar; three deaths, one throne
  (P. D'Orbiney). Participants: bata, anubis (namesake).
- **myth_egyptian_setne_and_the_book** — the vault, the audit, the tomb board game with
  sinking stakes (Setne I). Participants: book_of_thoth, thoth.
- **myth_egyptian_return_of_the_distant_goddess** — the raging Eye danced home; Bes's
  attested festival role (Philae reliefs). Participants: bes (+ hathor/tefnut — follow-up).
- *Lead only (no extracted participant)*: **the secret name of Ra** (Turin papyrus, Budge
  PD tr.) — verified this session; belongs to the Isis/Ra follow-up batch.

## 6. Skipped candidates and follow-up recommendations

Skipped under the 15-cap, in priority order for a follow-up batch — all zero-risk to
re-find: **Ra, Isis, Horus, Bastet, Hathor** (the famous five; deliberately deprioritized
per the recognition-spread + flag-priority instruction — every luck_gambling and
forsaken_candidate flag IS in this batch), then Ma'at, Amun, Ptah, Sobek, Neith, Khnum,
Nut, Nephthys, Wadjet, Wepwawet, Taweret, Heka; beasts/artifacts: Great Sphinx, Bennu, Eye
of Horus, Ankh, Scales of Ma'at. **Serapis** skipped on purpose: an engineered syncretic
god, best handled by Wave 4 alongside the Greek batch (syncretic_group osiris_serapis).
Two relations in this batch forward-reference **egyptian_ra** (Sekhmet eye_of, Apep
eternal_enemy_of) — dangling until that follow-up, flagged for Wave 4. D-4 exclusions
honored per census closed-notes (Imhotep, Setne-as-person, deified pharaohs); the Setne
cycle's divine artifact is retained, its human protagonist is not.
