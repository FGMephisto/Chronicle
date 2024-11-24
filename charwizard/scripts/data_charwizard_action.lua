-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Examples:
-- { type = "attack", range = "[M|R]", [modifier = #] }
--		If modifier defined, then attack bonus will be this fixed value
--		Otherwise, the attack bonus will be the ability bonus defined for the spell group
--
-- { type = "damage", clauses = { { dice = { "d#", ... }, modifier = #, type = "", [stat = ""] }, ... }, }
--		Each damage action can have multiple clauses which can do different damage types
--
-- { type = "heal", [subtype = "temp", ][sTargeting = "self", ] clauses = { { dice = { "d#", ... }, bonus = #, [stat = ""] }, ... }, }
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
--[[
	[""] = {
		actions = {
			{ type = "attack", range = "[M|R]", [modifier = #] },
			{ type = "damage", clauses = { { dice = { "d#", ... }, modifier = #, dmgtype = "", [stat = ""] }, ... }, },
			{ type = "heal", [subtype = "temp", ][sTargeting = "self", ] clauses = { { dice = { "d#", ... }, bonus = #, [stat = ""] }, ... }, },
			{ type = "powersave", save = "<ability>", [savemod = #, ][savestat = "<ability>", ][onmissdamage = "half"] },
			{ type = "effect", sName = "<effect text>", [sTargeting = "self", ][nDuration = #, ][sUnits = "[<empty>|minute|hour|day]", ][sApply = "[<empty>|action|roll|single]"] },
		},
	},
--]]
parsedata = {
	--
	-- CLASSES
	--
	-- Artificier
	["protector"] = { actions = { { type = "heal", subtype = "temp", clauses = { { dice = { "d8" }, stat = "intelligence" }, }, }, }, },
	["spellstoringitem"] = { actions = {}, prepared = 1, usesperiod = "once" },
	["soulofartifice"] = {
		actions = { { type = "effect", sName = "Soul of Artifice; SAVE: 1", sTargeting = "self", }, },
		prepared = 1,
	},
	["restorativereagents"] = {
		spell = { innate = { "Lesser Restoration", }, },
		actions = { { type = "heal", subtype = "temp", clauses = { { dice = { "d6", "d6" }, stat = "intelligence" }, }, }, },
	},
	["flashofgenius"] = { actions = { { type = "effect", sName = "Flash of Genius; SAVE: [INT]; CHECK: [INT]", sApply = "action", }, }, prepared = 1, },
	-- Artificer - Alchemist
	["toolproficiencyalchemist"] = {
		toolprof = { innate = { "Alchemist's Supplies" }, },
	},
	["alchemistsspells"] = {
		spell = {
			level = {
				[3] = { "Healing Word", "Ray of Sickness" },
				[5] = { "Flaming Sphere", "Melf's Acid Arrow" },
				[9] = { "Gaseous Form", "Mass Healing Word" },
				[13] = { "Blight", "Death Ward" },
				[17] = { "Cloudkill", "Raise Dead" },
			},
		},
	},
	["alchemicalsavant"] = {
		actions = {
			{ type = "effect", sName = "Alchemical Savant; HEAL: [INT]", sTargeting = "self", sApply = "roll", },
			{ type = "effect", sName = "Alchemical Savant; DMG: [INT]", sTargeting = "self", sApply = "roll", },
		},
	},
	["experimentalelixier"] = {
		multiple_actions = {
			["Experimental Elixier (Healing)"] = { actions = { { type = "heal", clauses = { { dice = { "d4", "d4" }, stat = "intelligence" }, }, }, }, },
			["Experimental Elixier (Resilience)"] = { actions = { { type = "effect", sName = "AC: 1", nDuration = 10, sUnits = "minute", }, }, },
			["Experimental Elixier (Boldness)"] = {
				actions = {
					{ type = "effect", sName = "ATK: d4", nDuration = 1, sUnits = "minute", },
					{ type = "effect", sName = "SAVE: d4", nDuration = 1, sUnits = "minute", },
				},
			},
		},
	},
	["restorativereagents"] = { actions = { { type = "heal", subtype = "temp", clauses = { { dice = { "d6", "d6" }, stat = "intelligence" }, }, }, }, },
	["chemicalmastery"] = {
		actions = { { type = "effect", sName = "Chemical Mastery; RESIST: acid; RESIST: poison; IMMUNE: poisoned", sTargeting = "self", }, },
		spell = { innate = { "Greater Restoration" }, },
	},
	-- Artificer - Armorer
	["toolsofthetraidearmorer"] = {
		armorprof = { innate = { "Heavy" }, },
		toolprof = { innate = { "Smith's Tools" }, },
	},
	["armorerspells"] = {
		spell = {
			level = {
				[3] = { "Magic Missile", "Thunderwave" },
				[5] = { "Mirror Image", "Shatter" },
				[9] = { "Hypnotic Pattern", "Lightning Bolt" },
				[13] = { "Fire Shield", "Greater Invisibility" },
				[17] = { "Passwall", "Wall of Force" },
			},
		},
	},
	["armormodel"] = {
		multiple_actions = {
			["Armor Model (Thunder Gauntlets)"] = { actions = { { type = "damage", clauses = { { dice = { "d8", }, dmgtype = "thunder", }, }, }, }, },
			["Armor Model (Defensive Field)"] = { actions = { { type = "heal", subtype = "temp", sTargeting = "self", clauses = { { dice = { }, stat = "artificer" }, }, }, }, },
			["Armor Model (Lightning Launcher)"] = {
				actions = {
					{ type = "attack", range = "R", },
					{ type = "damage", clauses = { { dice = { "d6", }, dmgtype = "lightning", }, }, },
				},
			},
			["Dampening Field"] = { actions = { { type = "effect", sName = "Dampening Field; ADVSAV: stealth", sTargeting = "self", }, }, },
		},
	},
	-- Artificer - Artillerist
	["toolsofthetraideartillerist"] = {
		toolprof = { innate = { "Woodcarver's Tools" }, },
	},
	["fortifiedposition"] = { actions = { { type = "effect", sName = "Fortified Position; Allies within 10 ft. of Eldritch Cannon have 1/2 cover", sTargeting = "self", }, }, },
	["artilleristspells"] = {
		spell = {
			level = {
				[3] = { "Shield", "Thunderwave" },
				[5] = { "Scorching Ray", "Shatter" },
				[9] = { "fireball", "Wind Wall" },
				[13] = { "Ice Storm", "Wall of Fire" },
				[17] = { "Cone of Cold", "Wall of Force" },
			},
		},
	},
	["eldritchcannon"] = { actions = { { type = "heal", clauses = { { dice = { "d6", "d6" }, }, }, }, }, },
	["arcanefirearm"] = { actions = { { type = "effect", sName = "Arcane Firearm; DMG: 1d8", sTargeting = "self",  sApply = "roll" }, }, },
	["explosivecannon"] = {
		actions = {
			{ type = "damage", clauses = { { dice = { "d8", "d8", "d8" }, dmgtype = "force", }, }, },
			{ type = "powersave", save = "dexterity", onmissdamage = "half" },
		},
	},
	-- Artificer - Battle Smith
	["toolproficiencybattlesmith"] = {
		toolprof = { innate = { "Smith's Tools" }, },
	},
	["battlesmithspells"] = {
		spell = {
			level = {
				[3] = { "Heroism", "Shield" },
				[5] = { "Branding Smite", "Warding Bond" },
				[9] = { "Aura of Vitality", "Conjure Barrage" },
				[13] = { "Aura of Purity", "Fire Shield" },
				[17] = { "Banishing Smite", "Mass Cure Wounds" },
			},
		},
	},
	["improveddefender"] = {
		actions = {
			{ type = "effect", sName = "Steel Defender; AC: 2", },
			{ type = "damage", clauses = { { dice = { "d4" }, dmgtype = "force", stat = "intelligence"  }, }, },
		},
	},
	["battleready"] = { weaponprof = { innate = { "Martial" }, }, },
	["arcanejolt"] = {
		actions = {
			{ type = "effect", sName = "Arcane Jolt; DMG: 2d6 force", sTargeting = "self", sApply = "roll", },
			{ type = "heal", clauses = { { dice = { "d6", "d6" }, }, }, },
		},
	},
	-- Barbarian
	["rage"] = { actions = { { type = "effect", sName = "Rage; ADVCHK: strength; ADVSAV: strength; DMG: 2, melee; RESIST: bludgeoning, piercing, slashing", sTargeting = "self", nDuration = 1, sUnits = "minute" }, }, prepared = 2, },
	["recklessattack"] = { actions = { { type = "effect", sName = "Reckless Attack; ADVATK: melee; GRANTADVATK", sTargeting = "self", nDuration = 1,  }, }, },
	["feralinstinct"] = { actions = { { type = "effect", sName = "Feral Instinct; ADVINIT; Can't be surprised but must enter rage", sTargeting = "self" }, }, },
	["relentlessrage"] = { actions = { { type = "powersave", save = "constitution", savemod = 10, }, }, usesperiod = "enc", },
	["retaliation"] = { actions = { { type = "effect", sName = "Retaliation", sTargeting = "self", }, }, },
	["brutalcritical"] = { actions = { { type = "effect", sName = "Brutal Critical; DMG: 3d8, melee, critical", sTargeting = "self", }, }, },
	["dangersense"] = { actions = { { type = "effect", sName = "Danger Sense; ADVSAV: dexterity", sTargeting = "self", sApply = "action" }, }, },
	["frenzy"] = { actions = { { type = "effect", sName = "Frenzy; Extra bonus action attack and suffer exhaustion after rage", sTargeting = "self", }, }, },
	-- Barbarian - Path of the Ancestral Guardian
	["ancestralprotectors"] = {
		actions = {
			{ type = "effect", sName = "Ancestral Protectors; GRANTADVATK", sTargeting = "self", nDuration = 1 },
			{ type = "effect", sName = "Ancestral Protectors; DISATK", nDuration = 1 },
			{ type = "effect", sName = "Ancestral Protectors; RESIST: all", sApply = "roll" },
		},
	},
	["consultthespirits"] = {
		actions = {},
		prepared = 1,
		spell = { innate = { "Augury", "Clairvoyance" }, },
	},
	["vengefulancestors"] = { actions = { { type = "damage", clauses = { { dice = { }, modifier = 1, dmgtype = "force", }, }, }, }, },
	-- Barbarian - Path of the Battlerager
	["battleragerarmor"] = {
		actions = {
			{ type = "attack", range = "M", },
			{ type = "damage", clauses = { { dice = { "d4", }, dmgtype = "piercing", stat = "strength" }, }, },
			{ type = "damage", clauses = { { dice = {}, modifier = 3, dmgtype = "piercing", }, }, },
		},
	},
	["battleragercharge"] = { actions = { { type = "effect", sName = "Battlerager Charge; Bonus action dash while raging", sTargeting = "self", }, }, },
	["recklessabandon"] = { actions = { { type = "heal", subtype = "temp", sTargeting = "self", clauses = { { dice = { }, stat = "constitution" }, }, }, }, },
	["spikedretribution"] = { actions = { { type = "damage", clauses = { { dice = { }, modifier = 3, dmgtype = "piercing", }, }, }, }, },
	-- Barbarian - Path of the Beast
	["formofthebeast"] = {
		multiple_actions = {
			["Form of the Beast (Bite)"] = {
				actions = {
					{ type = "attack", range = "M", },
					{ type = "damage", clauses = { { dice = { "d8", }, dmgtype = "piercing", stat = "strength" }, }, },
					{ type = "heal", sTargeting = "self", clauses = { { dice = { }, stat = "prf" }, }, },
				},
			},
			["Form of the Beast (Claws)"] = {
				actions = {
					{ type = "attack", range = "M", },
					{ type = "damage", clauses = { { dice = { "d6", }, dmgtype = "slashing", stat = "strength" }, }, },
				},
			},
			["Form of the Beast (Tail)"] = {
				actions = {
					{ type = "attack", range = "M", },
					{ type = "damage", clauses = { { dice = { "d8", }, dmgtype = "piercing", stat = "strength" }, }, },
					{ type = "effect", sName = "AC: 1d8", sTargeting = "self", sApply = "single" },
				},
			},
		},
	},
	["infectiousfury"] = {
		actions = {
			{ type = "powersave", save = "wisdom", savestat = "constitution", },
			{ type = "damage", clauses = { { dice = { "d12", "d12" }, dmgtype = "psychic", }, }, },
		},
	},
	["callthehunt"] = {
	   actions = {
			{ type = "heal", subtype = "temp", sTargeting = "self", clauses = { { dice = { }, bonus = 5, }, }, },
			{ type = "effect", sName = "DMG: 1d6", },
	   },
	},
	-- Barbarian - Path of the Berserker
	["mindlessrage"] = { actions = { { type = "effect", sName = "Mindless Rage; IMMUNE: frightened, charmed", sTargeting = "self", }, }, },
	["intimidatingpresence"] = {
		actions = {
			{ type = "powersave", save = "wisdom", savestat = "charisma", },
			{ type = "effect", sName = "Intimidating Presence; Frightened", nDuration = 1 },
		},
	},
	-- Barbarian - Path of the Storm Herald
	["stormaura"] = {
		actions = {
			{ type = "damage", clauses = { { dice = { }, modifier = 2, dmgtype = "fire", }, }, },
			{ type = "powersave", save = "dexterity", onmissdamage = "half" },
			{ type = "damage", clauses = { { dice = { "d6" }, dmgtype = "lightning", }, }, },
			{ type = "heal", subtype = "temp", sTargeting = "self", clauses = { { dice = { }, bonus = 2 }, }, },
		},
	},
	["stormsoul"] = {
		multiple_actions = {
			["Storm Soul (Desert)"] = { actions = { { type = "effect", sName = "Storm Soul: Desert; RESIST: fire; Special fire powers", sTargeting = "self", nDuration = 1, sUnits = "minute" }, }, },
			["Storm Soul (Sea)"] = { actions = { { type = "effect", sName = "Storm Soul: Sea; RESIST: lightning; Breathe underwater; Swim Speed 30'", sTargeting = "self", nDuration = 1, sUnits = "minute" }, }, },
			["Storm Soul (Tundra)"] = { actions = { { type = "effect", sName = "Storm Soul: Tundra; RESIST: cold; Special water powers", sTargeting = "self", nDuration = 1, sUnits = "minute" }, }, },
		},
	},
	["shieldingstorm"] = {
		actions = {
			{ type = "effect", sName = "Shielding Storm; RESIST: fire", },
			{ type = "effect", sName = "Shielding Storm; RESIST: lightning", },
			{ type = "effect", sName = "Shielding Storm; RESIST: cold", },
		},
	},
	["ragingstorm"] = {
		actions = {
			{ type = "powersave", save = "dexterity" },
			{ type = "effect", sName = "Raging Storm; Prone" },
			{ type = "damage", clauses = { { dice = {}, dmgtype = "fire", stat = "barbarian" }, }, },
			{ type = "powersave", save = "strength" },
			{ type = "effect", sName = "Raging Storm; Speed reduced to zero", nDuration = 1 },
		},
	},
	-- Barbarian - Path of the Totem Warrior
	["aspectofthebeast"] = {
		multiple_actions = {
			["Aspect of the Beast (Bear)"] = { actions = { { type = "effect", sName = "Aspect of the Beast (Bear); ADVCHK: strength", sTargeting = "self" }, }, },
			["Aspect of the Beast (Eagle)"] = { actions = { { type = "effect", sName = "Aspect of the Beast (Eagle); Special sight", sTargeting = "self" }, }, },
			["Aspect of the Beast (Wolf)"] = { actions = { { type = "effect", sName = "Aspect of the Beast (Wolf); Special tracking and movement", sTargeting = "self" }, }, },
		},
	},
	["spiritseeker"] = {
		spell = { innate = { "Beast Sense", "Speak with Animals" }, },
	},
	["totemspirit"] = {
		multiple_actions = {
			["Totem Spirit (Bear)"] = { actions = { { type = "effect", sName = "Totem Spirit (Bear); RESIST: all, !psychic", sTargeting = "self", nDuration = 1, sUnits = "minute" }, }, },
			["Totem Spirit (Eagle)"] = { actions = { { type = "effect", sName = "Totem Spirit (Eagle); Opportunity attacks are at disadvantage and bonus action dash", sTargeting = "self" }, }, },
			["Totem Spirit (Wolf)"] = { actions = { { type = "effect", sName = "Totem Spirit (Wolf); ADVATK: melee", sApply = "roll" }, }, },
		},
	},
	["totemicattunement"] = {
		multiple_actions = {
			["Totemic Attunement (Bear)"] = {
				actions = {
					 { type = "effect", sName = "Totemic Attunement (Bear); DISATK: melee", sApply = "roll", },
					 { type = "effect", sName = "Totemic Attunement (Bear); GRANTADVATK: melee", sTargeting = "self", sApply = "roll", },
				},
			},
			["Totemic Attunement (Eagle)"] = { actions = { { type = "effect", sName = "Totemic Attunement (Eagle); Fly speed", sTargeting = "self", }, }, },
			["Totemic Attunement (Wolf)"] = { actions = { { type = "effect", sName = "Totemic Attunement (Wolf); Prone", }, }, },
		},
	},
	-- Barbarian - Path of the Zealot
	["divinefury"] = {
		actions = {
			{ type = "effect", sName = "Divine Fury; DMG: [HLVL] necrotic; DMG: 1d6 necrotic", sTargeting = "self", sApply = "roll" },
			{ type = "effect", sName = "Divine Fury; DMG: [HLVL] radiant; DMG: 1d6 radiant", sTargeting = "self", sApply = "roll" },
		},
	},
	["zealouspresence"] = { actions = { { type = "effect", sName = "Zealous Presence; ADVATK;ADVSAV", nDuration = 1 }, }, prepared = 1, },
	-- Bard
	["bardicinspiration"] = { actions = { { type = "effect", sName = "Bardic Inspiration (d6) used for ability check, attack roll, or saving throw", nDuration = 10, sUnits = "minute" }, }, },
	["countercharm"] = { actions = { { type = "effect", sName = "Countercharm; Advantage on saving throws vs. Frightened or Charmed", sTargeting = "self", nDuration = 1 }, }, },
	["songofrest"] = { actions = { { type = "heal", clauses = { { dice = { "d6" }, }, }, }, }, },
	-- Bard - College of Creation
	-- Bard - College of Eloquence
	-- Bard - College of Glamour
	["mantleofinspiration"] = { actions = { { type = "heal", subtype = "temp", clauses = { { dice = {}, bonus = 5, }, }, }, }, },
	["enthrallingperformance"] = {
		actions = {
			{ type = "powersave", save = "wisdom" },
			{ type = "effect", sName = "Enthralling Performance; Charmed", nDuration = 1, sUnits = "hour" },
		},
		prepared = 1,
		usesperiod = "enc",
	},
	["mantleofmajesty"] = { actions = { { type = "effect", sName = "Mantle of Majesty", sTargeting = "self", nDuration = 1, sUnits = "minute" }, }, prepared = 1 },
	["unbreakablemajesty"] = {
		actions = {
			{ type = "powersave", save = "charisma" },
			{ type = "effect", sName = "Unbreakable Majesty", sTargeting = "self", nDuration = 1, sUnits = "minute", },
			{ type = "effect", sName = "Unbreakable Majesty ; DISSAV", sApply = "action" },
		},
		prepared = 1,
		usesperiod = "enc",
	},
	-- Bard - College of Lore
	["bonusproficiencieslore"] = {
		skill = { choice = 3, },
	},
	["additionalmagicalsecrets"] = {
		spell = { choice = 2, },
	},
	["peerlessskill"] = {},
	-- Bard - College of Spirits
	["guidingwhispers"] = {
		spell = { innate = { "Guidance" }, },
	},
	-- Bard - College of Swords
	["bonusproficienciesloreswords"] = { armorprof = { innate = { "Medium" }, }, weaponprof = { innate = { "Scimitar" }, }, },
	["fightingstyle"] = {
		multiple_actions = {
			["Fighting Style (Protection)"] = { actions = { { type = "effect", sName = "Fighting Style (Protection); DISATK", sApply = "roll" }, }, },
			["Fighting Style (Archery)"] = { actions = { { type = "effect", sName = "Fighting Style (Archery); ATK: 2,ranged", sTargeting = "self", }, }, },
			["Fighting Style (Dueling)"] = { actions = { { type = "effect", sName = "Fighting Style (Dueling); DMG: 2, melee", sTargeting = "self", }, }, },
		},
	},
	["bladeflourish"] = {
		multiple_actions = {
			["Blade Flourish (Defensive)"] = {
				actions = {
					{ type = "effect", sName = "Blade Flourish (Defensive Flourish); DMG: 1", sTargeting = "self", sApply = "roll" },
					{ type = "effect", sName = "Blade Flourish (Defensive Flourish); AC: 1", sTargeting = "self", nDuration = 1, },
				},
			},
			["Blade Flourish (Slashing)"] = { actions = { { type = "effect", sName = "Blade Flourish (Slashing Flourish); DMG: 1", sTargeting = "self", sApply = "roll" }, }, },
			["Blade Flourish (Mobile)"] = { actions = { { type = "effect", sName = "Blade Flourish (Mobile Flourish); DMG: 1", sTargeting = "self", sApply = "roll" }, }, },
		},
	},
	-- Bard - College of Valor
	["bonusproficienciesvalor"] = { armorprof = { innate = { "Medium", "Shields" }, }, weaponprof = { innate = { "Martial" }, }, },
	["combatinspiration"] = { actions = { { type = "effect", sName = "Combat Inspiration; (d6) used for ability check, attack roll, saving throw, weapon damage, or AC", nDuration = 10, sUnits = "minute" }, }, },
	-- Bard - College of Whispers
	["psychicblades"] = { actions = { { type = "effect", sName = "Psychic Blades; DMG: 2d6 psychic", sTargeting = "self", sApply = "roll" }, }, },
	["wordsofterror"] = {
		actions = {
			{ type = "powersave", save = "wisdom", },
			{ type = "effect", sName = "Frightened", nDuration = 1, sUnits = "hour", },
		},
	},
	["mantleofwhispers"] = {
		actions = {
			{ type = "effect", sName = "Mantle of Whispers; SKILL: 5 deception", sTargeting = "self", nDuration = 1, sUnits = "hour", },
		},
		prepared = 1,
		usesperiod = "enc",
	},
	["shadowlore"] = {
		actions = {
			{ type = "powersave", save = "wisdom" },
			{ type = "effect", sName = "Shadow Lore; Charmed", nDuration = 8, sUnits = "hour", },
		},
		prepared = 1,
	},
	-- Cleric
	["channeldivinity"] = {
		multiple_actions = {
			["Channel Divinity (Turn Undead)"] = {
				actions = {
					{ type = "powersave", save = "wisdom", },
					{ type = "effect", sName = "Channel Divinity (Turn Undead); Frightened; Incapacitated", nDuration = 1, sUnits = "minute", },
				},
				prepared = 1,
			},
		},
	},
	["channeldivinityarcaneabjuration"] = { actions = { { type = "effect", sName = "Channel Divinity (Arcane Abjuration); Banished", nDuration = 1, sUnits = "minute", }, }, prepared = 1, },
	["channeldivinitydestructivewrath"] = { actions = {}, prepared = 1 },
	["channeldivinitytouchofdeath"] = {
		actions = {
			{ type = "damage", clauses = { { dice = { }, modifier = 5, dmgtype = "necrotic", stat = "cleric" }, }, },
			{ type = "effect", sName = "Channel Divinity (Touch of Death); DMG: 5 [2LVL] necrotic", sTargeting = "self", sApply = "action", },
		},
		prepared = 1,
	},
	["channeldivinitypathtothegrave"] = { actions = { { type = "effect", sName = "Channel Divinity (Path to the Grave); VULN: all", sApply = "action" }, }, },
	["channeldivinityknowledgeoftheages"] = { actions = { { type = "effect", sName = "Channel Divinity (Knowledge of the Ages); SKILL: [PRF]", sTargeting = "self", nDuration = 10, sUnits = "minute" }, }, prepared = 1, },
	["channeldivinityreadthoughts"] = {
		actions = {
			{ type = "powersave", save = "wisdom", },
			{ type = "effect", sName = "Channel Divinity (Read Thoughts)", nDuration = 1, sUnits = "minute" },
		},
		prepared = 1,
	},
	["channeldivinitypreservelife"] = { actions = { { type = "heal", clauses = { { dice = { }, stat = "cleric" }, }, }, }, prepared = 1 },
	["channeldivinityradianceofthedawn"] = {
		actions = {
			{ type = "powersave", save = "constitution", onmissdamage = "half" },
			{ type = "damage", clauses = { { dice = { "d10", "d10" }, dmgtype = "radiant", stat = "cleric" }, }, },
		},
		prepared = 1,
	},
	["channeldivinitycharmanimalsandplants"] = {
		actions = {
			{ type = "effect", sName = "Channel Divinity (Charm Animals And Plants); Charmed", },
			{ type = "powersave", save = "wisdom", },
		},
		prepared = 1,
	},
	["channeldivinitybalmofpeace"] = { actions = { { type = "heal", clauses = { { dice = { "d6", "d6" }, stat = "wisdom" }, }, }, }, },
	["channeldivinityinvokeduplicity"] = {
		actions = {
			{ type = "effect", sName = "Channel Divinity (Invoke Duplicity)", sTargeting = "self", nDuration = 1, sUnits = "minute" },
			{ type = "effect", sName = "Channel Divinity (Invoke Duplicity); ADVATK", sApply = "roll" },
		},
		prepared = 1,
	},
	["channeldivinitycloakofshadows"] = { actions = { { type = "effect", sName = "Channel Divinity (Cloak of Shadows); Invisible", sTargeting = "self", nDuration = 1, }, }, prepared = 1, },
	["channeldivinitytwilightsanctuary"] = {
		actions = {
			{ type = "heal", subtype = "temp", clauses = { { dice = { "d6" }, stat = "cleric" }, }, },
			{ type = "effect", sName = "Channel Divinity (Twilight Sanctuary); Charmed", },
			{ type = "effect", sName = "Channel Divinity (Twilight Sanctuary); Frightened", },
		},
	},
	["channeldivinityguidedstrike"] = { actions = { { type = "effect", sName = "Channel Divinity (Guided Strike); ATK: 10", sTargeting = "self", sApply = "roll" }, }, prepared = 1, },
	["channeldivinitywargodsblessing"] = { actions = { { type = "effect", sName = "Channel Divinity (War God's Blessing); ATK: 10", sApply = "roll" }, }, prepared = 1, },
	["channeldivinitycontrolundead"] = {
		actions = {
			{ type = "powersave", save = "wisdom", },
			{ type = "effect", sName = "Channel Divinity (Control Undead)", nDuration = 24, sUnits = "hour", },
		},
	},
	["channeldivinitydreadfulaspect"] = {
		actions = {
			{ type = "powersave", save = "wisdom", },
			{ type = "effect", sName = "Channel Divinity (Dreadful Aspect); Frightened", nDuration = 1, sUnits = "minute", },
		},
	},
	["channeldivinitytouchofdeath"] = { actions = { { type = "effect", sName = "Channel Divinity (Touch of Death); DMG: 5 [2LVL] necrotic", sTargeting = "self", sApply = "action", }, }, },
	["channeldivinityabjureenemy"] = {
		actions = {
			{ type = "effect", sName = "Channel Divinity (Abjure Enemy); IF: TYPE (fiend,undead); DISSAV: wisdom", nDuration = 1, sApply = "roll", },
			{ type = "powersave", save = "wisdom", },
			{ type = "effect", sName = "Channel Divinity (Abjure Enemy); Frightened", nDuration = 1, },
			{ type = "effect", sName = "Channel Divinity (Abjure Enemy); Speed halved", nDuration = 1, },
		},
	},
	["channeldivinitynatureswrath"] = {
		actions = {
			{ type = "effect", sName = "Channel Divinity (Nature's Wrath); Restrained", },
			{ type = "powersave", save = "dexterity", },
			{ type = "powersave", save = "strength", },
		},
	},
	["channeldivinitysacredweapon"] = { actions = { { type = "effect", sName = "Channel Divinity (Sacred Weapon); ATK: [CHA]; DMGTYPE: magic", sTargeting = "self", nDuration = 1, sUnits = "minute", }, }, },
	["channeldivinityturnofthefaithless"] = {
		actions = {
			{ type = "powersave", save = "wisdom", },
			{ type = "effect", sName = "Channel Divinity (Turn the Faithless); Frightened; Incapacitated", nDuration = 1, sUnits = "minute", },
		},
	},
	["channeldivinityturnoftheunholy"] = {
		actions = {
			{ type = "powersave", save = "wisdom", },
			{ type = "effect", sName = "Channel Divinity (Turn the Unholy); Frightened; Incapacitated", nDuration = 1, sUnits = "minute", },
		},
	},
	["channeldivinityturnthetide"] = { actions = { { type = "heal", clauses = { { dice = { "d6" }, stat = "charisma" }, }, }, }, },
	["channeldivinityvowofenmity"] = { actions = { { type = "effect", sName = "Channel Divinity (Vow of Enmity); ADVATK", sTargeting = "self", nDuration = 1, sUnits = "minute", }, }, },
	["channeldivinityordersdemand"] = { actions = { { type = "powersave", save = "wisdom", }, { type = "effect", sName = "Order's Demand; Charmed", }, }, },
	["channeldivinitypathofthegrave"] = { actions = { { type = "effect", sName = "Channel Divinity (Path to the Grave); VULN: ; ADVATK", nDuration = 1, }, }, },
	["channeldivinityconqueringpresence"] = {
		actions = {
			{ type = "powersave", save = "widsom", },
			{ type = "effect", sName = "Channel Divinity (Conquering Presense); Frightened", nDuration = 1, sUnits = "minute" },
		},
	},
	["channeldivinityemissaryofpeace"] = { actions = { { type = "effect", sName = "Channel Divinity (Emissary of Peace); SKILL: 5 persuasion", sTargeting = "self", nDuration = 10, sUnits = "minute" }, }, },
	["channeldivinityrebuketheviolent"] = { actions = { { type = "powersave", save = "wisdom", onmissdamage = "half" }; }, },
	["divineintervention"] = { actions = {}, prepared = 1 },

	-- Cleric - Arcana Domain
	["domainspellsarcana"] = {
		spell = {
			level = {
				[1] = { "Detect Magic" , "Magic Missile" },
				[3] = { "Magic Weapon", "Nystul's Magic Aura" },
				[5] = { "Dispel Magic", "Magic Circle" },
				[7] = { "Arcane Eye", "Leomund's Secret Chest" },
				[9] = { "Planar Binding", "Teleportation Circle" },
			},
		},
	},
	["arcanainitiate"] = {
		skill = { innate = { "Arcana", }, },
		spell = { choice = 2, spelllist = { "Wizard", }, },
	},
	["arcanemastery"] = {
		spell = { choice = 4, spelllist = { "Wizard", }, },
	},
	-- Cleric - Death Domain
	["domainspellsdeathdomain"] = {
		spell = {
			level = {
				[1] = { "False Life", "Ray of Sickness" },
				[3] = { "Blindness/Deafness", "Ray of Enfeeblement" },
				[5] = { "Animate Dead", "Vampiric Touch" },
				[7] = { "Blight", "Death Ward" },
				[9] = { "Antilife Shell", "Cloudkill" },
			},
		},
	},
	["bonusproficienciesdeath"] = { weaponprof = { innate = { "Martial" }, }, },
	--["reaper"] = { spell = { choice = 1, spellschool = { "Necromancy" }, spelllevel = { 0 }, }, },
	["inescapabledestruction"] = { actions = { { type = "effect", sName = "Inescapable Destruction; Channel Divinity and spells ignore necrotic resistance", sTargeting = "self", }, }, },
	["divinestrikedeath"] = { actions = { { type = "effect", name = "Divine Strike (Death); DMG: 1d8 necrotic", sTargeting = "self", sApply = "roll" }, }, },
	-- Cleric - Forge Domain
	["domainspellsforge"] = {
		spell = {
			level = {
				[1] = { "Identify", "Searing Smite" },
				[3] = { "Heat Metal", "Magic Weapon" },
				[5] = { "Elemental Weapon", "Protection from Enegery" },
				[7] = { "Fabricate", "Wall of Fire" },
				[9] = { "Animate Objects", "Creation" },
			},
		},
	},
	["bonusproficienciesforgedomain"] = {
		armorprof = { innate = { "Heavy" }, },
		toolprof = { innate = { "Smith's Tools" }, },
	},
	["blessingoftheforge"] = {
		actions = {
			{ type = "effect", sName = "Blessing of the Forge (Weapon); ATK: 1; DMG: 1; DMGTYPE: magic", },
			{ type = "effect", sName = "Blessing of the Forge (Armor); AC: 1", },
		},
		prepared = 1,
	},
	["souloftheforge"] = { actions = { { type = "effect", sName = "Soul of the Forge; RESIST: fire; AC:1", sTargeting = "self", }, }, },
	["divinestrikeforge"] = { actions = { { type = "effect", sName = "DMG: 1d8 fire", sTargeting = "self", sApply = "roll" }, }, },
	["saintofforgeandfire"] = { actions = { { type = "effect", sName = "Saint of Forge; IMMUNE: fire; RESIST: bludgeoning, piercing, slashing, !magic", sTargeting = "self", }, }, },
	-- Cleric - Grave Domain
	["domainspellsgravedomain"] = {
		spell = {
			level = {
				[1] = { "Bane", "False Life" },
				[3] = { "Gentle Repose", "Ray of Enfeeblement" },
				[5] = { "Revivify", "Vampiric Touch" },
				[7] = { "Blight", "Death Ward" },
				[9] = { "Antilife Shell", "Raise Dead" },
			},
		},
	},
	["eyesofthegrave"] = { actions = {}, prepared = 1, },
	["sentinelatdeathsdoor"] = { actions = {}, prepared = 1, },
	["potentspellcasting"] = { actions = { { type = "effect", sName = "Potent Spellcasting; DMG: [WIS]", sTargeting = "self", sApply = "roll" }, }, },
	["keeperofsouls"] = { actions = { { type = "heal", clauses = { { dice = {}, bonus = 1, }, }, }, }, },
	-- Cleric - Knowledge Domain
	["knowledgedomainspells"] = {
		spell = {
			level = {
				[1] = { "Command", "Identify" },
				[3] = { "Augury", "Suggestion" },
				[5] = { "Nondetection", "Speak with Dead" },
				[7] = { "Arcane Eye", "Confusion" },
				[9] = { "Legend Lore", "Scrying" },
			},
		},
	},
	["visionsofthepast"] = { actions = { { type = "effect", sName = "Visions of the Past", sTargeting = "self", nDuration = 1, sUnits = "minute", }, }, prepared = 1, usesperiod = "enc" },
	["blessingsofknowledge"] = {
		language = { choice = 2, }, 
		skill = { choice = 2, choice_skill = { "Arcana", "History", "Nature", "Religion" }, prof = "double", }, 
	},
	-- Cleric - Life Domain
	["domainspellslife"] = {
		spell = {
			level = {
				[1] = { "Bless", "Cure Wounds" },
				[3] = { "Lesser Restoration", "Spiritual Weapon" },
				[5] = { "Beacon of Hope", "Revivify" },
				[7] = { "Death Ward", "Guardian of Faith" },
				[9] = { "Mass Cure Wounds", "Raise Dead" },
			},
		},
	},
	["bonusproficiencieslife"] = { armorprof = { innate = { "Heavy" }, }, },
	["discipleoflife"] = { actions = { { type = "heal", clauses = { { dice = { }, bonus = 3, }, }, }, }, },
	["blessedhealer"] = { actions = { { type = "heal", sTargeting = "self", clauses = { { dice = { }, bonus = 2, }, }, }, }, },
	["divinestrikelife"] = { actions = { { type = "effect", sName = "Divine Strike (Life); DMG: 1d8 radiant", sTargeting = "self", sApply = "roll" }, }, },
	["supremeheal"] = { actions = { { type = "heal", clauses = { { dice = { }, bonus = 8, }, }, }, }, },
	-- Cleric - Light Domain
	["domainspellslight"] = {
		spell = {
			level = {
				[1] = { "Burning Hands", "Faerie Fire" },
				[3] = { "Flaming Sphere", "Scorching Ray" },
				[5] = { "Daylight", "Fireball" },
				[7] = { "Guardian of Faith", "Wall of Fire" },
				[9] = { "Flame Strike", "Scrying" },
			},
		},
	},
	["bonuscantriplightdomain"] = {
		spell = { innate = { "Light" }, },
	},
	["wardingflare"] = { actions = { { type = "effect", sName = "Warding Flare; DISATK", sApply = "roll" }, }, prepared = 1 },
	["coronaoflight"] = {
		actions = {
			{ type = "effect", sName = "Corona of Light", nDuration = 1, sUnits = "minute", },
			{ type = "effect", sName = "Corona of Light; DISSAV: dexterity", },
		},
	},
	-- Cleric - Nature Domain
	["domainspellsnature"] = {
		spell = {
			level = {
				[1] = { "Animal Friendship", "Speak with Animals" },
				[3] = { "Barkskin", "Spike Growth" },
				[5] = { "Plant Growth", "Wind Wall" },
				[7] = { "Dominate Beast", "Grasping Vine" },
				[9] = { "Insect Plague", "Tree Stride" },
			},
		},
	},
	["acolyteofnature"] = {
		spell = { choice = 1, spelllist = { "Druid", }, spelllevel = 0, },
		skill = { choice = 1, choice_skill = { "Animal Handling", "Nature", "Survival", }, },
	},
	["bonusproficienciesnature"] = { armorprof = { innate = { "Heavy" }, }, },
	["dampenelements"] = { actions = { { type = "effect", sName = "Dampen Elements; RESIST: acid,cold,fire,lightning,thunder", sApply = "action" }, }, },
	["divinestrikenature"] = { actions = { { type = "effect", sName = "DMG: 1d8 cold, fire, or lightning", sTargeting = "self", sApply = "roll" }, }, },
	-- Cleric - Order Domain
	["domainspellsorder"] = {
		spell = {
			level = {
				[1] = { "Command", "Heroism" },
				[3] = { "Hold Person", "Zone of Truth" },
				[5] = { "Mass Healing Ward", "Slow" },
				[7] = { "Compulsion", "Locate Creature" },
				[9] = { "Commune", "Dominate Person" },
			},
		},
	},
	["bonusproficienciesorder"] = {
		armorprof = { innate = { "Heavy" }, },
		skill = { choice = 1, choice_skill = { "Intimidation", "Persuasion", }, },
	},
	["embodimentofthelaw"] = { actions = {}, prepared = 1 },
	["orderswrath"] = {
		actions = {
			{ type = "damage", clauses = { { dice = { "d8", "d8" }, dmgtype = "psychic", }, }, },
			{ type = "effect", sName = "Order's Wrath (Cursed)", nDuration = 1, },
		},
	},
	["divinestrikeorder"] = { actions = { { type = "effect", sName = "Divine Strike (Order); DMG: 1d8 psychic", sTargeting = "self", }, }, },
	-- Cleric - Peace Domain
	["domainspellspeace"] = {
		spell = {
			level = {
				[1] = { "Heroism", "Sanctuary" },
				[3] = { "Aid", "Warding Bond" },
				[5] = { "Beacon of Hope", "Sending" },
				[7] = { "Aura of Purity", "Otiluke's Resilient Sphere" },
				[9] = { "Restoration", "Rary's Telepathic Bond" },
			},
		},
	},
	["implementofpeace"] = {
		skill = { choice = 1, choice_skill = { "Insight", "Performance", "Persuasion" }, },
	},
	-- Cleric - Tempest Domain
	["domainspellstempest"] = {
		spell = {
			level = {
				[1] = { "Fog Cloud", "Thunderwave" },
				[3] = { "Gust of Wind", "Shatter" },
				[5] = { "Call Lightning", "Sleet Storm" },
				[7] = { "Control Water", "Ice Storm" },
				[9] = { "Destructive Wave", "Insect Plague" },
			},
		},
	},
	["bonusproficienciestempest"] = { armorprof = { innate = { "Heavy" }, }, weaponprof = { innate = { "Martial" }, }, },
	["stormborn"] = { actions = { { type = "effect", sName = "Stormborn; Fly walking speed", sTargeting = "self", }, }, },
	["wrathofthestorm"] = {
		actions = {
			{ type = "powersave", save = "dexterity", onmissdamage = "half" },
			{ type = "damage", clauses = { { dice = { "d8", "d8" }, dmgtype = "lightning", }, }, },
			{ type = "damage", clauses = { { dice = { "d8", "d8" }, dmgtype = "thunder", }, }, },
		},
		prepared = 1,
	},
	["divinestriketempest"] = { actions = { { type = "effect", sName = "DMG: 1d8 thunder", sTargeting = "self", }, }, },
	-- Cleric - Trickery Domain
	["domainspellstrickery"] = {
		spell = {
			level = {
				[1] = { "Charm Person", "Disguise Self" },
				[3] = { "Mirror Image", "Pass without Trace" },
				[5] = { "Blink", "Dispel Magic" },
				[7] = { "Dimension Door", "Polymorph" },
				[9] = { "Dominate Person", "Modify Memory" },
			},
		},
	},
	["blessingofthetrickster"] = { actions = { { type = "effect", sName = "Blessing of the Trickster; ADVSKILL: stealth", nDuration = 1, sUnits = "hour", }, }, },
	["divinestriketrickery"] = { actions = { { type = "effect", sName = "DMG: 1d8 poison", sTargeting = "self", }, }, },
	-- Cleric - Twilight Domain
	["domainspellstwilight"] = {
		spell = {
			level = {
				[1] = { "Faerie Fire", "Sleep" },
				[3] = { "Moonbeam", "See Invisibility" },
				[5] = { "Aura of Vitality", "Leomund's Tiny Hut" },
				[7] = { "Aura of Life", "Greater Invisibility" },
				[9] = { "Circle of Power", "Mislead" },
			},
		},
	},
	["bonusproficienciestwilight"] = {
		armorprof = { innate = { "Heavy" }, },
		weaponprof = { innate = { "Martial" }, },
	},
	["vigilantblessing"] = { actions = { { type = "effect", sName = "Vigilant Blessing;ADVINIT", sApply = "roll" }, }, },
	["divinestriketwilight"] = { actions = { { type = "effect", sName = "DMG: 1d8 radiant", sTargeting = "self", sApply = "roll" }, }, },
	-- Cleric - War Domain
	["domainspellswar"] = {
		spell = {
			level = {
				[1] = { "Divine Favor", "Shield of Faith" },
				[3] = { "Magic Weapon", "Spiritual Weapon" },
				[5] = { "Crusader's Mantle", "Spirit Guardians" },
				[7] = { "Freedom of Movement", "Stoneskin" },
				[9] = { "Flame Strike", "Hold Monster" },
			},
		},
	},
	["warpriest"] = { actions = {}, prepared = 1 },
	["bonusproficiencieswardomain"] = { armorprof = { innate = { "Heavy" }, }, weaponprof = { innate = { "Martial" }, }, },
	["divinestrikewar"] = { actions = { { type = "effect", sName = "DMG: 1d8", sTargeting = "self", sApply = "roll" }, }, },
	["avatarofbattle"] = { actions = { { type = "effect", sName = "Avatar of Battle; RESIST: bludgeoning,piercing,slashing,!magic", sTargeting = "self", }, }, },
	-- Druid
	["druidic"] = { language = { innate = { "Druidic" }, }, },
	["wildshape"] = { actions = {}, prepared = 2, usesperiod = "enc", },
	-- Druid - Circle of Dreams
	["balmofthesummercourt"] = {
		actions = {
			{ type = "heal", clauses = { { dice = { "d6", }, }, }, },
			{ type = "heal", subtype = "temp", clauses = { { dice = { }, bonus = 1, }, }, },
		},
		prepared = 1,
	},
	["hearthofmoonlightandshadow"] = { actions = { { type = "effect", sName = "Hearth of Moonlight and Shadow; SKILL: 5 perception,stealth", }, }, },
	["hiddenpaths"] = { actions = {}, prepared = 1, },
	["walkerindreams"] = {
		actions = {},
		prepared = 1,
		spell = { innate = { "Scrying", "Teleportaion Circle" }, },
	},
	-- Druid - Circle of Spores
	["circlespellsspores"] = {
		spell = {
			level = {
				[2] = { "Chill Touch" },
				[3] = { "Blindness/Deafness", "Gentle Repose" },
				[5] = { "Animate Dead", "Gaseous Form" },
				[7] = { "Blight", "Confusion" },
				[9] = { "Cloudkill", "Contagion" },
			},
		},
	},
	["fungalinfestation"] = { actions = {}, prepared = 1 },
	["haloofspores"] = {
		actions = {
			{ type = "powersave", save = "constitution", savestat = "spell", },
			{ type = "damage", clauses = { { dice = { "d4" }, dmgtype = "necrotic", }, }, },
		},
	},
	["symbioticentity"] = {
		actions = {
			{ type = "heal", subtype = "temp", sTargeting = "self", clauses = { { dice = { }, bonus = 4 }, }, },
			{ type = "effect", sName = "Symbiotic Entity; DMG: 1d6 necrotic", sTargeting = "self", nDuration = 10, sUnits = "minute", },
		},
	},
	["spreadingspores"] = { actions = { { type = "powersave", save = "constitution", savestat = "spell", }, }, },
	["fungalbody"] = { actions = { { type = "effect", sName = "Fungal Body; IMMUNE: blinded; IMMUNE: deafened; IMMUNE: frightened; IMMUNE: poisoned; IMMUNE: critical", sTargeting = "self", }, }, },
	-- Druid - Circle of Stars
	["starmap"] = {
		spell = { innate = { "Guidance", "Guiding Bolt" }, },
	},
	["starryform"] = {
		multiple_actions = {
			["Starry Form (Archer)"] = {
				actions = {
					{ type = "attack", range = "R", },
					{ type = "damage", clauses = { { dice = { "d8" }, dmgtype = "radiant", stat = "wisdom" }, }, },
				},
			},
			["Starry Form (Chalice)"] = { actions = { { type = "heal", sTargeting = "self", clauses = { { dice = { "d8" }, stat = "wisdom" }, }, }, }, },
		},
	},
	["cosmicomen"] = {
		multiple_actions = {
			["Cosmic Omen (Weal (even))"] = { actions = {}, },
			["Cosmic Omen (Woe (odd))"] = { actions = {}, },
		},
	},
	["fullofstars"] = { actions = { { type = "effect", sName = "RESIST: bludgeoning, piercing, slashing", sTargeting = "self", }, }, },
	-- Druid - Circle of the Land
	["bonuscantripland"] = {
		spell = { choice = 1, spelllist = "Druid", spelllevel = 0, },
	},
	["landsstride"] = { actions = { { type = "effect", sName = "Land's Stride; IFT: TYPE(plant); ADVSAV:all", sTargeting = "self", sApply = "action" }, }, },
	["naturalrecovery"] = { actions = {}, prepared = 1 },
	["naturesward"] = {
		actions = {
			{ type = "effect", sName = "Nature's Ward; IMMUNE: poison; IMMUNE: poisoned; IFT:TYPE(elemental,fey); IMMUNE: charmed; IMMUNE: frightened", sTargeting = "self", },
			{ type = "effect", sName = "Nature's Ward; IMMUNE: disease", sTargeting = "self", },
		},
	},
	["naturessanctuary"] = { actions = { { type = "powersave", save = "wisdom", }, }, },
	-- Druid - Circle of the Moon
	["combatwildshape"] = { actions = { { type = "heal", sTargeting = "self", clauses = { { dice = { "d8" }, }, }, }, }, usesperiod = "enc", },
	["primalstrike"] = { actions = { { type = "effect", sName = "Primal Strike; DMGTYPE: magic", sTargeting = "self", }, }, },
	-- Druid - Circle of the Shepherd
	["spirittotem"] = {
		actions = {
			{ type = "heal", subtype = "temp", clauses = { { dice = { }, bonus = 5, stat = "druid" }, }, },
			{ type = "heal", clauses = { { dice = { }, stat = "druid" }, }, },
			{ type = "effect", sName = "Spirit Totem (Bear); ADVCHK: strength; ADVSAV: strength", nDuration = 1, sUnits = "minute", },
			{ type = "effect", sName = "Spirit Totem (Hawk); ADVSKILL: perception", nDuration = 1, sUnits = "minute", },
			{ type = "effect", sName = "Spirit Totem (Hawk); ADVATK", sApply = "roll" },
			{ type = "effect", sName = "Spirit Totem (Unicorn); ADVCHK", sApply = "action", },
		},
		prepared = 1,
		usesperiod = "enc"
	},
	["mightysummoner"] = { actions = { { type = "effect", sName = "Mighty Summoner; DMGTYPE: magic", sTargeting = "self" }, }, },
	["guardianspirit"] = { actions = { { type = "heal", clauses = { { dice = { }, stat = "druid" }, }, }, }, },
	["faithfulsummons"] = {
		spell = { innate = { "Conjure Animals" }, },
		actions = { { type = "effect", sName = "Faithful Summons", sTargeting = "self", nDuration = 1, sUnits = "hour" }, },
		prepared = 1,
	},
	-- Druid - Circle of Wildfire
	-- Fighter
	["secondwind"] = { actions = { { type = "heal", sTargeting = "self", clauses = { { dice = { "d10" }, stat = "fighter" }, }, }, }, prepared = 1, usesperiod = "enc", },
	["actionsurge"] = { actions = {}, prepared = 1, usesperiod = "enc", },
	["indomitable"] = { actions = {}, prepared = 1, },
	-- Fighter - Arcane Archer
	["arcanearcherlore"] = {
		skill = { choice = 1, choice_skill = { "Arcana", "Nature", }, },
		spell = { choice = 1, choice_spell = { "Prestidigitation", "Druidcraft", }, },
	},
	["arcaneshot"] = {
		multiple_actions = {
			["Arcane Shot (Banishing Arrow)"] = {
				actions = {
					{ type = "powersave", save = "charisma", },
					{ type = "effect", sName = "Arcane Shot (Banishing Arrow); Incapacitated", nDuration = 1, },
				},
			},
			["Arcane Shot (Beguiling Arrow)"] = {
				actions = {
					{ type = "effect", sName = "Arcane Shot (Beguiling Arrow); DMG: 2d6, psychic", sTargeting = "self", sApply = "roll" },
					{ type = "powersave", save = "wisdom", },
					{ type = "effect", sName = "Arcane Shot (Beguiling Arrow); Charmed", nDuration = 1 },
				},
			},
			["Arcane Shot (Bursting Arrow)"] = { actions = { { type = "damage", clauses = { { dice = { "d6", "d6" }, dmgtype = "force", }, }, }, }, },
			["Arcane Shot (Enfeebling Arrow)"] = {
				actions = {
					{ type = "effect", sName = "Arcane Shot (Enfeebling Arrow); DMG: 2d6, necrotic", sTargeting = "self", sApply = "roll" },
					{ type = "powersave", save = "constitution", },
					{ type = "effect", sName = "Arcane Shot (Enfeebling Arrow); Damage Halved", },
				},
			},
			["Arcane Shot (Grasping Arrow)"] = {
				actions = {
					{ type = "effect", sName = "Arcane Shot (Grasping Arrow); DMG: 2d6, poison", sTargeting = "self", sApply = "roll" },
					{ type = "damage", clauses = { { dice = { "d6", "d6" }, dmgtype = "slashing", }, }, },
					{ type = "effect", sName = "Arcane Shot (Grasping Arrow); Takes damage on move", nDuration = 1, sUnits = "minute", },
				},
			},
			["Arcane Shot (Piercing Arrow)"] = {
				actions = {
					{ type = "powersave", save = "dexterity", onmissdamage = "half" },
					{ type = "effect", sName = "Arcane Shot (Piercing Arrow); DMG: 1d6, piercing", sTargeting = "self", sApply = "roll" },
				},
			},
			["Arcane Shot (Seeking Arrow)"] = {
				actions = {
					{ type = "powersave", save = "dexterity", onmissdamage = "half" },
					{ type = "effect", sName = "Arcane Shot (Seeking Arrow); DMG: 1d6, force", sTargeting = "self", sApply = "roll" },
				},
			},
			["Arcane Shot (Shadow Arrow)"] = {
				actions = {
					{ type = "effect", sName = "Arcane Shot (Shadow Arrow); DMG: 2d6, psychic", sTargeting = "self", sApply = "roll" },
					{ type = "powersave", save = "wisdom", },
					{ type = "effect", sName = "Arcane Shot (Shadow Arrow); Can't see beyond 5'", nDuration = 1, },
				},
			},
		},
	},
	["magicarrow"] = { actions = { { type = "effect", sName = "Magic Arrow; DMGTYPE: magic", sTargeting = "self", sApply = "roll" }, }, },
	-- Fighter - Battle Master
	["combatsuperiority"] = {
		multiple_actions = {
			["Combat Superiority (Superiority Dice)"] = { actions = {}, prepared = 4 },
			["Combat Superiority (Commander's Strike)"] = { actions = { { type = "effect", sName = "Commander's Strike; DMG: 1d8", sApply = "roll" }, }, },
			["Combat Superiority (Disarming Strike)"] = {
				actions = {
					{ type = "effect", sName = "Disarming Strike; DMG: 1d8", sTargeting = "self", sApply = "action" },
					{ type = "powersave", save = "strength", },
					{ type = "effect", sName = "Disarming Strike; Disarmed", nDuration = 1, },
				},
			},
			["Combat Superiority (Distracting Strike)"] = {
				actions = {
					{ type = "effect", sName = "Distracting Strike; DMG: 1d8", sApply = "action" },
					{ type = "effect", sName = "Distracting Strike; GRANTADVATK", nDuration = 1, sApply = "action" },
				},
			},
			["Combat Superiority (Evasive Footwork)"] = { actions = { { type = "effect", sName = "Evasive Footwork; AC: #", sTargeting = "self" }, }, },
			["Combat Superiority (Feinting Attack)"] = {
				actions = {
					{ type = "effect", sName = "Feinting Attack; DMG: 1d8", sTargeting = "self", sApply = "roll" },
					{ type = "effect", sName = "Feinting Attack; ADVATK", sTargeting = "self", nDuration = 1, sApply = "action" },
				},
			},
			["Combat Superiority (Goading Attack)"] = {
				actions = {
					{ type = "effect", sName = "Goading Attack; DMG: 1d8", sTargeting = "self", sApply = "action" },
					{ type = "effect", sName = "Goading Attack; GRANTADVATK", sTargeting = "self", sApply = "action" },
					{ type = "powersave", save = "wisdom", },
					{ type = "effect", sName = "Goaded; DISATK", nDuration = 1 },
				},
			},
			["Combat Superiority (Lunging Attack)"] = { actions = { { type = "effect", sName = "Lunging Attack; DMG: 1d8", sTargeting = "self", sApply = "action" }, }, },
			["Combat Superiority (Maneuvering Attack)"] = { actions = { { type = "effect", sName = "Maneuvering Attack; DMG: 1d8", sTargeting = "self", sApply = "action" }, }, },
			["Combat Superiority (Menacing Attack)"] = {
				actions = {
					{ type = "powersave", save = "wisdom", },
					{ type = "effect", sName = "Menacing Attack; Frightened", nDuration = 1 },
					{ type = "effect", sName = "Menacing Attack; DMG: 1d8", sTargeting = "self", sApply = "action" },
				},
			},
			["Combat Superiority (Parry)"] = { actions = { { type = "heal", sTargeting = "self", clauses = { { dice = { "d8" }, stat = "dexterity" }, }, }, }, },
			["Combat Superiority (Precision Attack)"] = { actions = { { type = "effect", sName = "Precision Attack; ATK: 1d8", sTargeting = "self", sApply = "action" }, }, },
			["Combat Superiority (Pushing Attack)"] = {
				actions = {
					{ type = "powersave", save = "strength", },
					{ type = "effect", sName = "Pushing Attack; DMG: 1d8", sTargeting = "self", sApply = "action" },
				},
			},
			["Combat Superiority (Rally)"] = { actions = { { type = "heal", subtype = "temp", clauses = { { dice = { "d8" }, stat = "charisma" }, }, }, }, },
			["Combat Superiority (Riposte)"] = { actions = { { type = "effect", sName = "Riposte; DMG: 1d8", sTargeting = "self", nDuration = 1, sApply = "action" }, }, },
			["Combat Superiority (Sweeping Attack)"] = {
				actions = {
					{ type = "damage", clauses = { { dice = { "d8" }, dmgtype = "slashing", }, }, },
					{ type = "damage", clauses = { { dice = { "d8" }, dmgtype = "piercing", }, }, },
					{ type = "damage", clauses = { { dice = { "d8" }, dmgtype = "bludgeoning", }, }, },
				},
			},
			["Combat Superiority (Trip Attack)"] = {
				actions = {
					{ type = "powersave", save = "strength", },
					{ type = "effect", sName = "Trip Attack; Prone", },
					{ type = "effect", sName = "Trip Attack; DMG:1d8", sTargeting = "self", sApply = "action" },
				},
			},
		},
	},
	["studentofwar"] = {
		toolprof = { choice = 1, choice_prof = { "Artisan's Tools" }, },
	},
	-- Fighter - Cavalier
	["bonusproficiencycavalier"] = {
		["multiple_choice"] = {
			skill = { choice = 1, choice_skill = { "Animal Handling", "History", "Insight", "Performance", "Persuasion", }, },
			language = { choice = 1, },
		},
	},
	["borntothesaddle"] = { actions = { { type = "effect", sName = "Born to the Saddle; ADVSAV", sTargeting = "self", sApply = "action" }, }, },
	["unwaveringmark"] = {
		actions = {
			{ type = "effect", sName = "Unwavering Mark", nDuration = 1, },
			{ type = "effect", sName = "Unwavering Mark; DISATK", sApply = "roll", },
			{ type = "damage", clauses = { { dice = {}, dmgtype = "", stat = "fighter" }, }, },
		},
		prepared = 1,
	},
	["wardingmaneuver"] = {
		actions = {
			{ type = "effect", sName = "Warding Maneuver; AC: 1", sApply = "action" },
			{ type = "effect", sName = "Warding Maneuver; RESIST: all", sApply = "action" },
		},
		prepared = 1,
	},
	["holdtheline"] = {
		actions = {
			{ type = "effect", sName = "Hold the Line; Speed zero", },
		},
	},
	["ferociouscharger"] = {
		actions = {
			{ type = "powersave", save = "strength", savestat = "strength", },
			{ type = "effect", sName = "Ferocious Charger; Prone", },
		},
	},
	-- Fighter - Champion
	["remarkableathlete"] = {
		actions = {
			{ type = "effect", sName = "Remarkable Athlete; CHECK: [HPRF] dexterity, strength, constitution", sTargeting = "self", sApply = "action" },
			{ type = "effect", sName = "Remarkable Athlete; INIT: [HPRF]; [STR] ft added to running long jump", sTargeting = "self", },
		},
	},
	["survivor"] = { actions = { { type = "effect", sName = "survivor; IF:Bloodied; REGEN:5 [CON]", sTargeting = "self", }, }, },
	-- Fighter - Echo Knight
	["reclaimpotential"] = { actions = { { type = "heal", subtype = "temp", sTargeting = "self", clauses = { { dice = { "d6", "d6" }, stat = "constitution" }, }, }, }, },
	-- Fighter - Eldritch Knight
	["eldritchstrike"] = { actions = { { type = "effect", sName = "Eldritch Strike; DISSAV: all", nDuration = 1 }, }, },
	-- Fighter - Psi Warrior
	-- Figther - Purple Dragon Knight
	["rallyingcry"] = { actions = { { type = "heal", sTargeting = "self", clauses = { { dice = { }, stat = "fighter" }, }, }, }, },
	["royalenvoy"] = { actions = { { type = "effect", sName = "SKILL:[PRF], persuasion", sTargeting = "self", }, }, },
	-- Fighter - Rune Knight
	["bonusproficienciesruneknight"] = {
		toolprof = { innate = { "Smith's Tools" }, }, 
		language = { innate = { "Giant" }, },
	},
	-- Fighter - Samurai
	["bonusproficiencysamurai"] = {
		skill = { choice = 1, choice_skill = { "History", "Insight", "Performance", "Persuasion", }, },
		language = { choice = 1, },
	},
	["fightingspirit"] = {
		actions = {
			{ type = "heal", subtype = "temp", sTargeting = "self", clauses = { { dice = { }, bonus = 5, }, }, },
			{ type = "effect", sName = "Fighting Spirit; ADVATK", sTargeting = "self", nDuration = 1, },
		},
		prepared = 3
	},
	["strengthbeforedeath"] = { actions = {}, prepared = 1 },
	["elegantcourtier"] = {
		actions = {
			{ type = "effect", sName = "Elegant Courtier; SKILL: [WIS] persuasion", sTargeting = "self", sApply = "action", },
			{ type = "effect", sName = "Elegant Courtier; SAVE: [PRF] wisdom", sTargeting = "self", },
			{ type = "effect", sName = "Elegant Courtier; SAVE: [PRF] intelligence", sTargeting = "self", },
			{ type = "effect", sName = "Elegant Courtier; SAVE: [PRF] charisma", sTargeting = "self", },
		},
	},
	["rapidstrike"] = { actions = { { type = "effect", sName = "ADVATK:", sTargeting = "self", sApply = "action" }, }, },
	-- Monk
	["martialarts"] = {
		actions = {
			{ type = "attack", range = "M", },
			{ type = "damage", clauses = { { dice = { "d4", }, dmgtype = "bludgeoning", stat = "dexterity" }, }, },
		},
	},
	["ki"] = {
		multiple_actions = {
			["Ki Points"] = { actions = {}, prepared = 2, usesperiod = "enc" },
			["Ki (Flurry of Blows)"] = {
				actions = {
					{ type = "powersave", save = "dexterity", },
					{ type = "effect", sName = "Flurry of Blows;Prone", },
					{ type = "powersave", save = "strength", },
				},
			},
			["Ki (Patient Defense)"] = { actions = { { type = "effect", sName = "Patient Defense; Dodge", sTargeting = "self", nDuration = 1, }, }, },
			["Ki (Step of the Wind)"] = { actions = { { type = "effect", sName = "Step of the Wind; Jump doubled", sTargeting = "self", }, }, },
			--[["Radiant Sunbolt"] = {
				actions = {
					{ type = "attack", range = "R" },
					{ type = "damage", clauses = { { dice = { "d4" }, dmgtype = "radiant", stat = "dexterity" }, }, },
				},
			},--]]
		},
		prepared = 1
	},
	["deflectmissiles"] = {
		actions = {
			{ type = "attack", range = "R", },
			{ type = "heal", clauses = { { dice = { "d10" }, stat = "dexterity" }, { dice = {}, stat = "monk" }, } },
		},
	},
	["slowfall"] = { actions = { { type = "heal", sTargeting = "self", clauses = { { dice = { }, stat = "monk" }, }, }, }, },
	["stunningstrike"] = {
		actions = {
			{ type = "powersave", save = "constitution", },
			{ type = "effect", sName = "Stunning Strike; Stunned", nDuration = 1, },
		},
	},
	["evasion"] = { actions = { { type = "effect", sName = "Evasion", sTargeting = "self", }, }, },
	["purityofbody"] = { actions = { { type = "effect", sName = "Purity of Body; Immunity to disease; IMMUNE: poison,poisoned", sTargeting = "self", }, }, },
	["diamondsoul"] = { actions = { { type = "effect", sName = "Diamond Soul; SAVE: [PRF]", sTargeting = "self", }, }, },
	["emptybody"] = { actions = { { type = "effect", sName = "Empty Body; Invisible; RESIST:all,!force", sTargeting = "self", nDuration = 1, sUnits = "minute", }, }, },
	-- Monk - Way of Mercy
	["implementsofmercy"] = {
		skill = { innate = { "Insight", "Medicine", }, },
		toolprof = { innate = { "Herbalism Kit", }, },
	},
	-- Monk - Way of Shadow
	["shadowarts"] = {
		spell = { innate = { "Minor Illusion" }, },
	},
	["shadowstep"] = { actions = { { type = "effect", sName = "Shadow Step; ADVATK: melee", sTargeting = "self", nDuration = 1, sApply = "action" }, }, },
	["cloakofshadows"] = { actions = { { type = "effect", sName = "Cloak of Shadows; Invisible", sTargeting = "self", }, }, },
	-- Monk - Way of the Ascendant
	["draconicdisciple"] = {
		language = { innate = { "Draconic" }, },
	},
	-- Monk - Way of the Astral Self
	-- Monk - Way of the Drunken Master
	["bonusproficienciesdrunkenmaster"] = {
		skill = { innate = { "Performance", }, },
		toolprof = { innate = { "Brewer's Supplies", }, },
	},
	["drunkardsluck"] = {
		actions = {
			{ type = "effect", sName = "ADVATK", sTargeting = "self", sApply = "action" },
			{ type = "effect", sName = "ADVCHK", sTargeting = "self", sApply = "action" },
			{ type = "effect", sName = "ADVSAV", sTargeting = "self", sApply = "action" },
		},
	},
	-- Monk - Way of the Four Elements
	["discipleoftheelements"] = {
		multiple_actions = {
			["Disciple of the Elements (Breath of Winter)"] = {
				actions = {},
			},
			["Disciple of the Elements (Fangs of the Fire Snake)"] = { actions = { { type = "effect", sName = "Fangs of the Fire Snake; DMG: 1d10 fire", sTargeting = "self", sApply = "roll" }, }, },
			["Disciple of the Elements (Fist of Unbroken Air)"] = {
				actions = {
					{ type = "powersave", save = "strength", onmissdamage = "half" },
					{ type = "damage", clauses = { { dice = { "d10", "d10", "d10" }, dmgtype = "bludgeoning", }, }, },
					{ type = "effect", sName = "Fist of Unbroken Air; Prone", },
				},
			},
			["Disciple of the Elements (Water Whip)"] = {
				actions = {
					{ type = "powersave", save = "dexterity", onmissdamage = "half" },
					{ type = "damage", clauses = { { dice = { "d10", "d10", "d10" }, dmgtype = "bludgeoning", }, }, },
					{ type = "effect", sName = "Water Whip; Prone", },
				},
			},
		},
	},
	-- Monk - Way of the Kensei
	["pathofthekensei"] = {
		actions = {
			{ type = "effect", sName = "Path of the Kensei; AC: 2", sTargeting = "self", nDuration = 1, },
			{ type = "effect", sName = "Path of the Kensei; DMG: 1d4, ranged", sTargeting = "self", nDuration = 1 },
		},
		toolprof = { choice = 1, choice_prof = { "Calligrapher's Supplies", "Painter's Supplies" }, },
	},
	["onewiththeblade"] = {
		actions = {
			{ type = "effect", sName = "One with the Blade; DMGTYPE: magic", sTargeting = "self", },
			{ type = "effect", sName = "One with the Blade; DMG: 1d4", sTargeting = "self", sApply = "roll" },
		},
	},
	["sharpentheblade"] = {
		actions = {
			{ type = "effect", sName = "Sharpen the Blade One Point; ATK: 1; DMG: 1", sTargeting = "self", nDuration = 1, sUnits = "minute", },
			{ type = "effect", sName = "Sharpen the Blade Two Points; ATK: 2; DMG: 2", sTargeting = "self", nDuration = 1, sUnits = "minute", },
			{ type = "effect", sName = "Sharpen the Blade Three Points; ATK: 3; DMG: 3", sTargeting = "self", nDuration = 1, sUnits = "minute", },
		},
	},
	-- Monk - Way of the Long Death
	["touchofdeath"] = { actions = { { type = "heal", subtype = "temp", sTargeting = "self", clauses = { { dice = { }, stat = "wisdom" }, { dice = { }, stat = "monk" }, }, }, }, },
	["hourofreaping"] = {
		actions = {
			{ type = "powersave", save = "wisdom", },
			{ type = "effect", sName = "Frightened", nDuration = 1, },
		},
	},
	["touchofthelongdeath"] = {
		actions = {
			{ type = "powersave", save = "constitution", onmissdamage = "half" },
			{ type = "damage", clauses = { { dice = { "d10", "d10" }, dmgtype = "necrotic", }, }, },
		},
	},
	-- Monk - Way of the Open Hand
	["openhandtechnique"] = {
		actions = {
			{ type = "powersave", save = "dexterity", },
			{ type = "effect", sName = "Open Hand Technique; Prone", },
			{ type = "powersave", save = "strength", },
			{ type = "effect", sName = "Open Hand Technique; Can't take reactions", nDuration = 1 },
		},
	},
	["wholenessofbody"] = { actions = { { type = "heal", sTargeting = "self", clauses = { { dice = { }, stat = "monk" }, }, }, }, prepared = 1 },
	["tranquility"] = {
		actions = {
			{ type = "powersave", save = "wisdom", savestat = "wisdom", },
			{ type = "effect", sName = "Tranquility", sTargeting = "self", },
		},
	},
	["quiveringpalm"] = {
		actions = {
			{ type = "powersave", save = "constitution", },
			{ type = "damage", clauses = { { dice = { "d10","d10","d10","d10","d10","d10","d10","d10","d10","d10" }, dmgtype = "necrotic", }, }, },
		},
	},
	-- Monk - Way of the Sun Soul
	["radiantsunbolt"] = {
		actions = {
			{ type = "attack", range = "R" },
			{ type = "damage", clauses = { { dice = { "d4" }, dmgtype = "radiant", stat = "dexterity" }, }, },
		},
	},
	["searingsunburst"] = { actions = { { type = "powersave", save = "constitution", }, { type = "damage", clauses = { { dice = { "d6", "d6" }, dmgtype = "radiant", }, }, }, }, },
	["sunshield"] = { actions = { { type = "damage", clauses = { { dice = { }, modifier = 5, dmgtype = "radiant", stat = "wisdom" }, }, }, }, },
	-- Paladin
	["layonhands"] = { actions = { { type = "heal", clauses = { { dice = { }, bonus = 5, }, }, }, }, },
	["divinesmite"] = { actions = { { type = "effect", sName = "Divine Smite; DMG: 2d8 radiant; IFT: TYPE(fiend,undead); DMG:1d8 radiant", sTargeting = "self", sApply = "roll" }, }, },
	["divinesense"] = { actions = { { type = "effect", sName = "Divine Sense; Know the location of any celestial, fiend, or undead (also hallow spell) within 60'", sTargeting = "self", nDuration = 1, }, }, prepared = 1 },
	["divinehealth"] = { actions = { { type = "effect", sName = "Divine Health; Immune to disease", sTargeting = "self", }, }, },
	["auraofprotection"] = { actions = { { type = "effect", sName = "Aura of Protection; SAVE: [CHA]", sTargeting = "self" }, }, },
	["auraofcourage"] = { actions = { { type = "effect", sName = "Aura of Courage; IMMUNE: frightened", }, }, },
	["improveddivinesmite"] = { actions = { { type = "effect", sName = "Improved Divine Smite; DMG: 1d8 radiant,melee", sTargeting = "self", }, }, },
	["cleansingtouch"] = { actions = {}, prepared = 1 },
	-- Paladin - Oath of Conquest
	["conquestoathspells"] = {
		spell = {
			level = {
				[3] = { "Armor of Agathys", "Command" },
				[5] = { "Hold Person", "Spiritual Weapon" },
				[9] = { "Bestow Curse", "Fear" },
				[13] = { "Dominate Beast", "Stoneskin" },
				[17] = { "Cloudkill", "Dominate Person" },
			},
		},
	},
	["auraofconquest"] = { actions = { { type = "effect", sName = "Aura of Conquest; DMGO: [HLVL] psychic; Movement is zero", }, }, },
	["scornfulrebuke"] = { actions = { { type = "damage", clauses = { { dice = {}, dmgtype = "psychic", stat = "charisma" }, }, }, }, },
	["invincibleconqueror"] = { actions = { { type = "effect", sName = "Invincible Conqueror; RESIST: all", sTargeting = "self", nDuration = 1, sUnits = "minute", }, }, },
	-- Paladin - Oath of Devotion
	["oathspellsdevotion"] = {
		spell = {
			level = {
				[3] = { "Protection from Evil and Good", "Sanctuary" },
				[5] = { "Lesser Restoration", "Zone of Truth" },
				[9] = { "Beacon of Hope", "Dispel Magic" },
				[13] = { "Freedom of Movement", "Guardian of Faith" },
				[17] = { "Commune", "Flame Strike" },
			},
		},
	},
	["auraofdevotion"] = { actions = { { type = "effect", sName = "Aura of Devotion; IMMUNE: Charmed", }, }, },
	["purityofspirit"] = {
		actions = {
			{ type = "effect", sName = "IFT: TYPE(aberration,celestial,elemental,fey,fiend,undead);GRANTDISATK:", sTargeting = "self", },
			{ type = "effect", sName = "IFT: TYPE(aberration,celestial,elemental,fey,fiend,undead); IMMUNE: charmed, frightened", sTargeting = "self", },
		},
	},
	["holynimbus"] = { actions = { { type = "damage", clauses = { { dice = { }, modifier = 10, dmgtype = "radiant", }, }, }, }, prepared = 1, },
	-- Paladin - Oath of Glory
	-- Paladin - Oath of Redemption
	["protectivespirit"] = { actions = { { type = "effect", sName = "Protective Spirit; IF: Bloodied; REGEN: [HLVL]; IF: Bloodied; REGEN: 1d6", sTargeting = "self", }, }, },
	["emissaryofredemption"] = { actions = { { type = "effect", sName = "Emissary of Redemption; RESIST: all", sTargeting = "self", }, }, },
	-- Paladin - Oath of the Ancients
	["auraofwarding"] = { actions = { { type = "effect", sName = "Aura of Warding; RESIST: all", sTargeting = "self", }, }, },
	["undyingsentinel"] = { actions = { { type = "heal", clauses = { { dice = {}, bonus = 1, }, }, }, }, prepared = 1, },
	["elderchampion"] = { actions = { { type = "effect", sName = "Elder Champion; REGEN: 10", sTargeting = "self", nDuration = 1, sUnits = "minute" }, }, },
	-- Paladin - Oath of the Crown
	["championchallenge"] = {
		actions = {
			{ type = "powersave", save = "wisdom", },
			{ type = "effect", sName = "Champion Challenge; Compelled to battle with and cannot move more than 30' from Paladin", },
		},
	},
	["unyieldingspirit"] = { actions = { { type = "effect", sName = "Unyielding Spirit; Advantages on saving throws against paralyzed and stunned", sTargeting = "self", }, }, },
	["exhaltedchampion"] = {
		actions = {
			{ type = "effect", sName = "Exhalted Champion; RESIST: bludgeoning,piercing,slashing,!magic", sTargeting = "self", nDuration = 1, sUnits = "hour", },
			{ type = "effect", sName = "Exhalted Champion; ADVDEATH; ADVSAV: wisdom", nDuration = 1, sUnits = "hour", },
		},
	},
	-- Paladin - Oath of the Watchers
	-- Paladin - Oath of Vengeance
	["relentlessavenger"] = { actions = { { type = "effect", sName = "Relentless Avenger; After hitting with an opportunity attack, move up to half your speed immediately, doesn't provoke opportunity attacks", sTargeting = "self", }, }, },
	["avengingangel"] = {
		actions = {
			{ type = "powersave", save = "wisdom", },
			{ type = "effect", sName = "Avenging Angel; Frightened; GRANTADVATK", nDuration = 1, sUnits = "minute", },
			{ type = "effect", sName = "Avenging Angel; Fly 60", sTargeting = "self", nDuration = 1, sUnits = "hour", },
		},
	},
	-- Paladin - Oathbreaker
	["auraofhate"] = { actions = { { type = "effect", sName = "Aura of Hate; DMG: [CHA]", }, }, },
	["supernaturalresistance"] = { actions = { { type = "effect", sName = "Supernatural Resistance; RESIST: bludgeoning,piercing,slashing,!magic", sTargeting = "self" }, }, },
	["dreadlord"] = {
		actions = {
			{ type = "damage", clauses = { { dice = { "d10", "d10", "d10", "d10" }, dmgtype = "psychic", }, }, },
			{ type = "effect", sName = "Dread Lord (Aura of Gloom)", sTargeting = "self", nDuration = 1, sUnits = "minute", },
			{ type = "effect", sName = "Dread Lord (Aura of Gloom); GRANTDISATK", },
			{ type = "attack", range = "M", modifier = 1 },
			{ type = "damage", clauses = { { dice = { "d10", "d10", "d10" }, dmgtype = "necrotic", stat = "charisma" }, }, },
		},
		prepared = 1,
	},
	-- Ranger
	["favoredenemy"] = {
		actions = {
			{ type = "effect", sName = "Favored Enemy; ADVSKILL: survival", sTargeting = "self", sApply = "action" },
			{ type = "effect", sName = "Favored Enemy; ADVCHK: intelligence", sTargeting = "self", sApply = "action" },
		},
	},
	["landsstride"] = { actions = { { type = "effect", sName = "Land's Stride; ADVSAV:all", sTargeting = "self", sApply = "action" }, }, },
	["hideinplainsight"] = { actions = { { type = "effect", sName = "Hide in Plain Sight; SKILL: 10, stealth", sTargeting = "self", sApply = "action" }, }, },
	["feralsenses"] = { actions = { { type = "effect", sName = "Feral Senses; IFT: invisible; ADVATK", sTargeting = "self", }, }, },
	["foeslayer"] = {
		actions = {
			{ type = "effect", sName = "Foe Slayer; ATK:[WIS]", sTargeting = "self", sApply = "action" },
			{ type = "effect", sName = "Foe Slayer; IFT: TYPE(giant,orc); DMG:[WIS]", sTargeting = "self", sApply = "action" },
		},
	},
	-- Ranger - Beast Master
	-- Ranger - Drakewarden
	-- Ranger - Fey Wanderer
	-- Ranger - Gloom Stalker
	["dreadambusher"] = {
		actions = {
			{ type = "effect", sName = "Dread Ambusher; DMG: 1d8", sTargeting = "self", sApply = "roll" },
			{ type = "effect", sName = "Dread Ambusher; INIT: [WIS]", sTargeting = "self", },
		},
		prepared = 1,
	},
	["ironmind"] = {
		actions = {
			{ type = "effect", sName = "Iron Mind; SAVE: [PRF] wisdom", sTargeting = "self", },
			{ type = "effect", sName = "Iron Mind; SAVE: [PRF] intelligence", sTargeting = "self", },
			{ type = "effect", sName = "Iron Mind; SAVE: [PRF] charisma", sTargeting = "self", },
		},
	},
	["shadowydodge"] = { actions = { { type = "effect", sName = "Shadowy Dodge; GRANTDISATK", sTargeting = "self", sApply = "action" }, }, },
	["stalkersflurry"] = { actions = { { type = "effect", sName = "Stalker's Flurry; Extra attack upon miss once per turn", sTargeting = "self", }, }, },
	["umbralsight"] = { actions = { { type = "effect", sName = "Umbral Sight; Invisible", sTargeting = "self", }, }, },
	-- Ranger - Horizon Walker
	["detectportal"] = { actions = {}, prepared = 1, },
	["etherealstep"] = { actions = {}, prepared = 1, usesperiod = "enc" },
	["planarwarrior"] = {
		actions = {
			{ type = "effect", sName = "Planar Warrior; DMGTYPE: force", sTargeting = "self", sApply = "roll" },
			{ type = "effect", sName = "Planar Warrior; DMG: 1d8 force", sTargeting = "self", sApply = "roll" },
		},
		prepared = 1,
	},
	["spectraldefense"] = { actions = { { type = "effect", sName = "Spectral Defense; RESIST: all", sTargeting = "self", sApply = "action" }, }, },
	-- Ranger - Hunter
	["huntersprey"] = {
		multiple_actions = {
			["Hunter's Prey (Colossus Slayer)"] = { actions = { { type = "effect", sName = "Colossus Slayer; IFT: Wounded; DMG: 1d8", sTargeting = "self", sApply = "roll" }, }, },
			["Hunter's Prey (Giant Killer)"] = { actions = { { type = "effect", sName = "Giant Killer; Large(r) creature within 5 feet misses, can reaction attack", sTargeting = "self", sApply = "roll" }, }, },
			["Hunter's Prey (Horde Breaker)"] = { actions = { { type = "effect", sName = "Horde Breaker; Can attack additional foe adjacent to target once per turn", sTargeting = "self", }, }, },
		},
	},
	["defensivetactics"] = {
		multiple_actions = {
			["Defensive Tactics (Escape the Horde)"] = { actions = { { type = "effect", sName = "Escape the Horde; GRANTDISATK: opportunity", sTargeting = "self", }, }, },
			["Defensive Tactics (Multiattack Defense)"] = { actions = { { type = "effect", sName = "Multiattack Defense; AC: 4", sTargeting = "self", nDuration = 1 }, }, },
			["Defensive Tactics (Steel Will)"] = { actions = { { type = "effect", sName = "Steel Will; Advantage on saving throws against frightened", sTargeting = "self", }, }, },
		},
	},
	["superiorhuntersdefense"] = {
		multiple_actions = {
			["Superior Hunter's Defense (Evasion)"] = { actions = { { type = "effect", sName = "Superior Hunter's Defense (Evasion); Evasion", sTargeting = "self", }, }, },
			["Superior Hunter's Defense (Stand Against the Tide)"] = { actions = { { type = "effect", sName = "Superior Hunter's Defense (Stand Against the Tide); Creature misses with melee, can force that same attack against another creature", sTargeting = "self", }, }, },
			["Superior Hunter's Defense (Uncanny Dodge)"] = { actions = { { type = "effect", sName = "Superior Hunter's Defense (Uncanny Dodge); RESIST: all", sTargeting = "self", sApply = "action" }, }, },
		},
	},
	-- Ranger - Monster Slayer
	["hunterssense"] = { actions = {}, prepared = 1 },
	["magicusersnemesis"] = { actions = { { type = "powersave", save = "wisdom", }, }, prepared = 1 },
	["slayersprey"] = { actions = { { type = "effect", sName = "Slayer's Prey; DMG: 1d6", sTargeting = "self", sApply = "roll" }, }, },
	["supernaturaldefense"] = { actions = { { type = "effect", sName = "Supernatural Defense; SAVE: 1d6; CHECK: 1d6", sTargeting = "self", sApply = "action" }, }, },
	-- Ranger - Swarmkeeper
	-- Rogue
	["sneakattack"] = { actions = { { type = "effect", sName = "Sneak Attack; DMG: 1d6", sTargeting = "self", sApply = "roll" }, }, },
	["thievescant"] = { language = { innate = { "Thieves' Cant" }, }, },
	["uncannydodge"] = { actions = { { type = "effect", sName = "Uncanny Dodge; RESIST: all", sTargeting = "self", sApply = "action" }, }, },
	["blindsense"] = { actions = { { type = "effect", sName = "Blindsense; Aware of hidden and invisible creature location within 10'", sTargeting = "self", sApply = "action" }, }, },
	["slipperymind"] = { actions = { { type = "effect", sName = "Slippery Mind; SAVE: [PRF] wisdom", sTargeting = "self" }, }, },
	["reliabletalent"] = { actions = { { type = "effect", sName = "Reliable Talent; Proficient ability checks roll at 10 minimum", sTargeting = "self", }, }, },
	["strokeofluck"] = { actions = {}, prepared = 1 },
	-- Rogue - Arcane Trickster
	["magicalambush"] = { actions = { { type = "effect", sName = "Magical Ambush; DISSAV: all", sApply = "roll" }, }, },
	["versatiletrickster"] = { actions = { { type = "effect", sName = "Versatile Trickster; ADVATK", sTargeting = "self", nDuration = 1 }, }, },
	["spellthief"] = {
		actions = {
			{ type = "effect", sName = "Spell Steal", sTargeting = "self", nDuration = 1, sUnits = "hour", },
			{ type = "powersave", save = "spell", savestat = "spell", },
		},
	},
	-- Rogue - Assassin
	["bonusproficienciesassassin"] = {
		toolprof = { innate = { "Disguise Kit", "Poisoner's Kit" }, },
	},
	["assassinate"] = { actions = { { type = "effect", sName = "Assassinate; ADVATK", sTargeting = "self", sApply = "action" }, }, },
	["impostor"] = { actions = { { type = "effect", sName = "Impostor; ADVSKILL: deception", sTargeting = "self", sApply = "action" }, }, },
	["deathstrike"] = { actions = { { type = "powersave", save = "constitution", }, }, },
	-- Rogue - Inquisitive
	["unerringeye"] = { actions = {}, prepared = 1, },
	["steadyeye"] = { actions = { { type = "effect", sName = "Steady Eye; ADVCHK: perception,investigation", sTargeting = "self", sApply = "action" }, }, },
	["eyeforweakness"] = { actions = { { type = "effect", sName = "Eye for Weakness; DMG: 3d6", sTargeting = "self", sApply = "roll", }, }, },
	["insightfulfighting"] = { actions = { { type = "effect", sName = "Insightful Fighting", sTargeting = "self", nDuration = 1, sUnits = "minute", }, }, },
	-- Rogue - Mastermind
	["masterofintrigue"] = {
		toolprof = { innate = { "Disguise Kit", "Forgery Kit", }, choice = 1, choice_prof = { "Gaming Set" }, },
		language = { choice = 1, },
	},
	["masteroftactics"] = { actions = { { type = "effect", sName = "Master of Tactics; ADVATK; ADVCHK", sTargeting = "self", sApply = "action" }, }, },
	-- Rogue - Phantom
	-- Rogue - Scout
	["survivalist"] = { actions = { { type = "effect", sName = "Survivalist; SKILL: [PRF] nature, survival", sTargeting = "self" }, }, },
	["ambushmaster"] = {
		actions = {
			{ type = "effect", sName = "Ambush Master; ADVINIT", sTargeting = "self" },
			{ type = "effect", sName = "Ambush Master; GRANTADVATK", nDuration = 1, },
		},
	},
	-- Rogue - Soulknife
	-- Rogue - Swashbuckler
	["rakishaudacity"] = { actions = { { type = "effect", sName = "Rakish Audacity; INIT: [CHA]", sTargeting = "self" }, }, },
	["panache"] = {
		actions = {
			{ type = "effect", sName = "Panache; Charmed", nDuration = 1, sUnits = "minute" },
			{ type = "effect", sName = "Panache; DISATK", nDuration = 1, sUnits = "minute" },
			{ type = "effect", sName = "Panache; GRANTADVATK", sTargeting = "self", nDuration = 1, sUnits = "minute" },
		},
	},
	["elegantmaneuver"] = { actions = { { type = "effect", sName = "Elegant Maneuver; ADVSKILL: acrobatics,athletics", sTargeting = "self", nDuration = 1 }, }, },
	["masterduelist"] = { actions = { { type = "effect", sName = "Master Duelist; ADVATK", sTargeting = "self", sApply = "action" }, }, prepared = 1, usesperiod = "enc", },
	-- Rogue - Thief
	["supremesneak"] = { actions = { { type = "effect", sName = "Supreme Sneak; ADVSKILL: stealth", sTargeting = "self", sApply = "action" }, }, },
	["secondstorywork"] = { actions = { { type = "effect", sName = "Second-Story Work; [DEX] ft added to running jump and climb at normal speed", sApply = "action" }, }, },
	-- Sorcerer
	["fontofmagic"] = { actions = {}, prepared = 2, },
	["metamagic"] = {
		multiple_actions = {
			["Metamagic (Heightened Spell)"] = { actions = { { type = "effect", sName = "Heightened Spell; DISSAV: all", sApply = "action" }, }, },
		},
	},
	-- Sorcerer - Aberrant Mind
	-- Sorcerer - Clockwork Soul
	-- Sorcerer - Divine Soul
	["favoredbythegods"] = { actions = {}, prepared = 1, },
	["strengthofthegrave"] = { actions = {}, prepared = 1 },
	-- Sorcerer - Draconic Bloodline
	["elementalaffinity"] = {
		actions = {
			{ type = "effect", sName = "Elemental Affinity; RESIST: ", sTargeting = "self", nDuration = 1, sUnits = "hour" },
			{ type = "effect", sName = "Elemental Affinity; DMG: [CHA]", sTargeting = "self", nDuration = 1, sUnits = "hour" },
		},
	},
	["draconicpresence"] = {
		actions = {
			{ type = "powersave", save = "wisdom", },
			{ type = "effect", sName = "Draconic Presence; Charmed", nDuration = 1, sUnits = "minute" },
			{ type = "effect", sName = "Draconic Presence", sTargeting = "self", nDuration = 1, sUnits = "minute" },
			{ type = "effect", sName = "Draconic Presence; Frightened", nDuration = 1, sUnits = "minute" },
		},
	},
	["dragonwings"] = { actions = { { type = "effect", sName = "Dragon Wings; Fly #", sTargeting = "self", }, }, },
	-- Sorcerer - Shadow Magic
	["houndofillomen"] = {
		actions = {
			{ type = "damage", clauses = { { dice = {}, modifier = 5, dmgtype = "force", }, }, },
			{ type = "effect", sName = "Hound of Ill Omen", sTargeting = "self", nDuration = 5, sUnits = "minute" },
		},
	},
	["otherworldlywings"] = { actions = { { type = "effect", sName = "Otherworldly Wings; Fly 30'", sTargeting = "self", }, }, },
	["umbralform"] = {
		actions = {
			{ type = "damage", clauses = { { dice = {}, modifier = 5, dmgtype = "force", }, }, },
			{ type = "effect", sName = "Umbral Form; RESIST: all,!radiant,!force", sTargeting = "self", nDuration = 1, sUnits = "minute" },
		},
	},
	["strengthofthegrave"] = { actions = {}, prepared = 1 },
	-- Sorcerer - Storm Sorcery
	["heartofthestorm"] = {
		actions = {
			{ type = "effect", sName = "Heart of the Storm; RESIST: lightning,thunder", sTargeting = "self", },
			{ type = "damage", clauses = { { dice = {}, modifier = 1, dmgtype = "lightning", }, }, },
			{ type = "damage", clauses = { { dice = {}, modifier = 1, dmgtype = "thunder", }, }, },
		},
	},
	["stormsfury"] = {
		actions = {
			{ type = "damage", clauses = { { dice = {}, modifier = 1, dmgtype = "lightning", stat = "sorcerer" }, }, },
			{ type = "powersave", save = "strength", },
		},
	},
	["windsoul"] = {
		actions = {
			{ type = "effect", sName = "Wind Soul; IMMUNE: lightning,thunder; Fly 60", sTargeting = "self", },
			{ type = "effect", sName = "Wind Soul; Fly 30", nDuration = 1, sUnits = "hour", },
			{ type = "effect", sName = "Wind Soul; IMMUNE: lightning,thunder; Fly 30", nDuration = 1, sUnits = "hour", },
		},
		prepared = 1
	},
	["tempestuousmagic"] = { actions = { { type = "effect", sName = "Tempestuous Magic; Fly 10' with no opp attack", sTargeting = "self", }, }, },
	-- Sorcerer - Wild Magic
	["tidesofchaos"] = { actions = { { type = "effect", sName = "Tides of Chaos; ADVATK; ADVCHK; ADVSAV", sTargeting = "self", sApply = "action", }, }, prepared = 1 },
	-- Warlock
	["eldritchinvocations"] = {
		multiple_actions = {
			["Eldritch Invocations (Bewitching Whispers)"] = { actions = {}, prepared = 1, },
			["Eldritch Invocations (Chains of Carceri)"] = { actions = {}, prepared = 1, },
			["Eldritch Invocations (Devil's Sight)"] = { actions = { { type = "effect", sName = "Devil's Sight 120", }, }, },
			["Eldritch Invocations (Dreadful Word)"] = {
				spell = { innate = { "Confusion" }, },
				actions = {
					{ type = "powersave", save = "wisdom", },
					{ type = "effect", sName = "Dreadful Word; roll on Confusion Table", },
				},
				prepared = 1,
			},
			["Eldritch Invocations (Gaze of Two Minds)"] = { actions = { { type = "effect", sName = "Gaze of Two Minds; Blinded; Deafened", nDuration = 1, sTargeting = "self" }, }, },
			["Eldritch Invocations (Minions of Chaos)"] = { actions = {}, prepared = 1 },
			["Eldritch Invocations (Mire of the Mind)"] = { actions = {}, prepared = 1 },
			["Eldritch Invocations (One with the Shadows)"] = { actions = { { type = "effect", sName = "One with Shadows; Invisible", sTargeting = "self", }, }, },
			["Eldritch Invocations (Scultor of Flesh)"] = { actions = { { type = "effect", sName = "One with Shadows; Invisible", sTargeting = "self", }, }, prepared = 1, },
			["Eldritch Invocations (Sign of Ill Omen)"] = { actions = {}, prepared = 1 },
			["Eldritch Invocations (Thief of Five Fates)"] = { actions = {}, prepared = 1 },
			["Eldritch Invocations (Witch Sight)"] = { actions = { { type = "effect", sName = "Witch Sight 30', can see shapechanger or concealed creature", sTargeting = "self", }, }, },
		},
	},
	["eldritchmaster"] = { actions = {}, prepared = 1 },
	["mysticarcanum"] = { actions = {}, prepared = 1 },
	-- Warlock - Hexblade
	["expandedspellslisthexblade"] = {},
	["hexbladescurse"] = {
		actions = {
			{ type = "effect", sName = "Hexblade's Curse; Cursed", nDuration = 1, sUnits = "minute", },
			{ type = "heal", sTargeting = "self", clauses = { { dice = {}, stat = "warlock" }, { dice = {}, stat = "charisma" }, } },
			{ type = "effect", sName = "Hexblade's Curse; IFT: custom(Cursed); DMG: [PRF]", sTargeting = "self", },
			{ type = "effect", sName = "Hexblade's Curse; CRIT: 19", sTargeting = "self", },
		},
		prepared = 1,
		usesperiod = "enc",
	},
	["hexwarrior"] = { armorprof = { innate = { "Medium", "Shields" }, }, weaponprof = { innate = { "Martial" }, }, },
	["masterofhexes"] = { actions = { { type = "effect", sName = "Master of Hexes; Cursed", }, }, },
	["accursedspecter"] = { actions = { { type = "effect", sName = "Accursed Specter; ATK: [CHA]", }, }, prepared = 1, },
	-- Warlock - The Archfey
	["feypresence"] = {
		actions = {
			{ type = "powersave", save = "wisdom", },
			{ type = "effect", sName = "Fey Presence; Frightened", nDuration = 1 },
			{ type = "effect", sName = "Fey Presence; Charmed", nDuration = 1, },
		},
		prepared = 1,
		usesperiod = "enc"
	},
	["mistyescape"] = { actions = { { type = "effect", sName = "Misty Escape; Invisible", nDuration = 1, sTargeting = "self" }, }, prepared = 1, usesperiod = "enc" },
	["beguilingdefenses"] = {
		actions = {
			{ type = "powersave", save = "wisdom", },
			{ type = "effect", sName = "Beguiling Defenses; IMMUNE: Charmed", sTargeting = "self", },
			{ type = "effect", sName = "Beguiling Defenses; Charmed", nDuration = 1, sUnits = "minute" },
		},
	},
	["darkdelirium"] = {
		actions = {
			{ type = "powersave", save = "wisdom", },
			{ type = "effect", sName = "Dark Delirium; Charmed", nDuration = 1, sUnits = "minute" },
			{ type = "effect", sName = "Dark Delirium; Frightened", nDuration = 1, sUnits = "minute" },
			{ type = "effect", sName = "Dark Delirium", sTargeting = "self", nDuration = 1, sUnits = "minute" },
		},
		prepared = 1,
		usesperiod = "enc",
	},
	-- Warlock - The Celestial
	["healinglight"] = { actions = { { type = "heal", sTargeting = "self", clauses = { { dice = { "d6" }, }, }, }, }, prepared = 1, },
	["searingvengeance"] = {
		actions = {
			{ type = "damage", clauses = { { dice = { "d8", "d8" }, dmgtype = "radiant", stat = "charisma" }, }, },
			{ type = "effect", sName = "Searing Vengeance; Blinded", },
		},
		prepared = 1,
	},
	-- Warlock - The Fathomless
	-- Warlock - The Fiend
	["darkonesblessing"] = { actions = { { type = "heal", subtype = "temp", sTargeting = "self", clauses = { { dice = {}, stat = "warlock" }, { dice = {}, stat = "charisma" }, }, }, }, },
	["darkonesownluck"] = { actions = { { type = "effect", sName = "Dark One's Own Luck; CHECK: 1d10; SAVE: 1d10", sTargeting = "self", sApply = "action" }, }, prepared = 1, usesperiod = "enc" },
	["fiendishresilience"] = { actions = { { type = "effect", sName = "Fiendish Resilience; RESIST: !magic,!silver,edit", sTargeting = "self" }, }, prepared = 1, usesperiod = "enc" },
	["hurlthroughhell"] = {
		actions = {
			{ type = "damage", clauses = { { dice = { "d10","d10","d10","d10","d10","d10","d10","d10","d10","d10" }, dmgtype = "psychic", }, }, },
			{ type = "effect", sName = "Hurl Through Hell", nDuration = 1 },
		},
		prepared = 1,
	},
	-- Warlock - The Genie
	-- Warlock - The Great Old One
	["entropicward"] = {
		actions = {
			{ type = "effect", sName = "Entropic Ward; DISATK", sApply = "action" },
			{ type = "effect", sName = "Entropic Ward; ADVATK", sTargeting = "self", nDuration = 1, sApply = "action" },
		},
		prepared = 1,
		usesperiod = "enc"
	},
	["createthrall"] = { actions = { { type = "effect", sName = "Create Thrall; Charmed", }, }, },
	["thoughtshield"] = { actions = { { type = "effect", sName = "Thought Shield; RESIST: psychic", sTargeting = "self", }, }, },
	-- Warlock - The Undead
	-- Warlock - The Undying
	["amongthedead"] = {
		actions = {
			{ type = "powersave", save = "wisdom", },
			{ type = "effect", sName = "Among the Dead; Advantages on saving throws vs. disease, undead must pass wisdom saving throw to attack", sTargeting = "self", },
		},
		spell = { innate = { "Spare the Dying" }, },
	},
	["defydeath"] = { actions = { { type = "heal", sTargeting = "self", clauses = { { dice = { "d8" }, stat = "constitution" }, }, }, }, prepared = 1, },
	["undyingnature"] = {},
	["indestructiblelife"] = { actions = { { type = "heal", sTargeting = "self", clauses = { { dice = { "d8" }, stat = "warlock" }, }, }, }, prepared = 1, usesperiod = "enc" },
	-- Wizard
	["arcanerecovery"] = { actions = {}, prepared = 1 },
	["benigntransposition"] = { actions = {}, prepared = 1 },
	-- Wizard - Bladesinging
	["songofvictory"] = { actions = { { type = "effect", sName = "Song of Victory; DMG: [INT]", sTargeting = "self", }, }, },
	["bladesong"] = { actions = { { type = "effect", sName = "Bladesong; AC: [INT]; SAVE: [INT] concentration; ADVSKILL: acrobatics; Speed increase by 10", sTargeting = "self", nDuration = 1, sUnits = "minute", }, }, prepared = 1, usesperiod = "enc", },
	["durablemagic"] = { actions = { { type = "effect", sName = "Durable Magic; AC: 2; SAVE: 2; (C)", sTargeting = "self", }, }, },
	["powersurge"] = { actions = { { type = "effect", sName = "Power Surge; DMG: [HLVL] force,magic", sTargeting = "self", sApply = "roll", }, }, },
	["tacticalwit"] = { actions = { { type = "effect", sName = "Tactical Wit; INIT: [INT]", sTargeting = "self", }, }, },
	-- Wizard - Chronurgy Magic
	-- Wizard - Graviturgy Magic
	-- Wizard - Order of Scribes
	-- Wizard - School of Abjuration
	["arcaneward"] = {
		actions = {
			{ type = "effect", sName = "Arcane Ward", sTargeting = "self" },
			{ type = "heal", subtype = "temp", sTargeting = "self", clauses = { { dice = {}, stat = "intelligence" }, }, },
		},
		prepared = 1,
	},
	["improvedabjuration"] = { actions = { { type = "effect", sName = "Improved Abjuration; CHECK: [PRF]", sTargeting = "self", sApply = "action" }, }, },
	["spellresistance"] = {
		actions = {
			{ type = "effect", sName = "Spell Resistance; ADVSAV: all", sTargeting = "self", sApply = "action" },
			{ type = "effect", sName = "Spell Resistance; RESIST: all", sTargeting = "self", sApply = "action" },
		},
	},
	-- Wizard - School of Conjuration
	["minorconjuration"] = { actions = { { type = "effect", sName = "Minor Conjuration", sTargeting = "self", nDuration = 1, sUnits = "hour", }, }, },
	["durablesummons"] = { actions = { { type = "heal", subtype = "temp", clauses = { { dice = {}, bonus = 30, }, }, }, }, },
	-- Wizard - School of Divination
	["thethirdeye"] = {
		multiple_actions = {
			["The Third Eye (Darkvision)"] = { actions = { { type = "effect", sName = "The Third Eye Darkvision; Darkvision 60", sTargeting = "self" }, }, prepared = 1, usesperiod = "enc", },
			["The Third Eye (Ethereal Sight)"] = { actions = { { type = "effect", sName = "The Third Eye Darkvision; Ethereal Sight 60", sTargeting = "self" }, }, prepared = 1, usesperiod = "enc" },
			["The Third Eye (Greater Comprehension)"] = { actions = { { type = "effect", sName = "Greater Comprehension", sTargeting = "self", }, }, prepared = 1, usesperiod = "enc" },
			["The Third Eye (See Invisibility)"] = { actions = { { type = "effect", sName = "See Invisibility within 10 feet", sTargeting = "self", }, }, prepared = 1, usesperiod = "enc" },
		},
	},
	["portent"] = { actions = {}, prepared = 2 },
	-- Wizard - School of Enchantment
	["hypnoticgaze"] = {
		actions = {
			{ type = "powersave", save = "wisdom", },
			{ type = "effect", sName = "Hypnotic Gaze; Charmed; Incapacitated", nDuration = 1, },
		},
		prepared = 1,
	},
	["instinctivecharm"] = { actions = { { type = "powersave", save = "wisdom", }, }, prepared = 1, },
	["altermemories"] = { actions = { { type = "powersave", save = "intelligence" }, }, },
	-- Wizard - School of Evocation
	["empoweredevocation"] = { actions = { { type = "effect", sName = "Empowered Evocation; DMG: [INT]", sTargeting = "self", sApply = "roll" }, }, },
	["overchannel"] = { actions = { { type = "damage", clauses = { { dice = { "d12", "d12" }, dmgtype = "necrotic", }, }, }, }, },
	-- Wizard - School of Illusion
	["illusoryself"] = { actions = {}, prepared = 1, usesperiod = "enc" },
	["illusoryreality"] = { actions = { { type = "effect", sName = "Illusory Reality", sTargeting = "self", nDuration = 1, sUnits = "minute", }, }, },
	-- Wizard - School of Necromancy
	["undeadthralls"] = { actions = { { type = "effect", sName = "Undead Thralls; DMG: [PRF]", }, }, },
	["inuredtoundeath"] = { actions = { { type = "effect", sName = "Inured to Undeath; RESIST: necrotic; HP MAX cannot be reduced", sTargeting = "self", }, }, },
	["commandundead"] = { actions = { { type = "powersave", save = "charisma", }, { type = "effect", sName = "Command Undead; Save every hour", }, }, },
	-- Wizard - School of Transmutation
	["minoralchemy"] = { actions = { { type = "effect", sName = "Minor Alchemy", sTargeting = "self", nDuration = 1, sUnits = "hour" }, }, },
	["transmutersstone"] = {
		actions = {
			{ type = "effect", sName = "Transmuter's Stone; Darkvision 60", },
			{ type = "effect", sName = "Transmuter's Stone; SAVE: [PRF] constitution", },
			{ type = "effect", sName = "Transmuter's Stone; RESIST: acid, cold, fire, lightning, thunder", },
		},
	},
	["shapechanger"] = { actions = {}, prepared = 1, usesperiod = "enc" },
	["mastertransmuter"] = { actions = {}, prepared = 1 },
	-- Wizard - School of War Magic
	["arcanedeflection"] = { actions = { { type = "effect", sName = "Arcane Deflection; AC: 2; SAVE: 4", sTargeting = "self", sApply = "action" }, }, },
	["deflectingshroud"] = { actions = { { type = "effect", sName = "Deflecting Shroud; DMG: [HLVL] force,magic", sTargeting = "self", sApply = "roll" }, }, },
	--
	-- Races
	--
	-- Aasimar
	-- Warlock - The Celestial - feature shares same name (default to Aasimar version)
	["celestialresistance"] = {
		actions = {
			{ type = "effect", sName = "Celestial Resistance; RESIST: necrotic,radiant", sTargeting = "self", },
		},
	},
	["healinghands"] = { actions = { { type = "heal", clauses = { { dice = {}, stat = "level" }, }, }, }, },
	["necroticshroud"] = {
		actions = {
			{ type = "effect", sName = "Necrotic Shroud; Frightened", nDuration = 1, },
			{ type = "effect", sName = "Necrotic Shroud", sTargeting = "self", nDuration = 1, sUnits = "minute" },
			{ type = "powersave", save = "charisma", },
			{ type = "effect", sName = "Necrotic Shroud; DMG: [LVL] necrotic", sTargeting = "self", sApply = "action" },
		},
		prepared = 1
	},
	["radiantconsumption"] = {
		actions = {
			{ type = "effect", sName = "Radiant Consumption", sTargeting = "self", nDuration = 1, },
			{ type = "damage", clauses = { { dice = {}, modifier = 1, dmgtype = "radiant", }, }, },
			{ type = "effect", sName = "Radiant Consumption; DMG: [LVL] radiant", sTargeting = "self", sApply = "action" },
		},
		prepared = 1
	},
	-- Warlock - The Celestial - feature shares same name (default to Aasimar version)
	["radiantsoul"] = {
		actions = {
			{ type = "effect", sName = "Radiant Soul; Fly Speed", sTargeting = "self", nDuration = 1, sUnits = "minute", },
			{ type = "effect", sName = "Radiant Soul; DMG: [LVL] radiant", sTargeting = "self", sApply = "action", },
		},
		prepared = 1
	},
	-- Bugbear
	["surpriseattack"] = { actions = { { type = "effect", sName = "Surprise Attack; DMG: 2d6", sTargeting = "self", sApply = "roll", }, }, },
	-- Centaur
	["charge"] = { actions = {}, prepared = 1 },
	["equinebuild"] = { actions = { { type = "effect", sName = "Equine Build; Climb movement costs 4 extra rather thn 1 extra.", sTargeting = "self", }, }, },
	-- Changeling
	["changeappearance"] = { actions = { { type = "effect", sName = "Change Appearance; ADVCHK: charisma", sTargeting = "self", sApply = "roll", }, }, },
	["divergentpersona"] = { actions = { { type = "effect", sName = "Divergent Persona; SKILL: [PRF]", sTargeting = "self", sApply = "roll", }, }, },
	["unsettlingvisage"] = { actions = { { type = "effect", sName = "Unsettling Visage; DISATK", sTargeting = "self", sApply = "roll", }, }, prepared = 1, usesperiod = "enc" },
	-- Dragonborn
	["reddragonbornbreathweapon"] = {
		actions = {
			{ type = "powersave", save = "dexterity", savestat = "constitution", onmissdamage = "half" },
			{ type = "damage", clauses = { { dice = { "d6", "d6" }, dmgtype = "fire", }, }, },
		},
	},
	["reddragonbornresistance"] = { actions = { { type = "effect", sName = "Draconic Resistance; RESIST: fire;", sTargeting = "self", }, }, },
	["bluedragonbornbreathweapon"] = {
		actions = {
			{ type = "powersave", save = "dexterity", savestat = "constitution", onmissdamage = "half" },
			{ type = "damage", clauses = { { dice = { "d6", "d6" }, dmgtype = "lightning", }, }, },
		},
	},
	["bluedragonbornresistance"] = { actions = { { type = "effect", sName = "Draconic Resistance; RESIST: lightning;", sTargeting = "self", }, }, },
	["greendragonbornbreathweapon"] = {
		actions = {
			{ type = "powersave", save = "constitution", savestat = "constitution",  onmissdamage = "half" },
			{ type = "damage", clauses = { { dice = { "d6", "d6" }, dmgtype = "poison", }, }, },
		},
	},
	["greendragonbornresistance"] = { actions = { { type = "effect", sName = "Draconic Resistance; RESIST: poison;", sTargeting = "self", }, }, },
	["bronzedragonbornbreathweapon"] = {
		actions = {
			{ type = "powersave", save = "dexterity", savestat = "constitution",  onmissdamage = "half" },
			{ type = "damage", clauses = { { dice = { "d6", "d6" }, dmgtype = "lightning", }, }, },
		},
	},
	["bronzedragonbornresistance"] = { actions = { { type = "effect", sName = "Draconic Resistance; RESIST: lightning;", sTargeting = "self", }, }, },
	["blackdragonbornbreathweapon"] = {
		actions = {
			{ type = "powersave", save = "dexterity", savestat = "constitution",  onmissdamage = "half" },
			{ type = "damage", clauses = { { dice = { "d6", "d6" }, dmgtype = "acid", }, }, },
		},
	},
	["blackdragonbornresistance"] = { actions = { { type = "effect", sName = "Draconic Resistance; RESIST: acid;", sTargeting = "self", }, }, },
	["whitedragonbornbreathweapon"] = {
		actions = {
			{ type = "powersave", save = "constitution", savestat = "constitution",  onmissdamage = "half" },
			{ type = "damage", clauses = { { dice = { "d6", "d6" }, dmgtype = "cold", }, }, },
		},
	},
	["whitedragonbornresistance"] = { actions = { { type = "effect", sName = "Draconic Resistance; RESIST: cold;", sTargeting = "self", }, }, },
	["golddragonbornbreathweapon"] = {
		actions = {
			{ type = "powersave", save = "dexterity", savestat = "constitution",  onmissdamage = "half" },
			{ type = "damage", clauses = { { dice = { "d6", "d6" }, dmgtype = "fire", }, }, },
		},
	},
	["golddragonbornresistance"] = { actions = { { type = "effect", sName = "Draconic Resistance; RESIST: fire;", sTargeting = "self", }, }, },
	["copperdragonbornbreathweapon"] = {
		actions = {
			{ type = "powersave", save = "dexterity", savestat = "constitution",  onmissdamage = "half" },
			{ type = "damage", clauses = { { dice = { "d6", "d6" }, dmgtype = "acid", }, }, },
		},
	},
	["copperdragonbornresistance"] = { actions = { { type = "effect", sName = "Draconic Resistance; RESIST: acid;", sTargeting = "self", }, }, },
	["brassdragonbornbreathweapon"] = {
		actions = {
			{ type = "powersave", save = "dexterity", savestat = "constitution",  onmissdamage = "half" },
			{ type = "damage", clauses = { { dice = { "d6", "d6" }, dmgtype = "fire", }, }, },
		},
	},
	["brassdragonbornresistance"] = { actions = { { type = "effect", sName = "Draconic Resistance; RESIST: fire;", sTargeting = "self", }, }, },
	["silverdragonbornbreathweapon"] = {
		actions = {
			{ type = "powersave", save = "constitution", savestat = "constitution",  onmissdamage = "half" },
			{ type = "damage", clauses = { { dice = { "d6", "d6" }, dmgtype = "cold", }, }, },
		},
	},
	["silverdragonbornresistance"] = { actions = { { type = "effect", sName = "Draconic Resistance; RESIST: cold;", sTargeting = "self", }, }, },
	-- Duergar
	["duergarmagic"] = {
		actions = {
			{ type = "powersave", save = "constitution", magic = true, savebase = "group" },
			{ type = "effect", sName = "Duergar Magic Enlarged; ADVCHK: strength; ADVSAV: strength; DMG: 1d4; (C)", nDuration = 1, sUnits = "minute" },
			{ type = "effect", sName = "Duergar Magic Reduced; DISCHK: strength; DISSAV: strength; DMG: -1d4; (C)", nDuration = 1, sUnits = "minute" },
		},
		prepared = 1
	},
	["duergarresilience"] = { actions = { { type = "effect", sName = "Duergar Resilience; Advantage against illusions, charmed, and paralyzed", sTargeting = "self" }, }, },
	["sunlightsensitivity"] = { actions = { { type = "effect", sName = "Sunlight Sensitivity; DISATK; DISSKILL: perception", sTargeting = "self" }, }, },
	-- Dwarf
	["dwarvenresilience"] = { actions = { { type = "effect", sName = "Dwarven Resilience; RESIST: poison; Advantage on saving throws vs. poison", sTargeting = "self" }, }, },
	["stonecunning"] = { actions = { { type = "effect", sName = "Stonecunning; SKILL: [2PRF] history", sTargeting = "self", sApply = "action" }, }, },
	["masteroflocks"] = { actions = { { type = "effect", sName = "Master of Locks; SKILL: 1d4 history, investigation, thieves' tools", sTargeting = "self", sApply = "action" }, }, },
	["wardsandseals"] = { actions = {}, prepared = 1 },
	["wardersintuition"] = { actions = { { type = "effect", sName = "Warder's Intuition; SKILL: 1d4 investigation, thieves' tools", sTargeting = "self", }, }, },
	-- Elf
	["feyancestry"] = { actions = { { type = "effect", sName = "Fey Ancestry; Advantage on saving throws vs. charmed, no magic sleep", sTargeting = "self", }, }, },
	["feystep"] = {
		actions = {
			{ type = "powersave", save = "wisdom", savestat = "charisma", },
			{ type = "effect", sName = "Fey Step; Charmed", nDuration = 1, sUnits = "minute" },
			{ type = "effect", sName = "Fey Step; Frightened", nDuration = 1, },
			{ type = "damage", clauses = { { dice = {}, dmgtype = "fire", stat = "charisma" }, }, },
		},
		prepared = 1
	},
	["maskofthewild"] = { actions = { { type = "effect", sName = "Mask of the Wild; Hide when lightly obscurred", sTargeting = "self", }, }, },
	["feyancestry"] = {
		spell = { innate = { "Dancing Lights" }, level = { [3] = { "Faerie Fire" }, [5] = { "Darkness" }, }, },
	},
	["childofthesea"] = { actions = { { type = "effect", sName = "Child of the Sea; Swim speed 30' and can breathe air and water", sTargeting = "self", }, }, },
	["friendofthesea"] = { actions = { { type = "effect", sName = "Friend of the Sea; Can communicate with beasts that have a swim speed", sTargeting = "self", }, }, },
	["giftoftheshadows"] = { actions = { { type = "effect", sName = "Gift of the Shadows; SKILL: 1d4 performance, stealth", sTargeting = "self", }, }, },
	["slipintoshadow"] = { actions = { { type = "effect", sName = "Slip Into Shadow; Hidden", sTargeting = "self", }, }, prepared = 1 },
	["deductiveintuition"] = { actions = { { type = "effect", sName = "Deductive Intuition; SKILL: 1d4 investigation, insight", sTargeting = "self", }, }, },
	["headwinds"] = { actions = {}, prepared = 1 },
	["stormsblessing"] = { actions = { { type = "effect", sName = "Storm's Blessing; RESIST: lightning", sTargeting = "self", }, }, },
	["windwrightsintuition"] = {
		actions = {
			{ type = "effect", sName = "Windwright's Intuition; SKILL: 1d4, acrobatics", sTargeting = "self", },
			{ type = "effect", sName = "Windwright's Intuition; SKILL: 1d4", sTargeting = "self", sApply = "action" },
		},
	},
	["cunningintuition"] = { actions = { { type = "effect", sName = "Cunning Intuition; SKILL: 1d4 performance, stealth", sTargeting = "self", }, }, },
	["stormsboon"] = { actions = { { type = "effect", sName = "Storm's Boon; RESIST: lightning", sTargeting = "self", }, }, },
	-- Firbolg
	["firbolgmagic"] = {
		spell = { innate = { "Detect Magic", "Disguise Self" }, },
	},
	["hiddenstep"] = { actions = { { type = "effect", sName = "Hidden Step; Invisible", sTargeting = "self", nDuration = 1 }, }, prepared = 1, usesperiod = "enc" },
	["speechofbeastandleaf"] = { actions = { { type = "effect", sName = "Speech of Beast and Leaf; ADVCHK: charisma", sTargeting = "self", nApply = "action" }, }, },
	-- Genasi
	["acidresistance"] = { actions = { { type = "effect", sName = "Acid Resistance; RESIST: acid", sTargeting = "self", }, }, },
	["calltothewave"] = {
		spell = { innate = { "Shape Water" }, level = { [3] = { "Create or Destroy Water" }, }, },
	},
	["earthwalk"] = { actions = { { type = "effect", sName = "Earth Walk; Earth and stone not difficult terrain", sTargeting = "self", }, }, },
	["fireresistance"] = { actions = { { type = "effect", sName = "Fire Resistance; RESIST: fire", sTargeting = "self", }, }, },
	["mergewithstone"] = {
		spell = { innate = { "Pass without Trace" }, },
	},
	["minglewiththewind"] = {
		spell = { innate = { "Levitate" }, },
	},
	["reachtotheblaze"] = {
		spell = { innate = { "Produce Flame" }, level = { [3] = { "Burning Hands" }, }, },
	},
	-- Githzerai
	-- Gnome
	["artificerslore"] = { actions = { { type = "effect", sName = "Artificer's Lore; SKILL: [PRF] history", sTargeting = "self", sApply = "action" }, }, },
	["gnomecunning"] = { actions = { { type = "effect", sName = "Gnome Cunning; ADVSAV: intelligence,wisdom,charisma", sTargeting = "self", sApply = "action" }, }, },
	["stonecamouflage"] = { actions = { { type = "effect", sName = "Stone Camouflage; ADVCHK: dexterity", sTargeting = "self", sApply = "action" }, }, },
	["giftedscribe"] = { actions = { { type = "effect", sName = "Gifted Scribe; SKILL: 1d4 forgery kit, calligrapher's supplies", sTargeting = "self", }, }, },
	["scribesinsight"] = { actions = {}, prepared = 1, },
	-- Hobgoblin
	["savingface"] = { actions = {}, prepared = 1, },
	-- Goblin
	["furyofthesmall"] = { actions = { { type = "damage", clauses = { { dice = {}, dmgtype = "", stat = "prf" }, }, }, }, prepared = 1, usesperiod = "enc" },
	["nimbleescape"] = { actions = { { type = "effect", sName = "Nimble Escape; Disengage or hide as bonus action", sTargeting = "self", }, }, },
	-- Goliath
	["stonesendurance"] = { actions = { { type = "heal", sTargeting = "self", clauses = { { dice = { "d12" }, stat = "constitution" }, }, }, }, prepared = 1, usesperiod = "enc" },
	-- Half-Orc
	["relentlessendurance"] = { actions = { { type = "heal", sTargeting = "self", clauses = { { dice = {}, bonus = 1, }, }, }, }, prepared = 1, },
	["huntersintuition"] = { actions = { { type = "effect", sName = "Hunter's Intuition; SKILL: 1d4 perception, survival", sTargeting = "self", }, }, },
	["imprintprey"] = { actions = { { type = "effect", sName = "Imprint Prey", sTargeting = "self", }, }, prepared = 1, usesperiod = "enc" },
	-- Halfling
	["brave"] = { actions = { { type = "effect", sName = "Brave; ADVSAV: all", sTargeting = "self", sApply = "action" }, }, },
	["naturallystealthy"] = { actions = { { type = "effect", sName = "Naturally Stealthy; Hide attempt obsucured by creature at least one size larger", }, }, },
	["silentspeech"] = { actions = { { type = "effect", sName = "Silent Speech; Telepathy 30 (if shared language)", sTargeting = "self" }, }, },
	["stoutresilience"] = { actions = { { type = "effect", sName = "Stout Resilience; RESIST: poison; Advantage on saving throws vs. poison", sTargeting = "self" }, }, },
	["healingtouch"] = { actions = {}, prepared = 1, usesperiod = "enc" },
	["medicalintuition"] = { actions = { { type = "effect", sName = "Halfling Dragonmarked: ; SKILL: 1d4 medicine", sTargeting = "self" }, }, },
	["artisansintuition"] = { actions = { { type = "effect", sName = "Artisan's Intuition; SKILL 1d4 edit", sTargeting = "self" }, }, },
	["everhospitable"] = { actions = { { type = "effect", sName = "Ever Hospitable; SKILL: 1d4 persuasion, brewer's supplies", sTargeting = "self" }, }, },
	-- Human
	["intuitivemotion"] = { actions = { { type = "effect", sName = "Intuitive Motion; SKILL: 1d4 athletics", sTargeting = "self" }, { type = "effect", sName = "Intuitive Motion; SKILL: 1d4", sTargeting = "self", sApply ="action" }, }, },
	["primalconnection"] = { actions = {}, prepared = 1, usesperiod = "enc" },
	["sentinelsintuition"] = {
		actions = {
			{ type = "effect", sName = "Sentinel's Intuition; INIT: 1d4", sTargeting = "self" },
			{ type = "effect", sName = "Sentinel's Intuition; SKILL: 1d4 perception", sTargeting = "self", sApply ="action" },
		},
	},
	["sentinelsshield"] = {
		spell = { innate = { "Blade Ward", "Shield" }, },
	},
	["sharedpassage"] = { actions = {}, prepared = 1, },
	["spellsmith"] = {
		actions = {
			{ type = "effect", sName = "Spellsmith; AC: 1", sTargeting = "self", nDuration = 1, sUnits = "hour" },
			{ type = "effect", sName = "Spellsmith; DMG: 1; ATK: 1; DMGTYPE: magic", sTargeting = "self", nDuration = 1, sUnits = "hour" },
		},
	},
	["vigilantguardian"] = { actions = { { type = "effect", sName = "Vigilant Guardian; ADVSKILL: insight, perception", sTargeting = "self", sApply = "action", }, }, },
	["wildintuition"] = { actions = { { type = "effect", sName = "Wild Intuition; SKILL: 1d4 animal handling, nature", sTargeting = "self", }, }, },
	["intuativemotion"] = { actions = { { type = "effect", sName = "Intuative Motion; SKILL: 1d4 acrobatics, vehicles (land)", sTargeting = "self", }, }, },
	["sentinalsintuition"] = { actions = { { type = "effect", sName = "Sentinal's Intuition; SKILL: 1d4 insight, perception", sTargeting = "self", }, }, },
	-- Kalashtar
	["dualmind"] = { actions = { { type = "effect", sName = "Dual Mind; ADVSAV: wisdom", sTargeting = "self", sApply = "roll" }, }, },
	["mentaldiscipline"] = {
		actions = {
			{ type = "effect", sName = "Mental Discipline (Kalashtar); RESIST: psychic", sTargeting = "self", },
			{ type = "effect", sName = "Mental Discipline (Githzerai): Advantage on saves vs. charmed/frightened", sTargeting = "self", },
		},
	},
	["mindlink"] = { actions = { { type = "effect", sName = "Mind Link; Telepathy 60' with one creature", sTargeting = "self", }, }, },
	["psychicglamour"] = { actions = { { type = "effect", sName = "Psychic Glamour; ADVSKILL: edit", sTargeting = "self", }, }, },
	["severedfromdreams"] = { actions = { { type = "effect", sName = "Severed from Dreams; Immune to dream effects", sTargeting = "self", }, }, },
	-- Kenku
	["mimicry"] = { actions = { { type = "effect", sName = "Mimicry", sTargeting = "self" }, }, },
	["expertforgery"] = { actions = { { type = "effect", sName = "Expert Forgery; ADVCHK: all", sTargeting = "self", sApply = "action" }, }, },
	-- Kobold
	["packtactics"] = { actions = { { type = "effect", sName = "Pack Tactics; ADVATK", sTargeting = "self", }, }, },
	["grovelcowerandbeg"] = { actions = { { type = "effect", sName = "Grovel Cower and Beg; GRANTADVATK", nDuration = 1, }, }, prepared = 1, usesperiod = "enc" },
	-- Lizardfolk
	["bite"] = { actions = { { type = "damage", clauses = { { dice = { "d6" }, dmgtype = "piercing", stat = "strength" }, }, }, }, },
	["hungryjaws"] = { actions = { { type = "heal", subtype = "temp", sTargeting = "self", clauses = { { dice = {}, stat = "constitution" }, }, }, }, prepared = 1, usesperiod = "enc" },
	-- Loxodon
	["keensmell"] = {
		actions = {
			{ type = "effect", sName = "Keen Smell; ADVSKILL: perception", sTargeting = "self", sApply = "action" },
			{ type = "effect", sName = "Keen Smell; ADVSKILL: survival", sTargeting = "self", sApply = "action" },
			{ type = "effect", sName = "Keen Smell; ADVSKILL: investigation", sTargeting = "self", sApply = "action" },
		},
	},
	["loxodonserenity"] = { actions = { { type = "effect", sName = "Loxodon Serenity; Advantage against being charmed or frightened.", sTargeting = "self", }, }, },
	-- Minotaur
	["hammeringhorns"] = { actions = { { type = "powersave", save = "strength", savestat = "strength", }, }, },
	-- Orc
	["aggressive"] = { actions = { { type = "effect", sName = "Aggressive; Bonus action move", }, }, },
	-- Shadar-kai
	["blessingoftheravenqueen"] = { actions = { { type = "effect", sName = "Blessing of the Raven Queen; RESIST: all", sTargeting = "self", nDuration = 1 }, }, },
	["necroticresistance"] = { actions = { { type = "effect", sName = "Necrotic Resistance; RESIST: necrotic", sTargeting = "self", }, }, },
	-- Shifter
	["markthescent"] = {
		actions = {
			{ type = "effect", sName = "Mark the Scent; CHECK: [PRF]", sTargeting = "self", sApply = "roll" },
		},
		usesperiod = "enc"
	},
	["shifted"] = {
		actions = {
			{ type = "heal", subtype = "temp", sTargeting = "self", clauses = { { dice = {}, stat = "level" }, { dice = {}, stat = "constitution" }, } },
			{ type = "effect", sName = "Shifted", sTargeting = "self", nDuration = 1, sUnits = "minute" },
		},
		prepared = 1,
		usesperiod = "enc"
	},
	["shiftingfeature"] = {
		multiple_actions = {
			["Shifting Feature (Beasthide)"] = { actions = { { type = "heal", subtype = "temp", sTargeting = "self", clauses = { { dice = { "d6" }, }, }, }, { type = "effect", sName = "Shifting Feature (Beastside); AC: 1", sTargeting = "self", nDuration = 1, sUnits = "minute" }, }, },
			["Shifting Feature (Longtooth)"] = { actions = { { type = "damage", clauses = { { dice = { "d6" }, dmgtype = "piercing", stat = "strength" }, }, }, }, },
			["Shifting Feature (Swiftstride)"] = { actions = { { type = "effect", sName = "Shifting Feature (Swiftstride); Special movement", sTargeting = "self", nDuration = 1, sUnits = "minute" }, }, },
			["Shifting Feature (Wildhunt)"] = { actions = { { type = "effect", sName = "Shifting Feature (Wildhunt); ADVCHK: wisdom", sTargeting = "self", nDuration = 1, sUnits = "minute" }, }, },
		},
	},
	-- Simic Hybrid
	["animalenhancement"] = {
		multiple_actions = {
			["Animal Enhancement (Manta Glide)"] = { actions = { { type = "effect", sName = "Animal Enhancement (Underater Adaptation); Can breathe air and water, swimming speed equal to walking speed.", sTargeting = "self", }, }, },
			["Animal Enhancement (Nimble Climber)"] = { actions = { { type = "effect", sName = "Animal Enhancement (Nimble Climber); Climbing speed equal to walking speed", sTargeting = "self", }, }, },
			["Animal Enhancement (Grappling Appendages)"] = {
				actions = {
					{ type = "effect", sName = "Animal Enhancement (Grappling Appendages); Grappled", },
					{ type = "damage", clauses = { { dice = { "d6" }, dmgtype = "bludgeoning", stat = "strength" }, }, },
				},
			},
			["Animal Enhancement (Carapace)"] = { actions = { { type = "effect", sName = "Animal Enhancement (Carapace); AC: 1", sTargeting = "self", }, }, },
			["Animal Enhancement (Acid Spit)"] = {
				actions = {
					{ type = "powersave", save = "dexterity", savestat = "constitution", },
					{ type = "damage", clauses = { { dice = { "d10", "d10" }, dmgtype = "acid", }, }, },
				},
			},
		},
	},
	-- Tabaxi
	["catsclaws"] = { actions = { { type = "damage", clauses = { { dice = { "d4" }, dmgtype = "slashing", stat = "strength" }, }, }, }, },
	-- Tiefling
	["infernallegacy"] = {
		spell = {
			innate = { "Thaumaturgy" },
			level = { [3] = { "Hellish Rebuke" }, },
		},
	},
	["hellishresistance"] = { actions = { { type = "effect", sName = "Hellish Resistance; RESIST: fire", sTargeting = "self" }, }, },
	["hellfire"] = { spell = { level = { [3] = { "Burning Hands" }, }, }, },
	["devilstongue"] = {
		spell = {
			innate = { "Vicious Mockery" },
			level = {
				[3] = { "Charm Person" },
				[5] = { "Enthrall" },
			},
		},
	},
	-- Tortle
	["claws"] = { actions = { { type = "damage", clauses = { { dice = { "d4" }, dmgtype = "slashing", stat = "strength" }, } }, }, },
	["holdbreath"] = { actions = { { type = "effect", sName = "Hold Breath", sTargeting = "self", nDuration = 1, sUnits = "hour" }, }, },
	["shelldefense"] = { actions = { { type = "effect", sName = "Shell Defense; AC: 4; ADVSAV: constitution, strength; prone; Speed is zero; DISSAV: dexterity; no actions.", sTargeting = "self", }, }, },
	-- Triton
	["guardiansofthedepths"] = { actions = { { type = "effect", sName = "Guardians of the Depths; RESIST: cold", sTargeting = "self" }, }, },
	["controlairandwater"] = {
		spell = {
			innate = { "Fog Cloud" },
			level = {
				[3] = { "Gust of Wind" },
				[5] = { "Wall of Water" },
			},
		},
	},
	-- Vedalken
	["partiallyamphibious"] = { actions = { { type = "effect", sName = "Partially Amphibious; Breathe underwater", sTargeting = "self", nDuration = 1, sUnits = "hour" }, }, },
	["tirelessprecision"] = { actions = { { type = "effect", sName = "Tireless Precision; SKILL: 1d4", sTargeting = "self", sApply = "roll" }, }, },
	["vedalkendispassion"] = { actions = { { type = "effect", sName = "Vedalken Dispassion; ADVSAV: intelligence,wisdom,charisma", sTargeting = "self", }, }, },
	-- Verdan
	["vedalkendispassion"] = { actions = { { type = "effect", sName = "Vedalken Dispassion; ADVSAV: intelligence,wisdom,charisma", sTargeting = "self", }, }, },
	["telepathicinsight"] = { actions = { { type = "effect", sName = "Telepathic Insight; ADVSAV: wisdom, charisma", sTargeting = "self", }, }, },
	["limitedtelepathy"] = { actions = { { type = "effect", sName = "Limited Telepathy 30 ft.", sTargeting = "self", }, }, },
	-- Warforged
	["integratedtool"] = { actions = { { type = "effect", sName = "Integrated Tool: ADVSKILL: ", sTargeting = "self" }, }, },
	["ironfists"] = { actions = { { type = "damage", clauses = { { dice = { "d4" }, dmgtype = "bludgeoning", stat = "strength" }, }, }, }, },
	["warforgedresilience"] = { actions = { { type = "effect", sName = "Warforged Resilience; RESIST: poison; Advantage against poison; Immune to disease and exhaustion; don't need sleep, food, drink, or air", sTargeting = "self" }, }, },
	["constructedresilience"] = { actions = { { type = "effect", sName = "Constructed Resilience; RESIST: poison; advantage on saves vs. poisoned, do not need to eat, drink, or breathe, or sleep, immune to disease, cannot be put to sleep by magic. ", sTargeting = "self" }, }, },
	["integratedprotection"] = { actions = { { type = "effect", sName = "Integrated Protection; AC: 1", sTargeting = "self" }, }, },
	-- Yuan-ti
	["yuantiinnatespellcasting"] = {
		spell = { innate = { "Poison Spray", "Animal Friendship" }, level = { [3] = { "Suggestion" }, }, },
	},
	["magicresistance"] = { actions = { { type = "effect", sName = "Yuan-ti Pureblood; Magic Resistance", sTargeting = "self" }, }, },
	["poisonimmunity"] = { actions = { { type = "effect", sName = "Poison Immunity; IMMUNE: poison,poisoned", sTargeting = "self" }, }, },
};

tBuildDataClass2024 = {
	-- Multiple
	["weaponmastery"] = {
		actions = {},
	},
	["extraattack"] = {
		actions = {},
	},

	-- Barbarian
	["rage"] = {
		actions = {
			{ type = "effect", sName = "Rage; ADVCHK: strength; ADVSAV: strength; DMG: 2; RESIST: bludgeoning, piercing, slashing", sTargeting = "self", nDuration = 10, sUnits = "minute", },
		},
		group = "Rage (Barbarian)",
		ability = "strength",
		prepared = 2,
	},
	["dangersense"] = {
		actions = {
			{ type = "effect", sName = "Danger Sense; ADVSAV: dexterity", sTargeting = "self" },
		},
	},
	["recklessattack"] = {
		actions = {
			{ type = "effect", sName = "Reckless Attack; ADVATK: melee; GRANTADVATK", sTargeting = "self", nDuration = 1, },
		},
	},
	["primalknowledge"] = {
		skill = { choice = 1, choice_skill = { "Animal Handling", "Athletics", "Intimidation", "Nature", "Perception", "Survival" }, },
	},
	["fastmovement"] = {
		addspeed = 10,
	},
	["feralinstinct"] = {
		actions = {
			{ type = "effect", sName = "Feral Instinct; ADVINIT", sTargeting = "self" },
		},
	},
	["relentlessrage"] = {
		actions = {
			{ type = "powersave", save = "constitution", savemod = 10, },
			{ type = "heal", sTargeting = "self", clauses = { { dice = {}, statmult = 2, stat = "barbarian" }, }, },
		},
		group = "Rage (Barbarian)",
		ability = "strength",
	},
	["brutalstrike"] = {
		actions = {
			{ type = "damage", clauses = { { dice = { "d10" }, dmgtype = "", }, }, },
		},
	},
	["persistentrage"] = {
		actions = {},
		group = "Rage (Barbarian)",
		ability = "strength",
	},
	-- Barbarian - Path of the Berserker
	["frenzy"] = {
		actions = {
			{ type = "effect", sName = "Frenzy; DMG: 2d6", sTargeting = "self", sApply = "action", nDuration = 1, },
		},
	},
	["mindlessrage"] = {
		actions = {
			{ type = "effect", sName = "Mindless Rage; IMMUNE: Charmed; IMMUNE: Frightened", sTargeting = "self", nDuration = 10, sUnits = "minute", },
		},
		group = "Rage (Barbarian)",
		ability = "strength",
	},
	["retaliation"] = {
		actions = {},
	},
	["intimidatingpresence"] = {
		actions = {
			{ type = "powersave", save = "wisdom", savestat = "strength", },
			{ type = "effect", sName = "Intimidating Presence; Frightened", nDuration = 1, sUnits = "minute", },
		},
		prepared = 1,
	},
	-- Barbarian - Path of the Wild Heart
	["animalspeaker"] = {
		spells = {
			{ name = "Beast Sense", ritual = true, },
			{ name = "Speak With Animals", ritual = true, },
			["group"] = "Spells (Barbarian)",
			["ability"] = "wisdom",
		},
	},
	["rageofthewilds"] = {
		multiple_actions = {
			["Rage of the Wilds (Bear)"] = {
				actions = {
					{ type = "effect", sName = "Rage of the Wilds (Bear); RESIST:all,!force,!necrotic,!psychic,!radiant", sTargeting = "self", nDuration = 10, sUnits = "minute", },
				},
				group = "Rage (Barbarian)",
				ability = "strength",
			},
			["Rage of the Wilds (Eagle)"] = {
				actions = {
					{ type = "effect", sName = "Rage of the Wilds (Eagle); Disengage; Dash", sTargeting = "self", nDuration = 1, },
				},
				group = "Rage (Barbarian)",
				ability = "strength",
			},
			["Rage of the Wilds (Wolf)"] = {
				actions = {
					{ type = "effect", sName = "Rage of the Wilds (Eagle); ADVATK", sApply="action", nDuration = 1, },
				},
				group = "Rage (Barbarian)",
				ability = "strength",
			},
		},
	},
	["aspectsofthewild"] = {
		multiple_actions = {
			["Aspects of the Wild (Owl)"] = {
				actions = {
					{ type = "effect", sName = "Aspects of the Wilds (Owl); VISION: 60 darkvision", sTargeting = "self", },
				},
			},
			["Aspects of the Wild (Panther)"] = {
				actions = {
					{ type = "effect", sName = "Aspects of the Wilds (Panther); Climb Speed", sTargeting = "self", },
				},
			},
			["Aspects of the Wild (Salmon)"] = {
				actions = {
					{ type = "effect", sName = "Aspects of the Wilds (Salmon); Swim Speed", sTargeting = "self", },
				},
			},
		},
	},
	["naturespeaker"] = {
		spells = {
			{ name = "Commune With Nature", ritual = true, },
			["group"] = "Spells (Barbarian)",
			["ability"] = "wisdom",
		},
	},
	["powerofthewilds"] = {
		multiple_actions = {
			["Power of the Wilds (Falcon)"] = {
				actions = {
					{ type = "effect", sName = "Power of the Wilds (Falcon); Fly Speed", sTargeting = "self", nDuration = 10, sUnits = "minute", },
				},
				group = "Rage (Barbarian)",
				ability = "strength",
			},
			["Power of the Wilds (Lion)"] = {
				actions = {
					{ type = "effect", sName = "Power of the Wilds (Lion); GRANTDISATK", sApply = "action", nDuration = 1, },
				},
				group = "Rage (Barbarian)",
				ability = "strength",
			},
			["Power of the Wilds (Ram)"] = {
				actions = {
					{ type = "effect", sName = "Power of the Wilds (Ram); Prone", },
				},
				group = "Rage (Barbarian)",
				ability = "strength",
			},
		},
	},
	-- Barbarian - Path of the World Tree
	["vitalityofthetree"] = {
		actions = {
			{ type = "heal", subtype = "temp", sTargeting = "self", clauses = { { dice = { }, stat = "barbarian", }, }, },
			{ type = "heal", subtype = "temp", clauses = { { dice = { "d6", "d6", }, }, }, },
		},
		group = "Rage (Barbarian)",
		ability = "strength",
	},
	["branchesofthetree"] = {
		actions = {
			{ type = "powersave", save = "strength", savestat = "base", },
			{ type = "effect", sName = "Branches of the Tree; Speed 0", nDuration = 1, },
		},
		group = "Rage (Barbarian)",
		ability = "strength",
	},
	["batteringroots"] = {
		actions = {},
	},
	["travelalongthetree"] = {
		actions = {},
		group = "Rage (Barbarian)",
		ability = "strength",
	},
	-- Barbarian - Path of the Zealot
	["divinefury"] = {
		actions = {
			{ type = "damage", clauses = { { dice = { "d6" }, statmult = 0.5, stat = "barbarian", dmgtype = "necrotic", }, }, },
			{ type = "damage", clauses = { { dice = { "d6" }, statmult = 0.5, stat = "barbarian", dmgtype = "radiant", }, }, },
		},
		group = "Rage (Barbarian)",
		ability = "strength",
	},
	["warriorofthegods"] = {
		actions = {
			{ type = "heal", sTargeting = "self", clauses = { { dice = { "d12" }, }, }, },
		},
		prepared = 4,
	},
	["fanaticalfocus"] = {
		actions = {},
		group = "Rage (Barbarian)",
		ability = "strength",
	},
	["zealouspresence"] = {
		actions = {
			{ type = "effect", sName = "Zealous Presence; ADVATK; ADVSAV", nDuration = 1, },
		},
		prepared = 1,
	},
	["rageofthegods"] = {
		actions = {
			{ type = "effect", sName = "Rage of the Gods; Fly Speed; RESIST: necrotic; RESIST: psychic; RESIST: radiant; ", sTargeting="self", nDuration = 1, sUnits = "minute", },
			{ type = "heal", clauses = { { dice = { }, stat="barbarian", }, }, },
		},
		prepared = 1,
		group = "Rage (Barbarian)",
		ability = "strength",
	},
	
	-- Bard
	["bardicinspiration"] = {
		actions = {
			{ type = "effect", sName = "Bardic Inspiration Die (Attack, Save, Check rolls)", nDuration = 1, sUnits = "hour" },
		},
		group = "Bardic Inspiration (Bard)",
		ability = "charisma",
		prepared = 1,
	},
	["fontofinspiration"] = {
		actions = {},
		group = "Bardic Inspiration (Bard)",
		ability = "charisma",
	},
	["countercharm"] = {
		actions = {
			{ type = "effect", sName = "Countercharm; Reroll failed Save vs. Frightened or Charmed with Advantage", nDuration = 1 },
		},
	},
	["superiorinspiration"] = {
		actions = {},
		group = "Bardic Inspiration (Bard)",
		ability = "charisma",
	},
	["wordsofcreation"] = {
		spells = {
			{ name = "Power Word Heal" },
			{ name = "Power Word Kill" },
			["group"] = "Spells (Bard)",
			["ability"] = "charisma",
		},
	},
	-- Bard - College of Dance
	["dazzlingfootwork"] = {
		multiple_actions = {
			["Dazzling Footwork (Dance Virtuoso)"] = {
				actions = {
					{ type = "effect", sName = "Dance Virtuoso; ADVSKILL: performance", sTargeting = "self", sApply = "roll", nDuration = 1 },
				},
			},
			["Agile Strikes"] = {
				actions = {},
				group = "Bardic Inspiration (Bard)",
				ability = "charisma",
			},
			["Dazzling Footwork (Bardic Damage)"] = {
				actions = {
					{ type = "damage", clauses = { { dice = { "d6" }, stat = "dexterity", dmgtype = "bludgeoning", }, }, },
				},
			},
		},
	},
	["inspiringmovement"] = {
		actions = {},
		group = "Bardic Inspiration (Bard)",
		ability = "charisma",
	},
	["tandemfootwork"] = {
		actions = {
			{ type = "effect", sName = "Tandem Footwork; ADVINIT", sApply = "roll", nDuration = 1 },
		},
		group = "Bardic Inspiration (Bard)",
		ability = "charisma",
	},
	["leadingevasion"] = {
		actions = {
			{ type = "effect", sName = "Evasion", sTargeting = "self" },
			{ type = "effect", sName = "Leading Evasion (Others); Evasion", sApply = "roll", nDuration = 1 },
		},
	},
	-- Bard - College of Glamour
	["beguilingmagic"] = {
		spells = {
			{ name = "Charm Person" },
			{ name = "Mirror Image" },
			["group"] = "Spells (Bard)",
			["ability"] = "charisma",
		},
		actions = {
			{ type = "powersave", save = "wisdom", savestat = "charisma", magic = true, },
			{ type = "effect", sName = "Charmed; NOTE: Save on end of round", nDuration = 1, sUnits = "minute" },
			{ type = "effect", sName = "Frightened; NOTE: Save on end of round", nDuration = 1, sUnits = "minute" },
		},
		prepared = 1,
	},
	["mantleofinspiration"] = {
		actions = {
			{ type = "heal", subtype = "temp", clauses = { { dice = { "d6", "d6" }, }, }, },
		},
		group = "Bardic Inspiration (Bard)",
		ability = "charisma",
	},
	["mantleofmajesty"] = {
		spells = {
			{ name = "Command" },
			["group"] = "Spells (Bard)",
			["ability"] = "charisma",
		},
		actions = {
			{ type = "effect", sName = "Mantle of Majesty; (C)", nDuration = 1, sUnits = "minute" },
		},
		prepared = 1,
	},
	["unbreakablemajesty"] = {
		actions = {
			{ type = "effect", sName = "Unbreakable Majesty", nDuration = 1, sUnits = "minute" },
			{ type = "powersave", save = "charisma", savestat = "charisma", magic = true, },
		},
		prepared = 1,
		usesperiod = "enc",
	},
	-- Bard - College of Lore
	["cuttingwords"] = {
		actions = {},
		group = "Bardic Inspiration (Bard)",
		ability = "charisma",
	},
	["peerlessskill"] = {
		actions = {},
		group = "Bardic Inspiration (Bard)",
		ability = "charisma",
	},
	-- Bard - College of Valor
	["combatinspiration"] = {
		actions = {
			{ type = "effect", sName = "Bardic Inspiration Die (Attack, Save, Check rolls, AC vs. Attack, Damage)", nDuration = 1, sUnits = "hour" },
		},
		group = "Bardic Inspiration (Bard)",
		ability = "charisma",
	},
	["martialtraining"] = {
		armorprof = { innate = { "Medium", "Shields", }, },
		weaponprof = { innate = { "Martial" }, },
	},
	["battlemagic"] = {
		actions = {},
	},

	-- Cleric
	["divineorder"] = {
		choicetype = "Divine Order",
		choicenum = 1,
		choiceskipadd = true,
	},
	["divineorderthaumaturge"] = {
		spells = {
			["list"] = "Cleric",
			["L0"] = 1,
			["group"] = "Spells (Cleric)",
			["ability"] = "wisdom",
		},
		actions = {
			{ type = "effect", sName = "Divine Order (Thaumaturge); SKILL: [WIS] arcana,religion", sTargeting = "self" },
		},
	},
	["divineorderprotector"] = {
		armorprof = { innate = { "Heavy" }, },
		weaponprof = { innate = { "Martial" }, },
	},
	["channeldivinitycleric"] = {
		multiple_actions = {
			["Channel Divinity"] = {
				actions = {},
				group = "Channel Divinity (Cleric)",
				ability = "wisdom",
				prepared = 2,
				usesperiod = "dual",
			},
			["Divine Spark"] = {
				actions = {
					{ type = "heal", clauses = { { dice = { "d8" }, stat = "wisdom" }, }, },
					{ type = "powersave", save = "constitution", savestat = "base", magic = true, onmissdamage = "half", },
					{ type = "damage", clauses = { { dice = { "d8" }, stat = "wisdom", dmgtype = "necrotic", }, }, },
					{ type = "damage", clauses = { { dice = { "d8" }, stat = "wisdom", dmgtype = "radiant", }, }, },
				},
				group = "Channel Divinity (Cleric)",
				ability = "wisdom",
			},
			["Turn Undead"] = {
				actions = {
					{ type = "powersave", save = "wisdom", savestat = "base", magic = true, },
					{ type = "effect", sName = "Channel Divinity (Turn Undead); Frightened; Incapacitated", nDuration = 1, sUnits = "minute", },
				},
				group = "Channel Divinity (Cleric)",
				ability = "wisdom",
			},
		},
	},
	["searundead"] = {
		actions = {
			{ type = "damage", clauses = { { dice = { "d8" }, dmgtype = "radiant", }, }, },
		},
		group = "Channel Divinity (Cleric)",
		ability = "wisdom",
	},
	["blessedstrikes"] = {
		choicetype = "Blessed Strikes",
		choicenum = 1,
		choiceskipadd = true,
	},
	["blessedstrikesdivinestrike"] = {
		multiple_actions = {
			["Divine Strike"] = {
				actions = {
					{ type = "effect", sName = "Divine Strike; DMG: 1d8 necrotic", sTargeting = "self", sApply = "roll", nDuration = 1, },
					{ type = "effect", sName = "Divine Strike; DMG: 1d8 radiant", sTargeting = "self", sApply = "roll", nDuration = 1, },
				},
			},
		},
	},
	["blessedstrikespotentspellcasting"] = {
		multiple_actions = {
			["Potent Spellcasting"] = {
				actions = {
					{ type = "effect", sName = "Potent Spellcasting; DMGS: [WIS]", sTargeting = "self", sApply = "roll", nDuration = 1, },
				},
			},
		},
	},
	["divineintervention"] = {
		actions = {},
		prepared = 1,
	},
	["improvedblessedstrikes"] = {
		followon = {
			["Blessed Strikes (Divine Strike)"] = { choicetype = "Improved Blessed Strikes", name = "Divine Strike", },
			["Blessed Strikes (Potent Spellcasting)"] = { choicetype = "Improved Blessed Strikes", name = "Potent Spellcasting", },
		};
	},
	["improvedblessedstrikesdivinestrike"] = {
		multiple_actions = {
			["Divine Strike (Improved)"] = {
				actions = {
					{ type = "effect", sName = "Divine Strike (Improved); DMG: 2d8 necrotic", sTargeting = "self", sApply = "roll", nDuration = 1, },
					{ type = "effect", sName = "Divine Strike (Improved); DMG: 2d8 radiant", sTargeting = "self", sApply = "roll", nDuration = 1, },
				},
			},
		},
	},
	["improvedblessedstrikespotentspellcasting"] = {
		multiple_actions = {
			["Potent Spellcasting (Improved)"] = {
				actions = {
					{ type = "heal", subtype = "temp", clauses = { { statmult = 2, stat = "wisdom" }, }, },
				},
			},
		},
	},
	["greaterdivineintervention"] = {
		actions = {},
		prepared = 1,
		usesperiod = "once",
	},
	-- Cleric - Life Domain
	["discipleoflife"] = {
		actions = {
			{ type = "heal", clauses = { { bonus = 3 }, }, },
			{ type = "heal", clauses = { { bonus = 4 }, }, },
			{ type = "heal", clauses = { { bonus = 5 }, }, },
			{ type = "heal", clauses = { { bonus = 6 }, }, },
			{ type = "heal", clauses = { { bonus = 7 }, }, },
			{ type = "heal", clauses = { { bonus = 8 }, }, },
			{ type = "heal", clauses = { { bonus = 9 }, }, },
			{ type = "heal", clauses = { { bonus = 10 }, }, },
			{ type = "heal", clauses = { { bonus = 11 }, }, },
		},
	},
	["lifedomainspells"] = {
		spells = {
			{ name = "Aid" },
			{ name = "Bless" },
			{ name = "Cure Wounds" },
			{ name = "Lesser Restoration" },
			["group"] = "Spells (Cleric)",
			["ability"] = "wisdom",
		},
	},
	["lifedomainspellsl5"] = {
		spells = {
			{ name = "Mass Healing Word" },
			{ name = "Revivify" },
			["group"] = "Spells (Cleric)",
			["ability"] = "wisdom",
		},
	},
	["lifedomainspellsl7"] = {
		spells = {
			{ name = "Aura of Life" },
			{ name = "Death Ward" },
			["group"] = "Spells (Cleric)",
			["ability"] = "wisdom",
		},
	},
	["lifedomainspellsl9"] = {
		spells = {
			{ name = "Greater Restoration" },
			{ name = "Mass Cure Wounds" },
			["group"] = "Spells (Cleric)",
			["ability"] = "wisdom",
		},
	},
	["preservelife"] = {
		actions = {
			{ type = "heal", clauses = { { statmult = 5, stat = "cleric" }, }, },
		},
		group = "Channel Divinity (Cleric)",
		ability = "wisdom",
	},
	["blessedhealer"] = {
		actions = {
			{ type = "heal", sTargeting = "self", clauses = { { bonus = 3 }, }, },
			{ type = "heal", sTargeting = "self", clauses = { { bonus = 4 }, }, },
			{ type = "heal", sTargeting = "self", clauses = { { bonus = 5 }, }, },
			{ type = "heal", sTargeting = "self", clauses = { { bonus = 6 }, }, },
			{ type = "heal", sTargeting = "self", clauses = { { bonus = 7 }, }, },
			{ type = "heal", sTargeting = "self", clauses = { { bonus = 8 }, }, },
			{ type = "heal", sTargeting = "self", clauses = { { bonus = 9 }, }, },
			{ type = "heal", sTargeting = "self", clauses = { { bonus = 10 }, }, },
			{ type = "heal", sTargeting = "self", clauses = { { bonus = 11 }, }, },
		},
	},
	["supremehealer"] = {
		actions = {},
	},
	-- Cleric - Light Domain
	["lightdomainspells"] = {
		spells = {
			{ name = "Burning Hands" },
			{ name = "Faerie Fire" },
			{ name = "Scorching Ray" },
			{ name = "See Invisibility" },
			["group"] = "Spells (Cleric)",
			["ability"] = "wisdom",
		},
	},
	["lightdomainspellsl5"] = {
		spells = {
			{ name = "Daylight" },
			{ name = "Fireball" },
			["group"] = "Spells (Cleric)",
			["ability"] = "wisdom",
		},
	},
	["lightdomainspellsl7"] = {
		spells = {
			{ name = "Arcane Eye" },
			{ name = "Wall of Fire" },
			["group"] = "Spells (Cleric)",
			["ability"] = "wisdom",
		},
	},
	["lightdomainspellsl9"] = {
		spells = {
			{ name = "Flame Strike" },
			{ name = "Scrying" },
			["group"] = "Spells (Cleric)",
			["ability"] = "wisdom",
		},
	},
	["radianceofthedawn"] = {
		actions = {
			{ type = "powersave", save = "constitution", savestat = "base", magic = true, onmissdamage = "half", },
			{ type = "damage", clauses = { { dice = { "d10", "d10" }, stat = "cleric", dmgtype = "radiant", }, }, },
		},
		group = "Channel Divinity (Cleric)",
		ability = "wisdom",
	},
	["wardingflare"] = {
		actions = {
			{ type = "effect", sName = "Warding Flare; DISATK", sApply = "roll", nDuration = 1, },
		},
		prepared = 1,
	},
	["improvedwardingflare"] = {
		multiple_actions = {
			["Warding Flare (Improved)"] = {
				actions = {
					{ type = "heal", subtype = "temp", clauses = { { dice = { "d6", "d6" }, stat = "wisdom" }, }, },
				},
			},
		},
	},
	["coronaoflight"] = {
		actions = {
			{ type = "effect", sName = "Corona of Light; LIGHT: 60/90 light", nDuration = 1, sUnits = "minute", },
			{ type = "effect", sName = "Corona of Light (Save DIS vs Fire/Radiant); DISSAV", sApply = "roll", nDuration = 1 },
		},
		prepared = 1,
	},
	-- Cleric - Trickery Domain
	["blessingofthetrickster"] = {
		actions = {
			{ type = "effect", sName = "Blessing of the Trickster; ADVSKILL: stealth", nDuration = 24, sUnits = "hour", },
		},
	},
	["invokeduplicity"] = {
		actions = {
			{ type = "effect", sName = "Invoke Duplicity", sTargeting = "self", nDuration = 1, sUnits = "minute", },
			{ type = "effect", sName = "Invoke Duplicity (Distract); ADVATK", sTargeting = "self", sApply = "roll", nDuration = 1 },
		},
		group = "Channel Divinity (Cleric)",
		ability = "wisdom",
	},
	["trickerydomainspells"] = {
		spells = {
			{ name = "Charm Person" },
			{ name = "Disguise Self" },
			{ name = "Invisibility" },
			{ name = "Pass without Trace" },
			["group"] = "Spells (Cleric)",
			["ability"] = "wisdom",
		},
	},
	["trickerydomainspellsl5"] = {
		spells = {
			{ name = "Hypnotic Pattern" },
			{ name = "Nondetection" },
			["group"] = "Spells (Cleric)",
			["ability"] = "wisdom",
		},
	},
	["trickerydomainspellsl7"] = {
		spells = {
			{ name = "Confusion" },
			{ name = "Dimension Door" },
			["group"] = "Spells (Cleric)",
			["ability"] = "wisdom",
		},
	},
	["trickerydomainspellsl9"] = {
		spells = {
			{ name = "Dominate Person" },
			{ name = "Modify Memory" },
			["group"] = "Spells (Cleric)",
			["ability"] = "wisdom",
		},
	},
	["tricksterstransposition"] = {
		multiple_actions = {
			["Invoke Duplicity (Transposition)"] = {
				actions = {},
				group = "Channel Divinity (Cleric)",
				ability = "wisdom",
			},
		},
	},
	["improvedduplicity"] = {
		multiple_actions = {
			["Invoke Duplicity (Improved)"] = {
				actions = {
					{ type = "effect", sName = "Improved Duplicity (Shared Distraction); ADVATK", sApply = "roll", nDuration = 1 },
					{ type = "heal", clauses = { { stat = "cleric" }, }, },
				},
				group = "Channel Divinity (Cleric)",
				ability = "wisdom",
			},
		},
	},
	-- Cleric - War Domain
	["guidedstrike"] = {
		actions = {},
		group = "Channel Divinity (Cleric)",
		ability = "wisdom",
	},
	["wardomainspells"] = {
		spells = {
			{ name = "Guiding Bolt" },
			{ name = "Magic Weapon" },
			{ name = "Shield of Faith" },
			{ name = "Spiritual Weapon" },
			["group"] = "Spells (Cleric)",
			["ability"] = "wisdom",
		},
	},
	["wardomainspellsl5"] = {
		spells = {
			{ name = "Crusader's Mantle" },
			{ name = "Spirit Guardians" },
			["group"] = "Spells (Cleric)",
			["ability"] = "wisdom",
		},
	},
	["wardomainspellsl7"] = {
		spells = {
			{ name = "Fire Shield" },
			{ name = "Freedom of Movement" },
			["group"] = "Spells (Cleric)",
			["ability"] = "wisdom",
		},
	},
	["wardomainspellsl9"] = {
		spells = {
			{ name = "Hold Monster" },
			{ name = "Steel Wind Strike" },
			["group"] = "Spells (Cleric)",
			["ability"] = "wisdom",
		},
	},
	["wargodsblessing"] = {
		actions = {},
		group = "Channel Divinity (Cleric)",
		ability = "wisdom",
	},
	["avatarofbattle"] = {
		actions = {
			{ type = "effect", sName = "Avatar of Battle; RESIST: bludgeoning,piercing,slashing", sTargeting = "self", },
		},
	},

	-- Druid
	["primalorder"] = {
		choicetype = "Primal Order",
		choicenum = 1,
		choiceskipadd = true,
	},
	["primalordermagician"] = {
		spells = {
			["list"] = "Druid",
			["L0"] = 1,
			["group"] = "Spells (Druid)",
			["ability"] = "wisdom",
		},
		actions = {
			{ type = "effect", sName = "Primal Order (Magician); SKILL: [WIS] arcana,nature", sTargeting = "self" },
		},
	},
	["primalorderwarden"] = {
		armorprof = { innate = { "Medium" }, },
		weaponprof = { innate = { "Martial" }, },
	},
	["wildshape"] = {
		actions = {},
		group = "Wild Shape (Druid)",
		ability = "wisdom",
		prepared = 2,
		usesperiod = "dual",
	},
	["wildcompanion"] = {
		actions = {},
	},
	["wildresurgence"] = {
		multiple_actions = {
			["Wild Resurgence (Spell Slot to Wild Shape)"] = {
				actions = {},
			},
			["Wild Resurgence (Wild Shape to L1 Spell Slot)"] = {
				actions = {},
				prepared = 1,
			},
		},
	},
	["elementalfury"] = {
		choicetype = "Elemental Fury",
		choicenum = 1,
		choiceskipadd = true,
	},
	["elementalfuryprimalstrike"] = {
		multiple_actions = {
			["Primal Strike"] = {
				actions = {
					{ type = "effect", sName = "Primal Strike; DMG: 1d8 cold", sTargeting = "self", sApply = "roll", nDuration = 1, },
					{ type = "effect", sName = "Primal Strike; DMG: 1d8 fire", sTargeting = "self", sApply = "roll", nDuration = 1, },
					{ type = "effect", sName = "Primal Strike; DMG: 1d8 lightning", sTargeting = "self", sApply = "roll", nDuration = 1, },
					{ type = "effect", sName = "Primal Strike; DMG: 1d8 thunder", sTargeting = "self", sApply = "roll", nDuration = 1, },
				},
			},
		},
	},
	["elementalfurypotentspellcasting"] = {
		multiple_actions = {
			["Potent Spellcasting"] = {
				actions = {
					{ type = "effect", sName = "Potent Spellcasting; DMGS: [WIS]", sTargeting = "self", sApply = "roll", nDuration = 1, },
				},
			},
		},
	},
	["communewithnature"] = {
		spells = {
			{ name = "Commune With Nature" },
			["group"] = "Spells (Druid)",
			["ability"] = "wisdom",
		},
	},
	["improvedelementalfury"] = {
		followon = {
			["Elemental Fury (Primal Strike)"] = { choicetype = "Improved Elemental Fury", name = "Primal Strike", },
			["Elemental Fury (Potent Spellcasting)"] = { choicetype = "Improved Elemental Fury", name = "Potent Spellcasting", },
		};
	},
	["improvedelementalfuryprimalstrike"] = {
		multiple_actions = {
			["Primal Strike (Improved)"] = {
				actions = {
					{ type = "effect", sName = "Primal Strike (Improved); DMG: 2d8 cold", sTargeting = "self", sApply = "roll", nDuration = 1, },
					{ type = "effect", sName = "Primal Strike (Improved); DMG: 2d8 fire", sTargeting = "self", sApply = "roll", nDuration = 1, },
					{ type = "effect", sName = "Primal Strike (Improved); DMG: 2d8 lightning", sTargeting = "self", sApply = "roll", nDuration = 1, },
					{ type = "effect", sName = "Primal Strike (Improved); DMG: 2d8 thunder", sTargeting = "self", sApply = "roll", nDuration = 1, },
				},
			},
		},
	},
	["improvedelementalfurypotentspellcasting"] = {
		multiple_actions = {
			["Potent Spellcasting (Improved)"] = {
				actions = {},
			},
		},
	},
	["beastspells"] = {
		actions = {},
		group = "Wild Shape (Druid)",
		ability = "wisdom",
	},
	["archdruid"] = {
		multiple_actions = {
			["Wild Shape (Archdruid) (Evergreen)"] = {
				actions = {},
				group = "Wild Shape (Druid)",
				ability = "wisdom",
			},
			["Wild Shape (Archdruid) (Nature Magician)"] = {
				actions = {},
				group = "Wild Shape (Druid)",
				ability = "wisdom",
				prepared = 1,
			},
		},
	},
	-- Druid - Circle of the Land
	["circleofthelandspells"] = {
		spells = {
			{ name = "Blur" },
			{ name = "Burning Hands" },
			{ name = "Fire Bolt" },
			{ name = "Fog Cloud" },
			{ name = "Hold Person" },
			{ name = "Ray of Frost" },
			{ name = "Misty Step" },
			{ name = "Shocking Grasp" },
			{ name = "Sleep" },
			{ name = "Acid Splash" },
			{ name = "Ray of Sickness" },
			{ name = "Web" },
			["group"] = "Spells (Druid)",
			["ability"] = "wisdom",
		},
	},
	["circleofthelandspellsl5"] = {
		spells = {
			{ name = "Fireball" },
			{ name = "Sleet Storm" },
			{ name = "Lightning Bolt" },
			{ name = "Stinking Cloud" },
			["group"] = "Spells (Druid)",
			["ability"] = "wisdom",
		},
	},
	["circleofthelandspellsl7"] = {
		spells = {
			{ name = "Blight" },
			{ name = "Ice Storm" },
			{ name = "Freedom of Movement" },
			{ name = "Polymorph" },
			["group"] = "Spells (Druid)",
			["ability"] = "wisdom",
		},
	},
	["circleofthelandspellsl9"] = {
		spells = {
			{ name = "Wall of Stone" },
			{ name = "Cone of Cold" },
			{ name = "Tree Stride" },
			{ name = "Insect Plague" },
			["group"] = "Spells (Druid)",
			["ability"] = "wisdom",
		},
	},
	["landsaid"] = {
		actions = {
			{ type = "powersave", save = "constitution", savestat = "base", magic = true, onmissdamage = "half", },
			{ type = "damage", clauses = { { dice = { "d6", "d6" }, dmgtype = "necrotic", }, }, },
			{ type = "heal", clauses = { { dice = { "d6", "d6" }, }, }, },
		},
		group = "Wild Shape (Druid)",
		ability = "wisdom",
	},
	["naturalrecovery"] = {
		multiple_actions = {
			["Natural Recovery (Circle Spell Cast)"] = {
				actions = {},
				prepared = 1,
			},
			["Natural Recovery (Spell Slot Recovery)"] = {
				actions = {},
				prepared = 1,
			},
		},
	},
	["naturesward"] = {
		actions = {
			{ type = "effect", sName = "Nature's Ward (Arid); IMMUNE: Poisoned; RESIST: fire", sTargeting = "self" },
			{ type = "effect", sName = "Nature's Ward (Polar); IMMUNE: Poisoned; RESIST: cold", sTargeting = "self" },
			{ type = "effect", sName = "Nature's Ward (Temperate); IMMUNE: Poisoned; RESIST: lightning", sTargeting = "self" },
			{ type = "effect", sName = "Nature's Ward (Tropical); IMMUNE: Poisoned; RESIST: poison", sTargeting = "self" },
		},
	},
	["naturessanctuary"] = {
		actions = {
			{ type = "effect", sName = "Nature's Sanctuary", nDuration = 1, sUnits = "minute" },
			{ type = "effect", sName = "COVER", nDuration = 1, sUnits = "minute" },
		},
	},
	-- Druid - Circle of the Moon
	["circleforms"] = {
		actions = {
			{ type = "effect", sName = "AC: 3 [WIS]", },
			{ type = "heal", subtype = "temp", clauses = { { statmult = 3, stat = "druid", }, }, },
		},
		group = "Wild Shape (Druid)",
		ability = "wisdom",
	},
	["circleofthemoonspells"] = {
		spells = {
			{ name = "Cure Wounds" },
			{ name = "Moonbeam" },
			{ name = "Starry Wisp" },
			["group"] = "Spells (Druid)",
			["ability"] = "wisdom",
		},
		actions = {},
		group = "Wild Shape (Druid)",
		ability = "wisdom",
	},
	["circleofthemoonspellsl5"] = {
		spells = {
			{ name = "Conjure Animals" },
			["group"] = "Spells (Druid)",
			["ability"] = "wisdom",
		},
	},
	["circleofthemoonspellsl7"] = {
		spells = {
			{ name = "Fount of Moonlight" },
			["group"] = "Spells (Druid)",
			["ability"] = "wisdom",
		},
	},
	["circleofthemoonspellsl9"] = {
		spells = {
			{ name = "Mass Cure Wounds" },
			["group"] = "Spells (Druid)",
			["ability"] = "wisdom",
		},
	},
	["improvedcircleforms"] = {
		multiple_actions = {
			["Lunar Radiance"] = {
				actions = {
					{ type = "effect", sName = "DMGTYPE: radiant", },
				},
				group = "Wild Shape (Druid)",
				ability = "wisdom",
			},
			["Increased Toughness"] = {
				actions = {
					{ type = "effect", sName = "SAVE: [WIS] constitution", },
				},
				group = "Wild Shape (Druid)",
				ability = "wisdom",
			},
		},
	},
	["moonlightstep"] = {
		actions = {
			{ type = "effect", sName = "ADVATK", sTargeting = "self", sApply = "roll", },
		},
		prepared = 1,
	},
	["lunarform"] = {
		multiple_actions = {
			["Lunar Radiance (Improved)"] = {
				actions = {
					{ type = "effect", sName = "DMG: 2d10 radiant", },
				},
				group = "Wild Shape (Druid)",
				ability = "wisdom",
			},
			["Moonlight Step (Shared Moonlight)"] = {
				actions = {},
			},
		},
	},
	-- Druid - Circle of the Sea
	["circleoftheseaspells"] = {
		spells = {
			{ name = "Fog Cloud" },
			{ name = "Gust of Wind" },
			{ name = "Ray of Frost" },
			{ name = "Shatter" },
			{ name = "Thunderwave" },
			["group"] = "Spells (Druid)",
			["ability"] = "wisdom",
		},
	},
	["circleoftheseaspellsl5"] = {
		spells = {
			{ name = "Lightning Bolt" },
			{ name = "Water Breathing" },
			["group"] = "Spells (Druid)",
			["ability"] = "wisdom",
		},
	},
	["circleoftheseaspellsl7"] = {
		spells = {
			{ name = "Control Water" },
			{ name = "Ice Storm" },
			["group"] = "Spells (Druid)",
			["ability"] = "wisdom",
		},
	},
	["circleoftheseaspellsl9"] = {
		spells = {
			{ name = "Conjure Elemental" },
			{ name = "Hold Monster" },
			["group"] = "Spells (Druid)",
			["ability"] = "wisdom",
		},
	},
	["wrathofthesea"] = {
		actions = {
			{ type = "effect", sName = "Wrath of the Sea", nDuration = 10, sUnits = "minute" },
			{ type = "powersave", save = "constitution", savestat = "base", magic = true, onmissdamage = "half", },
			{ type = "damage", clauses = { { dice = { "d6" }, dmgtype = "cold" }, }, },
		},
		group = "Wild Shape (Druid)",
		ability = "wisdom",
	},
	["aquaticaffinity"] = {
		multiple_actions = {
			["Wrath of the Sea (+10 ft.) "] = {
				actions = {},
				group = "Wild Shape (Druid)",
				ability = "wisdom",
			},
			["Aquatic Affinity"] = {
				actions = {
					{ type = "effect", sName = "Swim Speed", },
				},
			},
		},
	},
	["stormborn"] = {
		multiple_actions = {
			["Wrath of the Sea (Stormborn) "] = {
				actions = {
					{ type = "effect", sName = "Fly Speed; RESIST: cold,lightning,thunder", },
				},
				group = "Wild Shape (Druid)",
				ability = "wisdom",
			},
		},
	},
	["oceanicgift"] = {
		multiple_actions = {
			["Wrath of the Sea (Oceanic Gift) "] = {
				actions = {},
				group = "Wild Shape (Druid)",
				ability = "wisdom",
			},
		},
	},
	-- Druid - Circle of the Stars
	["starmap"] = {
		spells = {
			{ name = "Guidance" },
			{ name = "Guiding Bolt" },
			["group"] = "Spells (Druid)",
			["ability"] = "wisdom",
		},
		multiple_actions = {
			["Star Map (Guiding Bolt) "] = {
				actions = {},
				prepared = 1,
			},
		},
	},
	["starryform"] = {
		multiple_actions = {
			["Starry Form"] = {
				actions = {
					{ type = "effect", sName = "Starry Form; LIGHT: 10 light", nDuration = 10, sUnits="minute" },
				},
				group = "Wild Shape (Druid)",
				ability = "wisdom",
			},
			["Starry Form (Archer)"] = {
				actions = {
					{ type = "attack", range = "R", },
					{ type = "damage", clauses = { { dice = { "d8" }, dmgtype = "radiant", stat = "wisdom" }, }, },
				},
				group = "Wild Shape (Druid)",
				ability = "wisdom",
			},
			["Starry Form (Chalice)"] = {
				actions = {
					{ type = "heal", clauses = { { dice = { "d8" }, stat = "wisdom" }, }, },
				},
				group = "Wild Shape (Druid)",
				ability = "wisdom",
			},
			["Starry Form (Dragon)"] = {
				actions = {
					{ type = "effect", sName = "RELIABLECONC; RELIABLESAV: intelligence,wisdom", nDuration = 10, sUnits="minute" },
				},
				group = "Wild Shape (Druid)",
				ability = "wisdom",
			},
		},
	},
	["cosmicomen"] = {
		actions = {
			{ type = "effect", sName = "Cosmic Omen (Weal); ADVATK; ADVCHK; ADVSAV", sApply = "roll", nDuration = 1 },
			{ type = "effect", sName = "Cosmic Omen (Woe); DISATK; DISCHK; DISSAV", sApply = "roll", nDuration = 1 },
		},
		prepared = 1,
	},
	["twinklingconstellations"] = {
		multiple_actions = {
			["Starry Form (Archer) (Improved)"] = {
				actions = {
					{ type = "attack", range = "R", },
					{ type = "damage", clauses = { { dice = { "d8", "d8" }, dmgtype = "radiant", stat = "wisdom" }, }, },
				},
				group = "Wild Shape (Druid)",
				ability = "wisdom",
			},
			["Starry Form (Chalice) (Improved)"] = {
				actions = {
					{ type = "heal", clauses = { { dice = { "d8", "d8" }, stat = "wisdom" }, }, },
				},
				group = "Wild Shape (Druid)",
				ability = "wisdom",
			},
			["Starry Form (Dragon) (Improved)"] = {
				actions = {
					{ type = "effect", sName = "Fly Speed 20; Hover", nDuration = 10, sUnits="minute" },
				},
				group = "Wild Shape (Druid)",
				ability = "wisdom",
			},
		},
	},
	["fullofstars"] = {
		multiple_actions = {
			["Starry Form (Full of Stars)"] = {
				actions = {
					{ type = "effect", sName = "RESIST: bludgeoning,piercing,slashing", nDuration = 10, sUnits="minute" },
				},
				group = "Wild Shape (Druid)",
				ability = "wisdom",
			},
		},
	},

	-- Fighter
	["secondwind"] = {
		actions = {
			{ type = "heal", sTargeting = "self", clauses = { { dice = { "d10" }, stat = "fighter" }, }, },
		},
		group = "Second Wind (Fighter)",
		ability = "strength",
		prepared = 2,
		usesperiod = "dual",
	},
	["actionsurge"] = {
		actions = {},
		prepared = 1,
		usesperiod = "enc",
	},
	["tacticalmind"] = {
		actions = {},
		group = "Second Wind (Fighter)",
		ability = "strength",
	},
	["tacticalshift"] = {
		actions = {},
		group = "Second Wind (Fighter)",
		ability = "strength",
	},
	["indomitable"] = {
		actions = {
			{ type = "effect", sName = "SAVE: [FIGHTER]", sTargeting = "self", sApply = "roll", nDuration = 1, },
		},
		prepared = 1,
	},
	["tacticalmaster"] = {
		multiple_actions = {
			["Weapon Mastery (Tactical Master)"] = {
				actions = {},
			},
		},
	},
	["twoextraattacks"] = {
		actions = {},
	},
	["studiedattacks"] = {
		actions = {
			{ type = "effect", sName = "[TRGT]; ADVATK", sTargeting = "self", sApply = "roll", nDuration = 1, },
		},
		prepared = 1,
	},
	["threeextraattacks"] = {
		actions = {},
	},
	-- Fighter - Battle Master
	["combatsuperiority"] = {
		multiple_actions = {
			["Superiority Dice"] = {
				actions = {},
				group = "Combat Superiority (Fighter)",
				ability = "strength",
				prepared = 4,
				usesperiod = "enc",
			},
		},
		choicetype = "Maneuver",
		choicenum = 4,
	},
	["extramaneuvers"] = {
		choicetype = "Maneuver",
		choicenum = 2,
		choiceskipadd = true,
	},
	["knowyourenemy"] = {
		actions = {},
		prepared = 1,
	},
	["improvedcombatsuperiority"] = {
		actions = {},
		group = "Combat Superiority (Fighter)",
		ability = "strength",
	},
	["relentless"] = {
		actions = {},
		group = "Combat Superiority (Fighter)",
		ability = "strength",
	},
	["ultimatecombatsuperiority"] = {
		actions = {},
		group = "Combat Superiority (Fighter)",
		ability = "strength",
	},
	["maneuverambush"] = {
		multiple_actions = {
			["Ambush"] = {
				actions = {
					{ type = "effect", sName = "INIT: d8; SKILL: d8 stealth", sTargeting = "self", sApply = "roll", nDuration = 1, },
				},
				group = "Combat Superiority (Fighter)",
				ability = "strength",
			},
		},
	},
	["maneuverbaitandswitch"] = {
		multiple_actions = {
			["Bait and Switch"] = {
				actions = {
					{ type = "effect", sName = "AC: d8", nDuration = 1, },
				},
				group = "Combat Superiority (Fighter)",
				ability = "strength",
			},
		},
	},
	["maneuvercommandersstrike"] = {
		multiple_actions = {
			["Commander's Strike"] = {
				actions = {
					{ type = "effect", sName = "DMG: d8", sApply = "roll", nDuration = 1, },
				},
				group = "Combat Superiority (Fighter)",
				ability = "strength",
			},
		},
	},
	["maneuvercommandingpresence"] = {
		multiple_actions = {
			["Commanding Presence"] = {
				actions = {
					{ type = "effect", sName = "SKILL: d8 intimidation,performance,persuasion", sTargeting = "self", sApply = "roll", nDuration = 1, },
				},
				group = "Combat Superiority (Fighter)",
				ability = "strength",
			},
		},
	},
	["maneuverdisarmingattack"] = {
		multiple_actions = {
			["Disarming Attack"] = {
				actions = {
					{ type = "effect", sName = "DMG: d8", sTargeting = "self", sApply = "roll", nDuration = 1, },
					{ type = "powersave", save = "strength", savestat = "base", },
				},
				group = "Combat Superiority (Fighter)",
				ability = "strength",
			},
		},
	},
	["maneuverdistractingstrike"] = {
		multiple_actions = {
			["Distracting Strike"] = {
				actions = {
					{ type = "effect", sName = "DMG: d8", sTargeting = "self", sApply = "roll", nDuration = 1, },
					{ type = "effect", sName = "[TRGT]; GRANTADVATK", sApply = "roll", nDuration = 1, },
				},
				group = "Combat Superiority (Fighter)",
				ability = "strength",
			},
		},
	},
	["maneuverevasivefootwork"] = {
		multiple_actions = {
			["Evasive Footwork"] = {
				actions = {
					{ type = "effect", sName = "Disengage; AC: d8", sTargeting = "self", sApply = "roll", nDuration = 1, },
				},
				group = "Combat Superiority (Fighter)",
				ability = "strength",
			},
		},
	},
	["maneuverfeintingattack"] = {
		multiple_actions = {
			["Feinting Attack"] = {
				actions = {
					{ type = "effect", sName = "ADVATK", sTargeting = "self", sApply = "roll", nDuration = 1, },
					{ type = "effect", sName = "DMG: d8", sTargeting = "self", sApply = "roll", nDuration = 1, },
				},
				group = "Combat Superiority (Fighter)",
				ability = "strength",
			},
		},
	},
	["maneuvergoadingattack"] = {
		multiple_actions = {
			["Goading Attack"] = {
				actions = {
					{ type = "effect", sName = "DMG: d8", sTargeting = "self", sApply = "roll", nDuration = 1, },
					{ type = "powersave", save = "wisdom", savestat = "base", },
					{ type = "effect", sName = "[TRGT]; DISATK", nDuration = 1, },
				},
				group = "Combat Superiority (Fighter)",
				ability = "strength",
			},
		},
	},
	["maneuverlungingattack"] = {
		multiple_actions = {
			["Lunging Attack"] = {
				actions = {
					{ type = "effect", sName = "Dash", sTargeting = "self", nDuration = 1, },
					{ type = "effect", sName = "DMG: d8", sTargeting = "self", sApply = "roll", nDuration = 1, },
				},
				group = "Combat Superiority (Fighter)",
				ability = "strength",
			},
		},
	},
	["maneuvermaneuveringattack"] = {
		multiple_actions = {
			["Maneuvering Attack"] = {
				actions = {
					{ type = "effect", sName = "DMG: d8", sTargeting = "self", sApply = "roll", nDuration = 1, },
				},
				group = "Combat Superiority (Fighter)",
				ability = "strength",
			},
		},
	},
	["maneuvermenacingattack"] = {
		multiple_actions = {
			["Menacing Attack"] = {
				actions = {
					{ type = "effect", sName = "DMG: d8", sTargeting = "self", sApply = "roll", nDuration = 1, },
					{ type = "powersave", save = "wisdom", savestat = "base", },
					{ type = "effect", sName = "Frightened", nDuration = 1, },
				},
				group = "Combat Superiority (Fighter)",
				ability = "strength",
			},
		},
	},
	["maneuverparry"] = {
		multiple_actions = {
			["Parry"] = {
				actions = {
					{ type = "effect", sName = "RESIST: d8 [STR]", sTargeting = "self", sApply = "roll", nDuration = 1, },
					{ type = "effect", sName = "RESIST: d8 [DEX]", sTargeting = "self", sApply = "roll", nDuration = 1, },
				},
				group = "Combat Superiority (Fighter)",
				ability = "strength",
			},
		},
	},
	["maneuverprecisionattack"] = {
		multiple_actions = {
			["Precision Attack"] = {
				actions = {
					{ type = "effect", sName = "ATK: d8", sTargeting = "self", sApply = "roll", nDuration = 1, },
				},
				group = "Combat Superiority (Fighter)",
				ability = "strength",
			},
		},
	},
	["maneuverpushingattack"] = {
		multiple_actions = {
			["Pushing Attack"] = {
				actions = {
					{ type = "effect", sName = "DMG: d8", sTargeting = "self", sApply = "roll", nDuration = 1, },
					{ type = "powersave", save = "strength", savestat = "base", },
				},
				group = "Combat Superiority (Fighter)",
				ability = "strength",
			},
		},
	},
	["maneuverrally"] = {
		multiple_actions = {
			["Rally"] = {
				actions = {
					{ type = "heal", clauses = { { dice = { "d8" }, statmult = 0.5, stat = "fighter" }, }, },
				},
				group = "Combat Superiority (Fighter)",
				ability = "strength",
			},
		},
	},
	["maneuverriposte"] = {
		multiple_actions = {
			["Riposte"] = {
				actions = {
					{ type = "effect", sName = "DMG: d8", sTargeting = "self", sApply = "roll", nDuration = 1, },
				},
				group = "Combat Superiority (Fighter)",
				ability = "strength",
			},
		},
	},
	["maneuversweepingattack"] = {
		multiple_actions = {
			["Sweeping Attack"] = {
				actions = {
					{ type = "damage", clauses = { { dice = { "d8", }, }, }, },
				},
				group = "Combat Superiority (Fighter)",
				ability = "strength",
			},
		},
	},
	["maneuvertacticalassessment"] = {
		multiple_actions = {
			["Tactical Assessment"] = {
				actions = {
					{ type = "effect", sName = "SKILL: d8 history,insight,investigation", sTargeting = "self", sApply = "roll", nDuration = 1, },
				},
				group = "Combat Superiority (Fighter)",
				ability = "strength",
			},
		},
	},
	["maneuvertripattack"] = {
		multiple_actions = {
			["Trip Attack"] = {
				actions = {
					{ type = "effect", sName = "DMG: d8", sTargeting = "self", sApply = "roll", nDuration = 1, },
					{ type = "powersave", save = "strength", savestat = "base", },
					{ type = "effect", sName = "Prone", },
				},
				group = "Combat Superiority (Fighter)",
				ability = "strength",
			},
		},
	},
	-- Fighter - Champion
	["remarkableathlete"] = {
		actions = {
			{ type = "effect", sName = "Remarkable Athlete; ADVINIT; ADVSKILL: athletics", sTargeting = "self", },
		},
	};
	["heroicwarrior"] = {
		actions = {},
	};
	["survivor"] = {
		actions = {
			{ type = "effect", sName = "Survivor; ADVDEATH; IF:Bloodied; REGEN:5 [CON]", sTargeting = "self", },
		},
	};
	-- Fighter - Eldritch Knight
	["warbond"] = {
		actions = {},
	};
	["warmagic"] = {
		actions = {},
	};
	["eldritchstrike"] = {
		actions = {
			{ type = "effect", sName = "[TRGT]; Eldritch Strike; DISSAV", sApply = "roll", nDuration = 1, },
		},
	},
	["arcanecharge"] = {
		multiple_actions = {
			["Action Surge (Arcane Charge)"] = {
				actions = {},
			},
		},
	},
	["improvedwarmagic"] = {
		multiple_actions = {
			["War Magic (Improved)"] = {
				actions = {},
			},
		},
	};
	-- Fighter - Psi Warrior
	["psionicpowerpsiwarrior"] = {
		multiple_actions = {
			["Psionic Energy"] = {
				actions = {},
				group = "Psionic Energy (Fighter)",
				ability = "intelligence",
				prepared = 4,
				usesperiod = "dual",
			},
			["Protective Field"] = {
				actions = {
					{ type = "effect", sName = "Protective Field; RESIST: d6 [INT]", sApply = "roll", nDuration = 1, },
				},
				group = "Psionic Energy (Fighter)",
				ability = "intelligence",
			},
			["Psionic Strike"] = {
				actions = {
					{ type = "damage", clauses = { { dice = { "d6", }, dmgtype = "force", stat = "intelligence" }, }, },
				},
				group = "Psionic Energy (Fighter)",
				ability = "intelligence",
			},
			["Telekinetic Movement"] = {
				actions = {},
				group = "Psionic Power (Fighter)",
				ability = "intelligence",
				prepared = 1,
				usesperiod = "enc",
			},
		},
	},
	["telekineticadept"] = {
		multiple_actions = {
			["Psi-Powered Leap"] = {
				actions = {},
				group = "Psionic Power (Fighter)",
				ability = "intelligence",
				prepared = 1,
				usesperiod = "enc",
			},
			["Psionic Strike (Telekinetic)"] = {
				actions = {
					{ type = "powersave", save = "strength", savestat = "base", magic = true, },
					{ type = "effect", sName = "Prone" },
				},
				group = "Psionic Energy (Fighter)",
				ability = "intelligence",
			},
		},
	},
	["guardedmind"] = {
		multiple_actions = {
			["Guarded Mind"] = {
				actions = {
					{ type = "effect", sName = "Guarded Mind; RESIST: psychic", sTargeting = "self", },
				},
				group = "Psionic Power (Fighter)",
				ability = "intelligence",
			},
			["Guarded Mind"] = {
				actions = {},
				group = "Psionic Energy (Fighter)",
				ability = "intelligence",
			},
		},
	},
	["bulwarkofforce"] = {
		multiple_actions = {
			["Bulwark of Force"] = {
				actions = {
					{ type = "effect", sName = "Bulwark of Force; COVER", nDuration = 1, sUnits = "minute" },
				},
				group = "Psionic Power (Fighter)",
				ability = "intelligence",
				prepared = 1,
			},
		},
	},
	["telekineticmaster"] = {
		spells = {
			{ name = "Telekinesis" },
			["group"] = "Spells (Fighter)",
			["ability"] = "intelligence",
		},
		multiple_actions = {
			["Telekinetic Master"] = {
				actions = {},
				group = "Psionic Power (Fighter)",
				ability = "intelligence",
				prepared = 1,
			},
		},
	},

	-- Monk
	["martialarts"] = {
		actions = {
			{ type = "attack", range = "M", },
			{ type = "damage", clauses = { { dice = { "d6", }, dmgtype = "bludgeoning", stat = "dexterity" }, }, },
		},
	},
	["monksfocus"] = {
		multiple_actions = {
			["Focus"] = {
				actions = {},
				group = "Focus (Monk)",
				ability = "wisdom",
				prepared = 2,
				usesperiod = "enc" 
			},
			["Flurry of Blows"] = {
				actions = {},
				group = "Focus (Monk)",
				ability = "wisdom",
			},
			["Patient Defense"] = {
				actions = {
					{ type = "effect", sName = "Patient Defense; Disengage", sTargeting = "self", nDuration = 1, },
					{ type = "effect", sName = "Patient Defense; Disengage; Dodge", sTargeting = "self", nDuration = 1, },
				},
				group = "Focus (Monk)",
				ability = "wisdom",
			},
			["Step of the Wind"] = {
				actions = { { type = "effect", sName = "Step of the Wind; Disengage; Dash; Jump doubled", sTargeting = "self", }, },
				group = "Focus (Monk)",
				ability = "wisdom",
			},
		},
	},
	["unarmoredmovement"] = {
		addspeed = 10,
	},
	["extraunarmoredmovement"] = {
		addspeed = 5,
	},
	["uncannymetabolism"] = {
		actions = {
			{ type = "heal", clauses = { { dice = { "d6" }, stat = "monk" },	}, },
		},
		group = "Focus (Monk)",
		ability = "wisdom",
		prepared = 1,
	},
	["deflectattacks"] = {
		multiple_actions = {
			["Deflect Attacks"] = {
				actions = {
					{ type = "heal", clauses = { { dice = { "d10" }, stat = "dexterity" }, { dice = {}, stat = "monk" }, } },
				},
			},
			["Deflect Attacks"] = {
				actions = {
					{ type = "powersave", save = "dexterity", savestat = "base", },
					{ type = "damage", clauses = { { dice = { "d6", "d6" }, stat = "dexterity", }, }, },
				},
				group = "Focus (Monk)",
				ability = "wisdom",
			},
		},
	},
	["slowfall"] = {
		actions = {
			{ type = "heal", sTargeting = "self", clauses = { { dice = { }, statmult = 5, stat = "monk" }, }, },
		},
	},
	["stunningstrike"] = {
		actions = {
			{ type = "powersave", save = "constitution", savestat = "base", },
			{ type = "effect", sName = "Stunning Strike; Stunned", nDuration = 1, },
			{ type = "effect", sName = "Stunning Strike; Speed halved; GRANTADVATK", nDuration = 1, },
		},
		group = "Focus (Monk)",
		ability = "wisdom",
	},
	["empoweredstrikes"] = {
		actions = {
			{ type = "effect", sName = "DMGTYPE: force", sTargeting = "self", },
		},
	},
	["evasion"] = {
		actions = {
			{ type = "effect", sName = "Evasion", sTargeting = "self", },
		},
	},
	["acrobaticmovement"] = {
		actions = {},
	},
	["heightenedfocus"] = {
		actions = {},
		group = "Focus (Monk)",
		ability = "wisdom",
	},
	["selfrestoration"] = {
		actions = {},
	},
	["deflectenergy"] = {
		actions = {
			{ type = "heal", clauses = { { dice = { "d10" }, stat = "dexterity" }, { dice = {}, stat = "monk" }, } },
		},
	},
	["disciplinedsurvivor"] = {
		saveprof = { innate = { "strength", "dexterity", "constitution", "intelligence", "wisdom", "charisma", }, },
		actions = {},
		group = "Focus (Monk)",
		ability = "wisdom",
	},
	["perfectfocus"] = {
		actions = {},
		group = "Focus (Monk)",
		ability = "wisdom",
	},
	["superiordefense"] = {
		actions = {
			{ type = "effect", sName = "Superior Defense; RESIST: all,!force", sTargeting = "self", nDuration = 1, sUnits = "minute", },
		},
		group = "Focus (Monk)",
		ability = "wisdom",
	},
	-- Monk - Warrior of Mercy
	["handofharm"] = {
		actions = {
			{ type = "effect", sName = "DMG: 1d6 [WIS] necrotic", sTargeting = "self", sApply = "roll", nDuration = 1, },
		},
		group = "Focus (Monk)",
		ability = "wisdom",
	},
	["handofhealing"] = {
		actions = {
			{ type = "heal", clauses = { { dice = { "d6" }, stat = "wisdom", }, }, },
		},
		group = "Focus (Monk)",
		ability = "wisdom",
	},
	["physicianstouch"] = {
		multiple_actions = {
			["Hand of Harm (Improved)"] = {
				actions = {
					{ type = "effect", sName = "Poisoned", nDuration = 1, },
				},
				group = "Focus (Monk)",
				ability = "wisdom",
			},
			["Hand of Healing (Improved)"] = {
				actions = {},
				group = "Focus (Monk)",
				ability = "wisdom",
			},
		},
	},
	["flurryofhealingandharm"] = {
		actions = {},
		group = "Focus (Monk)",
		ability = "wisdom",
	},
	["handofultimatemercy"] = {
		actions = {
			{ type = "heal", clauses = { { dice = { "d10", "d10", "d10", "d10" }, stat = "wisdom", }, }, },
		},
		group = "Focus (Monk)",
		ability = "wisdom",
		prepared = 1,
	},
	-- Monk - Warrior of Shadow
	["shadowarts"] = {
		spells = {
			{ name = "Minor Illusion", },
			["group"] = "Spells (Monk)",
			["ability"] = "wisdom",
		},
		multiple_actions = {
			["Darkness"] = {
				actions = {
					{ type = "effect", sName = "LIGHT: 15/15 FF000000; (C)", nDuration = 10, sUnits = "minute" },
				},
				group = "Focus (Monk)",
				ability = "wisdom",
			},
			["Darkvision"] = {
				actions = {
					{ type = "effect", sName = "VISION: 60 darkvision", nDuration = 8, sUnits = "hour" },
				},
				group = "Focus (Monk)",
				ability = "wisdom",
			},
		},
	},
	["shadowstep"] = {
		actions = {
			{ type = "effect", sName = "ADVATK", sApply = "roll", nDuration = 1 },
		},
	},
	["improvedshadowstep"] = {
		actions = {},
		group = "Focus (Monk)",
		ability = "wisdom",
	},
	["cloakofshadows"] = {
		actions = {
			{ type = "effect", sName = "Cloak of Shadows; Invisible; NOTE: Flurry of Blows without Focus; NOTE: Move through occupied spaces as Difficult", nDuration = 1, sUnits = "minute" },
		},
		group = "Focus (Monk)",
		ability = "wisdom",
	},
	-- Monk - Warrior of the Elements
	["elementalattunement"] = {
		actions = {
			{ type = "effect", sName = "Elemental Attunement; Reach Unarmed +10", nDuration = 10, sUnits = "minute" },
			{ type = "effect", sName = "DMGTYPE:acid", sApply = "roll", nDuration = 1 },
			{ type = "effect", sName = "DMGTYPE:cold", sApply = "roll", nDuration = 1 },
			{ type = "effect", sName = "DMGTYPE:fire", sApply = "roll", nDuration = 1 },
			{ type = "effect", sName = "DMGTYPE:lightning", sApply = "roll", nDuration = 1 },
			{ type = "effect", sName = "DMGTYPE:thunder", sApply = "roll", nDuration = 1 },
			{ type = "powersave", save = "strength", savestat = "base", magic = true, },
		},
		group = "Focus (Monk)",
		ability = "wisdom",
	},
	["manipulateelements"] = {
		spells = {
			{ name = "Elementalism", },
			["group"] = "Spells (Monk)",
			["ability"] = "wisdom",
		},
	},
	["elementalburst"] = {
		actions = {
			{ type = "powersave", save = "dexterity", savestat = "base", magic = true, onmissdamage = "half", },
			{ type = "damage", clauses = { { dice = { "d8", "d8", "d8", }, dmgtype = "acid" }, }, },
			{ type = "damage", clauses = { { dice = { "d8", "d8", "d8", }, dmgtype = "cold" }, }, },
			{ type = "damage", clauses = { { dice = { "d8", "d8", "d8", }, dmgtype = "fire" }, }, },
			{ type = "damage", clauses = { { dice = { "d8", "d8", "d8", }, dmgtype = "lightning" }, }, },
			{ type = "damage", clauses = { { dice = { "d8", "d8", "d8", }, dmgtype = "thunder" }, }, },
		},
		group = "Focus (Monk)",
		ability = "wisdom",
	},
	["strideoftheelements"] = {
		multiple_actions = {
			["Elemental Attunement (Stride of the Elements)"] = {
				actions = {
					{ type = "effect", sName = "Fly Speed; Swim Speed", nDuration = 10, sUnits = "minute" },
				},
				group = "Focus (Monk)",
				ability = "wisdom",
			},
		},
	},
	["elementalepitome"] = {
		multiple_actions = {
			["Elemental Attunement (Damage Resistance)"] = {
				actions = {
					{ type = "effect", sName = "RESIST: acid", sTargeting = "self", nDuration = 10, sUnits = "minute" },
					{ type = "effect", sName = "RESIST: cold", sTargeting = "self", nDuration = 10, sUnits = "minute" },
					{ type = "effect", sName = "RESIST: fire", sTargeting = "self", nDuration = 10, sUnits = "minute" },
					{ type = "effect", sName = "RESIST: lightning", sTargeting = "self", nDuration = 10, sUnits = "minute" },
					{ type = "effect", sName = "RESIST: thunder", ssTargeting = "self", nDuration = 10, sUnits = "minute" },
				},
				group = "Focus (Monk)",
				ability = "wisdom",
			},
			["Step of the Wind (Elemental Epitome)"] = {
				actions = {
					{ type = "effect", sName = "SPEED +20", sTargeting = "self", nDuration = 1 },
					{ type = "damage", clauses = { { dice = { "d12" }, dmgtype = "acid" }, }, },
					{ type = "damage", clauses = { { dice = { "d12" }, dmgtype = "cold" }, }, },
					{ type = "damage", clauses = { { dice = { "d12" }, dmgtype = "fire" }, }, },
					{ type = "damage", clauses = { { dice = { "d12" }, dmgtype = "lightning" }, }, },
					{ type = "damage", clauses = { { dice = { "d12" }, dmgtype = "thunder" }, }, },
				},
				group = "Focus (Monk)",
				ability = "wisdom",
			},
			["Empowered Strikes (Elemental Epitome)"] = {
				actions = {
					{ type = "effect", sName = "DMG: 1d12", sTargeting = "self", sApply = "roll", nDuration = 1 },
				},
			},
		},
	},
	-- Monk - Warrior of the Open Hand
	["openhandtechnique"] = {
		multiple_actions = {
			["Flurry of Blows (Addle)"] = {
				actions = {
					{ type = "effect", sName = "NOTE: No Oportunity Attacks", nDuration = 1 },
				},
				group = "Focus (Monk)",
				ability = "wisdom",
			},
			["Flurry of Blows (Push)"] = {
				actions = {
					{ type = "powersave", save = "strength", savestat = "base", },
				},
				group = "Focus (Monk)",
				ability = "wisdom",
			},
			["Flurry of Blows (Topple)"] = {
				actions = {
					{ type = "powersave", save = "dexterity", savestat = "base", },
					{ type = "effect", sName = "Prone" },
				},
				group = "Focus (Monk)",
				ability = "wisdom",
			},
		},
	},
	["wholenessofbody"] = {
		actions = {
			{ type = "heal", clauses = { { dice = { "d6" }, stat = "wisdom", }, }, },
		},
		prepared = 1,
	},
	["fleetstep"] = {
		multiple_actions = {
			["Step of the Wind (Fleet Step)"] = {
				actions = {},
				group = "Focus (Monk)",
				ability = "wisdom",
			},
		},
	},
	["quiveringpalm"] = {
		actions = {
			{ type = "powersave", save = "constitution", onmissdamage = "half", savestat = "base", },
			{ type = "damage", clauses = { { dice = { "d12", "d12", "d12", "d12", "d12", "d12", "d12", "d12", "d12", "d12", }, dmgtype = "force" }, }, },
		},
		group = "Focus (Monk)",
		ability = "wisdom",
	},

	-- Paladin
	["layonhands"] = {
		actions = {
			{ type = "heal", clauses = { { dice = { }, statmult = 5, stat = "paladin", }, }, },
		},
	},
	["fightingstylepaladin"] = {
		choicetype = "Fighting Style",
		choicenum = 1,
		choiceskipadd = true,
	},
	["fightingstyleblessedwarrior"] = {
		spells = {
			["list"] = "Cleric",
			["L0"] = 2,
			["group"] = "Spells (Paladin)",
			["ability"] = "charisma",
		},
	},
	["paladinssmite"] = {
		spells = {
			{ name = "Divine Smite" },
			["group"] = "Spells (Paladin)",
			["ability"] = "charisma",
		},
		actions = {},
		prepared = 1,
	},
	["channeldivinitypaladin"] = {
		multiple_actions = {
			["Channel Divinity"] = {
				actions = {},
				group = "Channel Divinity (Paladin)",
				ability = "charisma",
				prepared = 2,
				usesperiod = "dual",
			},
			["Divine Sense"] = {
				actions = {
					{ type = "effect", sName = "Divine Sense", nDuration = 10, sUnits = "minute" },
				},
				group = "Channel Divinity (Paladin)",
				ability = "charisma",
			},
		},
	},
	["faithfulsteed"] = {
		spells = {
			{ name = "Find Steed" },
			["group"] = "Spells (Paladin)",
			["ability"] = "charisma",
		},
		actions = {},
		prepared = 1,
	},
	["auraofprotection"] = {
		actions = {
			{ type = "effect", sName = "Aura of Protection; SAVE: [CHA]" },
		},
		group = "Aura of Protection (Paladin)",
		ability = "charisma",
	},
	["abjurefoes"] = {
		actions = {
			{ type = "powersave", save = "wisdom", savestat = "base", magic = true, },
			{ type = "effect", sName = "Frightened", nDuration = 1, sUnits = "minute" },
		},
		group = "Channel Divinity (Paladin)",
		ability = "charisma",
	},
	["auraofcourage"] = {
		actions = {
			{ type = "effect", sName = "Aura of Courage; IMMUNE: Frightened" },
		},
		group = "Aura of Protection (Paladin)",
		ability = "charisma",
	},
	["radiantstrikes"] = {
		actions = {
			{ type = "effect", sName = "Radiant Strikes; DMG: 1d8 radiant", sTargeting = "self", },
		},
	},
	["restoringtouch"] = {
		multiple_actions = {
			["Lay on Hands (Restoring Touch)"] = {
				actions = {},
			},
		},
	},
	["auraexpansion"] = {
		actions = {},
		group = "Aura of Protection (Paladin)",
		ability = "charisma",
	},
	-- Paladin - Oath of Devotion
	["oathofdevotionspells"] = {
		spells = {
			{ name = "Protection from Evil and Good" },
			{ name = "Shield of Faith" },
			["group"] = "Spells (Paladin)",
			["ability"] = "charisma",
		},
	},
	["oathofdevotionspellsl5"] = {
		spells = {
			{ name = "Aid" },
			{ name = "Zone of Truth" },
			["group"] = "Spells (Paladin)",
			["ability"] = "charisma",
		},
	},
	["oathofdevotionspellsl9"] = {
		spells = {
			{ name = "Beacon of Hope" },
			{ name = "Dispel Magic" },
			["group"] = "Spells (Paladin)",
			["ability"] = "charisma",
		},
	},
	["oathofdevotionspellsl13"] = {
		spells = {
			{ name = "Freedom of Movement" },
			{ name = "Guardian of Faith" },
			["group"] = "Spells (Paladin)",
			["ability"] = "charisma",
		},
	},
	["oathofdevotionspellsl17"] = {
		spells = {
			{ name = "Commune" },
			{ name = "Flame Strike" },
			["group"] = "Spells (Paladin)",
			["ability"] = "charisma",
		},
	},
	["sacredweapon"] = {
		actions = {
			{ type = "effect", sName = "DMG: [CHA]; DMGTYPE: radiant; LIGHT: 20 light", nDuration = 10, sUnits = "minute" },
		},
		group = "Channel Divinity (Paladin)",
		ability = "charisma",
	},
	["auraofdevotion"] = {
		actions = {
			{ type = "effect", sName = "Aura of Devotion; IMMUNE: Charmed" },
		},
		group = "Aura of Protection (Paladin)",
		ability = "charisma",
	},
	["smiteofprotection"] = {
		actions = {
			{ type = "effect", sName = "Aura of Smite; COVER", nDuration = 1 },
		},
		group = "Aura of Protection (Paladin)",
		ability = "charisma",
	},
	["holynimbus"] = {
		actions = {
			{ type = "effect", sName = "Holy Nimbus (Sunlight)", sTargeting = "self", nDuration = 10, sUnits = "minute" },
			{ type = "effect", sName = "Holy Nimbus (Ally); IFT: TYPE(fiend,undead); ADVSAV", nDuration = 10, sUnits = "minute" },
			{ type = "effect", sName = "Holy Nimbus (Enemy); DMGO: [CHA] [PRF] radiant", nDuration = 10, sUnits = "minute" },
		},
		group = "Aura of Protection (Paladin)",
		ability = "charisma",
		prepared = 1,
	},
	-- Paladin - Oath of Glory
	["inspiringsmite"] = {
		actions = {
			{ type = "heal", subtype = "temp", clauses = { { dice = { "d8", "d8" }, stat = "paladin", }, }, },
		},
		group = "Channel Divinity (Paladin)",
		ability = "charisma",
	},
	["oathofgloryspells"] = {
		spells = {
			{ name = "Guiding Bolt" },
			{ name = "Heroism" },
			["group"] = "Spells (Paladin)",
			["ability"] = "charisma",
		},
	},
	["oathofgloryspellsl5"] = {
		spells = {
			{ name = "Enhance Ability" },
			{ name = "Magic Weapon" },
			["group"] = "Spells (Paladin)",
			["ability"] = "charisma",
		},
	},
	["oathofgloryspellsl9"] = {
		spells = {
			{ name = "Haste" },
			{ name = "Protection from Energy" },
			["group"] = "Spells (Paladin)",
			["ability"] = "charisma",
		},
	},
	["oathofgloryspellsl13"] = {
		spells = {
			{ name = "Compulsion" },
			{ name = "Freedom of Movement" },
			["group"] = "Spells (Paladin)",
			["ability"] = "charisma",
		},
	},
	["oathofgloryspellsl17"] = {
		spells = {
			{ name = "Legend Lore" },
			{ name = "Yolande's Regal Presence" },
			["group"] = "Spells (Paladin)",
			["ability"] = "charisma",
		},
	},
	["peerlessathlete"] = {
		actions = {
			{ type = "effect", sName = "Peerless Athlete; ADVSKILL: athletics; ADVSKILL: acrobatics; NOTE: Jump distance +10", sTargeting = "self", nDuration = 1, sUnits = "hour" },
		},
		group = "Channel Divinity (Paladin)",
		ability = "charisma",
	},
	["auraofalacrity"] = {
		addspeed = 10,
		actions = {
			{ type = "effect", sName = "Aura of Alacrity; Speed +10" },
		},
		group = "Aura of Protection (Paladin)",
		ability = "charisma",
	},
	["gloriousdefense"] = {
		actions = {
			{ type = "effect", sName = "Glorious Defense; AC: [CHA]" },
		},
		prepared = 1,
	},
	["livinglegend"] = {
		actions = {
			{ type = "effect", sName = "Living Legend; ADVCHECK: charisma; NOTE: Reaction to reroll failed Saves; NOTE: 1/turn - change Attack miss to a hit", sTargeting = "self", nDuration = 10, sUnits = "minute" },
		},
		prepared = 1,
	},
	-- Paladin - Oath of the Ancients
	["natureswrath"] = {
		actions = {
			{ type = "powersave", save = "strength", savestat = "base", magic = true, },
			{ type = "effect", sName = "Restrained", nDuration = 1, sUnits = "minute" },
		},
		group = "Channel Divinity (Paladin)",
		ability = "charisma",
	},
	["oathoftheancientsspells"] = {
		spells = {
			{ name = "Ensnaring Strike" },
			{ name = "Speak with Animals" },
			["group"] = "Spells (Paladin)",
			["ability"] = "charisma",
		},
	},
	["oathoftheancientsspellsl5"] = {
		spells = {
			{ name = "Misty Step" },
			{ name = "Moonbeam" },
			["group"] = "Spells (Paladin)",
			["ability"] = "charisma",
		},
	},
	["oathoftheancientsspellsl9"] = {
		spells = {
			{ name = "Plant Growth" },
			{ name = "Protection from Energy" },
			["group"] = "Spells (Paladin)",
			["ability"] = "charisma",
		},
	},
	["oathoftheancientsspellsl13"] = {
		spells = {
			{ name = "Ice Storm" },
			{ name = "Stoneskin" },
			["group"] = "Spells (Paladin)",
			["ability"] = "charisma",
		},
	},
	["oathoftheancientsspellsl17"] = {
		spells = {
			{ name = "Commune with Nature" },
			{ name = "Tree Stride" },
			["group"] = "Spells (Paladin)",
			["ability"] = "charisma",
		},
	},
	["auraofwarding"] = {
		actions = {
			{ type = "effect", sName = "Aura of Warding; RESIST: necrotic,psychic,radiant" },
		},
		group = "Aura of Protection (Paladin)",
		ability = "charisma",
	},
	["undyingsentinel"] = {
		actions = {
			{ type = "heal", sTargeting = "self", clauses = { { statmult = 3, stat = "paladin", }, }, },
		},
		prepared = 1,
	},
	["elderchampion"] = {
		actions = {
			{ type = "effect", sName = "Elder Champion (Ally); REGEN: 10; NOTE: Cast Action spells as Bonus action", nDuration = 1, sUnits = "minute" },
			{ type = "effect", sName = "Elder Champion (Enemy); DISSAV", nDuration = 1, sUnits = "minute" },
		},
		group = "Aura of Protection (Paladin)",
		ability = "charisma",
		prepared = 1,
	},
	-- Paladin - Oath of Vengeance
	["oathofvengeancespells"] = {
		spells = {
			{ name = "Bane" },
			{ name = "Hunter's Mark" },
			["group"] = "Spells (Paladin)",
			["ability"] = "charisma",
		},
	},
	["oathofvengeancespellsl5"] = {
		spells = {
			{ name = "Hold Person" },
			{ name = "Misty Step" },
			["group"] = "Spells (Paladin)",
			["ability"] = "charisma",
		},
	},
	["oathofvengeancespellsl9"] = {
		spells = {
			{ name = "Haste" },
			{ name = "Protection from Energy" },
			["group"] = "Spells (Paladin)",
			["ability"] = "charisma",
		},
	},
	["oathofvengeancespellsl13"] = {
		spells = {
			{ name = "Banishment" },
			{ name = "Dimension Door" },
			["group"] = "Spells (Paladin)",
			["ability"] = "charisma",
		},
	},
	["oathofvengeancespellsl17"] = {
		spells = {
			{ name = "Hold Monster" },
			{ name = "Scrying" },
			["group"] = "Spells (Paladin)",
			["ability"] = "charisma",
		},
	},
	["vowofenmity"] = {
		actions = {
			{ type = "effect", sName = "[TRGT]; ADVATK", sTargeting = "self", nDuration = 1, sUnits = "minute" },
		},
		group = "Channel Divinity (Paladin)",
		ability = "charisma",
	},
	["relentlessavenger"] = {
		actions = {
			{ type = "effect", sName = "Relentless Avenger; Speed 0", nDuration = 1 },
		},
	},
	["soulofvengeance"] = {
		multiple_actions = {
			["Vow of Enmity (Soul of Vengeance)"] = {
				actions = {},
				group = "Channel Divinity (Paladin)",
				ability = "charisma",
			},
		},
	},
	["avengingangel"] = {
		actions = {
			{ type = "effect", sName = "Avenging Angel; Fly Speed 60; Hover; ADVCHECK: charisma; NOTE: Reaction to reroll failed Saves; NOTE: 1/turn - change Attack miss to a hit", sTargeting = "self", nDuration = 10, sUnits = "minute" },
			{ type = "powersave", save = "wisdom", savestat = "base", magic = true, },
			{ type = "effect", sName = "Avenging Angel (Enemy); Frightened; GRANTADVATK", nDuration = 1, sUnits = "minute" },
		},
		prepared = 1,
	},

	-- Ranger
	["favoredenemy"] = {
		spells = {
			{ name = "Hunter's Mark" },
			["group"] = "Spells (Ranger)",
			["ability"] = "wisdom",
		},
		multiple_actions = {
			["Favored Enemy"] = {
				actions = {},
				group = "Hunter's Mark (Ranger)",
				ability = "wisdom",
				prepared = 2,
			},
		},
	},
	["fightingstyleranger"] = {
		choicetype = "Fighting Style",
		choicenum = 1,
		choiceskipadd = true,
	},
	["fightingstyledruidicwarrior"] = {
		spells = {
			["list"] = "Druid",
			["L0"] = 2,
			["group"] = "Spells (Ranger)",
			["ability"] = "wisdom",
		},
	},
	["roving"] = {
		specialmoves = { ["Climb"] = true, ["Swim"] = true, },
		addspeed = 10,
	},
	["tireless"] = {
		multiple_actions = {
			["Tireless (Temporary Hit Points)"] = {
				actions = {
					{ type = "heal", subtype = "temp", sTargeting = "self", clauses = { { dice = { "d8" }, stat = "wisdom", }, }, },
				},
				prepared = 1,
			},
			["Tireless (Decrease Exhaustion)"] = {
				actions = {},
			},
		},
	},
	["relentlesshunter"] = {
		actions = {
			{ type = "effect", sName = "Hunter's Mark", nDuration = 1, sUnits = "hour" },
			{ type = "effect", sName = "IFT: CUSTOM(Hunter's Mark); DMG: 1d6 force", sTargeting = "self", nDuration = 1, sUnits = "hour" },
		},
		group = "Hunter's Mark (Ranger)",
		ability = "wisdom",
	},
	["naturesveil"] = {
		actions = {
			{ type = "effect", sName = "Invisible", sTargeting = "self", nDuration = 1 },
		},
		prepared = 1,
	},
	["precisehunter"] = {
		actions = {
			{ type = "effect", sName = "Hunter's Mark", nDuration = 1, sUnits = "hour" },
			{ type = "effect", sName = "IFT: CUSTOM(Hunter's Mark); ADVATK; DMG: 1d6 force", sTargeting = "self", nDuration = 1, sUnits = "hour" },
		},
		group = "Hunter's Mark (Ranger)",
		ability = "wisdom",
	},
	["feralsenses"] = {
		senses = { ["Blindsight"] = 30, },
	},
	["foeslayer"] = {
		actions = {
			{ type = "effect", sName = "Hunter's Mark", nDuration = 1, sUnits = "hour" },
			{ type = "effect", sName = "IFT: CUSTOM(Hunter's Mark); ADVATK; DMG: 1d10 force", sTargeting = "self", nDuration = 1, sUnits = "hour" },
		},
		group = "Hunter's Mark (Ranger)",
		ability = "wisdom",
	},
	-- Ranger - Beast Master
	["primalcompanion"] = {
		multiple_actions = {
			["Primal Companion"] = {
				actions = {},
				prepared = 1,
				group = "Primal Companion (Ranger)",
				ability = "wisdom",
			},
			["Action"] = {
				actions = {},
				group = "Primal Companion (Ranger)",
				ability = "wisdom",
			},
		},
	},
	["exceptionaltraining"] = {
		multiple_actions = {
			["Bonus"] = {
				actions = {},
				group = "Primal Companion (Ranger)",
				ability = "wisdom",
			},
			["Action (Force)"] = {
				actions = {
					{ type = "effect", sName = "DMGTYPE: force" },
				},
				group = "Primal Companion (Ranger)",
				ability = "wisdom",
			},
		},
	},
	["bestialfury"] = {
		multiple_actions = {
			["Action (Strike x2)"] = {
				actions = {},
				group = "Primal Companion (Ranger)",
				ability = "wisdom",
			},
			["Action (Hunter's Mark)"] = {
				actions = {},
				group = "Primal Companion (Ranger)",
				ability = "wisdom",
			},
		},
	},
	["sharespells"] = {
		actions = {},
		group = "Primal Companion (Ranger)",
		ability = "wisdom",
	},
	-- Ranger - Fey Wanderer
	["dreadfulstrikes"] = {
		actions = {
			{ type = "effect", sName = "Dreadful Strikes; DMG: 1d4 psychic", sTargeting = "self", sApply = "roll", nDuration = 1 },
		},
	},
	["feywandererspells"] = {
		spells = {
			{ name = "Charm Person" },
			["group"] = "Spells (Ranger)",
			["ability"] = "wisdom",
		},
	},
	["feywandererspellsl5"] = {
		spells = {
			{ name = "Misty Step" },
			["group"] = "Spells (Ranger)",
			["ability"] = "wisdom",
		},
	},
	["feywandererspellsl9"] = {
		spells = {
			{ name = "Summon Fey" },
			["group"] = "Spells (Ranger)",
			["ability"] = "wisdom",
		},
	},
	["feywandererspellsl13"] = {
		spells = {
			{ name = "Dimension Door" },
			["group"] = "Spells (Ranger)",
			["ability"] = "wisdom",
		},
	},
	["feywandererspellsl17"] = {
		spells = {
			{ name = "Mislead" },
			["group"] = "Spells (Ranger)",
			["ability"] = "wisdom",
		},
	},
	["feywildgifts"] = {
		actions = {},
	},
	["otherworldlyglamour"] = {
		actions = {
			{ type = "effect", sName = "Otherworldly Glamour; CHECK: [WIS] charisma", sTargeting = "self" },
		},
	},
	["beguilingtwist"] = {
		actions = {
			{ type = "effect", sName = "Beguiling Twist; NOTE: ADV on Saves vs. Charmed/Frightened", sTargeting = "self" },
			{ type = "powersave", save = "wisdom", savestat = "wisdom", magic = true, },
			{ type = "effect", sName = "Beguiling Twist; Charmed; NOTE: Save on end of each round", nDuration = 1, sUnits = "minute" },
			{ type = "effect", sName = "Beguiling Twist; Frightened; NOTE: Save on end of each round", nDuration = 1, sUnits = "minute" },
		},
	},
	["feyreinforcements"] = {
		actions = {},
		prepared = 1,
	},
	["mistywanderer"] = {
		actions = {},
		prepared = 1,
	},
	-- Ranger - Gloom Stalker
	["dreadambusher"] = {
		multiple_actions = {
			["Dread Ambusher"] = {
				actions = {
					{ type = "effect", sName = "Dread Ambusher; ADVINIT", sTargeting = "self" },
					{ type = "effect", sName = "Ambusher's Leap; Speed +10", sTargeting = "self", nDuration = 1 },
				},
			},
			["Dreadful Strike"] = {
				actions = {
					{ type = "effect", sName = "Dreadful Strike; DMG: 2d6 psychic", sTargeting = "self", sApply = "roll", nDuration = 1 },
				},
				prepared = 1,
			},
		},
	},
	["gloomstalkerspells"] = {
		spells = {
			{ name = "Disguise Self" },
			["group"] = "Spells (Ranger)",
			["ability"] = "wisdom",
		},
	},
	["gloomstalkerspellsl5"] = {
		spells = {
			{ name = "Rope Trick" },
			["group"] = "Spells (Ranger)",
			["ability"] = "wisdom",
		},
	},
	["gloomstalkerspellsl9"] = {
		spells = {
			{ name = "Fear" },
			["group"] = "Spells (Ranger)",
			["ability"] = "wisdom",
		},
	},
	["gloomstalkerspellsl13"] = {
		spells = {
			{ name = "Greater Invisibility" },
			["group"] = "Spells (Ranger)",
			["ability"] = "wisdom",
		},
	},
	["gloomstalkerspellsl17"] = {
		spells = {
			{ name = "Seeming" },
			["group"] = "Spells (Ranger)",
			["ability"] = "wisdom",
		},
	},
	["umbralsight"] = {
		sense = { ["Darkvision"] = 60, },
		actions = {
			{ type = "effect", sName = "Umbral Sight; Invisible; NOTE: Only in full darkness", sTargeting = "self" },
		},
	},
	["stalkersflurry"] = {
		multiple_actions = {
			["Dreadful Strike (Improved)"] = {
				actions = {
					{ type = "effect", sName = "Dreadful Strike; DMG: 2d8 psychic", sTargeting = "self", sApply = "roll", nDuration = 1 },
				},
			},
			["Dreadful Strike (Sudden Strike)"] = {
				actions = {},
			},
			["Dreadful Strike (Mass Fear)"] = {
				actions = {
					{ type = "powersave", save = "wisdom", savestat = "wisdom", },
					{ type = "effect", sName = "Beguiling Twist; Frightened", nDuration = 1 },
				},
			},
		},
	},
	["shadowydodge"] = {
		actions = {
			{ type = "effect", sName = "DISATK", sApply = "roll", nDuration = 1 },
		},
	},
	-- Ranger - Hunter
	["hunterslore"] = {
		actions = {},
	},
	["huntersprey"] = {
		multiple_actions = {
			["Hunter's Prey (Colossus Slayer)"] = {
				actions = {
					{ type = "effect", sName = "Colossus Slayer; IFT: Wounded; DMG: 1d8", sTargeting = "self", sApply = "roll" },
				},
			},
			["Hunter's Prey (Horde Breaker)"] = {
				actions = {
					{ type = "effect", sName = "Horde Breaker", sTargeting = "self" },
				},
			},
		},
	},
	["defensivetactics"] = {
		multiple_actions = {
			["Defensive Tactics (Escape the Horde)"] = {
				actions = {
					{ type = "effect", sName = "Escape the Horde; GRANTDISATK", sTargeting = "self", nDuration = 1 },
				},
			},
			["Defensive Tactics (Multiattack Defense)"] = {
				actions = {
					{ type = "effect", sName = "Multiattack Defense; GRANTDISATK", nDuration = 1 },
				},
			},
		},
	},
	["superiorhuntersprey"] = {
		actions = {
			{ type = "damage", clauses = { { dice = { "d6", }, dmgtype = "force" }, }, },
		},
		group = "Hunter's Mark (Ranger)",
		ability = "wisdom",
	},
	["superiorhuntersdefense"] = {
		actions = {
			{ type = "effect", sName = "Superior Hunter's Defense (Acid); RESIST: acid", sTargeting = "self", },
			{ type = "effect", sName = "Superior Hunter's Defense (Bludgeoning); RESIST: bludgeoning", sTargeting = "self", },
			{ type = "effect", sName = "Superior Hunter's Defense (Cold); RESIST: cold", sTargeting = "self", },
			{ type = "effect", sName = "Superior Hunter's Defense (Fire); RESIST: fire", sTargeting = "self", },
			{ type = "effect", sName = "Superior Hunter's Defense (Lightning); RESIST: lightning", sTargeting = "self", },
			{ type = "effect", sName = "Superior Hunter's Defense (Necrotic); RESIST: necrotic", sTargeting = "self", },
			{ type = "effect", sName = "Superior Hunter's Defense (Piercing); RESIST: piercing", sTargeting = "self", },
			{ type = "effect", sName = "Superior Hunter's Defense (Poison); RESIST: poison", sTargeting = "self", },
			{ type = "effect", sName = "Superior Hunter's Defense (Psychic); RESIST: psychic", sTargeting = "self", },
			{ type = "effect", sName = "Superior Hunter's Defense (Slashing); RESIST: slashing", sTargeting = "self", },
			{ type = "effect", sName = "Superior Hunter's Defense (Radiant); RESIST: radiant", sTargeting = "self", },
			{ type = "effect", sName = "Superior Hunter's Defense (Thunder); RESIST: thunder", sTargeting = "self", },
		},
	},

	-- Rogue
	["sneakattack"] = {
		actions = {
			{ type = "effect", sName = "Sneak Attack; DMG: 1d6", sTargeting = "self", sApply = "roll", nDuration = 1, },
		},
		group = "Sneak Attack (Rogue)",
		ability = "dexterity",
	},
	["cunningaction"] = {
		actions = {},
	},
	["steadyaim"] = {
		actions = {
			{ type = "effect", sName = "Steady Aim; ADVATK; Speed 0", sTargeting = "self", sApply = "roll", nDuration = 1, },
		},
	},
	["cunningstrike"] = {
		multiple_actions = {
			["Poison (Cost 1d6)"] = {
				actions = {
					{ type = "powersave", save = "constitution", savestat = "base", },
					{ type = "effect", sName = "Poisoned; NOTE: Save on end of round", nDuration = 1, sUnits = "minute", },
				},
				group = "Sneak Attack (Rogue)",
				ability = "dexterity",
			},
			["Trip (Cost 1d6)"] = {
				actions = {
					{ type = "powersave", save = "dexterity", savestat = "base", },
					{ type = "effect", sName = "Prone" },
				},
				group = "Sneak Attack (Rogue)",
				ability = "dexterity",
			},
			["Withdraw (Cost 1d6)"] = {
				actions = {},
				group = "Sneak Attack (Rogue)",
				ability = "dexterity",
			},
		},
	},
	["uncannydodge"] = {
		actions = {
			{ type = "effect", sName = "Uncanny Dodge; RESIST: all", sTargeting = "self", sApply = "roll", nDuration = 1, },
		},
	},
	["improvedcunningstrike"] = {
		multiple_actions = {
			["Improved Cunning Strike"] = {
				actions = {},
				group = "Sneak Attack (Rogue)",
				ability = "dexterity",
			},
		},
	},
	["deviousstrikes"] = {
		multiple_actions = {
			["Daze (Cost 2d6)"] = {
				actions = {
					{ type = "powersave", save = "constitution", savestat = "base", },
					{ type = "effect", sName = "Dazed", nDuration = 1 },
				},
				group = "Sneak Attack (Rogue)",
				ability = "dexterity",
			},
			["Knock Out (Cost 6d6)"] = {
				actions = {
					{ type = "powersave", save = "constitution", savestat = "base", },
					{ type = "effect", sName = "Unconscious; NOTE: Save on end of round", nDuration = 1, sUnits = "minute" },
					{ type = "effect", sName = "Prone" },
				},
				group = "Sneak Attack (Rogue)",
				ability = "dexterity",
			},
			["Obscure (Cost 3d6)"] = {
				actions = {
					{ type = "powersave", save = "dexterity", savestat = "base", },
					{ type = "effect", sName = "Blinded", nDuration = 1 },
				},
				group = "Sneak Attack (Rogue)",
				ability = "dexterity",
			},
		},
	},
	["slipperymind"] = {
		saveprof = { innate = { "wisdom", "charisma", }, },
	},
	["elusive"] = {
		actions = {},
	},
	["strokeofluck"] = {
		actions = {},
		prepared = 1,
		usesperiod = "enc",
	},
	-- Rogue - Arcane Trickster
	["magehandlegerdemain"] = {
		actions = {},
	},
	["magicalambush"] = {
		actions = {
			{ type = "effect", sName = "Magical Ambush; DISSAV", sApply = "roll", nDuration = 1, },
		},
	},
	["versatiletrickster"] = {
		multiple_actions = {
			["Trip (Versatile Trickster)"] = {
				actions = {},
				group = "Sneak Attack (Rogue)",
				ability = "dexterity",
			},
		},
	},
	["spellthief"] = {
		actions = {
			{ type = "powersave", save = "intelligence", savestat = "intelligence", magic = true, },
		},
		prepared = 1,
	},
	-- Rogue - Assassin
	["assassinate"] = {
		actions = {
			{ type = "effect", sName = "Assassinate; ADVINIT", sTargeting = "self", },
			{ type = "effect", sName = "Assassinate; ADVATK; DMG: [ROGUE]", sTargeting = "self", sApply = "roll", nDuration = 1, },
		},
	},
	["infiltrationexpertise"] = {
		multiple_actions = {
			["Steady Aim (Infiltration Expertise)"] = {
				actions = {
					{ type = "effect", sName = "Steady Aim; ADVATK", sTargeting = "self", sApply = "roll", nDuration = 1, },
				},
			},
		},
	},
	["envenomweapons"] = {
		multiple_actions = {
			["Poison (Envenomed)"] = {
				actions = {
					{ type = "damage", clauses = { { dice = { "d6", "d6", }, dmgtype = "poison", }, }, },
				},
				group = "Sneak Attack (Rogue)",
				ability = "dexterity",
			},
		},
	},
	["deathstrike"] = {
		actions = {
			{ type = "powersave", save = "wisdom", savestat = "dexterity", },
		},
		group = "Sneak Attack (Rogue)",
		ability = "dexterity",
	},
	-- Rogue - Soulknife
	["psionicpowersoulknife"] = {
		multiple_actions = {
			["Psionic Energy"] = {
				actions = {},
				group = "Psionic Energy (Rogue)",
				ability = "intelligence",
				prepared = 4,
				usesperiod = "dual",
			},
			["Psi-Bolstered Knack"] = {
				actions = {},
				group = "Psionic Energy (Rogue)",
				ability = "intelligence",
			},
			["Psychic Whispers"] = {
				actions = {},
				group = "Psionic Energy (Rogue)",
				ability = "intelligence",
				prepared = 1,
			},
		},
	},
	["psychicblades"] = {
		actions = {},
	},
	["soulblades"] = {
		multiple_actions = {
			["Homing Strikes"] = {
				actions = {},
				group = "Psionic Energy (Rogue)",
				ability = "intelligence",
			},
			["Psychic Teleportation"] = {
				actions = {},
				group = "Psionic Energy (Rogue)",
				ability = "intelligence",
			},
		},
	},
	["psychicveil"] = {
		actions = {
			{ type = "effect", sName = "Psychic Veil; Invisible", sTargeting = "self", nDuration = 1, sUnits = "hour", },
		},
		prepared = 1,
	},
	["rendmind"] = {
		actions = {
			{ type = "powersave", save = "wisdom", savestat = "dexterity", magic = true, },
			{ type = "effect", sName = "Rend Mind; Stunned; NOTE: Save at end of round", nDuration = 1, sUnits = "minute", },
		},
		prepared = 1,
	},
	-- Rogue - Thief
	["fasthands"] = {
		actions = {},
	},
	["secondstorywork"] = {
		specialmoves = { ["Climb"] = true, },
		actions = {},
	},
	["supremesneak"] = {
		multiple_actions = {
			["Stealth (Cost 1d6)"] = {
				actions = {},
				group = "Sneak Attack (Rogue)",
				ability = "dexterity",
			},
		},
	},
	["usemagicdevice"] = {
		actions = {},
	},
	["thiefsreflexes"] = {
		actions = {},
	},

	-- Sorcerer
	["innatesorcery"] = {
		actions = {
			{ type = "effect", sName = "Innate Sorcery; SAVEDC: 1; ADVATK", sTargeting = "self", nDuration = 1, sUnits = "minute", },
		},
		prepared = 2,
	},
	["fontofmagic"] = {
		multiple_actions = {
			["Sorcery Points"] = {
				actions = {},
				group = "Sorcery Points (Sorcerer)",
				ability = "charisma",
				prepared = 2,
			},
			["Spell Slot to Sorcery Points"] = {
				actions = {},
				group = "Sorcery Points (Sorcerer)",
				ability = "charisma",
			},
			["Sorcery Points to Spell Slot"] = {
				actions = {},
				group = "Sorcery Points (Sorcerer)",
				ability = "charisma",
			},
		},
	},
	["metamagic"] = {
		choicetype = "Metamagic",
		choicenum = 2,
	},
	["extrametamagic"] = {
		choicetype = "Metamagic",
		choicenum = 2,
		choiceskipadd = true,
	},
	["sorcerousrestoration"] = {
		actions = {},
		group = "Sorcery Points (Sorcerer)",
		ability = "charisma",
		prepared = 1,
	},
	["sorceryincarnate"] = {
		multiple_actions = {
			["Innate Sorcery (Sorcery Incarnate)"] = {
				actions = {},
			},
		},
	},
	["arcaneapotheosis"] = {
		multiple_actions = {
			["Innate Sorcery (Arcane Apotheosis)"] = {
				actions = {},
			},
		},
	},
	["metamagiccarefulspell"] = {
		multiple_actions = {
			["Careful Spell (Cost 1)"] = {
				actions = {},
				group = "Sorcery Points (Sorcerer)",
				ability = "charisma",
			},
		},
	},
	["metamagicdistantspell"] = {
		multiple_actions = {
			["Distant Spell (Cost 1)"] = {
				actions = {},
				group = "Sorcery Points (Sorcerer)",
				ability = "charisma",
			},
		},
	},
	["metamagicempoweredspell"] = {
		multiple_actions = {
			["Empowered Spell (Cost 1)*"] = {
				actions = {},
				group = "Sorcery Points (Sorcerer)",
				ability = "charisma",
			},
		},
	},
	["metamagicextendedspell"] = {
		multiple_actions = {
			["Extended Spell (Cost 1)"] = {
				actions = {
					{ type = "effect", sName = "Extended Spell; ADVCONC; (C)", },
				},
				group = "Sorcery Points (Sorcerer)",
				ability = "charisma",
			},
		},
	},
	["metamagicheightenedspell"] = {
		multiple_actions = {
			["Heightened Spell (Cost 2)"] = {
				actions = {
					{ type = "effect", sName = "Heightened Spell; DISSAV", sApply = "roll", nDuration = 1, },
				},
				group = "Sorcery Points (Sorcerer)",
				ability = "charisma",
			},
		},
	},
	["metamagicquickenedspell"] = {
		multiple_actions = {
			["Quickened Spell (Cost 2)"] = {
				actions = {},
				group = "Sorcery Points (Sorcerer)",
				ability = "charisma",
			},
		},
	},
	["metamagicseekingspell"] = {
		multiple_actions = {
			["Seeking Spell (Cost 1)*"] = {
				actions = {},
				group = "Sorcery Points (Sorcerer)",
				ability = "charisma",
			},
		},
	},
	["metamagicsubtlespell"] = {
		multiple_actions = {
			["Subtle Spell (Cost 1)"] = {
				actions = {},
				group = "Sorcery Points (Sorcerer)",
				ability = "charisma",
			},
		},
	},
	["metamagictransmutedspell"] = {
		multiple_actions = {
			["Transmuted Spell (Cost 1)"] = {
				actions = {},
				group = "Sorcery Points (Sorcerer)",
				ability = "charisma",
			},
		},
	},
	["metamagictwinnedspell"] = {
		multiple_actions = {
			["Twinned Spell (Cost 1)"] = {
				actions = {},
				group = "Sorcery Points (Sorcerer)",
				ability = "charisma",
			},
		},
	},
	-- Sorcerer - Aberrant Sorcery
	["psionicspells"] = {
		spells = {
			{ name = "Arms of Hadar" },
			{ name = "Calm Emotions" },
			{ name = "Detect Thoughts" },
			{ name = "Dissonant Whispers" },
			{ name = "Mind Sliver" },
			["group"] = "Spells (Sorcerer)",
			["ability"] = "charisma",
		},
	},
	["psionicspellsl5"] = {
		spells = {
			{ name = "Hunger of Hadar" },
			{ name = "Sending" },
			["group"] = "Spells (Sorcerer)",
			["ability"] = "charisma",
		},
	},
	["psionicspellsl7"] = {
		spells = {
			{ name = "Evard's Black Tentacles" },
			{ name = "Summon Aberration" },
			["group"] = "Spells (Sorcerer)",
			["ability"] = "charisma",
		},
	},
	["psionicspellsl9"] = {
		spells = {
			{ name = "Rary's Telepathic Bond" },
			{ name = "Telekinesis" },
			["group"] = "Spells (Sorcerer)",
			["ability"] = "charisma",
		},
	},
	["telepathicspeech"] = {
		actions = {
			{ type = "effect", sName = "Telepathic Speech", nDuration = 3, sUnits = "minute", },
		},
	},
	["psionicsorcery"] = {
		multiple_actions = {
			["Psionic Sorcery"] = {
				actions = {},
				group = "Sorcery Points (Sorcerer)",
				ability = "charisma",
			},
		},
	},
	["psionicdefenses"] = {
		actions = {
			{ type = "effect", sName = "Psionic Defenses; RESIST: psychic; NOTE: ADV on Saves vs. Charmed/Frightened", sTargeting = "self" },
		},
	},
	["revelationinflesh"] = {
		multiple_actions = {
			["Aquatic Adaptation"] = {
				actions = {
					{ type = "effect", sName = "Aquatic Adaptation; Swim Speed x2; Breathe Underwater", sTargeting = "self", nDuration = 10, sUnits = "minute", },
				},
				group = "Sorcery Points (Sorcerer)",
				ability = "charisma",
			},
			["Glistening Flight"] = {
				actions = {
					{ type = "effect", sName = "Glistening Flight; Fly Speed; Hover", sTargeting = "self", nDuration = 10, sUnits = "minute", },
				},
				group = "Sorcery Points (Sorcerer)",
				ability = "charisma",
			},
			["See the Invisible"] = {
				actions = {
					{ type = "effect", sName = "See the Invisible", sTargeting = "self", nDuration = 10, sUnits = "minute", },
				},
				group = "Sorcery Points (Sorcerer)",
				ability = "charisma",
			},
			["Wormlike Movement"] = {
				actions = {
					{ type = "effect", sName = "Wormlike Movement", sTargeting = "self", nDuration = 10, sUnits = "minute", },
				},
				group = "Sorcery Points (Sorcerer)",
				ability = "charisma",
			},
		},
	},
	["warpingimplosion"] = {
		actions = {
			{ type = "powersave", save = "strength", savestat = "charisma", magic = true, onmissdamage = "half", },
			{ type = "damage", clauses = { { dice = { "d10", "d10", "d10", }, dmgtype = "force" }, }, },
		},
		prepared = 1,
	},
	-- Sorcerer - Clockwork Sorcery
	["clockworkspells"] = {
		spells = {
			{ name = "Aid" },
			{ name = "Alarm" },
			{ name = "Lesser Restoration" },
			{ name = "Protection from Evil and Good" },
			["group"] = "Spells (Sorcerer)",
			["ability"] = "charisma",
		},
	},
	["clockworkspellsl5"] = {
		spells = {
			{ name = "Dispel Magic" },
			{ name = "Protection From Energy" },
			["group"] = "Spells (Sorcerer)",
			["ability"] = "charisma",
		},
	},
	["clockworkspellsl7"] = {
		spells = {
			{ name = "Freedom of Movement" },
			{ name = "Summon Construct" },
			["group"] = "Spells (Sorcerer)",
			["ability"] = "charisma",
		},
	},
	["clockworkspellsl9"] = {
		spells = {
			{ name = "Greater Restoration" },
			{ name = "Wall of Force" },
			["group"] = "Spells (Sorcerer)",
			["ability"] = "charisma",
		},
	},
	["manifestationsoforder"] = {
		actions = {},
	},
	["restorebalance"] = {
		actions = {},
		prepared = 1,
	},
	["bastionoflaw"] = {
		actions = {
			{ type = "effect", sName = "Bastion of Law (1d8)", },
			{ type = "effect", sName = "Bastion of Law (2d8)", },
			{ type = "effect", sName = "Bastion of Law (3d8)", },
			{ type = "effect", sName = "Bastion of Law (4d8)", },
			{ type = "effect", sName = "Bastion of Law (5d8)", },
		},
		group = "Sorcery Points (Sorcerer)",
		ability = "charisma",
	},
	["tranceoforder"] = {
		actions = {
			{ type = "effect", sName = "Trance of Order; RELIABLE; NOTE: Negate ADV on attacks", sTargeting = "self", nDuration = 1, sUnits = "minute", },
		},
		prepared = 1,
	},
	["clockworkcavalcade"] = {
		actions = {
			{ type = "heal", clauses = { { bonus = 100 }, }, },
		},
		prepared = 1,
	},
	-- Sorcerer - Draconic Sorcery
	["draconicspells"] = {
		spells = {
			{ name = "Alter Self" },
			{ name = "Chromatic Orb" },
			{ name = "Command" },
			{ name = "Dragon's Breath" },
			["group"] = "Spells (Sorcerer)",
			["ability"] = "charisma",
		},
	},
	["draconicspellsl5"] = {
		spells = {
			{ name = "Fear" },
			{ name = "Fly" },
			["group"] = "Spells (Sorcerer)",
			["ability"] = "charisma",
		},
	},
	["draconicspellsl7"] = {
		spells = {
			{ name = "Arcane Eye" },
			{ name = "Charm Monster" },
			["group"] = "Spells (Sorcerer)",
			["ability"] = "charisma",
		},
	},
	["draconicspellsl9"] = {
		spells = {
			{ name = "Legend Lore" },
			{ name = "Summon Dragon" },
			["group"] = "Spells (Sorcerer)",
			["ability"] = "charisma",
		},
	},
	["elementalaffinity"] = {
		actions = {
			{ type = "effect", sName = "Elemental Affinity (Acid); RESIST: acid; NOTE: Add CHA to Acid damage roll", sTargeting = "self", },
			{ type = "effect", sName = "Elemental Affinity (Cold); RESIST: cold; NOTE: Add CHA to Cold damage roll", sTargeting = "self", },
			{ type = "effect", sName = "Elemental Affinity (Fire); RESIST: fire; NOTE: Add CHA to Fire damage roll", sTargeting = "self", },
			{ type = "effect", sName = "Elemental Affinity (Lightning); RESIST: lightning; NOTE: Add CHA to Lightning damage roll", sTargeting = "self", },
			{ type = "effect", sName = "Elemental Affinity (Poison); RESIST: poison; NOTE: Add CHA to Poison damage roll", sTargeting = "self", },
		},
	};
	["dragonwings"] = {
		actions = {
			{ type = "effect", sName = "Dragon Wings; Fly Speed 60", sTargeting = "self", nDuration = 1, sUnits = "hour", },
		},
		prepared = 1,
	};
	["dragoncompanion"] = {
		actions = {},
		prepared = 1,
	};
	-- Sorcerer - Wild Magic Sorcery
	["tidesofchaos"] = {
		actions = {
			{ type = "effect", sName = "Tides of Chaos; ADVATK; ADVCHK; ADVSAV", sTargeting = "self", sApply = "roll", nDuration = 1, },
		},
		prepared = 1,
	};
	["wildmagicsurge"] = {
		actions = {},
	};
	["bendluck"] = {
		actions = {},
		group = "Sorcery Points (Sorcerer)",
		ability = "charisma",
	},
	["controlledchaos"] = {
		multiple_actions = {
			["Wild Magic Surge (Controlled Chaos)"] = {
				actions = {},
			},
		},
	};
	["tamedsurge"] = {
		multiple_actions = {
			["Wild Magic Surge (Tamed Surge)"] = {
				actions = {},
				prepared = 1,
			},
		},
	};

	-- Warlock
	["eldritchinvocations"] = {
		choicetype = "Eldritch Invocation",
		choicenum = 1,
	},
	["extraeldritchinvocations"] = {
		choicetype = "Eldritch Invocation",
		choicenum = 2,
		choiceskipadd = true,
	},
	["extraeldritchinvocation"] = {
		choicetype = "Eldritch Invocation",
		choicenum = 1,
		choiceskipadd = true,
	},
	["magicalcunning"] = {
		actions = {},
		prepared = 1,
	},
	["contactpatron"] = {
		spells = {
			{ name = "Contact Other Plane" },
			["group"] = "Spells (Warlock)",
			["ability"] = "charisma",
		},
		actions = {},
		prepared = 1,
	},
	["mysticarcanuml6"] = {
		actions = {},
		prepared = 1,
	},
	["mysticarcanuml7"] = {
		actions = {},
		prepared = 1,
	},
	["mysticarcanuml8"] = {
		actions = {},
		prepared = 1,
	},
	["mysticarcanuml9"] = {
		actions = {},
		prepared = 1,
	},
	["eldritchmaster"] = {
		multiple_actions = {
			["Magical Cunning (Eldritch Master)"] = {
				actions = {},
			},
		},
	},
	["eldritchinvocationagonizingblast"] = {
		multiple_actions = {
			["Agonizing Blast"] = {
				actions = {
					{ type = "effect", sName = "Agonizing Blast; DMG: [CHA]", sTargeting = "self", sApply = "roll", nDuration = 1, },
				},
				group = "Eldritch Invocations (Warlock)",
				ability = "charisma",
			},
		},
	},
	["eldritchinvocationarmorofshadows"] = {
		multiple_actions = {
			["Armor of Shadows"] = {
				actions = {},
				group = "Eldritch Invocations (Warlock)",
				ability = "charisma",
			},
		},
	},
	["eldritchinvocationascendantstep"] = {
		multiple_actions = {
			["Ascendant Step"] = {
				actions = {},
				group = "Eldritch Invocations (Warlock)",
				ability = "charisma",
			},
		},
	},
	["eldritchinvocationdevilssight"] = {
		senses = { ["Devil's Sight"] = 30, },
	},
	["eldritchinvocationdevouringblade"] = {
		multiple_actions = {
			["Devouring Blade"] = {
				actions = {},
				group = "Eldritch Invocations (Warlock)",
				ability = "charisma",
			},
		},
	},
	["eldritchinvocationeldritchsmite"] = {
		multiple_actions = {
			["Eldritch Smite"] = {
				actions = {
					{ type = "effect", sName = "Eldritch Smite; DMG: 1d8 force", sTargeting = "self", sApply = "roll", nDuration = 1, },
					{ type = "effect", sName = "Eldritch Smite; DMG: 2d8 force", sTargeting = "self", sApply = "roll", nDuration = 1, },
					{ type = "effect", sName = "Eldritch Smite; DMG: 3d8 force", sTargeting = "self", sApply = "roll", nDuration = 1, },
					{ type = "effect", sName = "Eldritch Smite; DMG: 4d8 force", sTargeting = "self", sApply = "roll", nDuration = 1, },
					{ type = "effect", sName = "Eldritch Smite; DMG: 5d8 force", sTargeting = "self", sApply = "roll", nDuration = 1, },
					{ type = "effect", sName = "Prone", },
				},
				group = "Eldritch Invocations (Warlock)",
				ability = "charisma",
			},
		},
	},
	["eldritchinvocationeldritchspear"] = {
		multiple_actions = {
			["Eldritch Spear"] = {
				actions = {},
				group = "Eldritch Invocations (Warlock)",
				ability = "charisma",
			},
		},
	},
	["eldritchinvocationfiendishvigor"] = {
		multiple_actions = {
			["Fiendish Vigor"] = {
				actions = {
					{ type = "heal", subtype = "temp", clauses = { { modifier = 12, }, }, },
				},
				group = "Eldritch Invocations (Warlock)",
				ability = "charisma",
			},
		},
	},
	["eldritchinvocationgazeoftwominds"] = {
		multiple_actions = {
			["Gaze of Two Minds"] = {
				actions = {
					{ type = "effect", sName = "Gaze of Two Minds; NOTE: Bonus action to extend", },
				},
				group = "Eldritch Invocations (Warlock)",
				ability = "charisma",
			},
		},
	},
	["eldritchinvocationgiftofthedepths"] = {
		specialmoves = { ["Swim"] = true, },
		multiple_actions = {
			["Gift of the Depths"] = {
				actions = {},
				group = "Eldritch Invocations (Warlock)",
				ability = "charisma",
				prepared = 1,
			},
		},
	},
	["eldritchinvocationgiftoftheprotectors"] = {
		multiple_actions = {
			["Gift of the Protectors"] = {
				actions = {
					{ type = "heal", clauses = { { modifier = 1, }, }, },
				},
				group = "Eldritch Invocations (Warlock)",
				ability = "charisma",
			},
		},
	},
	["eldritchinvocationinvestmentofthechainmaster"] = {
		multiple_actions = {
			["Investment of the Chain Master"] = {
				actions = {
					{ type = "effect", sName = "Investment of the Chain Master; Fly Speed 40", },
					{ type = "effect", sName = "Investment of the Chain Master; Swim Speed 40", },
					{ type = "effect", sName = "Investment of the Chain Master; DMGTYPE: necrotic", },
					{ type = "effect", sName = "Investment of the Chain Master; DMGTYPE: radiant", },
					{ type = "effect", sName = "Investment of the Chain Master; RESIST: all", sApply = "roll", nDuration = 1, },
				},
				group = "Eldritch Invocations (Warlock)",
				ability = "charisma",
			},
		},
	},
	["eldritchinvocationlifedrinker"] = {
		multiple_actions = {
			["Lifedrinker"] = {
				actions = {
					{ type = "effect", sName = "Lifedrinker; DMG: 1d6 necrotic", sTargeting = "self", sApply = "roll", nDuration = 1, },
					{ type = "effect", sName = "Lifedrinker; DMG: 1d6 psychic", sTargeting = "self", sApply = "roll", nDuration = 1, },
					{ type = "effect", sName = "Lifedrinker; DMG: 1d6 radiant", sTargeting = "self", sApply = "roll", nDuration = 1, },
				},
				group = "Eldritch Invocations (Warlock)",
				ability = "charisma",
			},
		},
	},
	["eldritchinvocationmaskofmanyfaces"] = {
		multiple_actions = {
			["Mask of Many Faces"] = {
				actions = {},
				group = "Eldritch Invocations (Warlock)",
				ability = "charisma",
			},
		},
	},
	["eldritchinvocationmasterofmyriadforms"] = {
		multiple_actions = {
			["Master of Myriad Forms"] = {
				actions = {},
				group = "Eldritch Invocations (Warlock)",
				ability = "charisma",
			},
		},
	},
	["eldritchinvocationmistyvisions"] = {
		multiple_actions = {
			["Misty Visions"] = {
				actions = {},
				group = "Eldritch Invocations (Warlock)",
				ability = "charisma",
			},
		},
	},
	["eldritchinvocationonewithshadows"] = {
		multiple_actions = {
			["One with Shadows"] = {
				actions = {},
				group = "Eldritch Invocations (Warlock)",
				ability = "charisma",
			},
		},
	},
	["eldritchinvocationotherworldlyleap"] = {
		multiple_actions = {
			["Otherworldly Leap"] = {
				actions = {},
				group = "Eldritch Invocations (Warlock)",
				ability = "charisma",
			},
		},
	},
	["eldritchinvocationpactoftheblade"] = {
		multiple_actions = {
			["Pact of the Blade"] = {
				actions = {
					{ type = "effect", sName = "Pact of the Blade; DMGTYPE: necrotic", },
					{ type = "effect", sName = "Pact of the Blade; DMGTYPE: psychic", },
					{ type = "effect", sName = "Pact of the Blade; DMGTYPE: radiant", },
				},
				group = "Eldritch Invocations (Warlock)",
				ability = "charisma",
			},
		},
	},
	["eldritchinvocationpactofthechain"] = {
		multiple_actions = {
			["Pact of the Chain"] = {
				actions = {},
				group = "Eldritch Invocations (Warlock)",
				ability = "charisma",
			},
		},
	},
	["eldritchinvocationpactofthetome"] = {
		multiple_actions = {
			["Pact of the Tome"] = {
				actions = {},
				group = "Eldritch Invocations (Warlock)",
				ability = "charisma",
			},
		},
	},
	["eldritchinvocationrepellingblast"] = {
		multiple_actions = {
			["Repelling Blast"] = {
				actions = {},
				group = "Eldritch Invocations (Warlock)",
				ability = "charisma",
			},
		},
	},
	["eldritchinvocationthirstingblade"] = {
		multiple_actions = {
			["Thirsting Blade"] = {
				actions = {},
				group = "Eldritch Invocations (Warlock)",
				ability = "charisma",
			},
		},
	},
	["eldritchinvocationvisionsofdistantrealms"] = {
		multiple_actions = {
			["Visions of Distant Realms"] = {
				actions = {},
				group = "Eldritch Invocations (Warlock)",
				ability = "charisma",
			},
		},
	},
	["eldritchinvocationwhispersofthegrave"] = {
		multiple_actions = {
			["Whispers of the Grave"] = {
				actions = {},
				group = "Eldritch Invocations (Warlock)",
				ability = "charisma",
			},
		},
	},
	["eldritchinvocationwitchsight"] = {
		senses = { ["Truesight"] = 30, },
	},
	-- Warlock - Archfey Patron
	["archfeyspells"] = {
		spells = {
			{ name = "Calm Emotions" },
			{ name = "Faerie Fire" },
			{ name = "Misty Step" },
			{ name = "Phantasmal Force" },
			{ name = "Sleep" },
			["group"] = "Spells (Warlock)",
			["ability"] = "charisma",
		},
	},
	["archfeyspellsl5"] = {
		spells = {
			{ name = "Blink" },
			{ name = "Plant Growth" },
			["group"] = "Spells (Warlock)",
			["ability"] = "charisma",
		},
	},
	["archfeyspellsl7"] = {
		spells = {
			{ name = "Dominate Beast" },
			{ name = "Greater Invisibility" },
			["group"] = "Spells (Warlock)",
			["ability"] = "charisma",
		},
	},
	["archfeyspellsl9"] = {
		spells = {
			{ name = "Dominate Person" },
			{ name = "Seeming" },
			["group"] = "Spells (Warlock)",
			["ability"] = "charisma",
		},
	},
	["stepsofthefey"] = {
		multiple_actions = {
			["Steps of the Fey"] = {
				actions = {},
				group = "Misty Step (Warlock)",
				ability = "charisma",
				prepared = 1,
			},
			["Refreshing Step"] = {
				actions = {
					{ type = "heal", subtype = "temp", clauses = { { dice = { "d10" }, }, }, },
				},
				group = "Misty Step (Warlock)",
				ability = "charisma",
			},
			["Taunting Step"] = {
				actions = {
					{ type = "powersave", save = "wisdom", savestat = "charisma", },
					{ type = "effect", sName = "Steps of the Fey; DISATK", nDuration = 1, },
				},
				group = "Misty Step (Warlock)",
				ability = "charisma",
			},
		},
	},
	["mistyescape"] = {
		multiple_actions = {
			["Disappearing Step"] = {
				actions = {
					{ type = "effect", sName = "Disappearing Step; Invisible", sTargeting = "self", nDuration = 1, },
				},
				group = "Misty Step (Warlock)",
				ability = "charisma",
			},
			["Dreadful Step"] = {
				actions = {
					{ type = "powersave", save = "wisdom", savestat = "charisma", },
					{ type = "damage", clauses = { { dice = { "d10", "d10", }, dmgtype = "psychic" }, }, },
				},
				group = "Misty Step (Warlock)",
				ability = "charisma",
			},
		},
	},
	["beguilingdefenses"] = {
		multiple_actions = {
			["Beguiling Defenses"] = {
				actions = {
					{ type = "effect", sName = "Beguiling Defenses; IMMUNE: Charmed", sTargeting = "self", nDuration = 1, },
				},
			},
			["Beguiling Defenses (Reaction)"] = {
				actions = {
					{ type = "powersave", save = "wisdom", savestat = "charisma", },
				},
				prepared = 1,
			},
		},
	},
	["bewitchingmagic"] = {
		actions = {},
	},
	-- Warlock - Celestial Patron
	["celestialspells"] = {
		spells = {
			{ name = "Aid" },
			{ name = "Cure Wounds" },
			{ name = "Guiding Bolt" },
			{ name = "Lesser Restoration" },
			{ name = "Light" },
			{ name = "Sacred Flame" },
			["group"] = "Spells (Warlock)",
			["ability"] = "charisma",
		},
	},
	["celestialspellsl5"] = {
		spells = {
			{ name = "Daylight" },
			{ name = "Revivify" },
			["group"] = "Spells (Warlock)",
			["ability"] = "charisma",
		},
	},
	["celestialspellsl7"] = {
		spells = {
			{ name = "Guardian of Faith" },
			{ name = "Wall of Fire" },
			["group"] = "Spells (Warlock)",
			["ability"] = "charisma",
		},
	},
	["celestialspellsl9"] = {
		spells = {
			{ name = "Greater Restoration" },
			{ name = "Summon Celestial" },
			["group"] = "Spells (Warlock)",
			["ability"] = "charisma",
		},
	},
	["healinglight"] = {
		actions = {
			{ type = "heal", clauses = { { dice = { "d6" }, }, }, },
		},
		prepared = 4,
	},
	["radiantsoul"] = {
		actions = {
			{ type = "effect", sName = "Radiant Soul; RESIST: radiant", sTargeting = "self", },
			{ type = "effect", sName = "Radiant Soul (Damage); DMG: [CHA] fire", sTargeting = "self", sApply = "roll", nDuration = 1, },
			{ type = "effect", sName = "Radiant Soul (Damage); DMG: [CHA] radiant", sTargeting = "self", sApply = "roll", nDuration = 1, },
		},
	},
	["celestialresilience"] = {
		actions = {
			{ type = "heal", subtype = "temp", clauses = { { stat = "warlock" }, { stat = "charisma" }, }, },
			{ type = "heal", subtype = "temp", clauses = { { statmult = 0.5, stat = "warlock" }, { stat = "charisma" }, }, },
		},
	},
	["searingvengeance"] = {
		actions = {
			{ type = "heal", clauses = {}, },
			{ type = "damage", clauses = { { dice = { "d8", "d8", }, dmgtype = "radiant", stat = "charisma" }, }, },
			{ type = "effect", sName = "Blinded", nDuration = 1, },
		},
		prepared = 1,
	},
	-- Warlock - Fiend Patron
	["fiendspells"] = {
		spells = {
			{ name = "Burning Hands" },
			{ name = "Command" },
			{ name = "Scorching Ray" },
			{ name = "Suggestion" },
			["group"] = "Spells (Warlock)",
			["ability"] = "charisma",
		},
	},
	["fiendspellsl5"] = {
		spells = {
			{ name = "Fireball" },
			{ name = "Stinking Cloud" },
			["group"] = "Spells (Warlock)",
			["ability"] = "charisma",
		},
	},
	["fiendspellsl7"] = {
		spells = {
			{ name = "Fire Shield" },
			{ name = "Wall of Fire" },
			["group"] = "Spells (Warlock)",
			["ability"] = "charisma",
		},
	},
	["fiendspellsl9"] = {
		spells = {
			{ name = "Geas" },
			{ name = "Insect Plague" },
			["group"] = "Spells (Warlock)",
			["ability"] = "charisma",
		},
	},
	["darkonesblessing"] = {
		actions = {
			{ type = "heal", subtype = "temp", sTargeting = "self", clauses = { { stat = "warlock" }, { stat = "charisma" }, }, },
		},
	},
	["darkonesownluck"] = {
		actions = {
			{ type = "effect", sName = "Dark One's Own Luck; CHECK: 1d10; SAVE: 1d10", sApply = "roll", sTargeting = "self", nDuration = 1, },
		},
		prepared = 1,
	},
	["fiendishresilience"] = {
		actions = {
			{ type = "effect", sName = "Fiendish Resilience (Acid); RESIST: acid", sTargeting = "self", },
			{ type = "effect", sName = "Fiendish Resilience (Bludgeoning); RESIST: bludgeoning", sTargeting = "self", },
			{ type = "effect", sName = "Fiendish Resilience (Cold); RESIST: cold", sTargeting = "self", },
			{ type = "effect", sName = "Fiendish Resilience (Fire); RESIST: fire", sTargeting = "self", },
			{ type = "effect", sName = "Fiendish Resilience (Lightning); RESIST: lightning", sTargeting = "self", },
			{ type = "effect", sName = "Fiendish Resilience (Necrotic); RESIST: necrotic", sTargeting = "self", },
			{ type = "effect", sName = "Fiendish Resilience (Piercing); RESIST: piercing", sTargeting = "self", },
			{ type = "effect", sName = "Fiendish Resilience (Poison); RESIST: poison", sTargeting = "self", },
			{ type = "effect", sName = "Fiendish Resilience (Psychic); RESIST: psychic", sTargeting = "self", },
			{ type = "effect", sName = "Fiendish Resilience (Slashing); RESIST: slashing", sTargeting = "self", },
			{ type = "effect", sName = "Fiendish Resilience (Radiant); RESIST: radiant", sTargeting = "self", },
			{ type = "effect", sName = "Fiendish Resilience (Thunder); RESIST: thunder", sTargeting = "self", },
		},
	},
	["hurlthroughhell"] = {
		actions = {
			{ type = "powersave", save = "charisma", savestat = "charisma", },
			{ type = "damage", clauses = { { dice = { "d10", "d10", "d10", "d10", "d10", "d10", "d10", "d10", }, dmgtype = "psychic" }, }, },
			{ type = "effect", sName = "Hurl Through Hell; NOTE: Removed from plane; Incapacitated", nDuration = 1, },
		},
		prepared = 1,
	},
	-- Warlock - Great Old One Patron
	["greatoldonespells"] = {
		spells = {
			{ name = "Detect Thoughts" },
			{ name = "Dissonant Whispers" },
			{ name = "Phantasmal Force" },
			{ name = "Tasha's Hideous Laughter" },
			["group"] = "Spells (Warlock)",
			["ability"] = "charisma",
		},
	},
	["greatoldonespellsl5"] = {
		spells = {
			{ name = "Clairvoyance" },
			{ name = "Hunger of Hadar" },
			["group"] = "Spells (Warlock)",
			["ability"] = "charisma",
		},
	},
	["greatoldonespellsl7"] = {
		spells = {
			{ name = "Confusion" },
			{ name = "Summon Aberration" },
			["group"] = "Spells (Warlock)",
			["ability"] = "charisma",
		},
	},
	["greatoldonespellsl9"] = {
		spells = {
			{ name = "Modify Memory" },
			{ name = "Telekinesis" },
			["group"] = "Spells (Warlock)",
			["ability"] = "charisma",
		},
	},
	["awakenedmind"] = {
		actions = {
			{ type = "effect", sName = "Awakened Mind", nDuration = 1, sUnits = "minute", },
		},
	},
	["psychicspells"] = {
		actions = {
			{ type = "effect", sName = "Psychic Spells; DMGTYPE: psychic", sTargeting = "self", sApply = "roll", nDuration = 1, },
		},
	},
	["clairvoyantcombatant"] = {
		multiple_actions = {
			["Awakened Mind (Clairvoyant Combatant)"] = {
				actions = {
					{ type = "powersave", save = "wisdom", savestat = "charisma", },
					{ type = "effect", sName = "[TRGT]; Awakened Mind (Enemy); DISATK; GRANTADVATK", nDuration = 1, sUnits = "minute", },
				},
				prepared = 1,
				usesperiod = "enc",
			},
		},
	},
	["eldritchhex"] = {
		spells = {
			{ name = "Hex" },
			["group"] = "Spells (Warlock)",
			["ability"] = "charisma",
		},
		actions = {
			{ type = "effect", sName = "DISSAV: strength; (C)", nDuration = 1, sUnits = "hour" },
			{ type = "effect", sName = "DISSAV: dexterity; (C)", nDuration = 1, sUnits = "hour" },
			{ type = "effect", sName = "DISSAV: constitution; (C)", nDuration = 1, sUnits = "hour" },
			{ type = "effect", sName = "DISSAV: intelligence; (C)", nDuration = 1, sUnits = "hour" },
			{ type = "effect", sName = "DISSAV: wisdom; (C)", nDuration = 1, sUnits = "hour" },
			{ type = "effect", sName = "DISSAV: charisma; (C)", nDuration = 1, sUnits = "hour" },
		},
	},
	["thoughtshield"] = {
		actions = {
			{ type = "effect", sName = "Thought Shield; RESIST: psychic", sTargeting = "self", },
		},
	},
	["createthrall"] = {
		actions = {
			{ type = "heal", subtype = "temp", clauses = { { stat = "warlock" }, { stat = "charisma" }, }, },
		},
	},

	-- Wizard
	["arcanerecovery"] = {
		actions = {},
		prepared = 1,
	},
	["ritualadept"] = {
		actions = {},
	},
	["scholar"] = {
		skill = { choice = 1, choice_skill = { "Arcana", "History", "Investigation", "Medicine", "Nature", "Religion" }, },
	},
	["memorizespell"] = {
		actions = {},
		prepared = 1,
		usesperiod = "enc",
	},
	["spellmastery"] = {
		actions = {},
	},
	["signaturespells"] = {
		actions = {},
	},
	-- Wizard - Abjurer
	["abjurationsavant"] = {
		actions = {},
	},
	["arcaneward"] = {
		actions = {},
	},
	["projectedward"] = {
		multiple_actions = {
			["Arcane Ward (Projected Ward)"] = {
				actions = {},
			},
		},
	},
	["spellbreaker"] = {
		spells = {
			{ name = "Counterspell" },
			{ name = "Dispel Magic" },
			["group"] = "Spells (Wizard)",
			["ability"] = "intelligence",
		},
		actions = {
			{ type = "effect", sName = "Spell Breaker; CHECK: [INT]", sTargeting = "self", sApply = "roll", nDuration = 1, },
		},
	},
	["spellresistance"] = {
		actions = {
			{ type = "effect", sName = "Spell Resistance; NOTE: ADV to Saves vs. Spells; NOTE: Resistance to Spells", sTargeting = "self" },
		},
	},
	-- Wizard - Diviner
	["divinationsavant"] = {
		actions = {},
	},
	["portent"] = {
		actions = {},
	},
	["expertdivination"] = {
		actions = {},
	},
	["thethirdeye"] = {
		actions = {
			{ type = "effect", sName = "The Third Eye; VISION: 60 darkvision", sTargeting = "self" },
			{ type = "effect", sName = "The Third Eye; NOTE: Read any language", sTargeting = "self" },
			{ type = "effect", sName = "The Third Eye; NOTE: Cast See Invisibility for free", sTargeting = "self" },
		},
	},
	["greaterportent"] = {
		multiple_actions = {
			["Portent (Greater)"] = {
				actions = {},
			},
		},
	},
	-- Wizard - Evoker
	["evocationsavant"] = {
		actions = {},
	},
	["potentcantrip"] = {
		actions = {},
	},
	["sculptspells"] = {
		actions = {},
	},
	["empoweredevocation"] = {
		actions = {
			{ type = "effect", sName = "Empowered Evocation; DMGS: [INT]", sTargeting = "self", sApply = "roll", nDuration = 1, },
		},
	},
	["overchannel"] = {
		actions = {},
		prepared = 1,
	},
	-- Wizard - Illusionist
	["illusionsavant"] = {
		actions = {},
	},
	["improvedillusions"] = {
		spells = {
			{ name = "Minor Illusion" },
			["group"] = "Spells (Wizard)",
			["ability"] = "intelligence",
		},
		actions = {},
	},
	["phantasmalcreatures"] = {
		spells = {
			{ name = "Summon Beast" },
			{ name = "Summon Fey" },
			["group"] = "Spells (Wizard)",
			["ability"] = "intelligence",
		},
		actions = {},
		prepared = 1,
	},
	["illusoryself"] = {
		actions = {},
		prepared = 1,
		usesperiod = "enc",
	},
	["illusoryreality"] = {
		actions = {
			{ type = "effect", sName = "Illusory Reality", sTargeting = "self", nDuration = 1, sUnits = "minute", },
		},
		prepared = 1,
		usesperiod = "enc",
	},
};

tBuildDataSpecies2024 = {
	-- Aasimar
	["celestialresistance"] = {
		actions = {
			{ type = "effect", sName = "Celestial Resistance; RESIST: necrotic,radiant", sTargeting = "self", },
		},
	},
	["healinghands"] = {
		actions = {
			{ type = "heal", clauses = { { dice = { "d4", "d4", }, }, }, },
		},
		prepared = 1,
	},
	["celestialrevelation"] = {
		actions = {
			{ type = "effect", sName = "Celestial Revelation; DMG: [PRF] necrotic", sTargeting = "self", sApply = "action" },
			{ type = "effect", sName = "Celestial Revelation; DMG: [PRF] radiant", sTargeting = "self", sApply = "action" },
			{ type = "effect", sName = "Heavenly Wings", sTargeting = "self", nDuration = 1, sUnits = "minute" },
			{ type = "effect", sName = "Inner Radiance", sTargeting = "self", nDuration = 1, sUnits = "minute" },
			{ type = "damage", clauses = { { dice = {}, modifier = 2, dmgtype = "radiant", }, }, },
			{ type = "effect", sName = "Necrotic Shroud", sTargeting = "self", nDuration = 1, sUnits = "minute" },
			{ type = "effect", sName = "Frightened", nDuration = 1, },
		},
		prepared = 1,
	},
	["lightbearer"] = {
		spell = { innate = { "Light" }, },
	},
	-- Dragonborn
	["draconicflight"] = {
		actions = {
			{ type = "effect", sName = "Draconic Flight", sTargeting = "self", nDuration = 10, sUnits = "minute" },
		},
		prepared = 1,
	},
	["blackdragonbornbreathweapon"] = {
		actions = {
			{ type = "powersave", save = "dexterity", savestat = "constitution", onmissdamage = "half" },
			{ type = "damage", clauses = { { dice = { "d10" }, dmgtype = "acid", }, }, },
		},
	},
	["blackdragonborndamageresistance"] = {
		actions = {
			{ type = "effect", sName = "Draconic Resistance; RESIST: acid;", sTargeting = "self", },
		},
	},
	["bluedragonbornbreathweapon"] = {
		actions = {
			{ type = "powersave", save = "dexterity", savestat = "constitution", onmissdamage = "half" },
			{ type = "damage", clauses = { { dice = { "d10" }, dmgtype = "lightning", }, }, },
		},
	},
	["bluedragonborndamageresistance"] = {
		actions = {
			{ type = "effect", sName = "Draconic Resistance; RESIST: lightning;", sTargeting = "self", },
		},
	},
	["brassdragonbornbreathweapon"] = {
		actions = {
			{ type = "powersave", save = "dexterity", savestat = "constitution",  onmissdamage = "half" },
			{ type = "damage", clauses = { { dice = { "d10" }, dmgtype = "fire", }, }, },
		},
	},
	["brassdragonborndamageresistance"] = {
		actions = {
			{ type = "effect", sName = "Draconic Resistance; RESIST: fire;", sTargeting = "self", },
		},
	},
	["bronzedragonbornbreathweapon"] = {
		actions = {
			{ type = "powersave", save = "dexterity", savestat = "constitution",  onmissdamage = "half" },
			{ type = "damage", clauses = { { dice = { "d10" }, dmgtype = "lightning", }, }, },
		},
	},
	["bronzedragonborndamageresistance"] = {
		actions = {
			{ type = "effect", sName = "Draconic Resistance; RESIST: lightning;", sTargeting = "self", },
		},
	},
	["copperdragonbornbreathweapon"] = {
		actions = {
			{ type = "powersave", save = "dexterity", savestat = "constitution",  onmissdamage = "half" },
			{ type = "damage", clauses = { { dice = { "d10" }, dmgtype = "acid", }, }, },
		},
	},
	["copperdragonborndamageresistance"] = {
		actions = {
			{ type = "effect", sName = "Draconic Resistance; RESIST: acid;", sTargeting = "self", },
		},
	},
	["golddragonbornbreathweapon"] = {
		actions = {
			{ type = "powersave", save = "dexterity", savestat = "constitution",  onmissdamage = "half" },
			{ type = "damage", clauses = { { dice = { "d10" }, dmgtype = "fire", }, }, },
		},
	},
	["golddragonborndamageresistance"] = {
		actions = {
			{ type = "effect", sName = "Draconic Resistance; RESIST: fire;", sTargeting = "self", },
		},
	},
	["greendragonbornbreathweapon"] = {
		actions = {
			{ type = "powersave", save = "constitution", savestat = "constitution",  onmissdamage = "half" },
			{ type = "damage", clauses = { { dice = { "d10" }, dmgtype = "poison", }, }, },
		},
	},
	["greendragonborndamageresistance"] = {
		actions = {
			{ type = "effect", sName = "Draconic Resistance; RESIST: poison;", sTargeting = "self", },
		},
	},
	["reddragonbornbreathweapon"] = {
		actions = {
			{ type = "powersave", save = "dexterity", savestat = "constitution", onmissdamage = "half" },
			{ type = "damage", clauses = { { dice = { "d10" }, dmgtype = "fire", }, }, },
		},
	},
	["reddragonborndamageresistance"] = {
		actions = {
			{ type = "effect", sName = "Draconic Resistance; RESIST: fire;", sTargeting = "self", },
		},
	},
	["silverdragonbornbreathweapon"] = {
		actions = {
			{ type = "powersave", save = "constitution", savestat = "constitution",  onmissdamage = "half" },
			{ type = "damage", clauses = { { dice = { "d10" }, dmgtype = "cold", }, }, },
		},
	},
	["silverdragonborndamageresistance"] = {
		actions = {
			{ type = "effect", sName = "Draconic Resistance; RESIST: cold;", sTargeting = "self", },
		},
	},
	["whitedragonbornbreathweapon"] = {
		actions = {
			{ type = "powersave", save = "constitution", savestat = "constitution",  onmissdamage = "half" },
			{ type = "damage", clauses = { { dice = { "d10" }, dmgtype = "cold", }, }, },
		},
	},
	["whitedragonborndamageresistance"] = {
		actions = {
			{ type = "effect", sName = "Draconic Resistance; RESIST: cold;", sTargeting = "self", },
		},
	},
	-- Dwarf
	["dwarvenresilience"] = {
		actions = {
			{ type = "effect", sName = "Dwarven Resilience; RESIST: poison; Advantage on saving throws vs. Poisoned", sTargeting = "self" },
		},
	},
	["stonecunning"] = {
		actions = {
			{ type = "effect", sName = "Stonecunning; VISION: tremorsense 60", sTargeting = "self", nDuration = 10, sUnits = "minute" },
		},
		prepared = 2,
	},
	-- Elf
	["feyancestry"] = {
		actions = {
			{ type = "effect", sName = "Fey Ancestry; Advantage on saving throws vs. Charmed", sTargeting = "self", },
		},
	},
	["trance"] = {
		actions = {
			{ type = "effect", sName = "Trance; Immune to magical sleep", sTargeting = "self", },
		},
	},
	-- Gnome
	["gnomishcunning"] = {
		actions = {
			{ type = "effect", sName = "Gnome Cunning; ADVSAV: intelligence,wisdom,charisma", sTargeting = "self" },
		},
	},
	-- Goliath
	["largeform"] = {
		actions = {
			{ type = "effect", sName = "Goliath Large Form; ADVCHK: strength; Increased speed", sTargeting = "self", nDuration = 10, sUnits = "minute" },
		},
		prepared = 1,
	},
	["cloudsjaunt"] = {
		actions = {},
		prepared = 2,
	},
	["firesburn"] = {
		actions = {
			{ type = "damage", clauses = { { dice = { "d10" }, dmgtype = "fire", }, }, },
		},
		prepared = 2,
	},
	["frostschill"] = {
		actions = {
			{ type = "damage", clauses = { { dice = { "d6" }, dmgtype = "cold", }, }, },
			{ type = "effect", sName = "Frost's Chill; Reduced speed", nDuration = 1, },
		},
		prepared = 2,
	},
	["hillstumble"] = {
		actions = {
			{ type = "effect", sName = "Prone" },
		},
		prepared = 2,
	},
	["stonesendurance"] = {
		actions = {},
		prepared = 2,
	},
	["stormsthunder"] = {
		actions = {
			{ type = "damage", clauses = { { dice = { "d8" }, dmgtype = "thunder", }, }, },
		},
		prepared = 2,
	},
	-- Halfling
	["brave"] = {
		actions = {
			{ type = "effect", sName = "Brave; Advantage on saving throws vs. Frightened", sTargeting = "self" },
		},
	},
	["halflingnimbleness"] = {
		actions = {
			{ type = "effect", sName = "Halfling Nimbleness; Move through space of larger creatures", },
		},
	},
	["naturallystealthy"] = {
		actions = {
			{ type = "effect", sName = "Naturally Stealthy; Hide attempt obscured by larger creature", },
		},
	},
	-- Human
	["skillful"] = {
		skill = { choice = 1, },
	},
	-- Orc
	["adrenalinerush"] = {
		actions = {
			{ type = "heal", subtype = "temp", sTargeting = "self", clauses = { { dice = {}, bonus = 2, }, }, },
		},
		prepared = 2,
	},
	["relentlessendurance"] = {
		actions = {
			{ type = "heal", sTargeting = "self", clauses = { { dice = {}, bonus = 1, }, }, },
		},
		prepared = 1,
	},
	-- Tiefling
	["fireresistance"] = {
		actions = {
			{ type = "effect", sName = "Fire Resistance; RESIST: fire", sTargeting = "self" },
		},
	},
	["necroticresistance"] = {
		actions = {
			{ type = "effect", sName = "Necrotic Resistance; RESIST: necrotic", sTargeting = "self" },
		},
	},
	["poisonresistance"] = {
		actions = {
			{ type = "effect", sName = "Poison Resistance; RESIST: poison", sTargeting = "self" },
		},
	},
};

tBuildDataFeat2024 = {
	-- Origin Feats
	["alert"] = {
		multiple_actions = {
			["Alert (Initiative Swap)"] = {
				actions = {},
			},
		},
	},
	["crafter"] = {
		multiple_actions = {
			["Crafter (Discount)"] = {
				actions = {},
			},
			["Crafter (Fast Crafting)"] = {
				actions = {},
			},
		},
	},
	["healer"] = {
		multiple_actions = {
			["Healer (Battle Medic)"] = {
				actions = {},
			},
		},
	},
	["lucky"] = {
		multiple_actions = {
			["Lucky"] = {
				actions = {
					{ type = "effect", sName = "Lucky (ADV); ADVATK; ADVCHK; ADVSAV", sTargeting = "self", sApply = "action", nDuration = 1, },
					{ type = "effect", sName = "Lucky (DIS); DISATK", sApply = "action", nDuration = 1, },
				},
				prepared = 2,
			},
		},
	},
	["musician"] = {
		multiple_actions = {
			["Musician (Encouraging Song)"] = {
				actions = {},
			},
		},
	},
	["savageattacker"] = {
		multiple_actions = {
			["Savage Attacker (Damage Reroll)"] = {
				actions = {},
			},
		},
	},
	["tavernbrawler"] = {
		multiple_actions = {
			["Tavern Brawler (Enhanced Unarmed Strike)"] = {
				actions = {
					{ type = "attack", range = "M", },
					{ type = "damage", clauses = { { dice = { "d4", }, dmgtype = "bludgeoning", stat = "strength" }, }, },
				},
			},
			["Tavern Brawler (Damage Reroll)"] = {
				actions = {},
			},
			["Tavern Brawler (Push)"] = {
				actions = {},
			},
		},
	},
	
	-- General Feats
	["actor"] = {
		multiple_actions = {
			["Actor (Impersonation)"] = {
				actions = {
					{ type = "effect", sName = "Actor (Impersonation); ADVSKILL: Deception; ADVSKILL: Performance", sTargeting = "self", sApply = "action", nDuration = 1, },
				},
			},
			["Actor (Mimicry)"] = {
				actions = {
					{ type = "powersave", save = "wisdom", savestat = "charisma", },
				},
			},
		},
	},
	["athlete"] = {
		multiple_actions = {
			["Athlete (Climb)"] = {
				actions = {
					{ type = "effect", sName = "Athlete (Climb); Climb speed", sTargeting = "self", },
				},
			},
			["Athlete (Hop Up)"] = {
				actions = {},
			},
			["Athlete (Jumping)"] = {
				actions = {},
			},
		},
	},
	["charger"] = {
		multiple_actions = {
			["Charger (Improved Dash)"] = {
				actions = {
					{ type = "effect", sName = "Charger (Improved Dash); Dash; Speed +10", sTargeting = "self", nDuration = 1, },
				},
			},
			["Charger (Charge Attack)"] = {
				actions = {
					{ type = "effect", sName = "Charger (Charge Attack); DMG: 1d8", sTargeting = "self", sApply = "action", nDuration = 1, },
				},
			},
		},
	},
	["chef"] = {
		toolprof = { innate = { "Cook's Utensils" }, },
		multiple_actions = {
			["Chef (Replenishing Meal)"] = {
				actions = {
					{ type = "effect", sName = "Chef (Replenishing Meal); HEAL: 1d8", sApply = "action", nDuration = 1, },
				},
			},
			["Chef (Bolstering Treats)"] = {
				actions = {
					{ type = "heal", subtype = "temp", clauses = { { stat = "prf", }, }, },
				},
			},
		},
	},
	["crossbowexpert"] = {
		multiple_actions = {
			["Crossbow Expert (Ignore Loading)"] = {
				actions = {},
			},
			["Crossbow Expert (Firing in Melee)"] = {
				actions = {},
			},
			["Crossbow Expert (Dual Wielding)"] = {
				actions = {},
			},
		},
	},
	["crusher"] = {
		multiple_actions = {
			["Crusher (Push)"] = {
				actions = {},
			},
			["Crusher (Enhanced Critical)"] = {
				actions = {
					{ type = "effect", sName = "Crusher (Enhanced Critical); GRANTADVATK", nDuration = 1, },
				},
			},
		},
	},
	["defensiveduelist"] = {
		multiple_actions = {
			["Defensive Duelist (Parry)"] = {
				actions = {
					{ type = "effect", sName = "Defensive Duelist (Parry); AC: [PRF]", nDuration = 1, },
				},
			},
		},
	},
	["dualwielder"] = {
		multiple_actions = {
			["Dual Wielder (Enhanced Dual Wielding)"] = {
				actions = {},
			},
			["Dual Wielder (Quick Draw)"] = {
				actions = {},
			},
		},
	},
	["durable"] = {
		multiple_actions = {
			["Durable (Defy Death)"] = {
				actions = {
					{ type = "effect", sName = "Durable (Defy Death); ADVDEATH", },
				},
			},
			["Durable (Speedy Recovery)"] = {
				actions = {},
			},
		},
	},
	["elementaladeptacid"] = {
		multiple_actions = {
			["Elemental Adept (Energy Mastery) (Acid)"] = {
				actions = {},
			},
		},
	},
	["elementaladeptcold"] = {
		multiple_actions = {
			["Elemental Adept (Energy Mastery) (Cold)"] = {
				actions = {},
			},
		},
	},
	["elementaladeptfire"] = {
		multiple_actions = {
			["Elemental Adept (Energy Mastery) (Fire)"] = {
				actions = {},
			},
		},
	},
	["elementaladeptlightning"] = {
		multiple_actions = {
			["Elemental Adept (Energy Mastery) (Lightning)"] = {
				actions = {},
			},
		},
	},
	["elementaladeptthunder"] = {
		multiple_actions = {
			["Elemental Adept (Energy Mastery) (Thunder)"] = {
				actions = {},
			},
		},
	},
	["grappler"] = {
		multiple_actions = {
			["Grappler (Punch and Grab)"] = {
				actions = {},
			},
			["Grappler (Attack Advantage)"] = {
				actions = {
					{ type = "effect", sName = "Grappler (Attack Advantage); ADVATK", sTargeting = "self", sApply = "action", nDuration = 1, },
				},
			},
			["Grappler (Fast Wrestler)"] = {
				actions = {},
			},
		},
	},
	["greatweaponmaster"] = {
		multiple_actions = {
			["Great Weapon Master (Heavy Weapon Mastery)"] = {
				actions = {
					{ type = "effect", sName = "Great Weapon Master (Heavy Weapon Mastery); DMG: [PRF]", sTargeting = "self", sApply = "action", nDuration = 1, },
				},
			},
			["Great Weapon Master (Hew)"] = {
				actions = {},
			},
		},
	},
	["heavyarmormaster"] = {
		multiple_actions = {
			["Heavy Armor Master (Damage Reduction)"] = {
				actions = {
					{ type = "effect", sName = "Heavy Armor Master (Damage Reduction); RESIST: [PRF] bludgeoning,piercing,slashing", },
				},
			},
		},
	},
	["inspiringleader"] = {
		multiple_actions = {
			["Inspiring Leader (Bolstering Performance)"] = {
				actions = {
					{ type = "heal", subtype = "temp", clauses = { { dice = {}, stat = "level", }, { dice = {}, stat = "wisdom", }, }, },
					{ type = "heal", subtype = "temp", clauses = { { dice = {}, stat = "level", }, { dice = {}, stat = "charisma", }, }, },
				},
			},
		},
	},
	["keenmind"] = {
		multiple_actions = {
			["Keen Mind (Quick Study)"] = {
				actions = {},
			},
		},
	},
	["mageslayer"] = {
		multiple_actions = {
			["Mage Slayer (Guarded Mind)"] = {
				actions = {},
				prepared = 1,
				usesperiod = "enc",				
			},
		},
	},
	["mountedcombatant"] = {
		multiple_actions = {
			["Mounted Combatant (Mounted Strike)"] = {
				actions = {
					{ type = "effect", sName = "Mounted Combatant (Mounted Strike); ADVATK", sTargeting = "self", sApply = "action", nDuration = 1, },
				},
			},
			["Mounted Combatant (Leap Aside)"] = {
				actions = {
					{ type = "effect", sName = "Mounted Combatant (Leap Aside); Evasion", },
				},
			},
			["Mounted Combatant (Veer)"] = {
				actions = {},
			},
		},
	},
	["observant"] = {
		multiple_actions = {
			["Observant (Quick Search)"] = {
				actions = {},
			},
		},
	},
	["piercer"] = {
		multiple_actions = {
			["Piercer (Puncture)"] = {
				actions = {},
			},
			["Piercer (Enhanced Critical)"] = {
				actions = {},
			},
		},
	},
	["poisoner"] = {
		toolprof = { innate = { "Poisoner's Kit" }, },
		multiple_actions = {
			["Poisoner (Potent Poison)"] = {
				actions = {},
			},
			["Poisoner (Brew Poison)"] = {
				actions = {},
			},
		},
	},
	["polearmmaster"] = {
		multiple_actions = {
			["Polearm Master (Pole Strike)"] = {
				actions = {},
			},
			["Polearm Master (Reactive Strike)"] = {
				actions = {},
			},
		},
	},
	["ritualcaster"] = {
		multiple_actions = {
			["Ritual Caster (Quick Ritual)"] = {
				actions = {},
			},
		},
	},
	["sentinel"] = {
		multiple_actions = {
			["Sentinel (Guardian)"] = {
				actions = {},
			},
			["Sentinel (Halt)"] = {
				actions = {},
			},
		},
	},
	["sharpshooter"] = {
		multiple_actions = {
			["Sharpshooter (Bypass Cover)"] = {
				actions = {},
			},
			["Sharpshooter (Firing in Melee)"] = {
				actions = {},
			},
			["Sharpshooter (Long Shots)"] = {
				actions = {},
			},
		},
	},
	["shieldmaster"] = {
		multiple_actions = {
			["Shield Master (Shield Bash)"] = {
				actions = {
					{ type = "powersave", save = "strength", savestat = "strength" },
					{ type = "effect", sName = "Shield Master (Shield Bash); Prone", },
				},
			},
			["Shield Master (Interpose Shield)"] = {
				actions = {},
			},
		},
	},
	["skulker"] = {
		multiple_actions = {
			["Skulker (Fog of War)"] = {
				actions = {
					{ type = "effect", sName = "Skulker (Fog of War); ADVSKILL: stealth", },
				},
			},
			["Skulker (Sniper)"] = {
				actions = {},
			},
		},
	},
	["slasher"] = {
		multiple_actions = {
			["Slasher (Hamstring)"] = {
				actions = {
					{ type = "effect", sName = "Slasher (Hamstring); Speed -10", nDuration = 1, },
				},
			},
			["Slasher (Enhanced Critical)"] = {
				actions = {
					{ type = "effect", sName = "Slasher (Enhanced Critical); DISATK", nDuration = 1, },
				},
			},
		},
	},
	["speedy"] = {
		multiple_actions = {
			["Speedy (Dash over Difficult Terrain)"] = {
				actions = {},
			},
			["Speedy (Agile Movement)"] = {
				actions = {
					{ type = "effect", sName = "Speedy (Agile Movement); GRANTDISATK", nDuration = 1, },
				},
			},
		},
	},
	["spellsniper"] = {
		multiple_actions = {
			["Spell Sniper (Bypass Cover)"] = {
				actions = {},
			},
			["Spell Sniper (Casting in Melee)"] = {
				actions = {},
			},
			["Spell Sniper (Increased Range)"] = {
				actions = {},
			},
		},
	},
	["telekinetic"] = {
		multiple_actions = {
			["Telekinetic (Minor Telekinesis)"] = {
				actions = {},
			},
			["Telekinetic (Telekinetic Shove)"] = {
				actions = {
					{ type = "powersave", save = "strength", savestat = "intelligence", magic = true, },
				},
			},
		},
	},
	["telepathic"] = {
		multiple_actions = {
			["Telepathic (Telepathic Utterance)"] = {
				actions = {},
			},
		},
	},
	["warcaster"] = {
		multiple_actions = {
			["War Caster (Reactive Spell)"] = {
				actions = {},
			},
			["War Caster (Somatic Components)"] = {
				actions = {},
			},
		},
	},
	["weaponmaster"] = {
		multiple_actions = {
			["Weapon Master (Mastery Property)"] = {
				actions = {},
			},
		},
	},
	
	-- Fighting Style Feats
	["interception"] = {
		actions = {
			{ type = "effect", sName = "Interception; RESIST: 1d10 [PRF] all", sApply = "action", nDuration = 1, },
		},
	},
	["protection"] = {
		actions = {
			{ type = "effect", sName = "Protection; GRANTDISATK", nDuration = 1, },
		},
	},
	["unarmedfighting"] = {
		actions = {
			{ type = "attack", range = "M" },
			{ type = "damage", clauses = { { dice = { "d6", }, dmgtype = "bludgeoning", stat = "strength", }, }, },
			{ type = "damage", clauses = { { dice = { "d8", }, dmgtype = "bludgeoning", stat = "strength", }, }, },
			{ type = "damage", clauses = { { dice = { "d4", }, dmgtype = "bludgeoning", }, }, },
		},
	},

	-- Epic Boon Feats
	["boonofcombatprowess"] = {
		multiple_actions = {
			["Boon of Combat Prowess (Peerless Aim)"] = {
				actions = {},
			},
		},
	},
	["boonofdimensionaltravel"] = {
		multiple_actions = {
			["Boon of Dimensional Travel (Blink Steps)"] = {
				actions = {},
			},
		},
	},
	["boonofenergyresistance"] = {
		multiple_actions = {
			["Boon of Energy Resistance (Energy Resistances)"] = {
				actions = {
					{ type = "effect", sName = "Boon of Energy Resistance (Acid); RESIST: acid", sTargeting = "self", },
					{ type = "effect", sName = "Boon of Energy Resistance (Cold); RESIST: cold", sTargeting = "self", },
					{ type = "effect", sName = "Boon of Energy Resistance (Fire); RESIST: fire", sTargeting = "self", },
					{ type = "effect", sName = "Boon of Energy Resistance (Lightning); RESIST: lightning", sTargeting = "self", },
					{ type = "effect", sName = "Boon of Energy Resistance (Necrotic); RESIST: necrotic", sTargeting = "self", },
					{ type = "effect", sName = "Boon of Energy Resistance (Poison); RESIST: poison", sTargeting = "self", },
					{ type = "effect", sName = "Boon of Energy Resistance (Psychic); RESIST: psychic", sTargeting = "self", },
					{ type = "effect", sName = "Boon of Energy Resistance (Radiant); RESIST: radiant", sTargeting = "self", },
					{ type = "effect", sName = "Boon of Energy Resistance (Thunder); RESIST: thunder", sTargeting = "self", },
				},
			},
			["Boon of Energy Resistance (Energy Redirection)"] = {
				actions = {
					{ type = "powersave", save = "dexterity", savestat = "constitution", },
					{ type = "damage", clauses = { { dice = { "d12", "d12", }, dmgtype = "acid", stat = "constitution", }, }, },
					{ type = "damage", clauses = { { dice = { "d12", "d12", }, dmgtype = "cold", stat = "constitution", }, }, },
					{ type = "damage", clauses = { { dice = { "d12", "d12", }, dmgtype = "fire", stat = "constitution", }, }, },
					{ type = "damage", clauses = { { dice = { "d12", "d12", }, dmgtype = "lightning", stat = "constitution", }, }, },
					{ type = "damage", clauses = { { dice = { "d12", "d12", }, dmgtype = "necrotic", stat = "constitution", }, }, },
					{ type = "damage", clauses = { { dice = { "d12", "d12", }, dmgtype = "poison", stat = "constitution", }, }, },
					{ type = "damage", clauses = { { dice = { "d12", "d12", }, dmgtype = "psychic", stat = "constitution", }, }, },
					{ type = "damage", clauses = { { dice = { "d12", "d12", }, dmgtype = "radiant", stat = "constitution", }, }, },
					{ type = "damage", clauses = { { dice = { "d12", "d12", }, dmgtype = "thunder", stat = "constitution", }, }, },
				},
			},
		},
	},
	["boonoffate"] = {
		multiple_actions = {
			["Boon of Fate (Improve Fate)"] = {
				actions = {},
				prepared = 1,
				usesperiod = "enc",
			},
		},
	},
	["boonoffortitude"] = {
		multiple_actions = {
			["Boon of Fortitude (Fortified Health)"] = {
				actions = {
					{ type = "heal", clauses = { { dice = { }, }, stat = "constitution", }, },
				},
			},
		},
	},
	["boonofirresistableoffense"] = {
		multiple_actions = {
			["Boon of Irresistible Offense (Overcome Defenses)"] = {
				actions = {},
			},
			["Boon of Irresistible Offense (Overwhelming Strike)"] = {
				actions = {
					{ type = "effect", sName = "Boon of Irresistible Offense (Overwhelming Strike); DMG: [STR]", sTargeting = "self", sApply = "action", nDuration = 1, },
					{ type = "effect", sName = "Boon of Irresistible Offense (Overwhelming Strike); DMG: [DEX]", sTargeting = "self", sApply = "action", nDuration = 1, },
				},
			},
		},
	},
	["boonofrecovery"] = {
		multiple_actions = {
			["Boon of Recovery (Last Stand)"] = {
				actions = {
					{ type = "heal", clauses = {}, },
				},
				prepared = 1,
			},
			["Boon of Recovery (Recover Vitality)"] = {
				actions = {
					{ type = "heal", sTargeting = "self", clauses = { { dice = { "d10" }, }, }, },
				},
				prepared = 10,
			},
		},
	},
	["boonofspeed"] = {
		multiple_actions = {
			["Boon of Speed (Escape Artist)"] = {
				actions = {},
			},
		},
	},
	["boonofspellrecall"] = {
		multiple_actions = {
			["Boon of Spell Recall (Free Casting)"] = {
				actions = {},
			},
		},
	},
	["boonofthenightspirit"] = {
		multiple_actions = {
			["Boon of the Night Spirit (Merge with Shadows)"] = {
				actions = {
					{ type = "effect", sName = "Boon of the Night Spirit (Merge with Shadows); Invisible", sTargeting = "self", },
				},
			},
			["Boon of the Night Spirit (Shadowy Form)"] = {
				actions = {
					{ type = "effect", sName = "Boon of the Night Spirit (Shadowy Form); RESIST: all,!psychic,!radiant", sTargeting = "self", },
				},
			},
		},
	},
};
