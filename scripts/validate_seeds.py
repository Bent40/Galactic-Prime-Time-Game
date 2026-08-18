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
# Goal kinds the sim's HypeEngine can evaluate (simulation/hype_engine.gd).
# I-13 added forced_action (Pratfall!), body_block (Body Block!), move_spaces (Zoomies!).
CROWD_GOAL_KINDS = {"takedown", "overkill", "part_break", "exposed_strike",
                    "forced_action", "body_block", "move_spaces"}
PATRON_DOMAINS_MIN = 1  # sketch: docs/design/patron-gods.md — every god needs at least one domain
# Controlled mythology domain vocabulary (docs/design/mythology-research-spec.md §4 — 26 domains).
MYTHOLOGY_DOMAINS = {
    "war", "hunt", "sea", "sky_storm", "sun_fire", "moon_night", "earth_harvest",
    "death_underworld", "wisdom", "magic", "trickery", "craft_forge", "healing",
    "love_beauty", "music_performance", "luck_gambling", "wealth_commerce",
    "travel_speed", "justice_oaths", "chaos", "beasts_wild", "disease_poison",
    "protection_home", "poetry_story", "madness_dream", "time_fate",
}
# Personality axes (mythology-research-spec §5) — all 1..5.
PERSONALITY_AXES = {"generosity", "strictness", "pettiness", "wrath", "fidelity", "risk_appetite"}
MYTHOLOGY = DATA / "mythology"

failures: list[str] = []
notes: list[str] = []  # non-fatal, documented deviations surfaced on a green run


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


def load_jsonl(rel: str):
    """Load a .jsonl file relative to DATA (e.g. 'mythology/entities.jsonl').

    Returns a list of records, or None if missing / unparseable (records the
    failure). Blank lines are skipped.
    """
    p = DATA / rel
    if not p.is_file():
        fail(rel, "file missing")
        return None
    out = []
    for ln, line in enumerate(p.read_text(encoding="utf-8").splitlines(), 1):
        line = line.strip()
        if not line:
            continue
        try:
            out.append(json.loads(line))
        except json.JSONDecodeError as e:
            fail(rel, f"line {ln}: invalid JSON: {e}")
            return None
    return out


def check_unique(name: str, rows: list, field: str) -> None:
    seen = set()
    for r in rows:
        v = r.get(field)
        if v in seen:
            fail(name, f"duplicate {field}: {v!r}")
        seen.add(v)


def load_loadout_file(name: str):
    """Load a loadout file (demo_loadouts.json / recruit_loadouts.json shape):
    object with _meta + loadouts. Returns the list of loadout rows ([] when the
    file is absent); shape failures are recorded."""
    if not (DATA / name).is_file():
        return []
    doc = load(name)
    if doc is None:
        return []
    if not isinstance(doc, dict) or not isinstance(doc.get("loadouts"), list):
        fail(name, "top level must be an object with a 'loadouts' list")
        return []
    if not isinstance(doc.get("_meta"), dict):
        fail(name, "_meta object required (R14 placeholder notice)")
    for i, lo in enumerate(doc["loadouts"]):
        if not isinstance(lo, dict):
            fail(name, f"loadout {i}: must be an object, got {type(lo).__name__}")
    return [lo for lo in doc["loadouts"] if isinstance(lo, dict)]


def check_loadouts(name: str, loadouts: list, race_ids: set, patron_ids: set,
                   tag_keys: set, skills_by_id: dict) -> None:
    """Per-loadout shape + cross-reference checks, shared by demo_loadouts.json
    and recruit_loadouts.json (decision log #13 / KAN-4 Q68 — same schema)."""
    check_unique(name, loadouts, "id")
    check_unique(name, loadouts, "key")
    for lo in loadouts:
        k = lo.get("key", "?")
        for f_ in ("key", "display_name", "broadcast_persona"):
            if not isinstance(lo.get(f_), str) or not lo.get(f_):
                fail(name, f"{k}: {f_} must be a non-empty string")
        # Authored bit (decision log #25) — OPTIONAL: not everyone has a bit. When
        # present it must be exactly {key, name, line}, all non-empty strings.
        if "bit" in lo:
            bit = lo["bit"]
            if not isinstance(bit, dict) or set(bit) != {"key", "name", "line"}:
                fail(name, f"{k}: bit must be an object with exactly "
                           "{key, name, line} (decision log #25)")
            else:
                for bf in ("key", "name", "line"):
                    if not isinstance(bit.get(bf), str) or not bit.get(bf):
                        fail(name, f"{k}: bit.{bf} must be a non-empty string")
        if lo.get("race") not in race_ids:
            fail(name, f"{k}: race {lo.get('race')!r} is not a races.json id")
        traits = lo.get("traits")
        if not isinstance(traits, dict):
            fail(name, f"{k}: traits must be an object")
        else:
            for stat in sorted(STATS):
                if not isinstance(traits.get(stat), int) or traits[stat] < 1:
                    fail(name, f"{k}: trait {stat} must be int >= 1")
            extra = set(traits) - STATS - {"_placeholder"}
            if extra:
                fail(name, f"{k}: unknown trait keys {sorted(extra)}")
        skl = lo.get("skills")
        if not isinstance(skl, list) or not skl:
            fail(name, f"{k}: skills must be a non-empty list")
            skl = []
        for s in skl:
            if not isinstance(s, dict):
                fail(name, f"{k}: skill entry {s!r} is not an object")
                continue
            tpl = skills_by_id.get(s.get("id"))
            if tpl is None:
                fail(name, f"{k}: skill id {s.get('id')!r} unknown")
                continue
            if "key" in s and s["key"] != tpl.get("key"):
                fail(name, f"{k}: skill id {s['id']} key annotation "
                           f"{s['key']!r} != skills.json {tpl.get('key')!r}")
            cap = tpl.get("default_cap", 0)
            if "cap" in s:
                # R16 trade: a raised cap must exceed the template default (and obey the
                # schema's 0..10 CHECK).
                if not isinstance(s["cap"], int) or not (cap < s["cap"] <= 10):
                    fail(name, f"{k}: {tpl.get('key')}: cap override "
                               f"{s['cap']!r} must be int in {cap + 1}..10 (R16 trade)")
                else:
                    cap = s["cap"]
            if not isinstance(s.get("level"), int) or not (1 <= s["level"] <= cap):
                fail(name, f"{k}: {tpl.get('key')}: level {s.get('level')!r} "
                           f"outside 1..{cap}")
        if not isinstance(lo.get("camera_call_stacks"), int) or lo["camera_call_stacks"] < 0:
            fail(name, f"{k}: camera_call_stacks must be int >= 0")
        if lo.get("chosen_patron") not in patron_ids:
            fail(name, f"{k}: chosen_patron {lo.get('chosen_patron')!r} "
                       "is not a patron_gods.json id")
        lo_tags = lo.get("tags")
        if not isinstance(lo_tags, list):
            fail(name, f"{k}: tags must be a list "
                       "(RULED 2026-07-18: loadouts start tagless)")
        else:
            for tg in lo_tags:
                if tg not in tag_keys:
                    fail(name, f"{k}: tag {tg!r} is not a tags.json key")
        # Story-driven decline policy (decision #32) — OPTIONAL additive key
        # (recruit premades author it; absent = the engine's gone_for_run
        # default). When present it must be one of the two ruled behaviors.
        if "on_decline" in lo and lo["on_decline"] not in ("gone_for_run", "may_reoffer"):
            fail(name, f"{k}: on_decline {lo.get('on_decline')!r} must be "
                       "'gone_for_run' or 'may_reoffer' (decision #32)")
        if lo.get("rewireable") is not True:
            fail(name, f"{k}: rewireable must be true (owner principle, "
                       "slice-contestants §RULED item 9)")


def _skill_book_known_keys():
    """The IMPLEMENTED skill keys, parsed from simulation/skill_book.gd's
    KNOWN_KEYS array (no drifting mirror constant — the source file is the
    authority). Returns None when the array cannot be found."""
    import re
    p = ROOT / "simulation" / "skill_book.gd"
    if not p.is_file():
        return None
    m = re.search(r"const KNOWN_KEYS[^=]*=\s*\[(.*?)\]", p.read_text(encoding="utf-8"), re.S)
    if not m:
        return None
    return re.findall(r'"([^"]+)"', m.group(1))


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
    tags = load("tags.json") or []
    # Optional stub until KAN-7 (docs/design/patron-gods.md): validate only if present.
    patrons = load("patron_gods.json") if (DATA / "patron_gods.json").is_file() else []
    if not isinstance(patrons, list):
        fail("patron_gods.json", "top level must be a list")
        patrons = []
    goals = load("crowd_goals.json") if (DATA / "crowd_goals.json").is_file() else []
    if not isinstance(goals, list):
        fail("crowd_goals.json", "top level must be a list")
        goals = []
    for i, g in enumerate(goals):
        if not isinstance(g, dict):
            fail("crowd_goals.json", f"row {i}: must be an object, got {type(g).__name__}")
    goals = [g for g in goals if isinstance(g, dict)]
    # Demo loadouts (decision log #13; docs/design/slice-contestants-proposal.md §RULED)
    # + recruit premades (KAN-4, owner-approved concept Q68 — PROVISIONAL, same
    # schema): object with _meta + loadouts, not a bare list — validate if present.
    loadouts = load_loadout_file("demo_loadouts.json")
    recruits = load_loadout_file("recruit_loadouts.json")

    # races
    check_unique("races.json", races, "key")
    for r in races:
        check_body_parts("races.json", r.get("key", "?"), r.get("body_parts"), need_lethal=True)
        if r.get("size") not in SIZES:
            fail("races.json", f"{r.get('key')}: size {r.get('size')!r} not in {sorted(SIZES)}")
        # R21 reconciliation item 2 (rules-addendum R21; simulation/creation.gd
        # builds contestants off these plans): every layout needs a
        # torso-equivalent + head-equivalent so torso/head-routed conditions
        # (suffocation/exhausted/infected -> "torso", dissolution -> "head";
        # data/conditions.json target_body_parts) have a landing part. Checked
        # the way the ENGINE actually detects them: ConditionEngine's
        # _equivalent_part fallback asks for the EXACT key "torso"; head
        # detection is the "head" substring (ActionResolver._has_head /
        # lethal_if_head). A future plan keyed differently must teach the
        # engine and this check together.
        part_keys = [p.get("key", "") for p in (r.get("body_parts") or [])
                     if isinstance(p, dict)]
        if "torso" not in part_keys:
            fail("races.json", f"{r.get('key')}: no 'torso' part — torso-routed "
                               "conditions have no landing part (R21)")
        if not any("head" in k for k in part_keys):
            fail("races.json", f"{r.get('key')}: no head-equivalent part — "
                               "dissolution/head routing has no landing part (R21)")

    # enemies
    check_unique("enemies.json", enemies, "key")
    enemy_keys = {e.get("key") for e in enemies}
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
        # R23 personality block (the Antagonism engine's tuning surface,
        # decision #29): optional; when present the biases are numbers >= 0,
        # mock_sensitive is a bool, note is free-form. spare_respect is the
        # RESERVED sparing hook — carried and validated, read by nothing yet.
        # R15 pack synergy (wave 3a): pack_hunter is a bool gate, pack is the
        # non-empty family string; a pack_hunter without a pack never links,
        # so authoring one without the other is flagged.
        # Wave 4d herding (R11 #21): herder is a bool gate riding the SAME
        # pack family; a herder without a pack never splits roles, flagged
        # like the pack_hunter case.
        pers = e.get("personality")
        if pers is not None:
            if not isinstance(pers, dict):
                fail("enemies.json", f"{k}: personality must be an object (R23)")
            else:
                allowed = {"proximity_bias", "grudge_weight", "mock_sensitive",
                           "mock_grudge", "low_hp_bias", "decay", "spare_respect", "note",
                           "pack_hunter", "pack", "herder"}
                extra = set(pers) - allowed
                if extra:
                    fail("enemies.json", f"{k}: personality keys {sorted(extra)} invalid (R23)")
                for fk in ("proximity_bias", "grudge_weight", "mock_grudge",
                           "low_hp_bias", "decay", "spare_respect"):
                    v = pers.get(fk)
                    if v is not None and (isinstance(v, bool) or not isinstance(v, (int, float)) or v < 0):
                        fail("enemies.json", f"{k}: personality.{fk} must be a number >= 0 (R23)")
                if "mock_sensitive" in pers and not isinstance(pers["mock_sensitive"], bool):
                    fail("enemies.json", f"{k}: personality.mock_sensitive must be a bool (R23)")
                if "pack_hunter" in pers and not isinstance(pers["pack_hunter"], bool):
                    fail("enemies.json", f"{k}: personality.pack_hunter must be a bool (R15 wave 3a)")
                if "pack" in pers and (not isinstance(pers["pack"], str) or not pers["pack"]):
                    fail("enemies.json", f"{k}: personality.pack must be a non-empty string (R15 wave 3a)")
                if pers.get("pack_hunter") and not pers.get("pack"):
                    fail("enemies.json", f"{k}: pack_hunter without a pack family never links (R15 wave 3a)")
                if "herder" in pers and not isinstance(pers["herder"], bool):
                    fail("enemies.json", f"{k}: personality.herder must be a bool (wave 4d, R11 #21)")
                if pers.get("herder") and not pers.get("pack"):
                    fail("enemies.json", f"{k}: herder without a pack family never splits roles (wave 4d, R11 #21)")
        # abilities — the shapes EnemyAI v1 consumes (simulation/enemy_ai.gd):
        # damage list (strike), range/area reach, summon, heal.
        for a in e.get("abilities", []):
            ak = a.get("key", "?")
            if "moment_cost" in a and (not isinstance(a["moment_cost"], int) or a["moment_cost"] < 0):
                fail("enemies.json", f"{k}/{ak}: moment_cost must be int >= 0")
            if "range" in a and (not isinstance(a["range"], int) or a["range"] < 1):
                fail("enemies.json", f"{k}/{ak}: range must be int >= 1 (spaces, R10/B8)")
            area = a.get("area")
            if area is not None and area.startswith("cone"):
                parts = area.split(" ")
                if len(parts) != 2 or not parts[1].isdigit() or int(parts[1]) < 1:
                    fail("enemies.json", f"{k}/{ak}: cone area must be 'cone <spaces>=1>' (AI v1 reach)")
            for d in a.get("damage", []):
                if d.get("type") not in CONDITION_IDS:
                    fail("enemies.json", f"{k}: ability damage type {d.get('type')!r} not a condition id")
            if "summon" in a:
                s = a["summon"]
                if not isinstance(s, dict) or s.get("enemy_key") not in enemy_keys:
                    fail("enemies.json", f"{k}/{ak}: summon.enemy_key must reference an enemy key")
                if not isinstance(s.get("count"), int) or s.get("count", 0) < 1:
                    fail("enemies.json", f"{k}/{ak}: summon.count must be int >= 1")
            if "heal" in a:
                h = a["heal"]
                if not isinstance(h, dict) or not isinstance(h.get("amount"), int) or h["amount"] < 1:
                    fail("enemies.json", f"{k}/{ak}: heal.amount must be int >= 1")
                if h.get("target") not in (None, "self"):
                    fail("enemies.json", f"{k}/{ak}: heal.target {h.get('target')!r} unsupported (AI v1: self only)")
            # R26 undodgable flag (owner 2026-07-25, decision #32): data-driven,
            # additive — when present it must be a bool.
            if "undodgable" in a and not isinstance(a["undodgable"], bool):
                fail("enemies.json", f"{k}/{ak}: undodgable must be a bool (R26)")
            # R22 ability dodge block (the Dash counters ladder): threshold asks the
            # target's Reflexes; counter_at (optional) gates the counterattack rider.
            if "dodge" in a:
                dg = a["dodge"]
                if not isinstance(dg, dict) or not isinstance(dg.get("threshold"), int) or dg["threshold"] < 1:
                    fail("enemies.json", f"{k}/{ak}: dodge.threshold must be int >= 1 (R22)")
                elif "counter_at" in dg and (not isinstance(dg["counter_at"], int) or dg["counter_at"] < dg["threshold"]):
                    fail("enemies.json", f"{k}/{ak}: dodge.counter_at must be int >= dodge.threshold (R22)")
        # dodge threshold (boss ability pattern, R2 + R22): the threshold asks the
        # dodger's Reflexes (+ the stat's threshold die on the fallback), so any
        # positive int is legal — an unreachable ask is an intended impossible dodge.
        dt = e.get("traits", {}).get("dodge_threshold")
        if dt is not None and (not isinstance(dt, int) or dt < 1):
            fail("enemies.json", f"{k}: traits.dodge_threshold must be int >= 1 (R22 Reflexes ask)")
        phases = e.get("phases", [])
        nums = [p.get("phase_number") for p in phases]
        if nums != sorted(nums) or len(nums) != len(set(nums)):
            fail("enemies.json", f"{k}: phase_number sequence {nums} not strictly ordered/unique")
        for p in phases:
            if not p.get("trigger_condition"):
                fail("enemies.json", f"{k}: phase {p.get('phase_number')} missing trigger_condition")
        # explosion phases drive the machine (R11 #18): each needs a structured
        # hp_at_or_below, and the thresholds must strictly descend.
        explosion_thresholds = []
        for p in phases:
            if "explosion" in p.get("behavior", {}):
                t = p.get("hp_at_or_below")
                if not isinstance(t, int) or t < 0:
                    fail("enemies.json", f"{k}: explosion phase {p.get('phase_number')} needs hp_at_or_below int >= 0")
                else:
                    explosion_thresholds.append(t)
                # R26 undodgable flag (owner 2026-07-25, decision #32): data-driven,
                # additive — when present on an explosion block it must be a bool.
                ex = p["behavior"]["explosion"]
                if isinstance(ex, dict) and "undodgable" in ex and not isinstance(ex["undodgable"], bool):
                    fail("enemies.json", f"{k}: explosion phase {p.get('phase_number')} undodgable must be a bool (R26)")
            elif "hp_at_or_below" in p:
                fail("enemies.json", f"{k}: phase {p.get('phase_number')} has hp_at_or_below but no explosion (fight bands derive from the previous threshold)")
        if explosion_thresholds != sorted(explosion_thresholds, reverse=True) or \
                len(explosion_thresholds) != len(set(explosion_thresholds)):
            fail("enemies.json", f"{k}: explosion hp_at_or_below sequence {explosion_thresholds} must strictly descend")
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
        for f_ in ("generosity", "power", "influence"):
            if not isinstance(g.get(f_), int) or not (1 <= g[f_] <= 5):
                fail("patron_gods.json", f"{k}: {f_} must be int in 1..5")
        for f_ in ("buff_multiplier", "tier_up_bonus", "related_multiplier", "affection_modifier"):
            v = g.get(f_)
            if not isinstance(v, (int, float)) or v < 0:
                fail("patron_gods.json", f"{k}: {f_} must be a number >= 0")
        for f_ in ("favor_conditions", "taboos", "boon_table", "trial_table", "related"):
            if not isinstance(g.get(f_), list):
                fail("patron_gods.json", f"{k}: {f_} must be a list")
        for rel in g.get("related", []):
            if rel not in {p.get("key") for p in patrons}:
                fail("patron_gods.json", f"{k}: related god {rel!r} is not a patron key")

    # crowd goals (spectacle engine v1 — simulation/hype_engine.gd predicates;
    # every numeric value here is a PLACEHOLDER pending tuning, R14)
    check_unique("crowd_goals.json", goals, "id")
    for g in goals:
        k = g.get("id", "?")
        for f_ in ("id", "name", "kind"):
            if not isinstance(g.get(f_), str) or not g.get(f_):
                fail("crowd_goals.json", f"{k}: {f_} must be a non-empty string")
        if g.get("kind") not in CROWD_GOAL_KINDS:
            fail("crowd_goals.json", f"{k}: kind {g.get('kind')!r} not implemented by HypeEngine")
        if not isinstance(g.get("params"), dict):
            fail("crowd_goals.json", f"{k}: params must be an object")
        if not isinstance(g.get("payout"), int) or g.get("payout", 0) <= 0:
            fail("crowd_goals.json", f"{k}: payout must be int > 0")
        if not isinstance(g.get("deadline_clocks"), int) or g.get("deadline_clocks", 0) < 1:
            fail("crowd_goals.json", f"{k}: deadline_clocks must be int >= 1")
        if g.get("kind") == "overkill":
            th = g.get("params", {}).get("threshold") if isinstance(g.get("params"), dict) else None
            if not isinstance(th, int) or th <= 0:
                fail("crowd_goals.json", f"{k}: overkill needs params.threshold int > 0")
        if g.get("kind") == "move_spaces":
            sp = g.get("params", {}).get("spaces") if isinstance(g.get("params"), dict) else None
            if not isinstance(sp, int) or sp <= 0:
                fail("crowd_goals.json", f"{k}: move_spaces needs params.spaces int > 0")
        if g.get("kind") == "body_block":
            rk = g.get("params", {}).get("reaction_keys") if isinstance(g.get("params"), dict) else None
            if not isinstance(rk, list) or not all(isinstance(x, str) and x for x in rk or []):
                fail("crowd_goals.json", f"{k}: body_block needs params.reaction_keys list of strings")

    # tag_effects (I-13 slice tags — simulation/tag_engine.gd). Object with
    # _meta + a 'tags' list; keys AND names must match data/tags.json exactly
    # (tags.json is the ported catalog of record). All numbers PLACEHOLDER (R14).
    tag_by_key = {t.get("key"): t for t in tags}
    te_rows: list = []
    if (DATA / "tag_effects.json").is_file():
        te = load("tag_effects.json")
        if not isinstance(te, dict) or not isinstance(te.get("tags"), list):
            fail("tag_effects.json", "top level must be an object with a 'tags' list")
        else:
            if not isinstance(te.get("_meta"), dict):
                fail("tag_effects.json", "_meta object required (R14 placeholder + provenance)")
            te_rows = [r for r in te["tags"] if isinstance(r, dict)]
            if len(te_rows) != len(te["tags"]):
                fail("tag_effects.json", "every tag entry must be an object")
            check_unique("tag_effects.json", te_rows, "key")
            for r in te_rows:
                k = r.get("key", "?")
                src = tag_by_key.get(k)
                if src is None:
                    fail("tag_effects.json", f"{k}: key does not resolve to a data/tags.json tag")
                elif r.get("name") != src.get("name"):
                    fail("tag_effects.json", f"{k}: name {r.get('name')!r} != tags.json {src.get('name')!r}")
                doms = r.get("domains")
                if not isinstance(doms, list) or not doms or not all(isinstance(d, str) for d in doms):
                    fail("tag_effects.json", f"{k}: domains must be a non-empty list of strings")
                else:
                    for d in doms:
                        if d not in MYTHOLOGY_DOMAINS:
                            fail("tag_effects.json", f"{k}: domain {d!r} not in the controlled vocab")
                det = r.get("detector")
                if not isinstance(det, dict) or not isinstance(det.get("events"), list) or not det["events"]:
                    fail("tag_effects.json", f"{k}: detector.events must be a non-empty list")
                unlock = r.get("unlock")
                if not isinstance(unlock, dict) or not isinstance(unlock.get("count"), int) or unlock.get("count", 0) < 1:
                    fail("tag_effects.json", f"{k}: unlock.count must be int >= 1")
                res = r.get("resonance")
                if not isinstance(res, dict) or not isinstance(res.get("selectors"), list):
                    fail("tag_effects.json", f"{k}: resonance.selectors must be a list")
                elif not isinstance(res.get("resonance_pct"), int) or res.get("resonance_pct", 0) < 100:
                    fail("tag_effects.json", f"{k}: resonance.resonance_pct must be int >= 100")
                if not isinstance(r.get("earned_on_camera"), bool):
                    fail("tag_effects.json", f"{k}: earned_on_camera must be a boolean")
            # RULED item 8: the slice carries exactly ONE pattern-5 rider (the_bit).
            riders = sorted(r.get("key") for r in te_rows if "rider" in r)
            if riders != ["the_bit"]:
                fail("tag_effects.json", f"exactly one rider (the_bit) allowed, got {riders}")
            bit = next((r for r in te_rows if r.get("key") == "the_bit"), None)
            if bit is not None:
                rider = bit.get("rider", {})
                for f_ in ("base_spectacle", "bonus_per_prior"):
                    if not isinstance(rider.get(f_), int) or rider.get(f_, -1) < 0:
                        fail("tag_effects.json", f"the_bit: rider.{f_} must be int >= 0")

    # skills
    check_unique("skills.json", skills, "key")
    skill_ids = set()
    for s in skills:
        skill_ids.add(s.get("id"))
        k = s.get("key", "?")
        # G7 RULED (owner 2026-08-18, decision #33): NO exclusive skills — acquisition
        # requirements instead. The field is retired; its presence is now an error.
        if s.get("exclusive_to") is not None:
            fail("skills.json", f"{k}: exclusive_to is retired (G7 — no exclusive skills; use an 'acquisition' gate)")
        acq = s.get("acquisition")
        if acq is not None and (not isinstance(acq, str) or not acq):
            fail("skills.json", f"{k}: acquisition must be a non-empty string when present")
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

    # ---- Wave 3b: G3 keyword tree + Gemstone mutation recipes ----------------
    # skill_keywords.json — the RULED per-skill Gemstone keywords (G3, owner
    # 2026-07-23; book §4.5 taxonomy; verbatim port of the char-sheet repo's
    # apply-skill-passover.js KEYWORDS map + G6 new-skill seeds). Validate if
    # present. Consumed by simulation/skill_keywords.gd / skill_forge.gd.
    kw_doc = None
    kw_skills: dict = {}
    if (DATA / "skill_keywords.json").is_file():
        kw_doc = load("skill_keywords.json")
        if not isinstance(kw_doc, dict) or not isinstance(kw_doc.get("taxonomy"), dict) \
                or not isinstance(kw_doc.get("skills"), dict):
            fail("skill_keywords.json", "top level must be an object with 'taxonomy' "
                                        "and 'skills' objects")
            kw_doc = None
        else:
            if not isinstance(kw_doc.get("_meta"), dict):
                fail("skill_keywords.json", "_meta object required (G3 provenance)")
            taxonomy = kw_doc["taxonomy"]
            broad = set()
            narrow = set()
            for b, ns in taxonomy.items():
                if not isinstance(b, str) or not b:
                    fail("skill_keywords.json", f"broad group {b!r} must be a non-empty string")
                    continue
                broad.add(b)
                if not isinstance(ns, list) or not ns \
                        or not all(isinstance(n, str) and n for n in ns):
                    fail("skill_keywords.json", f"{b}: narrow members must be a non-empty "
                                                "list of non-empty strings")
                    continue
                for n in ns:
                    if n in narrow:
                        fail("skill_keywords.json", f"narrow keyword {n!r} appears in two "
                                                    "broad groups — classification must be unambiguous")
                    narrow.add(n)
            overlap = broad & narrow
            if overlap:
                fail("skill_keywords.json", f"keywords {sorted(overlap)} are both broad and "
                                            "narrow — the §4.5 hierarchy keeps them disjoint")
            vocab = broad | narrow
            kw_skills = kw_doc["skills"]
            for sk, kws in kw_skills.items():
                if not isinstance(sk, str) or not sk:
                    fail("skill_keywords.json", f"skill key {sk!r} must be a non-empty string")
                    continue
                if not isinstance(kws, list) or not (2 <= len(kws) <= 4):
                    fail("skill_keywords.json", f"{sk}: must carry 2..4 keywords "
                                                f"(book §4.5), got {kws!r}")
                    continue
                if len(set(kws)) != len(kws):
                    fail("skill_keywords.json", f"{sk}: duplicate keywords in {kws}")
                for kw in kws:
                    if not isinstance(kw, str) or not kw:
                        fail("skill_keywords.json", f"{sk}: empty/non-string keyword")
                    elif kw not in vocab:
                        fail("skill_keywords.json", f"{sk}: keyword {kw!r} is not in the "
                                                    "§4.5 taxonomy (broad or narrow)")
            # Every IMPLEMENTED sim skill needs its ruled keywords. The list of
            # implemented keys is parsed from simulation/skill_book.gd
            # KNOWN_KEYS (no drifting mirror).
            known = _skill_book_known_keys()
            if known is None:
                fail("skill_keywords.json", "cannot parse KNOWN_KEYS from "
                                            "simulation/skill_book.gd (check moved/renamed?)")
            else:
                for k in known:
                    if k not in kw_skills:
                        fail("skill_keywords.json", f"implemented skill {k!r} "
                                                    "(SkillBook.KNOWN_KEYS) has no keyword entry")
            # Non-fatal: catalog skills still awaiting a ruled assignment
            # (today: reversion — postdates the 44-row passover table).
            for s in skills:
                if s.get("key") not in kw_skills:
                    notes.append(f"NOTE skill_keywords.json: {s.get('key')!r} (skills.json) "
                                 "has no ruled keyword assignment — awaiting owner")

    # skill_mutations.json — authored Gemstone mutation recipes (G6; engine:
    # simulation/skill_forge.gd). Validate if present; cross-checks the G3
    # narrow-shared rule against skill_keywords.json.
    mutations: list = []
    if (DATA / "skill_mutations.json").is_file():
        mu = load("skill_mutations.json")
        if not isinstance(mu, dict) or not isinstance(mu.get("mutations"), list):
            fail("skill_mutations.json", "top level must be an object with a 'mutations' list")
        else:
            if not isinstance(mu.get("_meta"), dict):
                fail("skill_mutations.json", "_meta object required (G6 provenance + economy note)")
            mutations = [m for m in mu["mutations"] if isinstance(m, dict)]
            if len(mutations) != len(mu["mutations"]):
                fail("skill_mutations.json", "every mutation must be an object")
            check_unique("skill_mutations.json", mutations, "key")
            for m in mutations:
                k = m.get("key", "?")
                for f_ in ("key", "name", "note"):
                    if not isinstance(m.get(f_), str) or not m.get(f_):
                        fail("skill_mutations.json", f"{k}: {f_} must be a non-empty string")
                parents = m.get("parents")
                pkeys: list = []
                if not isinstance(parents, list) or len(parents) < 2:
                    fail("skill_mutations.json", f"{k}: parents must be a list of >= 2 rows")
                else:
                    for p in parents:
                        if not isinstance(p, dict) or not isinstance(p.get("key"), str) \
                                or not p.get("key") or not isinstance(p.get("min_level"), int) \
                                or p["min_level"] < 1:
                            fail("skill_mutations.json", f"{k}: parent {p!r} must be "
                                                         "{key: str, min_level: int >= 1}")
                            continue
                        if p["key"] in pkeys:
                            fail("skill_mutations.json", f"{k}: duplicate parent {p['key']!r}")
                        pkeys.append(p["key"])
                res = m.get("result")
                if not isinstance(res, dict) or not isinstance(res.get("key"), str) \
                        or not res.get("key") or not isinstance(res.get("level"), int) \
                        or res["level"] < 1:
                    fail("skill_mutations.json", f"{k}: result must be {{key: str, level: int >= 1}}")
                elif res["key"] in pkeys:
                    fail("skill_mutations.json", f"{k}: result {res['key']!r} is also a parent")
                if "compatibility_override" in m:
                    if not isinstance(m["compatibility_override"], bool):
                        fail("skill_mutations.json", f"{k}: compatibility_override must be a bool")
                    elif m["compatibility_override"]:
                        # An override is LEGAL but loud — it is the authored
                        # record of a GM call past the G3 narrow rule.
                        notes.append(f"NOTE skill_mutations.json: {k} carries "
                                     "compatibility_override — parents cleared by GM "
                                     "fiat, not the narrow-keyword rule (G3)")
                if kw_doc is not None:
                    for ref in pkeys + ([res["key"]] if isinstance(res, dict)
                                        and isinstance(res.get("key"), str) else []):
                        if ref not in kw_skills:
                            fail("skill_mutations.json", f"{k}: {ref!r} has no "
                                                         "skill_keywords.json entry")
                    # G3: parents pairwise share a NARROW keyword, unless the
                    # recipe carries the explicit authored override.
                    if not m.get("compatibility_override", False):
                        narrows = {n for ns in kw_doc["taxonomy"].values() for n in ns}
                        for i in range(len(pkeys)):
                            for j in range(i + 1, len(pkeys)):
                                a, b = pkeys[i], pkeys[j]
                                shared = set(kw_skills.get(a, [])) & set(kw_skills.get(b, [])) & narrows
                                if not shared:
                                    fail("skill_mutations.json",
                                         f"{k}: parents {a!r} x {b!r} share no NARROW "
                                         "keyword (G3 — broad-only is the GM-call tier; "
                                         "needs an authored compatibility_override)")

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

    # demo loadouts (Imani/Dario demo kits — decision log #13; NOT canon characters,
    # every number PLACEHOLDER per R14) + recruit premades (KAN-4 Q68 — Sasha &
    # Nikita, PROVISIONAL pending owner review; identical schema + checks)
    race_ids = {r.get("id") for r in races}
    patron_ids = {p.get("id") for p in patrons}
    tag_keys = {t.get("key") for t in tags}
    skills_by_id = {s.get("id"): s for s in skills}
    check_loadouts("demo_loadouts.json", loadouts, race_ids, patron_ids, tag_keys, skills_by_id)
    check_loadouts("recruit_loadouts.json", recruits, race_ids, patron_ids, tag_keys, skills_by_id)

    # ---- Wave 5: patron roster + domain->condition map -----------------------
    # patron_roster.json is generated by scripts/generate_patron_roster.py from
    # data/mythology/entities.jsonl. Validate only if present (optional artifact).
    roster: list = []
    if (DATA / "patron_roster.json").is_file():
        pr = load("patron_roster.json")
        if not isinstance(pr, dict) or not isinstance(pr.get("roster"), list):
            fail("patron_roster.json", "top level must be an object with a 'roster' list")
        else:
            meta = pr.get("_meta")
            if not isinstance(meta, dict):
                fail("patron_roster.json", "_meta object required (R14 placeholder + provenance)")
                meta = {}
            # Index the mythology extraction the generator drew from.
            ents = load_jsonl("mythology/entities.jsonl") or []
            ent_by_id = {e.get("id"): e for e in ents if isinstance(e, dict)}
            # An 'unresolved' roster entry is only legal if it is DECLARED in
            # _meta.unresolved_shortlist — no silently-broken records.
            declared_unresolved = {
                u.get("id") for u in meta.get("unresolved_shortlist", [])
                if isinstance(u, dict)
            }
            roster = [r for r in pr["roster"] if isinstance(r, dict)]
            if len(roster) != len(pr["roster"]):
                fail("patron_roster.json", "every roster entry must be an object")
            check_unique("patron_roster.json", roster, "id")
            required = ("id", "name", "tradition", "influence", "table_tier", "domains",
                        "personality", "favor_conditions", "taboos", "boon_domains",
                        "blessing_style", "casino_roles", "deal_sheet_hints")
            for r in roster:
                rid = r.get("id", "?")
                ent = ent_by_id.get(r.get("id"))
                # every id must resolve to a real mythology entity
                if ent is None:
                    fail("patron_roster.json", f"{rid}: id does not resolve to a "
                                               "data/mythology/entities.jsonl entity")
                status = r.get("status", "resolved")
                if status not in ("resolved", "unresolved"):
                    fail("patron_roster.json", f"{rid}: status {status!r} not in resolved|unresolved")
                if status == "resolved":
                    # resolved patrons MUST be patron_capable, with a real deal sheet
                    if ent is not None and not ent.get("patron_capable"):
                        fail("patron_roster.json", f"{rid}: status 'resolved' but entity is not patron_capable")
                    if not r.get("favor_conditions"):
                        fail("patron_roster.json", f"{rid}: resolved patron needs non-empty favor_conditions")
                    if not r.get("boon_domains"):
                        fail("patron_roster.json", f"{rid}: resolved patron needs non-empty boon_domains")
                    if not isinstance(r.get("blessing_style"), str) or not r.get("blessing_style"):
                        fail("patron_roster.json", f"{rid}: resolved patron needs a blessing_style string")
                else:
                    # 'unresolved' is only allowed if declared AND the entity genuinely
                    # is not patron_capable (can't hide a valid patron as unresolved).
                    if r.get("id") not in declared_unresolved:
                        fail("patron_roster.json", f"{rid}: status 'unresolved' but not "
                                                   "declared in _meta.unresolved_shortlist")
                    if ent is not None and ent.get("patron_capable"):
                        fail("patron_roster.json", f"{rid}: marked 'unresolved' but entity IS patron_capable")
                for f_ in required:
                    if f_ not in r:
                        fail("patron_roster.json", f"{rid}: missing required field {f_!r}")
                doms = r.get("domains")
                if not isinstance(doms, list) or not all(isinstance(d, str) for d in doms or []):
                    fail("patron_roster.json", f"{rid}: domains must be a list of strings")
                for d in doms or []:
                    if d not in MYTHOLOGY_DOMAINS:
                        fail("patron_roster.json", f"{rid}: domain {d!r} not in the controlled vocab")
                for d in r.get("boon_domains") or []:
                    if d not in MYTHOLOGY_DOMAINS:
                        fail("patron_roster.json", f"{rid}: boon_domain {d!r} not in the controlled vocab")
                if not isinstance(r.get("influence"), int) or not (1 <= r.get("influence", 0) <= 5):
                    fail("patron_roster.json", f"{rid}: influence must be int in 1..5")
                p = r.get("personality")
                if not isinstance(p, dict) or set(p) != PERSONALITY_AXES:
                    fail("patron_roster.json", f"{rid}: personality must carry exactly the 6 axes "
                                               f"{sorted(PERSONALITY_AXES)}")
                else:
                    for a, v in p.items():
                        if not isinstance(v, int) or not (1 <= v <= 5):
                            fail("patron_roster.json", f"{rid}: personality.{a} must be int in 1..5")
                if not isinstance(r.get("deal_sheet_hints"), dict) or not r.get("deal_sheet_hints"):
                    fail("patron_roster.json", f"{rid}: deal_sheet_hints must be a non-empty object")
                for f_ in ("favor_conditions", "taboos", "boon_domains", "casino_roles"):
                    if not isinstance(r.get(f_), list):
                        fail("patron_roster.json", f"{rid}: {f_} must be a list")
            # Surface the documented unresolved slot(s) even on a green run.
            for u in meta.get("unresolved_shortlist", []):
                if isinstance(u, dict):
                    notes.append(f"NOTE patron_roster.json: {u.get('id')} "
                                 f"({u.get('shortlist_name')}) is UNRESOLVED — {u.get('reason')}")

    # domain_condition_map.json — keys are valid domains, values valid condition ids.
    dcmap_pairs = 0
    if (DATA / "domain_condition_map.json").is_file():
        dc = load("domain_condition_map.json")
        if not isinstance(dc, dict) or not isinstance(dc.get("domain_conditions"), dict):
            fail("domain_condition_map.json", "top level must be an object with a "
                                              "'domain_conditions' object")
        else:
            dcm = dc["domain_conditions"]
            for dom, spec in dcm.items():
                if dom not in MYTHOLOGY_DOMAINS:
                    fail("domain_condition_map.json", f"key {dom!r} is not a controlled domain")
                if not isinstance(spec, dict) or not isinstance(spec.get("conditions"), list):
                    fail("domain_condition_map.json", f"{dom}: must be an object with a 'conditions' list")
                    continue
                for c in spec["conditions"]:
                    if c not in CONDITION_IDS:
                        fail("domain_condition_map.json", f"{dom}: condition {c!r} is not a rulebook condition id")
                dcmap_pairs += len(spec["conditions"])
            missing_domains = MYTHOLOGY_DOMAINS - set(dcm)
            if missing_domains:
                fail("domain_condition_map.json", f"missing domain entries: {sorted(missing_domains)}")

    # ---- KAN-5 wave 3d: demo_run encounter ARENA blocks ---------------------
    # Additive: validated only when data/demo_run.json exists. Mirrors the
    # engine's set_arena/staging gates (simulation/arena.gd + combat_sim.gd):
    # bounds shape sane, walls in bounds, objects (trash cans) in bounds and
    # off walls, doors (wave 4b) in bounds and off walls/objects/other doors,
    # and NO wall/object/door on any staged spawn hex.
    arena_count = 0
    door_count = 0
    exit_count = 0
    if (DATA / "demo_run.json").is_file():
        dr = load("demo_run.json")
        run = dr.get("run", {}) if isinstance(dr, dict) else {}
        party_specs = run.get("party", []) if isinstance(run, dict) else []

        def _hex(pair):
            if isinstance(pair, list) and len(pair) == 2 \
                    and all(isinstance(v, int) for v in pair):
                return (pair[0], pair[1])
            return None

        for ei, enc in enumerate(run.get("encounters", []) or []):
            if not isinstance(enc, dict) or "arena" not in enc:
                continue
            arena_count += 1
            where = f"encounters[{ei}] ({enc.get('key', '?')}) arena"
            arena = enc.get("arena")
            if not isinstance(arena, dict):
                fail("demo_run.json", f"{where}: must be an object")
                continue
            bounds = arena.get("bounds")
            in_bounds = None
            if isinstance(bounds, dict) and isinstance(bounds.get("hexes"), list):
                hex_set = set()
                for pair in bounds["hexes"]:
                    h = _hex(pair)
                    if h is None:
                        fail("demo_run.json", f"{where}: bad bounds hex {pair!r}")
                    else:
                        hex_set.add(h)
                if not hex_set:
                    fail("demo_run.json", f"{where}: empty explicit bounds")
                in_bounds = lambda h, s=hex_set: h in s
            elif isinstance(bounds, dict):
                w, hgt = bounds.get("width"), bounds.get("height")
                if not (isinstance(w, int) and isinstance(hgt, int) and w >= 1 and hgt >= 1):
                    fail("demo_run.json", f"{where}: rect bounds need int width/height >= 1")
                    continue
                origin = _hex(bounds.get("origin")) if "origin" in bounds \
                    else (-(w // 2), -(hgt // 2))
                if origin is None:
                    fail("demo_run.json", f"{where}: bad bounds origin")
                    continue
                in_bounds = lambda h, o=origin, w=w, hg=hgt: \
                    o[0] <= h[0] < o[0] + w and o[1] <= h[1] < o[1] + hg
            else:
                fail("demo_run.json", f"{where}: bounds object required")
                continue
            walls = set()
            for pair in arena.get("walls", []) or []:
                h = _hex(pair)
                if h is None:
                    fail("demo_run.json", f"{where}: bad wall hex {pair!r}")
                    continue
                if not in_bounds(h):
                    fail("demo_run.json", f"{where}: wall {list(h)} outside the bounds")
                walls.add(h)
            objects = set()
            for obj in arena.get("objects", []) or []:
                if not isinstance(obj, dict) or not obj.get("key"):
                    fail("demo_run.json", f"{where}: object needs a non-empty key")
                    continue
                h = _hex(obj.get("position"))
                if h is None:
                    fail("demo_run.json", f"{where}: object {obj.get('key')!r} bad position")
                    continue
                if not in_bounds(h):
                    fail("demo_run.json", f"{where}: object at {list(h)} outside the bounds")
                if h in walls:
                    fail("demo_run.json", f"{where}: object at {list(h)} sits on a wall")
                if h in objects:
                    fail("demo_run.json", f"{where}: two objects share hex {list(h)}")
                objects.add(h)
                burn = obj.get("burn", 0)
                if not isinstance(burn, int) or burn < 0:
                    fail("demo_run.json", f"{where}: object burn must be int >= 0")
            # Doors (wave 4b, R29): mirrors Arena.from_config (shape) +
            # CombatSim._set_arena (placement) — unique non-empty keys, a
            # ruled state, in bounds, off walls/objects/other doors.
            doors = set()
            door_keys = set()
            for door in arena.get("doors", []) or []:
                if not isinstance(door, dict) or not door.get("key"):
                    fail("demo_run.json", f"{where}: door needs a non-empty key")
                    continue
                dk = door.get("key")
                if dk in door_keys:
                    fail("demo_run.json", f"{where}: duplicate door key {dk!r}")
                door_keys.add(dk)
                if door.get("state") not in ("open", "closed"):
                    fail("demo_run.json", f"{where}: door {dk!r} state "
                                          f"{door.get('state')!r} must be 'open' or 'closed'")
                h = _hex(door.get("position"))
                if h is None:
                    fail("demo_run.json", f"{where}: door {dk!r} bad position")
                    continue
                if not in_bounds(h):
                    fail("demo_run.json", f"{where}: door {dk!r} at {list(h)} outside the bounds")
                if h in walls:
                    fail("demo_run.json", f"{where}: door {dk!r} at {list(h)} sits on a wall")
                if h in objects:
                    fail("demo_run.json", f"{where}: door {dk!r} at {list(h)} sits on an object")
                if h in doors:
                    fail("demo_run.json", f"{where}: two doors share hex {list(h)}")
                doors.add(h)
                door_count += 1
            # Spawn hexes: enemies (position/positions), staged allies, and the
            # party (encounter 0 uses the party specs' own positions; later
            # encounters restage via party_positions).
            spawns = []
            for row in enc.get("enemies", []) or []:
                if not isinstance(row, dict):
                    continue
                pos_list = row.get("positions") or ([row.get("position")] if row.get("position") else [])
                for pair in pos_list:
                    spawns.append((row.get("enemy_key", "?"), _hex(pair)))
            for ally in enc.get("allies", []) or []:
                spec = ally.get("spec", {}) if isinstance(ally, dict) else {}
                spawns.append((spec.get("id", "ally"), _hex(spec.get("position", [0, 0]))))
            pp = enc.get("party_positions")
            if isinstance(pp, dict):
                for pid, pair in pp.items():
                    spawns.append((pid, _hex(pair)))
            elif ei == 0:
                for spec in party_specs:
                    if isinstance(spec, dict):
                        spawns.append((spec.get("id", "?"), _hex(spec.get("position", [0, 0]))))
            for sid, h in spawns:
                if h is None:
                    fail("demo_run.json", f"{where}: spawn {sid!r} has a bad position")
                    continue
                if not in_bounds(h):
                    fail("demo_run.json", f"{where}: spawn {sid!r} at {list(h)} outside the bounds")
                if h in walls:
                    fail("demo_run.json", f"{where}: spawn {sid!r} at {list(h)} on a wall")
                if h in objects:
                    fail("demo_run.json", f"{where}: spawn {sid!r} at {list(h)} on an object")
                if h in doors:
                    fail("demo_run.json", f"{where}: spawn {sid!r} at {list(h)} on a door hex "
                                          "(a doorway is never a spawn hex, wave 4b)")

        # ---- KAN-5 wave 4b: room-GRAPH integrity (R29) -----------------------
        # Only when any def authors "exits" (graph mode; a linear list skips
        # this whole block). Mirrors RunState's graph rules: exit keys unique
        # per room, every exit resolves to a real encounter key, at least one
        # TERMINAL room (no exits) exists, the graph is a DAG (no cycles, v1),
        # and every room is reachable from the entry room (index 0).
        encs = [e for e in (run.get("encounters", []) or []) if isinstance(e, dict)]
        enc_keys = [e.get("key") for e in encs]
        if len(enc_keys) != len(set(enc_keys)):
            fail("demo_run.json", f"duplicate encounter keys: {sorted(k for k in set(enc_keys) if enc_keys.count(k) > 1)}")
        graph_mode = any("exits" in e for e in encs)
        if graph_mode and encs:
            adjacency: dict = {}
            for e in encs:
                k = e.get("key", "?")
                if "revisitable" in e and not isinstance(e["revisitable"], bool):
                    fail("demo_run.json", f"{k}: revisitable must be a bool (wave 4b)")
                targets = []
                seen_exit_keys = set()
                for x in e.get("exits", []) or []:
                    if not isinstance(x, dict) or not x.get("key") or not x.get("to"):
                        fail("demo_run.json", f"{k}: exit rows need non-empty key + to")
                        continue
                    if x["key"] in seen_exit_keys:
                        fail("demo_run.json", f"{k}: duplicate exit key {x['key']!r}")
                    seen_exit_keys.add(x["key"])
                    if x["to"] not in enc_keys:
                        fail("demo_run.json", f"{k}: exit {x['key']!r} -> {x['to']!r} "
                                              "does not resolve to an encounter key")
                        continue
                    targets.append(x["to"])
                    exit_count += 1
                adjacency[k] = targets
            if not any(not adjacency.get(e.get("key"), []) for e in encs):
                fail("demo_run.json", "graph mode: no TERMINAL room (a def without exits) "
                                      "exists — the run could never WIN (R29)")
            # Cycle check (v1 DAG): iterative DFS with colors.
            WHITE, GRAY, BLACK = 0, 1, 2
            color = {k: WHITE for k in adjacency}
            for start in adjacency:
                if color[start] != WHITE:
                    continue
                stack = [(start, iter(adjacency[start]))]
                color[start] = GRAY
                while stack:
                    node, it = stack[-1]
                    nxt = next(it, None)
                    if nxt is None:
                        color[node] = BLACK
                        stack.pop()
                        continue
                    if color.get(nxt, BLACK) == GRAY:
                        fail("demo_run.json", f"graph mode: cycle through {nxt!r} — "
                                              "the v1 room graph must be a DAG (R29)")
                        color[nxt] = BLACK
                    elif color.get(nxt) == WHITE:
                        color[nxt] = GRAY
                        stack.append((nxt, iter(adjacency[nxt])))
            # Reachability from the entry room (index 0).
            entry = encs[0].get("key")
            reached = set()
            frontier = [entry]
            while frontier:
                node = frontier.pop()
                if node in reached:
                    continue
                reached.add(node)
                frontier.extend(adjacency.get(node, []))
            unreachable = sorted(set(adjacency) - reached)
            if unreachable:
                fail("demo_run.json", f"graph mode: rooms {unreachable} unreachable "
                                      f"from the entry room {entry!r} (R29)")

    if notes:
        print("\n".join(notes))
    if failures:
        print("\n".join(failures))
        print(f"validate_seeds: {len(failures)} failure(s).")
        return 1
    n = sum(len(x) for x in (races, enemies, conditions, skills, thresholds, items, patrons,
                             goals, loadouts, recruits, roster, te_rows, kw_skills, mutations))
    print(f"validate_seeds: OK ({len(races)} races, {len(enemies)} enemies, "
          f"{len(conditions)} conditions, {len(skills)} skills, {len(thresholds)} thresholds, "
          f"{len(items)} items, {len(patrons)} patron gods, {len(goals)} crowd goals, "
          f"{len(te_rows)} slice tags, {len(loadouts)} demo loadouts, "
          f"{len(recruits)} recruit loadouts, {len(roster)} roster patrons, "
          f"{dcmap_pairs} domain->condition affinities, {len(kw_skills)} skill keyword "
          f"entries, {len(mutations)} mutation recipes, {arena_count} encounter arenas, "
          f"{door_count} doors, {exit_count} graph exits "
          f"— {n} rows checked).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
