--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local aFilters = {};

function onInit()
	local sPath = getDatabaseNode();
	DB.addHandler(sPath, "onChildAdded", self.onChildListChanged);
	DB.addHandler(sPath, "onChildDeleted", self.onChildListChanged);
end
function onClose()
	local sPath = getDatabaseNode();
	DB.removeHandler(sPath, "onChildAdded", self.onChildListChanged);
	DB.removeHandler(sPath, "onChildDeleted", self.onChildListChanged);
end

function addEntry()
	return createWindow(nil, true);
end

function onChildListChanged()
	window.onPowerListChanged();
end
function onChildWindowAdded(w)
	window.onPowerWindowAdded(w);
end

function onEnter()
	if Input.isShiftPressed() then
		createWindow(nil, true);
		return true;
	end

	return false;
end

function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		local sClass = draginfo.getShortcutData();
		if sClass == "reference_spell" or sClass == "power" then
			local w = getWindowAt(x,y);
			if w then
				draginfo.setSlot(2);
				draginfo.setStringData(w.group.getValue());
				draginfo.setSlot(1);
			end
		end
	end
	return false;
end

function onSortCompare(w1, w2)
	return window.onSortCompare(w1, w2);
end

function onHeaderToggle(wh)
	local sCategory = window.getWindowSort(wh);
	if aFilters[sCategory] then
		aFilters[sCategory] = nil;
		wh.name.setFont("subwindowsmalltitle");
	else
		aFilters[sCategory] = true;
		wh.name.setFont("subwindowsmalltitle_disabled");
	end
	applyFilter();
end

function onFilter(w)
	if w.getClass() == "power_group_header" then
		return w.getFilter();
	end

	-- Check to see if this category is hidden
	local sCategory = window.getWindowSort(w);
	if aFilters[sCategory] then
		return false;
	end

	return w.getFilter();
end
