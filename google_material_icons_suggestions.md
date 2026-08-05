# Google Material Icons Suggestions for Chronicle Ruleset

## UI Chrome — Strong Replacements for Existing Elements

These are the best Material fits because they replace generic UI controls where the thematic PNG icons feel heavy:

| Material Icon | Codepoint | Replace / Use For |
|---|---|---|
| `info` / `info_outline` | `e88e` | Replace the unused `button_info.png` / `button_info_down.png` |
| `open_in_new` or `launch` | `e89e` | Replace `button_details` / `button_details_down` (detail-open arrows) |
| `visibility` / `visibility_off` | `e8f4/e8f5` | Replace CoreRPG's `visibilityon`/`visibilityoff` on the Party Sheet |
| `add_circle` / `add_circle_outline` | `e147` | Replace `button_iadd` add-entry buttons throughout lists |
| `drag_indicator` | `e945` | New: reorder handle for weapons/skills/abilities list rows |
| `more_vert` | `e5d4` | New: context menu on list items (edit/duplicate/delete) |
| `link` / `link_off` | `e157/e16f` | Enhance the existing `button_link` control |
| `close` / `cancel` | `e5cd/e5c9` | New: remove-entry button on list rows |

---

## Character Stats — Potential Replacements or Additions

The current PNG icons (heart, shield, walk figure) are fine thematically, but these Material icons are cleaner at small sizes and have better visual weight consistency:

| Material Icon | Replace / Use For |
|---|---|
| `favorite` / `favorite_border` | Replace or supplement `char_health` (heart.png) |
| `shield` | Replace `char_cd` (surrounded-shield.png) for Combat Defense |
| `directions_run` | Replace `char_sprint` (run.png) — cleaner at 16–24px |
| `directions_walk` | Replace `char_move` (walk.png) |
| `warning` / `report_problem` | Supplement `char_injuries` — critical injury state |
| `battery_0_bar` → `battery_full` | New: fatigue levels replacing `char_fatigue` (oppression.png) |
| `bolt` | New: initiative icon (more legible than `char_init.png` at small sizes) |
| `healing` | New: recovery/rest action button |

---

## Proficiency & Skill System

The current `button_prof` uses PNG states. These work well as a font-based replacement:

| Material Icon | Use For |
|---|---|
| `star` / `star_half` / `star_border` | Replace proficiency states (none/half/full/double) — 4 states map perfectly |
| `grade` | Alternative single-icon proficiency indicator |
| `check_circle` / `check_circle_outline` | Specialty active/inactive toggle |
| `filter_list` | New: filter button for the skills list |

---

## Modifier Stack Buttons (Currently Text-Only)

The `PLUS1/2/4` and `MINUS1/2/4` modifier buttons are plain text. These icons would give them visual identity:

| Material Icon | Use For |
|---|---|
| `exposure_plus_1` / `exposure_plus_2` | +1D / +2D bonus dice |
| `add_circle` / `remove_circle` | Generic bonus/penalty toggle |
| `trending_up` / `trending_down` | Bonus / penalty dice visual indicator |
| `casino` | New: dice-related roll modifier context |

---

## Combat Tracker

| Material Icon | Use For |
|---|---|
| `sports_martial_arts` | Active combat section header (replaces `button_sword_down`) |
| `psychology` | Intrigue/social section header (replaces `button_fist_down`) |
| `emoji_events` | Destiny points on the Notes tab |
| `military_tech` | Rank/reputation fields |

---

## Navigation & Section Headers

The `label_charframetop` headers currently use inherited CoreRPG icons. These Material icons would unify the look:

| Material Icon | Section |
|---|---|
| `fitness_center` | Skills/Athletics |
| `auto_stories` | Notes / Background |
| `inventory_2` | Inventory |
| `list_alt` | Abilities/Qualities |
| `groups` | Party Sheet |
| `manage_accounts` | Character identity fields |
| `assignment` | Background tab |
| `timeline` | Experience / XP |

---

## Implementation Notes

Fantasy Grounds Unity supports custom fonts, so Material Icons can be used two ways:

1. **As exported PNGs** — export individual glyphs from the Material Icons font at your target size (24px or 32px), drop them into `graphics/icons_chronicle/`, register in `graphics_icons_chronicle.xml`. Best for thematic stat icons.

2. **As a font file** — load `MaterialIcons-Regular.ttf` via a `<font>` definition in your theme XML, then reference glyphs by Unicode codepoint in `<text>` controls. Best for UI chrome icons that scale cleanly.

### Highest Priority Candidates

- **`star` states** for proficiency buttons
- **`open_in_new`** for detail-open buttons
- **`drag_indicator`** for list reordering
- **`bolt`** for initiative

All of these are currently missing or using thematic PNGs that are harder to read at small UI sizes.
