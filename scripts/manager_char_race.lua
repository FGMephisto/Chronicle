-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function getRaceSubraceOptions(nodeRace)
	if DB.getValue(nodeRace, "ignoresubrace", 0) == 1 then
		return {};
	end

	local sRaceName = StringManager.trim(DB.getValue(nodeRace, "name", ""));
	local tOptions = {};
	RecordManager.callForEachRecordByStringI("race_subrace", "race", sRaceName, CharRaceManager.helperGetRaceExternalSubraceOption, tOptions);
	RecordManager.callForEachRecordByStringI("race", "name", sRaceName, CharRaceManager.helperGetRaceEmbeddedSubraceOption, tOptions);
	table.sort(tOptions, function(a,b) return a.text < b.text; end);
	return tOptions;
end
function helperGetRaceExternalSubraceOption(nodeSubrace, tOptions)
	local sSubraceName = StringManager.trim(DB.getValue(nodeSubrace, "name", ""));
	if sSubraceName ~= "" then
		table.insert(tOptions, { text = sSubraceName, linkclass = "reference_subrace", linkrecord = DB.getPath(nodeSubrace) });
	end
end
function helperGetRaceEmbeddedSubraceOption(nodeRace, tOptions)
	for _,nodeSubRace in ipairs(DB.getChildList(nodeRace, "subraces")) do
		local sSubraceName = StringManager.trim(DB.getValue(nodeSubRace, "name", ""));
		if sSubraceName ~= "" then
			table.insert(tOptions, { text = sSubraceName, linkclass = "reference_subrace", linkrecord = DB.getPath(nodeSubRace) });
		end
	end
end

function getRaceFromSubrace(sSubraceName)
	local tOptions = {};

	local nodeExternalSubrace = RecordManager.findRecordByStringI("race_subrace", "name", sSubraceName);
	if nodeExternalSubrace then
		local sRaceName = StringManager.trim(DB.getValue(nodeExternalSubrace, "race", ""));
		RecordManager.callForEachRecordByStringI("race", "name", sRaceName, CharRaceManager.helperGetRaceFromSubraceDirect, tOptions);
	else
		local sSubraceNameLower = StringManager.trim(sSubraceName):lower();
		RecordManager.callForEachRecord("race", CharRaceManager.helperGetRaceFromSubraceEmbedded, sSubraceNameLower, tOptions);
	end

	if #tOptions > 0 then
		local sRaceName = StringManager.trim(DB.getValue(tOptions[1], "name", ""));
		return sRaceName, tOptions[1];
	end

	return "", nil;
end
function helperGetRaceFromSubraceDirect(nodeRace, tOptions)
	if DB.getValue(nodeRace, "ignoresubrace", 0) ~= 1 then
		table.insert(tOptions, nodeRace);
	end
end
function helperGetRaceFromSubraceEmbedded(nodeRace, sSubraceNameLower, tOptions)
	if DB.getValue(nodeRace, "ignoresubrace", 0) == 1 then
		return;
	end

	for _,nodeSubRace in ipairs(DB.getChildList(nodeRace, "subraces")) do
		local sMatch = StringManager.trim(DB.getValue(nodeSubRace, "name", "")):lower();
		if sMatch == sSubraceNameLower then
			table.insert(tOptions, nodeRace);
		end
	end
end

function addRaceDrop(nodeChar, sClass, sRecord)
	if sClass == "reference_race" then
		local rAdd = CharManager.helperBuildAddStructure(nodeChar, sClass, sRecord);
		if not rAdd then
			return;
		end

		CharRaceManager.helperAddRaceMain(rAdd);
		CharRaceManager.helperAddRaceSubraceChoice(rAdd);

	elseif sClass == "reference_subrace" then
		local nodeSource = DB.findNode(sRecord);
		if not nodeSource then
			return;
		end

		local sSubraceName = StringManager.trim(DB.getValue(nodeSource, "name", ""));
		local sRaceName, nodeRace = CharRaceManager.getRaceFromSubrace(sSubraceName);
		if not nodeRace or ((sRaceName or "") == "") then
			ChatManager.SystemMessageResource("char_error_missingracefromsubrace");
			return;
		end


		local rAdd = {
			nodeSource = nodeRace,
			sSourceClass = "reference_race",
			sSourceName = sRaceName,
			nodeChar = nodeChar,
			sCharName = StringManager.trim(DB.getValue(nodeChar, "name", "")),
			sSubracePath = DB.getPath(nodeSource),
		};
		CharRaceManager.helperAddRaceMain(rAdd);
		CharRaceManager.helperAddRaceSubrace(rAdd);
	end
end
function helperAddRaceMain(rAdd)
	-- Notification
	ChatManager.SystemMessageResource("char_abilities_message_raceadd", rAdd.sSourceName, rAdd.sCharName);

	-- Set name and link
	DB.setValue(rAdd.nodeChar, "race", "string", rAdd.sSourceName);
	DB.setValue(rAdd.nodeChar, "racelink", "windowreference", "reference_race", DB.getPath(rAdd.nodeSource));
	DB.setValue(rAdd.nodeChar, "subracelink", "windowreference", "", "");

	-- Add racial traits
	for _,v in ipairs(DB.getChildList(rAdd.nodeSource, "traits")) do
		CharRaceManager.addRaceTrait(rAdd.nodeChar, "reference_racialtrait", DB.getPath(v), rAdd.bWizard);
	end
end
function helperAddRaceSubraceChoice(rAdd)
	local tRaceSubraceOptions = CharRaceManager.getRaceSubraceOptions(rAdd.nodeSource);
	if #tRaceSubraceOptions == 0 then
		return;
	end

	if #tRaceSubraceOptions == 1 then
		-- Automatically select only subrace
		rAdd.sSubracePath = tRaceSubraceOptions[1].linkrecord;
		CharRaceManager.helperAddRaceSubrace(rAdd);
	else
		-- Display dialog to choose subrace
		local wSelect = Interface.openWindow("select_dialog", "");
		local sTitle = Interface.getString("char_build_title_selectsubrace");
		local sMessage = Interface.getString("char_build_message_selectsubrace");
		wSelect.requestSelection(sTitle, sMessage, tRaceSubraceOptions, CharRaceManager.callbackAddRaceSubraceChoice, rAdd);
	end
end
function callbackAddRaceSubraceChoice(tSelection, rAdd, tSelectionLinks)
	if not tSelectionLinks or (#tSelectionLinks ~= 1) then
		ChatManager.SystemMessageResource("char_error_addsubrace");
		return;
	end

	rAdd.sSubracePath = tSelectionLinks[1].linkrecord;
	CharRaceManager.helperAddRaceSubrace(rAdd);
end
function helperAddRaceSubrace(rAdd)
	if ((rAdd.sSubracePath or "") == "") then
		ChatManager.SystemMessageResource("char_error_missingsubrace");
		return;
	end

	local sSubraceName = DB.getValue(DB.getPath(rAdd.sSubracePath, "name"), "");

	-- Notification
	ChatManager.SystemMessageResource("char_abilities_message_subraceadd", sSubraceName, rAdd.sCharName);

	-- Update race name and subrace link
	if sSubraceName:match(rAdd.sSourceName) then
		DB.setValue(rAdd.nodeChar, "race", "string", sSubraceName);
	else
		DB.setValue(rAdd.nodeChar, "race", "string", string.format("%s (%s)", rAdd.sSourceName, sSubraceName));
	end
	DB.setValue(rAdd.nodeChar, "subracelink", "windowreference", "reference_subrace", rAdd.sSubracePath);

	-- Add racial traits
	for _,v in ipairs(DB.getChildList(DB.getPath(rAdd.sSubracePath, "traits"))) do
		CharRaceManager.addRaceTrait(rAdd.nodeChar, "reference_subracialtrait", DB.getPath(v), rAdd.bWizard);
	end
end

function addRaceTrait(nodeChar, sClass, sRecord, bWizard)
	local rAdd = CharManager.helperBuildAddStructure(nodeChar, sClass, sRecord, bWizard);
	if not rAdd then
		return;
	end

	CharRaceManager.helperAddRaceTraitMain(rAdd);
end
function helperAddRaceTraitMain(rAdd)
	if rAdd.bWizard then
		CharRaceManager.helperAddRaceTraitMainWizard(rAdd);
	else
		CharRaceManager.helperAddRaceTraitMainDrop(rAdd);
	end
end
function helperAddRaceTraitMainWizard(rAdd)
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

	-- Create standard trait entry
	CharRaceManager.helperAddRaceTraitStandard(rAdd);

	-- Add trait actions
	CharManager.helperCheckActionsAdd(rAdd.nodeChar, rAdd.nodeSource, rAdd.sSourceType, "Race Actions/Effects");

	-- Add trait spells
	CharRaceManager.helperAddRaceTraitSpell(rAdd);
end
function helperAddRaceTraitMainDrop(rAdd)
	if rAdd.sSourceType == "abilityscoreincrease" then
		CharRaceManager.helperAddRaceTraitAbilityIncreaseDrop(rAdd);
		return;

	elseif rAdd.sSourceType == "age" then
		return;

	elseif rAdd.sSourceType == "alignment" then
		return;

	elseif rAdd.sSourceType == "size" then
		CharRaceManager.helperAddRaceTraitSizeDrop(rAdd);
		return;

	elseif rAdd.sSourceType == "speed" then
		CharRaceManager.helperAddRaceTraitSpeedDrop(rAdd);
		return;

	elseif rAdd.sSourceType == "fleetoffoot" then
		CharRaceManager.helperAddRaceTraitFleetOfFootDrop(rAdd);
		return;

	elseif rAdd.sSourceType == "darkvision" then
		CharRaceManager.helperAddRaceTraitDarkvisionDrop(rAdd);
		return;
		
	elseif rAdd.sSourceType == "superiordarkvision" then
		CharRaceManager.helperAddRaceTraitSuperiorDarkvisionDrop(rAdd);
		return;

	elseif rAdd.sSourceType == "languages" then
		CharRaceManager.helperAddRaceTraitLanguagesDrop(rAdd);
		return;
		
	elseif rAdd.sSourceType == "extralanguage" then
		CharManager.addLanguage(rAdd.nodeChar, "Choice");
		return;
	
	elseif rAdd.sSourceType == "subrace" then
		return;
		
	else
		local sText = DB.getText(rAdd.nodeSource, "text", "");
		
		if rAdd.sSourceType == "stonecunning" then
			-- Note: Bypass due to false positive in skill proficiency detection
		else
			CharManager.checkSkillProficiencies(rAdd.nodeChar, sText);
		end
		
		-- Create standard trait entry
		local nodeNewTrait = CharRaceManager.helperAddRaceTraitStandard(rAdd);
		if not nodeNewTrait then
			return;
		end
		
		-- Special handling
		local sNameLower = rAdd.sSourceName:lower();
		if sNameLower == CharManager.TRAIT_DWARVEN_TOUGHNESS then
			CharRaceManager.applyDwarvenToughness(rAdd.nodeChar, true);
		elseif sNameLower == CharManager.TRAIT_CATS_CLAWS then
			CharRaceManager.applyLegacyCatsClawsClimb(rAdd.nodeChar, sText);
		elseif CharArmorManager.isNaturalArmorTrait(rAdd.sSourceName) then
			CharArmorManager.calcItemArmorClass(rAdd.nodeChar);
		end

		-- Standard action addition handling
		CharManager.helperCheckActionsAdd(rAdd.nodeChar, rAdd.nodeSource, rAdd.sSourceType, "Race Actions/Effects");
	end
end

function helperAddRaceTraitStandard(rAdd)
	local nodeTraitList = DB.createChild(rAdd.nodeChar, "traitlist");
	if not nodeTraitList then
		return nil;
	end

	local nodeNewTrait = DB.createChildAndCopy(nodeTraitList, rAdd.nodeSource);
	if not nodeNewTrait then
		return nil;
	end

	DB.setValue(nodeNewTrait, "locked", "number", 1);
	if rAdd.sSourceClass == "reference_racialtrait" then
		DB.setValue(nodeNewTrait, "type", "string", "racial");
	elseif rAdd.sSourceClass == "reference_subracialtrait" then
		DB.setValue(nodeNewTrait, "type", "string", "subracial");
	end

	ChatManager.SystemMessageResource("char_abilities_message_traitadd", rAdd.sSourceName, rAdd.sCharName);

	return nodeNewTrait;
end
function helperAddRaceTraitSpell(rAdd)
	if not CharWizardData.aRaceSpells[rAdd.sSourceType] then
		return;
	end

	local tRaceSpells = CharManager.helperParseAbilitySpells(rAdd.nodeSource);
	if #tRaceSpells == 0 then
		return;
	end

	local sRaceName = DB.getValue(rAdd.nodeChar, "race", "");
	for _,v in ipairs(tRaceSpells) do
		local nodeSpell = RecordManager.findRecordByStringI("spell", "name", v);
		if nodeSpell then
			PowerManager.addPower("reference_spell", nodeSpell, rAdd.nodeChar, sRaceName .. " Innate Spells");
		end
	end
end
function helperAddRaceTraitAbilityIncreaseDrop(rAdd)
	local bApplied = false;
	local sAdjust = DB.getText(rAdd.nodeSource, "text", ""):lower();
	
	if sAdjust:match("your ability scores each increase") then
		for _,v in pairs(DataCommon.abilities) do
			CharManager.addAbilityAdjustment(rAdd.nodeChar, v, 1);
			bApplied = true;
		end
	else
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
			bApplied = true;
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
			CharManager.onAbilitySelectDialog(rAdd.nodeChar, tAbilitySelect);
			bApplied = true;
		end
	end
end
function helperAddRaceTraitSizeDrop(rAdd)
	local sSize = DB.getText(rAdd.nodeSource, "text", "");
	sSize = sSize:match("[Yy]our size is (%w+)");
	if not sSize then
		sSize = "Medium";
	end
	DB.setValue(rAdd.nodeChar, "size", "string", sSize);
end
function helperAddRaceTraitSpeedDrop(rAdd)
	local s = DB.getText(rAdd.nodeSource, "text", "");

	local nSpeed, tSpecial = CharRaceManager.parseRaceSpeed(s);
	
	DB.setValue(rAdd.nodeChar, "speed.base", "number", nSpeed);
	ChatManager.SystemMessageResource("char_abilities_message_basespeedset", nSpeed, DB.getValue(rAdd.nodeChar, "name", ""));

	local sExistingSpecial = StringManager.trim(DB.getValue(rAdd.nodeChar, "speed.special", ""));
	local tExistingSpecial = StringManager.split(sExistingSpecial, ",", true);

	local tFinalSpecial = {};
	local tMatchCheck = {};
	for _,sSpecial in ipairs(tSpecial) do
		if not tMatchCheck[sSpecial] then
			table.insert(tFinalSpecial, sSpecial);
		end
	end
	for _,sSpecial in ipairs(tExistingSpecial) do
		if not tMatchCheck[sSpecial] then
			table.insert(tFinalSpecial, sSpecial);
		end
	end
	DB.setValue(rAdd.nodeChar, "speed.special", "string", table.concat(tFinalSpecial, ", "));
end
function helperAddRaceTraitFleetOfFootDrop(rAdd)
	local sText = DB.getText(rAdd.nodeSource, "text", "");
	local sWalkSpeedIncrease = sText:match("walking speed increases to (%d+) feet");
	if sWalkSpeedIncrease then
		DB.setValue(rAdd.nodeChar, "speed.base", "number", tonumber(sWalkSpeedIncrease));
	end
end
function helperAddRaceTraitDarkvisionDrop(rAdd)
	local tSenses = {};
	local sSenses = DB.getValue(rAdd.nodeChar, "senses", "");
	if sSenses ~= "" then
		table.insert(tSenses, sSenses);
	end
	
	local sNewSense;
	local sText = DB.getText(rAdd.nodeSource, "text", "");
	if sText then
		local sDist = sText:match("%d+");
		if sDist then
			sNewSense = string.format("%s %s", rAdd.sSourceName, sDist);
		end
	end
	if not sNewSense then
		sNewSense = rAdd.sSourceName;
	end
	table.insert(tSenses, sNewSense);
	
	DB.setValue(rAdd.nodeChar, "senses", "string", table.concat(tSenses, ", "));
end
function helperAddRaceTraitSuperiorDarkvisionDrop(rAdd)
	local sDist = nil;
	local sText = DB.getText(rAdd.nodeSource, "text", "");
	if sText then
		sDist = sText:match("%d+");
	end
	if not sDist then
		return;
	end

	-- Check for regular Darkvision
	local sSenses = DB.getValue(rAdd.nodeChar, "senses", "");
	if sSenses:find("Darkvision (%d+)") then
		sSenses = sSenses:gsub("Darkvision (%d+)", rAdd.sSourceName .. " " .. sDist);
	else
		if sSenses ~= "" then
			sSenses = sSenses .. ", ";
		end
		sSenses = sSenses .. rAdd.sSourceName .. " " .. sDist;
	end
	
	DB.setValue(rAdd.nodeChar, "senses", "string", sSenses);
end
function helperAddRaceTraitLanguagesDrop(rAdd)
	local sText = DB.getText(rAdd.nodeSource, "text", "");
	local sLanguages = sText:match("You can speak, read, and write ([^.]+)");
	if not sLanguages then
		sLanguages = sText:match("You can read and write ([^.]+)");
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

function parseRaceSpeed(s)
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
		table.insert(tSpecial, "Swim " .. sSwimSpeed .. " ft.");
	elseif sWalkSpeed and sSpeed:match("you have a swimming speed equal to your walking speed") then
		table.insert(tSpecial, "Swim " .. nSpeed .. " ft.");
	end

	local sFlySpeed = sSpeed:match("flying speed of (%d+) feet");
	if sFlySpeed then
		table.insert(tSpecial, "Fly " .. sFlySpeed .. " ft.");
	elseif sSpeed:match("you have a flying speed equal to your walking speed") then
		table.insert(tSpecial, "Fly " .. nSpeed .. " ft.");
	end

	local sClimbSpeed = sSpeed:match("climbing speed of (%d+) feet");
	if sClimbSpeed then
		table.insert(tSpecial, "Climb " .. sClimbSpeed .. " ft.");
	elseif sSpeed:match("you have a climbing speed equal to your walking speed") then
		table.insert(tSpecial, "Climb " .. nSpeed .. " ft.");
	end
	
	local sBurrowSpeed = sSpeed:match("burrowing speed of (%d+) feet");
	if sBurrowSpeed then
		table.insert(tSpecial, "Burrow " .. sBurrowSpeed .. " ft.");
	elseif sSpeed:match("you have a burrowing speed equal to your walking speed") then
		table.insert(tSpecial, "Burrow " .. nSpeed .. " ft.");
	end

	return nSpeed, tSpecial;
end
function applyDwarvenToughness(nodeChar, bInitialAdd)
	-- Add extra hit points
	local nAddHP = 1;
	if bInitialAdd then
		nAddHP = CharClassManager.getCharLevel(nodeChar);
	end
	
	local nHP = DB.getValue(nodeChar, "hp.total", 0);
	nHP = nHP + nAddHP;
	DB.setValue(nodeChar, "hp.total", "number", nHP);
	
	ChatManager.SystemMessageResource("char_abilities_message_hpaddtrait", StringManager.capitalizeAll(CharManager.TRAIT_DWARVEN_TOUGHNESS), DB.getValue(nodeChar, "name", ""), nAddHP);
end
function applyLegacyCatsClawsClimb(nodeChar, sText)
	local sSpecialSpeed = sText:match("you have a climbing speed of (%d+) feet");
	if not sSpecialSpeed then
		return;
	end

	local tSpecial = {};
	local sSpecial = StringManager.trim(DB.getValue(nodeChar, "speed.special", ""));
	if tSpecial ~= "" then
		table.insert(tSpecial, sSpecial);
	end
	table.insert(tSpecial, "Climb " .. sSpecialSpeed .. " ft.");
	DB.setValue(nodeChar, "speed.special", "string", table.concat(tSpecial, ", "));
end
