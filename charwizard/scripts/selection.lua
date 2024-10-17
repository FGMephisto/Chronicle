--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onSelectButtonPressed()
	local sClass = getClass();
	if sClass == "list_entry_charwizard_backgroundselection" then
		CharWizardBackgroundManager.processBackground(self);
	elseif sClass == "list_entry_charwizard_speciesselection" then
		CharWizardSpeciesManager.processSpecies(self);
	elseif sClass == "list_entry_charwizard_ancestryselection" then
		CharWizardSpeciesManager.processAncestry(self);
	elseif sClass == "list_entry_decision_speciesfeat" then
		CharWizardSpeciesManager.processSpeciesDecisionFeat(self);
	elseif sClass == "list_entry_charwizard_classselection" then
		CharWizardClassManager.onAddClassButton(self);
	elseif sClass == "list_entry_charwizard_subclassselection" then
		CharWizardClassManager.onAddSubclassButton(self);
	elseif sClass == "list_entry_decision_classfeat" then
		CharWizardClassManager.onAddFeatClassButton(self);
	elseif sClass == "list_entry_list_spells" then
		CharWizardClassManager.addClassKnownSpell(self);
	end
end

function onModuleValueChanged()
	local sClass = getClass();
	if sClass == "list_entry_charwizard_backgroundselection" then
		self.onModuleValueChangedGeneral("getAllBackgrounds", "reference_background");
	elseif sClass == "list_entry_charwizard_speciesselection" then
		self.onModuleValueChangedGeneral("getAllSpecies", "reference_race");
	elseif sClass == "list_entry_charwizard_ancestryselection" then
		self.onModuleValueChangedAncestry();
	elseif sClass == "list_entry_decision_speciesfeat" then
		self.onModuleValueChangedGeneral("getAllFeats", "reference_feat");
	elseif sClass == "list_entry_charwizard_classselection" then
		self.onModuleValueChangedGeneral("getAllClasses", "reference_class");
	elseif sClass == "list_entry_charwizard_subclassselection" then
		self.onModuleValueChangedGeneral("getAllSubclasses", "reference_class_specialization");
	elseif sClass == "list_entry_decision_classfeat" then
		self.onModuleValueChangedGeneral("getAllFeats", "reference_feat");
	elseif sClass == "list_entry_list_spells" then
		self.onModuleValueChangedGeneral("getAllSpells", "power");
	end
end
function onModuleValueChangedGeneral(sFunction, sRecordClass)
	local sName = name.getValue():lower();
	local tRecords = WindowManager.callOuterWindowFunction(self, sFunction);
	for k,v in pairs(tRecords) do
		if k == sName then
			for _,v2 in ipairs(v) do
				if module.getValue() == v2.sModule then
					shortcut.setValue(sRecordClass, DB.getPath(v2.vNode));
					return;
				end
			end
		end
	end
end
function onModuleValueChangedAncestry()
	local sName = name.getValue();
	local tRecords = CharWizardSpeciesManager.collectAncestries();
	for k,v in pairs(tRecords) do
		if k == sName then
			for _,v2 in ipairs(v) do
				if module.getValue() == v2.sModule then
					shortcut.setValue(v2.linkclass, v2.linkrecord);
					return;
				end
			end
		end
	end
end
