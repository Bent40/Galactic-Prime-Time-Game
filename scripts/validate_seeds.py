#!/usr/bin/env python3
"""Seed-data integrity validator for Galactic Prime Time.

Run from the repo root (or anywhere): resolves data/ relative to this file.
Checks JSON shape + cross-file references + enum agreement with the SQLite
schema's CHECK constraints (mirrored here as constants; update both together).

Exit codes: 0 = all green, 1 = failures (each printed as FAIL <file>: <msg>).
Wired into `wf validate` via bmad.config.yaml (category: data).
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "data"

# Mirrors of the schema CHECK constraints (001_initial_schema.sql).
STATS = {"physique", "reflexes", "mind", "charm"}
ENEMY_CATEGORIES = {"Mob", "Elite", "Boss", "Super Boss"}
RESISTANCE_CLASSES = {"Physical", "Affliction", "Psychic", "None"}
SIZES = {"Small", "Medium", "Large", "Huge"}  # rules-addendum R7
CONDITION_IDS = {
    "bleeding", "crushed", "suffocation", "chilled", "exhausted",
    "infected", "burn", "poison", "dissolution",
}
FORCED_ACTION_TYPES = {None, "Body", "Tool"}
ITEM_TYPES = {"consumable", "equipment", "weapon", "system_item", "misc", "key_item", "tool"}
PATRON_DOMAINS_MIN = 1  # sketch: docs/design/patron-gods.md — every god needs at least one domain

failures: list[str] = []


def fail(f: str, msg: str) -> None:
    failures.append(f"FAIL {f}: {msg}")


def load(name: str):
    p = DATA / name
    if not p.is_file():
        fail(name, "file missing")
        return None
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        fail(name, f"invalid JSON: {e}")
        return None


def check_unique(name: str, rows: list, field: str) -> None:
    seen = set()
    for r in rows:
        v = r.get(field)
        if v in seen:
            fail(name, f"duplicate {field}: {v!r}")
        seen.add(v)


def check_body_parts(name: str, owner: str, parts, *, need_lethal: bool) -> None:
    if not isinstance(parts, list) or not parts:
        fail(name, f"{owner}: body_parts must be a non-empty list")
        return
    lethal_seen = False
    for p in parts:
        if not isinstance(p, dict):
            fail(name, f"{owner}: body part {p!r} is not an object (per-part HP is required)")
            continue
        for k in ("key", "name", "hp", "lethal"):
            if k not in p:
                fail(name, f"{owner}: part {p.get('key', p)!r} missing field {k!r}")
        if not isinstance(p.get("hp"), int) or p.get("hp", 0) < 1:
            fail(name, f"{owner}: part {p.get('key')!r} hp must be int >= 1")
        if p.get("lethal"):
            lethal_seen = True
    if need_lethal and not lethal_seen:
        fail(name, f"{owner}: no lethal part — nothing can kill it")


def main() -> int:
    races = load("races.json") or []
    enemies = load("enemies.json") or []
    conditions = load("conditions.json") or []
    skills = load("skills.json") or []
    thresholds = load("skill_thresholds.json") or []
    items = load("items.json") or []
    load("modifiers.json")
    load("tags.json")
    # Optional stub until KAN-7 (docs/design/patron-gods.md): validate only if present.
    patrons = load("patron_gods.json") if (DATA / "patron_gods.json").is_file() else []
    if not isinstance(patrons, list):
        fail("patron_gods.json", "top level must be a list")
        patrons = []

    # races
    check_unique("races.json", races, "key")
    for r in races:
        check_body_parts("races.json", r.get("key", "?"), r.get("body_parts"), need_lethal=True)
        if r.get("size") not in SIZES:
            fail("races.json", f"{r.get('key')}: size {r.get('size')!r} not in {sorted(SIZES)}")

    # enemies
    check_unique("enemies.json", enemies, "key")
    for e in enemies:
        k = e.get("key", "?")
        if e.get("category") not in ENEMY_CATEGORIES:
            fail("enemies.json", f"{k}: category {e.get('category')!r} not in {sorted(ENEMY_CATEGORIES)}")
        if e.get("size") not in SIZES:
            fail("enemies.json", f"{k}: size {e.get('size')!r} not in {sorted(SIZES)}")
        check_body_parts("enemies.json", k, e.get("body_parts"), need_lethal=True)
        sb = e.get("stat_block", {})
        if not set(sb).issubset(STATS):
            fail("enemies.json", f"{k}: stat_block keys {sorted(set(sb) - STATS)} invalid")
        res = e.get("resistances", {})
        if not set(res).issubset(RESISTANCE_CLASSES - {"None"}):
            fail("enemies.json", f"{k}: resistance keys {sorted(set(res) - RESISTANCE_CLASSES)} invalid")
        for d in [d for a in e.get("abilities", []) for d in a.get("damage", [])]:
            if d.get("type") not in CONDITION_IDS:
                fail("enemies.json", f"{k}: ability damage type {d.get('type')!r} not a condition id")
        phases = e.get("phases", [])
        nums = [p.get("phase_number") for p in phases]
        if nums != sorted(nums) or len(nums) != len(set(nums)):
            fail("enemies.json", f"{k}: phase_number sequence {nums} not strictly ordered/unique")
        for p in phases:
            if not p.get("trigger_condition"):
                fail("enemies.json", f"{k}: phase {p.get('phase_number')} missing trigger_condition")
        if e.get("category") in ("Boss", "Super Boss"):
            if not phases:
                fail("enemies.json", f"{k}: {e.get('category')} must have phases")
            if "surface_immunity" not in e.get("traits", {}) and not any(
                    "win" in (p.get("trigger_condition") or "").lower() for p in phases):
                # architecture doc: bosses need discoverable win conditions, not damage races
                fail("enemies.json", f"{k}: boss lacks a discoverable win condition "
                                     "(surface_immunity trait or explicit phase win trigger)")

    # conditions
    ids = {c.get("id") for c in conditions}
    if ids != CONDITION_IDS:
        fail("conditions.json", f"condition id set mismatch: missing {sorted(CONDITION_IDS - ids)}, "
                                f"extra {sorted(ids - CONDITION_IDS)}")
    for c in conditions:
        cid = c.get("id", "?")
        if c.get("resistance_type") not in RESISTANCE_CLASSES:
            fail("conditions.json", f"{cid}: resistance_type invalid")
        sr = c.get("spread_rules", {})
        tiers = c.get("tiers", [])
        if "clock_timer" in sr:
            if tiers:
                fail("conditions.json", f"{cid}: timer condition must not define tiers")
            if not isinstance(sr["clock_timer"], int) or sr["clock_timer"] < 1:
                fail("conditions.json", f"{cid}: clock_timer must be int >= 1")
        else:
            mt = sr.get("max_tier")
            nums = [t.get("tier") for t in tiers]
            if nums != list(range(1, len(nums) + 1)):
                fail("conditions.json", f"{cid}: tiers {nums} not contiguous from 1")
            if mt != len(tiers):
                fail("conditions.json", f"{cid}: max_tier {mt} != tier count {len(tiers)}")
            for t in tiers:
                if t.get("forced_action_type") not in FORCED_ACTION_TYPES:
                    fail("conditions.json", f"{cid} T{t.get('tier')}: forced_action_type invalid")
                if not isinstance(t.get("shock_tier"), int) or t["shock_tier"] < 0:
                    fail("conditions.json", f"{cid} T{t.get('tier')}: shock_tier must be int >= 0")

    # items — rpm/magazine are FLAT fields; that is the contract the engine
    # already consumes (action_resolver.gd R8: item.get("rpm"), item.has("magazine")).
    check_unique("items.json", items, "key")
    for i in items:
        k = i.get("key", "?")
        if i.get("item_type") not in ITEM_TYPES:
            fail("items.json", f"{k}: item_type {i.get('item_type')!r} not in {sorted(ITEM_TYPES)}")
        if "rpm" in i and (not isinstance(i["rpm"], int) or i["rpm"] < 1):
            fail("items.json", f"{k}: rpm must be int >= 1 (rounds per 1-Moment attack, R8)")
        if "magazine" in i and (not isinstance(i["magazine"], int) or i["magazine"] < 1):
            fail("items.json", f"{k}: magazine must be int >= 1 (capacity; reload refills it, R8)")
        if "magazine" in i and i.get("item_type") != "weapon":
            fail("items.json", f"{k}: magazine only makes sense on weapons")

    # patron gods (stub schema — docs/design/patron-gods.md)
    check_unique("patron_gods.json", patrons, "key")
    for g in patrons:
        k = g.get("key", "?")
        for f_ in ("key", "name", "origin", "faction", "temperament"):
            if not isinstance(g.get(f_), str) or not g.get(f_):
                fail("patron_gods.json", f"{k}: {f_} must be a non-empty string")
        doms = g.get("domains")
        if not isinstance(doms, list) or len(doms) < PATRON_DOMAINS_MIN \
                or not all(isinstance(d, str) for d in doms):
            fail("patron_gods.json", f"{k}: domains must be a non-empty list of strings")
        for f_ in ("generosity", "power"):
            if not isinstance(g.get(f_), int) or not (1 <= g[f_] <= 5):
                fail("patron_gods.json", f"{k}: {f_} must be int in 1..5")
        for f_ in ("buff_multiplier", "tier_up_bonus", "related_multiplier", "affection_modifier"):
            v = g.get(f_)
            if not isinstance(v, (int, float)) or v < 0:
                fail("patron_gods.json", f"{k}: {f_} must be a number >= 0")
        for f_ in ("favor_conditions", "boon_table", "trial_table", "related"):
            if not isinstance(g.get(f_), list):
                fail("patron_gods.json", f"{k}: {f_} must be a list")
        for rel in g.get("related", []):
            if rel not in {p.get("key") for p in patrons}:
                fail("patron_gods.json", f"{k}: related god {rel!r} is not a patron key")

    # skills
    check_unique("skills.json", skills, "key")
    skill_ids = set()
    for s in skills:
        skill_ids.add(s.get("id"))
        k = s.get("key", "?")
        excl = s.get("exclusive_to")
        if excl is not None and (not isinstance(excl, str) or not excl):
            fail("skills.json", f"{k}: exclusive_to must be a non-empty string (character key) or null")
        if s.get("primary_stat") not in STATS:
            fail("skills.json", f"{k}: primary_stat invalid")
        if s.get("secondary_stat") is not None and s.get("secondary_stat") not in STATS:
            fail("skills.json", f"{k}: secondary_stat invalid")
        if s.get("secondary_stat") == s.get("primary_stat"):
            fail("skills.json", f"{k}: secondary_stat equals primary_stat (schema CHECK)")
        if not isinstance(s.get("base_moment_cost"), int) or s["base_moment_cost"] < 0:
            fail("skills.json", f"{k}: base_moment_cost must be int >= 0")
        if not (0 <= s.get("default_cap", -1) <= 10):
            fail("skills.json", f"{k}: default_cap outside 0..10 (schema CHECK)")

    # skill_thresholds
    check_unique("skill_thresholds.json", thresholds, "id")
    seen_pairs = set()
    for t in thresholds:
        if t.get("skill_id") not in skill_ids:
            fail("skill_thresholds.json", f"id {t.get('id')}: skill_id {t.get('skill_id')} unknown")
        if not (0 <= t.get("level", -1) <= 10):
            fail("skill_thresholds.json", f"id {t.get('id')}: level outside 0..10 (schema CHECK)")
        if t.get("level", 0) < 5:
            fail("skill_thresholds.json", f"id {t.get('id')}: thresholds start at level 5 (rulebook)")
        pair = (t.get("skill_id"), t.get("level"))
        if pair in seen_pairs:
            fail("skill_thresholds.json", f"duplicate (skill_id, level) {pair} (schema UNIQUE)")
        seen_pairs.add(pair)
        if not set(json.loads(json.dumps(t.get("stat_requirements", {})))).issubset(STATS):
            fail("skill_thresholds.json", f"id {t.get('id')}: stat_requirements keys invalid")

    if failures:
        print("\n".join(failures))
        print(f"validate_seeds: {len(failures)} failure(s).")
        return 1
    n = sum(len(x) for x in (races, enemies, conditions, skills, thresholds, items, patrons))
    print(f"validate_seeds: OK ({len(races)} races, {len(enemies)} enemies, "
          f"{len(conditions)} conditions, {len(skills)} skills, {len(thresholds)} thresholds, "
          f"{len(items)} items, {len(patrons)} patron gods — {n} rows checked).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
