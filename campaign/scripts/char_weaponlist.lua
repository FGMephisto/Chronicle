--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	DB.addHandler(DB.getPath(window.getDatabaseNode(), "profbonus"), "onUpdate", self.onProfChanged);

	self.onModeChanged();
end
function onClose()
	DB.removeHandler(DB.getPath(window.getDatabaseNode(), "profbonus"), "onUpdate", self.onProfChanged);
end

function onModeChanged()
	applyFilter();
	WindowManager.callInnerWindowFunction(self, "onModeChanged");
end
function onProfChanged()
	WindowManager.callInnerWindowFunction(self, "onProfChanged");
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
