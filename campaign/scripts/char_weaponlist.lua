--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	DB.addHandler(getDatabaseNode(), "onChildAdded", self.onChildAdded);
	DB.addHandler(DB.getPath(window.getDatabaseNode(), "profbonus"), "onUpdate", self.onProfChanged);

	self.onModeChanged();
end

function onClose()
	DB.removeHandler(getDatabaseNode(), "onChildAdded", self.onChildAdded);
	DB.removeHandler(DB.getPath(window.getDatabaseNode(), "profbonus"), "onUpdate", self.onProfChanged);
end

function onChildAdded()
	self.onModeChanged();
end

function onProfChanged()
	for _,w in pairs(getWindows()) do
		w.onAttackChanged();
	end
end

function onModeChanged()
	local bPrepMode = (DB.getValue(window.getDatabaseNode(), "powermode", "") == "preparation");
	for _,w in ipairs(getWindows()) do
		w.carried.setVisible(bPrepMode);
	end

	applyFilter();
end

function onDrop(_, _, draginfo)
	if draginfo.isType("shortcut") then
		local sClass,_ = draginfo.getShortcutData();
		local nodeSource = draginfo.getDatabaseNode();
		if RecordDataManager.isRecordTypeDisplayClass("item", sClass) and ItemManager.isWeapon(nodeSource) then
			return ItemManager.handleAnyDrop(window.getDatabaseNode(), draginfo);
		end
	end
end

function onFilter(w)
	if (DB.getValue(window.getDatabaseNode(), "powermode", "") == "combat") and (w.carried.getValue() < 2) then
		return false;
	end
	return true;
end
