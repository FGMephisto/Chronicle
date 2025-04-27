--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

-- Ruleset action types
actions = {
	["dice"] = { bUseModStack = true },
	["table"] = { },
	["cast"] = { sTargeting = "each" },
	["castsave"] = { sTargeting = "each" },
	["death"] = { bUseModStack = true },
	["death_auto"] = { },
	["concentration"] = { },
	["powersave"] = { sTargeting = "each" },
	["attack"] = { sIcon = "action_attack", sTargeting = "each", bUseModStack = true },
	["damage"] = { sIcon = "action_damage", sTargeting = "all", bUseModStack = true },
	["heal"] = { sIcon = "action_heal", sTargeting = "all", bUseModStack = true },
	["effect"] = { sIcon = "action_effect", sTargeting = "all" },
	["init"] = { bUseModStack = true },
	["save"] = { bUseModStack = true },
	["check"] = { bUseModStack = true },
	["recharge"] = { },
	["recovery"] = { bUseModStack = true },
	["skill"] = { bUseModStack = true },
};

-- Adjusted
targetactions = {
	"cast",
	-- "castsave",
	-- "powersave",
	"attack",
	"damage",
	"heal",
	"effect"
};

currencies = { 
	{ name = "Gold", weight = 0.02, value = 200 },
	{ name = "Silver", weight = 0.02, value = 1 },
	{ name = "Copper", weight = 0.02, value = 0.02 },
};
currencyDefault = "Silver";

-- Adjusted
function onInit()
	CharEncumbranceManager.addStandardCalc("Chronicle") -- Add ruleset to supported rulesets for Encumberance calculation
	CombatListManager.registerStandardInitSupport();

	-- Add death marker manager
	-- ImageDeathMarkerManager.registerStandardDeathMarkersDnD();
	-- ImageDeathMarkerManager.setEnabled(true);
	-- ImageDeathMarkerManager.registerGetCreatureTypeFunction(ActorCommonManager.getCreatureTypeDnD);
	-- ImageDeathMarkerManager.registerCreatureTypes(DataCommon.creaturetype);

	ImageDeathMarkerManager.registerStandardDeathMarkersDnD();
	SoundsetManager.registerStandardSettingsCastAndAttack();
	SoundsetManager.setRecordTypeDropCallback("spell", SoundsetManager.handleStandardSpellDrop);

	VisionManager.addVisionType(Interface.getString("vision_darkvision_superior"), "darkvision");
	-- VisionManager.addVisionType(Interface.getString("vision_devilsight"), "truesight");
	-- VisionManager.addVisionType(Interface.getString("vision_devilsight_alt"), "truesight");

	-- LocationManager.registerLocationType({
		-- sKey = StringManager.simplify(Interface.getString("location_type_bastion")),
		-- sSub = "location_main_bastion",
	-- });
	-- LocationManager.registerLocationType({
		-- sKey = StringManager.simplify(Interface.getString("location_type_bastionfacility")),
		-- sSub = "location_main_bastionfacility",
	-- });

	-- Languages
	languages = {
		-- Standard languages
		[Interface.getString("language_value_common")] = "",
		[Interface.getString("language_value_common_sign")] = "",
		[Interface.getString("language_value_dwarvish")] = "Dwarven",
		[Interface.getString("language_value_elvish")] = "Elven",
		[Interface.getString("language_value_giant")] = "Dwarven",
		-- [Interface.getString("language_value_gnomish")] = "Dwarven",
		-- [Interface.getString("language_value_goblin")] = "Dwarven",
		-- [Interface.getString("language_value_halfling")] = "",
		-- [Interface.getString("language_value_orc")] = "Dwarven",
		-- Exotic languages
		-- [Interface.getString("language_value_abyssal")] = "Infernal",
		-- [Interface.getString("language_value_aquan")] = "Elven",
		-- [Interface.getString("language_value_auran")] = "Draconic",
		-- [Interface.getString("language_value_celestial")] = "Celestial",
		-- [Interface.getString("language_value_deepspeech")] = "",
		-- [Interface.getString("language_value_draconic")] = "Draconic",
		-- [Interface.getString("language_value_ignan")] = "Draconic",
		-- [Interface.getString("language_value_infernal")] = "Infernal",
		-- [Interface.getString("language_value_primordial")] = "Primordial",
		-- [Interface.getString("language_value_sylvan")] = "Elven",
		-- [Interface.getString("language_value_terran")] = "Dwarven",
		-- [Interface.getString("language_value_undercommon")] = "Elven",
		-- [Interface.getString("language_value_aarakocra")] = "",
		-- [Interface.getString("language_value_druidic")] = "",
		-- [Interface.getString("language_value_thievescant")] = "",
	};
	languagefonts = {
		[Interface.getString("language_value_celestial")] = "Celestial",
		[Interface.getString("language_value_draconic")] = "Draconic",
		[Interface.getString("language_value_dwarvish")] = "Dwarven",
		[Interface.getString("language_value_elvish")] = "Elven",
		[Interface.getString("language_value_infernal")] = "Infernal",
		[Interface.getString("language_value_primordial")] = "Primordial",
	};
	languagestandard = {
		Interface.getString("language_value_common_sign"),
		-- Interface.getString("language_value_draconic"),
		Interface.getString("language_value_dwarvish"),
		Interface.getString("language_value_elvish"),
		Interface.getString("language_value_giant"),
		-- Interface.getString("language_value_gnomish"),
		-- Interface.getString("language_value_goblin"),
		-- Interface.getString("language_value_halfling"),
		-- Interface.getString("language_value_orc"),
	};
end

-- Adjusted
function getCharSelectDetailHost(nodeChar)
	-- local sValue = "";
	-- local nLevel = DB.getValue(nodeChar, "level", 0);
	-- if nLevel > 0 then
		-- sValue = "Level " .. math.floor(nLevel*100)*0.01;
	-- end
	-- return sValue;
	return "";
end

-- Adjusted
function requestCharSelectDetailClient()
	-- return "name,#level";
	return "name";
end

-- Adjusted
function receiveCharSelectDetailClient(vDetails)
	-- return vDetails[1], "Level " .. math.floor(vDetails[2]*100)*0.01;
	return vDetails, "";
end

-- Adjusted
function getPregenCharSelectDetail(nodePregenChar)
	-- return CharClassManager.getCharClassSummary(nodePregenChar);
end

-- Adjusted
function getDistanceUnitsPerGrid()
	return 1;
end
