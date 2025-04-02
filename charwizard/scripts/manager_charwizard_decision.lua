--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function createDecisions(w, tData)
	local nPicks = tData and tData.nPicks or 1;
	for _ = 1, nPicks do
		CharWizardDecisionManager.createDecision(w, tData);
	end
end
function createDecision(w, tData)
	local wDecision = w.list_decisions.createWindow();
	wDecision.setData(tData);
	w.alert.setVisible();
	w.setDetailsVisible(true);
	return wDecision;
end

function refreshOverallDecisions()
	CharWizardDecisionManager.refreshOverallDecision("skill");
	CharWizardDecisionManager.refreshExpertiseDecision();
	CharWizardDecisionManager.refreshOverallDecision("armorprof");
	CharWizardDecisionManager.refreshOverallDecision("weaponprof");
	CharWizardDecisionManager.refreshOverallDecision("toolprof");
	CharWizardDecisionManager.refreshOverallDecision("language");
end

function refreshOverallDecision(sDecisionType)
	local tMap = CharWizardDecisionManager.helperCollectDataTypeBaseMap(sDecisionType);
	CharWizardDecisionManager.helperCallForEachRecord(CharWizardDecisionManager.helperRefreshRecordDecisionApplyBaseMap, sDecisionType, tMap);
	CharWizardDecisionManager.helperCallForEachRecord(CharWizardDecisionManager.helperRefreshRecordDecisionOptionsUpdate, sDecisionType, tMap);
end
function helperCallForEachRecord(fn, ...)
	local wClassPage = CharWizardManager.getWizardClassWindow();
	local wBackgroundPage = CharWizardManager.getWizardBackgroundWindow();
	local wSpeciesPage = CharWizardManager.getWizardSpeciesWindow();

	if wClassPage then
		for _,wClass in ipairs(wClassPage.class_list.getWindows()) do
			fn(wClass, ...);
		end
	end
	fn(wBackgroundPage, ...);
	fn(wSpeciesPage, ...);
end
function helperCollectDataTypeMap(sDecisionType)
	local tCollectMap = CharWizardManager.helperCollectDataTypeMap(sDecisionType);
	local tFinalMap = {};
	for k,_ in pairs(tCollectMap) do
		tFinalMap[StringManager.simplify(k)] = k;
	end
	return tFinalMap;
end
function helperCollectDataTypeBaseMap(sDecisionType)
	local tCollectMap = CharWizardManager.helperCollectDataTypeBaseMap(sDecisionType);
	local tFinalMap = {};
	for k,_ in pairs(tCollectMap) do
		tFinalMap[StringManager.simplify(k)] = k;
	end
	return tFinalMap;
end
function helperRefreshRecordDecisionApplyBaseMap(wRecord, sDecisionType, tMap)
	if not wRecord or not tMap then
		return;
	end
	for _,wFeature in ipairs(wRecord.list_features.getWindows()) do
		for _,wDecision in ipairs(wFeature.list_decisions.getWindows()) do
			if wDecision.decisiontype.getValue() == sDecisionType then
				local sDecisionKey = StringManager.simplify(wDecision.decision_choice.getValue());
				if (sDecisionKey ~= "") then
					if tMap[sDecisionKey] then
						wDecision.clearDecision();
					else
						tMap[sDecisionKey] = wDecision.decision_choice.getValue();
					end
				end
			end
		end
	end
end
function helperRefreshRecordDecisionOptionsUpdate(wRecord, sDecisionType, tMap)
	if not wRecord or not tMap then
		return;
	end
	for _,wFeature in ipairs(wRecord.list_features.getWindows()) do
		for _,wDecision in ipairs(wFeature.list_decisions.getWindows()) do
			if wDecision.decisiontype.getValue() == sDecisionType then
				wDecision.updateOptions(tMap);
			end
		end
	end
end

function refreshExpertiseDecision()
	local tSkillMap = CharWizardDecisionManager.helperCollectDataTypeMap("skill");
	CharWizardDecisionManager.helperCallForEachRecord(CharWizardDecisionManager.helperRefreshRecordExpertiseDecisionApplySkillMap, tSkillMap);

	local tMap = CharWizardDecisionManager.helperCollectDataTypeBaseMap("expertise");
	CharWizardDecisionManager.helperCallForEachRecord(CharWizardDecisionManager.helperRefreshRecordDecisionApplyBaseMap, "expertise", tMap);

	CharWizardDecisionManager.helperCallForEachRecord(CharWizardDecisionManager.helperRefreshRecordExpertiseDecisionOptionsUpdate, tSkillMap, tMap);
end
function helperRefreshRecordExpertiseDecisionApplySkillMap(wRecord, tSkillMap)
	if not wRecord or not tSkillMap then
		return;
	end
	local sDecisionType = "expertise";
	for _,wFeature in ipairs(wRecord.list_features.getWindows()) do
		for _,wDecision in ipairs(wFeature.list_decisions.getWindows()) do
			if wDecision.decisiontype.getValue() == sDecisionType then
				local sDecisionKey = StringManager.simplify(wDecision.decision_choice.getValue());
				if (sDecisionKey ~= "") then
					if not tSkillMap[sDecisionKey] then
						wDecision.clearDecision();
					end
				end
			end
		end
	end
end
function helperRefreshRecordExpertiseDecisionOptionsUpdate(wRecord, tSkillMap, tMap)
	if not wRecord or not tSkillMap or not tMap then
		return;
	end

	local tOptions = {};
	for _,s in pairs(tSkillMap) do
		table.insert(tOptions, s);
	end
	table.sort(tOptions);

	local sDecisionType = "expertise";
	for _,wFeature in ipairs(wRecord.list_features.getWindows()) do
		for _,wDecision in ipairs(wFeature.list_decisions.getWindows()) do
			if wDecision.decisiontype.getValue() == sDecisionType then
				local sDecision = wDecision.decision_choice.getValue();
				wDecision.setDataOptions(tOptions);
				wDecision.updateOptions(tMap);
				wDecision.decision_choice.setListValue(sDecision);
			end
		end
	end
end

function refreshFeatureChoiceDecision()
	local tMap = {};
	CharWizardDecisionManager.helperCallForEachRecord(CharWizardDecisionManager.helperRefreshRecordDecisionApplyBaseMap, "featurechoice", tMap);
	CharWizardDecisionManager.helperCallForEachRecord(CharWizardDecisionManager.helperRefreshRecordFeatureChoiceDecisionOptionsUpdate, tMap);
end
function helperRefreshRecordFeatureChoiceDecisionOptionsUpdate(wRecord, tMap)
	if not wRecord or not tMap then
		return;
	end

	local sDecisionType = "featurechoice";
	for _,wFeature in ipairs(wRecord.list_features.getWindows()) do
		for _,wDecision in ipairs(wFeature.list_decisions.getWindows()) do
			if wDecision.decisiontype.getValue() == sDecisionType then
				local sDecision = wDecision.decision_choice.getValue();
				wDecision.updateOptions(tMap);
				wDecision.decision_choice.setListValue(sDecision);
			end
		end
	end
end

function processSkillDecision(wDecision)
	CharWizardDecisionManager.refreshOverallDecision(wDecision.decisiontype.getValue());
	return CharWizardDecisionManager.helperCollectFeatureDecisionChoiceMap(wDecision);
end
function processExpertiseDecision(wDecision)
	CharWizardDecisionManager.refreshExpertiseDecision();
	return CharWizardDecisionManager.helperCollectFeatureDecisionChoiceMap(wDecision);
end
function processFeatureChoiceDecision(wDecision)
	CharWizardDecisionManager.refreshFeatureChoiceDecision(wDecision);
	return CharWizardDecisionManager.helperCollectFeatureDecisionChoiceMap(wDecision);
end
function processArmorProfDecision(wDecision)
	CharWizardDecisionManager.refreshOverallDecision(wDecision.decisiontype.getValue());
	return CharWizardDecisionManager.helperCollectFeatureDecisionChoiceMap(wDecision);
end
function processToolProfDecision(wDecision)
	CharWizardDecisionManager.refreshOverallDecision(wDecision.decisiontype.getValue());
	return CharWizardDecisionManager.helperCollectFeatureDecisionChoiceMap(wDecision);
end
function processWeaponProfDecision(wDecision)
	CharWizardDecisionManager.refreshOverallDecision(wDecision.decisiontype.getValue());
	return CharWizardDecisionManager.helperCollectFeatureDecisionChoiceMap(wDecision);
end
function processLanguageDecision(wDecision)
	CharWizardDecisionManager.refreshOverallDecision(wDecision.decisiontype.getValue());
	return CharWizardDecisionManager.helperCollectFeatureDecisionChoiceMap(wDecision);
end
function helperCollectFeatureDecisionChoiceMap(wDecision)
	local sDecisionType = wDecision.decisiontype.getValue();
	local tMap = {};
	for _,wFeature in ipairs(wDecision.windowlist.window.windowlist.getWindows()) do
		for _,w in ipairs(wFeature.list_decisions.getWindows()) do
			if w.decisiontype.getValue() == sDecisionType then
				local sDecisionKey = StringManager.simplify(w.decision_choice.getValue());
				if (sDecisionKey ~= "") then
					tMap[sDecisionKey] = w.decision_choice.getValue();
				end
			end
		end
	end
	return tMap;
end

-- Ensure ability decision across all background/species decisions are unique
function processAbilityDecision(wDecision)
	local sDecisionType = wDecision.decisiontype.getValue();

	local tAbilityMap = {};
	local sDecisionKey = StringManager.simplify(wDecision.decision_choice.getValue());
	if sDecisionKey ~= "" then
		tAbilityMap[sDecisionKey] = wDecision.decision.getValue():match("%d+") or 0;
	end

	local cFeatureList = wDecision.windowlist.window.windowlist
	for _,wFeature in ipairs(cFeatureList.getWindows()) do
		for _,w in ipairs(wFeature.list_decisions.getWindows()) do
			if (w ~= wDecision) and (w.decisiontype.getValue() == sDecisionType) then
				local sDecisionKey = StringManager.simplify(w.decision_choice.getValue());
				if sDecisionKey ~= "" then
					if tAbilityMap[sDecisionKey] then
						w.clearDecision();
					else
						tAbilityMap[sDecisionKey] = w.decision.getValue():match("%d+") or 0;
					end
				end
			end
		end
	end
	for _,wFeature in ipairs(cFeatureList.getWindows()) do
		for _,w in ipairs(wFeature.list_decisions.getWindows()) do
			if (w.decisiontype.getValue() == sDecisionType) then
				w.updateOptions(tAbilityMap);
			end
		end
	end

	return tAbilityMap;
end
-- Ensure ability decision within a class feature are unique
function processFeatureAbilityDecision(wDecision)
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
					w.clearDecision();
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
-- For spells, only make sure decisions within a feature are unique for now
function processSpellDecision(wDecision)
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
					w.clearDecision();
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
