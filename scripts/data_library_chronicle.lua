-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

-- ===================================================================================================================
-- ===================================================================================================================
function getItemIsIdentified(vRecord, vDefault)
	return LibraryData.getIDState("item", vRecord, true);
end

-- ===================================================================================================================
-- ===================================================================================================================
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

-- ===================================================================================================================
-- ===================================================================================================================
function getNPCTypeValue(vNode)
	local v = StringManager.trim(DB.getValue(vNode, "type", ""));
	local sType = v:match("^[^(%s]+");
	if sType then
		v = StringManager.trim(sType);
	end
	v = StringManager.capitalize(v);
	return v;
end

-- ===================================================================================================================
-- ===================================================================================================================
function getItemRarityValue(vNode)
	local v = StringManager.trim(DB.getValue(vNode, "rarity", ""));
	local sType = v:match("^[^(]+");
	if sType then
		v = StringManager.trim(sType);
	end
	v = StringManager.capitalize(v);
	return v;
end

-- ===================================================================================================================
-- ===================================================================================================================
function getItemAttunementValue(vNode)
	local v = StringManager.trim(DB.getValue(vNode, "rarity", "")):lower();
	if v:match("%(requires attunement") then
		return LibraryData.sFilterValueYes;
	end
	return LibraryData.sFilterValueNo;
end

-- ===================================================================================================================
-- ===================================================================================================================
function isItemIdentifiable(vNode)
	local sBasePath = UtilityManager.getDataBaseNodePathSplit(vNode)
	return (sBasePath ~= "reference");
end

-- ===================================================================================================================
-- ===================================================================================================================
function getSpellSourceValue(vNode)
	if not vNode then
		return {};
	end
	return StringManager.split(DB.getValue(vNode, "source", ""), ",", true);
end

-- ===================================================================================================================
-- ===================================================================================================================
function getSpellViewGroup(v)
	if v and (v >= 1) and (v <= 9) then
		return StringManager.ordinalize(v);
	end
	return Interface.getString("library_recordtype_value_spell_level_0_group");
end

-- ===================================================================================================================
-- ===================================================================================================================
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

-- ===================================================================================================================
-- Adjusted
-- ===================================================================================================================
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
		aGMListButtons = { "button_npc_byletter", "button_npc_bytype" },
		-- aGMEditButtons = { "button_add_npc_import", "button_add_npc_import_text" },
		aCustomFilters = {
			["CR"] = { sField = "cr", sType = "number", fSort = sortNPCCRValues },
			["Type"] = { sField = "type", fGetValue = getNPCTypeValue },
		},
	},
	["item"] = { 
		fIsIdentifiable = isItemIdentifiable,
		aDataMap = { "item", "reference.equipmentdata" },
		aRecordDisplayClasses = { "item", "reference_armor", "reference_weapon", "reference_equipment", "reference_mountsandotheranimals", "reference_waterbornevehicles", "reference_vehicle" },
		aGMListButtons = { "button_item_armor", "button_item_weapon" },
		aPlayerListButtons = { "button_item_armor", "button_item_weapon" },
		aCustomFilters = {
			["Type"] = { sField = "type" },
		},
	},

	-- New record types
	["feat"] = {
		bExport = true, 
		aDataMap = { "feat", "reference.featdata" }, 
		sRecordDisplayClass = "reference_feat", 
	},
	["skill"] = {
		bExport = true, 
		aDataMap = { "skill", "reference.skilldata" }, 
		sRecordDisplayClass = "reference_skill", 
	},
};

aListViews = {
	["npc"] = {
		["byletter"] = {
			aColumns = {
				{ sName = "name", sType = "string", sHeadingRes = "npc_grouped_label_name", nWidth=250 },
			},
			aFilters = { },
			aGroups = { { sDBField = "name", nLength = 1 } },
			aGroupValueOrder = { },
		},
		["bytype"] = {
			aColumns = {
				{ sName = "name", sType = "string", sHeadingRes = "npc_grouped_label_name", nWidth=250 },
				{ sName = "cr", sType = "string", sHeadingRes = "npc_grouped_label_cr", sTooltipRe = "npc_grouped_tooltip_cr", bCentered=true },
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
				{ sName = "armor_rating", sType = "number", sHeadingRes = "item_grouped_label_ar", sTooltipRes = "item_grouped_tooltip_ar", nWidth=40, bCentered=true, nSortOrder=1 },
				{ sName = "armor_penalty", sType = "number", sHeadingRes = "item_grouped_label_ap", sTooltipRes = "item_grouped_tooltip_ap", nWidth=40, bCentered=true, nSortOrder=2 },
				{ sName = "bulk", sType = "number", sHeadingRes = "item_grouped_label_bulk", sTooltipRes = "item_grouped_tooltip_bulk", nWidth=40, bCentered=true },
			},
			aFilters = { 
				{ sDBField = "type", vFilterValue = "Armor" }, 
				{ sCustom = "item_isidentified" } 
			},
			aGroups = { { sDBField = "subtype" } },
			aGroupValueOrder = { "Light Armor", "Medium Armor", "Heavy Armor" },
		},
		["weapon"] = {
			aColumns = {
				{ sName = "name", sType = "string", sHeadingRes = "item_grouped_label_name", nWidth=150 },
				{ sName = "cost", sType = "string", sHeadingRes = "item_grouped_label_cost", bCentered=true },
				{ sName = "weapon_dmg_string", sType = "string", sHeadingRes = "item_grouped_label_dmg", sTooltipRes = "item_grouped_tooltip_weapon_dmg", nWidth=120, bWrapped=true },
				{ sName = "weapon_speciality", sType = "string", sHeadingRes = "item_grouped_label_weapon_skill", nWidth=80, bWrapped=true },
				{ sName = "weapon_training", sType = "number", sHeadingRes = "item_grouped_label_weapon_training", nWidth=60, bCentered=true },
				{ sName = "bulk", sType = "number", sHeadingRes = "item_grouped_label_bulk", sTooltipRes = "item_grouped_tooltip_bulk", nWidth=40, bCentered=true },
				{ sName = "weapon_qualities", sType = "string", sHeadingRes = "item_grouped_label_weapon_qualities", nWidth=400, bWrapped=true },
			},
			aFilters = { 
				{ sDBField = "type", vFilterValue = "Weapon" }, 
				{ sCustom = "item_isidentified" } 
			},
			aGroups = { { sDBField = "subtype" } },
			aGroupValueOrder = { "Melee Weapons", "Ranged Weapons" },
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
			aFilters = { { sDBField = "type", vFilterValue = "Mounts And Other Animals" } },
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
			aFilters = { { sDBField = "type", vFilterValue = "Tack, Harness, And Drawn Vehicles" } },
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

-- ===================================================================================================================
-- Adjusted
-- ===================================================================================================================
function onInit()
	LibraryData.setCustomFilterHandler("item_isidentified", getItemIsIdentified);

	LibraryData.overrideRecordTypes(aRecordOverrides);
	LibraryData.setRecordViews(aListViews);
	
	-- Remove "Vehicles" from the sidebar
	LibraryData.setRecordTypeInfo("vehicle", nil);
end