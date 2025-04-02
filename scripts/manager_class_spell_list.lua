--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	Interface.addKeyedEventHandler("onLinkActivate", "class_spell_view", ClassSpellListManager.handleSpellViewLink);

	ExportManager.registerPreExportCallback(ClassSpellListManager.callbackSetupCSLViews);
	ExportManager.registerPostExportCallback(ClassSpellListManager.callbackAddCSLViews);
end
function onClose()
	if ClassSpellListManager.isInitialized() then
		ClassSpellListManager.removeSpellRecordHandlers();
		ClassSpellListManager.removeClassSpellListRecordHandlers();
	end
end

-- NOTE:
--		Most spell list names are simply words, with optional parentheses.
--		The original code used a simplify function that stripped out the extra characters.
--		However, the name keys are used to generate XML tags, so must be XML tag encoded.
--		But, the tags need to maintain a semblance of the simplify behavior for backward compatibility
--		So, we will encode the XML tag after applying part of the simplify logic (stripping spaces and parentheses and making lower case)
function generateNameKey(sName)
	return UtilityManager.encodeXMLTag(sName:gsub("[%s%(%)]", ""):lower());
end

function getClassSpellListViewRecord(sClassName)
	local tRecord = ClassSpellListManager.getClassSpellListRecord(sClassName);

	local rList = {};
	if tRecord then
		rList.sTitle = string.format("%s %s", tRecord.sName, Interface.getString("title_class_spell_view"));
	else
		rList.sTitle = string.format("Unknown %s", Interface.getString("title_class_spell_view"));
	end
	rList.aColumns = {
		{ sName = "name", sType = "string", sHeadingRes = "spell_view_grouped_label_name", nWidth=150, bWrapped=true, },
		{ sName = "castingtime", sType = "custom", sCustomKey = "spell_view_castingtime", sHeadingRes = "spell_view_grouped_label_castingtime", nWidth=100, },
		{ sName = "duration", sType = "string", sHeadingRes = "spell_view_grouped_label_duration", nWidth=100, bWrapped=true, },
		{ sName = "range", sType = "string", sHeadingRes = "spell_view_grouped_label_range", nWidth=150, bWrapped=true, },
	};
	rList.aGroups = { { sDBField = "level", sCustom = "spell_view_level_group" } };
	rList.aGroupValueOrder = { "Cantrips" };
	if tRecord then
		rList.aRecordList = tRecord.tSpells;
	else
		rList.aRecordList = {};
	end
	rList.sDisplayClass = "power";

	return rList;
end

--
--	INTERNAL
--

local _initialized = false;
function isInitialized()
	return _initialized;
end
function setInitialized(bValue)
	_initialized = bValue;
end

--
--	SPELL RECORD HANDLING
--

local _tSpellRecords = {};

function addSpellRecordHandlers()
	local function addSpellHandlerHelper(sMapping)
		local sPath = DB.getPath(sMapping);
		local sChildPath = sPath .. ".*@*";
		DB.addHandler(sChildPath, "onAdd", ClassSpellListManager.onSpellAdded);
		DB.addHandler(sChildPath, "onDelete", ClassSpellListManager.onSpellDeleted);
		DB.addHandler(DB.getPath(sChildPath, "name"), "onUpdate", ClassSpellListManager.onSpellNameChange);
		DB.addHandler(DB.getPath(sChildPath, "source"), "onUpdate", ClassSpellListManager.onSpellSourceChange);
	end

	local vNodes = LibraryData.getMappings("spell");
	for i = 1, #vNodes do
		addSpellHandlerHelper(vNodes[i]);
	end
end
function removeSpellRecordHandlers()
	local function removeSpellHandlerHelper(sMapping)
		local sPath = DB.getPath(sMapping);
		local sChildPath = sPath .. ".*@*";
		DB.removeHandler(sChildPath, "onAdd", ClassSpellListManager.onSpellAdded);
		DB.removeHandler(sChildPath, "onDelete", ClassSpellListManager.onSpellDeleted);
		DB.removeHandler(DB.getPath(sChildPath, "name"), "onUpdate", ClassSpellListManager.onSpellNameChange);
		DB.removeHandler(DB.getPath(sChildPath, "source"), "onUpdate", ClassSpellListManager.onSpellSourceChange);
	end

	local vNodes = LibraryData.getMappings("spell");
	for i = 1, #vNodes do
		removeSpellHandlerHelper(vNodes[i]);
	end
end

function rebuildSpellRecords()
	_tSpellRecords = {};
	RecordManager.callForEachRecord("spell", ClassSpellListManager.helperAddSpellRecord);

	ClassSpellListManager.onClassSpellListUpdate();
end
function onSpellAdded(vNode)
	ClassSpellListManager.helperAddSpellRecord(vNode);
	ClassSpellListManager.onClassSpellListUpdate();
end
function onSpellDeleted(vNode)
	ClassSpellListManager.helperRemoveSpellRecord(vNode);
	ClassSpellListManager.onClassSpellListUpdate();
end
function onSpellNameChange(vNode)
	local nodeSpell = DB.getChild(vNode, "..");
	ClassSpellListManager.helperUpdateSpellName(nodeSpell, _tSpellRecords[nodeSpell]);
	ClassSpellListManager.onClassSpellListUpdate();
end
function onSpellSourceChange(vNode)
	local nodeSpell = DB.getChild(vNode, "..");
	ClassSpellListManager.helperUpdateSpellSources(nodeSpell, _tSpellRecords[nodeSpell]);
	ClassSpellListManager.onClassSpellListUpdate();
end

function helperAddSpellRecord(nodeSpell)
	local rRecord = {};
	rRecord.vNode = nodeSpell;

	ClassSpellListManager.helperUpdateSpellName(nodeSpell, rRecord);
	ClassSpellListManager.helperUpdateSpellSources(nodeSpell, rRecord);

	_tSpellRecords[nodeSpell] = rRecord;
end
function helperRemoveSpellRecord(nodeSpell)
	if _tSpellRecords[nodeSpell] then
		_tSpellRecords[nodeSpell] = nil;
	end
end
function helperUpdateSpellName(nodeSpell, rRecord)
	if not nodeSpell or not rRecord then
		return;
	end

	rRecord.sDisplayName = DB.getValue(nodeSpell, "name", "");
	rRecord.sDisplayNameLower = rRecord.sDisplayName:lower();
end
function helperUpdateSpellSources(nodeSpell, rRecord)
	if not rRecord then
		return;
	end

	rRecord.tSources = ClassSpellListManager.helperGetSpellSources(nodeSpell);
end
function helperGetSpellSources(nodeSpell)
	local tSources = {};
	if nodeSpell then
		local tSplit = StringManager.split(DB.getValue(nodeSpell, "source", ""), ",", true);
		for _,v in ipairs(tSplit) do
			if v ~= "" then
				table.insert(tSources, v);
			end
		end
	end
	return tSources;
end

--
--	CLASS SPELL LIST RECORD HANDLING
--

local _tClassSpellListRecords = {};

function addClassSpellListRecordHandlers()
	local function addClassSpellListHandlerHelper(sMapping)
		local sPath = DB.getPath(sMapping);
		local sChildPath = sPath .. ".*@*";
		DB.addHandler(sChildPath, "onAdd", ClassSpellListManager.onClassSpellListAdded);
		DB.addHandler(sChildPath, "onDelete", ClassSpellListManager.onClassSpellListDeleted);
		DB.addHandler(DB.getPath(sChildPath, "name"), "onUpdate", ClassSpellListManager.onClassSpellListNameChange);
		local sSpellItemListPath = sPath .. ".*.spells@*";
		DB.addHandler(sSpellItemListPath, "onChildDeleted", ClassSpellListManager.onClassSpellListItemDeleted);
		local sSpellItemPath = sPath .. ".*.spells.*@*";
		DB.addHandler(DB.getPath(sSpellItemPath, "name"), "onUpdate", ClassSpellListManager.onClassSpellListItemNameChange);
	end

	local vNodes = LibraryData.getMappings("class_spell_list");
	for i = 1, #vNodes do
		addClassSpellListHandlerHelper(vNodes[i]);
	end
end
function removeClassSpellListRecordHandlers()
	local function removeClassSpellListHandlerHelper(sMapping)
		local sPath = DB.getPath(sMapping);
		local sChildPath = sPath .. ".*@*";
		DB.removeHandler(sChildPath, "onAdd", ClassSpellListManager.onClassSpellListAdded);
		DB.removeHandler(sChildPath, "onDelete", ClassSpellListManager.onClassSpellListDeleted);
		DB.removeHandler(DB.getPath(sChildPath, "name"), "onUpdate", ClassSpellListManager.onClassSpellListNameChange);
		local sSpellItemListPath = sPath .. ".*.spells@*";
		DB.removeHandler(sSpellItemListPath, "onChildDeleted", ClassSpellListManager.onClassSpellListItemDeleted);
		local sSpellItemPath = sPath .. ".*.spells.*@*";
		DB.removeHandler(DB.getPath(sSpellItemPath, "name"), "onUpdate", ClassSpellListManager.onClassSpellListItemNameChange);
	end

	local vNodes = LibraryData.getMappings("class_spell_list");
	for i = 1, #vNodes do
		removeClassSpellListHandlerHelper(vNodes[i]);
	end
end

function rebuildClassSpellListRecords()
	_tClassSpellListRecords = {};
	RecordManager.callForEachRecord("class_spell_list", ClassSpellListManager.helperAddClassSpellListRecord);

	ClassSpellListManager.onClassSpellListUpdate();
end
function onClassSpellListAdded(vNode)
	ClassSpellListManager.helperAddClassSpellListRecord(vNode);
	ClassSpellListManager.onClassSpellListUpdate();
end
function onClassSpellListDeleted(vNode)
	ClassSpellListManager.helperRemoveClassSpellListRecord(vNode);
	ClassSpellListManager.onClassSpellListUpdate();
end
function onClassSpellListNameChange(vNode)
	local nodeCSL = DB.getChild(vNode, "..");
	ClassSpellListManager.helperUpdateClassSpellListName(nodeCSL, _tClassSpellListRecords[nodeCSL]);
	ClassSpellListManager.onClassSpellListUpdate();
end
function onClassSpellListItemDeleted(vNode)
	local nodeCSL = DB.getChild(vNode, "..");
	ClassSpellListManager.helperUpdateClassSpellListItems(nodeCSL, _tClassSpellListRecords[nodeCSL]);
	ClassSpellListManager.onClassSpellListUpdate();
end
function onClassSpellListItemNameChange(vNode)
	local nodeCSL = DB.getChild(vNode, "....");
	ClassSpellListManager.helperUpdateClassSpellListItems(nodeCSL, _tClassSpellListRecords[nodeCSL]);
	ClassSpellListManager.onClassSpellListUpdate();
end

function helperAddClassSpellListRecord(vNode)
	local rRecord = {};
	rRecord.vNode = vNode;

	ClassSpellListManager.helperUpdateClassSpellListName(vNode, rRecord);
	ClassSpellListManager.helperUpdateClassSpellListItems(vNode, rRecord);

	_tClassSpellListRecords[vNode] = rRecord;
end
function helperRemoveClassSpellListRecord(vNode)
	if _tClassSpellListRecords[vNode] then
		_tClassSpellListRecords[vNode] = nil;
	end
end
function helperUpdateClassSpellListName(vNode, rRecord)
	if not vNode or not rRecord then
		return;
	end

	rRecord.sDisplayName = DB.getValue(vNode, "name", "");
	rRecord.sDisplayNameLower = rRecord.sDisplayName:lower();
end
function helperUpdateClassSpellListItems(vNode, rRecord)
	if not vNode or not rRecord then
		return;
	end

	rRecord.tSpellKeys = {};
	local tDupeCheck = {};
	for _,v in ipairs(DB.getChildList(vNode, "spells")) do
		local sKey = ClassSpellListManager.generateNameKey(DB.getValue(v, "name", ""));
		if (sKey ~= "") and not tDupeCheck[sKey] then
			tDupeCheck[sKey] = true;
			table.insert(rRecord.tSpellKeys, sKey);
		end
	end
end

--
--	SPELL VIEW HANDLING
--

local _tClassSpellLists = {};

function initialize()
	ClassSpellListManager.rebuildSpellRecords();
	ClassSpellListManager.rebuildClassSpellListRecords();

	ClassSpellListManager.addSpellRecordHandlers();
	ClassSpellListManager.addClassSpellListRecordHandlers();

	ClassSpellListManager.setInitialized(true);

	ClassSpellListManager.onClassSpellListUpdate();
end

function rebuildClassSpellLists()
	-- Use temporary table to avoid duplicates
	local tTempSpells = {};
	local tTempClasses = {};

	-- Build information from spell records
	for nodeSpell,vSpellRecord in pairs(_tSpellRecords) do
		local sSpellKey = ClassSpellListManager.generateNameKey(vSpellRecord.sDisplayName);
		if not tTempSpells[sSpellKey] then
			tTempSpells[sSpellKey] = { sName = vSpellRecord.sDisplayName, vNode = nodeSpell };
		end

		for _,sClassName in pairs(vSpellRecord.tSources) do
			local sClassKey = ClassSpellListManager.generateNameKey(sClassName);
			if not tTempClasses[sClassKey] then
				tTempClasses[sClassKey] = { sName = sClassName, tSpellKeySet = {} };
			end

			tTempClasses[sClassKey].tSpellKeySet[sSpellKey] = true;
		end
	end

	-- Build information from class spell list records
	for _,vClassSpellListRecord in pairs(_tClassSpellListRecords) do
		local sClassKey = ClassSpellListManager.generateNameKey(vClassSpellListRecord.sDisplayName);
		if not tTempClasses[sClassKey] then
			tTempClasses[sClassKey] = { sName = vClassSpellListRecord.sDisplayName, tSpellKeySet = {} };
		end

		for _,sSpellKey in ipairs(vClassSpellListRecord.tSpellKeys) do
			tTempClasses[sClassKey].tSpellKeySet[sSpellKey] = true;
		end
	end

	-- Build the final class spell lists
	_tClassSpellLists = {};
	for sClassKey,tTempClass in pairs(tTempClasses) do
		for sSpellKey,_ in pairs(tTempClass.tSpellKeySet) do
			if not _tClassSpellLists[sClassKey] then
				_tClassSpellLists[sClassKey] = { sName = tTempClass.sName, tSpells = {} };
			end
			if (sSpellKey ~= "") and tTempSpells[sSpellKey] then
				table.insert(_tClassSpellLists[sClassKey].tSpells, tTempSpells[sSpellKey].vNode);
			end
		end
	end
end

function getClassesWithSpellList()
	if not ClassSpellListManager.isInitialized() then
		ClassSpellListManager.initialize();
	end

	local tResults = {};
	for _,v in pairs(_tClassSpellLists) do
		table.insert(tResults, v.sName);
	end
	table.sort(tResults);
	return tResults;
end
function getClassSpellListRecord(sClassName)
	if not ClassSpellListManager.isInitialized() then
		ClassSpellListManager.initialize();
	end

	local sClassKey = ClassSpellListManager.generateNameKey(sClassName);
	return _tClassSpellLists[sClassKey];
end

function onClassSpellListUpdate()
	if not ClassSpellListManager.isInitialized() then
		return;
	end

	ClassSpellListManager.rebuildClassSpellLists();

	local w = Interface.findWindow("class_spell_views_index", "");
	if w then
		w.refresh();
	end

	local tSpellViews = Interface.getWindows("class_spell_view");
	for _,wSpellView in ipairs(tSpellViews) do
		wSpellView.refresh();
	end
end

function handleSpellViewLink(sClass, sPath)
	if (sPath or "") == "" then
		return false;
	end

	local w = Interface.openWindow(sClass, "");
	local sPathSansModule = StringManager.split(sPath, "@")[1];
	local tPathSansModule = StringManager.split(sPathSansModule, ".");
	local sClassKey = tPathSansModule[#tPathSansModule];
	w.init(sClassKey);
	return true;
end

--
--	EXPORT
--

local _bCSLExport = false;
local _tCSLViewsToExport = {};
local _tCSLViewNames = {};
function callbackSetupCSLViews(sRecordType, tRecords)
	if sRecordType == "spell" then
		if tRecords then
			for _,sRecord in ipairs(tRecords) do
				ClassSpellListManager.helperCallbackAddCSLViewFromSpell(DB.findNode(sRecord));
			end
		else
			RecordManager.callForEachCampaignRecord(sRecordType, ClassSpellListManager.helperCallbackAddCSLViewFromSpell);
		end
	elseif sRecordType == "class_spell_list" then
		_bCSLExport = true;
		if tRecords then
			for _,sRecord in ipairs(tRecords) do
				ClassSpellListManager.helperCallbackAddCSLViewFromRecord(DB.findNode(sRecord));
			end
		else
			RecordManager.callForEachCampaignRecord(sRecordType, ClassSpellListManager.helperCallbackAddCSLViewFromRecord);
		end
	elseif sRecordType == "" then
		ClassSpellListManager.helperCallbackWriteCSLViews();
	end
end
function helperCallbackAddCSLViewFromSpell(nodeSpell)
	local tSources = ClassSpellListManager.helperGetSpellSources(nodeSpell);
	for _,sClassName in ipairs(tSources) do
		ClassSpellListManager.helperCallbackAddCSLViewName(sClassName);
	end
end
function helperCallbackAddCSLViewFromRecord(nodeCSL)
	local sClassName = StringManager.trim(DB.getValue(nodeCSL, "name", ""));
	ClassSpellListManager.helperCallbackAddCSLViewName(sClassName);
end
function helperCallbackAddCSLViewName(sClassName)
	local sClassKey = ClassSpellListManager.generateNameKey(sClassName);
	if sClassKey ~= "" then
		if not _tCSLViewsToExport[sClassKey] then
			_tCSLViewsToExport[sClassKey] = true;
		end
		if not _tCSLViewNames[sClassKey] then
			_tCSLViewNames[sClassKey] = sClassName;
		end
	end
end
function helperCallbackWriteCSLViews()
	if not _bCSLExport then
		_tCSLViewsToExport = {};
		_tCSLViewNames = {};
		return;
	end

	-- Determine if spell views to export, and sort
	local tCSLViews = {};
	for sClassKey,_ in pairs(_tCSLViewsToExport) do
		table.insert(tCSLViews, sClassKey);
	end
	if #tCSLViews <= 0 then
		_bCSLExport = false;
		_tCSLViewsToExport = {};
		_tCSLViewNames = {};
		return;
	end
	table.sort(tCSLViews);

	-- Setup
	local sLibraryPath = "class_spell_views";
	local sListLabel = Interface.getString("title_class_spell_views");
	local sListClass = "referenceindex";
	local sListPath = "list.class_spell_views";
	local sListEntryClass = "class_spell_view";

	-- Build library link to class spell view list
	local tLibraryEntry = {};
	tLibraryEntry.createstring = { name = sListLabel };
	tLibraryEntry.createlink = { librarylink = { class = sListClass, recordname = sListPath } };
	ExportManager.addExportLibraryEntry(sLibraryPath, tLibraryEntry);

	-- Build top-level list node for spell views
	if not ExportManager.isExportNode("list") then
		ExportManager.setExportNode("list", { static = true });
	end
	local tListTopEntry = {};
	tListTopEntry.createstring = { name = sListLabel };
	ExportManager.setExportNode(sListPath, tListTopEntry);

	-- Add a list entry for each spell view
	for _,sClassKey in ipairs(tCSLViews) do
		local sListEntryPath = string.format("%s.index.%s", sListPath, sClassKey);
		local sListEntryLabel = _tCSLViewNames[sClassKey] or "";
		local sListEntryLinkPath = string.format("class_spell_view.%s@", sClassKey);
		local tListEntry = {};
		tListEntry.createstring = { name = sListEntryLabel };
		tListEntry.createlink = { listlink = { class = sListEntryClass, recordname = sListEntryLinkPath } };
		ExportManager.setExportNode(sListEntryPath, tListEntry);
	end

	_bCSLExport = false;
	_tCSLViewsToExport = {};
	_tCSLViewNames = {};
end
