# Workspace Guidelines

## Clean Code & Git-Tracked Updates
- Do **not** append inline `-- Adjusted` or `-- Added` comments to function signatures.
- Do **not** leave commented-out legacy code blocks. Rely on Git history, branches, version tags, and 3-way diffs to track differences against upstream.

## Git Commits & Baseline Synchronization Safety
- When syncing or updating rulesets against CoreRPG / 3.5E baseline updates, **never** perform broad staging (`git add -A` or `git add .`) without explicit confirmation.
- Only stage and commit files that have been explicitly reconciled, adapted, and tested.

## Debugging & Diagnostics
- Whenever the user asks to debug or reports an error, immediately check the recent entries in `C:\Users\Phili\OneDrive\Dokumente\RPG\Fantasy Grounds Unity Data\channels\Test\console.log`.
- Look up campaign DB structure and stored nodes in `C:\Users\Phili\OneDrive\Dokumente\RPG\Fantasy Grounds Unity Data\channels\Test\campaigns\<CampaignName>\db.xml` (e.g. `HarnMaster Dev\db.xml`) and chat output in `chatlog.html`.

## Custom Ruleset Functions
- Any custom functions created specifically for a custom ruleset (e.g., Chronicle, HarnMaster, Star Wars) that do not originate from upstream baseline scripts must be placed at the bottom of the file under a dedicated section header (e.g., `-- CHRONICLE CUSTOM SYSTEMS`).

