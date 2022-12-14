-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

local iscustom = true;

-- ===================================================================================================================
-- Unchanged
-- ===================================================================================================================
function onInit()
	setRadialOptions();
end

-- ===================================================================================================================
-- Unchanged
-- ===================================================================================================================
function onMenuSelection(selection, subselection)
	if selection == 6 and subselection == 7 then
		local node = getDatabaseNode();
		if node then
			node.delete();
		else
			close();
		end
	end
end

-- ===================================================================================================================
-- This function is called to set the entry to non-custom or custom.
-- Custom entries have configurable stats and editable labels.
-- ===================================================================================================================
-- Unchanged
-- ===================================================================================================================
function setCustom(state)
	iscustom = state;
	
	if iscustom then
		name.setEnabled(true);
		name.setLine(true);
	else
		name.setEnabled(false);
		name.setLine(false);
	end
	
	setRadialOptions();
end

-- ===================================================================================================================
-- Unchanged
-- ===================================================================================================================
function isCustom()
	return iscustom;
end

-- ===================================================================================================================
-- Unchanged
-- ===================================================================================================================
function setRadialOptions()
	resetMenuItems();

	if iscustom then
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
