--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

-- Abilities (database names)
abilities = {
	"strength",
	"dexterity",
	"constitution",
	"intelligence",
	"wisdom",
	"charisma"
};

ability_ltos = {
	["strength"] = "STR",
	["dexterity"] = "DEX",
	["constitution"] = "CON",
	["intelligence"] = "INT",
	["wisdom"] = "WIS",
	["charisma"] = "CHA"
};

ability_stol = {
	["STR"] = "strength",
	["DEX"] = "dexterity",
	["CON"] = "constitution",
	["INT"] = "intelligence",
	["WIS"] = "wisdom",
	["CHA"] = "charisma"
};

-- Basic class values (not display values)
classes = {
	"artificer",
	"barbarian",
	"bard",
	"cleric",
	"druid",
	"fighter",
	"monk",
	"paladin",
	"ranger",
	"rogue",
	"sorcerer",
	"warlock",
	"wizard",
};

-- Values for wound comparison
healthstatusfull = "healthy";
healthstatushalf = "bloodied";
healthstatuswounded = "wounded";

-- Values for alignment comparison
alignment_lawchaos = {
	["lawful"] = 1,
	["chaotic"] = 3,
	["l"] = 1,
	["c"] = 3,
	["lg"] = 1,
	["ln"] = 1,
	["le"] = 1,
	["cg"] = 3,
	["cn"] = 3,
	["ce"] = 3,
};
alignment_goodevil = {
	["good"] = 1,
	["evil"] = 3,
	["g"] = 1,
	["e"] = 3,
	["lg"] = 1,
	["le"] = 3,
	["ng"] = 1,
	["ne"] = 3,
	["cg"] = 1,
	["ce"] = 3,
};
alignment_neutral = "n";

-- Values for size comparison
creaturesize = {
	["tiny"] = -2,
	["small"] = -1,
	["medium"] = 0,
	["large"] = 1,
	["huge"] = 2,
	["gargantuan"] = 3,
	["t"] = -2,
	["s"] = -1,
	["m"] = 0,
	["l"] = 1,
	["h"] = 2,
	["g"] = 3,
};

-- Values for creature type comparison
creaturedefaulttype = "humanoid";
creaturehalftype = "half-";
creaturehalftypesubrace = "human";
-- NOTE: Multi-word types must come before single word types
creaturetype = {
	"aberration",
	"beast",
	"celestial",
	"construct",
	"dragon",
	"elemental",
	"fey",
	"fiend",
	"giant",
	"humanoid",
	"monstrosity",
	"ooze",
	"plant",
	"undead",
};
-- NOTE: Multi-word types must come before single word types
creaturesubtype = {
	"living construct",
	"aarakocra",
	"bullywug",
	"demon",
	"devil",
	"dragonborn",
	"dwarf",
	"elf",
	"gith",
	"gnoll",
	"gnome",
	"goblinoid",
	"grimlock",
	"halfling",
	"human",
	"kenku",
	"kuo-toa",
	"kobold",
	"lizardfolk",
	"merfolk",
	"orc",
	"quaggoth",
	"sahuagin",
	"shapechanger",
	"thri-kreen",
	"titan",
	"troglodyte",
	"yuan-ti",
	"yugoloth",
};

-- Values supported in effect conditionals
conditionaltags = {
};

-- Conditions supported in effect conditionals and for token widgets
-- (Also shown in Effects window)
conditions = {
	"blinded",
	"charmed",
	"cursed",
	"deafened",
	"encumbered",
	"frightened",
	"grappled",
	"incapacitated",
	"intoxicated",
	"invisible",
	"paralyzed",
	"petrified",
	"poisoned",
	"prone",
	"restrained",
	"stable",
	"stunned",
	"surprised",
	"turned",
	"unconscious"
};

-- Bonus/penalty effect types for token widgets
bonuscomps = {
	"INIT",
	"CHECK",
	"AC",
	"ATK",
	"DMG",
	"HEAL",
	"SAVE",
	"STR",
	"CON",
	"DEX",
	"INT",
	"WIS",
	"CHA",
};

-- Condition effect types for token widgets
condcomps = {
	["blinded"] = "cond_blinded",
	["charmed"] = "cond_charmed",
	["deafened"] = "cond_deafened",
	["encumbered"] = "cond_encumbered",
	["frightened"] = "cond_frightened",
	["grappled"] = "cond_grappled",
	["incapacitated"] = "cond_paralyzed",
	["invisible"] = "cond_invisible",
	["paralyzed"] = "cond_paralyzed",
	["petrified"] = "cond_paralyzed",
	["prone"] = "cond_prone",
	["restrained"] = "cond_restrained",
	["stunned"] = "cond_stunned",
	["surprised"] = "cond_disadvantage",
	["turned"] = "cond_frightened",
	["unconscious"] = "cond_unconscious",
	-- Similar to conditions
	["cover"] = "cond_cover",
	["scover"] = "cond_cover",
	-- ADV
	["advatk"] = "cond_advantage",
	["advchk"] = "cond_advantage",
	["advskill"] = "cond_advantage",
	["advinit"] = "cond_advantage",
	["advsav"] = "cond_advantage",
	["advdeath"] = "cond_advantage",
	["grantdisatk"] = "cond_advantage",
	-- DIS
	["disatk"] = "cond_disadvantage",
	["dischk"] = "cond_disadvantage",
	["disskill"] = "cond_disadvantage",
	["disinit"] = "cond_disadvantage",
	["dissav"] = "cond_disadvantage",
	["disdeath"] = "cond_disadvantage",
	["grantadvatk"] = "cond_disadvantage",
};

-- Other visible effect types for token widgets
othercomps = {
	["COVER"] = "cond_cover",
	["SCOVER"] = "cond_cover",
	["IMMUNE"] = "cond_immune",
	["RESIST"] = "cond_resistance",
	["VULN"] = "cond_vulnerable",
	["REGEN"] = "cond_regeneration",
	["DMGO"] = "cond_bleed",
	-- ADV
	["ADVATK"] = "cond_advantage",
	["ADVCHK"] = "cond_advantage",
	["ADVSKILL"] = "cond_advantage",
	["ADVINIT"] = "cond_advantage",
	["ADVSAV"] = "cond_advantage",
	["ADVDEATH"] = "cond_advantage",
	["GRANTDISATK"] = "cond_advantage",
	-- DIS
	["DISATK"] = "cond_disadvantage",
	["DISCHK"] = "cond_disadvantage",
	["DISSKILL"] = "cond_disadvantage",
	["DISINIT"] = "cond_disadvantage",
	["DISSAV"] = "cond_disadvantage",
	["DISDEATH"] = "cond_disadvantage",
	["GRANTADVATK"] = "cond_disadvantage",
};

-- Effect components which can be targeted
targetableeffectcomps = {
	"COVER",
	"SCOVER",
	"AC",
	"SAVE",
	"ATK",
	"DMG",
	"IMMUNE",
	"VULN",
	"RESIST"
};

connectors = {
	"and",
	"or"
};

-- Range types supported
rangetypes = {
	"melee",
	"ranged"
};

-- Damage types supported
dmgtypes = {
	"acid",		-- ENERGY TYPES
	"cold",
	"fire",
	"force",
	"lightning",
	"necrotic",
	"poison",
	"psychic",
	"radiant",
	"thunder",
	"adamantine", 	-- WEAPON PROPERTY DAMAGE TYPES
	"bludgeoning",
	"cold-forged iron",
	"magic",
	"piercing",
	"silver",
	"slashing",
	"critical", -- SPECIAL DAMAGE TYPES
};

specialdmgtypes = {
	"critical",
};

-- Bonus types supported in power descriptions
bonustypes = {
};
stackablebonustypes = {
};

function onInit()
	-- Classes
	class_nametovalue = {
		[Interface.getString("class_value_artificer")] = "artificer",
		[Interface.getString("class_value_bard")] = "bard",
		[Interface.getString("class_value_cleric")] = "cleric",
		[Interface.getString("class_value_druid")] = "druid",
		[Interface.getString("class_value_fighter")] = "fighter",
		[Interface.getString("class_value_monk")] = "monk",
		[Interface.getString("class_value_paladin")] = "paladin",
		[Interface.getString("class_value_ranger")] = "ranger",
		[Interface.getString("class_value_rogue")] = "rogue",
		[Interface.getString("class_value_sorcerer")] = "sorcerer",
		[Interface.getString("class_value_warlock")] = "warlock",
		[Interface.getString("class_value_wizard")] = "wizard",
	};

	class_valuetoname = {
		["artificer"] = Interface.getString("class_value_artificer"),
		["barbarian"] = Interface.getString("class_value_barbarian"),
		["bard"] = Interface.getString("class_value_bard"),
		["cleric"] = Interface.getString("class_value_cleric"),
		["druid"] = Interface.getString("class_value_druid"),
		["fighter"] = Interface.getString("class_value_fighter"),
		["monk"] = Interface.getString("class_value_monk"),
		["paladin"] = Interface.getString("class_value_paladin"),
		["ranger"] = Interface.getString("class_value_ranger"),
		["rogue"] = Interface.getString("class_value_rogue"),
		["sorcerer"] = Interface.getString("class_value_sorcerer"),
		["warlock"] = Interface.getString("class_value_warlock"),
		["wizard"] = Interface.getString("class_value_wizard"),
	};

	-- Skills
	skilldata = {
		[Interface.getString("skill_value_acrobatics")] = { stat = 'dexterity' },
		[Interface.getString("skill_value_animalhandling")] = { stat = 'wisdom' },
		[Interface.getString("skill_value_arcana")] = { stat = 'intelligence' },
		[Interface.getString("skill_value_athletics")] = { stat = 'strength' },
		[Interface.getString("skill_value_deception")] = { stat = 'charisma' },
		[Interface.getString("skill_value_history")] = { stat = 'intelligence' },
		[Interface.getString("skill_value_insight")] = { stat = 'wisdom' },
		[Interface.getString("skill_value_intimidation")] = { stat = 'charisma' },
		[Interface.getString("skill_value_investigation")] = { stat = 'intelligence' },
		[Interface.getString("skill_value_medicine")] = { stat = 'wisdom' },
		[Interface.getString("skill_value_nature")] = { stat = 'intelligence' },
		[Interface.getString("skill_value_perception")] = { stat = 'wisdom' },
		[Interface.getString("skill_value_performance")] = { stat = 'charisma' },
		[Interface.getString("skill_value_persuasion")] = { stat = 'charisma' },
		[Interface.getString("skill_value_religion")] = { stat = 'intelligence' },
		[Interface.getString("skill_value_sleightofhand")] = { stat = 'dexterity' },
		[Interface.getString("skill_value_stealth")] = { stat = 'dexterity', disarmorstealth = 1 },
		[Interface.getString("skill_value_survival")] = { stat = 'wisdom' },
	};

	-- Party sheet drop down list data
	psabilitydata = {
		Interface.getString("strength"),
		Interface.getString("dexterity"),
		Interface.getString("constitution"),
		Interface.getString("intelligence"),
		Interface.getString("wisdom"),
		Interface.getString("charisma"),
	};

	-- Party sheet drop down list data
	psskilldata = {
		Interface.getString("skill_value_acrobatics"),
		Interface.getString("skill_value_animalhandling"),
		Interface.getString("skill_value_arcana"),
		Interface.getString("skill_value_athletics"),
		Interface.getString("skill_value_deception"),
		Interface.getString("skill_value_history"),
		Interface.getString("skill_value_insight"),
		Interface.getString("skill_value_intimidation"),
		Interface.getString("skill_value_investigation"),
		Interface.getString("skill_value_medicine"),
		Interface.getString("skill_value_nature"),
		Interface.getString("skill_value_perception"),
		Interface.getString("skill_value_performance"),
		Interface.getString("skill_value_persuasion"),
		Interface.getString("skill_value_religion"),
		Interface.getString("skill_value_sleightofhand"),
		Interface.getString("skill_value_stealth"),
		Interface.getString("skill_value_survival"),
	};
end
