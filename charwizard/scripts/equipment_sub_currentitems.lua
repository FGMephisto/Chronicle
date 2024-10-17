--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	self.buildRecords();

	ListManager.initCustomList(self);
	ListManager.setPageSize(self, 24);
	ListManager.refreshDisplayList(self, true);
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
end
function buildRecords()
	self.clearRecords();

	local tEquipment = CharWizardManager.getEquipmentData();
	for _,v in pairs(tEquipment.classitems or {}) do
		self.addListRecord(v);
	end
	for _,v in pairs(tEquipment.backgrounditems or {}) do
		self.addListRecord(v);
	end
	for _,v in pairs(tEquipment.additems or {}) do
		self.addListRecord(v);
	end
end
function addListRecord(tNode)
	local rRecord = {};
	rRecord.vNode = tNode.item;
	rRecord.sDisplayName = DB.getValue(tNode.item, "name", "");
	rRecord.sDisplayNameLower = rRecord.sDisplayName:lower();
	rRecord.nCount = tNode.count or 1;

	if self.getAllRecords()[rRecord.sDisplayNameLower] then
		rRecord.nCount = self.getAllRecords()[rRecord.sDisplayNameLower].nCount + rRecord.nCount;
	end

	self.getAllRecords()[rRecord.sDisplayNameLower] = rRecord;
end
function deleteRecord(vNode)
	local bChanged = false;
	for _,v in pairs(self.getAllRecords()) do
		if v.vNode == vNode then
			local tEquipment = CharWizardManager.getEquipmentData();
			for k2,v2 in pairs(tEquipment.additems or {}) do
				if v2.item == vNode then
					tEquipment.additems[k2] = nil;
					bChanged = true;
					break;
				end
			end
		end
	end
	if bChanged then
		self.buildRecords();
		ListManager.refreshDisplayList(self, true);
	end
end

function addDisplayListItem(v)
	local wItem = list.createWindow(v.vNode);

	if v.nCount == 1 then
		wItem.count.setVisible(false);
	else
		wItem.count.setValue(v.nCount);
	end
end
