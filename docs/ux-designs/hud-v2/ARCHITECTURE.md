# Galactic Prime Time — HUD Architecture & Interaction Specification

## Document purpose

This document defines the intended logic of the general exploration/combat HUD. It explains what every visible area is responsible for, what remains permanently visible, what opens temporarily, and how inspection, targeting, timing, audience systems, and popup menus work together.

This is a **structural UX specification**, not a final visual lock. Panels may be resized, restyled, combined, removed, or added during testing without changing the overall logic.

---

# 1. Core design principle

The game world must remain the dominant part of the screen.

The HUD should make the game feel like a live cosmic casino broadcast, but it must frame the battlefield rather than compete with it.

The screen is divided by responsibility:

- **Center:** map, exploration, movement, combat, targeting, and environmental interaction.
- **Left:** party overview and the currently selected party member.
- **Top:** popup shortcuts, Moment/Clock information, and live wager information.
- **Right:** crowd state and detailed information about the currently focused entity.
- **Bottom:** action-category buttons, temporary action menus, expandable chat, End Turn, and the Momus ticker.

The HUD uses three visibility layers:

1. **Persistent shell**  
   Small, frequently needed information that is normally visible.

2. **Contextual interface**  
   Panels that change according to the selected character, enemy, object, or action.

3. **Modal overlays**  
   Large menus opened through top-navigation buttons.

---

# 2. Overall layout

```text
┌───────────────────────────────┬───────────────────────────────────────────────────────────────┐
│ Selected party member         │ Popup shortcuts                    Moment / Clock timeline    │
│ identity and urgent status    │                                    Live odds / highest bid    │
├───────────────┬───────────────┴───────────────────────────────────────────────────────────────┤
│ Party rail    │                                                                               │
│               │                              GAME WORLD                                       │
│               │                Exploration / movement / combat / targeting                    │
│               │                                                                               │
│               │                                                                               │
│               │                                                            Crowd state        │
│               │                                                            Focused-entity     │
│               │                                                            inspector           │
├───────────────┴──────────────────────────────┬────────────────────────────────────────────────┤
│ Expandable chat                             │ Action launcher, menus, and End Turn            │
├─────────────────────────────────────────────┴────────────────────────────────────────────────┤
│ Momus live ticker — click to open the complete event log                                      │
└───────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

# 3. Area reference

## Area 1 — Selected character panel

### Purpose

Shows the currently selected or currently acting party member.

### Information shown

- Portrait, game piece, or silhouette
- Character name and role
- Patron or divine affiliation
- Overall health
- Focus or other central resources
- Current action
- Current Clock position
- Most urgent injury or condition
- Spotlight state
- Important audience tags
- Limited-use resources

### Design rule

This is an **immediate summary**, not the complete health screen.

It should answer:

> Who is selected, what are they doing, and what requires attention right now?

The complete body-part and condition display belongs in the right-side inspector.

---

## Area 2 — Party rail

### Purpose

Displays every controllable party member in a compact, scalable list.

### Each card should show

- Portrait or piece icon
- Name
- Overall health state
- One or two urgent damaged-part indicators
- Current action or readiness
- Clock position
- Patron icon
- Spotlight or major audience-tag indicator
- Disabled, dead, unavailable, or off-map state

### Interaction

- **Left-click:** select and inspect that character.
- **Double-click:** center the camera on that character.
- **Hover:** show a short status tooltip.
- The active actor receives a strong highlight.
- The selected actor may expand slightly.
- The party list scrolls or paginates when required.

### Questions it should answer quickly

- Who is ready?
- Who is currently acting?
- Who is badly injured?
- Who is disabled?
- Who should the player inspect next?

---

## Area 3 — Global popup shortcuts

### Purpose

Provide quick access to large secondary systems without keeping those systems permanently open.

### Candidate buttons

- Wagers
- Divine Status
- Social
- Encyclopedia
- Achievements
- Quests
- Settings
- Main Menu
- Other later systems

### Behavior

- Clicking a button opens its popup or overlay.
- Clicking the active button again closes it.
- `Escape` closes the topmost popup.
- Only one major popup should normally be open at once.
- The active button is highlighted.
- Each popup remembers its previous tab and scroll position.
- The HUD remains visible behind the popup where useful.

### Pause behavior

Each popup must explicitly declare whether it pauses the game.

Suggested defaults:

- Encyclopedia: pauses
- Achievements: pauses
- Quests: pauses in ordinary single-player
- Divine Status: pauses in ordinary single-player
- Wagers: may continue updating if live betting is important
- Social: depends on whether the current mode is asynchronous or live

---

## Area 4 — Moment and Clock timeline

### Purpose

Explain the timing system visually.

### Information shown

- Current Moment
- Clock positions from 0 to 10
- Current Clock marker
- Party members and enemies
- Who is ready
- Who acts next
- Declared actions
- Windup periods
- Movement duration
- Delayed effects
- Enemy telegraphs
- Interruption windows
- Scheduled resolution points

### Example

```text
MOMENT 17

0 ─ 1 ─ 2 ─ 3 ─ 4 ─ 5 ─ 6 ─ 7 ─ 8 ─ 9 ─ 10
        Imani       Enemy preparing strike       Dario
```

### Interaction

- Hovering a marker highlights the related entity.
- Clicking a marker focuses that entity.
- Hovering an action bar explains what resolves and when.
- Selecting a new action previews its future position before confirmation.

### Required result

The player should immediately understand:

1. Who acts next
2. What is already happening
3. How long the selected action will take
4. Whether an enemy action can still be interrupted

---

## Area 5 — Live odds and highest bid

### Purpose

Show the most relevant casino and broadcast information during ordinary play.

### Compact contents

- Current survival or victory odds
- Highest active bidder
- One current live wager
- Important payout multiplier

### Example

```text
SURVIVAL ODDS: 3:1
TOP BIDDER: SEKHMET
LIVE WAGER: Expose the Network Core before Moment 20
```

### Behavior

- Important actions animate odds changes.
- Clicking the panel opens Full Wagers.
- A tooltip can explain why the latest shift occurred.
- The panel stays compact during combat.

---

## Area 6 — Crowd management

### Purpose

Represent the audience as an actionable system rather than a decorative popularity meter.

### Compact contents

- Current hype value and band
- Active crowd goal
- Reward
- Expiration or failure condition
- Spotlighted contestant
- Most recent important audience tag
- Current crowd mood

### Example

```text
CROWD: HEATED
GOAL: Break a limb before Clock 8
REWARD: +40 Hype
SPOTLIGHT: Dario
AUDIENCE NARRATIVE: “Reckless”
```

### Expanded view

Clicking the panel may open:

- Hype history
- Audience factions
- Recent reactions
- Available interventions
- Tag history
- Patron resonance
- Performance trends
- Crowd-related wager effects

### Camera Call and The Bit

Both remain inside **Free Actions**.

When either becomes especially relevant:

- The Crowd panel may pulse.
- The Free Actions button may receive a badge.
- A temporary notification may appear.
- The action remains inside Free Actions rather than becoming a permanent extra button.

---

## Area 7 — Contextual focused-entity inspector

### Purpose

Provide detailed information about whichever entity the player has focused.

The same panel is used for:

- Allies
- Enemies
- Objects
- Environmental structures
- Encounter-specific targets

---

### Ally focus

Show:

- Complete anatomical diagram
- Health by body part
- Conditions attached to each body part or organ
- Overall state
- Equipment
- Current action
- Patron obligations
- Available treatment or assistance
- Important resources

---

### Enemy focus

Show only information the player currently knows:

- Visible anatomy
- Known body parts
- Targetable parts
- Conditions
- Resistances and weaknesses
- Current or telegraphed action
- Range and position information
- Discovered encounter mechanics
- Suspected or hidden structures

### Discovery states

Enemy information may be classified as:

- **Visible:** directly observable
- **Known:** confirmed through discovery or earlier knowledge
- **Suspected:** inferred but uncertain
- **Hidden:** not yet discovered
- **Misidentified:** possibly incorrect information

### Incine-Dile example

Before discovery:

```text
Head
Left Hand
Right Hand
Torso
Unknown Internal Structure
```

After breach:

```text
Network Core — EXPOSED
Connected nodes highlighted
Destruction condition discovered
```

---

### Object focus

Show:

- Structural parts
- Durability
- Interaction options
- Environmental hazards
- Whether the object can be moved, broken, climbed, activated, or used as cover

---

### During targeting

When an action is selected, the inspector also shows:

- Valid target parts
- Estimated damage
- Expected condition changes
- Clock cost
- Exposure created
- Forced consequence
- Known uncertainty

---

## Area 8 — Expandable chat

### Purpose

Support party, spectator, social, or shared-world communication without permanently consuming much of the screen.

### Collapsed state

- One or two recent messages
- Unread count
- Current channel
- Expand button

### Expanded state

May include:

- Party chat
- Spectator chat
- System messages
- Patron messages
- Social-area conversation
- Moderation controls

### Priority rule

During normal single-player combat, chat stays visually subordinate to tactical information.

---

## Area 9 — Action launcher

### Purpose

Provide stable category buttons that open temporary menus.

### Permanent buttons

```text
[Move] [Attack] [Skills] [Free Actions] [End Turn]
```

---

### Move

Provides a visible movement command in addition to right-click movement.

Needed for:

- Discoverability
- Controller support
- Accessibility
- Previewing path and Clock cost
- Situations where right-click is remapped

---

### Attack

Opens basic weapon, natural, or unarmed attacks.

Each entry may show:

- Attack name
- Damage type
- Range
- Clock cost
- Valid target categories
- Valid body parts
- Short consequence summary

---

### Skills

Opens character-specific active abilities.

Each entry may show:

- Skill name
- Priming state or requirements
- Clock cost
- Resource cost
- Range
- Target type
- Availability
- Tactical purpose

---

### Free Actions

Contains actions outside normal Attack and Skill categories.

Possible contents:

- Inventory
- Interact
- Assist
- Inspect
- Camera Call
- The Bit
- Patron action
- Scenario-specific commands

“Free Action” is a category name. It does not guarantee that every option has no resource, charge, or timing cost. Each entry must show its actual cost.

---

### End Turn

Completes the command set and should be visually separated from the other buttons.

Its tooltip should explain the result.

```text
END TURN
Advance to Clock 4
Enemy acts next
```

A later thematic name could be tested:

- Commit
- Advance
- Lock Actions
- Yield

Until then, End Turn is the clearest label.

---

## Area 10 — Temporary action menu

### Purpose

Show only the choices relevant to the currently opened action category.

### Opening rules

- Menus open upward from the launcher button.
- Opening another action category replaces the current menu.
- `Escape` closes the menu.
- Right-click cancels one step.
- Temporary menus should avoid covering the selected target.

### Standard action flow

1. Open a category.
2. Select an action.
3. Select a target.
4. Select a body part or destination if required.
5. Review Clock cost and predicted consequences.
6. Confirm or cancel.

### Example

```text
FEINT

Target: Incine-Dile
Part: Left Hand
Cost: 2 Clocks

Expected:
- Low damage
- Applies Exposed
- Imani becomes Vulnerable until Clock 6

[Confirm] [Back]
```

### Near-target preview

A small tooltip near the cursor may show:

```text
LEFT HAND
Exposed
In range
```

The three information levels are:

1. **Near cursor:** immediate targeting facts
2. **Action menu:** cost and predicted result
3. **Right inspector:** complete known anatomy and conditions

---

## Area 11 — Momus broadcast ticker

### Purpose

Make the match feel continuously interpreted by the show.

### Possible content

- Recent actions
- Crowd reactions
- Patron commentary
- New tags
- Injury announcements
- Odds changes
- Boss discoveries
- Wager changes
- Host jokes
- Rule reminders

### Interaction

- Clicking opens the complete event log.
- The log may filter by:
  - Combat
  - Crowd
  - Patrons
  - Wagers
  - Dialogue
  - System

### Important limitation

Critical tactical information must not exist only in moving text.

The ticker is for:

- Flavor
- Summaries
- Reactions
- Retrievable context

Stable warnings still belong in the timeline, party rail, inspector, or action menu.

---

## Area 12 — End Turn / Commit control

### Purpose

Lock the current actor’s declaration and progress time.

### Information required before confirmation

- Current actor
- Current Clock
- Next Clock
- Whether an action is currently declared
- Who becomes ready next
- Whether an enemy resolves an action
- Whether untreated effects tick
- Whether the decision can be undone

### Example

```text
END TURN

Imani will wait.
Clock advances from 3 to 4.
Incine-Dile acts at Clock 4.
Burned II triggers on Dario.

[Confirm] [Cancel]
```

This prevents End Turn from behaving like an unexplained generic button.

---

# 4. Interaction modes

## Mode A — Exploration

Primary elements:

- Large map
- Compact party rail
- Selected-character summary
- Minimal crowd information
- Collapsed chat
- Exploration-relevant actions

The right inspector appears when something is focused.

---

## Mode B — Party member ready

Primary elements:

- Active party card highlighted
- Active timeline marker highlighted
- Character name repeated near the action launcher
- Available action categories
- Movement previews
- Current Clock clearly visible

---

## Mode C — Targeting an enemy body part

Primary elements:

- Valid targets highlighted
- Invalid targets dimmed
- Valid body parts highlighted
- Right inspector displays known anatomy
- Action menu displays predicted result
- Timeline previews duration
- Confirm and cancel controls appear

---

## Mode D — Popup open

Primary elements:

- Selected large popup
- Background HUD dimmed
- Popup button highlighted
- Escape closes
- Pause state clearly shown

---

## Mode E — Audience opportunity

Primary elements:

- Crowd panel animates
- Free Actions gains a badge
- Camera Call or The Bit is highlighted in the opened menu
- Reward, risk, and expiration are visible

---

# 5. Input logic

## Mouse — normal state

- Left-click entity: focus and inspect
- Double-click ally: center camera
- Right-click reachable ground: movement shortcut
- Hover: lightweight preview
- Mouse wheel: camera zoom or panel scroll depending on cursor position

## Mouse — action-selected state

- Left-click: select target or body part
- Right-click: cancel one step
- Escape: cancel full action
- Hover: show predicted outcome

## Suggested keyboard shortcuts

- `1`: Move
- `2`: Attack
- `3`: Skills
- `4`: Free Actions
- `Space`: End Turn / Commit
- `Tab`: cycle party members
- `Shift + Tab`: cycle enemies
- `Escape`: cancel or close

Direct shortcuts for Camera Call and The Bit may later be added without removing them from Free Actions.

## Controller requirement

Every mouse shortcut must also have a visible command path.

The player must be able to:

- Cycle focus
- Enter movement mode
- Open each action category
- Navigate the anatomy panel
- Confirm and cancel
- Open popup menus
- End the turn

---

# 6. Information priority

## Critical — stable and visible

- Current actor
- Current Moment and Clock
- Who acts next
- Urgent injury or death warning
- Selected action
- Selected target
- Clock cost
- End Turn consequence
- Crowd goal when close to expiration

## Important — shown contextually

- Complete anatomy
- All conditions
- Full odds information
- Patron obligations
- Audience tag history
- Equipment
- Complete skill descriptions

## Optional — collapsible or temporary

- Flavor commentary
- Minor crowd reactions
- Historical odds
- Non-urgent chat
- Detailed broadcast analytics

---

# 7. Visual behavior

- The game view receives the greatest visual weight.
- Edge panels may use dark translucent glass.
- Critical text must use strong contrast and stable backing.
- Menus should slide from the button or edge that owns them.
- Odds changes, newly exposed anatomy, new tags, and boss phase changes may animate.
- Major events may briefly override lower-priority information.
- Avoid constant animation in every panel.
- Do not rely on system emoji or uncontrolled fonts in the final release.
- The broadcast theme should come from framing, movement, typography, casino materials, and commentary—not from covering the battlefield.

---

# 8. Suggested Godot component structure

The final HUD should be composed from reusable scenes rather than one monolithic script.

Suggested scenes:

- `HudShell`
- `SelectedActorSummary`
- `PartyRail`
- `PartyCard`
- `GlobalMenuBar`
- `MomentTimeline`
- `LiveOddsPanel`
- `CrowdPanel`
- `EntityInspector`
- `BodyPartDiagram`
- `ChatPanel`
- `ActionLauncher`
- `ActionFlyout`
- `ActionPreview`
- `EndTurnConfirmation`
- `MomusTicker`
- `EventLogOverlay`
- `GlobalPopupHost`

Each scene should receive structured view data and should not infer game meaning from hardcoded names or IDs.

---

# 9. Minimum data required by the HUD

## Focused entity data

- Entity ID
- Display name
- Team
- Entity category
- Portrait or piece icon
- Position
- Current action
- Timeline state
- Overall physical state
- Known anatomy
- Known conditions
- Targetability
- Discovery state

## Action data

- Action ID
- Display name
- Category
- Clock cost
- Resource cost
- Requirements
- Range
- Valid target types
- Valid body parts
- Predicted effects
- Uncertainty
- Forced consequence
- Confirmation requirement

## Crowd data

- Hype value
- Hype band
- Active crowd goal
- Expiration
- Reward
- Failure consequence
- Spotlight
- Current tags
- Camera Call availability
- The Bit relevance

## Timeline data

- Current Moment
- Current Clock
- Actor readiness
- Declared actions
- Start and resolution Clocks
- Interruption windows
- Delayed effects
- Enemy telegraphs

---

# 10. First interactive HUD acceptance checklist

A new player should be able to do all of the following without external explanation:

- Identify the current actor.
- Identify who acts next.
- Select and inspect an ally.
- Select and inspect an enemy.
- Understand that enemy information may be incomplete.
- Open Attack.
- Open Skills.
- Open Free Actions.
- Find Camera Call.
- Find The Bit.
- Move through both the shortcut and visible Move command.
- Select an enemy body part.
- Understand an action’s Clock cost.
- Understand the likely consequence.
- Cancel safely.
- End the turn and understand what will happen.
- Recognize the current crowd goal.
- Open and close a top-navigation popup.
- Read Momus commentary.
- Open the full event log.
- Continue seeing enough of the battlefield while using these systems.

---

# Final structural decision

The HUD is a stable **shell with contextual content**, not a collection of permanently open dashboards.

The persistent structure is:

```text
Central game view
+ party rail
+ selected-character summary
+ Moment/Clock timeline
+ compact odds
+ compact crowd state
+ contextual inspector
+ action launcher
+ End Turn
+ Momus ticker
+ collapsed chat
+ popup shortcuts
```

Everything else opens only when requested or when the current action requires it.
