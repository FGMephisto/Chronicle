--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

-- Adjusted
function onInit()
	DB.addHandler(getDatabaseNode(), "onChildAdded", onChildAdded);

	self.onModeChanged();
end

-- Adjusted
function onClose()
	DB.removeHandler(getDatabaseNode(), "onChildAdded", onChildAdded);
end

function onChildAdded(nodeParent, nodeChild)
	onModeChanged();
end

function onModeChanged()
	applyFilter();
	WindowManager.callInnerWindowFunction(self, "onModeChanged");
end

-- Adjusted
function onProfChanged()
	-- WindowManager.callInnerWindowFunction(self, "onProfChanged");
end

function onDrop(_, _, draginfo)
	if draginfo.isType("shortcut") then
		local sClass,_ = draginfo.getShortcutData();
		if RecordDataManager.isRecordTypeDisplayClass("item", sClass) and ItemManager.isWeapon(draginfo.getDatabaseNode()) then
			return ItemManager.handleAnyDrop(window.getDatabaseNode(), draginfo);
		end
	end
end

function onFilter(w)
	if not WindowManager.getWindowReadOnlyState(window) then
		return true;
	end
	if (DB.getValue(window.getDatabaseNode(), "powermode", "") == "combat") and (w.carried.getValue() < 2) then
		return false;
	end
	return true;
end