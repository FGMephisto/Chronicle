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

function processSkillDataOptions(tOptions, bIs2024)
	if not tOptions or (#tOptions == 0) then
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
		return { sSkill, sSkill2 }, {}, 0;
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

function processArmorProfDataOptions(tOptions, bIs2024)
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

function processWeaponProfDataOptions(tOptions, bIs2024)
	if not tOptions or (#tOptions == 0) then
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

function processToolProfDataOptions(tOptions, bIs2024)
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
	elseif s:match("gain proficiency with one type of artisan's tools of your choice") then
		return {}, CharBuildManager.getToolNamesByType("Artisan's Tools", true), 1;
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
	elseif s:match("proficiency with one musical instrument of your choice") then
		return {}, CharBuildManager.getToolNamesByType("Musical Instrument", false), 1;
	-- XGtE - Prodigy
	elseif s:match("one tool proficiency of your choice") then
		return {}, CharBuildManager.getToolNamesByType(nil, false), 1;
	end
	return {}, {}, 0;
end

function processLanguageDataOptions(tOptions, bIs2024)
	if not tOptions or (#tOptions == 0) then
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
		return { sLanguage }, {}, 0;
	end

	-- Known languages
	-- XGtE - Prodigy
	if s:match("fluency in one language of your choice") then
		return {}, {}, 1;
	end

	-- PHB - Noble
	if s:match("One of your choice") then
		return {}, {}, 1;
	end

	local sLanguages = s:match("You can speak, read, and write ([^.]+)");
	if not sLanguages then
		sLanguages = s:match("You can read and write ([^.]+)");
	end
	if not sLanguages then
		sLanguages = s:match("can speak, read, and write ([^.]+)");
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
				if sLanguages:find(k) then
					nPicks = 1;
					sLanguages = sLanguages:gsub(k, "");
				end
			end
		end

		-- EXCEPTION - Satyr - Languages - MMotM
		sLanguages = sLanguages:gsub("one other language that you and your DM agree is appropriate for the character", "Choice");
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
	s = s:lower();

	local tBase = {};

	for _,vSentence in pairs(StringManager.split(s, ".")) do
		local sSpellText = vSentence:match("you know the (.-) cantrip");
		if not sSpellText then
			sSpellText = vSentence:match("you gain the (.-) cantrip");
		end
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
	local tBase, tOptions, nPicks;
	if bSource2024 then
		tBase, tOptions, nPicks = CharBuildManager.parseSkillsField2024(s);
	else
		tBase, tOptions, nPicks = CharBuildManager.parseSkillsField2014(s);
	end
	if (nPicks or 0) > 0 then
		tOptions = CharBuildManager.processSkillDataOptions(tOptions, bSource2024);
	end
	return tBase or {}, tOptions or {}, nPicks or {};
end
function parseSkillsField2024(s)
	s = StringManager.trim(s);
	if (s or "") == "" then
		return {}, {}, 0;
	end

	local sPicks = s:match("Choose any (%w+) skills?");
	if sPicks then
		local nPicks = CharBuildManager.convertSingleNumberTextToNumber(sPicks);
		return {}, {}, nPicks;
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

	local sPicks, nMatchEnd = s:match("Choose (%w+) from among()");
	if sPicks then
		return {}, CharBuildManager.parseOptionsFromText(s:sub(nMatchEnd)), CharBuildManager.convertSingleNumberTextToNumber(sPicks);
	end

	local sPicks, nMatchEnd = s:match("Choose (%w+) from()");
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
	local tBase, tOptions, nPicks; 
	if bSource2024 then
		tBase, tOptions, nPicks = CharBuildManager.parseArmorField2024(s);
	else
		tBase, tOptions, nPicks = CharBuildManager.parseArmorField2014(s);
	end

	if (nPicks or 0) > 0 then
		tOptions = CharBuildManager.processArmorProfDataOptions(tOptions, bSource2024);
	end
	return tBase or {}, tOptions or {}, nPicks or 0;
end
function parseArmorField2024(s)
	return CharBuildManager.helperParseArmorField(s);
end
function parseArmorField2014(s)
	return CharBuildManager.helperParseArmorField(s);
end
function helperParseArmorField(s, bSource2024)
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
	local tBase, tOptions, nPicks; 
	if bSource2024 then
		tBase, tOptions, nPicks = CharBuildManager.parseWeaponField2024(s);
	else
		tBase, tOptions, nPicks = CharBuildManager.parseWeaponField2014(s);
	end

	if (nPicks or 0) > 0 then
		tOptions = CharBuildManager.processWeaponProfDataOptions(tOptions, bSource2024);
	end
	return tBase or {}, tOptions or {}, nPicks or 0;
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
	elseif s:match("Martial weapons that have the Finesse or Light property") then
		table.insert(tBase, "Martial weapons that have the Finesse or Light property");
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
		local sSplitLower = sSplit:lower();
		if sSplitLower:match("simple weapons") then
			table.insert(tBase, "Simple");
		elseif sSplitLower:match("martial weapons") then
			table.insert(tBase, "Martial");
		else
			table.insert(tBase, StringManager.capitalize(sSplit));
		end
	end

	return tBase, {}, 0;
end

function parseToolsField(s, bSource2024)
	local tBase, tOptions, nPicks; 
	if bSource2024 then
		tBase, tOptions, nPicks = CharBuildManager.parseToolsField2024(s);
	else
		tBase, tOptions, nPicks = CharBuildManager.parseToolsField2014(s);
	end

	if (nPicks or 0) > 0 then
		tOptions = CharBuildManager.processToolProfDataOptions(tOptions, bSource2024);
	end
	return tBase or {}, tOptions or {}, nPicks or 0;
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

	local nPicks;

	local sPicks, nMatchEnd = s:match("Choose (%w+) from among()");
	local bEarlyPickMatch = false;
	if sPicks then
		nPicks = CharBuildManager.convertSingleNumberTextToNumber(sPicks);
		s = s:sub(nMatchEnd);
		bEarlyPickMatch = true;
	end

	s = s:gsub(", likely something native to your homeland", "");

	local tBase = {};
	local tOptions = {};

	local tSplit = CharBuildManager.parseOptionsFromString(s);
	for _,sSplit in ipairs(tSplit) do
		local sSplitLower = sSplit:lower();

		if not nPicks then
			if sSplitLower:match("^%d+") then
				nPicks = tonumber(sSplitLower:match("%d+")) or 1;
			elseif sSplitLower:match("^one") then
				nPicks = 1;
			elseif sSplitLower:match("^two") then
				nPicks = 2;
			elseif sSplitLower:match("^three") then
				nPicks = 3;
			end
		end

		if sSplitLower:match("musical") then
			local tToolOptions = CharBuildManager.getToolNamesByType("Musical Instrument", false);
			for _,v in ipairs(tToolOptions) do
				table.insert(tOptions, v);
			end
		elseif sSplitLower:match("gaming") then
			local tToolOptions = CharBuildManager.getToolNamesByType("Gaming Set", false);
			for _,v in ipairs(tToolOptions) do
				table.insert(tOptions, v);
			end
		elseif sSplitLower:match("artisan") then
			local tToolOptions = CharBuildManager.getToolNamesByType("Artisan's Tools", false);
			for _,v in ipairs(tToolOptions) do
				table.insert(tOptions, v);
			end
		else
			if bEarlyPickMatch then
				table.insert(tOptions, StringManager.capitalizeAll(sSplit));
			else
				table.insert(tBase, sSplit);
			end
		end
	end

	return tBase, tOptions, nPicks;
end

function parseLanguagesField(s, bSource2024)
	if bSource2024 then
		return {}, {}, 0;
	end
	
	local tBase, tOptions, nPicks = CharBuildManager.parseLanguagesField2014(s);
	if (nPicks or 0) > 0 then
		tOptions = CharBuildManager.processLanguageDataOptions(tOptions, bSource2024);
	end
	return tBase or {}, tOptions or {}, nPicks or 0;
end
function parseLanguagesField2014(s)
	if ((s or "") == "") or (s:lower() == "none") then
		return {}, {}, 0;
	end

	-- Clan Crafter - Sword Coast
	if s:match("Dwarvish or one other of your choice") then
		return { "Dwarvish" }, {}, 0;
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

	local sPicks = s:match("(%w+) of your choice");
	if sPicks then
		return {}, {}, CharBuildManager.convertSingleNumberTextToNumber(sPicks:lower());
	end

	return CharBuildManager.parseOptionsFromText(s), {}, 0;
end

--
--	COMMON FEATURE
--

function getCommonSkills(tOverride, s, bIs2024)
	local tBase = {};
	local tOptions = {};
	local nPicks = 0;

	if tOverride and tOverride.skill then
		tBase = tOverride.skill.innate or {};
		tOptions = tOverride.skill.choice_skill or {};
		nPicks = tOverride.skill.choice or 0;
	else
		if bIs2024 then
			tBase, tOptions, nPicks = CharBuildManager.getSkillsFromText2024(s);
		else
			tBase, tOptions, nPicks = CharBuildManager.getSkillsFromText2014(s);
		end
	end

	if (nPicks or 0) > 0 then
		tOptions = CharBuildManager.processSkillDataOptions(tOptions, bIs2024);
	end
	return tBase or {}, tOptions or {}, nPicks or 0;
end
function getCommonArmorProf(tOverride, s, bIs2024)
	local tBase = {};
	local tOptions = {};
	local nPicks = 0;

	if tOverride and tOverride.armorprof then
		tBase = tOverride.armorprof.innate or {};
		tOptions = tOverride.armorprof.choice_prof or {};
		nPicks = tOverride.armorprof.choice or 0;
	else
		if bIs2024 then
			tBase, tOptions, nPicks = CharBuildManager.getArmorProfFromText2024(s);
		else
			tBase, tOptions, nPicks = CharBuildManager.getArmorProfFromText2014(s);
		end
	end

	if (nPicks or 0) > 0 then
		tOptions = CharBuildManager.processArmorProfDataOptions(tOptions, bIs2024);
	end
	return tBase or {}, tOptions or {}, nPicks or 0;
end
function getCommonWeaponProf(tOverride, s, bIs2024)
	local tBase = {};
	local tOptions = {};
	local nPicks = 0;

	if tOverride and tOverride.weaponprof then
		tBase = tOverride.weaponprof.innate or {};
		tOptions = tOverride.weaponprof.choice_prof or {};
		nPicks = tOverride.weaponprof.choice or 0;
	else
		if bIs2024 then
			tBase, tOptions, nPicks = CharBuildManager.getWeaponProfFromText2024(s);
		else
			tBase, tOptions, nPicks = CharBuildManager.getWeaponProfFromText2014(s);
		end
	end

	if (nPicks or 0) > 0 then
		tOptions = CharBuildManager.processWeaponProfDataOptions(tOptions, bIs2024);
	end
	return tBase or {}, tOptions or {}, nPicks or 0;
end
function getCommonToolProf(tOverride, s, bIs2024)
	local tBase = {};
	local tOptions = {};
	local nPicks = 0;

	if tOverride and tOverride.toolprof then
		tBase = tOverride.toolprof.innate or {};
		tOptions = tOverride.toolprof.choice_prof or {};
		nPicks = tOverride.toolprof.choice or 0;
	else
		if bIs2024 then
			tBase, tOptions, nPicks = CharBuildManager.getToolProfFromText2024(s);
		else
			tBase, tOptions, nPicks = CharBuildManager.getToolProfFromText2014(s);
		end
	end

	if (nPicks or 0) > 0 then
		tOptions = CharBuildManager.processToolProfDataOptions(tOptions, bIs2024);
	end
	return tBase or {}, tOptions or {}, nPicks or 0;
end
function getCommonLanguages(tOverride, s, bIs2024)
	local tBase = {};
	local tOptions = {};
	local nPicks = 0;

	if tOverride and tOverride.language then
		tBase = tOverride.language.innate or {};
		tOptions = tOverride.language.choice_language or {};
		nPicks = tOverride.language.choice or 0;
	else
		if bIs2024 then
			tBase, tOptions, nPicks = CharBuildManager.getLanguagesFromText2024(s);
		else
			tBase, tOptions, nPicks = CharBuildManager.getLanguagesFromText2014(s);
		end
	end

	if (nPicks or 0) > 0 then
		tOptions = CharBuildManager.processLanguageDataOptions(tOptions, bIs2024);
	end
	return tBase or {}, tOptions or {}, nPicks or 0;
end
function getCommonSpells(tOverride, s, bIs2024)
	local tBase = {};
	local tOptions = {};
	local nPicks = 0;

	if bIs2024 and tOverride and tOverride.spells then
		for _,v in ipairs(tOverride.spells) do
			table.insert(tBase, v.name);
		end
	else
		if bIs2024 then
			tBase, tOptions, nPicks = CharBuildManager.getSpellsFromText2024(s);
		else
			tBase, tOptions, nPicks = CharBuildManager.getSpellsFromText2014(s);
		end
	end

	return tBase or {}, tOptions or {}, nPicks or 0;
end

--
--	CLASS SPECIFIC
--

function getClassFeatureOverrideData(sFeatureName, bIs2024)
	local sFeatureType = StringManager.simplify(sFeatureName);
	if bIs2024 then
		return CharWizardDataAction.tBuildDataClass2024[sFeatureType];
	end
	return CharWizardDataAction.parsedata[sFeatureType];
end
function getClassFeatureSkills(sFeatureName, s, bIs2024)
	local tOverride = CharBuildManager.getClassFeatureOverrideData(sFeatureName, bIs2024);
	return CharBuildManager.getCommonSkills(tOverride, s, bIs2024);
end
function getClassFeatureArmorProf(sFeatureName, s, bIs2024)
	local tOverride = CharBuildManager.getClassFeatureOverrideData(sFeatureName, bIs2024);
	return CharBuildManager.getCommonArmorProf(tOverride, s, bIs2024);
end
function getClassFeatureWeaponProf(sFeatureName, s, bIs2024)
	local tOverride = CharBuildManager.getClassFeatureOverrideData(sFeatureName, bIs2024);
	return CharBuildManager.getCommonWeaponProf(tOverride, s, bIs2024);
end
function getClassFeatureToolProf(sFeatureName, s, bIs2024)
	local tOverride = CharBuildManager.getClassFeatureOverrideData(sFeatureName, bIs2024);
	return CharBuildManager.getCommonToolProf(tOverride, s, bIs2024);
end
function getClassFeatureLanguages(sFeatureName, s, bIs2024)
	local tOverride = CharBuildManager.getClassFeatureOverrideData(sFeatureName, bIs2024);
	return CharBuildManager.getCommonLanguages(tOverride, s, bIs2024);
end
function getClassFeatureSpells(sFeatureName, s, bIs2024)
	local tOverride = CharBuildManager.getClassFeatureOverrideData(sFeatureName, bIs2024);
	return CharBuildManager.getCommonSpells(tOverride, s, bIs2024);
end

-- Expected: nodeSource, bSource2024, sClassName, nClassLevel
function getClassFeatureSpellcastingData(tData)
	if not CharBuildDropManager.helperBuildGetText(tData) then
		return nil;
	end
	local sClassNameLower = (tData.sClassName or ""):lower();
	local nClassLevel = math.max(math.min((tData.nClassLevel or 0), 20), 1);

	local tResult = {};
	tResult.sClassName = tData.sClassName or "";
	tResult.nClassLevel = nClassLevel;

	-- Calculate spellcasting ability
	tResult.sAbility = tData.sSourceText:match("(%a+) is your spellcasting ability");
	if not tResult.sAbility then
		tResult.sAbility = tData.sSourceText:match("(%a+) is the spellcasting ability");
	end
	if tResult.sAbility then
		tResult.sAbility = tResult.sAbility:lower();
	end

	-- Calculate caster level multiple
	local nFeatureLevel = DB.getValue(tData.nodeSource, "level", 0);
	if nFeatureLevel > 0 then
		local tExceptions;
		if tData.bSource2024 then
			tExceptions = { CharManager.CLASS_PALADIN, CharManager.CLASS_RANGER, CharManager.CLASS_ARTIFICER };
		else
			tExceptions = { CharManager.CLASS_ARTIFICER };
		end
		if StringManager.contains(tExceptions, sClassNameLower) then
			tResult.nCasterLevelMult = -2;
		else
			tResult.nCasterLevelMult = nFeatureLevel;
		end
	else
		tResult.nCasterLevelMult = 1;
	end

	-- Calculate cantrips known
	-- Bard/Cleric/Druid/Eldritch Knight (2024/2014)  Sorcerer/Warlock/Wizard (2014)
	local sCantrips = tData.sSourceText:match("know (%w+) cantrips of your choice");
	-- Sorcerer/Warlock/Wizard (2024)
	if not sCantrips then
		sCantrips = tData.sSourceText:match("know (%w+) %w+ cantrips of your choice");
	end
	-- Arcane Trickster (2024/2014)
	if not sCantrips then
		sCantrips = tData.sSourceText:match("and (%w+) other cantrips of your choice");
	end
	if sCantrips then
		tResult.nCantrips = CharBuildManager.convertSingleNumberTextToNumber(sCantrips, 2);
		if nFeatureLevel == 1 and ((tResult.nCasterLevelMult or 0) == 1) then
			if nClassLevel >= 4 then
				tResult.nCantrips = tResult.nCantrips + 1;
			end
		end
		if nClassLevel >= 10 then
			tResult.nCantrips = tResult.nCantrips + 1;
		end
		-- Artificer (2024 - UA) Special case
		if (nFeatureLevel == 1) and ((tResult.nCasterLevelMult or 0) == -2) then
			if nClassLevel >= 14 then
				tResult.nCantrips = tResult.nCantrips + 1;
			end
		end
	end

	-- Calculate prepared spells
	if tData.bSource2024 then
		local tPreparedData = CharWizardData.SPELLS_PREPARED_2024[sClassNameLower];
		if not tPreparedData then
			if tResult.nCasterLevelMult > 1 then
				tPreparedData = CharWizardData.SPELLS_PREPARED_2024.subclass;
			elseif tResult.nCasterLevelMult < 1 then
				tPreparedData = CharWizardData.SPELLS_PREPARED_2024.half;
			else
				tPreparedData = CharWizardData.SPELLS_PREPARED_2024.standard;
			end
		end
		tResult.nPrepared = tPreparedData[nClassLevel];
	else
		if tData.sSourceText:match("Preparing and Casting Spells") then
			tResult.nPrepared = nClassLevel;
			if tData.tAbilities and tResult.sAbility then
				local nAbilityScore = tData.tAbilities[tResult.sAbility] or 10;
				local nAbilityBonus = math.floor((nAbilityScore - 10) / 2);
				tResult.nPrepared = math.max(tResult.nPrepared + nAbilityBonus, 1);
			end
		end
	end

	-- Calculate known spells
	if tData.bSource2024 then
		if StringManager.contains({ CharManager.CLASS_WIZARD }, sClassNameLower) then
			tResult.nKnown = 4 + (nClassLevel * 2);
		end
	else
		local sClassNameUpper = (tData.sClassName or ""):upper();
		if sClassNameUpper:match("%s+") then
			sClassNameUpper = sClassNameUpper:gsub("%s+", "_");
		end
		local sKnownCheck = sClassNameUpper .. "_SPELLSKNOWN";
		if CharWizardData[sKnownCheck] then
			tResult.nKnown = CharWizardData[sKnownCheck][nClassLevel];
		end
	end

	return tResult;
end

--
--	SPECIES SPECIFIC
--

function getSpeciesTraitOverrideData(sTraitName, bIs2024)
	local sFeatureType = StringManager.simplify(sTraitName);
	if bIs2024 then
		return CharWizardDataAction.tBuildDataSpecies2024[sFeatureType];
	end
	return CharWizardDataAction.parsedata[sFeatureType];
end
function getSpeciesTraitSkills(sTraitName, s, bIs2024)
	local tOverride = CharBuildManager.getSpeciesTraitOverrideData(sTraitName, bIs2024);
	return CharBuildManager.getCommonSkills(tOverride, s, bIs2024);
end
function getSpeciesTraitArmorProf(sTraitName, s, bIs2024)
	local tOverride = CharBuildManager.getSpeciesTraitOverrideData(sTraitName, bIs2024);
	return CharBuildManager.getCommonArmorProf(tOverride, s, bIs2024);
end
function getSpeciesTraitWeaponProf(sTraitName, s, bIs2024)
	local tOverride = CharBuildManager.getSpeciesTraitOverrideData(sTraitName, bIs2024);
	return CharBuildManager.getCommonWeaponProf(tOverride, s, bIs2024);
end
function getSpeciesTraitToolProf(sTraitName, s, bIs2024)
	local tOverride = CharBuildManager.getSpeciesTraitOverrideData(sTraitName, bIs2024);
	return CharBuildManager.getCommonToolProf(tOverride, s, bIs2024);
end
function getSpeciesTraitLanguages(sTraitName, s, bIs2024)
	local tOverride = CharBuildManager.getSpeciesTraitOverrideData(sTraitName, bIs2024);
	return CharBuildManager.getCommonLanguages(tOverride, s, bIs2024);
end
function getSpeciesTraitSpells(sTraitName, s, bIs2024)
	local tOverride = CharBuildManager.getSpeciesTraitOverrideData(sTraitName, bIs2024);
	return CharBuildManager.getCommonSpells(tOverride, s, bIs2024);
end

function getSpeciesLanguages2024()
	local tBase = {};
	local sCommon = Interface.getString("language_value_common");
	if LanguageManager.isCampaignLanguage(sCommon) then
		table.insert(tBase, sCommon);
	end

	local tOptions = {};
	if GameSystem.languagestandard then
		for _,v in ipairs(GameSystem.languagestandard) do
			if LanguageManager.isCampaignLanguage(v) then
				table.insert(tOptions, v);
			end
		end
	end
	tOptions = CharBuildManager.processLanguageDataOptions(tOptions, true);

	return tBase, tOptions, 2;
end

--
-- BACKGROUND SPECIFIC
--

function getBackgroundFeatureLanguages(sFeatureName, s, bIs2024)
	return CharBuildManager.getCommonLanguages(nil, s, bIs2024);
end

--
--	FEAT SPECIFIC
--

function getFeatOverrideData(sFeatureName, bIs2024)
	local sFeatureType = StringManager.simplify(sFeatureName);
	if bIs2024 then
		return CharWizardDataAction.tBuildDataFeat2024[sFeatureType];
	end
	return CharWizardDataAction.parsedata[sFeatureType];
end
function getFeatSkills(sFeat, s, bIs2024)
	local tOverride = CharBuildManager.getFeatOverrideData(sFeatureName, bIs2024);
	return CharBuildManager.getCommonSkills(tOverride, s, bIs2024);
end
function getFeatArmorProf(sFeatureName, s, bIs2024)
	local tOverride = CharBuildManager.getFeatOverrideData(sFeatureName, bIs2024);
	return CharBuildManager.getCommonArmorProf(tOverride, s, bIs2024);
end
function getFeatWeaponProf(sFeatureName, s, bIs2024)
	local tOverride = CharBuildManager.getFeatOverrideData(sFeatureName, bIs2024);
	return CharBuildManager.getCommonWeaponProf(tOverride, s, bIs2024);
end
function getFeatToolProf(sFeatureName, s, bIs2024)
	local tOverride = CharBuildManager.getFeatOverrideData(sFeatureName, bIs2024);
	return CharBuildManager.getCommonToolProf(tOverride, s, bIs2024);
end
function getFeatLanguages(sFeatureName, s, bIs2024)
	local tOverride = CharBuildManager.getFeatOverrideData(sFeatureName, bIs2024);
	return CharBuildManager.getCommonLanguages(tOverride, s, bIs2024);
end
function getFeatSpells(sFeatureName, s, bIs2024)
	local tOverride = CharBuildManager.getFeatOverrideData(sFeatureName, bIs2024);
	return CharBuildManager.getCommonSpells(tOverride, s, bIs2024);
end

--
--	EQUIPMENT KITS
--

function helperAddEquipmentKit(rAdd)
	if not rAdd or rAdd.bWizard then
		return;
	end
	if not rAdd.bSource2024 then
		return;
	end
	if (rAdd.nCharClassLevel ~= 1) then
		return;
	end

	local tOptions = {};
	if rAdd.sSourceClass == "reference_class" then
		tOptions = CharBuildManager.getRecordEquipmentKitOptions2024(rAdd.nodeSource, "startingequipmentlist");
	else
		tOptions = CharBuildManager.getRecordEquipmentKitOptions2024(rAdd.nodeSource);
	end
	if #tOptions < 1 then
		return;
	end
	if tOptions == 1 then
		rAdd.sEquipmentKitRecord = tOptions[1].linkrecord;
		CharBuildManager.helperAddEquipmentKitOption(rAdd);
		return;
	end

	local tLookup = {};
	for _,v in ipairs(tOptions) do
		tLookup[v.text] = v.linkrecord;
	end
	local tDialogData = {
		title = Interface.getString("char_build_title_selectequipmentpack"),
		msg = Interface.getString("char_build_message_selectequipmentpack"):format(1),
		options = tOptions,
		callback = CharBuildManager.helperOnEquipmentKitSelect2024,
		custom = { rAdd = rAdd, tLookup = tLookup, },
		showmodule = true,
	};
	DialogManager.requestSelectionDialog(tDialogData);
end
function getRecordEquipmentKitOptions2024(nodeRecord, sListPath)
	if not nodeRecord then
		return {};
	end

	local tOptions = {};

	for k,nodeOption in ipairs(DB.getChildList(nodeRecord, sListPath or "equipmentlist")) do
		local tOutput = {};
		for _,nodeItem in ipairs(DB.getChildList(nodeOption, "items")) do
			local nCount = DB.getValue(nodeItem, "count", 0);
			local sName = DB.getValue(nodeItem, "name", "");
			if nCount > 1 then
				table.insert(tOutput, string.format("%d %s", nCount, sName));
			else
				table.insert(tOutput, sName);
			end
		end
		local nWealth = DB.getValue(nodeOption, "wealth", 0);
		if nWealth > 0 then
			table.insert(tOutput, string.format("%d GP", nWealth));
		end

		local tOption = {
			text = table.concat(tOutput, ", ");
			linkrecord = DB.getPath(nodeOption),
		};
		table.insert(tOptions, tOption);
	end

	return tOptions;
end
function helperOnEquipmentKitSelect2024(tSelection, tData)
	for _,s in ipairs(tSelection) do
		tData.rAdd.sEquipmentKitRecord = tData.tLookup[s];
		CharBuildManager.helperAddEquipmentKitOption(tData.rAdd);
	end
end
function helperAddEquipmentKitOption(rAdd)
	if not rAdd or ((rAdd.sEquipmentKitRecord or "") == "") then
		return;
	end
	local nodeOption = DB.findNode(rAdd.sEquipmentKitRecord);
	if not nodeOption then
		return;
	end

	for _,nodeItem in ipairs(DB.getChildList(nodeOption, "items")) do
		ItemManager.handleItem(DB.getPath(rAdd.nodeChar), "inventorylist", "item", DB.getPath(nodeItem), true);
	end

	local nWealth = DB.getValue(nodeOption, "wealth", 0);
	if nWealth > 0 then
		CurrencyManager.addRecordCurrency(rAdd.nodeChar, "GP", nWealth);
	end
end
