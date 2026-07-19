# Yoruba & West African tradition — Wave 2 extraction dossier

*Extraction batch of 2026-07-18, per `docs/design/mythology-research-spec.md` (RULED,
incl. the §3.3 depiction-policy v2 ruling). 15 entities from the Wave-1 census pool of
39. No frozen calibration entity belongs to this tradition; all scores are argued
against the six frozen anchors (Zeus 2/5, Ganesha 5/4, Amaterasu 4/4, Väinämöinen 1/3,
Baba Yaga 1/4, Zababa 1/1). Web verification ran 2026-07-18 through the session proxy;
every load-bearing myth below was checked against at least one source a level below
Wikipedia. Researcher: Wave-2 extraction agent (read-only, no subagents).*

## 1. Tradition overview — the casino-frame angle

The Yoruba orisha family (census `yoruba_west_african`, source_quality 3, influence
ceiling 4) is a LIVING tradition: orisha religion in Nigeria/Benin plus the Atlantic
diaspora — Lucumí/Santería (Cuba), Candomblé (Brazil), Trinidad Orisha — with
practitioner estimates in the millions. Rubric §3.1 band 4 names "Yoruba orishas"
explicitly, which anchors the influence-4 block below without further adjudication.
Every orisha, plus Mami Wata and the opon Ifá, carries `depiction_risk: living` — per
depiction v2 this is recorded DATA, not a gate; the register is respectful pop-culture
mythological fiction, never racist caricature.

**Why this pantheon is casino-native.** Three structural gifts to *this* game:

1. **The service industry of luck is Yoruba-run.** Eshu is literally the "pay the
   dealer first" rule as a person; Orunmila is a god whose entire portfolio is *knowing
   every player's odds in advance* (he witnessed each soul choose its destiny); Aje is
   the cash-flow itself; the opon Ifá is a fate-interface object. No other Wave-2
   tradition supplies the casino's front-of-house staff this directly.
2. **The Forsaken bench is deep.** Shango's central myth is an all-in loss converted
   into godhood; Babalú-Ayé was exiled by the pantheon and returned unkillable; Olokun
   challenged the supreme god and lost; Anansi (folk-tier) staked his own mother and
   won. Four verified wager/unmaking arcs in one batch.
3. **It's the pantheon that never went bankrupt.** Unlike the Greek/Norse tables, orisha
   worship *grew* through the last quarter-millennium cycle (the diaspora). In the
   divinity economy that makes them a growth stock, not nostalgia.

**Proposed pantheon modern-life attribution (canon §4 invites one per pantheon; OWNER
TO BLESS):** the orisha table plays as *a three-continent family franchise* — Lagos
headquarters, Havana and Bahia branch offices — the only house on the floor whose
earthly revenue rose last cycle. They throw the best party in the building, the drums
never stop, everyone on staff is somebody's godchild, and the dress code (all white on
initiation days) is enforced. Used lightly in the temperament lines.

**Closed material honored (census `closed_material_notes`, spec §3.3 carve-out):** the
Ifá literary corpus (256 odu, thousands of verses) is initiation-bound — only the fully
public FRAME of Ifá (Orunmila, the tray, the ikin, the ritual's outline) is collected;
no verse content is mined, and the dossier flags this on Orunmila and the opon Ifá.
Egungun/Oro/Ogboni society interiors and the Ashanti Golden Stool were left out
entirely. Shopona's spoken-name taboo is respected structurally: the entity's primary
name is the diaspora name Babalú-Ayé (and the taboo itself becomes a diegetic
mechanic, flagged for owner review).

**Primary sources used across the batch** (source ladder §7): A.B. Ellis, *The
Yoruba-Speaking Peoples of the Slave Coast* (1894, PD); R.S. Rattray, *Akan-Ashanti
Folk-Tales* (1930 — newly PD in the US as of 2026); Idowu, *Olodumare: God in Yoruba
Belief* (academic); Bascom, *Ifa Divination* (academic); Drewal (ed.), *Mami Wata: Arts
for Water Spirits in Africa and Its Diasporas* (2008, incl. the open African Arts PDF);
Okpewho, "Performance and Plot in The Ozidi Saga" (*Oral Tradition* 19/1, 2004, open
access); UNESCO listings (Ifá divination system, ICH 00146; Osun-Osogbo Sacred Grove,
WHC 1118); CDC Museum page on Shapona; Wikipedia strictly as index with claims verified
one level down (URLs cited per entity).

## 2. Selection rationale (vs. the 39-candidate pool)

- **Slots:** 9 patron-capable gods + 1 patron-capable spirit, 1 hero, 1 beast, 1 fiend,
  1 folk, 1 artifact = 15. The god count exceeds the spec's ≈6–7 guidance deliberately:
  this tradition's census shape is 23 gods vs 2 thin heroes, and the luck/forsaken
  flags (which the task orders prioritized) all sit god-side. Honest adaptation, not
  padding.
- **Every luck_gambling flag resolved (4/4):** Orunmila, Eshu, Aje taken; **Legba
  folded into Eshu** as one cross-tradition identity (`syncretic_group: eshu_legba`) —
  extracting him separately would create the duplicate-identity problem Wave 4 exists
  to remove; the Vodou wave attaches Papa Legba to the same group.
- **Every forsaken_candidate flag taken (4/4):** Shango, Olokun, Babalú-Ayé, Anansi.
- **Skipped, honestly:** Yemoja (strongest omission — slot pressure; her sea portfolio
  overlaps Olokun/Oshun; first in line for a follow-up batch), Oya, Olodumare (remote
  supreme with no cult shrines of his own — poor patron material; kept as an off-board
  figure via relations), Oduduwa (euhemeristic borderline + slot), Nana Buluku,
  Mawu-Lisa, Dan, Nyame (survives as a relation on Anansi), Ala, Amadioha, Osanyin,
  Ochosi, Ibeji, Bayajidda (thin, borderline founding-legend-of-historical-dynasty),
  Ninki Nanka (thin cryptid — better batched with global_folklore), Ijapa, Mmoatia,
  Aziza, Abiku/Ogbanje, Oshe Shango (folded into Shango's iconography), Egungun and
  the Golden Stool (restricted/closed — collection exclusion honored).

## 3. Entities

### Eshu (`yoruba_west_african_eshu`)
**Scores:** influence 4 / recognition 3 / living / vvip. Band 4 names Yoruba orishas
(Amaterasu-consistent); mythology-curious fame (Enki band).
**Sources:** the two-colored hat tale verified via the Yale-New Haven Teachers
Institute unit (teachersinstitute.yale.edu/curriculum/units/1998/2/98.02.04/3) and
multiple retellings (mythcrafts.com/2017/01/19/eshu-trickster-for-the-digital-age);
academic grounding in Ayodele Ogundipe's *Èṣù Elégbára* scholarship and Ellis 1894
(PD). "Fed first or messages go astray" is standard cult protocol across Bascom and
diaspora practice literature; his face on every opon Ifá rim (see §Opon Ifá) makes the
enforcer partnership with Orunmila material culture, not conjecture.
**Personality rationale:** generosity 3 (opens roads freely when paid); strictness 4
(HE is the pay-first protocol); pettiness 4 (engineered the hat feud between two
perfect friends to make a point about neglecting him); wrath 3 (misfortune, not
annihilation); fidelity 2 (everyone's messenger, no one's servant); risk 5 (chance
personified).
**Myth leads declared:** `myth_yoruba_west_african_eshu_two_colored_hat` (folk_tale/
local_legend grade; deed profile mind/charm; reenactment: split-perception team test).

### Orunmila (`yoruba_west_african_orunmila`)
**Scores:** influence 4 / recognition 2 / living / vvip.
**Sources:** Eleri Ipin ("witness of destiny") epithet and the ori-choice witnessing
verified via ileifa.org/orunmila-orisa-wisdom-witness-destiny-patron-ifa/ and
divinationwithifa.com (cross-checked against Bascom's *Ifa Divination*); the
ascension-and-sixteen-ikin myth (he withdraws to heaven and leaves the sixteen palm
nuts as his interface) verified via the same cluster (en.oshaeifa.com/orisha/orunmila/
carries the fullest retelling). Ifá divination system: UNESCO ICH 00146 (proclaimed
2005, inscribed 2008 — ich.unesco.org/en/RL/ifa-divination-system-00146).
**Closure note:** only the public frame is used; no odu verse content collected.
**Personality rationale:** wrath 1 and fidelity 5 are the myth's own shape — when
offended he *withdrew* rather than punished, and as destiny's witness he cannot leave
your file; strictness 4 (consultation protocol); risk 1 (nothing is uncertain to him —
the ultimate non-gambler in the building, which is exactly why the casino needs him).
**Myth leads declared:** `myth_yoruba_west_african_orunmila_witness_of_destiny`
(world_myth-adjacent: present at every soul's destiny-choice),
`myth_yoruba_west_african_orunmila_sixteen_ikin` (heroic_epic/local_legend grade).

### Obatala (`yoruba_west_african_obatala`)
**Scores:** influence 4 / recognition 3 / living / vvip.
**Sources:** the drunken-sculptor myth (palm wine, imperfect bodies, the vow, patronage
of disabled people) and the Oduduwa takeover verified via en.wikipedia.org/wiki/Ọbatala,
Oxford Reference ("Obatala Is Tempted with Palm Wine",
oxfordreference.com/display/10.1093/oi/authority.20110803100243353) and
oriire.com/article/obatala-the-creator-and-wisdom-keeper-in-yoruba-mythology;
devotee taboos (no palm wine ever; offerings without palm oil) confirmed in the same
cluster; classic academic treatments in Idowu and Courlander.
**Personality rationale:** pettiness 1 / wrath 2 / fidelity 5 (the cool, patient
"orisha funfun" — endures wrongs rather than avenging them); strictness 4 (white-cloth
purity code); risk 1 (took exactly one gamble in mythic history — palm wine — and its
cost defines him); generosity 4 (father-figure of the pantheon).
**Myth leads declared:** `myth_yoruba_west_african_obatala_drunken_sculptor` (world_myth
grade — origin of human imperfection), `myth_yoruba_west_african_obatala_oduduwa_creation`
(world_myth — the land-creation handover; participants include Oduduwa, not extracted).
**Deal-sheet note:** "win with a disabled limb" — the spec's own example favor
condition — is literally native to him; the GPT body-part HP system makes his whole
block sim-detectable today.

### Shango (`yoruba_west_african_shango`)
**Scores:** influence 4 / recognition 4 / living / vvip. Recognition 4 is a judged
call: Changó's Latin-music ubiquity + game/comic appearances put him in the Baba
Yaga/Ganesha band, one notch over Eshu; within ±1 either way.
**Sources:** the Oba-koso arc (lightning experiment, palace burned, retreat to Koso,
hanging denied by the cult cry "Oba ko so", deification) verified via
en.wikipedia.org/wiki/Ọba_kò_so, fabulahub.com/en/story/epic-shango-thunder-king-oyo-empire
and africanpoems.net (Sango's Tale); the Gbonka–Timi duel (Shango sets his two
too-powerful generals against each other; the winner turns on him) verified in the
same cluster — it is also the plot spine of Duro Ladipo's 1963 folk opera *Oba Kò So*
(the play is modern IP; the underlying legend is traditional). Lightning-strikes-liars
justice attested in standard references (Britannica-level).
**Euhemerism note (owner awareness, carried from census):** tradition names him an
early Alaafin of Oyo; historicity unverifiable; worshipped today purely as an orisha —
included as god per the census ruling.
**Personality rationale:** wrath 5 / risk 5 (drew lightning down on his own palace);
pettiness 4 (feared his own generals enough to engineer their mutual destruction);
fidelity 3 (three mythic marriages, one famous storm-out); strictness 3.
**Myth leads declared:** `myth_yoruba_west_african_shango_oba_koso` (heroic_epic; THE
forsaken-arc myth: all-in, total loss, apotheosis),
`myth_yoruba_west_african_shango_gbonka_timi` (heroic_epic; house-directed
champion-vs-champion template).

### Ogun (`yoruba_west_african_ogun`)
**Scores:** influence 4 / recognition 3 / living / vvip.
**Sources:** path-clearing primacy ("Osin Imole", first orisha to descend, machete
through the primordial thicket) verified via en.wikipedia.org/wiki/Ogun and
skabash.com/ogun-orisha/; the Ire massacre (king of Ire; slaughtered his own people;
turned his sword on himself / descended into the earth — versions vary and Wave 3
should record the variance) same cluster; **iron-oath practice in Nigerian courts**
(swearing on iron in place of Bible/Quran) verified via the Wikipedia article and
Patheos (patheos.com/blogs/voodoouniverse/2013/11/orisha-ogun-lord-of-iron-god-of-war/).
Ellis 1894 (PD) covers the Ogun cult at length.
**Personality rationale:** wrath 5 (Ire); strictness 4 (the oath-on-iron god);
fidelity 4 (the dog-companion, dogged-loyalty complex); generosity 3 (gave iron and
civilization to everyone); pettiness 2; risk 3.
**Myth leads declared:** `myth_yoruba_west_african_ogun_clears_the_path` (world_myth —
why the orishas could reach earth at all), `myth_yoruba_west_african_ogun_ire_massacre`
(local_legend/heroic_epic — rage, consequence, withdrawal).

### Oshun (`yoruba_west_african_oshun`)
**Scores:** influence 4 / recognition 4 / living / vvip. Recognition 4: Beyoncé-era pop
visibility (Lemonade, 2017 Grammys staging) + Osun-Osogbo's global profile.
**Sources:** the seventeenth-orisha myth (Olodumare sends 17 orishas; the 16 males
sideline the one woman; everything fails; Olodumare tells them nothing succeeds without
her; the reconciliation births Ose-Tura) verified via worldhistory.org/Oshun/ and
cosettepaneque.com/when-the-world-needed-a-woman-the-orisha-oshun/ (the myth's home is
the odu Ose Tura, but it circulates fully in public secondary literature — the
public-frame rule is respected: we cite retellings, not verse text). Osun-Osogbo Sacred
Grove: UNESCO WHC 1118, inscribed 2005 — the annual festival renews the founding pact
between the goddess and the town (whc.unesco.org/en/list/1118; pact details to be
re-verified at Wave 3 against the UNESCO nomination text).
**Personality rationale:** generosity 4 (sweet waters, freely given); pettiness 4 and
wrath 3 (the snub myth: not fury but withdrawal — the world simply stops working);
strictness 2 (easy protocol, hard grudges); risk 3.
**Myth leads declared:** `myth_yoruba_west_african_oshun_seventeenth_orisha`
(world_myth — creation stalls without her), `myth_yoruba_west_african_oshun_osogbo_pact`
(local_legend — goddess-community contract, festival renewal).

### Babalú-Ayé (`yoruba_west_african_babalu_aye`)
**Scores:** influence 4 / recognition 3 / living / vvip.
**Sources:** the spoken-name taboo and euphemism system ("Obaluaye" = King Who Owns
the Earth, etc.) verified via en.wikipedia.org/wiki/Sopona and the CDC Museum page
(cdc.gov/museum/history/shapona.html); the **1907 British colonial ban** on the Shopona
cult (priests accused of deliberately spreading smallpox via variolation scrapings —
Dr. Oguntola Sapara's investigation) verified via the CDC page and Wikipedia one level
down; exile-and-return arc and dogs/San Lázaro syncretism verified via
en.wikipedia.org/wiki/Babalú-Ayé (Lucumí patakí corpus; David H. Brown's *Santería
Enthroned* is the academic anchor; the Dec 17 San Lázaro pilgrimage to El Rincón,
Cuba, draws tens of thousands — the living-practice basis of influence 4).
**Name handling:** primary name = diaspora name per census sensitivity note; Ṣọ̀pọ̀na
recorded as a variant explicitly marked taboo-to-speak. The in-game name-taboo
mechanic is flagged for owner review (it gamifies a real taboo — we believe
respectfully, since the game's rule ENFORCES the reverence, but it is a judgment call).
**Personality rationale:** strictness 5 / wrath 5 (the severest taboo-and-punishment
complex in the pantheon — epidemic as anger); generosity 3 (owns cure as well as
plague); fidelity 4 (the dogs; loyal to the humble who honor him); risk 4 (exile
survivor — the Forsaken profile).
**Myth leads declared:** `myth_yoruba_west_african_babalu_exile_and_return`
(heroic_epic grade — exile, wandering, return in power; Wave 3 must record the
Yoruba/Arará/Lucumí version split honestly).

### Olokun (`yoruba_west_african_olokun`)
**Scores:** influence 4 / recognition 2 / living / vvip — the batch's rare-board VVIP:
enormous bankroll, low fame.
**Sources:** the cloth/splendor contest — Olokun challenges the supreme god; Olodumare
sends the chameleon Agemo, who mirrors every cloth Olokun wears; Olokun concedes to
the servant's mimicry — verified via en.wikipedia.org/wiki/Agemo_(deity),
mythencyclopedia.com/Ni-Pa/Olorun.html and encyclopedia.com (Olorun entry); the myth
is recorded academically in Idowu's *Olodumare*. Gender varies by region (female in
much Yoruba telling, male in Edo/Benin royal cult, androgynous in diaspora) — art
direction should embrace the ambiguity, not resolve it. Living worship: the Edo/Benin
Olokun cult and Lucumí Olokun practice ground influence 4.
**Personality rationale:** pettiness 4 / risk 5 (the contest was a pure-status
challenge to GOD, and he still wants a rematch); generosity 2 (deep wealth, grudging
release); wrath 4 (flood traditions — the chained-beneath-the-sea motif appears in
Benin/diaspora versions; recorded as a Wave-3 lead, not declared, pending better
sourcing); fidelity 3.
**Myth leads declared:** `myth_yoruba_west_african_olokun_cloth_contest` (world_myth
adjacent — why the sea submits to the sky; the casino reading: the house always wins,
and it wins by REFLECTION, not force).

### Aje (`yoruba_west_african_aje`)
**Scores:** influence 3 / recognition 1 / living / normal-table mythic collector.
**Sources:** Aje Shaluga attested in Ellis 1894 (PD) as the wealth/money orisha; the
tiger-cowrie favor-sign, the Olokun filiation ("daughter of Olokun" in Ifá-tradition
accounts), and Ọjọ́ Ajé ("day of wealth", Monday) verified via
africanpoems.net/gods-ancestors/salute-to-aje-orisha-of-wealth/,
naijadetails.com and asanee44.com/aje/ (diaspora-practice sources — a level below
academic; flagged accordingly). Gender and even individuation vary by source (Aje /
Ajé Ṣàlúgà); recorded as variants.
**HONESTY FLAG:** the narrative corpus is thin — the personality axes are PROVISIONAL,
derived from cult logic (wealth-giver = generosity 4; money leaves quarrelsome places =
strictness 3, fidelity 2, wrath 2 — she departs rather than punishes) more than from
narrative myth. Small honest entry per spec §7; she is in the batch because the spec
orders every luck_gambling flag collected and the canon loves a mythic-tier collector
piece.
**Myth leads declared:** `myth_yoruba_west_african_aje_daughter_of_olokun`
(folk_tale/genealogical grade — wealth is the deep sea's daughter; cowries come up
from Olokun's vault).

### Ozidi (`yoruba_west_african_ozidi`) — hero
**Scores:** influence 1 / recognition 1 / none / normal.
**Sources:** The Ozidi Saga (Ijaw/Ijo oral epic): posthumous son avenges his
assassinated father under the direction of his sorceress grandmother Oreame;
seven-night ritual performance at Orua; the saga ends with the Smallpox King
(Engarando) arriving by sea barge, afflicting Ozidi, and withdrawing defeated when the
disease is treated as an ordinary illness. Verified via en.wikipedia.org/wiki/The_Ozidi_Saga
and Isidore Okpewho, "Performance and Plot in The Ozidi Saga," *Oral Tradition* 19/1
(2004), open access (journal.oraltradition.org).
**IP note (corrects a census flag):** the census marked Ozidi `ip:public_domain_literary`;
in fact J.P. Clark-Bekederemo's standard bilingual edition (1977) is in-copyright
scholarship. The underlying oral epic is traditional — `ip_status: traditional` — but
later waves must not quote Clark's text; work from Okpewho's open article and summary
level.
**Personality rationale:** fidelity 5 / wrath 5 (a life built entirely around filial
vengeance); strictness 4 (the vengeance code); generosity 2; risk 4 (fights every
champion in sequence).
**Myth leads declared:** `myth_yoruba_west_african_ozidi_saga` (heroic_epic — the
full cycle; Wave 3 may split the Smallpox-King finale into its own record, it is the
best boss-design material in the batch).

### Sasabonsam (`yoruba_west_african_sasabonsam`) — beast
**Scores:** influence 1 / recognition 2 / none / normal.
**Sources:** Akan forest being with iron teeth, unnaturally long legs, feet hooked in
both directions; dwells in silk-cotton trees and takes hunters from above; entangled
with the Thursday forest rest-day obligation. Verified via
en.wikipedia.org/wiki/Sasabonsam and atlasobscura.com/articles/monster-mythology-sasabonsam
(which carries the rest-day enforcement reading); Rattray's Ashanti scholarship is the
academic anchor. Personality: ambush-predator profile (patient, territorial, rule-bound
in its own way — it polices the forest's observance day).
**Enemy sketch:** in the entity record's game_hooks — size L, canopy ambusher,
inflicts bleeding (iron teeth) and grapple-suffocation; two discoverable win
conditions (drop its anchor; learn and exploit the rest-day dormancy window). Never a
damage race.

### Adze (`yoruba_west_african_adze`) — fiend
**Scores:** influence 1 / recognition 2 / none / normal.
**Sources:** Ewe (Togo/Ghana) vampiric being: firefly form, passes through keyholes
and door cracks at night, prefers children's blood; possesses people, who are then
reckoned witches; reverts to a capturable/killable form only when caught; academically
read as a malaria/insect-borne-disease explanation. Verified via
en.wikipedia.org/wiki/Adze_(folklore) and atlasobscura.com/articles/monster-mythology-adze.
Personality: pettiness 5 is the folklore's own diagnosis — adze possession accusations
tracked envy lines in the community.
**Enemy sketch:** in game_hooks — the capture-don't-chase two-form design and the
possessed-ally event both come straight from attested lore.

### Anansi (`yoruba_west_african_anansi`) — folk
**Scores:** influence 1 / recognition 4 / none / normal — Baba Yaga's calibration twin
almost exactly (folk being, no worship, big pop fame).
**Sources:** "How the Sky-God's Stories Came to Be Anansi's Stories" — Anansi buys all
stories from Nyame for the price of the python Onini, the hornets Mmoboro, the leopard
Osebo, and the mmoatia (forest dwarf/fairy), and in Rattray's recorded Akan version
adds his own mother Ya Nsia to the stake; wins by trickery; all narrative becomes
"anansesem," spider stories. Verified via en.wikipedia.org/wiki/Anansi and
multoghost.wordpress.com/2024/05/03/how-anansis-bought-the-worlds-stories (which works
directly from Rattray, *Akan-Ashanti Folk-Tales*, 1930 — now PD in the US).
**IP note:** the folk substrate is free; avoid Gaiman's Mr. Nancy and Marvel
renditions in design.
**Personality rationale:** risk 5 and fidelity 2 are the same fact — he staked his
own mother; generosity 2 (won the stories for himself, not the world); strictness 1;
wrath 2 (out-schemes rather than smites).
**Myth leads declared:** `myth_yoruba_west_african_anansi_story_wager` (heroic_epic
grade in cultural weight — the wager that named all stories; reenactment hook:
a capture-gauntlet with a zero-kill win condition).

### Mami Wata (`yoruba_west_african_mami_wata`) — spirit
**Scores:** influence 3 / recognition 3 / living / vip.
**Sources:** pan-West-African (and diaspora) water spirit: mirror, comb, python; grants
sudden wealth, beauty, healing; the price is fidelity — devotee "spiritual marriages"
demand exclusivity/secrecy and breach means total ruin. Iconography famously
canonized from an ~1885 Hamburg chromolithograph of a snake charmer, adopted across
the coast (Drewal's scholarship traces the chain performer→poster→spirit). Verified
via en.wikipedia.org/wiki/Mami_Wata and Drewal, "Mami Wata: Arts for Water Spirits in
Africa and Its Diasporas," *African Arts* 41/2 (2008), open PDF
(staff.washington.edu/ellingsn/Drewal-Mami_Wata-AfAr.2008.41.2.pdf).
**Personality rationale:** generosity 5 AND strictness 5 — the covenant structure is
the whole personality: lavish while kept, ruinous when broken; pettiness 4 (jealous
exclusivity); fidelity 4 (she keeps her side); wrath 4 (the reversal of fortune).
**Myth leads declared:** `myth_yoruba_west_african_mami_wata_pact` (folk_tale/
local_legend — the abduction-return-with-wealth / covenant pattern; variant-rich by
design, which Wave 3 should represent as a pattern-myth rather than one canonical
telling).
**Canon-thesis note:** her human-manufactured image is the single best in-batch proof
of canon §4's thesis (gods wear what humanity imagines) — recommended for early lore
surfacing.

### Opon Ifá (`yoruba_west_african_opon_ifa`) — artifact
**Scores:** influence 3 / recognition 2 / living / normal. Influence semantics
judgment call: an artifact isn't worshipped; 3 records the living weight of the
practice it belongs to (Ifá, UNESCO ICH 00146). Flagged for Wave-4 normalization.
**Sources:** the carved face of Eshu on the tray's rim (watching the divination,
taking his portion), the iyerosun dust, the iroke tapper, and the ritual's outline
verified via the Art Institute of Chicago object page (artic.edu/artworks/152014),
Museum of Witchcraft and Magic object 3874, and ich.unesco.org/en/RL/ifa-divination-system-00146.
**Closure honored:** only fully public museum-published iconography is rendered; odu
verse content stays out of the game entirely.
**Item seed:** in game_hooks — a once-per-floor true-outcome preview relic with an
Eshu tax; deterministic-sim-friendly (reveals a resolved outcome, no hidden RNG).

## 4. Myth leads forward-declared (Wave 3 queue, all verified this session)

1. `myth_yoruba_west_african_eshu_two_colored_hat`
2. `myth_yoruba_west_african_orunmila_witness_of_destiny`
3. `myth_yoruba_west_african_orunmila_sixteen_ikin`
4. `myth_yoruba_west_african_obatala_drunken_sculptor`
5. `myth_yoruba_west_african_obatala_oduduwa_creation`
6. `myth_yoruba_west_african_shango_oba_koso`
7. `myth_yoruba_west_african_shango_gbonka_timi`
8. `myth_yoruba_west_african_ogun_clears_the_path`
9. `myth_yoruba_west_african_ogun_ire_massacre`
10. `myth_yoruba_west_african_oshun_seventeenth_orisha`
11. `myth_yoruba_west_african_oshun_osogbo_pact`
12. `myth_yoruba_west_african_babalu_exile_and_return`
13. `myth_yoruba_west_african_olokun_cloth_contest`
14. `myth_yoruba_west_african_aje_daughter_of_olokun`
15. `myth_yoruba_west_african_ozidi_saga`
16. `myth_yoruba_west_african_anansi_story_wager`
17. `myth_yoruba_west_african_mami_wata_pact`

Wave-3 watch item: Olokun's chained-flood tradition (Benin/diaspora) was NOT declared —
sourcing was not nailed down this session; verify before recording.

## 5. Calibration & honesty check

- The influence-4 block rests directly on rubric §3.1 band 4 naming "Yoruba orishas" —
  Amaterasu-consistent, below Ganesha's 5, above Zeus's 2. No frozen entity is
  contradicted; nothing in this batch scores outside ±1 of what the anchors imply.
- Judgment calls (both within ±1): Shango and Oshun recognition 4 vs 3; Opon Ifá /
  Aje / Mami Wata influence 3 (living-but-diffuse band).
- source_quality 3 was respected as a cap: Aje is deliberately small; Gaulish-style
  deep-profile inflation was avoided; closed Ifá verse material was not mined.
