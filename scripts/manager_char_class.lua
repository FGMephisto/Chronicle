-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

SPELLCASTING_SLOT_LEVELS = 9;
PACTMAGIC_SLOT_LEVELS = 5;

function addClass(nodeChar, sRecord, tData)
	local rAdd = CharBuildDropManager.helperBuildAddStructure(nodeChar, "reference_class", sRecord, tData);
	CharClassManager.helperAddClassMain(rAdd);
end
function addClassProficiency(nodeChar, sRecord, tData)
	local rAdd = CharBuildDropManager.helperBuildAddStructure(nodeChar, "reference_classproficiency", sRecord, tData);
	-- NOTE: Special handling for skills if class gets Expertise at L1
	rAdd.bAddExpertise = tData and tData.bAddExpertise;
	CharClassManager.helperAddClassProficiencyMain(rAdd);
end
function addClassFeature(nodeChar, sRecord, tData)
	local rAdd = CharBuildDropManager.helperBuildAddStructure(nodeChar, "reference_classfeature", sRecord, tData);
	CharClassManager.helperAddClassFeatureMain(rAdd);
end
function addClassFeatureChoice(nodeChar, sRecord, tData)
	local rAdd = CharBuildDropManager.helperBuildAddStructure(nodeChar, "reference_classfeaturechoice", sRecord, tData);
	CharClassManager.helperAddClassFeatureChoiceMain(rAdd);
end

function getSubclassOptions(nodeClass)
	if not nodeClass then
		return {};
	end

	local sClassName = DB.getValue(nodeClass, "name", "");
	local bIs2024 = (DB.getValue(nodeClass, "version", "") == "2024");

	local tSpecFilters = {
		{ sField = "class", sValue = sClassName, bIgnoreCase = true, },
		{ sField = "version", sValue = (bIs2024 and "2024" or ""), },
	};
	if bIs2024 then
		return RecordManager.getRecordOptionsByFilter("class_specialization", tSpecFilters, true);
	end

	local tOptions = {};
	RecordManager.callForEachRecordByFilter("class_specialization", tSpecFilters, CharClassManager.helperGetClassExternalSpecOption, tOptions);
	local tClassFilters = {
		{ sField = "name", sValue = sClassName, bIgnoreCase = true, },
		{ sField = "version", sValue = (bIs2024 and "2024" or ""), },
	};
	RecordManager.callForEachRecordByFilter("class", tClassFilters, CharClassManager.helperGetClassEmbeddedSpecOption, tOptions);
	table.sort(tOptions, function(a,b) return a.text < b.text; end);
	return tOptions;
end
function helperGetClassExternalSpecOption(nodeSubclass, tOptions)
	local sSpecName = StringManager.trim(DB.getValue(nodeSubclass, "name", ""));
	if sSpecName ~= "" then
		table.insert(tOptions, { text = sSpecName, linkclass = "reference_class_specialization", linkrecord = DB.getPath(nodeSubclass) });
	end
end
function helperGetClassEmbeddedSpecOption(nodeClass, tOptions)
	for _,nodeSubclass in ipairs(DB.getChildList(nodeClass, "abilities")) do
		local sSpecName = StringManager.trim(DB.getValue(nodeSubclass, "name", ""));
		if sSpecName ~= "" then
			table.insert(tOptions, { text = sSpecName, linkclass = "reference_classability", linkrecord = DB.getPath(nodeSubclass) });
		end
	end
end

function getSubclassLevel(nodeClass)
	if not nodeClass then
		return 0;
	end

	if type(nodeClass) == "string" then
		nodeClass = DB.findNode(nodeClass);
	end

	local bIs2024 = (DB.getValue(nodeClass, "version", "") == "2024");
	if bIs2024 then
		return 3;
	end

	local sClassName = DB.getValue(nodeClass, "name", "");
	local nodeClass = RecordManager.findRecordByStringI("class", "name", sClassName);
	if not nodeClass then
		return 0;
	end

	for _,v in ipairs(DB.getChildList(nodeClass, "features")) do
		if (DB.getValue(v, "specializationchoice", 0) == 1) then
			local nLevel = DB.getValue(v, "level", 0);
			if nLevel > 0 then
				return nLevel;
			end
		end
	end
	return 0;
end
function getSubclassRecord(nodeClass, sSubclass)
	local tSubclassOptions = CharClassManager.getSubclassOptions(nodeClass);
	local sSubclassLower = StringManager.simplify(sSubclass) or "";
	for _,vSubclass in ipairs(tSubclassOptions) do
		if StringManager.simplify(vSubclass.text) == sSubclassLower then
			return vSubclass;
		end
	end
	return nil;
end

function getClassName(rAdd)
	return DB.getValue(rAdd.nodeSource, "name", "");
end
function getClassSpellGroup(rAdd)
	return Interface.getString("char_spell_powergroup"):format(CharClassManager.getClassName(rAdd));
end

function helperAddClassMain(rAdd)
	if not rAdd then
		return;
	end

	-- Notification
	ChatManager.SystemMessageResource("char_abilities_message_classadd", rAdd.sSourceName, rAdd.sCharName);

	-- Store caster levels before level and feature additions 
	-- in order to calc spell slot upgrades correctly
	CharClassManager.helperAddClassCalcCasterLevel(rAdd);

	CharClassManager.helperAddClassLevel(rAdd);
	CharClassManager.helperAddClassHP(rAdd);
	CharClassManager.helperAddClassProficiencies(rAdd);
	CharClassManager.helperAddClassFeatures(rAdd);
	CharClassManager.helperAddClassUpdateSpellSlots(rAdd);

	CharClassManager.helperAddClassSpells(rAdd);

	if not rAdd.bWizard then
		CharClassManager.helperAddSubclassChoice(rAdd);
	end
end
function helperAddClassCalcCasterLevel(rAdd)
	rAdd.nCharCasterLevel = CharClassManager.calcSpellcastingLevel(rAdd.nodeChar); 
	rAdd.nCharPactMagicLevel = CharClassManager.calcPactMagicLevel(rAdd.nodeChar);
end
function helperAddClassLevel(rAdd)
	-- Check to see if the character already has this class; or create a new class entry
	rAdd.nodeCharClass = CharManager.getClassRecord(rAdd.nodeChar, rAdd.sSourceName, rAdd.bSource2024);
	if not rAdd.nodeCharClass then
		local nodeClassList = DB.createChild(rAdd.nodeChar, "classes");
		if not nodeClassList then
			return;
		end
		rAdd.nodeCharClass = DB.createChild(nodeClassList);
		rAdd.bNewCharClass = true;
	end
	
	-- Any way you get here, overwrite or set the class reference link and record version with the most current
	DB.setValue(rAdd.nodeCharClass, "shortcut", "windowreference", "reference_class", DB.getPath(rAdd.nodeSource));
	DB.setValue(rAdd.nodeCharClass, "version", "string", DB.getValue(rAdd.nodeSource, "version", ""));
	
	-- Add basic class information
	if rAdd.bNewCharClass then
		DB.setValue(rAdd.nodeCharClass, "name", "string", rAdd.sSourceName);
		rAdd.nCharClassLevel = 1;
	else
		rAdd.nCharClassLevel = DB.getValue(rAdd.nodeCharClass, "level", 0) + 1;
	end
	DB.setValue(rAdd.nodeCharClass, "level", "number", rAdd.nCharClassLevel);
	
	-- Calculate total level
	rAdd.nCharLevel = CharManager.getLevel(rAdd.nodeChar);
end
function helperAddClassHP(rAdd)
	-- Translate Hit Die
	local nHDMult = 1;
	local nHDSides = 6;
	local sHD = DB.getText(rAdd.nodeSource, "hp.hitdice.text", "");
	local sMult, sSides = sHD:match("(%d?)[dD](%d+)");
	if sMult and sSides then
		nHDMult = tonumber(sMult) or 1;
		nHDSides = tonumber(sSides) or 6;
	else
		ChatManager.SystemMessageResource("char_error_addclasshd");
	end
	if rAdd.bNewCharClass then
		DB.setValue(rAdd.nodeCharClass, "hddie", "dice", string.format("%sd%s", nHDMult, nHDSides));
	end

	-- Add hit points based on level added
	local nHP = DB.getValue(rAdd.nodeChar, "hp.total", 0);
	local nConBonus = DB.getValue(rAdd.nodeChar, "abilities.constitution.bonus", 0);
	if rAdd.nCharLevel == 1 then
		local nAddHP = math.max((nHDMult * nHDSides) + nConBonus, 1);
		nHP = nHP + nAddHP;

		ChatManager.SystemMessageResource("char_abilities_message_hpaddmax", rAdd.sSourceName, rAdd.sCharName, nAddHP);
	else
		local nAddHP = math.max(math.floor(((nHDMult * (nHDSides + 1)) / 2) + 0.5) + nConBonus, 1);
		nHP = nHP + nAddHP;

		ChatManager.SystemMessageResource("char_abilities_message_hpaddavg", rAdd.sSourceName, rAdd.sCharName, nAddHP);
	end
	DB.setValue(rAdd.nodeChar, "hp.total", "number", nHP);

	-- Special hit point level up handling
	-- 2024/2014 - PHB - Species - Dwarf - Dwarven Toughness
	if CharManager.hasTrait(rAdd.nodeChar, CharManager.TRAIT_DWARVEN_TOUGHNESS) then
		CharSpeciesManager.applyDwarvenToughness(rAdd.nodeChar);
	end
	-- 2024/2014 - PHB - Class - Sorcerer - Draconic Resilience
	if CharManager.hasFeature(rAdd.nodeChar, CharManager.FEATURE_DRACONIC_RESILIENCE) then
		local sClassNameLower = StringManager.simplify(DB.getValue(rAdd.nodeCharClass, "name", ""));
		if sClassNameLower == CharManager.CLASS_SORCERER then
			CharClassManager.applyDraconicResilience(rAdd.nodeChar);
		end
	end
	-- 2024/2014 - PHB - Feat - Tough
	if CharManager.hasFeat(rAdd.nodeChar, CharManager.FEAT_TOUGH) then
		CharFeatManager.applyTough(rAdd.nodeChar);
	end
end
function helperAddClassProficiencies(rAdd)
	if not rAdd.bNewCharClass then
		return;
	end

	-- NOTE: Special handling for skills if class gets Expertise at L1
	local bAddExpertise = false;
	if rAdd.nCharClassLevel == 1 then
		for _,node in ipairs(CharClassManager.helperGetClassBaseFeatures(rAdd)) do
			if StringManager.simplify(DB.getValue(node, "name", "")) == "expertise" then
				rAdd.bSkipExpertise = true;
				bAddExpertise = true;
				break;
			end
		end
	end
	
	if rAdd.nCharLevel == 1 then
		for _,v in ipairs(DB.getChildList(rAdd.nodeSource, "proficiencies")) do
			local tData = { bWizard = rAdd.bWizard };
			if DB.getName(v) == "skills" then
				tData.bAddExpertise = bAddExpertise;
			end
			CharClassManager.addClassProficiency(rAdd.nodeChar, DB.getPath(v), tData);
		end
	else
		for _,v in ipairs(DB.getChildList(rAdd.nodeSource, "multiclassproficiencies")) do
			local tData = { bWizard = rAdd.bWizard };
			if DB.getName(v) == "skills" then
				tData.bAddExpertise = bAddExpertise;
			end
			CharClassManager.addClassProficiency(rAdd.nodeChar, DB.getPath(v), tData);
		end
	end
end
function helperAddClassFeatures(rAdd)
	if not rAdd.nodeSource then
		return;
	end

	-- Add standard class features unless new specialization
	if not rAdd.bNewSpecAdd then
		CharClassManager.helperAddClassBaseFeatures(rAdd);
	end

	-- Add external class specialization features
	local sSubclass = CharManager.getSubclass(rAdd.nodeChar, rAdd.sSourceName, rAdd.bSource2024);
	if sSubclass == "" then
		return;
	end

	local bSpecIs2024 = (DB.getValue(rAdd.nodeCharClass, "specializationversion", "") == "2024");
	local tSpecFilters = {
		{ sField = "name", sValue = sSubclass, bIgnoreCase = true, },
		{ sField = "version", sValue = (bSpecIs2024 and "2024" or ""), },
	};
	local nodeSubclass = RecordManager.findRecordByFilter("class_specialization", tSpecFilters);
	if nodeSubclass then
		for _,vFeature in ipairs(DB.getChildList(nodeSubclass, "features")) do
			if (rAdd.bNewSpecAdd and (DB.getValue(vFeature, "level", 0) <= rAdd.nCharClassLevel)) or 
					(DB.getValue(vFeature, "level", 0) == rAdd.nCharClassLevel) then
				CharClassManager.addClassFeature(rAdd.nodeChar, DB.getPath(vFeature), { nodeCharClass = rAdd.nodeCharClass, bWizard = rAdd.bWizard });
			end
		end
	else
		local bClassIs2024 = (DB.getValue(rAdd.nodeSource, "version", "") == "2024");
		if not bClassIs2024 then
			local tClassFilters = {
				{ sField = "name", sValue = rAdd.sSourceName, bIgnoreCase = true, },
				{ sField = "version", sValue = (bClassIs2024 and "2024" or ""), },
			};
			RecordManager.callForEachRecordByFilter("class", tClassFilters, CharClassManager.helperAddClassLegacySpecFeaturesWorker, rAdd);
		end
	end
end
function helperGetClassBaseFeatures(rAdd)
	local tOutput = {};
	for _,node in ipairs(DB.getChildList(rAdd.nodeSource, "features")) do
		if (DB.getValue(node, "level", 0) == rAdd.nCharClassLevel) then
			local sFeatureSpec = StringManager.trim(DB.getValue(node, "specialization", ""));
			if sFeatureSpec == "" then
				table.insert(tOutput, node);
			end
		end
	end
	return tOutput;
end
-- NOTE: Special handling for skills if class gets Expertise at L1
function helperAddClassBaseFeatures(rAdd)
	for _,node in ipairs(CharClassManager.helperGetClassBaseFeatures(rAdd)) do
		if not rAdd.bSkipExpertise or (rAdd.nCharClassLevel ~= 1) or (StringManager.simplify(DB.getValue(node, "name", "")) ~= "expertise") then
			CharClassManager.addClassFeature(rAdd.nodeChar, DB.getPath(node), { nodeCharClass = rAdd.nodeCharClass, bWizard = rAdd.bWizard });
		end
	end
end
function helperAddClassLegacySpecFeaturesWorker(nodeClass, rAdd)
	for _,nodeFeature in ipairs(DB.getChildList(nodeClass, "features")) do
		if (DB.getValue(nodeFeature, "level", 0) == rAdd.nCharClassLevel) then
			local sFeatureSpec = StringManager.trim(DB.getValue(nodeFeature, "specialization", ""));
			if (sFeatureSpec ~= "") and CharClassManager.helperHasCharClassLegacySpecialization(rAdd.nodeChar, sFeatureSpec) then
				CharClassManager.addClassFeature(rAdd.nodeChar, DB.getPath(vFeature), { nodeCharClass = rAdd.nodeCharClass, bWizard = rAdd.bWizard });
			end
		end
	end
end
function helperHasCharClassLegacySpecialization(nodeChar, sSubclass)
	if (sSubclass or "") == "" then
		return true;
	end

	local sSubclassLower = StringManager.simplify(sSubclass);
	for _,nodeCharClass in ipairs(DB.getChildList(nodeChar, "classes")) do
		if StringManager.simplify(DB.getValue(nodeCharClass, "specialization", "")) == sSubclassLower then
			return true;
		end
	end

	return CharManager.hasFeature(nodeChar, sSubclassLower);
end
function helperAddClassUpdateSpellSlots(rAdd)
	-- Handle Spellcasting slots
	local nNewCasterLevel = CharClassManager.calcSpellcastingLevel(rAdd.nodeChar);
	local tSpellcastingSlotChange = CharClassManager.helperGetSpellcastingSlotChange(rAdd.nCharCasterLevel, nNewCasterLevel);
	for i = 1,CharClassManager.SPELLCASTING_SLOT_LEVELS do
		if tSpellcastingSlotChange[i] then
			local sField = "powermeta.spellslots" .. i .. ".max";
			DB.setValue(rAdd.nodeChar, sField, "number", math.max(DB.getValue(rAdd.nodeChar, sField, 0) + tSpellcastingSlotChange[i], 0));
		end
	end
	
	-- Handle Pact Magic slots
	local nNewPactMagicLevel = CharClassManager.calcPactMagicLevel(rAdd.nodeChar);
	local tPactMagicSlotChange = CharClassManager.helperGetPactMagicSlotChange(rAdd.nCharPactMagicLevel, nNewPactMagicLevel);
	for i = 1,CharClassManager.PACTMAGIC_SLOT_LEVELS do
		if tPactMagicSlotChange[i] then
			local sField = "powermeta.pactmagicslots" .. i .. ".max";
			DB.setValue(rAdd.nodeChar, sField, "number", math.max(DB.getValue(rAdd.nodeChar, sField, 0) + tPactMagicSlotChange[i], 0));
		end
	end
end
function helperAddClassSpells(rAdd)
	if not rAdd or not rAdd.bWizard then
		return;
	end

	-- TODO (2024) - Add Cantrip/Prepared Spell choices on level up (See Savant implementation)

	-- NOTE: Special handling for Wizard school savant feature
	-- CharClassManager.helperAddClassSavantSpells(rAdd);
end
function helperAddClassSavantSpells(rAdd)
	if rAdd.sSourceName:lower() == CharManager.CLASS_WIZARD then
		return;
	end

	local nPicks = 1;
	local nLevel;
	if rAdd.nCharClassLevel == 3 then
		nLevel = 2;
		nPicks = 2;
	elseif rAdd.nCharClassLevel == 5 then
		nLevel = 3;
	elseif rAdd.nCharClassLevel == 7 then
		nLevel = 4;
	elseif rAdd.nCharClassLevel == 9 then
		nLevel = 5;
	elseif rAdd.nCharClassLevel == 11 then
		nLevel = 6;
	elseif rAdd.nCharClassLevel == 13 then
		nLevel = 7;
	elseif rAdd.nCharClassLevel == 15 then
		nLevel = 8;
	elseif rAdd.nCharClassLevel == 17 then
		nLevel = 9;
	end
	if not nLevel then
		return;
	end

	local sSchool;
	if CharManager.hasFeature(rAdd.nodeChar, CharManager.FEATURE_ABJURATION_SAVANT) then
		sSchool = "Abjuration";
	elseif CharManager.hasFeature(rAdd.nodeChar, CharManager.FEATURE_DIVINATION_SAVANT) then
		sSchool = "Divination";
	elseif CharManager.hasFeature(rAdd.nodeChar, CharManager.FEATURE_EVOCATION_SAVANT) then
		sSchool = "Evocation";
	elseif CharManager.hasFeature(rAdd.nodeChar, CharManager.FEATURE_ILLUSION_SAVANT) then
		sSchool = "Illusion";
	end
	if not sSchool then
		return;
	end

	local tLevelValues = {};
	for i = 0, nLevel do
		table.insert(tLevelValues, tostring(i));
	end
	local tFilters = {
		{ sField = "version", sValue = "2024", },
		{ sField = "level", tValues = tLevelValues, },
		{ sField = "school", sValue = sSchool, bIgnoreCase = true, },
	};
	rAdd.sSpellGroup = CharClassManager.getClassSpellGroup(rAdd);
	local tData = { sClassName = "Wizard", sGroup = rAdd.sSpellGroup, bWizard = rAdd.bWizard, bSource2024 = rAdd.bSource2024, };
	CharBuildDropManager.pickSpellByFilter(rAdd, tFilters, nPicks, tData);
end

function helperAddSubclassChoice(rAdd)
	-- Determine whether class specialization choice is triggered at this level
	local nSpecLevel = CharClassManager.getSubclassLevel(rAdd.nodeSource);
	if nSpecLevel ~= rAdd.nCharClassLevel then
		return;
	end

	local tSubclassOptions = CharClassManager.getSubclassOptions(rAdd.nodeSource);
	if #tSubclassOptions == 0 then
		return;
	end

	if #tSubclassOptions == 1 then
		-- Automatically select only class specialization
		rAdd.sSubclassChoice = tSubclassOptions[1].text;
		CharClassManager.helperAddSubclass(rAdd);
	else
		local tData = {
			title = Interface.getString("char_build_title_selectspecialization"),
			msg = Interface.getString("char_build_message_selectspecialization"),
			options = tSubclassOptions,
			callback = CharClassManager.helperOnAddSubclassChoice,
			custom = rAdd,
		};
		local wSelect = Interface.openWindow("select_dialog", "");
		wSelect.requestSelectionByData(tData);
	end
end
function helperOnAddSubclassChoice(tSelection, rAdd)
	if not tSelection or (#tSelection ~= 1) then
		ChatManager.SystemMessageResource("char_error_addsubclass");
		return;
	end

	rAdd.sSubclassChoice = tSelection[1];
	CharClassManager.helperAddSubclass(rAdd);
end
function helperAddSubclass(rAdd)
	if not rAdd or ((rAdd.sSubclassChoice or "") == "") then
		return;
	end

	local tSubclass = CharClassManager.getSubclassRecord(rAdd.nodeSource, rAdd.sSubclassChoice);
	if not tSubclass then
		ChatManager.SystemMessageResource("char_error_missingsubclass");
		return;
	end
	rAdd.nodeSubclass = DB.findNode(tSubclass.linkrecord);
	if not rAdd.nodeSubclass then
		ChatManager.SystemMessageResource("char_error_missingsubclass");
		return;
	end

	rAdd.bNewSpecAdd = true;
	rAdd.bSubclass2024 = (DB.getValue(rAdd.nodeSubclass, "version", "") == "2024");

	-- Track specialization
	DB.setValue(rAdd.nodeCharClass, "specialization", "string", tSubclass.text);
	DB.setValue(rAdd.nodeCharClass, "specializationlink", "windowreference", tSubclass.linkclass, tSubclass.linkrecord);
	DB.setValue(rAdd.nodeCharClass, "specializationversion", "string", rAdd.bSubclass2024 and "2024" or "");

	-- Store caster levels before feature additions 
	-- in order to calc spell slot upgrades correctly
	CharClassManager.helperAddClassCalcCasterLevel(rAdd);

	-- Add features
	CharClassManager.helperAddClassFeatures(rAdd);

	-- Update spell slots (based on feature add)
	CharClassManager.helperAddClassUpdateSpellSlots(rAdd);

	-- NOTE: Special handling for Wizard school savant feature
	CharClassManager.helperAddClassSavantSpells(rAdd);
end

function helperAddClassProficiencyMain(rAdd)
	if not rAdd then
		return;
	end

	if rAdd.sSourceType == "savingthrows" then
		CharBuildDropManager.handleClassSavesField(rAdd);
	end

	if rAdd.bWizard then
		return;
	end

	if rAdd.sSourceType == "skills" then
		CharBuildDropManager.handleClassSkillsField(rAdd);
	elseif rAdd.sSourceType == "armor" then
		CharBuildDropManager.handleClassArmorField(rAdd);
	elseif rAdd.sSourceType == "weapons" then
		CharBuildDropManager.handleClassWeaponsField(rAdd);
	elseif rAdd.sSourceType == "tools" then
		CharBuildDropManager.handleClassToolsField(rAdd);
	end
end

function getFeatureClassName(rAdd)
	local s = DB.getValue(rAdd.nodeSource, "...class", "");
	if s ~= "" then
		return s;
	end
	return DB.getValue(rAdd.nodeSource, "...name", "");
end
function getFeatureSpellGroup(rAdd)
	return Interface.getString("char_spell_powergroup"):format(CharClassManager.getFeatureClassName(rAdd));
end
function getFeaturePowerGroup(rAdd)
	return Interface.getString("char_class_powergroup"):format(CharClassManager.getFeatureClassName(rAdd));
end
function getFeatureChoiceDisplayName(node)
	local sChoiceType = StringManager.trim(DB.getValue(node, "choicetype", ""));
	local sName = StringManager.trim(DB.getValue(node, "name", ""));
	if sChoiceType == "" then
		return sName;
	elseif sName == "" or sName == "-" then
		return sChoiceType;
	end
	return string.format("%s (%s)", sChoiceType, sName);
end

function helperAddClassFeatureMain(rAdd)
	if not rAdd then
		return;
	end

	if rAdd.bSource2024 then
		CharClassManager.helperAddClassFeatureMain2024(rAdd);
	else
		CharClassManager.helperAddClassFeatureMain2014(rAdd);
	end
end
function helperAddClassFeatureMain2024(rAdd)
	if CharBuildDropManager.handleClassFeatureChoices(rAdd) then
		return;
	end
	CharClassManager.helperAddClassFeatureMainWorker2024(rAdd);
end
function helperAddClassFeatureMainWorker2024(rAdd)
	if rAdd.nodeCharClass then
		rAdd.sClassName = StringManager.trim(DB.getValue(rAdd.nodeCharClass, "name", ""));
	else
		rAdd.sClassName = StringManager.trim(DB.getValue(rAdd.nodeSource, "...name", ""));
	end

	local sFeatureName = rAdd.sSourceName;
	if StringManager.contains({ "abilityscoreimprovement", "epicboon", "expertise", "extraunarmoredmovement" }, rAdd.sSourceType) then
		if rAdd.bWizard then
			return;
		end
	else
		-- Exit if feature already exists
		if DB.getValue(rAdd.nodeSource, "repeatable", 0) ~= 1 then
			if CharManager.hasFeature(rAdd.nodeChar, sFeatureName) then
				if (rAdd.sSourceType == "spellcasting") or (rAdd.sSourceType == "pactmagic") then
					sFeatureName = string.format("%s (%s)", sFeatureName, rAdd.sClassName);
					if CharManager.hasFeature(rAdd.nodeChar, sFeatureName) then
						return;
					end
				else
					return;
				end
			end
		end
	end

	-- Add standard feature record, and adjust name
	if not StringManager.contains({ "abilityscoreimprovement", "extraunarmoredmovement" }, rAdd.sSourceType) then
		local nodeNew = CharClassManager.helperAddClassFeatureStandard(rAdd);
		DB.setValue(nodeNew, "name", "string", sFeatureName);
	end

	-- Special handling
	if rAdd.sSourceType == "abilityscoreimprovement" then
		CharBuildDropManager.pickAbilityAdjust(rAdd.nodeChar, rAdd.bSource2024);
	elseif rAdd.sSourceType == "epicboon" then
		CharClassManager.helperAddClassFeatureEpicBoonDrop2024(rAdd);
	elseif StringManager.contains({ "fightingstyle", "additionalfightingstyle" }, rAdd.sSourceType) then
		CharClassManager.helperAddClassFeatureFightingStyle(rAdd);
	elseif rAdd.sSourceType == "spellcasting" then
		CharClassManager.helperAddClassFeatureSpellcasting(rAdd);
	elseif rAdd.sSourceType == "pactmagic" then
		CharClassManager.helperAddClassFeaturePactMagic(rAdd);

	elseif StringManager.contains({ "unarmoreddefense", "dazzlingfootwork" }, rAdd.sSourceType) then
		CharClassManager.helperAddClassFeatureUnarmoredDefense(rAdd);
	elseif rAdd.sSourceType == "expertise" then
		CharClassManager.helperAddClassFeatureExpertise(rAdd);
	elseif rAdd.sSourceType == "magicaldiscoveries" then
		CharClassManager.helperAddClassFeatureMagicalDiscoveries(rAdd);
	elseif rAdd.sSourceType == "studentofwar" then
		CharClassManager.helperAddClassFeatureStudentOfWar(rAdd);
	elseif rAdd.sSourceType == "primalknowledge" then
		CharClassManager.helperAddClassFeaturePrimalKnowledge(rAdd);
	elseif rAdd.sSourceType == "bodyandmind" then
		CharClassManager.helperAddClassFeatureBodyAndMind(rAdd);
	elseif rAdd.sSourceType == "deftexplorer" then
		CharClassManager.helperAddClassFeatureDeftExplorer(rAdd);
	elseif rAdd.sSourceType == "ironmind" then
		CharClassManager.helperAddClassFeatureIronMind(rAdd);
	elseif rAdd.sSourceType == "usemagicdevice" then
		CharClassManager.applyAttunementAdjust(rAdd.nodeChar, 1);
	elseif rAdd.sSourceType == "draconicresilience" then
		CharClassManager.helperAddClassFeatureDraconicResilience(rAdd);
	elseif rAdd.sSourceType == "eldritchinvocationlessonsofthefirstones" then
		CharClassManager.helperAddClassFeatureEldritchInvocationLessonsOfTheFirstOnes(rAdd);
	elseif rAdd.sSourceType == "eldritchinvocationpactofthetome" then
		CharClassManager.helperAddClassFeatureEldritchInvocationPactOfTheTome(rAdd);
	elseif rAdd.sSourceType == "scholar" then
		CharClassManager.helperAddClassFeatureScholar(rAdd);
	else
		CharBuildDropManager.checkFeatureDescription(rAdd);
	end

	CharBuildDropManager.checkClassFeatureActions(rAdd);
end
function helperAddClassFeatureMain2014(rAdd)
	if rAdd.nodeCharClass then
		rAdd.sClassName = StringManager.trim(DB.getValue(rAdd.nodeCharClass, "name", ""));
	else
		rAdd.sClassName = StringManager.trim(DB.getValue(rAdd.nodeSource, "...name", ""));
	end

	local sFeatureName = rAdd.sSourceName;
	if StringManager.contains({ "abilityscoreimprovement", }, rAdd.sSourceType) then
		if rAdd.bWizard then
			return;
		end
	else
		-- Exit if feature already exists
		if CharManager.hasFeature(rAdd.nodeChar, sFeatureName) then
			if (rAdd.sSourceType == "spellcasting") or (rAdd.sSourceType == "pactmagic") then
				sFeatureName = string.format("%s (%s)", sFeatureName, rAdd.sClassName);
				if CharManager.hasFeature(rAdd.nodeChar, sFeatureName) then
					return;
				end
			else
				return;
			end
		end
	end

	-- Add standard feature record, and adjust name
	if rAdd.sSourceType ~= "abilityscoreimprovement" then
		local nodeNew = CharClassManager.helperAddClassFeatureStandard(rAdd);
		DB.setValue(nodeNew, "name", "string", sFeatureName);
	end

	-- Special handling
	if rAdd.sSourceType == "abilityscoreimprovement" then
		CharBuildDropManager.pickAbilityAdjust(rAdd.nodeChar, rAdd.bSource2024);
	elseif rAdd.sSourceType == "spellcasting" then
		CharClassManager.helperAddClassFeatureSpellcasting(rAdd);
	elseif rAdd.sSourceType == "pactmagic" then
		CharClassManager.helperAddClassFeaturePactMagic(rAdd);
	elseif rAdd.sSourceType == "unarmoreddefense" then
		CharClassManager.helperAddClassFeatureUnarmoredDefense(rAdd);
	elseif rAdd.sSourceType == "draconicresilience" then
		CharClassManager.applyDraconicResilience(rAdd.nodeChar);
	elseif rAdd.sSourceType == "magicitemadept" or
			rAdd.sSourceType == "magicitemsavant" or
			rAdd.sSourceType == "magicitemmaster" then
		CharClassManager.applyAttunementAdjust(rAdd.nodeChar, 1);
	elseif rAdd.sSourceType == "eldritchinvocations" then
		-- Note: Bypass skill proficiencies due to false positive in skill proficiency detection
	else
		CharBuildDropManager.checkFeatureDescription(rAdd);
	end

	CharBuildDropManager.checkClassFeatureActions(rAdd);
end
function helperAddClassFeatureStandard(rAdd)
	local nodeFeatureList = DB.createChild(rAdd.nodeChar, "featurelist");
	if not nodeFeatureList then
		return nil;
	end

	local nodeNewFeature = DB.createChildAndCopy(nodeFeatureList, rAdd.nodeSource);
	if not nodeNewFeature then
		return nil;
	end

	DB.setValue(nodeNewFeature, "locked", "number", 1);
	ChatManager.SystemMessageResource("char_abilities_message_featureadd", rAdd.sSourceName, rAdd.sCharName);
	return nodeNewFeature;
end
function helperAddClassFeatureChoiceMain(rAdd)
	if not rAdd then
		return;
	end
	if rAdd.bSource2024 then
		CharClassManager.helperAddClassFeatureMainWorker2024(rAdd);
	else
		-- Feature Choices not supported in 2014 records
	end
end

function helperAddClassFeatureSpellcasting(rAdd)
	if not CharBuildDropManager.helperBuildGetText(rAdd) then
		return;
	end

	-- Add power group and details
	local sAbility = rAdd.sSourceText:match("(%a+) is your spellcasting ability");
	if sAbility then
		sAbility = sAbility:lower();
		
		local nPrepared;
		if rAdd.bSource2024 then
			local sPrepared = rAdd.sSourceText:match("To start, choose (%w+) level 1");
			nPrepared = CharBuildManager.convertSingleNumberTextToNumber(sPrepared, 4);
		else
			if rAdd.sSourceText:match("Preparing and Casting Spells") then
				local rActor = ActorManager.resolveActor(rAdd.nodeChar);
				nPrepared = math.min(1 + ActorManager5E.getAbilityBonus(rActor, sAbility));
			end
		end

		rAdd.sSpellGroup = CharClassManager.getFeatureSpellGroup(rAdd);
		CharManager.addPowerGroup(rAdd.nodeChar, { sName = rAdd.sSpellGroup, sCasterType = "memorization", sAbility = sAbility, nPrepared = nPrepared });
	end
	
	-- Add spell slot calculation info
	if rAdd.nodeCharClass then
		if rAdd.bSource2024 then
			if DB.getValue(rAdd.nodeCharClass, "casterlevelinvmult", 0) == 0 then
				local nFeatureLevel = DB.getValue(rAdd.nodeSource, "level", 0);
				if nFeatureLevel > 0 then
					if StringManager.contains({ CharManager.CLASS_PALADIN, CharManager.CLASS_RANGER }, rAdd.sClassName:lower()) then
						DB.setValue(rAdd.nodeCharClass, "casterlevelinvmult", "number", -2);
					else
						DB.setValue(rAdd.nodeCharClass, "casterlevelinvmult", "number", nFeatureLevel);
					end
				end
			end
		else
			if DB.getValue(rAdd.nodeCharClass, "casterlevelinvmult", 0) == 0 then
				local nFeatureLevel = DB.getValue(rAdd.nodeSource, "level", 0);
				if nFeatureLevel > 0 then
					if StringManager.contains({ CharManager.CLASS_ARTIFICER }, rAdd.sClassName:lower()) then
						DB.setValue(rAdd.nodeCharClass, "casterlevelinvmult", "number", -2);
					else
						DB.setValue(rAdd.nodeCharClass, "casterlevelinvmult", "number", nFeatureLevel);
					end
				end
			end
		end
	end
end
function helperAddClassFeaturePactMagic(rAdd)
	if not CharBuildDropManager.helperBuildGetText(rAdd) then
		return;
	end

	-- Add spell casting ability
	local sAbility = rAdd.sSourceText:match("(%a+) is the spellcasting ability");
	if sAbility then
		sAbility = sAbility:lower();
		
		local nPrepared;
		if rAdd.bSource2024 then
			local sPrepared = rAdd.sSourceText:match("To start, choose (%w+) level 1");
			nPrepared = CharBuildManager.convertSingleNumberTextToNumber(sPrepared, 4);
		end

		rAdd.sSpellGroup = CharClassManager.getFeatureSpellGroup(rAdd);
		CharManager.addPowerGroup(rAdd.nodeChar, { sName = rAdd.sSpellGroup, sCasterType = "memorization", sAbility = sAbility, nPrepared = nPrepared });
	end
	
	-- Add spell slot calculation info
	if rAdd.nodeCharClass then
		local nFeatureLevel = DB.getValue(rAdd.nodeSource, "level", 0);
		if nFeatureLevel > 0 then
			DB.setValue(rAdd.nodeCharClass, "casterpactmagic", "number", 1);
			if DB.getValue(rAdd.nodeCharClass, "casterlevelinvmult", 0) == 0 then
				DB.setValue(rAdd.nodeCharClass, "casterlevelinvmult", "number", nFeatureLevel);
			end
		end
	end
end
function helperAddClassFeatureEpicBoonDrop2024(rAdd)
	local tOptions = RecordManager.getRecordOptionsByStringI("feat", "category", "Epic Boon", true);
	CharBuildDropManager.pickFeat(rAdd.nodeChar, tOptions, 1, { bWizard = rAdd.bWizard, bSource2024 = rAdd.bSource2024, });
end
function helperAddClassFeatureExpertise(rAdd)
	CharBuildDropManager.pickSkillExpertise(rAdd.nodeChar, nil, 2);
end
function helperAddClassFeatureUnarmoredDefense(rAdd)
	if not CharBuildDropManager.helperBuildGetText(rAdd) then
		return;
	end

	-- 2024
	local sAbility = rAdd.sSourceText:match("base Armor Class equals 10 plus your Dexterity and (%w+) modifiers");
	if not sAbility then
		-- 2014
		sAbility = rAdd.sSourceText:match("your Armor Class equals 10 + your Dexterity modifier + your (%w+) modifier");
		if not sAbility then
			-- 2014
			sAbility = rAdd.sSourceText:match("your AC equals 10 + your Dexterity modifier + your (%w+) modifier");
		end
	end
	if not sAbility then
		return;
	end

	sAbility = sAbility:lower();
	if not StringManager.contains(DataCommon.abilities, sAbility) then
		return;
	end

	if CharArmorManager.hasNaturalArmor(rAdd.nodeChar) then
		return;
	end

	DB.setValue(rAdd.nodeChar, "defenses.ac.stat2", "string", sAbility);
end
function helperAddClassFeaturePrimalKnowledge(rAdd)
	if not rAdd.bWizard then
		local tSkills = { 
			"Animal Handling", "Athletics", "Intimidation", "Nature", "Perception", "Survival", 
		};
		CharBuildDropManager.pickSkill(rAdd.nodeChar, tSkills);
	end
end
function helperAddClassFeatureBodyAndMind(rAdd)
	CharManager.addAbilityAdjustment(rAdd.nodeChar, "dexterity", 4, 25);
	CharManager.addAbilityAdjustment(rAdd.nodeChar, "wisdom", 4, 25);
end
function helperAddClassFeatureMagicalDiscoveries(rAdd)
	rAdd.sSpellGroup = CharClassManager.getFeatureSpellGroup(rAdd);

	-- Get possible Cleric, Druid and Wizard spells
	local tOptions = {};
	local aMappings = LibraryData.getMappings("spell");
	for _,vMapping in ipairs(aMappings) do
		for _,nodeSpell in pairs(DB.getChildrenGlobal(vMapping)) do
			if DB.getValue(nodeSpell, "version", "") == "2024" then
				local sName = StringManager.trim(DB.getValue(nodeSpell, "name", ""));
				if sName ~= "" then
					local tSources = ClassSpellListManager.helperGetSpellSources(nodeSpell);
					if StringManager.contains(tSources, "Cleric") or StringManager.contains(tSources, "Druid") or StringManager.contains(tSources, "Wizard") then
						local nLevel = DB.getValue(nodeSpell, "level", 0);
						if nLevel <= 3 then
							table.insert(tOptions, { text = sName, linkclass = sDisplayClass, linkrecord = DB.getPath(nodeSpell) });
						end
					end
				end
			end
		end
	end
	table.sort(tOptions, function(a,b) return a.text < b.text; end);

	local wSelect = Interface.openWindow("select_dialog", "");
	local tData = {
		title = Interface.getString("char_build_title_selectspells"),
		msg = Interface.getString("char_build_message_selectspells"):format(2),
		options = tOptions,
		min = 2,
		callback = CharBuildDropManager.onSpellSelect,
		custom = { nodeChar = rAdd.nodeChar, sGroup = rAdd.sSpellGroup, bSource2024 = true, },
	};
	wSelect.requestSelectionByData(tData);
end
function helperAddClassFeatureFightingStyle(rAdd)
	if not rAdd.bWizard then
		local tOptions = RecordManager.getRecordOptionsByStringI("feat", "category", "Fighting Style", true);
		CharBuildDropManager.pickFeat(rAdd.nodeChar, tOptions, 1, { bWizard = rAdd.bWizard, bSource2024 = rAdd.bSource2024, });
	end
end
function helperAddClassFeatureStudentOfWar(rAdd)
	CharBuildDropManager.pickToolProficiencyBySubtype(rAdd.nodeChar, "Artisan's Tools");
	local tSkills = { 
		"Acrobatics", "Animal Handling", "Athletics", "History", "Insight", 
		"Intimidation", "Persuasion", "Perception", "Survival", 
	};
	CharBuildDropManager.pickSkill(rAdd.nodeChar, tSkills);
end
function helperAddClassFeatureDeftExplorer(rAdd)
	CharBuildDropManager.pickSkillExpertise(rAdd.nodeChar, nil, 1);
	CharBuildDropManager.pickLanguage(rAdd.nodeChar, nil, 2, { bWizard = rAdd.bWizard, bSource2024 = rAdd.bSource2024, });
end
function helperAddClassFeatureIronMind(rAdd)
	if CharManager.hasSaveProficiency(rAdd.nodeChar, "wisdom") then
		CharBuildDropManager.pickSaveProficiency(rAdd.nodeChar, { "intelligence", "charisma" });
	else
		CharManager.addSaveProficiency(rAdd.nodeChar, "wisdom");
	end
end
function helperAddClassFeatureDraconicResilience(rAdd)
	CharClassManager.helperAddClassFeatureUnarmoredDefense(rAdd);
	CharClassManager.applyDraconicResilience(rAdd.nodeChar);
end
function helperAddClassFeatureEldritchInvocationLessonsOfTheFirstOnes(rAdd)
	local tOptions = RecordManager.getRecordOptionsByStringI("feat", "category", "Origin", true);
	CharBuildDropManager.pickFeat(rAdd.nodeChar, tOptions, 1, { bWizard = rAdd.bWizard, bSource2024 = rAdd.bSource2024, });
end
function helperAddClassFeatureEldritchInvocationPactOfTheTome(rAdd)
	rAdd.sSpellGroup = CharClassManager.getClassSpellGroup(rAdd);

	local tFilters = {
		{ sField = "version", sValue = "2024", },
		{ sField = "level", sValue = "0", },
	};
	local tData = { sGroup = rAdd.sSpellGroup, bWizard = rAdd.bWizard, bSource2024 = rAdd.bSource2024, };
	CharBuildDropManager.pickSpellByFilter(rAdd, tFilters, 3, tData);

	local tFilters = {
		{ sField = "version", sValue = "2024", },
		{ sField = "level", sValue = "1", },
		{ sField = "ritual", sValue = "1", },
	};
	CharBuildDropManager.pickSpellByFilter(rAdd, tFilters, 2, tData);
end
function helperAddClassFeatureScholar(rAdd)
	CharBuildDropManager.pickSkillExpertise(rAdd.nodeChar, { "Arcana", "History", "Investigation", "Medicine", "Nature", "Religion" });
end

function helperGetSpellcastingSlotChange(nOldLevel, nNewLevel)
	local tSlots = {};
	if nNewLevel > nOldLevel then
		for i = nOldLevel + 1, nNewLevel do
			if i == 1 then
				tSlots[1] = (tSlots[1] or 0) + 2;
			elseif i == 2 then
				tSlots[1] = (tSlots[1] or 0) + 1;
			elseif i == 3 then
				tSlots[1] = (tSlots[1] or 0) + 1;
				tSlots[2] = (tSlots[2] or 0) + 2;
			elseif i == 4 then
				tSlots[2] = (tSlots[2] or 0) + 1;
			elseif i == 5 then
				tSlots[3] = (tSlots[3] or 0) + 2;
			elseif i == 6 then
				tSlots[3] = (tSlots[3] or 0) + 1;
			elseif i == 7 then
				tSlots[4] = (tSlots[4] or 0) + 1;
			elseif i == 8 then
				tSlots[4] = (tSlots[4] or 0) + 1;
			elseif i == 9 then
				tSlots[4] = (tSlots[4] or 0) + 1;
				tSlots[5] = (tSlots[5] or 0) + 1;
			elseif i == 10 then
				tSlots[5] = (tSlots[5] or 0) + 1;
			elseif i == 11 then
				tSlots[6] = (tSlots[6] or 0) + 1;
			elseif i == 12 then
				-- No change
			elseif i == 13 then
				tSlots[7] = (tSlots[7] or 0) + 1;
			elseif i == 14 then
				-- No change
			elseif i == 15 then
				tSlots[8] = (tSlots[8] or 0) + 1;
			elseif i == 16 then
				-- No change
			elseif i == 17 then
				tSlots[9] = (tSlots[9] or 0) + 1;
			elseif i == 18 then
				tSlots[5] = (tSlots[5] or 0) + 1;
			elseif i == 19 then
				tSlots[6] = (tSlots[6] or 0) + 1;
			elseif i == 20 then
				tSlots[7] = (tSlots[7] or 0) + 1;
			end
		end
	end
	return tSlots;
end
function helperGetPactMagicSlotChange(nOldLevel, nNewLevel)
	local tSlots = {};
	if nNewLevel > nOldLevel then
		for i = nOldLevel + 1, nNewLevel do
			if i == 1 then
				tSlots[1] = (tSlots[1] or 0) + 1;
			elseif i == 2 then
				tSlots[1] = (tSlots[1] or 0) + 1;
			elseif i == 3 then
				tSlots[1] = (tSlots[1] or 0) - 2;
				tSlots[2] = (tSlots[2] or 0) + 2;
			elseif i == 4 then
				-- No change
			elseif i == 5 then
				tSlots[2] = (tSlots[2] or 0) - 2;
				tSlots[3] = (tSlots[3] or 0) + 2;
			elseif i == 6 then
				-- No change
			elseif i == 7 then
				tSlots[3] = (tSlots[3] or 0) - 2;
				tSlots[4] = (tSlots[4] or 0) + 2;
			elseif i == 8 then
				-- No change
			elseif i == 9 then
				tSlots[4] = (tSlots[4] or 0) - 2;
				tSlots[5] = (tSlots[5] or 0) + 2;
			elseif i == 10 then
				-- No change
			elseif i == 11 then
				tSlots[5] = (tSlots[5] or 0) + 1;
			elseif i == 12 then
				-- No change
			elseif i == 13 then
				-- No change
			elseif i == 14 then
				-- No change
			elseif i == 15 then
				-- No change
			elseif i == 16 then
				-- No change
			elseif i == 17 then
				tSlots[5] = (tSlots[5] or 0) + 1;
			elseif i == 18 then
				-- No change
			elseif i == 19 then
				-- No change
			elseif i == 20 then
				-- No change
			end
		end
	end
	return tSlots;
end

function calcSpellcastingLevel(nodeChar)
	local tCharClassMagicData = CharManager.getSpellcastingData(nodeChar);
	return CharClassManager.helperCalcSpellcastingLevel(tCharClassMagicData);
end
function helperCalcSpellcastingLevel(tCharClassMagicData)
	local nCurrSpellCastLevel = 0;
	for _,tClass in ipairs(tCharClassMagicData) do
		if not tClass.bPactMagic then
			if tClass.nSpellSlotMult > 0 then
				local nClassSpellCastLevel;
				if #tCharClassMagicData > 1 then
					nClassSpellCastLevel = math.floor(tClass.nLevel  * (1 / tClass.nSpellSlotMult));
				else
					nClassSpellCastLevel = math.ceil(tClass.nLevel  * (1 / tClass.nSpellSlotMult));
				end
				nCurrSpellCastLevel = nCurrSpellCastLevel + nClassSpellCastLevel;
			elseif tClass.nSpellSlotMult < 0 then
				local nClassSpellCastLevel = math.ceil(tClass.nLevel  * (1 / -tClass.nSpellSlotMult));
				nCurrSpellCastLevel = nCurrSpellCastLevel + nClassSpellCastLevel;
			end
		end
	end
	return nCurrSpellCastLevel;
end

function calcPactMagicLevel(nodeChar)
	local tCharClassMagicData = CharManager.getSpellcastingData(nodeChar);
	return CharClassManager.helperCalcPactMagicLevel(tCharClassMagicData);
end
function helperCalcPactMagicLevel(tCharClassMagicData)
	local nPactMagicLevel = 0;
	for _,tClass in ipairs(tCharClassMagicData) do
		if tClass.bPactMagic then
			if tClass.nSpellSlotMult > 0 then
				nClassSpellCastLevel = math.ceil(tClass.nLevel * (1 / tClass.nSpellSlotMult));
				nPactMagicLevel = nPactMagicLevel + nClassSpellCastLevel;
			end
		end
	end
	return nPactMagicLevel;
end

function applyDraconicResilience(nodeChar)
	-- Add extra hit points
	local nAddHP = 1;
	local nHP = DB.getValue(nodeChar, "hp.total", 0);
	nHP = nHP + nAddHP;
	DB.setValue(nodeChar, "hp.total", "number", nHP);
	
	ChatManager.SystemMessageResource("char_abilities_message_hpaddfeature", StringManager.capitalizeAll(CharManager.FEATURE_DRACONIC_RESILIENCE), DB.getValue(nodeChar, "name", ""), nAddHP);
end
function applyAttunementAdjust(nodeChar, n)
	local nCurrentClassAttune = DB.getValue(nodeChar, "attunement.class", 0);
	DB.setValue(nodeChar, "attunement.class", "number", nCurrentClassAttune + n);
end
