-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

--
-- CHARACTER SHEET DROPS
--

function addInfoDB(nodeChar, sClass, sRecord)
	-- Validate parameters
	if not nodeChar then
		return false;
	end
	
	if sClass == "reference_race" then
		CharSpeciesManager.addSpecies(nodeChar, sRecord);
	elseif sClass == "reference_subrace" then
		CharSpeciesManager.addAncestry(nodeChar, sRecord);
	elseif sClass == "reference_racialtrait" or sClass == "reference_subracialtrait" then
		CharSpeciesManager.addSpeciesTrait(nodeChar, sRecord);

	elseif sClass == "reference_class" then
		CharClassManager.addClass(nodeChar, sRecord);
	elseif sClass == "reference_classproficiency" then
		CharClassManager.addClassProficiency(nodeChar, sRecord);
	elseif sClass == "reference_classfeature" then
		CharClassManager.addClassFeature(nodeChar, sRecord);
	elseif sClass == "reference_classfeaturechoice" then
		CharClassManager.addClassFeatureChoice(nodeChar, sRecord);

	elseif sClass == "reference_background" then
		CharBackgroundManager.addBackground(nodeChar, sRecord);
	elseif sClass == "reference_backgroundfeature" then
		CharBackgroundManager.addBackgroundFeature(nodeChar, sRecord);

	elseif sClass == "reference_feat" then
		CharFeatManager.addFeat(nodeChar, sRecord);
		
	elseif sClass == "reference_skill" then
		CharBuildDropManager.addSkillRecord(nodeChar, sRecord);
	elseif sClass == "ref_adventure" then
		CharBuildDropManager.addAdvLogDrop(nodeChar, sRecord);

	else
		return false;
	end
	
	return true;
end
function addSkillRecord(nodeChar, sRecord)
	local nodeSource = DB.findNode(sRecord);
	if not nodeSource then
		return;
	end
	
	-- Add skill entry
	local nodeSkill = CharManager.getSkillRecord(nodeChar, DB.getValue(nodeSource, "name", ""), true);
	if nodeSkill then
		DB.setValue(nodeSkill, "text", "formattedtext", DB.getValue(nodeSource, "text", ""));
	end
end
function addAdvLogDrop(nodeChar, sRecord)
	local nodeSource = DB.findNode(sRecord);
	if not nodeSource then
		return;
	end
	local nodeList = DB.createChild(nodeChar, "adventurelist");
	if not nodeList then
		return nil;
	end
	
	local nodeNew = DB.createChildAndCopy(nodeList, nodeSource);
	DB.setValue(nodeNew, "locked", "number", 1);
	
	ChatManager.SystemMessageResource("char_logs_message_adventureadd", DB.getValue(nodeSource, "name", ""), DB.getValue(nodeChar, "name", ""));
end

--
--	BUILD
--

function helperBuildAddStructure(nodeChar, sClass, sRecord, tData)
	if not nodeChar or ((sClass or "") == "") or ((sRecord or "") == "") then
		return nil;
	end

	local rAdd = { };
	rAdd.nodeSource = DB.findNode(sRecord);
	if not rAdd.nodeSource then
		return nil;
	end

	rAdd.sSourceClass = sClass;
	if sClass == "reference_classfeaturechoice" then
		rAdd.sSourceName = CharClassManager.getFeatureChoiceDisplayName(rAdd.nodeSource);
	else
		rAdd.sSourceName = StringManager.trim(DB.getValue(rAdd.nodeSource, "name", ""));
	end

	rAdd.nodeChar = nodeChar;
	rAdd.sCharName = StringManager.trim(DB.getValue(nodeChar, "name", ""));

	rAdd.sSourceType = StringManager.simplify(rAdd.sSourceName);
	if rAdd.sSourceType == "" then
		rAdd.sSourceType = DB.getName(rAdd.nodeSource);
	end

	if StringManager.contains({ "reference_background", "reference_class", "reference_feat", "reference_race", "reference_subrace", }, sClass) then
		rAdd.bSource2024 = (DB.getValue(rAdd.nodeSource, "version", "") == "2024");
	elseif StringManager.contains({ "reference_backgroundfeature", "reference_classfeature", "reference_classfeaturechoice", "reference_racialtrait", "reference_subracialtrait", }, sClass) then
		rAdd.bSource2024 = (DB.getValue(rAdd.nodeSource, "...version", "") == "2024");
	elseif StringManager.contains({ "reference_classproficiency", }, sClass) then
		rAdd.bSource2024 = (DB.getValue(rAdd.nodeSource, "...version", "") == "2024");
	end

	rAdd.bWizard = tData and tData.bWizard;
	if StringManager.contains({ "reference_classfeature", "reference_classfeaturechoice", }, sClass) then
		rAdd.nodeCharClass = tData and tData.nodeCharClass;
		rAdd.nodeClass = tData and tData.nodeClass or DB.getChild(rAdd.nodeSource, "...");
	end
	
	return rAdd;
end
function helperBuildGetText(rAdd)
	if not rAdd or not rAdd.nodeSource then
		return false;
	end
	if not rAdd.sSourceText then
		rAdd.sSourceText = StringManager.trim(DB.getText(rAdd.nodeSource, "text", ""));
	end
	if rAdd.sSourceText == "" then
		return false;
	end
	return true;
end

function handleAbilitiesField(rAdd)
	local s = StringManager.trim(DB.getValue(rAdd.nodeSource, "abilities", ""));
	if (s == "") or (s == "None") then
		return;
	end

	CharBuildDropManager.pickInitialAbilityAdjust(rAdd.nodeChar, CharBuildManager.parseAbilitiesFromString(s), rAdd.bSource2024);
end

-- Species
function handleSizeField(rAdd)
	CharBuildDropManager.pickSize(rAdd.nodeChar, CharBuildManager.parseSizesFromString(DB.getValue(rAdd.nodeSource, "size", "")));
end
function handleSpeedField(rAdd)
	CharManager.setSpeed(rAdd.nodeChar, DB.getValue(rAdd.nodeSource, "speed", ""):match("%d+"));
end

-- Class
function handleClassSavesField(rAdd)
	if not CharBuildDropManager.helperBuildGetText(rAdd) then
		return;
	end

	local tAbilities = CharBuildManager.parseAbilitiesFromString(rAdd.sSourceText);
	for _,sAbility in ipairs(tAbilities) do
		CharManager.addSaveProficiency(rAdd.nodeChar, sAbility);
	end
end
function handleClassSkillsField(rAdd)
	if not CharBuildDropManager.helperBuildGetText(rAdd) then
		return;
	end

	local tBase, tOptions, nPicks = CharBuildManager.parseSkillsField(rAdd.sSourceText, rAdd.bSource2024);

	for _,s in ipairs(tBase) do
		CharManager.addSkillProficiency(rAdd.nodeChar, s);
	end
	CharBuildDropManager.pickSkill(rAdd.nodeChar, tOptions, nPicks, { bAddExpertise = rAdd.bAddExpertise, });
end
function handleClassArmorField(rAdd)
	if not CharBuildDropManager.helperBuildGetText(rAdd) then
		return;
	end

	local tBase, tOptions, nPicks = CharBuildManager.parseArmorField(rAdd.sSourceText, rAdd.bSource2024);

	for _,s in ipairs(tBase) do
		CharManager.addProficiency(rAdd.nodeChar, "armor", s);
	end
	CharBuildDropManager.pickProficiency(rAdd.nodeChar, "armor", tOptions, nPicks);
end
function handleClassWeaponsField(rAdd)
	if not CharBuildDropManager.helperBuildGetText(rAdd) then
		return;
	end

	local tBase, tOptions, nPicks = CharBuildManager.parseWeaponField(rAdd.sSourceText, rAdd.bSource2024);

	for _,s in ipairs(tBase) do
		CharManager.addProficiency(rAdd.nodeChar, "weapons", s);
	end
	CharBuildDropManager.pickProficiency(rAdd.nodeChar, "weapons", tOptions, nPicks);
end
function handleClassToolsField(rAdd)
	if not CharBuildDropManager.helperBuildGetText(rAdd) then
		return;
	end

	local tBase, tOptions, nPicks = CharBuildManager.parseToolsField(rAdd.sSourceText, rAdd.bSource2024);

	for _,s in ipairs(tBase) do
		CharManager.addProficiency(rAdd.nodeChar, "tools", s);
	end
	CharBuildDropManager.pickProficiency(rAdd.nodeChar, "tools", tOptions, nPicks);
end

-- Background
function handleBackgroundSkillsField(rAdd)
	local s = StringManager.trim(DB.getValue(rAdd.nodeSource, "skill", ""));
	if (s == "") or (s == "None") then
		return;
	end

	local tBase, tOptions, nPicks = CharBuildManager.parseSkillsField(s, rAdd.bSource2024);

	for _,s in ipairs(tBase) do
		CharManager.addSkillProficiency(rAdd.nodeChar, s);
	end
	CharBuildDropManager.pickSkill(rAdd.nodeChar, tOptions, nPicks, { bAddExpertise = rAdd.bAddExpertise, });
end
function handleBackgroundToolsField(rAdd)
	local s = StringManager.trim(DB.getValue(rAdd.nodeSource, "tool", ""));
	if (s == "") or (s == "None") then
		return;
	end

	local tBase, tOptions, nPicks = CharBuildManager.parseToolsField(s, rAdd.bSource2024);

	for _,s in ipairs(tBase) do
		CharManager.addProficiency(rAdd.nodeChar, "tools", s);
	end
	CharBuildDropManager.pickProficiency(rAdd.nodeChar, "tools", tOptions, nPicks);
end
function handleBackgroundLanguagesField(rAdd)
	local s = StringManager.trim(DB.getValue(rAdd.nodeSource, "languages", ""));
	if (s == "") or (s == "None") then
		return;
	end

	local tBase, tOptions, nPicks = CharBuildManager.parseLanguagesField(s, rAdd.bSource2024);

	for _,s in ipairs(tBase) do
		CharManager.addLanguage(rAdd.nodeChar, s);
	end
	CharBuildDropManager.pickLanguage(rAdd.nodeChar, "language", tOptions, nPicks);
end

function checkFeatureDescription(rAdd)
	if not rAdd or rAdd.bWizard then
		return false;
	end
	if not CharBuildDropManager.helperBuildGetText(rAdd) then
		return;
	end

	CharBuildDropManager.helperCheckFeatureSkills(rAdd);
	CharBuildDropManager.helperCheckFeatureArmorProf(rAdd);
	CharBuildDropManager.helperCheckFeatureWeaponProf(rAdd);
	CharBuildDropManager.helperCheckFeatureToolProf(rAdd);
	CharBuildDropManager.helperCheckFeatureLanguages(rAdd);
	CharBuildDropManager.helperCheckFeatureSpells(rAdd);
end
function helperCheckFeatureSkills(rAdd)
	local tBase, tOptions, nPicks;
	if rAdd.sSourceClass == "reference_classfeature" then
		tBase, tOptions, nPicks = CharBuildManager.getClassFeatureSkills(rAdd.sSourceName, rAdd.sSourceText, rAdd.bSource2024);
	elseif rAdd.sSourceClass == "reference_backgroundfeature" then
		tBase, tOptions, nPicks = CharBuildManager.getClassFeatureSkills(rAdd.sSourceName, rAdd.sSourceText, rAdd.bSource2024);
	elseif rAdd.sSourceClass == "reference_racialtrait" then
		tBase, tOptions, nPicks = CharBuildManager.getSpeciesTraitSkills(rAdd.sSourceName, rAdd.sSourceText, rAdd.bSource2024);
	elseif rAdd.sSourceClass == "reference_feat" then
		tBase, tOptions, nPicks = CharBuildManager.getFeatSkills(rAdd.sSourceName, rAdd.sSourceText, rAdd.bSource2024);
	else
		return;
	end

	for _,v in ipairs(tBase) do
		CharManager.addSkillProficiency(rAdd.nodeChar, v);
	end
	CharBuildDropManager.pickSkill(rAdd.nodeChar, tOptions, nPicks);
end
function helperCheckFeatureArmorProf(rAdd)
	local tBase, tOptions, nPicks;
	if rAdd.sSourceClass == "reference_classfeature" then
		tBase, tOptions, nPicks = CharBuildManager.getClassFeatureArmorProf(rAdd.sSourceName, rAdd.sSourceText, rAdd.bSource2024);
	elseif rAdd.sSourceClass == "reference_backgroundfeature" then
		tBase, tOptions, nPicks = CharBuildManager.getClassFeatureArmorProf(rAdd.sSourceName, rAdd.sSourceText, rAdd.bSource2024);
	elseif rAdd.sSourceClass == "reference_racialtrait" then
		tBase, tOptions, nPicks = CharBuildManager.getSpeciesTraitArmorProf(rAdd.sSourceName, rAdd.sSourceText, rAdd.bSource2024);
	elseif rAdd.sSourceClass == "reference_feat" then
		tBase, tOptions, nPicks = CharBuildManager.getFeatArmorProf(rAdd.sSourceName, rAdd.sSourceText, rAdd.bSource2024);
	else
		return;
	end

	for _,v in ipairs(tBase) do
		CharManager.addProficiency(rAdd.nodeChar, "armor", v);
	end
	CharBuildDropManager.pickProficiency(rAdd.nodeChar, "armor", tOptions, nPicks);
end
function helperCheckFeatureWeaponProf(rAdd)
	local tBase, tOptions, nPicks;
	if rAdd.sSourceClass == "reference_classfeature" then
		tBase, tOptions, nPicks = CharBuildManager.getClassFeatureWeaponProf(rAdd.sSourceName, rAdd.sSourceText, rAdd.bSource2024);
	elseif rAdd.sSourceClass == "reference_backgroundfeature" then
		tBase, tOptions, nPicks = CharBuildManager.getClassFeatureWeaponProf(rAdd.sSourceName, rAdd.sSourceText, rAdd.bSource2024);
	elseif rAdd.sSourceClass == "reference_racialtrait" then
		tBase, tOptions, nPicks = CharBuildManager.getSpeciesTraitWeaponProf(rAdd.sSourceName, rAdd.sSourceText, rAdd.bSource2024);
	elseif rAdd.sSourceClass == "reference_feat" then
		tBase, tOptions, nPicks = CharBuildManager.getFeatWeaponProf(rAdd.sSourceName, rAdd.sSourceText, rAdd.bSource2024);
	else
		return;
	end

	for _,v in ipairs(tBase) do
		CharManager.addProficiency(rAdd.nodeChar, "weapons", v);
	end
	CharBuildDropManager.pickProficiency(rAdd.nodeChar, "weapons", tOptions, nPicks);
end
function helperCheckFeatureToolProf(rAdd)
	local tBase, tOptions, nPicks;
	if rAdd.sSourceClass == "reference_classfeature" then
		tBase, tOptions, nPicks = CharBuildManager.getClassFeatureToolProf(rAdd.sSourceName, rAdd.sSourceText, rAdd.bSource2024);
	elseif rAdd.sSourceClass == "reference_backgroundfeature" then
		tBase, tOptions, nPicks = CharBuildManager.getClassFeatureToolProf(rAdd.sSourceName, rAdd.sSourceText, rAdd.bSource2024);
	elseif rAdd.sSourceClass == "reference_racialtrait" then
		tBase, tOptions, nPicks = CharBuildManager.getSpeciesTraitToolProf(rAdd.sSourceName, rAdd.sSourceText, rAdd.bSource2024);
	elseif rAdd.sSourceClass == "reference_feat" then
		tBase, tOptions, nPicks = CharBuildManager.getFeatToolProf(rAdd.sSourceName, rAdd.sSourceText, rAdd.bSource2024);
	else
		return;
	end

	for _,v in ipairs(tBase) do
		CharManager.addProficiency(rAdd.nodeChar, "tools", v);
	end
	CharBuildDropManager.pickProficiency(rAdd.nodeChar, "tools", tOptions, nPicks);
end
function helperCheckFeatureLanguages(rAdd)
	local tBase, tOptions, nPicks;
	if rAdd.sSourceClass == "reference_classfeature" then
		tBase, tOptions, nPicks = CharBuildManager.getClassFeatureLanguages(rAdd.sSourceName, rAdd.sSourceText, rAdd.bSource2024);
	elseif rAdd.sSourceClass == "reference_backgroundfeature" then
		tBase, tOptions, nPicks = CharBuildManager.getClassFeatureLanguages(rAdd.sSourceName, rAdd.sSourceText, rAdd.bSource2024);
	elseif rAdd.sSourceClass == "reference_racialtrait" then
		tBase, tOptions, nPicks = CharBuildManager.getSpeciesTraitLanguages(rAdd.sSourceName, rAdd.sSourceText, rAdd.bSource2024);
	elseif rAdd.sSourceClass == "reference_feat" then
		tBase, tOptions, nPicks = CharBuildManager.getFeatLanguages(rAdd.sSourceName, rAdd.sSourceText, rAdd.bSource2024);
	else
		return;
	end

	for _,v in ipairs(tBase) do
		CharManager.addLanguage(rAdd.nodeChar, v);
	end
	CharBuildDropManager.pickLanguage(rAdd.nodeChar, tOptions, nPicks);
end
function helperCheckFeatureSpells(rAdd)
	local tBase, tOptions, nPicks;
	if rAdd.sSourceClass == "reference_classfeature" then
		tBase, tOptions, nPicks = CharBuildManager.getClassFeatureSpells(rAdd.sSourceName, rAdd.sSourceText, rAdd.bSource2024);
	elseif rAdd.sSourceClass == "reference_backgroundfeature" then
		tBase, tOptions, nPicks = CharBuildManager.getClassFeatureSpells(rAdd.sSourceName, rAdd.sSourceText, rAdd.bSource2024);
	elseif rAdd.sSourceClass == "reference_racialtrait" then
		tBase, tOptions, nPicks = CharBuildManager.getSpeciesTraitSpells(rAdd.sSourceName, rAdd.sSourceText, rAdd.bSource2024);
	elseif rAdd.sSourceClass == "reference_feat" then
		tBase, tOptions, nPicks = CharBuildManager.getFeatSpells(rAdd.sSourceName, rAdd.sSourceText, rAdd.bSource2024);
	else
		return;
	end

	if #tBase > 0 then
		local nPrepared = 1;
		if rAdd.sSourceClass == "reference_backgroundfeature" then
			rAdd.sSpellGroup = CharBackgroundManager.getFeatureSpellGroup(rAdd);
			CharManager.addPowerGroup(rAdd.nodeChar, { sName = rAdd.sSpellGroup, bChooseSpellAbility = true });
		elseif rAdd.sSourceClass == "reference_racialtrait" then
			rAdd.sSpellGroup = CharSpeciesManager.getTraitSpellGroup(rAdd);
			CharManager.addPowerGroup(rAdd.nodeChar, { sName = rAdd.sSpellGroup, bChooseSpellAbility = true });
		elseif rAdd.sSourceClass == "reference_classfeature" then
			rAdd.sSpellGroup = CharClassManager.getFeatureSpellGroup(rAdd);
			nPrepared = nil;
		else
			rAdd.sSpellGroup = Interface.getString("char_spell_powergroup"):format(rAdd.sSourceName);
		end

		local tSpell = { sGroup = rAdd.sSpellGroup, bSource2024 = rAdd.bSource2024, nPrepared = nPrepared, };
		for _,sSpell in ipairs(tBase) do
			tSpell.sName = sSpell;
			CharManager.addSpell(rAdd.nodeChar, tSpell);
		end
	end
end

function checkBackgroundFeatureActions(rAdd)
	if not rAdd or ((rAdd.sSourceType or "") == "") then
		return;
	end

	if rAdd.bSource2024 then
		-- No background features in 2024 records
	else
		rAdd.sPowerGroup = CharBackgroundManager.getClassSpellGroup(rAdd);
		CharBuildDropManager.helperCheckActions(rAdd, CharWizardDataAction.parsedata[rAdd.sSourceType]);
	end
end
function checkClassFeatureActions(rAdd)
	if not rAdd or ((rAdd.sSourceType or "") == "") then
		return;
	end

	rAdd.sPowerGroup = CharClassManager.getFeaturePowerGroup(rAdd);
	if rAdd.bSource2024 then
		CharBuildDropManager.helperCheckActions(rAdd, CharWizardDataAction.tBuildDataClass2024[rAdd.sSourceType]);
	else
		CharBuildDropManager.helperCheckActions(rAdd, CharWizardDataAction.parsedata[rAdd.sSourceType]);
	end
end
function checkFeatActions(rAdd)
	if not rAdd or ((rAdd.sSourceType or "") == "") then
		return;
	end

	if rAdd.bSource2024 then
		rAdd.sPowerGroup = CharFeatManager.getFeatPowerGroup(rAdd);
		CharBuildDropManager.helperCheckActions(rAdd, CharWizardDataAction.tBuildDataFeat2024[rAdd.sSourceType]);
	else
		-- Feat data not supported in 2014 records
	end
end
function checkSpeciesTraitActions(rAdd)
	if not rAdd or ((rAdd.sSourceType or "") == "") then
		return;
	end

	rAdd.sPowerGroup = CharSpeciesManager.getTraitPowerGroup(rAdd);
	if rAdd.bSource2024 then
		CharBuildDropManager.helperCheckActions(rAdd, CharWizardDataAction.tBuildDataSpecies2024[rAdd.sSourceType]);
	else
		CharBuildDropManager.helperCheckActions(rAdd, CharWizardDataAction.parsedata[rAdd.sSourceType]);
	end
end

function helperCheckActions(rAdd, tAction)
	if not rAdd or not rAdd.nodeChar or not rAdd.nodeSource then
		return;
	end
	if not tAction then
		return;
	end

	if tAction.actions then
		CharBuildDropManager.helperCheckActionsAdd(rAdd, tAction, rAdd.sSourceName);
	elseif tAction.multiple_actions then
		for k,v in pairs(tAction.multiple_actions) do
			CharBuildDropManager.helperCheckActionsAdd(rAdd, v, k);
		end
	end

	if rAdd.bSource2024 and tAction.spells then
		rAdd.sSpellGroup = tAction.spells.group;

		-- Add Direct
		CharManager.addPowerGroup(rAdd.nodeChar, { sName = rAdd.sSpellGroup, sAbility = tAction.spells.ability, })
		for _,v in ipairs(tAction.spells) do
			local tData = {
				sName = v.name,
				sGroup = tAction.spells.group,
				bSource2024 = rAdd.bSource2024,
				bRitual = v.ritual,
				nPrepared = v.prepared, 
			};
			CharManager.addSpell(rAdd.nodeChar, tData);
		end

		-- Pick By Class and Level
		for i = 0,9 do
			local vPicks = tAction.spells["L" .. i];
			if vPicks then
				local tFilters = {
					{ sField = "version", sValue = rAdd.bSource2024 and "2024" or "", },
					{ sField = "level", sValue = tostring(i), },
				};
				local tData = { sClassName = tAction.spells.list, sGroup = rAdd.sSpellGroup, bWizard = rAdd.bWizard, };
				CharBuildDropManager.pickSpellByFilter(rAdd, tFilters, tonumber(vPicks) or 0, tData);
			end
		end
	end

	if tAction.senses then
		for k,v in pairs(tAction.senses) do
			CharManager.addSense(rAdd.nodeChar, k, v);
		end
	end
	if tAction.addspeed then
		CharManager.addSpeed(rAdd.nodeChar, tAction.addspeed);
	end
	if tAction.specialmoves then
		for k,v in pairs(tAction.specialmoves) do
			if type(v) == "boolean" then
				CharManager.addSpecialMove(rAdd.nodeChar, k);
			else
				CharManager.addSpecialMove(rAdd.nodeChar, k, v);
			end
		end
	end
	if tAction.saveprof then
		for _,v in ipairs(tAction.saveprof) do
			CharManager.addSaveProficiency(rAdd.nodeChar, v);
		end
	end
	if rAdd.bSource2024 then
		if tAction.armorprof then
			for _,v in ipairs(tAction.armorprof) do
				CharManager.addProficiency(rAdd.nodeChar, "armor", v);
			end
		end
		if tAction.weaponprof then
			for _,v in ipairs(tAction.weaponprof) do
				CharManager.addProficiency(rAdd.nodeChar, "weapons", v);
			end
		end
		if tAction.toolprof then
			for _,v in ipairs(tAction.toolprof) do
				CharManager.addProficiency(rAdd.nodeChar, "tools", v);
			end
		end
	else
		-- TODO (2024) - Handle built-in 2014 armor/weapon/tool prof on drag and drop
	end
end
function helperCheckActionsAdd(rAdd, tAction, sPowerName)
	if not rAdd or not tAction then
		return;
	end
	if not tAction.actions then
		return;
	end

	if tAction.group then
		CharManager.addPowerGroup(rAdd.nodeChar, { sName = tAction.group, sAbility = tAction.ability, })
	end

	local rActionsAdd = {
		nodeSource = rAdd.nodeSource,
		nodeChar = rAdd.nodeChar,
		sPowerName = sPowerName,
		sPowerGroup = tAction.group or rAdd.sPowerGroup,
		tPowerActions = tAction.actions,
		nPowerPrepared = tAction.prepared,
		sUsePeriod = tAction.usesperiod,
	};
	CharBuildDropManager.helperCheckActionsAdd2(rActionsAdd);
end
function helperCheckActionsAdd2(rActionsAdd)
	local nodePowerList = DB.createChild(rActionsAdd.nodeChar, "powers");
	if not nodePowerList then
		return;
	end

	local nodeNewPower = DB.createChildAndCopy(nodePowerList, rActionsAdd.nodeSource);
	if not nodeNewPower then
		return;
	end

	-- Set specific data
	DB.setValue(nodeNewPower, "locked", "number", 1);
	DB.setValue(nodeNewPower, "group", "string", rActionsAdd.sPowerGroup);
	if rActionsAdd.nPowerPrepared and (rActionsAdd.nPowerPrepared > 0) then
		DB.setValue(nodeNewPower, "prepared", "number", rActionsAdd.nPowerPrepared);
	end
	if rActionsAdd.sUsePeriod then
		DB.setValue(nodeNewPower, "usesperiod", "string", rActionsAdd.sUsePeriod);
	end
	if rActionsAdd.sPowerName then
		DB.setValue(nodeNewPower, "name", "string", rActionsAdd.sPowerName);
	end

	-- Clean up
	DB.deleteChild(nodeNewPower, "level");
	local nodeActions = DB.createChild(nodeNewPower, "actions");
	DB.deleteChildren(nodeActions);

	-- Convert text to description
	local nodeText = DB.getChild(nodeNewPower, "text");
	if nodeText then
		local nodeDesc = DB.createChild(nodeNewPower, "description", "formattedtext");
		DB.copyNode(nodeText, nodeDesc);
		DB.deleteNode(nodeText);
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

function handleClassFeatureChoices(rAdd)
	if not rAdd or ((rAdd.sSourceType or "") == "") then
		return false;
	end

	if rAdd.bSource2024 and not rAdd.bWizard then
		return CharBuildDropManager.helperCheckChoices(rAdd, CharWizardDataAction.tBuildDataClass2024[rAdd.sSourceType]);
	else
		-- Feature Choices not supported in 2014 records
	end
	return false;
end
function helperCheckChoices(rAdd, tAction)
	if not rAdd or not tAction then
		return false;
	end

	if tAction.choicetype then
		CharBuildDropManager.helperCheckActions(rAdd, tAction);
		CharBuildDropManager.pickClassFeatureChoiceByType(rAdd, tAction.choicetype, tAction.choicenum);
		return true;
	end
	if tAction.addchoicetype then
		CharBuildDropManager.pickClassFeatureChoiceByType(rAdd, tAction.addchoicetype, tAction.choicenum);
		return false;
	end
	if tAction.followon then
		for s,v in pairs(tAction.followon) do
			if CharManager.hasFeature(rAdd.nodeChar, s) then
				local sTypeLower = StringManager.simplify(v.choicetype) or "";
				local sNameLower = StringManager.simplify(v.name) or "";
				for _,node in ipairs(DB.getChildList(rAdd.nodeClass, "featurechoices")) do
					if StringManager.simplify(DB.getValue(node, "choicetype", "")) == sTypeLower and
							StringManager.simplify(DB.getValue(node, "name", "")) == sNameLower then
						CharBuildDropManager.helperCheckActions(rAdd, tAction);
						CharClassManager.addClassFeatureChoice(rAdd.nodeChar, DB.getPath(node), { bWizard = rAdd.bWizard, });
						return true;
					end
				end
			end
		end
	end
	return false;
end

--
--	DROP BUILD SELECTION CHOICES
--

function pickInitialAbilityAdjust(nodeChar, tAbilities, bSource2024)
	if not nodeChar or not tAbilities then
		return;
	end
	if not bSource2024 then
		return;
	end

	if #tAbilities > 2 then
		local tOptions = {
			Interface.getString("char_build_option_selectabilityadjby2then1"),
			Interface.getString("char_build_option_selectabilityadj3by1"),
		};
		local tData = {
			title = Interface.getString("char_build_title_selectabilityadjtype"),
			msg = Interface.getString("char_build_message_selectabilityadjtype"):format(table.concat(tAbilities, ", ")),
			options = tOptions,
			callback = CharBuildDropManager.helperOnInitialAbilityAdjTypeSelect,
			custom = { nodeChar = nodeChar, tAbilities = tAbilities, },
		};
		local wSelect = Interface.openWindow("select_dialog", "");
		wSelect.requestSelectionByData(tData);
	elseif #tAbilities == 2 then
		CharBuildDropManager.helperAddBackgroundAdjBy2Then1(nodeChar, tAbilities);
	elseif #tAbilities == 1 then
		CharManager.addAbilityAdjustment(nodeChar, tAbilities[1], 2);
	end
end
function helperOnInitialAbilityAdjTypeSelect(tSelection, tData)
	if not tSelection or not tSelection[1] then
		return;
	end
	if tSelection[1] == Interface.getString("char_build_option_selectabilityadjby2then1") then
		CharBuildDropManager.helperInitialAbilityAdjBy2Then1(tData.nodeChar, tData.tAbilities);
	else
		CharBuildDropManager.helperInitialAbilityAdj3By1(tData.nodeChar, tData.tAbilities);
	end
end
function helperInitialAbilityAdjBy2Then1(nodeChar, tAbilities)
	local tData = {
		title = Interface.getString("char_build_title_selectabilityincrease"),
		msg = Interface.getString("char_build_message_selectabilityincrease"):format(1, 2),
		options = tAbilities,
		callback = CharBuildDropManager.helperOnInitialAbilityAdjBy2,
		custom = { nodeChar = nodeChar, tAbilities = tAbilities, },
	};
	local wSelect = Interface.openWindow("select_dialog", "");
	wSelect.requestSelectionByData(tData, true);
end
function helperOnInitialAbilityAdjBy2(tSelection, tData)
	if not tSelection or not tSelection[1] then
		return;
	end
	CharManager.addAbilityAdjustment(tData.nodeChar, tSelection[1]:lower(), 2);

	for k,v in ipairs(tData.tAbilities) do
		if tSelection[1] == v then
			table.remove(tData.tAbilities, k);
			break;
		end
	end

	if #(tData.tAbilities) == 1 then
		CharManager.addAbilityAdjustment(tData.nodeChar, tSelection[1]:lower(), 1);
	elseif #(tData.tAbilities) > 1 then
		local tData = {
			title = Interface.getString("char_build_title_selectabilityincrease"),
			msg = Interface.getString("char_build_message_selectabilityincrease"):format(1, 1),
			options = tData.tAbilities,
			callback = CharBuildDropManager.helperOnInitialAbilityAdjThen1,
			custom = { nodeChar = tData.nodeChar, },
		};
		local wSelect = Interface.openWindow("select_dialog", "");
		wSelect.requestSelectionByData(tData, true);
	end
end
function helperOnInitialAbilityAdjThen1(tSelection, tData)
	if not tSelection or not tSelection[1] then
		return;
	end
	CharManager.addAbilityAdjustment(tData.nodeChar, tSelection[1]:lower(), 1);
end
function helperInitialAbilityAdj3By1(nodeChar, tAbilities)
	if #tAbilities <= 3 then
		for _,s in ipairs(tAbilities) do
			CharManager.addAbilityAdjustment(nodeChar, s:lower(), 1);
		end
	else
		local tData = {
			title = Interface.getString("char_build_title_selectabilityincrease"),
			msg = Interface.getString("char_build_message_selectabilityincrease"):format(3, 1),
			options = tAbilities,
			min = 3,
			callback = CharBuildDropManager.helperOnInitialAbilityAdj3By1,
			custom = { nodeChar = nodeChar, },
		};
		local wSelect = Interface.openWindow("select_dialog", "");
		wSelect.requestSelectionByData(tData, true);
	end
end
function helperOnInitialAbilityAdj3By1(tSelection, tData)
	for _,s in ipairs(tSelection) do
		CharManager.addAbilityAdjustment(tData.nodeChar, s:lower(), 1);
	end
end

function pickAbility(nodeChar, tOptions, nPicks, tData)
	if not tData then
		return;
	end

	nPicks = nPicks or 1;
	if (nPicks <= 0) then
		return;
	end
	tData.nAbilityAdj = tData.nAbilityAdj or 1;
	tData.nAbilityMax = tData.nAbilityMax or 20;

	if #(tOptions or {}) == 0 then
		tOptions = CharBuildDropManager.getAbilityOptions(nodeChar, tData.nAbilityMax);
	end

	if nPicks >= #tOptions then
		for _,v in ipairs(tOptions) do
			CharManager.addAbilityAdjustment(nodeChar, v, tData.nAbilityAdj, tData.nAbilityMax);
		end
		return;
	end

	local tData = {
		title = Interface.getString("char_build_title_selectabilityincrease"),
		msg = Interface.getString("char_build_message_selectabilityincrease"):format(nPicks, tData.nAbilityAdj),
		options = tOptions,
		min = nPicks,
		callback = CharBuildDropManager.onAbilitySelect,
		custom = { nodeChar = nodeChar, nAbilityAdj = tData.nAbilityAdj, nAbilityMax = tData.nAbilityMax },
	};
	local wSelect = Interface.openWindow("select_dialog", "");
	wSelect.requestSelectionByData(tData, true);
end
function onAbilitySelect(tSelection, tData)
	for _,s in ipairs(tSelection) do
		CharManager.addAbilityAdjustment(tData.nodeChar, s, tData.nAbilityAdj or 1, tData.nAbilityMax);
	end
end
function getAbilityOptions(nodeChar, nAbilityMax)
	local tAbilities = {};
	for _,sAbility in ipairs(DataCommon.abilities) do
		if not nAbilityMax or (CharManager.getAbility(nodeChar, sAbility) < nAbilityMax) then
			table.insert(tAbilities, StringManager.capitalize(sAbility));
		end
	end
	return tAbilities;
end

function pickAbilities2014(nodeChar, tAbilitySelect)
	if #tAbilitySelect == 0 then
		return;
	end

	if not tAbilitySelect[1].aAbilities or (#(tAbilitySelect[1].aAbilities) == 0) then 
		tAbilitySelect[1].aAbilities = CharBuildDropManager.getDefaultAbilityOptions2014(); 
	end
	local nPicks = tAbilitySelect[1].nPicks or 1;
	local nAbilityAdj = tAbilitySelect[1].nAbilityAdj or 1;

	local tData = {
		title = Interface.getString("char_build_title_selectabilityincrease"),
		msg = Interface.getString("char_build_message_selectabilityincrease"):format(nPicks, nAbilityAdj),
		options = tAbilitySelect[1].aAbilities,
		min = nPicks,
		callback = CharBuildDropManager.onAbilitiesSelect2014,
		custom = { nodeChar = nodeChar, tAbilitySelect = tAbilitySelect, },
	};
	local wSelect = Interface.openWindow("select_dialog", "");
	wSelect.requestSelectionByData(tData, true);
end
function onAbilitiesSelect2014(aSelection, rAbilitySelectMeta)
	local rAbilitySelect = rAbilitySelectMeta.tAbilitySelect[1];
	for _,sAbility in ipairs(aSelection) do
		CharManager.addAbilityAdjustment(rAbilitySelectMeta.nodeChar, sAbility, rAbilitySelect.nAbilityAdj or 1, rAbilitySelect.nAbilityMax);
		
		if rAbilitySelect.bSaveProfAdd then
			local sAbilityLower = StringManager.simplify(sAbility);
			if StringManager.contains(DataCommon.abilities, sAbilityLower) then
				DB.setValue(rAbilitySelectMeta.nodeChar, "abilities." .. sAbilityLower .. ".saveprof", "number", 1);
				ChatManager.SystemMessageResource("char_abilities_message_saveadd", sAbility, DB.getValue(rAbilitySelectMeta.nodeChar, "name", ""));
			end
		end
	end

	table.remove(rAbilitySelectMeta.tAbilitySelect, 1);
	if #(rAbilitySelectMeta.tAbilitySelect) > 0 then
		for _,vSelect in ipairs(rAbilitySelectMeta.tAbilitySelect) do
			if vSelect.bOther then
				if not vSelect.aAbilities or (#vSelect.aAbilities == 0) then 
					vSelect.aAbilities = CharBuildDropManager.getDefaultAbilityOptions2014(); 
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
		CharBuildDropManager.pickAbilities2014(rAbilitySelectMeta.nodeChar, rAbilitySelectMeta.tAbilitySelect);
	end
end
function getDefaultAbilityOptions2014()
	local tOptions = {};
	for _,sAbility in ipairs(DataCommon.abilities) do
		table.insert(tOptions, StringManager.capitalize(sAbility));
	end
	return tOptions;
end

function pickAbilityAdjust(nodeChar, bSource2024)
	local tOptions = {
		Interface.getString("char_build_option_selectabilityadjby2"),
		Interface.getString("char_build_option_selectabilityadj2by1"),
	};
	local tData = {
		title = Interface.getString("char_build_title_selectabilityadjtype"),
		msg = Interface.getString("char_build_message_selectabilityadjtype"):format("Any"),
		options = tOptions,
		callback = CharBuildDropManager.helperOnAbilityAdjTypeSelect,
		custom = { nodeChar = nodeChar, bSource2024 = bSource2024, },
	};
	local wSelect = Interface.openWindow("select_dialog", "");
	wSelect.requestSelectionByData(tData);
end
function helperOnAbilityAdjTypeSelect(tSelection, tData)
	if not tSelection or not tSelection[1] then
		return;
	end
	if tSelection[1] == Interface.getString("char_build_option_selectabilityadjby2") then
		CharBuildDropManager.helperAbilityAdjBy2(tData.nodeChar, tData.bSource2024);
	else
		CharBuildDropManager.helperAbilityAdj2By1(tData.nodeChar, tData.bSource2024);
	end
end
function helperAbilityAdjBy2(nodeChar, bSource2024)
	local nAbilityMax = 20;
	local tData = {
		title = Interface.getString("char_build_title_selectabilityincrease"),
		msg = Interface.getString("char_build_message_selectabilityincrease"):format(1, 2),
		options = CharBuildDropManager.getAbilityOptions(nodeChar, nAbilityMax),
		callback = CharBuildDropManager.helperOnAbilityAdj,
		custom = { nodeChar = nodeChar, nAbilityAdj = 2, },
	};
	local wSelect = Interface.openWindow("select_dialog", "");
	wSelect.requestSelectionByData(tData, true);
end
function helperAbilityAdj2By1(nodeChar, bSource2024)
	local nAbilityMax = 20;
	local tData = {
		title = Interface.getString("char_build_title_selectabilityincrease"),
		msg = Interface.getString("char_build_message_selectabilityincrease"):format(2, 1),
		options = CharBuildDropManager.getAbilityOptions(nodeChar, nAbilityMax),
		min = 2,
		callback = CharBuildDropManager.helperOnAbilityAdj,
		custom = { nodeChar = nodeChar, nAbilityAdj = 1, },
	};
	local wSelect = Interface.openWindow("select_dialog", "");
	wSelect.requestSelectionByData(tData, true);
end
function helperOnAbilityAdj(tSelection, tData)
	for _,s in ipairs(tSelection) do
		CharManager.addAbilityAdjustment(tData.nodeChar, s:lower(), tData.nAbilityAdj);
	end
end

function pickSize(nodeChar, tSizes)
	if not nodeChar or not tSizes then
		return;
	end
	if #tSizes <= 1 then
		CharManager.setSize(nodeChar, tSizes[1]);
		return;
	end
	
	local tData = {
		title = Interface.getString("char_build_title_selectsize"),
		msg = Interface.getString("char_build_message_selectsize"),
		options = tSizes,
		callback = CharBuildDropManager.onSizeSelect,
		custom = { nodeChar = nodeChar },
	};
	local wSelect = Interface.openWindow("select_dialog", "");
	wSelect.requestSelectionByData(tData);
end
function onSizeSelect(tSelection, tData)
	for _,s in ipairs(tSelection) do
		CharManager.setSize(tData.nodeChar, s);
	end
end

function pickSaveProficiency(nodeChar, tOptions, nPicks)
	nPicks = nPicks or 1;
	if nPicks <= 0 then
		return;
	end

	local tSaveOptions;
	if #(tOptions or {}) == 0 then
		tSaveOptions = CharBuildDropManager.getSaveProficiencyOptions(nodeChar);
	else
		tSaveOptions = CharBuildDropManager.helperGetSaveProficiencyOptionsFilter(nodeChar, tOptions);
	end
		
	if nPicks >= #tSaveOptions then
		for _,v in ipairs(tSaveOptions) do
			CharManager.addSaveProficiency(nodeChar, v.text);
		end
		return;
	end
	
	local tData = {
		title = Interface.getString("char_build_title_selectprofs"),
		msg = Interface.getString("char_build_message_selectprofs"):format(nPicks or 1),
		options = tSaveOptions,
		min = nPicks or 1,
		callback = CharBuildDropManager.onSaveSelect,
		custom = { nodeChar = nodeChar },
	};
	local wSelect = Interface.openWindow("select_dialog", "");
	wSelect.requestSelectionByData(tData);
end
function onSaveSelect(tSelection, tData)
	for _,s in ipairs(tSelection) do
		CharManager.addSaveProficiency(tData.nodeChar, s);
	end
end
function getSaveProficiencyOptions(nodeChar)
	if not nodeChar then
		return {};
	end

	local tAbilities = {};
	for k,_ in pairs(DataCommon.abilities) do
		table.insert(tAbilities, k);
	end
	table.sort(tAbilities);

	return CharBuildDropManager.helperGetSaveProficiencyOptionsFilter(nodeChar, tAbilities);
end
function helperGetSaveProficiencyOptionsFilter(nodeChar, tAbilities)
	local tSaveOptions = {};
	for _,s in ipairs(tAbilities) do
		if not CharManager.hasSaveProficiency(nodeChar, s) then
			table.insert(tSaveOptions, { text = StringManager.capitalize(s) });
		end
	end
	return tSaveOptions;
end

function pickSkill(nodeChar, tSkills, nPicks, tData)
	nPicks = nPicks or 1;
	if nPicks <= 0 then
		return;
	end

	local tSkillOptions;
	if #(tSkills or {}) == 0 then
		tSkillOptions = CharBuildDropManager.getSkillProficiencyOptions(nodeChar);
	else
		tSkillOptions = CharBuildDropManager.helperGetSkillProficiencyOptionsFilterAndLink(nodeChar, tSkills);
	end
		
	if nPicks >= #tSkillOptions then
		for _,v in ipairs(tSkillOptions) do
			CharManager.addSkillProficiency(nodeChar, v.text);
		end
		return;
	end
	
	local tData = {
		title = Interface.getString("char_build_title_selectprofs"),
		msg = Interface.getString("char_build_message_selectprofs"):format(nPicks or 1),
		options = tSkillOptions,
		min = nPicks or 1,
		callback = CharBuildDropManager.onSkillSelect,
		custom = { nodeChar = nodeChar, bAddExpertise = tData and tData.bAddExpertise, },
	};
	local wSelect = Interface.openWindow("select_dialog", "");
	wSelect.requestSelectionByData(tData);
end
function onSkillSelect(tSelection, tData)
	for _,sSkill in ipairs(tSelection) do
		CharManager.addSkillProficiency(tData.nodeChar, sSkill);
	end

	-- NOTE: Special handling for skills if class gets Expertise at L1
	if tData and tData.bAddExpertise then
		CharBuildDropManager.pickSkillExpertise(tData.nodeChar, nil, 2);
	end
end
function getSkillProficiencyOptions(nodeChar)
	if not nodeChar then
		return {};
	end

	local tSkills = {};
	for k,_ in pairs(DataCommon.skilldata) do
		table.insert(tSkills, k);
	end
	table.sort(tSkills);

	return CharBuildDropManager.helperGetSkillProficiencyOptionsFilterAndLink(nodeChar, tSkills);
end
function helperGetSkillProficiencyOptionsFilterAndLink(nodeChar, tSkills)
	local tSkillOptions = {};
	for _,s in ipairs(tSkills) do
		if not CharManager.hasSkillProficiency(nodeChar, s) then
			table.insert(tSkillOptions, s);
		end
	end

	CharBuildDropManager.helperGetSkillOptionsLinks(tSkillOptions);
	return tSkillOptions;
end
function helperGetSkillOptionsLinks(tSkillOptions)
	for k,s in ipairs(tSkillOptions) do
		local rSkill = { text = s, linkclass = "", linkrecord = "" };
		local nodeSkill = RecordManager.findRecordByStringI("skill", "name", s);
		if nodeSkill then
			rSkill.linkclass = "reference_skill";
			rSkill.linkrecord = DB.getPath(nodeSkill);
		end
		tSkillOptions[k] = rSkill;
	end
end

function pickSkillExpertise(nodeChar, tSkills, nPicks)
	nPicks = nPicks or 1;
	if nPicks <= 0 then
		return;
	end

	local tSkillOptions;
	if #(tSkills or {}) == 0 then
		tSkillOptions = CharBuildDropManager.getSkillExpertiseOptions(nodeChar);
	else
		tSkillOptions = CharBuildDropManager.helperGetSkillExpertiseOptionsFilterAndLink(nodeChar, tSkills);
	end
		
	if nPicks >= #tSkillOptions then
		for _,v in ipairs(tSkillOptions) do
			CharManager.increaseSkillProficiency(nodeChar, v.text, 2);
		end
		return;
	end
	
	local tData = {
		title = Interface.getString("char_build_title_selectexpertises"),
		msg = Interface.getString("char_build_message_selectexpertises"):format(nPicks),
		options = tSkillOptions,
		min = nPicks,
		callback = CharBuildDropManager.onSkillExpertiseSelect,
		custom = { nodeChar = nodeChar, },
	};
	local wSelect = Interface.openWindow("select_dialog", "");
	wSelect.requestSelectionByData(tData);
end
function onSkillExpertiseSelect(tSelection, tData)
	for _,s in ipairs(tSelection) do
		CharManager.increaseSkillProficiency(tData.nodeChar, s, 2);
	end
end
function getSkillExpertiseOptions(nodeChar)
	if not nodeChar then
		return {};
	end

	local tSkills = {};
	for k,_ in pairs(DataCommon.skilldata) do
		table.insert(tSkills, k);
	end
	table.sort(tSkills);

	return CharBuildDropManager.helperGetSkillExpertiseOptionsFilterAndLink(nodeChar, tSkills);
end
function helperGetSkillExpertiseOptionsFilterAndLink(nodeChar, tSkills)
	local tSkillOptions = {};
	for _,s in ipairs(tSkills) do
		local nodeCharSkill = CharManager.getSkillRecord(nodeChar, s);
		if nodeCharSkill and (DB.getValue(nodeCharSkill, "prof", 0) == 1) then
			table.insert(tSkillOptions, s);
		end
	end

	CharBuildDropManager.helperGetSkillOptionsLinks(tSkillOptions);
	return tSkillOptions;
end

function pickSkillIncrease(nodeChar, tSkills, nPicks, tData)
	nPicks = nPicks or 1;
	if nPicks <= 0 then
		return;
	end

	local tSkillOptions;
	if #(tSkills or {}) == 0 then
		tSkillOptions = CharBuildDropManager.getSkillIncreaseOptions(nodeChar);
	else
		tSkillOptions = CharBuildDropManager.helperGetSkillIncreaseOptionsFilterAndLink(nodeChar, tSkills);
	end
		
	if nPicks >= #tSkillOptions then
		for _,v in ipairs(tSkillOptions) do
			CharManager.increaseSkillProficiency(nodeChar, v.text);
		end
		return;
	end
	
	local tData = {
		title = Interface.getString("char_build_title_selectprofincreases"),
		msg = Interface.getString("char_build_message_selectprofincreases"):format(nPicks),
		options = tSkillOptions,
		min = nPicks,
		callback = CharBuildDropManager.onSkillIncreaseSelect,
		custom = { nodeChar = nodeChar, nIncrease = tData and tData.nIncrease, },
	};
	local wSelect = Interface.openWindow("select_dialog", "");
	wSelect.requestSelectionByData(tData);
end
function onSkillIncreaseSelect(tSelection, tData)
	for _,s in ipairs(tSelection) do
		CharManager.increaseSkillProficiency(tData.nodeChar, s, tData.nIncrease);
	end
end
function getSkillIncreaseOptions(nodeChar)
	if not nodeChar then
		return {};
	end

	local tSkills = {};
	for k,_ in pairs(DataCommon.skilldata) do
		table.insert(tSkills, k);
	end
	table.sort(tSkills);

	return CharBuildDropManager.helperGetSkillIncreaseOptionsFilterAndLink(nodeChar, tSkills);
end
function helperGetSkillIncreaseOptionsFilterAndLink(nodeChar, tSkills)
	local tSkillOptions = {};
	for _,s in ipairs(tSkills) do
		local nodeCharSkill = CharManager.getSkillRecord(nodeChar, s);
		if not nodeCharSkill or (DB.getValue(nodeCharSkill, "prof", 0) ~= 2) then
			table.insert(tSkillOptions, s);
		end
	end

	CharBuildDropManager.helperGetSkillOptionsLinks(tSkillOptions);
	return tSkillOptions;
end

function pickToolProficiencyBySubtype(nodeChar, s, nPicks)
	nPicks = nPicks or 1;
	if nPicks <= 0 then
		return;
	end

	local tFilters = {
		{ sField = "version", sValue = "2024", },
		{ sField = "type", sValue = "Tools", bIgnoreCase = true, },
		{ sField = "subtype", sValue = s, bIgnoreCase = true, },
	};
	local tOptions = RecordManager.getRecordOptionsByFilter("item", tFilters, true);
	if nPicks >= #tOptions then
		for _,v in ipairs(tOptions) do
			CharManager.addProficiency(nodeChar, "tools", v.text);
		end
		return;
	end

	local tData = {
		title = Interface.getString("char_build_title_selectprofs"),
		msg = Interface.getString("char_build_message_selectprofs"):format(nPicks),
		options = tOptions,
		min = nPicks or 1,
		callback = CharBuildDropManager.onToolProfSelect,
		custom = { nodeChar = nodeChar, },
	};
	local wSelect = Interface.openWindow("select_dialog", "");
	wSelect.requestSelectionByData(tData);
end
function onToolProfSelect(tSelection, tData)
	for _,s in ipairs(tSelection) do
		CharManager.addProficiency(tData.nodeChar, "tools", s);
	end
end

function pickProficiency(nodeChar, sType, tOptions, nPicks)
	if nPicks >= #tOptions then
		for _,v in ipairs(tOptions) do
			CharManager.addProficiency(nodeChar, sType, v.text);
		end
		return;
	end
	
	local tData = {
		title = Interface.getString("char_build_title_selectprofs"),
		msg = Interface.getString("char_build_message_selectprofs"):format(nPicks),
		options = tOptions,
		min = nPicks,
		callback = CharBuildDropManager.onProficiencySelect,
		custom = { nodeChar = nodeChar, sType = sType, },
	};
	local wSelect = Interface.openWindow("select_dialog", "");
	wSelect.requestSelectionByData(tData);
end
function onProficiencySelect(tSelection, tData)
	for _,s in ipairs(tSelection) do
		CharManager.addProficiency(tData.nodeChar, tData.sType, s);
	end
end

function pickFeat(nodeChar, tOptions, nPicks, tData)
	if nPicks >= #tOptions then
		for _,v in ipairs(tOptions) do
			CharManager.addFeat(nodeChar, v.text, tData);
		end
		return;
	end

	local tData = {
		title = Interface.getString("char_build_title_selectfeats"),
		msg = Interface.getString("char_build_message_selectfeats"):format(nPicks),
		options = tOptions,
		min = nPicks,
		callback = CharBuildDropManager.onFeatSelect,
		custom = { nodeChar = nodeChar, bSource2024 = tData and tData.bSource2024, bWizard = tData and tData.bWizard, },
	};
	local wSelect = Interface.openWindow("select_dialog", "");
	wSelect.requestSelectionByData(tData);
end
function onFeatSelect(tSelection, tData)
	for _,s in ipairs(tSelection) do
		CharManager.addFeat(tData.nodeChar, s, tData);
	end
end

function pickLanguage(nodeChar, tOptions, nPicks, tData)
	nPicks = nPicks or 1;
	if nPicks <= 0 then
		return;
	end

	local tDialogOptions;
	if #(tOptions or {}) == 0 then
		tDialogOptions = CharBuildDropManager.getLanguageOptions(nodeChar);
	else
		tDialogOptions = CharBuildDropManager.helperGetLanguageOptionsFilter(nodeChar, tOptions);
	end
		
	if nPicks >= #tDialogOptions then
		for _,v in ipairs(tDialogOptions) do
			CharManager.addLanguage(nodeChar, v.text, tData);
		end
		return;
	end
	
	local tData = {
		title = Interface.getString("char_build_title_selectlanguages"),
		msg = Interface.getString("char_build_message_selectlanguages"):format(nPicks),
		options = tDialogOptions,
		min = nPicks,
		callback = CharBuildDropManager.onLanguageSelect,
		custom = { nodeChar = nodeChar, bSource2024 = tData and tData.bSource2024, bWizard = tData and tData.bWizard, },
	};
	local wSelect = Interface.openWindow("select_dialog", "");
	wSelect.requestSelectionByData(tData);
end
function onLanguageSelect(tSelection, tData)
	for _,s in ipairs(tSelection) do
		CharManager.addLanguage(tData.nodeChar, s, tData);
	end
end
function getLanguageOptions(nodeChar)
	if not nodeChar then
		return {};
	end

	local tOptions = {};
	for k,_ in pairs(GameSystem.languages) do
		table.insert(tOptions, k);
	end
	table.sort(tOptions);

	return CharBuildDropManager.helperGetLanguageOptionsFilter(nodeChar, tOptions);
end
function helperGetLanguageOptionsFilter(nodeChar, tOptions)
	local tFilteredOptions = {};
	for _,s in ipairs(tOptions) do
		if not CharManager.hasLanguage(nodeChar, s) then
			table.insert(tFilteredOptions, { text = StringManager.capitalizeAll(s) });
		end
	end
	return tFilteredOptions;
end

function pickSpellGroupAbility(rAdd, fnCallback)
	local tData = {
		options = { "Intelligence", "Wisdom", "Charisma", },
		callback = CharBuildDropManager.onSpellGroupAbilitySelect,
		custom = { rAdd = rAdd, fnCallback = fnCallback },
	};
	if rAdd.bSpellGroupAbilityIncrease then
		tData.title = Interface.getString("char_build_title_selectabilityincrease");
		tData.msg = Interface.getString("char_build_message_selectabilityincrease"):format(1, 1);
	else
		tData.title = Interface.getString("char_build_title_selectspellability");
		tData.msg = Interface.getString("char_build_message_selectspellability");
	end
	local wSelect = Interface.openWindow("select_dialog", "");
	wSelect.requestSelectionByData(tData);
end
function onSpellGroupAbilitySelect(tSelection, tData)
	if not tSelection or not tSelection[1] then
		return;
	end

	tData.rAdd.sSpellGroup = tData.rAdd.sSpellGroup or Interface.getString("char_spell_powergroup"):format(tData.rAdd.sSourceName);
	tData.rAdd.sSpellGroupAbility = tSelection[1]:lower();
	CharManager.addPowerGroup(tData.rAdd.nodeChar, { sName = tData.rAdd.sSpellGroup, sAbility = tData.rAdd.sSpellGroupAbility, });

	if tData.fnCallback then
		tData.fnCallback(tData.rAdd);
	end
end
function chooseSpellGroupAbility(nodePowerGroup)
	if not nodePowerGroup then
		return;
	end

	local tData = {
		title = Interface.getString("char_build_title_selectspellability"),
		msg = Interface.getString("char_build_message_selectspellability"),
		options = { "Intelligence", "Wisdom", "Charisma", },
		callback = CharBuildDropManager.onSpellGroupAbilityChoice,
		custom = { nodePowerGroup = nodePowerGroup, },
	};
	local wSelect = Interface.openWindow("select_dialog", "");
	wSelect.requestSelectionByData(tData);
end
function onSpellGroupAbilityChoice(tSelection, tData)
	if not tSelection or not tSelection[1] or not tData or not tData.nodePowerGroup then
		return;
	end
	DB.setValue(tData.nodePowerGroup, "stat", "string", tSelection[1]:lower());
end

function pickSpellByFilter(rAdd, tFilters, nPicks, tData)
	if not rAdd then
		return;
	end

	local tOptions = RecordManager.getRecordOptionsByFilter("spell", tFilters, true);

	-- Handle class-specific filter differently, since it's a combination field
	if tData and ((tData.sClassName or "") ~= "") then
		local tTemp = {};
		for _,v in ipairs(tOptions) do
			if (v.linkrecord or "") ~= "" then
				local nodeSpell = DB.findNode(v.linkrecord);
				if nodeSpell then
					local tSources = ClassSpellListManager.helperGetSpellSources(nodeSpell);
					if StringManager.contains(tSources, tData.sClassName) then
						table.insert(tTemp, v);
					end
				end
			end
		end
		tOptions = tTemp;
	end

	local tPickData = { sGroup = rAdd.sSpellGroup, bWizard = rAdd.bWizard, bSource2024 = rAdd.bSource2024, nPrepared = tData and tData.nPrepared, };
	CharBuildDropManager.pickSpell(rAdd.nodeChar, tOptions, nPicks, tPickData);
end
function pickSpell(nodeChar, tOptions, nPicks, tData)
	nPicks = nPicks or 1;
	if nPicks <= 0 then
		return;
	end

	local tDialogOptions;
	if #(tOptions or {}) == 0 then
		tDialogOptions = {};
	else
		tDialogOptions = CharBuildDropManager.helperGetSpellOptionsFilter(nodeChar, tData.sGroup, tOptions);
	end
		
	if nPicks >= #tDialogOptions then
		for _,v in ipairs(tDialogOptions) do
			CharManager.addSpell(nodeChar, { sName = v.text, sGroup = tData.sGroup, bSource2024 = tData.bSource2024, nPrepared = tData.nPrepared, });
		end
		return;
	end

	local tData = {
		title = Interface.getString("char_build_title_selectspells"),
		msg = Interface.getString("char_build_message_selectspells"):format(nPicks),
		min = nPicks,
		options = tDialogOptions,
		callback = CharBuildDropManager.onSpellSelect,
		custom = { nodeChar = nodeChar, sGroup = tData.sGroup, bSource2024 = tData.bSource2024, nPrepared = tData.nPrepared, },
	};
	local wSelect = Interface.openWindow("select_dialog", "");
	wSelect.requestSelectionByData(tData);
end
function onSpellSelect(tSelection, tData)
	for _,s in ipairs(tSelection) do
		CharManager.addSpell(tData.nodeChar, { sName = s, sGroup = tData.sGroup, bSource2024 = tData.bSource2024, nPrepared = tData.nPrepared, });
	end
end
function helperGetSpellOptionsFilter(nodeChar, sGroup, tOptions)
	local tFilteredOptions = {};
	for _,v in ipairs(tOptions) do
		if not CharManager.hasGroupPower(nodeChar, sGroup, v.text) then
			table.insert(tFilteredOptions, v);
		end
	end
	return tFilteredOptions;
end

function pickClassFeatureChoiceByType(rAdd, sType, nPicks)
	if ((sType or "") == "") then
		return;
	end

	local sClassName = CharClassManager.getFeatureClassName(rAdd);
	local nClassLevel = CharManager.getClassLevel(rAdd.nodeChar, sClassName);

	local tOptions = {};
	local sTypeLower = StringManager.simplify(sType);
	for _,node in ipairs(DB.getChildList(rAdd.nodeClass, "featurechoices")) do
		if StringManager.simplify(DB.getValue(node, "choicetype", "")) == sTypeLower then
			local nLevel = DB.getValue(node, "level", 0);
			if (nLevel <= 0) or (nLevel <= nClassLevel) then
				local sPrereq = StringManager.trim(DB.getValue(node, "prerequisite", ""));
				if sPrereq == "" or CharManager.hasFeature(rAdd.nodeChar, sPrereq) then
					local sOption = CharClassManager.getFeatureChoiceDisplayName(node);
					if (DB.getValue(node, "repeatable", 0) == 1) or not CharManager.hasFeature(rAdd.nodeChar, sOption) then
						table.insert(tOptions, { text = sOption, linkclass = "reference_classfeaturechoice", linkrecord = DB.getPath(node), });
					end
				end
			end
		end
	end

	local tPickData = { bWizard = rAdd.bWizard, bSource2024 = rAdd.bSource2024, };
	CharBuildDropManager.pickClassFeatureChoice(rAdd.nodeChar, tOptions, nPicks, tPickData);
end
function pickClassFeatureChoice(nodeChar, tOptions, nPicks, tData)
	nPicks = nPicks or 1;
	if nPicks <= 0 then
		return;
	end

	if nPicks >= #tOptions then
		for _,v in ipairs(tOptions) do
			CharClassManager.addClassFeatureChoice(nodeChar, v.linkrecord, { bWizard = tData.bWizard, bSource2024 = tData.bSource2024, });
		end
		return;
	end

	local tLookup = {};
	for _,v in ipairs(tOptions) do
		tLookup[v.text] = v.linkrecord;
	end
	local tData = {
		title = Interface.getString("char_build_title_selectclassfeaturechoices"),
		msg = Interface.getString("char_build_message_selectclassfeaturechoices"):format(nPicks),
		min = nPicks,
		options = tOptions,
		callback = CharBuildDropManager.onClassFeatureChoiceSelect,
		custom = { nodeChar = nodeChar, bWizard = tData.bWizard, bSource2024 = tData.bSource2024, tLookup = tLookup},
	};
	local wSelect = Interface.openWindow("select_dialog", "");
	wSelect.requestSelectionByData(tData);
end
function onClassFeatureChoiceSelect(tSelection, tData)
	for _,s in ipairs(tSelection) do
		local sRecord = tData.tLookup[s];
		if sRecord then
			CharClassManager.addClassFeatureChoice(tData.nodeChar, sRecord, { bWizard = tData.bWizard, bSource2024 = tData.bSource2024, });
		end
	end
end