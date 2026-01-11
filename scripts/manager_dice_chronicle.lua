--
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

--luacheck: ignore 631

local _tActorDiceSystemRules = {
	-- ["dragon_red"] = {
		-- sName = "Red Dragon|Adult Red Dragon|Ancient Red Dragon|Faerie Dragon (red)|Half-Red Dragon Veteran|Red Dragon Wyrmling|Young Red Dragon|Young Red Shadow Dragon|Guard Drake (Red)|Dragon Army Dragonnel|Wasteland Dragonnel", 
		-- sDefaultKey = "dragon_red",
	-- },
	-- ["dragon_blue"] = {
		-- sName = "Blue Dragon|Adult Blue Dragon|Ancient Blue Dragon|Blue Dragon Wyrmling|Faerie Dragon (blue)|Young Blue Dragon|Guard Drake (Blue)",
		-- sDefaultKey = "dragon_blue",
	-- },
	-- ["dragon_green"] = {
		-- sName = "Green Dragon|Adult Green Dragon|Ancient Green Dragon|Faerie Dragon (green)|Green Dragon Wyrmling|Young Green Dragon|Guard Drake (Green)|Venomfang",
		-- sDefaultKey = "dragon_green",
	-- },
	-- ["dragon_black"] = {
		-- sName = "Black Dragon|Adult Black Dragon|Ancient Black Dragon|Black Dragon Wyrmling|Young Black Dragon|Guard Drake (Black)",
		-- sDefaultKey = "dragon_black",
	-- },
	-- ["dragon_white"] = {
		-- sName = "White Dragon|Adult White Dragon|Ancient White Dragon|Young White Dragon|White Dragon Wyrmling|Guard Drake (White)",
		-- sDefaultKey = "dragon_white",
	-- },
	-- ["dragon_gold"] = {
		-- sName = "Gold Dragon|Adult Gold Dragon|Ancient Gold Dragon|Gold Dragon Wyrmling|Young Gold Dragon|Aurak Draconian",
		-- sDefaultKey = "dragon_gold",
	-- },
	-- ["dragon_silver"] = {
		-- sName = "Silver Dragon|Adult Silver Dragon|Ancient Silver Dragon|Silver Dragon Wyrmling|Young Silver Dragon|Sivak Draconian",
		-- sDefaultKey = "dragon_silver",
	-- },
	-- ["dragon_bronze"] = {
		-- sName = "Bronze Dragon|Adult Bronze Dragon|Ancient Bronze Dragon|Bronze Dragon Wyrmling|Young Bronze Dragon|Bozak Draconian",
		-- sDefaultKey = "dragon_bronze",
	-- },
	-- ["dragon_copper"] = {
		-- sName = "Copper Dragon|Adult Copper Dragon|Ancient Copper Dragon|Copper Dragon Wyrmling|Young Copper Dragon|Kapak Draconian",
		-- sDefaultKey = "dragon_copper",
	-- },
	-- ["dragon_brass"] = {
		-- sName = "Brass Dragon|Adult Brass Dragon|Ancient Brass Dragon|Brass Dragon Wyrmling|Young Brass Dragon|Baaz Draconian",
		-- sDefaultKey = "dragon_brass",
	-- },
	-- ["elemental_air"] = {
		-- sName = "Air Elemental|Air Elemental Myrmidon|Djinni|Dust Mephit|Invisible Stalker|Smoke Mephit|Steam Mephit",
		-- sDefaultKey = "elemental_air",
	-- },
	-- ["elemental_earth"] = {
		-- sName = "Earth Elemental|Earth Elemental Myrmidon|Galeb Duhr|Mud Mephit|Xorn|Dust Mephit",
		-- sDefaultKey = "elemental_earth",
	-- },
	-- ["elemental_fire"] = {
		-- sName = "Fire Elemental|Fire Elemental Myrmidon|Fire Snake|Magma Mephit|Magmin|Salamander|Azer|Efreeti",
		-- sDefaultKey = "elemental_fire",
	-- },
	-- ["elemental_water"] = {
		-- sName = "Water Elemental|Water Elemental Myrmidon|Water Weird|Ice Mephit|Marid",
		-- sDefaultKey = "elemental_water",
	-- },
	-- ["undead_vampire"] = {
		-- sName = "Vampire|Vampire Spawn|Vampire Spellcaster|Vampire Warrior",
		-- sDefaultKey = "undead_vampire",
	-- },
	-- ["undead_mummy"] = {
		-- sName = "Mummy|Mummy Lord|Demilich|Lich",
		-- sDefaultKey = "undead_mummy",
	-- },
	-- ["undead_zombie"] = {
		-- sName = "Ogre Zombie|Zombie|Beholder Zombie|Ghoul|Ghast",
		-- sDefaultKey = "undead_zombie",
	-- },
	-- ["undead_skeleton"] = {
		-- sName = "Warhorse Skeleton|Minotaur Skeleton|Skeleton|Bone Devil|Bone Devil (variant)",
		-- sDefaultKey = "undead_skeleton",
	-- },
	-- ["humanoid_were"] = {
		-- sName = "Werebear|Wereboar|Wererat|Weretiger|Werewolf",
		-- sDefaultKey = "humanoid_were",
	-- },
	-- ["beast_insect"] = {
		-- sName = "Giant Centipeded|Giant Fire Beetle|Giant Scorpion|Giant Wasp|Scorpion|Swarm of Insects|Swarm of Insects (Beetles)|Swarm of Insects (Centipedes)|Swarm of Insects (Wasps)",
		-- sDefaultKey = "beast_insect",
	-- },
	-- ["beast_reptile"] = {
		-- sName = "Allosaurus|Ankylosaurus|Crocodile|Giant Crocodile|Giant Lizard|Lizard|Lizardfolk|Lizardfolk Shaman|Lizardfolk King/Queen||Pteranodon|Triceratops|Tyrannosaurus Rex",
		-- sDefaultKey = "beast_reptile",
	-- },
	-- ["humanoid_death"] = {
		-- sName = "Death Knight|Death Slaad|Death Tyrant|Revenant|Wraith",
		-- sDefaultKey = "humanoid_death",
	-- },
	-- ["beast_aquatic"] = {
		-- sName = "Aboleth|Plesiosaurus|Dragon Turtle|Giant Octopus|Giant Shark|Hunter Shark|Killer Whale|Kuo-toa|Kuo-toa Archpriest|Kuo-toa Monitor|Kuo-toa Whip|Merfolk|Merrow|Octopus|Reef Shark|Sea Hag|Sea Horse|Swarm of Quippers",
		-- sDefaultKey = "beast_aquatic",
	-- },
	-- ["beast_avian"] = {
		-- sName = "Aarakocra|Axe Beak|Blood Hawk|Cockatrice|Eagle|Giant Eagle|Giant Owl|Owl|Hawk|Owlbear|Peryton|Raven|Swarm of Ravens",
		-- sDefaultKey = "beast_avian",
	-- },
};
local _tActorSystemDefaults = {
	-- ["dragon_red"] = {
		-- { diceskin = 282 }
	-- },
	-- ["dragon_blue"] = {
		-- { diceskin = 283 }
	-- },
	-- ["dragon_green"] = {
		-- { diceskin = 284 }
	-- },
	-- ["dragon_black"] = {
		-- { diceskin = 285 }
	-- },
	-- ["dragon_white"] = {
		-- { diceskin = 286 }
	-- },
	-- ["dragon_gold"] = {
		-- { diceskin = 287 }
	-- },
	-- ["dragon_silver"] = {
		-- { diceskin = 288 }
	-- },
	-- ["dragon_bronze"] = {
		-- { diceskin = 289 }
	-- },
	-- ["dragon_copper"] = {
		-- { diceskin = 290 }
	-- },
	-- ["dragon_brass"] = {
		-- { diceskin = 291 }
	-- },
	-- ["elemental_air"] = {
		-- { diceskin = 108 }
	-- },
	-- ["elemental_earth"] = {
		-- { diceskin = 107 }
	-- },
	-- ["elemental_fire"] = {
		-- { diceskin = 106 }
	-- },
	-- ["elemental_water"] = {
		-- { diceskin = 109 }
	-- },
	-- ["undead_vampire"] = {
		-- { diceskin = 302 }
	-- },
	-- ["undead_mummy"] = {
		-- { diceskin = 303 }
	-- },
	-- ["undead_zombie"] = {
		-- { diceskin = 304 }
	-- },
	-- ["undead_skeleton"] = {
		-- { diceskin = 305 }
	-- },
	-- ["humanoid_were"] = {
		-- { diceskin = 306 }
	-- },
	-- ["beast_insect"] = {
		-- { diceskin = 307 }
	-- },
	-- ["beast_reptile"] = {
		-- { diceskin = 308 }
	-- },
	-- ["humanoid_death"] = {
		-- { diceskin = 309 }
	-- },
	-- ["beast_aquatic"] = {
		-- { diceskin = 310 }
	-- },
	-- ["beast_avian"] = {
		-- { diceskin = 311 }
	-- },
};
local _tActorTypeDefaults = {
	-- ["aberration"] = {
		-- { diceskin = 261 }
	-- },
	["beast"] = {
		{ diceskin = 269 },
		{ diceskin = 95 }
	},
	-- ["celestial"] = {
		-- { diceskin = 262 }
	-- },
	-- ["construct"] = {
		-- { diceskin = 265 }
	-- },
	-- ["elemental"] = {
		-- { diceskin = 108 }
	-- },
	-- ["fey"] = {
		-- { diceskin = 263 }
	-- },
	-- ["fiend"] = {
		-- { diceskin = 270 },
		-- { diceskin = 0, dicebodycolor="FF000000", dicetextcolor="FFFF000" }
	-- },
	-- ["giant"] = {
		-- { diceskin = 267 }
	-- },
	-- ["ooze"] = {
		-- { diceskin = 266 }
	-- },
	-- ["plant"] = {
		-- { diceskin = 268 }
	-- },
	["undead"] = {
		{ diceskin = 260 },
		{ diceskin = 101 }
	},
};

function onInit()
	DiceRollManager.registerActorSupportDnD();
	DiceManager5E.registerActorTypeDefaults();
	DiceManager5E.registerActorSystemDefaults();
	DiceManager5E.registerActorSystemRules();

	DiceManager5E.registerActions();
end

-- Adjusted
function registerActions()
	DiceRollManager.registerDamageTypeMode("critical");

	DiceRollManager.registerDamageKey();
	-- DiceRollManager.registerDamageTypeKey("acid", "life");
	DiceRollManager.registerDamageTypeKey("cold", "frost");
	DiceRollManager.registerDamageTypeKey("fire", "fire");
	-- DiceRollManager.registerDamageTypeKey("force", "arcane");
	-- DiceRollManager.registerDamageTypeKey("lightning", "lightning");
	-- DiceRollManager.registerDamageTypeKey("necrotic", "shadow");
	DiceRollManager.registerDamageTypeKey("poison", "life");
	-- DiceRollManager.registerDamageTypeKey("psychic", "shadow");
	-- DiceRollManager.registerDamageTypeKey("radiant", "light");
	-- DiceRollManager.registerDamageTypeKey("thunder", "storm");

	DiceRollManager.registerDamageTypeKey("bludgeoning");
	DiceRollManager.registerDamageTypeKey("piercing");
	DiceRollManager.registerDamageTypeKey("slashing");

	-- DiceRollManager.registerDamageTypeKey("adamantine");
	-- DiceRollManager.registerDamageTypeKey("cold-forged iron");
	-- DiceRollManager.registerDamageTypeKey("silver");

	-- DiceRollManager.registerDamageTypeKey("magic");

	DiceRollManager.registerHealKey();
	DiceRollManager.registerHealTypeKey("health", "light");
	-- DiceRollManager.registerHealTypeKey("temp", "water");
end

function registerActorTypeDefaults()
	for k,v in pairs(_tActorTypeDefaults) do
		DiceRollManager.setDiceSkinDefaults(k, v);
	end
end
function registerActorSystemDefaults()
	for k,v in pairs(_tActorSystemDefaults) do
		DiceRollManager.setDiceSkinDefaults(k, v);
	end
end
function registerActorSystemRules()
	for k,v in pairs(_tActorDiceSystemRules) do
		DiceRollManager.setActorSystem(k, v);
	end
end