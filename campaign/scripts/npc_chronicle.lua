-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	onIDChanged();
end

function onLockChanged()
	StateChanged();
end

function StateChanged()
	if header.subwindow then
		header.subwindow.update();
	end
	-- if main_creature.subwindow then
		-- main_creature.subwindow.update();
	-- end

	local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());
	text.setReadOnly(bReadOnly);
end

function onIDChanged()
	if Session.IsHost then
		-- if main_creature.subwindow then
			-- main_creature.subwindow.update();
		-- end
	else
		local bID = LibraryData.getIDState("npc", getDatabaseNode(), true);
		tabs.setVisibility(bID);
	end
end