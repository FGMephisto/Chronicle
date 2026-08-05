-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

-- ===================================================================================================================
-- ===================================================================================================================
function onInit()
	local nodeSkill = getDatabaseNode();
	if nodeSkill then
		DB.addHandler(DB.getPath(nodeSkill, "name"), "onUpdate", updateSortKey);
		DB.addHandler(DB.getPath(nodeSkill, "stat"), "onUpdate", updateSortKey);
	end

	self.setRadialOptions();
	self.updateSortKey();
end

function onClose()
	local nodeSkill = getDatabaseNode();
	if nodeSkill then
		DB.removeHandler(DB.getPath(nodeSkill, "name"), "onUpdate", updateSortKey);
		DB.removeHandler(DB.getPath(nodeSkill, "stat"), "onUpdate", updateSortKey);
	end
end

function updateSortKey()
	local nodeSkill = getDatabaseNode();
	local sStat = DB.getValue(nodeSkill, "stat", "");
	local sName = DB.getValue(nodeSkill, "name", "");
	if (sName == "") and name then
		sName = name.getValue();
	end
	sortkey.setValue(sName .. " " .. sStat);
	if windowlist then
		windowlist.applySort();
	end
end

-- ===================================================================================================================
-- ===================================================================================================================
function onMenuSelection(selection, subselection)
	if selection == 6 and subselection == 7 then
		UtilityManager.safeDeleteWindow(self);
	end
end

-- ===================================================================================================================
-- ===================================================================================================================
function onEditModeChanged()
	local bEditMode = WindowManager.getEditMode(windowlist, "skills_iedit");
	if self.isCustom() then
		idelete.setVisibility(bEditMode);
	else
		idelete.setVisibility(false);
	end
end

-- ===================================================================================================================
-- This function is called to set the entry to non-custom or custom.
-- Custom entries have configurable stats and editable labels.
-- ===================================================================================================================
local _bCustom = true;
function setCustom(state)
	_bCustom = state;
	
	if _bCustom then
		name.setEnabled(true);
		name.setLine(true);
	else
		name.setEnabled(false);
		name.setLine(false);
	end
	
	setRadialOptions();
end

-- ===================================================================================================================
-- ===================================================================================================================
function isCustom()
	return _bCustom;
end

-- ===================================================================================================================
-- ===================================================================================================================
function setRadialOptions()
	resetMenuItems();

	if self.isCustom() then
		registerMenuItem(Interface.getString("list_menu_deleteitem"), "delete", 6);
		registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "delete", 6, 7);
	end
end

-- ===================================================================================================================
-- Adjusted to open "reference_skill" for skills
-- ===================================================================================================================
function openSkillLink()
	local nodeSkill = RecordManager.findRecordByStringI("skill", "name", name.getValue());

	if nodeSkill then
		Interface.openWindow("reference_skill", nodeSkill);
	else
		Interface.openWindow("ref_feat", getDatabaseNode());
	end
end

function action(draginfo)
	local nodeSkill = getDatabaseNode();
	local nodeChar = DB.getChild(nodeSkill, "...");
	local rActor = ActorManager.resolveActor(nodeChar);
	ActionSkill.performRoll(draginfo, rActor, nodeSkill);
	return true;
end