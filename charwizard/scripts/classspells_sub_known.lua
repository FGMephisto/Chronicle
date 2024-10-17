--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local _tSlots = {};
local sFilter = "";

function onInit()
	self.buildRecords();
	self.buildFilters();
end

function getClassName()
	return WindowManager.getOuterControlValue(self, "class");
end
function getClassSpellsKnown()
	local tClassData = CharWizardClassManager.getClassDataByName(self.getClassName());
	return tClassData and tClassData.spell or {};
end

local _tRecords = {};
function getAllRecords()
	return _tRecords;
end
function clearRecords()
	_tRecords = {};
	list.closeAll();
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
		_tSlots[k] = nil;
	end
end

function buildRecords(bUpdate)
	self.clearRecords();

	for _,v in pairs(self.getClassSpellsKnown()) do
		self.addListRecord(DB.findNode(v));
	end

	if not bUpdate then
		self.buildFilters();
	end
	
	local tSpells = self.getAllRecords();
	for k,v in pairs(tSpells) do
		if self.isFilteredRecord(v) then
			self.addDisplayListItem(v);
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

	self.getAllRecords()[vNode] = rRecord;
end
function addDisplayListItem(v)
	local wSpell = list.createWindow();
	wSpell.name.setValue(v.sDisplayName);
	wSpell.shortcut.setValue("reference_spell", DB.getPath(v.vNode));
end

function buildFilters()
	self.clearSlotFilters();

	local tLevels = {};
	for _,v in pairs(self.getAllRecords()) do
		local bAdd = true;
		for _,v2 in ipairs(tLevels) do
			if v2 == v.nSpellLevel then
				bAdd = false;
				break
			end
		end
		if bAdd then
			table.insert(tLevels, v.nSpellLevel);
		end
	end
	table.sort(tLevels);

	for _,v in pairs(tLevels) do
		self.helperBuildSlotFilter(v);
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

local _sLevelFilter = "";
function onLevelFilterChanged(sLevel)
	if _sLevelFilter == sLevel then
		return;
	end
	_sLevelFilter = sLevel;
	self.buildRecords(true);
end
function isFilteredRecord(v)
	if _sLevelFilter ~= "" then
		if tonumber(_sLevelFilter) ~= v.nSpellLevel then
			return false;
		end
	end
	return true;
end
