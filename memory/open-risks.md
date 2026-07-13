# Open Risks

<!-- wf memory: required sections below; keep the headings. -->

## Open risks

- **Solo-dev scope/stamina** (review-4 §2): the repo's own history (2-day burst → stall at
  KAN-2) is the evidenced failure mode. Mitigation: smallest honest vertical slice; every
  ladder stage shippable.
- **Theme doesn't sell by itself** (review-4 §1: reality-TV comps 0-for-3). Mitigation:
  litRPG/DCC positioning; spectacle-first marketing; audience system visible in the slice.
- **Free-action APM risk**: unlimited 0-cost actions become an APM contest under real-time
  tick drivers (review-1 D1 + DIRECTION sketch). Must be closed by the rules addendum.
- **Test execution environment**: Godot headless may not be runnable in every session
  container; validation status of GDScript tests must stay honest (never claim green
  without a run). Check `bmad.config.yaml` validation block for the current wired command.
- **godot-sqlite plugin not vendored** — DB layer can't execute until `addons/` exists.
