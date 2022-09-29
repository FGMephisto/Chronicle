-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System.
--

-- ===================================================================================================================
-- Modified
-- ===================================================================================================================
function onInit()
	DB.addHandler(DB.getPath(getDatabaseNode()), "onChildAdded", onChildAdded);
	
	onModeChanged();
end

-- ===================================================================================================================
-- Modified
-- ===================================================================================================================
function onClose()
	DB.removeHandler(DB.getPath(getDatabaseNode()), "onChildAdded", onChildAdded);
end

-- ===================================================================================================================
-- Modified
-- ===================================================================================================================
function onChildAdded()
	onModeChanged();
	update();
end

-- ===================================================================================================================
-- ===================================================================================================================
function onListChanged()
	update();
end

-- ===================================================================================================================
-- Modified
-- ===================================================================================================================
function onModeChanged()
	local bPrepMode = (DB.getValue(window.getDatabaseNode(), "powermode", "") ~= "combat");

	for _,w in ipairs(getWindows()) do
		w.carried.setVisible(bPrepMode);
	end
	
	applyFilter();
end

-- ===================================================================================================================
-- ===================================================================================================================
function update()
	-- Logic for button in the action section of CT
	if window.actions_iedit then
		local bEditMode = (window.actions_iedit.getValue() == 1)
		for _,w in pairs(window.actions.getWindows()) do
			w.idelete.setVisibility(bEditMode)
		end
	end

	-- Logic for the button in the action section of PC/NPC sheet
	if window.parentcontrol.window.actions_iedit then
		local bEditMode = (window.parentcontrol.window.actions_iedit.getValue() == 1)
		for _,w in pairs(getWindows()) do
			w.idelete.setVisibility(bEditMode)
		end
	end
end

-- ===================================================================================================================
-- ===================================================================================================================
function addEntry(bFocus)
	local w = createWindow();
	if bFocus and w then
		w.name.setFocus();
	end

	return w;
end

-- ===================================================================================================================
-- ===================================================================================================================
function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		local sClass, sRecord = draginfo.getShortcutData();
		local nodeSource = draginfo.getDatabaseNode();

		if LibraryData.isRecordDisplayClass("item", sClass) and ItemManager.isWeapon(nodeSource) then
			return ItemManager.handleAnyDrop(window.getDatabaseNode(), draginfo);
		end
	end
end

-- ===================================================================================================================
-- ===================================================================================================================
function onFilter(w)
	if (DB.getValue(window.getDatabaseNode(), "powermode", "") == "combat") and (w.carried.getValue() < 2) then
		return false;
	end
	return true;
end