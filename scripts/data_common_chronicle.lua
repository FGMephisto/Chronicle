-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

-- Abilities (database names)
abilities = {
	-- "strength",
	-- "dexterity",
	-- "constitution",
	-- "intelligence",
	-- "wisdom",
	-- "charisma"
	"agility",
	"animalhandling",
	"athletics",
	"awareness",
	"cunning",
	"deception",
	"endurance",
	"fighting",
	"healing",
	"language",
	"knowledge",
	"marksmanship",
	"persuasion",
	"status",
	"stealth",
	"survival",
	"thievery",
	"warfare",
	"will"
};

ability_ltos = {
	-- ["strength"] = "STR",
	-- ["dexterity"] = "DEX",
	-- ["constitution"] = "CON",
	-- ["intelligence"] = "INT",
	-- ["wisdom"] = "WIS",
	-- ["charisma"] = "CHA"
	["agility"] = "AGI",
	["animalhandling"] ="ANI",
	["athletics"] = "ATH",
	["awareness"] = "AWA",
	["cunning"] = "CUN",
	["deception"] = "DEC",
	["endurance"] = "END",
	["fighting"] = "FIG",
	["healing"] = "HEA",
	["language"] = "LAN",
	["knowledge"] = "KNO",
	["marksmanship"] = "MAR",
	["persuasion"] = "PER",
	["status"] = "STA",
	["stealth"] = "STE",
	["survival"] = "SUR",
	["thievery"] = "THI",
	["warfare"] = "WAR",
	["will"] = "WIL"
};

ability_stol = {
	-- ["STR"] = "strength",
	-- ["DEX"] = "dexterity",
	-- ["CON"] = "constitution",
	-- ["INT"] = "intelligence",
	-- ["WIS"] = "wisdom",
	-- ["CHA"] = "charisma"
	["AGI"] = "agility",
	["ANI"] = "animalhandling",
	["ATH"] = "athletics",
	["AWA"] = "awareness",
	["CUN"] = "cunning",
	["DEC"] = "deception",
	["END"] = "endurance",
	["FIG"] = "fighting",
	["HEA"] = "healing",
	["LAN"] = "language",
	["KNO"] = "knowledge",
	["MAR"] = "marksmanship",
	["PER"] = "persuasion",
	["STA"] = "status",
	["STE"] = "stealth",
	["SUR"] = "survival",
	["THI"] = "thievery",
	["WAR"] = "warfare",
	["WIL"] = "will"
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
	-- "aberration",
	"beast",
	-- "celestial",
	-- "construct",
	"dragon",
	-- "elemental",
	-- "fey",
	-- "fiend",
	"giant",
	"humanoid",
	-- "monstrosity",
	-- "ooze",
	-- "plant",
	"undead",
};
-- NOTE: Multi-word types must come before single word types
creaturesubtype = {
	-- "living construct",
	-- "aarakocra",
	-- "bullywug",
	-- "demon",
	-- "devil",
	-- "dragonborn",
	"dwarf",
	"elf", 
	-- "gith",
	-- "gnoll",
	-- "gnome", 
	-- "goblinoid",
	-- "grimlock",
	-- "halfling",
	-- "human",
	-- "kenku",
	-- "kuo-toa",
	-- "kobold",
	-- "lizardfolk",
	-- "merfolk",
	-- "orc",
	-- "quaggoth",
	-- "sahuagin",
	-- "shapechanger",
	-- "thri-kreen",
	-- "titan",
	-- "troglodyte",
	-- "yuan-ti",
	-- "yugoloth",
	"troll"
};

-- Values supported in effect conditionals
conditionaltags = {
};

-- Conditions supported in effect conditionals and for token widgets
-- (Also shown in Effects window)
conditions = {
	"blinded", 
	-- "charmed",
	-- "cursed",
	"deafened",
	"encumbered",
	"frightened", 
	"grappled", 
	"incapacitated",
	"intoxicated",
	-- "invisible", 
	"paralyzed",
	-- "petrified",
	"poisoned",
	"prone", 
	"restrained",
	-- "stable", 
	"stunned",
	-- "turned",
	"unconscious"
};

-- Bonus/penalty effect types for token widgets
bonuscomps = {
	"INIT",
	-- "CHECK",
	-- "AC",
	"ATK",
	"DMG",
	"HEAL",
	-- "SAVE",
	-- "STR",
	-- "CON",
	-- "DEX",
	-- "INT",
	-- "WIS",
	-- "CHA",
	"AGI",
	"ANI",
	"ATH",
	"AWA",
	"CUN",
	"DEC",
	"END",
	"FIG",
	"HEA",
	"LAN",
	"KNO",
	"MAR",
	"PER",
	"STA",
	"STE",
	"SUR",
	"THI",
	"WAR",
	"TESTD",
	"BONUSD",
	"DEF"
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
	["unconscious"] = "cond_unconscious",
	-- Similar to conditions
	["cover"] = "cond_cover",
	["scover"] = "cond_cover",
	-- ADV
	-- ["advatk"] = "cond_advantage",
	-- ["advchk"] = "cond_advantage",
	-- ["advskill"] = "cond_advantage",
	-- ["advinit"] = "cond_advantage",
	-- ["advsav"] = "cond_advantage",
	-- ["advdeath"] = "cond_advantage",
	-- ["grantdisatk"] = "cond_advantage",
	-- DIS
	-- ["disatk"] = "cond_disadvantage",
	-- ["dischk"] = "cond_disadvantage",
	-- ["disskill"] = "cond_disadvantage",
	-- ["disinit"] = "cond_disadvantage",
	-- ["dissav"] = "cond_disadvantage",
	-- ["disdeath"] = "cond_disadvantage",
	-- ["grantadvatk"] = "cond_disadvantage",
};

-- Other visible effect types for token widgets
othercomps = {
	["COVER"] = "cond_cover",
	["SCOVER"] = "cond_cover",
	["IMMUNE"] = "cond_immune",
	-- ["RESIST"] = "cond_resistance",
	-- ["VULN"] = "cond_vulnerable",
	-- ["REGEN"] = "cond_regeneration",
	["DMGO"] = "cond_bleed",
	-- ADV
	-- ["ADVATK"] = "cond_advantage",
	-- ["ADVCHK"] = "cond_advantage",
	-- ["ADVSKILL"] = "cond_advantage",
	-- ["ADVINIT"] = "cond_advantage",
	-- ["ADVSAV"] = "cond_advantage",
	-- ["ADVDEATH"] = "cond_advantage",
	-- ["GRANTDISATK"] = "cond_advantage",
	-- DIS
	-- ["DISATK"] = "cond_disadvantage",
	-- ["DISCHK"] = "cond_disadvantage",
	-- ["DISSKILL"] = "cond_disadvantage",
	-- ["DISINIT"] = "cond_disadvantage",
	-- ["DISSAV"] = "cond_disadvantage",
	-- ["DISDEATH"] = "cond_disadvantage",
	-- ["GRANTADVATK"] = "cond_disadvantage",
};

-- Effect components which can be targeted
targetableeffectcomps = {
	"COVER",
	"SCOVER",
	-- "AC",
	-- "SAVE",
	"ATK",
	"DMG",
	-- "IMMUNE",
	-- "VULN",
	-- "RESIST"
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
	-- "force",
	-- "lightning",
	-- "necrotic",
	"poison",
	-- "psychic",
	-- "radiant",
	-- "thunder",
	-- "adamantine", 	-- WEAPON PROPERTY DAMAGE TYPES
	"bludgeoning",
	-- "cold-forged iron",
	"magic",
	"piercing",
	-- "silver",
	"slashing",
	-- "critical", -- SPECIAL DAMAGE TYPES
};

specialdmgtypes = {
	-- "critical",
};

-- Bonus types supported in power descriptions
bonustypes = {
};
stackablebonustypes = {
};

function onInit()
	-- Classes
	-- Adjusted
	class_nametovalue = {
		-- [Interface.getString("class_value_artificer")] = "artificer",
		-- [Interface.getString("class_value_bard")] = "bard",
		-- [Interface.getString("class_value_cleric")] = "cleric",
		-- [Interface.getString("class_value_druid")] = "druid",
		-- [Interface.getString("class_value_fighter")] = "fighter",
		-- [Interface.getString("class_value_monk")] = "monk",
		-- [Interface.getString("class_value_paladin")] = "paladin",
		-- [Interface.getString("class_value_ranger")] = "ranger",
		-- [Interface.getString("class_value_rogue")] = "rogue",
		-- [Interface.getString("class_value_sorcerer")] = "sorcerer",
		-- [Interface.getString("class_value_warlock")] = "warlock",
		-- [Interface.getString("class_value_wizard")] = "wizard",
	};

	-- Adjusted
	class_valuetoname = {
		-- ["artificer"] = Interface.getString("class_value_artificer"),
		-- ["barbarian"] = Interface.getString("class_value_barbarian"),
		-- ["bard"] = Interface.getString("class_value_bard"),
		-- ["cleric"] = Interface.getString("class_value_cleric"),
		-- ["druid"] = Interface.getString("class_value_druid"),
		-- ["fighter"] = Interface.getString("class_value_fighter"),
		-- ["monk"] = Interface.getString("class_value_monk"),
		-- ["paladin"] = Interface.getString("class_value_paladin"),
		-- ["ranger"] = Interface.getString("class_value_ranger"),
		-- ["rogue"] = Interface.getString("class_value_rogue"),
		-- ["sorcerer"] = Interface.getString("class_value_sorcerer"),
		-- ["warlock"] = Interface.getString("class_value_warlock"),
		-- ["wizard"] = Interface.getString("class_value_wizard"),
	};

	-- Skills
	skilldata = {
		-- [Interface.getString("skill_value_acrobatics")] = { stat = 'dexterity' },
		-- [Interface.getString("skill_value_animalhandling")] = { stat = 'wisdom' },
		-- [Interface.getString("skill_value_arcana")] = { stat = 'intelligence' },
		-- [Interface.getString("skill_value_athletics")] = { stat = 'strength' },
		-- [Interface.getString("skill_value_deception")] = { stat = 'charisma' },
		-- [Interface.getString("skill_value_history")] = { stat = 'intelligence' },
		-- [Interface.getString("skill_value_insight")] = { stat = 'wisdom' },
		-- [Interface.getString("skill_value_intimidation")] = { stat = 'charisma' },
		-- [Interface.getString("skill_value_investigation")] = { stat = 'intelligence' },
		-- [Interface.getString("skill_value_medicine")] = { stat = 'wisdom' },
		-- [Interface.getString("skill_value_nature")] = { stat = 'intelligence' },
		-- [Interface.getString("skill_value_perception")] = { stat = 'wisdom' },
		-- [Interface.getString("skill_value_performance")] = { stat = 'charisma' },
		-- [Interface.getString("skill_value_persuasion")] = { stat = 'charisma' },
		-- [Interface.getString("skill_value_religion")] = { stat = 'intelligence' },
		-- [Interface.getString("skill_value_sleightofhand")] = { stat = 'dexterity' },
		-- [Interface.getString("skill_value_stealth")] = { stat = 'dexterity', disarmorstealth = 1 },
		-- [Interface.getString("skill_value_survival")] = { stat = 'wisdom' },
		[Interface.getString("skill_value_acrobatics")] = { stat = "agility", disarmorstealth = 1 },
		[Interface.getString("skill_value_act")] = { stat = "deception" },
		[Interface.getString("skill_value_axes")] = { stat = "fighting" },
		[Interface.getString("skill_value_balance")] = { stat = "agility", disarmorstealth = 1 },
		[Interface.getString("skill_value_bargain")] = { stat = "persuasion" },
		[Interface.getString("skill_value_blendin")] = { stat = "stealth" },
		[Interface.getString("skill_value_bludgeons")] = { stat = "fighting" },
		[Interface.getString("skill_value_bluff")] = { stat = "deception" },
		[Interface.getString("skill_value_bows")] = { stat = "marksmanship" },
		[Interface.getString("skill_value_brawling")] = { stat = "fighting" },
		[Interface.getString("skill_value_breeding")] = { stat = "status" },
		[Interface.getString("skill_value_charm")] = { stat = "persuasion" },
		[Interface.getString("skill_value_charmanimal")] = { stat = "animalhandling" },
		[Interface.getString("skill_value_cheat")] = { stat = "deception" },
		[Interface.getString("skill_value_climb")] = { stat = "athletics" },
		[Interface.getString("skill_value_command")] = { stat = "warfare" },
		[Interface.getString("skill_value_contortions")] = { stat = "agility", disarmorstealth = 1 },
		[Interface.getString("skill_value_convince")] = { stat = "persuasion" },
		[Interface.getString("skill_value_coordinate")] = { stat = "will" },
		[Interface.getString("skill_value_courage")] = { stat = "will" },
		[Interface.getString("skill_value_crossbows")] = { stat = "marksmanship" },
		[Interface.getString("skill_value_decipher")] = { stat = "cunning" },
		[Interface.getString("skill_value_dedication")] = { stat = "will" },
		[Interface.getString("skill_value_diagnosis")] = { stat = "healing" },
		[Interface.getString("skill_value_disguise")] = { stat = "deception" },
		[Interface.getString("skill_value_dodge")] = { stat = "agility", disarmorstealth = 1 },
		[Interface.getString("skill_value_drive")] = { stat = "animalhandling" },
		[Interface.getString("skill_value_education")] = { stat = "knowledge" },
		[Interface.getString("skill_value_empathy")] = { stat = "awareness" },
		[Interface.getString("skill_value_fencing")] = { stat = "fighting" },
		[Interface.getString("skill_value_forage")] = { stat = "survival" },
		[Interface.getString("skill_value_hunt")] = { stat = "survival" },
		[Interface.getString("skill_value_incite")] = { stat = "persuasion" },
		[Interface.getString("skill_value_intimidate")] = { stat = "persuasion" },
		[Interface.getString("skill_value_jump")] = { stat = "athletics" },
		[Interface.getString("skill_value_logic")] = { stat = "cunning" },
		[Interface.getString("skill_value_longblades")] = { stat = "fighting" },
		[Interface.getString("skill_value_memory")] = { stat = "cunning" },
		[Interface.getString("skill_value_notice")] = { stat = "awareness" },
		[Interface.getString("skill_value_orientation")] = { stat = "survival" },
		[Interface.getString("skill_value_picklock")] = { stat = "thievery" },
		[Interface.getString("skill_value_polearms")] = { stat = "fighting" },
		[Interface.getString("skill_value_quickness")] = { stat = "agility", disarmorstealth = 1 },
		[Interface.getString("skill_value_reputation")] = { stat = "status" },
		[Interface.getString("skill_value_research")] = { stat = "knowledge" },
		[Interface.getString("skill_value_resilience")] = { stat = "endurance" },
		[Interface.getString("skill_value_ride")] = { stat = "animalhandling" },
		[Interface.getString("skill_value_run")] = { stat = "athletics" },
		[Interface.getString("skill_value_seduce")] = { stat = "persuasion" },
		[Interface.getString("skill_value_shields")] = { stat = "fighting" },
		[Interface.getString("skill_value_shortblades")] = { stat = "fighting" },
		[Interface.getString("skill_value_siege")] = { stat = "marksmanship" },
		[Interface.getString("skill_value_sleightofhand")] = { stat = "thievery" },
		[Interface.getString("skill_value_sneak")] = { stat = "stealth" },
		[Interface.getString("skill_value_spears")] = { stat = "fighting" },
		[Interface.getString("skill_value_stamina")] = { stat = "endurance" },
		[Interface.getString("skill_value_steal")] = { stat = "thievery" },
		[Interface.getString("skill_value_stewardship")] = { stat = "status" },
		[Interface.getString("skill_value_strategy")] = { stat = "warfare" },
		[Interface.getString("skill_value_streetwise")] = { stat = "knowledge" },
		[Interface.getString("skill_value_strength")] = { stat = "athletics" },
		[Interface.getString("skill_value_swim")] = { stat = "athletics" },
		[Interface.getString("skill_value_tactics")] = { stat = "warfare" },
		[Interface.getString("skill_value_targetshooting")] = { stat = "marksmanship" },
		[Interface.getString("skill_value_taunt")] = { stat = "persuasion" },
		[Interface.getString("skill_value_throw")] = { stat = "athletics" },
		[Interface.getString("skill_value_thrown")] = { stat = "marksmanship" },
		[Interface.getString("skill_value_tournaments")] = { stat = "status" },
		[Interface.getString("skill_value_track")] = { stat = "survival" },
		[Interface.getString("skill_value_train")] = { stat = "animalhandling" },
		[Interface.getString("skill_value_treatailment")] = { stat = "healing" },
		[Interface.getString("skill_value_treatinjury")] = { stat = "healing" },
	};

	-- Party sheet drop down abilities list data
	psabilitydata = {
		-- Interface.getString("strength"),
		-- Interface.getString("dexterity"),
		-- Interface.getString("constitution"),
		-- Interface.getString("intelligence"),
		-- Interface.getString("wisdom"),
		-- Interface.getString("charisma"),
		Interface.getString("agility"),
		Interface.getString("animalhandling"),
		Interface.getString("athletics"),
		Interface.getString("awareness"),
		Interface.getString("cunning"),
		Interface.getString("deception"),
		Interface.getString("endurance"),
		Interface.getString("fighting"),
		Interface.getString("healing"),
		Interface.getString("knowledge"),
		Interface.getString("language"),
		Interface.getString("marksmanship"),
		Interface.getString("persuasion"),
		Interface.getString("status"),
		Interface.getString("stealth"),
		Interface.getString("survival"),
		Interface.getString("thievery"),
		Interface.getString("warfare"),
		Interface.getString("will")
	};

	-- Party sheet drop down skill list data
	psskilldata = {
		-- Interface.getString("skill_value_acrobatics"),
		-- Interface.getString("skill_value_animalhandling"),
		-- Interface.getString("skill_value_arcana"),
		-- Interface.getString("skill_value_athletics"),
		-- Interface.getString("skill_value_deception"),
		-- Interface.getString("skill_value_history"),
		-- Interface.getString("skill_value_insight"),
		-- Interface.getString("skill_value_intimidation"),
		-- Interface.getString("skill_value_investigation"),
		-- Interface.getString("skill_value_medicine"),
		-- Interface.getString("skill_value_nature"),
		-- Interface.getString("skill_value_perception"),
		-- Interface.getString("skill_value_performance"),
		-- Interface.getString("skill_value_persuasion"),
		-- Interface.getString("skill_value_religion"),
		-- Interface.getString("skill_value_sleightofhand"),
		-- Interface.getString("skill_value_stealth"),
		-- Interface.getString("skill_value_survival"),
		Interface.getString("skill_value_acrobatics"),
		Interface.getString("skill_value_balance"),
		Interface.getString("skill_value_contortions"),
		Interface.getString("skill_value_dodge"),
		Interface.getString("skill_value_quickness"),
		Interface.getString("skill_value_charmanimal"),
		Interface.getString("skill_value_drive"),
		Interface.getString("skill_value_ride"),
		Interface.getString("skill_value_train"),
		Interface.getString("skill_value_climb"),
		Interface.getString("skill_value_jump"),
		Interface.getString("skill_value_run"),
		Interface.getString("skill_value_strength"),
		Interface.getString("skill_value_swim"),
		Interface.getString("skill_value_throw"),
		Interface.getString("skill_value_empathy"),
		Interface.getString("skill_value_notice"),
		Interface.getString("skill_value_decipher"),
		Interface.getString("skill_value_logic"),
		Interface.getString("skill_value_memory"),
		Interface.getString("skill_value_act"),
		Interface.getString("skill_value_bluff"),
		Interface.getString("skill_value_cheat"),
		Interface.getString("skill_value_disguise"),
		Interface.getString("skill_value_resilience"),
		Interface.getString("skill_value_stamina"),
		Interface.getString("skill_value_axes"),
		Interface.getString("skill_value_bludgeons"),
		Interface.getString("skill_value_brawling"),
		Interface.getString("skill_value_fencing"),
		Interface.getString("skill_value_longblades"),
		Interface.getString("skill_value_polearms"),
		Interface.getString("skill_value_shields"),
		Interface.getString("skill_value_shortblades"),
		Interface.getString("skill_value_spears"),
		Interface.getString("skill_value_diagnosis"),
		Interface.getString("skill_value_treatailment"),
		Interface.getString("skill_value_treatinjury"),
		Interface.getString("skill_value_education"),
		Interface.getString("skill_value_research"),
		Interface.getString("skill_value_streetwise"),
		Interface.getString("skill_value_bows"),
		Interface.getString("skill_value_crossbows"),
		Interface.getString("skill_value_siege"),
		Interface.getString("skill_value_thrown"),
		Interface.getString("skill_value_targetshooting"),
		Interface.getString("skill_value_bargain"),
		Interface.getString("skill_value_charm"),
		Interface.getString("skill_value_convince"),
		Interface.getString("skill_value_incite"),
		Interface.getString("skill_value_intimidate"),
		Interface.getString("skill_value_seduce"),
		Interface.getString("skill_value_taunt"),
		Interface.getString("skill_value_breeding"),
		Interface.getString("skill_value_reputation"),
		Interface.getString("skill_value_stewardship"),
		Interface.getString("skill_value_tournaments"),
		Interface.getString("skill_value_blendin"),
		Interface.getString("skill_value_sneak"),
		Interface.getString("skill_value_forage"),
		Interface.getString("skill_value_hunt"),
		Interface.getString("skill_value_orientation"),
		Interface.getString("skill_value_track"),
		Interface.getString("skill_value_picklock"),
		Interface.getString("skill_value_sleightofhand"),
		Interface.getString("skill_value_steal"),
		Interface.getString("skill_value_command"),
		Interface.getString("skill_value_strategy"),
		Interface.getString("skill_value_tactics"),
		Interface.getString("skill_value_coordinate"),
		Interface.getString("skill_value_courage"),
		Interface.getString("skill_value_dedication")
	};
	
	-- --
	-- Added -->
	-- --
	-- Weapon grade list data
	wpngradedata = {
		"Common",
		"Superior",
		"Extraordinary",
		"Poor"
	};

	-- Weapon skill list data
	wpnskilldata = {
		"None",
		Interface.getString("skill_value_axes"),
		Interface.getString("skill_value_bludgeons"),
		Interface.getString("skill_value_brawling"),
		Interface.getString("skill_value_fencing"),
		Interface.getString("skill_value_longblades"),
		Interface.getString("skill_value_polearms"),
		Interface.getString("skill_value_shields"),
		Interface.getString("skill_value_shortblades"),
		Interface.getString("skill_value_spears"),
		Interface.getString("skill_value_bows"),
		Interface.getString("skill_value_crossbows"),
		Interface.getString("skill_value_siege"),
		Interface.getString("skill_value_thrown"),
	};

	-- Weapon damage abilities list data
	wpndmgabilitydata = {
		Interface.getString("agility"),
		Interface.getString("athletics"),
		Interface.getString("animalhandling"),
	};
end