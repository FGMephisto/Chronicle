--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	ListManager.initCustomList(self);
	ListManager.refreshDisplayList(self, true);
end
function onClose()
	ListManager.onCloseWindow(self);
end

local _tChoiceItems = {};
function getAllRecords()
	return _tChoiceItems;
end
function clearRecords()
	_tChoiceItems = {};
end

local _sKitType = "";
function getKitType()
	return _sKitType;
end
function setKitType(s)
	_sKitType = s;
end

local bIs2024 = false;
function is2024()
	return bIs2024;
end
function setVersion(bVersion)
	bIs2024 = bVersion;
end

function getSortFunction()
	return sortFunc;
end
function sortFunc(a, b)
	if self.is2024() then
		if a.sDisplayNameLower ~= b.sDisplayNameLower then
			return a.sDisplayNameLower < b.sDisplayNameLower;
		end
	else
		if a[1].sDisplayNameLower ~= b[1].sDisplayNameLower then
			return a[1].sDisplayNameLower < b[1].sDisplayNameLower;
		end

		return DB.getPath(a[1].vNode) < DB.getPath(b[1].vNode);
	end
end

function setData(tData, sType)
	self.clearRecords();

	for k,vItem in pairs(tData) do
		local tItems = {};
		local rRecord = {};
		rRecord.vNode = vItem.item;
		rRecord.sDisplayName = DB.getValue(rRecord.vNode, "name", "");
		rRecord.sDisplayNameLower = rRecord.sDisplayName:lower();
		rRecord.nCount = vItem.count;

		local tItems = self.getAllRecords();
		tItems[rRecord.sDisplayNameLower] = tItems[rRecord.sDisplayNameLower] or {};
		table.insert(tItems[rRecord.sDisplayNameLower], rRecord);
	end

	self.setKitType(sType);

	ListManager.refreshDisplayList(self, true);
end

function setData2024(tData, sType)
	self.setVersion(true);
	self.clearRecords();
	self.setKitType(sType);

	local tChoiceLetter = { "A", "B", "C" };
	for k,vOption in ipairs(tData) do
		local tItems = {};
		local nWealth = vOption.wealth;
		for _,vItem in ipairs(vOption.items) do
			local sName = DB.getValue(vItem.item, "name", "");
			local nCount = DB.getValue(vItem.item, "count", 0);
			local sItem = "";
			if nCount > 1 then
				sItem = ("%s %s"):format(nCount, sName);
			else
				sItem = ("%s"):format(sName);
			end
			table.insert(tItems, sItem);
		end
		if nWealth then
			table.insert(tItems, nWealth .. " GP");
		end

		local rRecord = {};
		rRecord.sDisplayName = table.concat(tItems, ", ");
		rRecord.sDisplayNameLower = tChoiceLetter[k];
		rRecord.tOption = vOption;

		local tOptions = self.getAllRecords();
		tOptions[k] = rRecord;
	end

	ListManager.refreshDisplayList(self, true);
end

function addDisplayListItem(v)
	if self.is2024() then
		local wItem = list.createWindow();
		wItem.name.setValue(("%s: %s"):format(v.sDisplayNameLower, v.sDisplayName));
	else
		local wItem = list.createWindow();
		wItem.name.setValue(v[1].sDisplayName);
		wItem.count.setValue(v[1].nCount);
		wItem.link.setValue("item", DB.getPath(v[1].vNode));
	end
end
