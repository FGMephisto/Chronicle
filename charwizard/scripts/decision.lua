--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function setData(tData)
	local sDecisionType = tData and tData.sDecisionType or "";
	decisiontype.setValue(sDecisionType);

	local bAbilityChoice = false;
	if sDecisionType == "skill" then
		decision.setValue(Interface.getString("charwizard_label_decision_skill"));
	elseif sDecisionType == "expertise" then
		decision.setValue(Interface.getString("charwizard_label_decision_expertise"));
	elseif sDecisionType == "armorprof" then
		decision.setValue(Interface.getString("charwizard_label_decision_armorprof"));
	elseif sDecisionType == "weaponprof" then
		decision.setValue(Interface.getString("charwizard_label_decision_weaponprof"));
	elseif sDecisionType == "toolprof" then
		decision.setValue(Interface.getString("charwizard_label_decision_toolprof"));
	elseif sDecisionType == "language" then
		decision.setValue(Interface.getString("charwizard_label_decision_language"));
	elseif sDecisionType == "feat" then
		decision.setValue(Interface.getString("charwizard_label_decision_feat"));
		alert.setVisible(true);
	elseif sDecisionType == "spell" then
		decision.setValue(Interface.getString("charwizard_label_decision_spell"));
	elseif sDecisionType == "subclass" then
		decision.setValue(Interface.getString("charwizard_label_decision_subclass"));
	elseif sDecisionType == "size" then
		decision.setValue(Interface.getString("charwizard_label_decision_size"));
		alert.setVisible(true);
	elseif sDecisionType == "asiorfeat" then
		decision.setValue(Interface.getString("charwizard_label_decision_asiorfeat"));
		decision_choice.addItems({ "Ability Score Increase", "Feat" });
		alert.setVisible(true);
	elseif sDecisionType == "asiclassoption" then
		decision.setValue(Interface.getString("charwizard_label_decision_asiclassoption"));
		decision_choice.addItems({"Option 1: One +2", "Option 2: Two +1's"});
		alert.setVisible(true);
	elseif sDecisionType == "asiclass" then
		decision.setValue(string.format(Interface.getString("charwizard_label_decision_asiclass"), tData and tData.nAdj or 1));
		bAbilityChoice = true;
	elseif sDecisionType == "asibackgroundoption" then
		decision.setValue(Interface.getString("charwizard_label_decision_asibackgroundoption"));
		decision_choice.addItems({"Option 1: One +2, One +1", "Option 2: Three +1's"});
	elseif sDecisionType == "asibackground" then
		decision.setValue(string.format(Interface.getString("charwizard_label_decision_asibackground"), tData and tData.nAdj or 1));
		bAbilityChoice = true;
	elseif sDecisionType == "asispeciesoption" then
		decision.setValue(Interface.getString("charwizard_label_decision_asispeciesoption"));
		decision_choice.addItems({"Option 1: One +2, One +1", "Option 2: Three +1's"});
	elseif sDecisionType == "asispecies" then
		decision.setValue(string.format(Interface.getString("charwizard_label_decision_asispecies"), tData and tData.nAdj or 1));
		bAbilityChoice = true;
	elseif sDecisionType == "variabletrait" then
		decision.setValue(Interface.getString("charwizard_label_decision_variabletrait"));
		decision_choice.addItems({ "Darkvision", "Skill" });
	elseif sDecisionType == "featurechoice" then
		decision.setValue(Interface.getString("charwizard_label_decision_featuredecision"));
	end

	if tData and tData.sDecisionClass then
		sub_decision_choice.setVisible(true);
		sub_decision_choice.setValue(tData.sDecisionClass, "");
		decision_choice.setComboBoxVisible(false);
	end

	if tData and (#(tData.tOptions or {}) > 0) then
		self.setDataOptions(tData.tOptions);
	elseif bAbilityChoice then
		self.setAbilityDataOptions();
	end
end

local _tDataOptions = {}
function getDataOptions()
	return _tDataOptions;
end
function setDataOptions(tOptions)
	_tDataOptions = UtilityManager.copyDeep(tOptions) or {};
	self.updateOptions();
end
function setAbilityDataOptions()
	local tAbilityOptions = {};
	for _,sAbility in pairs(DataCommon.abilities) do
		table.insert(tAbilityOptions, StringManager.capitalize(sAbility));
	end
	self.setDataOptions(tAbilityOptions);
end
function updateOptions(tSelectedSimplifiedKeyMap)
	tSelectedSimplifiedKeyMap = tSelectedSimplifiedKeyMap or {};
	decision_choice.clear();
	decision_choice.add("");
	for _,sOption in ipairs(self.getDataOptions()) do
		if not tSelectedSimplifiedKeyMap[StringManager.simplify(sOption)] or (decision_choice.getValue() == sOption) then
			decision_choice.add(sOption);
		end
	end
	if decision_choice.getValue() == "" then
		alert.setVisible();
	end
end

function clearDecision()
	decision_choice.setListValue("");
	self.checkOutstandingDecisions();
end

function onResetButtonPressed()
	local sClass = getClass();
	if sClass == "list_entry_charwizard_feature_decisions" then
		CharWizardClassManager.resetClassDecision(self);
	elseif sClass == "list_entry_charwizard_backgroundfeature_decisions" then
		CharWizardBackgroundManager.resetBackgroundDecisionFeat(self);
	elseif sClass == "list_entry_charwizard_trait_decisions" then
		CharWizardSpeciesManager.resetSpeciesDecisionFeat(self);
	end
end

function checkOutstandingDecisions()
	local bOutstandingDecisions = false;
	for _,wChild in ipairs(windowlist.getWindows()) do
		if wChild.hasOutstandingDecision() then
			bOutstandingDecisions = true;
			break;
		end
	end
	windowlist.window.setDetailsVisible(bOutstandingDecisions);
end
function hasOutstandingDecision()
	return (decision_choice.getValue() == "") and (choice.getValue() == "");
end

function onDecisionChoiceChanged()
	local sClass = getClass();
	if sClass == "list_entry_charwizard_feature_decisions" then
		CharWizardClassManager.processClassDecision(self);
	elseif sClass == "list_entry_charwizard_backgroundfeature_decisions" then
		CharWizardBackgroundManager.processBackgroundDecision(self);
	elseif sClass == "list_entry_charwizard_trait_decisions" then
		CharWizardSpeciesManager.processSpeciesDecision(self);
	end

	self.checkOutstandingDecisions();
end
