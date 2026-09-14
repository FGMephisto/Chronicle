-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

-- ===================================================================================================================
-- Ruleset action types
-- Adjusted
-- ===================================================================================================================
actions = {
	["dice"] = { bUseModStack = true, },
	["table"] = { sIcon = "action_table", },
	["attack"] = { sIcon = "action_attack", sTargeting = "each", bUseModStack = true, },
	["cast"] = { sIcon = "action_roll", sTargeting = "each", },
	["castsave"] = { sTargeting = "each", },
	["check"] = { sIcon = "action_roll", bUseModStack = true, },
	["concentration"] = { },
	["damage"] = { sIcon = "action_damage", sTargeting = "all", bUseModStack = true, },
	["death"] = { bUseModStack = true, },
	["death_auto"] = { },
	["heal"] = { sIcon = "action_heal", sTargeting = "all", bUseModStack = true, },
	["effect"] = { sIcon = "action_effect", sTargeting = "all", },
	["init"] = { sIcon = "action_roll", bUseModStack = true, },
	["powersave"] = { sIcon = "action_save", sTargeting = "each", sOpposed = "save", },
	["recharge"] = { },
	["recovery"] = { bUseModStack = true, },
	["save"] = { sIcon = "action_save", bUseModStack = true, },
	["save_auto"] = { },
	["skill"] = { sIcon = "action_roll", bUseModStack = true, },
};

currencies = { 
	{ name = "Gold", weight = 0.02, value = 200 },
	{ name = "Silver", weight = 0.02, value = 1 },
	{ name = "Copper", weight = 0.02, value = 0.02 },
};
currencyDefault = "Silver";

function onInit()	
	CharEncumbranceManager.addStandardCalc("Chronicle");
	CombatListManager.registerStandardInitSupport();
	
	ImageDeathMarkerManager.setEnabled(true);
	ImageDeathMarkerManager.registerGetCreatureTypeFunction(ActorCommonManager.getCreatureTypeDnD);
	ImageDeathMarkerManager.registerCreatureTypes(DataCommon.creaturetype);

	-- Languages
	languages = {
		[Interface.getString("language_value_common")] = "",
	};

	languagefonts = {
		[Interface.getString("language_value_celestial")] = "Celestial",
		[Interface.getString("language_value_draconic")] = "Draconic",
		[Interface.getString("language_value_dwarvish")] = "Dwarven",
		[Interface.getString("language_value_elvish")] = "Elven",
		[Interface.getString("language_value_infernal")] = "Infernal",
		[Interface.getString("language_value_primordial")] = "Primordial",
	};
end

-- ===================================================================================================================
-- Adjusted
-- ===================================================================================================================
function getCharSelectDetailHost(nodeChar)
	return "";
end

-- ===================================================================================================================
-- Adjusted
-- ===================================================================================================================
function requestCharSelectDetailClient()
	return "name";
end

-- ===================================================================================================================
-- Adjusted
-- ===================================================================================================================
function receiveCharSelectDetailClient(vDetails)
	return vDetails, "";
end

-- ===================================================================================================================
-- Adjusted
-- ===================================================================================================================
function getCharSelectDetailLocal(nodeLocal)
	local vDetails = {};
	table.insert(vDetails, DB.getValue(nodeLocal, "name", ""));
	return receiveCharSelectDetailClient(vDetails);
end

-- ===================================================================================================================
-- Adjusted
-- ===================================================================================================================
function getPregenCharSelectDetail(nodePregenChar)
	-- return CharClassManager.getCharClassSummary(nodePregenChar);
end

-- ===================================================================================================================
-- Adjusted
-- ===================================================================================================================
function getDistanceUnitsPerGrid()
	return 1;
end
