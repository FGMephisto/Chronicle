-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

SPELLCASTING_SLOT_LEVELS = 9;
PACTMAGIC_SLOT_LEVELS = 5;

function getClassSpecializationOptions(sClassName)
	local tOptions = {};
	RecordManager.callForEachRecordByStringI("class_specialization", "class", sClassName, CharClassManager.helperGetClassExternalSpecOption, tOptions);
	RecordManager.callForEachRecordByStringI("class", "name", sClassName, CharClassManager.helperGetClassEmbeddedSpecOption, tOptions);
	table.sort(tOptions, function(a,b) return a.text < b.text; end);
	return tOptions;
end
function helperGetClassExternalSpecOption(nodeClassSpec, tOptions)
	local sSpecName = StringManager.trim(DB.getValue(nodeClassSpec, "name", ""));
	if sSpecName ~= "" then
		table.insert(tOptions, { text = sSpecName, linkclass = "reference_class_specialization", linkrecord = DB.getPath(nodeClassSpec) });
	end
end
function helperGetClassEmbeddedSpecOption(nodeClass, tOptions)
	for _,nodeClassSpec in ipairs(DB.getChildList(nodeClass, "abilities")) do
		local sSpecName = StringManager.trim(DB.getValue(nodeClassSpec, "name", ""));
		if sSpecName ~= "" then
			table.insert(tOptions, { text = sSpecName, linkclass = "reference_classability", linkrecord = DB.getPath(nodeClassSpec) });
		end
	end
end

function getClassSpecializationLevel(sClassName)
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
function getClassSpecializationRecord(sClassName, sClassSpec)
	local tClassSpecOptions = CharClassManager.getClassSpecializationOptions(sClassName);
	local sClassSpecLower = StringManager.trim(sClassSpec):lower();
	for _,vClassSpec in ipairs(tClassSpecOptions) do
		local sMatch = StringManager.trim(vClassSpec.text):lower();
		if sMatch == sClassSpecLower then
			return vClassSpec;
		end
	end
	return nil;
end
-- Returns (nSpellcastingLevel, nPactMagicLevel)
function getClassSpellcastingLevel(sClassName, nClassLevel, sClassSpec)
	local nodeClass = RecordManager.findRecordByStringI("class", "name", sClassName);
	if not nodeClass then
		return 0, 0;
	end

	-- Check native class features and embedded class specialization features
	local sClassSpecLower = StringManager.trim(sClassSpec):lower();
	for _,vFeature in ipairs(DB.getChildList(nodeClass, "features")) do
		local sMatch = StringManager.trim(DB.getValue(vFeature, "name", "")):lower();
		if sMatch == CharManager.FEATURE_SPELLCASTING then
			local nLevel = DB.getValue(vFeature, "level", 0);
			if nLevel > 0 and nLevel <= nClassLevel then
				local sSpecMatch = StringManager.trim(DB.getValue(vFeature, "specialization", "")):lower();
				if (sSpecMatch == "") or (sSpecMatch == sClassSpecLower) then
					return nLevel, 0;
				end
			end
		elseif sMatch == CharManager.FEATURE_PACT_MAGIC then
			local nLevel = DB.getValue(vFeature, "level", 0);
			if nLevel > 0 and nLevel <= nClassLevel then
				local sSpecMatch = StringManager.trim(DB.getValue(vFeature, "specialization", "")):lower();
				if (sSpecMatch == "") or (sSpecMatch == sClassSpecLower) then
					return 0, nLevel;
				end
			end
		end
	end

	-- Check external class specialization features
	if sClassSpec ~= "" then
		local tClassSpec = getClassSpecializationRecord(sClassName, sClassSpec);
		if tClassSpec and tClassSpec.linkclass == "reference_class_specialization" then
			for _,vFeature in ipairs(DB.getChildList(DB.getPath(tClassSpec.linkrecord, "features"))) do
				local sMatch = StringManager.trim(DB.getValue(vFeature, "name", "")):lower();
				if sMatch == CharManager.FEATURE_SPELLCASTING then
					local nLevel = DB.getValue(vFeature, "level", 0);
					if nLevel > 0 then
						return nLevel, 0;
					end
				elseif sMatch == CharManager.FEATURE_PACT_MAGIC then
					local nLevel = DB.getValue(vFeature, "level", 0);
					if nLevel > 0 then
						return 0, nLevel;
					end
				end
			end
		end
	end

	return 0, 0;
end

function getCharLevel(nodeChar)
	local nTotal = 0;
	for _,v in ipairs(DB.getChildList(nodeChar, "classes")) do
		local nClassLevel = DB.getValue(v, "level", 0);
		if nClassLevel > 0 then
			nTotal = nTotal + nClassLevel;
		end
	end
	return nTotal;
end
function getCharClassSummary(nodeChar, bShort)
	if not nodeChar then
		return "";
	end
	
	local tSorted = {};
	for _,nodeChild in ipairs(DB.getChildList(nodeChar, "classes")) do
		table.insert(tSorted, nodeChild);
	end
	table.sort(tSorted, function(a,b) return DB.getValue(a, "name", "") < DB.getValue(b, "name", ""); end);
			
	local tClasses = {};
	for _,nodeChild in pairs(tSorted) do
		local sClass = DB.getValue(nodeChild, "name", "");
		local nLevel = DB.getValue(nodeChild, "level", 0);
		if nLevel > 0 then
			if bShort then
				sClass = sClass:sub(1,3);
			end
			table.insert(tClasses, sClass .. " " .. math.floor(nLevel*100)*0.01);
		end
	end

	return table.concat(tClasses, " / ");
end
function getCharClassHDUsage(nodeChar)
	local nHD = 0;
	local nHDUsed = 0;
	
	for _,nodeChild in ipairs(DB.getChildList(nodeChar, "classes")) do
		local nLevel = DB.getValue(nodeChild, "level", 0);
		local nHDMult = #(DB.getValue(nodeChild, "hddie", {}));
		nHD = nHD + (nLevel * nHDMult);
		nHDUsed = nHDUsed + DB.getValue(nodeChild, "hdused", 0);
	end
	
	return nHDUsed, nHD;
end
function getCharClassRecord(nodeChar, sClassName)
	if (sClassName or "") == "" then
		return nil;
	end
	local sClassNameLower = StringManager.trim(sClassName):lower();

	for _,v in ipairs(DB.getChildList(nodeChar, "classes")) do
		local sMatch = StringManager.trim(DB.getValue(v, "name", "")):lower();
		if sMatch == sClassNameLower then
			return v;
		end
	end
	return nil;
end
function getCharClassLevel(nodeChar, sClassName)
	local nodeCharClass = CharClassManager.getCharClassRecord(nodeChar, sClassName);
	if not nodeCharClass then
		return 0;
	end

	return DB.getValue(nodeCharClass, "level", 0);
end

function getCharClassSpecialization(nodeChar, sClassName)
	local nodeCharClass = CharClassManager.getCharClassRecord(nodeChar, sClassName);
	if not nodeCharClass then
		return "";
	end

	local sSpecName = StringManager.trim(DB.getValue(nodeCharClass, "specialization", ""));
	if sSpecName ~= "" then
		return sSpecName;
	end

	local tClassSpecOptions = CharClassManager.getClassSpecializationOptions(sClassName);
	for _,vClassSpec in ipairs(tClassSpecOptions) do
		if CharManager.hasFeature(vClassSpec.text) then
			return vClassSpec.text;
		end
	end

	return "";
end
function hasCharClassSpecialization(nodeChar, sClassSpec)
	if (sClassSpec or "") == "" then
		return true;
	end
	local sClassSpecLower = StringManager.trim(sClassSpec):lower();

	for _,nodeCharClass in ipairs(DB.getChildList(nodeChar, "classes")) do
		local sMatch = StringManager.trim(DB.getValue(nodeCharClass, "specialization", "")):lower();
		if sMatch == sClassSpecLower then
			return true;
		end
	end

	if CharManager.hasFeature(nodeChar, sClassSpecLower) then
		return true;
	end

	return false;
end

function addClass(nodeChar, sClass, sRecord, bWizard)
	local rAdd = CharManager.helperBuildAddStructure(nodeChar, sClass, sRecord, bWizard);
	if not rAdd then
		return;
	end

	CharClassManager.helperAddClassMain(rAdd);
	if not rAdd.bWizard then
		CharClassManager.helperAddClassSpecializationChoice(rAdd);
	end
end
function helperAddClassMain(rAdd)
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
end
function helperAddClassLevel(rAdd)
	-- Check to see if the character already has this class; or create a new class entry
	rAdd.nodeCharClass = CharClassManager.getCharClassRecord(rAdd.nodeChar, rAdd.sSourceName);
	if not rAdd.nodeCharClass then
		local nodeClassList = DB.createChild(rAdd.nodeChar, "classes");
		if not nodeClassList then
			return;
		end
		rAdd.nodeCharClass = DB.createChild(nodeClassList);
		rAdd.bNewCharClass = true;
	end
	
	-- Any way you get here, overwrite or set the class reference link with the most current
	DB.setValue(rAdd.nodeCharClass, "shortcut", "windowreference", "reference_class", DB.getPath(rAdd.nodeSource));
	
	-- Add basic class information
	if rAdd.bNewCharClass then
		DB.setValue(rAdd.nodeCharClass, "name", "string", rAdd.sSourceName);
		rAdd.nCharClassLevel = 1;
	else
		rAdd.nCharClassLevel = DB.getValue(rAdd.nodeCharClass, "level", 0) + 1;
	end
	DB.setValue(rAdd.nodeCharClass, "level", "number", rAdd.nCharClassLevel);
	
	-- Calculate total level
	rAdd.nCharLevel = CharClassManager.getCharLevel(rAdd.nodeChar);
end
function helperAddClassHP(rAdd)
	-- Translate Hit Die
	local bHDFound = false;
	local nHDMult = 1;
	local nHDSides = 6;
	local sHD = DB.getText(rAdd.nodeSource, "hp.hitdice.text");
	if sHD then
		local sMult, sSides = sHD:match("(%d)d(%d+)");
		if sMult and sSides then
			nHDMult = tonumber(sMult);
			nHDSides = tonumber(sSides);
			bHDFound = true;
		end
	end
	if not bHDFound then
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
	if CharManager.hasTrait(rAdd.nodeChar, CharManager.TRAIT_DWARVEN_TOUGHNESS) then
		CharRaceManager.applyDwarvenToughness(rAdd.nodeChar);
	end
	if CharManager.hasFeature(rAdd.nodeChar, CharManager.FEATURE_DRACONIC_RESILIENCE) then
		local sClassNameLower = StringManager.trim(DB.getValue(rAdd.nodeCharClass, "name", "")):lower();
		if sClassNameLower == CharManager.CLASS_SORCERER then
			CharClassManager.applyDraconicResilience(rAdd.nodeChar);
		end
	end
	if CharManager.hasFeat(rAdd.nodeChar, CharManager.FEAT_TOUGH) then
		CharFeatManager.applyTough(rAdd.nodeChar);
	end
end
function helperAddClassProficiencies(rAdd)
	if not rAdd.bNewCharClass then
		return;
	end

	if rAdd.nCharLevel == 1 then
		for _,v in ipairs(DB.getChildList(rAdd.nodeSource, "proficiencies")) do
			CharClassManager.addClassProficiency(rAdd.nodeChar, "reference_classproficiency", DB.getPath(v), rAdd.bWizard);
		end
	else
		for _,v in ipairs(DB.getChildList(rAdd.nodeSource, "multiclassproficiencies")) do
			CharClassManager.addClassProficiency(rAdd.nodeChar, "reference_classproficiency", DB.getPath(v), rAdd.bWizard);
		end
	end
end
function helperAddClassSpecializationChoice(rAdd)
	-- Determine whether class specialization choice is triggered at this level
	local nSpecLevel = CharClassManager.getClassSpecializationLevel(rAdd.sSourceName);
	if nSpecLevel ~= rAdd.nCharClassLevel then
		return;
	end

	local tClassSpecOptions = CharClassManager.getClassSpecializationOptions(rAdd.sSourceName);
	if #tClassSpecOptions == 0 then
		return;
	end

	if #tClassSpecOptions == 1 then
		-- Automatically select only class specialization
		rAdd.sClassSpecChoice = tClassSpecOptions[1].text;
		CharClassManager.helperAddClassSpecialization(rAdd);
	else
		-- Display dialog to choose specialization
		local wSelect = Interface.openWindow("select_dialog", "");
		local sTitle = Interface.getString("char_build_title_selectspecialization");
		local sMessage = Interface.getString("char_build_message_selectspecialization");
		wSelect.requestSelection(sTitle, sMessage, tClassSpecOptions, CharClassManager.callbackAddClassSpecializationChoice, rAdd);
	end
end
function callbackAddClassSpecializationChoice(tSelection, rAdd)
	if not tSelection or (#tSelection ~= 1) then
		ChatManager.SystemMessageResource("char_error_addclassspecialization");
		return;
	end

	rAdd.sClassSpecChoice = tSelection[1];
	CharClassManager.helperAddClassSpecialization(rAdd);
end
function helperAddClassSpecialization(rAdd)
	if ((rAdd.sClassSpecChoice or "") == "") then
		return;
	end

	local tClassSpec = CharClassManager.getClassSpecializationRecord(rAdd.sSourceName, rAdd.sClassSpecChoice);
	if not tClassSpec then
		ChatManager.SystemMessageResource("char_error_missingclassspecialization");
		return;
	end

	-- Track specialization
	DB.setValue(rAdd.nodeCharClass, "specialization", "string", tClassSpec.text);
	DB.setValue(rAdd.nodeCharClass, "specializationlink", "windowreference", tClassSpec.linkclass, tClassSpec.linkrecord);

	-- Store caster levels before feature additions 
	-- in order to calc spell slot upgrades correctly
	CharClassManager.helperAddClassCalcCasterLevel(rAdd);

	-- Add features
	rAdd.bNewSpecAdd = true;
	CharClassManager.helperAddClassFeatures(rAdd);

	-- Update spell slots (based on feature add)
	CharClassManager.helperAddClassUpdateSpellSlots(rAdd);
end
function helperAddClassFeatures(rAdd)
	-- Get class matches
	local nodeClass = rAdd.nodeSource;
	if not nodeClass then
		nodeClass = RecordManager.findRecordByStringI("class", "name", rAdd.sSourceName);
	end

	-- Add class features
	if not rAdd.bNewSpecAdd then
		CharClassManager.helperAddClassBaseFeaturesWorker(nodeClass, rAdd);
	end

	-- Add external class specialization features
	local sClassSpec = CharClassManager.getCharClassSpecialization(rAdd.nodeChar, rAdd.sSourceName);
	local nodeClassSpec = RecordManager.findRecordByStringI("class_specialization", "name", sClassSpec);
	if nodeClassSpec then
		for _,vFeature in ipairs(DB.getChildList(nodeClassSpec, "features")) do
			if (DB.getValue(vFeature, "level", 0) == rAdd.nCharClassLevel) then
				CharClassManager.addClassFeature(rAdd.nodeChar, "reference_classfeature", DB.getPath(vFeature), rAdd.nodeCharClass, rAdd.bWizard);
			end
		end
	else
		RecordManager.callForEachRecordByStringI("class", "name", rAdd.sSourceName, CharClassManager.helperAddClassSpecFeaturesWorker, rAdd);
	end
end
function helperAddClassBaseFeaturesWorker(nodeClass, rAdd)
	for _,vFeature in ipairs(DB.getChildList(nodeClass, "features")) do
		if (DB.getValue(vFeature, "level", 0) == rAdd.nCharClassLevel) then
			local sFeatureSpec = StringManager.trim(DB.getValue(vFeature, "specialization", ""));
			if sFeatureSpec == "" then
				CharClassManager.addClassFeature(rAdd.nodeChar, "reference_classfeature", DB.getPath(vFeature), rAdd.nodeCharClass, rAdd.bWizard);
			end
		end
	end
end
function helperAddClassSpecFeaturesWorker(nodeClass, rAdd)
	for _,vFeature in ipairs(DB.getChildList(nodeClass, "features")) do
		if (DB.getValue(vFeature, "level", 0) == rAdd.nCharClassLevel) then
			local sFeatureSpec = StringManager.trim(DB.getValue(vFeature, "specialization", ""));
			if (sFeatureSpec ~= "") and CharClassManager.hasCharClassSpecialization(rAdd.nodeChar, sFeatureSpec) then
				CharClassManager.addClassFeature(rAdd.nodeChar, "reference_classfeature", DB.getPath(vFeature), rAdd.nodeCharClass, rAdd.bWizard);
			end
		end
	end
end
function helperAddClassCalcCasterLevel(rAdd)
	rAdd.nCharCasterLevel = CharClassManager.calcSpellcastingLevel(rAdd.nodeChar); 
	rAdd.nCharPactMagicLevel = CharClassManager.calcPactMagicLevel(rAdd.nodeChar);
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

function addClassProficiency(nodeChar, sClass, sRecord, bWizard)
	local rAdd = CharManager.helperBuildAddStructure(nodeChar, sClass, sRecord, bWizard);
	if not rAdd then
		return;
	end

	-- Saving Throw Proficiencies
	if rAdd.sSourceType == "savingthrows" then
		local sText = StringManager.trim(DB.getText(rAdd.nodeSource, "text", ""));
		if sText == "" then
			return;
		end

		for sProf in sText:gmatch("(%a[%a%s]+)%,?") do
			local sProfLower = StringManager.trim(sProf):lower();
			if StringManager.contains(DataCommon.abilities, sProfLower) then
				DB.setValue(rAdd.nodeChar, "abilities." .. sProfLower .. ".saveprof", "number", 1);
				ChatManager.SystemMessageResource("char_abilities_message_saveadd", sProf, rAdd.sCharName);
			end
		end
	end

	if not rAdd.bWizard then
		-- Armor, Weapon or Tool Proficiencies
		if StringManager.contains({"armor", "weapons", "tools"}, rAdd.sSourceType) then
			local sText = StringManager.trim(DB.getText(rAdd.nodeSource, "text", ""));
			if sText == "" then
				return;
			end

			CharManager.addProficiency(rAdd.nodeChar, rAdd.sSourceType, DB.getText(rAdd.nodeSource, "text", ""));
			

		-- Skill Proficiencies
		elseif rAdd.sSourceType == "skills" then
			local nPicks, tSkills = CharManager.parseSkillProficiencyText(rAdd.nodeSource);
			if nPicks == 0 then
				ChatManager.SystemMessageResource("char_error_addskill");
				return nil;
			end
			CharManager.pickSkills(rAdd.nodeChar, tSkills, nPicks);
		end
	end
end

function addClassFeature(nodeChar, sClass, sRecord, nodeClass, bWizard)
	local rAdd = CharManager.helperBuildAddStructure(nodeChar, sClass, sRecord, bWizard);
	if not rAdd then
		return;
	end

	rAdd.nodeClass = nodeClass;
	CharClassManager.helperAddClassFeatureMain(rAdd);
end
function helperAddClassFeatureMain(rAdd)
	-- Skip certain entries
	if rAdd.bWizard then
		if rAdd.sSourceType == "abilityscoreimprovement" then
			return;
		end
	end

	-- Prep some variables
	if rAdd.nodeClass then
		rAdd.sFeatureClassName = StringManager.trim(DB.getValue(rAdd.nodeClass, "name", ""));
	else
		rAdd.sFeatureClassName = StringManager.trim(DB.getValue(rAdd.nodeSource, "...name", ""));
	end
	local sSourceNameLower = StringManager.trim(rAdd.sSourceName):lower();

	-- Get the final feature name; and check if it exists
	local sFeatureName = rAdd.sSourceName;
	if CharManager.hasFeature(rAdd.nodeChar, sFeatureName) then
		if sSourceNameLower == CharManager.FEATURE_SPELLCASTING or sSourceNameLower == CharManager.FEATURE_PACT_MAGIC then
			sFeatureName = sFeatureName .. " (" .. rAdd.sFeatureClassName .. ")";
			if CharManager.hasFeature(rAdd.nodeChar, sFeatureName) then
				return;
			end
		else
			return;
		end
	end

	-- Add standard feature record, and adjust name
	local vNew = CharClassManager.helperAddClassFeatureStandard(rAdd);
	DB.setValue(vNew, "name", "string", sFeatureName);

	-- Special handling
	if sSourceNameLower == CharManager.FEATURE_SPELLCASTING then
		CharClassManager.helperAddClassFeatureSpellcasting(rAdd);
	elseif sSourceNameLower == CharManager.FEATURE_PACT_MAGIC then
		CharClassManager.helperAddClassFeaturePactMagic(rAdd);
	elseif sSourceNameLower == CharManager.FEATURE_DRACONIC_RESILIENCE then
		CharClassManager.applyDraconicResilience(rAdd.nodeChar);
	elseif sSourceNameLower == CharManager.FEATURE_UNARMORED_DEFENSE then
		CharClassManager.applyUnarmoredDefense(rAdd.nodeChar, rAdd.nodeClass);
	elseif sSourceNameLower == CharManager.FEATURE_MAGIC_ITEM_ADEPT or
			sSourceNameLower == CharManager.FEATURE_MAGIC_ITEM_SAVANT or
			sSourceNameLower == CharManager.FEATURE_MAGIC_ITEM_MASTER then
		CharClassManager.applyAttunementAdjust(rAdd.nodeChar, 1);
	else
		if not rAdd.bWizard then
			if sSourceNameLower == CharManager.FEATURE_ELDRITCH_INVOCATIONS then
				-- Note: Bypass skill proficiencies due to false positive in skill proficiency detection
			else
				CharManager.checkSkillProficiencies(rAdd.nodeChar, DB.getText(vNew, "text", ""));
			end
		end
	end

	-- Standard action addition handling
	CharManager.helperCheckActionsAdd(rAdd.nodeChar, rAdd.nodeSource, rAdd.sSourceType, rAdd.sFeatureClassName .. " Actions/Effects");
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
function helperAddClassFeatureSpellcasting(rAdd)
	-- Add spell casting ability
	local sSpellcasting = DB.getText(rAdd.nodeSource, "text", "");
	local sAbility = sSpellcasting:match("(%a+) is your spellcasting ability");
	if sAbility then
		local sSpellsLabel = Interface.getString("power_label_groupspells");
		local sLowerSpellsLabel = sSpellsLabel:lower();
		
		local bFoundSpellcasting = false;
		for _,vGroup in ipairs(DB.getChildList(rAdd.nodeChar, "powergroup")) do
			if DB.getValue(vGroup, "name", ""):lower() == sLowerSpellsLabel then
				bFoundSpellcasting = true;
				break;
			end
		end
		
		local sNewGroupName = sSpellsLabel;
		if bFoundSpellcasting then
			sNewGroupName = sNewGroupName .. " (" .. rAdd.sFeatureClassName .. ")";
		end
		
		local nodePowerGroups = DB.createChild(rAdd.nodeChar, "powergroup");
		local nodeNewGroup = DB.createChild(nodePowerGroups);
		DB.setValue(nodeNewGroup, "castertype", "string", "memorization");
		DB.setValue(nodeNewGroup, "stat", "string", sAbility:lower());
		DB.setValue(nodeNewGroup, "name", "string", sNewGroupName);
		
		if sSpellcasting:match("Preparing and Casting Spells") then
			local rActor = ActorManager.resolveActor(rAdd.nodeChar);
			DB.setValue(nodeNewGroup, "prepared", "number", math.min(1 + ActorManager5E.getAbilityBonus(rActor, sAbility:lower())));
		end
	end
	
	-- Add spell slot calculation info
	if rAdd.nodeClass then
		if DB.getValue(rAdd.nodeClass, "casterlevelinvmult", 0) == 0 then
			local nFeatureLevel = DB.getValue(rAdd.nodeSource, "level", 0);
			if nFeatureLevel > 0 then
				if (rAdd.sFeatureClassName:lower() == CharManager.CLASS_ARTIFICER) then
					DB.setValue(rAdd.nodeClass, "casterlevelinvmult", "number", -2);
				else
					DB.setValue(rAdd.nodeClass, "casterlevelinvmult", "number", nFeatureLevel);
				end
			end
		end
	end
end
function helperAddClassFeaturePactMagic(rAdd)
	-- Add spell casting ability
	local sAbility = DB.getText(rAdd.nodeSource, "text", ""):match("(%a+) is your spellcasting ability");
	if sAbility then
		local sSpellsLabel = Interface.getString("power_label_groupspells");
		local sLowerSpellsLabel = sSpellsLabel:lower();
		
		local bFoundSpellcasting = false;
		for _,vGroup in ipairs(DB.getChildList(rAdd.nodeChar, "powergroup")) do
			if DB.getValue(vGroup, "name", ""):lower() == sLowerSpellsLabel then
				bFoundSpellcasting = true;
				break;
			end
		end
		
		local sNewGroupName = sSpellsLabel;
		if bFoundSpellcasting then
			sNewGroupName = sNewGroupName .. " (" .. rAdd.sFeatureClassName .. ")";
		end
		
		local nodePowerGroups = DB.createChild(rAdd.nodeChar, "powergroup");
		local nodeNewGroup = DB.createChild(nodePowerGroups);
		DB.setValue(nodeNewGroup, "castertype", "string", "memorization");
		DB.setValue(nodeNewGroup, "stat", "string", sAbility:lower());
		DB.setValue(nodeNewGroup, "name", "string", sNewGroupName);
	end
	
	-- Add spell slot calculation info
	if rAdd.nodeClass then
		local nFeatureLevel = DB.getValue(rAdd.nodeSource, "level", 0);
		if nFeatureLevel > 0 then
			DB.setValue(rAdd.nodeClass, "casterpactmagic", "number", 1);
			if DB.getValue(rAdd.nodeClass, "casterlevelinvmult", 0) == 0 then
				DB.setValue(rAdd.nodeClass, "casterlevelinvmult", "number", nFeatureLevel);
			end
		end
	end
end

function getCharClassMagicData(nodeChar)
	local tCharClassMagicData = {};
	local nSpellClasses = 0;
	for _,vClass in ipairs(DB.getChildList(nodeChar, "classes")) do
		local sClassName = DB.getValue(vClass, "name", "");
		local nClassLevel = DB.getValue(vClass, "level", 0);
		local bPactMagic = (DB.getValue(vClass, "casterpactmagic", 0) > 0);
		local nSpellSlotMult = DB.getValue(vClass, "casterlevelinvmult", 0);
		if nSpellSlotMult > 0 then
			nSpellClasses = nSpellClasses + 1;
		end
		table.insert(tCharClassMagicData, { sName = sClassName, nLevel = nClassLevel, bPactMagic = bPactMagic, nSpellSlotMult = nSpellSlotMult });
	end
	tCharClassMagicData.nSpellClasses = nSpellClasses;
	return tCharClassMagicData;
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
	local tCharClassMagicData = CharClassManager.getCharClassMagicData(nodeChar);
	return CharClassManager.helperCalcSpellcastingLevel(tCharClassMagicData);
end
function helperCalcSpellcastingLevel(tCharClassMagicData)
	local nCurrSpellCastLevel = 0;
	for _,tClass in ipairs(tCharClassMagicData) do
		if not tClass.bPactMagic then
			if tClass.nSpellSlotMult > 0 then
				local nClassSpellCastLevel;
				if tCharClassMagicData.nSpellClasses > 1 then
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
	local tCharClassMagicData = CharClassManager.getCharClassMagicData(nodeChar);
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

function applyUnarmoredDefense(nodeChar, nodeClass)
	local sAbility = "";
	local sClassLower = DB.getValue(nodeClass, "name", ""):lower();
	if sClassLower == CharManager.CLASS_BARBARIAN then
		sAbility = "constitution";
	elseif sClassLower == CharManager.CLASS_MONK then
		sAbility = "wisdom";
	end
	
	if sAbility == "" then
		return;
	end
	if (DB.getValue(nodeChar, "defenses.ac.stat2", "") ~= "") then
		return;
	end
	if CharArmorManager.hasNaturalArmor(nodeChar) then
		return;
	end

	DB.setValue(nodeChar, "defenses.ac.stat2", "string", sAbility);
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
