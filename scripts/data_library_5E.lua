-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function getVersionValue(node)
	return (StringManager.trim(DB.getValue(node, "version", "")) == "2024") and "2024" or "Legacy";
end

function getItemIsIdentified(vRecord, vDefault)
	return LibraryData.getIDState("item", vRecord, true);
end

function sortNPCCRValues(aFilterValues)
	local function fNPCSortValue(a)
		local v;
		if a == "1/2" then
			v = 0.5;
		elseif a == "1/4" then
			v = 0.25;
		elseif a == "1/8" then
			v = 0.125;
		else
			v = tonumber(a) or 0;
		end
		return v;
	end
	table.sort(aFilterValues, function(a,b) return fNPCSortValue(a) < fNPCSortValue(b); end);
	return aFilterValues;
end

function getNPCTypeValue(vNode)
	local v = StringManager.trim(DB.getValue(vNode, "type", ""));
	local sType = v:match("^[^(%s]+");
	if sType then
		v = StringManager.trim(sType);
	end
	v = StringManager.capitalize(v);
	return v;
end

function getItemRarityValue(vNode)
	local v = StringManager.trim(DB.getValue(vNode, "rarity", ""));
	local sType = v:match("^[^(]+");
	if sType then
		v = StringManager.trim(sType);
	end
	v = StringManager.capitalize(v);
	return v;
end

function getItemAttunementValue(vNode)
	local v = StringManager.trim(DB.getValue(vNode, "rarity", "")):lower();
	if v:match("%(requires attunement") then
		return Interface.getString("library_recordtype_filter_yes");
	end
	return Interface.getString("library_recordtype_filter_no");
end

function isItemIdentifiable(vNode)
	local sBasePath = UtilityManager.getDataBaseNodePathSplit(vNode)
	return (sBasePath ~= "reference");
end

function getSpellSourceValue(vNode)
	if not vNode then
		return {};
	end
	return StringManager.split(DB.getValue(vNode, "source", ""), ",", true);
end

function getSpellViewGroup(v)
	if v and (v >= 1) and (v <= 9) then
		return StringManager.ordinalize(v);
	end
	return Interface.getString("library_recordtype_value_spell_level_0_group");
end

function getSpellViewCastTime(vNode, vDefault)
	if not vNode then
		return vDefault;
	end
	local s = DB.getValue(vNode, "castingtime", vDefault);
	if not s then
		return vDefault;
	end
	if s:match("^%s*1 reaction") then
		return "1 reaction";
	end
	return s;
end

aRecordOverrides = {
	-- CoreRPG overrides
	["quest"] = { 
		aDataMap = { "quest", "reference.questdata" }, 
	},
	["image"] = { 
		aDataMap = { "image", "reference.imagedata" }, 
	},
	["npc"] = { 
		aDataMap = { "npc", "reference.npcdata" }, 
		aGMListButtons = { "button_npc_byletter", "button_npc_bycr", "button_npc_bytype" },
		aGMEditButtons = { "button_add_npc_import", "button_add_npc_import_text" },
		aCustomFilters = {
			["Version"] = { sField = "version", fGetValue = getVersionValue },
			["CR"] = { sField = "cr", sType = "number", fSort = sortNPCCRValues },
			["Type"] = { sField = "type", fGetValue = getNPCTypeValue },
		},
	},
	["item"] = { 
		fIsIdentifiable = isItemIdentifiable,
		aDataMap = { "item", "reference.equipmentdata", "reference.magicitemdata" }, 
		aRecordDisplayClasses = { "item", "reference_magicitem", "reference_armor", "reference_weapon", "reference_equipment", "reference_mountsandotheranimals", "reference_waterbornevehicles", "reference_vehicle" },
		aGMListButtons = { "button_item_armor", "button_item_weapon", "button_item_gear", "button_item_template" },
		--aGMEditButtons = { "button_add_item_import_text" },
		aPlayerListButtons = { "button_item_armor", "button_item_weapon", "button_item_gear" },
		aCustom = {
			tWindowMenu = { ["right"] = { "chat_output" } },
		},
		aCustomFilters = {
			["Version"] = { sField = "version", fGetValue = getVersionValue },
			["Type"] = { sField = "type" },
			["Rarity"] = { sField = "rarity", fGetValue = getItemRarityValue },
			["Attunement?"] = { sField = "rarity", fGetValue = getItemAttunementValue },
		},
	},
	["vehicle"] = {
		aCustomFilters = {
			["Version"] = { sField = "version", fGetValue = getVersionValue },
			["Type"] = { sField = "type" },
		},
	},
	
	-- New record types
	["itemtemplate"] = { 
		aDataMap = { "itemtemplate", "reference.magicrefitemdata" }, 
		aGMListButtons = { "button_forge_item"  };
		tOptions = {
			bExport = true,
			bHidden = true,
		},
		aCustomFilters = {
			["Version"] = { sField = "version", fGetValue = getVersionValue },
			["Type"] = { sField = "type" },
		},
	},
	["background"] = {
		aDataMap = { "background", "reference.backgrounddata" }, 
		sRecordDisplayClass = "reference_background", 
		tOptions = {
			bExport = true,
		},
		aCustom = {
			tWindowMenu = { ["right"] = { "chat_output" } },
		},
		aCustomFilters = {
			["Version"] = { sField = "version", fGetValue = getVersionValue },
		},
	},
	["class"] = {
		aDataMap = { "class", "reference.classdata" }, 
		sRecordDisplayClass = "reference_class", 
		aGMListButtons = { "button_class_specialization", "button_class_spell_view" },
		aPlayerListButtons = { "button_class_specialization", "button_class_spell_view" },
		tOptions = {
			bExport = true,
		},
		aCustom = {
			tWindowMenu = { ["right"] = { "chat_output" } },
		},
		aCustomFilters = {
			["Version"] = { sField = "version", fGetValue = getVersionValue },
		},
	},
	["class_specialization"] = {
		aDataMap = { "class_specialization", "reference.class_specializationdata" }, 
		sRecordDisplayClass = "reference_class_specialization", 
		tOptions = {
			bExport = true,
			bHidden = true,
		},
		aCustomFilters = {
			["Version"] = { sField = "version", fGetValue = getVersionValue },
			["Class"] = { sField = "class" },
		},
	},
	["class_spell_list"] = {
		aDataMap = { "class_spell_list", "reference.class_spell_listdata" }, 
		sRecordDisplayClass = "reference_class_spell_list", 
		tOptions = {
			bExport = true,
			bExportListSkip = true,
			bHidden = true,
		},
	},
	["feat"] = {
		aDataMap = { "feat", "reference.featdata" }, 
		sRecordDisplayClass = "reference_feat", 
		tOptions = {
			bExport = true,
		},
		aCustom = {
			tWindowMenu = { ["right"] = { "chat_output" } },
		},
		aCustomFilters = {
			["Version"] = { sField = "version", fGetValue = getVersionValue },
			["Category"] = { sField = "category" },
		},
	},
	["race"] = {
		aDataMap = { "race", "reference.racedata" }, 
		sRecordDisplayClass = "reference_race", 
		aGMListButtons = { "button_race_subrace" },
		aGMEditButtons = { "button_add_species_import_text" },
		aPlayerListButtons = { "button_race_subrace" },
		tOptions = {
			bExport = true,
		},
		aCustom = {
			tWindowMenu = { ["right"] = { "chat_output" } },
		},
		aCustomFilters = {
			["Version"] = { sField = "version", fGetValue = getVersionValue },
		},
	},
	["race_subrace"] = {
		aDataMap = { "race_subrace", "reference.race_subracedata" }, 
		sRecordDisplayClass = "reference_subrace", 
		tOptions = {
			bExport = true,
			bHidden = true,
		},
		aCustomFilters = {
			["Version"] = { sField = "version", fGetValue = getVersionValue },
			["Species"] = { sField = "race" },
		},
	},
	["skill"] = {
		aDataMap = { "skill", "reference.skilldata" }, 
		sRecordDisplayClass = "reference_skill", 
		tOptions = {
			bExport = true,
		},
		aCustom = {
			tWindowMenu = { ["right"] = { "chat_output" } },
		},
		aCustomFilters = {
			["Version"] = { sField = "version", fGetValue = getVersionValue },
		},
	},
	["spell"] = {
		aDataMap = { "spell", "reference.spelldata" }, 
		aRecordDisplayClasses = { "power", "reference_spell" },
		tOptions = {
			bExport = true,
			bPicture = true,
		},
		aCustom = {
			tWindowMenu = { ["right"] = { "chat_output" } },
		},
		aCustomFilters = {
			["Version"] = { sField = "version", fGetValue = getVersionValue },
			["Source"] = { sField = "source", fGetValue = getSpellSourceValue },
			["Level"] = { sField = "level", sType = "number" },
			["Ritual"] = { sField = "ritual", sType = "boolean" },
		},
	},
};

aListViews = {
	["npc"] = {
		["byletter"] = {
			aColumns = {
				{ sName = "name", sType = "string", sHeadingRes = "npc_grouped_label_name", nWidth=250 },
				{ sName = "cr", sType = "string", sHeadingRes = "npc_grouped_label_cr", sTooltipRes = "npc_grouped_tooltip_cr", bCentered=true },
			},
			aFilters = { },
			aGroups = { { sDBField = "name", nLength = 1 } },
			aGroupValueOrder = { },
		},
		["bycr"] = {
			aColumns = {
				{ sName = "name", sType = "string", sHeadingRes = "npc_grouped_label_name", nWidth=250 },
				{ sName = "cr", sType = "string", sHeadingRes = "npc_grouped_label_cr", sTooltipRes = "npc_grouped_tooltip_cr", bCentered=true },
			},
			aFilters = { },
			aGroups = { { sDBField = "cr", sPrefix = "CR" } },
			aGroupValueOrder = { "CR", "CR 0", "CR 1/8", "CR 1/4", "CR 1/2", 
								"CR 1", "CR 2", "CR 3", "CR 4", "CR 5", "CR 6", "CR 7", "CR 8", "CR 9" },
		},
		["bytype"] = {
			aColumns = {
				{ sName = "name", sType = "string", sHeadingRes = "npc_grouped_label_name", nWidth=250 },
				{ sName = "cr", sType = "string", sHeadingRes = "npc_grouped_label_cr", sTooltipRes = "npc_grouped_tooltip_cr", bCentered=true },
			},
			aFilters = { },
			aGroups = { { sDBField = "type" } },
			aGroupValueOrder = { },
		},
	},
	["item"] = {
		["armor"] = {
			aColumns = {
				{ sName = "name", sType = "string", sHeadingRes = "item_grouped_label_name", nWidth=150 },
				{ sName = "cost", sType = "string", sHeadingRes = "item_grouped_label_cost", bCentered=true },
				{ sName = "ac", sType = "number", sHeadingRes = "item_grouped_label_ac", sTooltipRes = "item_grouped_tooltip_ac", nWidth=40, bCentered=true, nSortOrder=1 },
				{ sName = "dexbonus", sType = "string", sHeadingRes = "item_grouped_label_dexbonus", sTooltipRes = "item_grouped_tooltip_dexbonus", nWidth=70, bCentered=true },
				{ sName = "strength", sType = "string", sHeadingRes = "item_grouped_label_strength", sTooltipRes = "item_grouped_tooltip_strength", bCentered=true },
				{ sName = "stealth", sType = "string", sHeadingRes = "item_grouped_label_stealth", sTooltipRes = "item_grouped_tooltip_stealth", nWidth=100, bCentered=true },
				{ sName = "weight", sType = "number", sHeadingRes = "item_grouped_label_weight", sTooltipRes = "item_grouped_tooltip_weight", nWidth=30, bCentered=true }
			},
			aFilters = { 
				{ sDBField = "type", vFilterValue = "Armor" }, 
				{ sCustom = "item_isidentified" } 
			},
			aGroups = { { sDBField = "subtype" } },
			aGroupValueOrder = { "Light Armor", "Medium Armor", "Heavy Armor", "Shield" },
		},
		["weapon"] = {
			aColumns = {
				{ sName = "name", sType = "string", sHeadingRes = "item_grouped_label_name", nWidth=150 },
				{ sName = "cost", sType = "string", sHeadingRes = "item_grouped_label_cost", bCentered=true },
				{ sName = "damage", sType = "string", sHeadingRes = "item_grouped_label_damage", nWidth=150, bCentered=true },
				{ sName = "weight", sType = "number", sHeadingRes = "item_grouped_label_weight", sTooltipRes = "item_grouped_tooltip_weight", nWidth=30, bCentered=true },
				{ sName = "properties", sType = "string", sHeadingRes = "item_grouped_label_properties", nWidth=300, bWrapped=true },
			},
			aFilters = { 
				{ sDBField = "type", vFilterValue = "Weapon" }, 
				{ sCustom = "item_isidentified" } 
			},
			aGroups = { { sDBField = "subtype" } },
			aGroupValueOrder = { "Simple Melee Weapons", "Simple Ranged Weapons", "Martial Weapons", "Martial Melee Weapons", "Martial Ranged Weapons" },
		},
		["gear"] = {
			aColumns = {
				{ sName = "name", sType = "string", sHeadingRes = "item_grouped_label_name", nWidth=150 },
				{ sName = "cost", sType = "string", sHeadingRes = "item_grouped_label_cost", bCentered=true },
				{ sName = "weight", sType = "number", sHeadingRes = "item_grouped_label_weight", sTooltipRes = "item_grouped_tooltip_weight", nWidth=30, bCentered=true },
			},
			aFilters = { 
				{ sDBField = "type", vFilterValue = "Adventuring Gear|Tools" }, 
				{ sCustom = "item_isidentified" },
			},
			aGroups = { { sDBField = "subtype" } },
		},
		["vehiclecomponent"] = {
			aColumns = {
				{ sName = "name", sType = "string", sHeadingRes = "item_grouped_label_name", nWidth=200 },
				{ sName = "cost", sType = "string", sHeadingRes = "item_label_cost", nWidth=200, bWrapped=true },
				{ sName = "crew", sType = "number", sHeadingRes = "item_label_crew", nWidth=40, bCentered=true },
				{ sName = "ac", sType = "number", sHeadingRes = "ac", sTooltipRes = "armorclass", nWidth=40, bCentered=true },
				{ sName = "damagethreshold", sType = "number", sHeadingRes = "dt", sTooltipRes = "damagethreshold", nWidth=40, bCentered=true },
				{ sName = "hp", sType = "number", sHeadingRes = "hp", sTooltipRes = "hitpoints", bCentered=true },
			},
			aFilters = { 
				{ sDBField = "type", vFilterValue = "Vehicle Component" }, 
				{ sCustom = "item_isidentified" } 
			},
			aGroups = { { sDBField = "type" } },
			aGroupValueOrder = {},
		},
		["vehiclecomponentupgrade"] = {
			aColumns = {
				{ sName = "name", sType = "string", sHeadingRes = "item_grouped_label_name", nWidth=200 },
				{ sName = "cost", sType = "string", sHeadingRes = "item_label_cost", nWidth=100, bWrapped=true },
			},
			aFilters = { 
				{ sDBField = "type", vFilterValue = "Vehicle Component Upgrade" }, 
				{ sCustom = "item_isidentified" } 
			},
			aGroups = { { sDBField = "type" } },
			aGroupValueOrder = {},
		},
		["vehicledrawn"] = {
			aColumns = {
				{ sName = "name", sType = "string", sHeadingRes = "item_grouped_label_name", nWidth=150 },
				{ sName = "cost", sType = "string", sHeadingRes = "item_grouped_label_cost", nWidth=70, bCentered=true },
				{ sName = "speed", sType = "string", sHeadingRes = "item_grouped_label_speed", nWidth=60, bCentered=true },
				{ sName = "carryingcapacity", sType = "string", sHeadingRes = "item_grouped_label_carryingcapacity", sTooltipRes="item_grouped_tooltip_carryingcapacity", nWidth=70, bCentered=true },
			},
			aFilters = { { sDBField = "type", vFilterValue = "Tack, Harness, And Drawn Vehicles" } },
			aGroups = { { sDBField = "subtype" } },
			aGroupValueOrder = { },
		},
		["vehiclemount"] = {
			aColumns = {
				{ sName = "name", sType = "string", sHeadingRes = "item_grouped_label_name", nWidth=150 },
				{ sName = "cost", sType = "string", sHeadingRes = "item_grouped_label_cost", nWidth=70, bCentered=true },
				{ sName = "speed", sType = "string", sHeadingRes = "item_grouped_label_speed", nWidth=60, bCentered=true },
				{ sName = "carryingcapacity", sType = "string", sHeadingRes = "item_grouped_label_carryingcapacity", sTooltipRes="item_grouped_tooltip_carryingcapacity", nWidth=70, bCentered=true },
			},
			aFilters = { { sDBField = "type", vFilterValue = "Mounts And Other Animals" } },
			aGroups = { { sDBField = "subtype" } },
			aGroupValueOrder = { },
		},
		["vehiclewater"] = {
			aColumns = {
				{ sName = "name", sType = "string", sHeadingRes = "item_grouped_label_name", nWidth=150 },
				{ sName = "cost", sType = "string", sHeadingRes = "item_grouped_label_cost", nWidth=70, bCentered=true },
				{ sName = "speed", sType = "string", sHeadingRes = "item_grouped_label_speed", nWidth=60, bCentered=true },
				{ sName = "carryingcapacity", sType = "string", sHeadingRes = "item_grouped_label_carryingcapacity", sTooltipRes="item_grouped_tooltip_carryingcapacity", nWidth=70, bCentered=true },
			},
			aFilters = { { sDBField = "type", vFilterValue = "Waterborne Vehicles" } },
			aGroups = { { sDBField = "subtype" } },
			aGroupValueOrder = { },
		},
	},
};

function onInit()
	LibraryData.setCustomFilterHandler("item_isidentified", getItemIsIdentified);
	LibraryData.setCustomGroupOutputHandler("spell_view_level_group", getSpellViewGroup);
	LibraryData.setCustomColumnHandler("spell_view_castingtime", getSpellViewCastTime);

	LibraryData.overrideRecordTypes(aRecordOverrides);
	LibraryData.setRecordViews(aListViews);
end
