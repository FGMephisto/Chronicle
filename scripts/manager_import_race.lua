-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local _tImportState = {};

function onTabletopInit()
	local sLabel = Interface.getString("import_race_mode_2022");
	ImportUtilityManager.registerImportMode("race", "2022", sLabel, ImportRaceManager.import2022);
end

function performImport(w)
	local sMode = w.mode.getSelectedValue();
	local tImportMode = ImportUtilityManager.getImportMode("race", sMode);
	if tImportMode then
		local sDesc = w.description.getValue();
		tImportMode.fn(sDesc);
	end
end

--
--	Built-in supported import modes
--

function import2022(sDesc)
	-- Track state information
	ImportRaceManager.initImportState(sDesc);

	-- Assume name on Line 1
	ImportRaceManager.importHelperName();
	
	-- Races normally start off with a descriptive text section. 
	-- These lines are read in and ignored until you reach the Traits section.
		-- Syntax:
		-- [Race Name] Traits
		-- [Subrace Name] Traits
		-- Examples of a race with no sub-races. The race name is Aasimar:		
		-- Aasimar Traits
		-- Example of a race (Genasi) with 4 different sub-races
		-- Genasi Traits
		-- Air Genasi Traits
		-- Earth Genasi Traits
		-- Fire Genasi Traits
		-- Water Genasi Traits
	ImportRaceManager.nextImportLine();
	while _tImportState.sActiveLine do

		if ImportRaceManager.handleRaceTraitsHeader() then
			-- Handled

		elseif ImportRaceManager.handleSubraceHeader() then
			-- Handled

		else
			-- Look for a feature heading. It should be proper cased and end in a period.
			-- If it is multiple words, then each word should begin with a capitalization.
			local sHeading, sRemainder = _tImportState.sActiveLine:match("([^.!]+[.!])%s(.*)")
			if ImportRaceManager.isTraitHeading(sHeading) then
				ImportRaceManager.finalizeTrait();
				ImportRaceManager.setTraitData(StringManager.trim(sHeading));
				ImportRaceManager.addDescOutput(string.format("<p>%s</p>", StringManager.trim(sRemainder)));
			else
				ImportRaceManager.addDescOutput(string.format("<p>%s</p>", _tImportState.sActiveLine));
			end
		end

		ImportRaceManager.nextImportLine();
	end

	-- Finalize all traits
	ImportRaceManager.finalizeTrait();
	
	-- Description
	ImportRaceManager.finalizeDescription();
	
	-- Open new record window and matching campaign list
	ImportUtilityManager.showRecord("race", _tImportState.node);
	for _,v in ipairs(_tImportState.tSubraceList) do
		ImportUtilityManager.showRecord("race_subrace", v.node);
	end
end

--
--	Import section helper functions
--

-- Assumes name is on next line
function importHelperName()
	-- Name
	ImportRaceManager.nextImportLine();
	_tImportState.sRaceName = StringManager.trim(_tImportState.sActiveLine);
	DB.setValue(_tImportState.node, "name", "string", _tImportState.sRaceName);
end

--
--	Import state identification and tracking
--

function handleRaceTraitsHeader()
	if _tImportState.nodeSubrace then
		return false;
	end

	-- look for a line that starts the Traits section
	local sTraitHeaderPattern = "^" .. _tImportState.sRaceName:lower() .. "%s+traits$";
	if not StringManager.trim(_tImportState.sActiveLine):lower():match(sTraitHeaderPattern) then
		return false;
	end

	ImportRaceManager.addDescOutput(string.format("<h>%s</h>", _tImportState.sActiveLine));

	-- skip the next line if it is a generic line like this
		-- example: As a bugbear, you have the following racial traits.
	local sNextLine = ImportRaceManager.peekImportLine();
	if sNextLine and sNextLine:match("traits%.$") then
		ImportRaceManager.nextImportLine();
		ImportRaceManager.addDescOutput(string.format("<p>%s</p>", _tImportState.sActiveLine));
	end

	return true;
end

function handleSubraceHeader()
	-- In MotM, the subrace is proceeded by a "<Subrace> Traits" header; but in PHB, it's only subrace
	-- Assume Subrace name is of form "<words> <race>" (i.e. High Elf, Wood Elf, Mountain Dwarf)
	-- 		This assumption does not hold for certain races (Sverfniblin), which will have to be entered manually
	local sTrimmedLine = StringManager.trim(StringManager.trim(_tImportState.sActiveLine):lower():gsub("traits$", ""));
	local sSubracePattern = _tImportState.sRaceName:lower() .. "$";
	if not sTrimmedLine:match(sSubracePattern) then
		return false;
	end
	local tSplit = StringManager.splitWords(sTrimmedLine);
	if #tSplit ~= 2 then
		return false;
	end

	local sSubraceName = StringManager.capitalizeAll(sTrimmedLine);
	if (sSubraceName or "") == "" then
		return false;
	end

	ImportRaceManager.setSubrace(sSubraceName);
	return true;
end

-- This function tries to determine whether or not the value is a heading for a Traits section.
-- s = the string to check
function isTraitHeading(s)
	-- Avoid empty strings
	if (s or "") == "" then
		return false;
	end

	-- Avoid initials in descriptive text (i.e. traits must be at least 3 letters plus the punctuation)
	if #s < 4 then
		return false;
	end

	-- look for replacements of of, and, the
	sTestValue = StringManager.trim(s);
	sTestValue = sTestValue:gsub(" of ", "");
	sTestValue = sTestValue:gsub(" to ", "");
	sTestValue = sTestValue:gsub(" from ", "");
	sTestValue = sTestValue:gsub(" and ", "");
	sTestValue = sTestValue:gsub(" the ", "");
	sTestValue = sTestValue:gsub(" with ", "");

	if sTestValue == StringManager.capitalizeAll(sTestValue) then
		return true;
	else
		-- if there are only 3 words, this is very likely a header
		local tSplit = StringManager.splitWords(sTestValue);
		if #tSplit <= 4 then
			return true;
		else
			if #tSplit < 6 then
				-- we believe this is not a header... but we let the user know just in case
				-- so they can manually clean it up.
				ChatManager.SystemMessage(s .. " was not identified as a header. Headers are either in Proper Case format or less than 4 words, with a period afterward. Words=" .. #tSplit);
			end
			
			-- This is not a header
			return false;
		end
	end
end

function initImportState(sDesc)
	_tImportState = {};

	local sCleanDesc = ImportUtilityManager.cleanUpText(sDesc);
	_tImportState.nLine = 0;
	_tImportState.tLines = ImportUtilityManager.parseFormattedTextToLines(sCleanDesc);
	_tImportState.sActiveLine = "";

	_tImportState.sDescription = sCleanDesc;
	
	_tImportState.sRaceName = "";
	_tImportState.tRaceDesc = {};

	_tImportState.tSubraceList = {};
	_tImportState.nodeActiveSubrace = nil;
	_tImportState.tActiveSubraceDesc = {};

	_tImportState.sTraitName = "";
	_tImportState.tTraitDesc = {};

	local sRootMapping = LibraryData.getRootMapping("race");
	_tImportState.node = DB.createChild(sRootMapping);
end

function nextImportLine(nAdvance)
	_tImportState.nLine = _tImportState.nLine + (nAdvance or 1);
	_tImportState.sActiveLine = _tImportState.tLines[_tImportState.nLine];
end

function peekImportLine(nAdvance)
	return _tImportState.tLines[_tImportState.nLine + (nAdvance or 1)];
end

function addDescOutput(s)
	if (s or "") == "" then
		return;
	end

	if (_tImportState.sTraitName or "") ~= "" then
		table.insert(_tImportState.tTraitDesc, s);
	elseif _tImportState.nodeActiveSubrace then
		table.insert(_tImportState.tActiveSubraceDesc, s);
	else
		table.insert(_tImportState.tRaceDesc, s);
	end
end

function finalizeDescription(s)
	ImportRaceManager.finalizeSubraceDescription();

	local tFinalDesc = {};
	local sText = table.concat(_tImportState.tRaceDesc);
	table.insert(tFinalDesc, sText);

	if #(_tImportState.tSubraceList) > 0 then
		local sDisplayClass = LibraryData.getRecordDisplayClass("race_subrace");
		table.insert(tFinalDesc, "<h>Subraces</h>");
		table.insert(tFinalDesc, "<linklist>");
		for _,v in ipairs(_tImportState.tSubraceList) do
			local sLink = string.format("<link class=\"%s\" recordname=\"%s\">%s</link>", sDisplayClass, DB.getPath(v.node), v.sName);
			table.insert(tFinalDesc, sLink);
		end
		table.insert(tFinalDesc, "</linklist>");
	end

	DB.setValue(_tImportState.node, "text", "formattedtext", table.concat(tFinalDesc));
end

function setTraitData(sName)
	_tImportState.sTraitName = sName;
	_tImportState.tTraitDesc = {};
end

function finalizeTrait()
	if (_tImportState.sTraitName or "") == "" then
		return;
	end

	local nodeGroup = DB.createChild(_tImportState.nodeActiveSubrace or _tImportState.node, "traits");
	local node = DB.createChild(nodeGroup, StringManager.simplify(_tImportState.sTraitName));
	if _tImportState.sTraitName:match("%.$") then
		DB.setValue(node, "name", "string", _tImportState.sTraitName:sub(1, -2));
	else
		DB.setValue(node, "name", "string", _tImportState.sTraitName);
	end
	local sDesc = table.concat(_tImportState.tTraitDesc);
	DB.setValue(node, "text", "formattedtext", sDesc);

	local sOutputDesc = string.format("<p><b><i>%s</i></b> %s</p>", _tImportState.sTraitName, table.concat(_tImportState.tTraitDesc):gsub("^<p>", ""):gsub("</p>$", ""));
	_tImportState.sTraitName = "";
	_tImportState.tTraitDesc = {};
	ImportRaceManager.addDescOutput(sOutputDesc);
end

function setSubrace(sSubraceName)
	if (sSubraceName or "") == "" then
		return;
	end

	ImportRaceManager.finalizeTrait();
	ImportRaceManager.finalizeSubraceDescription();

	_tImportState.sSubraceName = sSubraceName;
	local sRootMapping = LibraryData.getRootMapping("race_subrace");
	_tImportState.nodeActiveSubrace = DB.createChild(sRootMapping);
	DB.setValue(_tImportState.nodeActiveSubrace, "name", "string", sSubraceName);
	DB.setValue(_tImportState.nodeActiveSubrace, "race", "string", _tImportState.sRaceName);
	DB.setValue(_tImportState.nodeActiveSubrace, "text", "formattedtext", "");
	_tImportState.tActiveSubraceDesc = {};
	DB.createChild(_tImportState.nodeActiveSubrace, "traits");

	table.insert(_tImportState.tSubraceList, { sName = sSubraceName, node = _tImportState.nodeActiveSubrace });

	_tImportState.sTraitName = "";
	_tImportState.tTraitDesc = {};
end

function finalizeSubraceDescription()
	if _tImportState.nodeActiveSubrace then
		local sText = table.concat(_tImportState.tActiveSubraceDesc);
		DB.setValue(_tImportState.nodeActiveSubrace, "text", "formattedtext", sText);
	end
end
