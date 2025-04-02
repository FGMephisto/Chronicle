--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals charwizard_starting_equipment

genmethod = {
	"",
	"Standard Array",
	"Point Buy",
	"Dice Roll/Manual Entry",
};

-- Campaign and any custom is first and then this list
module_order_2024 = {
	"WOTC50PHB",
};
module_order_2014 = {
	"DD PHB Deluxe",
	"DD5E SRD Data",
	"DD Dungeon Masters Guide",
	"DD Monsters of the Multiverse Players",
	"DD Tashas Cauldron of Everything - Players",
	"DD Xanathar's Guide to Everything Players",
	"DD Mordenkainen's Tome of Foes Players",
};

aParseRaceLangChoices = {
	[", and fluency in one language of your choice."] = "",
	[" and one other language that you and your dm agree is appropriate for the character"] = "",
	[" and one other language that you and your dm agree is appropriate for your character"] = "",
	["one extra language of your choice"] = "",
	["one other language of your choice"] = "",
	["one additional language of your choice"] = "",
};
aRaceSkill = {
	["keensenses"] = true,
	["skillversatility"] = true,
	["menacing"] = true,
	["skills"] = true,
	["changelinginstincts"] = true,
	["graceful"] = true,
	["naturaltracker"] = true,
	["fierce"] = true,
	["tough"] = true,
	["specializeddesign"] = true,
	["survivor"] = true,
	["silentfeathers"] = true,
	["leporinesenses"] = true,
	["tirelessprecision"] = true,
	["wiryframe"] = true,
	["naturalathelete"] = true,
	["survivalinstinct"] = true,
	["kenkutraining"] = true,
	["primalintuition"] = true,
	["skill"] = true,
	["imposingpresence"] = true,
	["hunterslore"] = true,
	["catstalent"] = true,
	["psychicglamour"] = true,
	["reveler"] = true,
	["sneaky"] = true,
	["bestialinstincts"] = true,
	["naturalaffinity"] = true,
	["littlegiant"] = true,
	["kenkurecall"] = true,
	["naturesintuition"] = true,
	["besitalinstincts"] = true,
};
aRaceProficiency = {
	["proficiency"] = true,
	["dwarvencombattraining"] = true,
	["toolproficiency"] = true,
	["dwarvenarmortraining"] = true,
	["drowweapontraining"] = true,
	["elfweapontraining"] = true,
	["giftedscribe"] = true,
	["tinker"] = true,
	["specializeddesign"] = true,
	["divergentpersona"] = true,
	["masonsproficiency"] = true,
	["martialprodigy"] = true,
	["seaelftraining"] = true,
	["makersgift"] = true,
	["reveler"] = true,
};
aRaceSpecialSpeed = {
	["fleetoffoot"] = true,
	["seamonkey"] = true,
	["couriersspeed"] = true,
	["swiftstride"] = true,
	["spiderclimb"] = true,
	["fairyflight"] = true,
	["nimbleflight"] = true,
	["nimbleclimber"] = true,
	["underwateradaptation"] = true,
	["flight"] = true,
	["swimspeed"] = true,
	["swim"] = true,
	["winged"] = true,
	["catsclaws"] = true,
};
aRaceSpells = {
	["wardsandseals"] = true,
	["duergarmagic"] = true,
	["shapeshadows"] = true,
	["drowmagic"] = true,
	["scribesinsight"] = true,
	["whisperingwind"] = true,
	["naturalillusionist"] = true,
	["jorascosblessing"] = true,
	["innkeeperscharms"] = true,
	["infernallegacy"] = true,
	["sensethreats"] = true,
	["headwinds"] = true,
	["naturesvoice"] = true,
	["primalconnection"] = true,
	["makersgift"] = true,
	["sentinelsshield"] = true,
	["astralfire"] = true,
	["fairymagic"] = true,
	["hexmagic"] = true,
	["draconiclegacy"] = true,
	["magicsight"] = true,
	["githyankipsionics"] = true,
	["githzeraipsionics"] = true,
	["calltothewave"] = true,
	["mergewithstone"] = true,
	["reachtotheblaze"] = true,
	["minglewiththewind"] = true,
	["celestiallegacy"] = true,
	["lightbearer"] = true,
	["firbolgmagic"] = true,
	["feystep"] = true,
	["innatespellcasting"] = true,
	["cantrip"] = true,
	["blessingofthemoonweaver"] = true,
	["childofthewood"] = true,
	["controlairandwater"] = true,
	["serpentinespellcasting"] = true,
};
aRaceLanguages = {
	["languages"] = true,
	["extralanguage"] = true,
	["specializeddesign"] = true,
};
aRaceTraitNoAdd = {
	["abilityscoreincrease"] = true,
	["abilityscoreincreases"] = true,
};
tBuildOptionsNoAdd2014 = {
	["age"] = true,
	["alignment"] = true,
	["subrace"] = true,
};
tBuildOptionsNoStandardAdd2014 = {
	["size"] = true,
	["speed"] = true,
	["languages"] = true,
	["extralanguage"] = true,
};

tBuildOptionsNoAdd2024 = {
	["draconicancestry"] = true,
	["elvenlineage"] = true,
	["fiendishlegacy"] = true,
	["giantancestry"] = true,
	["gnomishlineage"] = true,
};
tBuildOptionsNoStandardAdd2024 = {
	["abilityscoreimprovement"] = true,
	["extraunarmoredmovement"] = true,
};
tBuildOptionsSpecialSpeed2024 = {
	["enhancedspeed"] = true,
};
tBuildOptionsSkill2024 = {
	["keensenses"] = true,
	["primalknowledge"] = true,
	["bonusproficiencies"] = true,
	["implementsofmercy"] = true,
	["skillful"] = true,
	["scholar"] = true,
};
tBuildOptionsProficiency2024 = {
	["martialtraining"] = true,
	["studentofwar"] = true,
	["implementsofmercy"] = true,
	["assassinstools"] = true,
};
tBuildOptionsFeats2024 = {
	["epicboon"] = true,
	["versatile"] = true,
	["fightingstyle"] = true,
	["additionalfightingstyle"] = true,
};
tBuildOptionsSpells2024 = {
	["animalspeaker"] = true,
	["naturespeaker"] = true,
	["beguilingmagic"] = true,
	["mantleofmajesty"] = true,
	["magicaldiscoveries"] = true,
	["lifedomainspellsl3"] = true,
	["lifedomainspellsl5"] = true,
	["lifedomainspellsl7"] = true,
	["lifedomainspellsl9"] = true,
	["lightdomainspellsl3"] = true,
	["lightdomainspellsl5"] = true,
	["lightdomainspellsl7"] = true,
	["lightdomainspellsl9"] = true,
	["trickerydomainspellsl3"] = true,
	["trickerydomainspellsl5"] = true,
	["trickerydomainspellsl7"] = true,
	["trickerydomainspellsl9"] = true,
	["wardomainspellsl3"] = true,
	["wardomainspellsl5"] = true,
	["wardomainspellsl7"] = true,
	["wardomainspellsl9"] = true,
	["circleofthelandl3"] = true,
	["circleofthelandl5"] = true,
	["circleofthelandl7"] = true,
	["circleofthelandl9"] = true,
	["circleoftheseal3"] = true,
	["circleoftheseal5"] = true,
	["circleoftheseal7"] = true,
	["circleoftheseal9"] = true,
	["additionalcantrip"] = true,
	["telekineticmaster"] = true,
	["shadowarts"] = true,
	["manipulateelements"] = true,
	["oathofdevotionspells"] = true,
	["oathofdevotionspellsl5"] = true,
	["oathofdevotionspellsl9"] = true,
	["oathofdevotionspellsl13"] = true,
	["oathofdevotionspellsl17"] = true,
	["oathofgloryspells"] = true,
	["oathofgloryspellsl5"] = true,
	["oathofgloryspellsl9"] = true,
	["oathofgloryspellsl13"] = true,
	["oathofgloryspellsl17"] = true,
	["oathofancientsspells"] = true,
	["oathofancientsspellsl5"] = true,
	["oathofancientsspellsl9"] = true,
	["oathofancientsspellsl13"] = true,
	["oathofancientsspellsl17"] = true,
	["oathofvengeancespells"] = true,
	["oathofvengeancespellsl5"] = true,
	["oathofvengeancespellsl9"] = true,
	["oathofvengeancespellsl13"] = true,
	["oathofvengeancespellsl17"] = true,
	["feywandererspells"] = true,
	["feywandererspellsl5"] = true,
	["feywandererspellsl9"] = true,
	["feyreinforcements"] = true,
	["feywandererspellsl13"] = true,
	["mistywanderer"] = true,
	["feywandererspellsl17"] = true,
	["gloomstalkerspells"] = true,
	["gloomstalkerspellsl5"] = true,
	["gloomstalkerspellsl9"] = true,
	["gloomstalkerspellsl13"] = true,
	["gloomstalkerspellsl17"] = true,
	["psionicspellsl3"] = true,
	["psionicspellsl5"] = true,
	["psionicspellsl7"] = true,
	["psionicspellsl9"] = true,
	["clockworkspellsl3"] = true,
	["clockworkspellsl5"] = true,
	["clockworkspellsl7"] = true,
	["clockworkspellsl9"] = true,
	["draconicspellsl3"] = true,
	["draconicspellsl5"] = true,
	["draconicspellsl7"] = true,
	["draconicspellsl9"] = true,
	["archfeyspellsl3"] = true,
	["archfeyspellsl5"] = true,
	["archfeyspellsl7"] = true,
	["archfeyspellsl9"] = true,
	["celestialspellsl3"] = true,
	["celestialspellsl5"] = true,
	["celestialspellsl7"] = true,
	["celestialspellsl9"] = true,
	["fiendspellsl3"] = true,
	["fiendspellsl5"] = true,
	["fiendspellsl7"] = true,
	["fiendspellsl9"] = true,
	["greatoldonespellsl3"] = true,
	["greatoldonespellsl5"] = true,
	["greatoldonespellsl7"] = true,
	["greatoldonespellsl9"] = true,
	["abjurantionsavant"] = true,
	["spellbreaker"] = true,
	["divinesavant"] = true,
	["evocationsavant"] = true,
	["illusionsavant"] = true,
	["improvedillusions"] = true,
	["phantasmalcreatures"] = true,
};

--Spells Known
BARD_SPELLSKNOWN = {4,5,6,7,8,9,10,11,12,14,15,15,16,18,19,19,20,22,22,22};
ELDRITCH_KNIGHT_SPELLSKNOWN = {0,0,3,4,4,4,5,6,6,7,8,8,9,10,10,11,11,11,12,13};
RANGER_SPELLSKNOWN = {0,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11};
ARCANE_TRICKSTER_SPELLSKNOWN = {0,0,3,4,4,4,5,6,6,7,8,8,9,10,10,11,11,11,12,13};
SORCERER_SPELLSKNOWN = {2,3,4,5,6,7,8,9,10,11,12,12,13,13,14,14,15,15,15,15};
WARLOCK_SPELLSKNOWN = {2,3,4,5,6,7,8,9,10,10,11,11,12,12,13,13,14,14,15,15};
WIZARD_SPELLSKNOWN = {6,8,10,12,14,16,18,20,22,24,26,28,30,32,34,36,38,40,42,44};

SPELLS_PREPARED_2024 = {
	["standard"] = { 4, 5, 6, 7, 9, 10, 11, 12, 14, 15, 16, 16, 17, 17, 18, 18, 19, 20, 21, 22, },
	["subclass"] = { 0, 0, 3, 4, 4, 4, 5, 6, 6, 7, 8, 8, 9, 10, 10, 11, 11, 11, 12, 13, },
	["half"] = { 2, 3, 4, 5, 6, 6, 7, 7, 9, 9, 10, 10, 11, 11, 12, 12, 14, 14, 15, 15, },
	["sorcerer"] = { 2, 4, 6, 7, 9, 10, 11, 12, 14, 15, 16, 16, 17, 17, 18, 18, 19, 20, 21, 22, },
	["warlock"] = { 2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 11, 11, 12, 12, 13, 13, 14, 14, 15, 15, },
	["wizard"] = { 4, 5, 6, 7, 9, 10, 11, 12, 14, 15, 16, 16, 17, 18, 19, 21, 22, 23, 24, 25, },
};

charwizard_starting_equipment = {};
function onInit()
	charwizard_starting_equipment = {
		["anti paladin"] = {
			starting_wealth = "5d4x10",
			choices = {
				[1] = {
					{ item = "shield", count = 1 },
					{ selection = "martial weapons", count = 2 },
				},
				[2] = {
					{ selection = "martial weapons", count = 2 },
				},
				[3] = {
					{ item = "javelin", count = 5 },
					{ selection = "simple melee weapons", count = 1 },
				},
				[4] = {
					{ item = "priest's pack", count = 1 },
					{ item = "explorer's pack", count = 1 },
				},
				[5] = {
					{ selection = "holy symbol", count = 1 },
				},
			},
			included = {
				{ item = "chain mail", count = 1 },
			},
		},
		["artificer"] = {
			starting_wealth = "5d4x10",
			choices = {
				[1] = {
					{ selection = "simple melee weapons", count = 1 },
					{ selection = "simple ranged weapons", count = 1 },
				},
				[2] = {
					{ selection = "simple melee weapons", count = 1 },
					{ selection = "simple ranged weapons", count = 1 },
				},
				[3] = {
					{ item = "studded leather", count = 1, },
					{ item = "scale mail", count = 1 },
				},
			},
			included = {
				{ item = "crossbow, light", count = 1 },
				{ item = "bolts (20)", count = 1 },
				{ item = "thieves' tools", count = 1 },
				{ item = "dungeoneer's pack", count = 1 },
			},
		},
		["barbarian"] = {
			starting_wealth = "5d4x10",
			choices = {
				[1] = {
					{ selection = "martial weapons", count = 1}
				},
				[2] = {
					{ selection = "simple melee weapons", count = 1 },
				},
				[3] = {
					{ selection = "simple melee weapons", count = 1 },
				},
			},
			included = {
				{ item = "explorer's pack", count = 1 },
				{ item = "javelin", count = 4 },
			},
		},
		["bard"] = {
			starting_wealth = "5d4x10",
			choices = {
				[1] = {
					{ item = "rapier", count = 1 },
					{ item = "longsword", count = 1 },
					{ selection = "simple melee weapons", count = 1 },
					{ selection = "simple ranged weapons", count = 1 },
				},
				[2] = {
					{ item = "diplomat's pack", count = 1 },
					{ item = "entertainer's pack", count = 1 },
				},
				[3] = {
					{ item = "lute", count = 1 },
					{ selection = "musical instrument", count = 1 },
				},
			},
			included = {
				{ item = "leather", count = 1 },
				{ item = "dagger", count = 1 },
			},
		},
		["cleric"] = {
			starting_wealth = "5d4x10",
			choices = {
				[1] = {
					{ item = "mace", count = 1 },
					{ item = "warhammer", count = 1, prof = 1 },
				},
				[2] = {
					{ item = "scale mail", count = 1 },
					{ item = "leather", count = 1 },
					{ item = "chain mail", count = 1, prof = 1 },
				},
				[3] = {
					{ item = "crossbow, light", count = 1, additional = "crossbow bolts (20)" },
					{ selection = "simple melee weapons", count = 1 },
					{ selection = "simple ranged weapons", count = 1 },
				},
				[4] = {
					{ item = "priest's pack", count = 1 },
					{ item = "explorer's pack", count = 1 },
				},
				[5] = {
					{ selection = "holy symbol", count = 1 },
				},
			},
			included = {
				{ item = "shield", count = 1 },
			},
		},
		["druid"] = {
			starting_wealth = "2d4x10",
			choices = {
				[1] = {
					{ item = "shield", count = 1 },
					{ selection = "simple melee weapons", count = 1 },
					{ selection = "simple ranged weapons", count = 1 },
				},
				[2] = {
					{ item = "scimitar", count = 1 },
					{ selection = "simple melee weapons", count = 1 },
				},
				[3] = {
					{ selection = "druidic focus", count = 1 },
				},
			},
			included = {
				{ item = "leather", count = 1 },
				{ item = "explorer's pack", count = 1 },
			},
		},
		["fighter"] = {
			starting_wealth = "5d4x10",
			choices = {
				[1] = {
					{ item = "chain mail", count = 1 },
					{ item = "leather", count = 1, additional = {"longbow", "arrows (20)"} },
				},
				[2] = {
					{ item = "shield", count = 1 },
					{ selection = "martial weapons", count = 1 },
					{ selection = "martial ranged weapons", count = 1 },
				},
				[3] = {
					{ selection = "martial weapons", count = 1 },
					{ selection = "martial ranged weapons", count = 1 },
				},
				[4] = {
					{ item = "crossbow, light", count = 1, additional = "bolts (20)" },
					{ item = "handaxe", count = 2 },
				},
				[5] = {
					{ item = "dungeoneer's pack", count = 1 },
					{ item = "explorer's pack", count = 1 },
				},
			},
			--[[included = {
				{ item = "longbow", count = 1 },
				{ item = "arrows (20)", count = 1 },
			},--]]
		},
		["monk"] = {
			starting_wealth = "5d4",
			choices = {
				[1] = {
					{ item = "shortsword", count = 1 },
					{ selection = "simple melee weapons", count = 1 },
					{ selection = "simple ranged weapons", count = 1 },
				},
				[2] = {
					{ item = "dungeoneer's pack", count = 1 },
					{ item = "explorer's pack", count = 1 },
				},
			},
			included = {
				{ item = "dart", count = 10 },
			},
		},
		["paladin"] = {
			starting_wealth = "5d4x10",
			choices = {
				[1] = {
					{ item = "shield", count = 1},
					{ selection = "martial weapons", count = 1},
				},
				[2] = {
					{ selection = "martial weapons", count = 1 },
				},
				[3] = {
					{ item = "javelin", count = 5 },
					{ selection = "simple melee weapons", count = 1 },
				},
				[4] = {
					{ item = "priest's pack", count = 1 },
					{ item = "explorer's pack", count = 1 },
				},
				[5] = {
					{ selection = "holy symbol", count = 1 },
				},
			},
			included = {
				{ item = "chain mail", count = 1 },
			},
		},
		["ranger"] = {
			starting_wealth = "5d4x10",
			choices = {
				[1] = {
					{ item = "scale mail", count = 1 },
					{ item = "leather", count = 1 },
				},
				[2] = {
					{ item = "shortsword", count = 2 },
					{ selection = "simple melee weapons", count = 1 },
				},
				[3] = {
					{ item = "dungeoneer's pack", count = 1 },
					{ item = "explorer's pack", count = 1 },
				},
			},
			included = {
				{ item = "longbow", count = 1 },
				{ item = "quiver", count = 1 },
				{ item = "arrows (20)", count = 1 },
			},
		},
		["rogue"] = {
			starting_wealth = "4d4x10",
			choices = {
				[1] = {
					{ item = "rapier", count = 1 },
					{ item = "shortsword", count = 1 },
				},
				[2] = {
					{ item = "shortbow", count = 1, additional = {"quiver", "arrows (20)"} },
					{ item = "shortsword", count = 1 },
				},
				[3] = {
					{ item = "burglar's pack", count = 1 },
					{ item = "dungeoneer's pack", count = 1 },
					{ item = "explorer's pack", count = 1 },
				},
			},
			included = {
				{ item = "leather", count = 1 },
				{ item = "dagger", count = 2 },
				{ item = "thieves' tools", count = 1 },
			},
		},
		["sorcerer"] = {
			starting_wealth = "3d4x10",
			choices = {
				[1] = {
					{ item = "crossbow, light", count = 1, additional = "bolts (20)" },
					{ selection = "simple melee weapons", count = 1 },
					{ selection = "simple ranged weapons", count = 1 },
				},
				[2] = {
					{ item = "component pouch", count = 1, },
					{ selection = "arcane focus", count = 1 },
				},
				[3] = {
					{ item = "dungeoneer's pack", count = 1 },
					{ item = "explorer's pack", count = 1 },
				},
			},
			included = {
				{ item = "dagger", count = 2 },
			},
		},
		["warlock"] = {
			starting_wealth = "4d4x10",
			choices = {
				[1] = {
					{ item = "crossbow, light", count = 1, additional = "bolts (20)" },
					{ selection = "simple melee weapons", count = 1 },
					{ selection = "simple ranged weapons", count = 1 },
				},
				[2] = {
					{ item = "component pouch", count = 1, },
					{ selection = "arcane focus", count = 1 },
				},
				[3] = {
					{ item = "scholar's pack", count = 1 },
					{ item = "dungeoneer's pack", count = 1 },
				},
				[4] = {
					{ selection = "simple melee weapons", count = 1 },
					{ selection = "simple ranged weapons", count = 1 },
				},
			},
			included = {
				{ item = "leather", count = 1 },
				{ item = "dagger", count = 2 },
			},
		},
		["wizard"] = {
			starting_wealth = "4d4x10",
			choices = {
				[1] = {
					{ item = "quarterstaff", count = 1 },
					{ item = "dagger", count = 1 },
				},
				[2] = {
					{ item = "component pouch", count = 1, },
					{ selection = "arcane focus", count = 1 },
				},
				[3] = {
					{ item = "scholar's pack", count = 1 },
					{ item = "explorer's pack", count = 1 },
				},
			},
			included = {
				{ item = "spellbook", count = 1 },
			},
		},
	};
end

--
-- Registration
--

function registerNewCharWizardStartingEquipment(s, aEquipment)
	charwizard_starting_equipment[s] = aEquipment;
end
