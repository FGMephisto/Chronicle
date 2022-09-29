-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System.
--

-- ===================================================================================================================
-- ===================================================================================================================
function onInit()
	ItemManager.setCustomCharAdd(onCharItemAdd);
	ItemManager.setCustomCharRemove(onCharItemDelete);
end

-- ===================================================================================================================
-- ===================================================================================================================
function outputUserMessage(sResource, ...)
	local sFormat = Interface.getString(sResource);
	local sMsg = string.format(sFormat, ...);
	ChatManager.SystemMessage(sMsg);
end

-- ===================================================================================================================
-- ITEM/FOCUS MANAGEMENT
-- ===================================================================================================================
function onCharItemAdd(nodeItem)
	-- Debug.chat("FN: onCharItemAdd in manager_char")
	local sTypeLower = StringManager.trim(DB.getValue(DB.getPath(nodeItem, "type"), "")):lower();

	if StringManager.contains({"mounts and other animals", "waterborne vehicles", "tack, harness, and drawn vehicles" }, sTypeLower) then
		DB.setValue(nodeItem, "carried", "number", 0);
	else
		DB.setValue(nodeItem, "carried", "number", 1);
	end
	
	CharArmorManager.addToArmorDB(nodeItem);
	CharWeaponManager.addToWeaponDB(nodeItem);
end

-- ===================================================================================================================
-- ===================================================================================================================
function onCharItemDelete(nodeItem)
	-- Debug.chat("FN: onCharItemDelete in manager_char")
	CharArmorManager.removeFromArmorDB(nodeItem);
	CharWeaponManager.removeFromWeaponDB(nodeItem);
end

-- ===================================================================================================================
-- ===================================================================================================================
function updateEncumbrance(nodeChar)
	Debug.console("CharManager.updateEncumbrance - DEPRECATED - 2022-02-01 - Use CharEncumbranceManager.updateEncumbrance");
	ChatManager.SystemMessage("CharManager.updateEncumbrance - DEPRECATED - 2022-02-01 - Contact forge/extension author");
	CharEncumbranceManager.updateEncumbrance(nodeChar);
end

-- ===================================================================================================================
-- ACTIONS
-- ===================================================================================================================
function rest(nodeChar, bLong)
	-- Debug.chat("FN: rest in manager_char")
	CharManager.resetHealth(nodeChar, bLong);
end

-- ===================================================================================================================
-- ===================================================================================================================
function resetHealth(nodeChar, bLong)
	-- Debug.chat("FN: resetHealth in manager_char")
	-- Reset damage
	DB.setValue(nodeChar, "hp.wounds", "number", 0)
end

-- ===================================================================================================================
-- CHARACTER SHEET DROPS
-- ===================================================================================================================
function addInfoDB(nodeChar, sClass, sRecord)
	-- Debug.chat("FN: addInfoDB in manager_char")
	-- Validate parameters
	if not nodeChar then
		return false;
	end
	
	if sClass == "reference_feat" then
		CharFeatManager.addFeat(nodeChar, sClass, sRecord);
	elseif sClass == "reference_skill" then
		CharManager.addSkill(nodeChar, sClass, sRecord);
	elseif sClass == "ref_adventure" then
		CharManager.addAdventure(nodeChar, sClass, sRecord);
	else
		return false;
	end
	
	return true;
end

-- ===================================================================================================================
-- ToDo: Obsolete?
-- ===================================================================================================================
function getFullAbilitySelectList()
	-- Debug.chat("FN: getFullAbilitySelectList in manager_char")
	local aAbilities = {};
	for _,v in ipairs(DataCommon.abilities) do
		table.insert(aAbilities, StringManager.capitalize(v));
	end
	return aAbilities;
end

-- ===================================================================================================================
-- ToDo: Obsolete?
-- ===================================================================================================================
function onAbilitySelectDialog(nodeChar, tAbilitySelect)
	-- Debug.chat("FN: onAbilitySelectDialog in manager_char")
	if #tAbilitySelect == 0 then
		return;
	end

	-- Check for empty or missing ability list, then use full list
	if not tAbilitySelect[1].aAbilities or (#(tAbilitySelect[1].aAbilities) == 0) then 
		tAbilitySelect[1].aAbilities = CharManager.getFullAbilitySelectList(); 
	end
	local nPicks = tAbilitySelect[1].nPicks or 1;
	local nAbilityAdj = tAbilitySelect[1].nAbilityAdj or 1;

	local rAbilitySelectMeta = { nodeChar = nodeChar, tAbilitySelect = tAbilitySelect };
	local wSelect = Interface.openWindow("select_dialog", "");
	local sTitle = Interface.getString("char_build_title_selectabilityincrease");
	local sMessage;
	if nPicks == 1 then
		sMessage = string.format(Interface.getString("char_build_message_selectabilityincrease1"), nAbilityAdj);
	else
		sMessage = string.format(Interface.getString("char_build_message_selectabilityincrease"), nPicks, nAbilityAdj);
	end
	wSelect.requestSelection(sTitle, sMessage, tAbilitySelect[1].aAbilities, onAbilitySelectComplete, rAbilitySelectMeta, nPicks, nil, true);
end

-- ===================================================================================================================
-- ToDo: Obsolete?
-- ===================================================================================================================
function onAbilitySelectComplete(aSelection, rAbilitySelectMeta)
	-- Debug.chat("FN: onAbilitySelectComplete in manager_char")
	local rAbilitySelect = rAbilitySelectMeta.tAbilitySelect[1];
	for _,sAbility in ipairs(aSelection) do
		CharManager.addAbilityAdjustment(rAbilitySelectMeta.nodeChar, sAbility, rAbilitySelect.nAbilityAdj or 1, rAbilitySelect.nAbilityMax);
		
		if rAbilitySelect.bSaveProfAdd then
			local sAbilityLower = StringManager.trim(sAbility):lower();
			if StringManager.contains(DataCommon.abilities, sAbilityLower) then
				DB.setValue(rAbilitySelectMeta.nodeChar, "abilities." .. sAbilityLower .. ".saveprof", "number", 1);
				CharManager.outputUserMessage("char_abilities_message_saveadd", sAbility, DB.getValue(rAbilitySelectMeta.nodeChar, "name", ""));
			end
		end
	end

	table.remove(rAbilitySelectMeta.tAbilitySelect, 1);
	if #(rAbilitySelectMeta.tAbilitySelect) > 0 then
		for _,vSelect in ipairs(rAbilitySelectMeta.tAbilitySelect) do
			if vSelect.bOther then
				if not vSelect.aAbilities or (#vSelect.aAbilities == 0) then 
					tAbilitySelect[1].aAbilities = CharManager.getFullAbilitySelectList(); 
				end
				local aNewAbilities = {};
				for _,vAbility in ipairs(vSelect.aAbilities) do
					if not StringManager.contains(aSelection, vAbility) then
						table.insert(aNewAbilities, vAbility);
					end
				end
				vSelect.aAbilities = aNewAbilities;
			end
		end
		CharManager.onAbilitySelectDialog(rAbilitySelectMeta.nodeChar, rAbilitySelectMeta.tAbilitySelect);
	end
end

-- ===================================================================================================================
-- ToDo: Obsolete?
-- ===================================================================================================================
function addAbilityAdjustment(nodeChar, sAbility, nAdj, nAbilityMax)
	local k = StringManager.trim(sAbility):lower();
	if StringManager.contains(DataCommon.abilities, k) then
		local sPath = "abilities." .. k .. ".score";
		local nCurrent = DB.getValue(nodeChar, sPath, 10);
		local nNewScore = nCurrent + nAdj;
		if nAbilityMax then
			nNewScore = math.max(math.min(nNewScore, nAbilityMax), nCurrent);
		end
		if nNewScore ~= nCurrent then
			DB.setValue(nodeChar, sPath, "number", nNewScore);
			CharManager.outputUserMessage("char_abilities_message_abilityadd", StringManager.capitalize(k), nNewScore - nCurrent, DB.getValue(nodeChar, "name", ""));
		end
	end
end

-- ===================================================================================================================
-- ToDo: Obsolete?
-- ===================================================================================================================
function onSkillSelect(aSelection, rSkillAdd)
	-- For each selected skill, add it to the character
	for _,sSkill in ipairs(aSelection) do
		CharManager.helperAddSkill(rSkillAdd.nodeChar, sSkill, rSkillAdd.nProf or 1);
	end
end

-- ===================================================================================================================
-- ToDo: Obsolete?
-- ===================================================================================================================
function addProficiency(nodeChar, sType, sText)
	-- Get the list we are going to add to
	local nodeList = nodeChar.createChild("proficiencylist");
	if not nodeList then
		return nil;
	end

	-- If proficiency is not none, then add it to the list
	if sText == "None" then
		return nil;
	end
	
	-- Make sure this item does not already exist
	for _,vProf in pairs(nodeList.getChildren()) do
		if DB.getValue(vProf, "name", "") == sText then
			return vProf;
		end
	end
	
	local nodeEntry = nodeList.createChild();
	local sValue;
	if sType == "armor" then
		sValue = Interface.getString("char_label_addprof_armor");
	elseif sType == "weapons" then
		sValue = Interface.getString("char_label_addprof_weapon");
	else
		sValue = Interface.getString("char_label_addprof_tool");
	end
	sValue = sValue .. ": " .. sText;
	DB.setValue(nodeEntry, "name", "string", sValue);

	-- Announce
	CharManager.outputUserMessage("char_abilities_message_profadd", DB.getValue(nodeEntry, "name", ""), DB.getValue(nodeChar, "name", ""));
	return nodeEntry;
end

-- ===================================================================================================================
-- ToDo: Obsolete?
-- ===================================================================================================================
function helperAddSkill(nodeChar, sSkill, nProficient)
	-- Get the list we are going to add to
	local nodeList = nodeChar.createChild("skilllist");
	if not nodeList then
		return nil;
	end
	
	-- Make sure this item does not already exist
	local nodeSkill = nil;
	for _,vSkill in pairs(nodeList.getChildren()) do
		if DB.getValue(vSkill, "name", "") == sSkill then
			nodeSkill = vSkill;
			break;
		end
	end
		
	-- Add the item
	if not nodeSkill then
		nodeSkill = nodeList.createChild();
		DB.setValue(nodeSkill, "name", "string", sSkill);
		if DataCommon.skilldata[sSkill] then
			DB.setValue(nodeSkill, "stat", "string", DataCommon.skilldata[sSkill].stat);
		end
	end
	if nProficient then
		if nProficient and type(nProficient) ~= "number" then
			nProficient = 1;
		end
		DB.setValue(nodeSkill, "prof", "number", nProficient);
	end

	-- Announce
	CharManager.outputUserMessage("char_abilities_message_skilladd", DB.getValue(nodeSkill, "name", ""), DB.getValue(nodeChar, "name", ""));
	return nodeSkill;
end

-- ===================================================================================================================
-- ToDo: Obsolete?
-- ===================================================================================================================
function parseSkillProficiencyText(nodeSkillProf)
	if not nodeSkillProf then
		return 0, {};
	end
	local sText = DB.getValue(nodeSkillProf, "text", "");
	if (sText or "") == "" then
		return 0, {};
	end
	
	local tSkills = {};
	local sPicks;
	if sText:match("Choose any ") then
		sPicks = sText:match("Choose any (%w+)");
		
	elseif sText:match("Choose ") then
		sPicks = sText:match("Choose (%w+) ");
		
		sText = sText:gsub("Choose (%w+) from ", "");
		sText = sText:gsub("Choose (%w+) skills? from ", "");
		sText = sText:gsub("and ", "");
		sText = sText:gsub("or ", "");
		
		for sSkill in sText:gmatch("(%a[%a%s]+)%,?") do
			table.insert(tSkills, StringManager.trim(sSkill));
		end
	end
	
	local nPicks = CharManager.convertSingleNumberTextToNumber(sPicks);

	return nPicks, tSkills;
end

-- ===================================================================================================================
-- ToDo: Obsolete?
-- ===================================================================================================================
function parseSkillsFromString(sSkills)
	local aSkills = {};
	sSkills = sSkills:gsub("and ", "");
	sSkills = sSkills:gsub("or ", "");
	local nPeriod = sSkills:match("%.()");
	if nPeriod then
		sSkills = sSkills:sub(1, nPeriod);
	end
	for sSkill in string.gmatch(sSkills, "(%a[%a%s]+)%,?") do
		local sTrim = StringManager.trim(sSkill);
		table.insert(aSkills, sTrim);
	end
	return aSkills;
end

-- ===================================================================================================================
-- ToDo: Obsolete?
-- ===================================================================================================================
function pickSkills(nodeChar, aSkills, nPicks, nProf)
	-- Check for empty or missing skill list, then use full list
	if not aSkills then 
		aSkills = {}; 
	end
	if #aSkills == 0 then
		for k,_ in pairs(DataCommon.skilldata) do
			table.insert(aSkills, k);
		end
		table.sort(aSkills);
	end
		
	-- Add links (if we can find them)
	for k,v in ipairs(aSkills) do
		local rSkillData = DataCommon.skilldata[v];
		if rSkillData then
			local rSkill = { text = v, linkclass = "", linkrecord = "" };
			local nodeSkill = RecordManager.findRecordByStringI("skill", "name", v);
			if nodeSkill then
				rSkill.linkclass = "reference_skill";
				rSkill.linkrecord = DB.getPath(nodeSkill);
			end
			aSkills[k] = rSkill;
		end
	end
	
	-- Display dialog to choose skill selection
	local rSkillAdd = { nodeChar = nodeChar, nProf = nProf };
	local wSelect = Interface.openWindow("select_dialog", "");
	local sTitle = Interface.getString("char_build_title_selectskills");
	local sMessage = string.format(Interface.getString("char_build_message_selectskills"), nPicks);
	wSelect.requestSelection (sTitle, sMessage, aSkills, CharManager.onSkillSelect, rSkillAdd, nPicks);
end

-- ===================================================================================================================
-- ToDo: Obsolete?
-- ===================================================================================================================
function checkSkillProficiencies(nodeChar, sText)
	-- Tabaxi - Cat's Talent - Volo
	local sSkill, sSkill2 = sText:match("proficiency in the ([%w%s]+) and ([%w%s]+) skills");
	if sSkill and sSkill2 then
		CharManager.helperAddSkill(nodeChar, sSkill, 1);
		CharManager.helperAddSkill(nodeChar, sSkill2, 1);
		return true;
	end
	-- Elf - Keen Senses - PHB
	-- Half-Orc - Menacing - PHB
	-- Goliath - Natural Athlete - Volo
	local sSkill = sText:match("proficiency in the ([%w%s]+) skill");
	if sSkill then
		CharManager.helperAddSkill(nodeChar, sSkill, 1);
		return true;
	end
	-- Bugbear - Sneaky - Volo
	-- (FALSE POSITIVE) Dwarf - Stonecunning
	sSkill = sText:match("proficient in the ([%w%s]+) skill");
	if sSkill then
		CharManager.helperAddSkill(nodeChar, sSkill, 1);
		return true;
	end
	-- Orc - Menacing - Volo
	sSkill = sText:match("trained in the ([%w%s]+) skill");
	if sSkill then
		CharManager.helperAddSkill(nodeChar, sSkill, 1);
		return true;
	end

	-- Half-Elf - Skill Versatility - PHB
	-- Human (Variant) - Skills - PHB
	local sPicks = sText:match("proficiency in (%w+) skills? of your choice");
	if sPicks then
		local nPicks = CharManager.convertSingleNumberTextToNumber(sPicks);
		CharManager.pickSkills(nodeChar, nil, nPicks);
		return true;
	end
	-- Cleric - Acolyte of Nature - PHB
	local nMatchEnd = sText:match("proficiency in one of the following skills of your choice()")
	if nMatchEnd then
		CharManager.pickSkills(nodeChar, CharManager.parseSkillsFromString(sText:sub(nMatchEnd)), 1);
		return true;
	end
	-- Lizardfolk - Hunter's Lore - Volo
	sPicks, nMatchEnd = sText:match("proficiency with (%w+) of the following skills of your choice()")
	if sPicks then
		local nPicks = CharManager.convertSingleNumberTextToNumber(sPicks);
		CharManager.pickSkills(nodeChar, CharManager.parseSkillsFromString(sText:sub(nMatchEnd)), nPicks);
		return true;
	end
	-- Cleric - Blessings of Knowledge - PHB
	-- Kenku - Kenuku Training - Volo
	sPicks, nMatchEnd = sText:match("proficient in your choice of (%w+) of the following skills()")
	if sPicks then
		local nPicks = CharManager.convertSingleNumberTextToNumber(sPicks);
		local nProf = 1;
		if sText:match("proficiency bonus is doubled") then
			nProf = 2;
		end
		CharManager.pickSkills(nodeChar, CharManager.parseSkillsFromString(sText:sub(nMatchEnd)), nPicks, nProf);
		return true;
	end
	return false;
end

-- ===================================================================================================================
-- ToDo: Obsolete?
-- ===================================================================================================================
function addLanguage(nodeChar, sLanguage)
	-- Get the list we are going to add to
	local nodeList = nodeChar.createChild("languagelist");
	if not nodeList then
		return false;
	end
	
	-- Make sure this item does not already exist
	if sLanguage ~= "Choice" then
		for _,v in pairs(nodeList.getChildren()) do
			if DB.getValue(v, "name", "") == sLanguage then
				return false;
			end
		end
	end

	-- Add the item
	local vNew = nodeList.createChild();
	DB.setValue(vNew, "name", "string", sLanguage);

	-- Announce
	CharManager.outputUserMessage("char_abilities_message_languageadd", DB.getValue(vNew, "name", ""), DB.getValue(nodeChar, "name", ""));
	return true;
end

-- ===================================================================================================================
-- ToDo: Obsolete?
-- ===================================================================================================================
function addSkill(nodeChar, sClass, sRecord)
	local nodeSource = DB.findNode(sRecord);
	if not nodeSource then
		return;
	end
	
	-- Add skill entry
	local nodeSkill = CharManager.helperAddSkill(nodeChar, DB.getValue(nodeSource, "name", ""));
	if nodeSkill then
		DB.setValue(nodeSkill, "text", "formattedtext", DB.getValue(nodeSource, "text", ""));
	end
end

-- ===================================================================================================================
-- ToDo: Obsolete?
-- ===================================================================================================================
function addAdventure(nodeChar, sClass, sRecord)
	local nodeSource = DB.findNode(sRecord);
	if not nodeSource then
		return;
	end

	-- Get the list we are going to add to
	local nodeList = DB.createChild(nodeChar, "adventurelist");
	if not nodeList then
		return nil;
	end
	
	-- Copy the adventure record data
	local vNew = DB.createChild(nodeList);
	DB.copyNode(nodeSource, vNew);
	DB.setValue(vNew, "locked", "number", 1);
	
	-- Notify
	CharManager.outputUserMessage("char_logs_message_adventureadd", DB.getValue(nodeSource, "name", ""), DB.getValue(nodeChar, "name", ""));
end

-- ===================================================================================================================
-- ToDo: Obsolete?
-- ===================================================================================================================
function hasTrait(nodeChar, sTrait)
	return (CharManager.getTraitRecord(nodeChar, sTrait) ~= nil);
end

-- ===================================================================================================================
-- ToDo: Obsolete?
-- ===================================================================================================================
function getTraitRecord(nodeChar, sTrait)
	if (sTrait or "") == "" then
		return nil;
	end
	
	local sTraitLower = StringManager.trim(sTrait):lower();
	for _,v in pairs(DB.getChildren(nodeChar, "traitlist")) do
		local sMatch = StringManager.trim(DB.getValue(v, "name", "")):lower();
		if sMatch == sTraitLower then
			return v;
		end
	end
	return nil;
end

-- ===================================================================================================================
-- ToDo: Obsolete?
-- ===================================================================================================================
function hasFeature(nodeChar, sFeature)
	if (sFeature or "") == "" then
		return false;
	end

	local sFeatureLower = StringManager.trim(sFeature):lower();
	for _,v in pairs(DB.getChildren(nodeChar, "featurelist")) do
		local sMatch = StringManager.trim(DB.getValue(v, "name", "")):lower();
		if sMatch == sFeatureLower then
			return true;
		end
	end
	
	return false;
end

-- ===================================================================================================================
-- ToDo: Obsolete?
-- ===================================================================================================================
function hasFeat(nodeChar, sFeat)
	return (CharManager.getFeatRecord(nodeChar, sFeat) ~= nil);
end

-- ===================================================================================================================
-- ToDo: Obsolete?
-- ===================================================================================================================
function getFeatRecord(nodeChar, sFeat)
	if (sFeat or "") == "" then
		return nil;
	end
	
	local sFeatLower = StringManager.trim(sFeat:lower());
	for _,v in pairs(DB.getChildren(nodeChar, "featlist")) do
		local sMatch = StringManager.trim(DB.getValue(v, "name", "")):lower();
		if sMatch == sFeatLower then
			return v;
		end
	end
	return nil;
end

-- ===================================================================================================================
-- ToDo: Obsolete?
-- ===================================================================================================================
function convertSingleNumberTextToNumber(s)
	if s then
		if s == "one" then return 1; end
		if s == "two" then return 2; end
		if s == "three" then return 3; end
		if s == "four" then return 4; end
		if s == "five" then return 5; end
		if s == "six" then return 6; end
		if s == "seven" then return 7; end
		if s == "eight" then return 8; end
		if s == "nine" then return 9; end
	end
	return 0;
end

-- ===================================================================================================================
-- ToDo: Obsolete?
-- ===================================================================================================================
function helperBuildAddStructure(nodeChar, sClass, sRecord, bWizard)
	if not nodeChar or ((sClass or "") == "") or ((sRecord or "") == "") then
		return nil;
	end

	local rAdd = { };
	rAdd.nodeSource = DB.findNode(sRecord);
	if not rAdd.nodeSource then
		return nil;
	end

	rAdd.sSourceClass = sClass;
	rAdd.sSourceName = StringManager.trim(DB.getValue(rAdd.nodeSource, "name", ""));
	rAdd.nodeChar = nodeChar;
	rAdd.sCharName = StringManager.trim(DB.getValue(nodeChar, "name", ""));
	rAdd.bWizard = bWizard;

	rAdd.sSourceType = StringManager.simplify(rAdd.sSourceName);
	if rAdd.sSourceType == "" then
		rAdd.sSourceType = rAdd.nodeSource.getName();
	end

	return rAdd;
end

-- ===================================================================================================================
-- ToDo: Obsolete?
-- ===================================================================================================================
function helperCheckActionsAdd(nodeChar, nodeSource, sSanitizedName, sPowerGroup)
	if not nodeSource then
		return;
	end
	local tAction = CharWizardDataAction.parsedata[sSanitizedName];
	if not tAction then
		return;
	end

	if tAction["actions"] then
		local rActionsAdd = {
			nodeSource = nodeSource,
			nodeChar = nodeChar,
			sPowerGroup = sPowerGroup,
			tPowerActions = tAction["actions"],
			nPowerPrepared = tAction.prepared
		};
		CharManager.helperAddActions(rActionsAdd);
	elseif tAction["multiple_actions"] then
		local rActionsAdd = {
			nodeSource = nodeSource,
			nodeChar = nodeChar,
			sPowerGroup = sPowerGroup,
		};
		for k,v in pairs(tAction["multiple_actions"]) do
			if v["actions"] then
				rActionsAdd.sPowerName = k;
				rActionsAdd.tPowerActions = v["actions"];
				rActionsAdd.nPowerPrepared = v.prepared;
				CharManager.helperAddActions(rActionsAdd);
			end
		end
	end
end

-- ===================================================================================================================
-- ToDo: Obsolete?
-- ===================================================================================================================
function helperAddActions(rActionsAdd)
	local nodePowerList = DB.createChild(rActionsAdd.nodeChar, "powers");
	if not nodePowerList then
		return;
	end

	local nodeNewPower = DB.createChild(nodePowerList);
	if not nodeNewPower then
		return;
	end

	DB.copyNode(rActionsAdd.nodeSource, nodeNewPower);
	
	-- Set specific data
	DB.setValue(nodeNewPower, "locked", "number", 1);
	DB.setValue(nodeNewPower, "group", "string", rActionsAdd.sPowerGroup);
	if rActionsAdd.nPowerPrepared and (rActionsAdd.nPowerPrepared > 0) then
		DB.setValue(nodeNewPower, "prepared", "number", rActionsAdd.nPowerPrepared);
	end
	if rActionsAdd.sPowerName then
		DB.setValue(nodeNewPower, "name", "string", rActionsAdd.sPowerName);
	end

	-- Clean up
	DB.deleteChild(nodeNewPower, "level");
	local nodeActions = DB.createChild(nodeNewPower, "actions");
	for _,v in pairs(DB.getChildren(nodeActions)) do
		v.delete();
	end

	-- Convert text to description
	local nodeText = DB.getChild(nodeNewPower, "text");
	if nodeText then
		local nodeDesc = DB.createChild(nodeNewPower, "description", "formattedtext");
		DB.copyNode(nodeText, nodeDesc);
		nodeText.delete();
	end

	-- See if we have specific actions to add
	if not rActionsAdd.tPowerActions then
		return;
	end

	local nodeCastAction = nil;
	for _,vAction in pairs(rActionsAdd.tPowerActions) do
		if vAction.type then
			if vAction.type == "attack" then
				if not nodeCastAction then
					nodeCastAction = DB.createChild(nodeActions);
					DB.setValue(nodeCastAction, "type", "string", "cast");
				end
				if nodeCastAction then
					if vAction.range == "R" then
						DB.setValue(nodeCastAction, "atktype", "string", "ranged");
					else
						DB.setValue(nodeCastAction, "atktype", "string", "melee");
					end

					if vAction.modifier then
						DB.setValue(nodeCastAction, "atkbase", "string", "fixed");
						DB.setValue(nodeCastAction, "atkmod", "number", tonumber(vAction.modifier) or 0);
					end
				end

			elseif vAction.type == "damage" then
				local nodeAction = DB.createChild(nodeActions);
				DB.setValue(nodeAction, "type", "string", "damage");

				local nodeDmgList = DB.createChild(nodeAction, "damagelist");
				for _,vDamage in ipairs(vAction.clauses) do
					local nodeEntry = DB.createChild(nodeDmgList);

					DB.setValue(nodeEntry, "dice", "dice", vDamage.dice);
					DB.setValue(nodeEntry, "bonus", "number", vDamage.bonus);
					if vDamage.stat then
						DB.setValue(nodeEntry, "stat", "string", vDamage.stat);
					end
					if vDamage.statmult then
						DB.setValue(nodeEntry, "statmult", "number", vDamage.statmult);
					end
					DB.setValue(nodeEntry, "type", "string", vDamage.dmgtype);
				end

			elseif vAction.type == "heal" then
				local nodeAction = DB.createChild(nodeActions);
				DB.setValue(nodeAction, "type", "string", "heal");

				if vAction.subtype == "temp" then
					DB.setValue(nodeAction, "healtype", "string", "temp");
				end
				if vAction.sTargeting then
					DB.setValue(nodeAction, "healtargeting", "string", vAction.sTargeting);
				end

				local nodeHealList = DB.createChild(nodeAction, "heallist");
				for _,vHeal in ipairs(vAction.clauses) do
					local nodeEntry = DB.createChild(nodeHealList);

					DB.setValue(nodeEntry, "dice", "dice", vHeal.dice);
					DB.setValue(nodeEntry, "bonus", "number", vHeal.bonus);
					if vHeal.stat then
						DB.setValue(nodeEntry, "stat", "string", vHeal.stat);
					end
					if vHeal.statmult then
						DB.setValue(nodeEntry, "statmult", "number", vHeal.statmult);
					end
				end

			elseif vAction.type == "powersave" then
				if not nodeCastAction then
					nodeCastAction = DB.createChild(nodeActions);
					DB.setValue(nodeCastAction, "type", "string", "cast");
				end
				if nodeCastAction then
					DB.setValue(nodeCastAction, "savetype", "string", vAction.save);
					DB.setValue(nodeCastAction, "savemagic", "number", 1);

					if vAction.savemod then
						DB.setValue(nodeCastAction, "savedcbase", "string", "fixed");
						DB.setValue(nodeCastAction, "savedcmod", "number", tonumber(vAction.savemod) or 8);
					elseif vAction.savestat then
						if vAction.savestat ~= "base" then
							DB.setValue(nodeCastAction, "savedcbase", "string", "ability");
							DB.setValue(nodeCastAction, "savedcstat", "string", vAction.savestat);
						end
					end
					if vAction.onmissdamage == "half" then
						DB.setValue(nodeCastAction, "onmissdamage", "string", "half");
					end
				end

			elseif vAction.type == "effect" then
				local nodeAction = DB.createChild(nodeActions);
				DB.setValue(nodeAction, "type", "string", "effect");

				DB.setValue(nodeAction, "label", "string", vAction.sName);

				if vAction.sTargeting then
					DB.setValue(nodeAction, "targeting", "string", vAction.sTargeting);
				end
				if vAction.sApply then
					DB.setValue(nodeAction, "apply", "string", vAction.sApply);
				end

				local nDuration = tonumber(vAction.nDuration) or 0;
				if nDuration ~= 0 then
					DB.setValue(nodeAction, "durmod", "number", nDuration);
					DB.setValue(nodeAction, "durunit", "string", vAction.sUnits);
				end
			end
		end
	end
end

-- ===================================================================================================================
-- ToDo: Obsolete?
-- ===================================================================================================================
function helperParseAbilitySpells(nodeSource)
	local tAbilitySpells = {};

	local sText = DB.getText(nodeSource, "text", ""):lower();
	local tSentences = StringManager.split(sText, ".");
	for _,vSentence in pairs(tSentences) do
	 	local sSpellText = vSentence:match("you know the (.-) cantrip");
		if not sSpellText then
		 	sSpellText = vSentence:match("you know the cantrip[s]? ([%w%s]+)");
		end
	 	if not sSpellText then
		 	sSpellText = vSentence:match("you can cast the (.-) on");
		end
		if not sSpellText then
			sSpellText = vSentence:match("to cast the (.-) spell");
		end
		if not sSpellText then
			sSpellText = vSentence:match("you can cast (.-) once with ");
		end
		if not sSpellText then
			sSpellText = vSentence:match("you can cast the (.-) with this trait");
		end
		if not sSpellText then
			sSpellText = vSentence:match("you can cast (.-) with this trait");
		end
		if not sSpellText then
			sSpellText = vSentence:match("you can also cast the (.-) with this trait");
		end
		if not sSpellText then
			sSpellText = vSentence:match("gain the ability to cast (.-), but only");
		end
		if not sSpellText then
			break;
		else
			sSpellText = sSpellText:gsub(" an unlimited number of times", "")
			sSpellText = sSpellText:gsub(" %(targeting yourself", "")
			sSpellText = sSpellText:gsub(" as a 2nd-level", "")
			sSpellText = sSpellText:gsub(" as a 2nd level", "")
			sSpellText = sSpellText:gsub(", but", "")
			sSpellText = sSpellText:gsub(" spell", "")

			sSpellText = StringManager.trim(sSpellText);

			local sSplit1, sSplit2 = sSpellText:match("(detect magic) and (detect poison and disease)")
			if not sSplit1 and not sSplit2 then
				sSplit1, sSplit2 = sSpellText:match("([%w%s]+) and ([%w%s]+)");
			end

			local tSplit = {};
			if sSplit1 and sSplit2 then
				table.insert(tSplit, sSplit1);
				table.insert(tSplit, sSplit2);
			end

			if #tSplit > 0 then
				for _,v in pairs(tSplit) do
					if vSentence:match("3rd") then
						-- Skip?
					elseif vSentence:match("5th") then
						-- Skip?
					else
						table.insert(tAbilitySpells, v);
					end
				end
			else
				if vSentence:match("3rd") then
					-- Skip?
				elseif vSentence:match("5th") then
					-- Skip?
				else
					table.insert(tAbilitySpells, sSpellText);
				end
			end
		end
	end

	return tAbilitySpells;
end