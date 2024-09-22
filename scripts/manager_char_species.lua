-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function addSpecies(nodeChar, sRecord, tData)
	local rAdd = CharBuildDropManager.helperBuildAddStructure(nodeChar, "reference_race", sRecord, tData);
	CharSpeciesManager.helperResolveAncestryOnSpeciesDrop(rAdd);
end
function addAncestry(nodeChar, sRecord, tData)
	local rAdd = CharBuildDropManager.helperBuildAddStructure(nodeChar, "reference_subrace", sRecord, tData);
	CharSpeciesManager.helperResolveSpeciesOnAncestryDrop(rAdd);
end
function addSpeciesTrait(nodeChar, sRecord, tData)
	local rAdd = CharBuildDropManager.helperBuildAddStructure(nodeChar, "reference_racialtrait", sRecord, tData);
	CharSpeciesManager.helperAddSpeciesTraitMain(rAdd);
end

function helperResolveAncestryOnSpeciesDrop(rAdd)
	if not rAdd then
		return;
	end
	local tOptions = CharSpeciesManager.getAncestryOptions(rAdd.nodeSource, rAdd.bSource2024);
	if #tOptions == 0 then
		CharSpeciesManager.helperAddSpecies(rAdd);
		return;
	end

	if #tOptions == 1 then
		-- Automatically select only ancestry
		rAdd.sAncestryPath = tOptions[1].linkrecord;
		CharSpeciesManager.helperAddSpecies(rAdd);
	else
		local tData = {
			title = Interface.getString("char_build_title_selectancestry"),
			msg = Interface.getString("char_build_message_selectancestry"),
			options = tOptions,
			callback = CharSpeciesManager.callbackResolveAncestryOnSpeciesDrop,
			custom = rAdd,
		};
		local wSelect = Interface.openWindow("select_dialog", "");
		wSelect.requestSelectionByData(tData);
	end
end
function callbackResolveAncestryOnSpeciesDrop(tSelection, rAdd, tSelectionLinks)
	if not tSelectionLinks or (#tSelectionLinks ~= 1) then
		CharManager.outputUserMessage("char_error_addancestry");
		return;
	end
	rAdd.sAncestryPath = tSelectionLinks[1].linkrecord;
	CharSpeciesManager.helperAddSpecies(rAdd);
end
function helperResolveSpeciesOnAncestryDrop(rAdd)
	if not rAdd then
		return;
	end
	local sSpeciesName, nodeSpecies = CharSpeciesManager.getSpeciesFromAncestry(rAdd.sSourceName, rAdd.bSource2024);
	if not nodeSpecies or ((sSpeciesName or "") == "") then
		ChatManager.SystemMessageResource("char_error_missingspeciesfromancestry");
		return;
	end

	local rSpeciesAdd = {
		nodeSource = nodeSpecies,
		sSourceClass = "reference_race",
		sSourceName = sSpeciesName,
		nodeChar = rAdd.nodeChar,
		sCharName = rAdd.sCharName,
		sAncestryPath = DB.getPath(rAdd.nodeSource),
	};
	CharSpeciesManager.helperAddSpecies(rSpeciesAdd);
end

function getAncestryOptions(nodeSpecies)
	local bSource2024 = (DB.getValue(nodeSpecies, "version", "") == "2024");
	if not bSource2024 and (DB.getValue(nodeSpecies, "ignoresubrace", 0) == 1) then
		return {};
	end

	local sSpeciesName = StringManager.trim(DB.getValue(nodeSpecies, "name", ""));
	if sSpeciesName == "" then
		return {};
	end

	local tAncestryFilters = {
		{ sField = "race", sValue = sSpeciesName, bIgnoreCase = true, },
		{ sField = "version", sValue = (bSource2024 and "2024" or ""), },
	};
	if bSource2024 then
		return RecordManager.getRecordOptionsByFilter("race_subrace", tAncestryFilters, true);
	end

	local tOptions = {};
	RecordManager.callForEachRecordByFilter("race_subrace", tAncestryFilters, CharSpeciesManager.helperGetSpeciesExternalAncestryOption, tOptions);
	if not bSource2024 then
		local tSpeciesFilters = {
			{ sField = "name", sValue = sSpeciesName, bIgnoreCase = true, },
			{ sField = "version", sValue = (bSource2024 and "2024" or ""), },
		};		
		RecordManager.callForEachRecordByFilter("race", tSpeciesFilters, CharSpeciesManager.helperGetSpeciesEmbeddedAncestryOption, tOptions);
	end
	table.sort(tOptions, function(a,b) return a.text < b.text; end);
	return tOptions;
end
function helperGetSpeciesExternalAncestryOption(node, tOptions)
	local sName = StringManager.trim(DB.getValue(node, "name", ""));
	if sName ~= "" then
		table.insert(tOptions, { text = sName, linkclass = "reference_subrace", linkrecord = DB.getPath(node), });
	end
end
function helperGetSpeciesEmbeddedAncestryOption(nodeSpecies, tOptions)
	for _,node in ipairs(DB.getChildList(nodeSpecies, "subraces")) do
		local sName = StringManager.trim(DB.getValue(node, "name", ""));
		if sName ~= "" then
			table.insert(tOptions, { text = sName, linkclass = "reference_subrace", linkrecord = DB.getPath(node), });
		end
	end
end

function getSpeciesFromAncestry(sAncestryName, bSource2024)
	local tOptions = {};

	local tAncestryFilters = {
		{ sField = "name", sValue = sAncestryName, bIgnoreCase = true, },
		{ sField = "version", sValue = (bSource2024 and "2024" or ""), },
	};
	local nodeExternalAncestry = RecordManager.findRecordByFilter("race_subrace", tAncestryFilters);
	if nodeExternalAncestry then
		local tSpeciesFilters = {
			{ sField = "name", sValue = DB.getValue(nodeExternalAncestry, "race", ""), bIgnoreCase = true, },
			{ sField = "version", sValue = (bSource2024 and "2024" or ""), },
		};
		RecordManager.callForEachRecordByFilter("race", tSpeciesFilters, CharSpeciesManager.helperGetSpeciesFromAncestryDirect, tOptions);
	elseif not bSource2024 then
		RecordManager.callForEachRecord("race", CharSpeciesManager.helperGetSpeciesFromAncestryEmbedded, tOptions, sAncestryName, bSource2024);
	end

	if #tOptions > 0 then
		local sSpeciesName = StringManager.trim(DB.getValue(tOptions[1], "name", ""));
		return sSpeciesName, tOptions[1];
	end

	return "", nil;
end
function helperGetSpeciesFromAncestryDirect(node, tOptions)
	if (DB.getValue(node, "version", "") ~= "2024") and (DB.getValue(node, "ignoresubrace", 0) == 1) then
		return;
	end
	table.insert(tOptions, node);
end
function helperGetSpeciesFromAncestryEmbedded(node, tOptions, sAncestryName, bSource2024)
	local bRecord2024 = (DB.getValue(node, "version", "") == "2024");
	if bRecord2024 ~= bSource2024 then
		return;
	end
	if not bRecord2024 and (DB.getValue(node, "ignoresubrace", 0) == 1) then
		return;
	end

	local sAncestryNameLower = StringManager.simplify(sAncestryName);
	for _,nodeAncestry in ipairs(DB.getChildList(node, "subraces")) do
		if StringManager.simplify(DB.getValue(nodeAncestry, "name", "")) == sAncestryNameLower then
			table.insert(tOptions, node);
		end
	end
end

function helperAddSpecies(rAdd)
	CharSpeciesManager.helperAddSpeciesMain(rAdd);
	CharSpeciesManager.helperAddAncestry(rAdd);
end
function helperAddSpeciesMain(rAdd)
	if not rAdd then
		return;
	end

	-- Notification
	ChatManager.SystemMessageResource("char_abilities_message_speciesadd", rAdd.sSourceName, rAdd.sCharName);

	-- Set name and link
	DB.setValue(rAdd.nodeChar, "race", "string", rAdd.sSourceName);
	DB.setValue(rAdd.nodeChar, "racelink", "windowreference", "reference_race", DB.getPath(rAdd.nodeSource));
	DB.setValue(rAdd.nodeChar, "subracelink", "windowreference", "", "");

	CharSpeciesManager.helperAddSpeciesMainStats(rAdd);

	-- Add species traits
	for _,v in ipairs(DB.getChildList(rAdd.nodeSource, "traits")) do
		CharSpeciesManager.addSpeciesTrait(rAdd.nodeChar, DB.getPath(v), { bWizard = rAdd.bWizard });
	end
end
function helperAddSpeciesMainStats(rAdd)
	if not rAdd or rAdd.bWizard then
		return;
	end

	if rAdd.bSource2024 then
		CharBuildDropManager.handleSizeField(rAdd);
		CharBuildDropManager.handleSpeedField(rAdd);
	end
end
function helperAddAncestry(rAdd)
	if not rAdd or ((rAdd.sAncestryPath or "") == "") then
		return;
	end
	local nodeAncestry = DB.findNode(rAdd.sAncestryPath);
	if not nodeAncestry then
		ChatManager.SystemMessageResource("char_error_missingancestry");
		return;
	end

	local sAncestryName = DB.getValue(nodeAncestry, "name", "");

	-- Notification
	ChatManager.SystemMessageResource("char_abilities_message_ancestryadd", sAncestryName, rAdd.sCharName);

	-- Update species name and ancestry link
	if sAncestryName:match(rAdd.sSourceName) then
		DB.setValue(rAdd.nodeChar, "race", "string", sAncestryName);
	else
		DB.setValue(rAdd.nodeChar, "race", "string", string.format("%s (%s)", rAdd.sSourceName, sAncestryName));
	end
	DB.setValue(rAdd.nodeChar, "subracelink", "windowreference", "reference_subrace", rAdd.sAncestryPath);

	-- Add species traits
	for _,v in ipairs(DB.getChildList(nodeAncestry, "traits")) do
		CharSpeciesManager.addSpeciesTrait(rAdd.nodeChar, DB.getPath(v), { bWizard = rAdd.bWizard });
	end
end

function getTraitSpeciesName(rAdd)
	local s = DB.getValue(rAdd.nodeSource, "...race", "");
	if s ~= "" then
		return s;
	end
	return DB.getValue(rAdd.nodeSource, "...name", "");
end
function getTraitSpellGroup(rAdd)
	return Interface.getString("char_spell_powergroup"):format(CharSpeciesManager.getTraitSpeciesName(rAdd));
end
function getTraitPowerGroup(rAdd)
	return Interface.getString("char_species_powergroup"):format(CharSpeciesManager.getTraitSpeciesName(rAdd));
end

function helperAddSpeciesTraitMain(rAdd)
	if not rAdd then
		return;
	end
	if rAdd.bWizard then
		if rAdd.bSource2024 then
			CharSpeciesManager.helperAddSpeciesTraitMainWizard2024(rAdd);
		else
			CharSpeciesManager.helperAddSpeciesTraitMainWizard2014(rAdd);
		end
	else
		if rAdd.bSource2024 then
			CharSpeciesManager.helperAddSpeciesTraitMainDrop2024(rAdd);
		else
			CharSpeciesManager.helperAddSpeciesTraitMainDrop2014(rAdd);
		end
	end
end
function helperAddSpeciesTraitMainWizard2024(rAdd)
	-- Skip certain entries
	if CharWizardData.tBuildOptionsNoParse2024[rAdd.sSourceType] then
		return;
	end
	if CharWizardData.tBuildOptionsNoAdd2024[rAdd.sSourceType] then
		return;
	end
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

	CharSpeciesManager.helperAddSpeciesTraitStandard(rAdd);

	CharBuildDropManager.checkSpeciesTraitActions(rAdd);
end
function helperAddSpeciesTraitMainWizard2014(rAdd)
	-- Skip certain entries
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

	CharSpeciesManager.helperAddSpeciesTraitStandard(rAdd);

	CharBuildDropManager.checkSpeciesTraitActions(rAdd);
end
function helperAddSpeciesTraitMainDrop2024(rAdd)
	if rAdd.sSourceType == "darkvision" or rAdd.sSourceType == "enhanceddarkvision" then
		CharSpeciesManager.helperAddSpeciesTraitDarkvisionDrop(rAdd);
		return;
		
	elseif rAdd.sSourceType == "enhancedspeed" then
		CharSpeciesManager.helperAddSpeciesTraitEnhancedSpeedDrop(rAdd);
		return;

	elseif rAdd.sSourceType == "versatile" then
		CharSpeciesManager.helperAddSpeciesTraitVersatileDrop2024(rAdd);
		return;

	else
		CharSpeciesManager.helperAddSpeciesTraitStandard(rAdd);

		if CharWizardData.tBuildOptionsNoParse2024[rAdd.sSourceType] then
			return;
		end

		CharBuildDropManager.checkFeatureDescription(rAdd);
		CharBuildDropManager.checkSpeciesTraitActions(rAdd);

		if rAdd.sSourceType == "dwarventoughness" then
			CharSpeciesManager.applyDwarvenToughness(rAdd.nodeChar, true);
		end
	end
end
function helperAddSpeciesTraitMainDrop2014(rAdd)
	if rAdd.sSourceType == "abilityscoreincrease" then
		CharSpeciesManager.helperAddSpeciesTraitAbilityIncreaseDrop2014(rAdd);
		return;

	elseif rAdd.sSourceType == "age" then
		return;

	elseif rAdd.sSourceType == "alignment" then
		return;

	elseif rAdd.sSourceType == "size" then
		CharSpeciesManager.helperAddSpeciesTraitSizeDrop2014(rAdd);
		return;

	elseif rAdd.sSourceType == "speed" then
		CharSpeciesManager.helperAddSpeciesTraitSpeedDrop2014(rAdd);
		return;

	elseif rAdd.sSourceType == "fleetoffoot" then
		CharSpeciesManager.helperAddSpeciesTraitEnhancedSpeedDrop(rAdd);
		return;

	elseif rAdd.sSourceType == "darkvision" or rAdd.sSourceType == "superiordarkvision" then
		CharSpeciesManager.helperAddSpeciesTraitDarkvisionDrop(rAdd);
		return;
		
	elseif rAdd.sSourceType == "languages" then
		CharSpeciesManager.helperAddSpeciesTraitLanguagesDrop2014(rAdd);
		return;
		
	elseif rAdd.sSourceType == "extralanguage" then
		CharBuildDropManager.pickLanguage(rAdd.nodeChar, nil, 1, { bWizard = rAdd.bWizard, bSource2024 = rAdd.bSource2024, });
		return;
	
	elseif rAdd.sSourceType == "subrace" then
		return;
		
	else
		CharSpeciesManager.helperAddSpeciesTraitStandard(rAdd);

		if CharWizardData.aRaceTraitNoParse[rAdd.sSourceType] then
			return;
		end

		CharBuildDropManager.checkFeatureDescription(rAdd);
		CharBuildDropManager.checkSpeciesTraitActions(rAdd);

		if rAdd.sSourceType == "dwarventoughness" then
			CharSpeciesManager.applyDwarvenToughness(rAdd.nodeChar, true);
		elseif rAdd.sSourceType == "catsclaws" then
			if CharBuildDropManager.helperBuildGetText(rAdd) then
				CharSpeciesManager.applyLegacyCatsClawsClimb(rAdd.nodeChar, DB.getText(rAdd.nodeSource, "text", ""));
			end
		elseif CharArmorManager.isNaturalArmorTrait(rAdd.sSourceName) then
			CharArmorManager.calcItemArmorClass(rAdd.nodeChar);
		end
	end
end

function helperAddSpeciesTraitStandard(rAdd)
	local nodeTraitList = DB.createChild(rAdd.nodeChar, "traitlist");
	if not nodeTraitList then
		return nil;
	end

	local nodeNewTrait = DB.createChildAndCopy(nodeTraitList, rAdd.nodeSource);
	if not nodeNewTrait then
		return nil;
	end
	DB.setValue(nodeNewTrait, "locked", "number", 1);

	ChatManager.SystemMessageResource("char_abilities_message_traitadd", rAdd.sSourceName, rAdd.sCharName);
	return nodeNewTrait;
end

function helperAddSpeciesTraitDarkvisionDrop(rAdd)
	if not CharBuildDropManager.helperBuildGetText(rAdd) then
		return;
	end
	CharManager.addSense(rAdd.nodeChar, "Darkvision", rAdd.sSourceText:match("%d+"));
end
function helperAddSpeciesTraitEnhancedSpeedDrop(rAdd)
	if not CharBuildDropManager.helperBuildGetText(rAdd) then
		return;
	end
	local sSpeed = rAdd.sSourceText:match("increases to (%d+) feet");
	CharManager.setSpeed(rAdd.nodeChar, sSpeed)
end
function helperAddSpeciesTraitVersatileDrop2024(rAdd)
	CharSpeciesManager.helperAddSpeciesTraitStandard(rAdd);

	local tOptions = RecordManager.getRecordOptionsByStringI("feat", "category", "Origin", true);
	CharBuildDropManager.pickFeat(rAdd.nodeChar, tOptions, 1, { bWizard = rAdd.bWizard, bSource2024 = rAdd.bSource2024, });
end

function helperAddSpeciesTraitAbilityIncreaseDrop2014(rAdd)
	if not CharBuildDropManager.helperBuildGetText(rAdd) then
		return;
	end

	local sAdjust = rAdd.sSourceText:lower();
	
	if sAdjust:match("your ability scores each increase") then
		for _,v in pairs(DataCommon.abilities) do
			CharManager.addAbilityAdjustment(rAdd.nodeChar, v, 1);
		end
		return;
	end

	local aIncreases = {};
	
	local n1, n2;
	local a1, a2, sIncrease = sAdjust:match("your (%w+) and (%w+) scores increase by (%d+)");
	if not a1 then
		a1, a2, sIncrease = sAdjust:match("your (%w+) and (%w+) scores both increase by (%d+)");
	end
	if a1 then
		local nIncrease = tonumber(sIncrease) or 0;
		aIncreases[a1] = nIncrease;
		aIncreases[a2] = nIncrease;
	else
		for a1, sIncrease in sAdjust:gmatch("your (%w+) score increases by (%d+)") do
			local nIncrease = tonumber(sIncrease) or 0;
			aIncreases[a1] = nIncrease;
		end
		for a1, sDecrease in sAdjust:gmatch("your (%w+) score is reduced by (%d+)") do
			local nDecrease = tonumber(sDecrease) or 0;
			aIncreases[a1] = nDecrease * -1;
		end
	end
	
	for k,v in pairs(aIncreases) do
		CharManager.addAbilityAdjustment(rAdd.nodeChar, k, v);
	end
	
	local tAbilitySelect = {};
	sIncrease = sAdjust:match("two different ability scores of your choice increase by (%d+)")
	if sIncrease then
		local nAbilityAdj = tonumber(sIncrease) or 1;
		table.insert(tAbilitySelect, { nPicks = 2, nAbilityAdj = nAbilityAdj });
	end
	sIncrease = sAdjust:match("one ability score of your choice increases by (%d+)");
	if sIncrease then
		local nAbilityAdj = tonumber(sIncrease) or 1;
		table.insert(tAbilitySelect, { nAbilityAdj = nAbilityAdj });
	end
	sIncrease = sAdjust:match("one other ability score of your choice increases by (%d+)");
	if sIncrease then
		local aAbilities = {};
		for _,v in ipairs(DataCommon.abilities) do
			if not aIncreases[v] then
				table.insert(aAbilities, StringManager.capitalize(v));
			end
		end
		if #aAbilities > 0 then
			local nAbilityAdj = tonumber(sIncrease) or 1;
			table.insert(tAbilitySelect, { aAbilities = aAbilities, nAbilityAdj = nAbilityAdj, bOther = true });
		end
	end
	sIncrease = sAdjust:match("two other ability scores of your choice increase by (%d+)");
	if sIncrease then
		local aAbilities = {};
		for _,v in ipairs(DataCommon.abilities) do
			if not aIncreases[v] then
				table.insert(aAbilities, StringManager.capitalize(v));
			end
		end
		if #aAbilities > 0 then
			local nAbilityAdj = tonumber(sIncrease) or 1;
			table.insert(tAbilitySelect, { aAbilities = aAbilities, nPicks = 2, nAbilityAdj = nAbilityAdj, bOther = true });
		end
	end
	a1, a2, sIncrease = sAdjust:match("either your (%w+) or your (%w+) increases by (%d+)");
	if a1 then
		local aAbilities = {};
		for _,v in ipairs(DataCommon.abilities) do
			if (v == a1) or (v == a2) then
				table.insert(aAbilities, StringManager.capitalize(v));
			end
		end
		if #aAbilities > 0 then
			local nAbilityAdj = tonumber(sIncrease) or 1;
			table.insert(tAbilitySelect, { aAbilities = aAbilities, nAbilityAdj = nAbilityAdj });
		end
	end
	if #tAbilitySelect > 0 then
		CharBuildDropManager.pickAbilities2014(rAdd.nodeChar, tAbilitySelect);
	end
end
function helperAddSpeciesTraitSizeDrop2014(rAdd)
	if not CharBuildDropManager.helperBuildGetText(rAdd) then
		return;
	end

	local sSize = rAdd.sSourceText:match("[Yy]our size is (%w+)");
	CharManager.setSize(nodeChar, sSize);
end
function helperAddSpeciesTraitSpeedDrop2014(rAdd)
	if not CharBuildDropManager.helperBuildGetText(rAdd) then
		return;
	end

	local nSpeed, tSpecial = CharSpeciesManager.helperParseSpeciesSpeed2014(rAdd.sSourceText);

	CharManager.setSpeed(nSpeed);
	for k,v in pairs(tSpecial) do
		CharManager.addSpecialMove(rAdd.nodeChar, k, v);
	end
end
function helperParseSpeciesSpeed2014(s)
	if (s or "") == "" then
		return 30, {};
	end

	local sSpeed = s:lower();
	local nSpeed = 30;
	local tSpecial = {};

	local sWalkSpeed = sSpeed:match("walking speed is (%d+) feet");
	if not sWalkSpeed then
		sWalkSpeed = sSpeed:match("land speed is (%d+) feet");
	end
	if sWalkSpeed then
		nSpeed = tonumber(sWalkSpeed) or 30;
	end
	
	local sSwimSpeed = sSpeed:match("swimming speed of (%d+) feet");
	if sSwimSpeed then
		tSpecial["Swim"] = sSwimSpeed;
	elseif sWalkSpeed and sSpeed:match("you have a swimming speed equal to your walking speed") then
		tSpecial["Swim"] = nSpeed;
	end

	local sFlySpeed = sSpeed:match("flying speed of (%d+) feet");
	if sFlySpeed then
		tSpecial["Fly"] = sFlySpeed;
	elseif sSpeed:match("you have a flying speed equal to your walking speed") then
		tSpecial["Fly"] = nSpeed;
	end

	local sClimbSpeed = sSpeed:match("climbing speed of (%d+) feet");
	if sClimbSpeed then
		tSpecial["Climb"] = sClimbSpeed;
	elseif sSpeed:match("you have a climbing speed equal to your walking speed") then
		tSpecial["Climb"] = nSpeed;
	end
	
	local sBurrowSpeed = sSpeed:match("burrowing speed of (%d+) feet");
	if sBurrowSpeed then
		tSpecial["Burrow"] = sBurrowSpeed;
	elseif sSpeed:match("you have a burrowing speed equal to your walking speed") then
		tSpecial["Burrow"] = nSpeed;
	end

	return nSpeed, tSpecial;
end
function helperAddSpeciesTraitLanguagesDrop2014(rAdd)
	if not CharBuildDropManager.helperBuildGetText(rAdd) then
		return;
	end

	local sLanguages = rAdd.sSourceText:match("You can speak, read, and write ([^.]+)");
	if not sLanguages then
		sLanguages = rAdd.sSourceText:match("You can read and write ([^.]+)");
	end
	if not sLanguages then
		return;
	end

	sLanguages = sLanguages:gsub("and ", ",");
	sLanguages = sLanguages:gsub("one extra language of your choice", "Choice");
	sLanguages = sLanguages:gsub("one other language of your choice", "Choice");
	-- EXCEPTION - Kenku - Languages - Volo
	sLanguages = sLanguages:gsub(", but you.*$", "");
	
	for s in sLanguages:gmatch("([^,]+)") do 
		CharManager.addLanguage(rAdd.nodeChar, s);
	end
end

function applyDwarvenToughness(nodeChar, bInitialAdd)
	-- Add extra hit points
	local nAddHP = 1;
	if bInitialAdd then
		nAddHP = CharManager.getLevel(nodeChar);
	end
	
	local nHP = DB.getValue(nodeChar, "hp.total", 0);
	nHP = nHP + nAddHP;
	DB.setValue(nodeChar, "hp.total", "number", nHP);
	
	ChatManager.SystemMessageResource("char_abilities_message_hpaddtrait", StringManager.capitalizeAll(CharManager.TRAIT_DWARVEN_TOUGHNESS), DB.getValue(nodeChar, "name", ""), nAddHP);
end
function applyLegacyCatsClawsClimb(nodeChar, sText)
	local sClimbSpeed = sText:match("you have a climbing speed of (%d+) feet");
	if not sClimbSpeed then
		return;
	end
	CharManager.addSpecialMove(rAdd.nodeChar, "Climb", sClimbSpeed);
end
