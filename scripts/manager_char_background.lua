-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function addBackground(nodeChar, sClass, sRecord, bWizard)
	local rAdd = CharManager.helperBuildAddStructure(nodeChar, sClass, sRecord, bWizard);
	if not rAdd then
		return;
	end

	CharBackgroundManager.helperAddBackgroundMain(rAdd);
end
function helperAddBackgroundMain(rAdd)
	-- Notification
	ChatManager.SystemMessageResource("char_abilities_message_backgroundadd", rAdd.sSourceName, rAdd.sCharName);

	-- Add the name and link to the main character sheet
	DB.setValue(rAdd.nodeChar, "background", "string", rAdd.sSourceName);
	DB.setValue(rAdd.nodeChar, "backgroundlink", "windowreference", rAdd.sSourceClass, DB.getPath(rAdd.nodeSource));
		
	CharBackgroundManager.helperAddBackgroundFeatures(rAdd);
	
	if not rAdd.bWizard then
		CharBackgroundManager.helperAddBackgroundSkills(rAdd);
		CharBackgroundManager.helperAddBackgroundTools(rAdd);
		CharBackgroundManager.helperAddBackgroundLanguages(rAdd);
	end
end
function helperAddBackgroundFeatures(rAdd)
	for _,v in ipairs(DB.getChildList(rAdd.nodeSource, "features")) do
		CharBackgroundManager.addBackgroundFeature(rAdd.nodeChar, "reference_backgroundfeature", DB.getPath(v), rAdd.bWizard);
	end
end
function helperAddBackgroundSkills(rAdd)
	local sSkills = StringManager.trim(DB.getValue(rAdd.nodeSource, "skill", ""));
	if sSkills ~= "" and sSkills ~= "None" then
		local nPicks = 0;
		local aPickSkills = {};
		if sSkills:match("Choose %w+ from among ") then
			local sPicks, sPickSkills = sSkills:match("Choose (%w+) from among (.*)");
			sPickSkills = sPickSkills:gsub("and ", "");

			sSkills = "";
			nPicks = CharManager.convertSingleNumberTextToNumber(sPicks);
			
			for sSkill in string.gmatch(sPickSkills, "(%a[%a%s]+)%,?") do
				local sTrim = StringManager.trim(sSkill);
				table.insert(aPickSkills, sTrim);
			end
		elseif sSkills:match("plus %w+ from among ") then
			local sPicks, sPickSkills = sSkills:match("plus (%w+) from among (.*)");
			sPickSkills = sPickSkills:gsub("and ", "");
			sPickSkills = sPickSkills:gsub(", as appropriate for your order", "");
			
			sSkills = sSkills:gsub(sSkills:match("plus %w+ from among (.*)"), "");
			nPicks = CharManager.convertSingleNumberTextToNumber(sPicks);
			
			for sSkill in string.gmatch(sPickSkills, "(%a[%a%s]+)%,?") do
				local sTrim = StringManager.trim(sSkill);
				if sTrim ~= "" then
					table.insert(aPickSkills, sTrim);
				end
			end
		elseif sSkills:match("plus your choice of one from among") then
			local sPickSkills = sSkills:match("plus your choice of one from among (.*)");
			sPickSkills = sPickSkills:gsub("and ", "");
			
			sSkills = sSkills:gsub("plus your choice of one from among (.*)", "");
			
			nPicks = 1;
			for sSkill in string.gmatch(sPickSkills, "(%a[%a%s]+)%,?") do
				local sTrim = StringManager.trim(sSkill);
				if sTrim ~= "" then
					table.insert(aPickSkills, sTrim);
				end
			end
		elseif sSkills:match("and one Intelligence, Wisdom, or Charisma skill of your choice, as appropriate to your faction") then
			sSkills = sSkills:gsub("and one Intelligence, Wisdom, or Charisma skill of your choice, as appropriate to your faction", "");
			
			nPicks = 1;
			for k,v in pairs(DataCommon.skilldata) do
				if (v.stat == "intelligence") or (v.stat == "wisdom") or (v.stat == "charisma") then
					table.insert(aPickSkills, k);
				end
			end
			table.sort(aPickSkills);
		end
		
		for sSkill in sSkills:gmatch("(%a[%a%s]+),?") do
			local sTrim = StringManager.trim(sSkill);
			if sTrim ~= "" then
				CharManager.helperAddSkill(rAdd.nodeChar, sTrim, 1);
			end
		end
		
		if nPicks > 0 then
			CharManager.pickSkills(rAdd.nodeChar, aPickSkills, nPicks);
		end
	end
end
function helperAddBackgroundTools(rAdd)
	local sTools = StringManager.trim(DB.getValue(rAdd.nodeSource, "tool", ""));
	if sTools ~= "" and sTools ~= "None" then
		CharManager.addProficiency(rAdd.nodeChar, "tools", sTools);
	end
end
function helperAddBackgroundLanguages(rAdd)
	local sLanguages = StringManager.trim(DB.getValue(rAdd.nodeSource, "languages", ""));
	if sLanguages ~= "" and sLanguages ~= "None" then
		CharManager.addLanguage(rAdd.nodeChar, sLanguages);
	end
end

-- NOTE: Currently, the wizard passes backgrounds through the racial trait system
-- 		And the drop system passes backgrounds through the class feature system
function addBackgroundFeature(nodeChar, sClass, sRecord, bWizard)
	local rAdd = CharManager.helperBuildAddStructure(nodeChar, sClass, sRecord, bWizard);
	if not rAdd then
		return;
	end

	CharBackgroundManager.helperAddBackgroundFeatureMain(rAdd)
end
function helperAddBackgroundFeatureMain(rAdd)
	-- Skip certain entries for wizard additions
	if rAdd.bWizard then
		if CharWizardData.aRaceTraitNoParse[rAdd.sSourceType] then
			return;
		end
		if CharWizardData.aRaceTraitNoAdd[rAdd.sSourceType] then
			return;
		end
		if CharWizardData.aRaceSpecialSpeed[rAdd.sSourceType] then
			return;
		end
		if CharWizardData.aRaceLanguages[rAdd.sSourceType] then
			return;
		end
		if CharWizardData.aRaceProficiency[rAdd.sSourceType] then
			return;
		end
		if CharWizardData.aRaceSkill[rAdd.sSourceType] then
			return;
		end
	end

	-- Make sure feature hasn't already been added
	if CharManager.hasFeature(rAdd.nodeChar, rAdd.sSourceName) then
		return;
	end

	-- Create standard trait entry
	CharBackgroundManager.helperAddBackgroundFeatureStandard(rAdd);

	-- Special handling
	if rAdd.bWizard then
		CharRaceManager.helperAddRaceTraitSpell(rAdd);
	else
		CharManager.checkSkillProficiencies(rAdd.nodeChar, DB.getText(rAdd.nodeSource, "text", ""));
	end

	-- Standard action addition handling
	CharManager.helperCheckActionsAdd(rAdd.nodeChar, rAdd.nodeSource, rAdd.sSourceType, "Race Actions/Effects");
end
function helperAddBackgroundFeatureStandard(rAdd)
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
