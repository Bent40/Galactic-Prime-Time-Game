#!/usr/bin/env python3
"""Wave 5 patron-roster generator (Galactic Prime Time).

Reads the mythology extraction (`data/mythology/entities.jsonl`), filters to the
owner-approved 24-god MVP shortlist (`docs/design/wave5-roster-shortlist.md`),
and emits `data/patron_roster.json` — playable patron records shaped for the
patron-god layer (`docs/design/patron-gods.md`) and the multiplier boon economy.

Design notes / honesty bars:
  * All numbers are PLACEHOLDER (R14). The `deal_sheet_hints` values are direct
    1-5 restatements of the entity's personality axes (mythology-research-spec
    §5), NOT invented tuning constants — the axis IS the lever, tuning comes
    later.
  * This file does NOT overwrite `data/patron_gods.json`. The five slice stubs
    (ids 1-5) stay put — `data/demo_loadouts.json` references chosen_patron ids
    2 (enyo) and 3 (hestia). The roster SUPERSEDES those stubs LATER, once the
    demo loadouts are re-pointed; for now both coexist.
  * No fabrication. If a shortlisted id is not `patron_capable` in the data
    (i.e. ships no `patron_block`), the deal-sheet dos/don'ts are NOT invented —
    the record is emitted with status "unresolved", empty favor/taboo lists, and
    a loud note, and is catalogued in `_meta.unresolved_shortlist` for an owner
    ruling. (This is the Anansi case: entities.jsonl marks it entity_class=folk /
    patron_capable=false / roles dealer+contestant_legend.)

Deterministic + idempotent: no wall-clock, no randomness; re-running produces a
byte-identical file. Run from anywhere (paths resolve relative to this file).
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ENTITIES = ROOT / "data" / "mythology" / "entities.jsonl"
OUT = ROOT / "data" / "patron_roster.json"

# ---------------------------------------------------------------------------
# The owner-approved 24-god MVP shortlist, resolved to entity ids.
# Source table: docs/design/wave5-roster-shortlist.md (name + tradition per row).
# Order below preserves the shortlist's row order (#1..#24).
# Name->id resolution rule: match by tradition + name. Traditions in the table
# are shorthands for the entities.jsonl tradition ids:
#   greek     -> greek_roman        abrahamic -> abrahamic_folk
#   japanese  -> japanese_shinto    yoruba    -> yoruba_west_african
#   norse     -> norse_germanic     arthurian -> arthurian_medieval
#   hindu/buddhist/chinese/celtic/mesoamerican/mesopotamian map 1:1.
# Disambiguation note: "Benzaiten" exists in TWO traditions (buddhist_benzaiten
# and japanese_shinto_benzaiten). The shortlist row says tradition=japanese, so
# #12 resolves to japanese_shinto_benzaiten.
# ---------------------------------------------------------------------------
SHORTLIST: list[tuple[str, str]] = [
    ("Ganesha",          "hindu_ganesha"),
    ("Avalokiteshvara",  "buddhist_avalokiteshvara"),
    ("Amaterasu",        "japanese_shinto_amaterasu"),
    ("Yama",             "buddhist_yama"),
    ("Palden Lhamo",     "buddhist_palden_lhamo"),
    ("Caishen",          "chinese_caishen"),
    ("Santa Muerte",     "abrahamic_folk_santa_muerte"),
    ("Eshu",             "yoruba_west_african_eshu"),
    ("Odin",             "norse_germanic_odin"),
    ("The Morrígan",     "celtic_morrigan"),
    ("Morgan le Fay",    "arthurian_medieval_morgan_le_fay"),
    ("Benzaiten",        "japanese_shinto_benzaiten"),
    ("Zeus",             "greek_roman_zeus"),
    ("Athena",           "greek_roman_athena"),
    ("Hades",            "greek_roman_hades"),
    ("Hermes",           "greek_roman_hermes"),
    ("Loki",             "norse_germanic_loki"),
    ("Tezcatlipoca",     "mesoamerican_tezcatlipoca"),
    ("Inanna",           "mesopotamian_inanna"),
    ("Beelzebub",        "abrahamic_folk_beelzebub"),
    ("Gad",              "abrahamic_folk_gad"),
    ("Lucifer",          "abrahamic_folk_lucifer"),
    ("Mammon",           "abrahamic_folk_mammon"),
    ("Ra",               "egyptian_ra"),
]

AXES = ("generosity", "strictness", "pettiness", "wrath", "fidelity", "risk_appetite")


def load_entities() -> dict[str, dict]:
    if not ENTITIES.is_file():
        sys.exit(f"generate_patron_roster: entities file missing: {ENTITIES}")
    by_id: dict[str, dict] = {}
    for ln, line in enumerate(ENTITIES.read_text(encoding="utf-8").splitlines(), 1):
        line = line.strip()
        if not line:
            continue
        try:
            rec = json.loads(line)
        except json.JSONDecodeError as e:
            sys.exit(f"generate_patron_roster: entities.jsonl line {ln}: invalid JSON: {e}")
        by_id[rec["id"]] = rec
    return by_id


def deal_sheet_hints(ent: dict) -> dict:
    """Personality axes -> deal-sheet levers (mythology-research-spec §5).

    Every value is a direct 1-5 axis restatement or a boolean threshold — a
    PLACEHOLDER lever (R14), not a tuned constant. Named per §5's driver column.
    """
    p = ent.get("personality", {})
    inf = ent.get("influence")
    taboos = (ent.get("patron_block") or {}).get("taboos", []) or []
    g, strict, petty, wrath, fid, risk = (p.get(a) for a in AXES)
    return {
        # generosity -> boon frequency / magnitude; gift chance at thresholds
        "boon_frequency": g,
        "boon_magnitude": g,
        # strictness -> taboo count + penalty severity on the deal sheet
        "taboo_severity": strict,
        "taboo_count": len(taboos),
        # pettiness -> rival-curse chance when you court other gods
        "rival_curse_chance": petty,
        # wrath -> punishment escalation speed after a taboo breach
        "punishment_speed": wrath,
        # fidelity -> buy-out resistance; low fidelity sells your contract sooner
        "buyout_resistance": fid,
        "buyout_magnet": isinstance(fid, int) and fid <= 1,  # fidelity-1 edge case
        # risk_appetite -> bet exoticness; >=4 = eager Forsaken host
        "forsaken_eager": isinstance(risk, int) and risk >= 4,
        # §5 amendment (owner 2026-07-18): Forsaken hosting is NOT influence-gated —
        # nothing-to-lose deities host too. influence==1 (extinct/locally-remembered)
        # is the available "nothing to lose" proxy.
        "forsaken_host_candidate": (isinstance(risk, int) and risk >= 4)
        or (inf == 1),
        "risk_appetite": risk,
    }


def build_record(name: str, ent: dict) -> dict:
    """Emit one roster record from an entity. Never fabricates deal-sheet prose."""
    pb = ent.get("patron_block") or {}
    resolved = bool(ent.get("patron_capable")) and bool(ent.get("patron_block"))
    rec = {
        "id": ent["id"],                       # stable slug == entity id
        "status": "resolved" if resolved else "unresolved",
        "name": ent.get("names", {}).get("primary", name),
        "shortlist_name": name,
        "tradition": ent.get("tradition"),
        "influence": ent.get("influence"),
        "recognition": ent.get("recognition"),
        "table_tier": ent.get("table_tier_hint"),
        "obscurity_tier": ent.get("obscurity_tier"),
        "domains": list(ent.get("domains", [])),
        "personality": {a: ent.get("personality", {}).get(a) for a in AXES},
        "temperament": ent.get("temperament"),
        # Deal sheet (dos/don'ts). Sourced from patron_block; NEVER invented.
        "favor_conditions": list(pb.get("favor_conditions", [])),
        "taboos": list(pb.get("taboos", [])),
        # boon_domains: patron_block value when present, else fall back to the
        # entity's own domains (an honest derivation, not invented content).
        "boon_domains": list(pb.get("boon_domains") or ent.get("domains", [])),
        "blessing_style": pb.get("blessing_style"),  # None if no patron_block
        "casino_roles": list(ent.get("casino_roles", [])),
        "deal_sheet_hints": deal_sheet_hints(ent),
    }
    if resolved:
        rec["notes"] = "PLACEHOLDER numbers (R14). Deal sheet derived from entities.jsonl patron_block; hints restate personality axes per mythology-research-spec §5."
    else:
        rec["notes"] = (
            "UNRESOLVED: shortlisted (wave5-roster-shortlist.md) as a patron, but "
            f"entities.jsonl marks patron_capable=false (entity_class="
            f"{ent.get('entity_class')!r}, casino_roles={ent.get('casino_roles')}) "
            "and ships NO patron_block. Deal-sheet dos/don'ts were NOT fabricated. "
            "Needs an owner ruling — see _meta.unresolved_shortlist."
        )
    return rec


def main() -> int:
    by_id = load_entities()

    # Integrity guard: every shortlisted id must exist in the extraction.
    missing = [(n, i) for n, i in SHORTLIST if i not in by_id]
    if missing:
        for n, i in missing:
            print(f"FATAL: shortlist entry {n!r} -> id {i!r} not found in entities.jsonl")
        return 2

    roster = [build_record(n, by_id[i]) for n, i in SHORTLIST]

    unresolved = [
        {
            "id": r["id"],
            "shortlist_name": r["shortlist_name"],
            "entity_class": by_id[r["id"]].get("entity_class"),
            "casino_roles": by_id[r["id"]].get("casino_roles"),
            "reason": "patron_capable=false and no patron_block in entities.jsonl; "
            "cannot derive a deal sheet without fabricating dos/don'ts.",
            "owner_options": [
                "Grant this entity a patron_block in the Wave-2 data and set "
                "patron_capable=true (then re-run this generator).",
                "Swap the shortlist slot for a patron_capable entity of the same "
                "tradition/archetype (e.g. another West-African trickster).",
            ],
        }
        for r in roster
        if r["status"] == "unresolved"
    ]

    tier_counts: dict[str, int] = {}
    for r in roster:
        tier_counts[r["table_tier"]] = tier_counts.get(r["table_tier"], 0) + 1

    doc = {
        "_meta": {
            "generated_by": "scripts/generate_patron_roster.py",
            "source": "data/mythology/entities.jsonl",
            "shortlist": "docs/design/wave5-roster-shortlist.md (owner-approved 24-god MVP)",
            "design": "docs/design/patron-gods.md",
            "placeholder_notice": "All numbers PLACEHOLDER (R14). deal_sheet_hints values "
            "are direct 1-5 restatements of the entity personality axes "
            "(mythology-research-spec §5), not tuned constants.",
            "supersession_note": "SUPERSEDES the slice stubs in data/patron_gods.json "
            "LATER, not yet: patron_gods.json ids 1-5 stay in place because "
            "data/demo_loadouts.json still references chosen_patron ids 2 (enyo) and "
            "3 (hestia). The migration re-points the demo loadouts first.",
            "deal_sheet_hint_semantics": {
                "boon_frequency/boon_magnitude": "generosity — boon frequency & magnitude; gift chance at affection thresholds",
                "taboo_severity": "strictness — taboo penalty severity",
                "taboo_count": "observed count of taboos on the deal sheet (strictness-correlated)",
                "rival_curse_chance": "pettiness — rival-curse chance when courting other gods",
                "punishment_speed": "wrath — punishment escalation speed after a taboo breach",
                "buyout_resistance": "fidelity — buy-out resistance (low = sells your contract sooner)",
                "buyout_magnet": "fidelity <= 1 — the buy-out-magnet edge case",
                "forsaken_eager": "risk_appetite >= 4 — eager Forsaken host",
                "forsaken_host_candidate": "risk_appetite >= 4 OR influence == 1 (nothing-to-lose proxy; §5 amendment)",
            },
            "roster_count": len(roster),
            "resolved_count": sum(1 for r in roster if r["status"] == "resolved"),
            "table_tier_counts": tier_counts,
            "unresolved_shortlist": unresolved,
        },
        "roster": roster,
    }

    OUT.write_text(
        json.dumps(doc, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )

    # ---- summary ----
    print(f"generate_patron_roster: wrote {OUT.relative_to(ROOT)}")
    print(
        f"  {len(roster)} roster records "
        f"({doc['_meta']['resolved_count']} resolved, {len(unresolved)} unresolved)"
    )
    print("  table tiers: " + ", ".join(f"{k}={v}" for k, v in sorted(tier_counts.items())))
    if unresolved:
        print("  UNRESOLVED (needs owner ruling, not fabricated):")
        for u in unresolved:
            print(f"    - {u['id']} ({u['shortlist_name']}): {u['reason']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
