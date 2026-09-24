---
name: fgu-pak-builder
description: >-
  Use this skill when packaging rulesets into .pak distribution files, updating release dates in base.xml,
  or deploying ruleset packages to Forge and Forge Test directories.
---

# Fantasy Grounds Ruleset Packaging & Release Workflow

This skill outlines the packaging and distribution process using `build-pak.ps1` for Fantasy Grounds custom rulesets.

## 1. Builder Script & Targets

- **Script Location**:
  `c:\Users\Phili\OneDrive\Dokumente\RPG\Fantasy Grounds Unity Data\Backup\build-pak.ps1`
- **Supported Targets**:
  - `Chronicle`
  - `HarnMaster3.5E`
  - `Star.Wars.D20`
  - `All`

---

## 2. Procedure

### Step 1: Prompt Target Selection
**Mandatory rule**: Always confirm with the user which ruleset they want to package before running the build:
- Ask if they wish to build **HarnMaster 3.5E**, **Chronicle**, **Star Wars D20**, or **All Rulesets**.
- Never trigger a blanket build of all rulesets without explicit instruction.

### Step 2: Pre-Build Git Check
Check `git status` in the target ruleset repository to ensure there are no unintended unstaged files or syntax errors in `base.xml` or scripts:
```powershell
git status -s
```

### Step 3: Run the Build Script
Execute the build script with the selected target:
```powershell
powershell -ExecutionPolicy Bypass -File "c:\Users\Phili\OneDrive\Dokumente\RPG\Fantasy Grounds Unity Data\Backup\build-pak.ps1" -Ruleset "<SelectedRuleset>"
```
*Note: If the release date in `base.xml` should NOT be changed, pass the `-NoDateUpdate` flag.*

### Step 4: Verify Exclusions and Outputs
Confirm the script completed successfully:
1. **Forge Whitelist & Exclusions**:
   - Only Forge-allowed extensions are packaged: `.xml`, `.jpg`, `.jpeg`, `.png`, `.lua`, `.txt`, `.md`, `.ttf`, `.otf`, `.fgf`, `.webm`, `.webp`.
   - Ensure directories and files such as `.git`, `.agent`, `.github`, `docs/`, `mkdocs.yml`, and `sync.ffs_db` were excluded from the generated archive.
2. **Deployments**: Verify that the generated `.pak` file was copied to:
   - The active `channels\Test\rulesets` folder
   - The respective `Backup\<Ruleset> Forge` folder
   - The respective `Backup\<Ruleset> Forge Test` folder
3. **Release Date**: If updated, verify the date change in `base.xml` using `git diff base.xml`.

