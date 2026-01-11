--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function handleDrop(sTarget, draginfo)
	if sTarget == "class_specialization" then
		return CampaignDataManager2.handleSubclassDrop(draginfo);
	elseif sTarget == "race_subrace" then
		return CampaignDataManager2.handleAncestryDrop(draginfo);
	end
end
function handleSubclassDrop(draginfo)
	if not LibraryData.allowEdit("class_specialization") then
		return false;
	end

	local sClass,sRecord = draginfo.getShortcutData();
	if sClass == "reference_classability" then
		CampaignDataManager2.helperOldSubclassCopy(draginfo.getDatabaseNode());
		return true;
	elseif RecordDataManager.isRecordTypeDisplayClass("class", sClass) then
		for _,nodeOldSpec in ipairs(DB.getChildList(DB.getPath(sRecord, "abilities"))) do
			CampaignDataManager2.helperOldSubclassCopy(nodeOldSpec);
		end
		return true;
	end
	return false;
end
function handleAncestryDrop(draginfo)
	if not LibraryData.allowEdit("race_subrace") then
		return false;
	end

	local sClass,sRecord = draginfo.getShortcutData();
	if RecordDataManager.isRecordTypeDisplayClass("race", sClass) then
		for _,nodeOldAncestry in ipairs(DB.getChildList(DB.getPath(sRecord, "subraces"))) do
			CampaignDataManager2.helperOldAncestryCopy(nodeOldAncestry);
		end
		return true;
	end
	return false;
end

function handleKitItemDrop(draginfo, nodeTarget)
	local sClass, sRecord = draginfo.getShortcutData();
	if StringManager.contains({
		"item", "reference_magicitem", "reference_armor", "reference_weapon",
		"reference_equipment", "reference_mountsandotheranimals",
		"reference_waterbornevehicles", "reference_vehicle" }, sClass) then

		local nodeSource = DB.findNode(sRecord);
		local sItem = DB.getValue(nodeSource, "name", "");
		local nodeOptionItem = "";
		for _,v in ipairs(DB.getChildList(DB.getChild(nodeTarget, "."))) do
			local sName = DB.getValue(v, "name", "");
			if sItem == sName then
				nodeOptionItem = v;
			end
		end

		if nodeOptionItem == "" then
			local nodeNewOptionItem = DB.createChild(nodeTarget);
			DB.copyNode(nodeSource, nodeNewOptionItem);

			DB.setValue(nodeNewOptionItem, "locked", "number", 1);
		else
			local nCount = DB.getValue(nodeOptionItem, "count", 0);
			DB.setValue(nodeOptionItem, "count", "number", nCount + 1);
		end
		return true;
	end

	return false;
end

function lookupCharData(sRecord, aRefModules)
	local node;
	local sPath, sModule = sRecord:match("([^@]*)@(.*)");
	if sModule then
		node = DB.findNode(sRecord);
		if not node and sModule == "*" then
			if sRecord:match("^reference%.equipmentdata%.") then
				node = DB.findNode(sRecord:gsub("^reference%.equipmentdata%.", "item."));
			elseif sRecord:match("^reference%.spelldata%.") then
				node = DB.findNode(sRecord:gsub("^reference%.spelldata%.", "spell."));
			end
		end
	else
		node = DB.findNode(sRecord);
		sPath = sRecord;
	end
	if node then
		return node;
	end

	local sModulePath = sPath:gsub("^reference[^.]*%.", "reference.");
	for _,v in ipairs(aRefModules) do
		local node = DB.findNode(string.format("%s@%s", sModulePath, v));
		if node then
			return node;
		end
	end

	return node;
end

function addPregenChar(nodeSource)
	local nodeTarget = CampaignDataManager.addPregenCharCore(nodeSource);
	if not nodeTarget then
		return nil;
	end

	-- Perform 5E specific processing
	CampaignDataManager.addPregenCharLockListEntries(nodeTarget, "featlist");
	CampaignDataManager.addPregenCharLockListEntries(nodeTarget, "featurelist");
	CampaignDataManager.addPregenCharLockListEntries(nodeTarget, "traitlist");
	CampaignDataManager.addPregenCharLockListEntries(nodeTarget, "proficiencylist");
	CampaignDataManager.addPregenCharLockListEntries(nodeTarget, "powers");

	return nodeTarget;
end

function onEncounterGenerated(nodeEncounter)
	CombatManager2.calcBattleCR(nodeEncounter);
end

-- Check to see if NPC has no spell entries defined, but a spellcasting trait. If so, then attempt to lookup and add spells.
function updateNPCSpells(nodeNPC)
	if not nodeNPC then
		return;
	end
	if DB.isReadOnly(nodeNPC) then
		return;
	end

	if (DB.getChildCount(nodeNPC, "spells") > 0) or (DB.getChildCount(nodeNPC, "innatespells") > 0) then
		return;
	end

	for _,v in ipairs(DB.getChildList(nodeNPC, "traits")) do
		local sTraitName = StringManager.trim(DB.getValue(v, "name", ""):lower());
		if sTraitName:match("^spellcasting") then
			CampaignDataManager2.updateNPCSpellcasting(nodeNPC, v);
		elseif sTraitName:match("^innate spellcasting") then
			CampaignDataManager2.updateNPCInnateSpellcasting(nodeNPC, v);
		end
	end

	for _,v in ipairs(DB.getChildList(nodeNPC, "actions")) do
		local sTraitName = StringManager.trim(DB.getValue(v, "name", ""):lower());
		if sTraitName:match("^spellcasting") then
			CampaignDataManager2.updateNPCActionSpellcasting(nodeNPC, v);
		end
	end
end
function updateNPCSpellcasting(nodeNPC, _)
	local aError = {};

	local rActor = ActorManager.resolveActor(nodeNPC);
	if rActor then
		local aPowerGroup = PowerManager.getPowerGroupRecord(rActor, nil, false);
		if aPowerGroup then
			for i = 0,9 do
				if aPowerGroup[i] then
					for _,sSpell in ipairs(aPowerGroup[i]) do
						if not CampaignDataManager2.updateNPCSpellHelper(sSpell, nodeNPC, aPowerGroup.bInnate) then
							table.insert(aError, sSpell);
						end
					end
				end
				if (i > 0) then
					if aPowerGroup[i] and aPowerGroup[i]["slots"] then
						DB.setValue(nodeNPC, "spellslots.level" .. i, "number", aPowerGroup[i]["slots"]);
					else
						DB.setValue(nodeNPC, "spellslots.level" .. i, "number", 0);
					end
				end
			end
		end
	end

	if #aError > 0 then
		ChatManager.SystemMessage("Failed spellcasting lookup on " .. #aError .. " spell(s) for (" .. DB.getValue(nodeNPC, "name", "") .. "). Make sure your spell module(s) are open.");
		ChatManager.SystemMessage("Spell lookup failures: " .. table.concat(aError, ", "));
	end
end
function resetNPCSpellcastingSlots(nodeNPC, _)
	if not nodeNPC then
		return;
	end
	if DB.isReadOnly(nodeNPC) then
		return;
	end

	for _,v in ipairs(DB.getChildList(nodeNPC, "traits")) do
		local sTraitName = StringManager.trim(DB.getValue(v, "name", ""):lower());
		if sTraitName:match("^spellcasting") then
			local rActor = ActorManager.resolveActor(nodeNPC);
			if rActor then
				local aPowerGroup = PowerManager.getPowerGroupRecord(rActor, nil, false);
				if aPowerGroup then
					for i = 1,9 do
						if aPowerGroup[i] and aPowerGroup[i]["slots"] then
							DB.setValue(nodeNPC, "spellslots.level" .. i, "number", aPowerGroup[i]["slots"]);
						else
							DB.setValue(nodeNPC, "spellslots.level" .. i, "number", 0);
						end
					end
				end
			end
		end
	end
end
function updateNPCInnateSpellcasting(nodeNPC, _)
	local aError = {};

	local rActor = ActorManager.resolveActor(nodeNPC);
	if rActor then
		local aPowerGroup = PowerManager.getPowerGroupRecord(rActor, nil, true);
		if aPowerGroup then
			for i = 0,9 do
				if aPowerGroup[i] then
					for _,sSpell in ipairs(aPowerGroup[i]) do
						if not CampaignDataManager2.updateNPCSpellHelper(sSpell, nodeNPC, aPowerGroup.bInnate, i) then
							table.insert(aError, sSpell);
						end
					end
				end
			end
		end
	end

	if #aError > 0 then
		ChatManager.SystemMessage("Failed innate spellcasting lookup on " .. #aError .. " spell(s) for (" .. DB.getValue(nodeNPC, "name", "") .. "). Make sure your spell module(s) are open.");
		ChatManager.SystemMessage("Spell lookup failures: " .. table.concat(aError, ", "));
	end
end
function updateNPCActionSpellcasting(nodeNPC, _)
	local aError = {};

	local rActor = ActorManager.resolveActor(nodeNPC);
	if rActor then
		local aPowerGroup = PowerManager.getPowerGroupRecord(rActor, nil, true);
		if aPowerGroup then
			for i = 0,9 do
				if aPowerGroup[i] then
					for _,sSpell in ipairs(aPowerGroup[i]) do
						if not CampaignDataManager2.updateNPCSpellHelper(sSpell, nodeNPC, aPowerGroup.bInnate, i) then
							table.insert(aError, sSpell);
						end
					end
				end
			end
		end
	end

	if #aError > 0 then
		ChatManager.SystemMessage("Failed spellcasting lookup on " .. #aError .. " spell(s) for (" .. DB.getValue(nodeNPC, "name", "") .. "). Make sure your spell module(s) are open.");
		ChatManager.SystemMessage("Spell lookup failures: " .. table.concat(aError, ", "));
	end
end
function updateNPCSpellHelper(sSpell, nodeNPC, bInnate, nDaily)
	local sCleaned = PowerManager.cleanNPCPowerName(sSpell);
	local tFilters = {
		{ sField = "name", sValue = sCleaned, bIgnoreCase = true, },
		{ sField = "version", sValue = (OptionsManager.isOption("GAVE", "2024") and "2024" or ""), },
	};
	local nodeSpell = RecordManager.findRecordByFilter("spell", tFilters);
	if not nodeSpell then
		tFilters = {
			{ sField = "name", sValue = sCleaned, bIgnoreCase = true, },
		};
		nodeSpell = RecordManager.findRecordByFilter("spell", tFilters);
		if not nodeSpell then
			return false;
		end
	end

	CampaignDataManager2.addNPCSpell(nodeNPC, nodeSpell, bInnate, nDaily);
	return true;
end
function addNPCSpell(nodeNPC, nodeSpellSource, bInnate, nDaily)
	-- Create the new spell node
	local nodeSpell;
	if bInnate then
		nodeSpell = DB.createChild(DB.getPath(nodeNPC, "innatespells"));
	else
		nodeSpell = DB.createChild(DB.getPath(nodeNPC, "spells"));
	end

	-- Add the daily use or level information to the name field
	local nLevel = DB.getValue(nodeSpellSource, "level", 0);
	local sSpellName = DB.getValue(nodeSpellSource, "name", "");
	if bInnate then
		if nDaily then
			if nDaily == 0 then
				DB.setValue(nodeSpell, "name", "string", sSpellName .. " (At will)");
			else
				DB.setValue(nodeSpell, "name", "string", sSpellName .. " (" .. nDaily .. "/day)");
			end
		else
			DB.setValue(nodeSpell, "name", "string", sSpellName);
		end
	else
		if nLevel == 1 then
			DB.setValue(nodeSpell, "name", "string", sSpellName .. " - 1st level");
		elseif nLevel == 2 then
			DB.setValue(nodeSpell, "name", "string", sSpellName .. " - 2nd level");
		elseif nLevel == 3 then
			DB.setValue(nodeSpell, "name", "string", sSpellName .. " - 3rd level");
		elseif nLevel >= 4 then
			DB.setValue(nodeSpell, "name", "string", sSpellName .. " - " .. nLevel .. "th level");
		else
			DB.setValue(nodeSpell, "name", "string", sSpellName .. " - Cantrip");
		end
	end

	-- Convert the multi-field spell data to a single spell description field.
	local sDesc = "Level: " .. nLevel;
	sDesc = sDesc .. "\rSchool: " .. DB.getValue(nodeSpellSource, "school", "");
	sDesc = sDesc .. "\rCasting Time: " .. DB.getValue(nodeSpellSource, "castingtime", "");
	sDesc = sDesc .. "\rComponents: " .. DB.getValue(nodeSpellSource, "components", "");
	sDesc = sDesc .. "\rDuration: " .. DB.getValue(nodeSpellSource, "duration", "");
	sDesc = sDesc .. "\rRange: " .. DB.getValue(nodeSpellSource, "range", "");
	sDesc = sDesc .. "\r";

	local sRefDesc = DB.getText(nodeSpellSource, "description");
	if sRefDesc then
		sDesc = sDesc .. "\r" .. sRefDesc;
	end

	DB.setValue(nodeSpell, "desc", "string", sDesc);
end

--
--	Legacy module data migration helpers
--

function helperOldSubclassCopy(nodeSource)
	local sRootMapping = LibraryData.getRootMapping("class_specialization");
	if ((sRootMapping or "") == "") then
		return;
	end

	local nodeTarget = DB.createChild(sRootMapping);
	local sSubclass = StringManager.trim(DB.getValue(nodeSource, "name", ""));
	DB.setValue(nodeTarget, "name", "string", sSubclass);
	DB.setValue(nodeTarget, "locked", "number", 1);

	local nodeClass = DB.getChild(nodeSource, "...");
	local sClassName = DB.getValue(nodeClass, "name", "");
	DB.setValue(nodeTarget, "class", "string", sClassName);

	local sSubclassText = DB.getValue(nodeSource, "text", "");
	local tFeatureLinks = {};
	for sSourceFeatureLinkPath in sSubclassText:gmatch("<link class=\"reference_classfeature\" recordname=\"([^\"]*)\"") do
		tFeatureLinks[sSourceFeatureLinkPath] = "";
	end
	local nodeFeatureList = DB.createChild(nodeTarget, "features");
	for _,nodeSourceFeature in ipairs(DB.getChildList(nodeClass, "features")) do
		local sMatch = StringManager.trim(DB.getValue(nodeSourceFeature, "specialization", ""));
		if sMatch == sSubclass then
			local nodeFeature = DB.createChild(nodeFeatureList);
			DB.setValue(nodeFeature, "name", "string", DB.getValue(nodeSourceFeature, "name", 0));
			DB.setValue(nodeFeature, "level", "number", DB.getValue(nodeSourceFeature, "level", 0));
			DB.setValue(nodeFeature, "text", "formattedtext", DB.getValue(nodeSourceFeature, "text", ""));
			DB.setValue(nodeFeature, "locked", "number", 1);

			local sSourceFeaturePath = DB.getPath(nodeSourceFeature);
			if tFeatureLinks[sSourceFeaturePath] then
				tFeatureLinks[sSourceFeaturePath] = DB.getPath(nodeFeature);
			end
		end
	end
	for sSourceFeaturePath, sTargetFeaturePath in pairs(tFeatureLinks) do
		if sTargetFeaturePath ~= "" then
			sSubclassText = sSubclassText:gsub(sSourceFeaturePath, sTargetFeaturePath);
		end
	end
	DB.setValue(nodeTarget, "text", "formattedtext", sSubclassText);
end

function helperOldAncestryCopy(nodeSource)
	local sRootMapping = LibraryData.getRootMapping("race_subrace");
	if ((sRootMapping or "") == "") then
		return;
	end

	local nodeTarget = DB.createChild(sRootMapping);
	DB.setValue(nodeTarget, "name", "string", DB.getValue(nodeSource, "name", ""));
	DB.setValue(nodeTarget, "locked", "number", 1);

	local sSpeciesName = DB.getValue(nodeSource, "...name", "");
	DB.setValue(nodeTarget, "race", "string", sSpeciesName);

	local sAncestryText = DB.getValue(nodeSource, "text", "");
	local tTraitLinks = {};
	for sSourceTraitLinkPath in sAncestryText:gmatch("<link class=\"reference_subracialtrait\" recordname=\"([^\"]*)\"") do
		tTraitLinks[sSourceTraitLinkPath] = "";
	end
	local nodeTraitList = DB.createChild(nodeTarget, "traits");
	for _,nodeSourceTrait in ipairs(DB.getChildList(nodeSource, "traits")) do
		local nodeTrait = DB.createChild(nodeTraitList);
		DB.setValue(nodeTrait, "name", "string", DB.getValue(nodeSourceTrait, "name", 0));
		DB.setValue(nodeTrait, "text", "formattedtext", DB.getValue(nodeSourceTrait, "text", ""));
		DB.setValue(nodeTrait, "locked", "number", 1);

		local sSourceTraitPath = DB.getPath(nodeSourceTrait);
		if tTraitLinks[sSourceTraitPath] then
			tTraitLinks[sSourceTraitPath] = DB.getPath(nodeTrait);
		end
	end
	for sSourceTraitPath, sTargetTraitPath in pairs(tTraitLinks) do
		if sTargetTraitPath ~= "" then
			sAncestryText = sAncestryText:gsub(sSourceTraitPath, sTargetTraitPath);
		end
	end
	DB.setValue(nodeTarget, "text", "formattedtext", sAncestryText);
end
