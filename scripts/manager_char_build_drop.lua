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

	if StringManager.contains({ "reference_background", "reference_class", "reference_class_specialization", "reference_feat", "reference_race", "reference_subrace", }, sClass) then
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

-- SPECIES
function handleSizeField2024(rAdd)
	CharBuildDropManager.pickSize(rAdd.nodeChar, CharBuildManager.parseSizesFromString(DB.getValue(rAdd.nodeSource, "size", "")));
end
function handleSpeedField2024(rAdd)
	CharManager.setSpeed(rAdd.nodeChar, DB.getValue(rAdd.nodeSource, "speed", ""):match("%d+"));
end
function handleSpeciesLanguage2024(rAdd)
	local tBase, tOptions, nPicks = CharBuildManager.getSpeciesLanguages2024();

	for _,s in ipairs(tBase) do
		CharManager.addLanguage(rAdd.nodeChar, s);
	end
	CharBuildDropManager.pickLanguage(rAdd.nodeChar, tOptions, nPicks);
end

-- CLASS
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

-- BACKGROUND
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
	CharBuildDropManager.pickLanguage(rAdd.nodeChar, tOptions, nPicks);
end

function addFeature(rAdd)
	if not rAdd then
		return;
	end

	if CharBuildDropManager.checkFeatureSkipAdd(rAdd) then
		return;
	end

	CharBuildDropManager.addFeatureStandard(rAdd);

	if not CharBuildDropManager.checkFeatureSpecialHandling(rAdd) then
		CharBuildDropManager.checkFeatureDescription(rAdd);
	end

	CharBuildDropManager.checkFeatureActions(rAdd);
end
function checkFeatureSkipAdd(rAdd)
	if not rAdd then
		return true;
	end

	if rAdd.sSourceClass == "reference_classfeature" or rAdd.sSourceClass == "reference_classfeaturechoice" then
		return CharClassManager.checkClassFeatureSkipAdd(rAdd);
	elseif rAdd.sSourceClass == "reference_backgroundfeature" then
		return CharBackgroundManager.checkBackgroundFeatureSkipAdd(rAdd);
	elseif rAdd.sSourceClass == "reference_racialtrait" then
		return CharSpeciesManager.checkSpeciesTraitSkipAdd(rAdd);
	elseif rAdd.sSourceClass == "reference_feat" then
		return CharFeatManager.checkFeatSkipAdd(rAdd);
	end

	return false;
end
function addFeatureStandard(rAdd)
	if not rAdd then
		return;
	end

	if CharBuildDropManager.checkFeatureSkipStandardAdd(rAdd) then
		return;
	end

	if rAdd.sSourceClass == "reference_classfeature" or rAdd.sSourceClass == "reference_classfeaturechoice" then
		CharClassManager.addClassFeatureStandard(rAdd);
	elseif rAdd.sSourceClass == "reference_backgroundfeature" then
		CharBackgroundManager.addBackgroundFeatureStandard(rAdd);
	elseif rAdd.sSourceClass == "reference_racialtrait" then
		CharSpeciesManager.addSpeciesTraitStandard(rAdd);
	elseif rAdd.sSourceClass == "reference_feat" then
		CharFeatManager.addFeatStandard(rAdd);
	end
end
function checkFeatureSkipStandardAdd(rAdd)
	if not rAdd then
		return true;
	end

	-- Feats are always added
	if rAdd.sSourceType == "reference_feat" then
		return false;
	end

	-- Skip if not supposed to add standard sub-record
	if rAdd.bSource2024 then
		if CharWizardData.tBuildOptionsNoStandardAdd2024[rAdd.sSourceType] then
			return true;
		end
	else
		if CharWizardData.tBuildOptionsNoStandardAdd2014[rAdd.sSourceType] then
			return true;
		end
	end

	return false;
end
function checkFeatureSpecialHandling(rAdd)
	if not rAdd then
		return true;
	end

	if rAdd.sSourceClass == "reference_classfeature" or rAdd.sSourceClass == "reference_classfeaturechoice" then
		return CharClassManager.checkClassFeatureSpecialHandling(rAdd);
	elseif rAdd.sSourceClass == "reference_backgroundfeature" then
		return CharBackgroundManager.checkBackgroundFeatureSpecialHandling(rAdd);
	elseif rAdd.sSourceClass == "reference_racialtrait" then
		return CharSpeciesManager.checkSpeciesTraitSpecialHandling(rAdd);
	elseif rAdd.sSourceClass == "reference_feat" then
		return CharFeatManager.checkFeatSpecialHandling(rAdd);
	end

	return false;
end

function checkFeatureDescription(rAdd)
	if not rAdd then
		return;
	end
	if rAdd.bWizard then
		if CharBuildDropManager.helperBuildGetText(rAdd) then
			CharBuildDropManager.helperCheckFeatureSpells(rAdd);
		end
		return;
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
	if rAdd.sSourceClass == "reference_classfeature" or rAdd.sSourceClass == "reference_classfeaturechoice" then
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
	if rAdd.sSourceClass == "reference_classfeature" or rAdd.sSourceClass == "reference_classfeaturechoice" then
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
	if rAdd.sSourceClass == "reference_classfeature" or rAdd.sSourceClass == "reference_classfeaturechoice" then
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
	if rAdd.sSourceClass == "reference_classfeature" or rAdd.sSourceClass == "reference_classfeaturechoice" then
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
	if rAdd.sSourceClass == "reference_classfeature" or rAdd.sSourceClass == "reference_classfeaturechoice" then
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
	if rAdd.sSourceClass == "reference_classfeature" or rAdd.sSourceClass == "reference_classfeaturechoice" then
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

	if (#tBase <= 0) and (#tOptions <= 0) then
		return;
	end

	local nPrepared = 1;
	if rAdd.sSourceClass == "reference_backgroundfeature" then
		rAdd.sSpellGroup = CharBackgroundManager.getFeatureSpellGroup(rAdd);
		CharBuildDropManager.helperCheckFeatureSpellsAddPowerGroup(rAdd.nodeChar, rAdd.sSourceText, rAdd.sSpellGroup);
	elseif rAdd.sSourceClass == "reference_racialtrait" then
		rAdd.sSpellGroup = CharSpeciesManager.getTraitSpellGroup(rAdd);
		CharBuildDropManager.helperCheckFeatureSpellsAddPowerGroup(rAdd.nodeChar, rAdd.sSourceText, rAdd.sSpellGroup);
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

	local tPickData = {
		sGroup = rAdd.sSpellGroup,
		bWizard = rAdd.bWizard,
		bSource2024 = rAdd.bSource2024,
		nPrepared = nPrepared,
	};
	CharBuildDropManager.pickSpell(rAdd.nodeChar, tOptions, nPicks, tPickData);
end
function helperCheckFeatureSpellsAddPowerGroup(nodeChar, s, sSpellGroup)
	local tPowerGroupData = { sName = sSpellGroup, };
	local sAbility = s:match("(%a+) is your spellcasting ability");
	if sAbility then
		tPowerGroupData.sAbility = sAbility:lower();
	else
		tPowerGroupData.bChooseSpellAbility = true;
	end
	CharManager.addPowerGroup(nodeChar, tPowerGroupData);
end

function checkFeatureActions(rAdd)
	if not rAdd then
		return false;
	end

	if rAdd.sSourceClass == "reference_classfeature" or rAdd.sSourceClass == "reference_classfeaturechoice" then
		return CharBuildDropManager.checkClassFeatureActions(rAdd);
	elseif rAdd.sSourceClass == "reference_backgroundfeature" then
		return CharBuildDropManager.checkBackgroundFeatureActions(rAdd);
	elseif rAdd.sSourceClass == "reference_racialtrait" then
		return CharBuildDropManager.checkSpeciesTraitActions(rAdd);
	elseif rAdd.sSourceClass == "reference_feat" then
		return CharBuildDropManager.checkFeatActions(rAdd);
	end
	return false;
end
function checkBackgroundFeatureActions(rAdd)
	if not rAdd or ((rAdd.sSourceType or "") == "") then
		return false;
	end

	if rAdd.bSource2024 then
		-- No background features in 2024 records
		return false;
	else
		rAdd.sPowerGroup = CharBackgroundManager.getFeaturePowerGroup(rAdd);
		return CharBuildDropManager.helperCheckActions(rAdd, CharWizardDataAction.parsedata[rAdd.sSourceType]);
	end
end
function checkClassFeatureActions(rAdd)
	if not rAdd or ((rAdd.sSourceType or "") == "") then
		return false;
	end

	rAdd.sPowerGroup = CharClassManager.getFeaturePowerGroup(rAdd);
	if rAdd.bSource2024 then
		return CharBuildDropManager.helperCheckActions(rAdd, CharWizardDataAction.tBuildDataClass2024[rAdd.sSourceType]);
	else
		return CharBuildDropManager.helperCheckActions(rAdd, CharWizardDataAction.parsedata[rAdd.sSourceType]);
	end
end
function checkFeatActions(rAdd)
	if not rAdd or ((rAdd.sSourceType or "") == "") then
		return false;
	end

	if rAdd.bSource2024 then
		rAdd.sPowerGroup = CharFeatManager.getFeatPowerGroup(rAdd);
		return CharBuildDropManager.helperCheckActions(rAdd, CharWizardDataAction.tBuildDataFeat2024[rAdd.sSourceType]);
	else
		-- Feat data not supported in 2014 records
		return false;
	end
end
function checkSpeciesTraitActions(rAdd)
	if not rAdd or ((rAdd.sSourceType or "") == "") then
		return false;
	end

	rAdd.sPowerGroup = CharSpeciesManager.getTraitPowerGroup(rAdd);
	if rAdd.bSource2024 then
		return CharBuildDropManager.helperCheckActions(rAdd, CharWizardDataAction.tBuildDataSpecies2024[rAdd.sSourceType]);
	else
		return CharBuildDropManager.helperCheckActions(rAdd, CharWizardDataAction.parsedata[rAdd.sSourceType]);
	end
end

function helperCheckActions(rAdd, tAction)
	if not rAdd or not rAdd.nodeChar or not rAdd.nodeSource then
		return false;
	end
	if not tAction then
		return false;
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

		-- Pick By Class and Level
		for i = 0,9 do
			local vPicks = tAction.spells["L" .. i];
			if vPicks then
				local tFilters = {
					{ sField = "version", sValue = rAdd.bSource2024 and "2024" or "", },
					{ sField = "level", sValue = tostring(i), },
				};
				local tData = {
					sClassName = tAction.spells.list,
					sGroup = rAdd.sSpellGroup,
					bWizard = rAdd.bWizard,
				};
				if i == 0 then
					tData.sPickType = "cantrip";
				else
					tData.sPickType = "prepared";
				end
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
		if tAction.saveprof.innate then
			for _,v in ipairs(tAction.saveprof.innate) do
				CharManager.addSaveProficiency(rAdd.nodeChar, v);
			end
		end
	end
	return true;
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
		bSource2024 = rAdd.bSource2024,
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
	DB.setValue(nodeNewPower, "version", "string", rActionsAdd.bSource2024 and "2024" or "");

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

	-- Feature Choices not supported in 2014 records
	if rAdd.bSource2024 then
		return CharBuildDropManager.helperCheckChoices(rAdd, CharWizardDataAction.tBuildDataClass2024[rAdd.sSourceType]);
	end
	return false;
end
function helperCheckChoices(rAdd, tAction)
	if not rAdd or not tAction then
		return false;
	end
	if rAdd.bWizard then
		return CharBuildDropManager.helperCheckChoicesWizard(rAdd, CharWizardDataAction.tBuildDataClass2024[rAdd.sSourceType]);
	else
		return CharBuildDropManager.helperCheckChoicesDrop(rAdd, CharWizardDataAction.tBuildDataClass2024[rAdd.sSourceType]);
	end
end
function helperCheckChoicesWizard(rAdd, tAction)
	if not rAdd or not tAction or ((rAdd.sSourceClass or "") ~= "reference_classfeature") then
		return false;
	end
	if tAction.choicetype then
		return CharBuildDropManager.helperCheckChoicesWizardChoiceType(rAdd, tAction);
	end
	if tAction.followon then
		return CharBuildDropManager.helperCheckChoicesWizardFollowOn(rAdd, tAction);
	end
	return false;
end
function helperCheckChoicesWizardChoiceType(rAdd, tAction)
	if not rAdd or not tAction then
		return false;
	end

	-- Get the class name for a class record or a subclass record
	local sClassName = StringManager.trim(DB.getValue(rAdd.nodeClass, "class", ""));
	if sClassName == "" then
		sClassName = DB.getValue(rAdd.nodeClass, "name", "");
	end

	local tFeatureData = {
		sClassName = sClassName,
		sName = rAdd.sSourceName,
		nLevel = DB.getValue(rAdd.nodeSource, "level", 0),
	};

	local tFeature = CharWizardClassManager.getClassFeatureData(tFeatureData);
	if not tFeature then
		return false;
	end

	local tChoices = CharWizardClassManager.collectFeatureChoicesByChoiceType(tFeatureData.sClassName, tAction.choicetype, true);

	local tMatch = {};
	for _,v in pairs(tChoices) do
		local sOption = CharClassManager.getFeatureChoiceDisplayName(v);
		if (sOption ~= "Fighting Style") and StringManager.contains(tFeature.featurechoice or {}, sOption) then
			table.insert(tMatch, v);
		end
	end
	if #tMatch == 0 then
		return false;
	end

	-- NOTE: Disable bWizard for now; since choice details aren't handled in the wizard
	local tData = {};-- { bWizard = rAdd.bWizard, };
	for _,v in ipairs(tMatch) do
		CharClassManager.addClassFeatureChoice(rAdd.nodeChar, DB.getPath(v), tData);
	end

	if tAction.choiceskipadd then
		CharBuildDropManager.helperCheckActions(rAdd, tAction);
		return true;
	end
	return false;
end
function helperCheckChoicesWizardFollowOn(rAdd, tAction)
	if not rAdd or not tAction then
		return false;
	end

	local sClassName = DB.getValue(rAdd.nodeClass, "name", "");
	for k,v in pairs(tAction.followon or {}) do
		if CharManager.hasFeature(rAdd.nodeChar, k) then
			local tChoices = CharWizardClassManager.collectFeatureChoicesByChoiceType(sClassName, v.choicetype, true);
			for _,nodeChoice in ipairs(tChoices) do
				if DB.getValue(nodeChoice, "choicetype", "") == (v.choicetype or "") and
						DB.getValue(nodeChoice, "name", "") == (v.name or "") then
					-- NOTE: Disable bWizard for now; since choice details aren't handled in the wizard
					local tData = {};-- { bWizard = rAdd.bWizard, };
					CharClassManager.addClassFeatureChoice(rAdd.nodeChar, DB.getPath(nodeChoice), tData);
					CharBuildDropManager.helperCheckActions(rAdd, tAction);
					return true;
				end
			end
			break;
		end
	end

	return false;
end
function helperCheckChoicesDrop(rAdd, tAction)
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

	if #tAbilities <= 0 then
		return;
	end
	if #tAbilities == 1 then
		CharManager.addAbilityAdjustment(nodeChar, tAbilities[1], 2);
		return;
	end
	if #tAbilities == 2 then
		CharBuildDropManager.helperAddBackgroundAdjBy2Then1(nodeChar, tAbilities);
		return;
	end

	local tOptions = {
		Interface.getString("char_build_option_selectabilityadjby2then1"),
		Interface.getString("char_build_option_selectabilityadj3by1"),
	};
	local tDialogData = {
		title = Interface.getString("char_build_title_selectabilityadjtype"),
		msg = Interface.getString("char_build_message_selectabilityadjtype"):format(table.concat(tAbilities, ", ")),
		options = tOptions,
		callback = CharBuildDropManager.helperOnInitialAbilityAdjTypeSelect,
		custom = { nodeChar = nodeChar, tAbilities = tAbilities, },
	};
	DialogManager.requestSelectionDialog(tDialogData);
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
	local tDialogData = {
		title = Interface.getString("char_build_title_selectabilityincrease"),
		msg = Interface.getString("char_build_message_selectabilityincrease"):format(1, 2),
		options = tAbilities,
		callback = CharBuildDropManager.helperOnInitialAbilityAdjBy2,
		custom = { nodeChar = nodeChar, tAbilities = tAbilities, },
	};
	DialogManager.requestSelectionDialog(tDialogData);
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

	if #(tData.tAbilities) <= 0 then
		return;
	end
	if #(tData.tAbilities) == 1 then
		CharManager.addAbilityAdjustment(tData.nodeChar, tSelection[1]:lower(), 1);
		return;
	end

	local tDialogData = {
		title = Interface.getString("char_build_title_selectabilityincrease"),
		msg = Interface.getString("char_build_message_selectabilityincrease"):format(1, 1),
		options = tData.tAbilities,
		callback = CharBuildDropManager.helperOnInitialAbilityAdjThen1,
		custom = { nodeChar = tData.nodeChar, },
	};
	DialogManager.requestSelectionDialog(tDialogData);
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
		return;
	end

	local tDialogData = {
		title = Interface.getString("char_build_title_selectabilityincrease"),
		msg = Interface.getString("char_build_message_selectabilityincrease"):format(3, 1),
		options = tAbilities,
		min = 3,
		callback = CharBuildDropManager.helperOnInitialAbilityAdj3By1,
		custom = { nodeChar = nodeChar, },
	};
	DialogManager.requestSelectionDialog(tDialogData);
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

	local tDialogData = {
		title = Interface.getString("char_build_title_selectabilityincrease"),
		msg = Interface.getString("char_build_message_selectabilityincrease"):format(nPicks, tData.nAbilityAdj),
		options = tOptions,
		min = nPicks,
		callback = CharBuildDropManager.onAbilitySelect,
		custom = { nodeChar = nodeChar, nAbilityAdj = tData.nAbilityAdj, nAbilityMax = tData.nAbilityMax },
	};
	DialogManager.requestSelectionDialog(tDialogData);
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

-- Due to Tasha's rules, set up decisions for every ability increase
function pickAbilities2014(nodeChar, tBase, tAbilitySelect)
	local tFinalAbilitySelect = {};
	for sAbility, nAbilityAdj in pairs(tBase) do
		local t = {
			tAbilities = CharBuildDropManager.getDefaultAbilityOptions2014(sAbility),
			nAbilityAdj = nAbilityAdj,
		};
		table.insert(tFinalAbilitySelect, t);
	end
	for _,v in ipairs(tAbilitySelect) do
		v.tAbilities = CharBuildDropManager.getDefaultAbilityOptions2014();
		table.insert(tFinalAbilitySelect, v);
	end
	if #tFinalAbilitySelect > 0 then
		CharBuildDropManager.helperPickAbilities2014(nodeChar, tFinalAbilitySelect);
	end
end
function helperPickAbilities2014(nodeChar, tAbilitySelect, bFront)
	if #tAbilitySelect == 0 then
		return;
	end

	local nPicks = tAbilitySelect[1].nPicks or 1;
	local nAbilityAdj = tAbilitySelect[1].nAbilityAdj or 1;

	local tDialogData = {
		title = Interface.getString("char_build_title_selectabilityincrease"),
		msg = Interface.getString("char_build_message_selectabilityincrease"):format(nPicks, nAbilityAdj),
		options = tAbilitySelect[1].tAbilities,
		min = nPicks,
		callback = CharBuildDropManager.onAbilitiesSelect2014,
		custom = { nodeChar = nodeChar, tAbilitySelect = tAbilitySelect, },
	};
	DialogManager.requestSelectionDialog(tDialogData, bFront);
end
function onAbilitiesSelect2014(tSelection, tData)
	local rAbilitySelect = tData.tAbilitySelect[1];
	for _,sAbility in ipairs(tSelection) do
		CharManager.addAbilityAdjustment(tData.nodeChar, sAbility, rAbilitySelect.nAbilityAdj or 1, rAbilitySelect.nAbilityMax);

		if rAbilitySelect.bSaveProfAdd then
			local sAbilityLower = StringManager.simplify(sAbility);
			if StringManager.contains(DataCommon.abilities, sAbilityLower) then
				DB.setValue(tData.nodeChar, "abilities." .. sAbilityLower .. ".saveprof", "number", 1);
				ChatManager.SystemMessageResource("char_abilities_message_saveadd", sAbility, DB.getValue(tData.nodeChar, "name", ""));
			end
		end
	end

	table.remove(tData.tAbilitySelect, 1);
	if #(tData.tAbilitySelect) > 0 then
		for _,vSelect in ipairs(tData.tAbilitySelect) do
			local tNewAbilities = {};
			for _,vAbility in ipairs(vSelect.tAbilities) do
				if not StringManager.contains(tSelection, vAbility.text) then
					table.insert(tNewAbilities, vAbility);
				end
			end
			vSelect.tAbilities = tNewAbilities;
		end
		CharBuildDropManager.helperPickAbilities2014(tData.nodeChar, tData.tAbilitySelect, true);
	end
end
function getDefaultAbilityOptions2014(sSelectedAbility)
	local tOptions = {};
	for _,sAbility in ipairs(DataCommon.abilities) do
		if (sSelectedAbility or "") == sAbility then
			table.insert(tOptions, { text = StringManager.capitalize(sAbility), selected = true, });
		else
			table.insert(tOptions, { text = StringManager.capitalize(sAbility), });
		end
	end
	return tOptions;
end

function pickASIOrFeat(nodeChar, bSource2024)
	local tOptions = {
		Interface.getString("char_build_option_asi"),
		Interface.getString("char_build_option_feat"),
	};
	local tDialogData = {
		title = Interface.getString("char_build_title_asiorfeat"),
		msg = Interface.getString("char_build_message_asiorfeat"),
		options = tOptions,
		callback = CharBuildDropManager.helperOnASIOrFeatSelect,
		custom = { nodeChar = nodeChar, bSource2024 = bSource2024, },
	};
	DialogManager.requestSelectionDialog(tDialogData);
end
function helperOnASIOrFeatSelect(tSelection, tData)
	if not tSelection or not tSelection[1] then
		return;
	end
	if tSelection[1] == Interface.getString("char_build_option_asi") then
		CharBuildDropManager.pickAbilityAdjust(tData.nodeChar, { bSource2024 = tData.bSource2024, bFront = true, });
	else
		CharBuildDropManager.pickFeat(tData.nodeChar, {}, 1, { bSource2024 = tData.bSource2024, bFront = true, });
	end
end
function pickAbilityAdjust(nodeChar, tData)
	local tOptions = {
		Interface.getString("char_build_option_selectabilityadjby2"),
		Interface.getString("char_build_option_selectabilityadj2by1"),
	};
	local tDialogData = {
		title = Interface.getString("char_build_title_selectabilityadjtype"),
		msg = Interface.getString("char_build_message_selectabilityadjtype"):format("Any"),
		options = tOptions,
		callback = CharBuildDropManager.helperOnAbilityAdjTypeSelect,
		custom = {
			nodeChar = nodeChar,
			bSource2024 = tData and tData.bSource2024,
		},
	};
	DialogManager.requestSelectionDialog(tDialogData, tData and tData.bFront);
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
function helperAbilityAdjBy2(nodeChar)
	local nAbilityMax = 20;
	local tDialogData = {
		title = Interface.getString("char_build_title_selectabilityincrease"),
		msg = Interface.getString("char_build_message_selectabilityincrease"):format(1, 2),
		options = CharBuildDropManager.getAbilityOptions(nodeChar, nAbilityMax),
		callback = CharBuildDropManager.helperOnAbilityAdj,
		custom = { nodeChar = nodeChar, nAbilityAdj = 2, },
	};
	DialogManager.requestSelectionDialog(tDialogData);
end
function helperAbilityAdj2By1(nodeChar)
	local nAbilityMax = 20;
	local tDialogData = {
		title = Interface.getString("char_build_title_selectabilityincrease"),
		msg = Interface.getString("char_build_message_selectabilityincrease"):format(2, 1),
		options = CharBuildDropManager.getAbilityOptions(nodeChar, nAbilityMax),
		min = 2,
		callback = CharBuildDropManager.helperOnAbilityAdj,
		custom = { nodeChar = nodeChar, nAbilityAdj = 1, },
	};
	DialogManager.requestSelectionDialog(tDialogData);
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

	local tDialogData = {
		title = Interface.getString("char_build_title_selectsize"),
		msg = Interface.getString("char_build_message_selectsize"),
		options = tSizes,
		callback = CharBuildDropManager.onSizeSelect,
		custom = { nodeChar = nodeChar },
	};
	DialogManager.requestSelectionDialog(tDialogData);
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

	if #(tOptions or {}) == 0 then
		tOptions = CharBuildDropManager.getSaveProficiencyOptions(nodeChar);
	else
		tOptions = CharBuildDropManager.helperGetSaveProficiencyOptionsFilter(nodeChar, tOptions);
	end

	if nPicks >= #tOptions then
		for _,v in ipairs(tOptions) do
			CharManager.addSaveProficiency(nodeChar, v.text);
		end
		return;
	end

	local tDialogData = {
		title = Interface.getString("char_build_title_selectprofs"),
		msg = Interface.getString("char_build_message_selectprofs"):format(nPicks or 1),
		options = tOptions,
		min = nPicks or 1,
		callback = CharBuildDropManager.onSaveSelect,
		custom = { nodeChar = nodeChar },
	};
	DialogManager.requestSelectionDialog(tDialogData);
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

	local tOptions = {};
	for k,_ in pairs(DataCommon.abilities) do
		table.insert(tOptions, { text = StringManager.capitalize(k), });
	end
	return CharBuildDropManager.helperGetSaveProficiencyOptionsFilter(nodeChar, tOptions);
end
function helperGetSaveProficiencyOptionsFilter(nodeChar, tOptions)
	local tFinalOptions = {};
	for _,v in ipairs(tOptions) do
		if type(v) == "string" then
			if not CharManager.hasSaveProficiency(nodeChar, v) then
				table.insert(tFinalOptions, { text = StringManager.capitalize(v), });
			end
		elseif type(v) == "table" then
			if not CharManager.hasSaveProficiency(nodeChar, v.text) then
				table.insert(tFinalOptions, v);
			end
		end
	end
	return tFinalOptions;
end

function pickSkill(nodeChar, tOptions, nPicks, tData)
	nPicks = nPicks or 1;
	if nPicks <= 0 then
		return;
	end

	if #(tOptions or {}) == 0 then
		tOptions = CharBuildDropManager.getSkillProficiencyOptions(nodeChar);
	else
		tOptions = CharBuildDropManager.helperGetSkillProficiencyOptionsFilterAndLink(nodeChar, tOptions);
	end

	if nPicks >= #tOptions then
		for _,v in ipairs(tOptions) do
			CharManager.addSkillProficiency(nodeChar, v.text);
		end
		return;
	end

	local tDialogData = {
		title = Interface.getString("char_build_title_selectprofs"),
		msg = Interface.getString("char_build_message_selectprofs"):format(nPicks or 1),
		options = tOptions,
		min = nPicks or 1,
		callback = CharBuildDropManager.onSkillSelect,
		custom = { nodeChar = nodeChar, bAddExpertise = tData and tData.bAddExpertise, },
	};
	DialogManager.requestSelectionDialog(tDialogData);
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

	local tOptions = {};
	for k,_ in pairs(DataCommon.skilldata) do
		table.insert(tOptions, k);
	end
	table.sort(tOptions);
	return CharBuildDropManager.helperGetSkillProficiencyOptionsFilterAndLink(nodeChar, tOptions);
end
function helperGetSkillProficiencyOptionsFilterAndLink(nodeChar, tOptions)
	local tFinalOptions = {};
	for _,v in ipairs(tOptions) do
		if type(v) == "string" then
			if not CharManager.hasSkillProficiency(nodeChar, v) then
				table.insert(tFinalOptions, { text = v, });
			end
		elseif type(v) == "table" then
			if not CharManager.hasSkillProficiency(nodeChar, v.text) then
				table.insert(tFinalOptions, v);
			end
		end
	end

	CharBuildDropManager.helperGetSkillOptionsLinks(tFinalOptions);
	return tFinalOptions;
end
function helperGetSkillOptionsLinks(tOptions)
	for k,v in ipairs(tOptions) do
		local tSkill;
		if type(v) == "string" then
			tSkill = { text = v, linkclass = "", linkrecord = "", };
		elseif type(v) == "table" then
			tSkill = v;
		end
		local nodeSkill = RecordManager.findRecordByStringI("skill", "name", tSkill.text);
		if nodeSkill then
			tSkill.linkclass = "reference_skill";
			tSkill.linkrecord = DB.getPath(nodeSkill);
		end
		tOptions[k] = tSkill;
	end
end

function pickSkillExpertise(nodeChar, tOptions, nPicks)
	nPicks = nPicks or 1;
	if nPicks <= 0 then
		return;
	end

	if #(tOptions or {}) == 0 then
		tOptions = CharBuildDropManager.getSkillExpertiseOptions(nodeChar);
	else
		tOptions = CharBuildDropManager.helperGetSkillExpertiseOptionsFilterAndLink(nodeChar, tOptions);
	end

	if nPicks >= #tOptions then
		for _,v in ipairs(tOptions) do
			CharManager.increaseSkillProficiency(nodeChar, v.text, 2);
		end
		return;
	end

	local tDialogData = {
		title = Interface.getString("char_build_title_selectexpertises"),
		msg = Interface.getString("char_build_message_selectexpertises"):format(nPicks),
		options = tOptions,
		min = nPicks,
		callback = CharBuildDropManager.onSkillExpertiseSelect,
		custom = { nodeChar = nodeChar, },
	};
	DialogManager.requestSelectionDialog(tDialogData);
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

	local tOptions = {};
	for k,_ in pairs(DataCommon.skilldata) do
		table.insert(tOptions, k);
	end
	table.sort(tOptions);
	return CharBuildDropManager.helperGetSkillExpertiseOptionsFilterAndLink(nodeChar, tOptions);
end
function helperGetSkillExpertiseOptionsFilterAndLink(nodeChar, tOptions)
	local tFinalOptions = {};
	for _,v in ipairs(tOptions) do
		if type(v) == "string" then
			local nodeCharSkill = CharManager.getSkillRecord(nodeChar, v);
			if nodeCharSkill and (DB.getValue(nodeCharSkill, "prof", 0) == 1) then
				table.insert(tFinalOptions, { text = v, });
			end
		elseif type(v) == "table" then
			local nodeCharSkill = CharManager.getSkillRecord(nodeChar, v.text);
			if nodeCharSkill and (DB.getValue(nodeCharSkill, "prof", 0) == 1) then
				table.insert(tFinalOptions, v);
			end
		end
	end

	CharBuildDropManager.helperGetSkillOptionsLinks(tFinalOptions);
	return tFinalOptions;
end

function pickSkillIncrease(nodeChar, tOptions, nPicks, tData)
	nPicks = nPicks or 1;
	if nPicks <= 0 then
		return;
	end

	if #(tOptions or {}) == 0 then
		tOptions = CharBuildDropManager.getSkillIncreaseOptions(nodeChar);
	else
		tOptions = CharBuildDropManager.helperGetSkillIncreaseOptionsFilterAndLink(nodeChar, tOptions);
	end

	if nPicks >= #tOptions then
		for _,v in ipairs(tOptions) do
			CharManager.increaseSkillProficiency(nodeChar, v.text);
		end
		return;
	end

	local tDialogData = {
		title = Interface.getString("char_build_title_selectprofincreases"),
		msg = Interface.getString("char_build_message_selectprofincreases"):format(nPicks),
		options = tOptions,
		min = nPicks,
		callback = CharBuildDropManager.onSkillIncreaseSelect,
		custom = { nodeChar = nodeChar, nIncrease = tData and tData.nIncrease, },
	};
	DialogManager.requestSelectionDialog(tDialogData);
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

	local tOptions = {};
	for k,_ in pairs(DataCommon.skilldata) do
		table.insert(tOptions, k);
	end
	table.sort(tOptions);
	return CharBuildDropManager.helperGetSkillIncreaseOptionsFilterAndLink(nodeChar, tOptions);
end
function helperGetSkillIncreaseOptionsFilterAndLink(nodeChar, tOptions)
	local tFinalOptions = {};
	for _,v in ipairs(tOptions) do
		if type(v) == "string" then
			local nodeCharSkill = CharManager.getSkillRecord(nodeChar, v);
			if not nodeCharSkill or (DB.getValue(nodeCharSkill, "prof", 0) ~= 2) then
				table.insert(tFinalOptions, { text = v, });
			end
		elseif type(v) == "table" then
			local nodeCharSkill = CharManager.getSkillRecord(nodeChar, v.text);
			if not nodeCharSkill or (DB.getValue(nodeCharSkill, "prof", 0) ~= 2) then
				table.insert(tFinalOptions, v);
			end
		end
	end

	CharBuildDropManager.helperGetSkillOptionsLinks(tFinalOptions);
	return tFinalOptions;
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

	local tDialogData = {
		title = Interface.getString("char_build_title_selectprofs"),
		msg = Interface.getString("char_build_message_selectprofs"):format(nPicks),
		options = tOptions,
		min = nPicks or 1,
		callback = CharBuildDropManager.onToolProfSelect,
		custom = { nodeChar = nodeChar, },
	};
	DialogManager.requestSelectionDialog(tDialogData);
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

	local tDialogData = {
		title = Interface.getString("char_build_title_selectprofs"),
		msg = Interface.getString("char_build_message_selectprofs"):format(nPicks),
		options = tOptions,
		min = nPicks,
		callback = CharBuildDropManager.onProficiencySelect,
		custom = { nodeChar = nodeChar, sType = sType, },
	};
	DialogManager.requestSelectionDialog(tDialogData);
end
function onProficiencySelect(tSelection, tData)
	for _,s in ipairs(tSelection) do
		CharManager.addProficiency(tData.nodeChar, tData.sType, s);
	end
end

function pickFeat(nodeChar, tOptions, nPicks, tData)
	nPicks = nPicks or 1;
	if nPicks <= 0 then
		return;
	end

	if #(tOptions or {}) == 0 then
		tOptions = CharBuildDropManager.getFeatOptions(nodeChar, tData);
	else
		tOptions = CharBuildDropManager.helperGetFeatOptionsFilter(nodeChar, tOptions);
	end

	if nPicks >= #tOptions then
		for _,v in ipairs(tOptions) do
			CharManager.addFeat(nodeChar, v.text, tData);
		end
		return;
	end

	local tDialogData = {
		title = Interface.getString("char_build_title_selectfeats"),
		msg = Interface.getString("char_build_message_selectfeats"):format(nPicks),
		options = tOptions,
		min = nPicks,
		callback = CharBuildDropManager.onFeatSelect,
		custom = { nodeChar = nodeChar, bSource2024 = tData and tData.bSource2024, bWizard = tData and tData.bWizard, },
	};
	DialogManager.requestSelectionDialog(tDialogData, tData and tData.bFront);
end
function onFeatSelect(tSelection, tData)
	for _,s in ipairs(tSelection) do
		CharManager.addFeat(tData.nodeChar, s, tData);
	end
end
function getFeatOptions(nodeChar, tData)
	if not nodeChar then
		return {};
	end

	local tFilters = {
		{ sField = "version", sValue = tData and tData.bSource2024 and "2024" or "", },
	};
	local tOptions = RecordManager.getRecordOptionsByFilter("feat", tFilters, true);
	return CharBuildDropManager.helperGetFeatOptionsFilter(nodeChar, tOptions);
end
function helperGetFeatOptionsFilter(nodeChar, tOptions)
	local tFinalOptions = {};
	for _,v in ipairs(tOptions) do
		if type(v) == "string" then
			local nodeFeat = CharManager.getFeatRecord(nodeChar, v);
			if not nodeFeat or (DB.getValue(nodeFeat, "repeatable", 0) == 1) then
				table.insert(tFinalOptions, { text = v, });
			end
		elseif type(v) == "table" then
			local nodeFeat = CharManager.getFeatRecord(nodeChar, v.text);
			if not nodeFeat or (DB.getValue(nodeFeat, "repeatable", 0) == 1) then
				table.insert(tFinalOptions, v);
			end
		end
	end
	return tFinalOptions;
end

function pickLanguage(nodeChar, tOptions, nPicks, tData)
	nPicks = nPicks or 1;
	if nPicks <= 0 then
		return;
	end

	if #(tOptions or {}) == 0 then
		tOptions = CharBuildDropManager.getLanguageOptions(nodeChar);
	else
		tOptions = CharBuildDropManager.helperGetLanguageOptionsFilter(nodeChar, tOptions);
	end

	if nPicks >= #tOptions then
		for _,v in ipairs(tOptions) do
			CharManager.addLanguage(nodeChar, v.text, tData);
		end
		return;
	end

	local tDialogData = {
		title = Interface.getString("char_build_title_selectlanguages"),
		msg = Interface.getString("char_build_message_selectlanguages"):format(nPicks),
		options = tOptions,
		min = nPicks,
		callback = CharBuildDropManager.onLanguageSelect,
		custom = { nodeChar = nodeChar, bSource2024 = tData and tData.bSource2024, bWizard = tData and tData.bWizard, },
	};
	DialogManager.requestSelectionDialog(tDialogData);
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
	for _,v in ipairs(tOptions) do
		if type(v) == "string" then
			if not CharManager.hasLanguage(nodeChar, v) then
				table.insert(tFilteredOptions, { text = StringManager.capitalizeAll(v) });
			end
		elseif type(v) == "table" then
			if not CharManager.hasLanguage(nodeChar, v.text) then
				table.insert(tFilteredOptions, v);
			end
		end
	end
	return tFilteredOptions;
end

function pickSpellGroupAbility(rAdd, fnCallback)
	local tDialogData = {
		options = { "Intelligence", "Wisdom", "Charisma", },
		callback = CharBuildDropManager.onSpellGroupAbilitySelect,
		custom = { rAdd = rAdd, fnCallback = fnCallback },
	};
	if rAdd.bSpellGroupAbilityIncrease then
		tDialogData.title = Interface.getString("char_build_title_selectabilityincrease");
		tDialogData.msg = Interface.getString("char_build_message_selectabilityincrease"):format(1, 1);
	else
		tDialogData.title = Interface.getString("char_build_title_selectspellability");
		tDialogData.msg = Interface.getString("char_build_message_selectspellability");
	end
	DialogManager.requestSelectionDialog(tDialogData);
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

	local tDialogData = {
		title = Interface.getString("char_build_title_selectspellability"),
		msg = Interface.getString("char_build_message_selectspellability"),
		options = { "Intelligence", "Wisdom", "Charisma", },
		callback = CharBuildDropManager.onSpellGroupAbilityChoice,
		custom = { nodePowerGroup = nodePowerGroup, },
	};
	DialogManager.requestSelectionDialog(tDialogData);
end
function onSpellGroupAbilityChoice(tSelection, tData)
	if not tSelection or not tSelection[1] or not tData or not tData.nodePowerGroup then
		return;
	end
	DB.setValue(tData.nodePowerGroup, "stat", "string", tSelection[1]:lower());
end

function getSpellOptionsByFilter(tFilters, tData)
	local tOptions = RecordManager.getRecordOptionsByFilter("spell", tFilters);

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

	return tOptions;
end
function pickSpellByFilter(rAdd, tFilters, nPicks, tData)
	if not rAdd then
		return;
	end

	local tOptions = CharBuildDropManager.getSpellOptionsByFilter(tFilters, tData);

	local tPickData = {
		sGroup = rAdd.sSpellGroup,
		bWizard = rAdd.bWizard,
		bSource2024 = rAdd.bSource2024,
		sPickType = tData and tData.sPickType,
		nPrepared = tData and tData.nPrepared,
		bFront = tData and tData.bFront,
	};
	if tData and tData.fnCallback then
		tPickData.fnCallback = tData.fnCallback;
		tPickData.tCallbackData = tData;
	end
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
		tDialogOptions = CharBuildDropManager.helperGetSpellOptionsFilter(nodeChar, tData.sGroup, tOptions, tData);
	end

	if nPicks >= #tDialogOptions then
		for _,v in ipairs(tDialogOptions) do
			CharManager.addSpell(nodeChar, { sRecord = v.linkrecord, sGroup = tData.sGroup, bSource2024 = tData.bSource2024, nPrepared = tData.nPrepared, });
		end
		if tData and tData.fnCallback then
			tData.fnCallback(tData.tCallbackData);
		end
		return;
	end

	-- Add Level prefixes and sort
	for _,v in ipairs(tDialogOptions) do
		local nodeSpell = DB.findNode(v.linkrecord);
		if nodeSpell then
			v.text = string.format("[L%d] %s", DB.getValue(nodeSpell, "level", 0), v.text);
		end
	end
	table.sort(tDialogOptions, function(a,b) return a.text < b.text; end);

	local tLookup = {};
	for _,v in ipairs(tDialogOptions) do
		tLookup[v.text] = v.linkrecord;
	end
	local tDialogData = {
		title = Interface.getString("char_build_title_selectspells"),
		msg = Interface.getString("char_build_message_selectspells"):format(nPicks),
		min = nPicks,
		options = tDialogOptions,
		callback = CharBuildDropManager.onSpellSelect,
		custom = {
			nodeChar = nodeChar,
			sGroup = tData.sGroup,
			bSource2024 = tData.bSource2024,
			nPrepared = tData.nPrepared,
			tLookup = tLookup,
		},
	};
	if tData and tData.fnCallback then
		tDialogData.custom.fnCallback = tData.fnCallback;
		tDialogData.custom.tCallbackData = tData.tCallbackData;
	end
	if tData and ((tData.sPickType or "") == "cantrip") then
		tDialogData.title = Interface.getString("char_build_title_selectspellscantrip");
		tDialogData.msg = Interface.getString("char_build_message_selectspellscantrip"):format(nPicks);
	elseif tData and ((tData.sPickType or "") == "prepared") then
		tDialogData.title = Interface.getString("char_build_title_selectspellsprepared");
		tDialogData.msg = Interface.getString("char_build_message_selectspellsprepared"):format(nPicks);
		tDialogData.custom.nPrepared = tDialogData.custom.nPrepared or 1;
	elseif tData and ((tData.sPickType or "") == "known") then
		tDialogData.title = Interface.getString("char_build_title_selectspellsknown");
		tDialogData.msg = Interface.getString("char_build_message_selectspellsknown"):format(nPicks);
	end
	DialogManager.requestSelectionDialog(tDialogData, tData.bFront);
end
function onSpellSelect(tSelection, tData)
	for _,s in ipairs(tSelection) do
		CharManager.addSpell(tData.nodeChar, { sRecord = tData.tLookup[s], sGroup = tData.sGroup, bSource2024 = tData.bSource2024, nPrepared = tData.nPrepared, });
	end
	if tData.fnCallback then
		tData.fnCallback(tData.tCallbackData);
	end
end
function helperGetSpellOptionsFilter(nodeChar, sGroup, tOptions, tData)
	local tFilteredOptions = {};
	for _,v in ipairs(tOptions) do
		if type(v) == "string" then
			if not CharManager.hasGroupPower(nodeChar, sGroup, v) then
				local tFilters = {
					{ sField = "name", sValue = v, bIgnoreCase = true, },
					{ sField = "version", sValue = tData and tData.bSource2024 and "2024" or "", },
				};
				local nodeSpell = RecordManager.findRecordByFilter("spell", tFilters);
				if nodeSpell then
					table.insert(tFilteredOptions, { text = v, linkclass = "power", linkrecord = DB.getPath(nodeSpell), });
				end
			end
		elseif type(v) == "table" then
			if not CharManager.hasGroupPower(nodeChar, sGroup, v.text) then
				table.insert(tFilteredOptions, v);
			end
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
	local tDialogData = {
		title = Interface.getString("char_build_title_selectclassfeaturechoices"),
		msg = Interface.getString("char_build_message_selectclassfeaturechoices"):format(nPicks),
		min = nPicks,
		options = tOptions,
		callback = CharBuildDropManager.onClassFeatureChoiceSelect,
		custom = { nodeChar = nodeChar, bWizard = tData.bWizard, bSource2024 = tData.bSource2024, tLookup = tLookup},
	};
	DialogManager.requestSelectionDialog(tDialogData);
end
function onClassFeatureChoiceSelect(tSelection, tData)
	for _,s in ipairs(tSelection) do
		local sRecord = tData.tLookup[s];
		if sRecord then
			CharClassManager.addClassFeatureChoice(tData.nodeChar, sRecord, { bWizard = tData.bWizard, bSource2024 = tData.bSource2024, });
		end
	end
end
