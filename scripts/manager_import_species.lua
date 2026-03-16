--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onTabletopInit()
	ImportUtilityManager.registerImportMode("species", "2022", Interface.getString("import_mode_2022"), ImportSpeciesManager.import2022);
end

function performImport(w)
	local tImportMode = ImportUtilityManager.getImportMode("species", w.mode.getSelectedValue());
	if tImportMode then
		tImportMode.fn(w.description.getValue());
	end
end

--
--	Built-in supported import modes
--

function import2022(sDesc)
	-- Track state information
	local tImportState = ImportSpeciesManager.initImportState(sDesc);

	-- Assume name on Line 1
	ImportSpeciesManager.importHelperName(tImportState);

	-- Species normally start off with a descriptive text section.
	-- These lines are read in and ignored until you reach the Traits section.
		-- Syntax:
		-- [Species Name] Traits
		-- [Ancestry Name] Traits
		-- Examples of a species (Aasimar) with no ancestries
		-- Aasimar Traits
		-- Example of a species (Genasi) with 4 different ancestries
		-- Genasi Traits
		-- Air Genasi Traits
		-- Earth Genasi Traits
		-- Fire Genasi Traits
		-- Water Genasi Traits
	ImportSpeciesManager.nextImportLine(tImportState);
	while tImportState.sActiveLine do

		if ImportSpeciesManager.handleSpeciesTraitsHeader(tImportState) then
			-- Handled

		elseif ImportSpeciesManager.handleAncestryHeader(tImportState) then
			-- Handled

		else
			-- Look for a feature heading. It should be proper cased and end in a period.
			-- If it is multiple words, then each word should begin with a capitalization.
			local sHeading, sRemainder = tImportState.sActiveLine:match("([^.!]+[.!])%s(.*)")
			if ImportSpeciesManager.isTraitHeading(sHeading) then
				ImportSpeciesManager.finalizeTrait(tImportState);
				ImportSpeciesManager.setTraitData(tImportState, StringManager.trim(sHeading));
				ImportSpeciesManager.addDescOutput(tImportState, string.format("<p>%s</p>", StringManager.trim(sRemainder)));
			else
				ImportSpeciesManager.addDescOutput(tImportState, string.format("<p>%s</p>", tImportState.sActiveLine));
			end
		end

		ImportSpeciesManager.nextImportLine(tImportState);
	end

	-- Finalize all traits
	ImportSpeciesManager.finalizeTrait(tImportState);

	-- Description
	ImportSpeciesManager.finalizeDescription(tImportState);

	-- Open new record window and matching campaign list
	ImportUtilityManager.showRecord("race", tImportState.node);
	for _,v in ipairs(tImportState.tAncestryList) do
		ImportUtilityManager.showRecord("race_subrace", v.node);
	end
end

--
--	Import section helper functions
--

-- Assumes name is on next line
function importHelperName(tImportState)
	-- Name
	ImportSpeciesManager.nextImportLine(tImportState);
	tImportState.sSpeciesName = StringManager.trim(tImportState.sActiveLine);
	DB.setValue(tImportState.node, "name", "string", tImportState.sSpeciesName);
end

--
--	Import state identification and tracking
--

function handleSpeciesTraitsHeader(tImportState)
	if tImportState.nodeAncestry then
		return false;
	end

	-- look for a line that starts the Traits section
	local sTraitHeaderPattern = "^" .. tImportState.sSpeciesName:lower() .. "%s+traits$";
	if not StringManager.trim(tImportState.sActiveLine):lower():match(sTraitHeaderPattern) then
		return false;
	end

	ImportSpeciesManager.addDescOutput(tImportState, string.format("<h>%s</h>", tImportState.sActiveLine));

	-- skip the next line if it is a generic line like this
		-- example: As a bugbear, you have the following racial traits.
	local sNextLine = ImportSpeciesManager.peekImportLine(tImportState);
	if sNextLine and sNextLine:match("traits%.$") then
		ImportSpeciesManager.nextImportLine(tImportState);
		ImportSpeciesManager.addDescOutput(tImportState, string.format("<p>%s</p>", tImportState.sActiveLine));
	end

	return true;
end

function handleAncestryHeader(tImportState)
	-- In MotM, the ancestry is proceeded by a "<Ancestry> Traits" header; but in PHB, it's only ancestry
	-- Assume Ancestry name is of form "<words> <species>" (i.e. High Elf, Wood Elf, Mountain Dwarf)
	-- 		This assumption does not hold for certain species (Sverfniblin), which will have to be entered manually
	local sTrimmedLine = StringManager.trim(StringManager.trim(tImportState.sActiveLine):lower():gsub("traits$", ""));
	local sAncestryPattern = tImportState.sSpeciesName:lower() .. "$";
	if not sTrimmedLine:match(sAncestryPattern) then
		return false;
	end
	local tSplit = StringManager.splitWords(sTrimmedLine);
	if #tSplit ~= 2 then
		return false;
	end

	local sAncestryName = StringManager.capitalizeAll(sTrimmedLine);
	if (sAncestryName or "") == "" then
		return false;
	end

	ImportSpeciesManager.setAncestry(tImportState, sAncestryName);
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
	local sTestValue = StringManager.trim(s);
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

	tImportState.sSpeciesName = "";
	tImportState.tSpeciesDesc = {};

	tImportState.tAncestryList = {};
	tImportState.nodeActiveAncestry = nil;
	tImportState.tActiveAncestryDesc = {};

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
	elseif tImportState.nodeActiveAncestry then
		table.insert(tImportState.tActiveAncestryDesc, s);
	else
		table.insert(tImportState.tSpeciesDesc, s);
	end
end

function finalizeDescription(tImportState)
	ImportSpeciesManager.finalizeAncestryDescription(tImportState);

	local tFinalDesc = {};
	local sText = table.concat(tImportState.tSpeciesDesc);
	table.insert(tFinalDesc, sText);

	if #(tImportState.tAncestryList) > 0 then
		local sDisplayClass = LibraryData.getRecordDisplayClass("race_subrace");
		table.insert(tFinalDesc, "<h>Subraces</h>");
		table.insert(tFinalDesc, "<linklist>");
		for _,v in ipairs(tImportState.tAncestryList) do
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

	local nodeGroup = DB.createChild(tImportState.nodeActiveAncestry or tImportState.node, "traits");
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
	ImportSpeciesManager.addDescOutput(tImportState, sOutputDesc);
end

function setAncestry(tImportState, sAncestryName)
	if (sAncestryName or "") == "" then
		return;
	end

	ImportSpeciesManager.finalizeTrait(tImportState);
	ImportSpeciesManager.finalizeAncestryDescription(tImportState);

	tImportState.sAncestryName = sAncestryName;
	local sRootMapping = LibraryData.getRootMapping("race_subrace");
	tImportState.nodeActiveAncestry = DB.createChild(sRootMapping);
	DB.setValue(tImportState.nodeActiveAncestry, "name", "string", sAncestryName);
	DB.setValue(tImportState.nodeActiveAncestry, "race", "string", tImportState.sSpeciesName);
	DB.setValue(tImportState.nodeActiveAncestry, "text", "formattedtext", "");
	tImportState.tActiveAncestryDesc = {};
	DB.createChild(tImportState.nodeActiveAncestry, "traits");

	table.insert(tImportState.tAncestryList, { sName = sAncestryName, node = tImportState.nodeActiveAncestry });

	tImportState.sTraitName = "";
	tImportState.tTraitDesc = {};
end

function finalizeAncestryDescription(tImportState)
	if tImportState.nodeActiveAncestry then
		local sText = table.concat(tImportState.tActiveAncestryDesc);
		DB.setValue(tImportState.nodeActiveAncestry, "text", "formattedtext", sText);
	end
end
