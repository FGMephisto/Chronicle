--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local _tSpecies = {};
local _tModules = {};

function onInit()
	self.buildSpecies();
	self.buildFilters();
end

function getAllSpecies()
	return _tSpecies;
end
function setAllSpecies(tSpecies)
	_tSpecies = tSpecies;
end
function getAllModules()
	return _tModules;
end
function clearRecords()
	_tSpecies = {};
	_tModules = {};
	list.closeAll();
end
function buildRecords()
	self.clearRecords();
	RecordManager.callForEachRecord("race", self.addListRecord);
end
function buildSpecies()
	self.buildRecords();

	for k,v in pairs(self.getAllSpecies()) do
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

	local bIs2024 = (DB.getValue(vNode, "version", "") == "2024");
	local tModule = Module.getModuleInfo(DB.getModule(vNode));
	rRecord.sModule = "Campaign";
	rRecord.sModuleName = "Campaign";
	if tModule then
		rRecord.sModule = tModule.displayname;
		rRecord.sModuleName = tModule.name;
	end
	if not bIs2024 then 
		rRecord.sModule = rRecord.sModule .. " (Legacy)";
	end

	rRecord.tAncestry = {};
	local tAncestries = CharSpeciesManager.getAncestryOptions(vNode);
	for _,v in ipairs(tAncestries) do
		table.insert(rRecord.tAncestry, v.linkrecord);
	end

	local tSpecies = self.getAllSpecies();
	if not tSpecies[rRecord.sDisplayNameLower] then
		tSpecies[rRecord.sDisplayNameLower] = {};
	end

	table.insert(tSpecies[rRecord.sDisplayNameLower], rRecord);
	self.setAllSpecies(tSpecies);
	self.getAllModules()[rRecord.sModule] = true;
end

function addDisplayListItem(k, tSpecies)
	if #(tSpecies or {}) == 0 then
		return;
	end
	local sSpecies = tSpecies[1].sDisplayName;
	if not sSpecies then
		return;
	end

	local wSpecies = list.createWindow();
	wSpecies.button_select.setVisible(true);
	wSpecies.name.setValue(sSpecies);

	local tModules = {};
	for _,v in ipairs(tSpecies) do
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
	wSpecies.module.addItems(tFinalModules);
	wSpecies.module.setVisible(true);

	if #tFinalModules == 1 then
		wSpecies.module.setComboBoxReadOnly(true);
		wSpecies.module.setFrame(nil);
	end

	wSpecies.module.setValue(tFinalModules[1]);
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
	self.buildSpecies();
end
function buildFilters()
	filter_name.setValue("");

	filter_source.clear();
	filter_source.add("");
	for k,_ in pairs(self.getAllModules()) do
		filter_source.add(k);
	end
end
function helperFilterCheck(tSpecies)
	local bModule = false;
	local bString = false;

	for _,v in ipairs(tSpecies) do
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
function moduleFilterCheck(tSpeciesEntry)
	local bAdd = false;
	if _sComboFilter == "" then
		return true;
	end
	if _sComboFilter == tSpeciesEntry.sModule:lower() then
		bAdd = true;
	end

	return bAdd;
end
function stringFilterCheck(tSpeciesEntry)
	local bAdd = false;
	if _sFilter == "" then
		return true;
	end

	for _,v in ipairs(StringManager.split(_sFilter:lower(), ",", true)) do
		if tSpeciesEntry.sDisplayNameLower:match(v) then
			bAdd = true;
		end
	end

	return bAdd;
end