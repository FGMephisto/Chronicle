---
name: fgu-baseline-sync
description: >-
  Use this skill when checking for upstream Fantasy Grounds ruleset updates (e.g., CoreRPG, 3.5E, 5E),
  detecting collisions or breaking changes with custom ruleset scripts (Chronicle, HarnMaster, Star Wars),
  or reconciling modified functions.
---

# Fantasy Grounds Baseline Synchronization Workflow

This skill outlines the standard procedure for detecting, evaluating, and reconciling upstream changes from base rulesets (CoreRPG, 3.5E, 5E) into your derived rulesets (`Chronicle`, `HarnMaster3.5E`, `Star.Wars.D20`).

## 1. Upstream Repositories & Tools

- **Upstream Repositories**:
  - CoreRPG: `c:\Users\Phili\OneDrive\Dokumente\RPG\Fantasy Grounds Unity Data\Backup\CoreRPG`
  - 5E: `c:\Users\Phili\OneDrive\Dokumente\RPG\Fantasy Grounds Unity Data\Backup\5E`
  - 3.5E: `c:\Users\Phili\OneDrive\Dokumente\RPG\Fantasy Grounds Unity Data\Backup\3E`
- **Collision Inspector**:
  - `c:\Users\Phili\OneDrive\Dokumente\RPG\Fantasy Grounds Unity Data\Backup\check-ruleset-updates.ps1`

---

## 2. Procedure

### Step 1: Run the Collision Inspector
Run the inspection script targeting the active ruleset (or `All`):
```powershell
powershell -ExecutionPolicy Bypass -File "c:\Users\Phili\OneDrive\Dokumente\RPG\Fantasy Grounds Unity Data\Backup\check-ruleset-updates.ps1" -Ruleset "<RulesetName>"
```
*Supported targets: `Chronicle`, `HarnMaster3.5E`, `Star.Wars.D20`, or `All`.*

Review the reported changes:
- **Direct collisions**: Files modified upstream that have an exact or custom-suffixed counterpart (`_chronicle`, `_hm3`, `_sw`).
- **Upstream additions**: New scripts or API utilities in CoreRPG/3.5E that might deprecate older patterns.

### Step 2: Perform 3-Way Diffing
For each collided script:
1. Locate the upstream base script (in `Backup/CoreRPG` or `Backup/5E` or `Backup/3E`).
2. Compare the previous upstream commit with the latest upstream commit to understand SmiteWorks' intent.
3. Compare the latest upstream script with the HarnMaster counterpart (e.g., `scripts/manager_combat_resolution_hm3.lua`).

### Step 3: Reconcile Code & Apply Workspace Conventions
- **Clean Code & Git-Tracked Updates**: Do not append inline `-- Adjusted` or `-- Added` comments to function signatures, and do not leave commented-out legacy code blocks. Keep the codebase clean and rely on Git history, branches, version tags, and 3-way diffs to track differences.
- **Preserve Custom Ruleset Logic**: Ensure custom adaptations (e.g. `combatresolution` node handling, injury creation hooks, ML checks) are maintained during reconciliation.

### Step 4: Staging & Git Safety
- **Strict Isolation**: **Never** run `git add .` or `git add -A`.
- Stage only the specific files that have been tested and reconciled:
  ```powershell
  git status
  git add scripts/manager_target_file_hm3.lua
  ```
