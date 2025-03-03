--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	self.buildClasses();
	self.buildFilters();
end

local _tClasses = {};
local _tModules = {};
function getAllClasses()
	return _tClasses;
end
function getAllModules()
	return _tModules;
end
function clearRecords()
	_tClasses = {};
	_tModules = {};
	list.closeAll();
end
function buildRecords()
	self.clearRecords();
	RecordManager.callForEachRecord("class", self.addListRecord);
end
function buildClasses()
	self.buildRecords();

	for k,v in pairs(self.getAllClasses()) do
		if self.helperFilterCheck(v) then
			self.addDisplayListItem(k, v);
		end
	end
end

function addListRecord(vNode)
	local rRecord = {};
	rRecord.vNode = vNode;
	rRecord.sDisplayName = DB.getValue(vNode, "name", "");
	rRecord.sDisplayNameLower = rRecord.sDisplayName:lower();

	rRecord.sModuleName = DB.getModule(vNode);
	rRecord.sModule = ModuleManager.getModuleDisplayName(rRecord.sModuleName);
	if (DB.getValue(vNode, "version", "") ~= "2024") then 
		local sLegacySuffix = Interface.getString("suffix_legacy");
		if not StringManager.endsWith(rRecord.sModule, sLegacySuffix) then
			rRecord.sModule = string.format("%s %s", rRecord.sModule, sLegacySuffix);
		end
	end

	local tClasses = self.getAllClasses();
	tClasses[rRecord.sDisplayNameLower] = tClasses[rRecord.sDisplayNameLower] or {};
	table.insert(tClasses[rRecord.sDisplayNameLower], rRecord);

	self.getAllModules()[rRecord.sModule] = true;
end
function buildFilters()
	filter_name.setValue("");

	filter_source.clear();
	filter_source.add("");
	for k,_ in pairs(self.getAllModules()) do
		filter_source.add(k);
	end
end

function addDisplayListItem(k, tClass)
	if #(tClass or {}) == 0 then
		return;
	end
	local sClass = tClass[1].sDisplayName;
	if not sClass then
		return;
	end

	local wClass = list.createWindow();
	wClass.button_select.setVisible(true);
	wClass.name.setValue(sClass);

	local tModules = {};
	for _,v in ipairs(tClass) do
		local nOrder;
		for k2,v2 in ipairs(CharWizardData.module_order_2024) do
			if v.sModuleName == v2 then
				nOrder = k2;
				break
			else
				for k3,v3 in ipairs(CharWizardData.module_order_2014) do
					if v.sModuleName == v3 then
						nOrder = k2 + 1;
						break
					end
				end
			end
		end

		local bModule = self.moduleFilterCheck(v);
		local bString = self.stringFilterCheck(v);
		if bModule and bString then
			if nOrder then
				table.insert(tModules, nOrder, v.sModule);
			else
				table.insert(tModules, v.sModule);
			end
		end
	end

	local tFinalModules = {};
	for _,v in pairs(tModules) do
		table.insert(tFinalModules, v);
	end
	wClass.module.addItems(tFinalModules);
	wClass.module.setVisible(true);

	if #tFinalModules == 1 then
		wClass.module.setComboBoxReadOnly(true);
		wClass.module.setFrame(nil);
	end

	wClass.module.setValue(tFinalModules[1]);
end

local _sComboFilter = "";
local _sFilter = "";
function onFilterChanged()
	local sSourceFilter = filter_source.getValue():lower();
	local sNameFilter = filter_name.getValue():lower();
	if sSourceFilter == _sComboFilter and sNameFilter == _sFilter then
		return;
	end

	_sComboFilter = sSourceFilter;
	_sFilter = sNameFilter;
	self.buildClasses();
end
function buildFilters()
	filter_name.setValue("");

	filter_source.clear();
	filter_source.add("");
	for k,_ in pairs(self.getAllModules()) do
		filter_source.add(k);
	end
end
function helperFilterCheck(tCurClass)
	local tClassData = CharWizardManager.getClassData();

	local bModule = false;
	local bString = false;
	for _,v in ipairs(tCurClass) do
		for k2 in pairs(tClassData) do
			if k2:lower() == v.sDisplayNameLower then
				return
			end
		end
		if self.moduleFilterCheck(v) then
			bModule = true;
		end
		if self.stringFilterCheck(v) then
			bString = true;
		end
	end
	return (bModule and bString);
end
function moduleFilterCheck(tClassEntry)
	local bAdd = false;
	if _sComboFilter == "" then
		return true;
	end
	if _sComboFilter == tClassEntry.sModule:lower() then
		bAdd = true;
	end
	return bAdd;
end
function stringFilterCheck(tClassEntry)
	local bAdd = false;
	if _sFilter == "" then
		return true;
	end
	for _,v in ipairs(StringManager.split(_sFilter:lower(), ",", true)) do
		if tClassEntry.sDisplayNameLower:match(v) then
			bAdd = true;
		end
	end
	return bAdd;
end
