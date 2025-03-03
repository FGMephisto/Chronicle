-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

function onInit()
	self.setRadialOptions();
end

function onMenuSelection(selection, subselection)
	if selection == 6 and subselection == 7 then
		UtilityManager.safeDeleteWindow(self);
	end
end

function onEditModeChanged()
	local bEditMode = WindowManager.getEditMode(windowlist, "sheet_iedit");
	idelete.setVisible(bEditMode and self.isCustom());
	idelete_spacer.setVisible(bEditMode and not self.isCustom());
end

-- This function is called to set the entry to non-custom or custom.
-- Custom entries have configurable stats and editable labels.
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
function isCustom()
	return _bCustom;
end

function setRadialOptions()
	resetMenuItems();

	if self.isCustom() then
		registerMenuItem(Interface.getString("list_menu_deleteitem"), "delete", 6);
		registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "delete", 6, 7);
	end
end

-- Adjusted
function openSkillLink()
	local nodeSkill = RecordManager.findRecordByStringI("skill", "name", name.getValue());
	if nodeSkill then
		Interface.openWindow(LibraryData.getRecordDisplayClass("skill"), nodeSkill);
	else
		Interface.openWindow("ref_feat", getDatabaseNode());
	end
end