-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Examples:
-- { type = "attack", range = "[M|R]", [modifier = #] }
--		If modifier defined, then attack bonus will be this fixed value
--		Otherwise, the attack bonus will be the ability bonus defined for the spell group
--
-- { type = "damage", clauses = { { dice = { "d#", ... }, modifier = #, type = "", [stat = ""] }, ... } }
--		Each damage action can have multiple clauses which can do different damage types
--
-- { type = "heal", [subtype = "temp", ][sTargeting = "self", ] clauses = { { dice = { "d#", ... }, bonus = #, [stat = ""] }, ... } }
--		Each heal action can have multiple clauses 
--		Heal actions are either direct healing or granting temporary hit points (if subtype = "temp" set)
--		If sTargeting = "self" set, then the heal will always be applied to self instead of target.
--
-- { type = "powersave", save = "<ability>", [savemod = #, ][savestat = "<ability>", ][onmissdamage = "half"] }
--		If savemod defined, then the DC will be this fixed value.
--		If savestat defined, then the DC will be calculated as 8 + specified ability bonus + proficiency bonus
--		Otherwise, the save DC will be the same as the spell group
--
-- { type = "effect", sName = "<effect text>", [sTargeting = "self", ][nDuration = #, ][sUnits = "[<empty>|minute|hour|day]", ][sApply = "[<empty>|action|roll|single]"] }
--		If sTargeting = "self" set, then the effect will always be applied to self instead of target.
--		If nDuration not set or is equal to zero, then the effect will not expire.


-- Spell lookup data
parsedata = {
	["aid"] = {
		{ type = "heal", subtype = "temp", clauses = { { bonus = 5 } } },
	},
	["bane"] = {
		{ type = "powersave", save = "charisma", magic = true, savebase = "group" },
		{ type = "effect", sName = "ATK: -1d4; SAVE: -1d4; (C)", nDuration = 1, sUnits = "minute" },
	},
	["beaconofhope"] = {
		{ type = "effect", sName = "ADVSAV: wisdom; ADVSAV: death; NOTE: Receive Max Healing; (C)", nDuration = 1, sUnits = "minute" },
	},
	["bestowcurse"] = {
		{ type = "powersave", save = "wisdom", magic = true, savebase = "group" },
		{ type = "effect", sName = "DISCHK: strength; DISSAV: strength; (C)", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "DISCHK: dexterity; DISSAV: dexterity; (C)", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "DISCHK: constitution; DISSAV: constitution; (C)", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "DISCHK: intelligence; DISSAV: intelligence; (C)", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "DISCHK: wisdom; DISSAV: wisdom; (C)", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "DISCHK: charisma; DISSAV: charisma; (C)", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "[TRGT]; GRANTDISATK; (C)", sTargeting = "self", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "NOTE: Wisdom save or lose action; (C)", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "[TRGT]; DMG: 1d8 necrotic; (C)", sTargeting = "self", nDuration = 1, sUnits = "minute" },
	},
	["bladebarrier"] = {
		{ type = "powersave", save = "dexterity", onmissdamage = "half", magic = true, savebase = "group" },
		{ type = "damage", clauses = { { dice = { "d10", "d10", "d10", "d10", "d10", "d10" }, dmgtype = "slashing,magic" } } },
	},
	["bladeward"] = {
		{ type = "effect", sName = "RESIST: bludgeoning,piercing,slashing", nDuration = 1 },
	},
	["bless"] = {
		{ type = "effect", sName = "ATK: 1d4; SAVE: 1d4; (C)", nDuration = 1, sUnits = "minute" },
	},
	["blindnessdeafness"] = {
		{ type = "powersave", save = "constitution", magic = true, savebase = "group" },
		{ type = "effect", sName = "Blinded; NOTE: End of Round Save", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "Deafened; NOTE: End of Round Save", nDuration = 1, sUnits = "minute" },
	},
	["blur"] = {
		{ type = "effect", sName = "GRANTDISATK; (C)", sTargeting = "self", nDuration = 1, sUnits = "minute" },
	},
	["chilltouch"] = {
		{ type = "attack", range = "R", spell = true, base = "group" },
		{ type = "damage", clauses = { { dice = { "d8" }, dmgtype = "necrotic" } } },
		{ type = "effect", sName = "NOTE: Can't regain hit points", nDuration = 1 },
		{ type = "effect", sName = "[TRGT]; GRANTDISATK", sTargeting = "self", nDuration = 1 },
	},
	["chromaticorb"] = {
		{ type = "attack", range = "R", spell = true, base = "group" },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8" }, dmgtype = "acid" } } },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8" }, dmgtype = "cold" } } },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8" }, dmgtype = "fire" } } },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8" }, dmgtype = "lightning" } } },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8" }, dmgtype = "poison" } } },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8" }, dmgtype = "thunder" } } },
	},
	["colorspray"] = {
		{ type = "effect", sName = "Blinded", nDuration = 1 },
	},
	["contagion"] = {
		{ type = "attack", range = "M", spell = true, base = "group" },
		{ type = "effect", sName = "NOTE: Contagion", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "NOTE: Blinding Sickness; DISCHK: wisdom; DISSAV: wisdom; Blinded", nDuration = 7, sUnits = "day" },
		{ type = "effect", sName = "NOTE: Filth Fever; DISCHK: strength; DISSAV: strength; NOTE: DIS on strength attacks", nDuration = 7, sUnits = "day" },
		{ type = "effect", sName = "NOTE: Flesh Rot; DISCHK: charisma; VULN: all", nDuration = 7, sUnits = "day" },
		{ type = "effect", sName = "NOTE: Mindfire; DISCHK: intelligence; NOTE: Confused", nDuration = 7, sUnits = "day" },
		{ type = "effect", sName = "NOTE: Seizure; DISCHK: dexterity; DISSAV: dexterity; NOTE: DIS on dexterity attacks", nDuration = 7, sUnits = "day" },
		{ type = "effect", sName = "NOTE: Slimy Doom; DISCHK: constitution; DISSAV: constitution; NOTE: Stunned when damaged", nDuration = 7, sUnits = "day" },
	},
	["crownofmadness"] = {
		{ type = "powersave", save = "wisdom", magic = true, savebase = "group" },
		{ type = "effect", sName = "Charmed; NOTE: Save on end of round; (C)", nDuration = 1, sUnits = "minute" },
	},
	["crusadersmantle"] = {
		{ type = "effect", sName = "DMG: 1d4 radiant; (C)", nDuration = 1, sUnits = "minute" },
	},
	["deathward"] = {
		{ type = "effect", sName = "NOTE: Death Ward", nDuration = 8, sUnits = "hour" },
	},
	["dispelevilandgood"] = {
		{ type = "attack", range = "M", spell = true, base = "group" },
		{ type = "powersave", save = "charisma", magic = true, savebase = "group" },
		{ type = "effect", sName = "IFT: TYPE(aberration, celestial, elemental, fey, fiend, undead); GRANTDISATK; IMMUNE: charmed,frightened,possessed; (C)", nDuration = 1, sUnits = "minute" },
	},
	["divinefavor"] = {
		{ type = "effect", sName = "DMG: 1d4 radiant; (C)", sTargeting = "self", nDuration = 1, sUnits = "minute" },
	},
	["divineword"] = {
		{ type = "powersave", save = "charisma", magic = true, savebase = "group" },
		{ type = "effect", sName = "Deafened", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "Deafened; Blinded", nDuration = 10, sUnits = "minute" },
		{ type = "effect", sName = "Blinded; Deafened; Stunned", nDuration = 1, sUnits = "hour" },
	},
	["enhanceability"] = {
		{ type = "effect", sName = "ADVCHK: constitution; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "heal", subtype = "temp", clauses = { { dice = { "d6", "d6" } } } },
		{ type = "effect", sName = "ADVCHK: strength; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "effect", sName = "ADVCHK: dexterity; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "effect", sName = "ADVCHK: charisma; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "effect", sName = "ADVCHK: intelligence; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "effect", sName = "ADVCHK: wisdom; (C)", nDuration = 1, sUnits = "hour" },
	},
	["enlargereduce"] = {
		{ type = "powersave", save = "constitution", magic = true, savebase = "group" },
		{ type = "effect", sName = "NOTE: Enlarged; ADVCHK: strength; ADVSAV: strength; DMG: 1d4; (C)", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "NOTE: Reduced; DISCHK: strength; DISSAV: strength; DMG: -1d4; (C)", nDuration = 1, sUnits = "minute" },
	},
	["faeriefire"] = {
		{ type = "powersave", save = "dexterity", magic = true, savebase = "group" },
		{ type = "effect", sName = "GRANTADVATK; (C)", nDuration = 1, sUnits = "minute" },
	},
	["feigndeath"] = {
		{ type = "effect", sName = "Blinded; Incapacitated; RESIST: all, !psychic", nDuration = 1, sUnits = "hour" },
	},
	["forbiddance"] = {
		{ type = "damage", clauses = { { dice = { "d10", "d10", "d10", "d10", "d10" }, dmgtype = "radiant" } } },
		{ type = "damage", clauses = { { dice = { "d10", "d10", "d10", "d10", "d10" }, dmgtype = "necrotic" } } },
	},
	["friends"] = {
		{ type = "effect", sName = "ADVCHK: charisma; (C)", nDuration = 1, sUnits = "minute" },
	},
	["gaseousform"] = {
		{ type = "effect", sName = "NOTE: Gaseous Form; RESIST: bludgeoning, piercing, slashing, !magic; ADVSAV: strength; ADVSAV: dexterity; ADVSAV: constitution", nDuration = 1, sUnits = "hour" },
	},
	["geas"] = {
		{ type = "powersave", save = "wisdom", magic = true, savebase = "group" },
		{ type = "effect", sName = "Charmed" },
		{ type = "damage", clauses = { { dice = { "d10", "d10", "d10", "d10", "d10" }, type = "psychic" } } },
	},
	["glyphofwarding"] = {
		{ type = "powersave", save = "dexterity", onmissdamage = "half", magic = true, savebase = "group" },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8", "d8", "d8" }, dmgtype = "acid" } } },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8", "d8", "d8" }, dmgtype = "cold" } } },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8", "d8", "d8" }, dmgtype = "fire" } } },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8", "d8", "d8" }, dmgtype = "lightning" } } },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8", "d8", "d8" }, dmgtype = "thunder" } } },
	},
	["grease"] = {
		{ type = "powersave", save = "dexterity", magic = true, savebase = "group" },
		{ type = "effect", sName = "Prone" },
	},
	["guardianoffaith"] = {
		{ type = "effect", sName = "NOTE: Guardian of Faith", sTargeting = "self", nDuration = 8, sUnits = "hour" },
		{ type = "powersave", save = "dexterity", onmissdamage = "half", magic = true, savebase = "group" },
		{ type = "damage", clauses = { { modifier = 20, dmgtype = "radiant" } } },
	},
	["guidingbolt"] = {
		{ type = "attack", range = "R", spell = true, base = "group" },
		{ type = "damage", clauses = { { dice = { "d6", "d6", "d6", "d6" }, dmgtype = "radiant" } } },
		{ type = "effect", sName = "GRANTADVATK", nDuration = 1, sApply = "roll" },
	},
	["hallow"] = {
		{ type = "powersave", save = "charisma", magic = true, savebase = "group" },
		{ type = "effect", sName = "IMMUNE: frightened; [FIXED]" },
		{ type = "effect", sName = "RESIST: acid; [FIXED]" },
		{ type = "effect", sName = "RESIST: cold; [FIXED]" },
		{ type = "effect", sName = "RESIST: fire; [FIXED]" },
		{ type = "effect", sName = "RESIST: lightning; [FIXED]" },
		{ type = "effect", sName = "RESIST: necrotic; [FIXED]" },
		{ type = "effect", sName = "RESIST: poison; [FIXED]" },
		{ type = "effect", sName = "RESIST: psychic; [FIXED]" },
		{ type = "effect", sName = "RESIST: radiant; [FIXED]" },
		{ type = "effect", sName = "RESIST: thunder; [FIXED]" },
		{ type = "effect", sName = "VULN: acid; [FIXED]" },
		{ type = "effect", sName = "VULN: cold; [FIXED]" },
		{ type = "effect", sName = "VULN: fire; [FIXED]" },
		{ type = "effect", sName = "VULN: lightning; [FIXED]" },
		{ type = "effect", sName = "VULN: necrotic; [FIXED]" },
		{ type = "effect", sName = "VULN: poison; [FIXED]" },
		{ type = "effect", sName = "VULN: psychic; [FIXED]" },
		{ type = "effect", sName = "VULN: radiant; [FIXED]" },
		{ type = "effect", sName = "VULN: thunder; [FIXED]" },
		{ type = "effect", sName = "Frightened; [FIXED]" },
		{ type = "effect", sName = "NOTE: Silenced; [FIXED]" },
		{ type = "effect", sName = "NOTE: Tongues; [FIXED]" },
	},
	["haste"] = {
		{ type = "effect", sName = "NOTE: Hasted; AC: 2; ADVSAV: dexterity; (C)", nDuration = 1, sUnits = "minute" },
	},
	["heroesfeast"] = {
		{ type = "effect", sName = "IMMUNE: poison,poisoned,frightened; ADVSAV: wisdom", nDuration = 1, sUnits = "day" },
		{ type = "heal", subtype = "temp", clauses = { { dice = { "d10", "d10" } } } },
	},
	["holyaura"] = {
		{ type = "effect", sName = "ADVSAV; GRANTDISATK; NOTE: Extra effect on fiend/undead melee attack; (C)", nDuration = 1, sUnits = "minute" },
	},
	["insectplague"] = {
		{ type = "effect", sName = "Insect Plague; (C)", sTargeting = "self", nDuration = 10, sUnits = "minute" },
		{ type = "powersave", save = "constitution", onmissdamage = "half", magic = true, savebase = "group" },
		{ type = "damage", clauses = { { dice = { "d10", "d10", "d10", "d10" }, dmgtype = "piercing,magic" } } },
	},
	["magearmor"] = {
		{ type = "effect", sName = "AC: 3", nDuration = 8, sUnits = "hour" },
	},
	["magiccircle"] = {
		{ type = "powersave", save = "charisma", magic = true, savebase = "group" },
		{ type = "effect", sName = "IFT: TYPE(aberration, celestial, elemental, fey, fiend, undead); GRANTDISATK; IMMUNE: charmed,frightened,possessed; [FIXED]", nDuration = 1, sUnits = "hour" },
	},
	["magicweapon"] = {
		{ type = "effect", sName = "ATK: 1; DMG: 1; DMGTYPE: magic; (C)", nDuration = 1, sUnits = "hour" },
	},
	["protectionfromenergy"] = {
		{ type = "effect", sName = "RESIST: acid; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "effect", sName = "RESIST: cold; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "effect", sName = "RESIST: fire; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "effect", sName = "RESIST: lightning; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "effect", sName = "RESIST: thunder; (C)", nDuration = 1, sUnits = "hour" },
	},
	["protectionfromevilandgood"] = {
		{ type = "effect", sName = "IFT: TYPE(aberration, celestial, elemental, fey, fiend, undead); GRANTDISATK; IMMUNE: charmed,frightened,possessed; (C)", nDuration = 10, sUnits = "minute" },
	},
	["protectionfrompoison"] = {
		{ type = "effect", sName = "RESIST: poison; NOTE: Poison save advantage", nDuration = 1, sUnits = "hour" },
	},
	["rayofenfeeblement"] = {
		{ type = "attack", range = "R", spell = true, base = "group" },
		{ type = "effect", sName = "NOTE: Deals half damage with Strength attacks; NOTE: Save on end of round; (C)", nDuration = 1, sUnits = "minute" },
	},
	["sanctuary"] = {
		{ type = "effect", sName = "NOTE: Sanctuary", nDuration = 1, sUnits = "minute" },
	},
	["shield"] = {
		{ type = "effect", sName = "AC: 5", sTargeting = "self", nDuration = 1 },
	},
	["shieldoffaith"] = {
		{ type = "effect", sName = "AC: 2; (C)", nDuration = 10, sUnits = "minute" },
	},
	["slow"] = {
		{ type = "powersave", save = "wisdom", magic = true, savebase = "group" },
		{ type = "effect", sName = "NOTE: Slowed; AC: -2; SAVE: -2 dexterity; NOTE: Save on end of round; (C)", nDuration = 1, sUnits = "minute" },
	},
	["sunbeam"] = {
		{ type = "effect", sName = "Sunbeam; (C)", sTargeting = "self", nDuration = 1, sUnits = "minute" },
		{ type = "powersave", save = "constitution", onmissdamage = "half", magic = true, savebase = "group" },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8", "d8", "d8", "d8" }, dmgtype = "radiant" } } },
		{ type = "effect", sName = "Blinded", nDuration = 1 },
	},
	["symbol"] = {
		{ type = "powersave", save = "constitution", onmissdamage = "half", magic = true, savebase = "group" },
		{ type = "damage", clauses = { { dice = { "d10", "d10", "d10", "d10", "d10", "d10", "d10", "d10", "d10", "d10" }, dmgtype = "necrotic" } } },
		{ type = "effect", sName = "NOTE: Symbol of Discord", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "NOTE: Symbol of FEar; Frightened", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "NOTE: Symbol of Hopelessness", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "NOTE: Symbol of Insanity", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "NOTE: Symbol of Pain; Incapacitated", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "NOTE: Symbol of Sleep; Unconscious", nDuration = 10, sUnits = "minute" },
		{ type = "effect", sName = "NOTE: Symbol of Stunning; Stunned", nDuration = 1, sUnits = "minute" },
	},
	["tashashideouslaughter"] = {
		{ type = "powersave", save = "wisdom", magic = true, savebase = "group" },
		{ type = "effect", sName = "Prone; Incapacitated; NOTE: Unable to stand up; NOTE: Save on end of round and damage; (C)", nDuration = 1, sUnits = "minute" },
	},
	["truestrike"] = {
		{ type = "effect", sName = "[TRGT]; ADVATK; (C)", sTargeting = "self", nDuration = 2, sApply = "roll" },
	},
	["wardingbond"] = {
		{ type = "effect", sName = "AC: 1; SAVE: 1; RESIST: all", nDuration = 1, sUnits = "hour" },
	},
};

tBuildDataSpell2024 = {
	["aid"] = {
		{ type = "heal", subtype = "temp", clauses = { { bonus = 5 } } },
	},
	["alterself"] = {
		{ type = "effect", sName = "Aquatic Adaptation; Swim speed; Breathe underwater; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "damage", clauses = { { dice = { "d6" }, dmgtype = "slashing" } } },
		{ type = "damage", clauses = { { dice = { "d6" }, dmgtype = "piercing" } } },
		{ type = "damage", clauses = { { dice = { "d6" }, dmgtype = "bludgeoning" } } },
	},
	["bane"] = {
		{ type = "powersave", save = "charisma", magic = true, savebase = "group" },
		{ type = "effect", sName = "ATK: -1d4; SAVE: -1d4; (C)", nDuration = 1, sUnits = "minute" },
	},
	["beaconofhope"] = {
		{ type = "effect", sName = "ADVSAV: wisdom; ADVSAV: death; NOTE: Receive Max Healing; (C)", nDuration = 1, sUnits = "minute" },
	},
	["bestowcurse"] = {
		{ type = "powersave", save = "wisdom", magic = true, savebase = "group" },
		{ type = "effect", sName = "DISCHK: strength; DISSAV: strength; (C)", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "DISCHK: dexterity; DISSAV: dexterity; (C)", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "DISCHK: constitution; DISSAV: constitution; (C)", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "DISCHK: intelligence; DISSAV: intelligence; (C)", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "DISCHK: wisdom; DISSAV: wisdom; (C)", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "DISCHK: charisma; DISSAV: charisma; (C)", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "[TRGT]; GRANTDISATK; (C)", sTargeting = "self", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "NOTE: Wisdom save or must Dodge; (C)", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "[TRGT]; DMG: 1d8 necrotic; (C)", sTargeting = "self", nDuration = 1, sUnits = "minute" },
	},
	["bigbyshand"] = {
		{ type = "attack", range = "m", spell = true, base = "group" },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8", "d8", "d8", }, dmgtype = "force" } } },
		{ type = "powersave", save = "strength", magic = true, savebase = "group" },
		{ type = "powersave", save = "dexterity", magic = true, savebase = "group" },
		{ type = "effect", sName = "Grappled; (C)", },
		{ type = "damage", clauses = { { dice = { "d6", "d6", "d6", "d6", }, dmgtype = "bludgeoning", stat="base", } } },
		{ type = "effect", sName = "COVER; (C)", sTargeting = "self", },
	},
	["bladeward"] = {
		{ type = "effect", sName = "[TRGT]; ATK: -1d4; (C)", nDuration = 1, sUnits = "minute"  },
	},
	["bless"] = {
		{ type = "effect", sName = "ATK: 1d4; SAVE: 1d4; (C)", nDuration = 1, sUnits = "minute" },
	},
	["blindnessdeafness"] = {
		{ type = "powersave", save = "constitution", magic = true, savebase = "group" },
		{ type = "effect", sName = "Blinded; NOTE: End of Round Save", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "Deafened; NOTE: End of Round Save", nDuration = 1, sUnits = "minute" },
	},
	["blur"] = {
		{ type = "effect", sName = "GRANTDISATK; (C)", sTargeting = "self", nDuration = 1, sUnits = "minute" },
	},
	["calmemotions"] = {
		{ type = "powersave", save = "charisma", magic = true, savebase = "group" },
		{ type = "effect", sName = "IMMUNE: Charmed; IMMUNE: Frightened; NOTE: Indifferent attitude; (C)", nDuration = 1, sUnits = "minute" },
	},
	["chilltouch"] = {
		{ type = "attack", range = "R", spell = true, base = "group" },
		{ type = "damage", clauses = { { dice = { "d10" }, dmgtype = "necrotic" } } },
		{ type = "effect", sName = "NOTE: Can't regain hit points", nDuration = 1 },
	},
	["chromaticorb"] = {
		{ type = "attack", range = "R", spell = true, base = "group" },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8" }, dmgtype = "acid" } } },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8" }, dmgtype = "cold" } } },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8" }, dmgtype = "fire" } } },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8" }, dmgtype = "lightning" } } },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8" }, dmgtype = "poison" } } },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8" }, dmgtype = "thunder" } } },
	},
	["circleofpower"] = {
		{ type = "effect", sName = "Magic Resistance; (C)", nDuration = 10, sUnits = "minute" },
	},
	["compelledduel"] = {
		{ type = "powersave", save = "wisdom", magic = true, savebase = "group" },
		{ type = "effect", sName = "DISATK; (C)", nDuration = 1, sUnits = "minute" },
	},
	["conjureminorelementals"] = {
		{ type = "effect", sName = "DMG: 2d8 acid; (C)", sTargeting = "self", sApply = "action", nDuration = 1 },
		{ type = "effect", sName = "DMG: 2d8 cold; (C)", sTargeting = "self", sApply = "action", nDuration = 1 },
		{ type = "effect", sName = "DMG: 2d8 fire; (C)", sTargeting = "self", sApply = "action", nDuration = 1 },
		{ type = "effect", sName = "DMG: 2d8 lightning; (C)", sTargeting = "self", sApply = "action", nDuration = 1 },
	},
	["contagion"] = {
		{ type = "powersave", save = "consitution", magic = true, savebase = "group" },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8", "d8", "d8", "d8", "d8", "d8", "d8", "d8", "d8", }, dmgtype = "necrotic" } } },
		{ type = "effect", sName = "Poisoned; DISSAV: strength", nDuration = 7, sUnits = "day" },
		{ type = "effect", sName = "Poisoned; DISSAV: dexterity", nDuration = 7, sUnits = "day" },
		{ type = "effect", sName = "Poisoned; DISSAV: constitution", nDuration = 7, sUnits = "day" },
		{ type = "effect", sName = "Poisoned; DISSAV: intelligence", nDuration = 7, sUnits = "day" },
		{ type = "effect", sName = "Poisoned; DISSAV: wisdom", nDuration = 7, sUnits = "day" },
		{ type = "effect", sName = "Poisoned; DISSAV: charisma", nDuration = 7, sUnits = "day" },
	},
	["continualflame"] = {
		{ type = "effect", sName = "Continual Flame; LIGHT: 20 torch" },
	},
	["crownofmadness"] = {
		{ type = "powersave", save = "wisdom", magic = true, savebase = "group" },
		{ type = "effect", sName = "Charmed; NOTE: Save on end of round; (C)", nDuration = 1, sUnits = "minute" },
	},
	["darkness"] = {
		{ type = "effect", sName = "LIGHT: 15/15 FF000000; (C)", nDuration = 10, sUnits = "minute" },
	},
	["darkvision"] = {
		{ type = "effect", sName = "VISION: 150 darkvision", nDuration = 8, sUnits = "hour" },
	},
	["daylight"] = {
		{ type = "effect", sName = "LIGHT: 60 light", nDuration = 1, sUnits = "hour" },
	},
	["deathward"] = {
		{ type = "effect", sName = "Death Ward", nDuration = 8, sUnits = "hour" },
		{ type = "heal", clauses = { { bonus = 1 } } },
	},
	["delayedblastfireball"] = {
		{ type = "powersave", save = "dexterity", onmissdamage = "half", magic = true, savebase = "group" },
		{ type = "damage", clauses = { { dice = { "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6" }, dmgtype = "fire" } } },
	},
	["destructivewave"] = {
		{ type = "powersave", save = "constitution", onmissdamage = "half", magic = true, savebase = "group" },
		{ type = "damage", clauses = { { dice = { "d6", "d6", "d6", "d6", "d6", }, dmgtype = "thunder" }, { dice = { "d6", "d6", "d6", "d6", "d6", }, dmgtype = "radiant" }, } },
		{ type = "damage", clauses = { { dice = { "d6", "d6", "d6", "d6", "d6", }, dmgtype = "thunder" }, { dice = { "d6", "d6", "d6", "d6", "d6", }, dmgtype = "necrotic" }, } },
		{ type = "effect", sName = "Prone" },
	},
	["dispelevilandgood"] = {
		{ type = "powersave", save = "charisma", magic = true, savebase = "group" },
		{ type = "effect", sName = "IFT: TYPE(aberration, celestial, elemental, fey, fiend, undead); GRANTDISATK; (C)", nDuration = 1, sUnits = "minute" },
	},
	["divineword"] = {
		{ type = "powersave", save = "charisma", magic = true, savebase = "group" },
		{ type = "effect", sName = "Deafened", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "Deafened; Blinded", nDuration = 10, sUnits = "minute" },
		{ type = "effect", sName = "Blinded; Deafened; Stunned", nDuration = 1, sUnits = "hour" },
	},
	["dragonsbreath"] = {
		{ type = "powersave", save = "dexterity", onmissdamage = "half", magic = true, savebase = "group" },
		{ type = "damage", clauses = { { dice = { "d6", "d6", "d6" }, dmgtype = "acid" } } },
		{ type = "damage", clauses = { { dice = { "d6", "d6", "d6" }, dmgtype = "cold" } } },
		{ type = "damage", clauses = { { dice = { "d6", "d6", "d6" }, dmgtype = "fire" } } },
		{ type = "damage", clauses = { { dice = { "d6", "d6", "d6" }, dmgtype = "lightning" } } },
		{ type = "damage", clauses = { { dice = { "d6", "d6", "d6" }, dmgtype = "poison" } } },
	},
	["elementalweapon"] = {
		{ type = "effect", sName = "ATK: 1; DMG: 1d4 acid; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "effect", sName = "ATK: 1; DMG: 1d4 cold; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "effect", sName = "ATK: 1; DMG: 1d4 fire; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "effect", sName = "ATK: 1; DMG: 1d4 lightning; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "effect", sName = "ATK: 1; DMG: 1d4 thunder; (C)", nDuration = 1, sUnits = "hour" },
	},
	["enhanceability"] = {
		{ type = "effect", sName = "ADVCHK: strength; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "effect", sName = "ADVCHK: dexterity; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "effect", sName = "ADVCHK: intelligence; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "effect", sName = "ADVCHK: wisdom; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "effect", sName = "ADVCHK: charisma; (C)", nDuration = 1, sUnits = "hour" },
	},
	["enlargereduce"] = {
		{ type = "powersave", save = "constitution", magic = true, savebase = "group" },
		{ type = "effect", sName = "NOTE: Enlarged; ADVCHK: strength; ADVSAV: strength; DMG: 1d4; (C)", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "NOTE: Reduced; DISCHK: strength; DISSAV: strength; DMG: -1d4; (C)", nDuration = 1, sUnits = "minute" },
	},
	["ensnaringstrike"] = {
		{ type = "powersave", save = "strength", magic = true, savebase = "group" },
		{ type = "effect", sName = "Restrained; DMGO: 1d6 piercing; (C)", nDuration = 1, sUnits = "minute" },
	},
	["enthrall"] = {
		{ type = "powersave", save = "wisdom", magic = true, savebase = "group" },
		{ type = "effect", sName = "SKILL: -10 perception; (C)", nDuration = 1, sUnits = "minute" },
	},
	["faeriefire"] = {
		{ type = "powersave", save = "dexterity", magic = true, savebase = "group" },
		{ type = "effect", sName = "LIGHT: 0/10 light; GRANTADVATK; (C)", nDuration = 1, sUnits = "minute" },
	},
	["feigndeath"] = {
		{ type = "effect", sName = "Blinded; Incapacitated; Speed 0; RESIST: all, !psychic; IMMUNE: Poisoned", nDuration = 1, sUnits = "hour" },
	},
	["flameblade"] = {
		{ type = "attack", range = "M", spell = true, base = "group" },
		{ type = "damage", clauses = { { dice = { "d6", "d6", "d6", }, dmgtype = "fire", stat="base", } } },
		{ type = "effect", sName = "Flame Blade; LIGHT: 10 torch; (C)", nDuration = 10, sUnits = "minute" },
	},
	["fleshtostone"] = {
		{ type = "powersave", save = "constitution", magic = true, savebase = "group" },
		{ type = "effect", sName = "Restrained; (C)", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "Speed 0", nDuration = 1 },
		{ type = "effect", sName = "Petrified; (C)", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "Petrified" },
	},
	["forbiddance"] = {
		{ type = "damage", clauses = { { dice = { "d10", "d10", "d10", "d10", "d10" }, dmgtype = "radiant" } } },
		{ type = "damage", clauses = { { dice = { "d10", "d10", "d10", "d10", "d10" }, dmgtype = "necrotic" } } },
	},
	["foresight"] = {
		{ type = "effect", sName = "ADVATK; ADVCHK; ADVSAV; GRANTDISATK", nDuration = 8, sUnits = "hour" },
	},
	["fountofmoonlight"] = {
		{ type = "effect", sName = "Fount of Moonlight; LIGHT: 20 light; RESIST: radiant; DMG: 2d6 radiant; (C)", nDuration = 10, sUnits = "minute" },
		{ type = "powersave", save = "constitution", magic = true, savebase = "group" },
		{ type = "effect", sName = "Blinded", nDuration = 1 },
	},
	["freedomofmovement"] = {
		{ type = "effect", sName = "Freedom of Movement; IMMUNE: Paralyzed; IMMUNE: Restrained; Swim Speed", nDuration = 1, sUnits = "hour" },
	},
	["gaseousform"] = {
		{ type = "effect", sName = "Gaseous Form; Fly Speed 10; RESIST: bludgeoning, piercing, slashing; IMMUNE: Prone; ADVSAV: strength; ADVSAV: dexterity; ADVSAV: constitution", nDuration = 1, sUnits = "hour" },
	},
	["glibness"] = {
		{ type = "effect", sName = "Glibness; NOTE: Charisma Checks are min 15", nDuration = 1, sUnits = "hour" },
	},
	["glyphofwarding"] = {
		{ type = "powersave", save = "dexterity", onmissdamage = "half", magic = true, savebase = "group" },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8", "d8", "d8" }, dmgtype = "acid" } } },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8", "d8", "d8" }, dmgtype = "cold" } } },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8", "d8", "d8" }, dmgtype = "fire" } } },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8", "d8", "d8" }, dmgtype = "lightning" } } },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8", "d8", "d8" }, dmgtype = "thunder" } } },
	},
	["goodberry"] = {
		{ type = "heal", clauses = { { bonus = 1 } } },
	},
	["grease"] = {
		{ type = "powersave", save = "dexterity", magic = true, savebase = "group" },
		{ type = "effect", sName = "Prone" },
	},
	["guidance"] = {
		{ type = "effect", sName = "SKILL: 1d4; (C)", sApply = "roll", nDuration = 1, sUnits = "minute", },
	},
	["guardianoffaith"] = {
		{ type = "powersave", save = "dexterity", onmissdamage = "half", magic = true, savebase = "group" },
		{ type = "damage", clauses = { { bonus = 20, dmgtype = "radiant" } } },
	},
	["guidingbolt"] = {
		{ type = "attack", range = "R", spell = true, base = "group" },
		{ type = "damage", clauses = { { dice = { "d6", "d6", "d6", "d6" }, dmgtype = "radiant" } } },
		{ type = "effect", sName = "GRANTADVATK", nDuration = 1, sApply = "roll" },
	},
	["hallow"] = {
		{ type = "effect", sName = "IMMUNE: Frightened" },
		{ type = "effect", sName = "RESIST: acid" },
		{ type = "effect", sName = "RESIST: cold" },
		{ type = "effect", sName = "RESIST: fire" },
		{ type = "effect", sName = "RESIST: lightning" },
		{ type = "effect", sName = "RESIST: necrotic" },
		{ type = "effect", sName = "RESIST: poison" },
		{ type = "effect", sName = "RESIST: psychic" },
		{ type = "effect", sName = "RESIST: radiant" },
		{ type = "effect", sName = "RESIST: thunder" },
		{ type = "effect", sName = "VULN: acid" },
		{ type = "effect", sName = "VULN: cold" },
		{ type = "effect", sName = "VULN: fire" },
		{ type = "effect", sName = "VULN: lightning" },
		{ type = "effect", sName = "VULN: necrotic" },
		{ type = "effect", sName = "VULN: poison" },
		{ type = "effect", sName = "VULN: psychic" },
		{ type = "effect", sName = "VULN: radiant" },
		{ type = "effect", sName = "VULN: thunder" },
		{ type = "effect", sName = "Frightened" },
		{ type = "effect", sName = "Silenced" },
		{ type = "effect", sName = "Tongues" },
	},
	["haste"] = {
		{ type = "effect", sName = "Haste; AC: 2; ADVSAV: dexterity; (C)", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "Lethargy; Incapacitated; Speed 0", nDuration = 1 },
	},
	["heroesfeast"] = {
		{ type = "effect", sName = "RESIST: poison; IMMUNE: Poisoned,Frightened", nDuration = 1, sUnits = "day" },
		{ type = "heal", subtype = "temp", clauses = { { dice = { "d10", "d10" } } } },
	},
	["heroism"] = {
		{ type = "effect", sName = "IMMUNE: Frightened; (C)", nDuration = 1, sUnits = "minute" },
		{ type = "heal", subtype = "temp", clauses = { { stat = "base" } } },
	},
	["hex"] = {
		{ type = "effect", sName = "[TRGT]; DMG: 1d6 necrotic; (C)", sTargeting = "self", nDuration = 1, sUnits = "hour" },
		{ type = "effect", sName = "DISCHK: strength; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "effect", sName = "DISCHK: dexterity; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "effect", sName = "DISCHK: constitution; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "effect", sName = "DISCHK: intelligence; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "effect", sName = "DISCHK: wisdom; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "effect", sName = "DISCHK: charisma; (C)", nDuration = 1, sUnits = "hour" },
	},
	["holyaura"] = {
		{ type = "effect", sName = "ADVSAV; GRANTDISATK; (C)", nDuration = 1, sUnits = "minute" },
		{ type = "powersave", save = "constitution", magic = true, savebase = "group" },
		{ type = "effect", sName = "Blinded", nDuration = 1 },
	},
	["huntersmark"] = {
		{ type = "effect", sName = "Hunter's Mark; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "effect", sName = "IFT: CUSTOM(Hunter's Mark); DMG: 1d6 force; (C)", sTargeting = "self", nDuration = 1, sUnits = "hour" },
	},
	["hypnoticpattern"] = {
		{ type = "powersave", save = "wisdom", magic = true, savebase = "group" },
		{ type = "effect", sName = "Charmed; Incapacitated; Speed 0; (C)", nDuration = 1, sUnits = "minute" },
	},
	["jallarzisstormofradiance"] = {
		{ type = "effect", sName = "Storm of Radiance; (C)", sTargeting = "self", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "Blinded; Deafened; (C)", nDuration = 1, sUnits = "minute" },
		{ type = "powersave", save = "constitution", onmissdamage = "half", magic = true, savebase = "group" },
		{ type = "damage", clauses = { { dice = { "d6", "d6", }, dmgtype = "radiant" }, { dice = { "d6", "d6", }, dmgtype = "thunder" } } },
	},
	["light"] = {
		{ type = "effect", sName = "LIGHT: 20 light", nDuration = 1, sUnits = "hour" },
	},
	["longstrider"] = {
		{ type = "effect", sName = "Speed +10", nDuration = 1, sUnits = "hour" },
	},
	["magearmor"] = {
		{ type = "effect", sName = "AC: 3", nDuration = 8, sUnits = "hour" },
	},
	["magiccircle"] = {
		{ type = "powersave", save = "charisma", magic = true, savebase = "group" },
		{ type = "effect", sName = "IFT: TYPE(aberration, celestial, elemental, fey, fiend, undead); GRANTDISATK; IMMUNE: Charmed,Frightened; [FIXED]", nDuration = 1, sUnits = "hour" },
	},
	["magicweapon"] = {
		{ type = "effect", sName = "ATK: 1; DMG: 1; DMGTYPE: magic; (C)", nDuration = 1, sUnits = "hour" },
	},
	["melfsacidarrow"] = {
		{ type = "attack", range = "R", spell = true, base = "group" },
		{ type = "damage", clauses = { { dice = { "d4", "d4", "d4", "d4", }, dmgtype = "acid" } } },
		{ type = "effect", sName = "DMGO: 2d4 acid", nDuration = 1 },
		{ type = "damage", clauses = { { dice = { "d4", "d4", }, dmgtype = "acid" } } },
	},
	["mindblank"] = {
		{ type = "effect", sName = "IMMUNE: psychic; IMMUNE: Charmed", nDuration = 24, sUnits = "hour" },
	},
	["mindsliver"] = {
		{ type = "powersave", save = "intelligence", magic = true, savebase = "group" },
		{ type = "damage", clauses = { { dice = { "d6", }, dmgtype = "psychic" } } },
		{ type = "effect", sName = "SAVE: -1d4", sApply="roll", nDuration = 1 },
	},
	["nondetection"] = {
		{ type = "effect", sName = "Nondetection", nDuration = 8, sUnits = "hour" },
	},
	["ottosirresistibledance"] = {
		{ type = "powersave", save = "wisdom", magic = true, savebase = "group" },
		{ type = "effect", sName = "Charmed; Speed 0; Must Dance; DISSAV: dexterity; DISATK; GRANTADVATK; NOTE: Save on end of round; (C)", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "Speed 0; Must Dance", nDuration = 1 },
	},
	["passwithouttrace"] = {
		{ type = "effect", sName = "SKILL: 10 stealth; (C)", nDuration = 1, sUnits = "hour" },
	},
	["phantasmalkiller"] = {
		{ type = "powersave", save = "wisdom", onmissdamage = "half", magic = true, savebase = "group" },
		{ type = "damage", clauses = { { dice = { "d10", "d10", "d10", "d10", }, dmgtype = "psychic" } } },
		{ type = "effect", sName = "DMGO: 4d10 psychic; NOTE: Save on end of round; (C)", nDuration = 1, sUnits = "minute" },
	},
	["powerwordstun"] = {
		{ type = "effect", sName = "Stunned; NOTE: Con Save on end of round" },
	},
	["prismaticspray"] = {
		{ type = "powersave", save = "dexterity", onmissdamage = "half", magic = true, savebase = "group" },
		{ type = "damage", clauses = { { dice = { "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6" }, dmgtype = "fire" } } },
		{ type = "damage", clauses = { { dice = { "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6" }, dmgtype = "acid" } } },
		{ type = "damage", clauses = { { dice = { "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6" }, dmgtype = "lightning" } } },
		{ type = "damage", clauses = { { dice = { "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6" }, dmgtype = "poison" } } },
		{ type = "damage", clauses = { { dice = { "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6" }, dmgtype = "cold" } } },
		{ type = "effect", sName = "Restrained; NOTE: Con Save on end of round (3 Successes Ends Effect) (3 Failures Applies Petrified)" },
		{ type = "effect", sName = "Blinded; NOTE: Wis Save on end of round (Success Ends) (Failure Teleports)", nDuration = 1 },
	},
	["prismaticwall"] = {
		{ type = "powersave", save = "constitution", magic = true, savebase = "group" },
		{ type = "effect", sName = "Blinded", nDuration = 1, sUnits = "minute" },
		{ type = "powersave", save = "dexterity", onmissdamage = "half", magic = true, savebase = "group" },
		{ type = "damage", clauses = { { dice = { "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6" }, dmgtype = "fire" } } },
		{ type = "damage", clauses = { { dice = { "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6" }, dmgtype = "acid" } } },
		{ type = "damage", clauses = { { dice = { "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6" }, dmgtype = "lightning" } } },
		{ type = "damage", clauses = { { dice = { "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6" }, dmgtype = "poison" } } },
		{ type = "damage", clauses = { { dice = { "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6" }, dmgtype = "cold" } } },
		{ type = "effect", sName = "Restrained; NOTE: Con Save on end of round (3 Successes Ends Effect) (3 Failures Applies Petrified)" },
		{ type = "effect", sName = "Blinded; NOTE: Wis Save on end of round (Success Ends) (Failure Teleports)", nDuration = 1 },
	},
	["produceflame"] = {
		{ type = "effect", sName = "LIGHT: 20 torch", nDuration = 10, sUnits = "minute" },
		{ type = "attack", range = "R", spell = true, base = "group" },
		{ type = "damage", clauses = { { dice = { "d8", }, dmgtype = "fire" } } },
	},
	["protectionfromenergy"] = {
		{ type = "effect", sName = "RESIST: acid; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "effect", sName = "RESIST: cold; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "effect", sName = "RESIST: fire; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "effect", sName = "RESIST: lightning; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "effect", sName = "RESIST: thunder; (C)", nDuration = 1, sUnits = "hour" },
	},
	["protectionfromevilandgood"] = {
		{ type = "effect", sName = "IFT: TYPE(aberration, celestial, elemental, fey, fiend, undead); GRANTDISATK; IMMUNE: Charmed,Frightened; (C)", nDuration = 10, sUnits = "minute" },
	},
	["protectionfrompoison"] = {
		{ type = "effect", sName = "RESIST: poison; NOTE: Poisoned save advantage", nDuration = 1, sUnits = "hour" },
	},
	["rarystelepathicbond"] = {
		{ type = "effect", sName = "Telepathic Bond", nDuration = 1, sUnits = "hour" },
	},
	["rayofenfeeblement"] = {
		{ type = "powersave", save = "constitution", magic = true, savebase = "group" },
		{ type = "effect", sName = "DISATK; DISCHK: strength; DISSAV: strength; DMG: -1d8; NOTE: Save on end of round; (C)", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "DISATK; (C)", sApply = "roll", nDuration = 1 },
	},
	["rayoffrost"] = {
		{ type = "attack", range = "R", spell = true, base = "group" },
		{ type = "damage", clauses = { { dice = { "d8", }, dmgtype = "cold" } } },
		{ type = "effect", sName = "Speed -10", nDuration = 1 },
	},
	["regenerate"] = {
		{ type = "heal", clauses = { { dice = { "d8", "d8", "d8", "d8", }, bonus = 15 } } },
		{ type = "effect", sName = "REGEN: 1", nDuration = 1, sUnits = "hour" },
	},
	["resistance"] = {
		{ type = "effect", sName = "RESIST: 1d4 acid; (C)", sApply = "roll", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "RESIST: 1d4 bludgeoning; (C)", sApply = "roll", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "RESIST: 1d4 cold; (C)", sApply = "roll", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "RESIST: 1d4 fire; (C)", sApply = "roll", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "RESIST: 1d4 lightning; (C)", sApply = "roll", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "RESIST: 1d4 necrotic; (C)", sApply = "roll", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "RESIST: 1d4 piercing; (C)", sApply = "roll", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "RESIST: 1d4 poison; (C)", sApply = "roll", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "RESIST: 1d4 radiant; (C)", sApply = "roll", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "RESIST: 1d4 slashing; (C)", sApply = "roll", nDuration = 1, sUnits = "minute" },
		{ type = "effect", sName = "RESIST: 1d4 thunder; (C)", sApply = "roll", nDuration = 1, sUnits = "minute" },
	},
	["resurrection"] = {
		{ type = "effect", sName = "ATK: -4; CHECK: -4; SAVE: -4", nDuration = 4, sUnits = "day" },
	},
	["revivify"] = {
		{ type = "heal", clauses = { { bonus = 1 } } },
	},
	["sanctuary"] = {
		{ type = "effect", sName = "Sanctuary", nDuration = 1, sUnits = "minute" },
		{ type = "powersave", save = "wisdom", magic = true, savebase = "group" },
	},
	["searingsmite"] = {
		{ type = "effect", sName = "DMG: 1d6 fire", sTargeting = "self", sApply = "roll", nDuration = 1 },
		{ type = "effect", sName = "DMGO: 1d6 fire; NOTE: Con Save on end of round" },
	},
	["seeming"] = {
		{ type = "effect", sName = "Seeming", nDuration = 8, sUnits = "hour" },
	},
	["shield"] = {
		{ type = "effect", sName = "AC: 5", sTargeting = "self", nDuration = 1 },
	},
	["shieldoffaith"] = {
		{ type = "effect", sName = "AC: 2; (C)", nDuration = 10, sUnits = "minute" },
	},
	["shillelagh"] = {
		{ type = "damage", clauses = { { dice = { "d8", }, dmgtype = "force", stat = "base" } } },
	},
	["shiningsmite"] = {
		{ type = "effect", sName = "DMG: 2d6 radiant", sTargeting = "self", sApply = "roll", nDuration = 1 },
		{ type = "effect", sName = "LIGHT: 5 light; GRANTADVATK; NOTE: No Invisible; (C)", nDuration = 1, sUnits = "minute" },
	},
	["shockinggrasp"] = {
		{ type = "attack", range = "M", spell = true, base = "group" },
		{ type = "damage", clauses = { { dice = { "d8", }, dmgtype = "lightning" } } },
		{ type = "effect", sName = "NOTE: No Opportunity Attacks", nDuration = 1 },
	},
	["silence"] = {
		{ type = "effect", sName = "Silenced; IMMUNE: thunder; IMMUNE: Deafened; (C)", nDuration = 10, sUnits = "minute" },
	},
	["sleep"] = {
		{ type = "powersave", save = "wisdom", magic = true, savebase = "group" },
		{ type = "effect", sName = "Incapacitated; NOTE: NOTE: Save on end of round (Success ends) (Failure applies Unconscious); (C)", nDuration = 1, sUnits = "minute" },
	},
	["slow"] = {
		{ type = "powersave", save = "wisdom", magic = true, savebase = "group" },
		{ type = "effect", sName = "Slowed; Speed Half; AC: -2; SAVE: -2 dexterity; NOTE: No Reactions; NOTE: Save on end of round; (C)", nDuration = 1, sUnits = "minute" },
	},
	["sorcerousburst"] = {
		{ type = "attack", range = "R", spell = true, base = "group" },
		{ type = "damage", clauses = { { dice = { "d8", }, dmgtype = "acid" } } },
		{ type = "damage", clauses = { { dice = { "d8", }, dmgtype = "cold" } } },
		{ type = "damage", clauses = { { dice = { "d8", }, dmgtype = "fire" } } },
		{ type = "damage", clauses = { { dice = { "d8", }, dmgtype = "lightning" } } },
		{ type = "damage", clauses = { { dice = { "d8", }, dmgtype = "poison" } } },
		{ type = "damage", clauses = { { dice = { "d8", }, dmgtype = "psychic" } } },
		{ type = "damage", clauses = { { dice = { "d8", }, dmgtype = "thunder" } } },
	},
	["spiritguardians"] = {
		{ type = "effect", sName = "Spirit Guardians; (C)", nDuration = 10, sUnits = "minute" },
		{ type = "effect", sName = "Speed Half; (C)", nDuration = 10, sUnits = "minute" },
		{ type = "powersave", save = "wisdom", onmissdamage = "half", magic = true, savebase = "group" },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8" }, dmgtype = "radiant" } } },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8" }, dmgtype = "necrotic" } } },
	},
	["starrywisp"] = {
		{ type = "attack", range = "R", spell = true, base = "group" },
		{ type = "damage", clauses = { { dice = { "d8", }, dmgtype = "radiant" } } },
		{ type = "effect", sName = "LIGHT: 0/10 light; NOTE: No Invisible", nDuration = 1 },
	},
	["stinkingcloud"] = {
		{ type = "powersave", save = "constitution", magic = true, savebase = "group" },
		{ type = "effect", sName = "Poisoned; NOTE: No Action, NOTE: No Bonus Action", nDuration = 1 },
	},
	["stoneskin"] = {
		{ type = "effect", sName = "RESIST: bludgeoning,piercing,slashing; (C)", nDuration = 1, sUnits = "hour" },
	},
	["stormofvengeance"] = {
		{ type = "powersave", save = "constitution", onmissdamage = "half", magic = true, savebase = "group" },
		{ type = "damage", clauses = { { dice = { "d6", "d6" }, dmgtype = "thunder" } } },
		{ type = "effect", sName = "Deafened; (C)", nDuration = 1, sUnits = "minute" },
		{ type = "damage", clauses = { { dice = { "d6", "d6", "d6", "d6" }, dmgtype = "acid" } } },
		{ type = "powersave", save = "dexterity", onmissdamage = "half", magic = true, savebase = "group" },
		{ type = "damage", clauses = { { dice = { "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6" }, dmgtype = "lightning" } } },
		{ type = "damage", clauses = { { dice = { "d6", "d6" }, dmgtype = "bludgeoning" } } },
		{ type = "damage", clauses = { { dice = { "d6" }, dmgtype = "cold" } } },
	},
	["symbol"] = {
		{ type = "powersave", save = "constitution", onmissdamage = "half", magic = true, savebase = "group" },
		{ type = "damage", clauses = { { dice = { "d10", "d10", "d10", "d10", "d10", "d10", "d10", "d10", "d10", "d10" }, dmgtype = "necrotic" } } },
		{ type = "powersave", save = "wisdom", magic = true, savebase = "group" },
		{ type = "effect", sName = "Symbol of Discord; DISATK; DISCHK", nDuration = 1, sUnits = "minute" },
		{ type = "powersave", save = "wisdom", magic = true, savebase = "group" },
		{ type = "effect", sName = "Symbol of Fear; Frightened", nDuration = 1, sUnits = "minute" },
		{ type = "powersave", save = "constitution", magic = true, savebase = "group" },
		{ type = "effect", sName = "Symbol of Pain; Incapacitated", nDuration = 1, sUnits = "minute" },
		{ type = "powersave", save = "wisdom", magic = true, savebase = "group" },
		{ type = "effect", sName = "Symbol of Sleep; Unconscious", nDuration = 10, sUnits = "minute" },
		{ type = "powersave", save = "wisdom", magic = true, savebase = "group" },
		{ type = "effect", sName = "Symbol of Stunning; Stunned", nDuration = 1, sUnits = "minute" },
	},
	["synapticstatic"] = {
		{ type = "powersave", save = "intelligence", onmissdamage = "half", magic = true, savebase = "group" },
		{ type = "damage", clauses = { { dice = { "d6", "d6", "d6", "d6", "d6", "d6", "d6", "d6" }, dmgtype = "psychic" } } },
		{ type = "effect", sName = "Muddled Thoughts; ATK: -1d6; CHECK: -1d6; NOTE: Concentration saves -1d6; NOTE: Save on end of round", nDuration = 1, sUnits = "minute" },
	},
	["tashashideouslaughter"] = {
		{ type = "powersave", save = "wisdom", magic = true, savebase = "group" },
		{ type = "effect", sName = "Prone; Incapacitated; NOTE: Unable to stand up; NOTE: Save on end of round and damage; (C)", nDuration = 1, sUnits = "minute" },
	},
	["telepathy"] = {
		{ type = "effect", sName = "Telepathy", nDuration = 24, sUnits = "hour" },
	},
	["tongues"] = {
		{ type = "effect", sName = "Tongues", nDuration = 1, sUnits = "hour" },
	},
	["truepolymorph"] = {
		{ type = "powersave", save = "wisdom", magic = true, savebase = "group" },
		{ type = "effect", sName = "True Polymorph; (C)", nDuration = 1, sUnits = "hour" },
	},
	["trueseeing"] = {
		{ type = "effect", sName = "VISION: 120 truesight", nDuration = 1, sUnits = "hour" },
	},
	["truestrike"] = {
		{ type = "effect", sName = "[TRGT]; NOTE: Attack/Damage use spell ability; DMGTYPE: radiant", sTargeting = "self", sApply = "roll", nDuration = 1 },
	},
	["tsunami"] = {
		{ type = "powersave", save = "strength", onmissdamage = "half", magic = true, savebase = "group" },
		{ type = "damage", clauses = { { dice = { "d10", "d10", "d10", "d10", "d10", "d10" }, dmgtype = "bludgeoning" } } },
		{ type = "powersave", save = "strength", magic = true, savebase = "group" },
		{ type = "damage", clauses = { { dice = { "d10", "d10", "d10", "d10", "d10" }, dmgtype = "bludgeoning" } } },
	},
	["viciousmockery"] = {
		{ type = "powersave", save = "wisdom", magic = true, savebase = "group" },
		{ type = "damage", clauses = { { dice = { "d6" }, dmgtype = "psychic" } } },
		{ type = "effect", sName = "DISATK", sApply = "roll", nDuration = 1 },
	},
	["walloffire"] = {
		{ type = "effect", sName = "Wall of Fire; (C)", sTargeting = "self", nDuration = 1, sUnits = "minute" },
		{ type = "powersave", save = "dexterity", onmissdamage = "half", magic = true, savebase = "group" },
		{ type = "damage", clauses = { { dice = { "d8", "d8", "d8", "d8", "d8" }, dmgtype = "fire" } } },
	},
	["wardingbond"] = {
		{ type = "effect", sName = "AC: 1; SAVE: 1; RESIST: all; NOTE: Caster takes same damage", nDuration = 1, sUnits = "hour" },
	},
	["waterbreathing"] = {
		{ type = "effect", sName = "Water Breathing", nDuration = 24, sUnits = "hour" },
	},
	["waterwalk"] = {
		{ type = "effect", sName = "Water Walk", nDuration = 1, sUnits = "hour" },
	},
	["web"] = {
		{ type = "effect", sName = "Web; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "powersave", save = "dexterity", magic = true, savebase = "group" },
		{ type = "effect", sName = "Restrained; (C)", nDuration = 1, sUnits = "hour" },
		{ type = "damage", clauses = { { dice = { "d4", "d4" }, dmgtype = "fire" } } },
	},
	["windwalk"] = {
		{ type = "effect", sName = "Wind Walk; Fly Speed 300; IMMUNE: Prone; RESIST: bludgeoning,piercing,slashing; NOTE: Can only Dash or revert", nDuration = 8, sUnits = "hour" },
		{ type = "effect", sName = "Wind Walk (Reverting); Stunned", nDuration = 1, sUnits = "minute" },
	},
	["wrathfulsmite"] = {
		{ type = "effect", sName = "DMG: 1d6 necrotic", sTargeting = "self", sApply = "roll", nDuration = 1 },
		{ type = "powersave", save = "wisdom", magic = true, savebase = "group" },
		{ type = "effect", sName = "Frightened; NOTE: Save on end of round", nDuration = 1, sUnits = "minute" },
	},
};
