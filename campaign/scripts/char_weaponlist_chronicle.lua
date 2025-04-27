-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

-- ===================================================================================================================
-- Adjusted
-- ===================================================================================================================
function onInit()
	DB.addHandler(getDatabaseNode(), "onChildAdded", onChildAdded);
	-- DB.addHandler(DB.getPath(window.getDatabaseNode(), "profbonus"), "onUpdate", onProfChanged);
	
	onModeChanged();
end

-- ===================================================================================================================
-- Adjusted
-- ===================================================================================================================
function onClose()
	DB.removeHandler(getDatabaseNode(), "onChildAdded", onChildAdded);
	-- DB.removeHandler(DB.getPath(window.getDatabaseNode(), "profbonus"), "onUpdate", onProfChanged);
end

-- ===================================================================================================================
-- Adjusted
-- ===================================================================================================================
function onChildAdded()
	onModeChanged();
end

-- ===================================================================================================================
-- Adjusted
-- ===================================================================================================================
function onProfChanged()
	-- for _,w in pairs(getWindows()) do
		-- w.onAttackChanged();
	-- end
end

-- ===================================================================================================================
-- Adjusted
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