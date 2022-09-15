-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

-- ===================================================================================================================
-- Ruleset action types
-- ===================================================================================================================
actions = {
	["dice"] = { bUseModStack = true },
	["table"] = { },
	["cast"] = { sTargeting = "each" },
	["castsave"] = { sTargeting = "each" },
	["death"] = { },
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

-- ===================================================================================================================
-- ===================================================================================================================
targetactions = {
	"cast",
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

-- ===================================================================================================================
-- ===================================================================================================================
function onInit()	
	-- Add ruleset to supported rulesets for Encumberance calculation
	CharEncumbranceManager.addStandardCalc("Chronicle")

	-- Languages
	languages = {
		[Interface.getString("language_value_common")] = "",
	}

	languagefonts = {
		[Interface.getString("language_value_celestial")] = "Celestial",
		[Interface.getString("language_value_draconic")] = "Draconic",
		[Interface.getString("language_value_dwarvish")] = "Dwarven",
		[Interface.getString("language_value_elvish")] = "Elven",
		[Interface.getString("language_value_infernal")] = "Infernal",
		[Interface.getString("language_value_primordial")] = "Primordial",
	}
end

-- ===================================================================================================================
-- ===================================================================================================================
function getCharSelectDetailHost(nodeChar)
	return "";
end

-- ===================================================================================================================
-- ===================================================================================================================
function requestCharSelectDetailClient()
	return "name";
end

-- ===================================================================================================================
-- ===================================================================================================================
function receiveCharSelectDetailClient(vDetails)
	return vDetails, "";
end

-- ===================================================================================================================
-- ===================================================================================================================
function getCharSelectDetailLocal(nodeLocal)
	local vDetails = {};
	table.insert(vDetails, DB.getValue(nodeLocal, "name", ""));
	return receiveCharSelectDetailClient(vDetails);
end

-- ===================================================================================================================
-- ===================================================================================================================
function getDistanceUnitsPerGrid()
	return 1;
end
