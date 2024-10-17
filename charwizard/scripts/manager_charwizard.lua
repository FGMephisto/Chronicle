--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--
--	WIZARD WINDOW
--

function registerWindow(w)
	CharWizardManager.resetData();
	w.sub_step_buttons.subwindow.button_class.onButtonPress();
end
function onTabButtonPressed(w, sTabTarget)
	local tButtons;
	if CharWizardManager.isLevelUpData() then
		tButtons = { "class", "commit", };
	else
		tButtons = { "species", "class", "abilities", "background", "equipment", "commit", };
	end

	for _,v in pairs(tButtons) do
		local cButton = w.sub_step_buttons.subwindow["button_" .. v];
		local cSub = w["sub_" .. v];
		if v == sTabTarget then
			cButton.setFrame("buttondown", 5, 5, 5, 5);
			cSub.setVisible(true);
		else
			cButton.setFrame("buttonup", 5, 5, 5, 5);
			cSub.setVisible(false);
		end
	end

	local c = w["sub_" .. sTabTarget];
	if c and c.subwindow and c.subwindow.update then
		c.subwindow.update();
	end
end

function getWizardWindow()
	if CharWizardManager.isLevelUpData() then
		return Interface.findWindow("charwizard_levelup", "");
	end
	return Interface.findWindow("charwizard", "");
end
function getWizardClassWindow()
	local wTop = CharWizardManager.getWizardWindow();
	if not wTop then
		return nil;
	end
	return wTop.sub_class.subwindow;
end
function getWizardBackgroundWindow()
	local wTop = CharWizardManager.getWizardWindow();
	if not wTop then
		return nil;
	end
	return wTop.sub_background.subwindow;
end
function getWizardSpeciesWindow()
	local wTop = CharWizardManager.getWizardWindow();
	if not wTop then
		return nil;
	end
	if not wTop.sub_species then
		return nil;
	end
	return wTop.sub_species.subwindow;
end
function getWizardAbilitiesWindow()
	local wTop = CharWizardManager.getWizardWindow();
	if not wTop then
		return nil;
	end
	if not wTop.sub_abilities then
		return nil;
	end
	return wTop.sub_abilities.subwindow;
end
function getWizardEquipmentWindow()
	local wTop = CharWizardManager.getWizardWindow();
	if not wTop then
		return nil;
	end
	if not wTop.sub_equipment then
		return nil;
	end
	return wTop.sub_equipment.subwindow;
end

function createDecisions(w, tData)
	local nPicks = tData and tData.nPicks or 1;
	for i = 1, nPicks do
		CharWizardManager.createDecision(w, tData);
	end
end
function createDecision(w, tData)
	local wDecision = w.list_decisions.createWindow();
	wDecision.setData(tData);
	w.alert.setVisible();
	w.setDetailsVisible(true);
	return wDecision;
end

function processStandardDecision(wDecision)
	local sDecisionType = wDecision.decisiontype.getValue();

	local tMap = {};
	local sDecisionKey = StringManager.simplify(wDecision.decision_choice.getValue());
	if sDecisionKey ~= "" then
		tMap[sDecisionKey] = wDecision.decision_choice.getValue();
	end
	for _,w in pairs(wDecision.windowlist.getWindows()) do
		if (w ~= wDecision) and (w.decisiontype.getValue() == sDecisionType) then
			local sDecisionKey = StringManager.simplify(w.decision_choice.getValue());
			if sDecisionKey ~= "" then
				if tMap[sDecisionKey] then
					w.decision_choice.setListValue("");
				else
					tMap[sDecisionKey] = w.decision_choice.getValue();
				end
			end
		end
	end
	
	for _,w in pairs(wDecision.windowlist.getWindows()) do
		if (w.decisiontype.getValue() == sDecisionType) then
			w.updateOptions(tMap);
		end
	end

	return tMap;
end
function processAbilityDecision(wDecision)
	local sDecisionType = wDecision.decisiontype.getValue();

	local tAbilityMap = {};
	local sDecisionKey = StringManager.simplify(wDecision.decision_choice.getValue());
	if sDecisionKey ~= "" then
		tAbilityMap[sDecisionKey] = wDecision.decision.getValue():match("%d+") or 0;
	end
	for _,w in pairs(wDecision.windowlist.getWindows()) do
		if (w ~= wDecision) and (w.decisiontype.getValue() == sDecisionType) then
			local sDecisionKey = StringManager.simplify(w.decision_choice.getValue());
			if sDecisionKey ~= "" then
				if tAbilityMap[sDecisionKey] then
					w.decision_choice.setListValue("");
				else
					tAbilityMap[sDecisionKey] = w.decision.getValue():match("%d+") or 0;
				end
			end
		end
	end

	for _,w in pairs(wDecision.windowlist.getWindows()) do
		if (w.decisiontype.getValue() == sDecisionType) then
			w.updateOptions(tAbilityMap);
		end
	end

	return tAbilityMap;
end

--
--	CHARACTER DATA
--

local _tCharData = {};
local _bIsClass2024 = false;
local _bIsSpecies2024 = false;

function getData()
	return _tCharData;
end
function resetData()
	_tCharData = {};
end

function isLevelUpData()
	local tCharData = CharWizardManager.getData();
	if not tCharData or not tCharData.identity then
		return false;
	end
	return true;
end
function setIdentity(sRecord)
	local tCharData = CharWizardManager.getData();
	if not tCharData then
		return;
	end
	tCharData.identity = sRecord;
end
function getIdentityNode()
	local tCharData = CharWizardManager.getData();
	if not tCharData or not tCharData.identity then
		return;
	end
	return DB.findNode(tCharData.identity);
end

function getName()
	local tCharData = CharWizardManager.getData();
	if not tCharData then
		return "";
	end
	return tCharData.name or "";
end
function setName(s)
	local tCharData = CharWizardManager.getData();
	if not tCharData then
		return;
	end
	tCharData.name = s;
end

function setSize(s)
	local tSpecies = CharWizardManager.getSpeciesData();
	if tSpecies then
		tSpecies.size = s or "Medium";
	end
end

function getStartingGold()
	local tCharData = CharWizardManager.getData();
	if not tCharData then
		return {};
	end
	return tCharData.startinggold or 0;
end
function setStartingGold(n)
	local tCharData = CharWizardManager.getData();
	if not tCharData then
		return {};
	end
	tCharData.startinggold = n;
end

function getAbilityData()
	local tCharData = CharWizardManager.getData();
	if not tCharData then
		return {};
	end
	tCharData.abilityscore = tCharData.abilityscore or {};
	return tCharData.abilityscore;
end
function clearAbilityData()
	local tCharData = CharWizardManager.getData();
	if not tCharData then
		return;
	end
	tCharData.abilityscore = {};
end

function hasBackground()
	return ((CharWizardBackgroundManager.getBackgroundRecord() or "") ~= "");
end
function getBackgroundData()
	local tCharData = CharWizardManager.getData();
	if not tCharData then
		return {};
	end
	tCharData.background = tCharData.background or {};
	return tCharData.background;
end
function clearBackgroundData()
	local tCharData = CharWizardManager.getData();
	if not tCharData then
		return;
	end
	tCharData.background = {};
	if tCharData.equipment then
		tCharData.equipment.backgroundkit = "";
		tCharData.equipment.backgrounditems = {};
	end
end

function getClassData()
	local tCharData = CharWizardManager.getData();
	if not tCharData then
		return {};
	end
	tCharData.class = tCharData.class or {};
	return tCharData.class;
end
function clearClassData()
	local tCharData = CharWizardManager.getData();
	if not tCharData then
		return;
	end
	tCharData.class = {};
end
function getStartingClassData()
	local tCharData = CharWizardManager.getData();
	if not tCharData then
		return {};
	end
	tCharData.startingclass = tCharData.startingclass or {};
	return tCharData.startingclass;
end
function clearStartingClassData()
	local tCharData = CharWizardManager.getData();
	if not tCharData then
		return;
	end
	tCharData.startingclass = {};
end

function getEquipmentData()
	local tCharData = CharWizardManager.getData();
	if not tCharData then
		return {};
	end
	tCharData.equipment = tCharData.equipment or {};
	return tCharData.equipment;
end
function clearEquipmentData()
	local tCharData = CharWizardManager.getData();
	if not tCharData then
		return;
	end
	tCharData.equipment = {};
end

function hasSpecies()
	return ((CharWizardSpeciesManager.getSpeciesRecord() or "") ~= "");
end
function getSpeciesData()
	local tCharData = CharWizardManager.getData();
	if not tCharData then
		return {};
	end
	tCharData.species = tCharData.species or {};
	return tCharData.species;
end
function clearSpeciesData()
	local tCharData = CharWizardManager.getData();
	if not tCharData then
		return;
	end
	tCharData.species = {};
end

function getImportData()
	local tCharData = CharWizardManager.getData();
	if not tCharData then
		return {};
	end
	tCharData.import = tCharData.import or {};
	return tCharData.import;
end
function clearImportData()
	local tCharData = CharWizardManager.getData();
	if not tCharData then
		return;
	end
	tCharData.import = {};
end

--
-- Collection Utilities
--

function collectSaveProficiencies()
	return CharWizardManager.helperCollectDataType("saveprof");
end
function collectSkills()
	return CharWizardManager.helperCollectDataType("skill");
end
function collectExpertises()
	return CharWizardManager.helperCollectDataType("expertise");
end
function collectArmorProficiencies()
	return CharWizardManager.helperCollectDataType("armorprof");
end
function collectWeaponProficiencies()
	return CharWizardManager.helperCollectDataType("weaponprof");
end
function collectToolProficiencies()
	return CharWizardManager.helperCollectDataType("toolprof");
end
function collectLanguages()
	return CharWizardManager.helperCollectDataType("language");
end
function collectFeats()
	local tClass = CharWizardManager.getClassData();
	local tSpecies = CharWizardManager.getSpeciesData();
	local tBackground = CharWizardManager.getBackgroundData();

	local tFeats = {};

	for _,vClass in pairs(tClass) do
		for kFeature,vFeature in pairs(vClass.features or {}) do
			for kFeatureLevel,vFeatureLevel in pairs(vFeature) do
				if vFeatureLevel.feat then
					table.insert(tFeats, { name = vFeatureLevel.feat, bIs2024 = vClass.bIs2024 });
				end
			end
		end
	end
	if tSpecies.feats then
		for _,v in pairs(tSpecies.feats) do
			table.insert(tFeats, { name = v, bIs2024 = tSpecies.bIs2024 });
		end
	end
	if tBackground.feat then
		table.insert(tFeats, { name = tBackground.feat, bIs2024 = tBackground.bIs2024 });
	end

	return tFeats;
end
function helperCollectDataType(s)
	if (s or "") == "" then
		return {};
	end

	local tSpecies = CharWizardManager.getSpeciesData();
	local tClass = CharWizardManager.getClassData();
	local tBackground = CharWizardManager.getBackgroundData();
	local tImport = CharWizardManager.getImportData();

	local sChoice = s .. "choice";
	local tResults = {};

	for _,v in pairs(tSpecies[s] or {}) do
		tResults[v] = true;
	end
	for _,v in pairs(tSpecies[sChoice] or {}) do
		tResults[v] = true;
	end
	for _,vClass in pairs(tClass) do
		for _,vFeature in pairs(vClass.features or {}) do
			for _,vFeatureLevel in pairs(vFeature) do
				for _,v in pairs(vFeatureLevel[s] or {}) do
					tResults[v] = true;
				end
				for _,v in pairs(vFeatureLevel[sChoice] or {}) do
					tResults[v] = true;
				end
			end
		end
	end
	for _,v in pairs(tBackground[s] or {}) do
		tResults[v] = true;
	end
	for _,v in pairs(tBackground[sChoice] or {}) do
		tResults[v] = true;
	end
	for _,v in pairs(tImport[s] or {}) do
		tResults[v] = true;
	end

	local tSorted = {};
	for k,_ in pairs(tResults) do
		table.insert(tSorted, k);
	end
	table.sort(tSorted);

	return tSorted;
end

function collectSaveProficienciesNew()
	return CharWizardManager.collectSaveProficiencies();
end
function collectArmorProficienciesNew()
	local tProfs = CharWizardManager.collectArmorProficiencies();
	
	local tImportData = CharWizardManager.getImportData();
	if not tImportData or (#(tImportData.armorprof or {}) == 0) then
		return tProfs;
	end

	local tAddProfs = {};
	local tCheckProfs = {}
	for _,v in ipairs(tImportData.armorprof) do
		tCheckProfs[StringManager.simplify(v)] = true;
	end
	for _,v in ipairs(tProfs) do
		if not tCheckProfs[StringManager.simplify(v)] then
			table.insert(tAddProfs, v);
		end
	end
	return tAddProfs;
end
function collectWeaponProficienciesNew()
	local tProfs = CharWizardManager.collectWeaponProficiencies();
	
	local tImportData = CharWizardManager.getImportData();
	if not tImportData or (#(tImportData.weaponprof or {}) == 0) then
		return tProfs;
	end

	local tAddProfs = {};
	local tCheckProfs = {}
	for _,v in ipairs(tImportData.weaponprof) do
		tCheckProfs[StringManager.simplify(v)] = true;
	end
	for _,v in ipairs(tProfs) do
		if not tCheckProfs[StringManager.simplify(v)] then
			table.insert(tAddProfs, v);
		end
	end
	return tAddProfs;
end
function collectToolProficienciesNew()
	local tProfs = CharWizardManager.collectToolProficiencies();

	local tImportData = CharWizardManager.getImportData();
	if not tImportData or (#(tImportData.toolprof or {}) == 0) then
		return tProfs;
	end

	local tAddProfs = {};
	local tCheckProfs = {}
	for _,v in ipairs(tImportData.toolprof) do
		tCheckProfs[StringManager.simplify(v)] = true;
	end
	for _,v in ipairs(tProfs) do
		if not tCheckProfs[StringManager.simplify(v)] then
			table.insert(tAddProfs, v);
		end
	end
	return tAddProfs;
end
-- NOTE: Return ruleset skills not already in .skill lists for each build component
function getAvailableSkills()
	local tSkills = CharWizardManager.collectSkills();
	local tAvailableSkills = {};
	for k,_ in pairs(DataCommon.skilldata) do
		if not StringManager.contains(tSkills, k) then
			table.insert(tAvailableSkills, k);
		end
	end
	return tAvailableSkills;
end
-- NOTE: Filter given list by available skills above
function filterByAvailableSkills(tSkills)
	if not tSkills then
		return {};
	end
	local tAvailableSkills = CharWizardManager.getAvailableSkills();
	local tFinal = {};
	for _,v in ipairs(tSkills) do
		if StringManager.contains(tAvailableSkills, v) then
			table.insert(tFinal, v);
		end
	end
	return tFinal;
end

--
-- Summary
--

function clearSummary()
	local wTop = CharWizardManager.getWizardWindow();
	local wCommit = wTop.sub_commit.subwindow;

	if wCommit.sub_commit_summary.subwindow then
		local wSummary = wCommit.sub_commit_summary.subwindow;
		wSummary.strength_total.setValue();
		wSummary.strength_modifier.setValue();
		wSummary.dexterity_total.setValue();
		wSummary.dexterity_modifier.setValue();
		wSummary.constitution_total.setValue();
		wSummary.constitution_modifier.setValue();
		wSummary.intelligence_total.setValue();
		wSummary.intelligence_modifier.setValue();
		wSummary.wisdom_total.setValue();
		wSummary.wisdom_modifier.setValue();
		wSummary.charisma_total.setValue();
		wSummary.charisma_modifier.setValue();

		wSummary.summary_species.setValue();
		wSummary.summary_background.setValue();
		wSummary.summary_class.setValue();
		wSummary.summary_senses.setValue();
		wSummary.summary_speed.setValue();
		wSummary.summary_speedspecial.setValue();

		wSummary.summary_languages.closeAll();
		wSummary.summary_skills.closeAll();
		wSummary.summary_traits.closeAll();
		wSummary.summary_features.closeAll();
		wSummary.summary_proficiencies.closeAll();
	end
end
function populateSummary()
	local wTop = CharWizardManager.getWizardWindow();
	local wCommit = wTop.sub_commit.subwindow;
	local wSummary = wCommit.sub_commit_summary.subwindow;

	local tSpecies = CharWizardManager.getSpeciesData();
	local sSpeciesTitle = "";
	if (tSpecies.species or "") ~= "" then
		sSpeciesTitle = DB.getValue(DB.findNode(tSpecies.species), "name", "");
		for _,v in pairs(DB.getChildren(DB.findNode(tSpecies.species), "traits")) do
			local w = wSummary.summary_traits.createWindow();
			w.name.setValue(DB.getValue(v, "name", ""));
		end
	end
	if (tSpecies.ancestry or "") ~= "" then
		sSpeciesTitle = string.format("%s (%s)", sSpeciesTitle, DB.getValue(DB.findNode(tSpecies.ancestry), "name", ""));
		for _,v in pairs(DB.getChildren(DB.findNode(tSpecies.ancestry), "traits")) do
			local w = wSummary.summary_traits.createWindow();
			w.name.setValue(DB.getValue(v, "name", ""));
		end
	end
	wSummary.summary_species.setValue(sSpeciesTitle);

	local tBackground = CharWizardManager.getBackgroundData();
	if (tBackground.background or "") ~= "" then
		wSummary.summary_background.setValue(DB.getValue(DB.findNode(tBackground.background), "name", ""));
	end

	local tASI = CharWizardManager.getAbilityData();
	for _,sAbility in ipairs(DataCommon.abilities) do
		local nTotal = tASI[sAbility] and tASI[sAbility].total or 10;
		local nModifier = tASI[sAbility] and tASI[sAbility].modifier or 0;

		wSummary[sAbility .. "_total"].setValue(nTotal);
		wSummary[sAbility .. "_modifier"].setValue(string.format("%+d", nModifier));
	end

	local tClass = CharWizardManager.getClassData();
	local tClasses = {};
	for k,v in pairs(tClass) do
		local sClass = k;
		local nLevel = v.level or 0;

		sClass = sClass:sub(1,3);

		if nLevel > 0 then
			table.insert(tClasses, sClass .. " " .. math.floor(nLevel*100)*0.01);
		end

		for k,v2 in pairs(v.features or {}) do
			local w = wSummary.summary_features.createWindow();
			w.name.setValue(k);
		end
	end
	wSummary.summary_class.setValue(table.concat(tClasses, " / "));

	if tSpecies.darkvision then
		wSummary.summary_senses.setValue(string.format("Darkvision %d", tSpecies.darkvision));
	else
		wSummary.summary_senses.setValue("");
	end
	wSummary.summary_speed.setValue(tSpecies.speed);
	wSummary.summary_speedspecial.setValue(tSpecies.speedspecial);

	for k,v in ipairs(CharWizardManager.collectSkills()) do
		local w = wSummary.summary_skills.createWindow();
		w.name.setValue(v);
	end

	for _,v in ipairs(CharWizardManager.collectArmorProficiencies()) do
		local w = wSummary.summary_proficiencies.createWindow();
		w.name.setValue(string.format("%s: %s", Interface.getString("char_label_addprof_armor"), v));
	end
	for _,v in ipairs(CharWizardManager.collectWeaponProficiencies()) do
		local w = wSummary.summary_proficiencies.createWindow();
		w.name.setValue(string.format("%s: %s", Interface.getString("char_label_addprof_weapon"), v));
	end
	for _,v in ipairs(CharWizardManager.collectToolProficiencies()) do
		local w = wSummary.summary_proficiencies.createWindow();
		w.name.setValue(string.format("%s: %s", Interface.getString("char_label_addprof_tool"), v));
	end

	for _,v in ipairs(CharWizardManager.collectLanguages()) do
		local w = wSummary.summary_languages.createWindow();
		w.name.setValue(StringManager.capitalize(v));
	end

	for _,v in ipairs(CharWizardManager.collectFeats()) do
		local w = wSummary.summary_feats.createWindow();
		w.name.setValue(v.name);
	end
end

--
-- Alerts
--

local _tWarnings = {};
function getCommitWarnings()
	return _tWarnings;
end
function checkCompletion()
	local wTop = CharWizardManager.getWizardWindow();

	_tWarnings = {};

	local bComplete = true;
	local tSpeciesAlerts, tClassAlerts, tAbilitiesAlerts, tBackgroundAlerts, tEquipmentAlerts = CharWizardManager.updateAlerts();
	if next(tSpeciesAlerts) or next(tClassAlerts) or next(tAbilitiesAlerts) or next(tBackgroundAlerts) or next(tEquipmentAlerts) then
		bComplete = false;
	end

	if not bComplete and wTop.sub_commit.subwindow then
		wTop.sub_commit.subwindow.warnings.closeAll();

		for _,v in ipairs(tSpeciesAlerts) do
			local w = wTop.sub_commit.subwindow.warnings.createWindow();
			w.warning.setValue(v);
			table.insert(_tWarnings, v);
		end
		for _,v in ipairs(tClassAlerts) do
			local w = wTop.sub_commit.subwindow.warnings.createWindow();
			w.warning.setValue(v);
			table.insert(_tWarnings, v);
		end
		for _,v in ipairs(tAbilitiesAlerts) do
			local w = wTop.sub_commit.subwindow.warnings.createWindow();
			w.warning.setValue(v);
			table.insert(_tWarnings, v);
		end
		for _,v in ipairs(tBackgroundAlerts) do
			local w = wTop.sub_commit.subwindow.warnings.createWindow();
			w.warning.setValue(v);
			table.insert(_tWarnings, v);
		end
		for _,v in ipairs(tEquipmentAlerts) do
			local w = wTop.sub_commit.subwindow.warnings.createWindow();
			w.warning.setValue(v);
			table.insert(_tWarnings, v);
		end
	end

	return bComplete;
end

function updateAlerts()
	local wTop = CharWizardManager.getWizardWindow();
	local aButtons = {};

	if CharWizardManager.isLevelUpData() then
		aButtons = { "class" };
	else
		aButtons = { "species", "class", "abilities", "background", "equipment" };
	end

	local tSpeciesAlerts = {};
	local tClassAlerts = {};
	local tAbilitiesAlerts = {};
	local tBackgroundAlerts = {};
	local tEquipmentAlerts = {};

	for _,vButton in ipairs(aButtons) do
		if wTop and wTop.sub_step_buttons.subwindow["button_" .. vButton] then
			local bTopAlert = false;

			local cAlert = wTop.sub_step_buttons.subwindow["button_" .. vButton].findWidget("alert");
			if not cAlert then
				cAlert = wTop.sub_step_buttons.subwindow["button_" .. vButton].addBitmapWidget();
				cAlert.setPosition("bottomright", -5, -5);
				cAlert.setSize(20, 20)
				cAlert.setName("alert");
			end

			if vButton == "species" then
				bTopAlert, tSpeciesAlerts = CharWizardManager.updateSpeciesAlerts(wTop);
			elseif vButton == "class" then
				bTopAlert, tClassAlerts = CharWizardManager.updateClassAlerts(wTop);
			elseif vButton == "abilities" then
				bTopAlert, tAbilitiesAlerts = CharWizardManager.updateAbilitiesAlerts(wTop);
			elseif vButton == "background" then
				bTopAlert, tBackgroundAlerts = CharWizardManager.updateBackgroundAlerts(wTop);
			elseif vButton == "equipment" then
				bTopAlert, tEquipmentAlerts = CharWizardManager.updateEquipmentAlerts(wTop);
			end

			if bTopAlert then
				cAlert.setBitmap("button_alert");
			else
				cAlert.setBitmap("button_dialog_ok_down");
			end
		end
	end

	return tSpeciesAlerts, tClassAlerts, tAbilitiesAlerts, tBackgroundAlerts, tEquipmentAlerts;
end

function updateClassAlerts(w)
	local wClass = CharWizardManager.getWizardClassWindow();
	if not wClass then
		return true, {"Select Class"};
	end
	if wClass.class_list.isEmpty() then
		return true, {"Select Class"};
	end

	local tAlerts = {};
	local bTopAlert = false;

	for _,vClass in pairs(wClass.class_list.getWindows()) do
		for _,v in pairs(vClass.list_class_features.getWindows()) do
			local bAlert = false;
			for _,v2 in pairs(v.list_decisions.getWindows()) do
				if ((v2.decision_choice.getValue() or "") == "") and 
					((v2.choice.getValue() or "") == "") then

					bAlert = true;
					bTopAlert = true;
					table.insert(tAlerts, "Select " .. v.feature.getValue() .. " Choice");
				end

				v2.alert.setVisible(bAlert);
			end

			v.alert.setVisible(bAlert);
		end
	end

	return bTopAlert, tAlerts
end
function updateBackgroundAlerts(w)
	local wBackground = CharWizardManager.getWizardBackgroundWindow();
	if not wBackground then
		return true, {"Select Background"};
	end
	if not wBackground.background_decisions_list or wBackground.background_decisions_list.isEmpty() then
		return true, {"Select Background"};
	end

	local tAlerts = {};
	local bTopAlert = false;

	for _,v in pairs(wBackground.background_decisions_list.getWindows()) do
		local bAlert = false;
		for _,v2 in pairs(v.list_decisions.getWindows()) do
			if v2.decision_choice.getValue() == "" then
				bAlert = true;
				bTopAlert = true;
				table.insert(tAlerts, v2.decision.getValue());
			end

			v2.alert.setVisible(bAlert);
		end

		v.alert.setVisible(bAlert);
	end

	if CharWizardManager.hasSpecies() and CharWizardManager.hasBackground() then
		if CharWizardSpeciesManager.isSpecies2024() and not CharWizardBackgroundManager.isBackground2024() then
			local sMsg = "You chose a 2024 Species and a Legacy Background. Adjust the MISC ability scores by increasing one score by 2 and a different one by one, or increasing three scores by one. Additionally, if the background doesn’t include a feat, choose an Origin feat.";
			table.insert(tAlerts, sMsg);
		elseif not CharWizardSpeciesManager.isSpecies2024() and CharWizardBackgroundManager.isBackground2024() then
			local sMsg = "You chose a Legacy Species and a 2024 Background. The ASI for the Species will be ignored.";
			table.insert(tAlerts, sMsg);
		end
	end
	
	return bTopAlert, tAlerts;
end
function updateSpeciesAlerts(w)
	local wSpecies = CharWizardManager.getWizardSpeciesWindow();
	if not wSpecies then
		return true, { Interface.getString("charwizard_label_speciesselection_alert") };
	end
	if not wSpecies.species_decisions_list or wSpecies.species_decisions_list.isEmpty() then
		return true, { Interface.getString("charwizard_label_speciesselection_alert") };
	end
	if wSpecies.ancestry_selection_list.isVisible() then
		return true, { Interface.getString("charwizard_label_subspeciesselection_alert") };
	end

	local tAlerts = {};
	local bTopAlert = false;

	for _,v in pairs(wSpecies.species_decisions_list.getWindows()) do
		local bAlert = false;
		for _,v2 in pairs(v.list_decisions.getWindows()) do
			if v2.decisiontype.getValue() == "feat" then
				if v2.choice.getValue() == "" then
					bAlert = true;
					bTopAlert = true;
					table.insert(tAlerts, v2.decision.getValue());
				end
			else
				if v2.decision_choice.getValue() == "" then
					bAlert = true;
					bTopAlert = true;
					table.insert(tAlerts, v2.decision.getValue());
				end
			end
			v2.alert.setVisible(bAlert);
		end
		v.alert.setVisible(bAlert);
	end
	
	return bTopAlert, tAlerts
end
function updateAbilitiesAlerts(w)
	local wAbility = CharWizardManager.getWizardAbilitiesWindow();
	if not wAbility then
		return true, {"Select Ability Scores"};
	end

	local sGenMethod = wAbility.cb_genmethod.getValue();

	if sGenMethod == "" then
		return true, {"Select Ability Scores"};
	end

	if sGenMethod:lower() == "point buy" then
		if wAbility.points_used.getValue() ~= wAbility.points_max.getValue() then
			return true, {"Select Ability Scores - Not all points used"};
		end
		return false, {};
	end

	local bBase = false;
	for _,v in pairs(DataCommon.abilities) do
		if wAbility[v .. "_base"].getValue() ~= 0 then
			bBase = true;
		end
	end
	if not bBase then
		return true, {"Select Ability Scores"};
	end
	return false, {};
end
function updateEquipmentAlerts(w)
	local wEquipment = CharWizardManager.getWizardEquipmentWindow();
	if not wEquipment then
		return true, { "Select Equipment Choice" };
	end

	local bIs2024 = CharWizardClassManager.isStartingClass2024();
	local bProcessKits = (bIs2024 or (CharWizardManager.getStartingGold() == 0));
	if not bProcessKits then
		return false, {};
	end

	local tAlerts = {};
	local bTopAlert = false;
	local wEquipmentKit = CharWizardEquipmentManager.getWizardEquipmentKitWindow();
	for _,v in pairs(wEquipmentKit.list_backgroundkit.getWindows()) do
		local bAlert = false;
		if not v.button_modify.isVisible() then
			bBackgroundSelected = true;
			bTopAlert = true;
			bAlert = true;
		end

		v.alert.setVisible(bAlert);
	end
	for _,v in pairs(wEquipmentKit.list_classkit.getWindows()) do
		local bAlert = false;
		if not v.button_modify.isVisible() then
			bBackgroundSelected = true;
			bTopAlert = true;
			bAlert = true;
		end

		v.alert.setVisible(bAlert);
	end

	return bTopAlert, tAlerts
end

--
-- Import
--

function checkImport(nodeChar)
	local bCanImport = true;
	local tMissingClasses = {};
	local tMissingSubclasses = {};

	for _,nodeCharClass in pairs(DB.getChildren(nodeChar, "classes")) do
		local tClass = CharWizardManager.helperImportGetClassRecord(nodeCharClass);
		if not tClass then
			local sClassName = DB.getValue(nodeCharClass, "name", "");
			local _, sClassRecord = DB.getValue(nodeCharClass, "shortcut", "", "");
			local sClassModule = StringManager.split(sClassRecord, "@")[2] or "";
			table.insert(tMissingClasses, { sName = sClassName, sModule = sClassModule });
		elseif tClass.bImportErrorSubclass then
			local sSubclassName = DB.getValue(nodeCharClass, "specialization", "");
			local _, sSubclassRecord = DB.getValue(nodeCharClass, "specializationlink", "", "");
			local sSubclassModule = StringManager.split(sSubclassRecord, "@")[2] or "";
			table.insert(tMissingSubclasses, { sName = sSubclassName, sModule = sSubclassModule });
		end
	end
	if #tMissingClasses > 0 then
		ChatManager.SystemMessage(Interface.getString("charwizard_error_import_missingclass"));
		for _,v in ipairs(tMissingClasses) do
			ChatManager.SystemMessage(string.format("  '%s' - (%s)", v.sName, v.sModule));
		end
		bCanImport = false;
	end
	if #tMissingSubclasses > 0 then
		ChatManager.SystemMessage(Interface.getString("charwizard_error_import_missingsubclass"));
		for _,v in ipairs(tMissingSubclasses) do
			ChatManager.SystemMessage(string.format("  '%s' - (%s)", v.sName, v.sModule));
		end
		bCanImport = false;
	end

	return bCanImport;
end

function importCharacter(nodeChar)
	local bCanImport = CharWizardManager.checkImport(nodeChar);
	if not bCanImport then
		return;
	end

	local wChar = Interface.findWindow("charsheet", nodeChar);
	if wChar then
		wChar.close();
	end
	local wCharClass = Interface.findWindow("charsheet_classes", nodeChar);
	if wCharClass then
		wCharClass.close();
	end

	local wWizard = Interface.openWindow("charwizard_levelup", "");

	CharWizardManager.resetData();
	CharWizardManager.setName(DB.getValue(nodeChar, "name", ""));
	CharWizardManager.setIdentity(DB.getPath(nodeChar));

	wWizard.sub_step_buttons.subwindow.button_class.onButtonPress();
	wWizard.sub_class.setValue("charwizard_sub_class", "");

	local tSpecies = CharWizardManager.getSpeciesData();
	local _,sSpeciesRecord = DB.getValue(nodeChar, "racelink", "");
	local _,sAncestryRecord = DB.getValue(nodeChar, "subracelink", "");
	tSpecies.species = sSpeciesRecord;
	tSpecies.ancestry = sAncestryRecord;
	tSpecies.speed = DB.getValue(nodeChar, "speed.base", 0);
	tSpecies.speedspecial = DB.getValue(nodeChar, "speed.special", "");
	local sMatch = DB.getValue(nodeChar, "senses", ""):match("Darkvision (%d+)");
	if sMatch then
		tSpecies.darkvision = tonumber(sMatch) or 60;
	end
	tSpecies.size = DB.getValue(nodeChar, "size", "");

	local tAbility = CharWizardManager.getAbilityData();
	local nStr, nDex, nCon, nInt, nWis, nCha;
	for k,nodeAbility in pairs(DB.getChildren(nodeChar, "abilities", "")) do
		tAbility[k] = { score = DB.getValue(nodeAbility, "score", 0), };
	end

	local tBackground = CharWizardManager.getBackgroundData();
	local _,sBackgroundRecord = DB.getValue(nodeChar, "backgroundlink", "");
	tBackground.background = sBackgroundRecord;

	local tImport = CharWizardManager.getImportData();
	tImport.skill = {};
	tImport.expertise = {};
	for _,vSkills in pairs(DB.getChildren(nodeChar, "skilllist")) do
		if DB.getValue(vSkills, "prof", 0) > 0 then
			local sSkill = StringManager.trim(DB.getValue(vSkills, "name", ""));
			local nProf = DB.getValue(vSkills, "prof", 0);
			if nProf == 1 then
				table.insert(tImport.skill, sSkill);
			elseif nProf == 2 then
				table.insert(tImport.expertise, sSkill);
			end
		end
	end

	tImport.armorprof = {};
	tImport.weaponprof = {};
	tImport.toolprof = {};
	local sArmorPrefix = string.format("^S%s:", Interface.getString("char_label_addprof_armor"));
	local sWeaponPrefix = string.format("^%s:", Interface.getString("char_label_addprof_weapon"));
	local sToolPrefix = string.format("^%s:", Interface.getString("char_label_addprof_tool"));
	for _,vProfs in ipairs(DB.getChildList(nodeChar, "proficiencylist")) do
		local sProf = DB.getValue(vProfs, "name", "");
		if sProf:match(sArmorPrefix) then
			sProf = StringManager.trim(sProf:gsub(sArmorPrefix, ""));
			if sProf ~= "" then
				table.insert(tImport.armorprof, StringManager.trim());
			end
		elseif sProf:match(sWeaponPrefix) then
			sProf = StringManager.trim(sProf:gsub(sWeaponPrefix, ""));
			if sProf ~= "" then
				table.insert(tImport.weaponprof, StringManager.trim());
			end
		elseif sProf:match(sToolPrefix) then
			sProf = StringManager.trim(sProf:gsub(sToolPrefix, ""));
			if sProf ~= "" then
				table.insert(tImport.toolprof, StringManager.trim());
			end
		end
	end

	tImport.language = {};
	for _,vLang in ipairs(DB.getChildList(nodeChar, "languagelist")) do
		table.insert(tImport.language, DB.getValue(vLang, "name", ""));
	end

	local tClassData = CharWizardManager.getClassData();
	for _,nodeCharClass in pairs(DB.getChildren(nodeChar, "classes")) do
		local tClass = CharWizardManager.helperImportGetClassRecord(nodeCharClass);
		if tClass then
			tClassData[DB.getValue(nodeCharClass, "name", "")] = tClass;
			CharWizardClassManager.addClass(tClass.record, true);
		end
	end

	CharWizardAbilitiesManager.updateAbilities()
end
function helperImportGetClassRecord(nodeCharClass)
	if not nodeCharClass then
		return nil;
	end

	-- Look up class name and database node
	local sClassName = DB.getValue(nodeCharClass, "name", "");
	local _, sClassRecord = DB.getValue(nodeCharClass, "shortcut", "", "");
	local nodeClass = DB.findNode(sClassRecord);

	-- If name mismatch, then reset, since old link with phantom record
	if nodeClass and (DB.getValue(nodeClass, "name", "") ~= sClassName) then
		nodeClass = nil;
	end

	-- If missing database node, then attempt to look up by class name and version saved on PC sheet
	if not nodeClass then
		local sVersion = DB.getValue(nodeCharClass, "version", "");
		local tClassFilters = {
			{ sField = "name", sValue = sClassName, bIgnoreCase = true, },
			{ sField = "version", sValue = sVersion, },
		};
		nodeClass = RecordManager.findRecordByFilter("class", tClassFilters);
	end

	-- If still missing database node, then fail
	if not nodeClass then
		return nil;
	end

	-- Look up class name and database node
	local sSubclassName = DB.getValue(nodeCharClass, "specialization", "");
	local _, sSubclassRecord = DB.getValue(nodeCharClass, "specializationlink", "", "");
	local nodeSubclass;
	if sSubclassRecord ~= "" then
		nodeSubclass = DB.findNode(sSubclassRecord);

		-- If name mismatch, then reset, since old link with phantom record
		if nodeSubclass and (DB.getValue(nodeSubclass, "name", "") ~= sSubclassName) then
			nodeSubclass = nil;
		end

		-- If missing database node, then attempt to look up by subclass name and version saved on PC sheet
		if not nodeSubclass then
			local sSubclassRecordByName = CharClassManager.findSubclassByName(nodeCharClass, sSubclassName);
			if (sSubclassRecordByName or "") ~= "" then
				nodeSubclass = DB.findNode(sSubclassRecordByName);
			end
		end
	end

	-- Build class record and return
	local tClass = {
		record = DB.getPath(nodeClass),
		level = DB.getValue(nodeCharClass, "level", 0),
		bIs2024 = (DB.getValue(nodeCharClass, "version", "") == "2024"),
		import = 1,
	};
	if nodeSubclass then
		tClass.subclass = DB.getPath(nodeSubclass);
	elseif sSubclassRecord ~= "" then
		tClass.bImportErrorSubclass = true;
	end
	return tClass;
end

--
-- Commit
--

function onCommit()
	if CharWizardManager.isLevelUpData() then
		CharWizardManager.levelupCharacter();
	else
		if Session.IsHost then
			CharWizardManager.commitCharacter(DB.createChild("charsheet"));
		else
			CharWizardManager.requestCommit();
		end
	end
end
function requestCommit()
	if not bRequested then
		User.requestIdentity(nil, "charsheet", "name", nil, CharWizardManager.requestCommitResponse);
		bRequested = true;
	end
end
function requestCommitResponse(bResult, sIdentity)
	if bResult then
		CharWizardManager.commitCharacter(DB.findNode("charsheet." .. sIdentity));
	else
		ChatManager.SystemMessage("Error: Failed to create new PC identity.")
	end
	bRequested = false;
end
function commitCharacter(nodeChar)
	-- Open the character sheet
	Interface.openWindow("charsheet", nodeChar);

	-- Apply character options in the correct order
	-- NOTE: Add proficiencies/feats before species/background/class, in case of follow-on dialogs needing to filter
	CharWizardManager.addCommitBasics(nodeChar);
	CharWizardManager.setCommitAbilityScores(nodeChar);

	CharWizardManager.addCommitSkills(nodeChar);
	CharWizardManager.addCommitProficiencies(nodeChar);
	CharWizardManager.addCommitLanguages(nodeChar);
	CharWizardManager.addCommitFeats(nodeChar);

	CharWizardManager.addCommitSpecies(nodeChar);
	CharWizardManager.addCommitBackground(nodeChar);
	CharWizardManager.addCommitClasses(nodeChar);

	CharWizardManager.addCommitInnateSpells(nodeChar)
	CharWizardManager.addCommitSpells(nodeChar);

	CharWizardManager.addCommitInventory(nodeChar);
	CharWizardManager.addCommitCurrency(nodeChar);

	-- Close the wizard window
	CharWizardManager.getWizardWindow().close();
end
function levelupCharacter()
	local nodeChar = CharWizardManager.getIdentityNode();
	if not nodeChar then
		return;
	end

	-- Open the character sheet
	Interface.openWindow("charsheet", nodeChar);

	-- Apply character options in the correct order
	-- NOTE: Add proficiencies/feats before species/background/class, in case of follow-on dialogs needing to filter
	CharWizardManager.setCommitAbilityScores(nodeChar);

	CharWizardManager.addCommitSkills(nodeChar);
	CharWizardManager.addCommitProficiencies(nodeChar);
	CharWizardManager.addCommitLanguages(nodeChar);
	CharWizardManager.addCommitFeats(nodeChar);

	CharWizardManager.addCommitLevelUpClass(nodeChar);

	CharWizardManager.addCommitSpells(nodeChar);

	-- Close the wizard window
	CharWizardManager.getWizardWindow().close();
end

function addCommitBasics(nodeChar)
	-- Save warnings
	DB.setValue(nodeChar, "notes", "string", table.concat(CharWizardManager.getCommitWarnings(), "\r"));

	-- Set name
	DB.setValue(nodeChar, "name", "string", CharWizardManager.getName());

	-- Set physical parameters
	local tSpecies = CharWizardManager.getSpeciesData();
	DB.setValue(nodeChar, "size", "string", StringManager.capitalize(tSpecies.size or "Medium"));
	DB.setValue(nodeChar, "speed.base", "number", tSpecies.speed or 30);
	if tSpecies.speedspecial then
		DB.setValue(nodeChar, "speed.special", "string", tSpecies.speedspecial);
	end
	if tSpecies.darkvision then
		DB.setValue(nodeChar, "senses", "string", string.format("Darkvision %d", tSpecies.darkvision));
	end
end
function addCommitSpecies(nodeChar)
	local tSpecies = CharWizardManager.getSpeciesData();
	local rAdd = CharBuildDropManager.helperBuildAddStructure(nodeChar, "reference_race", tSpecies.species, { bWizard = true });
	if not rAdd then
		return;
	end
	rAdd.sAncestryPath = tSpecies.ancestry;
	CharSpeciesManager.helperAddSpecies(rAdd);
end
function setCommitAbilityScores(nodeChar)
	local tASI = CharWizardManager.getAbilityData();
	for _,v in ipairs(DataCommon.abilities) do
		if tASI[v] and tASI[v].total then
			local nScore = tASI[v].total;
			if DB.getValue(nodeChar, "abilities." .. v .. ".score", 0) ~= nScore then
				DB.setValue(nodeChar, "abilities." .. v .. ".score", "number", nScore);
				DB.setValue(nodeChar, "abilities." .. v .. ".bonus", "number", math.floor((nScore - 10) / 2));

				ChatManager.SystemMessageResource("char_abilities_message_abilityset", StringManager.capitalize(v), nScore, DB.getValue(nodeChar, "name", ""));
			end
		end
	end
end
function addCommitBackground(nodeChar)
	local tBackground = CharWizardManager.getBackgroundData();
	if tBackground.background then
		tBackground.bWizard = true;
		CharBackgroundManager.addBackground(nodeChar, tBackground.background, tBackground);
	end
end
function addCommitFeats(nodeChar)
	local tFeats = CharWizardManager.collectFeats();
	for _,v in ipairs(tFeats) do
		-- NOTE: Disable bWizard for now; since feat details aren't handled in the wizard
		local tData = { bSource2024 = v.bIs2024, };-- { bWizard = true, bSource2024 = v.bIs2024, };
		CharManager.addFeat(nodeChar, v.name, tData);
	end
end
function addCommitClasses(nodeChar)
	local tMainClass = {
		sName = "",
		nLevel = 0,
		sRecord = "",
	};

	local tMultiClasses = {};
	for k,v in pairs(CharWizardManager.getClassData()) do
		if v.nClassOrder == 1 then
			tMainClass.sName = k;
			tMainClass.nLevel = v.level;
			tMainClass.sRecord = v.record;

			if v.subclass then
				tMainClass.nSubclassLevel = CharClassManager.getSubclassLevel(DB.findNode(v.record));
				tMainClass.sSubclassRecord = v.subclass;
			end
		else
			local tMultiClass = {
				sName = k,
				nLevel = v.level,
				sRecord = v.record,
			};
			if v.subclass then
				tMultiClass.nSubclassLevel = CharClassManager.getSubclassLevel(DB.findNode(v.record));
				tMultiClass.sSubclassRecord = v.subclass;
			end

			table.insert(tMultiClasses, tMultiClass);
		end
	end

	for i = 1, tMainClass.nLevel do
		local rAdd = CharBuildDropManager.helperBuildAddStructure(nodeChar, "reference_class", tMainClass.sRecord, { bWizard = true });
		if rAdd then
			rAdd.sSubclassRecord = tMainClass.sSubclassRecord;
			CharClassManager.helperAddClassMain(rAdd);
		end
	end

	if #tMultiClasses > 0 then
		for _,tMultiClass in ipairs(tMultiClasses) do
			for i = 1, tMultiClass.nLevel do
				local rAdd = CharBuildDropManager.helperBuildAddStructure(nodeChar, "reference_class", tMultiClass.sRecord, { bWizard = true });
				if rAdd then
					rAdd.sSubclassRecord = tMultiClass.sSubclassRecord;
					CharClassManager.helperAddClassMain(rAdd);
				end
			end
		end
	end
end
function addCommitLevelUpClass(nodeChar)
	local tLvlClass = {
		sName = "",
		nLevel = 0,
		sRecord = "",
	};

	local sClassRecord = "";
	for k,v in pairs(CharWizardManager.getClassData()) do
		if v.levelup == 1 then
			tLvlClass.sName = k;
			tLvlClass.nLevel = v.level;
			tLvlClass.sRecord = v.record;

			if v.subclass then
				tLvlClass.nSubclassLevel = CharClassManager.getSubclassLevel(v.record);
				tLvlClass.sSubclassRecord = v.subclass;
			end
			break;
		end
	end

	local rAdd = CharBuildDropManager.helperBuildAddStructure(nodeChar, "reference_class", tLvlClass.sRecord, { bWizard = true });
	if rAdd then
		rAdd.sSubclassRecord = tLvlClass.sSubclassRecord;
		CharClassManager.helperAddClassMain(rAdd);
	end
end
function addCommitProficiencies(nodeChar)
	local tSaveProfs = CharWizardManager.collectSaveProficienciesNew();
	for _,v in ipairs(tSaveProfs) do
		CharManager.addSaveProficiency(nodeChar, v);
	end

	local tArmorProfs = CharWizardManager.collectArmorProficienciesNew();
	for _,v in ipairs(tArmorProfs) do
		CharManager.addProficiency(nodeChar, "armor", v);
	end

	local tWeaponProfs = CharWizardManager.collectWeaponProficienciesNew();
	for _,v in ipairs(tWeaponProfs) do
		CharManager.addProficiency(nodeChar, "weapons", v);
	end

	local tToolProfs = CharWizardManager.collectToolProficienciesNew();
	for _,v in ipairs(tToolProfs) do
		CharManager.addProficiency(nodeChar, "tools", v);
	end
end
function addCommitSkills(nodeChar)
	for _,sSkill in pairs(CharWizardManager.collectExpertises()) do
		CharManager.increaseSkillProficiency(nodeChar, sSkill, 2);
	end
	for _,sSkill in pairs(CharWizardManager.collectSkills()) do
		CharManager.addSkillProficiency(nodeChar, sSkill);
	end
end
function addCommitLanguages(nodeChar)
	local tCollectedLang = CharWizardManager.collectLanguages(true);
	local tLang = {};

	local tImportData = CharWizardManager.getImportData();
	if next(tImportData) then
		if tImportData.languages then
			local aSortedLangs = {};
			for _,v in ipairs(tImportData.languages) do
				aSortedLangs[v.language] = true;
			end
			for _,v in ipairs(tCollectedLang) do
				if not aSortedLangs[v] then
					table.insert(tLang, v);
				end
			end
		end
	else
		tLang = tCollectedLang;
	end

	for _,v in pairs(tLang) do
		CharManager.addLanguage(nodeChar, v);
	end
end
function addCommitInnateSpells(nodeChar)
	local tSpecies = CharWizardManager.getSpeciesData();

	if tSpecies.spell then
		for _,v in pairs(tSpecies.spell) do
			local nodeSpecies = CharWizardSpeciesManager.getSpeciesRecord();
			local bSource2024 = (DB.getValue(nodeSpecies, "version", "") == "2024");
			local sSpecies = DB.getValue(nodeSpecies, "name", "");
			local sSpell = v.spell;
			local tSpellFilters = {
				{ sField = "name", sValue = sSpell, bIgnoreCase = true, },
				{ sField = "version", sValue = (bSource2024 and "2024" or ""), },
			};
			local nodeSpell = RecordManager.findRecordByFilter("spell", tSpellFilters);
			local sSpellGroup = Interface.getString("char_spell_powergroup"):format(sSpecies);
			local nodePowerGroups = DB.createChild(nodeChar, "powergroup");

			nodeNewGroup = nodePowerGroups.createChild();
			DB.setValue(nodeNewGroup, "castertype", "string", "memorization");
			-- Could only find High Elf with a Cantrip choice assume intelligence
			DB.setValue(nodeNewGroup, "stat", "string", "intelligence");
			DB.setValue(nodeNewGroup, "name", "string", sSpellGroup);

			PowerManager.addPower("reference_spell", nodeSpell, nodeChar, sSpellGroup);

			local sCharName = DB.getValue(nodeChar, "name", "");
			ChatManager.SystemMessageResource("char_abilities_message_spelladd", sSpell, sCharName);
		end
	end
end
function addCommitSpells(nodeChar)
	for k,vClass in pairs(CharWizardManager.getClassData()) do
		if vClass.spell then
			for _,vSelectedSpell in pairs(vClass.spell) do
				local sSpellName = DB.getValue(DB.findNode(vSelectedSpell), "name", "");
				local sRecord = vSelectedSpell;
				local sGroup = Interface.getString("char_spell_powergroup"):format(k);
				PowerManager.addPower("reference_spell", sRecord, nodeChar, sGroup);
			end
		end
	end
end
function addCommitInventory(nodeChar)
	local bIs2024 = CharWizardClassManager.isStartingClass2024();
	local bProcessKits = (bIs2024 or (CharWizardManager.getStartingGold() == 0));
	if not bProcessKits then
		return;
	end

	for _,v in ipairs(CharWizardClassManager.getStartingKitItems()) do
		ItemManager.handleItem(DB.getPath(nodeChar), "inventorylist", "item", DB.getPath(v.item), true);
	end
	for _,v in ipairs(CharWizardBackgroundManager.getBackgroundStartingKitItems()) do
		ItemManager.handleItem(DB.getPath(nodeChar), "inventorylist", "item", DB.getPath(v.item), true);
	end

	CharArmorManager.calcItemArmorClass(nodeChar);
end
function addCommitCurrency(nodeChar)
	local tEquipment = CharWizardManager.getEquipmentData();
	for _,v in ipairs(tEquipment.currency or {}) do
		CurrencyManager.addRecordCurrency(nodeChar, v.name, v.count);
	end
end
