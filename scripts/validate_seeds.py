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
    # Demo loadouts (decision log #13; docs/design/slice-contestants-proposal.md §RULED):
    # object with _meta + loadouts, not a bare list — validate only if present.
    demo = load("demo_loadouts.json") if (DATA / "demo_loadouts.json").is_file() else None
    loadouts: list = []
    if demo is not None:
        if not isinstance(demo, dict) or not isinstance(demo.get("loadouts"), list):
            fail("demo_loadouts.json", "top level must be an object with a 'loadouts' list")
        else:
            if not isinstance(demo.get("_meta"), dict):
                fail("demo_loadouts.json", "_meta object required (R14 placeholder notice)")
            for i, lo in enumerate(demo["loadouts"]):
                if not isinstance(lo, dict):
                    fail("demo_loadouts.json", f"loadout {i}: must be an object, got {type(lo).__name__}")
            loadouts = [lo for lo in demo["loadouts"] if isinstance(lo, dict)]

    # races
    check_unique("races.json", races, "key")
    for r in races:
        check_body_parts("races.json", r.get("key", "?"), r.get("body_parts"), need_lethal=True)
        if r.get("size") not in SIZES:
            fail("races.json", f"{r.get('key')}: size {r.get('size')!r} not in {sorted(SIZES)}")

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

    # demo loadouts (Imani/Dario demo kits — decision log #13; NOT canon characters,
    # every number PLACEHOLDER per R14)
    check_unique("demo_loadouts.json", loadouts, "id")
    check_unique("demo_loadouts.json", loadouts, "key")
    race_ids = {r.get("id") for r in races}
    patron_ids = {p.get("id") for p in patrons}
    tag_keys = {t.get("key") for t in tags}
    skills_by_id = {s.get("id"): s for s in skills}
    for lo in loadouts:
        k = lo.get("key", "?")
        for f_ in ("key", "display_name", "broadcast_persona"):
            if not isinstance(lo.get(f_), str) or not lo.get(f_):
                fail("demo_loadouts.json", f"{k}: {f_} must be a non-empty string")
        # Authored bit (decision log #25) — OPTIONAL: not everyone has a bit. When
        # present it must be exactly {key, name, line}, all non-empty strings.
        if "bit" in lo:
            bit = lo["bit"]
            if not isinstance(bit, dict) or set(bit) != {"key", "name", "line"}:
                fail("demo_loadouts.json", f"{k}: bit must be an object with exactly "
                                           "{key, name, line} (decision log #25)")
            else:
                for bf in ("key", "name", "line"):
                    if not isinstance(bit.get(bf), str) or not bit.get(bf):
                        fail("demo_loadouts.json", f"{k}: bit.{bf} must be a non-empty string")
        if lo.get("race") not in race_ids:
            fail("demo_loadouts.json", f"{k}: race {lo.get('race')!r} is not a races.json id")
        traits = lo.get("traits")
        if not isinstance(traits, dict):
            fail("demo_loadouts.json", f"{k}: traits must be an object")
        else:
            for stat in sorted(STATS):
                if not isinstance(traits.get(stat), int) or traits[stat] < 1:
                    fail("demo_loadouts.json", f"{k}: trait {stat} must be int >= 1")
            extra = set(traits) - STATS - {"_placeholder"}
            if extra:
                fail("demo_loadouts.json", f"{k}: unknown trait keys {sorted(extra)}")
        skl = lo.get("skills")
        if not isinstance(skl, list) or not skl:
            fail("demo_loadouts.json", f"{k}: skills must be a non-empty list")
            skl = []
        for s in skl:
            if not isinstance(s, dict):
                fail("demo_loadouts.json", f"{k}: skill entry {s!r} is not an object")
                continue
            tpl = skills_by_id.get(s.get("id"))
            if tpl is None:
                fail("demo_loadouts.json", f"{k}: skill id {s.get('id')!r} unknown")
                continue
            if "key" in s and s["key"] != tpl.get("key"):
                fail("demo_loadouts.json", f"{k}: skill id {s['id']} key annotation "
                                           f"{s['key']!r} != skills.json {tpl.get('key')!r}")
            cap = tpl.get("default_cap", 0)
            if "cap" in s:
                # R16 trade: a raised cap must exceed the template default (and obey the
                # schema's 0..10 CHECK).
                if not isinstance(s["cap"], int) or not (cap < s["cap"] <= 10):
                    fail("demo_loadouts.json", f"{k}: {tpl.get('key')}: cap override "
                                               f"{s['cap']!r} must be int in {cap + 1}..10 (R16 trade)")
                else:
                    cap = s["cap"]
            if not isinstance(s.get("level"), int) or not (1 <= s["level"] <= cap):
                fail("demo_loadouts.json", f"{k}: {tpl.get('key')}: level {s.get('level')!r} "
                                           f"outside 1..{cap}")
        if not isinstance(lo.get("camera_call_stacks"), int) or lo["camera_call_stacks"] < 0:
            fail("demo_loadouts.json", f"{k}: camera_call_stacks must be int >= 0")
        if lo.get("chosen_patron") not in patron_ids:
            fail("demo_loadouts.json", f"{k}: chosen_patron {lo.get('chosen_patron')!r} "
                                       "is not a patron_gods.json id")
        lo_tags = lo.get("tags")
        if not isinstance(lo_tags, list):
            fail("demo_loadouts.json", f"{k}: tags must be a list "
                                       "(RULED 2026-07-18: loadouts start tagless)")
        else:
            for tg in lo_tags:
                if tg not in tag_keys:
                    fail("demo_loadouts.json", f"{k}: tag {tg!r} is not a tags.json key")
        if lo.get("rewireable") is not True:
            fail("demo_loadouts.json", f"{k}: rewireable must be true (owner principle, "
                                       "slice-contestants §RULED item 9)")

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

    if notes:
        print("\n".join(notes))
    if failures:
        print("\n".join(failures))
        print(f"validate_seeds: {len(failures)} failure(s).")
        return 1
    n = sum(len(x) for x in (races, enemies, conditions, skills, thresholds, items, patrons,
                             goals, loadouts, roster, te_rows))
    print(f"validate_seeds: OK ({len(races)} races, {len(enemies)} enemies, "
          f"{len(conditions)} conditions, {len(skills)} skills, {len(thresholds)} thresholds, "
          f"{len(items)} items, {len(patrons)} patron gods, {len(goals)} crowd goals, "
          f"{len(te_rows)} slice tags, {len(loadouts)} demo loadouts, {len(roster)} roster patrons, "
          f"{dcmap_pairs} domain->condition affinities — {n} rows checked).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
