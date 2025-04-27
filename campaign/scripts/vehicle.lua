-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	self.onStateChanged();
	self.onIDChanged();
end
function onLockChanged()
	self.onStateChanged();
end

function onStateChanged()
	if header.subwindow then
		header.subwindow.update();
	end
	if main_vehicle.subwindow then
		main_vehicle.subwindow.update();
	end

	local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());
	text.setReadOnly(bReadOnly);
end

function onIDChanged()
	if Session.IsHost then
		if main_vehicle.subwindow then
			main_vehicle.subwindow.update();
		end
	else
		local bID = LibraryData.getIDState("vehicle", getDatabaseNode(), true);
		tabs.setVisibility(bID);
	end
end
