# Open Risks

<!-- wf memory: required sections below; keep the headings. -->

## Open risks

- **Solo-dev scope/stamina** (review-4 §2): the evidenced failure mode is burst→stall.
  Mitigation holding so far (KAN-2+3 shipped); keep every ladder stage shippable and the
  slice smallest-honest.
- **Theme doesn't sell by itself** (review-4 §1: reality-TV comps 0-for-3). Mitigation:
  litRPG/DCC positioning; spectacle-first marketing; audience system visible in the slice.
- **Living-religion sensitivity**: the casino frame now touches real, worshipped
  religions. Policy exists (mythology spec §3.3 — investor abstraction, messenger
  carve-out, per-figure owner gate, `restricted` never depicted) but residual reputational
  risk remains wherever `living` figures appear on-screen; the per-figure gate must
  actually be honored at content time.
- **IP flags on deferred families**: SCP is CC BY-SA (share-alike obligations),
  Slenderman-class is claimed IP. Research is safe; NOTHING `modern_ip_flagged` or
  `cc_licensed` ships without the clearance decision (`ship_status` gate in the spec).
- **Owner-gated bottleneck**: the skills passover blocks priming (S2.1), both companion
  kits (S4.3), and much content authoring; R14 blocks all real numbers. If both idle,
  the dev track runs out of ungated work around end of KAN-4/KAN-5.
- **Test execution environment**: Godot 4.5.2 installs in-container
  (`scripts/setup_godot.sh`); stale `.godot` class cache is guarded in the runner. Frame
  time on real GPU hardware still unmeasured (KAN3-S3 note) — measure on owner's machine.
- **godot-sqlite still not vendored** — DAL currently reads `data/*.json` (KAN3-S2
  works without it). SQLite migration deferred; revisit if/when data scale or the
  architecture doc's DB contract demands it.
