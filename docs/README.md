# Chronicle System Ruleset for Fantasy Grounds Unity

Ruleset for Green Ronin’s Chronicle System powering the Feudal Fantasy Roleplaying game **"Sword Chronicle"** and formerly Green Ronin’s **"A Song of Ice and Fire Roleplaying Game" (SIFRP)**.

---

## Release History

### Version v2026-09-14
- **CoreRPG & 5E Architecture Alignment**: Modernized ruleset scripts to adhere to current CoreRPG and 5E baseline standards.
- **Combat Resolution Engines**:
  - Migrated Attack, Damage, and Health action processing to modern action manager engines.
  - Implemented Degrees of Success damage multiplication, Armor Rating Damage Reduction, Piercing weapon quality offset, and damage deflection messaging.
- **Character & Combat Management**:
  - Updated `CharManager` and `CombatManager2` to modern standards, fully supporting Chronicle's 19-ability system, bulk calculations, and armor penalty/rating mechanics.
  - Updated initiative resolution for Quickness + Agility tests with effect bonus evaluation.
- **Codebase Clean-Up**:
  - Removed obsolete pre-2024 legacy files (`manager_char_race.lua`, `manager_import_race.lua`, `manager_action_heal.lua`, etc.).
  - Resolved all loose upstream twin collisions to ensure clean upstream updates.
  - Passed all LuaCheck syntax and lint checks with 0 warnings / 0 errors.

### Version v2023-02-24
- Added support for death markers.
- Added dice roll skin customization.
- Redesigned and migrated Combat Tracker entry subsections to subwindows.
- Redesigned and migrated Item record subsections to subwindows.

### Version v2022-05-30
- Added an icon for weapons indicating the degrees of success for a roll. The icon and degrees of success can be cycled by clicking or using the mouse wheel.
- Rolling a test through the Dice Tower no longer treats Bonus Dice as Test Dice.
- Various minor bug fixes.

### Version v2022-03-04
*Major upgrade with automated character migration.*
- **Character Sheet - Skills Tab**: Contains all Abilities and Specialties with dynamic filtering. Custom Specialties can be added and linked to an Ability.
- **Character Sheet - Abilities Tab**: Allows tracking Qualities and Languages.
- **Character Sheet - Inventory Tab**: Equipment tracking with carry status, bulk, and armor ratings reflected on other tabs.
- **Character Sheet - Notes Tab**: Tracks Destiny Points, Sorcery Points, and XP.
- **Character Sheet - Actions Tab**: Health, combat stats, commonly used tests, and weapons.
- **Items**: Specialized fields for Armor and Weapons, subtype filtering, and drag-and-drop support.
- **Combat Tracker**: Health, Fatigue, Injuries, and Wounds tracking with integrated initiative.
- **Party Sheet**: Adjusted for Chronicle system tests and attributes.
- **Desktop**: Cumulative bonus dice buttons (+1D, +2D, +4D) and drag-and-drop right-click bonus dice support.

### Version v2021-10-01
- Initial Release.
