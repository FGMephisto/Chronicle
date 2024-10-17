--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local _tSlots = {};
local _tSpells = {};
local _tModules = {};

function onInit()
	self.rebuildSpells();
end
function rebuildSpells()
	self.buildSpells();
	self.buildFilters();
end

function getClassName()
	return WindowManager.getOuterControlValue(self, "class");
end
function getClassRecord()
	return CharWizardClassManager.getClassDataByName(self.getClassName());
end
function getClassSpells()
	return ClassSpellListManager.getClassSpellListRecord(self.getClassName());
end
function getSubclassSpells()
	local sSubclass = CharWizardClassManager.getSubclassName(self.getClassName());
	if ((sSubclass or "") == "") then
		return {};
	end
	return ClassSpellListManager.getClassSpellListRecord(sSubclass);	
end

function getAllSpells()
	return _tSpells;
end
function setAllSpells(tSpells)
	_tSpells = tSpells;
end
function getAllModules()
	return _tModules;
end
function getSlotFilters()
	return _tSlots;
end
function addSlotFilter(k, cFilter)
	_tSlots[k] = cFilter;
end
function clearSlotFilters()
	for k,cFilter in pairs(_tSlots) do
		cFilter.destroy();
		_tSlots[cFilter] = nil;
	end
end
function clearSpells()
	_tSpells = {};
	_tModules = {};
	list.closeAll();
end
function buildRecords()
	self.clearSpells();

	local tSpells = {};
	local tClassSpellList = self.getClassSpells();
	local tSubclassSpellList = self.getSubclassSpells();
	for _,nodeSpell in ipairs(tClassSpellList and tClassSpellList.tSpells or {}) do
		local sSpellName = DB.getValue(nodeSpell, "name", "");
		tSpells[StringManager.simplify(sSpellName)] = true;
	end
	for _,nodeSpell in ipairs(tSubclassSpellList and tSubclassSpellList.tSpells or {}) do
		local sSpellName = DB.getValue(nodeSpell, "name", "");
		tSpells[StringManager.simplify(sSpellName)] = true;
	end

	RecordManager.callForEachRecord("spell", self.helperBuildRecords, tSpells);
end
function helperBuildRecords(node, tSpells)
	local sSpellName = StringManager.simplify(DB.getValue(node, "name", ""));
	if tSpells[StringManager.simplify(DB.getValue(node, "name", ""))] then
		self.addListRecord(node);
	end
end
function buildSpells()
	self.buildRecords();

	for k,v in pairs(self.getAllSpells()) do
		if self.isFilteredRecord(v) then
			self.addDisplayListItem(k,v);
		end
	end
end
function addListRecord(vNode)
	local rRecord = {};
	rRecord.vNode = vNode;
	rRecord.sDisplayName = DB.getValue(vNode, "name", "");
	rRecord.sDisplayNameLower = rRecord.sDisplayName:lower();
	rRecord.aSource = LibraryData5E.getSpellSourceValue(vNode);
	rRecord.nSpellLevel = DB.getValue(vNode, "level", 0);

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

	local tSpells = self.getAllSpells();
	if not tSpells[rRecord.sDisplayNameLower] then
		tSpells[rRecord.sDisplayNameLower] = {};
	end

	table.insert(tSpells[rRecord.sDisplayNameLower], rRecord);
	self.setAllSpells(tSpells);
	self.getAllModules()[rRecord.sModule] = true;
end

function addDisplayListItem(k, tSpell)
	if #(tSpell or {}) == 0 then
		return;
	end
	local sSpell = tSpell[1].sDisplayName;
	if not sSpell then
		return;
	end

	local wSpell = list.createWindow();
	wSpell.button_select.setVisible(true);
	wSpell.name.setValue(sSpell);

	local tModules = {};
	for _,v in ipairs(tSpell) do
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

	wSpell.module.addItems(tFinalModules);
	wSpell.module.setVisible(true);

	if #tFinalModules == 1 then
		wSpell.module.setComboBoxReadOnly(true);
		wSpell.module.setFrame(nil);
	end

	wSpell.module.setValue(tFinalModules[1]);
end

function buildFilters()
	filter_name.setValue("");

	filter_source.clear();
	filter_source.add("");
	for k,_ in pairs(self.getAllModules()) do
		filter_source.add(k);
	end

	self.clearSlotFilters();

	local tCharMagicData = CharWizardClassManager.getCharWizardMagicData();
	for i = 0,9 do
		if (i == 0) or tCharMagicData.tSpellSlots[i] or tCharMagicData.tPactMagicSlots[i] then
			self.helperBuildSlotFilter(i);
		end
	end
end
function helperBuildSlotFilter(nSpellLevel)
	local i = nSpellLevel + 1;
	local cFilter = spellcasting_filters.subwindow.createControl("button_charwizard_class_spell_filter", "button_filter" .. nSpellLevel);
	if nSpellLevel == 0 then
		cFilter.setAnchoredWidth(65);
	end
	local tWidget = {
		position = "center", x = 0, y = 1,
		color = ColorManager.getButtonTextColor(),
		font = "button-white",
		text = (nSpellLevel == 0) and "Cantrips" or tostring(nSpellLevel);
	};
	cFilter.addTextWidget(tWidget);
	self.addSlotFilter(i, cFilter);
end

local _sComboFilter = "";
local _sFilter = "";
local _sLevelFilter = "";
function onFilterChanged()
	local sSourceFilter = filter_source.getValue():lower();
	local sNameFilter = filter_name.getValue():lower();
	if sSourceFilter == _sComboFilter and sNameFilter == _sFilter then
		return;
	end

	_sComboFilter = sSourceFilter;
	_sFilter = sNameFilter;
	self.buildSpells();
end
function onLevelFilterChanged(sLevel)
	if _sLevelFilter == sLevel then
		return;
	end

	_sLevelFilter = sLevel;
	self.buildSpells();
end
function moduleFilterCheck(tSpellEntry)
	local bAdd = false;
	if _sComboFilter == "" then
		return true;
	end
	if _sComboFilter == tSpellEntry.sModule:lower() then
		bAdd = true;
	end

	return bAdd;
end
function stringFilterCheck(tSpellEntry)
	local bAdd = false;
	if _sFilter == "" then
		return true;
	end

	for _,v in ipairs(StringManager.split(_sFilter:lower(), ",", true)) do
		if tSpellEntry.sDisplayNameLower:match(v) then
			bAdd = true;
		end
	end

	return bAdd;
end
function isFilteredRecord(v)
	if sFilter ~= "" then
		if not v[1].sDisplayNameLower:find(_sFilter) then
			return false;
		end
	end

	local bModule = false;
	local bString = false;
	for _,v2 in ipairs(v) do
		if self.moduleFilterCheck(v2) then
			bModule = true;
		end
	end
	if not bModule then
		return false
	end

	if _sLevelFilter ~= "" then
		if _sLevelFilter ~= v[1].nSpellLevel then
			return false;
		end
	end

	local tClassData = self.getClassRecord();
	if tClassData then
		if _sLevelFilter == "" then
			if tClassData.pactmagicslots then
				if v[1].nSpellLevel > #tClassData.pactmagicslots then
					return false
				end
			end
			if tClassData.spellslots then
				if v[1].nSpellLevel > #tClassData.spellslots then
					return false
				end
			end
		end
		for _,vSpell in ipairs(tClassData.spell or {}) do
			local sSpellName = DB.getValue(DB.findNode(vSpell), "name", "");
			for _,v2 in ipairs(v) do
				if v2.vNode == DB.findNode(vSpell) or v2.sDisplayNameLower == sSpellName:lower() then
					return false
				end
			end
		end
	end

	return true;
end
