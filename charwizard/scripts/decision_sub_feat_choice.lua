--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	self.buildFeats();
	self.buildFilters();

	local sClassName = WindowManager.getOuterControlValue(self, "class") or "";
	local sFeatureName = WindowManager.getOuterControlValue(self, "feature") or "";

	local sKey = StringManager.simplify(sFeatureName);
	if CharWizardClassManager.isClass2024(sClassName) then
		if sKey == "epicboon" then
			filter_category.setValue("Epic Boon");
			label_category.setVisible(false);
			filter_category.setComboBoxVisible(false);
		elseif (sKey == "additionalfightingstyle") or StringManager.startsWith(sKey, "fightingstyle") then
			filter_category.setValue("Fighting Style");
			label_category.setVisible(false);
			filter_category.setComboBoxVisible(false);
		end
	end
	if CharWizardBackgroundManager.isBackground2024() then
		if sKey == "feat" then
			filter_category.setValue("Origin");
			label_category.setVisible(false);
			filter_category.setComboBoxVisible(false);
		end
	end
	if CharWizardSpeciesManager.isSpecies2024() then
		if sKey == "versatile" then
			filter_category.setValue("Origin");
			label_category.setVisible(false);
			filter_category.setComboBoxVisible(false);
		end
	end
end

local _tFeats = {};
local _tModules = {};
local _tCategories = {};
function getAllFeats()
	return _tFeats;
end
function getAllModules()
	return _tModules;
end
function getAllCategories()
	return _tCategories;
end
function clearRecords()
	_tFeats = {};
	_tModules = {};
	list.closeAll();
end
function buildRecords()
	self.clearRecords();
	RecordManager.callForEachRecord("feat", self.addListRecord);
end
function buildFeats()
	self.buildRecords();

	for k,v in pairs(self.getAllFeats()) do
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
	if rRecord.sDisplayNameLower == "ability score improvement" then
		return
	end

	rRecord.sCategory = DB.getValue(vNode, "category", "");

	rRecord.sModuleName = DB.getModule(vNode);
	rRecord.sModule = ModuleManager.getModuleDisplayName(rRecord.sModuleName);
	if (DB.getValue(vNode, "version", "") ~= "2024") then
		local sLegacySuffix = Interface.getString("suffix_legacy");
		if not StringManager.endsWith(rRecord.sModule, sLegacySuffix) then
			rRecord.sModule = string.format("%s %s", rRecord.sModule, sLegacySuffix);
		end
	end

	local tFeats = self.getAllFeats();
	tFeats[rRecord.sDisplayNameLower] = tFeats[rRecord.sDisplayNameLower] or {};
	table.insert(tFeats[rRecord.sDisplayNameLower], rRecord);

	self.getAllModules()[rRecord.sModule] = true;
	self.getAllCategories()[rRecord.sCategory] = true;
end
function addDisplayListItem(_, tFeat)
	if #(tFeat or {}) == 0 then
		return;
	end
	local sFeat = tFeat[1].sDisplayName;
	if not sFeat then
		return;
	end

	local tBaseFeats, tChoiceFeats = CharWizardManager.collectFeats();
	for _,v in ipairs(tBaseFeats) do
		if v.name == sFeat then
			return;
		end
	end
	if StringManager.contains(tChoiceFeats, DB.getPath(tFeat[1].vNode)) then
		return;
	end

	local wFeat = list.createWindow();
	wFeat.button_select.setVisible(true);
	wFeat.name.setValue(sFeat);

	local tModules = {};
	for _,v in ipairs(tFeat) do
		local nOrder;
		for k2,v2 in ipairs(CharWizardData.module_order_2024) do
			if v.sModuleName == v2 then
				nOrder = k2;
				break
			else
				for _,v3 in ipairs(CharWizardData.module_order_2014) do
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
	wFeat.module.addItems(tFinalModules);
	wFeat.module.setVisible(true);

	if #tFinalModules == 1 then
		wFeat.module.setComboBoxReadOnly(true);
		wFeat.module.setFrame(nil);
	end

	wFeat.module.setValue(tFinalModules[1]);
end

local _sCategoryFilter = "";
local _sComboFilter = "";
local _sFilter = "";
function onFilterChanged()
	local sCategoryFilter = filter_category.getValue():lower();
	local sSourceFilter = filter_source.getValue():lower();
	local sNameFilter = filter_name.getValue():lower();
	if sSourceFilter == _sComboFilter and sNameFilter == _sFilter and sCategoryFilter == _sCategoryFilter then
		return;
	end

	_sCategoryFilter = sCategoryFilter;
	_sComboFilter = sSourceFilter;
	_sFilter = sNameFilter;
	self.buildFeats();
end
function buildFilters()
	filter_name.setValue("");

	filter_source.clear();
	filter_source.add("");
	for k,_ in pairs(self.getAllModules()) do
		filter_source.add(k);
	end

	filter_category.clear();
	filter_category.add("");
	for k,_ in pairs(self.getAllCategories()) do
		filter_category.add(k);
	end
end
function helperFilterCheck(tFeat)
	local bCategory = false;
	local bModule = false;
	local bString = false;

	for _,v in ipairs(tFeat) do
		if self.categoryFilterCheck(v) then
			bCategory = true;
		end
		if self.moduleFilterCheck(v) then
			bModule = true;
		end
		if self.stringFilterCheck(v) then
			bString = true;
		end
	end

	if bModule and bString and bCategory then
		return true
	end

	return false
end
function categoryFilterCheck(tFeatEntry)
	local bAdd = false;
	if _sCategoryFilter == "" then
		return true;
	end
	if _sCategoryFilter == tFeatEntry.sCategory:lower() then
		bAdd = true;
	end

	return bAdd;
end
function moduleFilterCheck(tFeatEntry)
	local bAdd = false;
	if _sComboFilter == "" then
		return true;
	end
	if _sComboFilter == tFeatEntry.sModule:lower() then
		bAdd = true;
	end

	return bAdd;
end
function stringFilterCheck(tFeatEntry)
	local bAdd = false;
	if _sFilter == "" then
		return true;
	end

	for _,v in ipairs(StringManager.split(_sFilter:lower(), ",", true)) do
		if tFeatEntry.sDisplayNameLower:match(v:lower()) then
			bAdd = true;
		end
	end

	return bAdd;
end