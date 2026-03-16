--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onTabletopInit()
	ImportUtilityManager.registerImportMode("item", "2024", Interface.getString("import_mode_2024"), ImportItemManager.import2024);
end

function performImport(w)
	local tImportMode = ImportUtilityManager.getImportMode("item", w.mode.getSelectedValue());
	if tImportMode then
		tImportMode.fn(w.listdata.getValue(), w.description.getValue());
	end
end

--
--	Built-in supported import modes
--

function import2024(sList, sDesc)
	-- Track state information
	local tImportList = {};
	local tImportDescriptions = {};

	-- Add line break after every </h> tag
	sDesc = sDesc:gsub("</h>", "</h>\n")

	-- Clean up the input lists
	sList = sList:gsub("½", ".5");
	local sItemList = ImportUtilityManager.cleanUpText(sList);
	tImportList.nLine = 0;
	tImportList.tLines = ImportUtilityManager.parseFormattedTextToLines(sItemList);
	tImportList.sActiveLine = "";

	local sItemDesc = sDesc;
	tImportDescriptions.nLine = 0;
	tImportDescriptions.tLines = ImportUtilityManager.parseFormattedTextToLines(sItemDesc);
	tImportDescriptions.sActiveLine = "";

	-- Read the first line of the stats to get the item type
	ImportItemManager.nextImportLine(tImportList);
	local sItemType = tImportList.sActiveLine;

	-- Read the 2nd line of the List to get the Subtype
	ImportItemManager.nextImportLine(tImportList);
	local sItemSubType = tImportList.sActiveLine;

	-- Read the 3rd line of the List to get the data columns from a pipe-delimited string
	ImportItemManager.nextImportLine(tImportList);
	local sColumnNames = tImportList.sActiveLine;
	sColumnNames = (sColumnNames or ""):gsub("name", "Name");
	local columnNames = StringManager.splitByPattern(sColumnNames, "|", true);

	-- Table to store the parsed data
	local tParsedData = {};
	while ImportItemManager.nextImportLine(tImportList) do
		local rowValues = StringManager.splitByPattern(tImportList.sActiveLine, "|", true);

		-- Check if the first column value exists to use as a key
		local key = rowValues[1];
		if key then
			tParsedData[key:lower()] = {};
			for i, columnName in ipairs(columnNames) do
				tParsedData[key:lower()][columnName:lower()] = rowValues[i];
			end
		end
	end

	-- Process descriptions to match with items
	local currentItemName = nil;
	local currentItemDesc = "";
	while ImportItemManager.nextImportLine(tImportDescriptions) do
		local line = tImportDescriptions.sActiveLine;

		-- Check if the line is a heading or an item name
		if line:match("^<h>(.-)%s*%(.+%)</h>$") or line:match("^<h>(.-)</h>$") or line:match("^[^<]+$") then
			-- If there's an active item, save its description
			if currentItemName and tParsedData[currentItemName] then
				tParsedData[currentItemName]["description"] = currentItemDesc;
				currentItemDesc = "";
			end

			-- Extract the item name, ignoring text in parentheses
			currentItemName = line:match("^<h>(.-)%s*%(.+%)</h>$") or line:match("^<h>(.-)</h>$") or line:match("^[^<]+$");
			currentItemName = currentItemName:gsub("%s*%(.+%)", ""):lower();
		else
			-- Append the line to the current item description
			currentItemDesc = currentItemDesc .. line .. "</p><p>\n";
		end
	end

	-- Ensure the last item description is saved
	if currentItemName and tParsedData[currentItemName] then
		tParsedData[currentItemName]["description"] = currentItemDesc;
	end

	-- Create item records for each item
	local sRootMapping = LibraryData.getRootMapping("item");
	for _,value in pairs(tParsedData) do
		local nodeItem = DB.createChild(sRootMapping);
		DB.setValue(nodeItem, "type", "string", sItemType);
		DB.setValue(nodeItem, "subtype", "string", sItemSubType);
		DB.setValue(nodeItem, "rarity", "string", "common");
		DB.setValue(nodeItem, "version", "string", "2024");

		for columnName, columnValue in pairs(value) do
			if columnName == "weight" then
				local numericValue = columnValue:match("%d+%.?%d*") or "0"
				DB.setValue(nodeItem, columnName, "number", numericValue);
			elseif columnName == "ac" then
				local numericValue = columnValue:match("%d+%.?%d*") or "0"
				DB.setValue(nodeItem, columnName, "number", numericValue);
			elseif columnName == "bonus" then
				local numericValue = columnValue:match("%d+%.?%d*") or "0"
				DB.setValue(nodeItem, columnName, "number", numericValue);
			elseif columnName == "description" then
				columnValue = ImportItemManager.closeOpenTags(columnValue)
				DB.setValue(nodeItem, "description", "formattedtext", columnValue);
			else
				DB.setValue(nodeItem, columnName, "string", StringManager.trim(columnValue));
			end
		end
	end
end

--
--	Import state identification and tracking
--

function nextImportLine(tImportState, nAdvance)
	tImportState.nLine = tImportState.nLine + (nAdvance or 1);
	if tImportState.nLine <= #tImportState.tLines then
		tImportState.sActiveLine = tImportState.tLines[tImportState.nLine];
		return true;
	else
		tImportState.sActiveLine = nil;
		return false;
	end
end

function closeOpenTags(s)
	local tagStack = {}
	local closedString = ""
	local lastIndex = 1

	-- Iterate through the string to find tags
	while true do
		local startIndex, endIndex, tag, tagName = s:find("<(/?)(%w+)[^>]*>", lastIndex)
		if not startIndex then
			break
		end

		-- Handle the tags and text between them
		closedString = closedString .. s:sub(lastIndex, startIndex - 1)
		if tag == "/" then
			-- If this is a closing tag, pop from stack if it matches the last opened tag
			if #tagStack > 0 and tagStack[#tagStack] == tagName then
				table.remove(tagStack)
			end
		else
			-- This is an opening tag, add to stack
			table.insert(tagStack, tagName)
		end
		closedString = closedString .. s:sub(startIndex, endIndex)
		lastIndex = endIndex + 1
	end

	-- Add remaining string part
	closedString = closedString .. s:sub(lastIndex)

	-- Close any unclosed tags
	for i = #tagStack, 1, -1 do
		closedString = closedString .. "</" .. tagStack[i] .. ">"
	end

	return closedString
end
