-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

--
--	GENERAL
--

function convertSingleNumberTextToNumber(s, nDefault)
	if s then
		if s:match("^%d+$") then return tonumber(s) or 0; end
		if s == "one" then return 1; end
		if s == "two" then return 2; end
		if s == "three" then return 3; end
		if s == "four" then return 4; end
		if s == "five" then return 5; end
		if s == "six" then return 6; end
		if s == "seven" then return 7; end
		if s == "eight" then return 8; end
		if s == "nine" then return 9; end
	end
	return nDefault or 0;
end

function parseOptionsFromString(s)
	if not s then
		return {};
	end
	local tOptions = {};
	local tAndSplit = StringManager.splitByPattern(s, " and ", true);
	for _,s1 in ipairs(tAndSplit) do
		local tOrSplit = StringManager.splitByPattern(s1, " or ", true);
		for _,s2 in ipairs(tOrSplit) do
			local tCommaSplit = StringManager.splitByPattern(s2, ",", true);
			for _,s3 in ipairs(tCommaSplit) do
				if s3 ~= "" then
					table.insert(tOptions, s3);
				end
			end
		end
	end
	return tOptions;
end
function parseOptionsFromText(s)
	if not s then
		return {};
	end
	local nPeriod = s:match("%.()");
	if nPeriod then
		s = s:sub(1, nPeriod);
	end
	return CharBuildManager.parseOptionsFromString(s);
end
function parseAbilitiesFromString(s)
	local tParsed = CharBuildManager.parseOptionsFromString(s);
	local tAbilities = {};
	for _,sParse in ipairs(tParsed) do
		if StringManager.contains(DataCommon.abilities, sParse:lower()) then
			table.insert(tAbilities, sParse);
		end
	end
	return tAbilities;
end
function parseSizesFromString(s)
	if not s then
		return {};
	end
	local tStandardSizes = { "Medium", "Small", "Large", };
	local tSizes = {};
	for _,v in ipairs(tStandardSizes) do
		if s:match(v) then
			table.insert(tSizes, v);
		end
	end
	return tSizes;
end

--
--	OPTION TYPE DEFAULTS AND LOOKUPS
--

function getSkillNames()
	local tResults = {};
	for k,_ in pairs(DataCommon.skilldata) do
		table.insert(tResults, k);
	end
	table.sort(tResults);
	return tResults;
end
function getWeaponNames(bIs2024)
	local tFilters = {
		{ sField = "version", sValue = bIs2024 and "2024" or "", },
		{ sField = "type", sValue = "Weapon", bIgnoreCase = true, },
	};
	local tOptions = RecordManager.getRecordOptionsByFilter("item", tFilters, true);
	local tResults = {};
	for _,v in ipairs(tOptions) do
		table.insert(tResults, v.text)
	end
	return tResults;
end
function getToolNamesByType(vType, bIs2024)
	local tFilters;
	if type(vType) == "table" then
		tFilters = {
			{ sField = "version", sValue = bIs2024 and "2024" or "", },
			{ sField = "type", sValue = "Tools", bIgnoreCase = true, },
			{ sField = "subtype", tValues = vType, bIgnoreCase = true, },
		};
	elseif type(vType) == "nil" then
		tFilters = {
			{ sField = "version", sValue = bIs2024 and "2024" or "", },
			{ sField = "type", sValue = "Tools", bIgnoreCase = true, },
		};
	else
		tFilters = {
			{ sField = "version", sValue = bIs2024 and "2024" or "", },
			{ sField = "type", sValue = "Tools", bIgnoreCase = true, },
			{ sField = "subtype", sValue = vType, bIgnoreCase = true, },
		};
	end
	local tOptions = RecordManager.getRecordOptionsByFilter("item", tFilters, true);
	local tResults = {};
	for _,v in ipairs(tOptions) do
		table.insert(tResults, v.text)
	end
	return tResults;
end
function getLanguageNames()
	local tResults = {};
	for kLang,_ in pairs(LanguageManager.getCampaignLanguageMap()) do
		table.insert(tResults, kLang);
	end
	table.sort(tResults);
	return tResults;
end
function getFeatNames(bIs2024)
	local tFilters = {
		{ sField = "version", sValue = bIs2024 and "2024" or "", },
	};
	local tOptions = RecordManager.getRecordOptionsByFilter("feat", tFilters, true);
	local tResults = {};
	for _,v in ipairs(tOptions) do
		table.insert(tResults, v.text)
	end
	return tResults;
end
function getFeatNamesByCategory(sCategory)
	local tOptions = RecordManager.getRecordOptionsByStringI("feat", "category", sCategory, true);
	local tResults = {};
	for _,v in ipairs(tOptions) do
		table.insert(tResults, v.text)
	end
	return tResults;
end

function filterAbilities(tOptions)
	if not tOptions then
		return {};
	end
	local tFinal = {};
	for _,sOption in ipairs(tOptions) do
		local sOptionLower = StringManager.trim(sOption):lower();
		for _,s in ipairs(DataCommon.abilities) do
			if s == sOptionLower then
				table.insert(tFinal, StringManager.capitalize(s));
				break;
			end
		end
	end
	return tFinal;
end
function filterSkills(tOptions)
	if not tOptions then
		return {};
	end
	local tAll = CharWizardManager.getSkillNames();
	local tFinal = {};
	for _,sOption in ipairs(tOptions) do
		local sOptionLower = StringManager.trim(sOption):lower();
		for _,s in ipairs(tAll) do
			if s:lower() == sOptionLower then
				table.insert(tFinal, s);
				break;
			end
		end
	end
	return tFinal;
end

--
--	OPTION STRING PARSING
--

function processSkillDataOptions(tOptions)
	if not tOptions then
		return {};
	end
	if (#tOptions == 0) or StringManager.contains(tOptions, "any") then
		tOptions = CharBuildManager.getSkillNames();
	end
	return tOptions;
end
function getSkillsFromText2024(s)
	if not s then
		return {}, {}, 0;
	end
	-- PHB - Species - Elf - Keen Senses
	-- You have proficiency in the Insight, Perception, or Survival skill.
	local sSkill1, sSkill2, sSkill3 = s:match("[Pp]roficiency in the ([%w%s]+), ([%w%s]+),? or ([%w%s]+) skill");
	if sSkill1 and sSkill2 and sSkill3 then
		return {}, { sSkill1, sSkill2, sSkill3 }, 1;
	end

	-- PHB - Species - Human - Skillful
	-- You gain proficiency in one skill of your choice.
	local sPicks = s:match("[Pp]roficiency in (%w+) skills? of your choice");
	if sPicks then
		return {}, {}, CharBuildManager.convertSingleNumberTextToNumber(sPicks);
	end

	-- PHB - Class - Bard - College of Lore - Bonus Proficiencies
	local sPicks = s:match("[Pp]roficiency with (%w+) skills? of your choice");
	if sPicks then
		return {}, {}, CharBuildManager.convertSingleNumberTextToNumber(sPicks);
	end

	-- PHB - Class - Monk - Warrior of Mercy - Implements of Mercy
	-- You gain proficiency in the Insight and Medicine skills
	local sSkill1, sSkill2 = s:match("[Pp]roficiency in the ([%w%s]+) and ([%w%s]+) skills and proficiency with the Herbalism Kit");
	if sSkill1 and sSkill2 then
		return { sSkill1, sSkill2 }, {}, 0;
	end

	-- PHB - Class - Ranger - Fey Wanderer - Otherworldy Glamour
	-- You also gain proficiency in one of these skills of your choice: Deception, Performance, or Persuasion.
	local sPicks, sSkills = s:match("[Pp]roficiency in (%w+) of these skills of your choice: ([%w%s]+)");
	if sPicks and sSkills then
		return {}, CharBuildManager.parseOptionsFromString(sSkills), CharBuildManager.convertSingleNumberTextToNumber(sPicks);
	end

	return {}, {}, 0;
end
function getSkillsFromText2014(s)
	if not s then
		return {}, {}, 0;
	end

	-- Tabaxi - Cat's Talent - Volo
	local sSkill, sSkill2 = s:match("proficiency in the ([%w%s]+) and ([%w%s]+) skills");
	if sSkill and sSkill2 then
		return { sSkill1, sSkill2 }, {}, 0;
	end

	-- Elf - Keen Senses - PHB
	-- Half-Orc - Menacing - PHB
	-- Goliath - Natural Athlete - Volo
	local sSkill = s:match("proficiency in the ([%w%s]+) skill");
	if sSkill then
		return { sSkill }, {}, 0;
	end

	-- Bugbear - Sneaky - Volo
	-- (FALSE POSITIVE) Dwarf - Stonecunning
	sSkill = s:match("proficient in the ([%w%s]+) skill");
	if sSkill then
		return { sSkill }, {}, 0;
	end

	-- Orc - Menacing - Volo
	sSkill = s:match("trained in the ([%w%s]+) skill");
	if sSkill then
		return { sSkill }, {}, 0;
	end

	-- Half-Elf - Skill Versatility - PHB
	-- Human (Variant) - Skills - PHB
	local sPicks = s:match("proficiency in (%w+) skills? of your choice");
	if sPicks then
		return {}, {}, CharBuildManager.convertSingleNumberTextToNumber(sPicks);
	end

	sPicks = s:match("proficiency with (%w+) skills? of your choice")
	if sPicks then
		return {}, {}, CharBuildManager.convertSingleNumberTextToNumber(sPicks);
	end

	local sMatchEnd = s:match("choose one of the following skills()");
	if nMatchEnd then
		return {}, CharBuildManager.parseOptionsFromText(s:sub(nMatchEnd)), 1;
	end

	-- Cleric - Acolyte of Nature - PHB
	local nMatchEnd = s:match("proficiency in one of the following skills of your choice()")
	if nMatchEnd then
		return {}, CharBuildManager.parseOptionsFromText(s:sub(nMatchEnd)), 1;
	end

	-- Lizardfolk - Hunter's Lore - Volo
	sPicks, nMatchEnd = s:match("proficiency with (%w+) of the following skills of your choice()")
	if sPicks then
		return {}, CharBuildManager.parseOptionsFromText(s:sub(nMatchEnd)), CharBuildManager.convertSingleNumberTextToNumber(sPicks);
	end

	-- Lizardfolk - Hunter's Lore - Volo
	sPicks, nMatchEnd = s:match("proficiency with (%w+) of the following skills of your choice()")
	if sPicks then
		return {}, CharBuildManager.parseOptionsFromText(s:sub(nMatchEnd)), CharBuildManager.convertSingleNumberTextToNumber(sPicks);
	end

	-- Cleric - Blessings of Knowledge - PHB
	-- Kenku - Kenku Training - Volo
	sPicks, nMatchEnd = s:match("proficient in your choice of (%w+) of the following skills()")
	if sPicks then
		if s:match("proficiency bonus is doubled") then
			return {}, {}, 0;
		end
		return {}, CharBuildManager.parseOptionsFromText(s:sub(nMatchEnd)), CharBuildManager.convertSingleNumberTextToNumber(sPicks);
	end

	-- XGtE - Feat - Prodigy
	if s:match("one skill proficiency of your choice") then
		return {}, {}, 1;
	end

	-- XGtE - Feat - Squat Nimbleness
	local sSkillProf, sSkillProf2 = s:match("gain proficiency in the (%w+) or (%w+) skill");
	if sSkillProf and sSkillProf2 then
		return {}, { sSkillProf, sSkillProf2 }, 1;
	end

	-- PHB - Feat - Skilled
	local sSkillPicks = s:match("gain proficiency in any combination of (%w+) skills or tools");
	if sSkillPicks then
		return {}, {}, CharBuildManager.convertSingleNumberTextToNumber(sSkillPicks);
	end

	return {}, {}, 0;	
end

function processArmorProfDataOptions(tOptions)
	if not tOptions then
		return {};
	end
	return tOptions;
end
function getArmorProfFromText2024(s)
	if not s then
		return {}, {}, 0;
	end
	s = s:lower();
	if s:match("and training with medium armor and shields") then
		return { "Medium", "Shields" }, {}, 0;
	elseif s:match("and training with heavy armor") then
		return { "Heavy" }, {}, 0;
	elseif s:match("and training with medium armor") then
		return { "Medium" }, {}, 0;
	elseif s:match("gain training with light armor and shields") then
		return { "Light", "Shields" }, {}, 0;
	elseif s:match("gain training with medium armor") then
		return { "Medium" }, {}, 0;
	elseif s:match("gain training with heavy armor") then
		return { "Heavy" }, {}, 0;
	end
	return {}, {}, 0;
end
function getArmorProfFromText2014(s)
	if not s then
		return {}, {}, 0;
	end
	s = s:lower();
	if s:match("have proficiency with light and medium armor") then
		return { "Light", "Medium" }, {}, 0;
	elseif s:match("gain proficiency with medium armor and shields") then
		return { "Medium", "Shields" }, {}, 0;
	elseif s:match("gain proficiency with medium armor, shields, and martial weapons") then
		return { "Medium", "Shields" }, {}, 0;
	elseif s:match("gain proficiency with martial weapons and heavy armor") then
		return { "Heavy" }, {}, 0;
	elseif s:match("gain proficiency with light armor") then
		return { "Light" }, {}, 0;
	elseif s:match("gain proficiency with medium armor") then
		return { "Medium" }, {}, 0;
	elseif s:match("gain proficiency with heavy armor") then
		return { "Heavy" }, {}, 0;
	end
	return {}, {}, 0;
end

function processWeaponProfDataOptions(tOptions)
	if not tOptions then
		return {};
	end
	if (#tOptions == 0) or StringManager.contains(tOptions, "any") then
		return CharBuildManager.getWeaponNames(bIs2024);
	end
	return tOptions;
end
function getWeaponProfFromText2024(s)
	if not s then
		return {}, {}, 0;
	end
	s = s:lower();
	if s:match("have proficiency with improvised weapons") then
		return { "Improvised" }, {}, 0;
	elseif s:match("gain proficiency with martial weapons") then
		return { "Martial" }, {}, 0;
	end
	return {}, {}, 0;
end
function getWeaponProfFromText2014(s)
	if not s then
		return {}, {}, 0;
	end
	s = s:lower();
	if s:match("gain proficiency with four weapons of your choice") then
		return {}, {}, 4;
	elseif s:match("are proficient with improvised weapons") then
		return { "Improvised" }, {}, 0;
	elseif s:match("have proficiency with the battleaxe, handaxe, throwing hammer, and warhammer") then
		return { "Battleaxe", "Handaxe", "Throwing Hammer", "Warhammer" }, {}, 0;
	elseif s:match("have proficiency with the longsword, shortsword, shortbow, and longbow") then
		return { "Longsword", "Shortsword", "Shortbow", "Longbow" }, {}, 0;
	elseif s:match("have proficiency with rapiers, shortswords, and hand crossbows") then
		return { "Rapier", "Shortsword", "Hand Crossbow" }, {}, 0;
	elseif s:match("gain proficiency with medium armor, shields, and martial weapons") then
		return { "Martial" }, {}, 0;
	elseif s:match("gain proficiency with martial weapons") then
		return { "Martial" }, {}, 0;
	end

	-- PHB - Weapon Master
	local sPicks = s:match("gain proficiency with (%w+) weapons? of your choice");
	if sPicks then
		return {}, {}, CharBuildManager.convertSingleNumberTextToNumber(sPicks);
	end

	return {}, {}, 0;
end

function processToolProfDataOptions(tOptions)
	if not tOptions then
		return {};
	end
	local tFinalOptions = {};
	for _,v in ipairs(tOptions) do
		local sLower = v:lower();
		if sLower == "artisan's tools" then
			for _,sTool in ipairs(CharBuildManager.getToolNamesByType("Artisan's Tools", bIs2024)) do
				table.insert(tFinalOptions, sTool);
			end
		elseif sLower == "gaming set" then
			for _,sTool in ipairs(CharBuildManager.getToolNamesByType("Gaming Set", bIs2024)) do
				table.insert(tFinalOptions, sTool);
			end
		elseif sLower == "musical instrument" then
			for _,sTool in ipairs(CharBuildManager.getToolNamesByType("Musical Instrument", bIs2024)) do
				table.insert(tFinalOptions, sTool);
			end
		else
			table.insert(tFinalOptions, v);
		end
	end
	return tFinalOptions;
end
function getToolProfFromText2024(s)
	if not s then
		return {}, {}, 0;
	end
	s = s:lower();
	-- PHB - Class - Monk - Warrior of Mercy - Implements of Mercy
	if s:match("and proficiency with the herbalism kit") then
		return { "Herbalism Kit" }, {}, 0;
	-- PHB - Class - Rogue - Assassin - Assassin's Tools
	elseif s:match("You gain a disguise kit and a poisoner's kit, and you have proficiency with them") then
		return { "Disguise Kit", "Poisoner's Kit" }, {}, 0;
	elseif s:match("gain proficiency with three different artisan's tools of your choice from the fast crafting table") then
		local tOptions = {
			"Carpenter's Tools", "Jeweler's Tools", "Leatherworker's Tools", "Mason's Tools",
			"Potter's Tools", "Smith's Tools", "Tinker's Tools", "Weaver's Tools", "Woodcarver's Tools",
		};
		return {}, tOptions, 3;
	elseif s:match("gain proficiency with three musical instruments of your choice") then
		return {}, CharBuildManager.getToolNamesByType("Musical Instrument", true), 3;
	end
	return {}, {}, 0;
end
function getToolProfFromText2014(s)
	if not s then
		return {}, {}, 0;
	end
	s = s:lower();
	if s:match("gain proficiency with the artisan's tools of your choice: smith's tools, brewer's supplies, or mason's tools") then
		return {}, { "Smith's Tools", "Brewer's Supplies", "Mason's Tools" }, 1;
	elseif s:match("have proficiency with artisan's tools (tinker's tools)") then
		return { "Tinker's Tools" }, {}, 0;
	elseif s:match("gain proficiency with one type of artisan's tools of your choice") then
		return {}, CharBuildManager.getToolNamesByType("Artisan's Tools", false), 1;
	elseif s:match("gain proficiency with the disguise kit and the poisoner's kit") then
		return { "Disguise Kit", "Poisoner's Kit" }, {}, 0;
	-- XGtE - Prodigy
	elseif s:match("one tool proficiency of your choice") then
		return {}, CharBuildManager.getToolNamesByType(nil, false), 1;
	end
	return {}, {}, 0;
end

function processLanguageDataOptions(tOptions)
	if not tOptions then
		return {};
	end
	if (#tOptions == 0) or StringManager.contains(tOptions, "any") then
		return CharBuildManager.getLanguageNames();
	end
	return tOptions;
end
function getLanguagesFromText2024(s)
	if not s then
		return {}, {}, 0;
	end
	s = s:lower();
	-- PHB - Class - Druid - Druidic
	if s:match("you know druidic") then
		return { "Druidic" }, {}, 0;
	-- PHB - Class - Rogue - Thieves' Cant
	elseif s:match("you know thieves' cant and one other language of your choice") then
		return { "Thieves' Cant" }, {}, 1;
	end
	return {}, {}, 0;
end
function getLanguagesFromText2014(s)
	if not s then
		return {}, {}, 0;
	end

	-- Extra language choices
	-- PHB - Linguist
	local sPicks = s:match("learn (%w+) languages? of your choice");
	if sPicks then
		return {}, {}, CharBuildManager.convertSingleNumberTextToNumber(sPicks);
	end

	-- Known languages
	-- XGtE - Fey Teleportation
	local sLanguage = s:match("learn to speak, read, and write (%w+)");
	if sLanguage then
		return { sLanguage }, {}, 1;
	end

	-- Known languages
	-- XGtE - Prodigy
	if s:match("fluency in one language of your choice") then
		return {}, {}, 1;
	end

	local sLanguages = s:match("You can speak, read, and write ([^.]+)");
	if not sLanguages then
		sLanguages = s:match("You can read and write ([^.]+)");
	end
	if not sLanguages then
		sLanguages = s:match("You can read and write ([^.]+)");
	end
	if sLanguages then
		local tBase = {};
		local tOptions = {};
		local nPicks = 0;

		local sLanguage1, sLanguage2 = s:match("and your choice of (%w+) or (%w+)");
		if sLanguage1 and sLanguage2 then
			nPicks = 1;
			table.insert(tOptions, sLanguage1);
			table.insert(tOptions, sLanguage2);
			sLanguages = sLanguages:gsub("and your choice of (%w+) or (%w+)", "")
		elseif sLanguages:match("two other languages of your choice") then
			nPicks = 2;
			sLanguages = sLanguages:gsub("two other languages of your choice", "");
		else
			for k,v in pairs(CharWizardData.aParseRaceLangChoices) do
				nPicks = 1;
				sLanguages = sLanguages:gsub(k, "");
			end
		end

		sLanguages = sLanguages:gsub(" and ", ",");
		sLanguages = sLanguages:gsub("one extra language of your choice", "Choice");
		sLanguages = sLanguages:gsub("one other language of your choice", "Choice");
		-- EXCEPTION - Kenku - Languages - Volo
		sLanguages = sLanguages:gsub(", but you.*$", "");
		sLanguages = sLanguages:gsub(", but you can speak only by using your mimicry trait", "");
		
		local tSplitLanguages = StringManager.split(sLanguages, ",", true);
		for _,v in pairs(tSplitLanguages) do
			table.insert(tBase, v);
		end

		return tBase, tOptions, nPicks;
	end

	return {}, {}, 0;
end

function getSpellsFromText2024(s)
	if not s then
		return {}, {}, 0;
	end

	local tBase = {};
	for _,vSentence in pairs(StringManager.split(s, ".")) do
		local sSpellText = vSentence:match("know the (.-) cantrip");
		if sSpellText then
			local tSpellSplit = StringManager.splitByPattern(sSpellText, "and", true);
			for _,v in ipairs(tSpellSplit) do
				table.insert(tBase, v);
			end
		else
			sSpellText = vSentence:match("to cast the (.-) spell");
			if not sSpellText then
				sSpellText = vSentence:match("have the (.-) spell prepared");
			end
			if sSpellText then
				table.insert(tBase, StringManager.trim(sSpellText));
			end
		end
	end
	return tBase, {}, 0;
end
function getSpellsFromText2014(s)
	if not s then
		return {}, {}, 0;
	end
	local tBase = {};
	local sText = s:lower();
	for _,vSentence in pairs(StringManager.split(sText, ".")) do
	 	local sSpellText = vSentence:match("you know the (.-) cantrip");
		if not sSpellText then
		 	sSpellText = vSentence:match("you know the cantrip[s]? ([%w%s]+)");
		end
		if not sSpellText then
			sSpellText = vSentence:match("you can cast the (.-) on");
		end
		if not sSpellText then
			sSpellText = vSentence:match("to cast the (.-) spell");
		end
		if not sSpellText then
			sSpellText = vSentence:match("you can cast (.-) once with ");
		end
		if not sSpellText then
			sSpellText = vSentence:match("you can cast the (.-) with this trait");
		end
		if not sSpellText then
			sSpellText = vSentence:match("you can cast (.-) with this trait");
		end
		if not sSpellText then
			sSpellText = vSentence:match("you can also cast the (.-) with this trait");
		end
		if not sSpellText then
			sSpellText = vSentence:match("gain the ability to cast (.-), but only");
		end
		if not sSpellText then
			break;
		else
			sSpellText = sSpellText:gsub(" an unlimited number of times", "")
			sSpellText = sSpellText:gsub(" %(targeting yourself", "")
			sSpellText = sSpellText:gsub(" as a 2nd-level", "")
			sSpellText = sSpellText:gsub(" as a 2nd level", "")
			sSpellText = sSpellText:gsub(", but", "")
			sSpellText = sSpellText:gsub(" spell", "")

			sSpellText = StringManager.trim(sSpellText);

			local sSplit1, sSplit2 = sSpellText:match("(detect magic) and (detect poison and disease)")
			if not sSplit1 and not sSplit2 then
				sSplit1, sSplit2 = sSpellText:match("([%w%s]+) and ([%w%s]+)");
			end

			local tSplit = {};
			if sSplit1 and sSplit2 then
				table.insert(tSplit, sSplit1);
				table.insert(tSplit, sSplit2);
			end

			if #tSplit > 0 then
				for _,v in pairs(tSplit) do
					if vSentence:match("3rd") then
						-- Skip?
					elseif vSentence:match("5th") then
						-- Skip?
					else
						table.insert(tBase, v);
					end
				end
			else
				if vSentence:match("3rd") then
					-- Skip?
				elseif vSentence:match("5th") then
					-- Skip?
				else
					table.insert(tBase, sSpellText);
				end
			end
		end
	end

	return tBase, {}, 0;
end

--
--	FIELDS
--

function parseSkillsField(s, bSource2024)
	if bSource2024 then
		return CharBuildManager.parseSkillsField2024(s);
	end
	return CharBuildManager.parseSkillsField2014(s);
end
function parseSkillsField2024(s)
	s = StringManager.trim(s);
	if (s or "") == "" then
		return {}, {}, 0;
	end

	local sPicks = s:match("Choose any (%w+) skills?");
	if sPicks then
		local nPicks = CharBuildManager.convertSingleNumberTextToNumber(sPicks);
		return {}, CharBuildManager.processSkillDataOptions({ "any" }), nPicks;
	end

	local sPicks = s:match("Choose (%w+):");
	if sPicks then
		local nPicks = CharBuildManager.convertSingleNumberTextToNumber(sPicks);
		local tSkills = CharBuildManager.parseOptionsFromString(s:gsub("Choose (%w+):", ""));
		return {}, tSkills, nPicks;
	end

	return CharBuildManager.parseOptionsFromString(s), {}, 0;
end
function parseSkillsField2014(s)
	s = StringManager.trim(s);
	if (s or "") == "" then
		return {}, {}, 0;
	end

	local sPicks = s:match("Choose any (%w+)");
	if sPicks then
		return {}, {}, CharBuildManager.convertSingleNumberTextToNumber(sPicks);
	end

	local sPicks, nMatchEnd = s:match("Choose (%w+) skills? from()");
	if sPicks then
		return {}, CharBuildManager.parseOptionsFromText(s:sub(nMatchEnd)), CharBuildManager.convertSingleNumberTextToNumber(sPicks);
	end

	local sPicks, nMatchEnd = s:match("Choose (%w+) from()");
	if sPicks then
		return {}, CharBuildManager.parseOptionsFromText(s:sub(nMatchEnd)), CharBuildManager.convertSingleNumberTextToNumber(sPicks);
	end

	local sPicks, nMatchEnd = s:match("Choose (%w+) from among()");
	if sPicks then
		return {}, CharBuildManager.parseOptionsFromText(s:sub(nMatchEnd)), CharBuildManager.convertSingleNumberTextToNumber(sPicks);
	end

	local nMatchStart, sPicks, nMatchEnd = s:match("() plus (%w+) from among()");
	if sPicks then
		local tBase = CharBuildManager.parseOptionsFromText(s:sub(1, nMatchStart));
		local tOptions = CharBuildManager.parseOptionsFromText(s:sub(nMatchEnd));
		return tBase, tOptions, CharBuildManager.convertSingleNumberTextToNumber(sPicks);
	end

	local nMatchStart, sPicks, nMatchEnd = s:match("() plus (%w+) of your choice from among()");
	if sPicks then
		local tBase = CharBuildManager.parseOptionsFromText(s:sub(1, nMatchStart));
		local tOptions = CharBuildManager.parseOptionsFromText(s:sub(nMatchEnd));
		return tBase, tOptions, CharBuildManager.convertSingleNumberTextToNumber(sPicks);
	end

	local nMatchStart, sPicks, nMatchEnd = s:match("() plus your choice of (%w+) from among()");
	if sPicks then
		local tBase = CharBuildManager.parseOptionsFromText(s:sub(1, nMatchStart));
		local tOptions = CharBuildManager.parseOptionsFromText(s:sub(nMatchEnd));
		return tBase, tOptions, CharBuildManager.convertSingleNumberTextToNumber(sPicks);
	end

	local nMatchStart = s:match("() and one Intelligence, Wisdom, or Charisma skill of your choice");
	if nMatchStart then
		local tBase = CharBuildManager.parseOptionsFromText(s:sub(1, nMatchStart));
		local tOptions = {};
		for k,v in pairs(DataCommon.skilldata) do
			if (v.stat == "intelligence") or (v.stat == "wisdom") or (v.stat == "charisma") then
				table.insert(tOptions, k);
			end
		end
		table.sort(tOptions);
		return tBase, tOptions, 1;
	end

	return CharBuildManager.parseOptionsFromText(s), {}, 0;
end

function parseArmorField(s, bSource2024)
	if ((s or "") == "") or (s:lower() == "none") then
		return {}, {}, 0;
	end

	if not bSource2024 then
		s = s:gsub(" %(druids will not wear armor or use shields made of metal%)", "");
	end

	local tBase = {};

	if s:match("[Aa]ll armor") then
		table.insert(tBase, "Light");
		table.insert(tBase, "Medium");
		table.insert(tBase, "Heavy");
	else
		if s:match("[Ll]ight") then
			table.insert(tBase, "Light");
		end
		if s:match("[Mm]edium") then
			table.insert(tBase, "Medium");
		end
		if s:match("[Hh]eavy") then
			table.insert(tBase, "Heavy");
		end
	end
	if s:match("[Ss]hields") then
		table.insert(tBase, "Shields");
	end

	return tBase, {}, 0;
end

function parseWeaponField(s, bSource2024)
	if bSource2024 then
		return CharBuildManager.parseWeaponField2024(s);
	end
	return CharBuildManager.parseWeaponField2014(s);
end
function parseWeaponField2024(s)
	if (s or "") == "" then
		return {}, {}, 0;
	end

	local tBase = {};

	if s:match("Simple") then
		table.insert(tBase, "Simple");
	end
	
	-- Monk/Rogue special cases
	if s:match("Martial weapons that have the Light property") then
		table.insert(tBase, "Martial weapons that have the Light property");
		--CharManager.addProficiency(rAdd.nodeChar, "weapons", "Martial weapons that have the Light property", rAdd.bSource2024);
	elseif s:match("Martial weapons that have the Finesse or Light property") then
		table.insert(tBase, "Martial weapons that have the Finesse or Light property");
		--CharManager.addProficiency(rAdd.nodeChar, "weapons", "Martial weapons that have the Finesse or Light property", rAdd.bSource2024);
	elseif s:match("Martial") then
		table.insert(tBase, "Martial");
	end

	return tBase, {}, 0;
end
function parseWeaponField2014(s)
	if ((s or "") == "") or (s:lower() == "none") then
		return {}, {}, 0;
	end

	local tBase = {};

	for _,sSplit in ipairs(CharBuildManager.parseOptionsFromString(s)) do
		if sSplit:match("simple weapons") then
			table.insert(tBase, "Simple");
		elseif sSplit:match("martial weapons") then
			table.insert(tBase, "Martial");
		else
			table.insert(tBase, sSplit);
		end
	end

	return tBase, {}, 0;
end

function parseToolsField(s, bSource2024)
	if bSource2024 then
		return CharBuildManager.parseToolsField2024(s);
	end
	return CharBuildManager.parseToolsField2014(s);
end
function parseToolsField2024(s)
	if (s or "") == "" then
		return {}, {}, 0;
	end

	-- PHB - Bard
	local sPicks = s:match("Choose (%w+) Musical Instruments?");
	if sPicks then
		local nPicks = CharBuildManager.convertSingleNumberTextToNumber(sPicks);
		local tOptions = CharBuildManager.getToolNamesByType("Musical Instrument", true);
		return {}, tOptions, nPicks;
	end

	-- PHB - Monk
	local sPicks = s:match("Choose (%w+) types? of Artisan's Tools or Musical Instruments?");
	if sPicks then
		local nPicks = CharBuildManager.convertSingleNumberTextToNumber(sPicks);
		local tOptions = CharBuildManager.getToolNamesByType( { "Artisan's Tools", "Musical Instrument" }, true);
		return {}, tOptions, nPicks;
	end

	if s:match("Choose one kind of Musical Instrument") then
		local tOptions = CharBuildManager.getToolNamesByType("Musical Instrument", true);
		return {}, tOptions, 1;
	end

	if s:match("Choose one kind of Artisan's Tools") then
		local tOptions = CharBuildManager.getToolNamesByType("Artisan's Tools", true);
		return {}, tOptions, 1;
	end

	if s:match("Choose one kind of Gaming Set") then
		local tOptions = CharBuildManager.getToolNamesByType("Gaming Set", true);
		return {}, tOptions, 1;
	end

	return { s }, {}, 0;
end
function parseToolsField2014(s)
	if ((s or "") == "") or (s:lower() == "none") then
		return {}, {}, 0;
	end

	local sPicks, nMatchEnd = s:match("Choose (%w+) from among()");
	if sPicks then
		return {}, CharBuildManager.parseOptionsFromText(s:sub(nMatchEnd)), CharBuildManager.convertSingleNumberTextToNumber(sPicks);
	end

	s = s:gsub(", likely something native to your homeland", "");

	local tBase = {};
	local tOptions = {};
	local nPicks = 0;

	local tSplit = CharBuildManager.parseOptionsFromString(s);
	for _,sSplit in ipairs(tSplit) do
		local sSplitLower = sSplit:lower();

		if sSplitLower:match("^%d+$") then
			nPicks = tonumber(sSplitLower:match("%d+")) or 1;
		elseif sSplitLower:match("^one$") then
			nPicks = 1;
		elseif sSplitLower:match("^two$") then
			nPicks = 2;
		elseif sSplitLower:match("^three$") then
			nPicks = 3;
		end

		if sSplitLower:match("musical") then
			local tToolOptions = CharBuildManager.getToolNamesByType("Musical Instrument", true);
			for _,v in ipairs(tToolOptions) do
				table.insert(tOptions, v);
			end
		elseif sSplitLower:match("gaming") then
			local tToolOptions = CharBuildManager.getToolNamesByType("Gaming Set", true);
			for _,v in ipairs(tToolOptions) do
				table.insert(tOptions, v);
			end
		elseif sSplitLower:match("artisan") then
			local tToolOptions = CharBuildManager.getToolNamesByType("Artisan's Tools", true);
			for _,v in ipairs(tToolOptions) do
				table.insert(tOptions, v);
			end
		else
			table.insert(tBase, sSplit);
		end
	end

	return tBase, tOptions, nPicks;
end

function parseLanguagesField(s, bSource2024)
	if ((s or "") == "") or (s:lower() == "none") then
		return {}, {}, 0;
	end

	local sPicks = s:match("Choose any (%w+)");
	if sPicks then
		return {}, {}, CharBuildManager.convertSingleNumberTextToNumber(sPicks);
	end

	local sPicks, nMatchEnd = s:match("Choose (%w+) of()");
	if sPicks then
		return {}, CharBuildManager.parseOptionsFromText(s:sub(nMatchEnd)), CharBuildManager.convertSingleNumberTextToNumber(sPicks);
	end

	local nMatchEnd = s:match("Choose either()");
	if nMatchEnd then
		return {}, CharBuildManager.parseOptionsFromText(s:sub(nMatchEnd)), 1;
	end

	local sPicks = s:match("Choose (%w+) languages");
	if sPicks then
		return {}, {}, CharBuildManager.convertSingleNumberTextToNumber(sPicks);
	end

	return CharBuildManager.parseOptionsFromText(s), {}, 0;
end

--
--	COMMON FEATURE
--

function getCommonSkills(tFeature, s, bIs2024)
	if tFeature and tFeature.skill then
		local tBase = tFeature.skill.innate;
		local nPicks = tFeature.skill.choice;
		local tOptions;
		if nPicks then
			tOptions = CharBuildManager.processSkillDataOptions(tFeature.skill.choice_skill);
		end
		return tBase or {}, tOptions or {}, nPicks or 0;
	end

	if bIs2024 then
		return CharBuildManager.getSkillsFromText2024(s);
	else
		return CharBuildManager.getSkillsFromText2014(s);
	end
end
function getCommonArmorProf(tFeature, s, bIs2024)
	if tFeature and tFeature.armorprof then
		local tBase = tFeature.armorprof.innate;
		local nPicks = tFeature.armorprof.choice;
		local tOptions;
		if nPicks then
			tOptions = CharBuildManager.processArmorProfDataOptions(tFeature.armorprof.choice_prof);
		end
		return tBase or {}, tOptions or {}, nPicks or 0;
	end

	if bIs2024 then
		return CharBuildManager.getArmorProfFromText2024(s);
	else
		return CharBuildManager.getArmorProfFromText2014(s);
	end
end
function getCommonWeaponProf(tFeature, s, bIs2024)
	if tFeature and tFeature.weaponprof then
		local tBase = tFeature.weaponprof.innate;
		local nPicks = tFeature.weaponprof.choice;
		local tOptions;
		if nPicks then
			tOptions = CharBuildManager.processWeaponProfDataOptions(tFeature.weaponprof.choice_prof);
		end
		return tBase or {}, tOptions or {}, nPicks or 0;
	end

	if bIs2024 then
		return CharBuildManager.getWeaponProfFromText2024(s);
	else
		return CharBuildManager.getWeaponProfFromText2014(s);
	end
end
function getCommonToolProf(tFeature, s, bIs2024)
	if tFeature and tFeature.toolprof then
		local tBase = tFeature.toolprof.innate;
		local nPicks = tFeature.toolprof.choice;
		local tOptions;
		if nPicks then
			tOptions = CharBuildManager.processToolProfDataOptions(tFeature.toolprof.choice_prof);
		end
		return tBase or {}, tOptions or {}, nPicks or 0;
	end

	if bIs2024 then
		return CharBuildManager.getToolProfFromText2024(s);
	else
		return CharBuildManager.getToolProfFromText2014(s);
	end
end
function getCommonLanguages(tFeature, s, bIs2024)
	if tFeature and tFeature.language then
		local tBase = tFeature.language.innate;
		local nPicks = tFeature.language.choice;
		local tOptions;
		if nPicks then
			tOptions = CharBuildManager.processLanguageDataOptions(tFeature.language.choice_language);
		end
		return tBase or {}, tOptions or {}, nPicks or 0;
	end

	if bIs2024 then
		return CharBuildManager.getLanguagesFromText2024(s);
	else
		return CharBuildManager.getLanguagesFromText2014(s);
	end
end
function getCommonSpells(tFeature, s, bIs2024)
	if bIs2024 and tFeature and tFeature.spells then
		local tBase = {};
		for _,v in ipairs(tFeature.spells) do
			table.insert(tBase, v);
		end
		return tBase, {}, 0;
	end

	if bIs2024 then
		return CharBuildManager.getSpellsFromText2024(s);
	else
		return CharBuildManager.getSpellsFromText2014(s);
	end
end

--
--	CLASS SPECIFIC
--

function getClassFeatureData(sFeatureName, bIs2024)
	local sFeatureType = StringManager.simplify(sFeatureName);
	if bIs2024 then
		return CharWizardDataAction.tBuildDataClass2024[sFeatureType];
	end
	return CharWizardDataAction.parsedata[sFeatureType];
end
function getClassFeatureSkills(sFeatureName, s, bIs2024)
	local tFeature = CharBuildManager.getClassFeatureData(sFeatureName, bIs2024);
	return CharBuildManager.getCommonSkills(tFeature, s, bIs2024);
end
function getClassFeatureArmorProf(sFeatureName, s, bIs2024)
	local tFeature = CharBuildManager.getClassFeatureData(sFeatureName, bIs2024);
	return CharBuildManager.getCommonArmorProf(tFeature, s, bIs2024);
end
function getClassFeatureWeaponProf(sFeatureName, s, bIs2024)
	local tFeature = CharBuildManager.getClassFeatureData(sFeatureName, bIs2024);
	return CharBuildManager.getCommonWeaponProf(tFeature, s, bIs2024);
end
function getClassFeatureToolProf(sFeatureName, s, bIs2024)
	local tFeature = CharBuildManager.getClassFeatureData(sFeatureName, bIs2024);
	return CharBuildManager.getCommonToolProf(tFeature, s, bIs2024);
end
function getClassFeatureLanguages(sFeatureName, s, bIs2024)
	local tFeature = CharBuildManager.getClassFeatureData(sFeatureName, bIs2024);
	return CharBuildManager.getCommonLanguages(tFeature, s, bIs2024);
end
function getClassFeatureSpells(sFeatureName, s, bIs2024)
	local tFeature = CharBuildManager.getClassFeatureData(sFeatureName, bIs2024);
	return CharBuildManager.getCommonSpells(tFeature, s, bIs2024);
end

--
--	SPECIES SPECIFIC
--

function getSpeciesTraitData(sFeatureName, bIs2024)
	local sFeatureType = StringManager.simplify(sFeatureName);
	if bIs2024 then
		return CharWizardDataAction.tBuildDataSpecies2024[sFeatureType];
	end
	return CharWizardDataAction.parsedata[sFeatureType];
end
function getSpeciesTraitSkills(sFeatureName, s, bIs2024)
	local tFeature = CharBuildManager.getSpeciesTraitData(sFeatureName, bIs2024);
	return CharBuildManager.getCommonSkills(tFeature, s, bIs2024);
end
function getSpeciesTraitArmorProf(sFeatureName, s, bIs2024)
	local tFeature = CharBuildManager.getSpeciesTraitData(sFeatureName, bIs2024);
	return CharBuildManager.getCommonArmorProf(tFeature, s, bIs2024);
end
function getSpeciesTraitWeaponProf(sFeatureName, s, bIs2024)
	local tFeature = CharBuildManager.getSpeciesTraitData(sFeatureName, bIs2024);
	return CharBuildManager.getCommonWeaponProf(tFeature, s, bIs2024);
end
function getSpeciesTraitToolProf(sFeatureName, s, bIs2024)
	local tFeature = CharBuildManager.getSpeciesTraitData(sFeatureName, bIs2024);
	return CharBuildManager.getCommonToolProf(tFeature, s, bIs2024);
end
function getSpeciesTraitLanguages(sFeatureName, s, bIs2024)
	local tFeature = CharBuildManager.getSpeciesTraitData(sFeatureName, bIs2024);
	return CharBuildManager.getCommonLanguages(tFeature, s, bIs2024);
end
function getSpeciesTraitSpells(sFeatureName, s, bIs2024)
	local tFeature = CharBuildManager.getSpeciesTraitData(sFeatureName, bIs2024);
	return CharBuildManager.getCommonSpells(tFeature, s, bIs2024);
end

--
--	FEAT SPECIFIC
--

function getFeatData(sFeatureName, bIs2024)
	local sFeatureType = StringManager.simplify(sFeatureName);
	if bIs2024 then
		return CharWizardDataAction.tBuildDataFeat2024[sFeatureType];
	end
	return CharWizardDataAction.parsedata[sFeatureType];
end
function getFeatSkills(sFeat, s, bIs2024)
	local tFeature = CharBuildManager.getFeatData(sFeatureName, bIs2024);
	return CharBuildManager.getCommonSkills(tFeature, s, bIs2024);
end
function getFeatArmorProf(sFeatureName, s, bIs2024)
	local tFeature = CharBuildManager.getFeatData(sFeatureName, bIs2024);
	return CharBuildManager.getCommonArmorProf(tFeature, s, bIs2024);
end
function getFeatWeaponProf(sFeatureName, s, bIs2024)
	local tFeature = CharBuildManager.getFeatData(sFeatureName, bIs2024);
	return CharBuildManager.getCommonWeaponProf(tFeature, s, bIs2024);
end
function getFeatToolProf(sFeatureName, s, bIs2024)
	local tFeature = CharBuildManager.getFeatData(sFeatureName, bIs2024);
	return CharBuildManager.getCommonToolProf(tFeature, s, bIs2024);
end
function getFeatLanguages(sFeatureName, s, bIs2024)
	local tFeature = CharBuildManager.getFeatData(sFeatureName, bIs2024);
	return CharBuildManager.getCommonLanguages(tFeature, s, bIs2024);
end
function getFeatSpells(sFeatureName, s, bIs2024)
	local tFeature = CharBuildManager.getFeatData(sFeatureName, bIs2024);
	return CharBuildManager.getCommonSpells(tFeature, s, bIs2024);
end
