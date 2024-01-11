-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

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
	local tImportState = ImportRaceManager.initImportState(sDesc);

	-- Assume name on Line 1
	ImportRaceManager.importHelperName(tImportState);
	
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
	ImportRaceManager.nextImportLine(tImportState);
	while tImportState.sActiveLine do

		if ImportRaceManager.handleRaceTraitsHeader(tImportState) then
			-- Handled

		elseif ImportRaceManager.handleSubraceHeader(tImportState) then
			-- Handled

		else
			-- Look for a feature heading. It should be proper cased and end in a period.
			-- If it is multiple words, then each word should begin with a capitalization.
			local sHeading, sRemainder = tImportState.sActiveLine:match("([^.!]+[.!])%s(.*)")
			if ImportRaceManager.isTraitHeading(sHeading) then
				ImportRaceManager.finalizeTrait(tImportState);
				ImportRaceManager.setTraitData(tImportState, StringManager.trim(sHeading));
				ImportRaceManager.addDescOutput(tImportState, string.format("<p>%s</p>", StringManager.trim(sRemainder)));
			else
				ImportRaceManager.addDescOutput(tImportState, string.format("<p>%s</p>", tImportState.sActiveLine));
			end
		end

		ImportRaceManager.nextImportLine(tImportState);
	end

	-- Finalize all traits
	ImportRaceManager.finalizeTrait(tImportState);
	
	-- Description
	ImportRaceManager.finalizeDescription(tImportState);
	
	-- Open new record window and matching campaign list
	ImportUtilityManager.showRecord("race", tImportState.node);
	for _,v in ipairs(tImportState.tSubraceList) do
		ImportUtilityManager.showRecord("race_subrace", v.node);
	end
end

--
--	Import section helper functions
--

-- Assumes name is on next line
function importHelperName(tImportState)
	-- Name
	ImportRaceManager.nextImportLine(tImportState);
	tImportState.sRaceName = StringManager.trim(tImportState.sActiveLine);
	DB.setValue(tImportState.node, "name", "string", tImportState.sRaceName);
end

--
--	Import state identification and tracking
--

function handleRaceTraitsHeader(tImportState)
	if tImportState.nodeSubrace then
		return false;
	end

	-- look for a line that starts the Traits section
	local sTraitHeaderPattern = "^" .. tImportState.sRaceName:lower() .. "%s+traits$";
	if not StringManager.trim(tImportState.sActiveLine):lower():match(sTraitHeaderPattern) then
		return false;
	end

	ImportRaceManager.addDescOutput(tImportState, string.format("<h>%s</h>", tImportState.sActiveLine));

	-- skip the next line if it is a generic line like this
		-- example: As a bugbear, you have the following racial traits.
	local sNextLine = ImportRaceManager.peekImportLine(tImportState);
	if sNextLine and sNextLine:match("traits%.$") then
		ImportRaceManager.nextImportLine(tImportState);
		ImportRaceManager.addDescOutput(tImportState, string.format("<p>%s</p>", tImportState.sActiveLine));
	end

	return true;
end

function handleSubraceHeader(tImportState)
	-- In MotM, the subrace is proceeded by a "<Subrace> Traits" header; but in PHB, it's only subrace
	-- Assume Subrace name is of form "<words> <race>" (i.e. High Elf, Wood Elf, Mountain Dwarf)
	-- 		This assumption does not hold for certain races (Sverfniblin), which will have to be entered manually
	local sTrimmedLine = StringManager.trim(StringManager.trim(tImportState.sActiveLine):lower():gsub("traits$", ""));
	local sSubracePattern = tImportState.sRaceName:lower() .. "$";
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

	ImportRaceManager.setSubrace(tImportState, sSubraceName);
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
	local tImportState = {};

	local sCleanDesc = ImportUtilityManager.cleanUpText(sDesc);
	tImportState.nLine = 0;
	tImportState.tLines = ImportUtilityManager.parseFormattedTextToLines(sCleanDesc);
	tImportState.sActiveLine = "";

	tImportState.sDescription = sCleanDesc;
	
	tImportState.sRaceName = "";
	tImportState.tRaceDesc = {};

	tImportState.tSubraceList = {};
	tImportState.nodeActiveSubrace = nil;
	tImportState.tActiveSubraceDesc = {};

	tImportState.sTraitName = "";
	tImportState.tTraitDesc = {};

	local sRootMapping = LibraryData.getRootMapping("race");
	tImportState.node = DB.createChild(sRootMapping);

	return tImportState;
end

function nextImportLine(tImportState, nAdvance)
	tImportState.nLine = tImportState.nLine + (nAdvance or 1);
	tImportState.sActiveLine = tImportState.tLines[tImportState.nLine];
end

function peekImportLine(tImportState, nAdvance)
	return tImportState.tLines[tImportState.nLine + (nAdvance or 1)];
end

function addDescOutput(tImportState, s)
	if (s or "") == "" then
		return;
	end

	if (tImportState.sTraitName or "") ~= "" then
		table.insert(tImportState.tTraitDesc, s);
	elseif tImportState.nodeActiveSubrace then
		table.insert(tImportState.tActiveSubraceDesc, s);
	else
		table.insert(tImportState.tRaceDesc, s);
	end
end

function finalizeDescription(tImportState, s)
	ImportRaceManager.finalizeSubraceDescription(tImportState);

	local tFinalDesc = {};
	local sText = table.concat(tImportState.tRaceDesc);
	table.insert(tFinalDesc, sText);

	if #(tImportState.tSubraceList) > 0 then
		local sDisplayClass = LibraryData.getRecordDisplayClass("race_subrace");
		table.insert(tFinalDesc, "<h>Subraces</h>");
		table.insert(tFinalDesc, "<linklist>");
		for _,v in ipairs(tImportState.tSubraceList) do
			local sLink = string.format("<link class=\"%s\" recordname=\"%s\">%s</link>", sDisplayClass, DB.getPath(v.node), v.sName);
			table.insert(tFinalDesc, sLink);
		end
		table.insert(tFinalDesc, "</linklist>");
	end

	DB.setValue(tImportState.node, "text", "formattedtext", table.concat(tFinalDesc));
end

function setTraitData(tImportState, sName)
	tImportState.sTraitName = sName;
	tImportState.tTraitDesc = {};
end

function finalizeTrait(tImportState)
	if (tImportState.sTraitName or "") == "" then
		return;
	end

	local nodeGroup = DB.createChild(tImportState.nodeActiveSubrace or tImportState.node, "traits");
	local node = DB.createChild(nodeGroup, StringManager.simplify(tImportState.sTraitName));
	if tImportState.sTraitName:match("%.$") then
		DB.setValue(node, "name", "string", tImportState.sTraitName:sub(1, -2));
	else
		DB.setValue(node, "name", "string", tImportState.sTraitName);
	end
	local sDesc = table.concat(tImportState.tTraitDesc);
	DB.setValue(node, "text", "formattedtext", sDesc);

	local sOutputDesc = string.format("<p><b><i>%s</i></b> %s</p>", tImportState.sTraitName, table.concat(tImportState.tTraitDesc):gsub("^<p>", ""):gsub("</p>$", ""));
	tImportState.sTraitName = "";
	tImportState.tTraitDesc = {};
	ImportRaceManager.addDescOutput(tImportState, sOutputDesc);
end

function setSubrace(tImportState, sSubraceName)
	if (sSubraceName or "") == "" then
		return;
	end

	ImportRaceManager.finalizeTrait(tImportState);
	ImportRaceManager.finalizeSubraceDescription(tImportState);

	tImportState.sSubraceName = sSubraceName;
	local sRootMapping = LibraryData.getRootMapping("race_subrace");
	tImportState.nodeActiveSubrace = DB.createChild(sRootMapping);
	DB.setValue(tImportState.nodeActiveSubrace, "name", "string", sSubraceName);
	DB.setValue(tImportState.nodeActiveSubrace, "race", "string", tImportState.sRaceName);
	DB.setValue(tImportState.nodeActiveSubrace, "text", "formattedtext", "");
	tImportState.tActiveSubraceDesc = {};
	DB.createChild(tImportState.nodeActiveSubrace, "traits");

	table.insert(tImportState.tSubraceList, { sName = sSubraceName, node = tImportState.nodeActiveSubrace });

	tImportState.sTraitName = "";
	tImportState.tTraitDesc = {};
end

function finalizeSubraceDescription(tImportState)
	if tImportState.nodeActiveSubrace then
		local sText = table.concat(tImportState.tActiveSubraceDesc);
		DB.setValue(tImportState.nodeActiveSubrace, "text", "formattedtext", sText);
	end
end
