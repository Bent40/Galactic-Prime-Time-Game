# Mythology census — Wave 1 summary (2026-07-18)

**26/26 tradition families censused · 957 candidates · 0 failures.** Full records:
`data/mythology/traditions.json` (tradition map) + `data/mythology/census_candidates.jsonl`
(per-tradition candidate lists with flags). Method per `docs/design/mythology-research-spec.md`
§6: every agent carried the frozen Wave-0 calibration set, the rubrics, and the owner's
2026-07-18 rulings (D-1 messenger carve-out, D-3 deferred families, D-4 historical-human
exclusion). Every tradition reported closed/excluded material honestly — none returned empty
sensitivity notes.

## The tradition map

| tradition | wave⁺ | inf-ceil | rec-ceil | src-q | cands | luck | forsaken | living | restricted |
|---|---|---|---|---|---|---|---|---|---|
| abrahamic_folk | 1 | 5 | 5 | 5 | 45 | 3 | 7 | 12 | 1 |
| arthurian_medieval | 1 | 3 | 5 | 5 | 38 | 0 | 5 | 1 | 0 |
| buddhist | 1 | 5 | 4 | 5 | 39 | 6 | 2 | 27 | 2 |
| celtic | 1 | 3 | 5 | 4 | 41 | 2 | 3 | 9 | 0 |
| chinese | 1 | 5 | 5 | 4 | 40 | 5 | 9 | 21 | 0 |
| egyptian | 1 | 3 | 5 | 5 | 38 | 5 | 5 | 27 | 0 |
| greek_roman | 1 | 2 | 5 | 5 | 40 | 3 | 3 | 0 | 0 |
| hindu | 1 | 5 | 5 | 5 | 40 | 8 | 11 | 33 | 0 |
| japanese_shinto | 1 | 4 | 4 | 5 | 40 | 9 | 3 | 22 | 3 |
| mesoamerican | 1 | 4 | 4 | 4 | 40 | 3 | 6 | 4 | 3 |
| mesopotamian | 1 | 2 | 4 | 5 | 40 | 2 | 9 | 4 | 0 |
| norse_germanic | 1 | 3 | 5 | 5 | 40 | 2 | 10 | 13 | 0 |
| polynesian_maori | 1 | 3 | 5 | 4 | 39 | 1 | 3 | 15 | 6 |
| yoruba_west_african | 1 | 4 | 4 | 3 | 39 | 4 | 4 | 28 | 2 |
| andean | 2 | 4 | 3 | 3 | 36 | 2 | 5 | 5 | 1 |
| finnish_baltic | 2 | 3 | 3 | 4 | 40 | 5 | 6 | 12 | 0 |
| global_folklore | 2 | 1 | 5 | 4 | 39 | 1 | 0 | 0 | 2 |
| inuit | 2 | 3 | 3 | 3 | 24 | 0 | 1 | 3 | 3 |
| korean | 2 | 3 | 4 | 3 | 40 | 5 | 5 | 12 | 0 |
| native_north_american | 2 | 4 | 5 | 3 | 33 | 2 | 2 | 17 | 13 |
| slavic | 2 | 3 | 4 | 3 | 40 | 7 | 4 | 12 | 0 |
| vodou | 2 | 4 | 4 | 3 | 25 | 2 | 0 | 21 | 4 |
| zoroastrian | 2 | 3 | 4 | 4 | 37 | 2 | 4 | 16 | 0 |
| aboriginal_australian | 3 | 4 | 3 | 2 | 18 | 0 | 0 | 10 | 18 |
| cosmic_horror | 3 | 1 | 5 | 5 | 37 | 0 | 0 | 0 | 0 |
| internet_folklore | 3 | 1 | 4 | 4 | 29 | 2 | 3 | 0 | 0 |

⁺ *wave = the census agent's own priority proposal, not a decision.*

## Proposed Wave-2 extraction shortlist (⏸️ owner + main-session decision)

**Proposal: extract the 14 wave-1 traditions** — at ~10–12 entities each this lands the
spec's ~150-entity target across well more than the required ≥8 traditions, and the
influence-tier spread the MVP roster needs falls out naturally:

- **Living majors / big investors (influence 4–5):** hindu · buddhist · chinese ·
  japanese_shinto · yoruba_west_african · abrahamic_folk (investor institutions +
  depictable messenger tier) · mesoamerican
- **Mid-tier (influence 3):** norse_germanic · celtic · egyptian · arthurian_medieval ·
  polynesian_maori
- **Extinct-but-famous floor (influence 2, the Zeus tier):** greek_roman · mesopotamian

Wave-2 traditions (andean, finnish_baltic, global_folklore, inuit, korean,
native_north_american, slavic, vodou, zoroastrian) hold for the expansion pass. The two
◊ families (cosmic_horror 37 cands, internet_folklore 29 cands) are censused with
per-entity IP maps and stay `ship_status: deferred` per D-3 — extraction optional, later.

## Casino nobility — every luck/gambling deity found (spec §4 flag)

**81 flagged across the corpus:** Leprechaun (celtic, rec 5) · Thoth (egyptian, rec 4) · Hermes (greek_roman, rec 4) · Ganesha (hindu, rec 4) · Lakshmi (hindu, rec 4) · Inari (japanese_shinto, rec 4) · Rumpelstiltskin (global_folklore, rec 4) · Dokkaebi (korean, rec 4) · Coyote (native_north_american, rec 4) · Baron Samedi (vodou, rec 4) · Vaisravana (Bishamonten) (buddhist, rec 3) · Benzaiten (Buddhist Sarasvati) (buddhist, rec 3) · Lugh (celtic, rec 3) · Caishen (God of Wealth) (chinese, rec 3) · Khonsu (egyptian, rec 3) · Tyche (greek_roman, rec 3) · The Moirai (Fates) (greek_roman, rec 3) · Ebisu (japanese_shinto, rec 3) · Benzaiten (japanese_shinto, rec 3) · Bishamonten (japanese_shinto, rec 3) · Hotei (japanese_shinto, rec 3) · Norns (norse_germanic, rec 3) · Eshu (Elegba/Eleguá) (yoruba_west_african, rec 3) · Legba (yoruba_west_african, rec 3) · Sampo (finnish_baltic, rec 3) · Dokkaebi bangmangi (korean, rec 3) · Chernobog (slavic, rec 3) · Maximón (San Simón) (abrahamic_folk, rec 2) · Jambhala (Dzambhala) (buddhist, rec 2) · Vasudhara (buddhist, rec 2) · Mahakala (buddhist, rec 2) · Fu Lu Shou (Three Star Gods) (chinese, rec 2) · Tudi Gong (Earth God) (chinese, rec 2) · Pixiu (chinese, rec 2) · Hei Bai Wuchang (Black and White Impermanence) (chinese, rec 2) · Bes (egyptian, rec 2) · Shani (hindu, rec 2) · Kubera (hindu, rec 2) · Shakuni (hindu, rec 2) · Daikokuten (japanese_shinto, rec 2) · Fukurokuju (japanese_shinto, rec 2) · Jurojin (japanese_shinto, rec 2) · Uchide no Kozuchi (japanese_shinto, rec 2) · Xochipilli (mesoamerican, rec 2) · Macuilxochitl (mesoamerican, rec 2) · One Death and Seven Death (Lords of Xibalba) (mesoamerican, rec 2) · Tablet of Destinies (mesopotamian, rec 2) · Lono (polynesian_maori, rec 2) · Orunmila (yoruba_west_african, rec 2) · Ekeko (andean, rec 2) · Laima (finnish_baltic, rec 2) · Aitvaras (finnish_baltic, rec 2) · Chilseong (korean, rec 2) · Noqoilpi, the Great Gambler (native_north_american, rec 2) · Mokosh (slavic, rec 2) · Svetovit (slavic, rec 2) · Belobog (slavic, rec 2) · Sadko (slavic, rec 2) · Gede Nibo (vodou, rec 2) · Khvarenah (Farr) (zoroastrian, rec 2) · SCP-914 (The Clockworks) (internet_folklore, rec 2) · RNGesus (internet_folklore, rec 2) · Gad (abrahamic_folk, rec 1) · Meni (abrahamic_folk, rec 1) · Palden Lhamo (buddhist, rec 1) · Shai (egyptian, rec 1) · Renenutet (egyptian, rec 1) · Alakshmi (hindu, rec 1) · Kali (dice-demon) (hindu, rec 1) · Syamantaka (hindu, rec 1) · Namtar (mesopotamian, rec 1) · Hamingja (norse_germanic, rec 1) · Aje (yoruba_west_african, rec 1) · Huatya Curi (andean, rec 1) · Dalia (finnish_baltic, rec 1) · Jumis (finnish_baltic, rec 1) · Eopsin (korean, rec 1) · Gameunjang-agi (korean, rec 1) · Likho (slavic, rec 1) · Dola (slavic, rec 1) · Ashi (Ashi Vanghuhi) (zoroastrian, rec 1)

## Other aggregates

- **Forsaken-host candidates** (desperate / deposed / existence-wager myths): **110** flagged corpus-wide — the any-god-all-in amendment has a deep bench.
- **Living-worship figures:** heavy in hindu (33), yoruba (28), egyptian/buddhist (27 each — Kemetic revival and active veneration respectively), japanese_shinto (22), vodou (21): the per-figure owner gate (D-1) will matter at roster time, and the off-screen-investor default carries the rest.
- **Closed material:** aboriginal_australian returned an intentionally small list (18, all flagged for review) and native_north_american flagged 13 restricted — both censuses REPORT what is closed rather than collecting it, per spec §3.3/§7.
- **Syncretic chains** for Wave 4 dedup are flagged inline (`syncretic:` prefixes — Zeus/Jupiter, Inanna/Ishtar chains etc.).

## Next steps

1. ⏸️ Owner confirms/edits the Wave-2 shortlist above (+ the standing sitting items).
2. Wave 2: extraction fan-out (one agent per shortlisted tradition) → full `entities.jsonl`
   records + cited dossiers; acceptance criteria per spec §7 (calibration ±1, complete
   patron_blocks, rating_notes everywhere).
3. Wave 3 myths → Wave 4 cross-link/dedup → Wave 5 game mapping (dev session).
