-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function addBackground(nodeChar, sRecord, tData)
	local rAdd = CharBuildDropManager.helperBuildAddStructure(nodeChar, "reference_background", sRecord, tData);
	CharBackgroundManager.helperAddBackgroundMain(rAdd);
end
function addBackgroundFeature(nodeChar, sRecord, tData)
	local rAdd = CharBuildDropManager.helperBuildAddStructure(nodeChar, "reference_backgroundfeature", sRecord, tData);
	CharBackgroundManager.helperAddBackgroundFeatureMain(rAdd);
end

function getFeatureBackgroundName(rAdd)
	return DB.getValue(rAdd.nodeSource, "...name", "");
end
function getFeatureSpellGroup(rAdd)
	return Interface.getString("char_spell_powergroup"):format(CharBackgroundManager.getFeatureBackgroundName(rAdd));
end
function getFeaturePowerGroup(rAdd)
	return Interface.getString("char_background_powergroup"):format(CharBackgroundManager.getFeatureBackgroundName(rAdd));
end

function helperAddBackgroundMain(rAdd)
	if not rAdd then
		return;
	end

	-- Notification
	ChatManager.SystemMessageResource("char_abilities_message_backgroundadd", rAdd.sSourceName, rAdd.sCharName);

	-- Add the name and link to the main character sheet
	DB.setValue(rAdd.nodeChar, "background", "string", rAdd.sSourceName);
	DB.setValue(rAdd.nodeChar, "backgroundlink", "windowreference", rAdd.sSourceClass, DB.getPath(rAdd.nodeSource));
		
	if rAdd.bWizard then
		if not rAdd.bSource2024 then
			CharBackgroundManager.helperAddBackgroundFeatures2014(rAdd);
		end
	else
		if rAdd.bSource2024 then
			CharBackgroundManager.helperAddBackgroundAbilities2024(rAdd);
			CharBackgroundManager.helperAddBackgroundFeat2024(rAdd);
			CharBuildDropManager.handleBackgroundSkillsField(rAdd);
			CharBuildDropManager.handleBackgroundToolsField(rAdd);
		else
			CharBackgroundManager.helperAddBackgroundFeatures2014(rAdd);
			CharBuildDropManager.handleBackgroundSkillsField(rAdd);
			CharBuildDropManager.handleBackgroundToolsField(rAdd);
			CharBuildDropManager.handleBackgroundLanguagesField(rAdd);
		end
	end
end
function helperAddBackgroundAbilities2024(rAdd)
	CharBuildDropManager.handleAbilitiesField(rAdd);
end
function helperAddBackgroundFeat2024(rAdd)
	local s = StringManager.trim(DB.getValue(rAdd.nodeSource, "feat", ""));
	if (s == "None") then
		return;
	end

	if s ~= "" then
		CharManager.addFeat(rAdd.nodeChar, s, { bSource2024 = true, });
	else
		local tOptions = RecordManager.getRecordOptionsByStringI("feat", "category", "Origin", true);
		CharBuildDropManager.pickFeat(rAdd.nodeChar, tOptions, 1, { bWizard = rAdd.bWizard, bSource2024 = rAdd.bSource2024, });
	end
end
function helperAddBackgroundFeatures2014(rAdd)
	for _,v in ipairs(DB.getChildList(rAdd.nodeSource, "features")) do
		CharBackgroundManager.addBackgroundFeature(rAdd.nodeChar, "reference_backgroundfeature", DB.getPath(v), { bWizard = rAdd.bWizard });
	end
end

function helperAddBackgroundFeatureMain(rAdd)
	if not rAdd then
		return;
	end
	if CharManager.hasFeature(rAdd.nodeChar, rAdd.sSourceName) then
		return;
	end

	if rAdd.bWizard then
		CharBackgroundManager.helperAddBackgroundFeatureMainWizard(rAdd);
	else
		CharBackgroundManager.helperAddBackgroundFeatureMainDrop(rAdd);
	end
end
function helperAddBackgroundFeatureMainWizard(rAdd)
	if CharWizardData.tBuildOptionsSpecialSpeed2024[rAdd.sSourceType] then
		return;
	end
	if CharWizardData.tBuildOptionsLanguages2024[rAdd.sSourceType] then
		return;
	end
	if CharWizardData.tBuildOptionsProficiency2024[rAdd.sSourceType] then
		return;
	end
	if CharWizardData.tBuildOptionsSkill2024[rAdd.sSourceType] then
		return;
	end

	CharBackgroundManager.helperAddBackgroundFeatureStandard(rAdd);

	if CharWizardData.tBuildOptionsNoParse2024[rAdd.sSourceType] then
		return;
	end

	CharBuildDropManager.checkBackgroundFeatureActions(rAdd);
end
function helperAddBackgroundFeatureMainDrop(rAdd)
	CharBackgroundManager.helperAddBackgroundFeatureStandard(rAdd);

	if CharWizardData.tBuildOptionsNoParse2024[rAdd.sSourceType] then
		return;
	end

	CharBuildDropManager.checkFeatureDescription(rAdd);
	CharBuildDropManager.checkBackgroundFeatureActions(rAdd);
end
function helperAddBackgroundFeatureStandard(rAdd)
	if not rAdd or not rAdd.nodeChar then
		return nil;
	end

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
