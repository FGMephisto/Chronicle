--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	ListManager.initCustomList(self);
	self.buildRecords();
end
function onClose()
	ListManager.onCloseWindow(self);
end

local _tRecords = {};
function getAllRecords()
	return _tRecords;
end
function clearRecords()
	_tRecords = {};
	list.closeAll();
end

function getSortFunction()
	return self.sortFunc;
end
function onSortCompare(w1, w2)
	local tRecords = self.getAllRecords();
	local sW1 = w1.name.getValue():lower();
	local sW2 = w2.name.getValue():lower();
	return not self.charwizardItemsSortFunc(tRecords[sW1], tRecords[sW2]);
end
function sortFunc(a, b)
	if a[1].sDisplayNameLower ~= b[1].sDisplayNameLower then
		return a[1].sDisplayNameLower < b[1].sDisplayNameLower;
	end

	return DB.getPath(a[1].vNode) < DB.getPath(b[1].vNode);
end

function buildRecords()
	self.clearRecords();
	RecordManager.callForEachRecord("item", self.addListRecord);

	ListManager.setDisplayOffset(self, 0, true);
	ListManager.refreshDisplayList(self);
end

function addListRecord(vNode)
	local rRecord = {};
	rRecord.vNode = vNode;
	rRecord.sDisplayName = DB.getValue(vNode, "name", "");
	rRecord.sDisplayNameLower = rRecord.sDisplayName:lower();
	rRecord.sType = DB.getValue(vNode, "type", "");
	rRecord.sProperties = DB.getValue(vNode, "properties", "");

	if rRecord.sType:lower() == "treasure" or rRecord.sType:lower() == "woundrous item" then
		return false;
	end
	if rRecord.sProperties:lower():match("magic") then
		return false;
	end

	local tItems = self.getAllRecords();
	tItems[rRecord.sDisplayNameLower] = tItems[rRecord.sDisplayNameLower] or {};
	table.insert(tItems[rRecord.sDisplayNameLower], rRecord);
end
function addDisplayListItem(v)
	local wItem = list.createWindow();
	wItem.name.setValue(v[1].sDisplayName);
	wItem.link.setValue("item", DB.getPath(v[1].vNode));
end

local _sTypeFilter = "";
local _sFilter = "";
function onFilterChanged()
	local sTypeFilter = "";
	if button_armor.getValue() == 1 then
		sTypeFilter = "armor"
	elseif button_weapon.getValue() == 1 then
		sTypeFilter = "weapon"
	elseif button_gear.getValue() == 1 then
		sTypeFilter = "gear"
	end
	local sNameFilter = filter_name.getValue():lower();
	if sTypeFilter == _sTypeFilter and sNameFilter == _sFilter then
		return;
	end

	_sTypeFilter = sTypeFilter;
	_sFilter = sNameFilter;
	ListManager.refreshDisplayList(self, true);
end
function isFilteredRecord(v)
	local sType = v[1].sType:lower();
	if _sTypeFilter ~= "" then
		if _sTypeFilter == "gear" then
			if sType == "weapon" or sType == "armor" then
				return false;
			end
		elseif _sTypeFilter ~= sType then
			return false;
		end
	end

	if _sFilter ~= "" then
		if not v[1].sDisplayNameLower:find(_sFilter) then
			return false;
		end
	end

	return true;
end
