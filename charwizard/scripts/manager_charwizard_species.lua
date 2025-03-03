--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--
--	Data
--

function getSpeciesRecord()
	local tSpecies = CharWizardManager.getSpeciesData();
	return tSpecies.species;
end
function getSpeciesNode()
	local sRecord = CharWizardSpeciesManager.getSpeciesRecord();
	if (sRecord or "") == "" then
		return nil;
	end
	return DB.findNode(sRecord);
end
function setSpeciesRecord(sRecord)
	local tSpecies = CharWizardManager.getSpeciesData();
	tSpecies.species = sRecord;
	if ((sRecord or "") ~= "") then
		tSpecies.bIs2024 = (DB.getValue(DB.findNode(sRecord), "version", "") == "2024");
	else
		tSpecies.bIs2024 = nil;
	end
	CharWizardManager.updateAlerts();
end
function getAncestryRecord(sRecord)
	local tSpecies = CharWizardManager.getSpeciesData();
	return tSpecies.ancestry;
end
function setAncestryRecord(sRecord)
	local tSpecies = CharWizardManager.getSpeciesData();
	tSpecies.ancestry = sRecord;
end
function isSpecies2024()
	local tSpecies = CharWizardManager.getSpeciesData();
	return tSpecies.bIs2024;
end
function getSpeciesName()
	local tSpecies = CharWizardManager.getSpeciesData();
	if (tSpecies.species or "") == "" then
		return "";
	end
	return DB.getValue(DB.findNode(tSpecies.species), "name", "");
end
function getSpeciesDisplayName()
	local tSpecies = CharWizardManager.getSpeciesData();
	if (tSpecies.species or "") == "" then
		return "";
	end
	local sSpecies = DB.getValue(DB.findNode(tSpecies.species), "name", "");
	if (tSpecies.ancestry or "") == "" then
		return sSpecies:upper();
	end
	local sAncestry = DB.getValue(DB.findNode(tSpecies.ancestry), "name", "");
	return string.format("%s (%s)", sSpecies:upper(), sAncestry);
end
function setSpeciesSize(s)
	local tSpecies = CharWizardManager.getSpeciesData();
	tSpecies.size = s;
end
function setSpeciesSpeed(n)
	local tSpecies = CharWizardManager.getSpeciesData();
	tSpecies.speed = n;
end
function addSpeciesSpecialMove(s, vDist)
	local nDist = math.max(tonumber(vDist) or 0, 0);
	if not nodeChar or ((s or "") == "") then
		return;
	end

	local tSplit = StringManager.splitByPattern(tSpecies.speedspecial, ",", true);

	if nDist == 0 then
		if StringManager.contains(tSplit, s) then
			return;
		end
		table.insert(tSplit, s);
	else
		local sNewMove = string.format("%s %d", s, nDist);
		local sPatternMove = string.format("^%s %%d+$", s);
		local bPatternMatch = false;
		for k,v in ipairs(tSplit) do
			local sPatternMatch = sSpecialMove:match(sPatternMove);
			if sPatternMatch then
				if (tonumber(sPatternMatch) or 0) >= nDist then
					return;
				end
				tSplit[k] = sNewMove;
				bPatternMatch = true;
				break;
			end
		end
		if not bPatternMatch then
			table.insert(tSplit, sNewMove);
		end
	end

	tSpecies.speedspecial = table.concat(tSplit, ", ");
end
function setSpeciesDarkvision(n)
	local tSpecies = CharWizardManager.getSpeciesData();
	if tSpecies.darkvision and (n < tSpecies.darkvision) then
		return;
	end
	tSpecies.darkvision = n;
end
function addSpeciesAbilityIncreases(sAbility, nMod)
	if ((sAbility or "") == "") then
		return;
	end
	local tSpecies = CharWizardManager.getSpeciesData();
	tSpecies.abilityincrease = tSpecies.abilityincrease or {};
	for _,v in ipairs(tSpecies.abilityincrease) do
		if v.ability:lower() == sAbility:lower() then
			v.mod = v.mod + nMod;
			return;
		end
	end
	table.insert(tSpecies.abilityincrease, { ability = sAbility, mod = nMod } );
end
function clearSpeciesAbilityIncreases()
	local tSpecies = CharWizardManager.getSpeciesData();
	tSpecies.abilityincrease = {};
end
function setSpeciesBaseSkills(tSkills)
	local tSpecies = CharWizardManager.getSpeciesData();
	tSpecies.skill = tSpecies.skill or {};
	for _,v in pairs(tSkills) do
		table.insert(tSpecies.skill, v);
	end
end
function addSpeciesSkillChoice(s)
	if (s or "") == "" then
		return;
	end
	local tSpecies = CharWizardManager.getSpeciesData();
	tSpecies.skillchoice = tSpecies.skillchoice or {};
	if StringManager.contains(tSpecies.skillchoice, s) then
		return;
	end
	table.insert(tSpecies.skillchoice, s);
end
function clearSpeciesSkillChoice()
	local tSpecies = CharWizardManager.getSpeciesData();
	tSpecies.skillchoice = {};
end
function setSpeciesBaseLanguages(tLanguages)
	local tSpecies = CharWizardManager.getSpeciesData();
	tSpecies.language = tSpecies.language or {};
	for _,v in pairs(tLanguages) do
		table.insert(tSpecies.language, v);
	end
end
function addSpeciesLanguageChoice(s)
	if (s or "") == "" then
		return;
	end
	local tSpecies = CharWizardManager.getSpeciesData();
	tSpecies.languagechoice = tSpecies.languagechoice or {};
	if StringManager.contains(tSpecies.languagechoice, s) then
		return;
	end
	table.insert(tSpecies.languagechoice, s);
end
function clearSpeciesLanguageChoice()
	local tSpecies = CharWizardManager.getSpeciesData();
	tSpecies.languagechoice = {};
end
function setSpeciesBaseArmorProficiencies(tProfs)
	local tSpecies = CharWizardManager.getSpeciesData();
	tSpecies.armorprof = {};
	for _,v in pairs(tProfs) do
		table.insert(tSpecies.armorprof, v);
	end
end
function addSpeciesArmorProficiencyChoice(s)
	if (s or "") == "" then
		return;
	end
	local tSpecies = CharWizardManager.getSpeciesData();
	tSpecies.armorprofchoice = tSpecies.armorprofchoice or {};
	if StringManager.contains(tSpecies.armorprofchoice, s) then
		return;
	end
	table.insert(tSpecies.armorprofchoice, s);
end
function clearSpeciesArmorProficiencyChoice()
	local tSpecies = CharWizardManager.getSpeciesData();
	tSpecies.armorprofchoice = {};
end
function setSpeciesBaseWeaponProficiencies(tProfs)
	local tSpecies = CharWizardManager.getSpeciesData();
	tSpecies.weaponprof = {};
	for _,v in pairs(tProfs) do
		table.insert(tSpecies.weaponprof, v);
	end
end
function addSpeciesWeaponProficiencyChoice(s)
	if (s or "") == "" then
		return;
	end
	local tSpecies = CharWizardManager.getSpeciesData();
	tSpecies.weaponprofchoice = tSpecies.weaponprofchoice or {};
	if StringManager.contains(tSpecies.weaponprofchoice, s) then
		return;
	end
	table.insert(tSpecies.weaponprofchoice, s);
end
function clearSpeciesWeaponProficiencyChoice()
	local tSpecies = CharWizardManager.getSpeciesData();
	tSpecies.weaponprofchoice = {};
end
function setSpeciesBaseToolProficiencies(tProfs)
	local tSpecies = CharWizardManager.getSpeciesData();
	tSpecies.toolprof = {};
	for _,v in pairs(tProfs) do
		table.insert(tSpecies.toolprof, v);
	end
end
function addSpeciesToolProficiencyChoice(s)
	if (s or "") == "" then
		return;
	end
	local tSpecies = CharWizardManager.getSpeciesData();
	tSpecies.toolprofchoice = tSpecies.toolprofchoice or {};
	if StringManager.contains(tSpecies.toolprofchoice, s) then
		return;
	end
	table.insert(tSpecies.toolprofchoice, s);
end
function clearSpeciesToolProficiencyChoice()
	local tSpecies = CharWizardManager.getSpeciesData();
	tSpecies.toolprofchoice = {};
end

function addSpeciesBaseFeat(s)
	if (s or "") == "" then
		return;
	end
	local tSpecies = CharWizardManager.getSpeciesData();
	tSpecies.feats = tSpecies.feats or {};
	table.insert(tSpecies.feats, s);
end
function addSpeciesChoiceFeatPath(sPath)
	if (sPath or "") == "" then
		return;
	end
	local tSpecies = CharWizardManager.getSpeciesData();
	tSpecies.featpaths = tSpecies.featpaths or {};
	table.insert(tSpecies.featpaths, sPath);
end
function removeSpeciesChoiceFeatPath(sPath)
	if (sPath or "") == "" then
		return;
	end
	local tSpecies = CharWizardManager.getSpeciesData();
	for k,v in ipairs(tSpecies.featpaths or {}) do
		if v == sPath then
			table.remove(tSpecies.featpaths, k);
			return;
		end
	end
end

function setSpeciesSpellAbility(sAbility)
	if not sAbility then
		tSpecies.spellability = nil;
		return;
	end
	sAbility = sAbility:lower();
	local tSpecies = CharWizardManager.getSpeciesData();
	if StringManager.contains(DataCommon.abilities, sAbility) then
		tSpecies.spellability = sAbility;
	else
		tSpecies.spellability = nil;
	end
end
function setSpeciesBaseSpells(tSpells)
	local tSpecies = CharWizardManager.getSpeciesData();
	tSpecies.spell = tSpecies.spell or {};
	for _,s in pairs(tSpells) do
		table.insert(tSpecies.spell, s);
	end
end
function addSpeciesSpellChoice(s)
	if (s or "") == "" then
		return;
	end
	local tSpecies = CharWizardManager.getSpeciesData();
	tSpecies.spellchoice = tSpecies.spellchoice or {};
	if StringManager.contains(tSpecies.spellchoice, s) then
		return;
	end
	table.insert(tSpecies.spellchoice, s);
end
function clearSpeciesSpellChoice()
	local tSpecies = CharWizardManager.getSpeciesData();
	tSpecies.spellchoice = {};
end

--
--	Windows
--

function processSpecies(w)
	local _,sRecord = w.shortcut.getValue();

	CharWizardSpeciesManager.setSpeciesRecord(sRecord);

	local sSpecies = DB.getValue(DB.findNode(sRecord), "name", "");

	local wSpecies = CharWizardManager.getWizardSpeciesWindow();
	wSpecies.sub_speciesselection.setVisible(false);
	wSpecies.button_changespecies.setVisible(true);
	wSpecies.list_features.setVisible(true);
	wSpecies.ancestry_selection_list.setVisible(true);
	wSpecies.ancestry_selection_header.setVisible(true);
	wSpecies.species_select_header.setValue(sSpecies:upper());

	CharWizardSpeciesManager.updateSpeciesFields(wSpecies.list_features);
	CharWizardSpeciesManager.updateSpeciesTraits(wSpecies.list_features);
	CharWizardSpeciesManager.setupAncestries(wSpecies.ancestry_selection_list);
	CharWizardManager.updateAlerts();
end
function resetSpecies(w)
	CharWizardManager.clearSpeciesData();

	local wSpecies = CharWizardManager.getWizardSpeciesWindow();
	wSpecies.sub_speciesselection.setVisible(true);
	wSpecies.button_changespecies.setVisible(false);
	wSpecies.list_features.setVisible(false);
	wSpecies.list_features.closeAll();
	wSpecies.ancestry_selection_list.setVisible(false);
	wSpecies.ancestry_selection_list.closeAll();
	wSpecies.ancestry_selection_header.setVisible(false);
	wSpecies.button_changeancestry.setVisible(false);
	wSpecies.species_select_header.setValue(Interface.getString("charwizard_label_speciesselection"));

	CharWizardAbilitiesManager.updateAbilities();
	CharWizardDecisionManager.refreshOverallDecisions();
	CharWizardManager.updateAlerts();
end

--
-- Ancestries
--

function collectAncestries()
	local sRecord = CharWizardSpeciesManager.getSpeciesRecord();
	if (sRecord or "") == "" then
		return {};
	end

	local tFinalAncestries = {};
	local tAncestries = CharSpeciesManager.getAncestryOptions(DB.findNode(sRecord));
	for _,v in ipairs(tAncestries) do
		if not tFinalAncestries[v.text] then
			tFinalAncestries[v.text] = {};
		end

		v.sModuleName = DB.getModule(vNode);
		v.sModule = ModuleManager.getModuleDisplayName(v.sModuleName);
		if StringManager.contains(CharWizardData.module_order_2014, v.sModuleName) then 
		local sLegacySuffix = Interface.getString("suffix_legacy");
			if not StringManager.endsWith(v.sModule, sLegacySuffix) then
				v.sModule = string.format("%s %s", v.sModule, sLegacySuffix);
			end
		end

		table.insert(tFinalAncestries[v.text], v);
	end

	return tFinalAncestries;
end
function setupAncestries(w)
	local tAncestries = CharWizardSpeciesManager.collectAncestries();
	local nCount = 0;
	for k,v in pairs(tAncestries) do
		nCount = nCount + 1;

		local wAncestry = w.createWindow();
		wAncestry.button_select.setVisible(true);
		wAncestry.name.setValue(k);
		wAncestry.module.setVisible(true);

		local tModules = {};
		for _,v2 in ipairs(v) do
			local nOrder;
			for k3,v3 in ipairs(CharWizardData.module_order_2024) do
				if v2.sModuleName == v3 then
					nOrder = k2;
					break
				else
					for k4,v4 in ipairs(CharWizardData.module_order_2014) do
						if v2.sModuleName == v3 then
							nOrder = k3 + 1;
							break
						end
					end
				end
			end
			if nOrder then
				table.insert(tModules, nOrder, v2.sModule);
			else
				table.insert(tModules, v2.sModule);
			end
		end

		local tFinalModules = {};
		for _,v in pairs(tModules) do
			table.insert(tFinalModules, v);
		end
		wAncestry.module.addItems(tFinalModules);
		wAncestry.module.setVisible(true);

		if #tFinalModules == 1 then
			wAncestry.module.setComboBoxReadOnly(true);
			wAncestry.module.setFrame(nil);
		end

		wAncestry.module.setValue(tFinalModules[1]);
	end

	w.window.ancestry_selection_header.setVisible(nCount > 0);
	w.setVisible(nCount > 0);
end
function processAncestry(w)
	local _,sRecord = w.shortcut.getValue();

	CharWizardSpeciesManager.setAncestryRecord(sRecord);

	local wSpecies = CharWizardManager.getWizardSpeciesWindow();
	wSpecies.ancestry_selection_list.setVisible(false);
	wSpecies.species_select_header.setValue(CharWizardSpeciesManager.getSpeciesDisplayName());
	wSpecies.ancestry_selection_header.setVisible(false);
	wSpecies.button_changeancestry.setVisible(true);

	CharWizardSpeciesManager.updateSpeciesTraits(wSpecies.list_features, true);
end
function resetAncestry(w)
	CharWizardSpeciesManager.clearAncestryTraits(w);
	CharWizardSpeciesManager.setAncestryRecord(nil);

	local wSpecies = CharWizardManager.getWizardSpeciesWindow();
	wSpecies.button_changeancestry.setVisible(false);
	wSpecies.ancestry_selection_header.setVisible(true);
	wSpecies.ancestry_selection_list.setVisible(true);
	wSpecies.species_select_header.setValue(CharWizardSpeciesManager.getSpeciesDisplayName());

	for _,v in pairs(w.list_features.getWindows()) do
		for _,v2 in pairs(v.list_decisions.getWindows()) do
			if v2.decisiontype.getValue() ~= "asispeciesoption" then
				CharWizardSpeciesManager.processSpeciesDecision(v2);
			end
		end
	end

	CharWizardAbilitiesManager.updateAbilities();
	CharWizardDecisionManager.refreshOverallDecisions();
	CharWizardManager.updateAlerts();
end

--
--	Fields
--

function updateSpeciesFields(w)
	if CharWizardSpeciesManager.isSpecies2024() then
		CharWizardSpeciesManager.handleSpeciesSizeField2024(w);
		CharWizardSpeciesManager.handleSpeciesSpeedField2024(w);
		CharWizardSpeciesManager.handleSpeciesLanguage2024(w);
	end
end
function handleSpeciesSizeField2024(w)
	local sRecord = CharWizardSpeciesManager.getSpeciesRecord();
	if (sRecord or "") == "" then
		return {};
	end

	local sSize = DB.getValue(DB.findNode(sRecord), "size", "");
	local tOptions = CharBuildManager.parseSizesFromString(sSize);
	if #tOptions > 1 then
		local w2 = w.createWindow();
		w2.feature.setValue(Interface.getString("race_label_size"));
		w2.feature_desc.setValue(sSize);

		local w3 = CharWizardDecisionManager.createDecision(w2, { sDecisionType = "size", });
		for _,v in pairs(tOptions) do
			w3.decision_choice.add(v);
		end
	else
		CharWizardSpeciesManager.setSpeciesSize(tOptions[1]);
	end
end
function handleSpeciesSpeedField2024(w)
	local sRecord = CharWizardSpeciesManager.getSpeciesRecord();
	if (sRecord or "") == "" then
		return {};
	end

	local sSpeed = DB.getValue(DB.findNode(sRecord), "speed", ""):match("%d+");
	CharWizardSpeciesManager.setSpeciesSpeed(tonumber(sSpeed) or 30);
end
function handleSpeciesLanguage2024(w)
	local w2 = w.createWindow();
	w2.feature.setValue(Interface.getString("charwizard_label_languages"));
	w2.feature_desc.setValue(Interface.getString("charwizard_message_languages"));

	local tBase, tOptions, nPicks = CharBuildManager.getSpeciesLanguages2024()

	CharWizardSpeciesManager.setSpeciesBaseLanguages(tBase);

	if nPicks >= #tOptions then
		for _,v in ipairs(tOptions) do
			CharWizardSpeciesManager.addSpeciesLanguageChoice(v);
		end
	else
		CharWizardDecisionManager.createDecisions(w2, { sDecisionType = "language", nPicks = nPicks, tOptions = tOptions, });
	end

	CharWizardDecisionManager.refreshOverallDecision("language");
end

--
-- Traits
--

function clearAncestryTraits(w)
	local tSpeciesTraits = {};
	CharWizardSpeciesManager.collectAncestryTraits(tSpeciesTraits);
	
	local tTraits = {};
	for _,v in pairs(tSpeciesTraits) do
		tTraits[v.speciestrait] = true;
	end

	local wSpecies = CharWizardManager.getWizardSpeciesWindow();
	for _,v in ipairs(wSpecies.list_features.getWindows()) do
		local _,sRecord = v.shortcut.getValue();
		if tTraits[sRecord] then
			v.close();
		end
	end
end
function updateSpeciesTraits(w, bAncestry)
	local tSpeciesTraits = {};
	if bAncestry then
		CharWizardSpeciesManager.collectAncestryTraits(tSpeciesTraits);
	else
		CharWizardSpeciesManager.collectSpeciesTraits(tSpeciesTraits);
	end

	local bIs2024 = CharWizardSpeciesManager.isSpecies2024();
	local bAbilityScore = false;
	for kTrait,vTrait in pairs(tSpeciesTraits) do
		local sParseText = StringManager.trim(DB.getText(DB.findNode(vTrait.speciestrait), "text", ""));

		local w2 = w.createWindow();
		w2.feature.setValue(kTrait);
		w2.shortcut.setValue("reference_racialtrait", vTrait.speciestrait);
		w2.feature_desc.setValue(DB.getValue(DB.findNode(vTrait.speciestrait), "text", ""));

		local sTraitType = StringManager.simplify(kTrait):gsub(StringManager.simplify(Interface.getString("library_recordtype_single_race_subrace")) .. "$", "");
		if bIs2024 then
			if sTraitType == "darkvision" then
				local sDarkVision = sParseText:match("(%d+)");
				if sDarkVision then
					CharWizardSpeciesManager.setSpeciesDarkvision(tonumber(sDarkVision) or 60);
				end
			elseif sTraitType == "enhanceddarkvision" then
				local sDarkVision = sParseText:match("(%d+)");
				if sDarkVision then
					CharWizardSpeciesManager.setSpeciesDarkvision(tonumber(sDarkVision) or 120);
				end
			else
				if CharWizardData.tBuildOptionsSpecialSpeed2024[sTraitType] then
					CharWizardSpeciesManager.handleSpeciesSpeedTrait(w2, sParseText, true);
				end
				if CharWizardData.tBuildOptionsSkill2024[sTraitType] then
					CharWizardSpeciesManager.handleSpeciesSkills(w2, sTraitType, sParseText);
				end
				if CharWizardData.tBuildOptionsProficiency2024[sTraitType] then
					CharWizardSpeciesManager.handleSpeciesProficiencies(w2, sTraitType, sParseText);
				end
				if CharWizardData.tBuildOptionsSpells2024[sTraitType] then
					CharWizardSpeciesManager.handleSpeciesSpells(w2, sTraitType, sParseText);
				end
				if CharWizardData.tBuildOptionsFeats2024[sTraitType] then
					CharWizardSpeciesManager.handleSpeciesFeat(w2, sTraitType, sParseText);
				end
			end
		else
			if sTraitType:match("abilityscoreincrease") then
				CharWizardSpeciesManager.handleAbilityScoreInc(w2, sParseText);
				bAbilityScore = true;
			elseif sTraitType:match("size") then
				CharWizardSpeciesManager.handleSpeciesSizeTrait(w2, sParseText);
			elseif sTraitType:match("speed") then
				CharWizardSpeciesManager.handleSpeciesSpeedTrait(w2, sParseText, false);
			elseif sTraitType == "variabletrait" then
				CharWizardDecisionManager.createDecision(w2, { sDecisionType = "variabletrait", });
			elseif sTraitType == "darkvision" then
				local sDarkVision = sParseText:match("(%d+)");
				if sDarkVision then
					CharWizardSpeciesManager.setSpeciesDarkvision(tonumber(sDarkVision) or 60);
				end
			elseif sTraitType == "superiordarkvision" then
				local sDarkVision = sParseText:match("(%d+)");
				if sDarkVision then
					CharWizardSpeciesManager.setSpeciesDarkvision(tonumber(sDarkVision) or 120);
				end
			elseif sTraitType == "feat" then
				CharWizardSpeciesManager.handleSpeciesFeat(w2, sTraitType, sParseText);
			else
				if CharWizardData.aRaceSpecialSpeed[sTraitType] then
					CharWizardSpeciesManager.handleSpeciesSpeedTrait(w2, sParseText, true);
				end
				if CharWizardData.aRaceSkill[sTraitType] then
					CharWizardSpeciesManager.handleSpeciesSkills(w2, sTraitType, sParseText);
				end
				if CharWizardData.aRaceProficiency[sTraitType] then
					CharWizardSpeciesManager.handleSpeciesProficiencies(w2, sTraitType, sParseText);
				end
				if CharWizardData.aRaceLanguages[sTraitType] then
					CharWizardSpeciesManager.handleSpeciesLanguages(w2, sTraitType, sParseText);
				end
				if CharWizardData.aRaceSpells[sTraitType] then
					CharWizardSpeciesManager.handleSpeciesSpells(w2, sTraitType, sParseText);
				end
			end
		end
	end

	if not bIs2024 and not bAbilityScore and not bAncestry then
		CharWizardSpeciesManager.handleMissingSpeciesASI(w);
	end

	CharWizardManager.updateAlerts();
end
function handleMissingSpeciesASI(w)
	local w2 = w.createWindow();
	w2.feature.setValue("Ability Score Increase");
	w2.shortcut.setValue();
	w2.feature_desc.setValue();

	CharWizardDecisionManager.createDecision(w2, { sDecisionType = "asispeciesoption", });
end
function collectSpeciesTraits(tSpeciesTraits)
	local sRecord = CharWizardSpeciesManager.getSpeciesRecord();
	if (sRecord or "") == "" then
		return;
	end
	for _,v in pairs(DB.getChildren(DB.findNode(sRecord), "traits")) do
		local sTrait = DB.getValue(v, "name", "");
		if sTrait:lower() ~= "subrace" then
			tSpeciesTraits[sTrait] = { speciestrait = DB.getPath(v), };
		end
	end
end
function collectAncestryTraits(tSpeciesTraits)
	local sRecord = CharWizardSpeciesManager.getAncestryRecord();
	if (sRecord or "") == "" then
		return;
	end
	for _,v in pairs(DB.getChildren(DB.findNode(sRecord), "traits")) do
		local sTrait = DB.getValue(v, "name", "");
		sTrait = string.format("%s (%s)", sTrait, Interface.getString("library_recordtype_single_race_subrace"));
		tSpeciesTraits[sTrait] = { speciestrait = DB.getPath(v), };
	end
end

function handleAbilityScoreInc(w, s)
	w.feature_desc.setValue(s);

	if s:lower():match("alternatively") then
		CharWizardSpeciesManager.helperSpeciesAbilityScoreGeneric2014(w);
	else
		CharWizardSpeciesManager.helperSpeciesAbilityScoreSpecific2014(w, s);
	end
end
-- Handle generic ability score option choices (+2/+1 or +1 x3)
function helperSpeciesAbilityScoreGeneric2014(w)
	CharWizardDecisionManager.createDecision(w, { sDecisionType = "asispeciesoption", });
end
-- Due to Tasha's rules, set up decisions for every ability increase
function helperSpeciesAbilityScoreSpecific2014(w, s)
	local tBase, tAbilitySelect = CharSpeciesManager.helperParseSpeciesAbilityIncrease2014(s);

	CharWizardSpeciesManager.clearSpeciesAbilityIncreases();

	local tBaseWindows = {};
	for sAbility, nAbilityAdj in pairs(tBase) do
		tBaseWindows[sAbility] = CharWizardDecisionManager.createDecision(w, { sDecisionType = "asispecies", nAdj = nAbilityAdj });
	end
	for _,v in pairs(tAbilitySelect) do
		CharWizardDecisionManager.createDecisions(w, { sDecisionType = "asispecies", nAdj = v.nAbilityAdj or 1, nPicks = v.nPicks });
	end
	for sAbility, wDecision in pairs(tBaseWindows) do
		wDecision.decision_choice.setListValue(StringManager.capitalize(sAbility));
	end

	CharWizardAbilitiesManager.updateAbilities();
end

function handleSpeciesSizeTrait(w, s)
	local tChoices, sSize = CharWizardSpeciesManager.parseSpeciesSizeTrait(s);
	if next(tChoices) then
		local w2 = CharWizardDecisionManager.createDecision(w, { sDecisionType = "size", });
		for _,v in pairs(tChoices) do
			w2.decision_choice.add(StringManager.capitalize(v));
		end
	else
		CharWizardSpeciesManager.setSpeciesSize(sSize);
	end
end
function handleSpeciesSpeedTrait(w, s, bSpecialTrait)
	local nSpeed, tSpecial = CharSpeciesManager.helperParseSpeciesSpeed2014(s);

	CharWizardSpeciesManager.setSpeciesSpeed(nSpeed);
	for k,v in ipairs(tSpecial) do
		CharWizardSpeciesManager.addSpeciesSpecialMove(k, v);
	end
end

function handleSpeciesSkills(w, sTrait, s)
	local bIs2024 = CharWizardSpeciesManager.isSpecies2024();
	local tBase, tOptions, nPicks = CharBuildManager.getSpeciesTraitSkills(sTrait, s, bIs2024);

	CharWizardSpeciesManager.setSpeciesBaseSkills(tBase);

	if nPicks >= #tOptions then
		for _,v in ipairs(tOptions) do
			CharWizardSpeciesManager.addSpeciesSkillChoice(v);
		end
	else
		CharWizardDecisionManager.createDecisions(w, { sDecisionType = "skill", nPicks = nPicks, tOptions = tOptions, });
	end

	CharWizardDecisionManager.refreshOverallDecision("skill");
	CharWizardDecisionManager.refreshExpertiseDecision();
end
function handleSpeciesProficiencies(w, sTrait, s)
	CharWizardSpeciesManager.handleSpeciesArmorProficiencies(w, sTrait, s);
	CharWizardSpeciesManager.handleSpeciesWeaponProficiencies(w, sTrait, s);
	CharWizardSpeciesManager.handleSpeciesToolProficiencies(w, sTrait, s);
end
function handleSpeciesArmorProficiencies(w, sTrait, s)
	local bIs2024 = CharWizardSpeciesManager.isSpecies2024();
	local tBase, tOptions, nPicks = CharBuildManager.getSpeciesTraitArmorProf(sTrait, s, bIs2024)

	CharWizardSpeciesManager.setSpeciesBaseArmorProficiencies(tBase);

	if nPicks >= #tOptions then
		for _,v in ipairs(tOptions) do
			CharWizardSpeciesManager.addSpeciesArmorProficiencyChoice(v);
		end
	else
		CharWizardDecisionManager.createDecisions(w, { sDecisionType = "armorprof", nPicks = nPicks, tOptions = tOptions, });
	end

	CharWizardDecisionManager.refreshOverallDecision("armorprof");
end
function handleSpeciesWeaponProficiencies(w, sTrait, s)
	local bIs2024 = CharWizardSpeciesManager.isSpecies2024();
	local tBase, tOptions, nPicks = CharBuildManager.getSpeciesTraitWeaponProf(sTrait, s, bIs2024)

	CharWizardSpeciesManager.setSpeciesBaseWeaponProficiencies(tBase);

	if nPicks >= #tOptions then
		for _,v in ipairs(tOptions) do
			CharWizardSpeciesManager.addSpeciesWeaponProficiencyChoice(v);
		end
	else
		CharWizardDecisionManager.createDecisions(w, { sDecisionType = "weaponprof", nPicks = nPicks, tOptions = tOptions, });
	end

	CharWizardDecisionManager.refreshOverallDecision("weaponprof");
end
function handleSpeciesToolProficiencies(w, sTrait, s)
	local bIs2024 = CharWizardSpeciesManager.isSpecies2024();
	local tBase, tOptions, nPicks = CharBuildManager.getSpeciesTraitToolProf(sTrait, s, bIs2024)

	CharWizardSpeciesManager.setSpeciesBaseToolProficiencies(tBase);

	if nPicks >= #tOptions then
		for _,v in ipairs(tOptions) do
			CharWizardSpeciesManager.addSpeciesToolProficiencyChoice(v);
		end
	else
		CharWizardDecisionManager.createDecisions(w, { sDecisionType = "toolprof", nPicks = nPicks, tOptions = tOptions, });
	end

	CharWizardDecisionManager.refreshOverallDecision("toolprof");
end
function handleSpeciesLanguages(w, sTrait, s)
	local bIs2024 = CharWizardSpeciesManager.isSpecies2024();
	local tBase, tOptions, nPicks = CharBuildManager.getSpeciesTraitLanguages(sTrait, s, bIs2024)

	CharWizardSpeciesManager.setSpeciesBaseLanguages(tBase);

	if nPicks >= #tOptions then
		for _,v in ipairs(tOptions) do
			CharWizardSpeciesManager.addSpeciesLanguageChoice(v);
		end
	else
		CharWizardDecisionManager.createDecisions(w, { sDecisionType = "language", nPicks = nPicks, tOptions = tOptions, });
	end

	CharWizardDecisionManager.refreshOverallDecision("language");
end
function handleSpeciesSpells(w, sTrait, s)
	local bIs2024 = CharWizardSpeciesManager.isSpecies2024();
	local tBase, tOptions, nPicks = CharBuildManager.getSpeciesTraitSpells(sTrait, s, bIs2024);

	CharWizardSpeciesManager.setSpeciesBaseSpells(tBase);

	if nPicks >= #tOptions then
		for _,v in ipairs(tOptions) do
			CharWizardSpeciesManager.addSpeciesSpellChoice(v);
		end
	else
		CharWizardDecisionManager.createDecisions(w, { sDecisionType = "spell", nPicks = nPicks, tOptions = tOptions, });
	end

	local sAbility = s:match("(%a+) is your spellcasting ability");
	if sAbility then
		CharWizardSpeciesManager.setSpeciesSpellAbility(sAbility);
	end
end
function handleSpeciesFeat(w, sFeat, s, bIs2024)
	local bChoice, tFeats, tChoiceFeats, nChoices = CharWizardSpeciesManager.parseSpeciesFeats(s);
	for _,v in ipairs(tFeats) do
		CharWizardSpeciesManager.addSpeciesBaseFeat(v.name);
	end

	if bChoice then
		CharWizardDecisionManager.createDecision(w, { sDecisionType = "feat", sDecisionClass = "decision_sub_speciesfeat_choice", });
		w.alert.setVisible(true);
	end
end

--
--	Parsing
--

function parseSpeciesSizeTrait(s)
	local sSizeText = s:lower();
	local tChoices = {};
	local sSize = nil;

	if sSizeText:match("choice") then
		table.insert(tChoices, "small");
		table.insert(tChoices, "medium");
	else
		sSize = sSizeText:match("your size is (%w+)");
		if not sSize then
			sSize = sSizeText:match("you are (%w+)");
		end
		if not sSize then
			sSize = "Medium";
		end
	end

	return tChoices, sSize;
end
function parseSpeciesFeats(s)
	if not s then
		return false, {}, {}, 0;
	end
	s = s:lower();

	local sFeatText = s:match("you gain one feat of your choice");
	if not sFeatText then
		sFeatText = s:match("you gain an [%w%s]+ of your choice");
	end
	if not sFeatText then
		return false, {}, {}, 0;
	end

	local bChoice = false;
	local tSpeciesFeats = {};
	local tChoiceFeats = {};
	local nChoices = 1;

	local tAvailableFeats = CharBuildManager.getFeatNames(false);
	local aSortAvailableFeats = {};
	for k,v in pairs(tAvailableFeats) do
		aSortAvailableFeats[v] = "";
	end

	if sFeatText:match("choice") or sFeatText:match("choose") then
		if sFeatText:match("choice: ([^.]+)") or sFeatText:match("feats: ([^.]+)") then
			local sChoiceFeats = sFeatText:match("choice: ([^.]+)");

			if not sChoiceFeats then
				sChoiceFeats = sFeatText:match("feats: ([^.]+)");
			end

			if sChoiceFeats then
				sChoiceFeats = sChoiceFeats:gsub("and ", "");
				sChoiceFeats = sChoiceFeats:gsub("or ", "");

				local aWords = StringManager.split(sChoiceFeats, ",")
				for _,sWord in pairs(aWords) do
					local sFeatLower = StringManager.trim(sWord):lower();
					if aSortAvailableFeats[sFeatLower] then
						table.insert(tChoiceFeats, sWord);
					end
					if sWord == "two" then
						nChoices = 2;
					end
				end
			end
		else
			if sFeatText:match("of your choice") then
				if sFeatText:match("two ") then
					nChoices = 2;
				end
			end
		end

		bChoice = true;
	else
		sFeatText = sFeatText:gsub(" and ", " ")

		local aWords = StringManager.split(sFeatText, " ")
		for _,t in pairs(aWords) do
			if aSortAvailableFeats[t] then
				table.insert(tSpeciesFeats, t);
			end
		end
	end

	if not bChoice then
		return bChoice, tSpeciesFeats, nil, nChoices;
	end

	local aFinalFeats = {};
	for _,v in pairs(tAvailableFeats) do
		table.insert(aFinalFeats, v);
	end

	if #tChoiceFeats > 0 then
		local aFinalChoiceFeats = {};
		for _,v in pairs(tChoiceFeats) do
			v = StringManager.trim(v);
			if StringManager.contains(aFinalFeats, v) then
				table.insert(aFinalChoiceFeats, v);
			end
		end

		return bChoice, tSpeciesFeats, aFinalChoiceFeats, nChoices;
	end
	return bChoice, tSpeciesFeats, aFinalFeats, nChoices;
end

--
--	Decisions
--

local _bUpdatingDecision = false;
function processSpeciesDecision(w)
	if _bUpdatingDecision then
		return
	end
	_bUpdatingDecision = true;

	local sDecisionType = w.decisiontype.getValue();
	if sDecisionType == "asispeciesoption" then
		CharWizardSpeciesManager.processSpeciesDecisionASIOption(w);
	elseif sDecisionType == "asispecies" then
		CharWizardSpeciesManager.processSpeciesDecisionASI(w);
	elseif sDecisionType == "skill" then
		CharWizardSpeciesManager.processSpeciesDecisionSkill(w);
	elseif sDecisionType == "armorprof" then
		CharWizardSpeciesManager.processSpeciesDecisionArmorProficiency(w);
	elseif sDecisionType == "weaponprof" then
		CharWizardSpeciesManager.processSpeciesDecisionWeaponProficiency(w);
	elseif sDecisionType == "toolprof" then
		CharWizardSpeciesManager.processSpeciesDecisionToolProficiency(w);
	elseif sDecisionType == "language" then
		CharWizardSpeciesManager.processSpeciesDecisionLanguage(w);
	elseif sDecisionType == "feat" then
		CharWizardSpeciesManager.processSpeciesDecisionFeat(w);
	elseif sDecisionType == "spell" then
		CharWizardSpeciesManager.processSpeciesDecisionSpell(w);
	elseif sDecisionType == "variabletrait" then
		CharWizardSpeciesManager.processSpeciesDecisionVariableTrait(w);
	elseif sDecisionType == "size" then
		CharWizardManager.setSize(w.decision_choice.getValue());
	end

	_bUpdatingDecision = false;

	CharWizardManager.updateAlerts();
end
function processSpeciesDecisionASIOption(wDecision)
	local wFeature = wDecision.windowlist.window;
	CharWizardSpeciesManager.clearSpeciesAbilityIncreases();

	for _,w in pairs(wDecision.windowlist.getWindows()) do
		if w.decisiontype.getValue() == "asispecies" then
			w.close();
		end
	end

	local tAbilities = {};
	for _,v in pairs(DataCommon.abilities) do
		table.insert(tAbilities, StringManager.capitalize(v));
	end

	local sDecisionChoice = wDecision.decision_choice.getValue():lower();
	if sDecisionChoice:match("option 1") then
		CharWizardDecisionManager.createDecision(wFeature, { sDecisionType = "asispecies", nAdj = 2, tOptions = tAbilities });
		CharWizardDecisionManager.createDecision(wFeature, { sDecisionType = "asispecies", nAdj = 1, tOptions = tAbilities });
	else
		CharWizardDecisionManager.createDecisions(wFeature, { sDecisionType = "asispecies", nAdj = 1, nPicks = 3, tOptions = tAbilities });
	end

	CharWizardAbilitiesManager.updateAbilities();
end
function processSpeciesDecisionASI(wDecision)
	CharWizardSpeciesManager.clearSpeciesAbilityIncreases();

	local tAbilityMap = CharWizardDecisionManager.processAbilityDecision(wDecision, true);
	for sAbility,nMod in pairs(tAbilityMap) do
		CharWizardSpeciesManager.addSpeciesAbilityIncreases(sAbility, nMod);
	end

	CharWizardAbilitiesManager.updateAbilities();
end
function processSpeciesDecisionSkill(wDecision)
	CharWizardSpeciesManager.clearSpeciesSkillChoice();

	local tMap = CharWizardDecisionManager.processSkillDecision(wDecision);
	for _,s in pairs(tMap) do
		CharWizardSpeciesManager.addSpeciesSkillChoice(s);
	end

	CharWizardDecisionManager.refreshExpertiseDecision();
end
function processSpeciesDecisionArmorProficiency(wDecision)
	CharWizardSpeciesManager.clearSpeciesArmorProficiencyChoice();

	local tMap = CharWizardDecisionManager.processArmorProfDecision(wDecision);
	for _,s in pairs(tMap) do
		CharWizardSpeciesManager.addSpeciesArmorProficiencyChoice(s);
	end
end
function processSpeciesDecisionWeaponProficiency(wDecision)
	CharWizardSpeciesManager.clearSpeciesWeaponProficiencyChoice();

	local tMap = CharWizardDecisionManager.processWeaponProfDecision(wDecision);
	for _,s in pairs(tMap) do
		CharWizardSpeciesManager.addSpeciesWeaponProficiencyChoice(s);
	end
end
function processSpeciesDecisionToolProficiency(wDecision)
	CharWizardSpeciesManager.clearSpeciesToolProficiencyChoice();

	local tMap = CharWizardDecisionManager.processToolProfDecision(wDecision);
	for _,s in pairs(tMap) do
		CharWizardSpeciesManager.addSpeciesToolProficiencyChoice(s);
	end
end
function processSpeciesDecisionLanguage(wDecision)
	CharWizardSpeciesManager.clearSpeciesLanguageChoice();

	local tMap = CharWizardDecisionManager.processLanguageDecision(wDecision);
	for _,s in pairs(tMap) do
		CharWizardSpeciesManager.addSpeciesLanguageChoice(s);
	end
end
function processSpeciesDecisionVariableTrait(wDecision)
	local sDecisionChoice = wDecision.decision_choice.getValue():lower();
	if sDecisionChoice:match("darkvision") then
		CharWizardSpeciesManager.setSpeciesDarkvision(60);
		CharWizardSpeciesManager.clearSpeciesSkillChoice();
		for _,w in pairs(wDecision.windowlist.getWindows()) do
			if w.decisiontype.getValue() == "skill" then
				w.close();
			end
		end
	else
		CharWizardDecisionManager.createDecision(wDecision, { sDecisionType = "skill", tOptions = CharBuildManager.getSkillNames() });
	end

	CharWizardDecisionManager.refreshOverallDecision("skill");
end
function processSpeciesDecisionSpell(wDecision, sDecision)
	CharWizardSpeciesManager.clearSpeciesSpellChoice();

	local tMap = CharWizardDecisionManager.processSpellDecision(wDecision);
	for _,s in pairs(tMap) do
		CharWizardSpeciesManager.addSpeciesSpellChoice(s);
	end
end

function processSpeciesDecisionFeat(wSelection)
	local sFeat = wSelection.name.getValue();
	local sFeatClass, sFeatPath = wSelection.shortcut.getValue();

	CharWizardSpeciesManager.addSpeciesChoiceFeatPath(sFeatPath);

	local wDecision = wSelection.windowlist.window.parentcontrol.window;
	wDecision.choice.setValue(sFeat);
	wDecision.choicelink.setValue(sFeatClass, sFeatPath);
	wDecision.button_modify.setVisible(true);
	wDecision.sub_decision_choice.setVisible(false);
	wDecision.checkOutstandingDecisions();

	CharWizardManager.updateAlerts();
end
function resetSpeciesDecisionFeat(wDecision)
	local _,sFeatPath = wDecision.choicelink.getValue();

	CharWizardSpeciesManager.removeSpeciesChoiceFeatPath(sFeatPath);

	wDecision.choice.setValue();
	wDecision.choicelink.setValue();
	wDecision.button_modify.setVisible(false);
	wDecision.sub_decision_choice.setVisible(true);
	WindowManager.callInnerWindowFunction(wDecision, "buildFeats");

	CharWizardManager.updateAlerts();
end
