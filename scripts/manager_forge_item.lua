--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local FORGE_PATH_BASE_ITEMS = "forge.magicitem.baseitems";
local FORGE_PATH_TEMPLATES = "forge.magicitem.templates";

local RARITY_UNKNOWN = 1;
local RARITY_COMMON = 2;
local RARITY_UNCOMMON = 3;
local RARITY_RARE = 4;
local RARITY_VERY_RARE = 5;
local RARITY_LEGENDARY = 6;

local CURRENCY_VALUES = { cp = 1, sp = 10, ep = 50, gp = 100, pp = 1000 }

local _tItems = {};
local _tTemplates = {};

function setStatus(w, sStatusIcon, sStatus)
	w.sub_buttons.subwindow.statusicon.setStringValue(sStatusIcon);
	w.sub_buttons.subwindow.status.setValue(sStatus);
end
function clearStatus(w)
	w.sub_buttons.subwindow.statusicon.setIndex(0);
	w.sub_buttons.subwindow.status.setValue("");
end

function onDrop(_, draginfo)
	if draginfo.getType() == "shortcut" then
		local sClass, sRecord = draginfo.getShortcutData();
		if RecordDataManager.isRecordTypeDisplayClass("itemtemplate", sClass) then
			ForgeManagerItem.addTemplate(sClass, sRecord);
		elseif RecordDataManager.isRecordTypeDisplayClass("item", sClass) then
			ForgeManagerItem.addBaseItem(sClass, sRecord);
		elseif RecordDataManager.isRecordTypeDisplayClass("spell", sClass) then
			ForgeManagerItem.addSpellAsTemplate(sClass, sRecord);
		end
	end
	return true;
end
function addBaseItem(sClass, sRecord)
	local nodeSource = DB.findNode(sRecord);
	if not nodeSource then
		return;
	end

	local nodeTarget = DB.createChildAndCopy(FORGE_PATH_BASE_ITEMS, nodeSource);
	DB.setValue(nodeTarget, "locked", "number", 1);
	DB.setValue(nodeTarget, "refclass", "string", sClass);
end
function addTemplate(sClass, sRecord)
	local nodeSource = DB.findNode(sRecord);
	if not nodeSource then
		return;
	end

	local nodeTarget = DB.createChildAndCopy(FORGE_PATH_TEMPLATES, nodeSource);
	DB.setValue(nodeTarget, "locked", "number", 1);
	DB.setValue(nodeTarget, "refclass", "string", sClass);
end

function addSpellAsTemplate(sClass, sRecord)
	-- get the spell and assign it to nodeSource
	local nodeSource = DB.findNode(sRecord);
	if not nodeSource then
		return;
	end

	-- get School, level and name
	local level = DB.getValue(nodeSource, "level", 0);
	local school = DB.getValue(nodeSource, "school", "");
	local sDescription = DB.getValue(nodeSource, "description", "");
	local sName = DB.getValue(nodeSource, "name", "");
	local sCastingTime = DB.getValue(nodeSource, "castingtime", "");
	local sRange = DB.getValue(nodeSource, "range", "");
	local sComponents = DB.getValue(nodeSource, "components", "");
	local sDuration = DB.getValue(nodeSource, "duration", "");
	local sSource = DB.getValue(nodeSource, "source", "");

	local sSubtype;
	if (level == 0) then
		sSubtype = school .. " (Cantrip)";
	else
		sSubtype = school .. " (Level " .. tostring(level) .. ")";
	end
	local rarity = ForgeManagerItem.getRarityBasedOnLevel(level);

	-- create a new template node and assign known values
	local nodeTarget = DB.createChildAndCopy(FORGE_PATH_TEMPLATES, nodeSource);
	DB.setValue(nodeTarget, "locked", "number", 1);
	DB.setValue(nodeTarget, "refclass", "string", sClass);
	DB.setValue(nodeTarget, "type", "string", "spell");
	DB.setValue(nodeTarget, "rarity", "string", rarity);
	DB.setValue(nodeTarget, "subtype", "string", sSubtype);
	-- set the default spell value to 0. It should get picked up by the scroll
	DB.setValue(nodeTarget, "cost", "string", "0 gp");
	-- &#13; is a line feed
	DB.setValue(nodeTarget, "description", "formattedtext",
			"<h>" .. sName .. "</h><p><i>" .. sSubtype .. "</i></p>" ..
			"<p><b>Casting Time:</b> " .. sCastingTime ..
			"<b>&#13;Range:</b> " .. sRange ..
			"<b>&#13;Components:</b> " .. sComponents ..
			"<b>&#13;Duration:</b> " .. sDuration ..
			"</p>" ..  sDescription ..
			"<p><b>Source:</b> " .. sSource .. "</p>"
		);
end

-- Get a rarity value based on a spell's level
function getRarityBasedOnLevel(level)
	local rarity = ""

	if level == 0 or level == 1 then
		rarity = "Common"
	elseif level == 2 or level == 3 then
		rarity = "Uncommon"
	elseif level == 4 or level == 5 then
		rarity = "Rare"
	elseif level >= 6 and level <= 8 then
		rarity = "Very Rare"
	elseif level == 9 then
		rarity = "Legendary"
	end

	return rarity
end

function reset()
	DB.deleteChildren(FORGE_PATH_BASE_ITEMS);
	DB.deleteChildren(FORGE_PATH_TEMPLATES);
end
function forgeMagicItem(w)
	if not w then
		return;
	end

	-- Cache item and template nodes
	_tItems = DB.getChildList(FORGE_PATH_BASE_ITEMS);
	_tTemplates = DB.getChildList(FORGE_PATH_TEMPLATES);

	-- Validate forging data
	if ((#_tItems ~= 0) and (#_tTemplates ~= 0)) or (#_tTemplates >= 2) then
		ForgeManagerItem.createMagicItem();
		ForgeManagerItem.setStatus(w, "ok", Interface.getString("forge_item_message_success"));
	else
		ForgeManagerItem.setStatus(w, "error", Interface.getString("forge_item_message_missing"));
	end
end

function getDisplayType(node)
	local sIcon = "";

	local bMagicItem = (DB.getValue(node, "rarity", "") ~= "");

	local sTypeLower = StringManager.trim(DB.getValue(node, "type", ""):lower());
	if StringManager.contains({"armor", "weapon", "tool"}, sTypeLower) then
		sIcon = sTypeLower;
	elseif StringManager.contains({"mount", "vehicle"}, sTypeLower) then
		bMagicItem = false;
		sIcon = sTypeLower;
	elseif StringManager.contains({"potion", "ring", "rod", "scroll", "staff", "wand"}, sTypeLower) then
		bMagicItem = true;
		sIcon = sTypeLower;
	elseif sTypeLower == "wondrous item" then
		bMagicItem = true;
		sIcon = "wondrousitem";
	elseif DB.getValue(node, "refclass", "") == "reference_spell" or DB.getValue(node, "refclass", "") == "power" then
		bMagicItem = true;
		sIcon = "spell";
	end

	if bMagicItem and (sIcon ~= "") then
		sIcon = "m" .. sIcon;
	end

	return sIcon;
end

function getCompatibilityType(node)
	local sNameLower =  StringManager.trim(DB.getValue(node, "name", "")):lower();
	local sTypeLower = StringManager.trim(DB.getValue(node, "type", "")):lower();
	local sSubTypeLower = StringManager.trim(DB.getValue(node, "subtype", "")):lower();

	if sTypeLower == "armor" then
		return "armor";
	elseif sTypeLower == "weapon" or ((sTypeLower == "adventuring gear") and (sSubTypeLower == "ammunition")) then
		return "weapon";
	elseif StringManager.contains({"rod", "staff", "wand"}, sTypeLower) or ((sTypeLower == "adventuring gear") and (sSubTypeLower == "arcane focus")) then
		return "arcane focus";
	elseif sTypeLower == "ring" then
		return "ring";
	elseif sTypeLower == "potion" or
				((sTypeLower == "adventuring gear") and
				(sNameLower:match("potion") or sNameLower:match("bottle") or sNameLower:match("flask") or
				sNameLower:match("vial") or sNameLower:match("oil"))) then
		return "potion";
	elseif sTypeLower == "scroll" or ((sTypeLower == "adventuring gear") and (sNameLower:match("scroll") or sNameLower:match("paper"))) then
		return "scroll";
	elseif sTypeLower == "spell" then
		return "spell"
	elseif sTypeLower == "wondrous item" then
		return "adventuring gear";
	elseif sTypeLower == "adventuring gear" then
		return "adventuring gear";
	end

	return "";
end
function isCompatible()
	local sCompatibilityType = nil;

	-- Check to make sure _tTemplates are all the same type
	for _,v in ipairs(_tTemplates) do
		local sTemplateCompatibilityType = ForgeManagerItem.getCompatibilityType(v);
		if sTemplateCompatibilityType == "spell" then
			-- Allow compatibility if the template type is "spell"
		elseif sCompatibilityType then
			if (sCompatibilityType ~= sTemplateCompatibilityType) then
				return false;
			end
		else
			sCompatibilityType = sTemplateCompatibilityType;
		end
	end
	if not sCompatibilityType then
		return false;
	end

	-- Check to make sure items are compatible type to the templates
	for _,v in ipairs(_tItems) do
		if sCompatibilityType ~= ForgeManagerItem.getCompatibilityType(v) then
			return false;
		end
	end

	return true;
end

function createMagicItem()
	if (#_tTemplates == 0) or ((#_tItems == 0) and (#_tTemplates < 2)) then
		return;
	end

	-- Make sure we have at least one base item, or make the first template into a base item
	local bAllTemplates = false;
	if #_tItems == 0 then
		bAllTemplates = true;
		table.insert(_tItems, _tTemplates[1]);
		table.remove(_tTemplates, 1);
	end

	-- Cycle through each base item to apply templates
	for _,v in ipairs(_tItems) do
		local rMagicItem = ForgeManagerItem.getItemStats(v);
		if bAllTemplates then
			rMagicItem.isTemplate = true;
		end

		if StringManager.contains({"armor", "weapon", "rod", "staff", "wand", "spell"}, rMagicItem.sType:lower()) then
			rMagicItem.sName = rMagicItem.sName:gsub("%,?%s%+%d+$", "");
		end

		for _,v2 in ipairs(_tTemplates) do
			local rTemplate = ForgeManagerItem.getItemStats(v2);

			local sTemplateNameLower = rTemplate.sName:lower();
			local sTemplateTypeLower = rTemplate.sType:lower();

			if StringManager.contains({"armor", "weapon", "rod", "staff", "wand", "spell"}, sTemplateTypeLower) then
				rTemplate.sName = rTemplate.sName:gsub("%,?%s%+%d+$", "");
			end

			-- Inherit from template when fields empty
			if rMagicItem.sType == "" then
				rMagicItem.sType = rTemplate.sType;
			end
			if rMagicItem.sSubType == "" then
				rMagicItem.sSubType = rTemplate.sSubType;
			end
			if StringManager.contains({"weapon", "armor"}, sTemplateTypeLower) then
				if sTemplateTypeLower == "weapon" then
					if (rMagicItem.sDamage or "") == "" then
						rMagicItem.sDamage = rTemplate.sDamage;
					end
				end
				if sTemplateTypeLower == "armor" then
					rMagicItem.nAC = math.max(rMagicItem.nAC or 0, rTemplate.nAC or 0);
					if (rMagicItem.sDexBonus or "") == "" then
						rMagicItem.sDexBonus = rTemplate.sDexBonus;
					end
					if (rMagicItem.sStealth or "") == "" then
						rMagicItem.sStealth = rTemplate.sStealth;
					end
				end

				local aProperties = {};
				if rMagicItem.sProperties and rMagicItem.sProperties ~= "" then
					table.insert(aProperties, rMagicItem.sProperties);
				end
				if rTemplate.sProperties and rTemplate.sProperties ~= "" then
					table.insert(aProperties, rTemplate.sProperties);
				end
				table.insert(aProperties, "magic");
				rMagicItem.sProperties = table.concat(aProperties, ", ");
			end

			-- Rarity Adjustment
			if ForgeManagerItem.getItemRarityValue(rMagicItem.sRarity) < ForgeManagerItem.getItemRarityValue(rTemplate.sRarity) then
				rMagicItem.sRarity = rTemplate.sRarity;
			end

			-- Bonus Adjustment
			if StringManager.contains({"armor", "weapon", "rod", "staff", "wand"}, rMagicItem.sType:lower()) then
				rMagicItem.nBonus = (rMagicItem.nBonus or 0) + (rTemplate.nBonus or 0);
			end

			-- Name Adjustment
			if rMagicItem.sName == "" then
				rMagicItem.sName = rTemplate.sName;
			else
				-- Calculate new name
				local sNewName = nil;
				if sTemplateTypeLower == "weapon" then
					if sTemplateNameLower:match("weapon") then
						sNewName = rTemplate.sName:gsub("[wW]eapon", rMagicItem.sName, 1);
					elseif sTemplateNameLower:match("ammunition") then
						sNewName = rTemplate.sName:gsub("[aA]mmunition", rMagicItem.sName, 1);
					elseif sTemplateNameLower:match("arrow") then
						sNewName = rTemplate.sName:gsub("[aA]rrow", rMagicItem.sName, 1);
					elseif sTemplateNameLower:match("axe") then
						sNewName = rTemplate.sName:gsub("[aA]xe", rMagicItem.sName, 1);
					elseif sTemplateNameLower:match("dagger") then
						sNewName = rTemplate.sName:gsub("[dD]agger", rMagicItem.sName, 1);
					elseif sTemplateNameLower:match("hammer") then
						sNewName = rTemplate.sName:gsub("[hH]ammer", rMagicItem.sName, 1);
					elseif sTemplateNameLower:match("javelin") then
						sNewName = rTemplate.sName:gsub("[jJ]avelin", rMagicItem.sName, 1);
					elseif sTemplateNameLower:match("mace") then
						sNewName = rTemplate.sName:gsub("[mM]ace", rMagicItem.sName, 1);
					elseif sTemplateNameLower:match("scimitar") then
						sNewName = rTemplate.sName:gsub("[sS]cimitar", rMagicItem.sName, 1);
					elseif sTemplateNameLower:match("sword") then
						sNewName = rTemplate.sName:gsub("[sS]word", rMagicItem.sName, 1);
					elseif sTemplateNameLower:match("trident") then
						sNewName = rTemplate.sName:gsub("[tT]rident", rMagicItem.sName, 1);
					end
				elseif sTemplateTypeLower == "armor" then
					if sTemplateNameLower:match("armor") then
						if rMagicItem.sName:lower():match("armor") then
							sNewName = rTemplate.sName:gsub("[aA]rmor", rMagicItem.sName, 1);
						elseif rMagicItem.sName:lower():match("shield") then
							sNewName = rTemplate.sName:gsub("[aA]rmor", rMagicItem.sName, 1);
						else
							if rMagicItem.sSubType:lower() == "shield" then
								sNewName = rTemplate.sName:gsub("[aA]rmor", rMagicItem.sName .. " Shield", 1);
							else
								sNewName = rTemplate.sName:gsub("[aA]rmor", rMagicItem.sName .. " Armor", 1);
							end
						end
					elseif sTemplateNameLower:match("shield") then
						if rMagicItem.sName:lower():match("armor") then
							sNewName = rTemplate.sName:gsub("[sS]hield", rMagicItem.sName, 1);
						elseif rMagicItem.sName:lower():match("shield") then
							sNewName = rTemplate.sName:gsub("[sS]hield", rMagicItem.sName, 1);
						else
							if rMagicItem.sSubType:lower() == "shield" then
								sNewName = rTemplate.sName:gsub("[sS]hield", rMagicItem.sName .. " Shield", 1);
							else
								sNewName = rTemplate.sName:gsub("[sS]hield", rMagicItem.sName .. " Armor", 1);
							end
						end
					end
				elseif sTemplateTypeLower == "potion" then
					if sTemplateNameLower:match("elixir") then
						sNewName = rTemplate.sName:gsub("[eE]lixir", rMagicItem.sName, 1);
					elseif sTemplateNameLower:match("oil") then
						sNewName = rTemplate.sName:gsub("[oO]il", rMagicItem.sName, 1);
					elseif sTemplateNameLower:match("philter") then
						sNewName = rTemplate.sName:gsub("[pP]hilter", rMagicItem.sName, 1);
					elseif sTemplateNameLower:match("potion") then
						sNewName = rTemplate.sName:gsub("[pP]otion", rMagicItem.sName, 1);
					end
				elseif sTemplateTypeLower == "ring" then
					if sTemplateNameLower:match("ring") then
						sNewName = rTemplate.sName:gsub("[rR]ing", rMagicItem.sName, 1);
					end
				elseif StringManager.contains({"rod", "staff", "wand"}, sTemplateTypeLower) then
					if sTemplateNameLower:match("rod") then
						sNewName = rTemplate.sName:gsub("[rR]od", rMagicItem.sName, 1);
					elseif sTemplateNameLower:match("staff") then
						sNewName = rTemplate.sName:gsub("[sS]taff", rMagicItem.sName, 1);
					elseif sTemplateNameLower:match("wand") then
						sNewName = rTemplate.sName:gsub("[wW]and", rMagicItem.sName, 1);
					end
				elseif sTemplateTypeLower == "scroll" or sTemplateTypeLower == "spell" then
					if sTemplateNameLower:match("scroll") then
						sNewName = rTemplate.sName:gsub("[sS]croll", rMagicItem.sName, 1);
					elseif sTemplateNameLower:match("spell") then
						sNewName = "Scroll of " .. rMagicItem.sName;
					end
				elseif sTemplateTypeLower == "wondrous item" then
					local nStartOf = rTemplate.sName:find(" [oO]f ");
					if nStartOf then
						sNewName = rMagicItem.sName .. rTemplate.sName:sub(nStartOf);
					end
				end
				if sNewName then
					rMagicItem.sName = sNewName;

					local _,nEndOf = rMagicItem.sName:find(" [oO]f ");
					if nEndOf then
						rMagicItem.sName = rMagicItem.sName:sub(1, nEndOf) .. rMagicItem.sName:sub(nEndOf + 1):gsub(" [oO]f ", " and ");
					end
				else
					if not rMagicItem.sName:match(rTemplate.sName) then
						if rTemplate.sName:match(rMagicItem.sName) then
							rMagicItem.sName = rTemplate.sName;
						else
							rMagicItem.sName = rMagicItem.sName .. " [" .. rTemplate.sName .. "]";
						end
					end
				end

				local aParens = {};
				for sParens in rMagicItem.sName:gmatch(" (%[[^%]]+%])") do
					table.insert(aParens, sParens);
				end
				if #aParens > 0 then
					rMagicItem.sName = rMagicItem.sName:gsub(" %[[^%]]+%]", "") .. " " .. table.concat(aParens, " ");
				end
			end

			-- Description Adjustment
			if rMagicItem.sDescription == "" then
				rMagicItem.sDescription = rTemplate.sDescription;
			else
				if sTemplateTypeLower == "scroll" then
					if rTemplate.sSpells ~= "" then
						local aSpells = StringManager.split(rTemplate.sSpells, ";", true);
						for _,sSpellEntry in pairs(aSpells) do
							local sSpellName, sSpellRecord = sSpellEntry:match("(.*),(.*)");
							local sSpellLink = [[<link class="reference_spell" recordname="]] .. sSpellRecord .. [[">Spell: ]] .. sSpellName .. [[</link>]];
							rMagicItem.sDescription = rMagicItem.sDescription:gsub("<h>Description</h>", "<h>Description</h>" .. sSpellLink);
						end
					end
				else
					rMagicItem.sDescription = rMagicItem.sDescription .. "<p><b>" .. rTemplate.sName .. " Notes</b></p>" .. rTemplate.sDescription:gsub("%<h%>Description%<%/h%>", "");
				end
			end

			-- Cost Adjustment
			ForgeManagerItem.combineCosts(rMagicItem, rTemplate)
		end

		if StringManager.contains({"armor", "weapon", "rod", "staff", "wand"}, rMagicItem.sType:lower()) then
			if rMagicItem.nBonus and rMagicItem.nBonus ~= 0 then
				rMagicItem.sName = rMagicItem.sName .. ", +" .. rMagicItem.nBonus;
			end
		end

		-- Now that we've built the item, add it to the campaign
		ForgeManagerItem.addMagicItemToCampaign(rMagicItem);
	end
end

function getItemDescBonus(sDesc)
	local sDescLower = (sDesc or ""):lower();

	local sBonus = sDescLower:match("%+(%d+)%sbonus%sto%sattack");
	if not sBonus then
		sBonus = sDescLower:match("%+(%d+)%sbonus%sto%sthe%sattack");
	end
	if not sBonus then
		sBonus = sDescLower:match("%+(%d+)%sbonus%sto%sac");
	end

	return tonumber(sBonus) or 0;
end

function getItemRarityValue(sRarity)
	local sRarityLower = (sRarity or ""):lower();

	local nResult = RARITY_UNKNOWN;
	if sRarityLower:match("legendary") then
		nResult = RARITY_LEGENDARY;
	elseif sRarityLower:match("very rare") then
		nResult = RARITY_VERY_RARE;
	elseif sRarityLower:match("rare") then
		nResult = RARITY_RARE;
	elseif sRarityLower:match("uncommon") then
		nResult = RARITY_UNCOMMON;
	elseif sRarityLower:match("common") then
		nResult = RARITY_COMMON;
	end

	return nResult;
end

-- rItemRecord
-- 		sName
--		sType
--		sSubType
-- 		sCost;
--		sDescription;
--		nWeight;
--		nAC
-- 		sDexBonus
-- 		sStrength
-- 		sStealth
-- 		sDamage
-- 		sProperties
--		sRarity
--		sSpells;

function getItemStats(node)
	local rItemRecord = {};

	rItemRecord.sName = StringManager.trim(DB.getValue(node, "name", ""));
	rItemRecord.sVersion = DB.getValue(node, "version", "");
	rItemRecord.sPicture = DB.getValue(node, "picture", "");
	rItemRecord.sType = StringManager.trim(DB.getValue(node, "type", ""));
	rItemRecord.sSubType = StringManager.trim(DB.getValue(node, "subtype", ""));
	rItemRecord.sCost = DB.getValue(node, "cost", "");
	rItemRecord.sDescription = DB.getValue(node, "description", "");
	rItemRecord.nWeight = DB.getValue(node, "weight", 0);
	rItemRecord.sRarity = DB.getValue(node, "rarity", "");

	local aSpells = {};
	for _,v in ipairs(DB.getChildList(node, "spells")) do
		local _, sRecord = DB.getValue(v, "link", "", "");
		table.insert(aSpells, DB.getValue(v, "name", "") .. "," .. sRecord);
	end
	if #aSpells > 0 then
		rItemRecord.sSpells = table.concat(aSpells, ";");
	end

	local sTypeLower = StringManager.trim(rItemRecord.sType:lower());
	if sTypeLower == "armor" then
		rItemRecord.nBonus = DB.getValue(node, "bonus", 0);
		rItemRecord.nAC = DB.getValue(node, "ac", 0);
		rItemRecord.sDexBonus = DB.getValue(node, "dexbonus", "");
		rItemRecord.sStrength = DB.getValue(node, "strength", "");
		rItemRecord.sStealth = DB.getValue(node, "stealth", "");
	elseif sTypeLower == "weapon" then
		rItemRecord.nBonus = DB.getValue(node, "bonus", 0);
		rItemRecord.sDamage = DB.getValue(node, "damage", "");
		rItemRecord.sProperties = DB.getValue(node, "properties", "");
		rItemRecord.sMastery = DB.getValue(node, "mastery", "");
	elseif StringManager.contains({"rod", "staff", "wand"}, sTypeLower) then
		rItemRecord.nBonus = DB.getValue(node, "bonus", 0);
	end

	-- Calculate the template bonus from the name and description, and check whether it matches bonus field
	if StringManager.contains({"armor", "weapon", "rod", "staff", "wand"}, sTypeLower) then
		if rItemRecord.nBonus == 0 then
			local nTemplateNameBonus = tonumber(rItemRecord.sName:match("%,?%s%+(%d+)$")) or 0;
			if nTemplateNameBonus ~= 0 then
				rItemRecord.nBonus = nTemplateNameBonus;
			else
				rItemRecord.nBonus = ForgeManagerItem.getItemDescBonus(rItemRecord.sDescription);
			end
		end
	end

	return rItemRecord;
end

function getMagicItemValue(sCost, sRarity)
	if sRarity == "" then
		return sCost .. " gp";
	end

	local nValue = 0;

	local nRarity = ForgeManagerItem.getItemRarityValue(sRarity);
	if nRarity == RARITY_LEGENDARY then
		nValue = math.random(50001, 100000);
	elseif nRarity == RARITY_VERY_RARE then
		nValue = math.random(5001, 50000);
	elseif nRarity == RARITY_RARE then
		nValue = math.random(501, 5000);
	elseif nRarity == RARITY_UNCOMMON then
		nValue = math.random(101, 500);
	elseif nRarity == RARITY_COMMON then
		nValue = math.random(50, 100);
	end

	nValue = nValue + (tonumber(sCost) or 0);

	local k;
	local sValue = tostring(nValue);
	while true do
		sValue, k = sValue:gsub("^(%d+)(%d%d%d)", '%1,%2')
		if (k == 0) then
			break;
		end
	end
	return sValue .. " gp";
end

function parseCost(sCost)
	sCost = sCost:lower():gsub(",", ""); -- normalize case and remove commas

	-- Check for range values and take the average if present
	local low, high, unit = sCost:match("(%d+)%s*-%s*(%d+)%s*([c|s|e|g|p]p)");
	if low and high and unit then
		return (tonumber(low) + tonumber(high)) / 2, unit;
	end

	-- Parse single cost
	local value, unit = sCost:match("(%d+)%s*([c|s|e|g|p]p)");
	return tonumber(value), unit or "gp"; -- default to gp if no unit is found
end

function convertToCP(value, unit)
	return value * (CURRENCY_VALUES[unit] or 100);
end

function formatWithCommas(amount)
	local k;
	local formatted = tostring(amount);
	while true do
		formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", '%1,%2');
		if k == 0 then
			break;
		end
	end
	return formatted;
end

function convertFromCP(cpTotal)
	-- Ensure cpTotal is a valid number before conversion
	if not cpTotal or cpTotal <= 0 then
		return "0 cp";
	end

	-- Convert to the highest possible denomination without remainder
	for unit, factor in pairs({ pp = 1000, gp = 100, ep = 50, sp = 10, cp = 1 }) do
		if cpTotal % factor == 0 then
			local finalValue = cpTotal / factor;
			return ForgeManagerItem.formatWithCommas(finalValue) .. " " .. unit;
		end
	end
	-- Default return for any remainder case
	return ForgeManagerItem.formatWithCommas(cpTotal) .. " cp";
end

function combineCosts(rMagicItem, rTemplate)
	local magicValue, magicUnit = ForgeManagerItem.parseCost(rMagicItem.sCost);
	local templateValue, templateUnit = ForgeManagerItem.parseCost(rTemplate.sCost);

	if magicValue and templateValue then
		-- Both values are defined, so convert to CP and add
		local totalCP = ForgeManagerItem.convertToCP(magicValue, magicUnit) + ForgeManagerItem.convertToCP(templateValue, templateUnit);
		rMagicItem.sCost = ForgeManagerItem.convertFromCP(totalCP);
	elseif templateValue then
		-- Only template cost exists
		rMagicItem.sCost = rTemplate.sCost;
	else
		-- If neither has a valid cost, set to "0 gp"
		rMagicItem.sCost = "0 gp";
	end
end

function addMagicItemToCampaign(rMagicItem)
	local nodeTarget;
	if rMagicItem.isTemplate then
		nodeTarget = DB.createChild("itemtemplate");
	else
		nodeTarget = DB.createChild("item");
	end

	DB.setValue(nodeTarget, "locked", "number", 1);
	DB.setValue(nodeTarget, "name", "string", rMagicItem.sName);
	DB.setValue(nodeTarget, "version", "string", rMagicItem.sVersion);
	DB.setValue(nodeTarget, "picture", "token", rMagicItem.sPicture);
	DB.setValue(nodeTarget, "type", "string", rMagicItem.sType);
	DB.setValue(nodeTarget, "subtype", "string", rMagicItem.sSubType);
	DB.setValue(nodeTarget, "rarity", "string", rMagicItem.sRarity);
	DB.setValue(nodeTarget, "weight", "number", rMagicItem.nWeight);
	DB.setValue(nodeTarget, "cost", "string", rMagicItem.sCost);
	DB.setValue(nodeTarget, "description", "formattedtext", rMagicItem.sDescription);

	local sTypeLower = rMagicItem.sType:lower();
	if sTypeLower == "armor" then
		DB.setValue(nodeTarget, "bonus", "number", rMagicItem.nBonus);
		DB.setValue(nodeTarget, "ac", "number", rMagicItem.nAC);
		DB.setValue(nodeTarget, "dexbonus", "string", rMagicItem.sDexBonus);
		DB.setValue(nodeTarget, "stealth", "string", rMagicItem.sStealth);
		DB.setValue(nodeTarget, "strength", "string", rMagicItem.sStrength);
	elseif sTypeLower == "weapon" then
		DB.setValue(nodeTarget, "bonus", "number", rMagicItem.nBonus);
		DB.setValue(nodeTarget, "damage", "string", rMagicItem.sDamage);
		DB.setValue(nodeTarget, "properties", "string", rMagicItem.sProperties);
		DB.setValue(nodeTarget, "mastery", "string", rMagicItem.sMastery);
	end

	if rMagicItem.isTemplate then
		Interface.openWindow("itemtemplate", nodeTarget);
	else
		Interface.openWindow("item", nodeTarget);
	end
end
