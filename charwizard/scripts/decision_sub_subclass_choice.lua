--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	self.buildFilters();
end

local _sClassName = "";
local _bIs2024 = true;
local _tSubclasses = {};
local _tModules = {};
function getClassName()
	return _sClassName;
end
function setClassName(sClassName)
	_sClassName = sClassName;
	self.buildSubclasses();
end
function getAllSubclasses()
	return _tSubclasses;
end
function getAllModules()
	return _tModules;
end
function clearRecords()
	_tSubclasses = {};
	_tModules = {};
	list.closeAll();
end
function buildRecords()
	self.clearRecords();

	local tSubclassOptions = CharClassManager.getSubclassOptions(CharWizardClassManager.getClassNode(self.getClassName()));
	for k,v in pairs(tSubclassOptions) do
		self.addListRecord(DB.findNode(v.linkrecord));
	end
end
function buildSubclasses()
	self.buildRecords();
	self.buildFilters();

	for k,v in pairs(self.getAllSubclasses()) do
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

	local tSubclasses = self.getAllSubclasses();
	tSubclasses[rRecord.sDisplayNameLower] = tSubclasses[rRecord.sDisplayNameLower] or {};
	table.insert(tSubclasses[rRecord.sDisplayNameLower], rRecord);

	self.getAllModules()[rRecord.sModule] = true;
end

function addDisplayListItem(k, tSubclass)
	if #(tSubclass or {}) == 0 then
		return;
	end
	local sSubclass = tSubclass[1].sDisplayName;
	if not sSubclass then
		return;
	end

	local wSubclass = list.createWindow();
	wSubclass.button_select.setVisible(true);
	wSubclass.name.setValue(sSubclass);

	local tModules = {};
	for _,v in ipairs(tSubclass) do
		local nOrder;
		for k2,v2 in ipairs(CharWizardData.module_order_2024) do
			if v.sModuleName == v2 then
				nOrder = k2;
				break
			else
				local bFound = false;
				for k3,v3 in ipairs(CharWizardData.module_order_2014) do
					if v.sModuleName == v3 then
						nOrder = k2 + 1;
						bFound = true;
						break
					end
				end

				if bFound then
					break
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
	wSubclass.module.addItems(tFinalModules);
	wSubclass.module.setVisible(true);

	if #tFinalModules == 1 then
		wSubclass.module.setComboBoxReadOnly(true);
		wSubclass.module.setFrame(nil);
	end

	wSubclass.module.setValue(tFinalModules[1]);
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
	self.buildSubclasses();
end
function buildFilters()
	filter_name.setValue("");

	filter_source.clear();
	filter_source.add("");
	for k,_ in pairs(self.getAllModules()) do
		filter_source.add(k);
	end
end
function helperFilterCheck(tSubclass)
	local bModule = false;
	local bString = false;

	for _,v in ipairs(tSubclass) do
		if self.moduleFilterCheck(v) then
			bModule = true;
		end
		if self.stringFilterCheck(v) then
			bString = true;
		end
	end

	if bModule and bString then
		return true
	end

	return false
end
function moduleFilterCheck(tSubclassEntry)
	local bAdd = false;
	if _sComboFilter == "" then
		return true;
	end
	if _sComboFilter == tSubclassEntry.sModule:lower() then
		bAdd = true;
	end

	return bAdd;
end
function stringFilterCheck(tSubclassEntry)
	local bAdd = false;
	if _sFilter == "" then
		return true;
	end

	for _,v in ipairs(StringManager.split(_sFilter:lower(), ",", true)) do
		if tSubclassEntry.sDisplayNameLower:match(v) then
			bAdd = true;
		end
	end

	return bAdd;
end
