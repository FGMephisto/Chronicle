--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	self.buildBackgrounds();
	self.buildFilters();
end

local _tBackgrounds = {};
local _tModules = {};
function getAllBackgrounds()
	return _tBackgrounds;
end
function getAllModules()
	return _tModules;
end
function clearRecords()
	_tBackgrounds = {};
	_tModules = {};
	list.closeAll();
end
function buildRecords()
	self.clearRecords();
	RecordManager.callForEachRecord("background", self.addListRecord);
end
function buildBackgrounds()
	self.buildRecords();

	for k,v in pairs(self.getAllBackgrounds()) do
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
		rRecord.sModule = rRecord.sModule .. " (Legacy)";
	end

	local tBackgrounds = self.getAllBackgrounds();
	tBackgrounds[rRecord.sDisplayNameLower] = tBackgrounds[rRecord.sDisplayNameLower] or {};
	table.insert(tBackgrounds[rRecord.sDisplayNameLower], rRecord);

	self.getAllModules()[rRecord.sModule] = true;
end
function addDisplayListItem(k, tBackground)
	if #(tBackground or {}) == 0 then
		return;
	end
	local sBackground = tBackground[1].sDisplayName;
	if not sBackground then
		return;
	end

	local wBackground = list.createWindow();
	wBackground.button_select.setVisible(true);
	wBackground.name.setValue(sBackground);

	local tModules = {};
	local tOrderedModules = {};
	for _,v in ipairs(tBackground) do
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
				table.insert(tOrderedModules, nOrder, v.sModule);
			else
				table.insert(tModules, v.sModule);
			end
		end
	end

	local tFinalModules = {};
	for _,v in pairs(tModules) do
		table.insert(tFinalModules, v);
	end
	for _,v in pairs(tOrderedModules) do
		table.insert(tFinalModules, v);
	end
	wBackground.module.addItems(tFinalModules);
	wBackground.module.setVisible(true);

	if #tFinalModules == 1 then
		wBackground.module.setComboBoxReadOnly(true);
		wBackground.module.setFrame(nil);
	end

	wBackground.module.setValue(tFinalModules[1]);
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
	self.buildBackgrounds();
end
function buildFilters()
	filter_name.setValue("");

	filter_source.clear();
	filter_source.add("");
	for k,_ in pairs(self.getAllModules()) do
		filter_source.add(k);
	end
end
function helperFilterCheck(tBackground)
	local bModule = false;
	local bString = false;

	for _,v in ipairs(tBackground) do
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
function moduleFilterCheck(tBackgroundEntry)
	local bAdd = false;
	if _sComboFilter == "" then
		return true;
	end
	if _sComboFilter == tBackgroundEntry.sModule:lower() then
		bAdd = true;
	end

	return bAdd;
end
function stringFilterCheck(tBackgroundEntry)
	local bAdd = false;
	if _sFilter == "" then
		return true;
	end

	for _,v in ipairs(StringManager.split(_sFilter:lower(), ",", true)) do
		if tBackgroundEntry.sDisplayNameLower:match(v) then
			bAdd = true;
		end
	end

	return bAdd;
end
