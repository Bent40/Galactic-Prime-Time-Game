# Hindu tradition — Wave 2 extraction dossier

*Extraction batch of 2026-07-18, per `docs/design/mythology-research-spec.md` (RULED). 15
entities from the Wave-1 census pool of 41. Calibration: `hindu_ganesha` is a FROZEN
Wave-0 entity and is reproduced exactly (influence 5 / recognition 4 / living / vvip).
All other scores argued against the six frozen anchors below their sections.*

## 1. Tradition overview — the casino-frame angle

Hinduism is a living major religion (~1.2B adherents; census record `hindu`,
source_quality 5), which makes this the deepest-bankroll pantheon on the floor:
influence ceiling 5, and four of the seven patron-capable gods extracted here sit at
influence 5. Depiction policy v2 (spec §3.3, RULED 2026-07-18) applies: every deity
carries `depiction_risk: living` **as recorded data**, not a gate; the register is
respectful pop-culture mythological fiction.

What makes this tradition uniquely valuable to *this* game: **the gambling corpus is
native and enormous.** No other Wave-2 tradition has (a) a hymn in its oldest scripture
narrated by a ruined gambler (Rig Veda 10.34, the "Gambler's Lament", Griffith tr., PD
— the dice are vibhitaka nuts, "the brown ones born of the tall tree"); (b) a supreme
god who lost everything at dice to his wife, whose game decreed a national gambling
night (Diwali); (c) a national epic whose central catastrophe is a rigged dice match;
and (d) a full possession-narrative where a demon lives *inside* the dice. The Cosmic
Casino frame is nearly diegetic here. Selection therefore skews hard toward the
luck_gambling/forsaken flags — all 8 luck_gambling-flagged census candidates are in
this batch.

**Proposed pantheon modern-life attribution** (canon §4 invites one per pantheon;
OWNER TO BLESS): the Hindu table plays as *the casino's oldest family conglomerate* —
a sprawling billion-member family business where every cousin runs a division, the
founder (Brahma) can barely afford a table, and the family dice night once nearly
ended the world. Used lightly in the temperament lines.

**Primary sources used throughout** (source ladder §7): Ganguli's complete Mahabharata
(PD, sacred-texts.com); Griffith's Rig Veda (PD); Wilson's Vishnu Purana (PD);
Pargiter's Markandeya Purana incl. Devi Mahatmya (1904, PD); Burton's *Vikram and the
Vampire* (1870, PD, Project Gutenberg #2400); wisdomlib.org's Skanda Purana
translation; Wikipedia strictly as index with claims verified one level down. Web
verification ran 2026-07-18 through the session proxy; the specific searches and
verified pages are cited per entity.

## 2. Selection rationale (vs. the 41-candidate pool)

- **Slots:** 7 patron-capable gods, 2 heroes, 1 villain, 3 fiends, 1 spirit, 1 artifact = 15 (mix per spec §6, adapted: villain counted with heroes-tier narrative figures, fiends carry the beast/fiend quota).
- **Every luck_gambling flag taken** (8/8): Ganesha, Lakshmi, Shani, Kubera, Alakshmi, Shakuni, Kali (dice-demon), Syamantaka.
- **Forsaken candidates taken** (8/11): Shiva, Parvati, Alakshmi, Yudhishthira, Nala, Shakuni, Rahu, Kali (dice-demon). Skipped: Brahma, Indra, Draupadi (below).
- **Skipped famous names, honestly:** Vishnu, Krishna, Rama, Hanuman, Durga, Kali (goddess), Saraswati, Kartikeya, Yama, Narada, Ravana, Garuda, Shesha, Nandi, Kamadhenu, Apsaras, Churel, Sudarshana, Vajra, Amrita, Savitri, Brahma, Indra, Draupadi. The tradition easily supports a second 15-entity batch; see `notes` for the recommended follow-up shortlist (Draupadi in particular has a genuine living Tamil cult — Draupadi Amman — and was cut only for slot pressure).

## 3. Entities

### Ganesha (`hindu_ganesha`) — FROZEN calibration entity
**Scores:** influence 5 / recognition 4 / living / vvip — reproduced exactly from
`calibration.json`. **Sources:** Mahabharata Adi Parva §1 (Ganguli, PD) for the
scribe/broken-tusk episode; Shiva Purana for the race around the world; Brahma
Vaivarta Purana + Puranic Chaturthi tradition for the moon curse (verified via
en.wikipedia.org/wiki/Mythological_anecdotes_of_Ganesha and pujaservices.com, both
checked 2026-07-18). Census one-liner ("the house's favorite opening bet") retained as
the design angle: he is invoked before every venture, so every table's opening ritual
already belongs to him.
**Personality rationale:** generosity 4 (remover of obstacles, cheaply pleased with
modak); strictness 2 (famously accessible, minimal protocol); pettiness 3 (he cursed
the *moon* for laughing at him — grudge-with-style); wrath 2 (rarely escalates);
fidelity 4 (circled his parents as "his whole world"); risk_appetite 2 (won the race
around the world by thinking, not sprinting).
**Myth leads declared:** `myth_hindu_ganesha_scribe_broken_tusk` (he tore off his own
tusk to keep writing the Mahabharata — Adi Parva §1), `myth_hindu_ganesha_race_around_the_world`,
`myth_hindu_ganesha_moon_curse` (source of the False-Accusation debuff; links to Syamantaka).

### Shiva (`hindu_shiva`)
**Scores:** influence 5 (principal deity, Shaivism — Ganesha anchor), recognition 5
(global household name; census provisional 5) → vvip. **Sources:** the dice-game
myth verified directly in the Skanda Purana translation ("Śiva Loses to Pārvatī in a
Game of Dice", wisdomlib.org/hinduism/book/the-skanda-purana/d/doc365984.html) — he
staked and lost ornaments and, in the folk continuation, everything down to his
clothes; Parvati invoked Lakshmi before the game; Parvati decreed Diwali-night
gambling auspicious (also Padma Purana; cross-checked via talkingmyths.com and
sanatangyan.com, all fetched 2026-07-18). The Ellora caves carry a famous relief of
the game (note: Ellora, not Elephanta as I first assumed — corrected by the search).
Halahala poison-drinking and the churning: Mahabharata Adi Parva (Ganguli, PD) +
Vishnu Purana I.9 (Wilson, PD). Daksha's sacrifice destroyed: Vayu/Bhagavata Purana
and Mahabharata (well attested).
**Personality rationale:** generosity 5 (Bholenath, "easily pleased" — grants boons
recklessly, even to demons); strictness 2 (accepts any sincere offering; no
protocol); pettiness 2 (above grudges — his violence is eruption, not scheming);
wrath 5 (burned Kama to ash; Daksha's yajna; the Tandava); fidelity 4 (carried Sati's
corpse across the world in grief); risk_appetite 5 (kept doubling down at dice until
his clothes were on the table; drank the world's poison on the spot). Risk 5 + the
loss myth = the batch's flagship **forsaken_host**.
**Myth leads:** `myth_hindu_shiva_parvati_dice` (heroic_epic-grade wager story; the
casino's founding myth in this pantheon), `myth_hindu_samudra_manthana` (world_myth),
`myth_hindu_daksha_yajna`.

### Parvati (`hindu_parvati`)
**Scores:** influence 5 (principal goddess pan-India; Ganesha anchor), recognition 3
(census 3 — mythology-curious tier abroad) → vvip. **Sources:** dice game + Lakshmi
assist + Diwali decree as under Shiva (Skanda Purana ch. 34, verified at wisdomlib);
her austerities to win Shiva: Kalidasa's Kumarasambhava canto V (PD translations) and
Shiva Purana; Annapurna (she withdraws, the world starves, she feeds Shiva at Kashi):
Kashi-khanda tradition of the Skanda Purana — attestation is Puranic/late, flagged
honestly on the myth lead. Durga as her battle-form: standard Shakta identification
(Devi Mahatmya frame; used for the Mahishasura relation with the "as Durga" type).
**Personality rationale:** generosity 3; strictness 3 (expects the commitment she
herself modeled); pettiness 3 (the dice game is one long marital needling match);
wrath 4 (provoked, she *becomes* the most destructive being in the cosmos); fidelity
5 (eons of tapas across two lifetimes for one spouse — the axis anchor for 5);
risk_appetite 4 (challenged the god of destruction at his own game, with a banker
pre-arranged — eager, calculated gambler; §5 semantics make her an eager Forsaken
host, hence the role).
**Myth leads:** `myth_hindu_shiva_parvati_dice`, `myth_hindu_parvati_tapas`,
`myth_hindu_annapurna` (weakest attestation of her three; Kashi-khanda tradition).

### Lakshmi (`hindu_lakshmi`)
**Scores:** influence 5 (worshipped in virtually every household/business at Diwali),
recognition 4 (census 4 — Ganesha's visual tier, not Zeus's) → vvip. **Sources:**
churning-of-the-ocean birth: Vishnu Purana I.9 (Wilson, PD) and Mahabharata Adi Parva;
her departure from Indra's heaven after Durvasa's garland is spurned — the myth
template for patron abandonment — Vishnu Purana I.9 (Wilson, PD); her role staking
Parvati in the dice game: Skanda Purana ch. 34 (wisdomlib, verified). Epithet
Chanchala ("the fickle") is traditional and load-bearing for the fidelity axis.
**Personality rationale:** generosity 5 (wealth is her substance); strictness 4 (a
long, specific list of what drives her out: sloth, filth, boasting, unpaid debt);
pettiness 2 (she doesn't curse — she *leaves*); wrath 2 (her punishment is absence);
fidelity 2 (Chanchala — restlessness is her defining trait; lowest buy-out resistance
of any influence-5 patron, which is a deliberate, myth-true deal-sheet hook); 
risk_appetite 3 (patroness of Diwali gambling, but only ever bets the favorite).
**Myth leads:** `myth_hindu_samudra_manthana`, `myth_hindu_lakshmi_departs_heaven`,
`myth_hindu_shiva_parvati_dice`.

### Shani (`hindu_shani`)
**Scores:** influence 4 — dedicated living cult at genuine scale: Shani Shingnapur
(Maharashtra; shanidev.com verified), Shani temples and Saturday observance across
India; below the >100M principal tier, matching the Amaterasu anchor (living
significant practice). Recognition 2 (census 2) → vvip (influence ≥4). **Sources:**
the Brahma Vaivarta Purana variant where baby Ganesha's head falls off under Shani's
reluctant gaze — verified via en.wikipedia.org/wiki/Mythological_anecdotes_of_Ganesha
and pujaservices.com (both cite BVP, Ganapati Khanda); Shani Mahatmya (Marathi
devotional text) for the trial of King Vikramaditya (seven-and-a-half years of ruin
endured, then restitution) — attestation is devotional-literary, flagged on the lead.
**Personality rationale:** generosity 2 (pays out only what is earned, after the
ordeal); strictness 5 (the karmic auditor — most taboo-dense deal sheet in the
batch); pettiness 1 (nothing personal, ever — he even warned Parvati about his gaze);
wrath 4 (the gaze that removes heads/fortunes when forced); fidelity 5 (serves every
sentence to the day; never sells a contract); risk_appetite 1 (the slowest planet;
the house's counterweight to Shakuni). The "dealer who cannot be tipped" inverts the
canon's dealer-tipping rule as deliberate flavor.
**Myth leads:** `myth_hindu_shani_gaze_ganesha`, `myth_hindu_shani_trial_of_vikramaditya`.

### Kubera (`hindu_kubera`)
**Scores:** influence 3 (continuous folk invocation — Dhanteras with Lakshmi, some
temples — but thin dedicated cult), recognition 2 → normal table (mechanical §3.5:
influence 3 needs recognition ≥3 for VIP; the gods' own banker playing the normal
tables is good irony and the table system owns final placement anyway). **Sources:**
Lokapala of the north, king of yakshas, treasurer of the gods: standard epic/Puranic
(Mahabharata, Ramayana — Ganguli/Griffith PD). The Venkateswara wedding loan — Vishnu
borrows a fortune from Kubera for his marriage to Padmavati, repayable with interest
until the end of Kali Yuga, with Tirupati devotees' offerings understood as interest
payments — verified across multiple 2024–25 accounts (tirumalahills.org,
thedailyjagran.com, mystreal.com; rooted in the Venkatachala Mahatmya tradition).
**Syncretic note for Wave 4:** Kubera = Buddhist Vaiśravaṇa/Jambhala (the Buddhist
census already lists Vaisravana) — `syncretic_group: kubera_vaishravana` declared.
**Personality rationale:** generosity 3 (lends freely — *lends*, not gives);
strictness 4 (terms, deadlines, collateral); pettiness 3 (yaksha vanity — famously
showed off his wealth); wrath 2; fidelity 4 (a banker honors contracts);
risk_appetite 2 (the house never gambles).
**Myth lead:** `myth_hindu_kubera_venkateswara_loan`. (The popular Kubera-invites-
Ganesha-to-a-feast humbling tale was left OFF the myth list — I could not pin a
primary attestation; recorded here as color only.)

### Alakshmi (`hindu_alakshmi`)
**Scores:** influence 2 — judgment call, argued: the living tradition acknowledges
her continuously but *only to expel her* (Diwali expulsion rites; the lime-and-chili
ward hung outside shops is specifically anti-Alakshmi), and the divinity economy
reads influence as worship-*wealth* — an apotropaic negative cult banks nothing.
Recognition 1 (specialists) → normal, mythic tier — precisely the canon's collector
thrill. **Sources:** born of the churning of the ocean before/with Lakshmi (Padma
Purana; poison-origin variants), identified with Jyestha ("the Elder"), referenced in
the Sri Sukta khila as Lakshmi's elder sister whose ruin is prayed for
("alakṣmīr me naśyatāṁ") — verified via hinduismfacts.org, justkalinga.com and the
Jyestha/Alakshmi index articles (consumer-grade sites used only as index; the Sri
Sukta line and Padma Purana attribution cross-checked). Jyestha's traditional
iconography: donkey mount, crow banner, broom.
**Personality rationale:** generosity 1 (owns nothing to give — she takes);
strictness 2 (trivially easy to attract: just let things rot); pettiness 5 (jealousy
of her sister is her entire cosmology); wrath 3; fidelity 4 (dark joke, myth-true:
she *never* leaves voluntarily — entire rituals exist to pry her off you); 
risk_appetite 5 (nothing left to lose). **Forsaken lens (§5 amendment):** the
textbook desperate-god host — a goddess with zero positive worship inside the
richest living religion on the floor; staking her own existence to finally out-earn
her sister is completely in-character. Flagged accordingly.
**Myth lead:** `myth_hindu_alakshmi_origin_expulsion`.

### Nala (`hindu_nala`) — hero
**Scores:** influence 1 (no cult; Väinämöinen anchor — epic fame without worship),
recognition 2 → normal. **Sources:** the whole arc is one continuous PD primary: the
Nalopakhyana, Mahabharata Vana Parva (Ganguli tr., sacred-texts.com/hin/m03/m03077.htm,
verified): the dice-demon Kali, rejected by Damayanti, waits twelve years for a lapse
in Nala's purity, possesses him, and ruins him throw by throw; Nala loses the kingdom
to his brother Pushkara, wanders as Bahuka (charioteer and master cook), serves King
Rituparna, and trades his horse-lore (ashva-hridaya) for Rituparna's **aksha-hridaya
— the Heart of Dice** — demonstrated when Rituparna counts a vibhitaka tree's fruit
at a glance; the knowledge expels Kali into the vibhitaka tree, and Nala wins the
kingdom back in a single rematch. The golden swan messenger is from the same text.
**Personality rationale:** generosity 4 (model king; fed others even in exile);
strictness 3; pettiness 1; wrath 2; fidelity 4 (his abandonment of Damayanti is
explicitly the demon acting, not the man — the text is at pains to say so);
risk_appetite 4 (won his kingdom back on one all-in throw — but only after acquiring
the skill; calculated audacity, not compulsion).
**Myth lead:** `myth_hindu_nala_kali_dice` (heroic_epic; the single best
lose-everything-win-it-back template in the corpus).

### Yudhishthira (`hindu_yudhishthira`) — hero
**Scores:** influence 1 (Väinämöinen anchor; the epic is sacred but he has no cult of
note — 'living' recorded for the epic's active sanctity per census flag), recognition
2 → normal. **Sources:** all Ganguli PD: Sabha Parva (the dyuta — he stakes wealth,
kingdom, brothers, himself, then Draupadi, against Shakuni's unbeatable dice; the
assembly-hall humiliation guarantees the war); Vana Parva (Yaksha Prashna — his
brothers lie dead by the lake until he answers the yaksha's riddles: riddle-play with
lives as stakes); Drona Parva (his chariot rides above the earth until the
Ashwatthama half-lie grounds it); Mahaprasthanika/Svargarohana Parva (he refuses
heaven without the dog, who is Dharma himself).
**Personality rationale:** generosity 4; strictness 4 (rigid dharma); pettiness 1;
wrath 1 (canonically anger-free — forgave everything); fidelity 5 (the dog; the
brothers; the axis anchor for 5); risk_appetite 4 — pathological in one channel only:
the kshatriya code forbids refusing a challenge, and the house knows it. That split
(cautious everywhere, helpless at the table) is the deal-sheet's most exploitable
legend profile.
**Myth leads:** `myth_hindu_yudhishthira_dice_game` (heroic_epic, arguably
world_myth-adjacent for this game's purposes), `myth_hindu_yaksha_prashna`,
`myth_hindu_yudhishthira_final_journey`.

### Shakuni (`hindu_shakuni`) — villain
**Scores:** influence 1, recognition 2 → normal. Depiction_risk **low**, not none:
one documented active temple exists — Mayamkottu Malancharuvu Malanada, Pavithreswaram
(Kollam, Kerala), where the Kuravar community venerates him with toddy, silk, and
tender-coconut offerings at a granite throne said to be his (verified:
nativeplanet.com, hindu-blog.com, newsgram.com, 2026-07-18). Not enough for influence
2, but enough to record awareness. **Sources:** Sabha Parva (Ganguli, PD) for the
rigged game — Shakuni plays on Duryodhana's behalf and never loses a throw. **Honesty
flag:** the famous "dice carved from his father's bones" detail is late/folk
tradition and TV-serial canon, NOT the critical epic — usable as flavor, cited as
folk variant only (census's "some say" retained).
**Personality rationale:** generosity 1; strictness 2; pettiness 5 (a
decade-spanning revenge project executed through a board game); wrath 3; fidelity 4
(to his grudge and his family, unto death at Sahadeva's hands); risk_appetite 2 —
the batch's great inversion: the most famous gambler in the tradition **never takes
a real risk**; he only plays games he has already fixed. Forsaken flag per census:
his entire existence was one wager on vengeance.
**Myth lead:** `myth_hindu_yudhishthira_dice_game` (shared record; he is its engine).

### Kali, the dice-demon (`hindu_kali_dice_demon`) — fiend
**Disambiguation, load-bearing:** Sanskrit **Kali (कलि)**, spirit of the losing Kali
Yuga and demon of the dice — NOT the goddess Kālī (काली), who remains in the census
pool. **Scores:** influence 1 / recognition 1 — the Zababa-anchor honest floor;
mythic tier. **Sources:** Nalopakhyana (Ganguli, PD, verified at sacred-texts) for
the possession arc and the expulsion into the vibhitaka tree; Rig Veda 10.34
(Griffith, PD) establishes vibhitaka nuts as the actual dice of the era — hence his
icon. **Personality rationale:** generosity 1; strictness 1; pettiness 5 (twelve
years hiding inside a man to avenge a marriage rejection — the pettiest sustained act
in the corpus); wrath 4; fidelity 1 (a parasite by definition); risk_appetite 5 (he
*is* the bad bet). Boss design in `game_hooks` maps his possession mechanic straight
onto the rulebook's Forced Action d6 and keeps the discoverable win non-damage
(identify vessel → expel → cleanse), per the bosses-are-never-damage-races rule.
**Myth lead:** `myth_hindu_nala_kali_dice` (shared).

### Rahu (`hindu_rahu`) — fiend
**Scores:** influence 3 — genuinely living propitiatory practice: Rahu kalam, a daily
~90-minute inauspicious window, is observed across South India (drikpanchang.com,
prokerala.com verified); Srikalahasti (Andhra Pradesh) is THE Rahu-Ketu kshetra with
daily paid Rahu-Ketu pujas and stays open during eclipses (srikalahastitemple sites +
Wikipedia, verified). Fear-cult, not principal worship — 3, not 4. Recognition 2 →
normal (mechanical: influence 3 + recognition 2). **Sources:** the beheading —
Svarbhanu the asura sneaks into the amrita distribution line, Surya and Chandra
inform, Mohini/Vishnu decapitates him with the Sudarshana chakra, but the nectar has
passed his throat: the head (Rahu) and body (Ketu) live on, and the head eternally
swallows the sun and moon in revenge — Mahabharata Adi Parva, Astika section
(Ganguli, PD), also Vishnu Purana. Eclipse etiology: the swallowed light escapes
through the open neck — which is the boss design's discoverable win, straight from
the myth. **Personality rationale:** generosity 2; strictness 2; pettiness 5 (an
eternity of eclipse-grudge against two snitches); wrath 4; fidelity 3; risk_appetite
5 (crashed the highest-stakes pot in cosmic history and paid with his body). Forsaken
lens per census: a being who was already unmade once *at the gods' own table* and
survived it — exactly the §5 "wagered/unmade" profile.
**Myth lead:** `myth_hindu_rahu_beheading`.

### Mahishasura (`hindu_mahishasura`) — fiend
**Scores:** influence 1 (a slain adversary, not a worship object; the small modern
Asur/Santal counter-commemoration — Hudur Durga mourning — is noted but is
commemoration, below the folk-practice bar), recognition 2 (annually depicted in
Durga Puja iconography worldwide; census flags 'living' for that active festival role,
recorded) → normal. **Sources:** Devi Mahatmya (Markandeya Purana; Pargiter tr. 1904,
PD) for the battle and the shapeshifting sequence (buffalo → lion → man → elephant →
buffalo, beheaded mid-transformation); the boon — invulnerable to any male god or man,
hence only a woman can kill him — Devi Mahatmya frame + Devi Bhagavata Purana
(verified via multiple index sources 2026-07-18); Durga created from the pooled
energies and weapons of all the gods (same texts; the census one-liner). **Boss
design:** the boon IS the discoverable win condition (female contestant or the
party-forged 'Assembled Goddess' buff mirroring Durga's creation); final phase
immune otherwise — never a damage race. **Personality rationale:** generosity 1;
strictness 2; pettiness 3; wrath 5 (conquered heaven for spite); fidelity 2;
risk_appetite 4 (bought invulnerability with a scope exclusion he chose himself —
hubris as a bad contract). **Sensitivity:** play tragedy-grade, never mocking (the
counter-commemoration communities are real).
**Myth lead:** `myth_hindu_mahishasura_slaying` (world_myth-grade in Shakta
tradition — it is Navratri's founding story).

### Vetala (`hindu_vetala`) — spirit
**Scores:** influence 1 / recognition 2 → normal. Depiction_risk upgraded none → **low**
on my own verification: Betal/Vetal is an actively worshipped gramadevata (village
guardian, a Bhairava form of Shiva) in Goa, Sindhudurg, Kolhapur and Karwar, with the
triennial Gadyachi Jatra at Poinguinim — a *derived, distinct* figure from the
literary corpse-spirit, but close enough to record (en.wikipedia.org/wiki/Betal and
/wiki/Shree_Betal_temple, verified 2026-07-18; his sword-and-bowl iconography is
borrowed into our icon set). **Sources:** Vetala Panchavimshati — oldest full
recension in Kathasaritsagara book 12 (Somadeva, 11th c.); Burton's *Vikram and the
Vampire* (1870, PD, gutenberg.org/files/2400) is a PD retelling (11 of 25 tales, more
Burton than India — used as PD access point, not as authority). Frame verified: the
vetala hangs upside-down from the tree, animates corpses, tells riddle-tales; if the
king knows the answer and stays silent his head bursts; answering sends the corpse
flying back; at the cycle's end the vetala reveals the sorcerer's plan to sacrifice
the king, saving him. **Personality rationale:** generosity 2 (the final warning is a
genuine gift); strictness 5 (the riddle rules are exact and lethal); pettiness 3
(twenty-four rounds of deliberate trolling); wrath 3 (head-burst clause); fidelity 4
(becomes the king's ally once won); risk_appetite 3.
**Myth lead:** `myth_hindu_vetala_twenty_five_tales`.

### Syamantaka (`hindu_syamantaka`) — artifact
**Scores:** influence 1 / recognition 1 → normal; mythic-tier collector loot.
**Sources:** Vishnu Purana IV.13 (Wilson tr., PD) and Bhagavata Purana X.56–57: the
Sun's own jewel, given to Satrajit, yielding eight bharas (loads/bars) of gold daily
and warding calamity while its holder is virtuous — and destroying the unworthy.
Chain of custody: Prasena wears it hunting and is killed by a lion; the bear-king
Jambavan takes it; Krishna — falsely accused of the theft *because he saw the
inauspicious moon on Ganesh Chaturthi* (the Ganesha moon-curse tie-in, told
traditionally as the curse's showcase) — fights Jambavan for days, recovers it, and
clears his name publicly. The item seed in `game_hooks` maps all of this 1:1
(worthiness ledger, gold trickle, curse flip, honest-transfer clearing, and the
False-Accusation event link). **Personality** (read as the artifact's behavior):
generosity 5 / strictness 5 / pettiness 1 / wrath 4 / fidelity 3 (it changes hands
constantly) / risk_appetite 2.
**Myth leads:** `myth_hindu_syamantaka_jewel`, `myth_hindu_ganesha_moon_curse` (shared).

## 4. Forward-declared myth ids (for Wave 3)

| id | primary source (PD access) | suggested grade |
|---|---|---|
| myth_hindu_shiva_parvati_dice | Skanda Purana (wisdomlib tr.); Padma Purana; Ellora relief | heroic_epic |
| myth_hindu_samudra_manthana | Mahabharata Adi Parva (Ganguli); Vishnu Purana I.9 (Wilson) | world_myth |
| myth_hindu_daksha_yajna | Vayu/Bhagavata Purana; Mahabharata | world_myth |
| myth_hindu_parvati_tapas | Kumarasambhava V (Kalidasa, PD tr.); Shiva Purana | heroic_epic |
| myth_hindu_annapurna | Skanda Purana, Kashi Khanda tradition (late attestation — flagged) | local_legend |
| myth_hindu_lakshmi_departs_heaven | Vishnu Purana I.9 (Wilson) | world_myth |
| myth_hindu_ganesha_scribe_broken_tusk | Mahabharata Adi Parva §1 (Ganguli) | heroic_epic |
| myth_hindu_ganesha_race_around_the_world | Shiva Purana | folk_tale |
| myth_hindu_ganesha_moon_curse | Puranic Chaturthi tradition; Syamantaka frame | folk_tale |
| myth_hindu_shani_gaze_ganesha | Brahma Vaivarta Purana, Ganapati Khanda | local_legend |
| myth_hindu_shani_trial_of_vikramaditya | Shani Mahatmya (devotional-literary — flagged) | local_legend |
| myth_hindu_kubera_venkateswara_loan | Venkatachala Mahatmya tradition; living Tirupati practice | local_legend |
| myth_hindu_alakshmi_origin_expulsion | Padma Purana; Sri Sukta khila; Diwali rite | folk_tale |
| myth_hindu_nala_kali_dice | Mahabharata Vana Parva, Nalopakhyana (Ganguli) | heroic_epic |
| myth_hindu_yudhishthira_dice_game | Mahabharata Sabha Parva (Ganguli) | heroic_epic |
| myth_hindu_yaksha_prashna | Mahabharata Vana Parva (Ganguli) | heroic_epic |
| myth_hindu_yudhishthira_final_journey | Mahaprasthanika/Svargarohana Parva (Ganguli) | heroic_epic |
| myth_hindu_rahu_beheading | Mahabharata Adi Parva, Astika (Ganguli); Vishnu Purana | world_myth |
| myth_hindu_mahishasura_slaying | Devi Mahatmya / Markandeya Purana (Pargiter 1904) | world_myth |
| myth_hindu_vetala_twenty_five_tales | Kathasaritsagara bk. 12; Burton 1870 (PD) | folk_tale |
| myth_hindu_syamantaka_jewel | Vishnu Purana IV.13 (Wilson); Bhagavata X.56-57 | heroic_epic |

Also on record for Wave 3, unattached to any extracted entity: **Rig Veda 10.34, the
Gambler's Hymn** (Griffith, PD) — a ruined gambler's first-person lament ("the
dice... have pierced my heart"); no named deity beyond Savitr's admonition, so it is
declared as a tradition-level lead, not an entity myth_ref.

## 5. Verification log

Web searches run 2026-07-18 through the session proxy (all succeeded): (1) Skanda
Purana dice game + Diwali decree + relief location; (2) Alakshmi origin/Jyestha/Sri
Sukta; (3) Shani-gaze BVP variant + Shingnapur; (4) Kubera-Venkateswara loan; (5)
Shakuni Malanada temple; (6) Nalopakhyana aksha-hridaya/vibhitaka; (7) Rahu beheading
+ Rahu kalam + Srikalahasti; (8) Vetala Panchavimshati/Burton + Goa Betal cult; (9)
Mahishasura boon + shapeshift phases. Consumer-grade hits (hinduismfacts, justkalinga,
mystreal, nativeplanet, etc.) were used strictly as index per §7, with each
load-bearing claim resting on a PD primary or an encyclopedic source one level down.
