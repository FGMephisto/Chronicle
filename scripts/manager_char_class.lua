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
	CharClassManager.helperAddClassFeatureMain(rAdd);
end

function getSubclassOptions(nodeClass)
	if not nodeClass then
		return {};
	end

	local sClassName = DB.getValue(nodeClass, "name", "");
	local sClassVersion = DB.getValue(nodeClass, "version", "");
	local bIs2024 = (sClassVersion == "2024");

	local tSubclassFilters = {
		{ sField = "class", sValue = sClassName, bIgnoreCase = true, },
		{ sField = "version", sValue = (bIs2024 and "2024" or ""), },
	};
	local tOptions = RecordManager.getRecordOptionsByFilter("class_specialization", tSubclassFilters, true);

	if not bIs2024 then
		local tClassFilters = {
			{ sField = "name", sValue = sClassName, bIgnoreCase = true, },
			{ sField = "version", sValue = "", },
		};
		RecordManager.callForEachRecordByFilter("class", tClassFilters, CharClassManager.helperGetClassEmbeddedSubclassOption, tOptions);
		table.sort(tOptions, function(a,b) return a.text < b.text; end);
	end

	return tOptions;
end
function helperGetClassEmbeddedSubclassOption(nodeClass, tOptions)
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
function findSubclassByName(nodeClass, sSubclass)
	local tSubclassOptions = CharClassManager.getSubclassOptions(nodeClass);
	local sSubclassLower = StringManager.simplify(sSubclass) or "";
	for _,vSubclass in ipairs(tSubclassOptions) do
		if StringManager.simplify(vSubclass.text) == sSubclassLower then
			return vSubclass.linkrecord;
		end
	end
	return nil;
end

function getClassPowerGroupByName(sClassName)
	return Interface.getString("char_spell_powergroup"):format(sClassName or "");
end
function getClassName(rAdd)
	return DB.getValue(rAdd.nodeSource, "name", "");
end
function getClassSpellGroup(rAdd)
	return CharClassManager.getClassPowerGroupByName(CharClassManager.getClassName(rAdd));
end

function helperAddClassMain(rAdd)
	if not rAdd then
		return;
	end

	rAdd.nodeCharClass = CharManager.getClassRecord(rAdd.nodeChar, rAdd.sSourceName, rAdd.bSource2024);
	if rAdd.nodeCharClass then
		rAdd.nCharClassLevel = DB.getValue(rAdd.nodeCharClass, "level", 0) + 1;
	else
		rAdd.nCharClassLevel = 1;
	end

	if CharClassManager.helperCheckSubclass(rAdd) then
		return;
	end

	-- Notification
	ChatManager.SystemMessageResource("char_abilities_message_classadd", rAdd.sSourceName, rAdd.sCharName);

	-- Store spellcaster data in order to calculate upgrades correctly (slots, cantrips, spells)
	CharClassManager.helperAddClassGetCharSpellData(rAdd);

	CharClassManager.helperAddClassLevel(rAdd);
	CharClassManager.helperAddClassHP(rAdd);
	CharClassManager.helperAddClassProficiencies(rAdd);
	CharClassManager.helperAddClassFeatures(rAdd);

	-- Apply spellcaster upgrades (slots, cantrips, spells)
	CharClassManager.helperAddClassUpdateSpellData(rAdd);

	CharBuildManager.helperAddEquipmentKit(rAdd);
end

function helperAddClassLevel(rAdd)
	-- Check to see if the character already has this class; or create a new class entry
	if not rAdd.nodeCharClass then
		local nodeClassList = DB.createChild(rAdd.nodeChar, "classes");
		if not nodeClassList then
			return;
		end
		rAdd.nodeCharClass = DB.createChild(nodeClassList);
		DB.setValue(rAdd.nodeCharClass, "name", "string", rAdd.sSourceName);
		rAdd.bNewCharClass = true;
	end

	-- Any way you get here, overwrite or set the class reference link and record version with the most current
	DB.setValue(rAdd.nodeCharClass, "shortcut", "windowreference", "reference_class", DB.getPath(rAdd.nodeSource));
	DB.setValue(rAdd.nodeCharClass, "version", "string", DB.getValue(rAdd.nodeSource, "version", ""));

	-- Add basic class information
	if rAdd.bNewCharClass then
		DB.setValue(rAdd.nodeCharClass, "name", "string", rAdd.sSourceName);
	end
	DB.setValue(rAdd.nodeCharClass, "level", "number", rAdd.nCharClassLevel);
	CharManager.refreshNextLevelXP(rAdd.nodeChar);

	-- Calculate total level
	rAdd.nCharLevel = CharManager.getLevel(rAdd.nodeChar);

	-- Handle subclass setup, if subclass record defined, subclass level reached, and subclass not already assigned
	if ((rAdd.sSubclassRecord or "") ~= "") then
		if rAdd.nCharClassLevel >= CharClassManager.getSubclassLevel(rAdd.nodeSource) then
			local sSubclass = CharManager.getSubclass(rAdd.nodeChar, rAdd.sSourceName, rAdd.bSource2024);
			if sSubclass == "" then
				rAdd.nodeSubclass = DB.findNode(rAdd.sSubclassRecord);
				if rAdd.nodeSubclass then
					local isSubclass2024 = (DB.getValue(rAdd.nodeSubclass, "version", "") == "2024");
					DB.setValue(rAdd.nodeCharClass, "specialization", "string", DB.getValue(rAdd.nodeSubclass, "name", ""));
					DB.setValue(rAdd.nodeCharClass, "specializationlink", "windowreference", "reference_class_specialization", rAdd.sSubclassRecord);
					DB.setValue(rAdd.nodeCharClass, "specializationversion", "string", isSubclass2024 and "2024" or "");
				else
					ChatManager.SystemMessageResource("char_error_missingsubclass");
				end
			end
		end
	end
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

	CharClassManager.helperAddClassBaseFeatures(rAdd);

	CharClassManager.helperAddSubclassFeatures(rAdd);
	CharClassManager.helperGetLegacySubclassFeatures(rAdd);
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
function helperAddSubclassFeatures(rAdd)
	if not rAdd.nodeSubclass then
		local _, sSubclassRecord = DB.getValue(rAdd.nodeCharClass, "specializationlink", "", "");
		if sSubclassRecord ~= "" then
			rAdd.nodeSubclass = DB.findNode(sSubclassRecord);
		end
		if not rAdd.nodeSubclass then
			return;
		end
	end

	for _,vFeature in ipairs(DB.getChildList(rAdd.nodeSubclass, "features")) do
		if DB.getValue(vFeature, "level", 0) == rAdd.nCharClassLevel then
			CharClassManager.addClassFeature(rAdd.nodeChar, DB.getPath(vFeature), { nodeCharClass = rAdd.nodeCharClass, bWizard = rAdd.bWizard });
		end
	end
end
function helperGetLegacySubclassFeatures(rAdd)
	local bClassIs2024 = (DB.getValue(rAdd.nodeSource, "version", "") == "2024");
	if bClassIs2024 then
		return;
	end
	local _,sClassRecord = DB.getValue(rAdd.nodeCharClass, "shortcut", "", "");
	if sClassRecord == "" then
		return;
	end
	local nodeClass = DB.findNode(sClassRecord);
	if not nodeClass then
		return;
	end

	for _,nodeFeature in ipairs(DB.getChildList(nodeClass, "features")) do
		if (DB.getValue(nodeFeature, "level", 0) == rAdd.nCharClassLevel) then
			local sFeatureSpec = StringManager.trim(DB.getValue(nodeFeature, "specialization", ""));
			if (sFeatureSpec ~= "") and CharClassManager.helperHasCharClassLegacySpecialization(rAdd.nodeChar, sFeatureSpec) then
				CharClassManager.addClassFeature(rAdd.nodeChar, DB.getPath(nodeFeature), { nodeCharClass = rAdd.nodeCharClass, bWizard = rAdd.bWizard });
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

function helperAddClassGetCharSpellData(rAdd)
	rAdd.tCharClassMagicData = CharManager.getSpellcastingData(rAdd.nodeChar);
	for _,v in ipairs(rAdd.tCharClassMagicData) do
		if v.sClassName == rAdd.sSourceName then
			rAdd.tClassMagicData = v;
			break;
		end
	end

	rAdd.nCharCasterLevel = CharClassManager.helperCalcSpellcastingLevel(rAdd.tCharClassMagicData);
	rAdd.nCharPactMagicLevel = CharClassManager.helperCalcPactMagicLevel(rAdd.tCharClassMagicData);
end
function helperAddClassUpdateSpellData(rAdd)
	rAdd.sSpellGroup = CharClassManager.getClassSpellGroup(rAdd);
	CharClassManager.helperAddClassAdjustSpellData(rAdd);
	CharClassManager.helperAddClassAdjustSpellSlots(rAdd);
	CharClassManager.helperAddClassSpells(rAdd);
end
function helperAddClassAdjustSpellData(rAdd)
	rAdd.tNewCharClassMagicData = CharManager.getSpellcastingData(rAdd.nodeChar);
	for _,v in ipairs(rAdd.tNewCharClassMagicData) do
		if v.sClassName == rAdd.sSourceName then
			rAdd.tNewClassMagicData = v;
			break;
		end
	end

	local t = rAdd.tClassMagicData;
	local tNew = rAdd.tNewClassMagicData;
	if t and tNew then
		local sClassNameLower = tNew.sClassName:lower();

		-- Cantrips improvement
		if (tNew.nClassLevel == 4) and (t.nCasterLevelMult == 1) then
			tNew.nCantrips = (tNew.nCantrips or 0) + 1;
		elseif (tNew.nClassLevel == 10) then
			tNew.nCantrips = (tNew.nCantrips or 0) + 1;
		end

		-- Known Spells improvement
		if rAdd.bSource2024 then
			if StringManager.contains({ CharManager.CLASS_WIZARD }, sClassNameLower) then
				tNew.nKnown = (tNew.nKnown or 0) + 2;
			end
		else
			local sClassNameUpper = (t.sClassName or ""):upper();
			if sClassNameUpper:match("%s+") then
				sClassNameUpper = sClassNameUpper:gsub("%s+", "_");
			end
			local sKnownCheck = sClassNameUpper .. "_SPELLSKNOWN";
			local tKnownData = CharWizardData[sKnownCheck];
			if tKnownData then
				tNew.nKnown = (tNew.nKnown or 0) + math.max(tKnownData[tNew.nClassLevel] - tKnownData[t.nClassLevel], 0);
			end
		end

		-- Prepared Spells improvement
		if rAdd.bSource2024 then
			local tPreparedData = CharWizardData[sClassNameLower];
			if not tPreparedData then
				if t.nCasterLevelMult > 1 then
					tPreparedData = CharWizardData.SPELLS_PREPARED_2024.subclass;
				elseif t.nCasterLevelMult < 1 then
					tPreparedData = CharWizardData.SPELLS_PREPARED_2024.half;
				else
					tPreparedData = CharWizardData.SPELLS_PREPARED_2024.standard;
				end
			end
			tNew.nPrepared = (tNew.nPrepared or 0) + math.max(tPreparedData[tNew.nClassLevel] - tPreparedData[t.nClassLevel], 0);
		else
			if t.nPrepared > 0 then
				t.nPrepared = (tNew.nPrepared or 0) + 1;
			end
		end

		-- Update class record with changes
		if (tNew.nCantrips or 0) ~= (t.nCantrips or 0) then
			DB.setValue(rAdd.nodeCharClass, "cantrips", "number", tNew.nCantrips or 0);
		end
		if (tNew.nKnown or 0) ~= (t.nKnown or 0) then
			DB.setValue(rAdd.nodeCharClass, "spellsknown", "number", tNew.nKnown or 0);
		end
		if (tNew.nPrepared or 0) ~= (t.nPrepared or 0) then
			DB.setValue(rAdd.nodeCharClass, "spellsprepared", "number", tNew.nPrepared or 0);
		end
	end

	-- Update prepared value in power group
	if tNew then
		local nNewPrepared = (tNew and tNew.nPrepared or 0) - (t and t.nPrepared or 0);
		if nNewPrepared > 0 then
			local nodePowerGroup = CharManager.getPowerGroupRecord(rAdd.nodeChar, rAdd.sSpellGroup);
			if nodePowerGroup then
				DB.setValue(nodePowerGroup, "prepared", "number", DB.getValue(nodePowerGroup, "prepared", 0) + nNewPrepared);
			end
		end
	end
end
function helperAddClassAdjustSpellSlots(rAdd)
	-- Handle Spellcasting slots
	local nNewCasterLevel = CharClassManager.helperCalcSpellcastingLevel(rAdd.tNewCharClassMagicData);
	local tSpellcastingSlotChange = CharClassManager.helperGetSpellcastingSlotChange(rAdd.nCharCasterLevel, nNewCasterLevel);
	for i = 1,CharClassManager.SPELLCASTING_SLOT_LEVELS do
		if tSpellcastingSlotChange[i] then
			local sField = "powermeta.spellslots" .. i .. ".max";
			DB.setValue(rAdd.nodeChar, sField, "number", math.max(DB.getValue(rAdd.nodeChar, sField, 0) + tSpellcastingSlotChange[i], 0));
		end
	end

	-- Handle Pact Magic slots
	local nNewPactMagicLevel = CharClassManager.helperCalcPactMagicLevel(rAdd.tNewCharClassMagicData);
	local tPactMagicSlotChange = CharClassManager.helperGetPactMagicSlotChange(rAdd.nCharPactMagicLevel, nNewPactMagicLevel);
	for i = 1,CharClassManager.PACTMAGIC_SLOT_LEVELS do
		if tPactMagicSlotChange[i] then
			local sField = "powermeta.pactmagicslots" .. i .. ".max";
			DB.setValue(rAdd.nodeChar, sField, "number", math.max(DB.getValue(rAdd.nodeChar, sField, 0) + tPactMagicSlotChange[i], 0));
		end
	end
end
function helperAddClassSpells(rAdd)
	if rAdd.bWizard then
		return;
	end
	if not rAdd.tNewClassMagicData then
		return;
	end

	local sClassSpellList = rAdd.sSourceName;
	if rAdd.tNewClassMagicData.nCasterLevelMult > 1 then
		sClassSpellList = "Wizard";
	end

	-- Select new cantrips
	local nNewCantrips = (rAdd.tNewClassMagicData and rAdd.tNewClassMagicData.nCantrips or 0) - (rAdd.tClassMagicData and rAdd.tClassMagicData.nCantrips or 0);
	if nNewCantrips > 0 then
		local tSpellFilters = {
			{ sField = "version", sValue = "2024", },
			{ sField = "level", sValue = "0", },
		};
		local tData = {
			sClassName = sClassSpellList,
			sGroup = rAdd.sSpellGroup,
			bWizard = rAdd.bWizard,
			bSource2024 = rAdd.bSource2024,
			sPickType = "cantrip",
		};
		CharBuildDropManager.pickSpellByFilter(rAdd, tSpellFilters, nNewCantrips, tData);
	end

	local nClassCasterLevel = (rAdd.tNewClassMagicData and rAdd.tNewClassMagicData.nSpellCastLevel or 0);
	if nClassCasterLevel <= 0 then
		return;
	end

	-- Select new known/prepared spells
	CharClassManager.helperCalcSpellsKnownPreparedFromSpellGroup(rAdd);

	local nMaxSpellLevel = CharClassManager.helperCalcMaxSpellLevelFromCasterLevel(nClassCasterLevel);
	local nPrepared = (rAdd.tNewClassMagicData and rAdd.tNewClassMagicData.nPrepared or 0);
	local nKnown = (rAdd.tNewClassMagicData and rAdd.tNewClassMagicData.nKnown or 0);

	local tLevelValues = {};
	for i = 1, nMaxSpellLevel do
		table.insert(tLevelValues, tostring(i));
	end
	local tSpellFilters = {
		{ sField = "version", sValue = "2024", },
		{ sField = "level", tValues = tLevelValues, },
	};

	local tSpellData = {
		rAdd = rAdd,
		sClassName = sClassSpellList,
		nClassLevel = nClassCasterLevel,
		tFilters = tSpellFilters,
		sGroup = rAdd.sSpellGroup,
		bWizard = rAdd.bWizard,
		bSource2024 = rAdd.bSource2024,
		sPickType = "prepared",
	};
	tSpellData.nPreparedPicks = math.max(nPrepared - rAdd.nSpellGroupPrepared, 0);
	tSpellData.nKnownPicks = math.max(nKnown - (rAdd.nSpellGroupKnown + tSpellData.nPreparedPicks), 0);
	CharClassManager.helperAddClassSpellsPrepared(tSpellData);
end
function helperAddClassSpellsPrepared(tSpellData)
	if tSpellData.nPreparedPicks > 0 then
		tSpellData.sPickType = "prepared";
		tSpellData.fnCallback = CharClassManager.helperAddClassSpellsKnown;
		tSpellData.bPickSpells = true;
		CharBuildDropManager.pickSpellByFilter(tSpellData.rAdd, tSpellData.tFilters, tSpellData.nPreparedPicks, tSpellData);
	else
		CharClassManager.helperAddClassSpellsKnown(tSpellData);
	end
end
function helperAddClassSpellsKnown(tSpellData)
	if tSpellData.nKnownPicks > 0 then
		tSpellData.bFront = tSpellData.bPickSpells;
		tSpellData.bPickSpells = true;
		tSpellData.sPickType = "known";
		tSpellData.fnCallback = CharClassManager.helperAddClassSpellsSavant;
		CharBuildDropManager.pickSpellByFilter(tSpellData.rAdd, tSpellData.tFilters, tSpellData.nKnownPicks, tSpellData);
	else
		CharClassManager.helperAddClassSpellsSavant(tSpellData);
	end
end
function helperAddClassSpellsSavant(tSpellData)
	local rAdd = tSpellData.rAdd;
	if not rAdd then
		return;
	end
	if rAdd.sSourceName:lower() ~= CharManager.CLASS_WIZARD then
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

	local nPicks;
	if tSpellData.nClassLevel == 3 then
		nPicks = 2;
	elseif tSpellData.nClassLevel == 5 or
			tSpellData.nClassLevel == 7 or
			tSpellData.nClassLevel == 9 or
			tSpellData.nClassLevel == 11 or
			tSpellData.nClassLevel == 13 or
			tSpellData.nClassLevel == 15 or
			tSpellData.nClassLevel == 17 then
		nPicks = 1;
	end
	if not nPicks then
		return;
	end

	table.insert(tSpellData.tFilters, { sField = "school", sValue = sSchool, bIgnoreCase = true, });
	tSpellData.bFront = tSpellData.bPickSpells;
	tSpellData.sPickType = "known";
	tSpellData.fnCallback = nil;
	CharBuildDropManager.pickSpellByFilter(rAdd, tSpellData.tFilters, nPicks, tSpellData);
end
function helperCalcSpellsKnownPreparedFromSpellGroup(rAdd)
	rAdd.nSpellGroupPrepared = 0;
	rAdd.nSpellGroupKnown = 0;

	if (rAdd.sSpellGroup or "") == "" then
		return;
	end

	for _,nodePower in ipairs(DB.getChildList(rAdd.nodeChar, "powers")) do
		local sGroup = DB.getValue(nodePower, "group", "");
		if sGroup == rAdd.sSpellGroup then
			if DB.getValue(nodePower, "level", 0) > 0 then
				rAdd.nSpellGroupKnown = rAdd.nSpellGroupKnown + 1;
				if DB.getValue(nodePower, "prepared", 0) > 0 then
					rAdd.nSpellGroupPrepared = rAdd.nSpellGroupPrepared + 1;
				end
			end
		end
	end
end
function helperCalcMaxSpellLevelFromCasterLevel(n)
	return math.min(math.max(math.floor((n + 1) / 2), 1), PowerManager.SPELL_LEVELS);
end
function helperCalcSpellcastingLevel(tCharClassMagicData)
	local bMulticlass = (#tCharClassMagicData > 1);
	local nCasterLevel = 0;
	for _,tClass in ipairs(tCharClassMagicData) do
		if not tClass.bPactMagic then
			if bMulticlass then
				nCasterLevel = nCasterLevel + (tClass.nMulticlassSpellCastLevel or 0);
			else
				nCasterLevel = nCasterLevel + (tClass.nSpellCastLevel or 0);
			end
		end
	end
	return nCasterLevel;
end
function helperCalcPactMagicLevel(tCharClassMagicData)
	local bMulticlass = (#tCharClassMagicData > 1);
	local nCasterLevel = 0;
	for _,tClass in ipairs(tCharClassMagicData) do
		if tClass.bPactMagic then
			if bMulticlass then
				nCasterLevel = nCasterLevel + (tClass.nMulticlassSpellCastLevel or 0);
			else
				nCasterLevel = nCasterLevel + (tClass.nSpellCastLevel or 0);
			end
		end
	end
	return nCasterLevel;
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

function helperCheckSubclass(rAdd)
	if not rAdd then
		return false;
	end

	-- Character wizard handles subclass separately
	if rAdd.bWizard then
		return false;
	end

	-- Determine whether class specialization choice is triggered at this level
	if rAdd.nCharClassLevel ~= CharClassManager.getSubclassLevel(rAdd.nodeSource) then
		return false;
	end

	-- Determine whether subclass defined in class add structure already
	if ((rAdd.sSubclassRecord or "") ~= "") then
		return false;
	end

	-- Determine whether subclass already assigned
	local sSubclass = CharManager.getSubclass(rAdd.nodeChar, rAdd.sSourceName, rAdd.bSource2024);
	if sSubclass ~= "" then
		return false;
	end

	-- If subclass level reached and subclass is not defined and not assigned, then get the subclass options
	local tSubclassOptions = CharClassManager.getSubclassOptions(rAdd.nodeSource);
	if #tSubclassOptions == 0 then
		return false;
	end

	-- If only one subclass, then apply it.
	if #tSubclassOptions == 1 then
		-- Automatically select only class specialization
		rAdd.sSubclassRecord = tSubclassOptions[1].linkrecord;
		return CharClassManager.helperAddClassMain(rAdd);
	end

	-- Otherwise, show dialog
	rAdd.tSubclassOptions = tSubclassOptions;
	local tDialogData = {
		title = Interface.getString("char_build_title_selectspecialization"),
		msg = Interface.getString("char_build_message_selectspecialization"),
		options = tSubclassOptions,
		callback = CharClassManager.helperOnAddSubclassChoice,
		custom = rAdd,
		showmodule = true,
	};
	DialogManager.requestSelectionDialog(tDialogData);
	return true;
end
function helperOnAddSubclassChoice(tSelection, rAdd)
	if not tSelection or (#tSelection ~= 1) then
		ChatManager.SystemMessageResource("char_error_addsubclass");
		return;
	end

	local sSubclass = tSelection[1];
	for _,v in ipairs(rAdd.tSubclassOptions) do
		if v.text == sSubclass then
			rAdd.sSubclassRecord = v.linkrecord;
			break;
		end
	end
	if (rAdd.sSubclassRecord or "") ~= "" then
		CharClassManager.helperAddClassMain(rAdd);
	else
		ChatManager.SystemMessageResource("char_error_missingsubclass");
	end
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

	if rAdd.nodeCharClass then
		rAdd.sClassName = StringManager.trim(DB.getValue(rAdd.nodeCharClass, "name", ""));
	else
		rAdd.sClassName = StringManager.trim(DB.getValue(rAdd.nodeSource, "...name", ""));
	end
	CharBuildDropManager.addFeature(rAdd);
end
function checkClassFeatureSkipAdd(rAdd)
	-- Handle class feature choices (2024)
	if (rAdd.sSourceClass == "reference_classfeature") and CharBuildDropManager.handleClassFeatureChoices(rAdd) then
		return true;
	end

	-- Skip if feature already exists, and is not repeatable
	if DB.getValue(rAdd.nodeSource, "repeatable", 0) ~= 1 then
		if CharManager.hasFeature(rAdd.nodeChar, rAdd.sSourceName) then
			if (rAdd.sSourceType == "spellcasting") or (rAdd.sSourceType == "pactmagic") then
				rAdd.sSourceName = string.format("%s (%s)", rAdd.sSourceName, rAdd.sClassName);
				if CharManager.hasFeature(rAdd.nodeChar, rAdd.sSourceName) then
					return true;
				end
			else
				return true;
			end
		end
	end

	return false;
end
function addClassFeatureStandard(rAdd)
	local nodeFeatureList = DB.createChild(rAdd.nodeChar, "featurelist");
	if not nodeFeatureList then
		return nil;
	end

	local nodeNewFeature = DB.createChildAndCopy(nodeFeatureList, rAdd.nodeSource);
	if not nodeNewFeature then
		return nil;
	end
	DB.setValue(nodeNewFeature, "locked", "number", 1);

	-- Name can be changed during duplicate check for spellcasting to add class suffix
	DB.setValue(nodeNewFeature, "name", "string", rAdd.sSourceName);

	ChatManager.SystemMessageResource("char_abilities_message_featureadd", rAdd.sSourceName, rAdd.sCharName);
	return nodeNewFeature;
end
function checkClassFeatureSpecialHandling(rAdd)
	if not rAdd then
		return true;
	end

	if rAdd.bSource2024 then
		return CharClassManager.helperCheckClassFeatureSpecialHandling2024(rAdd);
	else
		return CharClassManager.helperCheckClassFeatureSpecialHandling2014(rAdd);
	end
end
function helperCheckClassFeatureSpecialHandling2024(rAdd)
	if not rAdd.bWizard then
		if rAdd.sSourceType == "abilityscoreimprovement" then
			CharBuildDropManager.pickASIOrFeat(rAdd.nodeChar, rAdd.bSource2024);
			return true;
		elseif rAdd.sSourceType == "epicboon" then
			CharClassManager.helperAddClassFeatureEpicBoonDrop2024(rAdd);
			return true;
		elseif StringManager.contains({ "fightingstyle", "additionalfightingstyle" }, rAdd.sSourceType) then
			CharClassManager.helperAddClassFeatureFightingStyle(rAdd);
			return true;
		elseif rAdd.sSourceType == "expertise" then
			CharClassManager.helperAddClassFeatureExpertise(rAdd);
			return true;
		end
	end

	if rAdd.sSourceType == "spellcasting" then
		CharClassManager.helperAddClassFeatureSpellcasting(rAdd);
	elseif rAdd.sSourceType == "pactmagic" then
		CharClassManager.helperAddClassFeaturePactMagic(rAdd);

	elseif StringManager.contains({ "unarmoreddefense", "dazzlingfootwork" }, rAdd.sSourceType) then
		CharClassManager.helperAddClassFeatureUnarmoredDefense(rAdd);
	elseif rAdd.sSourceType == "magicaldiscoveries" then
		CharClassManager.helperAddClassFeatureMagicalDiscoveries(rAdd);
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
		return false;
	end
	return true;
end
function helperCheckClassFeatureSpecialHandling2014(rAdd)
	if not rAdd.bWizard then
		if rAdd.sSourceType == "abilityscoreimprovement" then
			CharBuildDropManager.pickAbilityAdjust(rAdd.nodeChar, { bSource2024 = rAdd.bSource2024, });
			return true;
		end
	end

	if rAdd.sSourceType == "spellcasting" then
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
		return false;
	end
	return true;
end

function helperAddClassFeatureSpellcasting(rAdd)
	if not CharBuildDropManager.helperBuildGetText(rAdd) then
		return;
	end
	rAdd.nClassLevel = DB.getValue(rAdd.nodeCharClass, "level", 0);
	rAdd.tAbilities = {};
	for _,s in ipairs(DataCommon.abilities) do
		rAdd.tAbilities[s] = DB.getValue(rAdd.nodeChar, s, 10);
	end

	local tSpellcastingData = CharBuildManager.getClassFeatureSpellcastingData(rAdd);
	if not tSpellcastingData then
		return;
	end

	-- Add power group and details
	if (tSpellcastingData.sAbility or "") ~= "" then
		rAdd.sSpellGroup = CharClassManager.getFeatureSpellGroup(rAdd);
		CharManager.addPowerGroup(rAdd.nodeChar, { sName = rAdd.sSpellGroup, sCasterType = "memorization", sAbility = tSpellcastingData.sAbility });
	end

	-- Add spell slot calculation info
	if rAdd.nodeCharClass then
		if (DB.getValue(rAdd.nodeCharClass, "casterlevelinvmult", 0) == 0) then
			DB.setValue(rAdd.nodeCharClass, "casterlevelinvmult", "number", tSpellcastingData.nCasterLevelMult or 1);
			DB.setValue(rAdd.nodeCharClass, "cantrips", "number", tSpellcastingData.nCantrips or 0);
			DB.setValue(rAdd.nodeCharClass, "spellsknown", "number", tSpellcastingData.nKnown or 0);
			DB.setValue(rAdd.nodeCharClass, "spellsprepared", "number", tSpellcastingData.nPrepared or 0);
			DB.setValue(rAdd.nodeCharClass, "spellability", "string", tSpellcastingData.sAbility);
		end
	end
end
function helperAddClassFeaturePactMagic(rAdd)
	CharClassManager.helperAddClassFeatureSpellcasting(rAdd);
	if rAdd.nodeCharClass then
		DB.setValue(rAdd.nodeCharClass, "casterpactmagic", "number", 1);
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
		sAbility = rAdd.sSourceText:match("your Armor Class equals 10 %+ your Dexterity modifier %+ your (%w+) modifier");
		if not sAbility then
			-- 2014
			sAbility = rAdd.sSourceText:match("your AC equals 10 %+ your Dexterity modifier %+ your (%w+) modifier");
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
function helperAddClassFeatureBodyAndMind(rAdd)
	CharManager.addAbilityAdjustment(rAdd.nodeChar, "dexterity", 4, 25);
	CharManager.addAbilityAdjustment(rAdd.nodeChar, "wisdom", 4, 25);
end
function helperAddClassFeatureMagicalDiscoveries(rAdd)
	rAdd.sSpellGroup = CharClassManager.getFeatureSpellGroup(rAdd);

	-- Get possible Cleric, Druid and Wizard spells
	local tOptions = {};
	local sDisplayClass = RecordDataManager.getRecordTypeDisplayClass("spell");
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

	local tDialogData = {
		title = Interface.getString("char_build_title_selectspells"),
		msg = Interface.getString("char_build_message_selectspells"):format(2),
		options = tOptions,
		min = 2,
		callback = CharBuildDropManager.onSpellSelect,
		custom = { nodeChar = rAdd.nodeChar, sGroup = rAdd.sSpellGroup, bSource2024 = true, },
	};
	DialogManager.requestSelectionDialog(tDialogData);
end
function helperAddClassFeatureFightingStyle(rAdd)
	if not rAdd.bWizard then
		local tOptions = RecordManager.getRecordOptionsByStringI("feat", "category", "Fighting Style", true);
		CharBuildDropManager.pickFeat(rAdd.nodeChar, tOptions, 1, { bWizard = rAdd.bWizard, bSource2024 = rAdd.bSource2024, });
	end
end
function helperAddClassFeatureDeftExplorer(rAdd)
	CharBuildDropManager.pickSkillExpertise(rAdd.nodeChar, nil, 1);
	CharBuildDropManager.pickLanguage(rAdd.nodeChar, nil, 2, { bWizard = rAdd.bWizard, bSource2024 = rAdd.bSource2024, });
end
function helperAddClassFeatureIronMind(rAdd)
	if CharManager.hasSaveProficiency(rAdd.nodeChar, "wisdom") then
		CharBuildDropManager.pickSaveProficiency(rAdd.nodeChar, { "intelligence", "charisma", });
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
	local tData = {
		sGroup = rAdd.sSpellGroup,
		bWizard = rAdd.bWizard,
		bSource2024 = rAdd.bSource2024,
		sPickType = "cantrip",
	};
	CharBuildDropManager.pickSpellByFilter(rAdd, tFilters, 3, tData);

	local tFilters = {
		{ sField = "version", sValue = "2024", },
		{ sField = "level", sValue = "1", },
		{ sField = "ritual", sValue = "1", },
	};
	tData.sPickType = "prepared";
	CharBuildDropManager.pickSpellByFilter(rAdd, tFilters, 2, tData);
end
function helperAddClassFeatureScholar(rAdd)
	CharBuildDropManager.pickSkillExpertise(rAdd.nodeChar, { "Arcana", "History", "Investigation", "Medicine", "Nature", "Religion" });
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
