---
name: fgu-debug-diagnostics
description: >-
  Use this skill when debugging Fantasy Grounds ruleset errors, inspecting runtime logs in console.log,
  examining campaign database structure (db.xml), or verifying chatlog outputs.
---

# Fantasy Grounds Runtime & Database Debugging Workflow

Use this workflow whenever diagnosing FGU script crashes, console warnings, unexpected roll behavior, or data persistence issues.

## 1. Key Diagnostics Locations

- **Runtime Console Log**:
  - Exclusively: `C:\Users\Phili\OneDrive\Dokumente\RPG\Fantasy Grounds Unity Data\channels\Test\console.log`
- **Active Campaign Databases (`db.xml`)**:
  - Test Campaigns: `C:\Users\Phili\OneDrive\Dokumente\RPG\Fantasy Grounds Unity Data\channels\Test\campaigns\<CampaignName>\db.xml`
  - Default Dev Campaign: `C:\Users\Phili\OneDrive\Dokumente\RPG\Fantasy Grounds Unity Data\channels\Test\campaigns\HarnMaster Dev\db.xml`
- **Chat Logs (`chatlog.html`)**:
  - Test Campaigns: `C:\Users\Phili\OneDrive\Dokumente\RPG\Fantasy Grounds Unity Data\channels\Test\campaigns\<CampaignName>\chatlog.html`

---

## 2. Debugging Procedure

### Step 1: Inspect Recent `console.log` Entries
**Mandatory First Action**: Whenever the user says "debug", reports an error, or investigates unexpected behavior:
1. Immediately read the most recent lines of `channels\Test\console.log`.
2. Look specifically for:
   - **Lua Runtime Errors**: `Script execution error: [string "..."]:line: ...`
   - **Nil Index / Missing Function**: `attempt to index field '...' (a nil value)` or `attempt to call field '...' (a nil value)`
   - **XML Parsing / Template Errors**: `Could not find template '...'`, `Duplicate control '...'`, or anchoring conflicts.
   - **Debug.console / Debug.chat Output**: Custom logging inserted during script runs.

### Step 2: Look Up Database Structure (`db.xml`)
When data persistence, character sheet values, or combat tracker states are behaving unexpectedly:
1. Open the relevant campaign `db.xml` (e.g. `HarnMaster Dev\db.xml`).
2. Search for the specific data node hierarchy:
   - Characters: `<charsheet><id-00001>...</id-00001></charsheet>`
   - Combat Tracker: `<combattracker>...</combattracker>`
   - Combat Resolution / Transient state: `<combatresolution>...</combatresolution>`
   - Injuries / Skills / Items: Verify child node naming conventions and data types (`<number>`, `<string>`, `<windowreference>`).
3. Verify whether scripts are attempting to read nodes that do not exist or have different casing/nesting.

### Step 3: Inspect Chat Outputs (`chatlog.html`)
When debugging rolls, combat matrix evaluations, or system notifications:
1. Check `channels\Test\campaigns\<CampaignName>\chatlog.html`.
2. Inspect the raw text, formatting, icon tags, and message metadata sent through `Comm.deliverChatMessage` or `ActionsManager`.

### Step 4: Trace Code & Propose Fix
1. Map the error stack trace from `console.log` to the exact line in ruleset scripts (e.g., `scripts/manager_combat_resolution_hm3.lua`).
2. If modifying functions inherited from base rulesets (CoreRPG / 3.5E / 5E), preserve custom logic cleanly. Do not append inline `-- Adjusted` or `-- Added` comments; rely on Git diffs.
3. Never use `git add .` or `git add -A` when staging fixes.
