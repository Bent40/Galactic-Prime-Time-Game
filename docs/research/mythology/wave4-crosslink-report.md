# Wave 4 — cross-link / dedup report (2026-07-18)

Data health across the extraction is **excellent**: all 210 entities pass every mechanical
check (zero domain-vocab violations; `obscurity_tier` and `table_tier_hint` derive
correctly from the §3 formulas on every record; `patron_block` presence exactly matches
`patron_capable`), and the 294 myths are clean (valid grades, well-formed deed profiles,
no dangling `myth_refs`, every myth has a real participant). Wave 4 was therefore
cross-linking, not repair.

## ✅ Applied (main-session, mechanical / high-confidence)

**Syncretic unification — 4 same-figure merges** (one playable identity each; variants
become skins/aliases at roster time). Tag drift collapsed to one `syncretic_group`:
- `yama_dharmaraja` — buddhist_yama + chinese_yanluo_wang (canonical **buddhist_yama**; Enma is the JP skin)
- `kubera_vaisravana` — hindu_kubera + buddhist_vaisravana (canonical **hindu_kubera**; Bishamonten the higher-recognition skin)
- `sarasvati_benzaiten` — buddhist_benzaiten + japanese_shinto_benzaiten — **true duplicate** (canonical **japanese_shinto_benzaiten**/Benten)
- `fortuna_tyche_gad` — greek_roman_tyche + abrahamic_folk_gad (canonical **greek_roman_tyche**; Gad the Semitic skin)

**Rejected merge (kept separate, correctly):** Thoth + Hermes — Hermes-Trismegistus is a
*fusion* into a third figure, not a same-god syncretism; both stay playable.

**`chinese_jade_emperor` syncretic_group cleared to null** — the `sakra_jade_emperor` tag
over-claimed a contested Indra identification (buddhist_shakra_indra already holds the
distinct `indra_shakra` group).

**15 reciprocal relations added** — every A→B relation missing its B→A converse now has it
(parent/child, employs/serves, rival, fellow-fallen, etc.).

## ⏸️ Applied but FLAGGED for owner override

- **`chinese_caishen` influence 5 → 4.** The rubric pins Chinese folk-religion deities at
  influence 4 (the Amaterasu band); influence 5 is reserved for >100M living-major
  principals (Ganesha). At 5 he also outranked the supreme Jade Emperor (4) whom he
  *serves* — an inversion. Corrected to 4 (still VVIP tier). **Revert if Caishen is meant
  to be a deliberate influence-5 wealth outlier.**

## 📋 Deferred to Wave 2b / Wave 5 (not applied)

**Wave-2b extraction demand** — the most-referenced *un-extracted* figures (each fixes
dangling relation edges AND satisfies myth-participant demand). Top picks:
`yoruba_west_african_olodumare` (7 refs) · `egyptian_ra` (4) · `japanese_shinto_izanagi`
(4) · `abrahamic_folk_seal_of_solomon` (3) · then Fafnir, Grendel, Oduduwa, Nyame, Samael,
Behemoth, Poseidon, Apollo, Indra, Meni (2 each). A short Wave-2b of ~14 would close most
open edges. **Owner call whether to run it** (the roster's 24-god MVP doesn't require it).

**16 relations point at not-yet-extracted entities** — resolve when/if Wave-2b runs
(e.g. Sekhmet→Ra `eye_of`, Sigurd→Fafnir `slayer_of`, Lilith→Samael `consort_of`).

**Myth-participant id normalization** — a handful of myth participants use unprefixed ids
(`indra`, `chandra`, `draupadi`, `percival`, `bors`, `the_sage_under_the_tree`). Normalize
to `tradition_` prefixes during Wave 5 when the roster generator reconciles ids.

**Annotated non-issues (awareness only, no merge):** Mahakala/Okuninushi both carry a
"Daikoku" folk-etymology variant (different origin figures — do not merge);
`mesoamerican_macuilxochitl` Xochipilli overlap already folded in (no separate entity).
