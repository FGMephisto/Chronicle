-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System.
--

-- ===================================================================================================================
-- ===================================================================================================================
function onInit()
	-- ===================================================================================================================
	-- Skills
	-- ===================================================================================================================
	skilldata = {
		[Interface.getString("skill_value_acrobatics")] = { stat = 'agility', disarmorstealth = 1 },
		[Interface.getString("skill_value_balance")] = { stat = 'agility', disarmorstealth = 1 },
		[Interface.getString("skill_value_contortions")] = { stat = 'agility', disarmorstealth = 1 },
		[Interface.getString("skill_value_dodge")] = { stat = 'agility', disarmorstealth = 1 },
		[Interface.getString("skill_value_quickness")] = { stat = 'agility', disarmorstealth = 1 },
		[Interface.getString("skill_value_charmanimal")] = { stat = 'animalhandling' },
		[Interface.getString("skill_value_drive")] = { stat = 'animalhandling' },
		[Interface.getString("skill_value_ride")] = { stat = 'animalhandling' },
		[Interface.getString("skill_value_train")] = { stat = 'animalhandling' },
		[Interface.getString("skill_value_climb")] = { stat = 'athletics' },
		[Interface.getString("skill_value_jump")] = { stat = 'athletics' },
		[Interface.getString("skill_value_run")] = { stat = 'athletics' },
		[Interface.getString("skill_value_strength")] = { stat = 'athletics' },
		[Interface.getString("skill_value_swim")] = { stat = 'athletics' },
		[Interface.getString("skill_value_throw")] = { stat = 'athletics' },
		[Interface.getString("skill_value_empathy")] = { stat = 'awareness' },
		[Interface.getString("skill_value_notice")] = { stat = 'awareness' },
		[Interface.getString("skill_value_decipher")] = { stat = 'cunning' },
		[Interface.getString("skill_value_logic")] = { stat = 'cunning' },
		[Interface.getString("skill_value_memory")] = { stat = 'cunning' },
		[Interface.getString("skill_value_act")] = { stat = 'deception' },
		[Interface.getString("skill_value_bluff")] = { stat = 'deception' },
		[Interface.getString("skill_value_cheat")] = { stat = 'deception' },
		[Interface.getString("skill_value_disguise")] = { stat = 'deception' },
		[Interface.getString("skill_value_resilience")] = { stat = 'endurance' },
		[Interface.getString("skill_value_stamina")] = { stat = 'endurance' },
		[Interface.getString("skill_value_axes")] = { stat = 'fighting' },
		[Interface.getString("skill_value_bludgeons")] = { stat = 'fighting' },
		[Interface.getString("skill_value_brawling")] = { stat = 'fighting' },
		[Interface.getString("skill_value_fencing")] = { stat = 'fighting' },
		[Interface.getString("skill_value_longblades")] = { stat = 'fighting' },
		[Interface.getString("skill_value_polearms")] = { stat = 'fighting' },
		[Interface.getString("skill_value_shields")] = { stat = 'fighting' },
		[Interface.getString("skill_value_shortblades")] = { stat = 'fighting' },
		[Interface.getString("skill_value_spears")] = { stat = 'fighting' },
		[Interface.getString("skill_value_diagnosis")] = { stat = 'healing' },
		[Interface.getString("skill_value_treatailment")] = { stat = 'healing' },
		[Interface.getString("skill_value_treatinjury")] = { stat = 'healing' },
		[Interface.getString("skill_value_education")] = { stat = 'knowledge' },
		[Interface.getString("skill_value_research")] = { stat = 'knowledge' },
		[Interface.getString("skill_value_streetwise")] = { stat = 'knowledge' },
		[Interface.getString("skill_value_bows")] = { stat = 'marksmanship' },
		[Interface.getString("skill_value_crossbows")] = { stat = 'marksmanship' },
		[Interface.getString("skill_value_siege")] = { stat = 'marksmanship' },
		[Interface.getString("skill_value_thrown")] = { stat = 'marksmanship' },
		[Interface.getString("skill_value_targetshooting")] = { stat = 'marksmanship' },
		[Interface.getString("skill_value_bargain")] = { stat = 'persuasion' },
		[Interface.getString("skill_value_charm")] = { stat = 'persuasion' },
		[Interface.getString("skill_value_convince")] = { stat = 'persuasion' },
		[Interface.getString("skill_value_incite")] = { stat = 'persuasion' },
		[Interface.getString("skill_value_intimidate")] = { stat = 'persuasion' },
		[Interface.getString("skill_value_seduce")] = { stat = 'persuasion' },
		[Interface.getString("skill_value_taunt")] = { stat = 'persuasion' },
		[Interface.getString("skill_value_breeding")] = { stat = 'status' },
		[Interface.getString("skill_value_reputation")] = { stat = 'status' },
		[Interface.getString("skill_value_stewardship")] = { stat = 'status' },
		[Interface.getString("skill_value_tournaments")] = { stat = 'status' },
		[Interface.getString("skill_value_blendin")] = { stat = 'stealth' },
		[Interface.getString("skill_value_sneak")] = { stat = 'stealth' },
		[Interface.getString("skill_value_forage")] = { stat = 'survival' },
		[Interface.getString("skill_value_hunt")] = { stat = 'survival' },
		[Interface.getString("skill_value_orientation")] = { stat = 'survival' },
		[Interface.getString("skill_value_track")] = { stat = 'survival' },
		[Interface.getString("skill_value_picklock")] = { stat = 'thievery' },
		[Interface.getString("skill_value_sleightofhand")] = { stat = 'thievery' },
		[Interface.getString("skill_value_steal")] = { stat = 'thievery' },
		[Interface.getString("skill_value_command")] = { stat = 'warfare' },
		[Interface.getString("skill_value_strategy")] = { stat = 'warfare' },
		[Interface.getString("skill_value_tactics")] = { stat = 'warfare' },
		[Interface.getString("skill_value_coordinate")] = { stat = 'will' },
		[Interface.getString("skill_value_courage")] = { stat = 'will' },
		[Interface.getString("skill_value_dedication")] = { stat = 'will' }
	};

	-- skilldata = {
		-- [Interface.getString("skill_value_acrobatics")] = { lookup = "acrobatics", stat = 'agility', disarmorstealth = 1 },
		-- [Interface.getString("skill_value_balance")] = { lookup = "balance", stat = 'agility', disarmorstealth = 1 },
		-- [Interface.getString("skill_value_contortions")] = { lookup = "contortions", stat = 'agility', disarmorstealth = 1 },
		-- [Interface.getString("skill_value_dodge")] = { lookup = "dodge", stat = 'agility', disarmorstealth = 1 },
		-- [Interface.getString("skill_value_quickness")] = { lookup = "quickness", stat = 'agility', disarmorstealth = 1 },
		-- [Interface.getString("skill_value_charmanimal")] = { lookup = "charmanimal", stat = 'animalhandling' },
		-- [Interface.getString("skill_value_drive")] = { lookup = "drive", stat = 'animalhandling' },
		-- [Interface.getString("skill_value_ride")] = { lookup = "ride", stat = 'animalhandling' },
		-- [Interface.getString("skill_value_train")] = { lookup = "train", stat = 'animalhandling' },
		-- [Interface.getString("skill_value_climb")] = { lookup = "climb", stat = 'athletics' },
		-- [Interface.getString("skill_value_jump")] = { lookup = "jump", stat = 'athletics' },
		-- [Interface.getString("skill_value_run")] = { lookup = "run", stat = 'athletics' },
		-- [Interface.getString("skill_value_strength")] = { lookup = "strength", stat = 'athletics' },
		-- [Interface.getString("skill_value_swim")] = { lookup = "swim", stat = 'athletics' },
		-- [Interface.getString("skill_value_throw")] = { lookup = "throw", stat = 'athletics' },
		-- [Interface.getString("skill_value_empathy")] = { lookup = "empathy", stat = 'awareness' },
		-- [Interface.getString("skill_value_notice")] = { lookup = "notice", stat = 'awareness' },
		-- [Interface.getString("skill_value_decipher")] = { lookup = "decipher", stat = 'cunning' },
		-- [Interface.getString("skill_value_logic")] = { lookup = "logic", stat = 'cunning' },
		-- [Interface.getString("skill_value_memory")] = { lookup = "memory", stat = 'cunning' },
		-- [Interface.getString("skill_value_act")] = { lookup = "act", stat = 'deception' },
		-- [Interface.getString("skill_value_bluff")] = { lookup = "bluff", stat = 'deception' },
		-- [Interface.getString("skill_value_cheat")] = { lookup = "cheat", stat = 'deception' },
		-- [Interface.getString("skill_value_disguise")] = { lookup = "disguise", stat = 'deception' },
		-- [Interface.getString("skill_value_resilience")] = { lookup = "resilience", stat = 'endurance' },
		-- [Interface.getString("skill_value_stamina")] = { lookup = "stamina", stat = 'endurance' },
		-- [Interface.getString("skill_value_axes")] = { lookup = "axes", stat = 'fighting' },
		-- [Interface.getString("skill_value_bludgeons")] = { lookup = "bludgeons", stat = 'fighting' },
		-- [Interface.getString("skill_value_brawling")] = { lookup = "brawling", stat = 'fighting' },
		-- [Interface.getString("skill_value_fencing")] = { lookup = "fencing", stat = 'fighting' },
		-- [Interface.getString("skill_value_longblades")] = { lookup = "long blades", stat = 'fighting' },
		-- [Interface.getString("skill_value_polearms")] = { lookup = "polearms", stat = 'fighting' },
		-- [Interface.getString("skill_value_shields")] = { lookup = "shields", stat = 'fighting' },
		-- [Interface.getString("skill_value_shortblades")] = { lookup = "shortblades", stat = 'fighting' },
		-- [Interface.getString("skill_value_spears")] = { lookup = "spears", stat = 'fighting' },
		-- [Interface.getString("skill_value_diagnosis")] = { lookup = "diagnosis", stat = 'healing' },
		-- [Interface.getString("skill_value_treatailment")] = { lookup = "treatailment", stat = 'healing' },
		-- [Interface.getString("skill_value_treatinjury")] = { lookup = "treatinjury", stat = 'healing' },
		-- [Interface.getString("skill_value_education")] = { lookup = "education", stat = 'knowledge' },
		-- [Interface.getString("skill_value_research")] = { lookup = "research", stat = 'knowledge' },
		-- [Interface.getString("skill_value_streetwise")] = { lookup = "streetwise", stat = 'knowledge' },
		-- [Interface.getString("skill_value_bows")] = { lookup = "bows", stat = 'marksmanship' },
		-- [Interface.getString("skill_value_crossbows")] = { lookup = "crossbows", stat = 'marksmanship' },
		-- [Interface.getString("skill_value_siege")] = { lookup = "siege", stat = 'marksmanship' },
		-- [Interface.getString("skill_value_thrown")] = { lookup = "thrown", stat = 'marksmanship' },
		-- [Interface.getString("skill_value_targetshooting")] = { lookup = "targetshooting", stat = 'marksmanship' },
		-- [Interface.getString("skill_value_bargain")] = { lookup = "bargain", stat = 'persuasion' },
		-- [Interface.getString("skill_value_charm")] = { lookup = "charm", stat = 'persuasion' },
		-- [Interface.getString("skill_value_convince")] = { lookup = "convince", stat = 'persuasion' },
		-- [Interface.getString("skill_value_incite")] = { lookup = "incite", stat = 'persuasion' },
		-- [Interface.getString("skill_value_intimidate")] = { lookup = "intimidate", stat = 'persuasion' },
		-- [Interface.getString("skill_value_seduce")] = { lookup = "seduce", stat = 'persuasion' },
		-- [Interface.getString("skill_value_taunt")] = { lookup = "taunt", stat = 'persuasion' },
		-- [Interface.getString("skill_value_breeding")] = { lookup = "breeding", stat = 'status' },
		-- [Interface.getString("skill_value_reputation")] = { lookup = "reputation", stat = 'status' },
		-- [Interface.getString("skill_value_stewardship")] = { lookup = "stewardship", stat = 'status' },
		-- [Interface.getString("skill_value_tournaments")] = { lookup = "tournaments", stat = 'status' },
		-- [Interface.getString("skill_value_blendin")] = { lookup = "blendin", stat = 'stealth' },
		-- [Interface.getString("skill_value_sneak")] = { lookup = "sneak", stat = 'stealth' },
		-- [Interface.getString("skill_value_forage")] = { lookup = "forage", stat = 'survival' },
		-- [Interface.getString("skill_value_hunt")] = { lookup = "hunt", stat = 'survival' },
		-- [Interface.getString("skill_value_orientation")] = { lookup = "orientation", stat = 'survival' },
		-- [Interface.getString("skill_value_track")] = { lookup = "track", stat = 'survival' },
		-- [Interface.getString("skill_value_picklock")] = { lookup = "picklock", stat = 'thievery' },
		-- [Interface.getString("skill_value_sleightofhand")] = { lookup = "sleightofhand", stat = 'thievery' },
		-- [Interface.getString("skill_value_steal")] = { lookup = "steal", stat = 'thievery' },
		-- [Interface.getString("skill_value_command")] = { lookup = "command", stat = 'warfare' },
		-- [Interface.getString("skill_value_strategy")] = { lookup = "strategy", stat = 'warfare' },
		-- [Interface.getString("skill_value_tactics")] = { lookup = "tactics", stat = 'warfare' },
		-- [Interface.getString("skill_value_coordinate")] = { lookup = "coordinate", stat = 'will' },
		-- [Interface.getString("skill_value_courage")] = { lookup = "courage", stat = 'will' },
		-- [Interface.getString("skill_value_dedication")] = { lookup = "dedication", stat = 'will' }
	-- };

	-- ===================================================================================================================
	-- Weapon grade list data
	-- ===================================================================================================================
	wpngradedata = {
		"Common",
		"Superior",
		"Extraordinary",
		"Poor"
	};

	-- ===================================================================================================================
	-- Weapon skill list data
	-- ===================================================================================================================
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

	-- ===================================================================================================================
	-- Weapon damage abilities list data
	-- ===================================================================================================================
	wpndmgabilitydata = {
		Interface.getString("agility"),
		Interface.getString("athletics"),
		Interface.getString("animalhandling"),
	};

	-- ===================================================================================================================
	-- Party sheet drop down abilities list data
	-- ===================================================================================================================
	psabilitydata = {
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

	-- ===================================================================================================================
	-- Party sheet drop down skill list data
	-- ===================================================================================================================
	psskilldata = {
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

end

-- ===================================================================================================================
-- Abilities list
-- ===================================================================================================================
abilities = {
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

-- ===================================================================================================================
-- Abilities - Match shorthand to full name
-- ===================================================================================================================
ability_ltos = {
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

-- ===================================================================================================================
-- Abilities - Match full name to shorthand
-- ===================================================================================================================
ability_stol = {
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

-- ===================================================================================================================
-- Values for wound comparison
-- ===================================================================================================================
healthstatusfull = "healthy";
healthstatushalf = "bloodied";
healthstatuswounded = "wounded";

-- ===================================================================================================================
-- Values for size comparison
-- ===================================================================================================================
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

-- ===================================================================================================================
-- Values supported in effect conditionals
-- ===================================================================================================================
conditionaltags = {
};

-- ===================================================================================================================
-- Conditions supported in effect conditionals and for token widgets
-- ===================================================================================================================
conditions = {
	"blinded", 
	"deafened",
	"encumbered",
	"frightened", 
	"grappled", 
	"incapacitated",
	"intoxicated",
	"paralyzed",
	"poisoned",
	"prone", 
	"restrained",
	"stunned",
	"unconscious"
};

-- ===================================================================================================================
-- Bonus/penalty effect types for token widgets
-- ===================================================================================================================
bonuscomps = {
	-- "AC",
	"ATK",
	"BONUSD",
	-- "CHA",
	"CHECK",
	-- "CON",
	"DEF",
	-- "DEX",
	"DMG",
	"HEAL",
	"INIT",
	-- "INT",
	-- "SAVE",
	-- "STR",
	"TESTD",
	-- "WIS",
};

-- ===================================================================================================================
-- Condition effect types for token widgets, i.e. icon displayed
-- ===================================================================================================================
condcomps = {
	["blinded"] = "cond_blinded",
	["deafened"] = "cond_deafened",
	["encumbered"] = "cond_encumbered",
	["frightened"] = "cond_frightened",
	["grappled"] = "cond_grappled",
	["incapacitated"] = "cond_paralyzed",
	["intoxicated"] = "cond_intoxicated",
	["paralyzed"] = "cond_paralyzed",
	["prone"] = "cond_prone",
	["poisoned"] = "cond_poisoned",
	["restrained"] = "cond_restrained",
	["stunned"] = "cond_stunned",
	["unconscious"] = "cond_unconscious",

	-- Similar to conditions
	["cover"] = "cond_cover",
	["scover"] = "cond_cover",
};

-- ===================================================================================================================
-- Other visible effect types for token widgets
-- ===================================================================================================================
othercomps = {
	["COVER"] = "cond_cover",
	["SCOVER"] = "cond_cover",
};

-- ===================================================================================================================
-- Effect components which can be targeted
-- ===================================================================================================================
targetableeffectcomps = {
	"COVER",
	"SCOVER",
	"ATK",
	"DMG",
};

connectors = {
	"and",
	"or"
};

-- ===================================================================================================================
-- Range types supported
-- ===================================================================================================================
rangetypes = {
	"melee",
	"ranged"
};

-- ===================================================================================================================
-- Damage types supported
-- ===================================================================================================================
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

-- ===================================================================================================================
specialdmgtypes = {
	-- "critical",
};

-- ===================================================================================================================
-- Bonus types supported in power descriptions
-- ===================================================================================================================
bonustypes = {
};

-- ===================================================================================================================
stackablebonustypes = {
};