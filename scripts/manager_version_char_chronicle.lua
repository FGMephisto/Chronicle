--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

CHAR_DB_VERSION = 2;

function onInit()
	Interface.addKeyedEventHandler("onWindowOpened", "charsheet", VersionCharManager.onWindowOpened);
	RecordManager.setRecordAddCallback("charsheet", VersionCharManager.onNewRecord);
end

function onWindowOpened(w)
	VersionCharManager.updateVersion(w.getDatabaseNode());
end

function onNewRecord(nodeRecord)
	if not nodeRecord then
		return;
	end
	DB.setValue(nodeRecord, "chardbversion", "number", VersionCharManager.CHAR_DB_VERSION);
end
function updateVersion(nodeRecord)
	if not nodeRecord or not DB.isOwner(nodeRecord) then
		return;
	end
	local nCurrent = DB.getValue(nodeRecord, "chardbversion", 0);
	if nCurrent < VersionCharManager.CHAR_DB_VERSION then
		DB.setValue(nodeRecord, "chardbversion", "number", VersionCharManager.CHAR_DB_VERSION);

		if nCurrent < 2 then
			VersionCharManager.querySpellMigration2(nodeRecord);
		end
	end
end

function querySpellMigration2(nodeChar)
	if not nodeChar then
		return;
	end

	local bHasSpells = false;
	for _, nodePowerGroup in ipairs(DB.getChildList(nodeChar, "powergroup")) do
		if DB.getValue(nodePowerGroup, "castertype", "") == "memorization" then
			bHasSpells = true;
			break;
		end
	end
	if not bHasSpells then
		return;
	end

	local tData = {
		sTitleRes = "chardbversion2_title_migration",
		sText = string.format(Interface.getString("chardbversion2_message_migration"), DB.getValue(nodeChar, "name", "")),
		sPath = DB.getPath(nodeChar),
		fnCallback = VersionCharManager.handleDialogSpellMigration2,
	};
	DialogManager.openDialog("dialog_okcancel", tData);
end
function handleDialogSpellMigration2(sResult, tData)
	if (sResult or "") ~= "ok" then
		return;
	end
	local nodeChar = DB.findNode(tData.sPath);
	if not nodeChar then
		return;
	end

	local sTableGameVersion = (OptionsManager.isOption("GAVE", "2024") and "2024" or "");
	local tDeleteNodes = {};
	local tAddItems = {};
	for _,nodePower in ipairs(DB.getChildList(nodeChar, "powers")) do
		local sName = DB.getValue(nodePower, "name", "");
		sName = StringManager.trim(sName:gsub("%([^)]+%)", ""));
		sName = StringManager.trim(sName:gsub("%[[^]]+%]", ""));

		local tFilters = {
			{ sField = "name", sValue = sName, bIgnoreCase = true, },
			{ sField = "version", sValue = sTableGameVersion, },
		};
		local nodeRecord = RecordManager.findRecordByFilter("spell", tFilters);
		if not nodeRecord then
			nodeRecord = RecordManager.findRecordByStringI("spell", "name", sName);
		end
		if nodeRecord then
			table.insert(tDeleteNodes, nodePower);
			table.insert(tAddItems, { node = nodeRecord, sGroup = DB.getValue(nodePower, "group", ""), nPrepared = DB.getValue(nodePower, "prepared", 0), });
		end
	end

	for _,node in ipairs(tDeleteNodes) do
		DB.deleteNode(node);
	end
	for _,v in ipairs(tAddItems) do
		local nodeNewPower = PowerManager.addPower("power", v.node, nodeChar, v.sGroup);
		if nodeNewPower then
			if v.nPrepared == 1 then
				DB.setValue(nodeNewPower, "prepared", "number", v.nPrepared);
			end
		end
	end
end
